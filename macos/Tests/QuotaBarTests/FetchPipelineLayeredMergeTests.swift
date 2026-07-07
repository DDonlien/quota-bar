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
    let price: String
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
