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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                providersSection
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .navigationTitle("模型")
    }

    private var providersSection: some View {
        SettingsSection("Provider") {
            SettingsGroup {
                ForEach(Array(ProviderKind.allCases.enumerated()), id: \.element.id) { index, kind in
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
                            .frame(width: 28, height: 28)
                        Image(systemName: kind.iconSymbol)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(kind.brandColor)
                    }
                    Text(kind.displayName)
                        .font(.system(size: 13))
                }
            },
            subtitle: providerSubtitle(kind),
            trailing: {
                Toggle("", isOn: bindingEnabled(kind))
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
        )
    }

    private func providerSubtitle(_ kind: ProviderKind) -> String {
        switch kind {
        case .codex: return "OpenAI Codex CLI / ChatGPT Plus"
        case .minimax: return "MiniMax 开放平台 / Coding Plan"
        case .kimi: return "Moonshot Kimi"
        case .claude: return "Anthropic Claude"
        case .cursor: return "Cursor IDE"
        case .gemini: return "Google Gemini（已被 Antigravity 取代）"
        case .openai: return "OpenAI Platform"
        case .deepseek: return "DeepSeek"
        case .copilot: return "GitHub Copilot"
        case .openrouter: return "OpenRouter"
        case .perplexity: return "Perplexity"
        case .warp: return "Warp Terminal"
        case .trae: return "Trae IDE"
        case .antigravity: return "Google Antigravity"
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
