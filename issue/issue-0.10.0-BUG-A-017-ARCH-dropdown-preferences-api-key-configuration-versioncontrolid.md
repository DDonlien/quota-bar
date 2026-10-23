# sub/main: dropdown 授权文案统一 + Preferences 新增 API Key 配置入口

- ID：`0.10.0-BUG-A-017`。
- 类型：`ARCH`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: dropdown 授权文案统一 + Preferences 新增 API Key 配置入口。
- 原稳定 ID：`0.10.0-BUG-A-017`, `0.10.0-ARCH-L-000`, `0.10.0-ARCH-L-001`, `0.10.0-PM-A-016`, `0.10.0-ARCH-L-002`, `0.10.0-DOC-A-006`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户看到 dropdown 里 Antigravity/Z Code 直接展示原始技术性报错（"Antigravity HTTP 500: {...}"、"BigModel Start 可用，但未返回额度数值；builtin:..."），追问"为什么 agy/opencode/zcode 不显示打开 WebView 授权"，并给出标准：不能走 WebView 授权的 provider，应该统一显示"在 Preferences 中通过 API Key 授权"或"未获取到授权"两种灰字之一，不能再暴露原始 reason。同时指出 Preferences「模型」页的"获取模式"文案应该如实反映实现，并要求给支持 API Key 的 provider（参考 Zed 的"已配置/Reset"交互，视觉沿用本页原生 macOS 26 风格）在 Preferences 里加一行真正的手动输入入口——不只是 MiniMax，Z Code 也要有（用户贴的 Zed 截图里 GLM/Z.ai provider 正好也是纯 API Key 模式）。

- [x] [0.10.0-BUG-A-017] `MenuView` 的 `.needsConfiguration` 分支重写为三级判断（替换原来"MiniMax 特判内联输入框 / else 展示原始 reason"的二分支）：`apiKeyCapableKinds` → 灰字"在 Preferences 中通过 API Key 授权"；`webViewQuotaCapableKinds` → 保留原有蓝色可点击"打开 WebView 授权"；两者都不支持（Antigravity/opencode 等）→ 灰字"未获取到授权"，不再拼接原始技术性 reason（HTTP 状态码 JSON、内部错误链等只留在诊断日志里）#P0
- [x] [0.10.0-ARCH-L-000] 新增 `ProviderKind.apiKeyCapableKinds = [.minimax, .zcode]` 静态集合（跟 `webViewQuotaCapableKinds` 同一维护模式，新增/移除某 provider 的手动 key 支持时必须同步改这里）#P0
- [x] [0.10.0-ARCH-L-001] 新增 `ZCodeManualKeyStore`（`ZCodeAuthProvider.swift`）：Quota Bar 自己独占的 `~/Library/Application Support/QuotaBar/zcode-api-key.json`，供没装官方 Z Code CLI、只想手动粘贴 key 的用户使用；`ZCodeAuthProvider.configPaths` 把它排在最前，复用现有 `flattenStrings`/`isLikelyAPIKey` 通用解析逻辑识别，不需要额外解析代码 #P1 — `ZCodeAuthProviderTests`：missing-by-default、save/read 掩码显示、拒绝空 key 三个新测试
- [x] [0.10.0-PM-A-016] 「偏好设置 → 模型」页新增「API Key 配置」区块（`APIKeyConfigRow`），MiniMax 和 Z Code 各一行：展示"已配置 · 掩码 key"/"未配置"状态 + "配置/重置"按钮，点开后是原生 `SettingsRow` 风格的输入框（复用 dropdown 已有的 `APIKeyTextField`）；交互参考 Zed 的 provider 设置页（用户提供截图），视觉不复刻、沿用本页其余行的 macOS 26 原生风格。同步删除 dropdown 里原来 MiniMax 专属的内联输入框 `MiniMaxKeyInputField`（连带贯穿 5 层 View 的整条 `onSaveKey` 回调链），入口统一收敛到 Preferences #P0
- [x] [0.10.0-ARCH-L-002] 新增 `.providerCredentialsDidChange` 通知：Preferences 里保存 API key 成功后 post，`RefreshCoordinator` 订阅并 `refreshNow()`，不用等自动刷新周期——跟 `.webAuthorizationWindowDidClose` 同一类"用户刚做完授权动作应该立刻看到结果"的诉求 #P1
- [x] [0.10.0-DOC-A-006] 全面核对 `ModelsSettingsView.providerAccessModes` 跟 `Strategies.swift` 实际 pipeline 是否一致（用户反馈"这一页应该如实显示我们支持的获取模式"）：Codex/Kimi 的 "CLI" 改成更准确的 "Config"（默认 pipeline 没有真实 CLI 子进程执行）；Claude/Antigravity 补上遗漏的 "Keychain"；MiniMax/Z Code 统一用 "API" 标注——现在这个词对应一个真实可操作的能力（上面新增的手动输入入口），不再只是描述性标签 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260708-111500-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260708-111500-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

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

