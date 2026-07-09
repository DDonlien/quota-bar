# 用户原始 prompt

> 可是claude如果是ios订阅就只能从apple看过期日，这个没办法，做好隐藏兜底就可以；并确保如果用户是直接付款的能获取到信息
> opencode在cli和浏览器上也可以（额度和过期日）
>
> * 浏览器额度，其中长的占位符登陆了就会有，可能需要模拟浏览器操作？：https://opencode.ai/workspace/wrk_01KWTQ01HPDHJCFGAMGYMG1T3D/go
> * 订阅日期：https://billing.stripe.com/p/session/live_...（Stripe 客户门户 session 链接）
> * cli指令我不确定

# 启动运行时的分支和版本

- 分支：`main`
- 版本：本轮基于上一轮（授权 tier 完成度判断）未提交的工作树继续

# 任务开始时间

2026-07-09 00:50 +0800

# 任务结束时间

2026-07-09 01:06 +0800

# 任务结束时是否执行了提交

否——按惯例留给用户确认后再决定是否提交/推送。

# 已阅读上下文

- sst/opencode 真实源码（`gh api` 直读 GitHub）：`packages/console/app/src/routes/workspace/[id]/go/lite-section.tsx`（Go 页完整 JSX，`data-slot` DOM 结构 + `queryLiteSubscription` server query）、`routes/auth/index.ts`（`/auth` 已登录 302 到 `/workspace/{lastSeenWorkspaceID}`）、`lib/format-reset-time.ts`（reset 文案格式）、`i18n/en.ts`（三条用量的英文标签）、`console/core/src/subscription.ts`（`analyzeMonthlyUsage` 锚定 `timeSubscribed`）、`console/core/src/lite.ts`（limits 来自服务端配置 ZEN_LIMITS，代码里读不到具体窗口时长）。
- 本仓库：`QuotaModels.swift`（`QuotaWindow.periodLabel`/`displayTitle` 生成规则、`SubscriptionExpiryConfidence`）、`Strategies.swift`（`sourceKind`/`supportedLayers` 按 id 推导、opencodePipeline）、`SubscriptionExpirySources.swift`（claude 日期源现状）。

# 对话与行动记录

**Claude iOS 订阅**：用户澄清了上一轮 `INVESTIGATE-A-006` 的定性——iOS（Apple 内购）订阅的到期日只在 Apple 侧可见，claude.ai 网页上根本没有这个数据，"页面里未提取出日期"是数据不存在而非解析 bug。隐藏兜底上一轮已经做好（已授权时不显示假引导、日期留空），本轮无代码改动；直接付款用户的 `ClaudeHarvester` 提取路径保留，等有直接付款样本再验证。该条目从未完成待办改为已定性关闭。

**opencode 浏览器额度**：没有盲写解析器——先用 `gh api` 直读 sst/opencode 的 console 源码，确认了四件事：(1) console 是 SolidStart 应用，数据走 `"use server"` 内部 RPC，没有公开 JSON API，headlessDOM 是唯一稳妥路线；(2) Go 页的用量 DOM 有稳定的 `data-slot` 锚点（`usage-item`/`usage-value`/`reset-time`），且固定按 rolling → weekly → monthly 顺序渲染，标签文字是 i18n 的（多语言站点）——所以解析只认结构和顺序、不认文字；(3) workspace id 的发现方式：`/auth` 已登录时 302 到 `/workspace/{lastSeenWorkspaceID}`，从渲染结果正则 `wrk_` id 即可，不需要用户手填；(4) rolling 窗口时长来自服务端配置（ZEN_LIMITS），代码里读不到，按当前产品实际的 5 小时窗口标注周期并在注释里声明这个假设。

