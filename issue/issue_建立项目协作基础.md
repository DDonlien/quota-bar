# 建立项目协作基础

- ID：`0.0.0-DOC-A-000`。
- 类型：`DOC`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.0.0 - 项目初始化 / sub/main: 建立项目协作基础。
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

来源：`agent-log/20260629-214928-utcp8-taobe-gpt-5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

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

### 20260630103110-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260630103110-utcp8-gpt5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> quota bar现在的显示的各类信息是保存在哪里的？app内还是数据文件夹，这类应用的最佳实践是什么

补充：

> 别管，继续

#### 完成工作

- 明确当前显示数据分层：
  - 额度/订阅快照：刷新时 provider 实时获取，进入内存中的 `RefreshCoordinator.state` / `DashboardState`。
  - 用户偏好：写入 `~/Library/Application Support/QuotaBar/preferences.json`。
  - 凭证/登录态：读取各服务自身配置、浏览器 Cookie 或 macOS Keychain，不由 Quota Bar 自建凭证仓库。
  - 静态样例：`PlaceholderProviders.swift` 仍存在，但当前主启动路径未使用。
- 准备向用户说明最佳实践：偏好进 Application Support/UserDefaults，敏感凭证进 Keychain，缓存快照可短期保存到 Application Support/Caches，真实来源仍应优先实时刷新并标注时间。

#### 更新的需求 ID

无。

#### 验证方式

- 静态阅读源码与文档。
- 未运行构建或测试；本次无代码行为变更。

#### 备注

- 本次只新增执行日志。

### 20260630-104521-utcp8-taobe-gpt-5.md — 历史证据迁移

来源：`agent-log/20260630-104521-utcp8-taobe-gpt-5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 创建一个新的branch、worktree，叫menubar/main

#### 完成工作

- 新增 branch：`menubar/main`
- 新增 worktree：`/Users/taobe/Projects/GitHub/Personal/quota-bar/worktree/menubar-main`
- 新 worktree 当前 `HEAD`：`1532061`

#### 更新的需求 ID

无。

#### 验证方式

- `git worktree list --porcelain` 显示 `worktree/menubar-main` 绑定 `refs/heads/menubar/main`。
- 在新 worktree 中执行 `git status --short --branch` 返回 `## menubar/main`。
- 在新 worktree 中执行 `git rev-parse --short HEAD` 返回 `1532061`。

#### 备注

- 根目录未提交改动未被带入新 worktree；后续如需在 `menubar/main` 继承这些改动，需要先提交、cherry-pick、merge 或手动同步。

### 20260701-233811-utcp8-taobe-gpt-5.md — 历史证据迁移

来源：`agent-log/20260701-233811-utcp8-taobe-gpt-5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 打包 main 上面最新版的 Quota Bar

#### 完成工作

- 生成 app 包：`macos/build/20260701-233742-main/Quota Bar.app`
- 更新最新包软链：`macos/build/latest -> 20260701-233742-main`

#### 更新的需求 ID

无。

#### 验证方式

- `make app`：通过。
- 打包脚本完成 Swift build 与 app 签名。

#### 备注

- 历史构建保留在 `macos/build/`。

### 20260701-005000-utcp8-taobe-minimax-m3.md — 历史证据迁移

来源：`agent-log/20260701-005000-utcp8-taobe-minimax-m3.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

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