#### 完成工作

- `WebAuthorizationController.swift`：新增 `ProviderKind.apiKeyCapableKinds`。
- `ZCodeAuthProvider.swift`：新增 `ZCodeManualKeyStore`（`currentKeyState`/`readAPIKey`/`save`），`configPaths` 默认值把它排最前。
- `PreferencesStore.swift`：新增 `.providerCredentialsDidChange` 通知。
- `RefreshCoordinator.swift`：订阅新通知触发 `refreshNow()`。
- `MenuView.swift`：`.needsConfiguration` 分支重写为三级判断；删除 `MiniMaxKeyInputField` 及整条 `onSaveKey` 回调链（`MenuView`/`LoadingStateView`/`ReadyStateView`/`PlanSection`/`DraggablePlanSection` 五处签名清理）。
- `StatusBarController.swift`：`MenuView` 构造调用同步移除 `onSaveKey` 参数。
- `Preferences/ModelsSettingsView.swift`：新增 `apiKeySection` + `APIKeyConfigRow`（服务 MiniMax/Z Code 两个 provider）；`providerAccessModes` 全面修正。
- `Tests/QuotaBarTests/ZCodeAuthProviderTests.swift`：新增 4 个 `ZCodeManualKeyStore` 相关测试（missing 默认态、save/read 掩码显示、拒绝空 key、`defaultConfigPath` 断言）。

新包：`macos/build/20260708-110708-main/Quota Bar.app`（`build/latest` 已指向）。

#### 更新的需求 ID

- `[0.10.0-BUG-A-017]` `[0.10.0-ARCH-L-000]` `[0.10.0-ARCH-L-001]` `[0.10.0-PM-A-016]` `[0.10.0-ARCH-L-002]` `[0.10.0-DOC-A-006]`

#### 验证方式

- `swift build`：增量与 `rm -rf .build` 全量重建均通过。
- `swift test`：186 tests in 42 suites 全部通过（+4 个新增的 `ZCodeManualKeyStore` 测试）。
- `./scripts/build-app.sh`：产包成功。
- **未做真实交互验证**：发现用户自己已经在跑一个更早的开发包实例（PID 23746，10:50 启动，大概率是测试上一轮改动），为避免干扰用户自己的测试会话，没有用 computer-use 工具打开新包点击验证。建议用户自己：(1) 检查 Antigravity/Z Code 现在是否显示"未获取到授权"而不是原始报错；(2) 去「偏好设置 → 模型」页确认新出现的「API Key 配置」区块，试一次给 Z Code 填一个假 key 看状态是否正确切到"已配置"；(3) 确认 MiniMax 原来 dropdown 里的输入框已经消失。

#### 备注

- 未提交 git commit。
- `ZCodeManualKeyStore.save`/`MiniMaxConfigProvider.save` 保存后立即调用 `NotificationCenter.default.post(name: .providerCredentialsDidChange, ...)`触发刷新，但没有对这条通知链路本身写自动化测试（`RefreshCoordinator`订阅逻辑用的是跟`.webAuthorizationWindowDidClose`完全一样的模式，判断复用现有代码路径的信心已经足够，没有为了测试覆盖率重复造轮子）。
- MiniMax 的 `MiniMaxConfigProvider.save`有一个既有限制（不是这次引入的）：要求`~/.mavis/config.yaml`**已经存在**且带`provider.minimax.options.apiKey`字段，不会从零创建这个文件/字段结构——如果用户从来没跑过真正的 mavis 工具，Preferences 里点"保存"会看到"config.yaml 缺少 provider.minimax.options.apiKey 字段（请手动添加）"这个既有报错。Z Code 那边因为是 Quota Bar 自己独占的新文件，没有这个限制。这个不对称目前保留，没有为了统一体验去改 MiniMax 那边已经在生产环境跑着的持久化逻辑。
