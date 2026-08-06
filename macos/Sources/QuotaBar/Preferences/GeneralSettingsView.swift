import SwiftUI
import ServiceManagement

/// 「通用」偏好页：刷新 / 数据来源 / 菜单栏 / 启动。
///
/// 视觉对齐 macOS 26 系统设置：
/// - 4 个 `SettingsSection`，每个 section 1 个 `SettingsGroup` 圆角矩形容器
/// - 所有 toggle / picker 用 `.controlSize(.small)`，跟系统设置按钮尺寸一致
/// - 字段全部绑定 `PreferencesStore.shared`，修改即时持久化到
///   `~/Library/Application Support/QuotaBar/preferences.json`
struct GeneralSettingsView: View {
    @State private var store = PreferencesStore.shared

    var body: some View {
        SettingsPage(.general) {
            VStack(alignment: .leading, spacing: 20) {
                refreshSection
                languageSection
                iconModeSection
                launchSection
            }
        }
    }

    // MARK: - Sections

    private var refreshSection: some View {
        SettingsSection("刷新") {
            SettingsGroup {
                SettingsRow(
                    label: { Text("刷新间隔") },
                    trailing: {
                        Picker("", selection: bindingRefreshInterval) {
                            ForEach(RefreshIntervalOption.allCases) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .fixedSize()
                        .controlSize(.small)
                    }
                )
                SettingsDivider()
                SettingsRow(
                    label: { Text("Provider 刷新超时") },
                    trailing: {
                        Picker("", selection: bindingProviderTimeout) {
                            ForEach(ProviderTimeoutOption.allCases) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .fixedSize()
                        .controlSize(.small)
                    }
                )
            }
        }
    }

    private var languageSection: some View {
        SettingsSection("语言") {
            SettingsGroup {
                SettingsRow(
                    label: { Text("界面语言") },
                    trailing: {
                        Picker("", selection: bindingLanguage) {
                            ForEach(LanguagePreference.allCases, id: \.self) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .fixedSize()
                        .controlSize(.small)
                    }
                )
            }
        }
    }

    private var iconModeSection: some View {
        SettingsSection("菜单栏") {
            SettingsGroup {
                SettingsRow(
                    label: { Text("图标模式") },
                    subtitle: iconModeFooter,
                    separatesSubtitle: true,
                    trailing: {
                        Picker("", selection: bindingIconMode) {
                            ForEach(IconModePreference.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .fixedSize()
                        .controlSize(.small)
                    }
                )
            }
        }
    }

    private var iconModeFooter: String {
        switch store.preferences.iconMode {
        case .combined:
            return "一个菜单栏图标汇总所有可用订阅。"
        case .perProvider:
            return "每个 Provider 一个独立菜单栏图标。"
        }
    }

    private var launchSection: some View {
        SettingsSection("启动") {
            SettingsGroup {
                SettingsRow(
                    label: { Text("登录时自动启动") },
                    subtitle: launchAtLoginFooter,
                    separatesSubtitle: true,
                    trailing: {
                        Toggle("", isOn: bindingLaunchAtLogin)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .disabled(!canEditLaunchItem)
                    }
                )
            }
        }
    }

    // MARK: - Helpers

    private var launchAtLoginFooter: String {
        guard canRegisterLaunchItem else {
            if canUseLaunchItemService, store.preferences.launchAtLogin {
                return "当前是开发构建，不能新增登录项。请先关闭此开关，再打开已安装的 /Applications/Quota Bar.app 重新启用。"
            }
            return "当前不是安装在 /Applications 的正式应用，登录启动暂不可用。请打开已安装的 Quota Bar.app 后再启用。"
        }
        return store.preferences.launchAtLogin
            ? "已注册为登录项。可在「系统设置 → 通用 → 登录项」中管理。"
            : "启用后，登录 macOS 时会自动启动 Quota Bar。"
    }

    /// 当前进程是否可以调用 SMAppService。开发构建仍可关闭曾经注册的旧登录项。
    private var canUseLaunchItemService: Bool {
        Bundle.main.bundleIdentifier == "com.taobe.quotabar"
            && Bundle.main.bundleURL.pathExtension.caseInsensitiveCompare("app") == .orderedSame
    }

    /// 只有正式安装位置才能新增登录项，避免 `_builds` 或 worktree 构建被 macOS 记住。
    private var canRegisterLaunchItem: Bool {
        canUseLaunchItemService
            && QuotaBarAppInstallation.isInstalledAppBundle(Bundle.main.bundleURL)
    }

    /// 已经从开发包注册过的旧登录项仍需要可以被关闭，避免修复后无法清理旧状态。
    private var canEditLaunchItem: Bool {
        canRegisterLaunchItem || (canUseLaunchItemService && store.preferences.launchAtLogin)
    }

    // MARK: - Bindings

    private var bindingRefreshInterval: Binding<RefreshIntervalOption> {
        Binding(
            get: { store.currentRefreshIntervalOption },
            set: { store.setRefreshInterval($0) }
        )
    }

    private var bindingProviderTimeout: Binding<ProviderTimeoutOption> {
        Binding(
            get: { store.currentProviderTimeoutOption },
            set: { store.setProviderTimeout($0) }
        )
    }

    private var bindingIconMode: Binding<IconModePreference> {
        Binding(
            get: { store.preferences.iconMode },
            set: { store.setIconMode($0) }
        )
    }

    private var bindingLanguage: Binding<LanguagePreference> {
        Binding(
            get: { store.preferences.language },
            set: { store.setLanguage($0) }
        )
    }

    private var bindingLaunchAtLogin: Binding<Bool> {
        Binding(
            get: { store.preferences.launchAtLogin },
            set: { newValue in
                applyLaunchAtLoginRegistration(newValue)
                store.setLaunchAtLogin(newValue)
            }
        )
    }

    // MARK: - Launch at login (SMAppService)

    /// 注册 / 取消登录启动。只有正式安装位置可以新增，开发包仅允许取消旧注册。
    private func applyLaunchAtLoginRegistration(_ enabled: Bool) {
        guard canUseLaunchItemService else {
            NSLog("[Preferences] launchAtLogin 仅持久化偏好：当前进程不是可识别的 Quota Bar.app")
            return
        }
        guard !enabled || canRegisterLaunchItem else {
            NSLog("[Preferences] 拒绝从开发构建注册 launchAtLogin：\(Bundle.main.bundleURL.path)")
            return
        }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("[Preferences] SMAppService.\(enabled ? "register" : "unregister") 失败: \(error.localizedDescription)")
        }
    }
}

#Preview("General") {
    GeneralSettingsView()
        .frame(width: 700, height: 540)
}
