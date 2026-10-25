---
title: 建立真实订阅额度的多来源获取与失败降级
id: 0.2.0-DATA-B-000
type: DATA
status: 进行中（原文同时包含已完成与未完成项）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `1532061d80cab44eba9d5469836105dedd72a7e8`；标题路径：任务清单 / Phase - v0.2.0 - Quota Bar 核心功能 / sub/main: 获取真实订阅与额度数据。'
原稳定 ID: '`0.2.0-DATA-B-000`, `0.2.0-DATA-B-001`, `0.2.0-DATA-B-002`, `0.2.0-DATA-B-003`, `0.2.0-DATA-B-004`, `0.2.0-DATA-B-005`, `0.2.0-DATA-B-009`, `0.2.0-DATA-B-010`, `0.2.0-DATA-B-011`, `0.2.0-DATA-B-012`, `0.2.0-DATA-B-013`, `0.2.0-DATA-B-006`, `0.2.0-DATA-B-007`, `0.2.0-DATA-B-008`, `0.2.0-DATA-B-014`, `0.2.0-DATA-B-015`, `0.2.0-DATA-B-016`, `0.2.0-DATA-B-017`, `0.2.0-DATA-B-018`, `0.2.0-DATA-B-019`, `0.2.0-DATA-B-020`, `0.2.0-DATA-B-021`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.2.0-DATA-B-000`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.2.0-DATA-B-000`、`0.2.0-DATA-B-001`、`0.2.0-DATA-B-002`、`0.2.0-DATA-B-003`、`0.2.0-DATA-B-004`、`0.2.0-DATA-B-005`、`0.2.0-DATA-B-009`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.2.0-DATA-B-000-DATA-subscription-quota-data-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'sub/main: 获取真实订阅与额度数据。'
同源任务: '[仅按真实订阅档位映射价格](issue_%E4%BB%85%E6%8C%89%E7%9C%9F%E5%AE%9E%E8%AE%A2%E9%98%85%E6%A1%A3%E4%BD%8D%E6%98%A0%E5%B0%84%E4%BB%B7%E6%A0%BC.md)、[按系统地区换算订阅价格币种](issue_%E6%8C%89%E7%B3%BB%E7%BB%9F%E5%9C%B0%E5%8C%BA%E6%8D%A2%E7%AE%97%E8%AE%A2%E9%98%85%E4%BB%B7%E6%A0%BC%E5%B8%81%E7%A7%8D.md)、[通过OAuth与Web接口获取Kimi额度](issue_%E9%80%9A%E8%BF%87OAuth%E4%B8%8EWeb%E6%8E%A5%E5%8F%A3%E8%8E%B7%E5%8F%96Kimi%E9%A2%9D%E5%BA%A6.md)、[展示已安装但尚未接入Dashboard的应用](issue_%E5%B1%95%E7%A4%BA%E5%B7%B2%E5%AE%89%E8%A3%85%E4%BD%86%E5%B0%9A%E6%9C%AA%E6%8E%A5%E5%85%A5Dashboard%E7%9A%84%E5%BA%94%E7%94%A8.md)、[接入Claude组织与usage接口解析额度](issue_%E6%8E%A5%E5%85%A5Claude%E7%BB%84%E7%BB%87%E4%B8%8Eusage%E6%8E%A5%E5%8F%A3%E8%A7%A3%E6%9E%90%E9%A2%9D%E5%BA%A6.md)、[由Antigravity接替Gemini主动额度采集](issue_%E7%94%B1Antigravity%E6%8E%A5%E6%9B%BFGemini%E4%B8%BB%E5%8A%A8%E9%A2%9D%E5%BA%A6%E9%87%87%E9%9B%86.md)、[支持选择Cookie来源浏览器](issue_%E6%94%AF%E6%8C%81%E9%80%89%E6%8B%A9Cookie%E6%9D%A5%E6%BA%90%E6%B5%8F%E8%A7%88%E5%99%A8.md)、[通过Web接口获取MiniMax额度与套餐费用](issue_%E9%80%9A%E8%BF%87Web%E6%8E%A5%E5%8F%A3%E8%8E%B7%E5%8F%96MiniMax%E9%A2%9D%E5%BA%A6%E4%B8%8E%E5%A5%97%E9%A4%90%E8%B4%B9%E7%94%A8.md)、[通过本地服务获取Antigravity额度](issue_%E9%80%9A%E8%BF%87%E6%9C%AC%E5%9C%B0%E6%9C%8D%E5%8A%A1%E8%8E%B7%E5%8F%96Antigravity%E9%A2%9D%E5%BA%A6.md)、[支持同一服务的多身份订阅](issue_%E6%94%AF%E6%8C%81%E5%90%8C%E4%B8%80%E6%9C%8D%E5%8A%A1%E7%9A%84%E5%A4%9A%E8%BA%AB%E4%BB%BD%E8%AE%A2%E9%98%85.md)、[凭证缺失时继续尝试后续额度来源](issue_%E5%87%AD%E8%AF%81%E7%BC%BA%E5%A4%B1%E6%97%B6%E7%BB%A7%E7%BB%AD%E5%B0%9D%E8%AF%95%E5%90%8E%E7%BB%AD%E9%A2%9D%E5%BA%A6%E6%9D%A5%E6%BA%90.md)、[调研TraeWork独立Provider接入](issue_%E8%B0%83%E7%A0%94TraeWork%E7%8B%AC%E7%AB%8BProvider%E6%8E%A5%E5%85%A5.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

