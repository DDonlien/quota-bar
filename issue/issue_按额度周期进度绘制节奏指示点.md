---
title: 按额度周期进度绘制节奏指示点
id: 0.14.0-DATA-B-000
type: DATA
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.14.0 - 大陆可达性兜底 + 额度节奏指示 + Kimi 额度修复 / sub/main: 额度条节奏指示（linear pacing marker）。'
原稳定 ID: '`0.14.0-DATA-B-000`, `0.14.0-FE-B-000`, `0.14.0-FE-B-001`, `0.14.0-QA-B-000`, `0.14.0-QA-B-001`, `0.14.0-FE-B-002`；不改写或重编号这些既有 ID。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> 需求原文："在 drop down 的进度条上，应该标识出根据当前剩余更新时间推荐的使用量。例如：如果剩余 7 天，
> 今天是第 1 天，则应标识在 1/7 的位置。这个标识本身应该是个非常简洁的指示条或者指示点，不应该特别的张扬。"
>
> **语义确认**（本次实现采用的解释，如与用户预期不符可调整方向）：`ProgressPill` 的填充语义是"剩余比例"
> （`remainingFraction`，从左边缘铺满，值越大填充越宽）。指示点标的是"如果按线性节奏消耗，此刻理论上应该
> 还剩多少"——公式 `idealRemainingFraction = 1 - elapsedFraction = timeUntilReset / periodSeconds`。
> 用户例子（周期 7 天，今天第 1 天，已过 1/7）对应 `idealRemainingFraction = 6/7`，指示点落在**靠右侧**（应该
> 还剩 6/7）；如果实际填充（真实 remainingFraction）比指示点更靠左，说明消耗快于线性节奏。只对有明确
> `periodSeconds` + `resetsAt` 的额度窗口显示，固定额度包（`periodSeconds == nil`）不显示。

- [x] [0.14.0-DATA-B-000] `QuotaWindow` 新增方法 `idealRemainingFraction(relativeTo now: Date = Date()) -> Double?`：`periodSeconds`/`resetsAt` 任一缺失返回 `nil`；否则 `max(0, min(1, resetsAt.timeIntervalSince(now) / periodSeconds))`
- [x] [0.14.0-FE-B-000] `ProgressPill` 新增可选参数 `paceMarkerFraction: Double?`：非 nil 时在该 x 位置画一条 1.5pt 宽、`progressHeight+2` 高的低对比度竖线（`Palette.paceMarker = Color.primary.opacity(0.45)`，不使用状态色，避免和 track/fill 的红橙绿混淆）
- [x] [0.14.0-FE-B-001] `QuotaRow` 传入 `quota.idealRemainingFraction()` 给 `ProgressPill`
- [x] [0.14.0-QA-B-000] 新增 `QuotaWindowTests.swift`：周期起点（1.0）/day-1-of-7（6/7）/终点（0）/resetsAt 陈旧夹到 0/无 periodSeconds 返回 nil/无 resetsAt 返回 nil，共 6 个测试，`swift test` 213/213 通过
- [x] [0.14.0-QA-B-001] `swift run` 目测验证：不同剩余比例 + 不同节奏（超前/落后/持平）下指示点位置和视觉观感符合"简洁不张扬"的要求——用户打包后实机截图确认，Codex/Claude/Kimi/opencode 各条额度上的指示点位置均正确，样式认可（见下面 FE-B-002 的后续调整）

> **后续追加（用户实机截图反馈）**："我觉得你现在整体加宽后的进度条样式是 OK 的。那你不如就全局都用这个宽的，
> 不要在没有提示条的时候，进度条就变成窄的，这样很不统一，不太好。" 根因：指示点的 Capsule 比条本身
> （`progressHeight`）高 2pt，靠"poke 出来"跟条区分，这导致有指示点的条目视觉上比没有指示点的条目
> （固定额度包、loading 骨架屏）粗，两者不统一。

- [x] [0.14.0-FE-B-002] `progressHeight` 从 5 提到 7（原先"5pt 条 + poke 出 2pt 指示点"达到的视觉高度，直接作为新的统一基准），指示点高度从 `progressHeight+2` 改为跟条本身齐平的 `progressHeight`——不再依赖 poke 出来做区分，`Palette.paceMarker` 的低对比度颜色本身已经够跟 track/fill 区分；现在不管有没有指示点，所有额度条粗细一致

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

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
