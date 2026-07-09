# 用户原始 prompt

> opencode没获取到费用，但他现在只有1档（10刀）可以先写占位符固定住？（只要有订阅就是10刀，当然了还要记得做本地化换算）

# 启动运行时的分支和版本

- 分支：`main`
- 版本：本轮基于上一轮（API Key 配置行对齐修复）未提交的工作树继续

# 任务开始时间

2026-07-09 10:41 +0800

# 任务结束时间

2026-07-09 10:44 +0800

# 任务结束时是否执行了提交

否——按惯例留给用户确认后再决定是否提交/推送。

# 已阅读上下文

- `QuotaModels.swift` 的 `ProviderPricing`（`usdMonthlyPrice`/`localizedMonthlyPrice`/`format` 全文，确认本地化换算逻辑已经现成）。
- `OpenCodeWorkspaceProvider.swift` 里调用 `ProviderPricing.localizedMonthlyPrice(kind: .opencode, tier: "Go")` 的位置（`tier` 是硬编码字符串"Go"，不是从页面解析的）。

# 对话与行动记录

`ProviderPricing.usdMonthlyPrice` 是个按 `(kind, tier)` 查表的私有函数，其余 provider（Codex/Antigravity/Kimi/MiniMax/Claude）都在这张表里各自登记了美元价格，`localizedMonthlyPrice` 上层统一负责本地化（美元区直接显示、人民币区按 `ExchangeRateProvider` 实时汇率换算），这套换算逻辑已经是现成的、不需要为 opencode 单独写。之所以 opencode 一直显示"价格=未获取"，纯粹是因为这张表里从来没有 `.opencode` 的条目——`OpenCodeWorkspaceProvider` 虽然已经在调用这个函数，但表里查不到就直接返回 nil。

补一条 `(.opencode, "go") → 10` 就够了：`OpenCodeWorkspaceProvider` 传给这个函数的 `tier` 参数本来就是硬编码的字符串"Go"（不是从页面解析出来的档位名——因为 opencode Go 目前只有这一档，直接写死），补上价格表条目后，本地化换算是自动生效的，不需要额外代码。

# 完成工作

- `QuotaModels.swift`：`ProviderPricing.usdMonthlyPrice` 补上 `(.opencode, "go") → 10`，注释说明这是硬编码单档价格、以后 opencode 上线多档定价需要同步改成从页面解析。

# 更新的需求 ID

- `[0.10.0-DATA-B-021]`

# 更新的 README 或 DESIGN 章节

- 无。

# 验证方式

- `swift build`：无警告无错误。
- `swift test`：195 tests in 44 suites 全部通过（`ProviderPricing` 本身在这个项目里一直没有直接单测覆盖，这次补价格表条目也沿用了这个现状，没有新增测试）。
- `./scripts/build-app.sh`：产包成功，重启本机实例，等一轮真实刷新后直接读诊断日志确认：`opencode-webview：档位=Go，价格=¥68/月`（$10 按当前汇率换算，本地化逻辑确认生效）。

# 备注

- 未提交 git commit。
- 这是个纯粹的价格表补录，风险很低；唯一需要用户以后留意的点是：如果 opencode 官方上线第二档 Go 定价，这里写死的 $10 会变得不准确，需要改成从页面/API 解析真实价格而不是硬编码。
