---
title: 为官网分别提供购买与免费试用下载入口
id: 0.15.1-FE-B-000
type: FE
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.15.1 - Claude 探测顺序修复 + 日志 provider 配色 + 购买/下载双出口 / site/main: 购买与下载分成两个出口。'
原稳定 ID: '`0.15.1-FE-B-000`, `0.15.1-FE-B-001`；不改写或重编号这些既有 ID。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

- [x] [0.15.1-FE-B-000] 付费卡主按钮从"开始免费试用"改为"购买 Quota Bar"，下方新增一条 vibeisland 风格的次要文字链接"或先下载免费试用 →"（`data-download`，复用 `UPDATE_DOWNLOAD` 解析）。原来用"免费试用"包装一个其实是付款页的入口，点进去发现要填卡号会让人觉得被诓；现在语义各归各位。次要出口做成纯文字链接而不是第二个按钮，避免稀释主 CTA
- [x] [0.15.1-FE-B-001] `Hero.astro` 的静态兜底下载链接从 hardcode 的 `nightly-c6317d0…` 直链改为 `/api/download-latest`：那个硬编码值虽然还能跳转，但发的是很老的构建（2.0MB vs 当前 2.7MB），发布链路换过两轮都没人记得更新它；改成服务端解析的端点后永不过期，也不再在源码里留会腐烂的常量

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260630-093000-utcp8-taobe-minimax-m3.md — 历史证据迁移

来源：`agent-log/20260630-093000-utcp8-taobe-minimax-m3.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> Header 的 Never Lose Track 中文翻译成"始终掌握"。
> 然后第二行"提前掌握额度上限"的小字，在英文版里面不要让它换行
> 四个 Tab 需要 Hover 的效果，以及每个 Tab 选中的效果。
> 选中的效果应该要有进度条一样的特效，来表达它自动播放。下面的描述文字应该跟着这个 Tab 走，上面的图片也是参考附件的实现

#### 更新的需求 ID

- `0.x.x-FE-A-NNN-tab-progress`：tab 激活态进度条特效（已落地，feature 内部）
- `0.x.x-FE-A-NNN-tab-images`：4 张图跟随 tab 切换（已落地）

#### 验证方式

1. `cd worktree/site-main/site && npm run build` → ✓ 1 page built
2. `npm run preview -- --port 4322` 跑 build 产物
3. Playwright 截图对比：
   - `r5-zh-desktop-full.png` — 中文 hero：标题"始终掌握" ✅
   - `r5-en-desktop-full.png` — 英文 hero：subtitle "Stay ahead of every limit." 单行 ✅
   - `r5-tabs-2-t0.png` / `r5-tabs-2-t1.png` / `r5-tabs-2-t2.png` — Tab 进度条三时点：t=0.3s (8%) / t=1.5s (43%) / t=2.7s (自动切换到审批) ✅
   - `r5-tabs-2-hover.png` — hover Approve tab 时进度条暂停 + 边框加深 ✅
   - `r5-zh-mobile-tabs.png` / `r5-en-mobile-tabs.png` — Mobile 414：tab pill 一行 ✅

#### 备注

- 用户口语"Header" 在本任务中指 Hero 首屏，不是 Nav
- 当前 ProductPreview 4 张图是纯 CSS mockup 占位，后续可替换为真实应用截图
- i18n 应用脚本用 `textContent = val` 覆盖节点 — 给后续维护者的提醒：任何带结构化子节点的元素不要把 `data-i18n` 放在元素本身，应该放在内部的纯文本 span 上

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260701-005000-utcp8-taobe-minimax-m3.md — 历史证据迁移

来源：`agent-log/20260701-005000-utcp8-taobe-minimax-m3.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

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
