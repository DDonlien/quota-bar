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
    @Published private(set) var state: DashboardState = .empty
    @Published private(set) var isRefreshing: Bool = false
    @Published private(set) var needsFullDiskAccess: Bool = false
    @Published private(set) var hiddenKinds: Set<ProviderKind> = []

    let providers: [QuotaProvider]
    let installDetectors: [ProviderKind: InstallDetectorProvider]
    var refreshInterval: TimeInterval
    var providerTimeout: TimeInterval

    private var autoRefreshTask: Task<Void, Never>?
    private var inFlightTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []

    init(
        providers: [QuotaProvider],
        installDetectors: [ProviderKind: InstallDetectorProvider] = [:],
        refreshInterval: TimeInterval = 5 * 60,
        providerTimeout: TimeInterval = 10
    ) {
        self.providers = providers
        self.installDetectors = installDetectors
        self.refreshInterval = refreshInterval
        self.providerTimeout = providerTimeout

        NotificationCenter.default.publisher(for: .quotaPreferencesDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyProviderOrder()
            }
            .store(in: &cancellables)
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
        clearHidden()
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

    func hide(kind: ProviderKind) {
        hiddenKinds.insert(kind)
        // 从当前 state 中移除该 kind
        let updated = state.snapshots.filter { $0.kind != kind }
        state = DashboardState(
            snapshots: updated,
            refreshState: state.refreshState,
            lastUpdated: state.lastUpdated
        )
        refreshStatusItemAppearance()
    }

    func clearHidden() {
        hiddenKinds.removeAll()
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

        // 2. 跑 installed kind 的 pipeline（并发），只对「已装且未隐藏」的 kind seed placeholder。
        let activeProviders = providers.filter { installReasons[$0.kind] != nil && !hiddenKinds.contains($0.kind) }
        NSLog("QuotaBar: activeProviders = \(activeProviders.map { $0.kind.rawValue })")

        // 3. 立刻 seed placeholder（streaming refresh 的关键步骤）
        let providerOrder = PreferencesStore.shared.providerOrder()
        let now = Date()
        let placeholders = activeProviders
            .map { ProviderSnapshot.loading(kind: $0.kind, fetchedAt: now) }
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
                let installDetail = installReasons[kind]
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
                        result = .success(snapshot)
                    } catch {
                        NSLog("QuotaBar: ❌ \(kind.rawValue) failed: \(error)")
                        result = .failure(error)
                    }
                    // 拿到结果后回到 MainActor 立即更新 state。
                    // 每个 provider 完成都会触发一次 @Published，UI 原地刷新。
                    await MainActor.run {
                        self.applyProviderResult(
                            kind: kind,
                            result: result,
                            installDetail: installDetail,
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
            case .available, .loading: return false
            case .needsConfiguration, .notInstalled, .fetchFailed, .subscriptionExpired: return true
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
            case .available, .loading, .notInstalled, .subscriptionExpired:
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
        installDetail: String?,
        now: Date
    ) {
        let newSnapshot: ProviderSnapshot
        switch result {
        case .success(let snapshot):
            // pickBestSnapshot：单 provider 通常只跑一条 strategy；保留合并逻辑以防未来扩展
            newSnapshot = pickBestSnapshot(from: [snapshot]) ?? snapshot
        case .failure(let error):
            if let qe = error as? QuotaFetchError {
                let availability: ProviderAvailability
                if let installDetail {
                    availability = .needsConfiguration(reason: installDetail)
                } else {
                    availability = qe.availabilityFallback
                }
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
            keepAfterApply = !newSnapshot.quotas.isEmpty
        case .needsConfiguration, .subscriptionExpired:
            // v0.8.0：subscriptionExpired 跟 needsConfiguration 一样，保留让 UI 展示
            // 「已过期 / 上次套餐 / 到期日」灰标（让用户知道"我曾经是 Plus，但过期了"）。
            keepAfterApply = true
        case .loading, .notInstalled, .fetchFailed:
            keepAfterApply = false
        }

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
            case .available: return 4
            case .needsConfiguration: return 3
            case .subscriptionExpired: return 3
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
    private func detectInstallReasons() async -> [ProviderKind: String] {
        guard !installDetectors.isEmpty else {
            return Dictionary(uniqueKeysWithValues: providers.map { ($0.kind, "未知") })
        }

        return await withTaskGroup(of: (ProviderKind, String?).self) { group in
            for (kind, detector) in installDetectors {
                group.addTask {
                    do {
                        let snapshot = try await detector.fetchSnapshot(timeout: 3)
                        if case .needsConfiguration(let text) = snapshot.availability {
                            NSLog("QuotaBar: 🔍 \(kind.rawValue) detected: \(text)")
                            return (kind, text)
                        }
                        NSLog("QuotaBar: 🔍 \(kind.rawValue) not detected (availability not needsConfiguration)")
                        return (kind, nil)
                    } catch {
                        NSLog("QuotaBar: 🔍 \(kind.rawValue) detection failed: \(error)")
                        return (kind, nil)
                    }
                }
            }
            var map: [ProviderKind: String] = [:]
            for await (kind, reason) in group {
                if let reason { map[kind] = reason }
            }
            NSLog("QuotaBar: 🔍 detected kinds: \(map.keys.map { $0.rawValue })")
            return map
        }
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
