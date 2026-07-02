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
}
