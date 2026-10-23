# sub/main: opencode WebView 额度层（workspace Go 页）

- ID：`0.10.0-DATA-B-019`。
- 类型：`DATA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: opencode WebView 额度层（workspace Go 页）。
- 原稳定 ID：`0.10.0-DATA-B-019`, `0.10.0-DATA-B-020`, `0.10.0-ARCH-L-005`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户提供了真实入口："浏览器额度，其中长的占位符登陆了就会有：https://opencode.ai/workspace/wrk_.../go"；"订阅日期"在 Stripe 客户门户（短期 session 链接）；"cli指令我不确定"。要求给 opencode 接上浏览器侧的额度和过期日。

- [x] [0.10.0-DATA-B-019] 新增 `OpenCodeWorkspaceProvider`（`opencode-webview`）：读 sst/opencode 真实源码确认 console 是 SolidStart 应用、数据走 `"use server"` 内部 RPC 没有公开 JSON API，因此走 headlessDOM：先加载 `https://opencode.ai/auth`（已登录时 302 到 `/workspace/{lastSeenWorkspaceID}`，`routes/auth/index.ts`），正则出 `wrk_` id，再加载 `/workspace/{id}/go`，按 `data-slot="usage-item"/"usage-value"/"reset-time"` 结构锚点（`lite-section.tsx`）解析 Rolling/Weekly/Monthly 三条**已用**百分比——标签是 i18n 的，解析只认结构和顺序不认文字。周期标签按 5h/7d/30d 映射（rolling 窗口时长是服务端配置 ZEN_LIMITS，代码里读不到，按当前产品实际 5 小时标注并在注释里声明该假设）。reset 文案（"Resets in 3 hours 25 minutes"/中文等价）尽力解析成秒得出 `resetsAt`，解析不出不阻塞额度展示 #P1 — `OpenCodeWorkspaceProviderTests`：wrk_ id 提取、结构顺序解析、未订阅推广页零结果、reset 文案中英/兜底/不可识别 4 组测试
- [x] [0.10.0-DATA-B-020] opencode 订阅续费日：Stripe 客户门户的 session URL 是服务端动态生成的短期链接（`Billing.generateSessionUrl` server action），无法预先构造、不接。替代：Go 的月用量窗口锚定在订阅日（`analyzeMonthlyUsage(timeSubscribed:)`），monthly 重置时刻即下一个月度账单日——用解析出的 monthly reset 作为续费日代理，`subscriptionExpiresAtSource = .headlessDOM`、confidence `.medium` #P2
- [x] [0.10.0-ARCH-L-005] opencode 接入 WebView 授权体系：`webAuthorizationURL = https://opencode.ai/auth`（已登录/未登录两种状态都落在正确页面）、加入 `webViewQuotaCapableKinds`、`dashboardCookieDomains = ["opencode.ai"]`、pipeline 追加 `opencode-webview` 层、Preferences 获取模式改 `["Config", "Web", "API"]`。dropdown 的授权引导按既定优先级自动生效：未登录 WebView 时显示「打开 WebView 授权」（现在是真实可兑现的入口），WebView/API 都完成仍无额度才显示终态文案 #P1
- opencode CLI 指令：调研未发现 opencode CLI 有额度查询命令（docs 无相关子命令），用户自己也说"cli指令我不确定"——不接，等官方出了再说。

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260709-010527-utcp8-taobe-claude-fable-5.md — 历史证据迁移

来源：`agent-log/20260709-010527-utcp8-taobe-claude-fable-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 可是claude如果是ios订阅就只能从apple看过期日，这个没办法，做好隐藏兜底就可以；并确保如果用户是直接付款的能获取到信息
> opencode在cli和浏览器上也可以（额度和过期日）
>
> * 浏览器额度，其中长的占位符登陆了就会有，可能需要模拟浏览器操作？：https://opencode.ai/workspace/wrk_01KWTQ01HPDHJCFGAMGYMG1T3D/go
> * 订阅日期：https://billing.stripe.com/p/session/live_...（Stripe 客户门户 session 链接）
> * cli指令我不确定

#### 完成工作

- 新增 `OpenCodeWorkspaceProvider.swift`（`opencode-webview`）：cookie 预检 → `/auth` 入口页发现 `wrk_` id → 加载 `/workspace/{id}/go` → 结构化解析三条用量 → `QuotaWindow`（周期 5h/7d/30d，reset 文案尽力解析成 `resetsAt`）+ monthly reset 作为 `subscriptionExpiresAt` 代理；未订阅推广页（`promo-description`）抛 `.notSubscribed`，不污染 auth.json 已给出的档位基底。解析函数全部是可单测的静态纯函数。
- `Strategies.swift`：opencode pipeline 追加 `opencode-webview` 层（`sourceKind` 按 id 自动推导为 `.webViewSession`，全层支持）。
- `WebAuthorizationController.swift`：`webAuthorizationURL` 增加 `.opencode → https://opencode.ai/auth`；`webViewQuotaCapableKinds` 加入 `.opencode`。
- `BrowserCookieProvider.swift`：`dashboardCookieDomains` 增加 `.opencode → ["opencode.ai"]`（tier 完成度判断和 PlanHeader gate 也依赖它）。
- `Preferences/ModelsSettingsView.swift`：opencode 获取模式改 `["Config", "Web", "API"]`。
- 新增 `OpenCodeWorkspaceProviderTests`（4 组：id 提取、结构顺序解析、推广页零结果、reset 文案中英/兜底/不可识别）。
- `REQUIREMENTS.md`：`[0.10.0-DATA-B-019]` `[0.10.0-DATA-B-020]` `[0.10.0-ARCH-L-005]`，并把 `[0.10.0-INVESTIGATE-A-006]` 按用户澄清定性关闭。

新包：`macos/build/20260709-010527-main/Quota Bar.app`（`build/latest` 已指向），已重启本机开发态实例。

#### 更新的需求 ID

- `[0.10.0-DATA-B-019]` `[0.10.0-DATA-B-020]` `[0.10.0-ARCH-L-005]` `[0.10.0-INVESTIGATE-A-006]`（定性关闭）

#### 验证方式

- `swift build`：无警告无错误。
- `swift test`：194 tests in 44 suites 全部通过（新增 4 个解析测试；期间修了一处测试里 `TimeInterval?` 与整型字面量比较的诡异断言失败，显式 `TimeInterval(...)` 后正常）。
- `./scripts/build-app.sh`：产包成功，已重启实例。
- **无法本机端到端验证**：headlessDOM 抓取需要用户先在 App 内 WebView 登录 opencode.ai（本轮才加上这个入口），我没有登录态。解析器是照着 sst/opencode 真实源码的 DOM 结构写的（不是猜的），但真实页面首跑仍可能有出入——请用户点 opencode 行的「打开 WebView 授权」登录一次，然后看日志里 `opencode-webview` 的结果。

#### 备注

- 未提交 git commit。
- 已知假设：rolling 窗口按 5 小时标注（服务端配置读不到）；monthly reset ≈ 续费日（月订阅成立，年付/优惠券场景可能有偏差，confidence 已标 `.medium`）。
- 用户下一步操作：dropdown 里 opencode 行现在应显示可点击的「打开 WebView 授权」（WebView tier 优先于已配置的 API tier）——登录一次后，下一轮刷新应出现三条额度（5 小时/周额度/月额度）和一个日期。
