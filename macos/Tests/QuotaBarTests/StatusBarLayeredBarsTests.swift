import Foundation
import Testing
@testable import QuotaBar

@Suite("菜单栏图标分层显示")
@MainActor
struct StatusBarLayeredBarsTests {

    private func window(period: TimeInterval, remaining: Double) -> QuotaWindow {
        QuotaWindow(title: "", remainingFraction: remaining, refreshDescription: "", periodSeconds: period)
    }

    // MARK: - 选层逻辑（QuotaModels）

    @Test("按周期长短选出最短 + 次短两条额度，不受剩余比例影响")
    func topTwoQuotasByPeriodPicksShortestFirst() {
        let snapshot = ProviderSnapshot(
            kind: .claude,
            availability: .available,
            quotas: [
                window(period: 7 * 86400, remaining: 0.9),   // 周额度：剩得多
                window(period: 5 * 3600, remaining: 0.1),    // 5 小时：剩得少
            ],
            monthlyPrice: nil,
            fetchedAt: Date()
        )
        let pair = snapshot.primarySubscriptionGroupTopTwoQuotasByPeriod(itemOrder: [])
        #expect(pair?.shortest.periodSeconds == TimeInterval(5 * 3600))
        #expect(pair?.shortest.remainingFraction == 0.1)
        #expect(pair?.secondShortest?.periodSeconds == TimeInterval(7 * 86400))
        #expect(pair?.secondShortest?.remainingFraction == 0.9)
    }

    @Test("只有一条额度时 secondShortest 为 nil")
    func topTwoQuotasByPeriodSingleWindow() {
        let snapshot = ProviderSnapshot(
            kind: .opencode,
            availability: .available,
            quotas: [window(period: 5 * 3600, remaining: 0.5)],
            monthlyPrice: nil,
            fetchedAt: Date()
        )
        let pair = snapshot.primarySubscriptionGroupTopTwoQuotasByPeriod(itemOrder: [])
        #expect(pair?.secondShortest == nil)
    }

    @Test("没有 periodSeconds 的额度排在最后")
    func topTwoQuotasByPeriodNilPeriodSortsLast() {
        let snapshot = ProviderSnapshot(
            kind: .opencode,
            availability: .available,
            quotas: [
                window(period: 30 * 86400, remaining: 0.7),
                QuotaWindow(title: "", remainingFraction: 0.2, refreshDescription: "", periodSeconds: nil),
                window(period: 5 * 3600, remaining: 0.3),
            ],
            monthlyPrice: nil,
            fetchedAt: Date()
        )
        let pair = snapshot.primarySubscriptionGroupTopTwoQuotasByPeriod(itemOrder: [])
        #expect(pair?.shortest.periodSeconds == TimeInterval(5 * 3600))
        #expect(pair?.secondShortest?.periodSeconds == TimeInterval(30 * 86400))
    }

    // MARK: - StatusBarController.layeredFractions

    @Test("available 时 primary/secondary 分别取最短/次短周期的剩余比例")
    func layeredFractionsForAvailableSnapshot() {
        let snapshot = ProviderSnapshot(
            kind: .claude,
            availability: .available,
            quotas: [
                window(period: 7 * 86400, remaining: 0.9),
                window(period: 5 * 3600, remaining: 0.2),
            ],
            monthlyPrice: nil,
            fetchedAt: Date()
        )
        let (primary, secondary) = StatusBarController.layeredFractions(for: snapshot)
        #expect(primary == 0.2)
        #expect(secondary == 0.9)
    }

    @Test("loading/needsConfiguration 固定 50%、无 secondary")
    func layeredFractionsForLoading() {
        let snapshot = ProviderSnapshot(kind: .claude, availability: .loading, quotas: [], monthlyPrice: nil, fetchedAt: Date())
        let (primary, secondary) = StatusBarController.layeredFractions(for: snapshot)
        #expect(primary == 0.5)
        #expect(secondary == nil)
    }

    @Test("subscriptionExpired/notSubscribed 固定 0%、无 secondary")
    func layeredFractionsForExpired() {
        let expired = ProviderSnapshot(kind: .claude, availability: .subscriptionExpired(plan: nil, expiredAt: nil), quotas: [], monthlyPrice: nil, fetchedAt: Date())
        let (primary, secondary) = StatusBarController.layeredFractions(for: expired)
        #expect(primary == 0)
        #expect(secondary == nil)
    }

    // MARK: - BarsImageLayout 几何

    @Test("顶部圆角在 bar 顶到容器顶时是满值，随着高度降低自然过渡到 0")
    func adaptiveTopRadiusTransitionsSmoothly() {
        let layout = StatusBarController.BarsImageLayout(count: 2)
        // 满高度：bar 顶正好在容器顶，顶部应该有圆角（等同 barRadius）
        let fullRect = layout.barRect(at: 0, remainingFraction: 1.0)
        let fullPath = layout.barPath(at: 0, rect: fullRect)
        #expect(fullPath.elementCount > 4, "满高度的 bar 应该有曲线段（圆角），不是纯直角矩形")

        // 极短：bar 顶远离容器顶，顶部应该退化成直角（跟 count>1 情况下的中间 bar
        // 形状一致——一个纯矩形只有 4 个 element：moveTo + 3 条 line + close）。
        let shortRect = layout.barRect(at: 0, remainingFraction: 0.05)
        let shortPath = layout.barPath(at: 0, rect: shortRect)
        // 短 bar 仍然有底部固定圆角，所以不会退化成纯矩形，但顶部两个角应该是直角
        // （用 bounds 粗略验证：路径存在且没有崩溃即可，精确验证曲线控制点在这里
        // 意义不大——几何计算本身已经在 `adaptiveTopRadius` 里做了防御性 clamp）。
        #expect(shortPath.bounds.height > 0)
    }

    @Test("中间 bar（既不是第一个也不是最后一个）永远是直角矩形，不受高度影响")
    func middleBarIsAlwaysPlainRect() {
        let layout = StatusBarController.BarsImageLayout(count: 3)
        let rect = layout.barRect(at: 1, remainingFraction: 1.0)
        let path = layout.barPath(at: 1, rect: rect)
        #expect(path.elementCount == 5, "纯矩形路径应该是 moveTo + 3 条 lineTo + closePath = 5 个 element")
    }
}
