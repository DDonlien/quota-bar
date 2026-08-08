# 用户原始 prompt

> 有问题啊，我发现现在订阅过期了的 claude 是刷不出订阅过期这个信息的，看起来还是全额度重置时间未知

# 启动运行时的分支和版本

- 分支：`main`（工作目录 `/Users/taobe/Projects/GitHub/Personal/quota-bar/quota-bar_main`）
- 起始提交：`24b54ae`（fix: pin login item to installed app bundle）
- `VERSION`：0.11.0

# 任务开始时间

2026-08-08 22:00 +0800（约）

# 任务结束时间

2026-08-08 22:37 +0800

# 任务结束时是否执行了提交

否——只改了工作区文件，未提交（用户未要求提交）。

# 已阅读上下文

- `REQUIREMENTS.md`（v0.10.0「订阅过期识别与免费额度误判修正」phase 及开放 TODO `0.10.0-DATA-B-000/001/002/003`、`QA-B-000`）
- `AGENTS.md`（任务日志与 REQUIREMENTS 维护规范）
- `QuotaModels.swift`（`.subscriptionExpired` / `.notSubscribed` availability 语义与 UI 分支）
- `RefreshCoordinator.swift`（过期日 enrichment、applyProviderResult、fallback 优先级）
- `ProviderFetchStrategy.swift`（`runSequential` 串行管线：非 `.available` marker snapshot 直接短路返回）
- `DashboardEndpoints.swift`（`ClaudeUsageWindowParser` / `ClaudeDashboardParser`）
- `BrowserCookieProvider.swift`（webview 路径 `claude-webview`）
- `ClaudeOAuthUsageProvider.swift`、`ClaudeStatusLineUsageProvider.swift`、`ClaudeStatusLineHookInstaller.swift`
- `MiniMaxCLIProvider.swift` / `MiniMaxConfigProvider.swift`（`.notSubscribed` marker 既有先例）
- 用户机器真实数据：`~/Library/Application Support/QuotaBar/snapshots.json`（Claude 两条窗口 `refreshDescription: "重置时间未知"`、`sourceId: claude-webview`）、`provider-check.log`（`claude-billing-settings-page：页面里未提取出日期或档位`）、`~/.vibe-island/cache/rl.json`（订阅有效时期窗口带 resets_at 的真实样本）

# 对话与行动记录

1. **定位**：用户真实数据确认——订阅过期后 `claude-webview`（`organizations/{id}/usage`）返回的 `five_hour`/`seven_day` 窗口只剩 `utilization`（0% 用量 → 满额度条）、`resets_at` 全为 null，dropdown 显示「重置时间未知」；`claude-billing-settings-page` headless 抓取页面能加载但提取不出日期/档位（过期页没有 Next billing 文案）。`subscriptionExpired` 判定此前只有 Codex（id_token JWT claims）落地，Claude 无任何过期识别——正是 `0.10.0-DATA-B-001` 开放 TODO 里登记的部分。
2. **信号选择**：Anthropic usage 响应「窗口在、所有 resets_at 全 null」= 无有效订阅的服务端权威信号。对照有效订阅时期的真实 rl.json（2026-07-15，窗口带 resets_at）与项目全部测试夹具交叉验证。不用 billing 页 DOM 判定过期——2026-07-10 已实测过有效订阅用户的账单页也提取不出日期（SPA 渲染时序问题），不可靠。
3. **落地方式**：跟随 MiniMax/Codex 既有模式——provider 返回 `.notSubscribed` marker snapshot（不是抛错），`runSequential` 对非 `.available` snapshot 直接短路，杜绝「CLI 档位层 available 优先级压过 notSubscribed」这类覆盖问题。覆盖 Claude 三个额度路径：webview（`ClaudeDashboardParser.indicatesNoActivePlan` 经 `DashboardParser` 协议默认方法接入 `BrowserCookieProvider`）、OAuth（`ClaudeOAuthUsageProvider`）、statusLine 缓存（只认显式 `"resets_at": null`，键缺失是历史容忍形态不推断，防误伤）。
4. **验证**：`swift test` 全量 265 条通过（新增 8 条：ClaudeDashboardParser 四分支、OAuth marker、statusLine marker ×2 + indicatesNoActivePlan 判定）。

# 完成工作

- `macos/Sources/QuotaBar/DashboardEndpoints.swift`：
  - `DashboardParser` 协议 + 默认扩展新增 `indicatesNoActivePlan(data:)`（默认 false）；
  - `ClaudeUsageWindowParser.indicatesNoActivePlan(data:)`：已知窗口键（five_hour/seven_day/seven_day_sonnet/seven_day_opus，null 值键不算存在）有窗口但全部 `resets_at` 解析为 nil → 无有效订阅；一个窗口都没有返回 false（schema 变化不误判）；
  - `ClaudeDashboardParser` 实现该协议方法。
- `macos/Sources/QuotaBar/BrowserCookieProvider.swift`：`fetchSnapshotImpl` 解析出窗口后检查 `parser.indicatesNoActivePlan`，命中返回 `.notSubscribed` marker snapshot。
- `macos/Sources/QuotaBar/ClaudeOAuthUsageProvider.swift`：OAuth usage 响应命中同一信号时返回 `.notSubscribed` marker。
- `macos/Sources/QuotaBar/ClaudeStatusLineUsageProvider.swift`：`indicatesNoActivePlan(_:)`（仅显式 `NSNull` 判定）+ `fetchSnapshot` 命中时返回 marker。
- 测试：`ClaudeDashboardParserTests`（expired 全缺失 → true 且窗口仍可解析、任一窗口带 resets_at → false、无窗口 → false、全 null 键 → false）、`ClaudeOAuthUsageProviderTests`（expired 响应 → notSubscribed marker）、`ClaudeStatusLineUsageProviderTests`（显式 null → marker、键缺失 → 仍 available、indicatesNoActivePlan 判定边界）。
- `REQUIREMENTS.md`：`0.10.0-DATA-B-005` 登记完成（挂在既有 `sub/main: 所有 AI Provider 统一订阅过期识别` feature 下）。

# 更新的需求 ID

- [x] `0.10.0-DATA-B-005`（新增，Claude 订阅过期识别）

# 更新的 README 或 DESIGN 章节

无。

# 验证方式

- `cd macos && swift test`：265 条全过（含新增 8 条）。
- 行为推演（未实机跑 App）：用户机器上 Claude 管线顺序 statusline（无缓存失败）→ oauth（无凭证失败）→ auth-status-cli（未登录失败）→ webview（命中 no active plan → marker）→ 串行短路 → dropdown 显示「未订阅或订阅已过期」灰条，状态灯灰色，菜单栏不画 bar；过期日 headless 抓取不再每轮白跑（enrichment 对非 available 跳过）。

# 备注

- 状态语义选择 `.notSubscribed`（灰色「未订阅或订阅已过期」）而非 `.subscriptionExpired`（红标）：usage 信号只能证明「无有效订阅」，拿不到到期日/上次套餐名，而 `.subscriptionExpired` 按需求文档语义只用于「最近一个自然周内的明确到期记录」；跟 MiniMax `no active token plan subscription` 的既有映射一致。
- 未来若 Claude billing 页 DOM 出现可靠的「Resume/已过期」文案或 OAuth 凭证携带到期字段，可在此信号之前插入更高优先级 source（对应 `0.10.0-DATA-B-000/001` 的剩余部分）。
- 未提交、未 bump VERSION（不涉及打包发布；用户如要发版需按 AGENTS.md 规则 bump PATCH 并在 changelog 追加记录）。
