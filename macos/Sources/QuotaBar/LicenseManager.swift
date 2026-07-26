import Foundation

/// 授权激活与复验。
///
/// **为什么要经过自己的服务端**：Creem 的 license API 用 `x-api-key` 鉴权，那是一把
/// 能读写整个 Creem 账户的密钥，绝对不能进客户端二进制（源码还是公开的）。所以 App
/// 只跟 `quotabar.ddonlien.com/api/*` 说话，由 Vercel 那层带着密钥去调 Creem，
/// 见仓库根目录 `api/activate.mjs` / `api/validate.mjs`。
@MainActor
final class LicenseManager: ObservableObject {
    static let shared = LicenseManager()

    /// 当前授权状态。UI 和 `UpdateChecker` 的门禁都只读这个。
    @Published private(set) var state: LicenseState = .trial(daysRemaining: 7)
    /// 激活请求进行中（UI 用来禁用按钮、显示转圈）。
    @Published private(set) var isActivating = false
    /// 最近一次激活失败的原因；成功或重新输入时清空。
    @Published private(set) var lastError: String?

    private let activateURL: URL
    private let validateURL: URL
    private let session: URLSession
    private let preferences: PreferencesStore
    /// 两次复验之间的最小间隔。一次性买断产品的状态几乎不变，没必要频繁打扰服务端。
    private let revalidateInterval: TimeInterval

    init(
        activateURL: URL = URL(string: "https://quotabar.ddonlien.com/api/activate")!,
        validateURL: URL = URL(string: "https://quotabar.ddonlien.com/api/validate")!,
        session: URLSession? = nil,
        preferences: PreferencesStore = .shared,
        revalidateInterval: TimeInterval = 24 * 60 * 60
    ) {
        self.activateURL = activateURL
        self.validateURL = validateURL
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 15
            self.session = URLSession(configuration: config)
        }
        self.preferences = preferences
        self.revalidateInterval = revalidateInterval
        refreshState()
    }

    /// 重新根据本地数据计算状态。首次调用时顺带把试用起点写进偏好设置。
    func refreshState() {
        let firstLaunch = preferences.markFirstLaunchIfNeeded()
        state = LicenseEvaluator.state(
            firstLaunchAt: firstLaunch,
            license: preferences.preferences.license
        )
    }

    // MARK: 激活

    func activate(key rawKey: String) async {
        let key = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            lastError = "请输入许可证密钥"
            return
        }
        guard !isActivating else { return }

        isActivating = true
        lastError = nil
        defer { isActivating = false }

        do {
            let response = try await post(
                url: activateURL,
                body: ["key": key, "instanceName": Self.instanceName()]
            )
            guard response.ok, let instanceId = response.instanceId else {
                lastError = response.error ?? "激活失败，请检查密钥是否正确"
                return
            }
            preferences.setLicense(StoredLicense(
                key: key,
                instanceId: instanceId,
                status: response.status ?? StoredLicense.activeStatus,
                activatedAt: Date(),
                lastValidatedAt: Date(),
                expiresAt: response.expiresAt
            ))
            refreshState()
        } catch {
            lastError = "无法连接激活服务：\(error.localizedDescription)"
        }
    }

    /// 清除本地授权记录。只影响本机——不调用 Creem 的 deactivate，因为用户更常见的
    /// 意图是"这台机器不用了"而不是"退掉这个授权"，真要释放设备名额应该走 Creem 后台。
    func removeActivation() {
        preferences.setLicense(nil)
        lastError = nil
        refreshState()
    }

    // MARK: 复验

    /// 距离上次成功复验超过 `revalidateInterval` 时，跟服务端确认一次授权是否仍然有效。
    ///
    /// **fail open**：网络不通、服务端 5xx、响应无法解析——这些一律不动本地授权状态。
    /// 只有 Creem 明确回了一个非 `active` 的状态，才把本地记录降级。理由是误判的代价
    /// 完全不对等：错误地保留授权最多让一个已退款用户多用几天自动更新；错误地吊销授权
    /// 会让付了钱的用户在断网或服务端抽风时突然被降级，这是不能接受的。
    func revalidateIfDue(now: Date = Date()) async {
        guard let license = preferences.preferences.license else { return }
        if let last = license.lastValidatedAt, now.timeIntervalSince(last) < revalidateInterval {
            return
        }
        do {
            let response = try await post(
                url: validateURL,
                body: ["key": license.key, "instanceId": license.instanceId]
            )
            guard response.ok, let status = response.status else { return }  // fail open
            preferences.updateLicenseValidation(
                status: status,
                expiresAt: response.expiresAt,
                validatedAt: now
            )
            refreshState()
        } catch {
            // fail open：连不上就当这次没验过，下次启动再试。
        }
    }

    // MARK: 网络

    private struct LicenseResponse: Decodable {
        let ok: Bool
        let status: String?
        let instanceId: String?
        let expiresAt: Date?
        let error: String?
    }

    private func post(url: URL, body: [String: String]) async throws -> LicenseResponse {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        // 4xx 也带结构化 body（`{ok:false, error:"..."}`），照样解析出来把原因给用户；
        // 只有连 body 都解析不出来才当成协议级失败。
        if let decoded = try? decoder.decode(LicenseResponse.self, from: data) {
            return decoded
        }
        throw NSError(
            domain: "QuotaBar.License",
            code: http.statusCode,
            userInfo: [NSLocalizedDescriptionKey: "服务端返回了无法解析的响应（HTTP \(http.statusCode)）"]
        )
    }

    /// 提交给 Creem 的设备名。用机器名让用户在 Creem 后台能认出是哪台机器；
    /// 拿不到时退回一个稳定的占位串，不生成随机值（随机值会让同一台机器每次
    /// 重装都占掉一个新的激活名额）。
    static func instanceName() -> String {
        let name = Host.current().localizedName ?? ProcessInfo.processInfo.hostName
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Unknown Mac" : trimmed
    }
}
