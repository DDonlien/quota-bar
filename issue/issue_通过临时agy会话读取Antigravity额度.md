---
title: 通过临时agy会话读取Antigravity额度
id: 0.10.0-DATA-B-006
type: DATA
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: AGY 真实 CLI 层 + Claude 额度修复 + 获取方案审计。'
原稳定 ID: '`0.10.0-DATA-B-006`, `0.10.0-DATA-B-007`, `0.10.0-DATA-B-008`, `0.10.0-DOC-A-001`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.10.0-DATA-B-006`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.10.0-DATA-B-006`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.10.0-DATA-B-006-DATA-agy-cli-claude-quota-fixes-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'sub/main: AGY 真实 CLI 层 + Claude 额度修复 + 获取方案审计。'
同源任务: '[按真实响应解析Claude五小时与周额度](issue_%E6%8C%89%E7%9C%9F%E5%AE%9E%E5%93%8D%E5%BA%94%E8%A7%A3%E6%9E%90Claude%E4%BA%94%E5%B0%8F%E6%97%B6%E4%B8%8E%E5%91%A8%E9%A2%9D%E5%BA%A6.md)、[按候选命令名定位MiniMax与AntigravityCLI](issue_%E6%8C%89%E5%80%99%E9%80%89%E5%91%BD%E4%BB%A4%E5%90%8D%E5%AE%9A%E4%BD%8DMiniMax%E4%B8%8EAntigravityCLI.md)、[核对README获取矩阵的来源优先级](issue_%E6%A0%B8%E5%AF%B9README%E8%8E%B7%E5%8F%96%E7%9F%A9%E9%98%B5%E7%9A%84%E6%9D%A5%E6%BA%90%E4%BC%98%E5%85%88%E7%BA%A7.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> 用户用 `agy` 进入交互 CLI、`/usage` 查看额度演示了真实操作路径；同时反馈 Claude webview 授权后仍无额度；并指出 README 矩阵存在同列多个同优先级（Codex 两个 P2、GLM 两个 P2 两个 P3 等）的错误，要求全面审计矩阵与实现一致性。

- [x] [0.10.0-DATA-B-006] `AntigravityCLISessionProvider`：IDE / 已运行 agy 进程都不可用时，拉起临时 `agy` 交互会话（`/usr/bin/script` 提供 PTY）、复用其本地 RPC（委托 `AntigravityDashboardProvider(.cli)`）取结构化额度，成功或超时后立即终止会话；接入 antigravity 管线排在 `antigravity-cli` 之后、keychain 之前 #P0 — 不驱动 `/usage` TUI 文本解析（`agy --print "/usage"` 实测会被当自然语言 prompt 消耗额度，明确排除）

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-070343_Agent

原记录标题：2026-10-24 07:03:43 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-162234_Codex

按用户最新手写模板迁移属性和正文结构，保留任务语义、来源、原始状态及历史内容；本次未重新执行业务验收。

原版本关联记录（照录来源，不将本次文档迁移提交当作业务实施提交）：
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。

本次执行环境未提供具体模型标识，未补造 Model-Detail。

[本次文档迁移对话](codex://threads/01a157b3-610c-73b4-ae06-163c0f8490d3)
