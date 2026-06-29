import Foundation

// MARK: - JWT Payload Decoder

/// OpenAI / Codex 的 `id_token` 是个 RS256 签名的 JWT，本工具**只读 payload**（不验签），
/// 用于从 `https://api.openai.com/auth` 命名空间下提取订阅元信息：
/// - `chatgpt_plan_type`（"plus" / "pro" / "free" / "team" / "enterprise"）
/// - `chatgpt_subscription_active_start`（ISO 8601 字符串）
/// - `chatgpt_subscription_active_until`（ISO 8601 字符串）
/// - `chatgpt_subscription_last_checked`（ISO 8601 字符串）
///
/// 这些字段是 OpenAI 在签发 id_token 时塞进去的——**不依赖网络请求**，是订阅状态
/// 的最权威本地来源（"权威 > API 反推"原则，见 v0.8.0 phase 顶层说明）。
///
/// 不做签名验证：
/// 1. 应用本身已经持有 id_token 完整字符串，签名验证通常需要后端 JWKS；
/// 2. 即便伪造也只能误导本机 UI（攻击者本来就已经在本机 root）；
/// 3. ChatGPT 后端在每次 API 调用时仍会用签名验证 token 本身。
///
/// 失败返回 `nil`：id_token 格式坏、payload 不是合法 JSON、namespace 不存在、字段缺失
/// 等情况都静默返回 nil。调用方应该把 nil 当作"不知道"，**不要**用 nil 反推任何结论。
enum JWTPayloadDecoder {

    /// 解码 JWT 的 payload 部分（中间那段的 base64url），返回原始字典。
    /// 失败（结构 / base64 / JSON 解析）返回 nil。
    static func decode(_ token: String) -> [String: Any]? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }

        let payloadSegment = String(parts[1])
        guard let payloadData = base64URLDecode(payloadSegment) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            return nil
        }
        return json
    }

    /// 读 `https://api.openai.com/auth` 命名空间下的字段并组装成 `OpenAIAuthPayload`。
    /// 任意字段缺失或解析失败都返回 nil。
    static func openAIAuthPayload(_ token: String) -> OpenAIAuthPayload? {
        guard let json = decode(token),
              let auth = json["https://api.openai.com/auth"] as? [String: Any]
        else { return nil }
        return OpenAIAuthPayload(auth: auth)
    }

    private static func base64URLDecode(_ string: String) -> Data? {
        var s = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        // 补齐 base64 长度对齐
        let padding = (4 - s.count % 4) % 4
        s.append(String(repeating: "=", count: padding))
        return Data(base64Encoded: s)
    }
}

// MARK: - OpenAI Auth Payload

/// 解析后的 `https://api.openai.com/auth` 字段，封装为 Swift 类型。
/// 所有时间都是**绝对 UTC**（OpenAI 用 ISO 8601 字符串）。
struct OpenAIAuthPayload {
    let planType: String?
    let subscriptionActiveStart: Date?
    let subscriptionActiveUntil: Date?
    let subscriptionLastChecked: Date?
    let accountId: String?
    let userId: String?

    init?(auth: [String: Any]) {
        self.planType = auth["chatgpt_plan_type"] as? String
        self.subscriptionActiveStart = Self.parseISODate(auth["chatgpt_subscription_active_start"])
        self.subscriptionActiveUntil = Self.parseISODate(auth["chatgpt_subscription_active_until"])
        self.subscriptionLastChecked = Self.parseISODate(auth["chatgpt_subscription_last_checked"])
        self.accountId = auth["chatgpt_account_id"] as? String
        self.userId = auth["chatgpt_user_id"] as? String
    }

    private static func parseISODate(_ raw: Any?) -> Date? {
        guard let s = raw as? String else { return nil }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = withFraction.date(from: s) { return d }
        let withoutFraction = ISO8601DateFormatter()
        withoutFraction.formatOptions = [.withInternetDateTime]
        return withoutFraction.date(from: s)
    }
}

// MARK: - Subscription Status

/// 订阅状态：3 种核心值 + 1 个 unknown。
///
/// 这是"权威 > API 反推"模型的核心数据结构：
/// - **.active(expiresAt)**：订阅有效，已知到期日
/// - **.expired(lastPlan, expiredAt)**：订阅已过期，知道上次是什么套餐 / 何时过期
/// - **.free**：账号存在但没付费订阅（免费用户）
/// - **.unknown**：拿不到权威信息（id_token 缺失 / parser 失败 / 离线等），UI 退回到只看 quota
enum SubscriptionStatus: Hashable, Sendable {
    case active(expiresAt: Date?)
    case expired(lastPlan: String?, expiredAt: Date?)
    case free
    case unknown

    /// 是否处于"已过期 / 降级"状态——
    /// 任何导致 quota 不应该被信任为付费档位的情况都返回 true。
    var isEffectivelyExpired: Bool {
        switch self {
        case .expired: return true
        case .free: return true
        case .active: return false
        case .unknown: return false
        }
    }
}

