---
title: 调研智谱ZCode套餐与额度接入
id: 0.4.0-DATA-A-000
type: DATA
status: 待处理（原文未完成项保持未勾选）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`；标题路径：任务清单 / Phase - v0.4.0 - 新 Provider 接入（zcode / 千问 / 其他） / feat/glm-provider: 调研智谱 BigModel Z Code Provider。'
原稳定 ID: '`0.4.0-DATA-A-000`, `0.4.0-DATA-A-001`, `QuotaWindow`, `0.4.0-DATA-A-002`, `0.4.0-DATA-A-003`, `0.4.0-DATA-A-004`；不改写或重编号这些既有 ID。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

- [ ] [0.4.0-DATA-A-000] 在 `ProviderKind` enum 新增 `.zcode` 枚举值，`displayName = "Z Code"`、`brandColor`、`iconSymbol`、`bundleIdentifier = "dev.zcode.app"`、`credentialFiles = ["~/.zcode/v2/credentials.json"]`、`envVarNames = []` 等元数据补齐 #P1
- [ ] [0.4.0-DATA-A-001] `ZCodeAuthProvider` 实现：从 `~/.zcode/v2/config.json` 读启用 plan 的 API key + baseURL，对 plan endpoint 发 anthropic 兼容 API 拉 usage；解析剩余额度到 `[QuotaWindow]` #P1
- [ ] [0.4.0-DATA-A-002] 套餐映射：识别 `builtin:bigmodel-start-plan` / `builtin:bigmodel-coding-plan` / `builtin:zai-start-plan` / `builtin:zai-coding-plan` 4 种 plan，subscriptionGroup 按 plan 区分（每个 plan = 1 个订阅组）；价格映射到 `ProviderPricing` #P1
- [ ] [0.4.0-DATA-A-003] `ZcodeLoginRunner` + `InstallDetectorProvider`：探测 `dev.zcode.app` bundle 安装和 `~/.zcode/v2/config.json` 存在性，驱动 pipeline 串接 #P1
- [ ] [0.4.0-DATA-A-004] `Strategies.zcodePipeline()` 接入 `RefreshCoordinator`，凭证缺失时 fallback 到 Keychain / `needsConfiguration` 状态 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260627224800-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260627224800-utcp8-mavis.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 在本地每个branch开一个worktree工作

#### 验证

`git worktree list` 5 行（main + 4 feat）：

```
/Users/taobe/Projects/GitHub/Personal/quota-bar                                      79116cc [main]
/Users/taobe/Projects/GitHub/Personal/quota-bar/.worktrees/feat-glm-provider         fbda212 [feat/glm-provider]
/Users/taobe/Projects/GitHub/Personal/quota-bar/.worktrees/feat-hide-preferences     fcdd62f [feat/hide-preferences]
/Users/taobe/Projects/GitHub/Personal/quota-bar/.worktrees/feat-subscription-expiry  369e055 [feat/subscription-expiry]
/Users/taobe/Projects/GitHub/Personal/quota-bar/.worktrees/feat-website              e974437 [feat/website]
```

每个 worktree 逐个 `git rev-parse --abbrev-ref HEAD` / `git log -1` / `git status --short`
校验：4 个都指向正确 branch + 正确 commit，working tree clean。

#### 完成工作

开好 4 个本地 worktree，让 4 条独立工作线可以并行推进，互不污染 working tree。

#### 更新的需求 ID

无（worktree 操作不是需求实现，是工作流基础设施）。

#### 验证方式

- `git worktree list` 输出 5 行（main + 4 feat）
- 每个 worktree `git status --short` 都为空（clean）
- `.gitignore:37` 确认 `.worktrees/` 已 ignore，无需补充

#### 备注

- 4 个 worktree 共享同一个 `.git/` 数据库，但每个有独立 working tree 和独立 `.build/` 缓存
- macOS app 的 `.build/` 体积较大（一次完整 build 几百 MB），4 个 worktree 会有 4 份缓存——磁盘吃紧时考虑只开 1-2 个 worktree 串行做，或者建 `BUILT_PRODUCTS_DIR` 共享 build 产物
- 主 worktree (`/Users/taobe/Projects/GitHub/Personal/quota-bar`) 仍保持 main，可随时 `git merge --ff-only` 收 4 条线成果
- 如果某个 worktree 工作结束合回 main 后，可以 `git worktree remove .worktrees/feat-xxx` + `git branch -d feat/xxx` 清理

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260625221500-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260625221500-utcp8-mavis.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 关键决策

1. **删 fallback**：v0.3.0-UI-A-010 的 `quotas.map(\.resetsAt).max()` 被实测验证为「完全乱写」，v0.6.0 改 nil fallback。找不到真实到期日 → UI hide。
2. **协议设计**：`SubscriptionDateHarvester` 协议只关心「给一个 pageURL 和 page source → 给我 Date?」，**不**关心怎么抓页面。这样：
   - Kimi 走 API（已有 `subscriptionBalance.expireTime`）→ `KimiSubscriptionStatParser.parseSubscriptionExpiresAt`
   - Codex/Claude/Cursor/MiniMax/Antigravity 走 headless → `*Harvester` 实现 + `WKWebViewHeadlessLoader`
3. **WKWebView @MainActor**：macOS 上 WKWebView 必须在 main thread 创建/交互，整个 loader 用 `@MainActor` 隔离。`evaluateJavaScript` 的 completion 不一定在 main，wrap 进 `Task { @MainActor in }`。
4. **不污染用户浏览器 cookie**：用 `WKWebsiteDataStore.nonPersistent()`，注入的 cookie 只活在临时 store。

#### 完成工作

- [x] v0.6.0 phase 在 REQUIREMENTS.md 注册（上一轮已做）
- [x] arch worktree: 协议 + loader + hide fallback + 15 个测试
- [x] kimi worktree: 错塞修复 + 真实 expireTime 提取 + 5 个测试
- [x] 2 个 commit 合到 main
- [x] REQUIREMENTS.md 6 个 ARCH + 4 个 DATA-A 任务勾完成
- [x] 2 个 worktree 清理

#### 更新的需求 ID

- [x] [0.6.0-ARCH-A-000/001/002/003/001-test/003-test] — 全部完成
- [x] [0.6.0-DATA-A-000/001/002/002-test] — 全部完成

#### 验证方式

- `cd quota-bar-arch/quota-bar && swift build` — 零 warning
- `cd quota-bar-arch/quota-bar && swift test` — 15 tests passed, 3 suites passed
- `cd quota-bar-kimi/quota-bar && swift build` — 零 warning
- `cd quota-bar-kimi/quota-bar && swift test` — 20 tests passed, 4 suites passed
- main 顶部 3 个 commit：
  ```
  03dd984 feat(v0.6.0): kimi — subscriptionBalance.expireTime 作为真实订阅到期日
  0e9b809 feat(v0.6.0): arch — 订阅日期抓取基础架构
  e657332 docs(requirements): v0.6.0 新建 phase — 真实订阅到期日（headless 抓取订阅页）
  ```

#### 风险

- 删 fallback 后到第二批 5 个 provider 落地之间的窗口期：所有非 Kimi 的 provider 价格旁日期不显示
- 如果用户在这期间实测，可能误以为「date 功能没了」—— 需要在 commit message / README 里强调是「中间状态」
- 实际第二批不会很慢（每个 provider 几小时）

#### 后续 worktree

- v0.6.0-data-b-codex — Codex
- v0.6.0-data-c-claude — Claude
- v0.6.0-data-d-cursor — Cursor
- v0.6.0-data-e-minimax — MiniMax
- v0.6.0-data-f-antigravity — Antigravity
- v0.6.0-ui-a — UI 收尾（hide 时 layout 不跳动 + tooltip）

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260627162000-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260627162000-utcp8-mavis.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 可以，那这么操作：
> 1. 把当前的版本：隐藏偏好设置按钮（功能）、订阅到期日功能、GLM订阅支持，提交到main
> 2. 创建4个branch，title叫feat/，内容分别是上述3个功能，以及第四个是website（我们的官网功能），提交

#### 用户意图梳理

上一轮我问"release/v0.6.x 何时切 + 屏蔽策略如何"未获明确回答。本轮用户给出"两步走"：

- **Step 1**：在 main 上做当前版本的收尾（隐藏偏好设置按钮 + 推进 Kimi 订阅到期日 / GLM 任务为正式版状态），推 origin/main
- **Step 2**：基于这个稳定 main，开 4 个 `feat/` branch 作为后续工作的独立线

#### 更新的需求 ID

- 新增 `v0.7.0-DATA-A-000~005`（智谱 Z Code provider 接入 — 6 项）
- 新增 `v0.7.0-FE-A-000~001`（菜单栏 bar 集成 — 2 项）
- 新增 `v0.7.0-DOC-A-000`（README Provider 列表 — 1 项）

#### 验证方式

- `cd quota-bar && swift build`：Build complete! (8.66s)，0 warning
- `cd quota-bar && swift test`：20 tests in 4 suites passed
- `git branch -v`：main + 4 feat/ branch 全部指向正确 commit
- `git push origin main`：推送成功
- `git push origin feat/...`：4 branch 全部推送成功

#### 备注

- 上一轮遗留的两个待决定项（推 origin/main + 处理 22:10 那条 untracked agent-log）已在本轮一并消化：main 推到 origin，3 条 agent-log 全部 commit
- 4 个 feat/ branch 都基于 main `8d69017`（Step 1 收尾后），互不依赖、互不阻塞，可以并行推进
- 后续每个 branch 推进完成后用 fast-forward merge 合回 main：先 `git merge --ff-only <feat-branch>`，合并时确保 main 没新改动

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260618112258-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260618112258-utcp8-mavis.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

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

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：feat-website.md — 历史证据迁移

来源：`agent-log/branches/feat-website.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 后续入口

`web/` 子项目有自己的 `web/AGENTS.md` / `web/REQUIREMENTS.md` /
`web/DESIGN.md` / `web/agent-log/` 四件套（v0.1.0-DOC-A 落地），所有改动
遵循那套约定。

可能的下一步方向：

1. **Provider 卡片对齐 v0.6.0+ 实际接入列表** — 主页现在列了 6 家 provider，
   但 main 上 v0.7.0 之后还要加 Z Code。需要保持主页文案与 `quota-bar/`
   `ProviderKind` 同步。
2. **下载链接自动化增强** — 当前 dynamic 取 latest nightly DMG，可加 fallback
   + SHA256 校验。
3. **SEO / OG image / favicon 系列** — 主页分享卡片体验。
4. **Dark mode 适配** — 主页目前只跟随系统，需要验证 macOS 26 Liquid Glass
   风格的暗色视觉。

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
