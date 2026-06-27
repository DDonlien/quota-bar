import Foundation
import Testing
@testable import QuotaBar

// MARK: - ClaudeHarvester 解析订阅管理页 DOM 测试

@Suite("ClaudeHarvester")
struct ClaudeHarvesterTests {

    @Test("识别「Next billing on July 25, 2026」")
    func nextBillingLong() {
        let html = #"<div>Next billing on July 25, 2026</div>"#
        let date = ClaudeHarvester().extract(from: html)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 7)
        #expect(comps.day == 25)
    }

    @Test("识别「Subscription renewal: 2026-12-15」")
    func subscriptionRenewalISO() {
        let html = #"<p>Subscription renewal: 2026-12-15</p>"#
        let date = ClaudeHarvester().extract(from: html)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 12)
        #expect(comps.day == 15)
    }

    @Test("识别「Renews on Aug 3, 2026」")
    func renewsShort() {
        let html = #"<span>Renews on Aug 3, 2026</span>"#
        let date = ClaudeHarvester().extract(from: html)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 8)
        #expect(comps.day == 3)
    }

    @Test("无关键词时返回 nil")
    func noKeyword() {
        let html = #"<div>Subscription starts: January 1, 2024</div>"#
        #expect(ClaudeHarvester().extract(from: html) == nil)
    }

    @Test("pageURL 指向 claude.ai/settings/plan")
    func pageURLValue() {
        #expect(ClaudeHarvester().pageURL.absoluteString == "https://claude.ai/settings/plan")
        #expect(ClaudeHarvester().identifier == "claude-harvester")
    }
}