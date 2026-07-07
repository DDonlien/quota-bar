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
    /// 该 provider 完整额度应包含的 scope 集合（`QuotaWindow.scope`）。
    /// 非空时，首个成功 snapshot 缺 scope 会继续用后续 strategy 分层补齐
    /// （例如 Kimi：desktop token 只有 work，CLI OAuth 只有 code）。
    /// nil / 空 = 只要有额度窗口就视为 quota 层完整。
    let expectedQuotaScopes: Set<String>
    private let sourceIndexStore: ProviderSourceIndexStore

    private(set) var lastSnapshots: [String: ProviderSnapshot] = [:]
    private(set) var lastErrors: [String: QuotaFetchError] = [:]

    init(
        kind: ProviderKind,
        strategies: [ProviderFetchStrategy],
        runMode: RunMode = .parallel,
        expectedQuotaScopes: Set<String> = [],
        sourceIndexStore: ProviderSourceIndexStore = .shared
    ) {
        self.providerKind = kind
        self.strategies = strategies
        self.runMode = runMode
        self.expectedQuotaScopes = expectedQuotaScopes
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

    /// 分层串行执行（sub/main 分组分层获取方案的核心落地）：
    ///
    /// 0. 若「上次成功来源索引」对本轮所需层（额度/档位）**一致地**指向同一个来源，
    ///    先单独试这一个（详见 `cachedFirstStrategy`）；命中且完整就直接返回。
    /// 1. 缓存没有、或缓存没能完整覆盖，按 pipeline 声明顺序找第一个成功的 strategy
    ///    作为**基底 snapshot**（跳过刚才已经试过的缓存来源，避免同一轮内重复调用）；
    /// 2. 基底若缺层（quota scope 不全 / tier / price / 过期日为 nil），
    ///    继续用**声明覆盖该缺失层**的后续 strategy 补齐；
    /// 3. 补层 strategy 失败只记录，不影响基底结果；
    /// 4. 全部 strategy 失败才 throw，让 RefreshCoordinator 决定 fallback availability。
    private func runSequential(timeout: TimeInterval) async throws -> ProviderSnapshot {
        var fallbackError: QuotaFetchError?
        var merged: ProviderSnapshot?

        let ordered = effectiveOrder(for: [.quota, .plan])
        await logSourceOrdering(ordered)

        for strategy in ordered {
            if let base = merged {
                let missing = missingLayers(of: base)
                if missing.isEmpty { break }
                guard !missing.isDisjoint(with: strategy.supportedLayers) else { continue }
                do {
                    let addition = try await strategy.fetch(timeout: timeout)
                    lastSnapshots[strategy.id] = addition
                    recordSuccess(strategy: strategy, snapshot: addition)
                    await logAttempt(strategy: strategy, snapshot: addition, onlyLayers: missing)
                    merged = Self.mergeLayers(base: base, addition: addition)
                } catch let error as QuotaFetchError {
                    lastErrors[strategy.id] = error
                    recordError(error, strategy: strategy)
                    await logAttempt(strategy: strategy, error: error, onlyLayers: missing)
                } catch {
                    let transient = QuotaFetchError.transient(detail: error.localizedDescription)
                    lastErrors[strategy.id] = transient
                    recordError(transient, strategy: strategy)
                    await logAttempt(strategy: strategy, error: transient, onlyLayers: missing)
                }
                continue
            }

            do {
                let snapshot = try await strategy.fetch(timeout: timeout)
                lastSnapshots[strategy.id] = snapshot
                recordSuccess(strategy: strategy, snapshot: snapshot)
                await logAttempt(strategy: strategy, snapshot: snapshot)
                // 非 available（过期 / 未订阅 marker 等）直接返回，不做分层合并。
                guard snapshot.availability == .available else { return snapshot }
                merged = snapshot
                if missingLayers(of: snapshot).isEmpty { break }
            } catch let error as QuotaFetchError {
                lastErrors[strategy.id] = error
                recordError(error, strategy: strategy)
                await logAttempt(strategy: strategy, error: error)

                fallbackError = preferredFallbackError(current: fallbackError, new: error)
            } catch {
                let transient = QuotaFetchError.transient(detail: error.localizedDescription)
                lastErrors[strategy.id] = transient
                recordError(transient, strategy: strategy)
                await logAttempt(strategy: strategy, error: transient)
                fallbackError = preferredFallbackError(current: fallbackError, new: transient)
            }
        }

        if let merged { return merged }
        // 全失败时 throw，让 RefreshCoordinator 决定 fallback availability
        // （基于 service 是否已安装来决定 needsConfiguration vs notInstalled）。
        if let fallbackError {
            throw fallbackError
        }
        throw QuotaFetchError.sourceUnavailable(detail: "无可用数据源")
    }

    /// 本轮实际执行顺序：优先试「缓存来源」（若存在且对所需层一致），其余按声明顺序补齐。
    ///
    /// 「一致」指本轮所有传入的 `layers` 的「上次成功来源索引」都指向**同一个** strategy id
    /// ——也就是上次有一个来源一次性把这几层都拿全了，这次可以放心先只试它，省掉明知
    /// 会失败的前面几层。如果不同层指向不同来源、或者压根没有缓存记录，说明"没有单一
    /// 来源覆盖过全部所需信息"，这时不做任何取巧，直接按 pipeline 声明顺序完整跑一遍
    /// （这也是为什么 `quotaOnlySourceCannotShadowFullSource` 测试里"只给 quota 层缓存"
    /// 不会让这个部分来源抢到声明在前、真正完整的来源前面——它跟 `.plan` 层没有达成一致）。
    ///
    /// 缓存来源试过之后无论成不成功都不会在下面的完整 fallback 里重复出现（避免同一轮
    /// 内对同一个 strategy 打两次一模一样的请求）；但如果缓存来源失败或没能完整覆盖，
    /// 完整 fallback 依然会把**其余全部** strategy 按声明顺序跑一遍，不会因为"试过缓存"
    /// 就少跑本该跑的层。
    private func effectiveOrder(for layers: [ProviderFetchLayer]) -> [ProviderFetchStrategy] {
        guard let cachedFirst = cachedFirstStrategy(for: layers) else { return strategies }
        return [cachedFirst] + strategies.filter { $0.id != cachedFirst.id }
    }

    private func cachedFirstStrategy(for layers: [ProviderFetchLayer]) -> ProviderFetchStrategy? {
        // `compactMap` 会悄悄丢掉"这一层压根没有缓存记录"的情况，让它跟"缺失"混同成
        // "被忽略、其余层达成一致"——这不是"一致"，是"信息不全"，必须一并算作不一致。
        // 所以这里保留每一层原始的 `String?`（包括 nil），逐一跟第一层的值比较。
        let preferredIds = layers.map { sourceIndexStore.preferredSourceID(for: providerKind, layer: $0) }
        guard let first = preferredIds.first, let onlyId = first,
              preferredIds.allSatisfy({ $0 == onlyId }) else {
            return nil
        }
        return strategies.first { $0.id == onlyId }
    }

    /// 记录「上次成功来源索引」缓存里存了什么，以及本轮是否因此把它排到了最前面。
    private func logSourceOrdering(_ ordered: [ProviderFetchStrategy]) async {
        for layer in [ProviderFetchLayer.quota, .plan] {
            guard let preferredId = sourceIndexStore.preferredSourceID(for: providerKind, layer: layer) else { continue }
            let step: ProviderCheckLog.CheckStep = layer == .quota ? .quota : .plan
            let triedFirst = ordered.first?.id == preferredId
            await ProviderCheckLog.shared.record(
                kind: providerKind, step: step, method: "上次成功来源索引",
                outcome: triedFirst ? .success : .failure,
                detail: triedFirst
                    ? "命中缓存，优先尝试：\(preferredId)"
                    : "缓存来源 \(preferredId) 与其他层不一致，本轮按声明顺序完整探测"
            )
        }
    }

    /// 把单次 strategy 的执行结果投影成诊断日志行。一次 fetch 可能同时覆盖「额度获取」
    /// 和「档位与费用获取」两个 check step（例如同一个 API 响应里既有额度又有档位/价格），
    /// 这里按 `strategy.supportedLayers` 逐层各记一条，如实反映"这次方案对哪一层有贡献"。
    ///
    /// 两点统一规则：
    /// 1. 层的输出顺序固定是「额度获取」在前、「档位与费用获取」在后（对应 README
    ///    四层获取矩阵里 2/4 的顺序）——不能按 `ProviderFetchLayer` 的 `rawValue`
    ///    字母序排（"plan" < "quota"），那样会让同一次调用看起来像是先做了档位
    ///    检查、才做额度检查，跟额度层排在第 2 层的既定顺序自相矛盾。
    /// 2. MethodName 统一用 `strategy.sourceKind.checkLogLabel`（配置/凭证 → API、
    ///    CLI 命令等分类词），不用 strategy 自己的 id（如 `kimi-desktop-token`，
    ///    单看名字猜不出属于哪一类来源）；具体是哪个 strategy 放在 `detail` 里。
    ///
    /// `onlyLayers`（分层合并的补层调用专用）：只记录**这次调用实际是为了补哪一层**
    /// 才尝试的层，不是 `strategy.supportedLayers` 的全集。分层合并阶段，某个 strategy
    /// 可能同时支持 quota+plan，但这一轮只是因为 plan 还缺才被重新尝试——如果它失败，
    /// 不加这个过滤会记一条"额度获取失败"，但实际上额度早就被更早的来源满足了，只是
    /// 这次没打算靠它补额度。2026-07-07 用户看真实日志时确认过这个现象容易被误读成
    /// "全都失败"。首次尝试（`base == nil` 时）不传，此时确实是在为全部所需层探测。
    private func logAttempt(strategy: ProviderFetchStrategy, snapshot: ProviderSnapshot? = nil, error: QuotaFetchError? = nil, onlyLayers: Set<ProviderFetchLayer>? = nil) async {
        var relevantLayers = strategy.supportedLayers.intersection([.quota, .plan])
        if let onlyLayers {
            relevantLayers.formIntersection(onlyLayers)
        }
        guard !relevantLayers.isEmpty else { return }
        let method = strategy.sourceKind.checkLogLabel
        for layer in [ProviderFetchLayer.quota, .plan] where relevantLayers.contains(layer) {
            let step: ProviderCheckLog.CheckStep = layer == .quota ? .quota : .plan
            let outcome: ProviderCheckLog.Outcome
            let content: String
            if let error {
                outcome = .failure
                content = error.localizedDescription
            } else if let snapshot {
                switch layer {
                case .quota:
                    if snapshot.quotas.isEmpty {
                        outcome = .failure
                        content = "未获取到额度窗口"
                    } else {
                        outcome = .success
                        content = "获取到 \(snapshot.quotas.count) 条额度窗口"
                    }
                case .plan:
                    outcome = .success
                    let tier = snapshot.subscriptionTier ?? "未获取"
                    let price = snapshot.monthlyPrice ?? "未获取"
                    content = "档位=\(tier)，价格=\(price)"
                default:
                    outcome = .success
                    content = ""
                }
            } else {
                outcome = .failure
                content = "无结果"
            }
            await ProviderCheckLog.shared.record(kind: providerKind, step: step, method: method, outcome: outcome, detail: "来源 \(strategy.id)：\(content)")
        }
    }

    /// 基底 snapshot 还缺哪些层。
    ///
    /// 只追 `.quota` / `.plan`：订阅过期日（`.expiration`）由基底 snapshot 自带或
    /// RefreshCoordinator 的独立 expiry source resolver 补齐，不在额度管线里
    /// 追加兜底请求（避免每轮刷新为拿不到的日期多跑一遍低优先级 strategy）。
    private func missingLayers(of snapshot: ProviderSnapshot) -> Set<ProviderFetchLayer> {
        var missing: Set<ProviderFetchLayer> = []
        if snapshot.quotas.isEmpty {
            missing.insert(.quota)
        } else if !expectedQuotaScopes.isEmpty {
            let presentScopes = Set(snapshot.quotas.compactMap(\.scope))
            if !expectedQuotaScopes.isSubset(of: presentScopes) {
                missing.insert(.quota)
            }
        }
        if snapshot.subscriptionTier == nil || snapshot.monthlyPrice == nil {
            missing.insert(.plan)
        }
        return missing
    }

    /// 用 addition 填补 base 的缺失层：
    /// - quota：追加 base 中不存在的 scope（或 title+period 组合）的窗口；
    /// - plan：tier / price 为 nil 时填补；
    /// - expiration：过期日为 nil 时填补（连带来源与可信度标记）。
    static func mergeLayers(base: ProviderSnapshot, addition: ProviderSnapshot) -> ProviderSnapshot {
        guard addition.availability == .available else { return base }

        var quotas = base.quotas
        let presentKeys = Set(base.quotas.map { quotaMergeKey($0) })
        let presentScopes = Set(base.quotas.compactMap(\.scope))
        for window in addition.quotas {
            if let scope = window.scope {
                guard !presentScopes.contains(scope) else { continue }
            } else {
                guard !presentKeys.contains(quotaMergeKey(window)) else { continue }
            }
            quotas.append(window)
        }

        let expiresAt = base.subscriptionExpiresAt ?? addition.subscriptionExpiresAt
        return ProviderSnapshot(
            id: base.id,
            kind: base.kind,
            subscriptionTier: base.subscriptionTier ?? addition.subscriptionTier,
            availability: base.availability,
            quotas: quotas,
            monthlyPrice: base.monthlyPrice ?? addition.monthlyPrice,
            subscriptionExpiresAt: expiresAt,
            subscriptionExpiresAtSource: base.subscriptionExpiresAt != nil
                ? base.subscriptionExpiresAtSource
                : addition.subscriptionExpiresAtSource,
            subscriptionExpiresAtConfidence: base.subscriptionExpiresAt != nil
                ? base.subscriptionExpiresAtConfidence
                : addition.subscriptionExpiresAtConfidence,
            fetchedAt: max(base.fetchedAt, addition.fetchedAt),
            isStale: base.isStale
        )
    }

    private static func quotaMergeKey(_ window: QuotaWindow) -> String {
        "\(window.scope ?? window.title)|\(window.periodSeconds.map(String.init(describing:)) ?? "-")"
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
