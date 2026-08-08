import Foundation
import Testing
@testable import QuotaBar

/// 分组分层获取方案的核心行为：首个成功来源做基底，后续来源补缺失层。
@Suite("FetchPipeline layered merge")
struct FetchPipelineLayeredMergeTests {

    @Test("Kimi work-only base merges code windows from CLI source")
    @MainActor
    func mergesMissingQuotaScopes() async throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = ProviderSourceIndexStore(directoryURL: dir)

        let pipeline = FetchPipeline(
            kind: .kimi,
            strategies: [
                LayerStubStrategy(
                    id: "kimi-desktop-token",
                    layers: [.quota, .expiration, .plan],
                    tier: "Andante",
                    price: "¥49/月",
                    expiresAt: Date(timeIntervalSince1970: 1_800_000_000),
                    windows: [Self.window(title: "Work", scope: "work", period: 30 * 86400)]
                ),
                LayerStubStrategy(
                    id: "kimi-auth",
                    layers: [.quota],
                    tier: "Trial（已购）",
                    price: "¥46/月",
                    expiresAt: nil,
                    windows: [
                        Self.window(title: "Code", scope: "code", period: 5 * 3600),
                        Self.window(title: "Code", scope: "code", period: 7 * 86400),
                    ]
                ),
            ],
            runMode: .sequential,
            expectedQuotaScopes: ["work", "code"],
            sourceIndexStore: store
        )

        let snapshot = try await pipeline.run(timeout: 1)
        // 基底字段来自 desktop token
        #expect(snapshot.subscriptionTier == "Andante")
        #expect(snapshot.monthlyPrice == "¥49/月")
        #expect(snapshot.subscriptionExpiresAt != nil)
        // code scope 从 CLI 来源合并进来
        #expect(snapshot.quotas.count == 3)
        #expect(snapshot.quotas.contains { $0.scope == "work" })
        #expect(snapshot.quotas.filter { $0.scope == "code" }.count == 2)
    }

    @Test("base failure falls back to code-only source without merge")
    @MainActor
    func fallsBackWhenBaseFails() async throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = ProviderSourceIndexStore(directoryURL: dir)

        let pipeline = FetchPipeline(
            kind: .kimi,
            strategies: [
                FailingStubStrategy(id: "kimi-desktop-token", layers: [.quota, .expiration, .plan]),
                LayerStubStrategy(
                    id: "kimi-auth",
                    layers: [.quota],
                    tier: "Trial（已购）",
                    price: "¥46/月",
                    expiresAt: nil,
                    windows: [Self.window(title: "Code", scope: "code", period: 5 * 3600)]
                ),
            ],
            runMode: .sequential,
            expectedQuotaScopes: ["work", "code"],
            sourceIndexStore: store
        )

        let snapshot = try await pipeline.run(timeout: 1)
        #expect(snapshot.subscriptionTier == "Trial（已购）")
        #expect(snapshot.quotas.count == 1)
    }

    @Test("merge does not duplicate windows with same scope")
    @MainActor
    func mergeDeduplicatesByScope() {
        let base = ProviderSnapshot(
            kind: .kimi,
            subscriptionTier: "Andante",
            availability: .available,
            quotas: [Self.window(title: "Code", scope: "code", period: 5 * 3600)],
            monthlyPrice: "¥49/月",
            fetchedAt: Date()
        )
        let addition = ProviderSnapshot(
            kind: .kimi,
            subscriptionTier: "Trial（已购）",
            availability: .available,
            quotas: [
                Self.window(title: "Code", scope: "code", period: 7 * 86400),
                Self.window(title: "Work", scope: "work", period: 30 * 86400),
            ],
            monthlyPrice: "¥46/月",
            fetchedAt: Date()
        )
        let merged = FetchPipeline.mergeLayers(base: base, addition: addition)
        // code scope 已存在 → 整个 scope 不追加；work 是新 scope → 追加
        #expect(merged.quotas.count == 2)
        #expect(merged.quotas.contains { $0.scope == "work" })
        #expect(merged.subscriptionTier == "Andante")
    }

    @Test("notSubscribed marker from later source overrides tier-only base, dropping windows")
    @MainActor
    func mergePropagatesNotSubscribedMarker() {
        let base = ProviderSnapshot(
            kind: .claude,
            subscriptionTier: "Pro",
            availability: .available,
            quotas: [Self.window(title: "", scope: "go", period: 5 * 3600)],
            monthlyPrice: "¥136/月",
            fetchedAt: Date()
        )
        let marker = ProviderSnapshot(
            kind: .claude,
            availability: .notSubscribed(reason: "Claude 无有效订阅（额度窗口无重置时间）"),
            quotas: [],
            monthlyPrice: nil,
            fetchedAt: Date()
        )
        let merged = FetchPipeline.mergeLayers(base: base, addition: marker)
        guard case .notSubscribed = merged.availability else {
            Issue.record("期望 notSubscribed，实际 \(merged.availability)")
            return
        }
        // 误导性额度窗口被丢弃；base 已知档位/价格保留供 header 展示。
        #expect(merged.quotas.isEmpty)
        #expect(merged.subscriptionTier == "Pro")
        #expect(merged.monthlyPrice == "¥136/月")
    }

    @Test("subscriptionExpired marker from later source overrides available base")
    @MainActor
    func mergePropagatesSubscriptionExpiredMarker() {
        let base = ProviderSnapshot(
            kind: .codex,
            subscriptionTier: "Plus",
            availability: .available,
            quotas: [Self.window(title: "", scope: "go", period: 7 * 86400)],
            monthlyPrice: "$20/月",
            subscriptionExpiresAt: Date(timeIntervalSince1970: 1_700_000_000),
            fetchedAt: Date()
        )
        let marker = ProviderSnapshot(
            kind: .codex,
            subscriptionTier: "Plus",
            availability: .subscriptionExpired(plan: "Plus", expiredAt: Date(timeIntervalSince1970: 1_700_000_000)),
            quotas: [],
            monthlyPrice: nil,
            fetchedAt: Date()
        )
        let merged = FetchPipeline.mergeLayers(base: base, addition: marker)
        guard case .subscriptionExpired = merged.availability else {
            Issue.record("期望 subscriptionExpired，实际 \(merged.availability)")
            return
        }
        #expect(merged.quotas.isEmpty)
        #expect(merged.subscriptionExpiresAt != nil)
    }

    @Test("pipeline returns notSubscribed marker when later strategy reports it")
    @MainActor
    func pipelineSurfacesNotSubscribedFromLaterStrategy() async throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = ProviderSourceIndexStore(directoryURL: dir)

        let pipeline = FetchPipeline(
            kind: .opencode,
            strategies: [
                LayerStubStrategy(
                    id: "opencode-auth",
                    layers: [.plan],
                    tier: "Go",
                    price: nil,
                    expiresAt: nil,
                    windows: []
                ),
                NotSubscribedStubStrategy(id: "opencode-webview"),
            ],
            runMode: .sequential,
            expectedQuotaScopes: ["go"],
            sourceIndexStore: store
        )

        let snapshot = try await pipeline.run(timeout: 1)
        guard case .notSubscribed = snapshot.availability else {
            Issue.record("期望 notSubscribed，实际 \(snapshot.availability)")
            return
        }
        #expect(snapshot.quotas.isEmpty)
    }

    private static func window(title: String, scope: String, period: TimeInterval) -> QuotaWindow {
        QuotaWindow(
            title: title,
            remainingFraction: 0.5,
            refreshDescription: "1h",
            periodSeconds: period,
            scope: scope,
            subscriptionGroup: ProviderKind.kimi.rawValue
        )
    }

    private static func makeTempDirectory() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quota-bar-layered-merge-tests-\(UUID().uuidString)", isDirectory: true)
    }
}

