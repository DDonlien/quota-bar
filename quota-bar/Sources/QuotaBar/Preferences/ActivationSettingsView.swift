import SwiftUI

/// 「激活」偏好页：v0.3.0 阶段激活体系尚未上线，本页为占位骨架。
///
/// 视觉对齐 macOS 26 系统设置：
/// - 3 个 `SettingsSection`（当前状态 / 本机 / 说明）
/// - 真实激活流程（license / 订阅 token / 设备绑定等）落到后续 phase；
///   此页保留 UI 与文案，方便届时只填业务逻辑、不重做界面。
struct ActivationSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                statusSection
                deviceSection
                helpSection
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .navigationTitle("激活")
    }

    // MARK: - Sections

    private var statusSection: some View {
        SettingsSection("当前状态") {
            SettingsGroup {
                SettingsRow(
                    label: {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.shield")
                                .font(.system(size: 18))
                                .foregroundStyle(.secondary)
                                .frame(width: 28)
                            Text("未激活")
                                .font(.system(size: 13, weight: .medium))
                        }
                    },
                    subtitle: "v0.3.0 阶段激活体系尚未上线，当前为免费全功能版本。激活体系上线后，此处会展示激活状态、订阅有效期和续费入口。"
                )
            }
        }
    }

    private var deviceSection: some View {
        SettingsSection("本机") {
            SettingsGroup {
                SettingsRow(
                    label: { Text("设备 ID") },
                    trailing: {
                        Text(deviceIDMasked)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                )
            }
        }
    }

    private var helpSection: some View {
        SettingsSection("说明") {
            SettingsGroup {
                SettingsRow(
                    label: {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 18))
                                .foregroundStyle(.secondary)
                                .frame(width: 28)
                            Text("激活体系尚未发布")
                                .font(.system(size: 13, weight: .medium))
                        }
                    },
                    subtitle: "Quota Bar 当前为开源免费工具，所有 Provider 自动探测和额度展示功能均可直接使用。"
                )
                SettingsDivider()
                SettingsRow(
                    label: {
                        Link(destination: URL(string: "https://github.com/DDonlien/quota-bar")!) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.up.right.square")
                                Text("查看 GitHub 仓库")
                                    .font(.system(size: 13))
                            }
                        }
                    }
                )
            }
        }
    }

    // MARK: - Helpers

    /// 设备 ID：占位实现，用 bundlePath 的 hash 派生稳定伪 ID，
    /// 避免读取真实硬件 UUID（隐私）。激活体系上线后接入真实设备指纹。
    private var deviceIDMasked: String {
        let raw = Bundle.main.bundlePath
        let hash = raw.hashValue
        let truncated = UInt32(truncatingIfNeeded: hash)
        let hex = String(format: "%08X", truncated)
        return "••••-••••-\(hex)"
    }
}

#Preview("Activation") {
    ActivationSettingsView()
        .frame(width: 700, height: 540)
}
