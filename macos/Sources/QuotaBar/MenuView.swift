import SwiftUI

// MARK: - 样式常量

enum MenuDashboardStyle {
    static let width: CGFloat = 340

    // 容器与外边距（不与任何元素共享）
    static let menuTopPadding: CGFloat = 0           // 1 自身 = 0
    static let menuBottomPadding: CGFloat = 0        // 14 自身 = 0
    static let horizontalPadding: CGFloat = 14

    // 顶部汇总（每月费用 / 可用订阅），三种 padding 各自独立
    static let summaryFirstRowTopPadding: CGFloat = 8    // 2 上 padding
    static let summaryRowSpacing: CGFloat = 6            // 2 下 padding
    static let summaryLastRowBottomPadding: CGFloat = 8  // 3 下 padding
    /// 汇总内两行之间的纵向间距（兼容既有代码引用）。
    static let summarySpacing: CGFloat = 2

    // 汇总下方的 Divider（4 号），不与 plan 之间的 Divider 共享
    static let summaryDividerBottom: CGFloat = 8

    // Plan 标题（5 号），与额度行不共享
    static let planSectionSpacing: CGFloat = 0
    /// 通用 section 间距，Divider 与区块之间的纵向距离。
    static let sectionSpacing: CGFloat = 8

    // 额度行（6 / 7 号），各 padding 独立
    static let quotaRowTop: CGFloat = 6                  // 6 上 padding
    static let quotaTitleToProgress: CGFloat = 2        // 6 下 padding
    static let progressHeight: CGFloat = 5              // 7 自身
    /// 多条 QuotaRow 之间的纵向间距。
    static let quotaRowsSpacing: CGFloat = 6
    /// 单条 QuotaRow 内 标题行 与 ProgressPill 的纵向间距。
    static let quotaRowSpacing: CGFloat = 2
    /// 状态/额度块底部的留白。
    static let contentBlockSpacing: CGFloat = 6

    // Plan 之间的 Divider（8 号），与汇总下方 Divider 独立
    static let planDividerTop: CGFloat = 8
    static let planDividerBottom: CGFloat = 8

    // 空状态布局（与汇总行间距独立）
    static let emptyStateSpacing: CGFloat = 6

    // 布局常量
    static let leadingGlyphColumn: CGFloat = 13
    static let statusDotSize: CGFloat = 6
    static let quotaTitleWidth: CGFloat = 120
    static let quotaRefreshWidth: CGFloat = 72
    static let percentWidth: CGFloat = 34

    // 字号
    static let summaryFontSize: CGFloat = 13
    static let planNameFontSize: CGFloat = 13
    static let planPriceFontSize: CGFloat = 13
    /// 计划头部「订阅/数据最后有效日期」标签的字号。
    /// 比价格小 2pt，让价格仍是右侧视觉锚点。
    static let planExpiresAtFontSize: CGFloat = 11
    /// 价格与左侧 expiresAt 标签之间的间距。
    static let planPriceTrailingGap: CGFloat = 6
    static let quotaFontSize: CGFloat = 11
    static let emptyStateTitleSize: CGFloat = 13
    static let emptyStateBodySize: CGFloat = 11
    static let permissionBannerTitleSize: CGFloat = 12
    static let permissionBannerBodySize: CGFloat = 11

    // 字重
    static let summaryWeight: Font.Weight = .medium
    static let planNameWeight: Font.Weight = .regular
    static let quotaTitleWeight: Font.Weight = .regular
}

// MARK: - 颜色 token

private enum Palette {
    static let text = Color.primary
    static let secondary = Color.secondary
    static let divider = Color.primary.opacity(0.12)
    static let track = Color.primary.opacity(0.08)
    static let trackFailed = Color.primary.opacity(0.05)
    static let blue = Color(hex: "#0A7CFF")
    static let muted = Color.primary.opacity(0.35)
    static let warning = Color(hex: "#FF9F0A")
    static let warningBackground = Color(hex: "#FF9F0A").opacity(0.12)
}

// MARK: - 入口视图

struct MenuView: View {
    /// 直接持有 coordinator，让 SwiftUI 自动订阅 `@Published` 变化。
    /// 菜单打开期间刷新循环更新 `coordinator.state` 时，NSHostingView 内的 SwiftUI 树
    /// 会原地重渲染，不需要重建 NSMenuItem / 避免 dropdown 必须开关才看到新数据。
    @ObservedObject var coordinator: RefreshCoordinator
    let onSaveKey: ((ProviderKind, String) -> Void)?
    let onHideKind: ((ProviderKind) -> Void)?
    @State private var preferencesRevision = 0

    private var state: DashboardState { coordinator.state }
    private var isRefreshing: Bool { coordinator.isRefreshing }
    private var lastUpdatedText: String { coordinator.lastUpdatedText }
    private var needsFullDiskAccess: Bool { coordinator.needsFullDiskAccess }

    init(
        coordinator: RefreshCoordinator,
        onSaveKey: ((ProviderKind, String) -> Void)? = nil,
        onHideKind: ((ProviderKind) -> Void)? = nil
    ) {
        self.coordinator = coordinator
        self.onSaveKey = onSaveKey
        self.onHideKind = onHideKind
    }

    var body: some View {
        VStack(spacing: 0) {
            if needsFullDiskAccess {
                PermissionBannerView()
            }
            content
        }
        .padding(.top, MenuDashboardStyle.menuTopPadding)
        .padding(.horizontal, MenuDashboardStyle.horizontalPadding)
        .padding(.bottom, MenuDashboardStyle.menuBottomPadding)
        .frame(width: MenuDashboardStyle.width)
        .background(Color.clear)
        .foregroundStyle(Palette.text)
        .fixedSize(horizontal: false, vertical: true)
        .id(preferencesRevision)
        .onReceive(NotificationCenter.default.publisher(for: .quotaPreferencesDidChange)) { _ in
            preferencesRevision &+= 1
        }
    }

    @ViewBuilder
    private var content: some View {
        if state.isEmpty {
            EmptyStateView()
        } else if state.isInitialLoading {
            LoadingStateView(state: state, onSaveKey: onSaveKey, onHideKind: onHideKind)
        } else {
            ReadyStateView(state: state, isRefreshing: isRefreshing, onSaveKey: onSaveKey, onHideKind: onHideKind)
        }
    }
}

// MARK: - 权限引导横幅

