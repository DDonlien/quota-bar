import Foundation
import Testing
@testable import QuotaBar

// MARK: - ProviderSnapshot.subscriptionExpiresAt fallback 改 hide 后的行为

@Suite("ProviderSnapshot — subscriptionExpiresAt fallback (v0.6.0)")
struct ProviderSnapshotExpiresAtTests {

    /// 没传 subscriptionExpiresAt 时，**不应** fallback 到 quota 窗口 resetsAt。
    /// 历史背景：v0.3.0-UI-A-010 落地时 `quotas.map(\.resetsAt).max()` 推断
    /// 被实测为「乱写」（5h 窗口 → 5h 后、5h+周 → 7d 后）。v0.6.0 改 nil fallback。
    @Test("无 subscriptionExpiresAt 且 quotas 含 resetsAt 时，subscriptionExpiresAt 必须是 nil")
    func noFallbackToMaxResetsAt() {
        let now = Date()
        let futureDate = now.addingTimeInterval(5 * 3600)  // 5h 后
        let weeklyDate = now.addingTimeInterval(7 * 86400)  // 7d 后

        let quotas = [
            QuotaWindow(title: "5h", remainingFraction: 0.5, refreshDescription: "5h", resetsAt: futureDate, periodSeconds: 5 * 3600),
            QuotaWindow(title: "weekly", remainingFraction: 0.3, refreshDescription: "7d", resetsAt: weeklyDate, periodSeconds: 7 * 86400),
        ]
        let snapshot = ProviderSnapshot(
            kind: .codex,
            availability: .available,
            quotas: quotas,
            monthlyPrice: "$20/月",
            fetchedAt: now
        )
        // v0.6.0 改 hide：nil（不再是 weeklyDate 也不是 futureDate）
        #expect(snapshot.subscriptionExpiresAt == nil)
    }

    @Test("显式传 subscriptionExpiresAt 时优先使用")
    func explicitTakesPrecedence() {
        let now = Date()
        let realExpires = now.addingTimeInterval(30 * 86400)  // 30d 后（真实续费日）
        let quotaReset = now.addingTimeInterval(5 * 3600)  // 5h 后（quota 重置）

        let quotas = [
            QuotaWindow(title: "5h", remainingFraction: 0.5, refreshDescription: "5h", resetsAt: quotaReset, periodSeconds: 5 * 3600),
        ]
        let snapshot = ProviderSnapshot(
            kind: .codex,
            availability: .available,
            quotas: quotas,
            monthlyPrice: "$20/月",
            subscriptionExpiresAt: realExpires,
            fetchedAt: now
        )
        #expect(snapshot.subscriptionExpiresAt == realExpires)
    }

    @Test("无 quotas、也无 subscriptionExpiresAt 时是 nil")
    func noQuotasNoExpiresAt() {
        let snapshot = ProviderSnapshot(
            kind: .codex,
            availability: .available,
            quotas: [],
            monthlyPrice: nil,
            fetchedAt: Date()
        )
        #expect(snapshot.subscriptionExpiresAt == nil)
    }

    /// loading 占位 snapshot 的 subscriptionExpiresAt 仍为 nil（不影响 loading UI）。
    @Test("loading snapshot 的 subscriptionExpiresAt 是 nil")
    func loadingSnapshotExpiresAt() {
        let snapshot = ProviderSnapshot.loading(kind: .kimi)
        #expect(snapshot.subscriptionExpiresAt == nil)
    }
}
