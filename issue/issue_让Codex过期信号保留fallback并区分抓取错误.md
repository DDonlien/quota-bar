---
title: 让Codex过期信号保留fallback并区分抓取错误
id: 0.8.0-DATA-C-000
type: DATA
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`；标题路径：任务清单 / Phase - v0.8.0 - 订阅过期识别（"权威 > API 反推"模型） / DATA-C：Codex pipeline 不短路 inspector（v0.8.1 修订）。'
原稳定 ID: '`0.8.0-DATA-C-000`, `0.8.0-DATA-C-001`, `0.8.0-DATA-C-002`, `0.8.0-DATA-C-003`, `0.8.0-DATA-C-000-test`, `0.8.0-DATA-C-001-test`, `0.8.0-DATA-C-002-test`, `0.8.0-DATA-C-004-test`；不改写或重编号这些既有 ID。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> **修订原因**：v0.8.0 把 inspector 短路写在 `CodexAuthProvider` + `BrowserCookieProvider` Codex 路径两处，
> user 实测反馈：昨天 web 续费后 `~/.codex/auth.json` 没刷新（Codex.app 自己写本地缓存，web 续费不触发 OAuth flow），
> inspector 看到陈旧 `chatgpt_subscription_active_until` → 误判过期 → 但 BrowserCookie 路径用浏览器已登录会话
> 能拿到真实 plus quota。v0.8.0 行为把 inspector 当"绝对权威"短路所有 strategy，结果活跃订阅被错标过期。
>
> v0.8.1 调整：inspector 仍然是「权威」（不是完全抛弃），但**只在 CodexAuthProvider 一处检测**，
> 检测到过期时**throw** 让 pipeline 继续走 BrowserCookie / CLILog / Keychain。BrowserCookie 路径信任
> `CodexDashboardParser.plan_type=free → nil` 的 parser 层防御，不在入口再次拦截。
> 续费后 Codex.app 重新 OAuth refresh → auth.json 写入新 id_token → inspector 看到新到期日 → 回到正常路径。
>
> 这与 user 的优先级「app 授权信息 > CLI 指令 > Web 抓取」一致：app 授权信息（OAuth → wham/usage）
> 是主路径，Web（BrowserCookie）只是兜底；inspector 检测应该让 OAuth + Web 都有机会尝试，而不是
> 在第一道就堵死。

- [x] [0.8.0-DATA-C-000] `CodexAuthProvider.fetchSnapshot`：inspector 报 `.expired` / `.free` 时**throw** `QuotaFetchError.subscriptionExpired(plan, expiredAt)`（替换 v0.8.0-DATA-A-000 的"直接 return marker"行为），让 pipeline 继续走 BrowserCookie / CLILog / Keychain fallback #P1
- [x] [0.8.0-DATA-C-001] `BrowserCookieProvider.fetchSnapshotImpl` Codex 路径：移除 v0.8.0-DATA-A-002 加的 inspector 调用；信任 `CodexDashboardParser.plan_type=free → nil` 的 parser 层防御（parser 拒绝 free 用户的"月额度"窗口，让 BrowserCookie 也能 fallback 到 inspector 没看到的活跃订阅）#P1
- [x] [0.8.0-DATA-C-002] `RefreshCoordinator.applyProviderResult`：当 `error as? QuotaFetchError` 是 `.subscriptionExpired` 时，优先用 `qe.availabilityFallback`（=`.subscriptionExpired(plan, expiredAt)`），不被 `installDetail` 覆盖成 `.needsConfiguration`（防止 Codex.app 已装时把"订阅已过期"误显示为"待配置"）#P1
- [x] [0.8.0-DATA-C-003] `RefreshCoordinator.applyProviderResult`：其他 error type（`.missingCredentials` / `.permissionRequired` / `.transient` / `.sourceUnavailable`）仍走 installDetail fallback（保留 install 检测信号）#P1
- [x] [0.8.0-DATA-C-000-test] 单元测试：`CodexAuthProvider.fetchSnapshot` 在 inspector 报 `.expired(plus, ...)` 时 throw `.subscriptionExpired(plan: "plus", expiredAt)`；在 inspector 报 `.free` 时 throw `.subscriptionExpired(plan: nil, expiredAt: nil)`；不会向 endpoint 发请求（endpoint 用 `https://example.invalid/never-called`）#P1
- [x] [0.8.0-DATA-C-001-test] 单元测试：`BrowserCookieProvider` Codex 路径在 inspector expired 的 auth.json 存在 + cookie reader 为空时，**不再** throw `.subscriptionExpired`，而是走 `missingCredentials` / `sourceUnavailable` 路径（验证 v0.8.0 的 inspector 二次短路被移除）#P1
- [x] [0.8.0-DATA-C-002-test] 单元测试：`ProviderPipelines.makePipelines` 的 Codex pipeline 顺序仍是 `[codex-auth, codex-cookie, codex-cli, codex-keychain]`，`runMode == .sequential`（确保 inspector throw 后真能走到 BrowserCookie / CLILog / Keychain）#P1
- [x] [0.8.0-DATA-C-004-test] 单元测试：`QuotaFetchError.subscriptionExpired(plan, expiredAt).availabilityFallback` 返回 `.subscriptionExpired(plan, expiredAt)`（契约）；`.subscriptionExpired(plan: nil, expiredAt: nil)` 也正常 fallback（用于 .free 状态）#P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260702013307-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260702013307-utcp8-mavis.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 把 main 的内容 merge 到这个分支；Merge 之前或者之后，帮我检查两个问题：
>
> 1. 为什么 Antigravity 现在获取不到订阅额度了？
> 2. 为什么 Codex 现在获取不到有效的订阅了？
> 这两个对象我不确定在这个分支的某个版本是否曾有可用代码，即能正确获取到额度和订阅信息的代码。但现在 main 分支上的版本是不行的。
>
> 请先确认情况并告诉我你的解决思路，之后我们再决定是否要合并。

