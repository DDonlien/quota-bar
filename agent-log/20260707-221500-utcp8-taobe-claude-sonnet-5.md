# 用户原始 prompt

> （附截图：dropdown 显示 Codex/Claude 有真实额度，Antigravity 灰点、只有"备用：打开 WebView 授权"提示，没有任何额度条）
>
> （附一段真实诊断日志，Antigravity/Claude 两个 provider 的完整分层探测记录）
>
> 为什么我claude、antigravity额度一会有一会没有，日志里都是失败

# 启动运行时的分支和版本

- 分支：`main`
- 版本：本轮基于上一轮（更新检查纯版本号比较 + dropdown 隐藏按钮 + GLM/Z Code 关联修复）未提交的工作树继续

# 任务开始时间

2026-07-07 22:05 +0800

# 任务结束时间

2026-07-07 22:16 +0800

# 任务结束时是否执行了提交

否——按惯例留给用户确认后再决定是否提交/推送。

# 已阅读上下文

- 用户提供的真实日志片段（Antigravity/Claude 完整分层探测记录，含时间戳）。
- `ProviderFetchStrategy.swift` 全文（`runSequential`/`mergeLayers`/`logAttempt`/`missingLayers`）。
- `AntigravityCLISessionProvider.swift`（临时 agy 会话的建立/轮询逻辑）。
- `RefreshCoordinator.swift`（`applyProviderResult`/`enrichWithSubscriptionExpiry`/`runRefreshCycle` 的 streaming 更新机制）。
- `MenuView.swift`（`QuotaAuthPromptRow` 触发条件）。
- `Strategies.swift`（Antigravity pipeline 声明顺序）。

# 对话与行动记录

用户贴出真实日志和截图，问"为什么 claude、antigravity 额度一会有一会没有，日志里都是失败"。截图里 Antigravity 是灰点、没有任何额度条，只有"备用：打开 WebView 授权"；但同一段日志明确写着 `antigravity-cli-session` 成功拿到了 2 条额度窗口。这是一个值得认真排查的矛盾，而不是想当然地归因，所以先用一个 Explore 型 subagent 做只读排查（同时我自己也独立走读了一遍 `ProviderFetchStrategy.runSequential`/`mergeLayers` 的代码路径），双方结论一致：

**结论：不是数据被丢弃的 bug。** `mergeLayers`（`ProviderFetchStrategy.swift:278-311`）是纯追加逻辑——`var quotas = base.quotas` 后只往里 append，没有任何路径会清空已经拿到的 `quotas`；`runSequential` 的补层分支（100-121 行）里，后续来源失败只会走 `catch` 记录错误、`continue`，`merged` 本身不会被重新赋值成空。`enrichWithSubscriptionExpiry`（`RefreshCoordinator.swift:473-505`）失败时原样 `return snapshot`，也不会动 `quotas`。`MenuView.swift:381` 的 `QuotaAuthPromptRow` 纯粹由 `quotas.isEmpty` 触发。

**真正的解释是时序**：Antigravity 的 `antigravity-cli-session` 要现拉起一个临时 `agy` CLI 会话（`AntigravityCLISessionProvider`），等它的本地 RPC 就绪要经过 2 秒 settle + 0.7 秒轮询间隔的重试，日志显示这一步加上后续失败的 rpc/cli 尝试、再加上过期日 resolver，整轮跑下来接近 20 秒（22:04:29 → 22:04:48）——比 Codex/Kimi 这类直接读本地凭证文件的 provider 慢一个数量级。截图很可能是在这 20 秒窗口期间、`applyProviderResult` 还没把这次成功结果 apply 到 `state` 之前拍的，看到的是上一轮或本轮尚未完成前的旧状态（`runRefreshCycle` 第 3 步会把还没刷新完的行标成 `withStaleFlag(true)` 但保留旧数据，如果旧数据本身就是空额度，看起来就是"灰点+无额度"）。

Claude 的"时有时无"是另一类问题，不是显示 bug：日志里明确写着 `claude-oauth：Claude OAuth token 已过期，请重新 claude login`——这是真实的 token 过期，需要用户重新登录，不是代码逻辑问题；退化到 CLI（只给档位）+ WebView（只给额度）两层拼出完整结果，这次实际是成功拼出来了（截图里 Claude 是绿灯、有真实额度+Pro+¥136/月）。WebView 会话本身依赖 cookie 有效期和 SPA 渲染时机，也天然存在偶发失败的可能。

**但排查过程中确实揪出一个真实、值得修的问题**：`logAttempt`（`ProviderFetchStrategy.swift:215`）原来无条件按 `strategy.supportedLayers` 的全集记录日志，不管这一轮到底是为了补哪一层。分层合并阶段，`antigravity-rpc`/`antigravity-cli` 其实只是因为档位（plan）层还缺才被重新尝试——额度早就被 `antigravity-cli-session` 满足了——但它们失败时，日志会连带记一条「额度获取 | 失败」，跟额度层实际状态（早就成功了）矛盾。这正是用户"日志里都是失败"这种误导观感的直接来源之一：日志技术上没撒谎（这些来源确实"失败"了），但把"为什么失败"的语境（"只是为了补档位，跟额度无关"）弄丢了。

修复：`logAttempt` 新增 `onlyLayers` 参数，`runSequential` 的补层分支调用时传入 `missing`（本轮实际缺失、值得重试的层集合），日志只记录这次调用真正相关的层。首次尝试（`merged == nil`）不受影响——那时候确实是在为全部所需层探测，不需要过滤。

# 完成工作

- `macos/Sources/QuotaBar/ProviderFetchStrategy.swift`：`logAttempt` 新增可选 `onlyLayers` 参数；`runSequential` 补层分支的三处调用（成功/`QuotaFetchError`/其他 error）都传入 `missing`。
- `macos/Tests/QuotaBarTests/ProviderFetchStrategyTests.swift`：新增 `mergeBranchFailureOnlyLogsMissingLayer` 回归测试 + 两个专用 stub strategy（`QuotaOnlyStubStrategy`/`ThrowingBothLayersStubStrategy`），验证"额度已满足、后续来源只是为了补档位"场景下不会误报额度失败。
- `REQUIREMENTS.md`：v0.10.0 phase 新增 `[0.10.0-BUG-A-011]`。
- 未修改任何"额度获取本身"的逻辑——确认过这部分没有 bug，不做无必要的改动。

# 更新的需求 ID

- `[0.10.0-BUG-A-011]`

# 更新的 README 或 DESIGN 章节

- 无——纯诊断日志准确性修复，不影响用户可见的功能行为文档。

# 验证方式

- `swift build`：无警告无错误。
- `swift test`：181 tests in 42 suites 全部通过（含新增回归测试）。
- 未做真实端到端验证（比如真的用一台跑着 Antigravity 的机器触发一次刷新、掐着秒表在中途截图复现"灰点"状态）——时序解释在逻辑上自洽且与代码读取结果一致，但没有用真实产物重现那个具体的 20 秒窗口。

# 备注

- 未提交 git commit。
- 给用户的说明重点：(1) 额度数据本身没有被丢弃，是刷新过程中的时序造成截图看到了旧状态；(2) Claude 的 OAuth token 已过期，需要用户自己重新 `claude login` 才能让这条路径恢复；(3) 日志的"额度获取失败"误报已经修复，以后类似情况日志会更准确地反映"这次失败其实是为了补档位，跟额度无关"。
