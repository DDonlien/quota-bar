import Foundation

/// Kimi Desktop App token 数据源。
///
/// Kimi CLI OAuth (`~/.kimi-code`) 只能返回 Code 额度；Kimi 桌面 App 会在
/// `~/Library/Application Support/kimi-desktop/bridge-store/token-store.json`
/// 保存 Web access token。该 token 可直接调用 membership API，拿到 Work 月额度、
/// Code 5h/周额度、订阅档位和到期日，且不需要读取浏览器 Cookie 或触发浏览器 Keychain 弹窗。
final class KimiDesktopTokenProvider: QuotaProvider, @unchecked Sendable {
    let id = "kimi-desktop-token"
    let kind: ProviderKind = .kimi
    var displayName: String { kind.displayName }

    private let tokenStorePath: String
    private let endpoint: URL
    private let subscriptionEndpoint: URL
    private let session: URLSession
    private let dateProvider: () -> Date

    init(
        tokenStorePath: String? = nil,
        endpoint: URL = URL(string: "https://www.kimi.com/apiv2/kimi.gateway.membership.v2.MembershipService/GetSubscriptionStat")!,
        subscriptionEndpoint: URL = URL(string: "https://www.kimi.com/apiv2/kimi.gateway.membership.v2.MembershipService/GetSubscription")!,
        session: URLSession = .shared,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.tokenStorePath = tokenStorePath
            ?? NSHomeDirectory() + "/Library/Application Support/kimi-desktop/bridge-store/token-store.json"
        self.endpoint = endpoint
        self.subscriptionEndpoint = subscriptionEndpoint
        self.session = session
        self.dateProvider = dateProvider
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let fetchedAt = dateProvider()
        let accessToken = try readAccessToken()

        let data = try await performMembershipRequest(
            url: endpoint,
            accessToken: accessToken,
            timeout: timeout
        )

        let parser = KimiSubscriptionStatParser()
        guard let windows = parser.parse(data: data), !windows.isEmpty else {
            throw QuotaFetchError.transient(detail: "无法解析 Kimi Desktop membership 响应")
        }

        let subscriptionData = await fetchOptionalSubscriptionData(
            accessToken: accessToken,
            timeout: min(1.5, timeout)
        )
        let subscriptionParser = KimiSubscriptionParser()
        let tier = subscriptionData.flatMap { subscriptionParser.parseTier(data: $0) }
            ?? parser.parseTier(data: data)
            ?? tierFromTokenStore()
        let monthlyPrice: String?
        if let subscriptionData,
           let parsedPrice = subscriptionParser.parseMonthlyPrice(data: subscriptionData) {
            monthlyPrice = parsedPrice
        } else if let parsedPrice = parser.parseMonthlyPrice(data: data) {
            monthlyPrice = parsedPrice
        } else {
            monthlyPrice = await ProviderPricing.localizedMonthlyPrice(kind: .kimi, tier: tier)
        }
        let subscriptionExpiresAt = subscriptionData.flatMap {
            subscriptionParser.parseSubscriptionExpiresAt(data: $0)
        }

        return ProviderSnapshot(
            kind: .kimi,
            subscriptionTier: ProviderPricing.normalizedTier(tier),
            availability: .available,
            quotas: windows,
            monthlyPrice: monthlyPrice,
            subscriptionExpiresAt: subscriptionExpiresAt,
            fetchedAt: fetchedAt
        )
    }

    private func performMembershipRequest(
        url: URL,
        accessToken: String,
        timeout: TimeInterval
    ) async throws -> Data {
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("kimi-auth=\(accessToken)", forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://www.kimi.com", forHTTPHeaderField: "Origin")
        request.setValue("https://www.kimi.com/code/console", forHTTPHeaderField: "Referer")
        request.setValue("1", forHTTPHeaderField: "connect-protocol-version")
        request.setValue("web", forHTTPHeaderField: "x-msh-platform")
        request.setValue("zh-CN", forHTTPHeaderField: "x-language")
        request.setValue(TimeZone.current.identifier, forHTTPHeaderField: "r-timezone")
        request.httpBody = Data("{}".utf8)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw QuotaFetchError.transient(detail: "Kimi Desktop membership 返回非 HTTP 响应")
        }
        switch http.statusCode {
        case 200..<300:
            return data
        case 401, 403:
            throw QuotaFetchError.missingCredentials(detail: "Kimi Desktop token 已过期，请重新登录 Kimi")
        default:
            throw QuotaFetchError.transient(detail: "Kimi Desktop membership HTTP \(http.statusCode)")
        }
    }

    private func fetchOptionalSubscriptionData(
        accessToken: String,
        timeout: TimeInterval
    ) async -> Data? {
        do {
            return try await performMembershipRequest(
                url: subscriptionEndpoint,
                accessToken: accessToken,
                timeout: timeout
            )
        } catch {
            NSLog("QuotaBar: [kimi-desktop-token] GetSubscription failed: \(error)")
            return nil
        }
    }

    private func readAccessToken() throws -> String {
        let url = URL(fileURLWithPath: tokenStorePath)
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tokens = json["tokens"] as? [String: Any],
              let accessToken = tokens["access_token"] as? String,
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw QuotaFetchError.missingCredentials(detail: "未找到 Kimi Desktop token")
        }
        return accessToken
    }

    private func tierFromTokenStore() -> String? {
        let url = URL(fileURLWithPath: tokenStorePath)
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tokens = json["tokens"] as? [String: Any],
              let raw = tokens["msh_user_subscription_data"] as? String,
              let rawData = raw.data(using: .utf8),
              let subscription = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any] else {
            return nil
        }
        if let title = subscription["title"] as? String,
           !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return title
        }
        if let level = (subscription["currentMembershipLevel"] as? NSNumber)?.intValue {
            return Self.membershipLevelName(level)
        }
        return nil
    }

    private static func membershipLevelName(_ level: Int) -> String? {
        // Kimi Desktop 本地缓存只有 numeric level 时，用作最后兜底。
        // 实测 currentMembershipLevel=15 对应最低付费档，价格映射为 Andante。
        switch level {
        case 15: return "Andante"
        default: return nil
        }
    }
}
