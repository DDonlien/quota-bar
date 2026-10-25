---
title: 以权威订阅元信息纠正Codex免费额度误判
id: migration-55e27d3757c0
type: API
status: 已确认约束 / 状态待核对（原文未单列完成状态）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`；标题路径：任务清单 / Phase - v0.8.0 - 订阅过期识别（"权威 > API 反推"模型）。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> **触发 bug**：user 实测发现 `~/.codex/auth.json` 的 id_token 里 `chatgpt_subscription_active_until = 2026-06-25`，但 Codex.app 在订阅过期后调 `wham/usage` 仍能拿到 200 OK，**响应里** `plan_type` 跌成 `"free"`，`rate_limit.primary_window.limit_window_seconds` 跳到 `2592000`（30 天），被现有 parser 错误地按"5h 窗口"处理 → UI 推断成"月额度" → 显示"5% 月额度"——**完全是误导**。从原理上"用 quota 数值反推过期"就不靠谱（quota 数值会因用量变化、API 改动、free 用户本来就有月度窗口而误判）。
>
> **解决思路**：订阅状态最权威的来源 = 服务商在用户登录时写下来的本地授权元信息（OpenAI 把订阅到期日塞进 id_token 的 payload；其他 provider 类似），**不依赖网络、不需要解析 quota window**。按 user 提的优先级："app 授权信息 > CLI 指令 > Web 抓取"。
>
> **本 phase 第一批只覆盖 Codex**（user 当前 case），其他 provider 沿用同一 inspector 模式扩展：
> 1. 从 `~/.codex/auth.json` 的 `id_token` 解码出 `chatgpt_plan_type` + `chatgpt_subscription_active_until`
> 2. 过期时直接返回 `.subscriptionExpired` snapshot，不让 free 用户的"月额度"窗口被任何 strategy 渲染
> 3. UI 状态灯红色 + 灰标"订阅已过期 · Plus · 到期 2026/6/25"
> 4. CodexDashboardParser 加 `plan_type == "free"` 防御，避免 BrowserCookie 路径绕过
>
> **不做什么**（YAGNI）：
> - 不重写整个订阅状态机——本 phase 只识别"过期 / free"两种清楚状态，"明天即将到期提醒"留 P2
> - 不在 v0.8.0 接 Claude/Cursor/Antigravity 的同类检测——每个 provider 的 token 字段不一样（Claude 的 entitlement 路径不同，Cursor 走 dashboard 抓取，Antigravity 走本地 language_server），工作量是 Codex 的 3-5x
> - 不做"明天续费提醒"等可观察性优化

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

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
