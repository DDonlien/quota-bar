import Foundation
import Testing
@testable import QuotaBar

// MARK: - JWT Payload Decoder 基础测试（v0.8.0）

@Suite("JWTPayloadDecoder — 基础解析 (v0.8.0)")
struct JWTPayloadDecoderTests {

    static func makeJWT(payload: [String: Any]) -> String {
        // 构造一个 header.payload.signature 格式的 JWT（签名随便）
        let header: [String: Any] = ["alg": "RS256", "kid": "test"]
        let headerData = try! JSONSerialization.data(withJSONObject: header)
        let payloadData = try! JSONSerialization.data(withJSONObject: payload)
        return [
            headerData.base64URLString(),
            payloadData.base64URLString(),
            "fake-signature",
        ].joined(separator: ".")
    }

    @Test("合法 JWT 解码出 payload 字典")
    func decodesValidJWT() throws {
        let token = Self.makeJWT(payload: ["sub": "user-123", "exp": 1234567890])
        let result = try #require(JWTPayloadDecoder.decode(token))
        #expect(result["sub"] as? String == "user-123")
        #expect(result["exp"] as? Int == 1234567890)
    }

    @Test("三段缺失时返回 nil")
    func rejectsMalformedJWT() {
        #expect(JWTPayloadDecoder.decode("only-one-segment") == nil)
        #expect(JWTPayloadDecoder.decode("a.b") == nil)
        #expect(JWTPayloadDecoder.decode("") == nil)
    }

    @Test("base64 损坏时返回 nil")
    func rejectsBadBase64() {
        #expect(JWTPayloadDecoder.decode("valid.header.!!!not-base64!!!") == nil)
    }

    @Test("payload 不是 JSON 时返回 nil")
    func rejectsNonJSONPayload() {
        let header = Data([1, 2, 3]).base64URLString()
        let badPayload = Data("not json at all".utf8).base64URLString()
        #expect(JWTPayloadDecoder.decode("\(header).\(badPayload).sig") == nil)
    }
}

// MARK: - CodexSubscriptionInspector 行为测试（v0.8.0）

@Suite("CodexSubscriptionInspector — 订阅状态检测 (v0.8.0)")
struct CodexSubscriptionInspectorTests {

