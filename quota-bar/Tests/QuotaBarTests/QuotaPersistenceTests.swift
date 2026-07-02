import Foundation
import Testing
@testable import QuotaBar

@Suite("Quota persistence")
struct QuotaPersistenceTests {
    @Test("snapshot cache round-trips available snapshot as stale")
    @MainActor
    func snapshotCacheRoundTripsAsStale() throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = ProviderSnapshotCacheStore(directoryURL: dir)
        let snapshot = ProviderSnapshot(
            kind: .codex,
            subscriptionTier: "Plus",
            availability: .available,
            quotas: [
                QuotaWindow(
                    title: "Code",
                    remainingFraction: 0.42,
                    refreshDescription: "1d",
                    periodSeconds: 7 * 24 * 60 * 60,
                    subscriptionGroup: ProviderKind.codex.rawValue
                )
            ],
            monthlyPrice: "$20/月",
            subscriptionExpiresAt: Date(timeIntervalSince1970: 1_800_000_000),
            fetchedAt: Date(timeIntervalSince1970: 1_790_000_000)
        )

        store.store(snapshot, sourceKind: .configFile, sourceId: "codex-auth")

        let reloaded = ProviderSnapshotCacheStore(directoryURL: dir)
        let cached = try #require(reloaded.snapshot(for: .codex))
        #expect(cached.isStale)
        #expect(cached.subscriptionTier == "Plus")
        #expect(cached.quotas.count == 1)
        #expect(cached.quotas[0].remainingFraction == 0.42)
    }

    @Test("snapshot cache discards corrupt file")
    @MainActor
    func snapshotCacheDiscardsCorruptFile() throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data("not-json".utf8).write(to: dir.appendingPathComponent("snapshots.json"))

        let store = ProviderSnapshotCacheStore(directoryURL: dir)
        #expect(store.loadAll().isEmpty)
    }

    @Test("snapshot cache drops deprecated Codex local-log estimates")
    @MainActor
    func snapshotCacheDropsCodexLocalLogEstimates() throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = ProviderSnapshotCacheStore(directoryURL: dir)

        store.store(
            ProviderSnapshot(
                kind: .codex,
                availability: .available,
                quotas: [
                    QuotaWindow(
                        title: "",
                        remainingFraction: 1,
                        refreshDescription: "5h",
                        periodSeconds: 5 * 60 * 60,
                        subscriptionGroup: ProviderKind.codex.rawValue
                    )
                ],
                monthlyPrice: nil,
                fetchedAt: Date()
            ),
            sourceKind: .localLog,
            sourceId: "codex-cli"
        )

        let reloaded = ProviderSnapshotCacheStore(directoryURL: dir)
        #expect(reloaded.snapshot(for: .codex) == nil)
    }

    @Test("ineligible snapshot removes old cache")
    @MainActor
    func ineligibleSnapshotRemovesOldCache() throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = ProviderSnapshotCacheStore(directoryURL: dir)

        store.store(ProviderSnapshot(
            kind: .kimi,
            availability: .available,
            quotas: [QuotaWindow(title: "Code", remainingFraction: 0.7, refreshDescription: "1h")],
            monthlyPrice: "¥49/月",
            fetchedAt: Date()
        ))
        #expect(store.snapshot(for: .kimi) != nil)

        store.store(ProviderSnapshot(
            kind: .kimi,
            availability: .fetchFailed(reason: "network"),
            quotas: [],
            monthlyPrice: nil,
            fetchedAt: Date()
        ))
        #expect(store.snapshot(for: .kimi) == nil)
    }

    @Test("source index keeps last successful source preferred after a failure")
    @MainActor
    func sourceIndexPreferenceSurvivesFailure() throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = ProviderSourceIndexStore(directoryURL: dir)

        store.recordSuccess(
            kind: .codex,
            layer: .quota,
            sourceKind: .configFile,
            sourceId: "codex-auth",
            at: Date(timeIntervalSince1970: 100)
        )
        store.recordFailure(
            kind: .codex,
            layer: .quota,
            sourceKind: .configFile,
            sourceId: "codex-auth",
            error: "temporary",
            at: Date(timeIntervalSince1970: 200)
        )

        #expect(store.preferredSourceID(for: .codex, layer: .quota) == "codex-auth")
    }

    private static func makeTempDirectory() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quota-bar-persistence-tests-\(UUID().uuidString)", isDirectory: true)
    }
}
