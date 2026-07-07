import SwiftUI

/// Quota Bar 偏好设置窗口主场景。
///
/// 视觉风格对齐 macOS 26 系统设置（参考 Vibe Island 复刻）：
/// - Sidebar 交给 `NavigationSplitView` + `List(.sidebar)` 原生组件绘制，
///   使用系统侧边栏材质、圆角、选中态和 Liquid Glass 效果
/// - 右侧 detail 自绘固定 toolbar-style title
/// - Detail 用 `SettingsSection` + `SettingsGroup` + `SettingsRow` 组件拼装
///
/// Sidebar 布局：默认组（无标题）→ 通用 / 模型；Quota Bar 组 → 激活 / 关于。
struct PreferencesScene: View {
    @State private var selection: PreferencesSection = .general
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        } detail: {
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 760, minHeight: 540)
        .onChange(of: columnVisibility) { _, _ in
            columnVisibility = .all
        }
        .toolbar(removing: .sidebarToggle)
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
        case .diagnostics: DiagnosticsSettingsView()
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
