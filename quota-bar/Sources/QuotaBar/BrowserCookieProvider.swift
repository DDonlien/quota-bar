import Foundation
import SwiftUI
import SweetCookieKit

/// 浏览器 Cookie 数据源。
///
/// 拉取流程：
/// 1. 通过 `BrowserCookieReader` 读取匹配域的 Cookie（SweetCookieKit，跨浏览器支持）；
/// 2. 用这些 Cookie 调服务商 Dashboard 接口（`DashboardEndpoints` 注册表）；
/// 3. 解析响应为 `ProviderSnapshot`。
///
/// **降级策略**：
/// - SweetCookieKit 抛 `accessDenied` → 转 `transient`，由聚合器在 UI 显示 FDA 引导；
/// - 读不到 Cookie → `missingCredentials`（需要登录）；
/// - Cookie 在但请求失败 → `transient`（保留上次数据）；
/// - 解析失败或 endpoint 未对接 → fallback 占位（仍然标记为已登录）。
final class BrowserCookieProvider: QuotaProvider, @unchecked Sendable {

    let id: String
    let kind: ProviderKind
    var displayName: String { kind.displayName }

    private let cookieReader: BrowserCookieReader
    private let session: URLSession
    private let endpoint: DashboardEndpoints.Endpoint?
    private let dateProvider: () -> Date

    init(
        id: String,
        kind: ProviderKind,
        cookieReader: BrowserCookieReader,
        session: URLSession = .shared,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.id = id
        self.kind = kind
        self.cookieReader = cookieReader
        self.session = session
        self.endpoint = DashboardEndpoints.endpoint(for: kind)
        self.dateProvider = dateProvider
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let fetchedAt = dateProvider()

        // 提前检查 endpoint：没接入 dashboard 的 provider 直接跳过 cookies 读取
        // （避免 SwiftCookieKit 同步阻塞导致 refresh hang）。
        guard let endpoint else {
            throw QuotaFetchError.sourceUnavailable(detail: "未接入 dashboard")
        }

        let domains = kind.dashboardCookieDomains
        let cookies: [HTTPCookie]
        do {
            // 整个 cookie 读取包 4s 硬超时，避免某些浏览器的 cookie 文件锁住 SweetCookieKit
            cookies = try await withThrowingTaskGroup(of: [HTTPCookie].self) { group in
                let hardTimeout: TimeInterval = min(4, timeout)
                group.addTask { [cookieReader, domains] in
                    try await cookieReader.readCookies(matching: domains)
                }
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(hardTimeout * 1_000_000_000))
                    throw QuotaFetchError.transient(detail: "浏览器 Cookie 读取超时（\(Int(hardTimeout))s）")
                }
                guard let first = try await group.next() else { return [] }
                group.cancelAll()
                return first
            }
        } catch let error as FilesystemCookieReader.ReaderError {
            switch error {
            case .privacyAccessDenied:
                throw QuotaFetchError.permissionRequired(detail: "读取浏览器 Cookie 需要 Full Disk Access")
            case .cookieStoreUnavailable:
                throw QuotaFetchError.sourceUnavailable(detail: "未发现已登录的浏览器")
            case .loadFailed(_, let detail):
                throw QuotaFetchError.transient(detail: detail)
            }
        }

        guard !cookies.isEmpty else {
            throw QuotaFetchError.missingCredentials(detail: "未登录")
        }

        let data = try await performRequest(with: cookies, endpoint: endpoint.url)
        if let windows = endpoint.parser.parse(data: data) {
            let tier = parsePlanType(from: data)
            return ProviderSnapshot(
                kind: kind,
                subscriptionTier: ProviderPricing.normalizedTier(tier),
                availability: .available,
                quotas: windows,
                monthlyPrice: await ProviderPricing.localizedMonthlyPrice(kind: kind, tier: tier),
                fetchedAt: fetchedAt
            )
        }
        throw QuotaFetchError.transient(detail: "无法解析 dashboard 响应")
    }

    private func parsePlanType(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json["plan_type"] as? String
    }

    private func performRequest(with cookies: [HTTPCookie], endpoint url: URL) async throws -> Data {
        // 把 cookie 拼成 `Cookie:` 请求头，比塞 HTTPCookieStorage 更可控。
        let cookieHeader = cookies
            .map { "\($0.name)=\($0.value)" }
            .joined(separator: "; ")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 QuotaBar/1.0",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw QuotaFetchError.transient(detail: "Dashboard 返回非 HTTP 响应")
        }
        switch http.statusCode {
        case 200..<300:
            return data
        case 401, 403:
            throw QuotaFetchError.missingCredentials(detail: "Cookie 已过期，请重新登录")
        default:
            throw QuotaFetchError.transient(detail: "Dashboard HTTP \(http.statusCode)")
        }
    }
}

// MARK: - ProviderKind 辅助

extension ProviderKind {
    /// 用于从浏览器 cookie 中查找 dashboard 会话的目标域。
    var dashboardCookieDomains: [String] {
        switch self {
        case .codex, .openai: return ["chatgpt.com", "openai.com"]
        case .claude: return ["claude.ai", "anthropic.com"]
        case .gemini: return ["google.com", "gemini.google.com"]
        case .minimax: return ["minimax.chat", "minimax.com"]
        case .kimi: return ["kimi.com", "kimi.moonshot.cn", "moonshot.cn"]
        case .deepseek: return ["deepseek.com", "chat.deepseek.com"]
        case .copilot: return ["github.com", "copilot.github.com"]
        case .openrouter: return ["openrouter.ai"]
        case .perplexity: return ["perplexity.ai"]
        case .cursor: return ["cursor.com", "cursor.sh"]
        default: return []
        }
    }
}