**订阅日期**：用户给的 Stripe 链接是客户门户的短期 session（服务端 `Billing.generateSessionUrl` 动态生成），无法预先构造、不能长期使用——不接。替代方案有真实依据：console 源码里 `analyzeMonthlyUsage(timeSubscribed:)` 把月用量窗口锚定在订阅日，monthly 重置时刻就是下一个月度账单日——用解析出的 monthly reset 作为续费日代理（`.headlessDOM` 来源、`.medium` 置信度）。

**CLI**：查了 opencode docs 没有额度查询子命令，用户自己也不确定——不接。

# 完成工作

- 新增 `OpenCodeWorkspaceProvider.swift`（`opencode-webview`）：cookie 预检 → `/auth` 入口页发现 `wrk_` id → 加载 `/workspace/{id}/go` → 结构化解析三条用量 → `QuotaWindow`（周期 5h/7d/30d，reset 文案尽力解析成 `resetsAt`）+ monthly reset 作为 `subscriptionExpiresAt` 代理；未订阅推广页（`promo-description`）抛 `.notSubscribed`，不污染 auth.json 已给出的档位基底。解析函数全部是可单测的静态纯函数。
- `Strategies.swift`：opencode pipeline 追加 `opencode-webview` 层（`sourceKind` 按 id 自动推导为 `.webViewSession`，全层支持）。
- `WebAuthorizationController.swift`：`webAuthorizationURL` 增加 `.opencode → https://opencode.ai/auth`；`webViewQuotaCapableKinds` 加入 `.opencode`。
- `BrowserCookieProvider.swift`：`dashboardCookieDomains` 增加 `.opencode → ["opencode.ai"]`（tier 完成度判断和 PlanHeader gate 也依赖它）。
- `Preferences/ModelsSettingsView.swift`：opencode 获取模式改 `["Config", "Web", "API"]`。
- 新增 `OpenCodeWorkspaceProviderTests`（4 组：id 提取、结构顺序解析、推广页零结果、reset 文案中英/兜底/不可识别）。
- `REQUIREMENTS.md`：`[0.10.0-DATA-B-019]` `[0.10.0-DATA-B-020]` `[0.10.0-ARCH-L-005]`，并把 `[0.10.0-INVESTIGATE-A-006]` 按用户澄清定性关闭。

新包：`macos/build/20260709-010527-main/Quota Bar.app`（`build/latest` 已指向），已重启本机开发态实例。

# 更新的需求 ID

- `[0.10.0-DATA-B-019]` `[0.10.0-DATA-B-020]` `[0.10.0-ARCH-L-005]` `[0.10.0-INVESTIGATE-A-006]`（定性关闭）

# 更新的 README 或 DESIGN 章节

- 无（README 分层矩阵如需同步 opencode 的 Web 层，留给下一轮文档核对）。

# 验证方式

- `swift build`：无警告无错误。
- `swift test`：194 tests in 44 suites 全部通过（新增 4 个解析测试；期间修了一处测试里 `TimeInterval?` 与整型字面量比较的诡异断言失败，显式 `TimeInterval(...)` 后正常）。
- `./scripts/build-app.sh`：产包成功，已重启实例。
- **无法本机端到端验证**：headlessDOM 抓取需要用户先在 App 内 WebView 登录 opencode.ai（本轮才加上这个入口），我没有登录态。解析器是照着 sst/opencode 真实源码的 DOM 结构写的（不是猜的），但真实页面首跑仍可能有出入——请用户点 opencode 行的「打开 WebView 授权」登录一次，然后看日志里 `opencode-webview` 的结果。

# 备注

- 未提交 git commit。
- 已知假设：rolling 窗口按 5 小时标注（服务端配置读不到）；monthly reset ≈ 续费日（月订阅成立，年付/优惠券场景可能有偏差，confidence 已标 `.medium`）。
- 用户下一步操作：dropdown 里 opencode 行现在应显示可点击的「打开 WebView 授权」（WebView tier 优先于已配置的 API tier）——登录一次后，下一轮刷新应出现三条额度（5 小时/周额度/月额度）和一个日期。
