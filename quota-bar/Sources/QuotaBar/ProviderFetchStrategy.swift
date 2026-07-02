import Foundation

/// ProviderFetchStrategy：单一数据拉取通道。
///
/// 每个 ProviderKind 暴露一组有序的 strategy，按顺序串行 fallback。
/// 设计参考 CodexBar 的 `ProviderFetchStrategy` + Pipeline 模式。
///
/// 实现职责：
/// - **自己负责超时控制**：通过 `timeout` 参数决定何时放弃；
/// - **失败抛 `QuotaFetchError`**：让上层区分 `missingCredentials` / `sourceUnavailable` / `transient`；
/// - **成功返回带真实数据的 `ProviderSnapshot`**：哪怕只拿到部分字段。
protocol ProviderFetchStrategy: Sendable {
    var id: String { get }
    var displayName: String { get }
    var kind: ProviderKind { get }
    var sourceKind: ProviderSourceKind { get }
    var supportedLayers: Set<ProviderFetchLayer> { get }
    var sourceMetadata: [String: String] { get }

    func fetch(timeout: TimeInterval) async throws -> ProviderSnapshot
}

extension ProviderFetchStrategy {
    var sourceKind: ProviderSourceKind { .unknown }
    var supportedLayers: Set<ProviderFetchLayer> { [.quota, .expiration, .plan] }
    var sourceMetadata: [String: String] { [:] }
}

// MARK: - Pipeline

/// 一组按顺序尝试的 strategy 集合。
///
/// 运行策略：
/// 1. **首次** 串行跑第一个可用 strategy，失败则降级到下一个；
/// 2. 后续 **并发** 跑所有 strategy 拿最佳快照（节省轮询时间）；
/// 3. 合并多次结果时按 `availability` + `quotas.count` 选最优。
@MainActor
final class FetchPipeline {

    enum RunMode {
        /// 串行：第一个 strategy 失败才尝试下一个（适合登录场景）。
        case sequential
        /// 并发：所有 strategy 同时跑，按优先级合并（适合轮询场景，默认）。
        case parallel
    }

    let providerKind: ProviderKind
    private(set) var strategies: [ProviderFetchStrategy]
    var runMode: RunMode
    private let sourceIndexStore: ProviderSourceIndexStore

    private(set) var lastSnapshots: [String: ProviderSnapshot] = [:]
    private(set) var lastErrors: [String: QuotaFetchError] = [:]

    init(
        kind: ProviderKind,
        strategies: [ProviderFetchStrategy],
        runMode: RunMode = .parallel,
        sourceIndexStore: ProviderSourceIndexStore = .shared
    ) {
        self.providerKind = kind
        self.strategies = strategies
        self.runMode = runMode
        self.sourceIndexStore = sourceIndexStore
    }

    func run(timeout: TimeInterval) async throws -> ProviderSnapshot {
        switch runMode {
        case .sequential:
            return try await runSequential(timeout: timeout)
        case .parallel:
            return await runParallel(timeout: timeout)
        }
    }

    private func runSequential(timeout: TimeInterval) async throws -> ProviderSnapshot {
        var fallbackError: QuotaFetchError?
        for strategy in orderedStrategies(for: [.quota, .expiration, .plan]) {
            do {
                let snapshot = try await strategy.fetch(timeout: timeout)
                lastSnapshots[strategy.id] = snapshot
                recordSuccess(strategy: strategy, snapshot: snapshot)
                return snapshot
            } catch let error as QuotaFetchError {
                lastErrors[strategy.id] = error
                recordError(error, strategy: strategy)

                fallbackError = preferredFallbackError(current: fallbackError, new: error)
            } catch {
                let transient = QuotaFetchError.transient(detail: error.localizedDescription)
                lastErrors[strategy.id] = transient
                recordError(transient, strategy: strategy)
                fallbackError = preferredFallbackError(current: fallbackError, new: transient)
            }
        }
        // 全失败时 throw，让 RefreshCoordinator 决定 fallback availability
        // （基于 service 是否已安装来决定 needsConfiguration vs notInstalled）。
        if let fallbackError {
            throw fallbackError
        }
        throw QuotaFetchError.sourceUnavailable(detail: "无可用数据源")
    }

    private func runParallel(timeout: TimeInterval) async -> ProviderSnapshot {
        let collected: [(String, Result<ProviderSnapshot, Error>)] = await withTaskGroup(of: (String, Result<ProviderSnapshot, Error>).self) { group in
            for strategy in strategies {
                let id = strategy.id
                group.addTask { [strategy] in
                    do {
                        let snapshot = try await strategy.fetch(timeout: timeout)
                        return (id, .success(snapshot))
                    } catch {
                        return (id, .failure(error))
                    }
                }
            }
            var results: [(String, Result<ProviderSnapshot, Error>)] = []
            for await result in group { results.append(result) }
            return results
        }

        return Self.merge(
            results: collected,
            snapshots: &lastSnapshots,
            errors: &lastErrors,
            fallback: fallbackSnapshot(error: nil),
            sourceIndexStore: sourceIndexStore,
            strategiesById: Dictionary(uniqueKeysWithValues: strategies.map { ($0.id, $0) })
        )
    }

