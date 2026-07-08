# 用户原始 prompt

> （前几轮：截图问 claude/antigravity 额度一会有一会没有；讨论后用户用中文重问一遍同一问题）
>
> （截图：偏好设置「通用」页显示"刷新间隔 1 分钟"，但同时打开的 dropdown 显示"自动刷新 5 分钟，上次更新 00:21"）
>
> 我发现刷新间隔改了不会同步真的生效

# 启动运行时的分支和版本

- 分支：`main`
- 版本：用户已通过 GitHub Desktop 提交了上一轮工作（`19e5e34 Unify versioning and update-checker to semver-only`），本轮在此基础上继续

# 任务开始时间

2026-07-08 00:22 +0800

# 任务结束时间

2026-07-08 00:27 +0800

# 任务结束时是否执行了提交

否——按惯例留给用户确认后再决定是否提交/推送。

# 已阅读上下文

- `RefreshCoordinator.swift`（`refreshInterval` 字段、`start()`/`stop()`/`runAutoRefreshLoop()`、`.quotaPreferencesDidChange` 订阅）。
- `PreferencesStore.swift`（`refreshIntervalSeconds`、`setRefreshInterval`、单例结构确认无注入点）。
- `StatusBarController.swift`（`RefreshCoordinator` 默认构造参数）。
- `GeneralSettingsView.swift`（刷新间隔 Picker 绑定）。

# 对话与行动记录

用户先贴了一段真实截图+日志问"为什么 claude、antigravity 额度一会有一会没有，日志里都是失败"，我排查后确认不是数据丢失 bug，而是刷新耗时导致的时序问题（详见上一条 agent-log），同时顺手修了一处日志误报（`logAttempt` 的 `onlyLayers` 过滤，已记 `0.10.0-BUG-A-011`）。

本轮用户用中文重问一遍同一问题（我用中文重新作答，内容不变），随后立刻贴出第二个独立问题：偏好设置「通用」页把刷新间隔设成了 1 分钟，但同时打开的 dropdown 底部仍然显示"自动刷新 5 分钟"——间隔改了没有真正生效。

排查 `grep -rn "refreshInterval"` 全仓库引用，发现这是一个**从未接通**的架构性 bug，不是这次改动引入的回归：

- `GeneralSettingsView` 的 Picker 绑定 `store.setRefreshInterval(...)`，正确写入 `PreferencesStore.preferences.refreshIntervalSeconds` 并 persist（`persist()` 会 post `.quotaPreferencesDidChange`，这条链路是通的）。
- 但 `RefreshCoordinator.refreshInterval`（自动刷新循环 `runAutoRefreshLoop()` 里 `Task.sleep` 真正读的字段，也是 dropdown「自动刷新 N 分钟」文案 `autoRefreshText` 读的同一个字段）是构造函数传入的**独立**值，跟偏好设置完全没有关联。
- 更严重的是：`StatusBarController.init` 里构造默认 `RefreshCoordinator(...)` 时压根没传 `refreshInterval` 参数，永远吃 `RefreshCoordinator` 构造函数自己的默认值 `5 * 60`——也就是说不仅"运行中改了不生效"，连**应用重启**都不会读取上次保存在 `preferences.json` 里的值。这个偏好设置从实现以来就是纯摆设。

修复两处：
1. `StatusBarController.init` 默认构造参数显式传入 `refreshInterval: PreferencesStore.shared.preferences.refreshIntervalSeconds`，让启动时真正读到上次保存的偏好。
2. `RefreshCoordinator` 的 `.quotaPreferencesDidChange` 订阅新增 `applyRefreshIntervalChange()`：比较偏好里的新值和当前 `refreshInterval`，不同就更新并重启自动刷新循环（`stop()` + `start()`），让新间隔立刻生效，不用等当前这轮 sleep 走完、也不用重启 app。

# 完成工作

- `macos/Sources/QuotaBar/StatusBarController.swift`：`RefreshCoordinator` 默认构造参数补上 `refreshInterval`。
- `macos/Sources/QuotaBar/RefreshCoordinator.swift`：新增 `applyRefreshIntervalChange()` 私有方法，接入 `.quotaPreferencesDidChange` 订阅。
- `REQUIREMENTS.md`：v0.10.0 phase 新增 `[0.10.0-BUG-A-012]`/`[0.10.0-BUG-A-013]`。

# 更新的需求 ID

- `[0.10.0-BUG-A-012]` `[0.10.0-BUG-A-013]`

# 更新的 README 或 DESIGN 章节

- 无。

# 验证方式

- `swift build`：无警告无错误。
- `swift test`：181 tests in 42 suites 全部通过（本轮未新增自动化测试，见下方备注说明原因）。
- 未做真实端到端验证（改完偏好设置后实际观察 dropdown 文案是否立刻变化、以及缩短间隔后是否真的提前触发下一轮刷新）——逻辑直接、改动小，但没有用真实打包 app 交互确认。

# 备注

- 未新增自动化测试：`PreferencesStore.shared` 是硬编码单例，直接读写用户真实的 `~/Library/Application Support/QuotaBar/preferences.json`，不像 `ProviderSourceIndexStore`/`ProviderCheckLogStore` 那样支持注入临时目录做测试隔离。强行写一个会 mutate 真实偏好文件的测试，会违反本次会话早前（Claude Keychain 那次）已经确立的"测试不能碰真实用户状态"原则。这属于 `PreferencesStore` 本身缺乏可测试性设计的既有问题，不在本次修复范围内展开重构。
- 未提交 git commit。
