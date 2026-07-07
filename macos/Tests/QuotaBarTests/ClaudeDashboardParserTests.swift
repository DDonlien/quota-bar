import Foundation
import Testing
@testable import QuotaBar

/// 覆盖 Claude web dashboard 的真实响应形状（five_hour/seven_day 等顶层字段，
/// 不在任何 usage/limits wrapper 下——这与 CodexBar / Claude-Usage-Tracker 两个
/// 独立参考实现交叉验证一致）。此前的 parser 只认 wrapper key 下的数组，导致
/// 真实响应恒等于空数组，是「Claude 额度获取失败」的根因。
@Suite("ClaudeDashboardParser")
struct ClaudeDashboardParserTests {

    @Test("parses real five_hour / seven_day / seven_day_sonnet shape")
    func parsesRealShape() throws {
        let json: [String: Any] = [
            "five_hour": ["utilization": 25, "resets_at": "2026-07-06T20:00:00Z"],
            "seven_day": ["utilization": 40, "resets_at": "2026-07-10T00:00:00Z"],
            "seven_day_sonnet": ["utilization": 15, "resets_at": "2026-07-10T00:00:00Z"],
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let windows = try #require(ClaudeDashboardParser().parse(data: data))
        #expect(windows.count == 3)
        // five_hour/seven_day 只是时间维度，title 留空（跟 Codex 一致，见
        // ClaudeUsageWindowParser 里的说明）；用 periodSeconds 区分。
        let session = try #require(windows.first { $0.title.isEmpty && $0.periodSeconds == TimeInterval(5 * 3600) })
        #expect(session.remainingFraction == 0.75)
        #expect(session.periodSeconds == TimeInterval(5 * 3600))
        let weekly = try #require(windows.first { $0.title.isEmpty && $0.periodSeconds == TimeInterval(7 * 86400) })
        #expect(weekly.remainingFraction == 0.6)
        let sonnet = try #require(windows.first { $0.title == "Weekly (Sonnet)" })
        #expect(sonnet.remainingFraction == 0.85)
    }

    @Test("prefers seven_day_sonnet over seven_day_opus when both present")
    func prefersSonnetOverOpus() throws {
        let json: [String: Any] = [
            "five_hour": ["utilization": 0],
            "seven_day_sonnet": ["utilization": 10],
            "seven_day_opus": ["utilization": 90],
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let windows = try #require(ClaudeDashboardParser().parse(data: data))
        #expect(windows.contains { $0.title == "Weekly (Sonnet)" })
        #expect(!windows.contains { $0.title == "Weekly (Opus)" })
    }

    @Test("falls back to opus window when sonnet is absent")
    func fallsBackToOpus() throws {
        let json: [String: Any] = [
            "five_hour": ["utilization": 0],
            "seven_day_opus": ["utilization": 33],
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let windows = try #require(ClaudeDashboardParser().parse(data: data))
        #expect(windows.contains { $0.title == "Weekly (Opus)" })
    }

    @Test("returns nil when no known or fallback fields are present")
    func returnsNilForEmptyResponse() {
        let data = try! JSONSerialization.data(withJSONObject: ["unrelated": "field"] as [String: Any])
        #expect(ClaudeDashboardParser().parse(data: data) == nil)
    }

    @Test("organizations response selects org with chat capability over api-only org")
    func selectsChatCapableOrg() throws {
        let json: [[String: Any]] = [
            ["uuid": "api-only-org", "name": "Billing", "capabilities": ["api"]],
            ["uuid": "chat-org", "name": "Personal", "capabilities": ["chat", "claude_code"]],
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let url = try #require(ClaudeDashboardParser.usageURL(from: data))
        #expect(url.absoluteString == "https://claude.ai/api/organizations/chat-org/usage")
    }

    @Test("falls back to first org when no capabilities metadata present")
    func fallsBackToFirstOrgWithoutCapabilities() throws {
        let json: [[String: Any]] = [
            ["uuid": "only-org", "name": "Personal"],
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let url = try #require(ClaudeDashboardParser.usageURL(from: data))
        #expect(url.absoluteString == "https://claude.ai/api/organizations/only-org/usage")
    }

    @Test("handles wrapped {\"organizations\": [...]} shape too")
    func handlesWrappedOrganizations() throws {
        let json: [String: Any] = [
            "organizations": [
                ["uuid": "wrapped-org", "capabilities": ["chat"]],
            ],
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let url = try #require(ClaudeDashboardParser.usageURL(from: data))
        #expect(url.absoluteString == "https://claude.ai/api/organizations/wrapped-org/usage")
    }
}
