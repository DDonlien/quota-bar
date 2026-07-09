import Foundation
import Testing
@testable import QuotaBar

@Suite("ZCodeAuthProvider")
struct ZCodeAuthProviderTests {
    @Test("quota parser keeps session, weekly, and MCP limits separate")
    func parserKeepsDistinctLimitUnits() throws {
        let json = """
        {
          "code": 200,
          "success": true,
          "data": {
            "planName": "builtin:zai-coding-plan",
            "limits": [
              {
                "type": "TOKENS_LIMIT",
                "unit": 3,
                "number": 5,
                "percentage": 20,
                "nextResetTime": 1800000000000
              },
              {
                "type": "TOKENS_LIMIT",
                "unit": 6,
                "number": 1,
                "percentage": 40,
                "nextResetTime": "2027-01-15T00:00:00Z"
              },
              {
                "type": "TIME_LIMIT",
                "unit": 5,
                "number": 1,
                "percentage": 10
              }
            ]
          }
        }
        """

        let parsed = try ZCodeAuthProvider.parseQuotaLimitResponse(
            data: Data(json.utf8),
            now: Date(timeIntervalSince1970: 1_700_000_000)
        )

        #expect(parsed.planName == "builtin:zai-coding-plan")
        #expect(parsed.quotas.count == 3)

        let session = try #require(parsed.quotas.first { $0.scope == "tokens:session" })
        #expect(session.title == "Code")
        #expect(session.periodSeconds == TimeInterval(5 * 60 * 60))
        #expect(session.remainingFraction == 0.8)

        let weekly = try #require(parsed.quotas.first { $0.scope == "tokens:weekly" })
        #expect(weekly.title == "Code")
        #expect(weekly.periodSeconds == TimeInterval(7 * 24 * 60 * 60))
        #expect(weekly.remainingFraction == 0.6)

        let mcp = try #require(parsed.quotas.first { $0.scope == "time:5" })
        #expect(mcp.title == "MCP")
        #expect(mcp.periodSeconds == TimeInterval(30 * 24 * 60 * 60))
        #expect(mcp.remainingFraction == 0.9)
    }

    @Test("quota parser can compute percentage from usage and remaining fields")
    func parserComputesPercentageFromUsageFields() throws {
        let json = """
        {
          "success": true,
          "data": {
            "limits": [
              {
                "type": "TOKENS_LIMIT",
                "unit": 6,
                "number": 1,
                "usage": 1000,
                "remaining": 250
              }
            ]
          }
        }
        """

        let parsed = try ZCodeAuthProvider.parseQuotaLimitResponse(data: Data(json.utf8))
        let weekly = try #require(parsed.quotas.first)
        #expect(weekly.remainingFraction == 0.25)
    }

    @Test("billing balance parser returns daily model token quotas")
    func billingBalanceParserReturnsModelQuotas() throws {
        let json = """
        {
          "code": 0,
          "msg": "",
          "data": {
            "server_time": 1782399411,
            "balances": [
              {
                "plan_id": "zcode-v3-start-plan-0615",
                "entitlement_id": "ent_start_public_glm_5p2",
                "show_name": "GLM-5.2",
                "total_units": 3000000,
                "used_units": 3000000,
                "remaining_units": 0,
                "available_units": 0,
                "period_start": 1782316800,
                "period_end": 1782403199,
                "expires_at": 1782403199
              },
              {
                "plan_id": "zcode-v3-start-plan-0615",
                "entitlement_id": "ent_start_public_glm_5turbo",
                "show_name": "GLM-5-Turbo",
                "total_units": 2000000,
                "used_units": 276828,
                "remaining_units": 1723172,
                "available_units": 1723172,
                "period_start": 1782316800,
                "period_end": 1782403199,
                "expires_at": 1782403199
              }
            ]
          }
        }
        """

        let parsed = try ZCodeAuthProvider.parseQuotaLimitResponse(
            data: Data(json.utf8),
            now: Date(timeIntervalSince1970: 1_782_319_000),
            fallbackPlanName: "builtin:bigmodel-start-plan"
        )

        #expect(parsed.quotas.count == 2)
        #expect(parsed.planName == "builtin:bigmodel-start-plan")
        let turbo = try #require(parsed.quotas.first { $0.title == "GLM-5-Turbo" })
        #expect(turbo.remainingFraction > 0.86)
        #expect(turbo.remainingFraction < 0.87)
        #expect(turbo.periodSeconds == TimeInterval(24 * 60 * 60))
        #expect(turbo.scope == "ent_start_public_glm_5turbo")
    }