    private func fallbackSnapshot(error: QuotaFetchError?) -> ProviderSnapshot {
        let now = Date()
        let availability = error?.availabilityFallback ?? .fetchFailed(reason: "无可用数据源")
        return ProviderSnapshot(
            kind: providerKind,
            availability: availability,
            quotas: [],
            monthlyPrice: providerKind.fallbackMonthlyPrice,
            fetchedAt: now
        )
    }

    private func preferredFallbackError(current: QuotaFetchError?, new: QuotaFetchError) -> QuotaFetchError {
        guard let current else { return new }
        return new.fallbackPriority > current.fallbackPriority ? new : current
    }

    private func orderedStrategies(for layers: [ProviderFetchLayer]) -> [ProviderFetchStrategy] {
        let preferredIds = layers.compactMap { layer in
            sourceIndexStore.preferredSourceID(for: providerKind, layer: layer)
        }
        guard !preferredIds.isEmpty else { return strategies }

        let requestedLayers = Set(layers)
        var ordered: [ProviderFetchStrategy] = []
        var seen = Set<String>()

        func hasFullCoverage(_ strategy: ProviderFetchStrategy) -> Bool {
            requestedLayers.isSubset(of: strategy.supportedLayers)
        }

        func append(_ strategy: ProviderFetchStrategy) {
            guard seen.insert(strategy.id).inserted else { return }
            ordered.append(strategy)
        }

        let preferredStrategies = preferredIds.compactMap { preferredId in
            strategies.first { $0.id == preferredId }
        }

        for strategy in preferredStrategies where hasFullCoverage(strategy) {
            append(strategy)
        }
        for strategy in strategies where hasFullCoverage(strategy) {
            append(strategy)
        }
        for strategy in preferredStrategies {
            append(strategy)
        }
        for strategy in strategies {
            append(strategy)
        }
        return ordered
    }

    private func recordSuccess(strategy: ProviderFetchStrategy, snapshot: ProviderSnapshot) {
        for layer in successfulLayers(from: snapshot).intersection(strategy.supportedLayers) {
            sourceIndexStore.recordSuccess(
                kind: providerKind,
                layer: layer,
                sourceKind: strategy.sourceKind,
                sourceId: strategy.id,
                metadata: strategy.sourceMetadata,
                at: snapshot.fetchedAt
            )
        }
    }

    private func recordError(_ error: QuotaFetchError, strategy: ProviderFetchStrategy) {
        let semanticLayers = successfulLayers(from: error).intersection(strategy.supportedLayers)
        if semanticLayers.isEmpty {
            for layer in strategy.supportedLayers {
                sourceIndexStore.recordFailure(
                    kind: providerKind,
                    layer: layer,
                    sourceKind: strategy.sourceKind,
                    sourceId: strategy.id,
                    error: error.localizedDescription,
                    metadata: strategy.sourceMetadata
                )
            }
        } else {
            for layer in semanticLayers {
                sourceIndexStore.recordSuccess(
                    kind: providerKind,
                    layer: layer,
                    sourceKind: strategy.sourceKind,
                    sourceId: strategy.id,
                    metadata: strategy.sourceMetadata
                )
            }
        }
    }

    private func successfulLayers(from snapshot: ProviderSnapshot) -> Set<ProviderFetchLayer> {
        var layers: Set<ProviderFetchLayer> = [.provider]
        switch snapshot.availability {
        case .available:
            if !snapshot.quotas.isEmpty {
                layers.insert(.quota)
            }
            if snapshot.subscriptionTier != nil || snapshot.monthlyPrice != nil {
                layers.insert(.plan)
            }
            if snapshot.subscriptionExpiresAt != nil {
                layers.insert(.expiration)
            }
        case .subscriptionExpired(let plan, let expiredAt):
            layers.insert(.expiration)
            if plan != nil {
                layers.insert(.plan)
            }
            if expiredAt != nil {
                layers.insert(.expiration)
            }
        case .notSubscribed:
            layers.insert(.expiration)
        case .needsConfiguration, .loading, .notInstalled, .fetchFailed:
            break
        }
        return layers
    }