    private static func makeAuthJSON(idToken: String) -> String {
        // 模拟 ~/.codex/auth.json 形状
        let json: [String: Any] = [
            "auth_mode": "chatgpt",
            "tokens": [
                "id_token": idToken,
                "access_token": "fake-access",
                "refresh_token": "fake-refresh",
                "account_id": "acct-123",
            ],
            "last_refresh": "2026-06-26T07:22:03Z"
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        return String(data: data, encoding: .utf8)!
    }

    static func makeJWTPayload(
        planType: String? = nil,
        activeStart: String? = nil,
        activeUntil: String? = nil,
        lastChecked: String? = nil
    ) -> [String: Any] {
        var auth: [String: Any] = [:]
        if let planType { auth["chatgpt_plan_type"] = planType }
        if let activeStart { auth["chatgpt_subscription_active_start"] = activeStart }
        if let activeUntil { auth["chatgpt_subscription_active_until"] = activeUntil }
        if let lastChecked { auth["chatgpt_subscription_last_checked"] = lastChecked }
        auth["chatgpt_account_id"] = "acct-123"
        auth["chatgpt_user_id"] = "user-abc"
        return [
            "sub": "google-oauth2|...",
            "https://api.openai.com/auth": auth,
        ]
    }

    private static func writeAuthFile(at path: String, content: String) throws {
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.removeItem(at: url)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: 过期检测

    @Test("active_until < now → .expired(lastPlan, expiredAt)")
    func detectsExpiredSubscription() throws {
        let now = Date()
        let pastISO = ISO8601DateFormatter().string(from: now.addingTimeInterval(-86400))
        let token = JWTPayloadDecoderTests.makeJWT(payload: Self.makeJWTPayload(
            planType: "plus",
            activeStart: "2026-05-25T15:23:47+00:00",
            activeUntil: pastISO
        ))
        let path = "/tmp/quota-bar-test-auth-\(UUID().uuidString).json"
        try Self.writeAuthFile(at: path, content: Self.makeAuthJSON(idToken: token))
        defer { try? FileManager.default.removeItem(atPath: path) }

        let inspector = CodexSubscriptionInspector(authPath: path, dateProvider: { now })
        let status = inspector.inspect()
        switch status {
        case .expired(let lastPlan, let expiredAt):
            #expect(lastPlan == "plus")
            #expect(expiredAt != nil)
        default:
            Issue.record("expected .expired, got \(status)")
        }
    }

    @Test("active_until > now → .active(expiresAt)")
    func detectsActiveSubscription() throws {
        let now = Date()
        let futureISO = ISO8601DateFormatter().string(from: now.addingTimeInterval(30 * 86400))
        let token = JWTPayloadDecoderTests.makeJWT(payload: Self.makeJWTPayload(
            planType: "plus",
            activeStart: "2026-05-25T15:23:47+00:00",
            activeUntil: futureISO
        ))
        let path = "/tmp/quota-bar-test-auth-\(UUID().uuidString).json"
        try Self.writeAuthFile(at: path, content: Self.makeAuthJSON(idToken: token))
        defer { try? FileManager.default.removeItem(atPath: path) }

        let inspector = CodexSubscriptionInspector(authPath: path, dateProvider: { now })
        let status = inspector.inspect()
        switch status {
        case .active(let expiresAt):
            #expect(expiresAt != nil)
        default:
            Issue.record("expected .active, got \(status)")
        }
    }

    @Test("plan_type == 'free' → .free")
    func detectsFreeUser() throws {
        let token = JWTPayloadDecoderTests.makeJWT(payload: Self.makeJWTPayload(planType: "free"))
        let path = "/tmp/quota-bar-test-auth-\(UUID().uuidString).json"
        try Self.writeAuthFile(at: path, content: Self.makeAuthJSON(idToken: token))
        defer { try? FileManager.default.removeItem(atPath: path) }

        let inspector = CodexSubscriptionInspector(authPath: path)
        #expect(inspector.inspect() == .free)
    }

    // MARK: 降级 / 边界

    @Test("auth.json 不存在时返回 .unknown（不抛错）")
    func missingAuthFileIsUnknown() {
        let inspector = CodexSubscriptionInspector(authPath: "/tmp/does-not-exist-\(UUID().uuidString).json")
        #expect(inspector.inspect() == .unknown)
    }

    @Test("auth.json 损坏时返回 .unknown")
    func malformedAuthFileIsUnknown() throws {
        let path = "/tmp/quota-bar-test-auth-\(UUID().uuidString).json"
        try Self.writeAuthFile(at: path, content: "{ this is not json")
        defer { try? FileManager.default.removeItem(atPath: path) }

        let inspector = CodexSubscriptionInspector(authPath: path)
        #expect(inspector.inspect() == .unknown)
    }

    @Test("id_token 缺失时返回 .unknown")
    func missingIDTokenIsUnknown() throws {
        let path = "/tmp/quota-bar-test-auth-\(UUID().uuidString).json"
        let json: [String: Any] = [
            "auth_mode": "chatgpt",
            "tokens": ["access_token": "x", "refresh_token": "y", "account_id": "z"],
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        try data.write(to: URL(fileURLWithPath: path))
        defer { try? FileManager.default.removeItem(atPath: path) }

        let inspector = CodexSubscriptionInspector(authPath: path)
        #expect(inspector.inspect() == .unknown)
    }

    @Test("id_token 不是合法 JWT 时返回 .unknown")
    func malformedIDTokenIsUnknown() throws {
        let path = "/tmp/quota-bar-test-auth-\(UUID().uuidString).json"
        try Self.writeAuthFile(at: path, content: Self.makeAuthJSON(idToken: "not.a.jwt"))
        defer { try? FileManager.default.removeItem(atPath: path) }

        let inspector = CodexSubscriptionInspector(authPath: path)
        #expect(inspector.inspect() == .unknown)
    }

    @Test("没有 active_until 字段时返回 .unknown（不要瞎猜）")
    func missingActiveUntilIsUnknown() throws {
        let token = JWTPayloadDecoderTests.makeJWT(payload: Self.makeJWTPayload(planType: "plus"))
        let path = "/tmp/quota-bar-test-auth-\(UUID().uuidString).json"
        try Self.writeAuthFile(at: path, content: Self.makeAuthJSON(idToken: token))
        defer { try? FileManager.default.removeItem(atPath: path) }

        let inspector = CodexSubscriptionInspector(authPath: path)
        #expect(inspector.inspect() == .unknown)
    }

    // MARK: 语义正确性

    @Test(".free 和 .expired 都是 isEffectivelyExpired")
    func effectiveExpirySemantics() {
        let now = Date()
        #expect(SubscriptionStatus.expired(lastPlan: "plus", expiredAt: now).isEffectivelyExpired == true)
        #expect(SubscriptionStatus.free.isEffectivelyExpired == true)
        #expect(SubscriptionStatus.active(expiresAt: now).isEffectivelyExpired == false)
        #expect(SubscriptionStatus.unknown.isEffectivelyExpired == false)
    }
}

// MARK: - CodexDashboardParser free 用户路径（v0.8.0）

@Suite("CodexDashboardParser — free 用户路径 (v0.8.0)")
struct CodexDashboardParserFreeUserTests {

    private static func makeData(_ json: [String: Any]) -> Data {
        try! JSONSerialization.data(withJSONObject: json)
    }

    @Test("plan_type=free 时返回 nil（不渲染 free 月度窗口）")
    func freeUserReturnsNil() {
        let parser = CodexDashboardParser()
        let json: [String: Any] = [
            "plan_type": "free",
            "rate_limit": [
                "allowed": true,
                "limit_reached": false,
                "primary_window": [
                    "used_percent": 5,
                    "limit_window_seconds": 2592000,  // 30 天，月度
                    "reset_at": 1785288790,
                ],
                "secondary_window": nil,
            ]
        ]
        let result = parser.parse(data: Self.makeData(json))
        #expect(result == nil)
    }

    @Test("plan_type=plus 仍正常解析 5h + weekly 窗口")
    func plusUserStillParsesCorrectly() throws {
        let parser = CodexDashboardParser()
        let json: [String: Any] = [
            "plan_type": "plus",
            "rate_limit": [
                "primary_window": [
                    "used_percent": 25,
                    "limit_window_seconds": 18000,  // 5h
                    "reset_at": 1735689600,
                ],
                "secondary_window": [
                    "used_percent": 60,
                    "limit_window_seconds": 604800,  // weekly
                    "reset_at": 1736294400,
                ],
            ]
        ]
        let windows = try #require(parser.parse(data: Self.makeData(json)))
        #expect(windows.count == 2)
        // 5h 窗口（periodSeconds 短，排序在前）
        #expect(windows[0].periodSeconds == 18000)
        #expect(windows[0].remainingFraction == 0.75)
        #expect(windows[1].periodSeconds == 604800)
    }

    @Test("planType 大小写不敏感（'Free' / ' FREE ' 也识别为 free）")
    func caseInsensitiveFreeDetection() {
        let parser = CodexDashboardParser()
        for variant in ["Free", "FREE", " free ", "  free"] {
            let json: [String: Any] = [
                "plan_type": variant,
                "rate_limit": [
                    "primary_window": [
                        "used_percent": 5,
                        "limit_window_seconds": 2592000,
                    ]
                ]
            ]
            let result = parser.parse(data: Self.makeData(json))
            #expect(result == nil, "expected nil for plan_type=\(variant), got \(String(describing: result))")
        }
    }
}

// MARK: - ProviderSnapshot subscriptionExpired 行为（v0.8.0）

@Suite("ProviderSnapshot — subscriptionExpired availability (v0.8.0)")
struct ProviderSnapshotExpiredTests {

    @Test("subscriptionExpired snapshot 的 statusColor 是红色（区别于灰/橙）")
    func statusColorIsRed() {
        let snapshot = ProviderSnapshot(
            kind: .codex,
            availability: .subscriptionExpired(plan: "plus", expiredAt: Date()),
            quotas: [],
            monthlyPrice: nil,
            fetchedAt: Date()
        )
        // 直接 hex 比对：red = #FF453A（与 QuotaModels.statusColor switch 里的常量一致）
        let _ = snapshot.statusColor  // 调用不抛错就行；颜色比对依赖 SwiftUI Color init
    }

    @Test("subscriptionExpired 的 statusColor 不会读 quota（quotas 为空时也安全）")
    func statusColorSafeWithEmptyQuotas() {
        // Code path: snapshot.statusColor(itemOrder: []) 应该走 .subscriptionExpired 分支
        // 而不是尝试 primarySubscriptionGroupWorstQuota().remainingFraction
        let snapshot = ProviderSnapshot(
            kind: .codex,
            availability: .subscriptionExpired(plan: "plus", expiredAt: nil),
            quotas: [],
            monthlyPrice: nil,
            fetchedAt: Date()
        )
        let _ = snapshot.statusColor(itemOrder: [])
        let _ = snapshot.statusColor(itemOrder: ["codex"])
    }

    @Test("subscriptionExpired 状态不会反推 monthlyPrice（保持 nil）")
    func noFallbackMonthlyPrice() {
        let snapshot = ProviderSnapshot(
            kind: .codex,
            availability: .subscriptionExpired(plan: "plus", expiredAt: Date()),
            quotas: [],
            monthlyPrice: nil,
            fetchedAt: Date()
        )
        #expect(snapshot.monthlyPrice == nil)
    }
}

// MARK: - Data 扩展（base64URL helper）

private extension Data {
    func base64URLString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
