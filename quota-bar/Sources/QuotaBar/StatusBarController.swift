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
        // 用固定 length 避免 macOS 26 NSStatusBar 把 item 放到虚拟屏外
        // （variableLength 在新菜单栏 widget 系统里会落到不可见区域，AppleScript 报 x=-719）
        self.statusItem = NSStatusBar.system.statusItem(withLength: 80)
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
    /// - **零订阅**：单 SF Symbol `questionmark.circle`
    /// - **有 fetchFailed**：fetchFailed 的订阅不画 bar，但其他正常订阅的 bar 仍画
    ///
    /// **刷新中不切换图标**——保持 bars 不变，避免菜单栏出现 spinner 闪烁。
    /// tooltip 也不带"正在刷新"字样，只展示订阅剩余百分比。
    private func refreshStatusItemAppearance() {
        guard let button = statusItem.button else { return }

        let snapshots = coordinator.state.snapshots
        let available = snapshots.filter { $0.availability == .available }

        // 无论是否刷新中，都画 bars image（保持菜单栏稳定，不闪 spinner）
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

    /// 画 N 个垂直 bar 的 NSImage（macOS 26 Liquid Glass menu bar widget 规范）。
    ///
    /// 容器：
    /// - 1px white 30% 透明边框，6pt 圆角
    /// - 内框 20×20pt，padding 2pt → 内容区 16×16pt
    ///
    /// Bars：
    /// - 颜色 = 纯白 `#FFFFFF`（不染色，让 liquid glass 容器区分订阅）
    /// - 高度 = `max(2pt, remainingFraction × 16pt)`
    /// - 居底对齐（bar bottom = container bottom）
    /// - 宽度按订阅数动态：N=1 → 16pt；N=2 → 7.5pt；N≥3 → 4.67pt（最小宽度）
    /// - gap = 1pt
    /// - 圆角 4pt（除非 bar 太窄，自动降为宽度一半）
    ///
    /// 总尺寸：
    /// - 高度固定 24pt（容器 20pt + 上下 padding 2pt×2）
    /// - 宽度 = 内容总宽 + 边框 2pt
    ///   - N=1 → 22pt
    ///   - N=2 → 22pt
    ///   - N=3 → 22pt
    ///   - N=4 → 29.67pt（容器变宽以容纳更多 bar）
    private static func makeBarsImage(from snapshots: [ProviderSnapshot]) -> NSImage {
        // 兜底：零订阅 → ? 图标
        if snapshots.isEmpty {
            if let fallback = NSImage(
                systemSymbolName: "questionmark.circle",
                accessibilityDescription: "Quota Bar 暂无订阅"
            ) {
                fallback.isTemplate = true
                fallback.size = NSSize(width: 16, height: 16)
                return fallback
            }
        }

        let count = snapshots.count
        let containerHeight: CGFloat = 20
        let borderRadius: CGFloat = 6
        let contentSize: CGFloat = 16  // 20 - 2×2 padding
        let gap: CGFloat = 1
        let minBarWidth: CGFloat = 4.67

        // 动态 bar 宽度：理想 (content - (N-1) × gap) / N，但不低于 minBarWidth
        let barWidth: CGFloat = {
            if count <= 1 { return contentSize }
            let totalGap = CGFloat(count - 1) * gap
            let ideal = (contentSize - totalGap) / CGFloat(count)
            return max(ideal, minBarWidth)
        }()

        // 内容总宽 = N × barWidth + (N-1) × gap
        let contentWidth = CGFloat(count) * barWidth + CGFloat(max(0, count - 1)) * gap
        // 外框宽度（含 2px padding）
        let containerWidth = contentWidth + 4

        // 画布尺寸：外框 + 上下 2pt margin（让 image 比 NSStatusItem 默认高度略小）
        let imageHeight: CGFloat = 24
        let imageWidth: CGFloat = containerWidth + 4  // 左右各 2pt margin

        let image = NSImage(size: NSSize(width: imageWidth, height: imageHeight))
        image.lockFocus()

        // 计算容器在画布上的位置（居中）
        let containerX = (imageWidth - containerWidth) / 2
        let containerY: CGFloat = 2

        // 1. Liquid glass 容器背景（白 30% 边框 + 透明填充，模拟 glass 容器）
        let containerRect = NSRect(
            x: containerX,
            y: containerY,
            width: containerWidth,
            height: containerHeight
        )
        let containerPath = NSBezierPath(roundedRect: containerRect, xRadius: borderRadius, yRadius: borderRadius)
        // 透明填充 + 1px 白 30% 边框
        NSColor.clear.setFill()
        containerPath.fill()
        NSColor(white: 1.0, alpha: 0.3).setStroke()
        containerPath.lineWidth = 1.0
        containerPath.stroke()

        // 2. Bars（白色，居底对齐）
        let contentOriginX = containerX + 2  // 容器内 padding 2pt
        let contentOriginY = containerY + 2  // 容器内 padding 2pt (bottom)
        let minBarHeight: CGFloat = 2  // 用完也画最小 bar
        let maxBarHeight = contentSize  // 16pt

        for (i, snap) in snapshots.enumerated() {
            // bar 高度 = 该订阅所有 quota 窗口里最低 remainingFraction
            let remaining = snap.quotas.isEmpty
                ? 1.0
                : snap.quotas.map { $0.remainingFraction }.min() ?? 1.0
            let barHeight = max(minBarHeight, CGFloat(remaining) * maxBarHeight)
            let barX = contentOriginX + CGFloat(i) * (barWidth + gap)
            // 居底对齐：bar bottom = contentOriginY（容器内 bottom）
            let barY = contentOriginY

            let rect = NSRect(x: barX, y: barY, width: barWidth, height: barHeight)
            // 圆角不超过 bar 宽度一半（避免窄 bar 圆角重叠）
            let cornerRadius = min(4.0, barWidth / 2.0)
            let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
            NSColor.white.setFill()
            path.fill()
        }

        image.unlockFocus()
        image.isTemplate = false
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
            needsFullDiskAccess: coordinator.needsFullDiskAccess,
            onSaveKey: { [weak self] kind, _ in
                // 用户保存了某个 provider 的 API key → 触发刷新
                self?.coordinator.refreshNow()
            }
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
