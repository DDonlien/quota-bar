# 用户原始 prompt

> 检查并确保所有其他 provider 的类似问题都解决；然后提交

# 启动运行时的分支和版本

- 分支：`main`（工作目录 `/Users/taobe/Projects/GitHub/Personal/quota-bar/quota-bar_main`）
- 起始提交：`24b54ae`（fix: pin login item to installed app bundle）
- `VERSION`：0.11.0
- 工作区含上一任务（Claude 订阅过期识别，`0.10.0-DATA-B-005`）未提交改动

# 任务开始时间

2026-08-08 22:38 +0800（约）

# 任务结束时间

2026-08-08 22:46 +0800（提交后）

# 任务结束时是否执行了提交

是——一次提交包含本任务改动 + 上一任务（Claude 订阅过期识别）改动。

# 已阅读上下文

- 上一任务日志 `agent-log/20260808-223737-utcp8-taobe-deepseek-v4-flash.md`
- `ProviderFetchStrategy.swift`（`runSequential` 串行管线 + `mergeLayers`）
- `Strategies.swift`（全部 provider pipeline 声明与顺序）
- `OpenCodeWorkspaceProvider.swift`、`OpenCodeAuthProvider.swift`
- `KimiDesktopTokenProvider.swift`、`KimiSubscriptionParser`（DashboardEndpoints.swift）、`KimiSubscriptionParserBalancesTests.swift`、`KimiDesktopTokenProviderTests.swift`
- `AntigravityDashboardProvider.swift`、`AntigravityCLISessionProvider.swift`、`KimiHarvester.swift`、`ZCodeAuthProvider.swift`
- 用户机器真实状态：snapshots.json（kimi 有效期 2026-08-15、opencode Go 正常、codex 周窗口正常）与 Kimi 真实响应夹具（`"subscribed": true`、`"status": "SUBSCRIPTION_STATUS_ACTIVE"` 顶层字段确认存在）

# 对话与行动记录

1. **逐 provider 审计**（同类问题 = 订阅过期但显示误导性额度/不显示过期状态）：
   - Codex ✅ 已覆盖（id_token inspector + `plan_type == "free"` parser 防御，v0.8.0）
   - MiniMax ✅ 已覆盖（`indicatesNoActiveSubscription` → notSubscribed，v0.10.0-DATA-B-004）
   - Claude ✅ 上一任务刚覆盖
   - opencode ⚠️ 推广页判定存在但**抛错**——`opencode-auth` 的 tier-only 成功先占住基底后，抛错的 notSubscribed 被管线吞掉，UI 退回「授权获取额度」而不是过期状态 → 修
   - Kimi ⚠️ 无任何过期识别 → 修
   - Antigravity ⚠️ 无可靠信号（`planStatus` 字段含义无真实过期样本可验证）→ 登记后续，不改
   - Cursor（无额度管线，仅过期日 harvester）、Z Code/GLM/Trae（API Key/Keychain，无订阅概念）→ 不适用
2. **系统性根因**：`FetchPipeline.mergeLayers` 对后续来源返回的 `.notSubscribed`/`.subscriptionExpired` marker 静默丢弃（`guard addition.availability == .available else { return base }`）——只要管线里**先**有一个 tier-only「已配置」来源成功（Claude 的 cli、opencode 的 auth），后到的服务端权威 marker 就永远不生效。改成 marker 优先：采用 marker 的 availability、丢弃 base 可能误导的额度窗口、保留 base 已知档位/价格/到期日供 header 展示。这条修复同时让「Claude CLI 已登录 + 订阅过期」场景正确（webview marker 不再被 cli tier-only 基底吞掉）。
3. **opencode**：`OpenCodeWorkspaceProvider` Go 推广页从 throw 改为返回 `.notSubscribed` marker snapshot（对齐 MiniMax/Claude 模式）。
4. **Kimi**：真实响应夹具暴露顶层 `subscribed` 布尔与 `status` 字符串——用服务端显式布尔做权威信号（`subscribed == false` → 无有效订阅；`== true` → 有效，不再看日期），`subscribed` 缺失时退而求其次用「`nextBillingTime` 已过 → 周期结束未续费」；`KimiDesktopTokenProvider` 与 `BrowserCookieProvider` Kimi 路径返回 marker。`parseDate` 顺手改 static（被 static 方法调用）。
5. **验证**：新增 8 条测试（mergeLayers marker 传播 ×2、管线级 marker 短路 ×1、Kimi parser 判定 ×4、Kimi desktop token marker ×1），全量 `swift test` 273 条通过。

# 完成工作

- `macos/Sources/QuotaBar/ProviderFetchStrategy.swift`：`mergeLayers` 对 `.subscriptionExpired`/`.notSubscribed` addition 返回 marker 合并结果（availability 用 addition、quotas 清空、tier/price/expiresAt 保留 base 值）。
- `macos/Sources/QuotaBar/OpenCodeWorkspaceProvider.swift`：Go 推广页（无订阅）改返回 `.notSubscribed` marker。
- `macos/Sources/QuotaBar/DashboardEndpoints.swift`：`KimiSubscriptionParser.indicatesNoActivePlan(data:now:)`（`subscribed == false` 优先，`nextBillingTime` 已过兜底）；`parseDate` 改 static。
- `macos/Sources/QuotaBar/KimiDesktopTokenProvider.swift`：GetSubscription 响应命中信号 → 返回 `.notSubscribed` marker。
- `macos/Sources/QuotaBar/BrowserCookieProvider.swift`：Kimi webview 路径同一检查。
- 测试：`FetchPipelineLayeredMergeTests`（marker 传播 ×2 + 管线级 ×1 + stub 改造）、`KimiSubscriptionParserBalancesTests`（判定 ×4）、`KimiDesktopTokenProviderTests`（marker ×1）。
- `REQUIREMENTS.md`：`0.10.0-DATA-B-006` 登记完成（审计结论 + 三处修复 + Antigravity 后续登记）。
- 提交 `git commit`（工作区全部改动，含上一任务）。

# 更新的需求 ID

- [x] `0.10.0-DATA-B-006`（新增：其余 provider 同类问题审计 + mergeLayers marker 传播 + opencode/Kimi 修复）
- 上一任务的 `0.10.0-DATA-B-005` 随提交一并合入

# 更新的 README 或 DESIGN 章节

无。

# 验证方式

- `cd macos && swift test`：273 条全过（上一任务 265 + 本任务新增 8）。
- 行为推演：Claude「CLI 已登录 + 订阅过期」→ cli tier-only 基底 + webview marker → mergeLayers 覆盖为 notSubscribed（保留 Pro/价格）；opencode 无订阅 → auth tier-only + webview marker → notSubscribed；Kimi 过期 → desktop/webview 返回 marker 短路；Kimi 有效（用户当前状态）→ `subscribed: true` → 不受影响。

# 备注

- Antigravity 过期识别维持现状：`GetUserStatus.planStatus.planInfo` 只确认 planName 字段，无真实过期响应样本可验证判定边界，登记为 `0.10.0-DATA-B-001`/`-006` 的后续工作（README 矩阵里对应格本就是「待验证」）。
- Kimi 的 `status` 字符串字段（`SUBSCRIPTION_STATUS_ACTIVE`）未用作判定——未知取值集合，布尔 + 日期两个信号已足够；未来若发现 `subscribed` 对试用账号语义不同再回来修正。
- 提交信息：`fix: 统一订阅过期识别——mergeLayers 传播 notSubscribed marker + opencode/Kimi 补漏`（实际以 `git log` 为准）。