private struct PermissionBannerView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 13))
                .foregroundStyle(Palette.warning)
                .frame(width: 16, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text("浏览器数据需要授权")
                    .font(.system(size: MenuDashboardStyle.permissionBannerTitleSize, weight: .medium))
                    .foregroundStyle(Palette.text)
                Text("只有读取浏览器 Cookie 兜底时才需要 Full Disk Access。Codex 已优先使用本机 auth.json，不需要这项权限。")
                    .font(.system(size: MenuDashboardStyle.permissionBannerBodySize, weight: .regular))
                    .foregroundStyle(Palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    PrivacyAccessChecker.openFullDiskAccessSettings()
                } label: {
                    Text("打开系统设置")
                        .font(.system(size: MenuDashboardStyle.permissionBannerBodySize, weight: .medium))
                        .foregroundStyle(Palette.warning)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 2)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.warningBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(.top, 8)
    }
}

// MARK: - 空状态

private struct EmptyStateView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: MenuDashboardStyle.emptyStateSpacing) {
            Text("未发现已登录的 AI 服务")
                .font(.system(size: MenuDashboardStyle.emptyStateTitleSize, weight: MenuDashboardStyle.summaryWeight))
                .foregroundStyle(Palette.text)

            Text("在 Codex CLI、MiniMax 或 Kimi 等任一服务中完成登录后，重启 Quota Bar 即可在此查看订阅额度。")
                .font(.system(size: MenuDashboardStyle.emptyStateBodySize, weight: .regular))
                .foregroundStyle(Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 120, alignment: .center)
    }
}

// MARK: - 加载状态

private struct LoadingStateView: View {
    let state: DashboardState
    let onSaveKey: ((ProviderKind, String) -> Void)?
    let onHideKind: ((ProviderKind) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            SummaryView(
                costText: "—",
                availabilityText: "—/\(state.totalCount)",
                isRefreshing: true,
                hasStaleData: false
            )

            DividerLine()
                .padding(.bottom, MenuDashboardStyle.summaryDividerBottom)

            ForEach(Array(state.snapshots.enumerated()), id: \.element.id) { index, snapshot in
                DraggablePlanSection(
                    snapshot: snapshot,
                    index: index,
                    allSnapshots: state.snapshots,
                    isLoading: true,
                    onSaveKey: onSaveKey,
                    onHideKind: onHideKind
                )

                if index < state.snapshots.count - 1 {
                    DividerLine()
                        .padding(.top, MenuDashboardStyle.planDividerTop)
                        .padding(.bottom, MenuDashboardStyle.planDividerBottom)
                }
            }

            if !state.snapshots.isEmpty {
                DividerLine()
                    .padding(.top, MenuDashboardStyle.planDividerTop)
                    .padding(.bottom, MenuDashboardStyle.planDividerBottom)
            }
        }
    }
}

// MARK: - 正常状态

private struct ReadyStateView: View {
    let state: DashboardState
    let isRefreshing: Bool
    let onSaveKey: ((ProviderKind, String) -> Void)?
    let onHideKind: ((ProviderKind) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            SummaryView(
                costText: state.totalMonthlyCostText,
                availabilityText: state.availabilityText,
                isRefreshing: isRefreshing,
                hasStaleData: state.hasStaleData
            )

            DividerLine()
                .padding(.bottom, MenuDashboardStyle.summaryDividerBottom)

            ForEach(Array(state.snapshots.enumerated()), id: \.element.id) { index, snapshot in
                // isLoading 派生自 snapshot.availability：streaming refresh 中部分
                // snapshot 可能是 .loading（骨架），已完成的是真实数据。
                DraggablePlanSection(
                    snapshot: snapshot,
                    index: index,
                    allSnapshots: state.snapshots,
                    isLoading: snapshot.availability == .loading,
                    onSaveKey: onSaveKey,
                    onHideKind: onHideKind
                )

                if index < state.snapshots.count - 1 {
                    DividerLine()
                        .padding(.top, MenuDashboardStyle.planDividerTop)
                        .padding(.bottom, MenuDashboardStyle.planDividerBottom)
                }
            }

            if !state.snapshots.isEmpty {
                DividerLine()
                    .padding(.top, MenuDashboardStyle.planDividerTop)
                    .padding(.bottom, MenuDashboardStyle.planDividerBottom)
            }
        }
    }
}

// MARK: - 顶部汇总

private struct SummaryView: View {
    let costText: String
    let availabilityText: String
    let isRefreshing: Bool
    let hasStaleData: Bool

    var body: some View {
        VStack(spacing: MenuDashboardStyle.summaryRowSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text("每月费用")
                    .font(.system(size: MenuDashboardStyle.summaryFontSize, weight: MenuDashboardStyle.summaryWeight))
                    .foregroundStyle(Palette.text)

                Spacer()

                HStack(spacing: 4) {
                    if isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.5)
                            .frame(width: 8, height: 8)
                    }
                    Text(costText)
                        .font(.system(size: MenuDashboardStyle.summaryFontSize, weight: .regular))
                        .foregroundStyle(Palette.secondary)
                }
            }

            HStack(alignment: .firstTextBaseline) {
                Text("可用订阅")
                    .font(.system(size: MenuDashboardStyle.summaryFontSize, weight: MenuDashboardStyle.summaryWeight))
                    .foregroundStyle(Palette.text)

                Spacer()

                HStack(spacing: 4) {
                    if hasStaleData {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(Color(hex: "#FF9F0A"))
                    }
                    Text(availabilityText)
                        .font(.system(size: MenuDashboardStyle.summaryFontSize, weight: .regular))
                        .foregroundStyle(Palette.secondary)
                }
            }
        }
        .padding(.top, MenuDashboardStyle.summaryFirstRowTopPadding)
        .padding(.bottom, MenuDashboardStyle.summaryLastRowBottomPadding)
    }
}

// MARK: - Provider 区块

private struct PlanSection: View {
    let snapshot: ProviderSnapshot
    let isLoading: Bool
    let onSaveKey: ((ProviderKind, String) -> Void)?
    let onHideKind: ((ProviderKind) -> Void)?

    /// 该 provider 的订阅组（按用户订阅组排序）及其 quota list。
    private var subscriptionGroups: [(groupKey: String, items: [QuotaWindow])] {
        let groupOrder = PreferencesStore.shared.subscriptionGroupOrder(for: snapshot.kind)
        return snapshot.subscriptionGroups(customOrder: groupOrder)
    }

