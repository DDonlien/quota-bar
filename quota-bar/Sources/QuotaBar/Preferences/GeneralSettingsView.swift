import SwiftUI
import ServiceManagement

/// 「通用」偏好页：刷新 / 数据来源 / 菜单栏 / 启动。
///
/// 字段全部绑定 `PreferencesStore.shared`，修改即时持久化到
/// `~/Library/Application Support/QuotaBar/preferences.json`。
struct GeneralSettingsView: View {
    @State private var store = PreferencesStore.shared

    var body: some View {
        Form {
            refreshSection
            browserSection
            iconModeSection
            launchSection
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(.regularMaterial)
        .navigationTitle("通用")
        .padding(.horizontal, 4)
    }

    // MARK: - Sections

    private var refreshSection: some View {
        Section {
            refreshIntervalRow
        } header: {
            Text("刷新")
        } footer: {
            Text("Quota Bar 会按此间隔自动刷新各 Provider 的额度数据；也随时可通过菜单「立即刷新」手动触发。")
        }
    }

    private var browserSection: some View {
        Section {
            Picker(selection: bindingBrowserSource) {
                ForEach(BrowserSourcePreference.allCases, id: \.self) { source in
                    Text(source.displayName).tag(source)
                }
            } label: {
                Text("Cookie 来源")
            }
            .pickerStyle(.menu)
        } header: {
            Text("数据来源")
        } footer: {
            Text("选择从哪个浏览器读取 Cookie 获取 dashboard 数据；自动模式按导入顺序尝试所有已登录浏览器。")
        }
    }

    private var iconModeSection: some View {
        Section {
            Picker(selection: bindingIconMode) {
                ForEach(IconModePreference.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            } label: {
                Text("图标模式")
            }
            .pickerStyle(.menu)
        } header: {
            Text("菜单栏")
        } footer: {
            Text("单图标汇总：当前默认行为，画 N 个 bar 汇总所有可用订阅。多图标分 Provider：每个 Provider 一个独立状态栏图标（预留）。")
        }
    }

    private var launchSection: some View {
        Section {
            Toggle(isOn: bindingLaunchAtLogin) {
                Text("登录时自动启动")
            }
        } header: {
            Text("启动")
        } footer: {
            Text(launchAtLoginFooter)
        }
    }

    // MARK: - Rows

    private var refreshIntervalRow: some View {
        HStack(spacing: 12) {
            Slider(value: bindingRefreshInterval, in: 60...3600, step: 60) {
                Text("刷新间隔")
            } minimumValueLabel: {
                Text("1 分")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            } maximumValueLabel: {
                Text("60 分")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text(refreshIntervalText)
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 56, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("刷新间隔")
        .accessibilityValue(refreshIntervalText)
    }

    private var refreshIntervalText: String {
        let minutes = max(1, Int((store.preferences.refreshIntervalSeconds / 60).rounded()))
        return "\(minutes) 分钟"
    }

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

    private var bindingRefreshInterval: Binding<TimeInterval> {
        Binding(
            get: { store.preferences.refreshIntervalSeconds },
            set: { store.setRefreshInterval($0) }
        )
    }

    private var bindingBrowserSource: Binding<BrowserSourcePreference> {
        Binding(
            get: { store.preferences.browserSource },
            set: { store.setBrowserSource($0) }
        )
    }

    private var bindingIconMode: Binding<IconModePreference> {
        Binding(
            get: { store.preferences.iconMode },
            set: { store.setIconMode($0) }
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
        .frame(width: 600, height: 500)
}