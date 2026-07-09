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

    /// 回归测试：2026-07-07 用户看真实日志时反馈"日志里都是失败"，看着像额度一直没拿到；
    /// 但实际额度早就被声明顺序里更靠前的来源满足了，只是档位/价格还缺，后续来源只是在
    /// 为档位重试。根因是 `logAttempt` 原来无条件按 `strategy.supportedLayers` 记录，不管
    /// 这一轮到底是为了补哪一层——补层失败时会连带记一条误导性的"额度获取失败"。
    @Test("merge-branch strategy failures only log the layer actually being retried, not a spurious quota failure")
    @MainActor
    func mergeBranchFailureOnlyLogsMissingLayer() async throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = ProviderSourceIndexStore(directoryURL: dir)
        // 独立的临时日志文件——避免写到 `ProviderCheckLog.shared` 背后真实用户机器上的
        // 诊断日志（`~/Library/Application Support/QuotaBar/provider-check.log`）。
        let logFileURL = dir.appendingPathComponent("provider-check.log")
        let checkLog = ProviderCheckLog(store: ProviderCheckLogStore(fileURL: logFileURL))

        let pipeline = FetchPipeline(
            kind: .antigravity,
            strategies: [
                QuotaOnlyStubStrategy(id: "quota-source"),
                ThrowingBothLayersStubStrategy(id: "plan-filler"),
            ],
            runMode: .sequential,
            sourceIndexStore: store,
            checkLog: checkLog
        )

        let snapshot = try await pipeline.run(timeout: 1)
        // 额度已经被第一个来源满足；第二个来源只是为了补档位，重试失败不该影响额度。
        #expect(snapshot.quotas.count == 2)
        #expect(snapshot.subscriptionTier == nil)

        let lines = await checkLog.flush(kind: .antigravity)
        #expect(!lines.contains { $0.contains("额度获取") && $0.contains("plan-filler") },
                 "额度已经由 quota-source 满足，plan-filler 的失败不该在「额度获取」步骤留下误导性记录")
        #expect(lines.contains { $0.contains("档位与费用获取") && $0.contains("plan-filler") && $0.contains("失败") },
                 "plan-filler 确实是为了补档位才被重试，「档位与费用获取」步骤应该如实记录它的失败")
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

/// 只贡献额度层、tier/price 为 nil——用来模拟 Antigravity `antigravity-cli-session`
/// 这种"能拿到额度但拿不到档位"的真实场景。
private struct QuotaOnlyStubStrategy: ProviderFetchStrategy {
    let id: String

    var displayName: String { id }
    var kind: ProviderKind { .antigravity }
    var sourceKind: ProviderSourceKind { .cli }
    var supportedLayers: Set<ProviderFetchLayer> { [.quota, .plan] }

    func fetch(timeout: TimeInterval) async throws -> ProviderSnapshot {
        ProviderSnapshot(
            kind: .antigravity,
            subscriptionTier: nil,
            availability: .available,
            quotas: [
                QuotaWindow(title: "A", remainingFraction: 0.5, refreshDescription: "1h", periodSeconds: 3600, subscriptionGroup: ProviderKind.antigravity.rawValue),
                QuotaWindow(title: "B", remainingFraction: 0.5, refreshDescription: "1h", periodSeconds: 7200, subscriptionGroup: ProviderKind.antigravity.rawValue),
            ],
            monthlyPrice: nil,
            fetchedAt: Date()
        )
    }
}

/// 同时声明支持额度+档位两层、但每次都失败——用来模拟 `antigravity-rpc`/`antigravity-cli`
/// 这种"IDE 没开、直接失败"的场景，此时它其实只是被拉来补档位层。
private struct ThrowingBothLayersStubStrategy: ProviderFetchStrategy {
    let id: String

    var displayName: String { id }
    var kind: ProviderKind { .antigravity }
    var sourceKind: ProviderSourceKind { .rpc }
    var supportedLayers: Set<ProviderFetchLayer> { [.quota, .plan] }

    func fetch(timeout: TimeInterval) async throws -> ProviderSnapshot {
        throw QuotaFetchError.sourceUnavailable(detail: "stub 故意失败，模拟 IDE 未运行")
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
