import Foundation

/// Codex OAuth (`auth.json`) 数据源。
///
/// 参考 CodexBar 的 Codex OAuth 路径：
/// 1. 读 `~/.codex/auth.json`（或 `$CODEX_HOME/auth.json`）；
/// 2. 调 `GET https://chatgpt.com/backend-api/wham/usage`；
/// 3. Header: `Authorization: Bearer <access_token>` 和可选 `ChatGPT-Account-Id`；
/// 4. 解析 `primary_window` / `secondary_window` 或新 schema 的 `five_hour` / `weekly`。
final class CodexAuthProvider: QuotaProvider, @unchecked Sendable {

    let id = "codex-auth"
    let kind: ProviderKind = .codex
    var displayName: String { kind.displayName }

    private let authPath: String
    private let endpoint: URL
    private let session: URLSession
    private let dateProvider: () -> Date
    /// v0.8.0：订阅状态检查器——从 auth.json 的 id_token 读 `chatgpt_subscription_active_until`。
    /// 见 `SubscriptionInspector.swift` 顶部说明。
    private let inspector: CodexSubscriptionInspector

    init(
        authPath: String? = nil,
        endpoint: URL = URL(string: "https://chatgpt.com/backend-api/wham/usage")!,
        session: URLSession = .shared,
        dateProvider: @escaping () -> Date = Date.init,
        inspector: CodexSubscriptionInspector? = nil
    ) {
        if let authPath {
            self.authPath = authPath
        } else {
            let codexHome = ProcessInfo.processInfo.environment["CODEX_HOME"]
                ?? NSHomeDirectory() + "/.codex"
            self.authPath = codexHome + "/auth.json"
        }
        self.endpoint = endpoint
        self.session = session
        self.dateProvider = dateProvider
        // 默认用同一个 authPath 构造 inspector；测试可注入自定义
        self.inspector = inspector ?? CodexSubscriptionInspector(authPath: self.authPath, dateProvider: dateProvider)
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let fetchedAt = dateProvider()

        // v0.8.0：先用 CodexSubscriptionInspector 检查订阅状态（"权威 > API 反推"模型）。
        // - 订阅已过期 / 已跌成 free → **返回** availability=.subscriptionExpired 的 marker
        //   snapshot（不是 throw！），让 pipeline 立即返回，**不**让后续 BrowserCookie / CLILog
        //   strategy 用 free 用户的"月额度" primary_window 覆盖掉正确状态
        // - .active / .unknown → 继续走原流程，让 wham/usage 拿真实 quota
        // 失败读不到 auth.json 时跳过检查（保持向后兼容：旧用户/CLI 模式 → 走原路径）
        let subscriptionStatus = inspector.inspect()
        if subscriptionStatus.isEffectivelyExpired {
            let (plan, expiredAt) = Self.extractExpiry(from: subscriptionStatus)
            return ProviderSnapshot(
                kind: .codex,
                subscriptionTier: ProviderPricing.normalizedTier(plan),
                availability: .subscriptionExpired(plan: plan, expiredAt: expiredAt),
                quotas: [],
                monthlyPrice: nil,
                fetchedAt: fetchedAt
            )
        }

        guard let creds = loadCredentials() else {
            throw QuotaFetchError.missingCredentials(detail: "未找到 ~/.codex/auth.json")
        }
        guard !creds.accessToken.isEmpty else {
            throw QuotaFetchError.missingCredentials(detail: "auth.json 缺少 access_token")
        }

        var request = URLRequest(url: endpoint, timeoutInterval: timeout)
        request.httpMethod = "GET"
        request.setValue("Bearer \(creds.accessToken)", forHTTPHeaderField: "Authorization")
        if let accountId = creds.accountId, !accountId.isEmpty {
            request.setValue(accountId, forHTTPHeaderField: "ChatGPT-Account-Id")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 QuotaBar/1.0",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw QuotaFetchError.transient(detail: "wham/usage 返回非 HTTP 响应")
        }
        switch http.statusCode {
        case 200..<300:
            break
        case 401, 403:
            throw QuotaFetchError.missingCredentials(detail: "OAuth token 已过期，请重新 codex login")
        default:
            throw QuotaFetchError.transient(detail: "wham/usage HTTP \(http.statusCode)")
        }

        let parser = CodexDashboardParser()
        guard let windows = parser.parse(data: data), !windows.isEmpty else {
            throw QuotaFetchError.transient(detail: "无法解析 Codex usage 响应")
        }
        let tier = parsePlanType(from: data)

        return ProviderSnapshot(
            kind: .codex,
            subscriptionTier: ProviderPricing.normalizedTier(tier),
            availability: .available,
            quotas: windows,
            monthlyPrice: await ProviderPricing.localizedMonthlyPrice(kind: .codex, tier: tier),
            fetchedAt: fetchedAt
        )
    }

    /// 从 `SubscriptionStatus` 中提取 `(plan, expiredAt)` 给错误用。
    private static func extractExpiry(from status: SubscriptionStatus) -> (String?, Date?) {
        switch status {
        case .expired(let lastPlan, let expiredAt):
            return (lastPlan, expiredAt)
        case .free:
            // free 状态：planType 是 "free"（OpenAI 自己标），但 lastPlan 历史 plan 是 nil
            return (nil, nil)
        case .active, .unknown:
            return (nil, nil)
        }
    }

    private struct Credentials {
        let accessToken: String
        let accountId: String?
    }

    private func loadCredentials() -> Credentials? {
        let url = URL(fileURLWithPath: authPath)
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        guard let tokens = json["tokens"] as? [String: Any] else { return nil }
        let accessToken = (tokens["access_token"] as? String)
            ?? (tokens["accessToken"] as? String)
            ?? ""
        guard !accessToken.isEmpty else { return nil }
        let accountId = (tokens["account_id"] as? String) ?? (tokens["accountId"] as? String)

        return Credentials(accessToken: accessToken, accountId: accountId)
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
}
