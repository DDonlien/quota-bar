# 用户原始 prompt

> （截图：dropdown 里 Antigravity 显示"待配置 · Antigravity HTTP 500: {"code":"unknown"...}"，Z Code 显示"待配置 · BigModel Start 可用，但未返回额度数值；builtin:..."）
>
> 我以为我们已经统一过dropdown里的所有字词了，为什么agy、opencode和zcode没有显示打开 WebView 授权？如果实际上不能这样授权，我们可接受的标准显示应该是：
> 在 Preferences 中通过 API Key授权，灰色字
> 未获取到授权，灰色字
>
>（后续追问 MiniMax 现有内联输入框是否要搬到 Preferences，用户回复"看我后续的提示"）
>
>（截图1：Preferences「模型」页当前状态；截图2：Zed 的 GLM/Z.ai provider 设置页，展示"API key configured for https://api.z.ai/api/paas/v4" + Reset）
>
> 然后prefereces里这一页应该如实显示我们支持的获取模式，我不确定现在是不是这样；然后api模式如果支持，应该在这里有额外一行针对每个provider，用于输入api，类似zed的设计（图2，只是参考大致的交互逻辑，布局和视觉还是macos26原生那一套）

# 启动运行时的分支和版本

- 分支：`main`
- 版本：本轮基于上一轮（Preferences 摆设字段清理 + WebView 授权修复 + 浏览器 Cookie 路径删除）未提交的工作树继续

# 任务开始时间

2026-07-08 02:00 +0800（跨会话，用户后续消息延续到约 11:15）

# 任务结束时间

2026-07-08 11:15 +0800

# 任务结束时是否执行了提交

否——按惯例留给用户确认后再决定是否提交/推送。

# 已阅读上下文

- `MenuView.swift` 的 `.needsConfiguration` 分支、`MiniMaxKeyInputField`、`onSaveKey` 回调链（贯穿 5 层 View）。
- `MiniMaxConfigProvider.swift` 全文（`KeyInputState`/`currentKeyState`/`save`，理解 `~/.mavis/config.yaml` 的读写机制）。
- `ZCodeAuthProvider.swift` 全文（`loadConfig`/`extractCandidates`/`flattenStrings`/`isLikelyAPIKey` 通用解析逻辑）。
- `ModelsSettingsView.swift`/`SettingsComponents.swift` 全文（`SettingsRow`/`SettingsGroup`/`SettingsDivider` 组件）。
- `Strategies.swift` 逐个 pipeline 核对 `providerAccessModes` 文案准确性。

# 对话与行动记录

用户看到 Antigravity/Z Code 在 dropdown 里直接暴露原始技术性报错（HTTP 状态码 JSON、内部错误链），指出这违反了之前说好的"统一 dropdown 字词"，并给出明确标准：不能走 WebView 授权的 provider，应该展示"在 Preferences 中通过 API Key 授权"或"未获取到授权"两种灰字之一，不能再暴露原始 reason。

排查确认根因：`MenuView` 的 `.needsConfiguration` 分支只有两条路径——MiniMax 特判（内联输入框）和"其余情况展示原始 reason"，中间完全没有"这个 provider 到底有没有别的授权方式"这层判断，Antigravity/Z Code 落进了兜底的原始 reason 分支。

追问 MiniMax 现有的内联 API Key 输入框（写 `~/.mavis/config.yaml`）是否要搬到 Preferences 时，用户没有直接选项，回复"看我后续的提示"——随后用两张截图给出了明确方向：(1) Preferences「模型」页应该如实反映真实获取模式；(2) 参考 Zed 的 GLM/Z.ai provider 设置页交互（"已配置 API key + Reset"），给每个支持 API Key 的 provider 在 Preferences 加一行真正的手动输入入口，不只是 MiniMax，Z Code 也要有——用户特意提到 Zed 那张截图里配置的正好是 GLM/Z.ai，跟 Quota Bar 的 Z Code 是同一个后端，直接印证了 Z Code 也该有这个能力。

实现拆成五块：

1. **`.needsConfiguration` 三级判断**：`apiKeyCapableKinds` → 灰字指向 Preferences；`webViewQuotaCapableKinds` → 保留蓝色可点击按钮；都不支持 → 灰字"未获取到授权"。
2. **新增 `ProviderKind.apiKeyCapableKinds = [.minimax, .zcode]`**，跟已有的 `webViewQuotaCapableKinds` 同一维护模式。
3. **新增 `ZCodeManualKeyStore`**：Z Code 此前完全没有手动输入 key 的入口（只能靠官方 CLI 自动写的配置文件），新增一个 Quota Bar 自己独占的 JSON 文件（`~/Library/Application Support/QuotaBar/zcode-api-key.json`），排在 `ZCodeAuthProvider.configPaths` 最前——复用现成的通用字符串解析逻辑（`flattenStrings`/`isLikelyAPIKey`），不需要额外写解析代码。
4. **Preferences 新增「API Key 配置」区块**（`APIKeyConfigRow`）：MiniMax、Z Code 各一行，"已配置/未配置"状态 + "配置/重置"按钮，点开后原生 `SettingsRow` 风格输入框（复用 dropdown 已有的 `APIKeyTextField`，在普通 `NSWindow` 里其实比原来的 NSMenu 焦点 workaround 场景更简单）。同步删除 dropdown 里的 `MiniMaxKeyInputField` 和贯穿 `MenuView`→`ReadyStateView`/`LoadingStateView`→`DraggablePlanSection`→`PlanSection` 五层的整条 `onSaveKey` 回调链——入口统一收敛到 Preferences 后，dropdown 那条链路彻底变成死代码，删掉了而不是留着。
5. **`providerAccessModes` 全面核对**：跟 `Strategies.swift` 逐个 pipeline 核对后发现好几处不准——Codex/Kimi 标了 "CLI" 但默认 pipeline 根本没有真实 CLI 子进程执行；Claude/Antigravity 漏标了 "Keychain"（两条 pipeline 最后都有 KeychainProvider 兜底）；MiniMax/Z Code 统一用 "API" 表示"支持手动填 Key"，现在这个词有真实、可操作的能力对应，不再是纯描述性标签。

