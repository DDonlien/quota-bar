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
        installDetectors: ProviderFactory.createInstallDetectors(),
        // 此前这里没传，`RefreshCoordinator` 用自己构造函数的默认值 5 分钟——不管用户在
        // 偏好设置里存了什么，每次启动都会被无视。这里显式传入持久化的偏好值。
        refreshInterval: PreferencesStore.shared.preferences.refreshIntervalSeconds,
        // 同上：`advanced.providerTimeoutSeconds` 之前也没人读过，`providerTimeout` 一直
        // 固定用 `RefreshCoordinator` 自己的默认值（10 秒）。
        providerTimeout: PreferencesStore.shared.preferences.advanced.providerTimeoutSeconds
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
                if case .subscriptionExpired = snap.availability {
                    // v0.8.0：tooltip 提示"已过期"，区别于正常的 0% / 30% 数字
                    return "\(snap.kind.displayName) 已过期"
                }
                let pct = Int((Self.remainingFraction(for: snap) * 100).rounded())
                return "\(snap.kind.displayName) \(pct)%"
            }.joined(separator: " · ")
            button.toolTip = "Quota Bar · \(summary)"
        }
    }

    /// 画 N 个垂直 bar 的 NSImage（macOS 26 Liquid Glass menu bar widget 规范）。
    ///
    /// 只绘制 `.available` / `.loading` / `.subscriptionExpired` 的 snapshot；
    /// 高度取该订阅最近重置 quota 窗口的 `remainingFraction`，
    /// 与 dropdown 中最紧迫周期的读数一致。
    /// **`.loading` 画 dimmed 50% 占位 bar**，streaming refresh 时随着 provider 一个个
    /// 完成，bar 从"dimmed 占位"渐变为"实际高度"。
    // 三处从 `private` 松到默认 internal（`makeBarsImage`/`layeredFractions`/
    // `BarsImageLayout`）：分层显示这套自定义绘图逻辑第一次写，靠单元测试直接验证
    // 选层/几何计算，比只靠人工截图靠谱——真实截图这个 accessory 模式 + 未签名
    // 开发态包又拿不到（这个会话里反复踩过这个坑），能测的部分就应该测。
    static func makeBarsImage(from snapshots: [ProviderSnapshot]) -> NSImage {
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

        // 分层显示（2026-07-09 新增）：每个 bar 最多画两层——实心层固定对应最短周期
        // 额度（比如 5 小时），虚线/纹理层固定对应次短周期额度（比如周额度），只有
        // 一条 quota 的 provider 退化成单层（跟改动前一样）。叠放顺序取决于谁更高：
        // 更高的那层先画在底层，更矮的那层后画、叠在前面——保证矮的那层不会被高的
        // 那层完全盖住（用户提供的参考图示范了两种叠放情况）。
        // `.loading` snapshot 两层都用 dimmed alpha，跟其他 bar 视觉上区分开
        // （让用户看到「这个 provider 还在刷新」），同时保持可见以体现"动态增长"。
        for (i, snap) in snapshots.enumerated() {
            let isLoading: Bool
            if case .loading = snap.availability { isLoading = true } else { isLoading = false }
            let solidAlpha: CGFloat = isLoading ? 0.4 : 1.0
            let hatchAlpha: CGFloat = isLoading ? 0.25 : 0.45

            let (primaryFraction, secondaryFraction) = layeredFractions(for: snap)
            let primaryRect = layout.barRect(at: i, remainingFraction: CGFloat(primaryFraction))

            guard let secondaryFraction else {
                guard primaryRect.height > 0 else { continue }
                let path = layout.barPath(at: i, rect: primaryRect)
                NSColor(white: 1.0, alpha: solidAlpha).setFill()
                path.fill()
                continue
            }

            let secondaryRect = layout.barRect(at: i, remainingFraction: CGFloat(secondaryFraction))
            let solidPath = primaryRect.height > 0 ? layout.barPath(at: i, rect: primaryRect) : nil
            let hatchedPath = secondaryRect.height > 0 ? layout.barPath(at: i, rect: secondaryRect) : nil

            if secondaryRect.height >= primaryRect.height {
                // 次短周期剩余更多（更常见情况）：它更高，先画成底层背景——这时纹理层
                // 底下还是透明画布，用普通半透明白色斜线就能跟深色菜单栏背景形成对比；
                // 最短周期（实心）更矮，叠在它前面。
                if let hatchedPath { fillHatched(hatchedPath, alpha: hatchAlpha, erasing: false) }
                if let solidPath {
                    NSColor(white: 1.0, alpha: solidAlpha).setFill()
                    solidPath.fill()
                }
            } else {
                // 次短周期剩余更少（比如周额度快用完了，但当前 5 小时窗口刚重置）：
                // 实心层更高，先画成底；纹理层更矮，叠在前面——这时纹理层底下已经是
                // 不透明的实心白色，半透明白色斜线在纯白底上完全看不出来，改用
                // `.destinationOut` 直接在实心层上"擦"出斜线镂空，让菜单栏背景从
                // 缝隙里透出来，不管底下是透明画布还是已经填满的实心层都看得清。
                if let solidPath {
                    NSColor(white: 1.0, alpha: solidAlpha).setFill()
                    solidPath.fill()
                }
                if let hatchedPath { fillHatched(hatchedPath, alpha: hatchAlpha, erasing: true) }
            }
        }

        image.unlockFocus()
        return image
    }

    /// 虚线/纹理层的画法：45° 斜线阵列，裁剪到传入的 bar 形状内。用手绘斜线而不是
    /// 平铺 pattern image——图标只有个位数 pt 宽，`NSColor(patternImage:)` 那套在
    /// 这个尺度下没有直接手绘线条精确可控。
    ///
    /// `erasing`：纹理层叠在已经画满的实心层前面时（次短周期比最短周期矮的场景），
    /// 半透明白色斜线画在纯白底上完全没有对比度、视觉上等于什么都没画——这种情况
    /// 改用 `.destinationOut` 复合模式把斜线"擦"进已经画好的实心区域，露出底下的
    /// 菜单栏背景，不管背景是透明画布还是已经不透明都能看出纹理。纹理层是背景层
    /// （画在透明画布上）时正常画半透明白色斜线即可，`erasing` 传 `false`。
    private static func fillHatched(_ path: NSBezierPath, alpha: CGFloat, erasing: Bool) {
        NSGraphicsContext.saveGraphicsState()
        path.addClip()
        let bounds = path.bounds
        let spacing: CGFloat = 2.0
        let lineWidth: CGFloat = 0.75
        if erasing {
            NSGraphicsContext.current?.compositingOperation = .destinationOut
            NSColor(white: 0, alpha: alpha).setStroke()
        } else {
            NSColor(white: 1.0, alpha: alpha).setStroke()
        }
        var x = bounds.minX - bounds.height
        while x < bounds.maxX {
            let segment = NSBezierPath()
            segment.lineWidth = lineWidth
            segment.move(to: NSPoint(x: x, y: bounds.minY))
            segment.line(to: NSPoint(x: x + bounds.height, y: bounds.maxY))
            segment.stroke()
            x += spacing
        }
        NSGraphicsContext.restoreGraphicsState()
    }

    private static func statusItemLength(for image: NSImage) -> CGFloat {
        // image 宽度就是可见 bar 组宽度；status item 不再额外加宽。
        if image.isTemplate {
            return NSStatusItem.squareLength
        }
        return ceil(image.size.width)
    }

    static func drawableSnapshots(from snapshots: [ProviderSnapshot]) -> [ProviderSnapshot] {
        // 显示：available（有 quota）/ loading / subscriptionExpired
        // 隐藏：needsConfiguration / notSubscribed / notInstalled / fetchFailed
        // v0.8.0：subscriptionExpired 仍画 bar（0% 高度，最小占位），让用户看到
        // "我知道这个订阅存在但已过期"——区别于 notInstalled（直接不画）。
        snapshots.filter { snapshot in
            switch snapshot.availability {
            case .available:
                return !snapshot.quotas.isEmpty
            case .loading, .subscriptionExpired:
                return true
            case .needsConfiguration, .notSubscribed, .notInstalled, .fetchFailed:
                return false
            }
        }
    }

    private static func remainingFraction(for snapshot: ProviderSnapshot, now: Date = Date()) -> Double {
        // loading 和 needsConfiguration 都显示 50% 的 bar（loading 用 dimmed alpha 区分）
        switch snapshot.availability {
        case .loading, .needsConfiguration:
            return 0.5
        case .subscriptionExpired:
            // v0.8.0：订阅已过期 → bar 高度 0%（与其他"用完"视觉一致），但仍画最小 bar
            // 占位以让用户知道订阅存在。
            return 0
        case .notSubscribed:
            return 0
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

    /// 菜单栏图标分层显示（2026-07-09 新增）：每个 bar 最多同时画两层——
    /// `primary` 固定对应最短周期额度（比如 5 小时），`secondary`（存在的话）固定对应
    /// 次短周期额度（比如周额度）。跟 `remainingFraction`（单层、按"剩余最少"取值）
    /// 是两套并行逻辑：单层場景（loading/needsConfiguration/subscriptionExpired/
    /// notSubscribed，以及只有一条 quota 的 provider）复用同样的固定值语义，`secondary`
    /// 为 nil，退化成原来的单层画法。
    static func layeredFractions(for snapshot: ProviderSnapshot, now: Date = Date()) -> (primary: Double, secondary: Double?) {
        switch snapshot.availability {
        case .loading, .needsConfiguration:
            return (0.5, nil)
        case .subscriptionExpired, .notSubscribed:
            return (0, nil)
        default:
            break
        }
        let groupOrder = PreferencesStore.shared.subscriptionGroupOrder(for: snapshot.kind)
        guard let pair = snapshot.primarySubscriptionGroupTopTwoQuotasByPeriod(itemOrder: groupOrder) else {
            return (0, nil)
        }
        let primary = max(0, min(1, pair.shortest.remainingFraction))
        let secondary = pair.secondShortest.map { max(0, min(1, $0.remainingFraction)) }
        return (primary, secondary)
    }

    struct BarsImageLayout {
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

        var maxBarHeight: CGFloat {
            imageHeight - 2 * borderWidth - 2 * verticalPadding
        }

        func barRect(at index: Int, remainingFraction: CGFloat) -> NSRect {
            let clampedFraction = max(0, min(1, remainingFraction))
            let barHeight = clampedFraction * maxBarHeight
            return NSRect(
                x: borderWidth + barToLinePadding + CGFloat(index) * (barWidth + gap),
                y: borderWidth + verticalPadding,
                width: barWidth,
                height: barHeight
            )
        }

        /// 顶部圆角按"bar 顶边离容器顶边的距离"自然过渡：距离为 0（bar 顶到頂、
        /// 满额度）时给足 `barRadius`，距离达到 `barRadius` 或更远时收缩到 0——
        /// 一个远低于容器顶部的短 bar 不应该还带着一个视觉上跟顶边毫无关系、凭空
        /// 浮在中间的圆角（2026-07-09 用户反馈）。底部圆角不受此影响，bar 永远贴底，
        /// 底边圆角固定跟容器底边圆角保持一致。
        private func adaptiveTopRadius(for rect: NSRect) -> CGFloat {
            let containerTopY = borderWidth + verticalPadding + maxBarHeight
            let gap = max(0, containerTopY - rect.maxY)
            guard gap < barRadius else { return 0 }
            return barRadius * (1 - gap / barRadius)
        }

        /// 最左/最右 bar 的圆角矩形路径：底部固定 `barRadius`，顶部用
        /// `adaptiveTopRadius` 自然过渡；中间 bar 直接返回普通矩形（跟改动前一样，
        /// 不受影响）。分层显示下，实心层和纹理层各自独立调用这个函数、各自按
        /// 自己的高度算顶部圆角——哪一层的顶边离容器顶边近，哪一层就该有顶部圆角，
        /// 跟另一层的高度无关。
        func barPath(at index: Int, rect: NSRect) -> NSBezierPath {
            guard rect.width > 0, rect.height > 0 else { return NSBezierPath(rect: rect) }

            let isFirst = index == 0
            let isLast = index == count - 1
            guard isFirst || isLast else { return NSBezierPath(rect: rect) }

            let bottomRadius = min(barRadius, rect.width / 2, rect.height / 2)
            let topRadius = min(adaptiveTopRadius(for: rect), rect.width / 2, rect.height / 2)
            let topLeft = isFirst ? topRadius : 0
            let topRight = isLast ? topRadius : 0
            let bottomLeft = isFirst ? bottomRadius : 0
            let bottomRight = isLast ? bottomRadius : 0

            guard topLeft > 0 || topRight > 0 || bottomLeft > 0 || bottomRight > 0 else {
                return NSBezierPath(rect: rect)
            }
            return Self.roundedRectPath(
                rect: rect,
                topLeft: topLeft, topRight: topRight,
                bottomLeft: bottomLeft, bottomRight: bottomRight
            )
        }

        /// 支持四个角各自独立半径的圆角矩形路径（半径为 0 的角画成直角）。
        private static func roundedRectPath(
            rect: NSRect,
            topLeft: CGFloat, topRight: CGFloat,
            bottomLeft: CGFloat, bottomRight: CGFloat
        ) -> NSBezierPath {
            let minX = rect.minX, maxX = rect.maxX, minY = rect.minY, maxY = rect.maxY
            let path = NSBezierPath()

            path.move(to: NSPoint(x: minX, y: maxY - topLeft))
            if topLeft > 0 {
                path.curve(
                    to: NSPoint(x: minX + topLeft, y: maxY),
                    controlPoint1: NSPoint(x: minX, y: maxY - topLeft * 0.45),
                    controlPoint2: NSPoint(x: minX + topLeft * 0.45, y: maxY)
                )
            } else {
                path.line(to: NSPoint(x: minX, y: maxY))
            }

            path.line(to: NSPoint(x: maxX - topRight, y: maxY))
            if topRight > 0 {
                path.curve(
                    to: NSPoint(x: maxX, y: maxY - topRight),
                    controlPoint1: NSPoint(x: maxX - topRight * 0.45, y: maxY),
                    controlPoint2: NSPoint(x: maxX, y: maxY - topRight * 0.45)
                )
            } else {
                path.line(to: NSPoint(x: maxX, y: maxY))
            }

            path.line(to: NSPoint(x: maxX, y: minY + bottomRight))
            if bottomRight > 0 {
                path.curve(
                    to: NSPoint(x: maxX - bottomRight, y: minY),
                    controlPoint1: NSPoint(x: maxX, y: minY + bottomRight * 0.45),
                    controlPoint2: NSPoint(x: maxX - bottomRight * 0.45, y: minY)
                )
            } else {
                path.line(to: NSPoint(x: maxX, y: minY))
            }

            path.line(to: NSPoint(x: minX + bottomLeft, y: minY))
            if bottomLeft > 0 {
                path.curve(
                    to: NSPoint(x: minX, y: minY + bottomLeft),
                    controlPoint1: NSPoint(x: minX + bottomLeft * 0.45, y: minY),
                    controlPoint2: NSPoint(x: minX, y: minY + bottomLeft * 0.45)
                )
            } else {
                path.line(to: NSPoint(x: minX, y: minY))
            }
            path.close()
            return path
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
        case .glm: return NSColor(srgbRed: 0x7C/255, green: 0x3A/255, blue: 0xED/255, alpha: 1)
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
        case .zcode: return NSColor(srgbRed: 0x38/255, green: 0x66/255, blue: 0xFF/255, alpha: 1)
        case .opencode: return NSColor(srgbRed: 0x03/255, green: 0xB0/255, blue: 0x00/255, alpha: 1)
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

        // v0.3.0-PM-A-006：偏好设置窗口由 PreferencesWindowController 单例承载
        // （preferences/main 合并进 main 时该菜单项被手动 merge 漏掉，2026-07-05 恢复）。
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

    // 触发偏好窗口：由 PreferencesWindowController（NSWindow + NSHostingView）单例
    // 管理，不走 SwiftUI Settings scene —— 后者在 .accessory 菜单栏 app 下
    // 会被默默吞掉（见 PreferencesWindowController.swift 注释）。
    @objc private func openPreferences() {
        PreferencesWindowController.shared.show()
    }

    @objc private func quit() {
        coordinator.stop()
        NSApplication.shared.terminate(nil)
    }
}
