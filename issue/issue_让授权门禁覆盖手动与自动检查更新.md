---
title: 让授权门禁覆盖手动与自动检查更新
id: 0.15.3-BUG-A-000
type: DATA
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.15.3 - 检查更新门禁补全（手动点击此前会绕过）+ 测试隔离 + flaky 修复 / sub/main: check() 门禁覆盖手动路径。'
原稳定 ID: '`0.15.3-BUG-A-000`, `0.15.3-BUG-A-001`, `0.15.3-DATA-A-000`, `0.15.3-QA-A-000`, `0.15.3-QA-A-001`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.15.3-BUG-A-000`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.15.3-BUG-A-000`、`0.15.3-BUG-A-001`、`0.15.3-DATA-A-000`、`0.15.3-QA-A-000`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.15.3-BUG-A-000-DATA-check-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'sub/main: check() 门禁覆盖手动路径。'
同源任务: '[固定倒计时测试基准时间以消除截断抖动](issue_%E5%9B%BA%E5%AE%9A%E5%80%92%E8%AE%A1%E6%97%B6%E6%B5%8B%E8%AF%95%E5%9F%BA%E5%87%86%E6%97%B6%E9%97%B4%E4%BB%A5%E6%B6%88%E9%99%A4%E6%88%AA%E6%96%AD%E6%8A%96%E5%8A%A8.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

- [x] [0.15.3-BUG-A-000] `UpdateChecker.check()` 原本门禁条件是 `!userInitiated && !licenseAllowsAutomaticUpdates`——只挡自动/后台触发，手动点击（`userInitiated: true`）完全绕过。改成门禁对两条路径统一生效：`!licenseAllowsAutomaticUpdates` 就挡，不再看是谁触发的
- [x] [0.15.3-BUG-A-001] 挡住后的反馈按触发方式分层：手动点击要给可见反馈（`state = .error("检查更新需要激活…")`），不能让用户点了按钮却像什么都没发生；自动/后台触发保持静默（不改 `state`），不必每次打开关于页或每轮后台轮询都跳一条错误
- [x] [0.15.3-DATA-A-000] `licenseStateProvider` 从"构造后可改的公开 var（默认闭包读 `LicenseManager.shared`）"改成正规的 init 参数注入点，对齐 `preferences`/`checkLogStore` 已有的 DI 模式
- [x] [0.15.3-QA-A-000] 新增 `manualCheckBlockedWhenUnlicensed` / `automaticCheckSkippedWhenUnlicensedStaysQuiet` 两个测试，断言门禁生效时**不发起真实请求**且两种触发方式的可见状态符合各自预期。修复过程中顺带发现：收紧门禁前，`UpdateCheckerFallbackTests.swift` 里全部 4 个用 `userInitiated: true` 构造 `UpdateChecker` 的既有测试都没有注入 `licenseStateProvider`，靠默认值悄悄读了 `LicenseManager.shared.state`——也就是跑测试这台机器当下真实的试用状态；这次改动让门禁真正对 `userInitiated: true` 生效后，这 4 个测试因为开发机试用已过期而集体变红，暴露了这个此前一直存在但被"手动检查不受门禁约束"这个旧设计意外掩盖的测试隔离漏洞。已给全部 4 处补上确定的 `.trial(daysRemaining: 7)` 注入

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
