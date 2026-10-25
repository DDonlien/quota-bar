---
title: 明确ad-hoc自动更新与semver发布的实施边界
id: migration-10ea5b589cf3
type: TOOL
status: 已确认约束 / 状态待核对（原文未单列完成状态）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.11.0 - 真实自动更新（ad-hoc 预开发版）+ semver 发版。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> **现状**：
> - `AboutSettingsView` 的「检查更新」是占位（点击只跳 GitHub Releases 页面）
> - `release.yml` 打的 tag 是 `nightly-<sha>`，`CFBundleShortVersionString` 硬编码成 `"1.0"`
> - `.app` 产物 `unsigned and not notarized`（`release.yml:124`），用户首次打开要「右键 → 打开」
> - 没有 helper 脚本，更新替换无任何实现
>
> **本 phase 目标**（在没有 Apple Developer Program 的前提下，把 update 机制全部跑通）：
> 1. 「检查更新」变真：调 GitHub Releases API → 解析 semver + nightly 两种 tag → 比版本 → 后台下载 → helper 替换。
> 2. 引入 semver 发版路径，保留 nightly 作为常规 push 自动打包。
> 3. helper 脚本和主 .app 都用 ad-hoc 签名（`--sign -`），先把更新流程本身打透。
>
> **本 phase 关键立场**（**延续到 v0.12.0** 的设计边界）：
> - **不引入 cert 改动**：build script 维持 `--sign -` ad-hoc 签名，**无 notarize** 步骤；首次打开仍需「右键 → 打开」（本机用一次后 macOS 记住）。
> - **TCC 权限保留为 best-effort**：ad-hoc 签名下 macOS 可能把替换后的 .app 当成新 app，正式形式化保障要等 v0.12.0 切到 Developer ID。
> - **helper 脚本也用 ad-hoc**：本机使用可接受；v0.12.0 同步升级为 Developer ID。
> - **本 phase 内任何签名相关改动都 defer 到 v0.12.0**。
>
> **与 v0.12.0 的关系**（这是关键的「延续性」设计）：
> - v0.11.0 是 v0.12.0 的**预开发版**，**不重写 update 流程**。v0.12.0 在 v0.11.0 已落地的 update 机制上**仅升级签名链 + notarize**。
> - v0.12.0 的具体差异（v0.11.0 已经完成、v0.12.0 不动的部分）：UpdateChecker / 状态机 / UI / semver workflow / helper 替换逻辑。
> - v0.12.0 唯一改的是：build script 签名身份、notarize 步骤、helper 脚本签名、cert 一致性断言、相关文档。
> - 共享资产：bundle identifier `com.taobe.quotabar` 在 v0.11.0 阶段就锁死，v0.12.0 升级 cert 时直接复用，避免 TCC 权限被清。
>
> **worktree 拆分**：所有任务在 `update/main` 单 worktree 推进；v0.12.0 在同一 worktree 继续。

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
