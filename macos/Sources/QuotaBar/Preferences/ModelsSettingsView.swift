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
    private let visibleProviders: [ProviderKind] = [.codex, .minimax, .kimi, .claude, .antigravity, .glm]

    var body: some View {
        SettingsPage(.models) {
            VStack(alignment: .leading, spacing: 18) {
                providersSection
                claudeStatusLineSection
            }
        }
    }

    /// Claude Code statusLine hook 额度捕获开关（v0.10.0-DATA-B-018）。
    /// 开启后往 `~/.claude/settings.json` 写入一个小脚本作为 statusLine 命令，
    /// 捕获 Claude Code 自己在终端状态栏渲染时携带的额度数据——不需要浏览器、
    /// WebView 或 Keychain；代价是只有在最近跑过 claude 交互会话时数据才新鲜。
    private var claudeStatusLineSection: some View {
        SettingsSection("Claude Code 额度捕获（实验）") {
            SettingsGroup {
                SettingsRow(
                    label: { Text("捕获终端状态栏额度数据") },
                    subtitle: "在 ~/.claude/settings.json 里注册 statusLine 脚本，读取 Claude Code 自己渲染状态栏时携带的额度数据；不修改你已有的自定义 statusLine。仅在你最近用过 claude 交互会话时数据才新鲜。",
                    subtitleLeading: 0,
                    verticalPadding: 6,
                    trailing: {
                        Toggle("", isOn: bindingClaudeStatusLineHook)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                    }
                )
                if let message = claudeStatusLineStatusMessage {
                    SettingsDivider()
                    SettingsRow(
                        label: {
                            Text(message)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        },
                        verticalPadding: 6
                    )
                }
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
        case .claude: return ["statusLine", "Config", "CLI", "Web"]
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

    @State private var claudeStatusLineStatusMessage: String?

    private var bindingClaudeStatusLineHook: Binding<Bool> {
        Binding(
            get: { store.preferences.claudeStatusLineHookEnabled },
            set: { enabled in
                store.setClaudeStatusLineHookEnabled(enabled)
                if enabled {
                    switch ClaudeStatusLineHookInstaller.shared.install() {
                    case .installed:
                        claudeStatusLineStatusMessage = "已启用。打开一次 claude 交互会话即可开始捕获额度。"
                    case .skippedExistingStatusLine:
                        claudeStatusLineStatusMessage = "检测到你已有自定义 statusLine 配置，为避免覆盖未做修改——这种情况下额度捕获不会生效。"
                    case .failed(let reason):
                        claudeStatusLineStatusMessage = reason
                    }
                } else {
                    ClaudeStatusLineHookInstaller.shared.uninstall()
                    claudeStatusLineStatusMessage = nil
                }
            }
        )
    }
}

#Preview("Models") {
    ModelsSettingsView()
        .frame(width: 700, height: 540)
}
