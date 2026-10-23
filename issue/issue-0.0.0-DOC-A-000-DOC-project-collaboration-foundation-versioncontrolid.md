# sub/main: 建立项目协作基础

- ID：`0.0.0-DOC-A-000`。
- 类型：`DOC`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`；标题路径：任务清单 / Phase - v0.0.0 - 项目初始化 / sub/main: 建立项目协作基础。
- 原稳定 ID：`0.0.0-DOC-A-000`, `0.0.0-DOC-A-001`, `0.0.0-DOC-A-002`, `0.0.0-DOC-A-003`, `0.0.0-DOC-A-004`, `0.0.0-DOC-A-005`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.0.0-DOC-A-000] 建立项目协作基础 #docs #P0
- [x] [0.0.0-DOC-A-001] 基于 `agent-template` 创建根目录 `AGENTS.md`
- [x] [0.0.0-DOC-A-002] 基于 `agent-template` 创建根目录 `README.md`
- [x] [0.0.0-DOC-A-003] 基于 `agent-template` 创建根目录 `REQUIREMENTS.md` #cut 旧工作制度已由本轮 Issue 流程替代；原勾选只保留历史事实。
- [x] [0.0.0-DOC-A-004] 基于 `agent-template` 创建根目录 `DESIGN.md`
- [x] [0.0.0-DOC-A-005] 创建根目录 `agent-log/` #cut 旧工作制度已由本轮 Issue 流程替代；原勾选只保留历史事实。

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260629-214928-utcp8-taobe-gpt-5.md — 历史证据迁移

来源：`agent-log/20260629-214928-utcp8-taobe-gpt-5.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

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

### 20260701-005000-utcp8-taobe-minimax-m3.md — 历史证据迁移

来源：`agent-log/20260701-005000-utcp8-taobe-minimax-m3.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 1. 验证 a43eef8 commit 的所有 4 个修复

代码层面对照：

| Issue | 修复位置 | 验证结果 |
|---|---|---|
| FAQ q1+a1 重复 | `FAQ.astro:16-50` 只剩 q2-q4；`dict.ts` faq 段无 q1/a1 | ✓ |
| approve heading | `dict.ts:37` `"Every model, every tier — one dropdown away."` 40 字符 | ✓ |
| Nav 边界 fade | `Nav.astro:64-80` `::after` 1px linear-gradient(透明→0.05→0.10→0.05→透明) | ✓ |
| Nav 居中对齐 | `Nav.astro:82-91` `.site-nav__inner` 加 `max-width: 1060px` + `margin-inline: auto` | ✓ |

#### 2. 运行时验证（Playwright @ 1280×900 viewport）

DOM 量测结果：

- `navAfter`: height 1px, background = linear-gradient(...transparent 0% → 0.05 12% → 0.10 50% → 0.05 88% → transparent 100%) — fade 梯度生效
- `.site-nav__inner`: max-width 1060px, margin-inline auto, padding 12px 24px
- nav logo `getBoundingClientRect().left = 134`, actions `right = 1146`
- product preview heading `x = 134, right = 1146, width = 1012` — 左右边与 header 完全对齐
- approve heading: text "Every model, every tier — one dropdown away.", height 31.2px, lineHeight 31.2px → **1 行**
- reorder heading（自动轮播到 adjust tab）: "Reorder any asset by drag — the menu bar follows instantly.", 同样 1 行
- FAQ DOM: 只剩 `Is it secure? / Does it work on Windows? / Is this a subscription?` 3 项

#### 验证方式

- `curl http://localhost:4321/` → HTTP 200
- Playwright `browser_take_screenshot` × 4 + DOM 量测 × 3（navAfter / previewHeading / FAQ questions）
- `rg "faq\.(q|a)1"` → 0 matches
- `rg "product\.heading\.approve"` → 2 matches（en + zh dict），均为短文案

#### 备注

- 上一轮 ef75a4d（fade 增强 + visibility 补偿）之后用户回的是 4 个视觉问题，本轮 a43eef8 已全部覆盖。
- 当前 site/main 相对 origin/site-main ahead 8 commits；如果用户确认通过，下一轮可以直接 `git push origin site/main`。
- 用户没要求文档同步（REQUIREMENTS.md / DESIGN.md 都没动）—— 这次只动了 4 个文件，scope 收紧。

### 20260629-211711-utcp8-taobe-gpt-5.md — 历史证据迁移

来源：`agent-log/20260629-211711-utcp8-taobe-gpt-5.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

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

### 20260618174200-utcp8-minimax-m3.md — 历史证据迁移

来源：`agent-log/20260618174200-utcp8-minimax-m3.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

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
