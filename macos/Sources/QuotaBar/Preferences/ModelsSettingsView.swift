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
    // `.glm` 之前在这里，但它是个"幽灵" kind——`Strategies.supportedProviderKinds`
    // 从来没有把它接进任何真实 pipeline，dropdown 里跑的实际是 `.zcode`。两个不同的
    // `ProviderKind` 枚举值意味着两套完全独立的 `PreferencesStore.providerOverrides`
    // 记录，Preferences 这里切 "GLM" 的开关不会影响任何真正在跑的 provider，dropdown
    // 里隐藏 "Z Code" 也不会反映到这个开关上（2026-07-07 用户实测发现"关联不上"）。
    // 这里改用真正在跑的 `.zcode`，跟 dropdown 显示的是同一个 kind。
    private let visibleProviders: [ProviderKind] = [.codex, .minimax, .kimi, .claude, .antigravity, .zcode, .opencode]

    var body: some View {
        SettingsPage(.models) {
            VStack(alignment: .leading, spacing: 18) {
                providersSection
                apiKeySection
                claudeStatusLineSection
            }
        }
    }

    /// 手动输入 API Key 的 provider（`ProviderKind.apiKeyCapableKinds`）：此前 MiniMax
    /// 唯一的输入入口是 dropdown 里的一个内联文本框，Z Code 则完全没有——用户拿到一个
    /// Z Code API key 但没装官方 CLI 时，没有任何办法喂给 Quota Bar。这里统一挪到
    /// Preferences，跟其余 provider 配置项放在一起（2026-07-08 用户反馈 + 参考 Zed
    /// 的"已配置/重置"交互模式，视觉沿用本页原生 macOS 26 风格）。
    private var apiKeySection: some View {
        SettingsSection("API Key 配置") {
            VStack(alignment: .leading, spacing: 8) {
                Text("给没有官方登录方式、或不想装官方 CLI 的 Provider 手动粘贴 API Key，仅保存在本机。")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                SettingsGroup {
                    ForEach(Array(apiKeyCapableProviders.enumerated()), id: \.element.id) { index, kind in
                        if index > 0 { SettingsDivider() }
                        APIKeyConfigRow(kind: kind)
                    }
                }
            }
        }
    }

    private var apiKeyCapableProviders: [ProviderKind] {
        visibleProviders.filter { ProviderKind.apiKeyCapableKinds.contains($0) }
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
        case .zcode: return "智谱 / Z.ai"
        case .cursor: return "Anysphere"
        case .gemini, .antigravity: return "Google"
        case .openai: return "OpenAI"
        case .deepseek: return "DeepSeek"
        case .copilot: return "GitHub"
        case .openrouter: return "OpenRouter"
        case .perplexity: return "Perplexity"
        case .warp: return "Warp"
        case .trae: return "ByteDance"
        case .opencode: return "SST"
        }
    }

    /// 2026-07-08 全面核对过跟 `Strategies.swift` 里每个 pipeline 实际注册的策略是否
    /// 一致（用户反馈"这一页应该如实显示我们支持的获取模式"）。改动点：
    /// - Codex/Kimi 之前写了 "CLI"，但默认 pipeline 根本没有真实执行 CLI 子进程
    ///   （`codexLogEstimateEnabled`/CLI OAuth 都只是读本地 token 文件直调 API），
    ///   改成更准确的 "Config"；
    /// - Claude/Antigravity 补上 "Keychain"（两条 pipeline 最后都有 KeychainProvider
    ///   兜底，之前漏标）；
    /// - MiniMax/Z Code 统一用 "API" 表示"支持手动填 API Key"——这不再只是命名巧合，
    ///   两者现在在下面的「API Key 配置」区块里都有真实的手动输入入口
    ///   （`ProviderKind.apiKeyCapableKinds`），"API" 这个词现在对应一个真实、
    ///   可操作的能力，不是描述性标签。
    private func providerAccessModes(_ kind: ProviderKind) -> [String] {
        switch kind {
        case .codex: return ["Config", "Web", "Keychain"]
        case .minimax: return ["API", "CLI", "Web", "Keychain"]
        case .kimi: return ["Config", "Web", "Keychain"]
        case .claude: return ["statusLine", "Config", "CLI", "Web", "Keychain"]
        case .glm: return ["API（待接入）"]
        case .zcode: return ["API", "Keychain"]
        case .cursor: return ["待接入"]
        case .gemini: return ["待接入"]
        case .openai: return ["待接入"]
        case .deepseek: return ["待接入"]
        case .copilot: return ["待接入"]
        case .openrouter: return ["待接入"]
        case .perplexity: return ["待接入"]
        case .warp: return ["待接入"]
        case .trae: return ["待接入"]
        case .antigravity: return ["App", "CLI", "Keychain"]
        case .opencode: return ["Config", "Web", "API"]
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

// MARK: - API Key 配置行

/// MiniMax（`MiniMaxConfigProvider`）和 Z Code（`ZCodeManualKeyStore`）分别有自己的
/// `KeyInputState` 类型（字段/命名不完全一致），这里统一映射成一个本地展示状态，
/// 一套 UI 同时服务两者，交互参考 Zed 的"已配置 API Key / Reset"模式，但视觉沿用
/// 本页其余行已有的 `SettingsRow`/`SettingsGroup` 原生风格，不复刻 Zed 的具体样式。
private struct APIKeyConfigRow: View {
    let kind: ProviderKind

    private enum DisplayState {
        case missing
        case placeholder(current: String)
        case configured(masked: String)

        var isConfigured: Bool {
            if case .configured = self { return true }
            return false
        }
    }

    @State private var state: DisplayState = .missing
    @State private var isEditing = false
    @State private var keyInput = ""
    @State private var errorMessage: String?

    /// 没有直接复用 `SettingsRow`——展开编辑态需要在"名称行下面那一行"放
    /// TextField + 「保存」按钮，而 `SettingsRow.subtitle` 只接受 `Text`，塞不进一个
    /// 可交互的输入框。改成手动拼一个 `VStack`，用跟 `SettingsRow` 完全一致的
    /// padding/字号/颜色常量保持视觉统一（2026-07-09 用户反馈：之前用两个
    /// `SettingsRow` 叠一个 `SettingsDivider` 实现，多出一条不必要的分割线，输入框
    /// 也没跟名称左对齐，「保存」也没跟「取消」对齐——本质原因是输入框那一行走的是
    /// `label:` 参数而不是 `subtitle:`，`subtitleLeading` 对它完全不生效）。
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 12) {
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
                        .foregroundStyle(.primary)
                }
                Spacer(minLength: 12)
                Button(isEditing ? "取消" : (state.isConfigured ? "重置" : "配置")) {
                    if isEditing {
                        isEditing = false
                        errorMessage = nil
                    } else {
                        keyInput = ""
                        errorMessage = nil
                        isEditing = true
                    }
                }
                .controlSize(.small)
            }

            if isEditing {
                // 输入框直接代替下面这行原本的灰字状态说明——编辑态不需要同时展示
                // "未配置/已配置"这类静态描述，输入框本身就代表了当前状态。
                // 这里是 Preferences 的普通 `NSWindow`，不是 NSMenu 的 tracking-mode
                // 自定义视图——原来的 `APIKeyTextField`（包 `NSTextField` + 全局
                // NSEvent 监听器拦截 Cmd+V/mouseUp）是专门为 dropdown 里那个已经
                // 删掉的内联输入框做的变通，这里完全用不上，原生 `TextField` 就能
                // 正常拿到焦点和键盘输入。
                HStack(spacing: 6) {
                    TextField("粘贴或输入 \(kind.displayName) API Key", text: $keyInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                        .onSubmit(save)
                    Button("保存", action: save)
                        .controlSize(.small)
                        .disabled(keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.leading, 36)
            } else {
                statusText
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 36)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .padding(.leading, 36)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .onAppear(perform: reload)
    }

    // 之前这里直接把反引号拼进纯文本字符串（"当前 `sk-xxx`"）——`SettingsRow`
    // 的 subtitle 是普通 `String`，走的是 `Text(_ content: some StringProtocol)`
    // 初始化器，不会像 `Text(_ key: LocalizedStringKey)` 那样解析 Markdown，反引号
    // 只会被原样显示成两个字符，而不是等宽代码样式（2026-07-08 用户反馈视觉问题）。
    // 改成把技术性的值单独拆成一个等宽字体 `Text`，跟说明文字拼在一起。
    private var statusText: Text {
        switch state {
        case .missing:
            return Text("未配置 · \(missingHint)")
        case .placeholder(let current):
            return Text("待替换占位符 · 当前 \(Text(current).font(.system(size: 11, design: .monospaced)))")
        case .configured(let masked):
            return Text("\(Text(masked).font(.system(size: 11, design: .monospaced)))（重新输入会覆盖）")
        }
    }

    private var missingHint: String {
        switch kind {
        case .minimax: return "写入 ~/.mavis/config.yaml"
        case .zcode: return "供没有安装官方 CLI 时手动接入"
        case .opencode: return "供没有安装官方 CLI 时手动接入"
        default: return ""
        }
    }

    private func reload() {
        switch kind {
        case .minimax:
            switch MiniMaxConfigProvider.currentKeyState() {
            case .missing: state = .missing
            case .placeholder(let current): state = .placeholder(current: current)
            case .configured(let masked): state = .configured(masked: masked)
            }
        case .zcode:
            switch ZCodeManualKeyStore.currentKeyState() {
            case .missing: state = .missing
            case .configured(let masked): state = .configured(masked: masked)
            }
        case .opencode:
            switch OpenCodeManualKeyStore.currentKeyState() {
            case .missing: state = .missing
            case .configured(let masked): state = .configured(masked: masked)
            }
        default:
            state = .missing
        }
    }

    private func save() {
        let trimmed = keyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            switch kind {
            case .minimax: try MiniMaxConfigProvider.save(apiKey: trimmed)
            case .zcode: try ZCodeManualKeyStore.save(apiKey: trimmed)
            case .opencode: try OpenCodeManualKeyStore.save(apiKey: trimmed)
            default: break
            }
            errorMessage = nil
            isEditing = false
            keyInput = ""
            reload()
            // 保存成功后立即触发一次刷新，不用等下一个自动周期才看到结果
            // （见 `RefreshCoordinator` 对 `.providerCredentialsDidChange` 的订阅）。
            NotificationCenter.default.post(name: .providerCredentialsDidChange, object: kind)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
