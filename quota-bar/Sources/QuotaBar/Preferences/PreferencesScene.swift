import SwiftUI

/// Quota Bar 偏好设置窗口主场景。
///
/// 视觉风格对齐 macOS 26 系统设置（参考 Vibe Island 复刻）：
/// - Sidebar 列表彩色 SF Symbol icon + 选中行 system glass 高亮
/// - 顶部 toolbar-style title（NavigationSplitView 自动渲染）
/// - Detail 用 `SettingsSection` + `SettingsGroup` + `SettingsRow` 组件拼装
/// - 整个窗口用 `.regularMaterial` 玻璃背景（由 `PreferencesWindowController` 设置）
///
/// Sidebar 布局：默认组（无标题）→ 通用 / 模型；Quota Bar 组 → 激活 / 关于。
struct PreferencesScene: View {
    @State private var selection: PreferencesSection = .general

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 760, minHeight: 540)
        // 隐藏 NavigationSplitView 默认的 sidebar toggle 工具栏按钮（用户反馈
        // 「收纳按钮没必要」）。`.windowToolbar` 覆盖 macOS 顶部整条 toolbar，
        // 隐藏后 sidebar 仍可通过拖拽调整宽度。
        .toolbar(.hidden, for: .windowToolbar)
        // 注意：不再加 `.background(.regularMaterial)` —— glass 材质带阴影偏深，
        // 系统设置「软件更新」页是极浅灰（`.windowBackgroundColor`），
        // 整个窗口底色由 NSWindow `backgroundColor` 提供即可。
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selection) {
            // 默认组：放在 List 顶层，SwiftUI sidebar style 不渲染 header。
            ForEach(PreferencesSection.allCases.filter { $0.group == .default }) { section in
                sidebarRow(section)
            }

            // Quota Bar 组：用 `Section("title")` 渲染 macOS 26 风格的分组 header。
            Section {
                ForEach(PreferencesSection.allCases.filter { $0.group == .quotaBar }) { section in
                    sidebarRow(section)
                }
            } header: {
                Text(PreferencesGroup.quotaBar.title ?? "")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(nil)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Quota Bar")
    }

    private func sidebarRow(_ section: PreferencesSection) -> some View {
        Label {
            Text(section.title)
        } icon: {
            Image(systemName: section.icon)
                .foregroundStyle(section.tint)
        }
        .tag(section)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .general: GeneralSettingsView()
        case .models: ModelsSettingsView()
        case .activation: ActivationSettingsView()
        case .about: AboutSettingsView()
        }
    }
}

#Preview("Preferences - General") {
    PreferencesScene()
        .frame(width: 900, height: 600)
}

#Preview("Preferences - Models") {
    PreferencesScene()
        .frame(width: 900, height: 600)
}
