import SwiftUI

/// Quota Bar 偏好设置窗口主场景。
///
/// 在 `CodingPlanMenuApp` 通过 SwiftUI `Settings` scene 注册后：
/// - macOS 自动创建标准偏好窗口（`⌘,` 触发）
/// - 应用菜单自动出现「Quota Bar → 偏好设置…」项
/// - window 自动应用 macOS 26 Liquid Glass 材质
///
/// Sidebar 布局：默认组（无标题）→ 通用 / 模型；Quota Bar 组 → 激活 / 关于。
struct PreferencesScene: View {
    @State private var selection: PreferencesSection = .general

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            detailView
                .frame(minWidth: 540)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 720, minHeight: 480)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selection) {
            // 默认组：直接放在 List 顶层，不渲染 Section header
            ForEach(PreferencesSection.allCases.filter { $0.group == .default }) { section in
                sidebarRow(section)
            }

            // Quota Bar 组：带 Section header
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