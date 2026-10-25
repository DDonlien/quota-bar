---
title: 统一Dropdown隐藏操作与持久Provider开关
id: 0.10.0-UI-B-004
type: UI
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 缓存优先级语义纠正 + dropdown 隐藏按钮与 Preferences 开关状态统一。'
原稳定 ID: '`0.10.0-BUG-A-004`, `0.10.0-UI-B-004`, `0.10.0-ARCH-F-000`, `0.10.0-ARCH-F-001`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.10.0-BUG-A-004`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.10.0-UI-B-004`、`0.10.0-ARCH-F-000`、`0.10.0-ARCH-F-001`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.10.0-BUG-A-004-UI-dropdown-preferences-state-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'sub/main: 缓存优先级语义纠正 + dropdown 隐藏按钮与 Preferences 开关状态统一。'
同源任务: '[仅在全部所需层同源时提前尝试缓存来源](issue_%E4%BB%85%E5%9C%A8%E5%85%A8%E9%83%A8%E6%89%80%E9%9C%80%E5%B1%82%E5%90%8C%E6%BA%90%E6%97%B6%E6%8F%90%E5%89%8D%E5%B0%9D%E8%AF%95%E7%BC%93%E5%AD%98%E6%9D%A5%E6%BA%90.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

共同范围与完整历史见[仅在全部所需层同源时提前尝试缓存来源](issue_%E4%BB%85%E5%9C%A8%E5%85%A8%E9%83%A8%E6%89%80%E9%9C%80%E5%B1%82%E5%90%8C%E6%BA%90%E6%97%B6%E6%8F%90%E5%89%8D%E5%B0%9D%E8%AF%95%E7%BC%93%E5%AD%98%E6%9D%A5%E6%BA%90.md)；本文件保留以下独立目标的原文。

- [x] [0.10.0-UI-B-004] dropdown 隐藏（叉）按钮从"只在 `.needsConfiguration` 出现"改为"所有没有真实额度数据的 provider 都出现"（`.needsConfiguration` / `.notSubscribed` / `.subscriptionExpired` / `.available` 但 `quotas.isEmpty`），已有真实额度的 provider 不提供（没有"不想用"的诉求，误触代价也更高）#P1
- [x] [0.10.0-ARCH-F-000] 删除 `RefreshCoordinator.hiddenKinds`（内存态、手动刷新会被 `clearHidden()` 清空的临时隐藏集合），改为统一读写 `PreferencesStore.isEnabled(kind:)`（持久化）。`hide(kind:)` 现在直接调用 `PreferencesStore.setEnabled(false, for:)`；`runRefreshCycle` 的 `activeProviders` 过滤也改读同一个持久化状态。dropdown 隐藏按钮和 Preferences「模型」页的开关现在是同一份状态的两个入口，任一边改动都会真正阻止该 provider 发起请求，而不是只在 UI 上视觉隐藏 #P0
- [x] [0.10.0-ARCH-F-001] `RefreshCoordinator` 新增 `applyEnabledFilterChange()`，订阅 `.quotaPreferencesDidChange` 通知：立即把刚被关闭的 provider 从 `state.snapshots` 摘掉；刚被重新启用但 `state.snapshots` 里还没有它的 provider，立刻触发一次 `refreshNow()`，不用等下一个 5 分钟自动周期 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 历史记录-时间未记录

原迁移条目的历史Comments完整保留于[同源历史](issue_%E4%BB%85%E5%9C%A8%E5%85%A8%E9%83%A8%E6%89%80%E9%9C%80%E5%B1%82%E5%90%8C%E6%BA%90%E6%97%B6%E6%8F%90%E5%89%8D%E5%B0%9D%E8%AF%95%E7%BC%93%E5%AD%98%E6%9D%A5%E6%BA%90.md#comments)，不从历史日志新增完成标记。

原记录时间、具体执行 Agent、模型与原会话未记录，未补造。

## 20261024-070343_Agent

原记录标题：2026-10-24 07:03:43 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-162234_Codex

按用户最新手写模板迁移属性和正文结构，保留任务语义、来源、原始状态及历史内容；本次未重新执行业务验收。

原版本关联记录（照录来源，不将本次文档迁移提交当作业务实施提交）：
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。

本次执行环境未提供具体模型标识，未补造 Model-Detail。

[本次文档迁移对话](codex://threads/01a157b3-610c-73b4-ae06-163c0f8490d3)
