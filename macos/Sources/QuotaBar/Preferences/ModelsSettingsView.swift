import SwiftUI

/// 「模型」偏好页：列出 `ProviderKind.allCases`，每个 Provider 一行 toggle。
///
/// 视觉对齐 macOS 26 系统设置：
/// - 1 个 `SettingsSection("Provider")` 包 1 个 `SettingsGroup`
/// - 每个 Provider 一行：brand color icon + name + subtitle + switch toggle
///
/// 关闭后：`RefreshCoordinator` 过滤 `.notInstalled` 的逻辑同样会过滤掉 disabled provider
/// （具体落到 `PreferencesStore.isEnabled(kind:)`，由调用方决定如何在 pipeline 中过滤）。
struct ModelsSettingsView: View {
    @State private var store = PreferencesStore.shared
    private let visibleProviders: [ProviderKind] = [.codex, .minimax, .kimi, .claude, .glm]

    var body: some View {
        SettingsPage(.models) {
            VStack(alignment: .leading, spacing: 18) {
                providersSection
            }
        }
    }

    private var providersSection: some View {
        SettingsSection("Provider") {
            SettingsGroup {
                ForEach(Array(visibleProviders.enumerated()), id: \.element.id) { index, kind in
                    if index > 0 { SettingsDivider() }
                    providerRow(kind)
                }
            }
        }
    }

    private func providerRow(_ kind: ProviderKind) -> some View {
        SettingsRow(
            label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(kind.brandColor.opacity(0.18))
                            .frame(width: 24, height: 24)
                        Image(systemName: kind.iconSymbol)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(kind.brandColor)
                    }
                    Text(kind.displayName)
                        .font(.system(size: 13))
                }
            },
            subtitle: providerSubtitle(kind),
            subtitleLeading: 36,
            verticalPadding: 6,
            trailing: {
                Toggle("", isOn: bindingEnabled(kind))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.mini)
            }
        )
    }

    private func providerSubtitle(_ kind: ProviderKind) -> String {
        "\(providerVendor(kind)) | \(providerAccessModes(kind).joined(separator: ", "))"
    }

    private func providerVendor(_ kind: ProviderKind) -> String {
        switch kind {
        case .codex: return "OpenAI"
        case .minimax: return "MiniMax"
        case .kimi: return "Moonshot"
        case .claude: return "Anthropic"
        case .glm: return "智谱"
        case .zcode: return "Z Code"
        case .cursor: return "Anysphere"
        case .gemini, .antigravity: return "Google"
        case .openai: return "OpenAI"
        case .deepseek: return "DeepSeek"
        case .copilot: return "GitHub"
        case .openrouter: return "OpenRouter"
        case .perplexity: return "Perplexity"
        case .warp: return "Warp"
        case .trae: return "ByteDance"
        }
    }

    private func providerAccessModes(_ kind: ProviderKind) -> [String] {
        switch kind {
        case .codex: return ["CLI", "Web"]
        case .minimax: return ["CLI", "Web", "API"]
        case .kimi: return ["CLI", "Web"]
        case .claude: return ["Web"]
        case .glm: return ["API（待接入）"]
        case .zcode: return ["Config", "Keychain"]
        case .cursor: return ["待接入"]
        case .gemini: return ["待接入"]
        case .openai: return ["待接入"]
        case .deepseek: return ["待接入"]
        case .copilot: return ["待接入"]
        case .openrouter: return ["待接入"]
        case .perplexity: return ["待接入"]
        case .warp: return ["待接入"]
        case .trae: return ["待接入"]
        case .antigravity: return ["App", "CLI"]
        }
    }

    private func bindingEnabled(_ kind: ProviderKind) -> Binding<Bool> {
        Binding(
            get: { store.isEnabled(kind: kind) },
            set: { store.setEnabled($0, for: kind) }
        )
    }
}

#Preview("Models") {
    ModelsSettingsView()
        .frame(width: 700, height: 540)
}