    private var hasMultipleSubscriptionGroups: Bool {
        subscriptionGroups.count > 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MenuDashboardStyle.planSectionSpacing) {
            PlanHeader(snapshot: snapshot, onHide: {
                onHideKind?(snapshot.kind)
            })

            switch snapshot.availability {
            case .loading:
                // 正在刷新中：provider 行已出现（PlanHeader），下方展示骨架占位等待真实数据。
                // 真实数据回填后这里会自动切到 .available / .needsConfiguration 分支。
                QuotaSkeleton()
            case .available:
                if isLoading {
                    QuotaSkeleton()
                } else if snapshot.quotas.isEmpty {
                    // 非授权流程只拿到了 provider 存在的信号（如 tier-only CLI 兜底层），
                    // 额度本身还没有——额度栏自己请求授权，不依赖 header 那边的按钮。
                    QuotaAuthPromptRow(kind: snapshot.kind)
                } else if hasMultipleSubscriptionGroups {
                    // 多订阅组 provider：子组作为拖拽边界存在，但不渲染额外标签行。
                    // 状态灯仍只在 provider header 上显示，组内多条 quota 作为整组移动。
                    ForEach(Array(subscriptionGroups.enumerated()), id: \.element.groupKey) { groupIndex, group in
                        SubscriptionGroupBlock(
                            snapshot: snapshot,
                            groupKey: group.groupKey,
                            quotas: group.items,
                            groupIndex: groupIndex,
                            allGroupKeys: subscriptionGroups.map(\.groupKey),
                            isLoading: false
                        )
                    }
                } else {
                    // 单订阅组 provider：保持现有 UI（一个 quota list，状态灯在 planHeader 上）
                    QuotaRows(snapshot: snapshot, quotas: subscriptionGroups.first?.items ?? [])
                }
            case .subscriptionExpired(let plan, let expiredAt):
                // v0.8.0：订阅已过期。不渲染任何 quota window（避免被 free 用户的"月额度"
                // primary_window 误导成有效付费额度），只展示一行灰标 hint，让用户知道
                // 1) 账号在 2) 上次付费档位 3) 到期日
                StatusRow(text: Self.expiredHint(plan: plan, expiredAt: expiredAt))
            case .notSubscribed:
                // 服务端已经明确告知"没有有效订阅"（不是获取失败、不是不清楚）：
                // 直接显示灰色定论文案，不拼接原始技术性 reason（那是给日志看的）。
                StatusRow(text: "未订阅或订阅已过期")
            case .needsConfiguration(let reason):
                if snapshot.kind == .minimax, let onSaveKey {
                    MiniMaxKeyInputField(
                        reason: reason,
                        onSave: { key in onSaveKey(snapshot.kind, key) }
                    )
                } else if snapshot.kind.webAuthorizationURL != nil && ProviderKind.webViewQuotaCapableKinds.contains(snapshot.kind) {
                    // 还不清楚这个 provider 到底有没有订阅（拿数据失败/凭证问题等，
                    // 不是服务端明确告知"未订阅"）：只给一个清晰的操作入口，不展示
                    // 原始技术性 reason 文本（例如内部拼接的多条错误信息），要么点开
                    // WebView 授权，要么等下一轮非授权流程再试。
                    //
                    // 同 `missingTierNeedsAuth`/`QuotaAuthPromptRow`：额外要求
                    // `webViewQuotaCapableKinds`，因为 Antigravity/Z Code 的
                    // WebView 登录窗口没有接入任何能解出额度的 dashboard 接口，
                    // 在这里展示这个按钮同样是个兑现不了的承诺。
                    InlineActionButton(
                        title: Self.webAuthorizationTitle(for: snapshot.kind),
                        action: { WebAuthorizationController.shared.openAuthorization(for: snapshot.kind) }
                    )
                    .frame(height: 16)
                    .padding(.top, MenuDashboardStyle.quotaRowTop)
                    .padding(.leading, MenuDashboardStyle.leadingGlyphColumn)
                } else {
                    // 没有 WebView 授权入口可给：只能展示原始 reason，没有更好的选择。
                    StatusRow(text: "待配置 · \(reason)")
                }
            case .notInstalled:
                StatusRow(text: "未安装")
            case .fetchFailed(let reason):
                StatusRow(text: "获取失败 · \(reason)")
            }
        }
        .opacity(snapshot.isStale ? 0.7 : 1.0)
    }

    /// v0.8.0：把 `.subscriptionExpired(plan, expiredAt)` 拼成一行用户可读的灰标 hint。
    /// 例：`订阅已过期 · Plus · 到期 2026/6/25`，`订阅已过期 · Plus`（无到期日），
    /// 或 `订阅已过期`（都没有）。
    private static func expiredHint(plan: String?, expiredAt: Date?) -> String {
        var parts: [String] = ["订阅已过期"]
        if let plan, !plan.isEmpty {
            parts.append(plan)
        }
        if let expiredAt {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.timeZone = TimeZone.current
            f.dateFormat = "yyyy/M/d"
            parts.append("到期 \(f.string(from: expiredAt))")
        }
        return parts.joined(separator: " · ")
    }

    private static func webAuthorizationTitle(for kind: ProviderKind) -> String {
        switch kind {
        case .antigravity:
            return "备用：打开 WebView 授权"
        default:
            return "打开 WebView 授权"
        }
    }
}

/// 订阅组 block（多订阅组 provider 下显示）。
/// 不渲染独立组标题；拖拽作用域是整个订阅组，而不是组内单条 quota。
private struct SubscriptionGroupBlock: View {
    let snapshot: ProviderSnapshot
    let groupKey: String
    let quotas: [QuotaWindow]
    let groupIndex: Int
    let allGroupKeys: [String]
    let isLoading: Bool

    var body: some View {
        VStack(spacing: 0) {
            ForEach(orderedQuotas) { quota in
                QuotaRow(quota: quota)
            }
        }
        .padding(.leading, MenuDashboardStyle.leadingGlyphColumn)
        .contentShape(Rectangle())
        .onDrag {
            let provider = NSItemProvider(object: Self.dragString(forGroup: groupKey, kind: snapshot.kind) as NSString)
            provider.suggestedName = "\(snapshot.kind.rawValue):\(groupKey)"
            return provider
        }
        .onDrop(
            of: [.text],
            delegate: SubscriptionGroupDropDelegate(
                targetGroupKey: groupKey,
                kind: snapshot.kind,
                allGroupKeys: allGroupKeys
            )
        )
    }

