# 以真实订阅来源替代额度重置时间推断到期日

- ID：`migration-8065bbb47a9d`。
- 类型：`QA`。
- 状态：已确认约束 / 状态待核对（原文未单列完成状态）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页）。

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

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260625220500-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260625220500-utcp8-mavis.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

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

### 2026-10-24 07:03:43 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