- [x] [0.2.0-DATA-B-000] 为每个已探测到的可用 Agent 获取订阅/额度/用量信息 #P1 — `RefreshCoordinator` + `FetchPipeline`
- [x] [0.2.0-DATA-B-001] 支持从浏览器 Cookie 读取服务商 Dashboard 数据（参考 CodexBar 的 Cookie 复用机制）#P1 — `FilesystemCookieReader` (SweetCookieKit) + `BrowserCookieProvider`
- [x] [0.2.0-DATA-B-002] 支持从本地 CLI 日志或 RPC 接口读取额度数据（如 Codex CLI 本地 JSONL 日志）#P1 — `CLILogProvider` (Codex)
- [x] [0.2.0-DATA-B-003] 支持从 Keychain 中的 OAuth token 或 API key 读取额度数据 #P1 — `KeychainProvider.readToken()`
- [x] [0.2.0-DATA-B-004] 将获取到的数据映射到现有 UI 模型：月费、session 额度、weekly 额度、重置时间 #P1 — `CodexDashboardParser`
- [x] [0.2.0-DATA-B-005] 获取失败时保留上一次有效数据，并在 UI 中标记「数据可能过期」#P1 — `ProviderSnapshot.isStale` 字段已就位
- [x] [0.2.0-DATA-B-009] 未拿到真实 dashboard/usage 响应时不生成 Plus/Pro、价格或 100% 额度占位 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260620202608-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260620202608-utcp8-gpt5.md` @ `1532061d80cab44eba9d5469836105dedd72a7e8`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 根据更新的requirements约束条件[@AGENTS.md (80:108)](file:///Users/taobe/Projects/GitHub/Personal/quota-bar/AGENTS.md#L80:108) 更新文件[@REQUIREMENTS.md](file:///Users/taobe/Projects/GitHub/Personal/quota-bar/REQUIREMENTS.md)

#### 完成工作

- 已更新 `REQUIREMENTS.md`，使其符合 `AGENTS.md` 中新版 requirements 命名约束。
- 保留原有需求语义、完成状态、延后/取消标记与备注；仅调整结构、区块类型和 ID 形态。

#### 更新的需求 ID

- 本次为需求文档规范化，不新增产品需求。
- 原有旧 ID 已按新版格式迁移到版本化 ID。

#### 验证方式

- `python3` 自定义格式检查：通过，确认 `REQUIREMENTS.md` 的一级标题、二级 Phase 标题、三级任务区块和 task ID 均符合新版规则。
- `git --no-pager diff -- REQUIREMENTS.md`：已查看，确认改动集中在需求文档结构与 ID 规范化。

#### 备注

- 未运行 `swift build`，本次仅修改 Markdown 需求文档，不涉及 Swift 代码或构建流程。

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
