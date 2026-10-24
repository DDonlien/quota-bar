# 明确将ZCode调研结果转为正式Provider接入的范围

- ID：`migration-e7c9be5520c0`。
- 类型：`PM`。
- 状态：已确认约束 / 状态待核对（原文未单列完成状态）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`；标题路径：任务清单 / Phase - v0.7.0 - 智谱 GLM Provider 接入（feat/glm-provider）。

## 当前需求与范围

> **承接关系**：v0.4.0 phase 在用户电脑上已完成 zcode App 安装调研（`/Applications/ZCode.app`、bundle id `dev.zcode.app`、`~/.zcode/v2/` 目录布局、4 种 plan 标识），但 Provider 接入代码本身未落地。v0.7.0 把调研成果转为正式版任务，在 `feat/glm-provider` branch 上推进。
>
> **zcode 是什么**：智谱 BigModel Z Code（`https://zcode.z.ai`）桌面 IDE，是 opencode 的 fork/skin，走 anthropic 兼容 API；4 种 plan（`builtin:bigmodel-start-plan` / `builtin:bigmodel-coding-plan` / `builtin:zai-start-plan` / `builtin:zai-coding-plan`）覆盖智谱开放平台 + Z.ai 海外版两套站点。
>
> **为什么叫 GLM 而不是 zcode**：用户对外沟通时用「GLM」（智谱模型族名）覆盖度更广；内部 provider 名沿用 `zcode`（与 bundle id / config 路径一致），UI 显示名用 `Z Code`。
>
> **与 v0.6.0 第二批的关系**：v0.7.0 不属于 v0.6.0 第二批（第二批是 headless 抓订阅页拿订阅到期日）。GLM 接入是独立工作线（要做完整 provider + 套餐映射），所以单独立 phase。

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260618112258-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260618112258-utcp8-mavis.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 创建新的worktree，实现ui-c

#### 完成工作

1. **创建 `.gitignore`**（`/Users/taobe/Projects/GitHub/Personal/quota-bar/.gitignore`）
   - 排除 `.DS_Store`、`.build/`、`.swiftpm/`、xcuserdata
   - 排除 `.worktrees/`，避免 worktree 内容污染主仓库 `git status`
2. **创建 worktree**
   - 命令：`git worktree add -b feat/ui-c .worktrees/ui-c main`
   - 路径：`/Users/taobe/Projects/GitHub/Personal/quota-bar/.worktrees/ui-c`
   - 分支：`feat/ui-c`
   - 基线：`main` @ `43fe088`
3. **验证 worktree 状态**：`git worktree list` 显示三条记录（main / feature/ref-a / feat/ui-c），新 worktree HEAD 停在 43fe088 与 main 一致

#### 需求更新

- `REQUIREMENTS.md`：未变更。本任务仅创建工作分支，不应在未实现前勾选 UI-C 子需求
- `README.md` / `DESIGN.md`：未变更

#### 验证方式

- `git pull --ff-only`：返回 `Already up to date.`
- `git worktree list`：返回三条记录，feat/ui-c 已就位
- `git worktree add` 输出：`Preparing worktree (new branch 'feat/ui-c') / HEAD is now at 43fe088`

#### 备注

- 分支命名沿用 `feat/<id>` 短前缀，区别于仓库外现存 worktree 的 `feature/ref-a`，但两者都指向 P1 阶段同一模块链（REF-A → UI-C）
- worktree 路径采用仓库内 `.worktrees/ui-c`，依赖 `.gitignore` 防止脏 status
- 本日志仅记录 worktree 创建动作；UI-C 实际实现的对话、决策与勾选会落在后续日志中
- 下一步建议：进入 `.worktrees/ui-c` 目录，`git pull` 拉 `feature/ref-a` 的刷新机制 API（如已合入），再开始 UI-C 编码

### 20260618174200-utcp8-minimax-m3.md — 历史证据迁移

来源：`agent-log/20260618174200-utcp8-minimax-m3.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

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

### feat-subscription-expiry.md — 历史证据迁移

来源：`agent-log/branches/feat-subscription-expiry.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

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

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
