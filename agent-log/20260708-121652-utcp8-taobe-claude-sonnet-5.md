# 用户原始 prompt

>（截图：dropdown，Antigravity 显示"未获取到授权"）
>
> 然后记住，除非我特别要求，否则总是用中文回答我。
>
> 另外，你自己看一下日志，现在 Antigravity 怎么可能是"未获取到授权"呢？
>
> 我现在应该是没有额度，因为我的订阅在今天已经过期了。但它不应该是"未获取到授权"，因为 literally 同样的代码，昨天你还能获取到授权。
>
> 检查一下是哪里出错了。
>
> dropdown的额度提示信息还是错误的，我给你完整整理一遍。
>
> 1. 任何途径获得了额度，就如实显示额度。
> 1.1. 如果非授权途径能获得额度信息，并且额度信息是明确的已经过期，那就显示未订阅或已过期，这个是可接受的，比如你现在的 MiniMax
>
> 2. 如果所有非授权途径（也就是除去 WebView 和 API，包括未来如果我们要做 FDA 或者 Cookie）都已经尝试了，但依然没有获取到额度，那就显示授权途径的提示。
>
> 授权途径的提示按照如下顺序优先展示：
> • 优先是 FDA（因为它是伤害性最小且一次性的）
> • 其次是 WebView
> • 其次是 API
>
> 当然，如果我们现在实际上没有 FDA，就不显示 FDA。
>
> 如果上一个授权形式完成了授权，但没有获取到额度，就提示下一个。
>
> 只有上述途径全都授权完了，才显示"未获取到授权"。也就是说，只有所有的途径都尝试完了，并且授权都是成功的（比如能得到确认的成功反馈，但就是没有额度），才能确定这个模型是不返回额度的，此时显示"没有额度信息"。
>
> 按照这个规则，首先我没有尝试 API，你就不应该 Antigravity 显示"未获取到授权"，我 code 也不应该显示"没有额度信息"。

# 启动运行时的分支和版本

- 分支：`main`
- 版本：本轮基于上一轮（claude-webview WKWebsiteDataStore 预热修复）未提交的工作树继续

# 任务开始时间

2026-07-08 12:07 +0800

# 任务结束时间

2026-07-08 12:17 +0800

# 任务结束时是否执行了提交

否——按惯例留给用户确认后再决定是否提交/推送。

# 已阅读上下文

- 真实诊断日志 `~/Library/Application Support/QuotaBar/provider-check.log`（Antigravity 段，11:58–12:08）。
- `AntigravityDashboardProvider.swift`（HTTP 500 → `QuotaFetchError` 映射）、`BrowserCookieProvider.swift`（missingCredentials vs transient 的区分）。
- `QuotaModels.swift`（`ProviderAvailability`/`QuotaFetchError`/`fallbackPriority` 全文）。
- `RefreshCoordinator.swift` 的 `applyProviderResult`/`availabilityFallback` 全文。
- `MenuView.swift` 的 `PlanSection`/`PlanHeader`/`QuotaAuthPromptRow` 全文。
- `WebAuthorizationController.swift`（`webViewQuotaCapableKinds`/`apiKeyCapableKinds`）。
- `OpenCodeAuthProvider.swift`（opencode "暂无额度数据" 现状展示的真实来源）。

# 对话与行动记录

先记了一条 feedback 记忆："除非用户特别要求，否则总是用中文回答"。

然后直接查真实日志确认 Antigravity 当前的真实失败原因：`antigravity-cli`/`antigravity-cli-session` 持续返回 HTTP 500（`GetCascadeModelConfigData() is nil`），`antigravity-rpc` 返回"IDE 未运行或未激活 workspace"。追到 `AntigravityDashboardProvider.swift:284`，HTTP 500 被映射成 `QuotaFetchError.transient`（不是一个明确的"订阅已过期"信号——跟用户规则 1.1 的"额度信息明确已过期"标准不符，这只是一个含糊的服务端错误）。再追到 `RefreshCoordinator.swift:506-507`，`.transient` 在 provider 已检测安装的情况下统一映射成 `.needsConfiguration`。最后到 `MenuView.swift` 的 `.needsConfiguration` 分支：此前对"既不支持 API Key 也不支持 WebView 额度"的 provider 一律展示"未获取到授权"——但 Antigravity 两者都不支持（WebView 登录窗口只服务到期日抓取，这是本轮会话更早之前就核实过的），也没有 FDA，根本没有任何授权补救动作可以提示，"未获取到授权"是个兑现不了的承诺，跟用户说的"同样的代码昨天还能获取到授权"完全对得上——不是回归，是这个分支的 else 兜底文案从一开始就选错了。

