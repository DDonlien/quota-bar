import Foundation
import Testing
@testable import QuotaBar

// MARK: - 测试用 Harvester（验证 firstDate 解析多种格式）

private struct FixtureHarvester: SubscriptionDateHarvester {
    let identifier = "fixture"
    let pageURL = URL(string: "https://example.com/account")!

    func extract(from pageSource: String) -> Date? {
        firstDate(in: pageSource, candidates: [
            // ISO 8601 with fractional
            "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d+)?Z?",
            // 美式 "July 25, 2026" / "Jul 25, 2026"
            "\\b(?:January|February|March|April|May|June|July|August|September|October|November|December)\\s+\\d{1,2},\\s+\\d{4}\\b",
            "\\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\s+\\d{1,2},\\s+\\d{4}\\b",
            // 中文
            "\\d{4}年\\d{1,2}月\\d{1,2}日",
        ])
    }
}

@Suite("SubscriptionDateHarvester")
struct SubscriptionDateHarvesterTests {

    @Test("解析 ISO 8601 with fractional seconds")
    func iso8601Fractional() {
        let html = "<div>Renews on 2026-07-25T10:30:00.000Z</div>"
        let date = FixtureHarvester().extract(from: html)
        #expect(date != nil)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 7)
        #expect(comps.day == 25)
    }

    @Test("解析 ISO 8601 without fractional")
    func iso8601Plain() {
        let html = "<span>Next billing: 2026-12-01T00:00:00Z</span>"
        let date = FixtureHarvester().extract(from: html)
        #expect(date != nil)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 12)
    }

    @Test("解析美式「July 25, 2026」")
    func usLong() {
        let html = "<p>Your plan renews on July 25, 2026</p>"
        let date = FixtureHarvester().extract(from: html)
        #expect(date != nil)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 7)
        #expect(comps.day == 25)
    }

    @Test("解析简写「Jul 25, 2026」")
    func usShort() {
        let html = "<p>Renews on Jul 25, 2026 at midnight</p>"
        let date = FixtureHarvester().extract(from: html)
        #expect(date != nil)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 7)
        #expect(comps.day == 25)
    }

    @Test("解析中文「2026年7月25日」")
    func zhCN() {
        let html = "<div>到期日：2026年7月25日</div>"
        let date = FixtureHarvester().extract(from: html)
        #expect(date != nil)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 7)
        #expect(comps.day == 25)
    }

    @Test("找不到日期时返回 nil（不 throw）")
    func noDateFound() {
        let html = "<html><body><h1>Account</h1><p>No date here.</p></body></html>"
        #expect(FixtureHarvester().extract(from: html) == nil)
    }

    @Test("空字符串返回 nil")
    func emptySource() {
        #expect(FixtureHarvester().extract(from: "") == nil)
    }
}
