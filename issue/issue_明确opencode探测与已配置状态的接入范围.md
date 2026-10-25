---
title: 明确opencode探测与已配置状态的接入范围
id: migration-5fbc62863920
type: DOC
status: 已确认约束 / 状态待核对（原文未单列完成状态）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.13.0 - opencode Provider 支持（探测 + 诚实的"已配置"态）。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> **背景**：opencode（`https://opencode.ai`）是一个 BYOK 聚合 CLI，本身没有稳定的额度百分比接口——
> 调研确认 Zen（其自家 pay-as-you-go 网关）的 credits API 返回 `Not Found`（未上线/不稳定），
> Go（其自家订阅）的用量只能靠抓一个未公开的私有 dashboard 网页 + 浏览器 auth cookie，没有官方文档且结构随时可能变。
> 参考了同类项目 `opgginc/opencode-bar`（GitHub 上一个已实现 opencode 用量追踪的 macOS 菜单栏 App）的源码验证了以上结论。
>
> **本 phase 的范围决策**（已与用户确认，2026-07-08）：只做「探测 + 诚实的已配置态」——
> 读 `~/.local/share/opencode/auth.json` 判断已配置了哪些下游 provider，`.available` + 空 quotas，
> 对齐 `ClaudeAuthStatusCLIProvider` 的 tier-only fallback 先例（有真实档位信息但没有额度数值时，
> 不伪造百分比，quotas 留空，UI 自然显示灰色"未知"灯）。不引入浏览器 cookie 抓取 Go 私有 dashboard 的方案，
> 也不用本地 `opencode stats` CLI 伪造一个固定月度上限来充当额度条——两者都超出当前验证过的可靠数据范围。
>
> **VERSION 说明**：本 phase 完成，但暂不 bump 根目录 `VERSION` 文件——v0.11.0 / v0.12.0 phase
> （自动更新 + Developer ID 签名）已在 REQUIREMENTS.md 中规划但尚未全部完成，可能有其他 agent 正在推进，
> 现在 bump VERSION 可能与其并发工作冲突或造成版本语义混乱（VERSION 目前落在 0.10.0，早于已规划但未完成
> 的 0.11.0/0.12.0）。VERSION 的实际 bump 时机留给之后统一处理已完成 phase 时一并决定。

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
