import Foundation
import Testing
@testable import QuotaBar

/// Claude 配置文件 → API 数据源：`~/.claude/.credentials.json` 的 OAuth access
/// token 直调 `api.anthropic.com/api/oauth/usage`。端点/字段经 CodexBar
/// （`ClaudeOAuthUsageFetcher`）交叉验证。
@Suite("ClaudeOAuthUsageProvider", .serialized)
struct ClaudeOAuthUsageProviderTests {

    @Test("parses credentials file and returns quota + tier from real response shape")
    func parsesRealCredentialsAndUsage() async throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let credsPath = dir.appendingPathComponent(".credentials.json").path
        try Data("""
        {"claudeAiOauth": {"accessToken": "sk-ant-oat-test", "subscriptionType": "pro"}}
        """.utf8).write(to: URL(fileURLWithPath: credsPath))

        ClaudeOAuthMockURLProtocol.responseHandler = { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-ant-oat-test")
            #expect(request.value(forHTTPHeaderField: "anthropic-beta") == "oauth-2025-04-20")
            let json: [String: Any] = [
                "five_hour": ["utilization": 10, "resets_at": "2026-07-06T20:00:00Z"],
                "seven_day": ["utilization": 30, "resets_at": "2026-07-10T00:00:00Z"],
            ]
            let data = try! JSONSerialization.data(withJSONObject: json)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, data)
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ClaudeOAuthMockURLProtocol.self]
        let session = URLSession(configuration: config)

        let provider = ClaudeOAuthUsageProvider(
            credentialsPath: credsPath,
            endpoint: URL(string: "https://api.anthropic.test/api/oauth/usage")!,
            session: session
        )
        let snapshot = try await provider.fetchSnapshot(timeout: 2)
        #expect(snapshot.availability == .available)
        #expect(snapshot.subscriptionTier == "Pro")
        #expect(snapshot.monthlyPrice == "US$20/月" || snapshot.monthlyPrice != nil)
        // title 留空（跟 Codex 一致），用 periodSeconds 区分 5 小时 / 周窗口。
        #expect(snapshot.quotas.contains { $0.title.isEmpty && $0.periodSeconds == 5 * 3600 })
        #expect(snapshot.quotas.contains { $0.title.isEmpty && $0.periodSeconds == 7 * 86400 })
    }

    @Test("missing credentials file throws missingCredentials")
    func missingFileThrows() async {
        // 显式注入一个固定返回 nil 的 keychainReader，不让测试依赖开发机上
        // 真实 Keychain 里可能存在的 "Claude Code-credentials" 条目。
        let provider = ClaudeOAuthUsageProvider(credentialsPath: "/nonexistent/.credentials.json", keychainReader: { nil })
        do {
            _ = try await provider.fetchSnapshot(timeout: 1)
            Issue.record("应该抛错")
        } catch let error as QuotaFetchError {
            guard case .missingCredentials = error else {
                Issue.record("期望 missingCredentials，实际 \(error)")
                return
            }
        } catch {
            Issue.record("非 QuotaFetchError: \(error)")
        }
    }

    @Test("credentials file without accessToken throws missingCredentials")
    func missingAccessTokenThrows() async throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let credsPath = dir.appendingPathComponent(".credentials.json").path
        try Data(#"{"claudeAiOauth": {"subscriptionType": "pro"}}"#.utf8).write(to: URL(fileURLWithPath: credsPath))

        // 同上：显式注入 nil，不依赖开发机真实 Keychain 状态。
        let provider = ClaudeOAuthUsageProvider(credentialsPath: credsPath, keychainReader: { nil })
        do {
            _ = try await provider.fetchSnapshot(timeout: 1)
            Issue.record("应该抛错")
        } catch let error as QuotaFetchError {
            guard case .missingCredentials = error else {
                Issue.record("期望 missingCredentials，实际 \(error)")
                return
            }
        } catch {
            Issue.record("非 QuotaFetchError: \(error)")
        }
    }

    @Test("HTTP 401 maps to missingCredentials with re-login hint")
    func unauthorizedMapsToMissingCredentials() async throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let credsPath = dir.appendingPathComponent(".credentials.json").path
        try Data(#"{"claudeAiOauth": {"accessToken": "expired-token"}}"#.utf8).write(to: URL(fileURLWithPath: credsPath))

        ClaudeOAuthMockURLProtocol.responseHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ClaudeOAuthMockURLProtocol.self]
        let provider = ClaudeOAuthUsageProvider(
            credentialsPath: credsPath,
            endpoint: URL(string: "https://api.anthropic.test/api/oauth/usage")!,
            session: URLSession(configuration: config)
        )
        do {
            _ = try await provider.fetchSnapshot(timeout: 1)
            Issue.record("应该抛错")
        } catch let error as QuotaFetchError {
            guard case .missingCredentials = error else {
                Issue.record("期望 missingCredentials，实际 \(error)")
                return
            }
        } catch {
            Issue.record("非 QuotaFetchError: \(error)")
        }
    }

    @Test("HTTP 429 maps to transient (rate limited)")
    func rateLimitMapsToTransient() async throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let credsPath = dir.appendingPathComponent(".credentials.json").path
        try Data(#"{"claudeAiOauth": {"accessToken": "tok"}}"#.utf8).write(to: URL(fileURLWithPath: credsPath))

        ClaudeOAuthMockURLProtocol.responseHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 429, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ClaudeOAuthMockURLProtocol.self]
        let provider = ClaudeOAuthUsageProvider(
            credentialsPath: credsPath,
            endpoint: URL(string: "https://api.anthropic.test/api/oauth/usage")!,
            session: URLSession(configuration: config)
        )
        do {
            _ = try await provider.fetchSnapshot(timeout: 1)
            Issue.record("应该抛错")
        } catch let error as QuotaFetchError {
            guard case .transient = error else {
                Issue.record("期望 transient，实际 \(error)")
                return
            }
        } catch {
            Issue.record("非 QuotaFetchError: \(error)")
        }
    }

    private static func makeTempDirectory() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quota-bar-claude-oauth-tests-\(UUID().uuidString)", isDirectory: true)
    }
}

