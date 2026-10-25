---
title: 抓取Codex真实订阅到期日
id: 0.6.0-DATA-B-000
type: DATA
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`；标题路径：任务清单 / Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页） / DATA-B：Codex 真实订阅到期日（headless 抓订阅页）。'
原稳定 ID: '`0.6.0-DATA-B-000`, `0.6.0-DATA-B-001`, `0.6.0-DATA-B-001-test`；不改写或重编号这些既有 ID。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> Codex (chatgpt.com) 的 `/backend-api/wham/usage` 只返回 quota 窗口，**不返回订阅到期日**。需要 headless 抓 `https://chatgpt.com/#settings/Billing` 页面，提取「Next billing date」「Renewal date」之类 DOM 文本。

- [x] [0.6.0-DATA-B-000] `CodexHarvester` 实现：用 `WKWebViewHeadlessLoader` 加载 `https://chatgpt.com/#settings/Billing`，DOM 提取续费日期；找不到返回 nil；超时/Cloudflare challenge 失败抛 `QuotaFetchError.transient` 让 pipeline 降级 #P1
- [x] [0.6.0-DATA-B-001] `CodexAuthProvider` / `BrowserCookieProvider` Codex 路径新增 strategy：headless 抓订阅页 → 拿 `subscriptionExpiresAt`；和现有 quota 抓取并行，结果合并到 `ProviderSnapshot` #P1
- [x] [0.6.0-DATA-B-001-test] 单元测试：mock HTML（含"Next billing on July 25, 2026"等常见模式）验证 `CodexHarvester` 解析出正确 `Date` #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260628004500-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260628004500-utcp8-mavis.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 你接下来在feat-subscription-expiry这个branch工作，进入对应worktree，完成这个需求

#### 用户意图梳理

用户给的方向性指令——"在 feat-subscription-expiry branch 工作，进入对应 worktree，完成这个需求"。
本会话开头先：
1. 列了 5 个候选方案让用户选范围
2. 用户选了 "all-five"（当前 worktree 全做 5 个），违反 branch marker doc 建议的"每个 provider 独立 sub-worktree"，但用户拍板就这么干

#### 设计决策

**集成点**：harvester 调用放在 `RefreshCoordinator.runRefreshCycle` 的 per-provider task 内
- quota fetch 完成后 `await enrichWithHarvester(snapshot, kind:)` 短超时跑 harvester
- 不放在 BrowserCookieProvider 里，因为 AntigravityDashboardProvider 走独立路径；统一在协调器层处理所有 provider 更合理
- 失败兜底：harvester 任何错误（cookie 读不到 / permission / transient / 超时 / 找不到日期）→ 返回原 snapshot，UI hide

**harvester 超时**：6s（比 `providerTimeout=10s` 略短，因为 headless 加载订阅页一般 3-5s，且整个 refresh cycle 尾延迟 = max(providerTimeout, harvesterTimeout)，不能过长拖累 5min 自动刷新节奏）

**extract 策略**：context-aware 而非纯 firstDate
- 每个 harvester 列出"真正表示续费"的关键词（"Next billing"、"Renews on"、"到期日" 等）
- 关键词附近 100 字符窗口内找日期，找不到就 nil（**不 fallback 到无关键词的 firstDate**，避免抓到无关日期）
- 在 `SubscriptionDateHarvester` 协议扩展里加了 `extractNear(keywords:candidates:window:in:)` helper

**parseLooseDate 增强**：发现 Claude / Cursor 测试里 ISO 8601 date-only（"2026-12-15" 没时间部分）没被解析，补上 `yyyy-MM-dd` UTC 解析

**Test 设计**：每个 harvester 的测试只测 `extract(from:)` 纯函数（mock HTML 字符串），不动 WKWebView。
WKWebViewHeadlessLoader 的集成测试已有"cookie 入口失败路径"覆盖；真实加载依赖 macOS window server，无法在 CI 测。

#### 验证

- `cd quota-bar && swift build` → Build complete! (10.69s)
- `cd quota-bar && swift test` → Test run with 59 tests in 10 suites passed after 0.010 seconds
- 全部 59 个测试通过（20 个原有 + 39 个新加）

#### 完成工作

- v0.6.0-DATA-B（Codex）3 个任务全部勾选完成
- v0.6.0-DATA-C（Claude）3 个任务全部勾选完成
- v0.6.0-DATA-D（Cursor）3 个任务全部勾选完成
- v0.6.0-DATA-E（MiniMax）3 个任务全部勾选完成
- v0.6.0-DATA-F（Antigravity）3 个任务全部勾选完成
- 5 个 harvester 全部实现 + 测试通过 + RefreshCoordinator 集成完毕
- build / test 双绿

#### 更新的需求 ID

