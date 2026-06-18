import Foundation
import SwiftUI

/// 浏览器 Cookie 数据源。
///
/// 拉取流程：
/// 1. 通过 `BrowserCookieReader` 读取匹配域的 Cookie；
/// 2. 用这些 Cookie 调服务商 Dashboard 接口；
/// 3. 解析响应为 `ProviderSnapshot`。
///
/// **降级策略**：
/// - 读不到 Cookie → `missingCredentials`（需要登录）；
/// - Cookie 在但请求失败 → `transient`（保留上次数据）；
/// - 解析失败 → `transient`。
final class BrowserCookieProvider: QuotaProvider, @unchecked Sendable {

    let id: String
    let kind: ProviderKind
    var displayName: String { kind.displayName }

    private let cookieReader: BrowserCookieReader
    private let session: URLSession
    private let dashboardEndpoint: URL?
    private let parser: BrowserDashboardParser

    init(
        id: String,
        kind: ProviderKind,
        cookieReader: BrowserCookieReader,
        session: URLSession = .shared,
        dashboardEndpoint: URL? = nil,
        parser: BrowserDashboardParser
    ) {
        self.id = id
        self.kind = kind
        self.cookieReader = cookieReader
        self.session = session
        self.dashboardEndpoint = dashboardEndpoint
        self.parser = parser
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let domains = kind.dashboardCookieDomains
        let cookies: [HTTPCookie]
        do {
            cookies = try await cookieReader.readCookies(matching: domains)
        } catch let error as FilesystemCookieReader.ReaderError {
            throw QuotaFetchError.transient(detail: error.localizedDescription)
        }

        guard !cookies.isEmpty else {
            throw QuotaFetchError.missingCredentials(
                detail: "未登录"
            )
        }

        guard let endpoint = dashboardEndpoint else {
            // 还没有接入真实 endpoint，但 cookie 已存在 —— 视为可用并返回占位额度。
            return parser.fallback(for: kind, fetchedAt: Date())
        }

        let payload = try await performRequest(with: cookies, endpoint: endpoint)
        return try parser.parse(data: payload, kind: kind, fetchedAt: Date())
    }

    private func performRequest(with cookies: [HTTPCookie], endpoint: URL) async throws -> Data {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue(
            "Mozilla/5.0 QuotaBar/1.0",
            forHTTPHeaderField: "User-Agent"
        )

        let configuration = session.configuration
        let cookieStorage = configuration.httpCookieStorage ?? HTTPCookieStorage.shared
        cookies.forEach { cookieStorage.setCookie($0) }

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw QuotaFetchError.transient(detail: "Dashboard 返回非 HTTP 响应")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw QuotaFetchError.transient(
                detail: "Dashboard HTTP \(http.statusCode)"
            )
        }
        return data
    }
}

// MARK: - 解析器协议

protocol BrowserDashboardParser: Sendable {
    func parse(data: Data, kind: ProviderKind, fetchedAt: Date) throws -> ProviderSnapshot
    func fallback(for kind: ProviderKind, fetchedAt: Date) -> ProviderSnapshot
}

// MARK: - 占位解析器

struct PlaceholderDashboardParser: BrowserDashboardParser {
    func parse(data: Data, kind: ProviderKind, fetchedAt: Date) throws -> ProviderSnapshot {
        let fraction = data.isEmpty ? 1.0 : min(1.0, Double(data.count % 100) / 100.0)
        return ProviderSnapshot(
            kind: kind,
            availability: .available,
            quotas: [
                QuotaWindow(title: "5小时额度", remainingFraction: fraction, refreshDescription: "刷新中..."),
                QuotaWindow(title: "周额度", remainingFraction: fraction, refreshDescription: "刷新中...")
            ],
            monthlyPrice: kind.fallbackMonthlyPrice,
            fetchedAt: fetchedAt
        )
    }

    func fallback(for kind: ProviderKind, fetchedAt: Date) -> ProviderSnapshot {
        ProviderSnapshot(
            kind: kind,
            availability: .available,
            quotas: [
                QuotaWindow(title: "5小时额度", remainingFraction: 1.0, refreshDescription: "等待首次刷新"),
                QuotaWindow(title: "周额度", remainingFraction: 1.0, refreshDescription: "等待首次刷新")
            ],
            monthlyPrice: kind.fallbackMonthlyPrice,
            fetchedAt: fetchedAt
        )
    }
}

// MARK: - ProviderKind 辅助

extension ProviderKind {
    var dashboardCookieDomains: [String] {
        switch self {
        case .codex: return ["chatgpt.com", "openai.com"]
        case .minimax: return ["minimax.chat", "minimax.com"]
        case .kimi: return ["kimi.com", "kimi.moonshot.cn"]
        default: return []
        }
    }
}
