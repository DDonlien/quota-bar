import SwiftUI

/// 「关于」偏好页：应用名 / 版本 / GitHub / 版权 / 重置偏好。
///
/// 视觉对齐 macOS 26 系统设置：
/// - 3 个 `SettingsSection`（应用 / 链接 / 维护）
struct AboutSettingsView: View {
    @State private var store = PreferencesStore.shared
    @State private var showResetConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                appInfoSection
                linksSection
                resetSection
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .navigationTitle("关于")
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

    private var appInfoSection: some View {
        SettingsSection("应用") {
            SettingsGroup {
                SettingsRow(
                    label: {
                        HStack(spacing: 14) {
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

                            VStack(alignment: .leading, spacing: 2) {
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
                    trailing: { Text("DDonlien").foregroundStyle(.secondary) }
                )
                SettingsDivider()
                SettingsRow(
                    label: { Text("许可") },
                    trailing: { Text("MIT").foregroundStyle(.secondary) }
                )
                SettingsDivider()
                SettingsRow(
                    label: { Text("平台") },
                    trailing: { Text("macOS 26+").foregroundStyle(.secondary) }
                )
            }
        }
    }

    private var linksSection: some View {
        SettingsSection("链接") {
            SettingsGroup {
                if let repo = URL(string: "https://github.com/DDonlien/quota-bar") {
                    SettingsRow(
                        label: {
                            Link(destination: repo) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.up.right.square")
                                    Text("GitHub 仓库")
                                        .font(.system(size: 13))
                                }
                            }
                        },
                        trailing: {
                            Text("github.com/DDonlien/quota-bar")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    )
                }
                SettingsDivider()
                if let releases = URL(string: "https://github.com/DDonlien/quota-bar/releases") {
                    SettingsRow(
                        label: {
                            Link(destination: releases) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("下载最新版本")
                                        .font(.system(size: 13))
                                }
                            }
                        }
                    )
                }
            }
        }
    }

    private var resetSection: some View {
        SettingsSection("维护") {
            SettingsGroup {
                SettingsRow(
                    label: {
                        Button(role: .destructive) {
                            showResetConfirmation = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.uturn.backward")
                                Text("重置偏好设置…")
                                    .font(.system(size: 13))
                            }
                            .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    },
                    subtitle: "重置后所有 Provider 开关、刷新间隔、排序偏好都会清空，回到默认状态。"
                )
            }
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
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "dev"
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
