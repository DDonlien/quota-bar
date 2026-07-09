import Foundation
import SwiftUI
import Combine

// MARK: - Provider 协议

/// 订阅数据源协议。所有 Provider 实现此协议。
protocol QuotaProvider: AnyObject, Sendable {
    var id: String { get }
    var kind: ProviderKind { get }
    var displayName: String { get }

    /// 拉取一次最新快照。超时由调用方控制。
    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot
}

// MARK: - 刷新协调器

@MainActor
final class RefreshCoordinator: ObservableObject {
    struct ProviderInstallSummary: Sendable {
        let detections: [InstallDetectorProvider.InstallDetection]

        var reason: String {
            detections.map(\.detail).joined(separator: "；")
        }
    }

    @Published private(set) var state: DashboardState = .empty
    @Published private(set) var isRefreshing: Bool = false
    @Published private(set) var needsFullDiskAccess: Bool = false

    let providers: [QuotaProvider]
    let installDetectors: [ProviderKind: InstallDetectorProvider]
    private let sourceIndexStore: ProviderSourceIndexStore
    private let snapshotCacheStore: ProviderSnapshotCacheStore
    private let harvesterTimeout: TimeInterval = 12
    var refreshInterval: TimeInterval
    var providerTimeout: TimeInterval

    private var autoRefreshTask: Task<Void, Never>?
    private var inFlightTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []

    init(
        providers: [QuotaProvider],
        installDetectors: [ProviderKind: InstallDetectorProvider] = [:],
        refreshInterval: TimeInterval = 5 * 60,
        providerTimeout: TimeInterval = 10,
        sourceIndexStore: ProviderSourceIndexStore = .shared,
        snapshotCacheStore: ProviderSnapshotCacheStore = .shared
    ) {
        self.providers = providers
        self.installDetectors = installDetectors
        self.sourceIndexStore = sourceIndexStore
        self.snapshotCacheStore = snapshotCacheStore
        self.refreshInterval = refreshInterval
        self.providerTimeout = providerTimeout

        let cachedSnapshots = Self.sortedSnapshots(
            snapshotCacheStore.loadAll(),
            order: PreferencesStore.shared.providerOrder()
        )
        self.state = DashboardState(
            snapshots: cachedSnapshots,
            refreshState: .idle,
            lastUpdated: cachedSnapshots.map(\.fetchedAt).max()
        )

        // `.receive(on: RunLoop.main)`（Combine 默认用 `RunLoop.Mode.default`）在 dropdown
        // 打开期间不会触发——NSMenu 的鼠标 tracking 用的是 `.eventTracking` run loop
        // mode，`.default` 模式排的活要等菜单关闭、tracking loop 退出才会跑，这正是
        // "点了叉不会立刻隐藏，要关闭再打开 dropdown 才生效"的根因（2026-07-07 用户
        // 实测发现）。改用 `DispatchQueue.main`：GCD 主队列的任务通过 common run loop
        // mode 派发，不受 tracking mode 影响，dropdown 开着的时候也能正常触发。
        NotificationCenter.default.publisher(for: .quotaPreferencesDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyProviderOrder()
                self?.applyEnabledFilterChange()
                self?.applyRefreshIntervalChange()
                self?.applyProviderTimeoutChange()
            }
            .store(in: &cancellables)

        // 用户关掉 App 内 WebView 授权窗口后立即刷新一次——此前这里完全没有触发
        // 任何动作，用户登录完看到的还是登录前的失败状态，得等下一个自动刷新周期
        // 或者自己想起来手动点「立即刷新」，体感上跟"WebView 登录没用"没区别
        // （2026-07-08 用户实测反馈）。见 `WebAuthorizationController.windowWillClose`。
        NotificationCenter.default.publisher(for: .webAuthorizationWindowDidClose)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshNow()
            }
            .store(in: &cancellables)

        // 用户在「偏好设置 → 模型」里保存了 API key 后立即刷新一次，原理同上。
        NotificationCenter.default.publisher(for: .providerCredentialsDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshNow()
            }
            .store(in: &cancellables)

