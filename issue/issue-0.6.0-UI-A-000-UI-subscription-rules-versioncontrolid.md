# feat/subscription-expiry: 调整订阅到期日展示规则

- ID：`0.6.0-UI-A-000`。
- 类型：`UI`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `1532061d80cab44eba9d5469836105dedd72a7e8`；标题路径：任务清单 / Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页） / feat/subscription-expiry: 调整订阅到期日展示规则。
- 原稳定 ID：`0.6.0-UI-A-000`, `0.6.0-UI-A-001`；不改写或重编号这些既有 ID。

## 当前需求与范围

> `subscriptionExpiresAt = nil` 时 `MenuView.PlanHeader.expiresAtText` 已经返回 nil，UI 不显示。**但**需要确认：
> 1. dropdown 价格行 layout 不要因为 hide 产生跳动；
> 2. 把目前灰色的 "刷新时间未知" 文案在 quota row 里保留（那不是 subscriptionExpiresAt，是 quota resetsAt，是另一个字段）；
> 3. tooltip 提示用户"日期未配置"（可选，nice-to-have）

- [x] [0.6.0-UI-A-000] 验证 `MenuView.PlanHeader.expiresAtText == nil` 时 HStack 收缩正常（价格仍居右、不留空隙）#P1
- [x] [0.6.0-UI-A-001] 给 `expiresAtText` 加 `.help("...")` tooltip：显示「订阅续费日期」+ 完整 ISO 日期（让用户 hover 能看到精确时间）#P2

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260625221000-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260625221000-utcp8-mavis.md` @ `1532061d80cab44eba9d5469836105dedd72a7e8`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 3. UI-A-000：验证 expiresAtText==nil 时 HStack 收缩

**review 结果**（基于 v0.3.0-UI-A-010 落地的代码）：

```swift
HStack(spacing: planPriceTrailingGap) {
    if let expiresAtText {
        Text(expiresAtText)...
    }
    Text(snapshot.monthlyPrice ?? "—")...
}
```

- `expiresAtText` 为 nil 时 `if let` 不渲染日期 Text；
- HStack 收缩为只装价格 Text（宽度 ≈ 1 个价格文字）；
- 外层 `Spacer()` 把整个 HStack 推到右边缘。

**结论**：行为已正确，不需要强制改代码。**改了什么**：抽出 `subscriptionExpiresDate: Date?` 公共前置条件（消除 `expiresAtText` 里的内联 guard 重复），加 doc 注释把"nil 时 HStack 收缩"行为锁定在源码里，避免后续维护者误改后产生 layout 跳动。

#### 完成工作

- `[0.6.0-UI-A-000]` UI 行为验证：HStack 收缩已通过代码 review 确认正确，加注释锁定行为。
- `[0.6.0-UI-A-001]` UI 行为变更：日期 Text 加 `.help()` tooltip 显示精确本地时间。
- 清理悬挂的 arch worktree（`git worktree prune` 无效时手动清 `.git/worktrees/`）。
- DESIGN.md / REQUIREMENTS.md 同步。

#### 更新的需求 ID

- 勾选完成：`[0.6.0-UI-A-000]` / `[0.6.0-UI-A-001]`

#### 验证方式

- `cd quota-bar && swift build`：通过 ✅，0 warning。
- 没运行 `swift run` / `build-app.sh`：本轮只是 UI 静态层 + 计算属性改动，不涉及运行行为；
  tooltip 的 hover 行为需要手验 dropdown（任何已配置 provider，hover 价格左侧的日期灰字应看到 `订阅续费日期：2026-XX-XX HH:MM:SS GMT+8` 形式）。

#### 备注

- **arch 状态独立于本 worktree**：v0.6.0-ARCH-A-* 的所有 6 条任务在 arch 分支上 0 commit。本轮 UI 改动不阻塞 arch 落地（无论 arch 是直接合 main 还是先开新分支后合 main），也不会和 arch 冲突。
- **arch 落地后行为差异**：arch merge 后 `ProviderSnapshot.subscriptionExpiresAt` 在没有显式传值时会是 nil（删了 `max(resetsAt)` fallback），本轮 UI 代码无需任何调整，行为正确：nil 时不显示日期、也不显示 tooltip。
- **没引入新依赖**、没动 ABI、没改公共协议签名。
- **commit 切分建议**：本 worktree 一个 commit 即可，message 形如 `feat(ui): show precise subscription renewal date in plan header tooltip` + 解释 UI-A-000 注释锁定行为。
- **未提交**：保持 worktree 工作区原样，方便用户先看 diff 再决定提交 + MR 流程。
- **git worktree prune 失效**：本机 git 对"目录已被外部删但 `.git/worktrees/<name>/` 元数据还在"的悬挂 worktree 不会自动 prune，必须手动 `mavis-trash .git/worktrees/<name>/` + `git branch -D <branch>`。建议下次清理悬挂 worktree 用这个组合。

### 20260626160800-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260626160800-utcp8-mavis.md` @ `1532061d80cab44eba9d5469836105dedd72a7e8`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 2. 验证 v0.6.0-ui-a 在最新 main 上能编能跑

