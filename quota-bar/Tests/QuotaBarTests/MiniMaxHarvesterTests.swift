import Foundation
import Testing
@testable import QuotaBar

// MARK: - MiniMaxHarvester 解析订阅管理页 DOM 测试

@Suite("MiniMaxHarvester")
struct MiniMaxHarvesterTests {

    @Test("识别中文「到期日：2026年7月25日」")
    func expiresAtChinese() {
        let html = #"<div><span>到期日：</span><strong>2026年7月25日</strong></div>"#
        let date = MiniMaxHarvester().extract(from: html)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 7)
        #expect(comps.day == 25)
    }

    @Test("识别「续费日期：2026-12-15」")
    func renewalDateISO() {
        let html = #"<span>续费日期：2026-12-15</span>"#
        let date = MiniMaxHarvester().extract(from: html)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 12)
        #expect(comps.day == 15)
    }

    @Test("识别「下次扣费：Aug 3, 2026」（英文 i18n 切换时）")
    func nextChargeEnglish() {
        let html = #"<div>下次扣费：Aug 3, 2026</div>"#
        let date = MiniMaxHarvester().extract(from: html)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 8)
        #expect(comps.day == 3)
    }

    @Test("识别「Next billing on July 25, 2026」")
    func nextBillingEnglish() {
        let html = #"<p>Next billing on July 25, 2026</p>"#
        let date = MiniMaxHarvester().extract(from: html)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 7)
        #expect(comps.day == 25)
    }

    @Test("无关键词时返回 nil")
    func noKeyword() {
        let html = #"<div>账户创建：2024年1月1日</div><div>最近登录：2026年6月20日</div>"#
        #expect(MiniMaxHarvester().extract(from: html) == nil)
    }

    @Test("pageURL 指向 platform.minimaxi.com console plan")
    func pageURLValue() {
        #expect(MiniMaxHarvester().pageURL.absoluteString == "https://platform.minimaxi.com/console/plan")
        #expect(MiniMaxHarvester().identifier == "minimax-harvester")
    }
}
