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

    let providers: [QuotaProvider]
    let installDetectors: [ProviderKind: InstallDetectorProvider]
    var refreshInterval: TimeInterval
    var providerTimeout: TimeInterval

    private var autoRefreshTask: Task<Void, Never>?
    private var inFlightTask: Task<Void, Never>?

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
    }

    deinit {
        autoRefreshTask?.cancel()
        inFlightTask?.cancel()
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

    // MARK: - 单次刷新循环

    private func runRefreshCycle() async {
        isRefreshing = true
        defer { isRefreshing = false }

        // 1. 前置检测：哪些 service 真的装了 App/CLI/凭证？
        //    没装的 kind 直接跳过 pipeline，UI 不会显示。
        let installReasons = await detectInstallReasons()
        NSLog("QuotaBar: installReasons = \(installReasons.keys.sorted { $0.rawValue < $1.rawValue })")

        // 2. 跑 installed kind 的 pipeline（并发）
        let activeProviders = providers.filter { installReasons[$0.kind] != nil }
        NSLog("QuotaBar: activeProviders = \(activeProviders.map { $0.kind.rawValue })")
        let results = await withTaskGroup(of: (ProviderSnapshot?, Error?, ProviderKind).self) { group in
            for provider in activeProviders {
                let kind = provider.kind
                group.addTask {
                    NSLog("QuotaBar: ▶️ start pipeline for \(kind.rawValue)")
                    do {
                        let snapshot = try await provider.fetchSnapshot(timeout: self.providerTimeout)
                        NSLog("QuotaBar: ✅ \(kind.rawValue) done, avail=\(snapshot.availability)")
                        return (snapshot, nil, kind)
                    } catch {
                        NSLog("QuotaBar: ❌ \(kind.rawValue) failed: \(error)")
                        return (nil, error, kind)
                    }
                }
            }

            var collected: [(ProviderSnapshot?, Error?, ProviderKind)] = []
            for await result in group {
                collected.append(result)
            }
            NSLog("QuotaBar: all pipelines done, \(collected.count) results")
            return collected
        }

        let now = Date()
        var snapshots: [ProviderSnapshot] = []

        // 按 kind 分组并合并结果
        var byKind: [ProviderKind: [ProviderSnapshot]] = [:]
        for (result, error, kind) in results {
            if let snapshot = result {
                byKind[snapshot.kind, default: []].append(snapshot)
            } else if let error = error as? QuotaFetchError {
                // 失败时生成降级 snapshot。
                // service 已安装但 pipeline 全失败 → needsConfiguration，
                // 让 UI 显示「已安装但未拿到授权」。
                let availability: ProviderAvailability
                if let installDetail = installReasons[kind] {
                    availability = .needsConfiguration(reason: installDetail)
                } else {
                    availability = error.availabilityFallback
                }
                let fallback = ProviderSnapshot(
                    kind: kind,
                    availability: availability,
                    quotas: [],
                    monthlyPrice: kind.fallbackMonthlyPrice,
                    fetchedAt: now
                )
                byKind[kind, default: []].append(fallback)
            }
        }

        for (_, group) in byKind {
            if let best = pickBestSnapshot(from: group) {
                snapshots.append(best)
            }
        }

        needsFullDiskAccess = snapshots.contains { snapshot in
            switch snapshot.availability {
            case .needsConfiguration(let reason), .fetchFailed(let reason):
                return reason.localizedCaseInsensitiveContains("Full Disk Access")
                    || reason.localizedCaseInsensitiveContains("完全磁盘访问")
            case .available, .notInstalled:
                return false
            }
        }

        snapshots = snapshots.filter { snapshot in
            switch snapshot.availability {
            case .available:
                return !snapshot.quotas.isEmpty
            case .needsConfiguration:
                // App 已安装但未接入 dashboard 的服务保留展示（如 Trae、Antigravity）
                return true
            case .notInstalled, .fetchFailed:
                return false
            }
        }

        // 按 kind 稳定排序
        snapshots.sort { $0.kind.rawValue < $1.kind.rawValue }

        let refreshState: RefreshState
        if !snapshots.isEmpty {
            let hasFailed = snapshots.contains { $0.availability != .available }
            if hasFailed {
                refreshState = .partialFailure(at: now, failedProviderIds: [])
            } else {
                refreshState = .succeeded(at: now)
            }
        } else {
            refreshState = .failed(at: nil, message: "所有服务刷新失败")
        }

        state = DashboardState(
            snapshots: snapshots,
            refreshState: refreshState,
            lastUpdated: now
        )
    }

    /// 从同一 kind 的多个快照中选出最好的一个。
    private func pickBestSnapshot(from snapshots: [ProviderSnapshot]) -> ProviderSnapshot? {
        guard !snapshots.isEmpty else { return nil }

        // 优先级：available > needsConfiguration > notInstalled > fetchFailed
        let priority: (ProviderAvailability) -> Int = { availability in
            switch availability {
            case .available: return 3
            case .needsConfiguration: return 2
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
            // 没配 detector 就退化为「全部跑」——保持向后兼容
            return Dictionary(uniqueKeysWithValues: providers.map { ($0.kind, "未知") })
        }

        return await withTaskGroup(of: (ProviderKind, String?).self) { group in
            for (kind, detector) in installDetectors {
                group.addTask {
                    do {
                        let snapshot = try await detector.fetchSnapshot(timeout: 3)
                        if case .needsConfiguration(let text) = snapshot.availability {
                            return (kind, text)
                        }
                        return (kind, nil)
                    } catch {
                        return (kind, nil)
                    }
                }
            }
            var map: [ProviderKind: String] = [:]
            for await (kind, reason) in group {
                if let reason { map[kind] = reason }
            }
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
