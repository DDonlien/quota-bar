import AppKit
import SwiftUI
import Combine

/// 状态栏控制器：负责创建 NSStatusItem、挂载 NSMenu、并在数据变化时重建内容。
///
/// 视图层是 SwiftUI（`MenuView`），但宿主是 AppKit 的 NSMenu，所以这里用 NSHostingView
/// 桥接。状态刷新由 `RefreshCoordinator` 驱动，本控制器只负责订阅并渲染。
@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let menu = NSMenu()
    private let coordinator: RefreshCoordinator
    private var cancellables: Set<AnyCancellable> = []

    let statusItem: NSStatusItem

    init(coordinator: RefreshCoordinator = RefreshCoordinator(
        providers: ProviderFactory.createProviders(),
        installDetectors: ProviderFactory.createInstallDetectors()
    )) {
        self.coordinator = coordinator
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        configureStatusItem()
        configureMenu()
        observeCoordinator()

        coordinator.start()
    }

    // MARK: - 配置

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        if let image = NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: "Quota Bar") {
            image.isTemplate = true
            image.size = NSSize(width: 17, height: 17)
            button.image = image
            button.imagePosition = .imageLeft
            button.imageScaling = .scaleProportionallyDown
        } else {
            button.title = "QB"
        }

        button.toolTip = "Quota Bar"
        statusItem.menu = menu
        refreshStatusItemAppearance()
    }

    /// 根据 coordinator.state 里所有 snapshot 的 overallAvailability 切换状态栏图标 + tooltip + 数字徽标。
    /// 三态：
    /// - **normal**：至少一个 available，且没有 fetchFailed → `chart.bar.fill` + 显示最低 remaining% 数字
    /// - **refreshing**：正在刷 → `arrow.triangle.2.circlepath` + 标题 "刷新中"
    /// - **warning**：有 needsConfiguration 或全 needsConfiguration → `chart.bar` 空徽标
    /// - **error**：有任何 fetchFailed，或全 fetchFailed → `exclamationmark.triangle.fill` + 标题 "!"
    private func refreshStatusItemAppearance() {
        guard let button = statusItem.button else { return }

        let snapshots = coordinator.state.snapshots
        let isRefreshing = coordinator.isRefreshing
        let overall = Self.overallAvailability(of: snapshots)

        let symbolName: String
        let tooltipSuffix: String
        let titleSuffix: String?

        if isRefreshing {
            symbolName = "arrow.triangle.2.circlepath"
            tooltipSuffix = "（正在刷新）"
            titleSuffix = "刷新中"
        } else {
            switch overall {
            case .normal:
                symbolName = "chart.bar.fill"
                tooltipSuffix = "（运行中）"
                titleSuffix = Self.minimumRemainingText(of: snapshots)
            case .warning:
                symbolName = "chart.bar"
                tooltipSuffix = "（部分服务待配置）"
                titleSuffix = nil
            case .error:
                symbolName = "exclamationmark.triangle.fill"
                tooltipSuffix = "（数据获取失败）"
                titleSuffix = "!"
            }
        }

        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Quota Bar") {
            image.isTemplate = true
            image.size = NSSize(width: 17, height: 17)
            button.image = image
        }
        button.title = titleSuffix ?? ""
        button.toolTip = "Quota Bar \(tooltipSuffix)"
    }

    /// 所有 available snapshot 里所有 quota 窗口的最低 remaining%。
    /// 用最低值能更早提醒用户某条额度即将耗尽 —— 跟用户感知"最紧迫的额度"对齐。
    private static func minimumRemainingText(of snapshots: [ProviderSnapshot]) -> String? {
        let allQuotas = snapshots
            .filter { $0.availability == .available }
            .flatMap { $0.quotas }
        guard !allQuotas.isEmpty else { return nil }
        let minPercent = allQuotas.map { Int(($0.remainingFraction * 100).rounded()) }.min() ?? 0
        return "\(minPercent)%"
    }

    enum OverallAvailability {
        case normal
        case warning
        case error
    }

    private static func overallAvailability(of snapshots: [ProviderSnapshot]) -> OverallAvailability {
        if snapshots.isEmpty {
            return .warning  // 没有任何安装的服务，提示用户
        }
        let hasError = snapshots.contains { snapshot in
            if case .fetchFailed = snapshot.availability { return true }
            return false
        }
        if hasError { return .error }

        let hasWarning = snapshots.contains { snapshot in
            if case .needsConfiguration = snapshot.availability { return true }
            return false
        }
        if hasWarning { return .warning }

        return .normal
    }

    private func configureMenu() {
        menu.delegate = self
        menu.autoenablesItems = false
        rebuildMenu()
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    // MARK: - 菜单重建

    private func rebuildMenu() {
        menu.removeAllItems()

        let dashboardItem = NSMenuItem()
        let state = coordinator.state
        let menuView = MenuView(
            state: state,
            isRefreshing: coordinator.isRefreshing,
            lastUpdatedText: coordinator.lastUpdatedText,
            needsFullDiskAccess: coordinator.needsFullDiskAccess
        )
        let dashboardView = NSHostingView(rootView: menuView)
        dashboardView.frame = NSRect(x: 0, y: 0, width: MenuDashboardStyle.width, height: 1)
        dashboardView.layout()
        let fittingSize = dashboardView.fittingSize
        dashboardView.frame = NSRect(
            x: 0,
            y: 0,
            width: MenuDashboardStyle.width,
            height: fittingSize.height
        )
        dashboardView.wantsLayer = true
        dashboardView.layer?.backgroundColor = NSColor.clear.cgColor
        dashboardItem.view = dashboardView
        menu.addItem(dashboardItem)

        let refreshItem = NSMenuItem(title: "立即刷新", action: #selector(refreshNow), keyEquivalent: "")
        refreshItem.target = self
        refreshItem.isEnabled = true
        if let image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "立即刷新") {
            image.isTemplate = true
            image.size = NSSize(width: 14, height: 14)
            refreshItem.image = image
        }
        menu.addItem(refreshItem)

        let autoRefreshItem = NSMenuItem(title: coordinator.autoRefreshText, action: nil, keyEquivalent: "")
        autoRefreshItem.isEnabled = false
        autoRefreshItem.attributedTitle = NSAttributedString(
            string: coordinator.autoRefreshText,
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        menu.addItem(autoRefreshItem)

        menu.addItem(makeMenuItem(title: "偏好设置...", systemSymbolName: "gearshape", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(makeMenuItem(title: "退出", systemSymbolName: "xmark.square", action: #selector(quit), keyEquivalent: "q"))
    }

    private func makeMenuItem(
        title: String,
        systemSymbolName: String,
        action: Selector,
        keyEquivalent: String = ""
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        item.isEnabled = true

        if let image = NSImage(systemSymbolName: systemSymbolName, accessibilityDescription: title) {
            image.isTemplate = true
            image.size = NSSize(width: 14, height: 14)
            item.image = image
        }

        return item
    }

    // MARK: - 订阅 coordinator

    private func observeCoordinator() {
        coordinator.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildMenu()
                self?.refreshStatusItemAppearance()
            }
            .store(in: &cancellables)

        coordinator.$isRefreshing
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildMenu()
                self?.refreshStatusItemAppearance()
            }
            .store(in: &cancellables)

        coordinator.$needsFullDiskAccess
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.rebuildMenu() }
            .store(in: &cancellables)
    }

    // MARK: - 菜单动作

    @objc private func refreshNow() {
        coordinator.refreshNow()
    }

    @objc private func openPreferences() {
        NSSound.beep()
    }

    @objc private func quit() {
        coordinator.stop()
        NSApplication.shared.terminate(nil)
    }
}