    /// 拖拽 payload：`<kind>:<groupKey>`，确保只与同 provider 内的订阅组 drop 配对。
    static func dragString(forGroup groupKey: String, kind: ProviderKind) -> String {
        "\(kind.rawValue):\(groupKey)"
    }

    /// 订阅组内按用户拖拽顺序排好的 quota list。
    private var orderedQuotas: [QuotaWindow] {
        let itemOrder = PreferencesStore.shared.quotaItemOrder(for: snapshot.kind)
        return quotas.sorted { a, b in
            let ai = itemOrder.firstIndex(of: a.stableKey) ?? Int.max
            let bi = itemOrder.firstIndex(of: b.stableKey) ?? Int.max
            if ai != bi { return ai < bi }
            return (a.periodSeconds ?? .greatestFiniteMagnitude) < (b.periodSeconds ?? .greatestFiniteMagnitude)
        }
    }
}

/// 订阅组级 DropDelegate：只接受同 provider 内的订阅组 drop。
private struct SubscriptionGroupDropDelegate: DropDelegate {
    let targetGroupKey: String
    let kind: ProviderKind
    let allGroupKeys: [String]

    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else { return false }

        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { (itemData, error) in
            let dragged = (itemData as? Data).flatMap { String(data: $0, encoding: .utf8) }
            DispatchQueue.main.async {
                guard let dragged,
                      let separatorIndex = dragged.firstIndex(of: ":") else { return }
                let draggedKindRaw = String(dragged[dragged.startIndex..<separatorIndex])
                let draggedGroupKey = String(dragged[dragged.index(after: separatorIndex)...])
                guard draggedKindRaw == kind.rawValue,
                      draggedGroupKey != targetGroupKey,
                      allGroupKeys.contains(draggedGroupKey),
                      allGroupKeys.contains(targetGroupKey) else { return }

                var order = PreferencesStore.shared.subscriptionGroupOrder(for: kind)
                if order.isEmpty {
                    order = allGroupKeys
                }
                let currentKeys = Set(allGroupKeys)
                order = order.filter { currentKeys.contains($0) }
                let missing = allGroupKeys.filter { !order.contains($0) }
                order.append(contentsOf: missing)

                guard let from = order.firstIndex(of: draggedGroupKey),
                      let to = order.firstIndex(of: targetGroupKey),
                      from != to
                else { return }

                order.moveElement(at: from, to: to)
                PreferencesStore.shared.setSubscriptionGroupOrder(order, for: kind)
            }
        }
        return true
    }
}

/// 支持 Provider 级拖拽排序的包装视图。
private struct DraggablePlanSection: View {
    let snapshot: ProviderSnapshot
    let index: Int
    let allSnapshots: [ProviderSnapshot]
    let isLoading: Bool
    let onSaveKey: ((ProviderKind, String) -> Void)?
    let onHideKind: ((ProviderKind) -> Void)?

    @State private var isDropTarget = false

    var body: some View {
        PlanSection(
            snapshot: snapshot,
            isLoading: isLoading,
            onSaveKey: onSaveKey,
            onHideKind: onHideKind
        )
        .contentShape(Rectangle())
        .onDrag {
            let provider = NSItemProvider(object: snapshot.kind.rawValue as NSString)
            provider.suggestedName = snapshot.kind.rawValue
            return provider
        }
        .onDrop(
            of: [.text],
            delegate: ProviderDropDelegate(
                targetKind: snapshot.kind,
                allKinds: allSnapshots.map(\.kind),
                index: index,
                isDropTarget: $isDropTarget
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isDropTarget ? Color.blue : Color.clear, lineWidth: 1)
                .padding(.horizontal, -4)
        )
        .opacity(isDropTarget ? 0.6 : 1.0)
    }
}

/// SwiftUI DropDelegate：接收拖拽的 Provider rawValue，重新排序并持久化。
private struct ProviderDropDelegate: DropDelegate {
    let targetKind: ProviderKind
    let allKinds: [ProviderKind]
    let index: Int
    @Binding var isDropTarget: Bool

    func dropEntered(info: DropInfo) {
        isDropTarget = true
    }

    func dropExited(info: DropInfo) {
        isDropTarget = false
    }

    func performDrop(info: DropInfo) -> Bool {
        isDropTarget = false
        guard let itemProvider = info.itemProviders(for: [.text]).first else { return false }

        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { (itemData, error) in
            // 先拷贝数据再进主线程，避免 Sendable 警告
            let draggedRawValue = (itemData as? Data).flatMap { String(data: $0, encoding: .utf8) }
            DispatchQueue.main.async {
                guard let draggedRawValue,
                      draggedRawValue != targetKind.rawValue,
                      let sourceIndex = allKinds.firstIndex(where: { $0.rawValue == draggedRawValue }),
                      sourceIndex != index
                else { return }

                var order = PreferencesStore.shared.providerOrder()
                if order.isEmpty {
                    order = allKinds.map(\.rawValue)
                }
                // 确保 order 包含所有当前 kind
                let currentKinds = Set(allKinds.map(\.rawValue))
                order = order.filter { currentKinds.contains($0) }
                let missing = allKinds.map(\.rawValue).filter { !order.contains($0) }
                order.append(contentsOf: missing)

                guard let from = order.firstIndex(of: draggedRawValue),
                      let to = order.firstIndex(of: targetKind.rawValue)
                else { return }

                order.moveElement(at: from, to: to)
                PreferencesStore.shared.setProviderOrder(order)
            }
        }
        return true
    }
}

// MARK: - MiniMax Key 输入字段

/// 在 dropdown 里显示 MiniMax API Key 状态，并提供「输入/修改」按钮。
/// 按钮点击后弹出 NSAlert（避免 NSMenu modal 循环导致 NSTextField 焦点丢失），
/// 用户在 alert 中输入 API Key 后保存到 ~/.mavis/config.yaml。
private struct MiniMaxKeyInputField: View {
    let reason: String
    let onSave: (String) -> Void

