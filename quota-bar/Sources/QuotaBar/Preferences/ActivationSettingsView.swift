import SwiftUI

/// 「激活」偏好页：v0.3.0 阶段激活体系尚未上线，本页为占位骨架。
///
/// 真实激活流程（license / 订阅 token / 设备绑定等）落到后续 phase；
/// 此页保留 UI 与文案，方便届时只填业务逻辑、不重做界面。
struct ActivationSettingsView: View {
    var body: some View {
        Form {
            activationStatusSection
            deviceSection
            helpSection
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(.regularMaterial)
        .navigationTitle("激活")
        .padding(.horizontal, 4)
    }

    // MARK: - Sections

    private var activationStatusSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("未激活")
                        .font(.body.weight(.semibold))
                    Text("v0.3.0 阶段激活体系尚未上线，当前为免费全功能版本。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
        } header: {
            Text("当前状态")
        } footer: {
            Text("激活体系上线后，此处会展示激活状态、订阅有效期和续费入口。")
        }
    }

    private var deviceSection: some View {
        Section {
            HStack {
                Text("设备 ID")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(deviceIDMasked)
                    .font(.body.monospaced())
                    .textSelection(.enabled)
            }
        } header: {
            Text("本机")
        } footer: {
            Text("激活体系上线后，设备 ID 会用于绑定许可证与跨设备同步。")
        }
    }

    private var helpSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label("激活体系尚未发布", systemImage: "info.circle")
                    .font(.body.weight(.medium))
                Text("Quota Bar 当前为开源免费工具，所有 Provider 自动探测和额度展示功能均可直接使用。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let url = URL(string: "https://github.com/DDonlien/quota-bar") {
                    Link(destination: url) {
                        Label("查看 GitHub 仓库", systemImage: "arrow.up.right.square")
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("说明")
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
        .frame(width: 600, height: 500)
}