private struct LayerStubStrategy: ProviderFetchStrategy {
    let id: String
    let layers: Set<ProviderFetchLayer>
    let tier: String
    let price: String?
    let expiresAt: Date?
    let windows: [QuotaWindow]

    var displayName: String { id }
    var kind: ProviderKind { .kimi }
    var sourceKind: ProviderSourceKind { .configFile }
    var supportedLayers: Set<ProviderFetchLayer> { layers }

    func fetch(timeout: TimeInterval) async throws -> ProviderSnapshot {
        ProviderSnapshot(
            kind: .kimi,
            subscriptionTier: tier,
            availability: .available,
            quotas: windows,
            monthlyPrice: price,
            subscriptionExpiresAt: expiresAt,
            subscriptionExpiresAtSource: expiresAt != nil ? .api : nil,
            subscriptionExpiresAtConfidence: expiresAt != nil ? .high : nil,
            fetchedAt: Date()
        )
    }
}

private struct FailingStubStrategy: ProviderFetchStrategy {
    let id: String
    let layers: Set<ProviderFetchLayer>

    var displayName: String { id }
    var kind: ProviderKind { .kimi }
    var sourceKind: ProviderSourceKind { .configFile }
    var supportedLayers: Set<ProviderFetchLayer> { layers }

    func fetch(timeout: TimeInterval) async throws -> ProviderSnapshot {
        throw QuotaFetchError.transient(detail: "stub failure")
    }
}

private struct NotSubscribedStubStrategy: ProviderFetchStrategy {
    let id: String

    var displayName: String { id }
    var kind: ProviderKind { .opencode }
    var sourceKind: ProviderSourceKind { .webViewSession }
    var supportedLayers: Set<ProviderFetchLayer> { [.quota, .plan] }

    func fetch(timeout: TimeInterval) async throws -> ProviderSnapshot {
        ProviderSnapshot(
            kind: .opencode,
            availability: .notSubscribed(reason: "workspace 未订阅 opencode Go"),
            quotas: [],
            monthlyPrice: nil,
            fetchedAt: Date()
        )
    }
}
