---
title: 为ClaudeOAuth读取提供Keychain凭证兜底
id: 0.10.0-DATA-B-017
type: DATA
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 修复 Claude 额度真正的根因（子进程环境裁剪）+ Keychain 凭证兜底。'
原稳定 ID: '`0.10.0-DATA-B-016`, `0.10.0-DATA-B-017`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.10.0-DATA-B-016`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.10.0-DATA-B-017`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.10.0-DATA-B-016-DATA-fixes-claude-quota-keychain-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'sub/main: 修复 Claude 额度真正的根因（子进程环境裁剪）+ Keychain 凭证兜底。'
同源任务: '[为Claude与MiniMax子进程保留必要环境](issue_%E4%B8%BAClaude%E4%B8%8EMiniMax%E5%AD%90%E8%BF%9B%E7%A8%8B%E4%BF%9D%E7%95%99%E5%BF%85%E8%A6%81%E7%8E%AF%E5%A2%83.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

共同范围与完整历史见[为Claude与MiniMax子进程保留必要环境](issue_%E4%B8%BAClaude%E4%B8%8EMiniMax%E5%AD%90%E8%BF%9B%E7%A8%8B%E4%BF%9D%E7%95%99%E5%BF%85%E8%A6%81%E7%8E%AF%E5%A2%83.md)；本文件保留以下独立目标的原文。

- [x] [0.10.0-DATA-B-017] `ClaudeOAuthUsageProvider` 增加 Keychain 凭证兜底：`~/.claude/.credentials.json` 不存在或解析失败时，改读 Keychain `"Claude Code-credentials"`（`ClaudeKeychainCredentialsReader`，取最近修改条目，同 0.10.0-DATA-B-014 的选择逻辑），同一套 JSON 解析复用两个来源；读取时**不设** `interactionNotAllowed`，允许系统弹出一次性「始终允许」授权（读取另一 App 写入的 Keychain 条目的标准流程，等价用户所说的"系统设置里开"，与浏览器 Cookie Keychain 静默降级的 0.9.0-SEC-A-001 是不同凭证来源，不适用同一条禁令）#P0 — 让只有 Keychain、没有凭证文件的机器（本机即是）也能不经 WebView 拿到真实额度

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 历史记录-时间未记录

原迁移条目的历史Comments完整保留于[同源历史](issue_%E4%B8%BAClaude%E4%B8%8EMiniMax%E5%AD%90%E8%BF%9B%E7%A8%8B%E4%BF%9D%E7%95%99%E5%BF%85%E8%A6%81%E7%8E%AF%E5%A2%83.md#comments)，不从历史日志新增完成标记。

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