- `git log e657332..main -- MenuView.swift` → 空输出，**arch/kimi/docs 三 commit 都没改 MenuView.swift**，rebase 不会冲突
- v0.6.0-ui-a 工作区跑 `swift build`：通过 ✅（但只有 1 个 placeholder 测试通过，原因是 worktree 创建时 arch/kimi 还没合，缺 4 个测试文件）

#### 7. 最终 main 状态验证

- `swift build`：0 warning ✅
- `swift test`：20 tests in 4 suites passed ✅
- 工作树干净（只剩上一轮 22:10 那个 agent 留下的 untracked `agent-log/20260625221000-utcp8-mavis.md`，本次不动）

#### 完成工作

- [x] 把 v0.6.0-ui-a 工作区改动 commit 到 `feat/v0.6.0-ui-a` 分支
- [x] rebase 到 main HEAD（arch/kimi 零冲突）
- [x] fast-forward merge 到 main，main HEAD = `e31383c`
- [x] 跑 `swift build` + `swift test` 验证：20 tests passed
- [x] 清理 `.worktrees/v0.6.0-ui-a` + `.worktrees/price-update-date` 两个游离 worktree
- [x] 删除 `feat/v0.6.0-ui-a` + `feat/price-update-date` 两个本地分支
- [ ] main 推到 origin/main（**未做，等用户授权**）

#### 更新的需求 ID

- 无新增需求；[0.6.0-UI-A-000]/[001] 在 22:10 已勾完成，本轮只负责 commit + merge
- v0.6.0 phase 进度：arch + kimi + UI-A 已全部合到 main；**第二批 5 个 headless provider（Codex/Claude/Cursor/MiniMax/Antigravity）尚未开工**

#### 验证方式

- `cd quota-bar && swift build` → Build complete! (0.11s)，0 warning
- `cd quota-bar && swift test` → 20 tests in 4 suites passed
- v0.6.0-ui-a worktree rebase 后同命令：build + test 全过

#### 用户行为差异

- 现在 Kimi 的 PlanHeader 会显示 tooltip（hover 日期灰字看精确本地时间）
- 其他 5 个 provider（Codex/Claude/Cursor/MiniMax/Antigravity）价格旁日期仍然消失（arch 删了 max(resetsAt) fallback，第二批还没落地）
- 这个「Kimi 有日期 / 其他没有」的不一致状态会持续到第二批 5 个 provider harvester 落地

#### 后续 worktree 计划（v0.6.0 第二批，5 个独立 worktree 并行也行）

- v0.6.0-data-b-codex
- v0.6.0-data-c-claude
- v0.6.0-data-d-cursor
- v0.6.0-data-e-minimax
- v0.6.0-data-f-antigravity
- 每个用 `feat/v0.6.0-data-X-<provider>` 分支 + `*Harvester: SubscriptionDateHarvester` 实现
- 完成后逐一 ff merge 到 main