        // 「偏好设置 → 日志」页的「刷新」按钮：Preferences 窗口跟 StatusBarController
        // 是两套独立的视图层级，没有直接持有 RefreshCoordinator 的引用，用通知解耦。
        NotificationCenter.default.publisher(for: .manualRefreshRequested)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshNow()
            }
            .store(in: &cancellables)
    }

    /// 跟 `applyRefreshIntervalChange()` 同一类问题：`advanced.providerTimeoutSeconds`
    /// 此前完全没有 UI、也没有被这里读取过，`providerTimeout` 一直固定用构造函数的
    /// 默认值。现在偏好设置里有了「Provider 刷新超时」选项后，这里负责同步。
    /// 不需要像刷新间隔那样重启循环——`providerTimeout` 只在每次发起新的
    /// `fetchSnapshot(timeout:)` 调用时被读取，改完这里，下一轮刷新（不管是自动还是
    /// 手动触发）自然就会用上新值，正在进行中的请求也不需要被打断。
    private func applyProviderTimeoutChange() {
        providerTimeout = PreferencesStore.shared.preferences.advanced.providerTimeoutSeconds
    }

    /// 偏好设置里的「刷新间隔」只会写入 `PreferencesStore.preferences.refreshIntervalSeconds`
    /// 并 persist；`RefreshCoordinator.refreshInterval` 是构造时传入的独立字段，此前从未
    /// 跟偏好同步过——不管是启动时（`StatusBarController` 用的是构造函数默认值，压根没读
    /// 持久化的偏好）还是运行中改动（`.quotaPreferencesDidChange` 订阅者原来只处理 provider
    /// 顺序/启停，没碰这个字段），导致 dropdown 里「自动刷新 N 分钟」的文案和真实的自动
    /// 刷新节奏永远停在构造时的默认值，用户在偏好里怎么改都不会生效（2026-07-07 用户
    /// 实测发现）。这里补上同步，并且如果间隔真的变了就重启自动刷新循环——不这样做的话，
    /// 新间隔只有等当前这轮 `Task.sleep` 走完才会用上，缩短间隔时体感上还是"不生效"。
    private func applyRefreshIntervalChange() {
        let newInterval = PreferencesStore.shared.preferences.refreshIntervalSeconds
        guard newInterval != refreshInterval else { return }
        refreshInterval = newInterval
        guard autoRefreshTask != nil else { return }
        stop()
        start()
    }

    deinit {
        autoRefreshTask?.cancel()
        inFlightTask?.cancel()
    }

    /// 按当前 `providerOrder` 重新排列 `state.snapshots`，不触发网络请求。
    /// 用户拖拽 Provider 区块后，持久化偏好设置会触发此更新，使 dropdown 立即反映新顺序。
    private func applyProviderOrder() {
        let providerOrder = PreferencesStore.shared.providerOrder()
        var snapshots = state.snapshots
        snapshots.sort { a, b in
            let indexA = providerOrder.firstIndex(of: a.kind.rawValue) ?? Int.max
            let indexB = providerOrder.firstIndex(of: b.kind.rawValue) ?? Int.max
            if indexA != indexB { return indexA < indexB }
            return a.kind.rawValue < b.kind.rawValue
        }
        state = DashboardState(
            snapshots: snapshots,
            refreshState: state.refreshState,
            lastUpdated: state.lastUpdated
        )
    }

    // MARK: - 生命周期

    func start() {
        guard autoRefreshTask == nil else { return }
        autoRefreshTask = Task { [weak self] in
            await self?.runAutoRefreshLoop()
        }
    }

    func stop() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
    }

    private func runAutoRefreshLoop() async {
        await runRefreshCycle()
        while !Task.isCancelled {
            do {
                try await Task.sleep(nanoseconds: UInt64(refreshInterval * 1_000_000_000))
            } catch {
                return
            }
            if Task.isCancelled { return }
            await runRefreshCycle()
        }
    }

    // MARK: - 手动刷新

    func refreshNow() {
        if let existing = inFlightTask {
            inFlightTask = Task { [weak self] in
                _ = await existing.value
                guard let self else { return }
                if Task.isCancelled { return }
                await self.runRefreshCycle()
            }
            return
        }
        inFlightTask = Task { [weak self] in
            await self?.runRefreshCycle()
        }
    }

    // MARK: - 隐藏 / 恢复
    //
    // dropdown 里点「隐藏」跟在 Preferences「模型」页把该 provider 的开关关掉是**同一个
    // 动作**：都写 `PreferencesStore.setEnabled(false, for:)`，都会让该 provider 从
    // `activeProviders` 里被过滤掉、不再实际发起任何网络/CLI 请求——不是只在 dropdown
    // 里视觉隐藏、后台仍然正常刷新的"假隐藏"。两个入口共享同一份持久化状态，任一边
    // 改了，另一边通过 `.quotaPreferencesDidChange` 通知同步。

    /// dropdown 里点击「隐藏」：等同于在 Preferences 里关闭该 provider 的开关。
    func hide(kind: ProviderKind) {
        PreferencesStore.shared.setEnabled(false, for: kind)
        // `setEnabled` 内部 `persist()` 会 post `.quotaPreferencesDidChange`，上面的
        // 订阅者也会调用 `applyEnabledFilterChange()`——但那条链路要经过
        // NotificationCenter → Combine 调度，点击这一刻正处在 dropdown 的 NSMenu
        // tracking 期间，调度有被推迟到菜单关闭才执行的风险。这里直接同步再调一次，
        // 保证点击的瞬间就从 `state.snapshots` 里摘掉，不依赖那条异步链路的时机。
        applyEnabledFilterChange()
    }

    /// 把当前 `state.snapshots` 按 `PreferencesStore.isEnabled` 重新过滤 + 视需要补一次刷新。
    /// 由 `.quotaPreferencesDidChange` 触发——不管是 dropdown 的隐藏按钮还是 Preferences
    /// 「模型」页的开关改的，都走这一条同步路径，保证两处状态一致。
    private func applyEnabledFilterChange() {
        let stillEnabled = state.snapshots.filter { PreferencesStore.shared.isEnabled(kind: $0.kind) }
        if stillEnabled.count != state.snapshots.count {
            state = DashboardState(
                snapshots: stillEnabled,
                refreshState: state.refreshState,
                lastUpdated: state.lastUpdated
            )
            refreshStatusItemAppearance()
        }

        // 刚被重新启用、但 state 里还没有它的 snapshot（之前被过滤掉了）：
        // 不等下一个 5 分钟自动周期，立刻刷新一次。
        let hasNewlyEnabledMissing = providers.contains { provider in
            PreferencesStore.shared.isEnabled(kind: provider.kind)
                && !state.snapshots.contains { $0.kind == provider.kind }
        }
        if hasNewlyEnabledMissing {
            refreshNow()
        }
    }

    private func refreshStatusItemAppearance() {
        // 触发 @Published 通知，让 StatusBarController 重建
        objectWillChange.send()
    }

    // MARK: - 单次刷新循环

    /// 单次刷新循环（streaming 版本）：
    ///
    /// 1. **探测安装**：跑 `detectInstallReasons()` 找出哪些 kind 真的装了。
    /// 2. **立刻 seed placeholder**：对每个 active + 未隐藏的 kind，注入
    ///    `ProviderSnapshot.loading(kind:)` 到 `state.snapshots`，按用户偏好顺序排好。
    ///    UI 立即看到 provider 行 + 骨架占位，不需要等任何 pipeline 完成。
    /// 3. **per-provider 并发 fetch**：用 `withTaskGroup` 给每个 provider 一个子任务，
    ///    pipeline 完成（或失败）时**立即**调用 `applyProviderResult`，把对应 kind 的
    ///    snapshot 替换为真实（或 fallback）版本，并发布新的 state。
    ///    UI 在菜单打开期间会原地更新（依赖 v0.3.0-UI-A-004 的 @ObservedObject 绑定），
    ///    菜单栏 bar 也按完成的 snapshot 同步"动态增长"。
    /// 4. **收尾**：所有 provider 都完成后，计算最终 `refreshState`
    ///    （`.succeeded` / `.partialFailure` / `.failed`）。
    ///
    /// **关键不变量**：
    /// - 任何时刻 `state.snapshots` 都保持「已安装且未隐藏」的全部 kind（loading 或 completed）。
    /// - 之前在 state 里、但本轮不再 active 的 kind 会被剔除（不再显示）。
    /// - `state.lastUpdated` 每次有 provider 完成时都向前推（不是等所有完成）。
    private func runRefreshCycle() async {
        isRefreshing = true
        defer { isRefreshing = false }

        // 1. 前置检测：哪些 service 真的装了 App/CLI/凭证？
        //    没装的 kind 直接跳过 pipeline，UI 不会显示。
        let installReasons = await detectInstallReasons()
        NSLog("QuotaBar: installReasons = \(installReasons.keys.sorted { $0.rawValue < $1.rawValue })")
        removeCacheForUndetectedProviders(detectedKinds: Set(installReasons.keys))

        // 2. 跑 installed kind 的 pipeline（并发），只对「已装且用户未关闭」的 kind seed
        //    placeholder。是否启用统一读 `PreferencesStore.isEnabled`——dropdown 隐藏
        //    按钮和 Preferences 开关写的是同一份持久化状态，这里只需要读一处。
        let activeProviders = providers.filter { installReasons[$0.kind] != nil && PreferencesStore.shared.isEnabled(kind: $0.kind) }
        NSLog("QuotaBar: activeProviders = \(activeProviders.map { $0.kind.rawValue })")

        // 未检测到安装 / 已隐藏的 kind 不会进入下面的 per-provider 并发阶段，
        // 这里先把它们在 detectInstallReasons 里积累的「Provider 获取」诊断日志落盘，
        // 避免那部分记录一直留在内存缓冲区里出不来。
        let activeKinds = Set(activeProviders.map(\.kind))
        for provider in providers where !activeKinds.contains(provider.kind) {
            await ProviderCheckLog.shared.flush(kind: provider.kind)
        }

        // 3. 立刻 seed placeholder（streaming refresh 的关键步骤）
        let providerOrder = PreferencesStore.shared.providerOrder()
        let now = Date()
        let currentByKind = Dictionary(uniqueKeysWithValues: state.snapshots.map { ($0.kind, $0) })
        let placeholders = activeProviders
            .map { provider -> ProviderSnapshot in
                if let current = currentByKind[provider.kind], current.availability != .loading {
                    return current.withStaleFlag(true)
                }
                if let cached = snapshotCacheStore.snapshot(for: provider.kind) {
                    return cached
                }
                return ProviderSnapshot.loading(kind: provider.kind, fetchedAt: now)
            }
            .sorted { Self.sortByProviderOrder($0.kind, $1.kind, order: providerOrder) }
        state = DashboardState(
            snapshots: placeholders,
            refreshState: .refreshing,
            lastUpdated: state.lastUpdated
        )

        // 4. per-provider 并发 fetch，每个完成立即 apply。
        await withTaskGroup(of: Void.self) { group in
            for provider in activeProviders {
                let kind = provider.kind
                let installSummary = installReasons[kind]
                group.addTask { [weak self] in
                    guard let self else { return }
                    NSLog("QuotaBar: ▶️ start pipeline for \(kind.rawValue)")
                    let result: Result<ProviderSnapshot, Error>
                    do {
                        let snapshot = try await provider.fetchSnapshot(timeout: self.providerTimeout)
                        let quotasInfo = snapshot.quotas.map { "\($0.title): \(Int($0.remainingFraction * 100))% (scope=\($0.scope ?? "nil"))" }.joined(separator: ", ")
                        let tier = snapshot.subscriptionTier ?? "nil"
                        let price = snapshot.monthlyPrice ?? "nil"
                        NSLog("QuotaBar: ✅ \(kind.rawValue) done, tier=\(tier), price=\(price), avail=\(snapshot.availability), quotas=[\(quotasInfo)]")
                        let enriched = await self.enrichWithSubscriptionExpiry(snapshot)
                        result = .success(enriched)
                    } catch {
                        NSLog("QuotaBar: ❌ \(kind.rawValue) failed: \(error)")
                        result = .failure(error)
                    }
                    // 该 provider 本轮全部 check step（安装探测已在上面 flush 过、额度/档位/
                    // 过期日到这里都跑完了）落盘，保证同一 provider 的日志连续输出。
                    await ProviderCheckLog.shared.flush(kind: kind)
                    // 拿到结果后回到 MainActor 立即更新 state。
                    // 每个 provider 完成都会触发一次 @Published，UI 原地刷新。
                    await MainActor.run {
                        self.applyProviderResult(
                            kind: kind,
                            result: result,
                            installSummary: installSummary,
                            now: Date()
                        )
                    }
                }
            }

            // 监听每个 child task 的结束，但不在这里 await 结果（结果在 child 内部已经 apply）。
            for await _ in group {
                // 中间不重算 refreshState，等全部完成再做最后一次收尾。
                // 期间 state.snapshots 已被每个 child 增量更新。
            }
        }

        // 5. 收尾：计算最终 refreshState。
        let finalSnapshots = state.snapshots
        let hasAnyVisible = !finalSnapshots.isEmpty
        let hasFailedKind = finalSnapshots.contains { snapshot in
            switch snapshot.availability {
            case .available, .loading, .subscriptionExpired, .notSubscribed:
                return false
            case .needsConfiguration, .notInstalled, .fetchFailed:
                return true
            }
        }
        let hasAnyLoading = finalSnapshots.contains { $0.availability == .loading }

        let finalRefreshState: RefreshState
        if !hasAnyVisible {
            finalRefreshState = .failed(at: nil, message: "所有服务刷新失败")
        } else if hasFailedKind {
            finalRefreshState = .partialFailure(at: Date(), failedProviderIds: [])
        } else {
            finalRefreshState = .succeeded(at: Date())
        }

        needsFullDiskAccess = finalSnapshots.contains { snapshot in
            switch snapshot.availability {
            case .needsConfiguration(let reason), .fetchFailed(let reason):
                return reason.localizedCaseInsensitiveContains("Full Disk Access")
                    || reason.localizedCaseInsensitiveContains("完全磁盘访问")
            case .available, .loading, .notInstalled, .subscriptionExpired, .notSubscribed:
                return false
            }
        }

        state = DashboardState(
            snapshots: finalSnapshots,
            refreshState: finalRefreshState,
            lastUpdated: state.lastUpdated
        )

        NSLog("QuotaBar: refresh cycle done, \(finalSnapshots.count) snapshots (hadLoading=\(hasAnyLoading), failed=\(hasFailedKind))")
    }

    /// 把单个 provider 的 fetch 结果应用到 state：
    /// - success → 用真实 snapshot 替换对应 kind 的 loading placeholder（同位置替换，保持 UI 顺序稳定）
    /// - failure → 生成 fallback snapshot（needsConfiguration / fetchFailed / notInstalled）
    /// - 每次 apply 都重新发布 `state`，SwiftUI 自动响应；菜单栏 bar 也同步更新
    /// - `state.lastUpdated` 推进到本结果的时间戳（让"上次更新 HH:mm"在每个 provider 完成时都前进）
    private func applyProviderResult(
        kind: ProviderKind,
        result: Result<ProviderSnapshot, Error>,
        installSummary: ProviderInstallSummary?,
        now: Date
    ) {
        let newSnapshot: ProviderSnapshot
        switch result {
        case .success(let snapshot):
            // pickBestSnapshot：单 provider 通常只跑一条 strategy；保留合并逻辑以防未来扩展
            newSnapshot = pickBestSnapshot(from: [snapshot]) ?? snapshot
        case .failure(let error):
            if let qe = error as? QuotaFetchError {
                let availability = availabilityFallback(for: qe, installSummary: installSummary)
                newSnapshot = ProviderSnapshot(
                    kind: kind,
                    availability: availability,
                    quotas: [],
                    monthlyPrice: kind.fallbackMonthlyPrice,
                    fetchedAt: now
                )
            } else {
                newSnapshot = ProviderSnapshot(
                    kind: kind,
                    availability: .fetchFailed(reason: error.localizedDescription),
                    quotas: [],
                    monthlyPrice: kind.fallbackMonthlyPrice,
                    fetchedAt: now
                )
            }
        }

        // 过滤掉 fetchFailed / notInstalled（与原行为一致）：不在 dropdown 显示
        // loading（理论上此时 loading 已被替换）/ available / subscriptionExpired / needsConfiguration 保留
        let keepAfterApply: Bool
        switch newSnapshot.availability {
        case .available:
            // `.available` 只会来自至少一个 strategy 成功——即便只是 tier-only（CLI 兜底层
            // 拿到档位但没拿到额度），也一定至少有 tier/price 之一非 nil，不存在"什么都没有"
            // 的空 available。额度层缺失时应保留展示、在 dropdown 里提示"打开 WebView 授权"，
            // 而不是整个 provider 从列表消失（曾经因为这里错误剔除导致 Claude 完全不显示）。
            keepAfterApply = true
        case .needsConfiguration, .subscriptionExpired, .notSubscribed:
            // v0.8.0：subscriptionExpired 跟 needsConfiguration 一样，保留让 UI 展示
            // 「已过期 / 上次套餐 / 到期日」灰标（让用户知道"我曾经是 Plus，但过期了"）。
            keepAfterApply = true
        case .loading, .notInstalled, .fetchFailed:
            keepAfterApply = false
        }
        updateSnapshotCache(with: newSnapshot)

        var newSnapshots = state.snapshots
        if let index = newSnapshots.firstIndex(where: { $0.kind == kind }) {
            // 同位置替换：loading placeholder → real snapshot，保持 UI 顺序稳定
            if keepAfterApply {
                newSnapshots[index] = newSnapshot
            } else {
                // fetchFailed / notInstalled：移除该 kind 的条目
                newSnapshots.remove(at: index)
            }
        } else if keepAfterApply {
            // 不在 state 中（理论上不应发生，placeholder 一定存在；防御性处理）
            newSnapshots.append(newSnapshot)
            // 重新按用户偏好排序
            let order = PreferencesStore.shared.providerOrder()
            newSnapshots.sort { Self.sortByProviderOrder($0.kind, $1.kind, order: order) }
        }
        // else: 不在 state 且不该保留（罕见）→ 不插入

        // 推进 lastUpdated：本结果的时间戳如果比当前更新就更新（per-provider 刷新会让"上次更新"逐步前进）
        let newLastUpdated: Date?
        if let prev = state.lastUpdated {
            newLastUpdated = max(prev, newSnapshot.fetchedAt)
        } else {
            newLastUpdated = newSnapshot.fetchedAt
        }

        state = DashboardState(
            snapshots: newSnapshots,
            refreshState: state.refreshState,
            lastUpdated: newLastUpdated
        )
    }

    private func availabilityFallback(
        for error: QuotaFetchError,
        installSummary: ProviderInstallSummary?
    ) -> ProviderAvailability {
        switch error {
        case .subscriptionExpired, .notSubscribed:
            return error.availabilityFallback
        case .missingCredentials(let detail), .permissionRequired(let detail):
            return .needsConfiguration(reason: combinedReason(primary: detail, installSummary: installSummary))
        case .transient(let detail):
            return .needsConfiguration(reason: combinedReason(primary: detail, installSummary: installSummary))
        case .sourceUnavailable(let detail):
            if installSummary != nil {
                return .needsConfiguration(reason: combinedReason(primary: detail, installSummary: installSummary))
            }
            return error.availabilityFallback
        }
    }

    private func combinedReason(primary: String, installSummary: ProviderInstallSummary?) -> String {
        let trimmed = primary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let installSummary else {
            return trimmed.isEmpty ? "待配置" : trimmed
        }
        guard !trimmed.isEmpty, trimmed != installSummary.reason else {
            return installSummary.reason
        }
        return "\(trimmed)；\(installSummary.reason)"
    }

    private func enrichWithSubscriptionExpiry(_ snapshot: ProviderSnapshot) async -> ProviderSnapshot {
        guard snapshot.availability == .available else {
            QuotaBarDiagnostics.write("[\(snapshot.kind.rawValue)] skip subscription expiry enrichment, availability=\(snapshot.availability)")
            return snapshot
        }

        let resolver = SubscriptionExpiryResolver(timeout: harvesterTimeout)
        QuotaBarDiagnostics.write("[\(snapshot.kind.rawValue)] start subscription expiry enrichment")
        guard let resolution = await resolver.resolve(for: snapshot) else {
            QuotaBarDiagnostics.write("[\(snapshot.kind.rawValue)] subscription expiry unresolved")
            return snapshot
        }
        QuotaBarDiagnostics.write("[\(snapshot.kind.rawValue)] subscription expiry resolved expiresAt=\(resolution.expiresAt), source=\(resolution.source.id), kind=\(resolution.source.kind.rawValue), confidence=\(resolution.source.confidence.rawValue)")
        NSLog(
            "QuotaBar: 📅 \(snapshot.kind.rawValue) subscriptionExpiresAt=\(resolution.expiresAt) source=\(resolution.source.kind.rawValue) confidence=\(resolution.source.confidence.rawValue)"
        )
        return ProviderSnapshot(
            id: snapshot.id,
            kind: snapshot.kind,
            subscriptionTier: snapshot.subscriptionTier,
            availability: snapshot.availability,
            quotas: snapshot.quotas,
            monthlyPrice: snapshot.monthlyPrice,
            subscriptionExpiresAt: resolution.expiresAt,
            subscriptionExpiresAtSource: resolution.source.kind,
            subscriptionExpiresAtConfidence: resolution.source.confidence,
            fetchedAt: snapshot.fetchedAt,
            isStale: snapshot.isStale
        )
    }

    /// 按用户偏好 provider 顺序排序；未指定的 provider 按 rawValue 字母顺序排在后面。
    private static func sortByProviderOrder(_ a: ProviderKind, _ b: ProviderKind, order: [String]) -> Bool {
        let indexA = order.firstIndex(of: a.rawValue) ?? Int.max
        let indexB = order.firstIndex(of: b.rawValue) ?? Int.max
        if indexA != indexB { return indexA < indexB }
        return a.rawValue < b.rawValue
    }

    /// 从同一 kind 的多个快照中选出最好的一个。
    private func pickBestSnapshot(from snapshots: [ProviderSnapshot]) -> ProviderSnapshot? {
        guard !snapshots.isEmpty else { return nil }

        // 优先级：available > needsConfiguration > loading > notInstalled > fetchFailed
        // loading 介于 needsConfiguration 和 notInstalled 之间：它表明 service 已装且正在取数据，
        // 优先级略高于 notInstalled / fetchFailed 但低于 available / needsConfiguration。
        // v0.8.0：subscriptionExpired 优先级与 needsConfiguration 同级（都是"配置相关"问题）
        let priority: (ProviderAvailability) -> Int = { availability in
            switch availability {
            case .available: return 5
            case .subscriptionExpired: return 4
            case .notSubscribed: return 4
            case .needsConfiguration: return 3
            case .loading: return 2
            case .notInstalled: return 1
            case .fetchFailed: return 0
            }
        }

        // 先按优先级排序，再选非 stale 的
        let sorted = snapshots.sorted { a, b in
            let pa = priority(a.availability)
            let pb = priority(b.availability)
            if pa != pb { return pa > pb }
            // 同一优先级：选 quotas 更多的（真实数据优先于占位数据）
            return a.quotas.count > b.quotas.count
        }

        return sorted.first
    }

    // MARK: - 辅助

    /// 并行跑所有 `InstallDetectorProvider`，返回 kind → install reason。
    /// 没装的 kind 不会出现在结果里。
    /// reason 后续用于 pipeline 失败时 fallback 显示「已安装 X / Y」的文案。
    private func detectInstallReasons() async -> [ProviderKind: ProviderInstallSummary] {
        guard !installDetectors.isEmpty else {
            return Dictionary(uniqueKeysWithValues: providers.map { ($0.kind, ProviderInstallSummary(detections: [])) })
        }

        let preferredSourceIds = Dictionary(uniqueKeysWithValues: installDetectors.keys.map {
            ($0, sourceIndexStore.preferredSourceID(for: $0, layer: .provider))
        })

        return await withTaskGroup(of: (ProviderKind, ProviderInstallSummary?).self) { group in
            for (kind, detector) in installDetectors {
                let preferredSourceId = preferredSourceIds[kind] ?? nil
                group.addTask {
                    let detections = await detector.detectSources(preferredSourceId: preferredSourceId)
                    if detections.isEmpty {
                        NSLog("QuotaBar: 🔍 \(kind.rawValue) not detected")
                        return (kind, nil)
                    }
                    let summary = ProviderInstallSummary(detections: detections)
                    NSLog("QuotaBar: 🔍 \(kind.rawValue) detected: \(summary.reason)")
                    return (kind, summary)
                }
            }
            var map: [ProviderKind: ProviderInstallSummary] = [:]
            for await (kind, summary) in group {
                guard let summary else { continue }
                map[kind] = summary
                for detection in summary.detections {
                    sourceIndexStore.recordSuccess(
                        kind: kind,
                        layer: .provider,
                        sourceKind: detection.sourceKind,
                        sourceId: detection.sourceId,
                        metadata: detection.metadata
                    )
                }
            }
            NSLog("QuotaBar: 🔍 detected kinds: \(map.keys.map { $0.rawValue })")
            return map
        }
    }

    private func updateSnapshotCache(with snapshot: ProviderSnapshot) {
        let sourceRecord = snapshotCacheSourceRecord(for: snapshot)
        switch snapshot.availability {
        case .available:
            if snapshot.quotas.isEmpty {
                snapshotCacheStore.remove(kind: snapshot.kind)
            } else {
                snapshotCacheStore.store(
                    snapshot,
                    sourceKind: sourceRecord?.sourceKind,
                    sourceId: sourceRecord?.sourceId
                )
            }
        case .subscriptionExpired, .notSubscribed:
            snapshotCacheStore.store(
                snapshot,
                sourceKind: sourceRecord?.sourceKind,
                sourceId: sourceRecord?.sourceId
            )
        case .loading, .needsConfiguration, .notInstalled, .fetchFailed:
            snapshotCacheStore.remove(kind: snapshot.kind)
        }
    }

    private func snapshotCacheSourceRecord(for snapshot: ProviderSnapshot) -> ProviderSourceRecord? {
        switch snapshot.availability {
        case .available:
            return sourceIndexStore.preferredSource(for: snapshot.kind, layer: .quota)
                ?? sourceIndexStore.preferredSource(for: snapshot.kind, layer: .plan)
                ?? sourceIndexStore.preferredSource(for: snapshot.kind, layer: .expiration)
                ?? sourceIndexStore.preferredSource(for: snapshot.kind, layer: .provider)
        case .subscriptionExpired, .notSubscribed:
            return sourceIndexStore.preferredSource(for: snapshot.kind, layer: .expiration)
                ?? sourceIndexStore.preferredSource(for: snapshot.kind, layer: .provider)
        case .loading, .needsConfiguration, .notInstalled, .fetchFailed:
            return nil
        }
    }

    private func removeCacheForUndetectedProviders(detectedKinds: Set<ProviderKind>) {
        let managedKinds = Set(providers.map(\.kind))
        for snapshot in snapshotCacheStore.loadAll() where managedKinds.contains(snapshot.kind) && !detectedKinds.contains(snapshot.kind) {
            snapshotCacheStore.remove(kind: snapshot.kind)
        }
    }

    private static func sortedSnapshots(_ snapshots: [ProviderSnapshot], order: [String]) -> [ProviderSnapshot] {
        snapshots.sorted { sortByProviderOrder($0.kind, $1.kind, order: order) }
    }

    var lastUpdatedText: String {
        guard let date = state.lastUpdated else { return "尚未刷新" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "上次更新 \(formatter.string(from: date))"
    }

    var autoRefreshText: String {
        let mins = Int(refreshInterval / 60)
        return "自动刷新 \(mins) 分钟"
    }
}
