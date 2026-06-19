import SwiftUI

// MARK: - 样式常量

enum MenuDashboardStyle {
    static let width: CGFloat = 292

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
    static let quotaTitleWidth: CGFloat = 56
    static let quotaRefreshWidth: CGFloat = 72
    static let percentWidth: CGFloat = 34

    // 字号
    static let summaryFontSize: CGFloat = 13
    static let planNameFontSize: CGFloat = 13
    static let planPriceFontSize: CGFloat = 13
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
    let state: DashboardState
    let isRefreshing: Bool
    let lastUpdatedText: String
    let needsFullDiskAccess: Bool

    init(
        state: DashboardState,
        isRefreshing: Bool,
        lastUpdatedText: String,
        needsFullDiskAccess: Bool = false
    ) {
        self.state = state
        self.isRefreshing = isRefreshing
        self.lastUpdatedText = lastUpdatedText
        self.needsFullDiskAccess = needsFullDiskAccess
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
    }

    @ViewBuilder
    private var content: some View {
        if state.isEmpty {
            EmptyStateView()
        } else if state.isInitialLoading {
            LoadingStateView(state: state)
        } else {
            ReadyStateView(state: state, isRefreshing: isRefreshing)
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
                PlanSection(snapshot: snapshot, isLoading: true)

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
                PlanSection(snapshot: snapshot, isLoading: false)

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

    var body: some View {
        VStack(alignment: .leading, spacing: MenuDashboardStyle.planSectionSpacing) {
            PlanHeader(snapshot: snapshot)

            switch snapshot.availability {
            case .available:
                if isLoading {
                    QuotaSkeleton()
                } else {
                    QuotaRows(snapshot: snapshot)
                }
            case .needsConfiguration(let reason):
                StatusRow(text: "待配置 · \(reason)")
            case .notInstalled:
                StatusRow(text: "未安装")
            case .fetchFailed(let reason):
                StatusRow(text: "获取失败 · \(reason)")
            }
        }
        .opacity(snapshot.isStale ? 0.7 : 1.0)
    }
}

// MARK: - 标题行

private struct PlanHeader: View {
    let snapshot: ProviderSnapshot

    var body: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(snapshot.statusColor)
                .frame(width: MenuDashboardStyle.statusDotSize, height: MenuDashboardStyle.statusDotSize)
                .frame(width: MenuDashboardStyle.leadingGlyphColumn, alignment: .center)

            Text(snapshot.displayName)
                .font(.system(size: MenuDashboardStyle.planNameFontSize, weight: MenuDashboardStyle.planNameWeight))
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.9)

            Spacer()

            Text(snapshot.monthlyPrice ?? "—")
                .font(.system(size: MenuDashboardStyle.planPriceFontSize, weight: .regular))
                .foregroundStyle(Palette.secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - 额度行

private struct QuotaRows: View {
    let snapshot: ProviderSnapshot

    /// 渲染前先按"最短订阅周期优先"排序；当 quota 有 scope 时按 scope 分组、
    /// 组内仍按 periodSeconds 排序。UI 层兜底排序，保证所有 provider 一致体验。
    private var sortedQuotas: [QuotaWindow] {
        snapshot.quotas.sorted { lhs, rhs in
            let ls = lhs.periodSeconds ?? .greatestFiniteMagnitude
            let rs = rhs.periodSeconds ?? .greatestFiniteMagnitude
            return ls < rs
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(sortedQuotas) { quota in
                QuotaRow(quota: quota, showScope: hasMultipleScopes)
            }
        }
        .padding(.leading, MenuDashboardStyle.leadingGlyphColumn)
    }

    /// 仅当该 provider 同时存在多个 scope 时显示 scope 标签，
    /// 否则隐藏避免视觉噪声。
    private var hasMultipleScopes: Bool {
        let scopes = Set(snapshot.quotas.compactMap { $0.scope })
        return scopes.count > 1
    }
}

private struct QuotaRow: View {
    let quota: QuotaWindow
    let showScope: Bool

    private var percentText: String {
        "\(Int((quota.remainingFraction * 100).rounded()))%"
    }

    private var titleWithScope: String {
        if showScope, let scope = quota.scope, !scope.isEmpty {
            return "\(quota.title) · \(scope)"
        }
        return quota.title
    }

    var body: some View {
        VStack(spacing: MenuDashboardStyle.quotaTitleToProgress) {
            HStack(alignment: .firstTextBaseline) {
                Text(titleWithScope)
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

            ProgressPill(value: quota.remainingFraction)
        }
        .padding(.top, MenuDashboardStyle.quotaRowTop)
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

// MARK: - 进度条

private struct ProgressPill: View {
    let value: Double

    private var clampedValue: Double {
        min(max(value, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Palette.track)

                Capsule()
                    .fill(Palette.blue)
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
