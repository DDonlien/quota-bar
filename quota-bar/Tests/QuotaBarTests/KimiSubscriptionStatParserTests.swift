import Foundation
import Testing
@testable import QuotaBar

// MARK: - KimiSubscriptionStatParser 订阅到期日测试（v0.6.0 DATA-A）
//
// 覆盖：
// 1. GetSubscriptionStat 不再负责返回 UI 展示的最后有效日
// 2. Work quota 的 resetsAt 不再等于 expireTime（修复 v0.3.0 错塞 bug）
// 3. Code 5h / 周额度的 resetsAt 仍走 ratelimitCode5h.resetTime 等
// 4. 边界：没 subscriptionBalance / expireTime 解析失败

@Suite("KimiSubscriptionStatParser — 订阅到期日 (v0.6.0)")
struct KimiSubscriptionStatParserTests {

    private static func fixtureJSON() -> [String: Any] {
        [
            "ratelimitCode5h": [
                "enabled": true,
                "resetTime": "2026-06-25T18:00:00Z",
                "ratio": 0.10,
            ],
            "ratelimitCode7d": [
                "enabled": true,
                "resetTime": "2026-06-30T12:00:00Z",
                "ratio": 0.30,
            ],
            "subscriptionBalance": [
                "amountUsedRatio": 0.62,
                "kimiCodeUsedRatio": 0.15,
                "expireTime": "2026-08-15T10:30:00.000Z",
            ],
        ]
    }

    private static func makeData(_ json: [String: Any]) -> Data {
        try! JSONSerialization.data(withJSONObject: json)
    }

    @Test("parseSubscriptionExpiresAt 不使用 subscriptionBalance.expireTime 作为展示日期")
    func statExpireTimeIsNotDisplayExpiry() {
        let parser = KimiSubscriptionStatParser()
        let data = Self.makeData(Self.fixtureJSON())
        #expect(parser.parseSubscriptionExpiresAt(data: data) == nil)
    }

    @Test("Work quota 的 resetsAt 不再等于 expireTime（v0.6.0 修复）")
    func workQuotaResetsAtIsNil() throws {
        let parser = KimiSubscriptionStatParser()
        let data = Self.makeData(Self.fixtureJSON())
        let windows = try #require(parser.parse(data: data))
        let workPredicate: (QuotaWindow) -> Bool = { $0.title == "Work" && $0.scope == "work" }
        let work = windows.first(where: workPredicate)
        #expect(work?.resetsAt == nil)
    }

    @Test("Code 5h / 周额度的 resetsAt 仍走 ratelimitCode5h/7d.resetTime")
    func codeQuotasRetainResetsAt() throws {
        let parser = KimiSubscriptionStatParser()
        let data = Self.makeData(Self.fixtureJSON())
        let windows = try #require(parser.parse(data: data))
        let code5hPredicate: (QuotaWindow) -> Bool = { $0.title == "Code" && $0.periodSeconds == 5 * 3600 }
        let codeWeeklyPredicate: (QuotaWindow) -> Bool = { $0.title == "Code" && $0.periodSeconds == 7 * 86400 }
        let code5h = windows.first(where: code5hPredicate)
        let codeWeekly = windows.first(where: codeWeeklyPredicate)
        #expect(code5h?.resetsAt != nil)
        #expect(codeWeekly?.resetsAt != nil)
    }

    @Test("ratelimit 无 ratio 时用 subscriptionBalance.kimiCodeUsedRatio 填充 Code 额度")
    func codeQuotasUseKimiCodeUsedRatioFallback() throws {
        let parser = KimiSubscriptionStatParser()
        let json: [String: Any] = [
            "ratelimitCode5h": [
                "enabled": true,
                "resetTime": "2026-07-02T19:15:47.914900774Z",
            ],
            "ratelimitCode7d": [
                "enabled": true,
                "resetTime": "2026-07-09T14:15:47.914900774Z",
            ],
            "subscriptionBalance": [
                "amountUsedRatio": 1,
                "kimiCodeUsedRatio": 0.2989,
                "expireTime": "2026-07-10T00:00:00Z",
            ],
        ]
        let windows = try #require(parser.parse(data: Self.makeData(json)))
        let codeWindows = windows.filter { $0.title == "Code" }
        #expect(codeWindows.count == 2)
        for window in codeWindows {
            #expect(abs(window.remainingFraction - 0.7011) < 0.0001)
        }
    }

    @Test("没有 subscriptionBalance 字段时 parseSubscriptionExpiresAt 返回 nil")
    func noBalanceField() {
        let parser = KimiSubscriptionStatParser()
        let json: [String: Any] = [
            "ratelimitCode5h": ["enabled": true, "resetTime": "2026-06-25T18:00:00Z"],
        ]
        let data = Self.makeData(json)
        #expect(parser.parseSubscriptionExpiresAt(data: data) == nil)
    }

    @Test("expireTime 解析失败时 parseSubscriptionExpiresAt 返回 nil（不 throw）")
    func invalidExpireTime() {
        let parser = KimiSubscriptionStatParser()
        let json: [String: Any] = [
            "subscriptionBalance": [
                "amountUsedRatio": 0.5,
                "expireTime": "not-a-date",
            ],
        ]
        let data = Self.makeData(json)
        #expect(parser.parseSubscriptionExpiresAt(data: data) == nil)
    }

    @Test("GetSubscription.nextBillingTime 转换为本地自然日的前一天")
    func subscriptionRenewalDateConvertedToLastValidDate() throws {
        let parser = KimiSubscriptionParser()
        let data = Self.makeData([
            "subscription": [
                "nextBillingTime": "2026-07-09T14:33:09.134631Z",
                "goods": [
                    "title": "Andante",
                    "amounts": [["priceInCents": "4900"]],
                ],
            ],
        ])

        let expiresAt = try #require(parser.parseSubscriptionExpiresAt(data: data))
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: expiresAt)
        #expect(comps.year == 2026)
        #expect(comps.month == 7)
        #expect(comps.day == 8)
    }
}
