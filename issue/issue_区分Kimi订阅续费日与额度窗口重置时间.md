---
title: 区分Kimi订阅续费日与额度窗口重置时间
id: 0.6.0-DATA-A-000
type: DATA
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`；标题路径：任务清单 / Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页） / DATA-A：Kimi 真实订阅到期日（已有数据，5 行代码）。'
原稳定 ID: '`0.6.0-DATA-A-000`, `0.6.0-DATA-A-001`, `0.6.0-DATA-A-002`, `0.6.0-DATA-A-002-test`；不改写或重编号这些既有 ID。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> Kimi 的 `GetSubscriptionStat` 响应里 `subscriptionBalance.expireTime` **就是真实的订阅到期日**，但当前代码把它错塞到 Work quota 窗口的 `resetsAt`。这是最快、最稳的 1 个 provider，先打通。

- [x] [0.6.0-DATA-A-000] `KimiSubscriptionStatParser` 解析 `subscriptionBalance.expireTime` 后**不再塞给 Work quota 的 `resetsAt`**（Work 的 resetsAt 应该是月度窗口的滚动结束时间，跟 subscription 到期日是不同概念）#P1
- [x] [0.6.0-DATA-A-001] Kimi `ProviderSnapshot.subscriptionExpiresAt` 使用 `GetSubscription.nextBillingTime` 作为“下一次续费日”来源，转换为本地自然日的前一天作为“最后有效日”；不再使用 `subscriptionBalance.expireTime` / `currentEndTime` 直接展示，避免把续费日或服务端结束时间错显示为 7/10 #P1
- [x] [0.6.0-DATA-A-002] Work quota 窗口的 `resetsAt` 改为从 `subscriptionBalance.expireTime` 反推或保留为 nil（让 UI 不显示月度 quota 的"重置时间"——已经隐含在 subscriptionExpiresAt 里，避免双信息）；如需要月度窗口重置，则计算 `now + periodSeconds` 兜底 #P1
- [x] [0.6.0-DATA-A-002-test] 单元测试：mock `GetSubscriptionStat` JSON 验证 stat parser 不再输出展示到期日，mock `GetSubscription.nextBillingTime` 验证续费日前一天会显示为最后有效日；Work quota `resetsAt` 不再等于 expireTime #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260702223030-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260702223030-utcp8-gpt5.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> kimi额度对了，订阅名称有了，日期不对，之前出现过这个错误，应该是7/8最后有效，你获取到的7/9是续费日期，然后你现在显示的是7/10
> minimax没有到期日，codex也没有，这俩之前（可能是在sub-expiry）是好的
> agy又没有额度了，zcode也还没有额度

#### 完成工作

- `KimiSubscriptionStatParser.parseSubscriptionExpiresAt` 改为返回 nil，避免把无法确认语义的 `expireTime/currentEndTime` 直接展示。
- `KimiSubscriptionParser.parseSubscriptionExpiresAt` 新增 `nextBillingTime` 解析与最后有效日转换。
- `KimiDesktopTokenProvider` 和 `BrowserCookieProvider` 使用 `GetSubscription` 返回的日期。
- 新增/更新测试覆盖：
  - stat parser 不再输出展示日期。
  - `nextBillingTime = 2026-07-09...` 会显示为 `2026/7/8`。
  - Desktop provider 订阅日期来自 `GetSubscription.nextBillingTime`。
- 打包新版本：`quota-bar/build/20260702-223006/QuotaBar.app`，快捷入口 `quota-bar/build/latest/QuotaBar.app`。

#### 更新的需求 ID

- `0.6.0-ARCH-A-003`
- `0.6.0-DATA-A-001`
- `0.6.0-DATA-A-002-test`
- `0.6.0-DATA-B-002`
- `0.6.0-UI-A-002`

#### 验证方式

- `cd quota-bar && env CLANG_MODULE_CACHE_PATH=.build/clang-module-cache SWIFT_MODULE_CACHE_PATH=.build/swift-module-cache swift test --disable-sandbox`
  - 结果：通过，63 个 Swift Testing 测试通过。
- `cd quota-bar && ./scripts/build-app.sh`
  - 结果：通过，生成 `/Users/taobe/Projects/GitHub/Personal/quota-bar/worktree/sub-main/quota-bar/build/20260702-223006/QuotaBar.app`。

#### 备注

- Codex/MiniMax 当前无到期日不是本次代码修复范围内可直接恢复的问题：`sub/expiry` 没有可合并的真实实现，当前应继续隐藏，避免展示 stale 或伪造日期。
- Antigravity 当前只看到 `agy` 进程，未看到 `language_server`，因此现有本地 RPC 路径会如实显示不可用。
- Z Code 服务端仍可能返回 plan available 但无可渲染 quota，当前逻辑应如实展示“没有额度数值”，不得从 plan-cache 伪造。

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
