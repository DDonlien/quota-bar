import SwiftUI

/// 「关于」偏好页：应用名 / 版本 / GitHub / 版权 / 重置偏好。
struct AboutSettingsView: View {
    @State private var store = PreferencesStore.shared
    @State private var showResetConfirmation = false

    var body: some View {
        Form {
            appInfoSection
            linksSection
            resetSection
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(.regularMaterial)
        .navigationTitle("关于")
        .padding(.horizontal, 4)
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
        Section {
            HStack(spacing: 14) {
                // 应用图标：用 NSImage 桥接 SF Symbol fallback
                Group {
                    if let icon = appIconImage {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 32, weight: .regular))
                            .foregroundStyle(.tint)
                    }
                }
                .frame(width: 48, height: 48)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(appName)
                        .font(.title3.weight(.semibold))
                    HStack(spacing: 8) {
                        Text("版本 \(appVersion)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text("Build \(appBuild)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.vertical, 4)

            HStack {
                Text("开发者")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("DDonlien")
            }
            HStack {
                Text("许可")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("MIT")
            }
            HStack {
                Text("平台")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("macOS 26+")
            }
        } header: {
            Text("应用")
        }
    }

    private var linksSection: some View {
        Section {
            if let repo = URL(string: "https://github.com/DDonlien/quota-bar") {
                Link(destination: repo) {
                    HStack {
                        Label("GitHub 仓库", systemImage: "arrow.up.right.square")
                        Spacer()
                        Text("github.com/DDonlien/quota-bar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
            if let releases = URL(string: "https://github.com/DDonlien/quota-bar/releases") {
                Link(destination: releases) {
                    Label("下载最新版本", systemImage: "square.and.arrow.down")
                }
            }
        } header: {
            Text("链接")
        }
    }

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                Label("重置偏好设置…", systemImage: "arrow.uturn.backward")
            }
        } header: {
            Text("维护")
        } footer: {
            Text("重置后所有 Provider 开关、刷新间隔、排序偏好都会清空，回到默认状态。")
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
        .frame(width: 600, height: 500)
}