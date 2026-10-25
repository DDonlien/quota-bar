---
title: 建立项目协作基础
id: 0.0.0-DOC-A-000
type: DOC
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `1532061d80cab44eba9d5469836105dedd72a7e8`；标题路径：任务清单 / Phase - v0.0.0 - 项目初始化 / sub/main: 建立项目协作基础。'
原稳定 ID: '`0.0.0-DOC-A-000`, `0.0.0-DOC-A-001`, `0.0.0-DOC-A-002`, `0.0.0-DOC-A-003`, `0.0.0-DOC-A-004`, `0.0.0-DOC-A-005`；不改写或重编号这些既有 ID。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

- [x] [0.0.0-DOC-A-000] 建立项目协作基础 #docs #P0
- [x] [0.0.0-DOC-A-001] 基于 `agent-template` 创建根目录 `AGENTS.md`
- [x] [0.0.0-DOC-A-002] 基于 `agent-template` 创建根目录 `README.md`
- [x] [0.0.0-DOC-A-003] 基于 `agent-template` 创建根目录 `REQUIREMENTS.md` #cut 旧工作制度已由本轮 Issue 流程替代；原勾选只保留历史事实。
- [x] [0.0.0-DOC-A-004] 基于 `agent-template` 创建根目录 `DESIGN.md`
- [x] [0.0.0-DOC-A-005] 创建根目录 `agent-log/` #cut 旧工作制度已由本轮 Issue 流程替代；原勾选只保留历史事实。

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260629-214928-utcp8-taobe-gpt-5.md — 历史证据迁移

来源：`agent-log/20260629-214928-utcp8-taobe-gpt-5.md` @ `1532061d80cab44eba9d5469836105dedd72a7e8`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 合理，改回来，一并修改agent-template里的agents.md

#### 完成工作

- 项目根目录重新成为 `main` 工作区。
- `worktree/` 保持单数目录名，并只承载其他分支工作区。
- GitHub Desktop / Codex / 其他 Agent 可重新以项目根目录作为 repo 入口。
- `agent-template/AGENTS.md` 已同步为该折中规则。

#### 更新的需求 ID

- `0.8.0-DOC-A-007`：标记 `#cut`，说明撤回原因。
- `0.8.0-DOC-A-008`：标记 `#cut`，说明撤回原因。
- `0.8.0-DOC-A-009`：标记 `#cut`，说明撤回原因。
- 新增并完成 `0.8.0-DOC-A-010`。
- 新增并完成 `0.8.0-DOC-A-011`。

#### 验证方式

- `git rev-parse --show-toplevel` 返回项目根目录。
- `git worktree list --porcelain` 第一项为项目根目录 `main`，其他分支在 `worktree/` 下。
- `worktree/*/.git` 指向根 `.git/worktrees/...`。
- 文档扫描确认活规则不再要求默认使用 `.repo/` 或 `worktree/main/`。

#### 备注

- `site/src/components/Footer.astro`、`MenuBarMockup.astro`、`Nav.astro`、`site/src/layouts/Layout.astro` 与 logo 图片在本轮前已存在未提交改动；本轮只保留，不解释其业务内容。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260629-211711-utcp8-taobe-gpt-5.md — 历史证据迁移

来源：`agent-log/20260629-211711-utcp8-taobe-gpt-5.md` @ `1532061d80cab44eba9d5469836105dedd72a7e8`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 我commit了，然后我修改了agent-template里的agents.md文档，要求main也一并放在worktree下了，并且worktree应该跟随其他文件夹一样总是单数，为我完成更大规模的整理

#### 完成工作

- 容器根目录现在只保留 `.repo/` 和 `worktree/`。
- `main` 实际工作区已迁入 `worktree/main/`。
- 其他 worktree 路径已统一为 `worktree/<name>/`。
- `.repo/.git` 成为主仓库 Git 元数据入口。
- 文档已同步更新到单数 `worktree/` 规则。

#### 更新的需求 ID

- `0.8.0-DOC-A-006`
- `0.8.0-DOC-A-007`
- `0.8.0-DOC-A-008`
- `0.8.0-DOC-A-009`

#### 验证方式

- `git rev-parse --show-toplevel` 在 `worktree/main/` 返回 `/Users/taobe/Projects/GitHub/Personal/quota-bar/worktree/main`。
- `git status --short --branch` 在 `worktree/main/` 正常显示 `main...origin/main`，仅剩本轮文档改动。
- `git worktree list --porcelain` 显示所有附加 worktree 位于 `worktree/` 下。
- `git status --short --branch` 在 `worktree/feat-glm-provider` 正常运行。
- `make build`：通过。首次因 SwiftPM 缓存记录旧路径失败，清理 `macos/.build` 后通过。
- `make test`：通过，20 tests in 4 suites passed。
- `npm run build`（`site/`）：通过，产出 `site/dist/`。

