# 用户原始 prompt

>（截图：dropdown，opencode · Go 三条额度的右侧时间栏显示"重置于 5 小时..."/"重置于 3 天 22..."/"重置于 29 天 1..."，跟 Codex/Claude 的 "4h59m"/"4d0h"/"6d15h" 格式不一致）
>
> 可以看到额度但是描述不对，我们应该严格统一重制时间的文本描述 参考一下其他的模型用的描述方式，应该是类似xxdxxh这样

# 启动运行时的分支和版本

- 分支：`main`
- 版本：本轮基于上一轮（opencode Go 页解析器修复）未提交的工作树继续

# 任务开始时间

2026-07-09 09:48 +0800

# 任务结束时间

2026-07-09 09:52 +0800

# 任务结束时是否执行了提交

否——按惯例留给用户确认后再决定是否提交/推送。

# 已阅读上下文

- `QuotaModels.swift` 的 `QuotaResetText.description(for:relativeTo:)`（已存在的共享格式化函数，"XdXXh"/"XhXXm"/"XmXXs"）。
- `MiniMaxConfigProvider.swift`/`ZCodeAuthProvider.swift` 里 `refreshDescription` 的用法，确认全部 provider 统一走这个函数。
- `OpenCodeWorkspaceProvider.swift` 的 `fetchSnapshot`（上一轮写的）。

# 对话与行动记录

搜了一下 `refreshDescription` 在全部 provider 里的赋值方式，发现 MiniMax/Z Code 等都是 `QuotaResetText.description(for: resetsAt, relativeTo: now)`——一个早就存在的共享格式化函数，专门生成"XdXXh"/"XhXXm"这种紧凑格式。而我上一轮写的 `OpenCodeWorkspaceProvider` 直接把 opencode.ai 页面上的原文（"重置于 5 小时 0 分钟"这种 i18n 文案）塞进了 `refreshDescription`——这是个明显的疏漏：页面原文只应该是"给 `parseResetSeconds` 解析出 `resetsAt` 这个 Date"的输入，不应该直接展示给用户。

修复很直接：在构造 `QuotaWindow` 时，`refreshDescription` 改成用已经解析出的 `resetsAt` 调用 `QuotaResetText.description(for:relativeTo:)`；`resetsAt` 解析失败（极少数情况）时才 fallback 到页面原文，保证至少有点东西可看。

# 完成工作

- `OpenCodeWorkspaceProvider.swift`：`fetchSnapshot` 构造 `QuotaWindow` 时，`refreshDescription` 改用 `QuotaResetText.description(for: resetsAt, relativeTo: now)`，不再直接使用页面原文。

# 更新的需求 ID

- `[0.10.0-BUG-A-027]`

# 更新的 README 或 DESIGN 章节

- 无。

# 验证方式

- `swift build`：无警告无错误。
- `swift test`：195 tests in 44 suites 全部通过（`parseUsageItems`/`parseResetSeconds` 本身的解析逻辑没变，不需要改测试）。
- `./scripts/build-app.sh`：产包成功，重启本机实例，等一轮真实刷新后直接读 `~/Library/Application Support/QuotaBar/snapshots.json` 落盘结果确认：opencode 三条额度的 `refreshDescription` 分别是 `5h0m`/`3d22h`/`29d15h`，跟 Codex（`4h59m`）/Claude（`4h46m`）的格式完全一致。

# 备注

- 未提交 git commit。
- 这是个小疏漏，本该在上一轮实现时就注意到（其他 provider 都是这个惯例），这次是用户截图对比才发现。
