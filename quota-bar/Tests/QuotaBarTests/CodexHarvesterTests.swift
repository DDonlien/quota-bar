import Foundation
import Testing
@testable import QuotaBar

// MARK: - CodexHarvester 解析订阅管理页 DOM 测试

@Suite("CodexHarvester")
struct CodexHarvesterTests {

    @Test("识别「Next billing on July 25, 2026」")
    func nextBillingLong() {
        let html = #"<div class="billing"><span>Next billing on</span> <strong>July 25, 2026</strong></div>"#
        let date = CodexHarvester().extract(from: html)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 7)
        #expect(comps.day == 25)
    }

    @Test("识别「Renews on Jul 25, 2026」")
    func renewsShort() {
        let html = #"<p>Renews on Jul 25, 2026 at midnight UTC.</p>"#
        let date = CodexHarvester().extract(from: html)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 7)
        #expect(comps.day == 25)
    }

    @Test("识别 ISO 8601 日期「2026-07-25」")
    func iso8601Date() {
        let html = #"<span>Billing date:</span> 2026-07-25"#
        let date = CodexHarvester().extract(from: html)
        let comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 7)
        #expect(comps.day == 25)
    }

    @Test("无关键词时返回 nil（不抓无关日期）")
    func noKeyword() {
        // 页面上有日期但没有「Next billing」之类关键词 → 不应被识别为续费日
        let html = #"<div>Account created: January 1, 2024</div><div>Last login: 2026-06-20</div>"#
        #expect(CodexHarvester().extract(from: html) == nil)
    }

    @Test("空字符串返回 nil")
    func empty() {
        #expect(CodexHarvester().extract(from: "") == nil)
    }

    @Test("pageURL 指向 chatgpt.com/account/manage")
    func pageURLValue() {
        #expect(CodexHarvester().pageURL.absoluteString == "https://chatgpt.com/account/manage")
        #expect(CodexHarvester().identifier == "codex-harvester")
    }
}