    @State private var keyInput: String = ""
    @State private var savedKeyState: MiniMaxConfigProvider.KeyInputState =
        MiniMaxConfigProvider.currentKeyState()
    @State private var lastError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            switch savedKeyState {
            case .missing:
                Text("待输入 Key · \(reason)")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            case .placeholder(let current):
                Text("待替换占位符 · 当前 `\(current)`")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Palette.warning)
                    .fixedSize(horizontal: false, vertical: true)
            case .configured(let masked):
                Text("Key 已配置 · \(masked)（重新输入会覆盖）")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 6) {
                APIKeyTextField(
                    text: $keyInput,
                    placeholder: "粘贴或输入 MiniMax API Key",
                    onSubmit: { save() }
                )

                Button(action: save) {
                    Text("保存")
                        .font(.system(size: 12, weight: .medium))
                }
                .controlSize(.regular)
                .disabled(keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let lastError {
                Text(lastError)
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "#FF453A"))
            }
        }
        .padding(.leading, MenuDashboardStyle.leadingGlyphColumn)
    }

    private func save() {
        let trimmed = keyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try MiniMaxConfigProvider.save(apiKey: trimmed)
            keyInput = ""
            savedKeyState = MiniMaxConfigProvider.currentKeyState()
            lastError = nil
            onSave(trimmed)
        } catch {
            lastError = error.localizedDescription
        }
    }
}

// MARK: - AppKit TextField（在 NSMenu 的 custom view 中保持焦点和输入）

import AppKit

/// 在 NSMenu 的 trackMouse 循环中保持焦点和输入能力。
///
/// 关键：acceptsFirstMouse = true，让 NSTextField 在窗口非 key 时也能接收 mouseDown。
/// mouseDown 中直接请求 firstResponder，不调用 super.mouseDown（避免 NSMenu 关闭）。
/// mouseUp 也不调用 super，并通过 Coordinator 的 NSEvent 拦截器阻止 NSMenu 收到 mouseUp。
private final class FocusTextField: NSTextField {
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    override func mouseUp(with event: NSEvent) {
    }

    override func mouseDragged(with event: NSEvent) {
    }
}

/// 用 AppKit NSTextField 包装成 SwiftUI 的 NSViewRepresentable，
/// 确保在 NSMenu 的 custom view 中能正常获取焦点和接收键盘输入。
///
/// 使用 `bezelStyle = .roundedBezel` + `controlSize = .regular`，外观接近原生 SwiftUI `.roundedBorder`。
/// 同时注册 `NSEvent` 本地监听器拦截 `Cmd+V`（解决 NSMenu 中 Paste 不可用）和 `mouseUp`（阻止菜单关闭）。
struct APIKeyTextField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let onSubmit: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let textField = FocusTextField()
        textField.placeholderString = placeholder
        textField.isEditable = true
        textField.isSelectable = true
        textField.isBezeled = true
        textField.bezelStyle = .roundedBezel
        textField.isBordered = true
        textField.controlSize = .regular
        textField.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textField.focusRingType = .default
        textField.usesSingleLineMode = true
        textField.lineBreakMode = .byTruncatingTail
        textField.drawsBackground = false
        textField.backgroundColor = NSColor.clear
        textField.textColor = NSColor.labelColor
        textField.delegate = context.coordinator
        textField.target = context.coordinator
        textField.action = #selector(Coordinator.submit)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.translatesAutoresizingMaskIntoConstraints = false

        // 右键菜单支持 Paste
        let menu = NSMenu()
        let pasteItem = NSMenuItem(title: "粘贴", action: #selector(Coordinator.pasteMenuItem), keyEquivalent: "")
        pasteItem.target = context.coordinator
        menu.addItem(pasteItem)
        textField.menu = menu

        context.coordinator.textField = textField
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: APIKeyTextField
        weak var textField: NSTextField?
        private var pasteMonitor: Any?
        private var mouseUpMonitor: Any?

        init(_ parent: APIKeyTextField) {
            self.parent = parent
            super.init()

            // 拦截 mouseUp，阻止 NSMenu 在点击输入框时关闭菜单
            mouseUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
                guard let self = self else { return event }
                let location = event.locationInWindow
                let field = self.textField
                Task { @MainActor in
                    guard let f = field else { return }
                    let point = f.convert(location, from: nil)
                    if f.hitTest(point) != nil {
                        // 点击在 textField 上，不返回事件（NSMenu 不关闭）
                    }
                }
                return event
            }

            // 拦截 Cmd+V 粘贴（NSMenu 的 modal 事件循环会阻断标准 Edit 菜单）
            pasteMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self = self else { return event }
                if event.modifierFlags.contains(.command) && event.keyCode == 9 {
                    // keyCode 9 = V key
                    let field = self.textField
                    Task { @MainActor in
                        if let f = field {
                            NSApp.sendAction(#selector(NSText.paste(_:)), to: f, from: nil)
                        }
                    }
                    return nil
                }
                return event
            }
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }

        @MainActor
        @objc func submit() {
            parent.onSubmit()
        }

        @MainActor
        @objc func pasteMenuItem() {
            if let field = textField {
                NSApp.sendAction(#selector(NSText.paste(_:)), to: field, from: nil)
            }
        }

        deinit {
            if let monitor = mouseUpMonitor {
                NSEvent.removeMonitor(monitor)
            }
            if let monitor = pasteMonitor {
                NSEvent.removeMonitor(monitor)
            }
        }
    }
}

// MARK: - 隐藏按钮（NSButton 包装，解决 NSMenu 中 SwiftUI Button 点击被拦截）

private struct HideButton: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton()
        if let image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "隐藏") {
            image.isTemplate = true
            button.image = image
        }
        button.imageScaling = .scaleProportionallyDown
        button.imagePosition = .imageOnly
        button.isBordered = false
        button.target = context.coordinator
        button.action = #selector(Coordinator.tapped)
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.setContentHuggingPriority(.defaultHigh, for: .vertical)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    func updateNSView(_ nsView: NSButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(action)
    }

    class Coordinator: NSObject {
        let action: () -> Void
        init(_ action: @escaping () -> Void) {
            self.action = action
        }
        @objc func tapped() {
            action()
        }
    }
}

// MARK: - 标题行

private struct PlanHeader: View {
    let snapshot: ProviderSnapshot
    let onHide: (() -> Void)?

    /// TierName：非授权流程也可能拿到（tier-only CLI 层等）；空字符串视为未获取。
    private var tierName: String? {
        guard let tier = snapshot.subscriptionTier?.trimmingCharacters(in: .whitespacesAndNewlines),
              !tier.isEmpty else { return nil }
        return tier
    }