顺手确认了 opencode 现有的"暂无额度数据"文案其实已经是这套规则的一个雏形实现（`OpenCodeAuthProvider` 确认没有额度接口时返回 `.available` + 空 quotas，`QuotaAuthPromptRow` 判断不支持 WebView 就展示这句诚实文案）——只是这个雏形只覆盖了 `.available`+空 quotas 这一个 availability 分支，`.needsConfiguration` 分支是另一套独立、更旧的三级判断逻辑，两边没有共享同一套优先级规则，而且 `QuotaAuthPromptRow` 压根没考虑过 API Key tier（只判断 WebView），MiniMax 如果落到这个分支会静默漏掉 API 引导。同时发现 `.needsConfiguration` 分支原有的 if/else 顺序是"先判断 API Key，再判断 WebView"——跟用户这次明确的"WebView 优先于 API"顺序刚好反了。

# 完成工作

- `WebAuthorizationController.swift`：新增 `ProviderKind.AuthRemediationTier`（`.webView`/`.apiKey`，FDA 未实现不建模）和 `availableAuthRemediationTiers` 计算属性，按 FDA > WebView > API 优先级排好序，只包含这个 provider 真正支持的 tier。
- `MenuView.swift`：
  - `.needsConfiguration` 分支改用 `availableAuthRemediationTiers.first` 做 switch：`.webView` → 「打开 WebView 授权」按钮；`.apiKey` → 灰字指向 Preferences；`nil`（一个 tier 都不支持）→ 「暂无额度数据」（不再是「未获取到授权」）。
  - `QuotaAuthPromptRow` 同步改成同一套 `availableAuthRemediationTiers` 判断（之前只判断 WebView，现在也会展示 API Key 引导），保证同一个 provider 不会因为落在 `.available`+空 quotas 还是 `.needsConfiguration` 两个不同 availability 分支而展示不一致的文案。
- `REQUIREMENTS.md`：新增 `[0.10.0-BUG-A-020]`（Antigravity 误报根因）、`[0.10.0-ARCH-L-003]`（`availableAuthRemediationTiers` + 两处调用点统一）、`[0.10.0-INVESTIGATE-A-004]`（顺手发现的测试污染真实日志文件问题，已用 `spawn_task` 单独派发，不在本轮修复）。
- 用 `spawn_task` 派发了一个独立后台任务（`task_9a5b6e04`）：`swift test` 时 `ProviderFetchStrategyTests.swift` 的 stub（"quota-source"/"plan-filler"）没有给 `ProviderCheckLog` 注入独立临时文件，写穿了真实用户机器的 `provider-check.log`——排查 Antigravity 问题时在真实日志里翻到了这两条测试噪音数据，跟当前任务无关，先记下来单独处理。

新包：`macos/build/20260708-121652-main/Quota Bar.app`（`build/latest` 已指向）。

# 更新的需求 ID

- `[0.10.0-BUG-A-020]` `[0.10.0-ARCH-L-003]` `[0.10.0-INVESTIGATE-A-004]`

# 更新的 README 或 DESIGN 章节

- 无。

# 验证方式

- `swift build`：无警告无错误。
- `swift test`：186 tests in 42 suites 全部通过（本轮未新增/删除测试——纯 UI 文案/优先级判断改动，行为需要用户在真实环境里用刚才打的包重新验证 Antigravity 的展示是否变成"暂无额度数据"）。
- `./scripts/build-app.sh`：产包成功。

# 备注

- 未提交 git commit。
- 范围说明：本轮只实现了"按 FDA > WebView > API 优先级展示第一个这个 provider 真正支持的 tier"，没有实现用户规则里更细的一层——"如果优先级更高的 tier（比如 WebView）已经确认完成授权，但还是拿不到额度，就自动展示下一个 tier（比如 API）的引导"。这需要单独追踪"每个 tier 是否已经完成授权"的状态（目前 `QuotaFetchError`/`ProviderAvailability` 的错误分类还没有为此建模——`missingCredentials` vs `transient` 已经能区分"没登录"和"登录了但请求失败"，但还没有把这个信号一路传到 UI 层做 tier 升级判断），如果用户之后遇到"WebView 明明登录了但还是没有 API 引导"这类情况，需要再单独扩展。
- 已知这次没处理的具体点：MiniMax 目前是唯一同时具备 WebView 和 API 两个 tier 的 provider，这次改动让它在 `.needsConfiguration`/空 quotas 分支下默认优先展示 WebView 引导（而不是像之前一样固定展示 API 引导）——如果用户实际使用习惯是"更喜欢直接填 API Key，不想开 WebView 登录"，可能需要反馈调整（但这是用户本轮明确给出的优先级规则，按规则实现的默认行为）。
