---
title: 在同service的Keychain条目中选取最新凭证
id: 0.10.0-DATA-B-014
type: ARCH
status: 进行中（原文同时包含已完成与未完成项）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 面向全网用户的 hardcoded 路径 / 假设审计。'
原稳定 ID: '`0.10.0-ARCH-C-000`, `0.10.0-ARCH-C-001`, `0.10.0-DATA-B-013`, `0.10.0-DATA-B-014`, `0.10.0-QA-B-000`, `0.10.0-DATA-B-015`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.10.0-ARCH-C-000`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.10.0-DATA-B-014`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.10.0-ARCH-C-000-ARCH-hardcoded-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'sub/main: 面向全网用户的 hardcoded 路径 / 假设审计。'
同源任务: '[按用户环境定位并执行CLI命令](issue_%E6%8C%89%E7%94%A8%E6%88%B7%E7%8E%AF%E5%A2%83%E5%AE%9A%E4%BD%8D%E5%B9%B6%E6%89%A7%E8%A1%8CCLI%E5%91%BD%E4%BB%A4.md)、[支持从Edge多个浏览器Profile读取Cookie](issue_%E6%94%AF%E6%8C%81%E4%BB%8EEdge%E5%A4%9A%E4%B8%AA%E6%B5%8F%E8%A7%88%E5%99%A8Profile%E8%AF%BB%E5%8F%96Cookie.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

共同范围与完整历史见[按用户环境定位并执行CLI命令](issue_%E6%8C%89%E7%94%A8%E6%88%B7%E7%8E%AF%E5%A2%83%E5%AE%9A%E4%BD%8D%E5%B9%B6%E6%89%A7%E8%A1%8CCLI%E5%91%BD%E4%BB%A4.md)；本文件保留以下独立目标的原文。

- [x] [0.10.0-DATA-B-014] `KeychainProvider.readToken()` 的 service-only（account=nil）查询路径改为 `kSecMatchLimitAll` 取全部匹配项后按 `kSecAttrModificationDate` 选最近修改的一条，而不是 Keychain 内部枚举顺序里任意一条——覆盖重装 / 多版本 CLI 各自写入同 service 不同条目的场景 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 历史记录-时间未记录

原迁移条目的历史Comments完整保留于[同源历史](issue_%E6%8C%89%E7%94%A8%E6%88%B7%E7%8E%AF%E5%A2%83%E5%AE%9A%E4%BD%8D%E5%B9%B6%E6%89%A7%E8%A1%8CCLI%E5%91%BD%E4%BB%A4.md#comments)，不从历史日志新增完成标记。

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
