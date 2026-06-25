import Foundation
import SwiftUI

/// 占位 Provider：用静态数据模拟真实刷新行为。
final class PlaceholderProvider: QuotaProvider, @unchecked Sendable {
    let id: String
    let kind: ProviderKind
    let displayName: String

    private let quotas: [QuotaWindow]
    private let monthlyPrice: String

    init(
        id: String,
        kind: ProviderKind,
        displayName: String,
        monthlyPrice: String,
        quotas: [QuotaWindow]
    ) {
        self.id = id
        self.kind = kind
        self.displayName = displayName
        self.monthlyPrice = monthlyPrice
        self.quotas = quotas
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let delayMs = UInt64.random(in: 100...300)
        try await Task.sleep(nanoseconds: delayMs * 1_000_000)

        return ProviderSnapshot(
            kind: kind,
            availability: .available,
            quotas: quotas,
            monthlyPrice: monthlyPrice,
            fetchedAt: Date()
        )
    }
}

enum PlaceholderProviders {
    static func defaults() -> [QuotaProvider] {
        let now = Date()
        let calendar = Calendar.current
        let nextRefresh = calendar.date(byAdding: .hour, value: 5, to: now) ?? now

        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 H:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        let refreshText = "\(formatter.string(from: nextRefresh))刷新"

        return [
            PlaceholderProvider(
                id: "codex",
                kind: .codex,
                displayName: "Codex",
                monthlyPrice: "¥150/月",
                quotas: [
                    QuotaWindow(title: "", remainingFraction: 1.0, refreshDescription: refreshText, resetsAt: nextRefresh, periodSeconds: 5 * 3600),
                    QuotaWindow(title: "", remainingFraction: 0.64, refreshDescription: refreshText, resetsAt: nextRefresh, periodSeconds: 7 * 86400)
                ]
            ),
            PlaceholderProvider(
                id: "minimax",
                kind: .minimax,
                displayName: "MiniMax",
                monthlyPrice: "¥150/月",
                quotas: [
                    QuotaWindow(title: "", remainingFraction: 0.0, refreshDescription: refreshText, resetsAt: nextRefresh, periodSeconds: 5 * 3600),
                    QuotaWindow(title: "", remainingFraction: 1.0, refreshDescription: refreshText, resetsAt: nextRefresh, periodSeconds: 7 * 86400)
                ]
            ),
            PlaceholderProvider(
                id: "kimi",
                kind: .kimi,
                displayName: "Kimi",
                monthlyPrice: "¥150/月",
                quotas: [
                    QuotaWindow(title: "", remainingFraction: 0.28, refreshDescription: refreshText, resetsAt: nextRefresh, periodSeconds: 5 * 3600),
                    QuotaWindow(title: "", remainingFraction: 1.0, refreshDescription: refreshText, resetsAt: nextRefresh, periodSeconds: 7 * 86400)
                ]
            )
        ]
    }
}
