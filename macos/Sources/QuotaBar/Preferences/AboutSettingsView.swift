import AppKit
import SwiftUI

/// 「关于」偏好页：应用名 / 版本 / 检查更新 / 重置偏好。
///
/// 视觉对齐 macOS 26 系统设置：
/// - 不展示额外 section 标题，保持紧凑系统列表。
struct AboutSettingsView: View {
    @State private var store = PreferencesStore.shared
    @ObservedObject private var updateChecker = UpdateChecker.shared
    @ObservedObject private var license = LicenseManager.shared
    @State private var showResetConfirmation = false

    var body: some View {
        SettingsPage(.about) {
            VStack(alignment: .leading, spacing: 20) {
                appInfoGroup
                licenseGroup
                updateGroup
                resetSection
            }
        }
        .onAppear {
            // v0.11.0-FE-A-005：打开关于页时后台触发一次（5min 内不重复请求）。
            updateChecker.check(userInitiated: false)
            // 授权状态同理要按当下重算——本页展示的剩余天数以及下面那组更新按钮
            // 是否降级，都依赖它（见 `LicenseManager.startStateRefreshTimer`）。
            license.refreshState()
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

    /// 授权状态摘要（v0.15.0）。放在「检查更新」上方——它解释的正是下方那组按钮
    /// 为什么可能是降级状态，顺序上先因后果。详细操作在「激活」页，这里只做提示。
    private var licenseGroup: some View {
        SettingsGroup {
            SettingsRow(
                label: {
                    SettingsIconLabel(licenseTitle, symbol: licenseSymbol, tint: licenseTint)
                },
                subtitle: licenseSubtitle,
                subtitleLeading: 36,
                verticalPadding: 8
            )
        }
    }

    private var licenseTitle: String {
        switch license.state {
        case .trial(let days): return "试用中 · 剩余 \(days) 天"
        case .trialExpired: return "试用已结束"
        case .licensed: return "已激活"
        case .licenseInvalid: return "授权无效"
        }
    }

    private var licenseSymbol: String {
        switch license.state {
        case .trial: return "clock"
        case .trialExpired: return "lock.shield"
        case .licensed: return "checkmark.seal"
        case .licenseInvalid: return "exclamationmark.triangle"
        }
    }

    private var licenseTint: Color {
        switch license.state {
        case .trial: return .blue
        case .trialExpired: return .orange
        case .licensed: return .green
        case .licenseInvalid: return .red
        }
    }

    private var licenseSubtitle: String {
        switch license.state {
        case .trial:
            return "自动更新可用。试用结束后额度获取照常工作，只有自动更新会停用。"
        case .trialExpired, .licenseInvalid:
            return "自动更新已停用，额度获取不受影响。在「激活」页输入许可证即可恢复。"
        case .licensed:
            return "自动更新已启用。"
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
                        // 2026-07-31 用户反馈：试用过期后应该是"按钮直接置灰"，不是
                        // "能点、点了才告诉你不行"——之前 check() 内部的门禁（拒绝并
                        // 弹 .error）是点击后才生效的兜底，现在按钮本身先一步disable，
                        // 那条内部门禁在正常 UI 路径下就走不到了，纯粹当第二道防线
                        // （防的是万一以后哪里绕过这个按钮直接调 check(userInitiated:
                        // true)）。
                        .disabled(updateBusy || updateChecker.updatesRequireLicense)
                        .help(updateChecker.updatesRequireLicense ? "试用已结束，检查更新已停用。在「激活」页输入许可证即可恢复。" : "")
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
            Text("已是最新版本 v\(version)")
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
                // 未激活时不给"立即下载并安装"——那是付费换来的便利。但仍然如实
                // 告知有新版本、并给出官网手动下载这条任何人都走得通的路径，
                // 不把用户堵在死胡同里（v0.15.0）。
                if updateChecker.updatesRequireLicense {
                    HStack(spacing: 12) {
                        Button("前往官网下载") {
                            NSWorkspace.shared.open(URL(string: "https://quotabar.ddonlien.com/")!)
                        }
                        .controlSize(.small)
                        Button("查看 GitHub Release") { NSWorkspace.shared.open(candidate.releaseURL) }
                            .controlSize(.small)
                        Button("稍后提醒") { updateChecker.ignoreCurrentUpdate() }
                            .controlSize(.small)
                    }
                    Text("App 内一键安装需要激活；手动下载安装不受限制。")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                } else {
                    HStack(spacing: 12) {
                        Button("立即下载并安装") { updateChecker.downloadAndInstall() }
                            .controlSize(.small)
                        Button("查看 GitHub Release") { NSWorkspace.shared.open(candidate.releaseURL) }
                            .controlSize(.small)
                        Button("稍后提醒") { updateChecker.ignoreCurrentUpdate() }
                            .controlSize(.small)
                    }
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
