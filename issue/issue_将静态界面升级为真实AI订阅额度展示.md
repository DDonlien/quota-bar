---
title: 将静态界面升级为真实AI订阅额度展示
id: migration-380a479e8fcc
type: PM
status: 已确认约束 / 状态待核对（原文未单列完成状态）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`；标题路径：任务清单 / Phase - v0.2.0 - Quota Bar 核心功能。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

本阶段参考 CodexBar 实现思路，将现有静态 UI 升级为自动探测、获取并展示真实 AI 订阅额度的功能核心。优先聚焦数据获取与刷新机制，偏好设置页面延后至 P2。

> **2026-06-18 更新**：本次 `feat/real-data-and-public` 分支落地的范围如下。括号内是落地位置。
> - **真实数据接入（P0）**：SweetCookieKit 集成 / TCC 引导 / Keychain 真读 / Codex dashboard endpoint + parser
> - **可扩展性（P1）**：`ProviderFetchStrategy` + `FetchPipeline` + `TTYCommandRunner` + `LoginRunner` + AgentDetector 类型合一

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260618205739-utcp8-minimax-m3.md — 历史证据迁移

来源：`agent-log/20260618205739-utcp8-minimax-m3.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 你来改

接续上一轮对话：用户对「菜单栏应用在系统设置里到底叫什么名字」提出疑问（因为 `CodingPlanMenu` 和 Quota Bar 是同一个东西，担心找错应用、给错权限）。我提议修改 [build-app.sh](file:///Users/taobe/Projects/GitHub/Personal/quota-bar/drop-down-test/CodingPlanMenu/build-app.sh) 的 `CFBundleDisplayName` 为 "Quota Bar"，用户回复「你来改」。

#### 验证方式

- 静态：cat 已确认第 35 行值为 `Quota Bar`；第 31 / 33 / 37 行 bundle id / bundle name / bundle executable 仍是 `CodingPlanMenu` / `com.example.CodingPlanMenu`
- 构建：未运行（沙箱限制同上一条日志）；重新运行 `./build-app.sh` 后生成的 `Info.plist` 将包含 `Quota Bar`
- 应用行为：未启动应用验证（用户在系统设置里看到的应用名才是验证点）

#### 需求 / 设计更新

- `REQUIREMENTS.md`：未变更
- `README.md`：未变更
- `DESIGN.md`：未变更
- `AGENTS.md`：未变更

#### 备注

- 本次修改未提交，等用户决定是否一并把 `build-app.sh` 与上一轮的 padding 改动一起 commit
- Keychain 授权提示：「Quota Bar 需要 Keychain 授权」已经与新 DisplayName 一致，不会出现名字错位
- 用户在系统设置 → 隐私与安全 → 完全磁盘访问权限 中，应能找到「Quota Bar」应用并勾选；如果之前已经按 `CodingPlanMenu` 授权过，按 bundle id 仍会匹配，状态保持不变
- 之前给用户的引导语（"找 Quota Bar 应用授权"）从这一版打包后开始真正生效

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260620144300-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260620144300-utcp8-gpt5.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

You are running as a local coding agent for a Multica workspace.

Your assigned issue ID is: 4a47a0c0-4dff-47bc-8005-6bbeaf541755

Start by running `multica issue get 4a47a0c0-4dff-47bc-8005-6bbeaf541755 --output json` to understand your task, then complete it.
For comment history, follow the rule in your runtime workflow file (assignment-triggered tasks treat the read as mandatory). `multica issue comment list 4a47a0c0-4dff-47bc-8005-6bbeaf541755 --output json` returns all comments for the issue (server caps at 2000). On long-running issues use `--recent 20 --output json` to read the 20 most recently active threads, then page older threads via the stderr `Next thread cursor: ...` line and the matching `--before` / `--before-id` until you have enough history. `--since <RFC3339>` is still available for incremental polling and may combine with `--recent`.

#### 需求更新

- 未修改 `REQUIREMENTS.md`。本次只把未完成需求录入 Multica 子 issue 并触发其他 agent 执行。

#### 验证方式

- `multica issue list --project 138f4c9d-2ea2-4e5f-bd8a-f65785d3b16e --limit 20 --output json` 确认 TB-37、TB-38、TB-39 已创建，且均挂在 TB-28 下。

#### 备注

- 本次没有代码变更，不运行 `swift build`。
- `git pull` 因长时间无输出被中断；已记录在本日志和交付说明中。

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
