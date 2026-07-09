# 用户原始 prompt

>（截图1：Preferences「模型」页，opencode 行显示 `sk-v73B9···tt4P（重新输入会覆盖）` + dropdown 里 opencode · Go 下方仍显示"在 Preferences 中通过 API Key 授权"）
>（截图2：Claude WebView 授权窗口，claude.ai 已登录显示聊天界面；dropdown 里 Claude · Pro 右侧仍显示"打开 WebView 授权"）
>
> 输入了无事发生啊，key如下：sk-v73B9...（67 位真实 key）
>
> 另外webview还是不行，登陆了根本检测不到，都不说检测到以后的信息获取了

# 启动运行时的分支和版本

- 分支：`main`
- 版本：本轮基于上一轮（WebKit 崩溃修复 + 原生 TextField）未提交的工作树继续

# 任务开始时间

2026-07-09 00:36 +0800

# 任务结束时间

2026-07-09 00:45 +0800

# 任务结束时是否执行了提交

否——按惯例留给用户确认后再决定是否提交/推送。

# 已阅读上下文

- `~/Library/Application Support/QuotaBar/provider-check.log`（Claude/opencode 00:33–00:35 三轮真实日志）。
- `~/Library/Application Support/QuotaBar/opencode-api-key.json`（确认 key 已保存，67 位）。
- `MenuView.swift`（`PlanSection`/`PlanHeader`/`QuotaAuthPromptRow`）、`WebAuthorizationController.swift`（tier 声明）、`MiniMaxConfigProvider.currentKeyState` 签名。

# 对话与行动记录

先读真实日志核实用户的两个判断，结果都跟表象不同：

**"webview 登录了检测不到"——检测其实已经通了**。00:33 起每一轮都是 `claude-webview：获取到 2 条额度窗口 | 成功`，昨天的 `WebKitSessionWarmup` 预热修复实际生效了；dropdown 里 Claude 那 89%/29% 的额度就是 WebView 会话取到的（同轮里 statusline 没缓存、oauth 限流、CLI 只有档位，webview 是唯一成功的额度来源）。真正失败的是**过期日**层：`claude-billing-settings-page：页面里未提取出日期`——登录态有效、页面能加载，但 harvester 从 claude.ai 账单页 DOM 里解析不出日期。而 `PlanHeader.canOfferWebAuthorizationForDate` 在"日期缺失 + 支持 headlessDOM"时会显示"打开 WebView 授权"——对一个已经登录的用户来说这是个已经兑现过的承诺，再点一次不会有任何新结果，正是这个虚假引导让用户以为"登录根本没被检测到"。

**opencode "无事发生"——key 保存成功了，是提示逻辑没跟上**。`opencode-api-key.json` 里 67 位 key 完整保存、Preferences 也正确显示掩码；但 dropdown 的 `QuotaAuthPromptRow` 只看"这个 provider 支不支持 API tier"，不看"这个 tier 是否已经完成"——这正是 `0.10.0-ARCH-L-003` 当时明确写了"没有实现 tier 升级判断"的那个留白，用户这次实测精确命中。

两个修复：

1. **tier 完成度判断**：`ProviderKind` 新增 `manualAPIKeyIsConfigured`（各 kind 读各自 key 存储，MiniMax 的占位符状态不算已配置）和 `firstPendingAuthRemediationTier()`——按 FDA > WebView > API 优先级返回第一个还没完成授权的 tier；`.webView` 已完成 = WebView 会话存储里有该 provider dashboard 域的 Cookie（跟 `claude-webview` 策略判断"已登录"同一个检查）；全部完成或没有任何 tier 返回 nil。`MenuView` 的 `.needsConfiguration` 分支抽成独立的 `NeedsConfigurationRow`（顺便把只剩它在用的 `webAuthorizationTitle` 一起搬过去），和 `QuotaAuthPromptRow` 统一改用这个异步判断：初值用静态能力列表第一项（避免闪烁），`.task(id: fetchedAt)` 在每轮刷新后重新判定（保存 key 触发的 `.providerCredentialsDidChange` 刷新会带来新的 fetchedAt）。opencode 现在配好 key 后显示终态"暂无额度数据"。

2. **已授权时隐藏虚假引导**：`PlanHeader` 新增 `webViewSessionAuthorized` 状态（`.task` 异步查 `appSessionHasCookies`，初值 false——未知时宁可多显示引导，也不隐藏一个真正需要的入口），`missingTierNeedsAuth` 和 `canOfferWebAuthorizationForDate` 都加上 `!webViewSessionAuthorized`。Claude 现在 header 右侧只显示价格，不再有误导性的"打开 WebView 授权"。

**没修的**：claude.ai 账单页的日期提取失败是真实的解析问题（选择器/路由可能过时），需要拿到真实页面 DOM 单独排查，记为 `[0.10.0-INVESTIGATE-A-006]` 待办——修好之前 Claude 的日期一栏按现有规则留空。

# 完成工作

- `WebAuthorizationController.swift`：新增 `ProviderKind.manualAPIKeyIsConfigured` + `firstPendingAuthRemediationTier()`。
- `MenuView.swift`：`.needsConfiguration` 分支抽成 `NeedsConfigurationRow`（含 tier 异步判定）；`QuotaAuthPromptRow` 同步改造（新增 `fetchedAt` 参数）；`PlanHeader` 新增 `webViewSessionAuthorized` gate。
- `REQUIREMENTS.md`：`[0.10.0-INVESTIGATE-A-005]`（日志核实）、`[0.10.0-BUG-A-024]`（tier 完成度）、`[0.10.0-BUG-A-025]`（虚假引导）、`[ ] [0.10.0-INVESTIGATE-A-006]`（日期提取待办）。

新包：`macos/build/20260709-004301-main/Quota Bar.app`（`build/latest` 已指向），已重启本机开发态实例。

# 更新的需求 ID

- `[0.10.0-INVESTIGATE-A-005]` `[0.10.0-BUG-A-024]` `[0.10.0-BUG-A-025]` `[0.10.0-INVESTIGATE-A-006]`（未完成待办）

# 更新的 README 或 DESIGN 章节

- 无。

# 验证方式

- `swift build`：无警告无错误。
- `swift test`：190 tests in 43 suites 全部通过。
- `./scripts/build-app.sh`：产包成功，已重启实例。
- 日志核实（本轮的关键证据来源）：`provider-check.log` 00:33–00:35 三轮完整记录，claude-webview 额度层全部成功、日期层全部失败于 DOM 提取。

# 备注

- 未提交 git commit。
- 请用户验证两点：(1) dropdown 里 opencode 现在应显示"暂无额度数据"而不是 API Key 引导；(2) Claude header 右侧应只有 ¥136/月、无"打开 WebView 授权"链接。
- 上一轮的崩溃修复（`WebKitSessionWarmup` 挂真实窗口）到目前没有再出现新的 `.ips` 崩溃报告，暂时视为有效，继续观察。
