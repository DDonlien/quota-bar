---
title: 恢复KimiWork月额度与WebView接口解析
id: 0.14.0-BUG-B-000
type: QA
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.14.0 - 大陆可达性兜底 + 额度节奏指示 + Kimi 额度修复 / sub/main: Kimi CLI OAuth 5 小时/周额度丢失修复。'
原稳定 ID: '`0.14.0-BUG-A-000`, `0.14.0-QA-C-000`, `0.14.0-DOC-B-000`, `0.14.0-BUG-B-000`, `0.14.0-BUG-B-001`, `0.14.0-QA-C-001`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.14.0-BUG-A-000`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.14.0-BUG-B-000`、`0.14.0-BUG-B-001`、`0.14.0-QA-C-001`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.14.0-BUG-A-000-QA-kimi-cli-oauth-quota-fixes-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'sub/main: Kimi CLI OAuth 5 小时/周额度丢失修复。'
同源任务: '[只读KimiCLI凭证并在内存刷新OAuth](issue_%E5%8F%AA%E8%AF%BBKimiCLI%E5%87%AD%E8%AF%81%E5%B9%B6%E5%9C%A8%E5%86%85%E5%AD%98%E5%88%B7%E6%96%B0OAuth.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

共同范围与完整历史见[只读KimiCLI凭证并在内存刷新OAuth](issue_%E5%8F%AA%E8%AF%BBKimiCLI%E5%87%AD%E8%AF%81%E5%B9%B6%E5%9C%A8%E5%86%85%E5%AD%98%E5%88%B7%E6%96%B0OAuth.md)；本文件保留以下独立目标的原文。

- [x] [0.14.0-BUG-B-000] `KimiSubscriptionParser.parse` 的 Work 窗口把 `resetsAt` 从 `nil` 改成
  `expireTime`（`refreshDescription` 早就在用同一个日期，写进 `resetsAt` 不引入新的不确定性）
- [x] [0.14.0-BUG-B-001] `DashboardEndpoints.endpoint(for: .kimi)`（`kimi-webview` 用的端点）从
  `GetSubscriptionStat` + `KimiSubscriptionStatParser` 改成跟 `KimiDesktopTokenProvider` 一致的
  `GetSubscription` + `KimiSubscriptionParser`
- [x] [0.14.0-QA-C-001] `KimiSubscriptionParserBalancesTests` 更新第一个测试的 `resetsAt` 断言；
  `swift test` 217/217 通过

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 历史记录-时间未记录

原迁移条目的历史Comments完整保留于[同源历史](issue_%E5%8F%AA%E8%AF%BBKimiCLI%E5%87%AD%E8%AF%81%E5%B9%B6%E5%9C%A8%E5%86%85%E5%AD%98%E5%88%B7%E6%96%B0OAuth.md#comments)，不从历史日志新增完成标记。

原记录时间、具体执行 Agent、模型与原会话未记录，未补造。

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
