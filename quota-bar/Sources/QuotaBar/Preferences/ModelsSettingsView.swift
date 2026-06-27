import SwiftUI

/// 「模型」偏好页：列出 `ProviderKind.allCases`，每个 Provider 一行 toggle。
///
/// 关闭后：`RefreshCoordinator` 过滤 `.notInstalled` 的逻辑同样会过滤掉 disabled provider
/// （具体落到 `PreferencesStore.isEnabled(kind:)`，由调用方决定如何在 pipeline 中过滤）。
struct ModelsSettingsView: View {
    @State private var store = PreferencesStore.shared

    var body: some View {
        Form {
            Section {
                ForEach(ProviderKind.allCases) { kind in
                    providerRow(kind)
                }
            } header: {
                Text("已支持的 Provider")
            } footer: {
                Text("关闭后，Quota Bar 不会再为该 Provider 抓取数据，也不会在 dropdown 或菜单栏展示。自动探测仍然运行，但结果会被过滤掉。")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(.regularMaterial)
        .navigationTitle("模型")
        .padding(.horizontal, 4)
    }

    private func providerRow(_ kind: ProviderKind) -> some View {
        HStack(spacing: 12) {
            // brand color 图标占位
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(kind.brandColor.opacity(0.18))
                    .frame(width: 28, height: 28)
                Image(systemName: kind.iconSymbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(kind.brandColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(kind.displayName)
                    .font(.body)
                Text(providerSubtitle(kind))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Toggle("", isOn: bindingEnabled(kind))
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(kind.displayName)
        .accessibilityValue(store.isEnabled(kind: kind) ? "已启用" : "已禁用")
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
        .frame(width: 600, height: 500)
}