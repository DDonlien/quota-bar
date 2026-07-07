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

        // 整体包裹 timeout：cookie 读取 + 网络请求都不应超过传入的 timeout，
        // 避免某个同步 I/O hang 住导致 pipeline 长时间无法 fallback。
        return try await withThrowingTaskGroup(of: ProviderSnapshot.self) { group in
            group.addTask { [weak self] in
                guard let self else {
                    throw QuotaFetchError.sourceUnavailable(detail: "Provider 已释放")
                }
                return try await self.fetchSnapshotImpl(endpoint: endpoint, fetchedAt: fetchedAt, timeout: timeout)
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw QuotaFetchError.transient(detail: "浏览器 Cookie dashboard 超时（\(Int(timeout))s）")
            }
            guard let first = try await group.next() else {
                throw QuotaFetchError.sourceUnavailable(detail: "浏览器 Cookie 任务为空")
            }
            group.cancelAll()
            return first
        }
    }

    private func fetchSnapshotImpl(endpoint: DashboardEndpoints.Endpoint, fetchedAt: Date, timeout: TimeInterval) async throws -> ProviderSnapshot {
        // v0.8.0 + v0.8.1 修订：Codex 路径**不再**在 BrowserCookie 入口短路订阅过期。
        // 原因：inspector 数据来自 ~/.codex/auth.json 的 id_token（陈旧缓存）——用户 web 续费后
        // 该字段可能滞后。如果 BrowserCookie 也按 inspector 短路，就完全拿不到真实 quota。
        // 现在 CodexAuthProvider 在 inspector 过期时 throw `.subscriptionExpired`，
        // pipeline 会走到这里直接调 dashboard API；plan_type=free 时由 CodexDashboardParser
        // 在解析层 return nil（不渲染免费档的"月额度"窗口）。
        // —— Inspector 仍由 CodexAuthProvider 调一次（"权威"端），此处 BrowserCookie 信任 API。

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
        NSLog("QuotaBar: [\(kind.rawValue)-cookie] got \(cookies.count) cookies")

        // Kimi：并行请求 GetSubscription（档位/价格）和 GetSubscriptionStat（额度），
        // 避免串行导致整体超时。
        if kind == .kimi {
            return try await fetchKimiSnapshot(
                cookies: cookies,
                quotaEndpoint: endpoint,
                fetchedAt: fetchedAt
            )
        }

        let initialData = try await performRequest(with: cookies, endpoint: endpoint)
        let data: Data
        if let followUpURL = endpoint.followUpURL?(initialData) {
            let followUp = DashboardEndpoints.Endpoint(url: followUpURL, parser: endpoint.parser)
            data = try await performRequest(with: cookies, endpoint: followUp)
        } else {
            data = initialData
        }

        NSLog("QuotaBar: [\(kind.rawValue)-cookie] dashboard raw (first 800): \(String(data: data.prefix(800), encoding: .utf8) ?? "<nil>")")

        guard let windows = endpoint.parser.parse(data: data) else {
            NSLog("QuotaBar: [\(kind.rawValue)-cookie] parser returned nil")
            throw QuotaFetchError.transient(detail: "无法解析 dashboard 响应")
        }
        NSLog("QuotaBar: [\(kind.rawValue)-cookie] parsed windows: \(windows.map { "\($0.title): \(Int($0.remainingFraction*100))%" }.joined(separator: ", "))")
        let tier = endpoint.parser.parseTier(data: data) ?? parsePlanType(from: data)
        let monthlyPrice: String?
        if let parsedPrice = endpoint.parser.parseMonthlyPrice(data: data) {
            monthlyPrice = parsedPrice
        } else {
            monthlyPrice = await ProviderPricing.localizedMonthlyPrice(kind: kind, tier: tier)
        }
        NSLog("QuotaBar: [\(kind.rawValue)-cookie] final tier=\(tier ?? "<nil>"), price=\(monthlyPrice ?? "<nil>")")
        // v0.6.0：parser 显式提供订阅到期日（Kimi 的 KimiSubscriptionStatParser 从
        // subscriptionBalance.expireTime 取）；其他 parser 默认返回 nil（UI hide）。
        let subscriptionExpiresAt = endpoint.parser.parseSubscriptionExpiresAt(data: data)
        return ProviderSnapshot(
            kind: kind,
            subscriptionTier: ProviderPricing.normalizedTier(tier),
            availability: .available,
            quotas: windows,
            monthlyPrice: monthlyPrice,
            subscriptionExpiresAt: subscriptionExpiresAt,
            fetchedAt: fetchedAt
        )
    }

    /// Kimi 专用。2026-07 起服务端下线 `GetSubscriptionStat`（404），主请求切到
    /// `GetSubscription`：一个响应同时给 Work 月额度（balances[]）、档位、价格和
    /// 续费日；旧 stat 端点保留为可选兼容路径（个别账号可能仍在返回）。
    /// Code 5h/周额度由管线里的 CLI OAuth 分层合并补齐。
    private func fetchKimiSnapshot(
        cookies: [HTTPCookie],
        quotaEndpoint: DashboardEndpoints.Endpoint,
        fetchedAt: Date
    ) async throws -> ProviderSnapshot {
        let subscriptionParser = KimiSubscriptionParser()
        let subscriptionEndpoint = DashboardEndpoints.Endpoint(
            url: URL(string: "https://www.kimi.com/apiv2/kimi.gateway.membership.v2.MembershipService/GetSubscription")!,
            method: "POST",
            body: Data("{}".utf8),
            headers: [
                "Content-Type": "application/json",
                "Origin": "https://www.kimi.com",
                "Referer": "https://www.kimi.com/"
            ],
            parser: subscriptionParser,
            bearerTokenCookieName: "kimi-auth"
        )

        // 主请求：GetSubscription（Work 额度 + 档位 + 价格 + 续费日）。
        let subscriptionData = try? await performRequest(with: cookies, endpoint: subscriptionEndpoint)
        var windows = subscriptionData.flatMap { subscriptionParser.parse(data: $0) } ?? []

        // 兼容路径：主请求拿不到额度时再试旧 stat 端点（含 Work + Code）。
        var statData: Data?
        if windows.isEmpty {
            statData = await fetchOptionalKimiSubscriptionData(
                cookies: cookies,
                endpoint: quotaEndpoint,
                timeout: 3
            )
            if let statData, let statWindows = quotaEndpoint.parser.parse(data: statData) {
                windows = statWindows
            }
        }
        guard !windows.isEmpty else {
            NSLog("QuotaBar: [kimi-cookie] GetSubscription/GetSubscriptionStat 均未产出额度")
            throw QuotaFetchError.transient(detail: "无法解析 Kimi dashboard 响应")
        }
        NSLog("QuotaBar: [kimi-cookie] parsed windows: \(windows.map { "\($0.title): \(Int($0.remainingFraction*100))%" }.joined(separator: ", "))")

        // 档位 / 价格 / 续费日全部来自 GetSubscription；stat 只在兼容路径下兜底 tier。
        let tier = subscriptionData.flatMap { subscriptionParser.parseTier(data: $0) }
            ?? statData.flatMap { quotaEndpoint.parser.parseTier(data: $0) }
        let monthlyPrice: String?
        if let subscriptionData,
           let parsedPrice = subscriptionParser.parseMonthlyPrice(data: subscriptionData) {
            monthlyPrice = parsedPrice
        } else {
            monthlyPrice = await ProviderPricing.localizedMonthlyPrice(kind: .kimi, tier: tier)
        }
        // Kimi 的展示日期来自 GetSubscription.nextBillingTime（下一次续费日）
        // 转换出的最后有效日；stat 的 expireTime/currentEndTime 不直接展示。
        let subscriptionExpiresAt = subscriptionData.flatMap {
            subscriptionParser.parseSubscriptionExpiresAt(data: $0)
        }
        NSLog("QuotaBar: [kimi-cookie] final tier=\(tier ?? "<nil>"), price=\(monthlyPrice ?? "<nil>"), expiresAt=\(subscriptionExpiresAt?.description ?? "<nil>")")
        return ProviderSnapshot(
            kind: .kimi,
            subscriptionTier: ProviderPricing.normalizedTier(tier),
            availability: .available,
            quotas: windows,
            monthlyPrice: monthlyPrice,
            subscriptionExpiresAt: subscriptionExpiresAt,
            subscriptionExpiresAtSource: subscriptionExpiresAt != nil ? .browserAPI : nil,
            subscriptionExpiresAtConfidence: subscriptionExpiresAt != nil ? .high : nil,
            fetchedAt: fetchedAt
        )
    }

    private func fetchOptionalKimiSubscriptionData(
        cookies: [HTTPCookie],
        endpoint: DashboardEndpoints.Endpoint,
        timeout: TimeInterval
    ) async -> Data? {
        await withTaskGroup(of: Data?.self) { group in
            group.addTask {
                do {
                    return try await self.performRequest(with: cookies, endpoint: endpoint)
                } catch {
                    NSLog("QuotaBar: [kimi-cookie] GetSubscription failed: \(error)")
                    return nil
                }
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                NSLog("QuotaBar: [kimi-cookie] GetSubscription skipped after optional timeout")
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }

    private func parsePlanType(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        // 顶层字段
        if let plan = json["plan_type"] as? String
            ?? json["planType"] as? String
            ?? json["plan"] as? String
            ?? json["tier"] as? String
            ?? json["subscription"] as? String,
           !plan.isEmpty {
            return plan
        }
        // 嵌套字段
        if let account = json["account"] as? [String: Any] {
            return account["plan_type"] as? String
                ?? account["planType"] as? String
                ?? account["plan"] as? String
                ?? account["tier"] as? String
        }
        if let user = json["user"] as? [String: Any] {
            return user["plan_type"] as? String
                ?? user["planType"] as? String
                ?? user["plan"] as? String
                ?? user["tier"] as? String
        }
        return nil
    }

    private func performRequest(with cookies: [HTTPCookie], endpoint: DashboardEndpoints.Endpoint) async throws -> Data {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = endpoint.method
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 QuotaBar/1.0",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Kimi 等 provider 把 auth token 放在 cookie 中，但 API 要求 Bearer 认证
        if let bearerCookieName = endpoint.bearerTokenCookieName,
           let bearerCookie = cookies.first(where: { $0.name == bearerCookieName }) {
            request.setValue("Bearer \(bearerCookie.value)", forHTTPHeaderField: "Authorization")
            // 仍然保留 Cookie header，因为某些接口可能同时需要
            let cookieHeader = cookies
                .map { "\($0.name)=\($0.value)" }
                .joined(separator: "; ")
            request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        } else {
            let cookieHeader = cookies
                .map { "\($0.name)=\($0.value)" }
                .joined(separator: "; ")
            request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        }

        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = endpoint.body
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