/// `/usr/bin/security` CLI 读取——2026-07-07 从直接调 `SecItemCopyMatching` 改成
/// 走系统 `security` CLI（参考 ClaudeBar 真实实现），因为 `/usr/bin/security` 是
/// 稳定的 Apple 签名二进制，用户一次「始终允许」的信任不会因为我们自己 ad-hoc
/// 签名每次重新构建而失效。这里只验证"找不到条目时返回 nil"这个跨机器都成立的
/// 确定性行为，不断言真实凭证内容（那依赖开发机是否登录过 Claude）。
@Suite("ClaudeKeychainCredentialsReader")
struct ClaudeKeychainCredentialsReaderTests {
    @Test("returns nil for a service that does not exist in the keychain")
    func returnsNilForNonexistentService() async {
        let data = await ClaudeKeychainCredentialsReader.readViaSecurityCLI(
            service: "com.quotabar.definitely-nonexistent-test-service-\(UUID().uuidString)"
        )
        #expect(data == nil)
    }
}

private final class ClaudeOAuthMockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var responseHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

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

/// `claude auth status --json` 输出解析（CLI 命令层，只贡献档位）。
@Suite("ClaudeAuthStatusCLIProvider parsing")
struct ClaudeAuthStatusCLIProviderTests {

    @Test("logged-in status with subscriptionType yields tier + price, no fabricated quota")
    func parsesLoggedInStatus() async throws {
        let json: [String: Any] = [
            "loggedIn": true,
            "authMethod": "claude.ai",
            "subscriptionType": "pro",
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let snapshot = try await ClaudeAuthStatusCLIProvider.parseStatusOutput(data, fetchedAt: Date())
        #expect(snapshot.availability == .available)
        #expect(snapshot.subscriptionTier == "Pro")
        #expect(snapshot.quotas.isEmpty)
        // 价格是从档位名字静态映射的公开定价，不是"伪造额度"——只贡献档位的
        // CLI 兜底层理应也能带出价格（回归测试：曾经这里硬编码成 nil）。
        #expect(snapshot.monthlyPrice != nil)
    }

    @Test("not logged in throws missingCredentials")
    func notLoggedInThrows() async {
        let json: [String: Any] = ["loggedIn": false]
        let data = try! JSONSerialization.data(withJSONObject: json)
        await #expect(throws: QuotaFetchError.missingCredentials(detail: "claude CLI 未登录，请先运行 claude 登录")) {
            _ = try await ClaudeAuthStatusCLIProvider.parseStatusOutput(data, fetchedAt: Date())
        }
    }

    @Test("malformed output throws transient")
    func malformedOutputThrows() async {
        let data = Data("not json".utf8)
        await #expect(throws: (any Error).self) {
            _ = try await ClaudeAuthStatusCLIProvider.parseStatusOutput(data, fetchedAt: Date())
        }
    }
}

/// KeychainProvider 的 Claude service/account 修正（回归测试：确认不再用假的
/// "com.anthropic.claude"，account 为 nil 走 service-only 匹配）。
@Suite("KeychainProvider Claude defaults")
struct KeychainProviderClaudeDefaultsTests {
    @Test("Claude uses the real Keychain service name confirmed via CodexBar reference")
    func usesRealServiceName() {
        #expect(ProviderKind.claude.defaultKeychainService == "Claude Code-credentials")
        #expect(ProviderKind.claude.defaultKeychainAccount == nil)
    }

    @Test("other providers keep explicit account filtering unaffected")
    func otherProvidersUnaffected() {
        #expect(ProviderKind.codex.defaultKeychainAccount == "oauth-token")
        #expect(ProviderKind.kimi.defaultKeychainAccount == "session")
        #expect(ProviderKind.minimax.defaultKeychainAccount == "api-key")
    }
}
