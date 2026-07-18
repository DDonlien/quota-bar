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
