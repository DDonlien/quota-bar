import AppKit
import SwiftUI

/// 「关于」偏好页：应用名 / 版本 / 检查更新 / 重置偏好。
///
/// 视觉对齐 macOS 26 系统设置：
/// - 不展示额外 section 标题，保持紧凑系统列表。
struct AboutSettingsView: View {
    @State private var store = PreferencesStore.shared
    @State private var showResetConfirmation = false

    var body: some View {
        SettingsPage(.about) {
            VStack(alignment: .leading, spacing: 20) {
                appInfoGroup
                updateGroup
                resetSection
            }
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
                    Button {
                        openReleasesPage()
                    } label: {
                        SettingsIconLabel("检查更新", symbol: "arrow.triangle.2.circlepath", tint: .blue)
                    }
                    .buttonStyle(.plain)
                },
                verticalPadding: 8
            )
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

    private func openReleasesPage() {
        guard let url = URL(string: "https://github.com/DDonlien/quota-bar/releases") else { return }
        NSWorkspace.shared.open(url)
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
