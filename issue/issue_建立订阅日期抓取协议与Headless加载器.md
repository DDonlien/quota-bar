---
title: 建立订阅日期抓取协议与Headless加载器
id: 0.6.0-ARCH-A-000
type: ARCH
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页） / feat/subscription-expiry: 建立订阅日期抓取基础架构。'
原稳定 ID: '`0.6.0-ARCH-A-000`, `0.6.0-ARCH-A-001`, `0.6.0-ARCH-A-002`, `0.6.0-ARCH-A-003`, `0.6.0-ARCH-A-003-test`, `0.6.0-ARCH-A-001-test`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.6.0-ARCH-A-000`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.6.0-ARCH-A-000`、`0.6.0-ARCH-A-001`、`0.6.0-ARCH-A-003`、`0.6.0-ARCH-A-003-test`、`0.6.0-ARCH-A-001-test`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.6.0-ARCH-A-000-ARCH-subscription-foundation-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'feat/subscription-expiry: 建立订阅日期抓取基础架构。'
同源任务: '[禁止以额度重置时间推断订阅到期日](issue_%E7%A6%81%E6%AD%A2%E4%BB%A5%E9%A2%9D%E5%BA%A6%E9%87%8D%E7%BD%AE%E6%97%B6%E9%97%B4%E6%8E%A8%E6%96%AD%E8%AE%A2%E9%98%85%E5%88%B0%E6%9C%9F%E6%97%A5.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> 提供给各 provider 复用的 headless 抓取 + DOM 提取框架。Kimi 这种直接 API 返回 expireTime 的不走这个架构，但协议入口统一。

- [x] [0.6.0-ARCH-A-000] 设计 `SubscriptionDateHarvester` 协议：每个 provider 实现 `harvest(from data: Data) async throws -> Date?`，输入是抓到的页面 Data（或 WKWebView handle），输出是订阅到期日；找不到返回 nil #P1
- [x] [0.6.0-ARCH-A-001] `WKWebViewHeadlessLoader` 实现：注入 `WKHTTPCookieStore` cookie → 加载 URL → 等 `network idle` / 特定 DOM 节点出现 → 回调 `Data` 或 `String`；可在 `FetchPipeline` strategy 中复用，超时与现有 strategy 一致 #P1
- [x] [0.6.0-ARCH-A-003] `DashboardParser` 协议加 `parseSubscriptionExpiresAt(data: Date = Date()) -> Date?`，默认实现返回 nil；Kimi `KimiSubscriptionStatParser` 实现从 `subscriptionBalance.expireTime` 提取（这一改动给 Kimi 顺带补上）#P1
- [x] [0.6.0-ARCH-A-003-test] 给 harvester 协议 + fallback 改 hide 写单元测试：mock HTML feed 解析，验证 `subscriptionExpiresAt` 正确 / 不正确两种路径 #P1
- [x] [0.6.0-ARCH-A-001-test] `WKWebViewHeadlessLoader` 集成测试：mock URLProtocol 喂 HTML，验证 cookie 注入 + DOM ready 等待 + 超时降级 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：feat-subscription-expiry.md — 历史证据迁移

来源：`agent-log/branches/feat-subscription-expiry.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 后续入口

每个 provider 一个独立 worktree / branch 子线，互不阻塞：

```
.worktrees/feat-sub-expiry-codex      feat/sub-expiry-codex
.worktrees/feat-sub-expiry-claude     feat/sub-expiry-claude
.worktrees/feat-sub-expiry-cursor     feat/sub-expiry-cursor
.worktrees/feat-sub-expiry-minimax    feat/sub-expiry-minimax
.worktrees/feat-sub-expiry-antigrav   feat/sub-expiry-antigravity
```

每个 worktree 完成一个 provider 后 ff merge 回这个 branch，5 个齐了再 ff merge 回 main。

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
