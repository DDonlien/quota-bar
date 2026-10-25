---
title: 调研Claude订阅到期日来源
id: 0.8.0-DATA-B-000
type: DATA
status: 待定 / 延后（沿用原需求记录）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`；标题路径：任务清单 / Phase - v0.8.0 - 订阅过期识别（"权威 > API 反推"模型） / DATA-B：其他 provider 沿用 Inspector 模式（v0.8.0 不落地，只登记）。'
原稳定 ID: '`0.8.0-DATA-B-000`, `0.8.0-DATA-B-001`, `0.8.0-DATA-B-002`, `0.8.0-DATA-B-003`, `0.8.0-DATA-B-004`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.8.0-DATA-B-000`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.8.0-DATA-B-000`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.8.0-DATA-B-000-DATA-provider-inspector-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: DATA-B：其他 provider 沿用 Inspector 模式（v0.8.0 不落地，只登记）。
同源任务: '[调研Cursor订阅到期日来源](issue_%E8%B0%83%E7%A0%94Cursor%E8%AE%A2%E9%98%85%E5%88%B0%E6%9C%9F%E6%97%A5%E6%9D%A5%E6%BA%90.md)、[调研MiniMax订阅到期日来源](issue_%E8%B0%83%E7%A0%94MiniMax%E8%AE%A2%E9%98%85%E5%88%B0%E6%9C%9F%E6%97%A5%E6%9D%A5%E6%BA%90.md)、[调研Antigravity订阅到期日来源](issue_%E8%B0%83%E7%A0%94Antigravity%E8%AE%A2%E9%98%85%E5%88%B0%E6%9C%9F%E6%97%A5%E6%9D%A5%E6%BA%90.md)、[核对Kimi已有订阅到期日来源](issue_%E6%A0%B8%E5%AF%B9Kimi%E5%B7%B2%E6%9C%89%E8%AE%A2%E9%98%85%E5%88%B0%E6%9C%9F%E6%97%A5%E6%9D%A5%E6%BA%90.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> 每个 provider 的订阅状态来源不同，工作量是 Codex 的 3-5x。先登记，等 Codex 这条线稳定后再排期。

- [ ] [0.8.0-DATA-B-000] Claude 订阅到期日：claude.ai 的 session cookie 里解析 `membership_type` / `subscription_end_date` 字段；或抓 `claude.ai/settings/plan` DOM 提取"Next billing" #deferred — 等 v0.6.0-DATA-C（Claude 真实订阅到期日 headless 抓取）落地后顺手做

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-070408_Agent

原记录标题：2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-162234_Codex

按用户最新手写模板迁移属性和正文结构，保留任务语义、来源、原始状态及历史内容；本次未重新执行业务验收。

原版本关联记录（照录来源，不将本次文档迁移提交当作业务实施提交）：
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。

本次执行环境未提供具体模型标识，未补造 Model-Detail。

[本次文档迁移对话](codex://threads/01a157b3-610c-73b4-ae06-163c0f8490d3)