- [0.6.0-DATA-B-000] [0.6.0-DATA-B-001] [0.6.0-DATA-B-001-test]
- [0.6.0-DATA-C-000] [0.6.0-DATA-C-001] [0.6.0-DATA-C-001-test]
- [0.6.0-DATA-D-000] [0.6.0-DATA-D-001] [0.6.0-DATA-D-001-test]
- [0.6.0-DATA-E-000] [0.6.0-DATA-E-001] [0.6.0-DATA-E-001-test]
- [0.6.0-DATA-F-000] [0.6.0-DATA-F-001] [0.6.0-DATA-F-001-test]

共 15 个 task 勾选完成。

#### 验证方式

- `cd quota-bar && swift build` 通过（10.69s）
- `cd quota-bar && swift test` 通过（59 tests, 10 suites, 0.010s）
- 真实 headless 加载效果需要本地 macOS 跑 `swift run` + 浏览器登录态验证（CI 沙盒没 window server，无法测）

#### 已知 trade-off（用户可感知的限制）

1. **DOM 模式是猜测的** — 我没真实访问 `chatgpt.com/account/manage` / `claude.ai/settings/plan` / `cursor.com/dashboard` / `minimaxi.com/user-center/payment/balance` / `antigravity.google/settings` 抓 HTML 样本。当前 5 个 harvester 的 keywords + dateCandidates 都是基于：
   - ChatGPT / Cursor 等公开文档提到的字段名
   - OpenAI / Anthropic / Cursor / MiniMax UI 截图见过的文本模式
   - 类似订阅管理页（Google One、Stripe Customer Portal、Netlify Billing）的通用模式

   真实环境跑出来如果 regex 不命中，harvester 会返回 nil（UI hide）。这是设计契约：找不到就 nil，**不 throw，不污染主 pipeline**。

2. **Antigravity 路径不确定** — Antigravity 是 Google 系 IDE，订阅管理页可能在 `antigravity.google/settings`，也可能要跟 Google 账号 OAuth 跳转到 `accounts.google.com`。当前实现只抓 `antigravity.google/settings`。如果实际不在该路径，需要调整 pageURL。

3. **Cursor 路径不确定** — Cursor dashboard 也可能用 client-side 渲染（React + CSR），headless 抓到的 HTML 是 React bootstrap 而不是 SSR，关键词可能在 hydration 之后才出现。当前实现只等 `didFinish` 就抓 outerHTML，没等 React 渲染完。如果实际抓不到，需要在 `WKWebViewHeadlessLoader` 加 "等关键 DOM 出现" 的逻辑。

4. **MiniMax i18n 不确定** — MiniMax 主体面向中文用户，页面用「到期日 / 续费日期 / 下次扣费」；如果用户切到英文（"Next billing on"），harvester 也支持。如果页面用了不在这两组关键词里的文案，会返回 nil。

5. **集成点位置** — 把 harvester 放在 `RefreshCoordinator.runRefreshCycle` 意味着每次 5min 自动刷新都会跑一次 harvester（即使 quota 没变化）。可以接受，因为 harvester 是异步、不阻塞主流程，失败就 nil。

#### 后续可优化方向（不在本次范围）

- 用户实测抓不到时，把真实 DOM 贴过来 → 调 regex；
- `WKWebViewHeadlessLoader` 加 network-idle / DOM-mutation-observer 等更智能的等待；
- harvester 结果加 `RefreshCoordinator` 的缓存层（同一 provider 5min 内不重复抓）；
- Antigravity 路径可能需要跟 accounts.google.com OAuth 重定向。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260619011202-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260619011202-utcp8-gpt5.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

其他的ai都不行，你可以访问cli和terminal直接帮我build，帮我解决现在quota bar的问题：没办法正确货渠道电脑上的ai的情况，参考codex bar是怎么做的，而且现在一直要full disk access，明显不合理

#### 验证方式

- `cd drop-down-test/CodingPlanMenu && swift build`：通过。
- `cd drop-down-test/CodingPlanMenu && ./build-app.sh`：通过，生成 `QuotaBar.app`。
- 已关闭旧进程并通过 `open .../QuotaBar.app` 启动新构建，进程 PID 为 `91907`。

#### 需求更新

- `DA-A-005` 标记完成：菜单不再展示 `.notInstalled` snapshot。
- `UI-C-005` 文案更新为“浏览器 Cookie 数据源缺 Full Disk Access 时按需显示引导”。

#### 备注

- 工作区已有 `.build/`、`.DS_Store` 等构建产物变更；本轮运行 build 后这些文件继续保持 dirty。未回滚这些已有/构建生成的文件。
- 当前未实现 Codex OAuth token refresh；若 token 过期，会提示重新 `codex login`。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-070408_Agent

原记录标题：2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-162234_Codex

按用户最新手写模板迁移属性和正文结构，保留任务语义、来源、原始状态及历史内容；本次未重新执行业务验收。

原版本关联记录（照录来源，不将本次文档迁移提交当作业务实施提交）：
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。

本次执行环境未提供具体模型标识，未补造 Model-Detail。

[本次文档迁移对话](codex://threads/01a157b3-610c-73b4-ae06-163c0f8490d3)
