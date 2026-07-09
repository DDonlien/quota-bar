import SwiftUI

private enum SettingsLayout {
    static let detailHorizontalInset: CGFloat = 20
    static let sectionSpacing: CGFloat = 20
    static let headerHeight: CGFloat = 58
    static let headerTopInset: CGFloat = 13
    static let headerContentHeight: CGFloat = 28
    static let contentTopInset: CGFloat = headerTopInset + headerContentHeight + sectionSpacing
}

// MARK: - SettingsPage

/// 偏好设置 detail 页通用外壳：固定顶部 toolbar 标题 + 可滚动 section 内容。
///
/// 顶部标题对齐 macOS 系统设置右侧 toolbar 行；标题固定在顶部，
/// 不参与右侧内容滚动。
struct SettingsPage<Content: View>: View {
    let section: PreferencesSection
    @ViewBuilder let content: Content

    init(_ section: PreferencesSection, @ViewBuilder content: () -> Content) {
        self.section = section
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                content
                    .padding(.top, SettingsLayout.contentTopInset)
                    .padding(.horizontal, SettingsLayout.detailHorizontalInset)
                    .padding(.bottom, 28)
            }

            SettingsPageHeader(section)
        }
        .navigationTitle(section.title)
        .toolbar(.hidden, for: .windowToolbar)
        .ignoresSafeArea(.container, edges: .top)
    }
}

private struct SettingsPageHeader: View {
    let section: PreferencesSection

    init(_ section: PreferencesSection) {
        self.section = section
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(section.tint.opacity(0.16))
                    Image(systemName: section.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(section.tint)
                }
                .frame(width: 28, height: 28)

                Text(section.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, SettingsLayout.detailHorizontalInset)
            .padding(.top, SettingsLayout.headerTopInset)

            Spacer(minLength: 0)
        }
        .frame(height: SettingsLayout.headerHeight, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            HeaderFadeMaterial()
        }
        .allowsHitTesting(false)
    }
}

private struct HeaderFadeMaterial: View {
    var body: some View {
        Rectangle()
            .fill(.bar)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.62),
                        .init(color: .black.opacity(0), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}

// MARK: - SettingsSection

/// macOS 26 系统设置风格的「section + 多个 group」容器。
///
/// 对应参考图中「系统」「展开」「显隐」等分区：
/// - 顶部 13pt semibold primary 标题
/// - 下方若干 `SettingsGroup`，垂直间距 8pt
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)
            content
        }
    }
}

// MARK: - SettingsIconLabel

/// 设置行里常用的 24pt 图标 + 文本标签。
struct SettingsIconLabel: View {
    let symbol: String
    let title: String
    let tint: Color

    init(_ title: String, symbol: String, tint: Color = .secondary) {
        self.title = title
        self.symbol = symbol
        self.tint = tint
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(tint.opacity(0.16))
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 24, height: 24)

            Text(title)
                .font(.system(size: 13))
        }
    }
}

// MARK: - SettingsGroup

/// macOS 26 系统设置风格的「圆角矩形容器」（软件更新页那种极浅灰卡牌）。
///
/// 视觉细节：
/// - 10pt 圆角矩形
/// - `.background.secondary` 极浅灰填充（**不是** `.regularMaterial` 玻璃：
///   glass 材质带阴影偏深；系统设置实际是几乎看不出玻璃的极浅灰）
/// - 0.5pt `.separator` 描边
/// - 内部 row 间用 `SettingsDivider` 隔开
struct SettingsGroup<Content: View>: View {
    @ViewBuilder let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.background.secondary)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.separator, lineWidth: 0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - SettingsRow

/// macOS 26 系统设置风格的「单行设置项」。
///
/// 结构：
/// - 左侧 label（system font 13pt regular primary）
/// - 右侧 trailing（toggle / picker / slider / value label）
/// - 可选 subtitle（caption secondary）放在 label 下方，贴近 macOS 系统设置列表行
struct SettingsRow<Label: View, Trailing: View>: View {
    @ViewBuilder let label: Label
    /// `Text` 而不是 `String`：部分行需要混合字体的 subtitle（比如一段说明文字
    /// 里嵌一小段等宽字体的技术性值，如 API Key 掩码），`Text` 可以用 `+` 拼接
    /// 不同样式的片段，纯 `String` 做不到（2026-07-08 用户反馈"API Key 配置"行
    /// 里字面量反引号没有渲染成等宽样式，见 `APIKeyConfigRow.statusText`）。
    let subtitle: Text?
    let subtitleLeading: CGFloat
    let separatesSubtitle: Bool
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    @ViewBuilder let trailing: Trailing

    init(
        @ViewBuilder label: () -> Label,
        subtitle: Text? = nil,
        subtitleLeading: CGFloat = 0,
        separatesSubtitle: Bool = false,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 9,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.label = label()
        self.subtitle = subtitle
        self.subtitleLeading = subtitleLeading
        self.separatesSubtitle = separatesSubtitle
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.trailing = trailing()
    }

    init(
        @ViewBuilder label: () -> Label,
        subtitle: String?,
        subtitleLeading: CGFloat = 0,
        separatesSubtitle: Bool = false,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 9,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.init(
            label: label,
            subtitle: subtitle.map(Text.init),
            subtitleLeading: subtitleLeading,
            separatesSubtitle: separatesSubtitle,
            horizontalPadding: horizontalPadding,
            verticalPadding: verticalPadding,
            trailing: trailing
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 12) {
                label
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                Spacer(minLength: 12)
                trailing
            }
            if let subtitle {
                if separatesSubtitle {
                    Divider()
                        .padding(.vertical, 5)
                }
                subtitle
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, subtitleLeading)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - SettingsDivider

/// Group 内 row 之间的分隔线。SwiftUI 默认 `Divider()` 会从边缘到边缘，
/// macOS 26 系统设置风格是从 row 左边距（16pt）开始到右边。
struct SettingsDivider: View {
    var leading: CGFloat = 16
    var trailing: CGFloat = 16

    var body: some View {
        Divider()
            .padding(.vertical, 2)
            .padding(.leading, leading)
            .padding(.trailing, trailing)
    }
}
