import Foundation
import Testing
@testable import QuotaBar

// MARK: - AntigravityHarvester 解析订阅管理页 DOM 测试

@Suite("AntigravityHarvester")
struct AntigravityHarvesterTests {

    @Test("识别 Google 风格「Mon, Jul 25, 2026」")
    func googleStyleShort() {
        let html = #"<div>Next billing on Mon, Jul 25, 2026</div>"#
        let date = AntigravityHarvester().extract(from: html)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 7)
        #expect(comps.day == 25)
    }

    @Test("识别 Google 风格「Wednesday, July 25, 2026」")
    func googleStyleLong() {
        let html = #"<p>Next billing on Wednesday, July 25, 2026</p>"#
        let date = AntigravityHarvester().extract(from: html)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 7)
        #expect(comps.day == 25)
    }

    @Test("识别「Plan renews on 2026-07-25」")
    func planRenewsISO() {
        let html = #"<span>Plan renews on 2026-07-25</span>"#
        let date = AntigravityHarvester().extract(from: html)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 7)
        #expect(comps.day == 25)
    }

    @Test("识别「Renews on August 3, 2026」")
    func renewsLong() {
        let html = #"<div>Renews on August 3, 2026</div>"#
        let date = AntigravityHarvester().extract(from: html)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 8)
        #expect(comps.day == 3)
    }

    @Test("无关键词时返回 nil")
    func noKeyword() {
        let html = #"<div>Account created: Jan 1, 2024</div><div>Plan ends: 2026-06-20</div>"#
        // 注意 "Plan ends" 不在关键词列表里（避免抓 trial end / grace period）
        #expect(AntigravityHarvester().extract(from: html) == nil)
    }

    @Test("pageURL 指向 antigravity.google/settings")
    func pageURLValue() {
        #expect(AntigravityHarvester().pageURL.absoluteString == "https://antigravity.google/settings")
        #expect(AntigravityHarvester().identifier == "antigravity-harvester")
    }
}