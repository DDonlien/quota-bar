import Foundation
import Testing
@testable import QuotaBar

/// App 自有 WebView 会话桥（分层获取的最后一层）相关测试。
@Suite("AppWebViewSessionCookieReader")
struct AppWebViewSessionCookieReaderTests {

    @Test("filters cookies by domain suffix and drops expired ones")
    func filtersByDomain() async throws {
        let reader = AppWebViewSessionCookieReader(cookiesProvider: {
            [
                Self.cookie(domain: ".claude.ai", name: "sessionKey"),
                Self.cookie(domain: "chatgpt.com", name: "__Secure-next-auth"),
                Self.cookie(domain: "example.com", name: "unrelated"),
                Self.cookie(domain: ".claude.ai", name: "expired", expires: Date(timeIntervalSinceNow: -3600)),
            ]
        })
        let cookies = try await reader.readCookies(matching: ["claude.ai"])
        #expect(cookies.count == 1)
        #expect(cookies.first?.name == "sessionKey")

        let empty = try await reader.readCookies(matching: ["kimi.com"])
        #expect(empty.isEmpty)
    }

    @Test("webview strategies are wired as last quota layer before keychain")
    @MainActor
    func pipelinesContainWebViewLayer() {
        let pipelines = ProviderPipelines.makePipelines()
        for kind in [ProviderKind.codex, .claude, .kimi, .minimax] {
            let pipeline = pipelines.first { $0.providerKind == kind }
            let ids = pipeline?.strategies.map(\.id) ?? []
            let webviewIndex = ids.firstIndex(of: "\(kind.rawValue)-webview")
            let keychainIndex = ids.firstIndex(of: "\(kind.rawValue)-keychain")
            #expect(webviewIndex != nil, "\(kind.rawValue) 管线缺 webview 层")
            #expect(keychainIndex != nil)
            if let webviewIndex, let keychainIndex {
                #expect(webviewIndex == keychainIndex - 1, "\(kind.rawValue) webview 层应紧邻 keychain 之前")
            }
        }
    }

    private static func cookie(domain: String, name: String, expires: Date? = nil) -> HTTPCookie {
        var properties: [HTTPCookiePropertyKey: Any] = [
            .domain: domain,
            .path: "/",
            .name: name,
            .value: "v",
        ]
        if let expires {
            properties[.expires] = expires
        }
        return HTTPCookie(properties: properties)!
    }
}

/// Codex accounts/check JSON 解析（browserAPI 过期日 source）。
@Suite("CodexAccountsCheckParser")
struct CodexAccountsCheckParserTests {

    @Test("extracts expires_at from active subscription")
    func extractsActiveExpiry() throws {
        let json: [String: Any] = [
            "accounts": [
                "default": [
                    "entitlement": [
                        "has_active_subscription": true,
                        "subscription_plan": "chatgptplusplan",
                        "expires_at": "2026-07-25T15:23:58+00:00",
                    ],
                ],
            ],
        ]
        let date = try #require(CodexAccountsCheckParser.extractExpiresAt(from: Self.data(json)))
        #expect(date == ISO8601DateFormatter().date(from: "2026-07-25T15:23:58+00:00"))
    }

    @Test("prefers active subscription over inactive accounts")
    func prefersActive() throws {
        let json: [String: Any] = [
            "accounts": [
                "old-team": [
                    "entitlement": [
                        "has_active_subscription": false,
                        "expires_at": "2026-12-31T00:00:00+00:00",
                    ],
                ],
                "default": [
                    "entitlement": [
                        "has_active_subscription": true,
                        "expires_at": "2026-07-25T15:23:58+00:00",
                    ],
                ],
            ],
        ]
        let date = try #require(CodexAccountsCheckParser.extractExpiresAt(from: Self.data(json)))
        #expect(date == ISO8601DateFormatter().date(from: "2026-07-25T15:23:58+00:00"))
    }

    @Test("returns nil for malformed or empty responses")
    func handlesMalformed() {
        #expect(CodexAccountsCheckParser.extractExpiresAt(from: Data("not json".utf8)) == nil)
        #expect(CodexAccountsCheckParser.extractExpiresAt(from: Self.data(["accounts": [String: Any]()])) == nil)
        #expect(CodexAccountsCheckParser.extractExpiresAt(from: Self.data(["foo": "bar"])) == nil)
    }

    private static func data(_ json: [String: Any]) -> Data {
        try! JSONSerialization.data(withJSONObject: json)
    }
}

/// MiniMax 真实 CLI 命令输出解析。
@Suite("MiniMaxCommandProvider parsing")
struct MiniMaxCommandProviderTests {

    @Test("error wrapper with no-active-subscription maps to notSubscribed")
    func errorWrapperNotSubscribed() async {
        let output = Data(#"{"error":{"code":1,"message":"API error: no active token plan subscription (HTTP 200)"}}"#.utf8)
        await #expect(throws: QuotaFetchError.notSubscribed(detail: "MiniMax Coding Plan 订阅已到期或未订阅")) {
            _ = try await MiniMaxCommandProvider.parseCommandOutput(output, fetchedAt: Date())
        }
    }

    @Test("remains-shaped output parses into quota windows")
    func remainsOutputParses() async throws {
        let json: [String: Any] = [
            "base_resp": ["status_code": 0, "status_msg": "success"],
            "current_package_name": "Plus",
            "model_remains": [
                [
                    "model_name": "general",
                    "current_interval_remaining_percent": 80,
                    "current_weekly_remaining_percent": 60,
                    "start_time": 1_783_200_000_000,
                    "end_time": 1_783_218_000_000,
                    "weekly_start_time": 1_782_800_000_000,
                    "weekly_end_time": 1_783_404_800_000,
                ],
            ],
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let snapshot = try await MiniMaxCommandProvider.parseCommandOutput(data, fetchedAt: Date())
        #expect(snapshot.availability == .available)
        #expect(snapshot.quotas.count == 2)
        #expect(snapshot.subscriptionTier == "Plus")
    }

    @Test("stray non-JSON prefix and suffix are stripped before parsing")
    func stripsNoise() async {
        let output = Data("\u{1B}[2K\r{\"error\":{\"code\":1,\"message\":\"no active token plan subscription\"}}\n".utf8)
        await #expect(throws: QuotaFetchError.notSubscribed(detail: "MiniMax Coding Plan 订阅已到期或未订阅")) {
            _ = try await MiniMaxCommandProvider.parseCommandOutput(output, fetchedAt: Date())
        }
    }

    @Test("provider without mmx binary reports sourceUnavailable")
    func missingBinary() async {
        let provider = MiniMaxCommandProvider(executablePathCandidates: ["/nonexistent/mmx"])
        do {
            _ = try await provider.fetchSnapshot(timeout: 1)
            Issue.record("应该抛错")
        } catch let error as QuotaFetchError {
            guard case .sourceUnavailable = error else {
                Issue.record("期望 sourceUnavailable，实际 \(error)")
                return
            }
        } catch {
            Issue.record("非 QuotaFetchError: \(error)")
        }
    }
}
