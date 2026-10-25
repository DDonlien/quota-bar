---
title: 接通Provider刷新超时偏好
id: 0.10.0-BUG-A-016
type: ARCH
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 偏好设置摆设字段全面审计 + WebView 授权修复 + 移除浏览器 Cookie 文件读取。'
原稳定 ID: '`0.10.0-BUG-A-014`, `0.10.0-BUG-A-015`, `0.10.0-ARCH-K-000`, `0.10.0-ARCH-K-001`, `0.10.0-CLEAN-A-001`, `0.10.0-BUG-A-016`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.10.0-BUG-A-014`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.10.0-BUG-A-016`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.10.0-BUG-A-014-ARCH-webview-fixes-cookie-files-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'sub/main: 偏好设置摆设字段全面审计 + WebView 授权修复 + 移除浏览器 Cookie 文件读取。'
同源任务: '[补齐WebView真实授权能力与SSO弹窗处理](issue_%E8%A1%A5%E9%BD%90WebView%E7%9C%9F%E5%AE%9E%E6%8E%88%E6%9D%83%E8%83%BD%E5%8A%9B%E4%B8%8ESSO%E5%BC%B9%E7%AA%97%E5%A4%84%E7%90%86.md)、[移除浏览器Cookie文件读取路径及相关偏好](issue_%E7%A7%BB%E9%99%A4%E6%B5%8F%E8%A7%88%E5%99%A8Cookie%E6%96%87%E4%BB%B6%E8%AF%BB%E5%8F%96%E8%B7%AF%E5%BE%84%E5%8F%8A%E7%9B%B8%E5%85%B3%E5%81%8F%E5%A5%BD.md)、[删除无消费方的偏好字段与访问器](issue_%E5%88%A0%E9%99%A4%E6%97%A0%E6%B6%88%E8%B4%B9%E6%96%B9%E7%9A%84%E5%81%8F%E5%A5%BD%E5%AD%97%E6%AE%B5%E4%B8%8E%E8%AE%BF%E9%97%AE%E5%99%A8.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

共同范围与完整历史见[补齐WebView真实授权能力与SSO弹窗处理](issue_%E8%A1%A5%E9%BD%90WebView%E7%9C%9F%E5%AE%9E%E6%8E%88%E6%9D%83%E8%83%BD%E5%8A%9B%E4%B8%8ESSO%E5%BC%B9%E7%AA%97%E5%A4%84%E7%90%86.md)；本文件保留以下独立目标的原文。

- [x] [0.10.0-BUG-A-016] 接通 `advanced.providerTimeoutSeconds`：新增 `ProviderTimeoutOption` 离散选项（10/15/20/30 秒，跟 `RefreshIntervalOption` 同一设计）+ `PreferencesStore.setProviderTimeout`/`currentProviderTimeoutOption`；`GeneralSettingsView` 新增「Provider 刷新超时」Picker；`StatusBarController`/`RefreshCoordinator` 启动时读取、运行中通过 `applyProviderTimeoutChange()` 实时同步——此前这个字段有意图（默认值 30，`RefreshCoordinator.providerTimeout` 默认值却是不同步的 10）但从未接通，跟 `refreshIntervalSeconds` 是同一类 bug #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 历史记录-时间未记录

原迁移条目的历史Comments完整保留于[同源历史](issue_%E8%A1%A5%E9%BD%90WebView%E7%9C%9F%E5%AE%9E%E6%8E%88%E6%9D%83%E8%83%BD%E5%8A%9B%E4%B8%8ESSO%E5%BC%B9%E7%AA%97%E5%A4%84%E7%90%86.md#comments)，不从历史日志新增完成标记。

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