    /// TierName 缺失但额度已经拿到时的假设（见需求方规格）：TierName 都拿不到，
    /// 订阅费用、到期日、订阅周期理应也一并拿不到——用一个授权引导覆盖整个右侧，
    /// 不必再分别判断价格/日期。额度本身缺失时由额度栏自己的按钮请求授权，这里不重复。
    ///
    /// 除了 `webAuthorizationURL != nil`，还必须确认这个 provider 真的注册了能解出
    /// 档位的 WebView 会话策略（`ProviderKind.webViewQuotaCapableKinds`）——不然
    /// 对 Antigravity/Z Code 这种只用 WebView 登录窗口抓订阅到期日、完全没有档位
    /// 来源的 provider，会展示一个登录了也没用的虚假授权引导（2026-07-08 用户实测
    /// 反馈）。
    private var missingTierNeedsAuth: Bool {
        snapshot.availability == .available
            && tierName == nil
            && !snapshot.quotas.isEmpty
            && snapshot.kind.webAuthorizationURL != nil
            && ProviderKind.webViewQuotaCapableKinds.contains(snapshot.kind)
    }

    /// 触发「显示到期日」的前置条件：必须有到期日、且处于已配置可用状态。
    /// 订阅费用是否存在是独立的一条轴线，不再作为日期显示的前置条件——
    /// 拿到日期但没拿到价格（或反之）都应该各自独立展示/隐藏。
    private var subscriptionExpiresDate: Date? {
        guard snapshot.availability == .available,
              let date = snapshot.subscriptionExpiresAt else { return nil }
        return date
    }

    /// 订阅/数据最后有效日期展示文案：`YYYY/M/D`（无前导零，例如 "2026/6/25"）。
    /// 语义见 `ProviderSnapshot.subscriptionExpiresAt`。
    private var expiresAtText: String? {
        subscriptionExpiresDate.map { Self.expiresAtFormatter.string(from: $0) }
    }

    /// 订阅/数据最后有效日期的精确时间（tooltip 用），格式 `yyyy-MM-dd HH:mm:ss zzz`
    /// （本地时区，例如 `2026-06-25 22:00:00 GMT+8`）。比 `yyyy/M/d` 多出时、分、秒和
    /// 时区信息，避免「0:00 还是 12:00 重置」之类的歧义（v0.6.0-UI-A-001）。
    private var preciseExpiresAtText: String? {
        subscriptionExpiresDate.map { Self.preciseExpiresAtFormatter.string(from: $0) }
    }

    private static let expiresAtFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy/M/d"
        return f
    }()

    private static let preciseExpiresAtFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        return f
    }()

    /// 有 TierName、有额度，但没有订阅到期日、且该 provider 的日期依赖 headless 订阅页
    /// （Codex / MiniMax / Claude 等）时，提供 WebView 授权引导入口。
    /// Kimi 等日期直接来自本地 API 的 provider 不显示（拿不到就是真没有）。
    private var canOfferWebAuthorizationForDate: Bool {
        snapshot.availability == .available
            && tierName != nil
            && !snapshot.quotas.isEmpty
            && snapshot.subscriptionExpiresAt == nil
            && snapshot.kind.webAuthorizationURL != nil
            && SubscriptionExpirySources.sources(for: snapshot.kind).contains { $0.kind == .headlessDOM }
    }

    private static let authPromptText = "打开 WebView 授权"

    /// 「隐藏」按钮只在这个 provider 还没拿到真实额度数据时提供——跟在偏好设置
    /// 「模型」页把开关关掉是完全同一个动作（见 `RefreshCoordinator.hide(kind:)`），
    /// 持久化后不会再实际发起这个 provider 的任何请求，不是只在 dropdown 里视觉隐藏。
    /// 已经有真实额度的 provider 不提供这个按钮——那种情况下没有"我不用这个"的诉求，
    /// 误触的代价也更高。
    private var canHide: Bool {
        switch snapshot.availability {
        case .needsConfiguration, .notSubscribed, .subscriptionExpired:
            return true
        case .available:
            return snapshot.quotas.isEmpty
        case .loading, .notInstalled, .fetchFailed:
            return false
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(snapshot.statusColor(itemOrder: PreferencesStore.shared.subscriptionGroupOrder(for: snapshot.kind)))
                .frame(width: MenuDashboardStyle.statusDotSize, height: MenuDashboardStyle.statusDotSize)
                .frame(width: MenuDashboardStyle.leadingGlyphColumn, alignment: .center)

            HStack(spacing: 0) {
                Text(snapshot.kind.displayName)
                    .font(.system(size: MenuDashboardStyle.planNameFontSize, weight: MenuDashboardStyle.planNameWeight))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                if let tierName {
                    Text(" · \(tierName)")
                        .font(.system(size: MenuDashboardStyle.planNameFontSize, weight: .regular))
                        .foregroundStyle(Palette.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }
            }

            Spacer()

            if missingTierNeedsAuth {
                // TierName 都没拿到：按规格假设价格/到期日/周期也一并拿不到，
                // 用一个授权引导覆盖整个右侧，不再分别判断。
                Text(Self.authPromptText)
                    .font(.system(size: MenuDashboardStyle.planExpiresAtFontSize, weight: .regular))
                    .foregroundStyle(Palette.secondary)
                    .underline()
                    .lineLimit(1)
                    .onTapGesture {
                        WebAuthorizationController.shared.openAuthorization(for: snapshot.kind)
                    }
                    .help("在 App 内登录 \(snapshot.kind.displayName) 网页一次，后续自动获取档位、价格与到期日")
            } else {
                HStack(spacing: MenuDashboardStyle.planPriceTrailingGap) {
                    if let expiresAtText {
                        // 订阅/数据最后有效日期；灰色 11pt 视觉上比 13pt 价格次要，
                        // 与右侧价格共享 secondary 灰系，让「日期 + 价格」形成一组信息。
                        // UI-A-001：hover 显示精确到秒的本地时区时间。
                        Text(expiresAtText)
                            .font(.system(size: MenuDashboardStyle.planExpiresAtFontSize, weight: .regular))
                            .foregroundStyle(Palette.secondary)
                            .lineLimit(1)
                            .monospacedDigit()
                            .help("最后有效日期：\(preciseExpiresAtText ?? expiresAtText)")
                    } else if canOfferWebAuthorizationForDate {
                        // 有 TierName、有额度，但拿不到订阅到期日，且该 provider 支持
                        // WebView 授权：提供与日期同样式的可点击引导（一次授权后
                        // headless 永久静默补日期）。
                        Text(Self.authPromptText)
                            .font(.system(size: MenuDashboardStyle.planExpiresAtFontSize, weight: .regular))
                            .foregroundStyle(Palette.secondary)
                            .underline()
                            .lineLimit(1)
                            .onTapGesture {
                                WebAuthorizationController.shared.openAuthorization(for: snapshot.kind)
                            }
                            .help("在 App 内登录 \(snapshot.kind.displayName) 网页一次，后续自动获取订阅到期日")
                    }
                    // 没拿到费用（不管是真没有——如 API pay-as-you-go——还是暂未获取）
                    // 就整组不显示：不渲染货币符号、订阅费用、订阅周期。
                    if let price = snapshot.monthlyPrice {
                        Text(price)
                            .font(.system(size: MenuDashboardStyle.planPriceFontSize, weight: .regular))
                            .foregroundStyle(Palette.secondary)
                            .lineLimit(1)
                    }
                }
            }

            if canHide {
                HideButton(action: {
                    onHide?()
                })
                .frame(width: 16, height: 16)
                .padding(.leading, 6)
                .help("隐藏此订阅（等同于在偏好设置「模型」页关闭）")
            }
        }
    }
}