来源：`agent-log/20260629-211711-utcp8-taobe-gpt-5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

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

### 20260630104059-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260630104059-utcp8-gpt5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 把这些需求纳入requirements

补充：

> 把这些需求纳入requirements

#### 完成工作

- 新增 `v0.9.0` phase，覆盖：
  - Application Support 作为 Quota Bar 自有持久化目录；
  - schema version 与安全边界；
  - provider 来源索引缓存；
  - 浏览器 Cookie / CLI 配置来源索引；
  - last-known-good 快照；
  - 启动、更新、重装、刷新期间的 stale 兜底；
  - 刷新失败或不可用时不得用旧快照假装可用；
  - 移除主路径样例数据 provider。

#### 更新的需求 ID

- 新增：
  - `0.9.0-ARCH-A-000` 至 `0.9.0-ARCH-A-002`
  - `0.9.0-DATA-A-000` 至 `0.9.0-DATA-A-003`
  - `0.9.0-DATA-B-000` 至 `0.9.0-DATA-B-005`
  - `0.9.0-UI-A-000` 至 `0.9.0-UI-A-002`

#### 验证方式

- `rg -n "Phase - v0\\.9\\.0|0\\.9\\.0-" REQUIREMENTS.md`
- `git diff -- REQUIREMENTS.md`

#### 备注

- 本次未改源码，未运行构建或测试。

### 20260702160059-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260702160059-utcp8-gpt5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 完成工作

- 新增 `QuotaPersistence.swift`：`provider-sources.json` 与 `snapshots.json`，带 `schemaVersion`，坏文件安全丢弃，文件权限收紧为 0600。
- 新增 `ZCodeAuthProvider.swift`：配置解析、quota URL 解析、Bearer 请求、Z.ai / BigModel quota JSON parser。
- 更新 `RefreshCoordinator`：stale 快照启动/刷新过渡、真实失败状态替换、缓存写入资格控制、provider-layer preferred source 复查。
- 更新 `ProviderFetchStrategy` / `Strategies` / `InstallDetectorProvider`：来源类型、layer 标记、last-success-first fallback、Z Code pipeline、安装探测结构化来源。
- 更新 UI 状态：新增 `.notSubscribed`，dropdown 显示“未订阅”，菜单栏 bar 不把未订阅算作可用额度。
- 更新 README 与 REQUIREMENTS。
- 新增/更新测试：持久化读写、Z Code parser、Codex free/旧过期归一化。

#### 更新的需求 ID

- 已完成：`0.4.0-DATA-A-000`、`0.4.0-DATA-A-001`、`0.4.0-DATA-A-004`、`0.4.0-QA-A-003`
- 已完成：`0.7.0-DATA-A-000`、`0.7.0-DATA-A-001`、`0.7.0-DATA-A-004`、`0.7.0-DATA-A-005`、`0.7.0-DOC-A-000`
- 已完成：`0.9.0-ARCH-A-000`、`0.9.0-ARCH-A-001`、`0.9.0-ARCH-A-002`
- 已完成：`0.9.0-ARCH-B-000`、`0.9.0-ARCH-B-004`、`0.9.0-ARCH-B-005`
- 已完成：`0.9.0-DATA-A-000`、`0.9.0-DATA-A-001`、`0.9.0-DATA-A-002`、`0.9.0-DATA-A-003`
- 已完成：`0.9.0-DATA-B-000`、`0.9.0-DATA-B-001`、`0.9.0-DATA-B-002`、`0.9.0-DATA-B-003`、`0.9.0-DATA-B-004`、`0.9.0-DATA-B-005`
- 已完成：`0.9.0-UI-A-000`、`0.9.0-UI-A-001`、`0.9.0-UI-A-002`
- 保持未完成：Z Code 价格知识映射、ZcodeLoginRunner、未验证 CLI/RPC/Browser DOM 节点。

#### 验证方式

- `swift build`：通过。
- `swift test`：通过，55 个测试通过。

#### 备注

- 首次 `swift build` 因沙盒无法写 `~/.cache/clang/ModuleCache` 失败，随后按授权方式重跑通过。
- Z Code 四种 builtin plan 已可归一为 tier 名称并作为 subscriptionGroup；官方价格映射仍未硬编码，避免在缺少可靠价目源时写入错误费用。

### 20260618174200-utcp8-minimax-m3.md — 历史证据迁移

来源：`agent-log/20260618174200-utcp8-minimax-m3.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

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

### 2026-10-24 07:03:43 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
