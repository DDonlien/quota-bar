import Foundation
import Testing
@testable import QuotaBar

@Suite("StatusBarController")
struct StatusBarControllerTests {
    @Test("needsConfiguration 不绘制菜单栏占位 bar")
    @MainActor
    func needsConfigurationIsNotDrawable() {
        let snapshots = [
            ProviderSnapshot(
                kind: .antigravity,
                availability: .needsConfiguration(reason: "找不到 language_server"),
                quotas: [],
                monthlyPrice: nil,
                fetchedAt: Date()
            ),
            ProviderSnapshot(
                kind: .codex,
                availability: .available,
                quotas: [
                    QuotaWindow(title: "5 小时额度", remainingFraction: 0.8, refreshDescription: "4h")
                ],
                monthlyPrice: "¥136/月",
                fetchedAt: Date()
            ),
        ]

        let drawable = StatusBarController.drawableSnapshots(from: snapshots)
        #expect(drawable.map { $0.kind } == [ProviderKind.codex])
    }
}