// MARK: - Codex Subscription Inspector

/// Codex 订阅状态检查器：从 `~/.codex/auth.json` 的 id_token 读 OpenAI 提供的
/// 订阅元信息。**不依赖网络**——auth.json 是 Codex.app 自己在登录时写下来的本地文件。
///
/// 这是 v0.8.0 phase 选定的"权威"数据源（按 user 提的 ".app 授权信息 > CLI > Web 抓取"
/// 优先级）：
/// - Plus 订阅过期时，OpenAI 在 `id_token` 的 `chatgpt_subscription_active_until` 标了
///   过期时间（`auth.json` 不需要网络就能读）。
/// - 比"调 wham/usage 看 plan_type=free"更可靠：网络不可达 / API 改 schema / 401 时仍然有效。
/// - 比 CLILogProvider 的"5h/weekly 用完"反推更准确：CLILog 永远不知道订阅本身的状态。
struct CodexSubscriptionInspector {

    enum InspectorError: LocalizedError {
        case authFileMissing(path: String)
        case authFileMalformed(detail: String)
        case idTokenMissing
        case idTokenMalformed

        var errorDescription: String? {
            switch self {
            case .authFileMissing(let path):
                return "auth.json 不存在（\(path)）"
            case .authFileMalformed(let detail):
                return "auth.json 解析失败：\(detail)"
            case .idTokenMissing:
                return "auth.json 缺少 id_token"
            case .idTokenMalformed:
                return "id_token 不是合法 JWT"
            }
        }
    }

    let authPath: String
    let dateProvider: () -> Date

    init(
        authPath: String? = nil,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        if let authPath {
            self.authPath = authPath
        } else {
            let codexHome = ProcessInfo.processInfo.environment["CODEX_HOME"]
                ?? NSHomeDirectory() + "/.codex"
            self.authPath = codexHome + "/auth.json"
        }
        self.dateProvider = dateProvider
    }

    /// 读 `auth.json` 解析 id_token，返回 `SubscriptionStatus`。
    /// 失败（文件缺失 / JSON 坏 / id_token 缺失 / 字段缺失）返回 `.unknown`，
    /// 不抛错——调用方应该把"读不到"安全降级到"调 API 反推"。
    func inspect() -> SubscriptionStatus {
        let now = dateProvider()
        guard let payload = loadPayload() else { return .unknown }
        return Self.status(from: payload, now: now)
    }

    /// 同步抛错版（测试用）：失败时抛 `InspectorError`，成功返回 `SubscriptionStatus`。
    func inspectStrict() throws -> SubscriptionStatus {
        let now = dateProvider()
        let payload = try loadPayloadStrict()
        return Self.status(from: payload, now: now)
    }

    // MARK: - Static helpers

    /// 把 OpenAI 提供的元数据组装成 `SubscriptionStatus`。
    /// 规则（按权威度排序）：
    /// 1. `plan_type == "free"` → `.free`（OpenAI 自己的判断，最高权威）
    /// 2. `subscription_active_until < now` → `.expired(lastPlan: planType, expiredAt: ...)`
    /// 3. `subscription_active_until >= now` → `.active(expiresAt: ...)`
    /// 4. 字段缺失 → `.unknown`
    static func status(from payload: OpenAIAuthPayload, now: Date) -> SubscriptionStatus {
        if let planType = payload.planType, planType.lowercased() == "free" {
            return .free
        }
        if let activeUntil = payload.subscriptionActiveUntil {
            if activeUntil < now {
                return .expired(lastPlan: payload.planType, expiredAt: activeUntil)
            }
            return .active(expiresAt: activeUntil)
        }
        // 没拿到到期日：返回 unknown，但带 planType 让 UI 知道上次是什么套餐
        return .unknown
    }

    // MARK: - Private

    private func loadPayload() -> OpenAIAuthPayload? {
        let url = URL(fileURLWithPath: authPath)
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tokens = json["tokens"] as? [String: Any],
              let idToken = tokens["id_token"] as? String
        else { return nil }
        return JWTPayloadDecoder.openAIAuthPayload(idToken)
    }

    private func loadPayloadStrict() throws -> OpenAIAuthPayload {
        let url = URL(fileURLWithPath: authPath)
        guard FileManager.default.fileExists(atPath: authPath) else {
            throw InspectorError.authFileMissing(path: authPath)
        }
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw InspectorError.authFileMalformed(detail: "auth.json 不是合法 JSON")
        }
        guard let tokens = json["tokens"] as? [String: Any],
              let idToken = tokens["id_token"] as? String,
              !idToken.isEmpty
        else {
            throw InspectorError.idTokenMissing
        }
        guard let payload = JWTPayloadDecoder.openAIAuthPayload(idToken) else {
            throw InspectorError.idTokenMalformed
        }
        return payload
    }
}
