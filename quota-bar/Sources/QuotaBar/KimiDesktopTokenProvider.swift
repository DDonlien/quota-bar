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
    private let session: URLSession
    private let dateProvider: () -> Date

    init(
        tokenStorePath: String? = nil,
        endpoint: URL = URL(string: "https://www.kimi.com/apiv2/kimi.gateway.membership.v2.MembershipService/GetSubscriptionStat")!,
        session: URLSession = .shared,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.tokenStorePath = tokenStorePath
            ?? NSHomeDirectory() + "/Library/Application Support/kimi-desktop/bridge-store/token-store.json"
        self.endpoint = endpoint
        self.session = session
        self.dateProvider = dateProvider
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let fetchedAt = dateProvider()
        let accessToken = try readAccessToken()

        var request = URLRequest(url: endpoint, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://www.kimi.com", forHTTPHeaderField: "Origin")
        request.setValue("https://www.kimi.com/", forHTTPHeaderField: "Referer")
        request.httpBody = Data("{}".utf8)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw QuotaFetchError.transient(detail: "Kimi Desktop membership 返回非 HTTP 响应")
        }
        switch http.statusCode {
        case 200..<300:
            break
        case 401, 403:
            throw QuotaFetchError.missingCredentials(detail: "Kimi Desktop token 已过期，请重新登录 Kimi")
        default:
            throw QuotaFetchError.transient(detail: "Kimi Desktop membership HTTP \(http.statusCode)")
        }

        let parser = KimiSubscriptionStatParser()
        guard let windows = parser.parse(data: data), !windows.isEmpty else {
            throw QuotaFetchError.transient(detail: "无法解析 Kimi Desktop membership 响应")
        }
        let tier = parser.parseTier(data: data)
        let monthlyPrice: String?
        if let parsedPrice = parser.parseMonthlyPrice(data: data) {
            monthlyPrice = parsedPrice
        } else {
            monthlyPrice = await ProviderPricing.localizedMonthlyPrice(kind: .kimi, tier: tier)
        }

        return ProviderSnapshot(
            kind: .kimi,
            subscriptionTier: ProviderPricing.normalizedTier(tier),
            availability: .available,
            quotas: windows,
            monthlyPrice: monthlyPrice,
            subscriptionExpiresAt: parser.parseSubscriptionExpiresAt(data: data),
            fetchedAt: fetchedAt
        )
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
}
