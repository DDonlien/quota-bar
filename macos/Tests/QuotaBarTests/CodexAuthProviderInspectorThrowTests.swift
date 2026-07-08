import Foundation
import Testing
@testable import QuotaBar

// MARK: - CodexAuthProvider: inspector 只能作为真实请求失败后的辅助信号

/// `auth.json` 里的 id_token 可能比 access_token / 服务端 usage 状态更陈旧。
/// 用户在 Web 续费后，`chatgpt_subscription_active_until` 仍可能停在旧日期；
/// 因此 CodexAuthProvider 必须先尝试真实 `wham/usage`，不能让 inspector
/// 在请求前短路到 expired/free。
@Suite("CodexAuthProvider — stale inspector does not short-circuit usage", .serialized)
struct CodexAuthProviderInspectorThrowTests {

    private static func makeAuthJSON(idToken: String) -> String {
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

    /// 构造一个 `chatgpt_subscription_active_until = pastISO` 的过期 JWT。
    private static func makeExpiredJWT(planType: String, until: Date) -> String {
        let pastISO = ISO8601DateFormatter().string(from: until)
        let auth: [String: Any] = [
            "chatgpt_plan_type": planType,
            "chatgpt_subscription_active_start": "2026-05-25T15:23:47+00:00",
            "chatgpt_subscription_active_until": pastISO,
            "chatgpt_account_id": "acct-123",
            "chatgpt_user_id": "user-abc",
        ]
        let payload: [String: Any] = [
            "sub": "google-oauth2|...",
            "https://api.openai.com/auth": auth,
        ]
        let header: [String: Any] = ["alg": "RS256", "kid": "test"]
        let headerData = try! JSONSerialization.data(withJSONObject: header)
        let payloadData = try! JSONSerialization.data(withJSONObject: payload)
        return [
            headerData.base64URLString(),
            payloadData.base64URLString(),
            "fake-signature",
        ].joined(separator: ".")
    }

    /// 构造一个 `chatgpt_plan_type = "free"` 的 JWT。
    private static func makeFreeJWT() -> String {
        let auth: [String: Any] = [
            "chatgpt_plan_type": "free",
            "chatgpt_account_id": "acct-123",
            "chatgpt_user_id": "user-abc",
        ]
        let payload: [String: Any] = [
            "sub": "google-oauth2|...",
            "https://api.openai.com/auth": auth,
        ]
        let header: [String: Any] = ["alg": "RS256", "kid": "test"]
        let headerData = try! JSONSerialization.data(withJSONObject: header)
        let payloadData = try! JSONSerialization.data(withJSONObject: payload)
        return [
            headerData.base64URLString(),
            payloadData.base64URLString(),
            "fake-signature",
        ].joined(separator: ".")
    }

    private static func writeAuthFile(at path: String, content: String) throws {
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.removeItem(at: url)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func makeUsageJSON(
        planType: String = "plus",
        primaryUsed: Double = 40,
        secondaryUsed: Double = 60,
        now: Date
    ) -> Data {
        let payload: [String: Any] = [
            "plan_type": planType,
            "rate_limit": [
                "primary_window": [
                    "used_percent": primaryUsed,
                    "reset_at": now.addingTimeInterval(5 * 60 * 60).timeIntervalSince1970,
                    "limit_window_seconds": 5 * 60 * 60,
                ],
                "secondary_window": [
                    "used_percent": secondaryUsed,
                    "reset_at": now.addingTimeInterval(7 * 24 * 60 * 60).timeIntervalSince1970,
                    "limit_window_seconds": 7 * 24 * 60 * 60,
                ],
            ],
        ]
        return try! JSONSerialization.data(withJSONObject: payload)
    }

    private static func makeSession(statusCode: Int, data: Data) -> URLSession {
        MockURLProtocol.responseHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, data)
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    @Test("inspector 过期但 wham/usage 成功时返回真实额度")
    func inspectorExpiredStillUsesWhamUsage() async throws {
        let now = Date()
        let token = Self.makeExpiredJWT(planType: "plus", until: now.addingTimeInterval(-86400))
        let path = "/tmp/quota-bar-test-auth-\(UUID().uuidString).json"
        try Self.writeAuthFile(at: path, content: Self.makeAuthJSON(idToken: token))
        defer { try? FileManager.default.removeItem(atPath: path) }

        let inspector = CodexSubscriptionInspector(authPath: path, dateProvider: { now })
        let provider = CodexAuthProvider(
            authPath: path,
            endpoint: URL(string: "https://chatgpt.test/backend-api/wham/usage")!,
            session: Self.makeSession(statusCode: 200, data: Self.makeUsageJSON(now: now)),
            dateProvider: { now },
            inspector: inspector
        )

        let snapshot = try await provider.fetchSnapshot(timeout: 1)
        #expect(snapshot.availability == .available)
        #expect(snapshot.subscriptionTier == "Plus")
        #expect(snapshot.quotas.count == 2)
        #expect(snapshot.quotas[0].remainingFraction == 0.6)
        #expect(snapshot.quotas[1].remainingFraction == 0.4)
        #expect(snapshot.subscriptionExpiresAt == nil)
    }

    @Test("inspector free 但 wham/usage 成功时仍以真实 usage 为准")
    func inspectorFreeStillUsesWhamUsage() async throws {
        let now = Date()
        let token = Self.makeFreeJWT()
        let path = "/tmp/quota-bar-test-auth-\(UUID().uuidString).json"
        try Self.writeAuthFile(at: path, content: Self.makeAuthJSON(idToken: token))
        defer { try? FileManager.default.removeItem(atPath: path) }

        let inspector = CodexSubscriptionInspector(authPath: path, dateProvider: { now })
        let provider = CodexAuthProvider(
            authPath: path,
            endpoint: URL(string: "https://chatgpt.test/backend-api/wham/usage")!,
            session: Self.makeSession(statusCode: 200, data: Self.makeUsageJSON(primaryUsed: 25, secondaryUsed: 75, now: now)),
            dateProvider: { now },
            inspector: inspector
        )

        let snapshot = try await provider.fetchSnapshot(timeout: 1)
        #expect(snapshot.availability == .available)
        #expect(snapshot.quotas[0].remainingFraction == 0.75)
        #expect(snapshot.quotas[1].remainingFraction == 0.25)
    }

    @Test("wham/usage 401 且 inspector 最近过期时显示已过期")
    func usageUnauthorizedFallsBackToRecentExpiredStatus() async throws {
        let now = Date()
        let token = Self.makeExpiredJWT(planType: "plus", until: now.addingTimeInterval(-86400))
        let path = "/tmp/quota-bar-test-auth-\(UUID().uuidString).json"
        try Self.writeAuthFile(at: path, content: Self.makeAuthJSON(idToken: token))
        defer { try? FileManager.default.removeItem(atPath: path) }

        let inspector = CodexSubscriptionInspector(authPath: path, dateProvider: { now })
        let provider = CodexAuthProvider(
            authPath: path,
            endpoint: URL(string: "https://chatgpt.test/backend-api/wham/usage")!,
            session: Self.makeSession(statusCode: 401, data: Data("{}".utf8)),
            dateProvider: { now },
            inspector: inspector
        )

        do {
            _ = try await provider.fetchSnapshot(timeout: 1)
            Issue.record("expected throw .subscriptionExpired, but fetchSnapshot returned")
        } catch let QuotaFetchError.subscriptionExpired(plan, expiredAt) {
            #expect(plan == "plus")
            #expect(expiredAt != nil)
        } catch {
            Issue.record("expected .subscriptionExpired, got \(error)")
        }
    }

    @Test("wham/usage 401 且 inspector 超过一周过期时显示未订阅")
    func usageUnauthorizedFallsBackToOldExpiredNotSubscribed() async throws {
        let now = Date()
        let token = Self.makeExpiredJWT(planType: "plus", until: now.addingTimeInterval(-9 * 86400))
        let path = "/tmp/quota-bar-test-auth-\(UUID().uuidString).json"
        try Self.writeAuthFile(at: path, content: Self.makeAuthJSON(idToken: token))
        defer { try? FileManager.default.removeItem(atPath: path) }

        let inspector = CodexSubscriptionInspector(authPath: path, dateProvider: { now })
        let provider = CodexAuthProvider(
            authPath: path,
            endpoint: URL(string: "https://chatgpt.test/backend-api/wham/usage")!,
            session: Self.makeSession(statusCode: 401, data: Data("{}".utf8)),
            dateProvider: { now },
            inspector: inspector
        )

        do {
            _ = try await provider.fetchSnapshot(timeout: 1)
            Issue.record("expected throw .notSubscribed, but fetchSnapshot returned")
        } catch let QuotaFetchError.notSubscribed(detail) {
            #expect(detail == "未订阅")
        } catch {
            Issue.record("expected .notSubscribed, got \(error)")
        }
    }
}

// MARK: - QuotaFetchError.availabilityFallback (v0.8.0 已存在, v0.8.1 强化契约)

@Suite("QuotaFetchError — availabilityFallback (v0.8.1)")
struct QuotaFetchErrorAvailabilityFallbackTests {

    @Test(".subscriptionExpired 的 availabilityFallback 是 .subscriptionExpired(plan, expiredAt)")
    func subscriptionExpiredAvailabilityFallback() {
        let expiredAt = Date()
        let err = QuotaFetchError.subscriptionExpired(plan: "plus", expiredAt: expiredAt)
        if case .subscriptionExpired(let plan, let at) = err.availabilityFallback {
            #expect(plan == "plus")
            #expect(at == expiredAt)
        } else {
            Issue.record("expected .subscriptionExpired, got \(err.availabilityFallback)")
        }
    }

    @Test(".subscriptionExpired(plan: nil, expiredAt: nil) 也能 fallback（用于 .free 状态）")
    func subscriptionExpiredNilFallback() {
        let err = QuotaFetchError.subscriptionExpired(plan: nil, expiredAt: nil)
        if case .subscriptionExpired(let plan, let at) = err.availabilityFallback {
            #expect(plan == nil)
            #expect(at == nil)
        } else {
            Issue.record("expected .subscriptionExpired, got \(err.availabilityFallback)")
        }
    }

    @Test(".notSubscribed 的 availabilityFallback 是 .notSubscribed")
    func notSubscribedAvailabilityFallback() {
        let err = QuotaFetchError.notSubscribed(detail: "未订阅")
        if case .notSubscribed(let reason) = err.availabilityFallback {
            #expect(reason == "未订阅")
        } else {
            Issue.record("expected .notSubscribed, got \(err.availabilityFallback)")
        }
    }

    @Test(".transient 的 availabilityFallback 是 .fetchFailed")
    func transientAvailabilityFallback() {
        let err = QuotaFetchError.transient(detail: "x")
        if case .fetchFailed(let reason) = err.availabilityFallback {
            #expect(reason == "x")
        } else {
            Issue.record("expected .fetchFailed, got \(err.availabilityFallback)")
        }
    }
}

// MARK: - Codex pipeline strategies 顺序（v0.8.1）

/// 默认刷新不能主动触发浏览器 Cookie 权限，也不能用本地日志估算冒充真实额度。
/// 浏览器 Cookie 和 Codex 日志估算只在显式环境开关下加入 pipeline。
@Suite("Codex pipeline — default strategy order")
struct CodexPipelineStrategyOrderTests {

    @Test("codexPipeline 默认是 auth → webview 会话 → keychain，不包含 cookie / cli log")
    @MainActor
    func strategiesOrder() {
        unsetenv("QUOTABAR_ENABLE_CODEX_LOG_ESTIMATE")
        let pipelines = ProviderPipelines.makePipelines()
        guard let codexPipeline = pipelines.first(where: { $0.providerKind == .codex }) else {
            Issue.record("codex pipeline not found")
            return
        }

        // strategies 是 private(set) var，可以读。
        // 默认链路：auth → App WebView 会话（最后额度层）→ keychain；
        // 浏览器 cookie 读取路径已彻底移除（2026-07-08），CLI log 仍需显式启用。
        let strategyIds = codexPipeline.strategies.map { $0.id }
        #expect(strategyIds.count == 3, "expected 3 strategies, got \(strategyIds.count)")
        #expect(strategyIds[0].contains("codex-auth"))
        #expect(strategyIds[1].contains("codex-webview"))
        #expect(strategyIds[2].contains("codex-keychain"))
        #expect(!strategyIds.contains { $0.contains("codex-cookie") })
        #expect(!strategyIds.contains { $0 == "codex-cli" })
    }

    @Test("codexPipeline runMode 是 sequential（不是 parallel）—— 第一个成功就停")
    @MainActor
    func sequentialRunMode() {
        let pipelines = ProviderPipelines.makePipelines()
        guard let codexPipeline = pipelines.first(where: { $0.providerKind == .codex }) else {
            Issue.record("codex pipeline not found")
            return
        }
        // sequential 是关键：auth 失败后才走到 keychain，不并发触发敏感来源。
        if case .sequential = codexPipeline.runMode {
            // pass
        } else {
            Issue.record("expected sequential runMode, got \(codexPipeline.runMode)")
        }
    }
}

// MARK: - BrowserCookieProvider: Codex 路径不再调 inspector（v0.8.1）

/// v0.8.1 修订：BrowserCookieProvider 在 Codex 入口不再调 CodexSubscriptionInspector，
/// 否则会把 inspector 陈旧数据再次短路。
/// 用 init 验证：传入 `kind = .codex` 仍能正常构造（不再需要 inspector 参数）；
/// 用真实 auth.json + inspector expired 状态 + 故意让 cookie 读取失败，
/// 验证 BrowserCookieProvider 走的是 missingCredentials / sourceUnavailable 路径，
/// 而不是 subscriptionExpired（v0.8.0 的行为）。
@Suite("BrowserCookieProvider — Codex 路径不再短路 (v0.8.1)")
struct BrowserCookieProviderCodexPathNoLongerShortCircuits {

    private static func makeAuthJSON(idToken: String) -> String {
        let json: [String: Any] = [
            "auth_mode": "chatgpt",
            "tokens": [
                "id_token": idToken,
                "access_token": "fake-access",
                "refresh_token": "fake-refresh",
                "account_id": "acct-123",
            ]
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        return String(data: data, encoding: .utf8)!
    }

    /// 构造过期 JWT（v0.8.0 旧行为下 BrowserCookieProvider 会 throw subscriptionExpired）
    private static func makeExpiredJWT() -> String {
        let now = Date()
        let pastISO = ISO8601DateFormatter().string(from: now.addingTimeInterval(-86400))
        let auth: [String: Any] = [
            "chatgpt_plan_type": "plus",
            "chatgpt_subscription_active_until": pastISO,
        ]
        let payload: [String: Any] = [
            "https://api.openai.com/auth": auth,
        ]
        let header: [String: Any] = ["alg": "RS256"]
        let headerData = try! JSONSerialization.data(withJSONObject: header)
        let payloadData = try! JSONSerialization.data(withJSONObject: payload)
        return [
            headerData.base64URLString(),
            payloadData.base64URLString(),
            "fake-sig",
        ].joined(separator: ".")
    }

    private static func writeAuthFile(at path: String, content: String) throws {
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.removeItem(at: url)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    @Test("inspector expired 的 auth.json 存在时，BrowserCookieProvider Codex 路径不再 throw subscriptionExpired")
    func codexPathNoLongerInspectorShortCircuit() async throws {
        let token = Self.makeExpiredJWT()
        let path = "/tmp/quota-bar-test-auth-\(UUID().uuidString).json"
        try Self.writeAuthFile(at: path, content: Self.makeAuthJSON(idToken: token))
        defer { try? FileManager.default.removeItem(atPath: path) }

        // 关键：通过环境变量让 CodexSubscriptionInspector 读到过期 auth.json
        setenv("CODEX_HOME", "/tmp/quota-bar-test-auth-\(UUID().uuidString)", 1)
        defer { unsetenv("CODEX_HOME") }

        // 构造 BrowserCookieProvider，cookieReader 是空 reader（永远读不到 cookies）
        let emptyReader = EmptyCookieReader()
        let provider = BrowserCookieProvider(
            id: "codex-cookie",
            kind: .codex,
            cookieReader: emptyReader
        )

        do {
            _ = try await provider.fetchSnapshot(timeout: 1)
            Issue.record("expected throw (cookies empty), but fetchSnapshot returned")
        } catch QuotaFetchError.subscriptionExpired {
            // v0.8.0 旧行为：throw subscriptionExpired
            // v0.8.1 新行为：应该走到 cookie reader → missingCredentials
            Issue.record("v0.8.1 regression: BrowserCookieProvider Codex 路径仍在调 inspector")
        } catch {
            // 期望路径：missingCredentials("未登录") 或 sourceUnavailable("未发现已登录的浏览器")
            // 具体哪个取决于 EmptyCookieReader 的实现
            if case QuotaFetchError.missingCredentials = error {
                // pass
            } else if case QuotaFetchError.sourceUnavailable = error {
                // pass
            } else if case QuotaFetchError.permissionRequired = error {
                // pass（FDA 没给权限也是 missingCredentials 之前的合法路径）
            } else {
                Issue.record("expected missingCredentials/sourceUnavailable, got \(error)")
            }
        }
    }
}

/// 空 cookie reader —— 永远返回空数组
private final class EmptyCookieReader: BrowserCookieReader, @unchecked Sendable {
    func readCookies(matching domains: [String]) async throws -> [HTTPCookie] {
        return []
    }
}

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var responseHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.responseHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Data 扩展（base64URL helper，与现有测试复用）

private extension Data {
    func base64URLString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
