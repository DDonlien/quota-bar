---
title: 从Codex授权元信息解码订阅状态
id: 0.8.0-ARCH-A-000
type: ARCH
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`；标题路径：任务清单 / Phase - v0.8.0 - 订阅过期识别（"权威 > API 反推"模型） / ARCH-A：订阅状态基础架构。'
原稳定 ID: '`0.8.0-ARCH-A-000`, `0.8.0-ARCH-A-001`, `0.8.0-ARCH-A-002`, `0.8.0-ARCH-A-003`, `0.8.0-ARCH-A-003-test`；不改写或重编号这些既有 ID。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> Codex 一次落地，其他 provider 复用同模式。

- [x] [0.8.0-ARCH-A-000] `JWTPayloadDecoder` 工具：解 JWT payload 部分（不验签，只读 base64url+JSON），失败返回 nil #P1 — `SubscriptionInspector.swift:JWTPayloadDecoder`
- [x] [0.8.0-ARCH-A-001] `OpenAIAuthPayload` struct：把 `https://api.openai.com/auth` 命名空间下的字段组装成 Swift 类型（plan_type / active_start / active_until / last_checked）#P1
- [x] [0.8.0-ARCH-A-002] `SubscriptionStatus` 枚举：`.active(expiresAt)` / `.expired(lastPlan, expiredAt)` / `.free` / `.unknown`；`isEffectivelyExpired` 计算属性 #P1
- [x] [0.8.0-ARCH-A-003] `CodexSubscriptionInspector`：从 `~/.codex/auth.json` 解 id_token → 映射成 `SubscriptionStatus`；失败（文件缺失 / 字段缺失 / JWT 坏）一律返回 `.unknown`，**不要**瞎猜 #P1 — `SubscriptionInspector.swift:CodexSubscriptionInspector`
- [x] [0.8.0-ARCH-A-003-test] 单元测试：JWT 解析 4 种边界（合法 / 三段缺失 / base64 坏 / 非 JSON payload） + inspector 6 种路径（expired / active / free / 文件缺失 / 字段缺失） + `.isEffectivelyExpired` 语义 #P1

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
