import Foundation
import Testing
@testable import QuotaBar

// MARK: - CodexAuthProvider: inspector expired 时 throw（v0.8.1）

/// v0.8.1 修订：inspector 检测到 `.expired` / `.free` 时**不再**直接 return marker snapshot，
/// 而是 throw `QuotaFetchError.subscriptionExpired`，让 pipeline 真走完 BrowserCookieProvider
/// / CLILogProvider / KeychainProvider fallback。
///
/// 触发场景：用户 web 续费后 `~/.codex/auth.json` 未刷新，inspector 看到陈旧
/// `chatgpt_subscription_active_until` → 误判过期 → 但 BrowserCookie 路径用浏览器已登录
/// 会话能拿到真实 plus quota。
@Suite("CodexAuthProvider — inspector expired throw (v0.8.1)")
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

    @Test("inspector 报 .expired(plus, ...) → CodexAuthProvider throw .subscriptionExpired（不 return marker）")
    func inspectorExpiredThrows() async throws {
        let now = Date()
        let token = Self.makeExpiredJWT(planType: "plus", until: now.addingTimeInterval(-86400))
        let path = "/tmp/quota-bar-test-auth-\(UUID().uuidString).json"
        try Self.writeAuthFile(at: path, content: Self.makeAuthJSON(idToken: token))
        defer { try? FileManager.default.removeItem(atPath: path) }

        let inspector = CodexSubscriptionInspector(authPath: path, dateProvider: { now })
        // 用一个永远不该被 hit 的 endpoint：如果 fetchSnapshot 错误地走 return-marker 路径，
        // 它根本不会发请求；如果是 throw 路径，也不会发请求（wham/usage 调用前已 throw）。
        let provider = CodexAuthProvider(
            authPath: path,
            endpoint: URL(string: "https://example.invalid/never-called")!,
            session: URLSession(configuration: .ephemeral),
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

    @Test("inspector 报 .free → CodexAuthProvider throw .subscriptionExpired(plan: nil, expiredAt: nil)")
    func inspectorFreeThrows() async throws {
        let token = Self.makeFreeJWT()
        let path = "/tmp/quota-bar-test-auth-\(UUID().uuidString).json"
        try Self.writeAuthFile(at: path, content: Self.makeAuthJSON(idToken: token))
        defer { try? FileManager.default.removeItem(atPath: path) }

        let inspector = CodexSubscriptionInspector(authPath: path)
        let provider = CodexAuthProvider(
            authPath: path,
            endpoint: URL(string: "https://example.invalid/never-called")!,
            session: URLSession(configuration: .ephemeral),
            dateProvider: Date.init,
            inspector: inspector
        )

        do {
            _ = try await provider.fetchSnapshot(timeout: 1)
            Issue.record("expected throw .subscriptionExpired, but fetchSnapshot returned")
        } catch let QuotaFetchError.subscriptionExpired(plan, expiredAt) {
            // .free 状态：plan 和 expiredAt 都应该是 nil
            #expect(plan == nil)
            #expect(expiredAt == nil)
        } catch {
            Issue.record("expected .subscriptionExpired, got \(error)")
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

/// v0.8.1 验证：Codex pipeline 顺序仍然是
///   CodexAuthProvider → BrowserCookieProvider → CLILogProvider → KeychainProvider
/// 且 inspector 过期时第一个 strategy throw `.subscriptionExpired`，pipeline 真走完剩余 strategy。
@Suite("Codex pipeline — strategy 顺序 (v0.8.1)")
struct CodexPipelineStrategyOrderTests {

    @Test("codexPipeline strategies 顺序包含 4 个 strategy，依次为 auth → cookie → cli → keychain")
    @MainActor
    func strategiesOrder() {
        // 触发 makePipelines（不需要 cookieReader 真读）
        let pipelines = ProviderPipelines.makePipelines(
            cookieReader: FilesystemCookieReader(),
            edgeCookieReader: EdgeCookieReader()
        )
        guard let codexPipeline = pipelines.first(where: { $0.providerKind == .codex }) else {
            Issue.record("codex pipeline not found")
            return
        }

        // strategies 是 private(set) var，可以读
        let strategyIds = codexPipeline.strategies.map { $0.id }
        #expect(strategyIds.count == 4, "expected 4 strategies, got \(strategyIds.count)")
        #expect(strategyIds[0].contains("codex-auth"))
        #expect(strategyIds[1].contains("codex-cookie"))
        #expect(strategyIds[2].contains("codex-cli"))
        #expect(strategyIds[3].contains("codex-keychain"))
    }

    @Test("codexPipeline runMode 是 sequential（不是 parallel）—— 第一个成功就停")
    @MainActor
    func sequentialRunMode() {
        let pipelines = ProviderPipelines.makePipelines(
            cookieReader: FilesystemCookieReader(),
            edgeCookieReader: EdgeCookieReader()
        )
        guard let codexPipeline = pipelines.first(where: { $0.providerKind == .codex }) else {
            Issue.record("codex pipeline not found")
            return
        }
        // sequential 是关键：inspector expired throw 后必须走到 BrowserCookie
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

// MARK: - Data 扩展（base64URL helper，与现有测试复用）

private extension Data {
    func base64URLString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}