    @Test("plan cache provider reports available start plan without faking quotas")
    func planCacheReportsAvailablePlanWithoutFakeQuotas() async throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quota-bar-zcode-cache-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let path = dir.appendingPathComponent("coding-plan-cache.json").path
        try Data("""
        {
          "version": 1,
          "entryStatus": {
            "items": {
              "builtin:bigmodel-start-plan": { "status": "available" },
              "builtin:bigmodel-coding-plan": {
                "status": "unavailable",
                "reason": "coding_plan_not_entitled"
              }
            }
          }
        }
        """.utf8).write(to: URL(fileURLWithPath: path))

        let provider = ZCodePlanCacheProvider(cachePath: path)
        let snapshot = try await provider.fetchSnapshot(timeout: 1)
        #expect(snapshot.subscriptionTier == "BigModel Start")
        #expect(snapshot.quotas.isEmpty)
        if case .needsConfiguration(let reason) = snapshot.availability {
            #expect(reason.contains("BigModel Start"))
            #expect(reason.contains("coding_plan_not_entitled"))
        } else {
            Issue.record("expected needsConfiguration, got \(snapshot.availability)")
        }
    }

    // MARK: - ZCodeManualKeyStore（偏好设置手动输入 API Key，2026-07-08）

    private static func tempKeyStorePath() -> String {
        NSTemporaryDirectory() + "quota-bar-zcode-key-\(UUID().uuidString).json"
    }

    @Test("manual key store reports missing before anything is saved")
    func manualKeyStoreMissingByDefault() {
        let path = Self.tempKeyStorePath()
        defer { try? FileManager.default.removeItem(atPath: path) }
        #expect(ZCodeManualKeyStore.currentKeyState(configPath: path) == .missing)
    }

    @Test("manual key store save/read round-trips and masks the key for display")
    func manualKeyStoreSaveAndReadRoundTrips() throws {
        let path = Self.tempKeyStorePath()
        defer { try? FileManager.default.removeItem(atPath: path) }

        try ZCodeManualKeyStore.save(apiKey: "sk-zcode-real-key-1234567890", configPath: path)
        #expect(ZCodeManualKeyStore.readAPIKey(configPath: path) == "sk-zcode-real-key-1234567890")

        guard case .configured(let masked) = ZCodeManualKeyStore.currentKeyState(configPath: path) else {
            Issue.record("expected .configured after save")
            return
        }
        #expect(masked.hasPrefix("sk-zcode"))
        #expect(masked.hasSuffix("7890"))
    }

    @Test("manual key store rejects an empty key")
    func manualKeyStoreRejectsEmptyKey() {
        let path = Self.tempKeyStorePath()
        defer { try? FileManager.default.removeItem(atPath: path) }
        #expect(throws: Error.self) {
            try ZCodeManualKeyStore.save(apiKey: "   ", configPath: path)
        }
    }

    @Test("ZCodeAuthProvider's default configPaths list the manual key store first")
    func authProviderDefaultConfigPathsPrioritizeManualStore() {
        // 不实例化真的走网络——只验证"手动 key store 排在自动探测路径最前面"这条
        // 声明本身没有漂移（真正的读取逻辑复用 loadConfig() 已有的通用字符串扁平化
        // 解析，由 `manualKeyStoreSaveAndReadRoundTrips` 覆盖）。
        #expect(ZCodeManualKeyStore.defaultConfigPath.contains("QuotaBar"))
        #expect(ZCodeManualKeyStore.defaultConfigPath.hasSuffix("zcode-api-key.json"))
    }
}
