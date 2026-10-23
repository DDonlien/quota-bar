# sub/main: 授权 tier 完成度判断落地 + 已授权时隐藏虚假 WebView 引导

- ID：`0.10.0-INVESTIGATE-A-005`。
- 类型：`API`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 授权 tier 完成度判断落地 + 已授权时隐藏虚假 WebView 引导。
- 原稳定 ID：`0.10.0-INVESTIGATE-A-005`, `0.10.0-BUG-A-024`, `0.10.0-BUG-A-025`, `0.10.0-INVESTIGATE-A-006`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户反馈两点：opencode 粘贴 API Key 后"无事发生"（key 实际保存成功、Preferences 里也显示已配置，但 dropdown 依然提示"在 Preferences 中通过 API Key 授权"）；"webview还是不行，登陆了根本检测不到"（Claude WebView 已登录，dropdown header 仍显示"打开 WebView 授权"）。

- [x] [0.10.0-INVESTIGATE-A-005] 先读真实诊断日志核实"webview 检测不到"：00:33 起**每一轮**都是 `claude-webview：获取到 2 条额度窗口 | 成功`——`0.10.0-BUG-A-019` 的预热修复实际已生效，dropdown 里 Claude 的 89%/29% 额度正是 WebView 会话取到的（statusline/oauth 限流/CLI 同轮全部失败）。真正失败的是过期日层：`claude-billing-settings-page：页面里未提取出日期`（登录态有效、页面能加载，但 DOM 里解析不出日期）。用户看到的"打开 WebView 授权"是 `PlanHeader.canOfferWebAuthorizationForDate` 在日期缺失时的引导——已登录的用户再点一次也不会有任何新结果，这个虚假引导正是"检测不到"错觉的来源（下条修复）#P0
- [x] [0.10.0-BUG-A-024] 落地此前 `0.10.0-ARCH-L-003` 明确留白的"tier 完成度"判断：新增 `ProviderKind.manualAPIKeyIsConfigured`（各 kind 读各自 key 存储，占位符不算）和 `firstPendingAuthRemediationTier()`（按 FDA > WebView > API 优先级返回第一个**还没完成授权**的 tier；`.webView` 已完成 = App WebView 会话存储有该 provider dashboard 域的 Cookie，`.apiKey` 已完成 = 手动 key 已真实配置；全部完成或没有任何 tier 返回 nil）。`MenuView` 的 `.needsConfiguration` 分支抽成 `NeedsConfigurationRow`、`QuotaAuthPromptRow` 一并改用这个异步判断（初值用静态能力列表第一项避免闪烁，`.task(id: fetchedAt)` 每轮刷新后重判）：待完成 tier 是 `.webView` → 授权按钮，`.apiKey` → 灰字指 Preferences，nil → 终态"暂无额度数据"。opencode 配好 key 后现在正确显示终态文案 #P0
- [x] [0.10.0-BUG-A-025] `PlanHeader` 的两处"打开 WebView 授权"引导（`missingTierNeedsAuth` 档位缺失、`canOfferWebAuthorizationForDate` 日期缺失）都加上 `!webViewSessionAuthorized` 条件（`.task(id: fetchedAt)` 异步查 `appSessionHasCookies`，初值 false——未知时宁可多显示引导也不隐藏真正需要的入口）：已登录的 provider 不再展示一个已经兑现过的授权承诺，Claude 现在 header 右侧只显示价格、不再有误导性的授权链接 #P0
- [x] [0.10.0-INVESTIGATE-A-006] claude.ai 账单/设置页的订阅到期日提取持续失败（"页面里未提取出日期"）——用户澄清根因：**iOS（Apple 内购）订阅的到期日只在 Apple 侧可见，claude.ai 网页上根本不存在这个数据**，提取不出来是数据不存在而非解析 bug。结论：(1) 隐藏兜底已到位（`0.10.0-BUG-A-025`：已授权时不显示假引导，日期一栏留空）；(2) 直接付款（网页 Stripe）用户的提取路径保留 `ClaudeHarvester` 不动，等有直接付款账号的真实样本再验证其选择器是否有效 #P2

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260709-004301-utcp8-taobe-claude-fable-5.md — 历史证据迁移

来源：`agent-log/20260709-004301-utcp8-taobe-claude-fable-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

>（截图1：Preferences「模型」页，opencode 行显示 `sk-v73B9···tt4P（重新输入会覆盖）` + dropdown 里 opencode · Go 下方仍显示"在 Preferences 中通过 API Key 授权"）
>（截图2：Claude WebView 授权窗口，claude.ai 已登录显示聊天界面；dropdown 里 Claude · Pro 右侧仍显示"打开 WebView 授权"）
>
> 输入了无事发生啊，key如下：sk-v73B9...（67 位真实 key）
>
> 另外webview还是不行，登陆了根本检测不到，都不说检测到以后的信息获取了

#### 完成工作

- `WebAuthorizationController.swift`：新增 `ProviderKind.manualAPIKeyIsConfigured` + `firstPendingAuthRemediationTier()`。
- `MenuView.swift`：`.needsConfiguration` 分支抽成 `NeedsConfigurationRow`（含 tier 异步判定）；`QuotaAuthPromptRow` 同步改造（新增 `fetchedAt` 参数）；`PlanHeader` 新增 `webViewSessionAuthorized` gate。
- `REQUIREMENTS.md`：`[0.10.0-INVESTIGATE-A-005]`（日志核实）、`[0.10.0-BUG-A-024]`（tier 完成度）、`[0.10.0-BUG-A-025]`（虚假引导）、`[ ] [0.10.0-INVESTIGATE-A-006]`（日期提取待办）。

新包：`macos/build/20260709-004301-main/Quota Bar.app`（`build/latest` 已指向），已重启本机开发态实例。

#### 更新的需求 ID

- `[0.10.0-INVESTIGATE-A-005]` `[0.10.0-BUG-A-024]` `[0.10.0-BUG-A-025]` `[0.10.0-INVESTIGATE-A-006]`（未完成待办）

#### 验证方式

- `swift build`：无警告无错误。
- `swift test`：190 tests in 43 suites 全部通过。
- `./scripts/build-app.sh`：产包成功，已重启实例。
- 日志核实（本轮的关键证据来源）：`provider-check.log` 00:33–00:35 三轮完整记录，claude-webview 额度层全部成功、日期层全部失败于 DOM 提取。

#### 备注

- 未提交 git commit。
- 请用户验证两点：(1) dropdown 里 opencode 现在应显示"暂无额度数据"而不是 API Key 引导；(2) Claude header 右侧应只有 ¥136/月、无"打开 WebView 授权"链接。
- 上一轮的崩溃修复（`WebKitSessionWarmup` 挂真实窗口）到目前没有再出现新的 `.ips` 崩溃报告，暂时视为有效，继续观察。
