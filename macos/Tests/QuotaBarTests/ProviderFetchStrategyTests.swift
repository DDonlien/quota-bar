import Foundation
import Testing
@testable import QuotaBar

@Suite("Provider fetch strategy ordering")
struct ProviderFetchStrategyTests {
    @Test("source index does not let a quota-only source shadow a full provider source")
    @MainActor
    func quotaOnlySourceCannotShadowFullSource() async throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = ProviderSourceIndexStore(directoryURL: dir)
        store.recordSuccess(
            kind: .kimi,
            layer: .quota,
            sourceKind: .configFile,
            sourceId: "partial",
            at: Date(timeIntervalSince1970: 200)
        )

        let pipeline = FetchPipeline(
            kind: .kimi,
            strategies: [
                StubStrategy(id: "full", layers: [.quota, .expiration, .plan], markerTier: "Full"),
                StubStrategy(id: "partial", layers: [.quota], markerTier: "Partial"),
            ],
            runMode: .sequential,
            sourceIndexStore: store
        )

        let snapshot = try await pipeline.run(timeout: 1)
        #expect(snapshot.subscriptionTier == "Full")
    }

    @Test("cached source agreeing across all requested layers is tried before an earlier-declared strategy")
    @MainActor
    func cachedSourceAgreeingAcrossLayersTriesFirst() async throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = ProviderSourceIndexStore(directoryURL: dir)
        // 同一个来源在 quota 和 plan 两层都是上次成功来源——一致，值得信任优先尝试。
        for layer in [ProviderFetchLayer.quota, .plan] {
            store.recordSuccess(
                kind: .kimi, layer: layer, sourceKind: .configFile,
                sourceId: "declaredSecond", at: Date(timeIntervalSince1970: 200)
            )
        }

        let pipeline = FetchPipeline(
            kind: .kimi,
            strategies: [
                StubStrategy(id: "declaredFirst", layers: [.quota, .expiration, .plan], markerTier: "First"),
                StubStrategy(id: "declaredSecond", layers: [.quota, .expiration, .plan], markerTier: "Second"),
            ],
            runMode: .sequential,
            sourceIndexStore: store
        )

        let snapshot = try await pipeline.run(timeout: 1)
        // 即使 "declaredSecond" 在数组里排第二，两层一致的缓存应该让它被优先尝试，
        // 成功后直接采用——不需要再跑声明顺序里排第一的 "declaredFirst"。
        #expect(snapshot.subscriptionTier == "Second")
    }

    @Test("cached source that fails falls through to the full declared-order pass")
    @MainActor
    func cachedSourceFailureFallsThroughToFullPass() async throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = ProviderSourceIndexStore(directoryURL: dir)
        for layer in [ProviderFetchLayer.quota, .plan] {
            store.recordSuccess(
                kind: .kimi, layer: layer, sourceKind: .configFile,
                sourceId: "cachedButNowBroken", at: Date(timeIntervalSince1970: 200)
            )
        }

        let pipeline = FetchPipeline(
            kind: .kimi,
            strategies: [
                ThrowingStubStrategy(id: "cachedButNowBroken"),
                StubStrategy(id: "declaredSecond", layers: [.quota, .expiration, .plan], markerTier: "Second"),
            ],
            runMode: .sequential,
            sourceIndexStore: store
        )

        let snapshot = try await pipeline.run(timeout: 1)
        // 缓存来源这次失败了；不能因为"试过缓存"就放弃，完整 fallback 还是要把
        // 剩下的 strategy（这里是 "declaredSecond"）跑一遍。
        #expect(snapshot.subscriptionTier == "Second")
    }

    @Test("Antigravity pipeline order is RPC then running-CLI then managed CLI session then keychain")
    @MainActor
    func antigravityPipelineOrder() {
        let pipeline = try! #require(ProviderPipelines.makePipelines().first { $0.providerKind == .antigravity })
        #expect(pipeline.strategies.map(\.id) == [
            "antigravity-rpc",
            "antigravity-cli",
            "antigravity-cli-session",
            "antigravity-keychain",
        ])
    }

    private static func makeTempDirectory() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quota-bar-provider-fetch-tests-\(UUID().uuidString)", isDirectory: true)
    }
}

private struct ThrowingStubStrategy: ProviderFetchStrategy {
    let id: String

    var displayName: String { id }
    var kind: ProviderKind { .kimi }
    var sourceKind: ProviderSourceKind { .configFile }
    var supportedLayers: Set<ProviderFetchLayer> { [.quota, .expiration, .plan] }

    func fetch(timeout: TimeInterval) async throws -> ProviderSnapshot {
        throw QuotaFetchError.transient(detail: "stub 故意失败，模拟缓存来源这次失效")
    }
}

private struct StubStrategy: ProviderFetchStrategy {
    let id: String
    let layers: Set<ProviderFetchLayer>
    let markerTier: String

    var displayName: String { id }
    var kind: ProviderKind { .kimi }
    var sourceKind: ProviderSourceKind { .configFile }
    var supportedLayers: Set<ProviderFetchLayer> { layers }

    func fetch(timeout: TimeInterval) async throws -> ProviderSnapshot {
        ProviderSnapshot(
            kind: .kimi,
            subscriptionTier: markerTier,
            availability: .available,
            quotas: [
                QuotaWindow(
                    title: "Code",
                    remainingFraction: 0.7,
                    refreshDescription: "1h",
                    periodSeconds: 5 * 60 * 60,
                    subscriptionGroup: ProviderKind.kimi.rawValue
                )
            ],
            monthlyPrice: "¥49/月",
            subscriptionExpiresAt: markerTier == "Full" ? Date(timeIntervalSince1970: 1_800_000_000) : nil,
            fetchedAt: Date()
        )
    }
}
