---
title: 为仅有订阅档位的Provider显示灰色状态灯
id: 0.10.0-BUG-A-005
type: UI
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: dropdown 全局规则纠正 + 日志页体验 + 日志内容可读性统一。'
原稳定 ID: '`0.10.0-UI-C-000`, `0.10.0-ARCH-G-000`, `0.10.0-BUG-A-005`, `0.10.0-UI-C-001`, `0.10.0-ARCH-G-001`, `0.10.0-ARCH-G-002`, `0.10.0-BUG-A-006`, `0.10.0-INVESTIGATE-A-000`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.10.0-ARCH-G-000`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.10.0-BUG-A-005`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.10.0-ARCH-G-000-UI-dropdown-rules-experience-content-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'sub/main: dropdown 全局规则纠正 + 日志页体验 + 日志内容可读性统一。'
同源任务: '[保持日志页宽度并在日志变化后更新内容](issue_%E4%BF%9D%E6%8C%81%E6%97%A5%E5%BF%97%E9%A1%B5%E5%AE%BD%E5%BA%A6%E5%B9%B6%E5%9C%A8%E6%97%A5%E5%BF%97%E5%8F%98%E5%8C%96%E5%90%8E%E6%9B%B4%E6%96%B0%E5%86%85%E5%AE%B9.md)、[统一WebView授权提示的下划线规则](issue_%E7%BB%9F%E4%B8%80WebView%E6%8E%88%E6%9D%83%E6%8F%90%E7%A4%BA%E7%9A%84%E4%B8%8B%E5%88%92%E7%BA%BF%E8%A7%84%E5%88%99.md)、[统一诊断日志层级顺序与来源分类](issue_%E7%BB%9F%E4%B8%80%E8%AF%8A%E6%96%AD%E6%97%A5%E5%BF%97%E5%B1%82%E7%BA%A7%E9%A1%BA%E5%BA%8F%E4%B8%8E%E6%9D%A5%E6%BA%90%E5%88%86%E7%B1%BB.md)、[排查ClaudeOAuth与Keychain凭证读取失败](issue_%E6%8E%92%E6%9F%A5ClaudeOAuth%E4%B8%8EKeychain%E5%87%AD%E8%AF%81%E8%AF%BB%E5%8F%96%E5%A4%B1%E8%B4%A5.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

共同范围与完整历史见[保持日志页宽度并在日志变化后更新内容](issue_%E4%BF%9D%E6%8C%81%E6%97%A5%E5%BF%97%E9%A1%B5%E5%AE%BD%E5%BA%A6%E5%B9%B6%E5%9C%A8%E6%97%A5%E5%BF%97%E5%8F%98%E5%8C%96%E5%90%8E%E6%9B%B4%E6%96%B0%E5%86%85%E5%AE%B9.md)；本文件保留以下独立目标的原文。

- [x] [0.10.0-BUG-A-005] `ProviderSnapshot.statusColor` 的 `.available` 分支修复：`primarySubscriptionGroupWorstQuota` 为 nil（tier-only 兜底层成功、额度层还没拿到，如 Claude 常见的 CLI-only 状态）时，原来用 `?? 1.0` 兜底把"不知道剩多少"当成"剩 100%"画绿灯；改为这种情况下返回灰色"未知"灯，跟 loading/needsConfiguration 同一套语义 #P0

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 历史记录-时间未记录

原迁移条目的历史Comments完整保留于[同源历史](issue_%E4%BF%9D%E6%8C%81%E6%97%A5%E5%BF%97%E9%A1%B5%E5%AE%BD%E5%BA%A6%E5%B9%B6%E5%9C%A8%E6%97%A5%E5%BF%97%E5%8F%98%E5%8C%96%E5%90%8E%E6%9B%B4%E6%96%B0%E5%86%85%E5%AE%B9.md#comments)，不从历史日志新增完成标记。

原记录时间、具体执行 Agent、模型与原会话未记录，未补造。

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
