import Foundation
import Testing
@testable import QuotaBar

// MARK: - CursorHarvester 解析订阅管理页 DOM 测试

@Suite("CursorHarvester")
struct CursorHarvesterTests {

    @Test("识别「Pro plan renews on July 25, 2026」")
    func proPlanRenews() {
        let html = #"<div class="plan-card"><h3>Pro plan</h3><span>Pro plan renews on July 25, 2026</span></div>"#
        let date = CursorHarvester().extract(from: html)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 7)
        #expect(comps.day == 25)
    }

    @Test("识别「Business plan renews on Sep 1, 2026」")
    func businessPlanRenews() {
        let html = #"<span>Business plan renews on Sep 1, 2026</span>"#
        let date = CursorHarvester().extract(from: html)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 9)
        #expect(comps.day == 1)
    }

    @Test("识别「Subscription ends on 2026-07-25」")
    func subscriptionEndsISO() {
        let html = #"<p>Subscription ends on 2026-07-25</p>"#
        let date = CursorHarvester().extract(from: html)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 7)
        #expect(comps.day == 25)
    }

    @Test("识别「Renews on Nov 12, 2026」")
    func renewsShort() {
        let html = #"<span>Renews on Nov 12, 2026</span>"#
        let date = CursorHarvester().extract(from: html)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 11)
        #expect(comps.day == 12)
    }

    @Test("无关键词时返回 nil（不被无关日期误导）")
    func noKeyword() {
        let html = #"<div>Joined Cursor: 2024-03-15</div><div>Last active: 2026-06-20</div>"#
        #expect(CursorHarvester().extract(from: html) == nil)
    }

    @Test("pageURL 指向 cursor.com/dashboard")
    func pageURLValue() {
        #expect(CursorHarvester().pageURL.absoluteString == "https://cursor.com/dashboard")
        #expect(CursorHarvester().identifier == "cursor-harvester")
    }
}