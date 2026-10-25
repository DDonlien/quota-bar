---
title: 区分Kimi订阅续费日与额度窗口重置时间
id: 0.6.0-DATA-A-000
type: DATA
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `1532061d80cab44eba9d5469836105dedd72a7e8`；标题路径：任务清单 / Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页） / feat/subscription-expiry: 接入 Kimi 真实订阅到期日。'
原稳定 ID: '`0.6.0-DATA-A-000`, `0.6.0-DATA-A-001`, `0.6.0-DATA-A-002`, `0.6.0-DATA-A-002-test`；不改写或重编号这些既有 ID。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> Kimi 的 `GetSubscriptionStat` 响应里 `subscriptionBalance.expireTime` **就是真实的订阅到期日**，但当前代码把它错塞到 Work quota 窗口的 `resetsAt`。这是最快、最稳的 1 个 provider，先打通。

- [x] [0.6.0-DATA-A-000] `KimiSubscriptionStatParser` 解析 `subscriptionBalance.expireTime` 后**不再塞给 Work quota 的 `resetsAt`**（Work 的 resetsAt 应该是月度窗口的滚动结束时间，跟 subscription 到期日是不同概念）#P1
- [x] [0.6.0-DATA-A-001] `KimiSubscriptionStatParser.parseSubscriptionExpiresAt(data:)` 返回 `subscriptionBalance.expireTime`；`BrowserCookieProvider` 调 `parseSubscriptionExpiresAt` 拿到值后传给 `ProviderSnapshot.subscriptionExpiresAt` #P1
- [x] [0.6.0-DATA-A-002] Work quota 窗口的 `resetsAt` 改为从 `subscriptionBalance.expireTime` 反推或保留为 nil（让 UI 不显示月度 quota 的"重置时间"——已经隐含在 subscriptionExpiresAt 里，避免双信息）；如需要月度窗口重置，则计算 `now + periodSeconds` 兜底 #P1
- [x] [0.6.0-DATA-A-002-test] 单元测试：mock `GetSubscriptionStat` JSON 验证 `subscriptionExpiresAt == expireTime`，Work quota `resetsAt` 不再等于 expireTime #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260619160000-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260619160000-utcp8-mavis.md` @ `1532061d80cab44eba9d5469836105dedd72a7e8`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 原始 prompt（用户给 kimi CLI 的）

1. 把本地 worktree 里的菜单栏图标 bar 功能改动合并到 main
2. 检查并清空所有 worktree
3. 列出当前的 requirements

> 下一步最重要的工作是确保真的能获取到本地的订阅。现在只有 Codex 能正确获取到。我的电脑上至少有 Trae Work、Kimi、MiniMax 和 Google 的 Antigravity。其中除了 Trae Work 以外，所有的都有 CLI，Quota Bar 应该尝试从 app 和 cli 获取订阅，确保即使只安装其中一个也能正确识别到订阅信息；并且能识别两个工具用的是否是一个订阅权限/用户，确保如果用的是两个权限，能正确地拆分成两个权限的信息；如果两个用的是同一个权限，能正确合并成一个权限的信息。

#### 本机实际探测结果（先验证再设计）

- `~/.kimi-code/credentials/kimi-code.json` 里有 OAuth access_token（JWT，scope=kimi-code），但 `POST /apiv2/.../GetUsages` 401 `REASON_INVALID_AUTH_TOKEN` —— CLI token 不能直接调 web endpoint
- `~/.mavis/config.yaml` 里的 `apiKey: sk-xxx` 是脱敏过的（用户隐藏真 key），不是真 key
- MiniMax web endpoint `api.minimax.chat/v1/api/openplatform/coding_plan/remains` 在浏览器签名检查下被 Cloudflare 1010 拦截；带 cookie 走能命中但要 web cookie
- **结论**：CLI OAuth token 路径在本机不可直接用于拿 dashboard 数据，Kimi/MiniMax 真实可行的数据源只有浏览器 Cookie（用户在浏览器登录 kimi.com / minimax.chat）

#### 运行验证日志（FileHandle 输出后已删）

```
QB: codex ok av=available q=2 tier=Plus
QB: kimi ok av=needsConfiguration(reason: "App 已安装，dashboard 暂未接入") q=0 tier=-
QB: minimax ok av=needsConfiguration(reason: "App 已安装，dashboard 暂未接入") q=0 tier=-
QB: trae ok av=needsConfiguration(reason: "App 已安装，dashboard 暂未接入") q=0 tier=-
QB: antigravity ok av=needsConfiguration(reason: "App 已安装，dashboard 暂未接入") q=0 tier=-
QB: gemini ok av=notInstalled q=0 tier=-
QB: claude ok av=notInstalled q=0 tier=-
```

7 个 provider 全部被识别。dashboard 里展示 Codex（真实 Plus 额度）+ Kimi/MiniMax/Trae/Antigravity（已安装但需在浏览器登录），过滤 Gemini/Claude（未登录且无 App）。

#### 已知遗留问题

1. **Edge Safe Storage 弹窗**：Kimi/MiniMax/Claude/Gemini pipeline 走 BrowserCookieProvider 时会触发（SweetCookieKit 行为，跟 CodexBar 一样）。需要 CodexBar 的 `BrowserCookieAccessGate` 类似机制在 `coordinator.refreshCycle` 一次性提示用户。
2. **截图验证没成功**：AppleScript 没点中 status bar item 的菜单，但日志已证 dashboard 数据正确。
3. **Kimi CLI token 不直接可用**：401 时 KimiAuthProvider 转 missingCredentials 让 pipeline fallback 到 Cookie/Keychain/App 兜底，是合理的。

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
