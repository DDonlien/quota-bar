import AppKit
import SwiftUI

/// 「关于」偏好页：应用名 / 版本 / 检查更新 / 重置偏好。
///
/// 视觉对齐 macOS 26 系统设置：
/// - 不展示额外 section 标题，保持紧凑系统列表。
struct AboutSettingsView: View {
    @State private var store = PreferencesStore.shared
    @ObservedObject private var updateChecker = UpdateChecker.shared
    @State private var showResetConfirmation = false

    var body: some View {
        SettingsPage(.about) {
            VStack(alignment: .leading, spacing: 20) {
                appInfoGroup
                updateGroup
                resetSection
            }
        }
        .onAppear {
            // v0.11.0-FE-A-005：打开关于页时后台触发一次（5min 内不重复请求）。
            updateChecker.check(userInitiated: false)
        }
        .confirmationDialog(
            "确定要重置所有偏好设置吗？",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("重置偏好", role: .destructive) {
                store.resetToDefaults()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("所有 Provider 开关、刷新间隔、排序等偏好会被清空。关闭 Quota Bar 后下次启动生效。")
        }
    }

    // MARK: - Sections

    private var appInfoGroup: some View {
        SettingsGroup {
            SettingsRow(
                label: {
                    HStack(spacing: 12) {
                        Group {
                            if let icon = appIconImage {
                                Image(nsImage: icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } else {
                                Image(systemName: "chart.bar.doc.horizontal")
                                    .font(.system(size: 28, weight: .regular))
                                    .foregroundStyle(.tint)
                            }
                        }
                        .frame(width: 40, height: 40)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(appName)
                                .font(.system(size: 13, weight: .semibold))
                            Text("版本 \(appVersion) · Build \(appBuild)")
                                .font(.system(size: 11).monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            )
            SettingsDivider()
            SettingsRow(
                label: { Text("开发者") },
                trailing: { Text("Taobe").foregroundStyle(.secondary) }
            )
        }
    }

    private var updateGroup: some View {
        SettingsGroup {
            SettingsRow(
                label: {
                    HStack(spacing: 10) {
                        Button {
                            updateChecker.check(userInitiated: true)
                        } label: {
                            SettingsIconLabel("检查更新", symbol: "arrow.triangle.2.circlepath", tint: .blue)
                        }
                        .buttonStyle(.plain)
                        .disabled(updateBusy)
                        if case .checking = updateChecker.state {
                            ProgressView().controlSize(.small)
                        }
                    }
                },
                verticalPadding: 8
            )
            if hasUpdateStatus {
                SettingsDivider()
                SettingsRow(
                    label: { updateStatusView },
                    verticalPadding: 8
                )
            }
            if !store.preferences.ignoredVersions.isEmpty {
                SettingsDivider()
                SettingsRow(
                    label: {
                        Button("重置已忽略的版本（\(store.preferences.ignoredVersions.count)）") {
                            updateChecker.resetIgnoredVersions()
                        }
                        .controlSize(.small)
                    },
                    verticalPadding: 8
                )
            }
        }
    }

    private var updateBusy: Bool {
        switch updateChecker.state {
        case .checking, .downloading, .verifying, .installing: return true
        default: return false
        }
    }

    private var hasUpdateStatus: Bool {
        switch updateChecker.state {
        case .idle, .checking: return false
        default: return true
        }
    }

    /// 检查更新按钮下方的状态区（v0.11.0-UI-A-000/001）。
    @ViewBuilder
    private var updateStatusView: some View {
        switch updateChecker.state {
        case .idle, .checking:
            EmptyView()
        case .upToDate(let version):
            Text("已是最新版本 \(version == "1.0" ? "（nightly \(appBuild)）" : "v\(version)")")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        case .error(let message):
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.orange)
        case .updateAvailable(let candidate):
            VStack(alignment: .leading, spacing: 6) {
                Text("\(candidate.tag) 已发布")
                    .font(.system(size: 12, weight: .semibold))
                if !candidate.releaseNotes.isEmpty {
                    Text(candidate.releaseNotes)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(6)
                }
                HStack(spacing: 12) {
                    Button("立即下载并安装") { updateChecker.downloadAndInstall() }
                        .controlSize(.small)
                    Button("查看 GitHub Release") { NSWorkspace.shared.open(candidate.releaseURL) }
                        .controlSize(.small)
                    Button("稍后提醒") { updateChecker.ignoreCurrentUpdate() }
                        .controlSize(.small)
                }
            }
        case .downloading(let progress):
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: progress) {
                    Text("正在下载更新… \(Int(progress * 100))%")
                        .font(.system(size: 11))
                }
                Button("取消") { updateChecker.cancelDownload() }
                    .controlSize(.small)
            }
        case .verifying:
            Text("正在校验更新包…")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        case .downloaded(let candidate, _):
            VStack(alignment: .leading, spacing: 6) {
                Text("\(candidate.tag) 已下载完成")
                    .font(.system(size: 12, weight: .semibold))
                HStack(spacing: 12) {
                    Button("立即重启并安装") { updateChecker.installDownloadedUpdate() }
                        .controlSize(.small)
                    Button("稍后") { updateChecker.ignoreCurrentUpdate() }
                        .controlSize(.small)
                }
                Text("macOS 权限设置（Accessibility 等）更新后通常会保留；正式形式化保障将在 v0.12.0 升级签名后落地。")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        case .installing:
            Text("正在安装更新，应用将自动重启…")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private var resetSection: some View {
        SettingsGroup {
            SettingsRow(
                label: {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        SettingsIconLabel("重置偏好设置…", symbol: "arrow.uturn.backward", tint: .red)
                    }
                    .buttonStyle(.plain)
                },
                subtitle: "重置后所有 Provider 开关、刷新间隔、排序偏好都会清空，回到默认状态。",
                subtitleLeading: 36,
                separatesSubtitle: true,
                verticalPadding: 8
            )
        }
    }

    // MARK: - Helpers

    private var appName: String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
            ?? Bundle.main.infoDictionary?["CFBundleName"] as? String
            ?? "Quota Bar"
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["QBDisplayBuild"] as? String
            ?? Bundle.main.infoDictionary?["CFBundleVersion"] as? String
            ?? "dev"
    }

    /// 应用图标。SwiftPM 直跑时不存在 AppIcon，取不到就 fallback 到 SF Symbol。
    private var appIconImage: NSImage? {
        if let icon = NSImage(named: NSImage.applicationIconName), icon.size.width > 0 {
            return icon
        }
        return nil
    }
}

#Preview("About") {
    AboutSettingsView()
        .frame(width: 700, height: 540)
}
