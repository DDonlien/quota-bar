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

        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.toolTip = "Quota Bar"
        statusItem.menu = menu
        refreshStatusItemAppearance()
    }

    /// 根据 coordinator.state 切换状态栏图标 + tooltip。
    ///
    /// **状态栏设计**（Liquid Glass 风格）：
    /// - **正常**：画 N 个垂直 bar，每个对应一个 `.available` 订阅；
    ///   - bar 数量 = 已配置订阅数（needsConfiguration / notInstalled / fetchFailed 不显示）
    ///   - bar 颜色 = 该订阅的 brand color
    ///   - bar 高度 = 该订阅所有 quota 窗口里最低 `remainingFraction`（用最低值对齐"最紧迫的额度"感知）
    ///   - bar 顺序 = dashboard 里的 snapshot 顺序（按 `kind.rawValue` 字母升序）
    ///   - 用完的（0%）仍然画最小 bar（2pt），让用户知道订阅存在
    /// - **刷新中**：单 SF Symbol `arrow.triangle.2.circlepath`（spinner）
    /// - **零订阅**：单 SF Symbol `questionmark.circle`
    /// - **有 fetchFailed**：fetchFailed 的订阅不画 bar，但其他正常订阅的 bar 仍画
    ///
    /// tooltip 显示每个 bar 对应订阅的剩余百分比，方便在 menu bar 悬停查看。
    private func refreshStatusItemAppearance() {
        guard let button = statusItem.button else { return }

        let snapshots = coordinator.state.snapshots
        let isRefreshing = coordinator.isRefreshing
        let available = snapshots.filter { $0.availability == .available }

        if isRefreshing {
            // 刷新中：spinner SF Symbol
            if let image = NSImage(
                systemSymbolName: "arrow.triangle.2.circlepath",
                accessibilityDescription: "Quota Bar 刷新中"
            ) {
                image.isTemplate = true
                image.size = NSSize(width: 16, height: 16)
                button.image = image
            }
            button.title = ""
            button.toolTip = "Quota Bar · 正在刷新…"
            return
        }

        // 正常 / 部分失败状态：画 bars image（available 数量从 0 到 N）
        let image = Self.makeBarsImage(from: available)
        button.image = image
        button.title = ""

        // tooltip：每个订阅的剩余%
        if available.isEmpty {
            let needsConfigCount = snapshots.filter {
                if case .needsConfiguration = $0.availability { return true }
                return false
            }.count
            if needsConfigCount > 0 {
                button.toolTip = "Quota Bar · \(needsConfigCount) 个服务待配置"
            } else {
                button.toolTip = "Quota Bar · 暂无已配置订阅"
            }
        } else {
            let summary = available.map { snap -> String in
                let pct = snap.quotas.isEmpty
                    ? 100
                    : Int((snap.quotas.map { $0.remainingFraction }.min()! * 100).rounded())
                return "\(snap.kind.displayName) \(pct)%"
            }.joined(separator: " · ")
            button.toolTip = "Quota Bar · \(summary)"
        }
    }

    /// 画 N 个垂直 bar 的 NSImage。
    ///
    /// 每个订阅 1 个 bar：
    /// - 宽 3.5pt，高 = `max(2pt, remainingFraction × 14pt)`
    /// - 间距 1.5pt
    /// - 颜色 = kind 的 brand color（95% 不透明度，让 menu bar 背景轻微透出，模拟 liquid glass 透光感）
    /// - 圆角 1pt（接近 SF Symbol 的圆角感）
    ///
    /// Image 总高 16pt（适配 NSStatusBar 默认 ~22pt 高度 + 上下 padding）。
    private static func makeBarsImage(from snapshots: [ProviderSnapshot]) -> NSImage {
        let barWidth: CGFloat = 3.5
        let barGap: CGFloat = 1.5
        let imageHeight: CGFloat = 16
        let topPadding: CGFloat = 2
        let bottomPadding: CGFloat = 2
        let maxBarHeight = imageHeight - topPadding - bottomPadding  // 12pt
        let minBarHeight: CGFloat = 2  // 用完也画最小 bar，让用户知情
        let count = snapshots.count

        // 兜底：零订阅 → ? 图标
        if count == 0 {
            if let fallback = NSImage(
                systemSymbolName: "questionmark.circle",
                accessibilityDescription: "Quota Bar 暂无订阅"
            ) {
                fallback.isTemplate = true
                fallback.size = NSSize(width: 16, height: 16)
                return fallback
            }
        }

        let totalWidth = CGFloat(count) * barWidth + CGFloat(max(0, count - 1)) * barGap
        let image = NSImage(size: NSSize(width: max(totalWidth, 8), height: imageHeight))
        image.lockFocus()

        // Liquid glass 容器：极淡灰半透明圆角矩形，模拟 menu bar widget 的玻璃底
        let containerRect = NSRect(x: 0, y: 0, width: totalWidth, height: imageHeight)
        let containerPath = NSBezierPath(
            roundedRect: containerRect.insetBy(dx: -1, dy: -1),
            xRadius: 3.5,
            yRadius: 3.5
        )
        NSColor(white: 0, alpha: 0.04).setFill()
        containerPath.fill()

        for (i, snap) in snapshots.enumerated() {
            // bar 高度 = 该订阅所有 quota 窗口里最低 remainingFraction（对齐"最紧迫"）
            let remaining = snap.quotas.isEmpty
                ? 1.0
                : snap.quotas.map { $0.remainingFraction }.min() ?? 1.0
            let barHeight = max(minBarHeight, CGFloat(remaining) * maxBarHeight)
            let x = CGFloat(i) * (barWidth + barGap)
            let y = bottomPadding + (maxBarHeight - barHeight) / 2

            let rect = NSRect(x: x, y: y, width: barWidth, height: barHeight)
            let path = NSBezierPath(roundedRect: rect, xRadius: 1.0, yRadius: 1.0)

            let color = brandNSColor(for: snap.kind)
            // 95% 不透明度让 menu bar 背景轻微透出，模拟 liquid glass 透光
            color.withAlphaComponent(0.95).setFill()
            path.fill()
        }

        image.unlockFocus()
        image.isTemplate = false  // 用品牌色，不用 template
        return image
    }

    private static func brandNSColor(for kind: ProviderKind) -> NSColor {
        switch kind {
        case .codex: return NSColor(srgbRed: 0x35/255, green: 0xC8/255, blue: 0x5A/255, alpha: 1)
        case .minimax: return NSColor(srgbRed: 0xFF/255, green: 0x45/255, blue: 0x3A/255, alpha: 1)
        case .kimi: return NSColor(srgbRed: 0xFF/255, green: 0x9F/255, blue: 0x0A/255, alpha: 1)
        case .claude: return NSColor(srgbRed: 0xD4/255, green: 0xA5/255, blue: 0x74/255, alpha: 1)
        case .cursor: return NSColor(srgbRed: 0x5E/255, green: 0x6A/255, blue: 0xD2/255, alpha: 1)
        case .gemini: return NSColor(srgbRed: 0x42/255, green: 0x85/255, blue: 0xF4/255, alpha: 1)
        case .openai: return NSColor(srgbRed: 0x10/255, green: 0xA3/255, blue: 0x7F/255, alpha: 1)
        case .deepseek: return NSColor(srgbRed: 0x4D/255, green: 0x6B/255, blue: 0xFA/255, alpha: 1)
        case .copilot: return NSColor(srgbRed: 0x6E/255, green: 0x76/255, blue: 0x81/255, alpha: 1)
        case .openrouter: return NSColor(srgbRed: 0xF5/255, green: 0x9E/255, blue: 0x0B/255, alpha: 1)
        case .perplexity: return NSColor(srgbRed: 0x1F/255, green: 0xB8/255, blue: 0xCD/255, alpha: 1)
        case .warp: return NSColor(srgbRed: 0x5E/255, green: 0x6A/255, blue: 0xD2/255, alpha: 1)
        case .trae: return NSColor(srgbRed: 0x3D/255, green: 0x7C/255, blue: 0xFF/255, alpha: 1)
        case .antigravity: return NSColor(srgbRed: 0x1A/255, green: 0x73/255, blue: 0xE8/255, alpha: 1)
        }
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