后续对话展开：用户提供截图（macOS 菜单栏下拉面板），发现 Codex 显示「订阅已过期 · plus · 到期 2026/6/25」、Antigravity 显示「待配置 · App 已装 (/Applications/Antigravity.app)」。然后补充：

> 我的 Codex 25 号是过期了，但我又续费了，就在昨天。既然 Antigravity Apps 的获取权限已经失败了，你就应该接着按顺序尝试 CLI 和 Web 吧

最后一句 `do it`，表示授权执行 v0.8.1 修订方案。

#### 完成工作

- 4 个源文件改动：`CodexAuthProvider.swift`、`BrowserCookieProvider.swift`、`RefreshCoordinator.swift`、`REQUIREMENTS.md`
- 1 个新测试文件：`Tests/QuotaBarTests/CodexAuthProviderInspectorThrowTests.swift`（351+ 行，4 个 test suite，8 个测试）
- 编译：`swift build` 完整通过
- 测试：`swift test` 47/47 通过（v0.8.0 39 个 + v0.8.1 新增 8 个）

#### 更新的需求 ID

新增 v0.8.0 phase 子 block：

- `[0.8.0-DATA-C-000]` `CodexAuthProvider` inspector 过期 throw
- `[0.8.0-DATA-C-001]` `BrowserCookieProvider` Codex 路径移除 inspector
- `[0.8.0-DATA-C-002]` `RefreshCoordinator` subscriptionExpired 优先 installDetail
- `[0.8.0-DATA-C-003]` `RefreshCoordinator` 其他 error 仍走 installDetail
- `[0.8.0-DATA-C-000-test]` CodexAuthProvider throw 测试
- `[0.8.0-DATA-C-001-test]` BrowserCookieProvider 不再短路测试
- `[0.8.0-DATA-C-002-test]` Codex pipeline strategy 顺序测试
- `[0.8.0-DATA-C-004-test]` availabilityFallback 契约测试

#### 验证方式

- `cd quota-bar && swift build` — 完整 build 通过
- `cd quota-bar && swift test` — 47 tests in 12 suites passed
- 手动集成验证（user 跑 build）：user 需要重新 build macOS app 并打开 dropdown 看 Codex 行的状态：
  - 如果 OAuth wham/usage 拿到真实 plus quota → 显示真实 quota
  - 如果 BrowserCookie 拿到真实 plus quota → 显示真实 quota
  - 如果 CLI 日志有 → 显示粗略估算
  - 如果全失败 + inspector 真过期 → 显示「订阅已过期 · plus · 到期 2026/6/25」（不再被 installDetail 覆盖成"待配置"）

#### 备注

- Antigravity 任务**未启动**：pipeline 架构上不存在 CLI / Web quota 路径，必须等 user 提供 Console 日志才能定位 DashboardProvider 失败原因（最可能是 Antigravity IDE 本地 protocol 变更 / 进程名 / 端口 / csrf 来源变化）。建议另开 task 处理。
- merge main → sub/main 的决定暂未执行：v0.8.1 修订与 main 上的代码行为已经一致（main 上 md5 一致 / 逻辑等价），merge 的增量价值主要是 v0.9.0 REQUIREMENTS + `CodexSubscriptionInspectorTests.swift` 测试。等 v0.8.1 验证通过后再决定 merge 节奏。
- 不 commit：等 user review + 在 Antigravity 任务开新工作分支前不污染 sub/main commit history。

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