/// 额度栏目：非授权流程拿不到额度时的引导行（蓝色、可点击）。
/// 与 header 里 tier/date 缺失时的灰色引导视觉区分——这里是"额度完全没有"，
/// 优先级更高，用 accent 蓝色强调。
///
/// 下划线规则统一：灰色引导（header 里那两处）都带下划线，蓝色引导（这里）
/// 都不带——颜色本身已经足够表明"可点击"，蓝色 + 下划线是过度强调。
private struct QuotaAuthPromptRow: View {
    let kind: ProviderKind

    /// 同 `PlanHeader.missingTierNeedsAuth`：只有真的注册了 WebView 会话额度策略的
    /// provider 才展示可点击的授权引导，否则会承诺一个登录了也拿不到额度的假入口
    /// （2026-07-08 用户实测 Antigravity 反馈）。
    private var canOfferWebAuthorization: Bool {
        kind.webAuthorizationURL != nil && ProviderKind.webViewQuotaCapableKinds.contains(kind)
    }

    var body: some View {
        Group {
            if canOfferWebAuthorization {
                Text("打开 WebView 授权")
                    .font(.system(size: MenuDashboardStyle.quotaFontSize, weight: .medium))
                    .foregroundStyle(Palette.blue)
                    .onTapGesture {
                        WebAuthorizationController.shared.openAuthorization(for: kind)
                    }
            } else {
                Text("暂无额度数据")
                    .font(.system(size: MenuDashboardStyle.quotaFontSize, weight: .regular))
                    .foregroundStyle(Palette.secondary)
            }
        }
        .padding(.top, MenuDashboardStyle.quotaRowTop)
        .padding(.leading, MenuDashboardStyle.leadingGlyphColumn)
    }
}

// MARK: - 额度行

private struct QuotaRows: View {
    let snapshot: ProviderSnapshot
    let quotas: [QuotaWindow]

    /// 按用户自定义顺序排列后的 quotas。
    private var orderedQuotas: [QuotaWindow] {
        let customOrder = PreferencesStore.shared.quotaItemOrder(for: snapshot.kind)
        return quotas.sorted { a, b in
            let ai = customOrder.firstIndex(of: a.stableKey) ?? Int.max
            let bi = customOrder.firstIndex(of: b.stableKey) ?? Int.max
            if ai != bi { return ai < bi }
            return (a.periodSeconds ?? .greatestFiniteMagnitude) < (b.periodSeconds ?? .greatestFiniteMagnitude)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(orderedQuotas) { quota in
                QuotaRow(quota: quota)
            }
        }
        .padding(.leading, MenuDashboardStyle.leadingGlyphColumn)
    }
}

/// 支持拖拽排序的单条额度对象视图。
///
/// `scopedGroupKey`：
/// - `nil` → 单订阅组 provider，可在整个 provider 内拖拽 quota；
/// - 非 nil → 多订阅组 provider，拖拽只在该订阅组内有效（避免跨组错位）。
private struct DraggableQuotaRow: View {
    let snapshot: ProviderSnapshot
    let quota: QuotaWindow
    let allQuotas: [QuotaWindow]
    let index: Int
    let scopedGroupKey: String?

    @State private var isDropTarget = false

    var body: some View {
        QuotaRow(quota: quota)
            .contentShape(Rectangle())
            .onDrag {
                // 多订阅组 provider：payload 包含 groupKey 防止跨组 drop；单订阅组沿用原 stableKey
                let payload: String
                if let groupKey = scopedGroupKey {
                    payload = "\(snapshot.kind.rawValue):\(groupKey):\(quota.stableKey)"
                } else {
                    payload = quota.stableKey
                }
                let provider = NSItemProvider(object: payload as NSString)
                provider.suggestedName = quota.stableKey
                return provider
            }
            .onDrop(
                of: [.text],
                delegate: QuotaItemDropDelegate(
                    snapshot: snapshot,
                    quota: quota,
                    allQuotas: allQuotas,
                    index: index,
                    scopedGroupKey: scopedGroupKey,
                    isDropTarget: $isDropTarget
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isDropTarget ? Color.blue : Color.clear, lineWidth: 1)
                    .padding(.horizontal, -4)
            )
            .opacity(isDropTarget ? 0.6 : 1.0)
    }
}

private struct QuotaRow: View {
    let quota: QuotaWindow

    private var percentText: String {
        "\(Int((quota.remainingFraction * 100).rounded()))%"
    }

    private var displayTitle: String {
        quota.displayTitle
    }

