---
title: 按Provider流式刷新并原位替换加载占位
id: 0.3.0-FE-A-000
type: FE
status: 进行中（原文同时包含已完成与未完成项）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`；标题路径：任务清单 / Phase - v0.3.0 - UI 拖拽、订阅组语义与 dropdown 实时刷新 / FE-A：Streaming 刷新（per-provider 增量发布）。'
原稳定 ID: '`0.3.0-FE-A-000`, `0.3.0-FE-A-001`, `0.3.0-FE-A-002`, `0.3.0-FE-A-003`, `0.3.0-FE-A-004`, `0.3.0-FE-A-005`, `0.3.0-FE-A-006`, `0.3.0-UI-A-008`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.3.0-FE-A-000`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.3.0-FE-A-000`、`0.3.0-FE-A-001`、`0.3.0-FE-A-002`、`0.3.0-FE-A-003`、`0.3.0-FE-A-004`、`0.3.0-FE-A-005`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.3.0-FE-A-000-FE-streaming-refresh-per-provider-release-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: FE-A：Streaming 刷新（per-provider 增量发布）。
同源任务: '[订阅组重排后立即更新菜单栏与状态灯](issue_%E8%AE%A2%E9%98%85%E7%BB%84%E9%87%8D%E6%8E%92%E5%90%8E%E7%AB%8B%E5%8D%B3%E6%9B%B4%E6%96%B0%E8%8F%9C%E5%8D%95%E6%A0%8F%E4%B8%8E%E7%8A%B6%E6%80%81%E7%81%AF.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> 旧实现：所有 provider 并发 fetch，但只在**全部完成**后才把 `state` 整体替换为新值——
> 即使 dropdown 已经能"实时刷新"（v0.3.0-UI-A-004），用户看到的也只是"白屏 → 一次完整数据出现"。
> 新实现：探测到安装后立刻注入 `.loading` placeholder，provider 完成一个就 apply 一个、
> publish 一次 `state`，UI 立即响应。菜单栏 bar 也按完成顺序逐个"动态增长"。

- [x] [0.3.0-FE-A-000] `ProviderAvailability` 新增 `.loading` 枚举值 + `ProviderSnapshot.loading(kind:)` 工厂：占位 snapshot，quotas 为空、tier/price 为 nil、`isStale = false`；UI 渲染为骨架 #P1 — `QuotaModels.swift`
- [x] [0.3.0-FE-A-001] `RefreshCoordinator.runRefreshCycle` 重写为 streaming：探测安装 → 立即按用户偏好顺序 seed `.loading` placeholders → 用 `withTaskGroup` 并发跑每个 provider → 每个 provider 完成（含 fallback）立即调用 `applyProviderResult` 在原位置替换 placeholder → 全部完成后计算最终 `refreshState` #P1 — `RefreshCoordinator.swift:runRefreshCycle`
- [x] [0.3.0-FE-A-002] `state.lastUpdated` 在每个 provider 完成时推进（`max(prev, fetchedAt)`），让顶部"上次更新 HH:mm"逐 provider 前进，用户看到"数据正在流入" #P1 — `RefreshCoordinator.applyProviderResult`
- [x] [0.3.0-FE-A-003] `MenuView.PlanSection` 加 `case .loading: QuotaSkeleton()`：loading snapshot 直接走骨架分支；`ReadyStateView` 把 `isLoading` 改为派生自 `snapshot.availability == .loading`，per-snapshot 独立判断 #P1 — `MenuView.swift`
- [x] [0.3.0-FE-A-004] `StatusBarController.drawableSnapshots` / `remainingFraction` / `makeBarsImage` 处理 `.loading`：bar 高度 50%、alpha 0.4（dimmed），区别于 needsConfiguration（alpha 1.0 50%）；tooltip 在 loading 时显示「刷新中」而不是 50% #P1 — `StatusBarController.swift`
- [x] [0.3.0-FE-A-005] `pickBestSnapshot` 和 `FetchPipeline.merge` 的 availability 优先级加上 `.loading`（priority 2，介于 needsConfiguration=3 和 notInstalled=1 之间），避免 exhaustiveness warning 影响新 case #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260625104200-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260625104200-utcp8-mavis.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 1. 用户反馈的核心问题

旧实现流程：
1. 探测所有安装的 provider
2. 用 `withTaskGroup` 并发跑所有 pipeline
3. **等所有完成** → `await for ... in group` 退出循环
4. 一次性把全部结果合并后赋给 `state`（`@Published`）
5. SwiftUI 在 `@ObservedObject` 绑定下响应 state 变化（v0.3.0-UI-A-004 已实现）

结果：**虽然 SwiftUI 能响应 state 变化，但 state 本身只在所有 pipeline 都完成时才更新一次**。用户看到的体验是"白屏 → 一瞬间全部数据出现"，中间没有任何 provider 完成时的中间态。即使不关 dropdown，新数据也是在所有 provider 都完成之后才一次性出现，跟"白屏 → 一次性出现"没区别。

而且菜单栏 bar 也只在所有快照替换完成时才一次性重画，没有"逐步增加"的视觉。

#### 5. 验证

- `cd quota-bar && swift build`：通过 ✅
- 仅有一个预先存在的 warning（`MiniMaxConfigProvider.swift:346` 未使用变量 `prefix`），与本次修改无关。
- 旧的 ProviderFetchStrategy 和 RefreshCoordinator 里的 priority closure 加上 `.loading` 后编译通过。

#### 6. 用户手验清单（运行时验证）

跑 `cd quota-bar && swift run` 后：

1. **首启动 streaming**：
   - 启动瞬间 dropdown（如果打开）应看到所有 active provider 的骨架行，菜单栏看到 dimmed 50% bar 占位。
   - 1~3 秒内骨架逐个被真实数据替换，菜单栏 bar 从 dimmed 跳变为实际高度。
2. **手动刷新（立即刷新）**：
   - 点菜单「立即刷新」→ dropdown 立刻变骨架 → 逐个回填真实数据，菜单栏 bar 短暂全 dimmed → 逐个变亮。
   - **不关 dropdown** 也能看到完整 streaming 过程。
3. **多 provider 并发完成顺序**：
   - Antigravity / Codex / Kimi / MiniMax 启动时间差异大（IDE 探测快、Cookie 读取中、CLI 调用慢），观察到完成顺序随机 → 真实数据按完成顺序逐个出现。
4. **菜单栏动态增长**：
   - 启动瞬间菜单栏有 N 个 dimmed 50% bar（N = active kinds 数）→ 逐个变全亮、bar 高度按真实 remainingFraction 调整。
   - 不要 spinner（注释里强调过"刷新中不切换图标"）。
5. **首启动 dropdown 实时刷新**：
   - 打开 dropdown 不关 → 等自动刷新（5min）或点"立即刷新" → dropdown 内部原地刷新（已有 v0.3.0-UI-A-004 保证）。
6. **可访问 Console.app** 看 `QuotaBar:` 开头的 NSLog：每个 provider 完成会打 `✅ <kind> done` log。

#### 7. 后续可能改进（未做）

- **保留旧数据 re-refresh**：在 `ProviderSnapshot` 加 `isRefreshingNow: Bool` 字段，让重刷新期间保留旧数据 + 显示骨架覆盖层 / spinner。当前是骨架完全替换，flicker 短暂可接受。
- **per-provider 进度**：如果某个 provider 特别慢（>2s），可以在 UI 显示「Codex 还在刷新... 已等 3s」之类提示。当前没有。
- **retry backoff**：失败的 provider 在下一次自动刷新之前不重试（每次都重新走 pipeline）。当前行为不变。

#### 完成工作

- 数据层：`.loading` availability + `ProviderSnapshot.loading(kind:)` 工厂。
- 协调器：`runRefreshCycle` 重写为 streaming，per-provider 增量 publish state。
- 协调器：`applyProviderResult` 新方法，failure fallback 复用原逻辑。
- dropdown：`.loading` case 走骨架，`ReadyStateView` 派生 per-snapshot isLoading。
- 菜单栏：loading snapshot 画 dimmed 50% bar，tooltip 显示「刷新中」。
- pipeline priority：`.loading` 加进 exhaustive switch。
- 文档：REQUIREMENTS.md v0.3.0-FE-A 子区块新增 6 条需求。

#### 更新的需求 ID

新增：

- `[0.3.0-FE-A-000]` `ProviderAvailability.loading` + `ProviderSnapshot.loading(kind:)` 工厂。
- `[0.3.0-FE-A-001]` `runRefreshCycle` 重写为 streaming：探测 → seed placeholder → per-provider apply。
- `[0.3.0-FE-A-002]` `state.lastUpdated` 每次 provider 完成都推进。
- `[0.3.0-FE-A-003]` `MenuView.PlanSection` 加 `.loading` case；`ReadyStateView` per-snapshot `isLoading` 派生。
- `[0.3.0-FE-A-004]` `StatusBarController` 处理 `.loading`：dimmed 50% bar + tooltip「刷新中」。
- `[0.3.0-FE-A-005]` `pickBestSnapshot` / `FetchPipeline.merge` 优先级 closure 加 `.loading` case。

#### 验证方式

- `cd quota-bar && swift build`：通过 ✅
- 用户手验清单见上文「6. 用户手验清单」。

#### 备注

- **隐藏 / 重刷新 flicker**：当前重刷新瞬间所有 snapshot 会从真实数据 → 骨架 → 真实数据（依次回填）。如果用户觉得这个 flicker 不舒服，再加 `isRefreshingNow` 字段保留旧数据。本轮先按用户原话「先显示刷新中，等获取到再显示具体的值」实现。
- **`primarySubscriptionGroupWorstQuota` 不变**：streaming 只改 coordinator 发布时机，不改 quota 取值逻辑。
- **fetchFailed 的隐藏时机**：applyProviderResult 里把 fetchFailed snapshot 从 state.snapshots 移除，但仅当 replaceAt 成功（state 里确实有 placeholder）。如果 placeholder 已被某种异常路径移除，applyProviderResult 会 fallback 走 `if let index = ... else if keepAfterApply`，不会重复插入。
- **state.lastUpdated 在 hide()/clearHidden() 时的语义**：hide() 现在直接清空 state.snapshots 不会动 lastUpdated；如果用户 hide 掉所有 provider，lastUpdated 仍保留上一次刷新时间。这是合理的——「我最后一次成功刷新是什么时候」与「当前可见几个 provider」是两件事。
- **v0.3.0-UI-A-004 是 streaming 的前提**：没有 @ObservedObject 绑定 coordinator，per-provider publish 不会触发 UI 更新。当前这套已就位，所以 streaming 直接受益。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-070408_Agent

原记录标题：2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-162234_Codex

按用户最新手写模板迁移属性和正文结构，保留任务语义、来源、原始状态及历史内容；本次未重新执行业务验收。

原版本关联记录（照录来源，不将本次文档迁移提交当作业务实施提交）：
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。

本次执行环境未提供具体模型标识，未补造 Model-Detail。

[本次文档迁移对话](codex://threads/01a157b3-610c-73b4-ae06-163c0f8490d3)
