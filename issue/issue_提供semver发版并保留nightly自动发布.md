---
title: 提供semver发版并保留nightly自动发布
id: 0.11.0-CI-A-000
type: CI
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.11.0 - 真实自动更新（ad-hoc 预开发版）+ semver 发版 / update/main: 引入 semver 发版路径。'
原稳定 ID: '`0.11.0-CI-A-000`, `0.11.0-CI-A-001`, `0.11.0-CI-A-002`, `0.11.0-CI-A-003`, `0.11.0-CI-A-004`, `0.12.0-SEC-A-005`, `0.11.0-CI-A-002-test`；不改写或重编号这些既有 ID。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> 保留 nightly 作为默认 push 自动打包路径；新增 `workflow_dispatch` 触发的 semver 发版路径。
> 引入 semver 并不意味着丢弃 nightly —— nightly 仍是 dev 日常节奏，semver 是「对外稳定版」标记。

- [x] [0.11.0-CI-A-000] `release.yml` 新增 `workflow_dispatch` 输入项 `version`（形如 `v0.11.0`），触发 semver 发版；main 自动 push 路径继续产出 `nightly-<sha>` 不变 #P1
- [x] [0.11.0-CI-A-001] semver 发版路径 tag = `version` 输入值（如 `v0.11.0`）、`prerelease: false`；产物上传到同名 GitHub Release；DMG 名称 `QuotaBar-<version>.dmg`；macOS `CFBundleShortVersionString` 同步写入 `0.11.0`（去前导 `v`）#P1
- [x] [0.11.0-CI-A-002] `build-app.sh` 接受 `VERSION` 环境变量：默认空时走 nightly 行为（`CFBundleShortVersionString = "1.0"` 保持），传入 `v0.11.0` 时写入 `CFBundleShortVersionString = "0.11.0"`；脚本内对 `VERSION` 走严格 `vX.Y.Z` 校验，非合法格式立即 fail，不静默回退 #P1
- [x] [0.11.0-CI-A-003] `CFBundleVersion` / `QBDisplayBuild` 统一日期戳 `YYMMDD.HHMMSS.branch`（当前已部分实现，验证 nightly 与 semver 两条路径都走同一逻辑）#P1
- [x] [0.11.0-CI-A-004] `release.yml` 注释维持 `unsigned and not notarized`，与本 phase ad-hoc 实际行为一致；v0.12.0 升级 cert 时再更新注释为实际签名 + notarize 步骤（升级版见 [0.12.0-SEC-A-005]）#P1
- [x] [0.11.0-CI-A-002-test] 测试 `build-app.sh` 在 `VERSION=v0.11.0` / `VERSION=` / `VERSION=garbage` 三种情况下 Info.plist 写入行为分别正确 #P1 — 2026-07-05 手动验证：garbage 立即 fail、v0.11.0 写入 0.11.0、空写入 1.0

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-070343_Agent

原记录标题：2026-10-24 07:03:43 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-162234_Codex

按用户最新手写模板迁移属性和正文结构，保留任务语义、来源、原始状态及历史内容；本次未重新执行业务验收。

原版本关联记录（照录来源，不将本次文档迁移提交当作业务实施提交）：
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。

本次执行环境未提供具体模型标识，未补造 Model-Detail。

[本次文档迁移对话](codex://threads/01a157b3-610c-73b4-ae06-163c0f8490d3)
