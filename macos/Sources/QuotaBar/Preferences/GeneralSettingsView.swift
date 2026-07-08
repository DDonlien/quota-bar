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
                    subtitle: "Quota Bar 会按此间隔自动刷新各 Provider 的额度数据。",
                    separatesSubtitle: true,
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
                    subtitle: "单个 Provider 单次拉取额度的最长等待时间；部分方案（如 Antigravity 的临时 CLI 会话）本身较慢，超时太短容易在系统稍有波动时被判定为失败。",
                    separatesSubtitle: true,
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
                    }
                )
            }
        }
    }

    // MARK: - Helpers

    private var launchAtLoginFooter: String {
        guard canRegisterLaunchItem else {
            return "应用尚未以 .app 形式安装（SwiftPM 直跑），登录启动暂不可用。请用 ./scripts/build-app.sh 打包 .app 后再启用。"
        }
        return store.preferences.launchAtLogin
            ? "已注册为登录项。可在「系统设置 → 通用 → 登录项」中管理。"
            : "启用后，登录 macOS 时会自动启动 Quota Bar。"
    }

    /// 当前进程是否是有效 .app（SwiftPM 直跑时 bundleIdentifier 为 swift-package-manager 占位）。
    private var canRegisterLaunchItem: Bool {
        guard let id = Bundle.main.bundleIdentifier, !id.isEmpty else { return false }
        return !id.hasPrefix("org.swift-package-manager")
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

    /// 注册 / 取消登录启动。SwiftPM 直跑时仅持久化偏好，不真正调用 SMAppService。
    private func applyLaunchAtLoginRegistration(_ enabled: Bool) {
        guard canRegisterLaunchItem else {
            NSLog("[Preferences] launchAtLogin 仅持久化偏好：当前进程不是有效 .app")
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
