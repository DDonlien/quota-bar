---
title: 让已保存与新修改的自动刷新间隔立即生效
id: 0.10.0-BUG-A-012
type: QA
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 「刷新间隔」偏好从未真正生效。'
原稳定 ID: '`0.10.0-BUG-A-012`, `0.10.0-BUG-A-013`；不改写或重编号这些既有 ID。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> 用户反馈"我发现刷新间隔改了不会同步真的生效"。排查确认这是一个从未接通的架构性 bug：偏好设置的 Picker 只写入 `PreferencesStore.preferences.refreshIntervalSeconds` 并 persist，但 `RefreshCoordinator.refreshInterval`（自动刷新循环真正读取、dropdown「自动刷新 N 分钟」文案也读取的字段）是构造函数传入的独立值，从来没有跟这个偏好同步过——不仅运行中改动不生效，连**应用启动时**都不会读取上次保存的偏好（`StatusBarController` 构造 `RefreshCoordinator` 时没有传 `refreshInterval` 参数，永远吃构造函数自己的默认值 5 分钟）。也就是说这个偏好设置从实现以来就是摆设，不是这次改动引入的回归。

- [x] [0.10.0-BUG-A-012] `StatusBarController.init` 默认构造 `RefreshCoordinator` 时显式传入 `refreshInterval: PreferencesStore.shared.preferences.refreshIntervalSeconds`，应用启动时会真正读取上次保存的偏好，不再永远固定 5 分钟 #P0
- [x] [0.10.0-BUG-A-013] `RefreshCoordinator` 的 `.quotaPreferencesDidChange` 订阅新增 `applyRefreshIntervalChange()`：检测到 `PreferencesStore.preferences.refreshIntervalSeconds` 变化时同步更新 `self.refreshInterval`，并重启自动刷新循环（`stop()` + `start()`）让新间隔立刻生效，不需要等当前这轮 `Task.sleep` 走完、也不需要重启 app #P0 — 未新增自动化测试：`PreferencesStore.shared` 是硬编码单例、直接读写真实 `preferences.json`，没有像其余 store 那样支持注入临时目录，强行测试会触碰用户真实偏好文件，跟本次会话已确立的"不在测试里碰真实用户状态"原则冲突；已用 `swift build`/`swift test`（181 全过）验证不引入回归，逻辑本身很直接（读值、比较、必要时重启）

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260708-002700-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260708-002700-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> （前几轮：截图问 claude/antigravity 额度一会有一会没有；讨论后用户用中文重问一遍同一问题）
>
> （截图：偏好设置「通用」页显示"刷新间隔 1 分钟"，但同时打开的 dropdown 显示"自动刷新 5 分钟，上次更新 00:21"）
>
> 我发现刷新间隔改了不会同步真的生效

#### 完成工作

- `macos/Sources/QuotaBar/StatusBarController.swift`：`RefreshCoordinator` 默认构造参数补上 `refreshInterval`。
- `macos/Sources/QuotaBar/RefreshCoordinator.swift`：新增 `applyRefreshIntervalChange()` 私有方法，接入 `.quotaPreferencesDidChange` 订阅。
- `REQUIREMENTS.md`：v0.10.0 phase 新增 `[0.10.0-BUG-A-012]`/`[0.10.0-BUG-A-013]`。

#### 更新的需求 ID

- `[0.10.0-BUG-A-012]` `[0.10.0-BUG-A-013]`

#### 验证方式

- `swift build`：无警告无错误。
- `swift test`：181 tests in 42 suites 全部通过（本轮未新增自动化测试，见下方备注说明原因）。
- 未做真实端到端验证（改完偏好设置后实际观察 dropdown 文案是否立刻变化、以及缩短间隔后是否真的提前触发下一轮刷新）——逻辑直接、改动小，但没有用真实打包 app 交互确认。

#### 备注

- 未新增自动化测试：`PreferencesStore.shared` 是硬编码单例，直接读写用户真实的 `~/Library/Application Support/QuotaBar/preferences.json`，不像 `ProviderSourceIndexStore`/`ProviderCheckLogStore` 那样支持注入临时目录做测试隔离。强行写一个会 mutate 真实偏好文件的测试，会违反本次会话早前（Claude Keychain 那次）已经确立的"测试不能碰真实用户状态"原则。这属于 `PreferencesStore` 本身缺乏可测试性设计的既有问题，不在本次修复范围内展开重构。
- 未提交 git commit。

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
