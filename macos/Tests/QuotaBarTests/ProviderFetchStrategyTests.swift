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

    @Test("Antigravity pipeline order is RPC then CLI then keychain")
    @MainActor
    func antigravityPipelineOrder() {
        let pipeline = try! #require(ProviderPipelines.makePipelines().first { $0.providerKind == .antigravity })
        #expect(pipeline.strategies.map(\.id) == [
            "antigravity-rpc",
            "antigravity-cli",
            "antigravity-keychain",
        ])
    }

    private static func makeTempDirectory() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quota-bar-provider-fetch-tests-\(UUID().uuidString)", isDirectory: true)
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