opencode 明确不在这次改动范围内——它是纯 BYOK 聚合 CLI，走的是 `.available` + 空 quotas 状态（`QuotaAuthPromptRow` 分支，不是 `.needsConfiguration`），当前"暂无额度数据"文案本身准确（不是授权问题，是它本来就没有官方额度百分比接口），跟这次要修的"原始 reason 暴露"是不同问题，没有改动。

# 完成工作

- `WebAuthorizationController.swift`：新增 `ProviderKind.apiKeyCapableKinds`。
- `ZCodeAuthProvider.swift`：新增 `ZCodeManualKeyStore`（`currentKeyState`/`readAPIKey`/`save`），`configPaths` 默认值把它排最前。
- `PreferencesStore.swift`：新增 `.providerCredentialsDidChange` 通知。
- `RefreshCoordinator.swift`：订阅新通知触发 `refreshNow()`。
- `MenuView.swift`：`.needsConfiguration` 分支重写为三级判断；删除 `MiniMaxKeyInputField` 及整条 `onSaveKey` 回调链（`MenuView`/`LoadingStateView`/`ReadyStateView`/`PlanSection`/`DraggablePlanSection` 五处签名清理）。
- `StatusBarController.swift`：`MenuView` 构造调用同步移除 `onSaveKey` 参数。
- `Preferences/ModelsSettingsView.swift`：新增 `apiKeySection` + `APIKeyConfigRow`（服务 MiniMax/Z Code 两个 provider）；`providerAccessModes` 全面修正。
- `Tests/QuotaBarTests/ZCodeAuthProviderTests.swift`：新增 4 个 `ZCodeManualKeyStore` 相关测试（missing 默认态、save/read 掩码显示、拒绝空 key、`defaultConfigPath` 断言）。

新包：`macos/build/20260708-110708-main/Quota Bar.app`（`build/latest` 已指向）。

# 更新的需求 ID

- `[0.10.0-BUG-A-017]` `[0.10.0-ARCH-L-000]` `[0.10.0-ARCH-L-001]` `[0.10.0-PM-A-016]` `[0.10.0-ARCH-L-002]` `[0.10.0-DOC-A-006]`

# 更新的 README 或 DESIGN 章节

- 无——本轮全部是 Preferences/dropdown 的 UI 与凭证输入功能改动，未涉及 README 里已经在上一轮更新过的架构性描述。

# 验证方式

- `swift build`：增量与 `rm -rf .build` 全量重建均通过。
- `swift test`：186 tests in 42 suites 全部通过（+4 个新增的 `ZCodeManualKeyStore` 测试）。
- `./scripts/build-app.sh`：产包成功。
- **未做真实交互验证**：发现用户自己已经在跑一个更早的开发包实例（PID 23746，10:50 启动，大概率是测试上一轮改动），为避免干扰用户自己的测试会话，没有用 computer-use 工具打开新包点击验证。建议用户自己：(1) 检查 Antigravity/Z Code 现在是否显示"未获取到授权"而不是原始报错；(2) 去「偏好设置 → 模型」页确认新出现的「API Key 配置」区块，试一次给 Z Code 填一个假 key 看状态是否正确切到"已配置"；(3) 确认 MiniMax 原来 dropdown 里的输入框已经消失。

# 备注

- 未提交 git commit。
- `ZCodeManualKeyStore.save`/`MiniMaxConfigProvider.save` 保存后立即调用 `NotificationCenter.default.post(name: .providerCredentialsDidChange, ...)`触发刷新，但没有对这条通知链路本身写自动化测试（`RefreshCoordinator`订阅逻辑用的是跟`.webAuthorizationWindowDidClose`完全一样的模式，判断复用现有代码路径的信心已经足够，没有为了测试覆盖率重复造轮子）。
- MiniMax 的 `MiniMaxConfigProvider.save`有一个既有限制（不是这次引入的）：要求`~/.mavis/config.yaml`**已经存在**且带`provider.minimax.options.apiKey`字段，不会从零创建这个文件/字段结构——如果用户从来没跑过真正的 mavis 工具，Preferences 里点"保存"会看到"config.yaml 缺少 provider.minimax.options.apiKey 字段（请手动添加）"这个既有报错。Z Code 那边因为是 Quota Bar 自己独占的新文件，没有这个限制。这个不对称目前保留，没有为了统一体验去改 MiniMax 那边已经在生产环境跑着的持久化逻辑。