    var body: some View {
        VStack(spacing: MenuDashboardStyle.quotaTitleToProgress) {
            HStack(alignment: .firstTextBaseline) {
                Text(displayTitle)
                    .font(.system(size: MenuDashboardStyle.quotaFontSize, weight: MenuDashboardStyle.quotaTitleWeight))
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .frame(width: MenuDashboardStyle.quotaTitleWidth, alignment: .leading)

                Spacer(minLength: 6)

                Text(quota.refreshDescription)
                    .font(.system(size: MenuDashboardStyle.quotaFontSize, weight: .regular))
                    .foregroundStyle(Palette.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)
                    .frame(width: MenuDashboardStyle.quotaRefreshWidth, alignment: .trailing)

                Text(percentText)
                    .font(.system(size: MenuDashboardStyle.quotaFontSize, weight: .regular))
                    .foregroundStyle(Palette.secondary)
                    .lineLimit(1)
                    .monospacedDigit()
                    .frame(width: MenuDashboardStyle.percentWidth, alignment: .trailing)
            }

            ProgressPill(value: quota.remainingFraction, tint: Self.healthColor(for: quota.remainingFraction))
        }
        .padding(.top, MenuDashboardStyle.quotaRowTop)
    }

    private static func healthColor(for remainingFraction: Double) -> Color {
        remainingFraction <= 0.3 ? Palette.warning : Color.blue
    }
}

/// SwiftUI DropDelegate：接收拖拽的额度对象 stableKey，重新排序并持久化。
///
/// `scopedGroupKey`：
/// - `nil` → 单订阅组 provider，可在整个 provider 内拖拽 quota；
/// - 非 nil → 多订阅组 provider，drop 仅在同 subscription group 内有效（payload 形如
///   `<kind>:<groupKey>:<stableKey>`，跨组 drop 会被忽略）。
private struct QuotaItemDropDelegate: DropDelegate {
    let snapshot: ProviderSnapshot
    let quota: QuotaWindow
    let allQuotas: [QuotaWindow]
    let index: Int
    let scopedGroupKey: String?
    @Binding var isDropTarget: Bool

    func dropEntered(info: DropInfo) {
        isDropTarget = true
    }

    func dropExited(info: DropInfo) {
        isDropTarget = false
    }

    func performDrop(info: DropInfo) -> Bool {
        isDropTarget = false
        guard let itemProvider = info.itemProviders(for: [.text]).first else { return false }

        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { (itemData, error) in
            // 先拷贝数据再进主线程，避免 Sendable 警告
            let dragged = (itemData as? Data).flatMap { String(data: $0, encoding: .utf8) }
            DispatchQueue.main.async {
                // 多订阅组 provider：payload = "<kind>:<groupKey>:<stableKey>"，跨组 drop 忽略
                if let scoped = scopedGroupKey {
                    guard let dragged,
                          let parsed = Self.parseScopedPayload(dragged, kind: snapshot.kind),
                          parsed.groupKey == scoped,
                          parsed.stableKey != quota.stableKey
                    else { return }
                } else {
                    // 单订阅组：payload 直接是 stableKey
                    guard let dragged,
                          dragged != quota.stableKey
                    else { return }
                }

                guard let dragged = dragged,
                      let stableKey = (scopedGroupKey != nil
                                       ? Self.parseScopedPayload(dragged, kind: snapshot.kind)?.stableKey
                                       : dragged),
                      let sourceIndex = allQuotas.firstIndex(where: { $0.stableKey == stableKey }),
                      sourceIndex != index
                else { return }

                var order = PreferencesStore.shared.quotaItemOrder(for: snapshot.kind)
                if order.isEmpty {
                    order = allQuotas.map(\.stableKey)
                }
                // 确保 order 包含所有当前 key
                let currentKeys = Set(allQuotas.map(\.stableKey))
                order = order.filter { currentKeys.contains($0) }
                let missing = allQuotas.map(\.stableKey).filter { !order.contains($0) }
                order.append(contentsOf: missing)

                guard let from = order.firstIndex(of: stableKey),
                      let to = order.firstIndex(of: quota.stableKey)
                else { return }

                order.moveElement(at: from, to: to)
                PreferencesStore.shared.setQuotaItemOrder(order, for: snapshot.kind)
            }
        }
        return true
    }

    private static func parseScopedPayload(_ payload: String, kind: ProviderKind) -> (groupKey: String, stableKey: String)? {
        // "<kind>:<groupKey>:<stableKey>"
        let parts = payload.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0] == kind.rawValue else { return nil }
        return (String(parts[1]), String(parts[2]))
    }
}

private extension Array {
    mutating func moveElement(at fromIndex: Int, to toIndex: Int) {
        let element = remove(at: fromIndex)
        insert(element, at: toIndex)
    }
}

// MARK: - 加载骨架

private struct QuotaSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            SkeletonRow()
            SkeletonRow()
        }
        .padding(.leading, MenuDashboardStyle.leadingGlyphColumn)
    }
}

private struct SkeletonRow: View {
    var body: some View {
        VStack(spacing: MenuDashboardStyle.quotaTitleToProgress) {
            HStack(alignment: .firstTextBaseline) {
                Text("  ")
                    .font(.system(size: MenuDashboardStyle.quotaFontSize))
                    .frame(width: MenuDashboardStyle.quotaTitleWidth, alignment: .leading)
                Spacer()
            }
            ProgressPill(value: 0)
        }
        .padding(.top, MenuDashboardStyle.quotaRowTop)
    }
}

// MARK: - 状态行

private struct StatusRow: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: MenuDashboardStyle.quotaFontSize, weight: .regular))
            .foregroundStyle(Palette.secondary)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .padding(.top, MenuDashboardStyle.quotaRowTop)
            .padding(.leading, MenuDashboardStyle.leadingGlyphColumn)
    }
}

private struct InlineActionButton: NSViewRepresentable {
    let title: String
    let action: () -> Void

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(title: title, target: context.coordinator, action: #selector(Coordinator.tapped))
        button.isBordered = false
        button.bezelStyle = .inline
        button.alignment = .left
        button.font = NSFont.systemFont(ofSize: MenuDashboardStyle.quotaFontSize, weight: .medium)
        button.contentTintColor = NSColor.controlAccentColor
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    func updateNSView(_ nsView: NSButton, context: Context) {
        nsView.title = title
        context.coordinator.action = action
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    final class Coordinator: NSObject {
        var action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func tapped() {
            action()
        }
    }
}

// MARK: - 进度条

private struct ProgressPill: View {
    let value: Double
    var tint: Color = Palette.blue

    private var clampedValue: Double {
        min(max(value, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Palette.track)

                Capsule()
                    .fill(tint)
                    .frame(width: proxy.size.width * clampedValue)
            }
        }
        .frame(height: MenuDashboardStyle.progressHeight)
    }
}

// MARK: - 分割线

private struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(Palette.divider)
            .frame(height: 1)
    }
}
