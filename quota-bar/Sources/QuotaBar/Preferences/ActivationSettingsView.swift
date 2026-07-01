import SwiftUI

/// 「激活」偏好页：当前阶段只持久化激活邮箱，不展示占位设备 ID。
struct ActivationSettingsView: View {
    @State private var store = PreferencesStore.shared

    var body: some View {
        SettingsPage(.activation) {
            VStack(alignment: .leading, spacing: 20) {
                activationGroup
                removeActivationGroup
            }
        }
    }

    private var activationGroup: some View {
        SettingsGroup {
            SettingsRow(
                label: {
                    SettingsIconLabel("未激活", symbol: "lock.shield", tint: .orange)
                },
                verticalPadding: 8
            )
            SettingsDivider()
            SettingsRow(
                label: {
                    TextField("输入激活邮箱", text: bindingActivationEmail)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                },
                verticalPadding: 8
            )
        }
    }

    private var removeActivationGroup: some View {
        SettingsGroup {
            SettingsRow(
                label: {
                    Button(role: .destructive) {
                        store.setActivationEmail("")
                    } label: {
                        SettingsIconLabel("移除激活", symbol: "xmark.circle", tint: .red)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isActivated)
                    .opacity(isActivated ? 1 : 0.45)
                },
                verticalPadding: 8
            )
        }
    }

    /// 当前尚未接入真实激活后端；未激活状态下不能执行「移除激活」。
    private var isActivated: Bool {
        false
    }

    private var bindingActivationEmail: Binding<String> {
        Binding(
            get: { store.preferences.activationEmail },
            set: { store.setActivationEmail($0) }
        )
    }
}

#Preview("Activation") {
    ActivationSettingsView()
        .frame(width: 700, height: 540)
}