#### 备注

- `git worktree list` 的第一行仍显示 `.repo`，这是 Git 对主仓库 gitdir 所在目录的展示方式；实际 `core.worktree` 和 `git rev-parse --show-toplevel` 均指向 `worktree/main/`，`.repo/` 内没有业务文件。
- `worktree/feat-preferences` 在任务开始前已有未提交业务改动，本轮未修改也未回滚。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260618174200-utcp8-minimax-m3.md — 历史证据迁移

来源：`agent-log/20260618174200-utcp8-minimax-m3.md` @ `1532061d80cab44eba9d5469836105dedd72a7e8`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 检查所有的 work tree，用最新的版本合并到主分支，从而实现让这个工具真的可以获取到本机的订阅信息

#### 各 worktree 扫描结果

| Worktree | 分支 | HEAD | 与 main 关系 | 关键内容 |
|----------|------|------|--------------|----------|
| `/Users/taobe/Projects/GitHub/Personal/quota-bar` | main | 43fe088 | base | UI prototype |
| `/Users/taobe/Projects/GitHub/Personal/quota-bar-sub-a` | feat/sub-a-subscription-fetching | 43fe088 | 同 main | 仅文档改动 |
| `/Users/taobe/Projects/GitHub/Personal/quota-bar.ref-a` | feature/ref-a | 43fe088 | 同 main | 仅文档改动 |
| `/Users/taobe/Projects/GitHub/Personal/quota-bar/.worktrees/feat-real-data-and-public` | **feat/real-data-and-public** | **158fcd2** | **5 commits ahead** | **真实数据接入 + 策略管线 + 发布准备** |
| `/Users/taobe/Projects/GitHub/Personal/quota-bar/.worktrees/ui-c` | feat/ui-c | 43fe088 | 同 main | 未提交 UI 草稿（DashboardState/DashboardViewModel/MockQuotaService） |
| `/Users/taobe/Projects/GitHub/Personal/quota-bar/.worktrees/investigate-codex-bar` | investigate/codex-bar | 43fe088 | 同 main | 未提交调研笔记 |

结论：`feat/real-data-and-public` 是唯一显著领先且具备真实数据获取能力的分支，为用户要求的「最新版本」。

#### 验证方式

- 静态：`git log --oneline` 显示 5 个新 commit 已落地；[Sources/CodingPlanMenu/](file:///Users/taobe/Projects/GitHub/Personal/quota-bar/drop-down-test/CodingPlanMenu/Sources/CodingPlanMenu) 现在含 20 个 Swift 文件
- 静态：grep `MenuDashboardStyle\.` 在 MenuView.swift 中全部命中 14 个独立常量
- 构建：`swift build` 失败，`error: invalid manifest` 叠加 `sandbox_apply: Operation not permitted`（沙箱无法写缓存 / 无法解析 SweetCookieKit 网络依赖）。此为环境限制，代码层面无错误。
- 未运行应用验证

#### 需求 / 设计更新

- `REQUIREMENTS.md`：merge 已包含 P0/P1 项目的勾选状态更新；stash 中我的额外说明段被丢弃（不影响主需求状态）
- `README.md` / `CHANGELOG.md`：merge 已引入全新版本
- `DESIGN.md`：未变更

#### 备注

- merge 未 push（5 commits 待 `git push origin main`，需用户授权）
- 主 worktree 上的 4 个 padding 相关的 agent-log + padding control.csv 仍是 untracked；用户可选择是否一并提交
- feat 分支原始的 `summaryFirstRowTopPadding = 4` 与本会话最新 spec（=8）不同步；本回合已在 main 上做单点修复；如要让 feat 分支也同步，需要再做一个 feat 分支上的 commit
- 主 worktree 上 MenuView.swift 还有 5 个死代码 legacy 常量（`summarySpacing: 2`、`sectionSpacing: 8`、`quotaRowsSpacing: 6`、`quotaRowSpacing: 2`、`contentBlockSpacing: 6`），是 feat 分支带过来的；上一轮曾在 main 的工作副本中清理过，merge 后被恢复。本回合未再次清理，等用户决定
- 沙箱限制导致 `swift build` 无法在本环境执行；如需验证构建，请退出沙箱后运行

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
