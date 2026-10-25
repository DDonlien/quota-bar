---
title: 以真实订阅来源替代额度重置时间推断到期日
id: migration-8065bbb47a9d
type: QA
status: 已确认约束 / 状态待核对（原文未单列完成状态）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`；标题路径：任务清单 / Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页）。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> **问题**：v0.3.0-UI-A-010 落地的「订阅/数据最后有效日期」灰色标签当前值是 `quotas.map(\.resetsAt).max()`，语义上是「最晚 quota 窗口的下次重置时间」，**不是订阅到期日**。结果：
> - 只有 5h 窗口的 provider → 显示 5h 后的时间（完全不是订阅到期）
> - 5h + 周窗口 → 显示 7d 后（看起来"差不多对"，但跟真实续费日没关系）
> - 月度订阅 + 5h/周窗口 → 显示 30d 后（碰巧接近，但本质不是账单日）
>
> **解决思路**：用 headless 抓取各家订阅管理页（chatgpt.com/account、claude.ai/settings、cursor.com/dashboard 等），从 DOM 提取「续费日期 / 到期日」。比起"挨个研究私有 API"，**订阅页就是设计给用户看日期的**，一定有结构化的「下次扣费 / 到期」信息。Kimi 这类已经有 API 返回 `subscriptionBalance.expireTime` 的直接接。
>
> **找不到时**：直接 hide（`subscriptionExpiresAt = nil` → `MenuView.PlanHeader.expiresAtText` 返回 nil → UI 不显示）。**不再 fallback 到 max(resetsAt)**，因为那个值已经被验证是"乱写的"。
>
> **worktree 拆分**：每个 provider 一个独立 worktree，互不依赖；1 个 ARCH worktree 做基础架构（HARVESTER 协议 + WKWebView wrapper + fallback 改 hide）必须先落地，其余 5-6 个 provider worktree 后续并行开。

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260625220500-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260625220500-utcp8-mavis.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户拍板

- **B 方向**（真实订阅到期日）
- **架构换成 headless 抓订阅页**（不是研究各家私有 API）
- **每个 provider 拆一个 worktree**
- **执行前先写 requirement**

#### 完成工作

- [x] 在 `REQUIREMENTS.md` 增加 `## Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页）`
- [x] 拆分 7 个 block（ARCH + 6 个 provider + UI）
- [x] 每个 provider 加 `-test` 子任务
- [x] 写本文档

#### 更新的需求 ID

- 新建 [0.6.0-ARCH-A-000/001/002/003/003-test/001-test]
- 新建 [0.6.0-DATA-A-000/001/002/002-test]
- 新建 [0.6.0-DATA-B-000/001/001-test]
- 新建 [0.6.0-DATA-C-000/001/001-test]
- 新建 [0.6.0-DATA-D-000/001/001-test]
- 新建 [0.6.0-DATA-E-000/001/001-test]
- 新建 [0.6.0-DATA-F-000/001/001-test]
- 新建 [0.6.0-UI-A-000/001]

#### 验证方式

- `cd quota-bar && swift build` 通过（当前 v0.5.0 baseline 已 build 干净）
- 各 worktree merge 后跑 `make test`

#### 备注

- 用户原话"献血 requirement"应为语音误识"先写 requirement"，按上下文理解执行
- v0.6.0 名字是 agent 起的，未与用户确认；如要叫 v0.5.1 后续可改
- headless 方案使用 macOS native WKWebView，不引入 Node.js 依赖；和现有 web/ 子项目（Vercel 部署）解耦
- 6 个 headless provider 抓取的实际 URL 待 worktree 实施时人工核验（先列候选 URL，实施时验证）

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260625221500-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260625221500-utcp8-mavis.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

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

来源：`agent-log/20260627162000-utcp8-mavis.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

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
