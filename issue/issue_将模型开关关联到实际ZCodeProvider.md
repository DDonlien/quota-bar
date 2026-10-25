---
title: 将模型开关关联到实际ZCodeProvider
id: 0.10.0-BUG-A-010
type: ARCH
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 更新检查改为纯版本号比较 + dropdown 隐藏按钮实时刷新 + GLM/Z Code 开关关联修复。'
原稳定 ID: '`0.10.0-ARCH-J-000`, `0.10.0-ARCH-J-001`, `0.10.0-ARCH-J-002`, `0.10.0-DOC-A-005`, `0.10.0-BUG-A-009`, `0.10.0-BUG-A-010`, `0.10.0-QA-A-001`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.10.0-ARCH-J-000`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.10.0-BUG-A-010`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.10.0-ARCH-J-000-ARCH-dropdown-refresh-glm-code-fixes-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'sub/main: 更新检查改为纯版本号比较 + dropdown 隐藏按钮实时刷新 + GLM/Z Code 开关关联修复。'
同源任务: '[以语义版本号比较更新并统一VERSION来源](issue_%E4%BB%A5%E8%AF%AD%E4%B9%89%E7%89%88%E6%9C%AC%E5%8F%B7%E6%AF%94%E8%BE%83%E6%9B%B4%E6%96%B0%E5%B9%B6%E7%BB%9F%E4%B8%80VERSION%E6%9D%A5%E6%BA%90.md)、[在菜单Tracking期间立即刷新偏好变更](issue_%E5%9C%A8%E8%8F%9C%E5%8D%95Tracking%E6%9C%9F%E9%97%B4%E7%AB%8B%E5%8D%B3%E5%88%B7%E6%96%B0%E5%81%8F%E5%A5%BD%E5%8F%98%E6%9B%B4.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

共同范围与完整历史见[以语义版本号比较更新并统一VERSION来源](issue_%E4%BB%A5%E8%AF%AD%E4%B9%89%E7%89%88%E6%9C%AC%E5%8F%B7%E6%AF%94%E8%BE%83%E6%9B%B4%E6%96%B0%E5%B9%B6%E7%BB%9F%E4%B8%80VERSION%E6%9D%A5%E6%BA%90.md)；本文件保留以下独立目标的原文。

- [x] [0.10.0-BUG-A-010] `ModelsSettingsView.visibleProviders` 把幽灵 kind `.glm`（从未接入任何真实 pipeline）换成实际在跑的 `.zcode`——此前 Preferences 切 "GLM" 开关和 dropdown 隐藏 "Z Code" 是两个完全独立的 `ProviderOverride` 记录，互不影响；`providerVendor(.zcode)` 的展示文案从 `"Z Code"` 改为更准确的 `"智谱 / Z.ai"` #P0

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 历史记录-时间未记录

原迁移条目的历史Comments完整保留于[同源历史](issue_%E4%BB%A5%E8%AF%AD%E4%B9%89%E7%89%88%E6%9C%AC%E5%8F%B7%E6%AF%94%E8%BE%83%E6%9B%B4%E6%96%B0%E5%B9%B6%E7%BB%9F%E4%B8%80VERSION%E6%9D%A5%E6%BA%90.md#comments)，不从历史日志新增完成标记。

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
