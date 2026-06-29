import SwiftUI

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

// MARK: - SettingsGroup

/// macOS 26 系统设置风格的「圆角矩形容器」。
///
/// 视觉细节：
/// - 10pt 圆角矩形
/// - `.regularMaterial` 磨砂玻璃背景
/// - 0.5pt `.separator` 描边
/// - 内部 row 间用 `SettingsDivider` 隔开（不要在 row 上加 padding-bottom）
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
                .fill(.regularMaterial)
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
/// - 可选 subtitle（caption secondary）放在 label 下方
struct SettingsRow<Label: View, Trailing: View>: View {
    @ViewBuilder let label: Label
    let subtitle: String?
    @ViewBuilder let trailing: Trailing

    init(
        @ViewBuilder label: () -> Label,
        subtitle: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.label = label()
        self.subtitle = subtitle
        self.trailing = trailing()
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
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - SettingsDivider

/// Group 内 row 之间的分隔线。SwiftUI 默认 `Divider()` 会从边缘到边缘，
/// macOS 26 系统设置风格是从 row 左边距（16pt）开始到右边。
struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 16)
    }
}
