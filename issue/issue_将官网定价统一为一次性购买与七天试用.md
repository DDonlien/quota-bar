---
title: 将官网定价统一为一次性购买与七天试用
id: 0.3.2-CONTENT-A-000
type: CONTENT
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`site/REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.3.2 - 定价叙事从"限时免费"改为"$4.99 一次性购买 + 7 天试用"。'
原稳定 ID: '`0.3.2-CONTENT-A-000`, `0.3.2-CONTENT-A-001`, `0.3.2-QA-A-000`；不改写或重编号这些既有 ID。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> **背景**：用户明确要求去掉"Get Pro Free / 限时免费·Beta 专享"这套叙事——不再讲"现在下载就永久
> 免费"，直接卖 $4.99，用 7 天免费试用替代原本的"Beta 免费转正"钩子。这一步也让上一个 phase 里改到
> $4.99 的那个"划掉的旧价"数字（`$0` 现价 + `$4.99` 划线价两段式）失去意义，一并简化成单一价格展示。

- [x] [0.3.2-CONTENT-A-000] `Pricing.astro` 付费卡片：徽标从"Limited Time · Beta Exclusive"改成"7-Day Free Trial"；`.pricing__amount` 从"`$0` 现价 + `$4.99` 划线价"两段式简化成单一 `$4.99`（删掉 `.pricing__amount-old` 节点和对应死 CSS 规则）；note 从"Free during Beta · $4.99 at launch"改成"One-time purchase · includes future updates"；CTA 从"Get Pro Free"改成"Start Free Trial"；section 级 `pricing.heading`/`pricing.subheading` 从"免费送 Pro"叙事改成"$4.99 一次性购买 + 7 天试用"叙事；中英文同步，`Pricing.astro` 静态 fallback 跟 `dict.ts` 保持一致
- [x] [0.3.2-CONTENT-A-001] `terms.s2.body1`（中英文）同步重写：去掉"Beta 下载者上线时自动获得终身 Pro"，改成"官方版自带 7 天完整 Pro 功能免费试用、试用结束后一次性购买 $4.99"；开源免费、授权激活细节待定、vendor-中立 MoR 声明三处不变
- [x] [0.3.2-QA-A-000] `npm run build` 通过；全文 grep 确认无 "Get Pro Free"/"免费领取 Pro"/"free for life"/"永久免费送"/"Beta 专享"/"Beta Exclusive"/`amount-old` 残留；Browser 面板 `document.querySelector` 精确核对付费卡片 badge/amount/note/cta 四处文案，`getBoundingClientRect` 确认两张定价卡去掉划线价后依然等高对齐（均 444px、同一 top）——本次 Browser 面板滚动截图失效（session 内已知的环境问题，`get_page_text`/`javascript_tool` 不受影响），改用几何数据代替截图验证

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
