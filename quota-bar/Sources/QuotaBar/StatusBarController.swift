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
    private var isMenuOpen = false
    private var needsRebuild = false

    let statusItem: NSStatusItem

    init(coordinator: RefreshCoordinator = RefreshCoordinator(
        providers: ProviderFactory.createProviders(),
        installDetectors: ProviderFactory.createInstallDetectors()
    )) {
        self.coordinator = coordinator
        // 不使用 variableLength，避免 macOS 26 新菜单栏 widget 系统把 item 放到虚拟屏外；
        // 后续按实际绘制 image 宽度手动更新 length，避免窄图标占 80pt。
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
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
        button.imageScaling = .scaleNone
        button.toolTip = "Quota Bar"
        statusItem.menu = menu
        refreshStatusItemAppearance()
    }

    /// 根据 coordinator.state 切换状态栏图标 + tooltip。
    ///
    /// **状态栏设计**（Liquid Glass 风格）：
    /// - **正常**：画 N 个垂直圆角 bar，每个对应一个 `.available` 订阅；
    ///   - bar 数量 = 已配置订阅数（needsConfiguration / notInstalled / fetchFailed 不显示）
    ///   - bar 颜色 = 该订阅名称的 brand color
    ///   - bar 高度 = 该订阅最近重置 quota 窗口的 `remainingFraction`
    ///   - bar 顺序 = dashboard 里的 snapshot 顺序（按 `kind.rawValue` 字母升序）
    ///   - 用完的（0%）仍然画最小 bar，让用户知道订阅存在
    /// - **零订阅**：单 SF Symbol `questionmark.circle`
    /// - **有 fetchFailed**：fetchFailed 的订阅不画 bar，但其他正常订阅的 bar 仍画
    ///
    /// **刷新中不切换图标**——保持 bars 不变，避免菜单栏出现 spinner 闪烁。
    /// tooltip 也不带"正在刷新"字样，只展示订阅剩余百分比。
    private func refreshStatusItemAppearance() {
        guard let button = statusItem.button else { return }

        let snapshots = coordinator.state.snapshots
        let available = Self.drawableSnapshots(from: snapshots)

        // 无论是否刷新中，都画 bars image（保持菜单栏稳定，不闪 spinner）
        let image = Self.makeBarsImage(from: available)
        button.image = image
        button.title = ""
        statusItem.length = Self.statusItemLength(for: image)

        // tooltip：每个订阅的剩余%（loading 的 provider 显示「刷新中」而不是 50%）
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
                if case .loading = snap.availability {
                    return "\(snap.kind.displayName) 刷新中"
                }
                let pct = Int((Self.remainingFraction(for: snap) * 100).rounded())
                return "\(snap.kind.displayName) \(pct)%"
            }.joined(separator: " · ")
            button.toolTip = "Quota Bar · \(summary)"
        }
    }

    /// 画 N 个垂直 bar 的 NSImage（macOS 26 Liquid Glass menu bar widget 规范）。
    ///
    /// 只绘制 `.available` / `.needsConfiguration` / `.loading` 的 snapshot；
    /// 高度取该订阅最近重置 quota 窗口的 `remainingFraction`，
    /// 与 dropdown 中最紧迫周期的读数一致。
    /// **`.loading` 画 dimmed 50% 占位 bar**，streaming refresh 时随着 provider 一个个
    /// 完成，bar 从"dimmed 占位"渐变为"实际高度"。
    private static func makeBarsImage(from snapshots: [ProviderSnapshot]) -> NSImage {
        let snapshots = drawableSnapshots(from: snapshots)

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

        let layout = BarsImageLayout(count: snapshots.count)
        let image = NSImage(size: layout.imageSize)
        image.isTemplate = false
        image.lockFocus()
        NSGraphicsContext.current?.shouldAntialias = true

        let borderPath = NSBezierPath(
            roundedRect: layout.borderRect,
            xRadius: layout.borderRadius,
            yRadius: layout.borderRadius
        )
        NSColor(white: 1.0, alpha: 0.5).setStroke()
        borderPath.lineWidth = layout.borderWidth
        borderPath.stroke()

        // 填充 bars（白色，居底对齐）。最左侧 bar 左下角圆角。
        // `.loading` snapshot 画 dimmed 50% bar（alpha 0.4），与其他 bar 视觉上
        // 区分开（让用户看到「这个 provider 还在刷新」），同时保持可见以体现"动态增长"。
        for (i, snap) in snapshots.enumerated() {
            let remaining = remainingFraction(for: snap)
            let rect = layout.barRect(at: i, remainingFraction: CGFloat(remaining))
            guard rect.height > 0 else { continue }
            let path = layout.barPath(at: i, rect: rect)
            if case .loading = snap.availability {
                NSColor(white: 1.0, alpha: 0.4).setFill()
            } else {
                NSColor.white.setFill()
            }
            path.fill()
        }

        image.unlockFocus()
        return image
    }

    private static func statusItemLength(for image: NSImage) -> CGFloat {
        // image 宽度就是可见 bar 组宽度；status item 不再额外加宽。
        if image.isTemplate {
            return NSStatusItem.squareLength
        }
        return ceil(image.size.width)
    }

    private static func drawableSnapshots(from snapshots: [ProviderSnapshot]) -> [ProviderSnapshot] {
        // 显示：available（有 quota）/ needsConfiguration / loading
        // 隐藏：notInstalled / fetchFailed
        snapshots.filter { snapshot in
            switch snapshot.availability {
            case .available:
                return !snapshot.quotas.isEmpty
            case .needsConfiguration, .loading:
                return true
            case .notInstalled, .fetchFailed:
                return false
            }
        }
    }

    private static func remainingFraction(for snapshot: ProviderSnapshot, now: Date = Date()) -> Double {
        // loading 和 needsConfiguration 都显示 50% 的 bar（loading 用 dimmed alpha 区分）
        switch snapshot.availability {
        case .loading, .needsConfiguration:
            return 0.5
        default:
            break
        }
        guard let quota = statusBarQuota(for: snapshot, now: now) else { return 0 }
        return max(0, min(1, quota.remainingFraction))
    }

    private static func statusBarQuota(for snapshot: ProviderSnapshot, now: Date) -> QuotaWindow? {
        // 取用户排序后第一个**订阅组**（top subscription group）里剩余比例最低的 quota。
        // 多订阅组（MiniMax General/Video、Antigravity Gemini/Other）按用户拖拽顺序取排第一的组；
        // 单一订阅组（Codex/Kimi 整组）取整组最差那条。
        // bar/灯取值只跟"订阅组顺序"绑定，跟 quota 拖拽顺序解耦。
        let groupOrder = PreferencesStore.shared.subscriptionGroupOrder(for: snapshot.kind)
        return snapshot.primarySubscriptionGroupWorstQuota(itemOrder: groupOrder)
    }

    private struct BarsImageLayout {
        let count: Int

        let imageHeight: CGFloat = 18
        let borderWidth: CGFloat = 1
        let borderRadius: CGFloat = 4
        let barToLinePadding: CGFloat = 1
        let gap: CGFloat = 1
        let barRadius: CGFloat = 2
        let verticalPadding: CGFloat = 1

        var barWidth: CGFloat {
            switch count {
            case 1: return 14
            case 2: return 7
            default: return 4
            }
        }

        var contentWidth: CGFloat {
            CGFloat(count) * barWidth + CGFloat(max(0, count - 1)) * gap
        }

        var imageSize: NSSize {
            let totalWidth = contentWidth + 2 * barToLinePadding + 2 * borderWidth
            return NSSize(width: totalWidth, height: imageHeight)
        }

        var borderRect: NSRect {
            NSRect(
                x: borderWidth / 2,
                y: borderWidth / 2,
                width: imageSize.width - borderWidth,
                height: imageSize.height - borderWidth
            )
        }

        func barRect(at index: Int, remainingFraction: CGFloat) -> NSRect {
            let clampedFraction = max(0, min(1, remainingFraction))
            let maxBarHeight = imageHeight - 2 * borderWidth - 2 * verticalPadding
            let barHeight = clampedFraction * maxBarHeight
            return NSRect(
                x: borderWidth + barToLinePadding + CGFloat(index) * (barWidth + gap),
                y: borderWidth + verticalPadding,
                width: barWidth,
                height: barHeight
            )
        }

        func barPath(at index: Int, rect: NSRect) -> NSBezierPath {
            let radius = min(barRadius, rect.width / 2, rect.height / 2)
            guard radius > 0 else {
                return NSBezierPath(rect: rect)
            }

            let isFirst = index == 0
            let isLast = index == count - 1

            if isFirst && isLast {
                // 只有一个 bar，四个角都圆角
                return NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
            } else if isFirst {
                // 最左 bar，只绘制左侧圆角（左上和左下）
                let path = NSBezierPath()
                let minX = rect.minX
                let maxX = rect.maxX
                let minY = rect.minY
                let maxY = rect.maxY

                // 从左上圆角的起点开始
                path.move(to: NSPoint(x: minX, y: maxY - radius))
                path.curve(
                    to: NSPoint(x: minX + radius, y: maxY),
                    controlPoint1: NSPoint(x: minX, y: maxY - radius * 0.45),
                    controlPoint2: NSPoint(x: minX + radius * 0.45, y: maxY)
                )
                // 上边
                path.line(to: NSPoint(x: maxX, y: maxY))
                // 右边
                path.line(to: NSPoint(x: maxX, y: minY))
                // 下边
                path.line(to: NSPoint(x: minX + radius, y: minY))
                // 左下圆角
                path.curve(
                    to: NSPoint(x: minX, y: minY + radius),
                    controlPoint1: NSPoint(x: minX + radius * 0.45, y: minY),
                    controlPoint2: NSPoint(x: minX, y: minY + radius * 0.45)
                )
                path.close()
                return path
            } else if isLast {
                // 最右 bar，只绘制右侧圆角（右上和右下）
                let path = NSBezierPath()
                let minX = rect.minX
                let maxX = rect.maxX
                let minY = rect.minY
                let maxY = rect.maxY

                // 从左上开始
                path.move(to: NSPoint(x: minX, y: maxY))
                // 上边
                path.line(to: NSPoint(x: maxX - radius, y: maxY))
                // 右上圆角
                path.curve(
                    to: NSPoint(x: maxX, y: maxY - radius),
                    controlPoint1: NSPoint(x: maxX - radius * 0.45, y: maxY),
                    controlPoint2: NSPoint(x: maxX, y: maxY - radius * 0.45)
                )
                // 右边
                path.line(to: NSPoint(x: maxX, y: minY + radius))
                // 右下圆角
                path.curve(
                    to: NSPoint(x: maxX - radius, y: minY),
                    controlPoint1: NSPoint(x: maxX, y: minY + radius * 0.45),
                    controlPoint2: NSPoint(x: maxX - radius * 0.45, y: minY)
                )
                // 下边
                path.line(to: NSPoint(x: minX, y: minY))
                path.close()
                return path
            } else {
                // 中间 bar，不绘制圆角
                return NSBezierPath(rect: rect)
            }
        }
    }

    private static func statusBarColor(for snapshot: ProviderSnapshot) -> NSColor {
        brandNSColor(for: snapshot.kind)
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
        isMenuOpen = true
        rebuildMenu()
    }

    func menuDidClose(_ menu: NSMenu) {
        isMenuOpen = false
        if needsRebuild {
            needsRebuild = false
            rebuildMenu()
        }
    }

    // MARK: - 菜单重建

    private func rebuildMenu() {
        menu.removeAllItems()

        let dashboardItem = NSMenuItem()
        let menuView = MenuView(
            coordinator: coordinator,
            onSaveKey: { [weak self] kind, _ in
                // 用户保存了某个 provider 的 API key → 触发刷新
                self?.coordinator.refreshNow()
            },
            onHideKind: { [weak self] kind in
                self?.coordinator.hide(kind: kind)
                self?.rebuildMenu()
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

        let timeText = "\(coordinator.autoRefreshText)，\(coordinator.lastUpdatedText)"
        let timeItem = NSMenuItem(title: timeText, action: nil, keyEquivalent: "")
        timeItem.isEnabled = false
        timeItem.attributedTitle = NSAttributedString(
            string: timeText,
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        menu.addItem(timeItem)

        // 偏好设置入口：v0.3.0-PM-A-000 在 feat/preferences branch 落地后重新启用。
        // SwiftUI `Settings` scene 自动处理 `⌘,` 快捷键与窗口生命周期，这里只需要 sendAction 触发。
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
                // MenuView 通过 @ObservedObject 订阅 coordinator，菜单打开期间 SwiftUI
                // 会原地重渲染 NSHostingView 内容，不需要 rebuildMenu。
                // 状态栏图标仍然需要主动刷新。
                if !(self?.isMenuOpen ?? false) {
                    self?.rebuildMenu()
                }
                self?.refreshStatusItemAppearance()
            }
            .store(in: &cancellables)

        coordinator.$isRefreshing
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                if !(self?.isMenuOpen ?? false) {
                    self?.rebuildMenu()
                }
                self?.refreshStatusItemAppearance()
            }
            .store(in: &cancellables)

        coordinator.$needsFullDiskAccess
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                if !(self?.isMenuOpen ?? false) {
                    self?.rebuildMenu()
                }
            }
            .store(in: &cancellables)

        // 用户拖拽额度对象或 Provider 区块导致排序偏好变化时：
        // 1. 立即刷新菜单栏图标（status item）；
        // 2. 菜单关闭时整体 rebuild（菜单打开期间 SwiftUI 已通过 @ObservedObject 自动响应）。
        NotificationCenter.default.publisher(for: .quotaPreferencesDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                if !self.isMenuOpen {
                    self.rebuildMenu()
                }
                self.refreshStatusItemAppearance()
            }
            .store(in: &cancellables)
    }

    // MARK: - 菜单动作

    @objc private func refreshNow() {
        coordinator.refreshNow()
    }

    // 触发 SwiftUI `Settings` scene：sendAction `showSettingsWindow:` 是系统约定的 selector，
    // SwiftUI App 的 Settings scene 自动响应并显示/聚焦偏好窗口（v0.3.0-PM-A-006）。
    @objc private func openPreferences() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc private func quit() {
        coordinator.stop()
        NSApplication.shared.terminate(nil)
    }
}
