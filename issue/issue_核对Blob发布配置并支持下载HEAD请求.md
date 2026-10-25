---
title: 核对Blob发布配置并支持下载HEAD请求
id: 0.15.0-QA-A-001
type: QA
status: 进行中（原文同时包含已完成与未完成项）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.15.0 - 7 天试用 + Creem 授权激活 + 发布链路迁移到 Vercel Blob / sub/main: 验证。'
原稳定 ID: '`0.15.0-QA-A-000`, `0.15.0-QA-A-001`, `0.15.0-QA-A-002`, `0.15.0-BE-B-002`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.15.0-QA-A-000`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.15.0-QA-A-001`、`0.15.0-BE-B-002`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.15.0-QA-A-000-QA-verification-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'sub/main: 验证。'
同源任务: '[核对试用授权边界与服务故障降级](issue_%E6%A0%B8%E5%AF%B9%E8%AF%95%E7%94%A8%E6%8E%88%E6%9D%83%E8%BE%B9%E7%95%8C%E4%B8%8E%E6%9C%8D%E5%8A%A1%E6%95%85%E9%9A%9C%E9%99%8D%E7%BA%A7.md)、[核对Creem激活所需的外部配置与端到端结果](issue_%E6%A0%B8%E5%AF%B9Creem%E6%BF%80%E6%B4%BB%E6%89%80%E9%9C%80%E7%9A%84%E5%A4%96%E9%83%A8%E9%85%8D%E7%BD%AE%E4%B8%8E%E7%AB%AF%E5%88%B0%E7%AB%AF%E7%BB%93%E6%9E%9C.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

共同范围与完整历史见[核对试用授权边界与服务故障降级](issue_%E6%A0%B8%E5%AF%B9%E8%AF%95%E7%94%A8%E6%8E%88%E6%9D%83%E8%BE%B9%E7%95%8C%E4%B8%8E%E6%9C%8D%E5%8A%A1%E6%95%85%E9%9A%9C%E9%99%8D%E7%BA%A7.md)；本文件保留以下独立目标的原文。

- [x] [0.15.0-QA-A-001] **Blob 链路端到端已验证**：用 Vercel CLI 建 public blob store（`quota-bar-releases`，自动注入 `BLOB_READ_WRITE_TOKEN` 到三个环境）+ 手动加 `BLOB_PUBLIC_BASE_URL`，token 经管道传入 GitHub Actions Secrets（值未落到任何输出）。`workflow_dispatch` 跑通一次真实发布：Blob 上传步骤执行、legacy fallback 被正确跳过、GitHub Release 不带 dmg；`curl` 确认 Blob 上 manifest 与 dmg 均可公开取到；重新部署后 `/api/latest-release` 已切到 Blob manifest（返回单条、资产 URL 指向 `/api/download-latest`），`/api/download-latest` 完整下载 2734775 字节且 `hdiutil verify` 校验 VALID
- [x] [0.15.0-BE-B-002] `api/download-latest.mjs` 补 `HEAD` 导出：Vercel 不会把 HEAD 自动路由到 GET，实测 `curl -I` 撞 405，会被下载器/代理误读成"地址挂了"；复用 GET 逻辑取真实响应头后丢掉 body，避免手写一份跟 GET 不一致的头

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 历史记录-时间未记录

原迁移条目的历史Comments完整保留于[同源历史](issue_%E6%A0%B8%E5%AF%B9%E8%AF%95%E7%94%A8%E6%8E%88%E6%9D%83%E8%BE%B9%E7%95%8C%E4%B8%8E%E6%9C%8D%E5%8A%A1%E6%95%85%E9%9A%9C%E9%99%8D%E7%BA%A7.md#comments)，不从历史日志新增完成标记。

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
