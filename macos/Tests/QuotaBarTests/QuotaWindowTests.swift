import Foundation
import Testing
@testable import QuotaBar

@Suite("QuotaWindow.idealRemainingFraction")
struct QuotaWindowIdealRemainingFractionTests {
    private let periodSeconds: TimeInterval = 7 * 24 * 60 * 60  // 7 天周期

    private func makeWindow(resetsAt: Date?) -> QuotaWindow {
        QuotaWindow(
            title: "Code",
            remainingFraction: 0.5,
            refreshDescription: "",
            resetsAt: resetsAt,
            periodSeconds: periodSeconds
        )
    }

    @Test("day 1 of a 7-day period: 6 days until reset → ideal remaining is 6/7")
    func day1Of7() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let resetsAt = now.addingTimeInterval(6 * 24 * 60 * 60)  // 还剩 6 天到重置
        let window = makeWindow(resetsAt: resetsAt)
        let ideal = window.idealRemainingFraction(relativeTo: now)
        #expect(ideal != nil)
        #expect(abs(ideal! - 6.0 / 7.0) < 0.0001)
    }

    @Test("just reset: full period remaining → ideal remaining is 1.0")
    func periodStart() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let resetsAt = now.addingTimeInterval(periodSeconds)
        let window = makeWindow(resetsAt: resetsAt)
        #expect(window.idealRemainingFraction(relativeTo: now) == 1.0)
    }

    @Test("right at reset time: ideal remaining is 0")
    func periodEnd() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let window = makeWindow(resetsAt: now)
        #expect(window.idealRemainingFraction(relativeTo: now) == 0.0)
    }

    @Test("stale resetsAt in the past clamps to 0, does not go negative")
    func pastResetClamps() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let resetsAt = now.addingTimeInterval(-3600)
        let window = makeWindow(resetsAt: resetsAt)
        #expect(window.idealRemainingFraction(relativeTo: now) == 0.0)
    }

    @Test("missing periodSeconds (fixed quota) returns nil")
    func missingPeriodSeconds() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let window = QuotaWindow(
            title: "Fixed Pack",
            remainingFraction: 0.5,
            refreshDescription: "",
            resetsAt: now.addingTimeInterval(3600),
            periodSeconds: nil
        )
        #expect(window.idealRemainingFraction(relativeTo: now) == nil)
    }

    @Test("missing resetsAt returns nil")
    func missingResetsAt() {
        let window = makeWindow(resetsAt: nil)
        #expect(window.idealRemainingFraction() == nil)
    }
}

/// 2026-07-30：节奏指示点改为随时间连续更新（`QuotaRow` 用 `TimelineView` 每秒重算）。
///
/// 这里锁定它依赖的那条性质：`idealRemainingFraction` 是时间的**连续**函数——
/// 相邻时刻只差极小的量。视图侧原本 5 分钟才重建一次，于是把这条连续曲线渲染成了
/// 大步跳变；函数本身一直是对的，所以测试只需要证明"按秒采样确实是平滑的"，
/// 这样每秒驱动一次就必然得到自然移动。
@Suite("节奏指示点随时间连续变化")
struct PaceMarkerContinuityTests {
    private static func window(periodSeconds: TimeInterval, resetsIn: TimeInterval, now: Date) -> QuotaWindow {
        QuotaWindow(
            title: "Code",
            remainingFraction: 0.5,
            refreshDescription: "-",
            resetsAt: now.addingTimeInterval(resetsIn),
            periodSeconds: periodSeconds,
            subscriptionGroup: ProviderKind.kimi.rawValue
        )
    }

    @Test("每秒采样的位移是亚像素级的，不是大步跳变")
    func perSecondStepIsSubPixel() throws {
        let now = Date()
        // 5 小时窗口，刚好过半
        let w = Self.window(periodSeconds: 5 * 3600, resetsIn: 2.5 * 3600, now: now)
        let a = try #require(w.idealRemainingFraction(relativeTo: now))
        let b = try #require(w.idealRemainingFraction(relativeTo: now.addingTimeInterval(1)))

        #expect(b < a, "时间前进，理想剩余比例必须下降")
        // 1 秒 / 5 小时 ≈ 0.0056%；在 200pt 宽的条上约 0.011pt，肉眼无跳变
        #expect(abs(a - b) < 0.0001)
    }

    @Test("整段区间内单调下降")
    func monotonicallyDecreases() throws {
        let now = Date()
        let w = Self.window(periodSeconds: 3600, resetsIn: 3600, now: now)
        var previous = 1.1
        for minute in stride(from: 0.0, through: 60.0, by: 5.0) {
            let f = try #require(w.idealRemainingFraction(relativeTo: now.addingTimeInterval(minute * 60)))
            #expect(f < previous, "第 \(minute) 分钟应低于上一采样点")
            previous = f
        }
        #expect(previous == 0, "窗口走完时理想剩余应为 0")
    }
}

/// 2026-07-30：重置倒计时改为按当下时间现算（`QuotaRow.refreshText(at:)`），
/// 不再沿用抓取那一刻算好的字符串。
///
/// 这里锁的是 `QuotaResetText` 这一侧的两条性质：现算结果确实随时间递减，以及
/// `resetsAt` 缺失时必须保留原文——有些来源的 `refreshDescription` 根本不是倒计时
/// 而是描述性文案（MiniMax 的「Coding Plan 主套餐」），那些窗口不带 `resetsAt`，
/// 一旦被误当成倒计时重算就会把文案冲掉。
@Suite("重置倒计时随时间递减")
struct ResetCountdownTests {
    @Test("同一个 resetsAt，越晚看剩余越少")
    func countsDown() {
        let reset = Date().addingTimeInterval(2 * 3600 + 10 * 60)
        let now = Date()
        #expect(QuotaResetText.description(for: reset, relativeTo: now) == "2h10m")
        #expect(QuotaResetText.description(for: reset, relativeTo: now.addingTimeInterval(60)) == "2h9m")
        #expect(QuotaResetText.description(for: reset, relativeTo: now.addingTimeInterval(3600)) == "1h10m")
    }

    /// 一小时以内精确到秒——这正是"按秒重算"这个粒度有意义的原因。
    @Test("一小时以内逐秒变化")
    func ticksBySecondUnderAnHour() {
        let reset = Date().addingTimeInterval(90)
        let now = Date()
        #expect(QuotaResetText.description(for: reset, relativeTo: now) == "1m30s")
        #expect(QuotaResetText.description(for: reset, relativeTo: now.addingTimeInterval(1)) == "1m29s")
    }

    @Test("已过重置时刻显示已重置")
    func showsResetWhenPast() {
        let now = Date()
        #expect(QuotaResetText.description(for: now.addingTimeInterval(-1), relativeTo: now) == "已重置")
    }

    /// 回归保护：没有 `resetsAt` 的窗口必须原样保留 `refreshDescription`。
    @Test("缺少 resetsAt 的窗口保留原始描述文案")
    func keepsOriginalTextWithoutResetsAt() {
        let w = QuotaWindow(
            title: "Coding Plan",
            remainingFraction: 0.8,
            refreshDescription: "Coding Plan 主套餐",
            periodSeconds: 30 * 86400
        )
        #expect(w.resetsAt == nil)
        #expect(w.refreshDescription == "Coding Plan 主套餐")
        // resetsAt 为 nil 时也算不出理想剩余比例，节奏指示点同样不该出现
        #expect(w.idealRemainingFraction() == nil)
    }
}
