import SwiftUI

/// 「激活」偏好页（v0.15.0 接入真实 Creem 授权）。
///
/// 三段结构：当前状态 → 输入许可证密钥并激活 → 移除激活。
/// 试用期内和已激活时都不会挡任何功能，这个页面只影响自动更新是否可用，
/// 页面文案也如实这么说，不制造"不激活就不能用"的错觉。
struct ActivationSettingsView: View {
    @ObservedObject private var license = LicenseManager.shared
    @State private var keyInput: String = ""

    var body: some View {
        SettingsPage(.activation) {
            VStack(alignment: .leading, spacing: 20) {
                statusGroup
                if !license.state.isLicensed {
                    activateGroup
                    purchaseHint
                }
                if license.state.isLicensed {
                    removeActivationGroup
                }
            }
        }
        // 打开这一页的瞬间就要显示当下真实的剩余天数，不能等定时器下一次触发
        // （见 `LicenseManager.startStateRefreshTimer`）。
        .onAppear { license.refreshState() }
    }

    // MARK: 当前状态

    private var statusGroup: some View {
        SettingsGroup {
            SettingsRow(
                label: {
                    SettingsIconLabel(statusTitle, symbol: statusSymbol, tint: statusTint)
                },
                subtitle: statusSubtitle,
                subtitleLeading: 36,
                verticalPadding: 8
            )
        }
    }

    private var statusTitle: String {
        switch license.state {
        case .trial(let days): return "试用中 · 剩余 \(days) 天"
        case .trialExpired: return "试用已结束"
        case .licensed: return "已激活"
        case .licenseInvalid: return "授权无效"
        }
    }

    private var statusSymbol: String {
        switch license.state {
        case .trial: return "clock"
        case .trialExpired: return "lock.shield"
        case .licensed: return "checkmark.seal"
        case .licenseInvalid: return "exclamationmark.triangle"
        }
    }

    private var statusTint: Color {
        switch license.state {
        case .trial: return .blue
        case .trialExpired: return .orange
        case .licensed: return .green
        case .licenseInvalid: return .red
        }
    }

    private var statusSubtitle: String {
        switch license.state {
        case .trial:
            return "试用期内所有功能可用。试用结束后额度获取仍然照常工作，只有自动更新会停用。"
        case .trialExpired:
            return "额度获取不受影响，仍然照常工作；自动更新已停用——激活后恢复，也可以随时到官网手动下载新版本。"
        case .licensed(let expiresAt):
            if let expiresAt {
                return "自动更新已启用。授权有效期至 \(Self.dateText(expiresAt))。"
            }
            return "自动更新已启用。感谢支持 Quota Bar。"
        case .licenseInvalid(let reason):
            return "\(reason)。自动更新已停用；额度获取不受影响。"
        }
    }

    // MARK: 激活

    private var activateGroup: some View {
        SettingsGroup {
            SettingsRow(
                label: {
                    TextField("粘贴许可证密钥", text: $keyInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .disabled(license.isActivating)
                        .onSubmit { activate() }
                },
                subtitle: "购买后可以在 Creem 发送的邮件里找到这串密钥。",
                verticalPadding: 8,
                trailing: {
                    Button(license.isActivating ? "激活中…" : "激活") { activate() }
                        .disabled(license.isActivating || keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            )
            if let error = license.lastError {
                SettingsDivider()
                SettingsRow(
                    label: {
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    },
                    verticalPadding: 6
                )
            }
        }
    }

    private var purchaseHint: some View {
        SettingsGroup {
            SettingsRow(
                label: {
                    Link(destination: URL(string: "https://quotabar.ddonlien.com/#pricing")!) {
                        SettingsIconLabel("购买许可证 · $4.99", symbol: "cart", tint: .accentColor)
                    }
                },
                subtitle: "一次性购买，包含未来更新。源码始终开源，也可以永久免费自行编译。",
                subtitleLeading: 36,
                verticalPadding: 8
            )
        }
    }

    private var removeActivationGroup: some View {
        SettingsGroup {
            SettingsRow(
                label: {
                    Button(role: .destructive) {
                        license.removeActivation()
                        keyInput = ""
                    } label: {
                        SettingsIconLabel("移除激活", symbol: "xmark.circle", tint: .red)
                    }
                    .buttonStyle(.plain)
                },
                subtitle: "只清除本机的授权记录，不会退掉你的许可证；需要释放设备名额请到 Creem 后台操作。",
                subtitleLeading: 36,
                verticalPadding: 8
            )
        }
    }

    private func activate() {
        let key = keyInput
        Task { await license.activate(key: key) }
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

#Preview("Activation") {
    ActivationSettingsView()
        .frame(width: 700, height: 540)
}