    private func successfulLayers(from error: QuotaFetchError) -> Set<ProviderFetchLayer> {
        switch error {
        case .subscriptionExpired(let plan, let expiredAt):
            var layers: Set<ProviderFetchLayer> = [.expiration]
            if plan != nil || expiredAt != nil {
                layers.insert(.plan)
            }
            return layers
        case .notSubscribed:
            return [.expiration]
        case .missingCredentials, .permissionRequired, .sourceUnavailable, .transient:
            return []
        }
    }

    // MARK: - 合并

    private static func merge(
        results: [(String, Result<ProviderSnapshot, Error>)],
        snapshots: inout [String: ProviderSnapshot],
        errors: inout [String: QuotaFetchError],
        fallback: ProviderSnapshot,
        sourceIndexStore: ProviderSourceIndexStore,
        strategiesById: [String: ProviderFetchStrategy]
    ) -> ProviderSnapshot {
        let priority: (ProviderAvailability) -> Int = { availability in
            switch availability {
            case .available: return 5
            case .subscriptionExpired: return 4
            case .notSubscribed: return 4
            case .needsConfiguration: return 3
            // v0.8.0：subscriptionExpired 优先级与 needsConfiguration 同级（都是"配置相关"问题）
            case .loading: return 2
            case .notInstalled: return 1
            case .fetchFailed: return 0
            }
        }

        var best: ProviderSnapshot?

        for (id, result) in results {
            switch result {
            case .success(let snapshot):
                snapshots[id] = snapshot
                if let strategy = strategiesById[id] {
                    let layers = successfulLayersForMerge(from: snapshot).intersection(strategy.supportedLayers)
                    for layer in layers {
                        sourceIndexStore.recordSuccess(
                            kind: snapshot.kind,
                            layer: layer,
                            sourceKind: strategy.sourceKind,
                            sourceId: strategy.id,
                            metadata: strategy.sourceMetadata,
                            at: snapshot.fetchedAt
                        )
                    }
                }
                if let current = best {
                    let pa = priority(snapshot.availability)
                    let pb = priority(current.availability)
                    if pa > pb || (pa == pb && snapshot.quotas.count > current.quotas.count) {
                        best = snapshot
                    }
                } else {
                    best = snapshot
                }
            case .failure(let error):
                if let qe = error as? QuotaFetchError {
                    errors[id] = qe
                    if let strategy = strategiesById[id] {
                        for layer in strategy.supportedLayers {
                            sourceIndexStore.recordFailure(
                                kind: strategy.kind,
                                layer: layer,
                                sourceKind: strategy.sourceKind,
                                sourceId: strategy.id,
                                error: qe.localizedDescription,
                                metadata: strategy.sourceMetadata
                            )
                        }
                    }
                } else {
                    let transient = QuotaFetchError.transient(detail: error.localizedDescription)
                    errors[id] = transient
                    if let strategy = strategiesById[id] {
                        for layer in strategy.supportedLayers {
                            sourceIndexStore.recordFailure(
                                kind: strategy.kind,
                                layer: layer,
                                sourceKind: strategy.sourceKind,
                                sourceId: strategy.id,
                                error: transient.localizedDescription,
                                metadata: strategy.sourceMetadata
                            )
                        }
                    }
                }
            }
        }
        return best ?? fallback
    }

    private static func successfulLayersForMerge(from snapshot: ProviderSnapshot) -> Set<ProviderFetchLayer> {
        var layers: Set<ProviderFetchLayer> = [.provider]
        switch snapshot.availability {
        case .available:
            if !snapshot.quotas.isEmpty {
                layers.insert(.quota)
            }
            if snapshot.subscriptionTier != nil || snapshot.monthlyPrice != nil {
                layers.insert(.plan)
            }
            if snapshot.subscriptionExpiresAt != nil {
                layers.insert(.expiration)
            }
        case .subscriptionExpired(let plan, let expiredAt):
            layers.insert(.expiration)
            if plan != nil || expiredAt != nil {
                layers.insert(.plan)
            }
        case .notSubscribed:
            layers.insert(.expiration)
        case .needsConfiguration, .loading, .notInstalled, .fetchFailed:
            break
        }
        return layers
    }
}

// MARK: - QuotaProvider 适配

/// 让 `FetchPipeline` 也能套进现有 `RefreshCoordinator` 的 `QuotaProvider` 接口。
/// Coordinator 仍然拿 `[QuotaProvider]`，但内部实现可以替换为 pipeline-based。
final class PipelineQuotaProvider: QuotaProvider, @unchecked Sendable {
    let id: String
    let kind: ProviderKind
    var displayName: String { kind.displayName }

    private let pipeline: FetchPipeline

    init(id: String, pipeline: FetchPipeline) {
        self.id = id
        self.kind = pipeline.providerKind
        self.pipeline = pipeline
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        try await pipeline.run(timeout: timeout)
    }
}
