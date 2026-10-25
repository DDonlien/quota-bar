---
title: 记录并展示Provider分层获取诊断日志
id: 0.10.0-ARCH-E-000
type: ARCH
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: Preferences provider 列表遗漏 + dropdown Claude 消失架构 bug + 分层诊断日志 + dropdown 显示规则重写。'
原稳定 ID: '`0.10.0-BUG-A-000`, `0.10.0-BUG-A-001`, `0.10.0-ARCH-E-000`, `0.10.0-ARCH-E-001`, `0.10.0-ARCH-E-002`, `0.10.0-PM-A-014`, `0.10.0-UI-B-000`, `0.10.0-UI-B-001`, `0.10.0-CLEAN-A-000`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.10.0-BUG-A-000`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.10.0-ARCH-E-000`、`0.10.0-ARCH-E-001`、`0.10.0-ARCH-E-002`、`0.10.0-PM-A-014`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.10.0-BUG-A-000-ARCH-preferences-provider-list-dropdown-claude-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'sub/main: Preferences provider 列表遗漏 + dropdown Claude 消失架构 bug + 分层诊断日志 + dropdown 显示规则重写。'
同源任务: '[在模型偏好页补齐Antigravity开关](issue_%E5%9C%A8%E6%A8%A1%E5%9E%8B%E5%81%8F%E5%A5%BD%E9%A1%B5%E8%A1%A5%E9%BD%90Antigravity%E5%BC%80%E5%85%B3.md)、[按真实档位与额度完善Dropdown显示](issue_%E6%8C%89%E7%9C%9F%E5%AE%9E%E6%A1%A3%E4%BD%8D%E4%B8%8E%E9%A2%9D%E5%BA%A6%E5%AE%8C%E5%96%84Dropdown%E6%98%BE%E7%A4%BA.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

共同范围与完整历史见[在模型偏好页补齐Antigravity开关](issue_%E5%9C%A8%E6%A8%A1%E5%9E%8B%E5%81%8F%E5%A5%BD%E9%A1%B5%E8%A1%A5%E9%BD%90Antigravity%E5%BC%80%E5%85%B3.md)；本文件保留以下独立目标的原文。

- [x] [0.10.0-ARCH-E-000] 新增 `ProviderCheckLog` actor + `ProviderCheckLogStore`：按用户规格实现结构化分层获取诊断日志，格式 `<yyyy.mm.dd_hh.mm.ss> - <ProviderName>: <CheckStep>, <MethodName>: <Result>`；CheckStep 对应 README 四层获取矩阵（Provider 获取/额度获取/过期日获取/档位与费用获取）；按 provider 缓冲、该 provider 本轮工作完全结束才整段落盘，保证同一 provider 的行始终连续输出，check step / method name 按真实调用顺序自然满足；结果里明示缓存命中/失效、成功获取到的信息、失败原因 #P0
- [x] [0.10.0-ARCH-E-001] 确认并保留现有并发模型：`RefreshCoordinator` 对安装探测和 pipeline+过期日阶段都用 `withTaskGroup` 做 provider 间并发；单个 provider 内部（`FetchPipeline.runSequential`、`SubscriptionExpiryResolver.resolve`）都是严格 for 循环顺序执行——已经符合"provider 内顺序检查、provider 间并发检查"，本次只新增日志埋点，不改变原有并发架构 #P0
- [x] [0.10.0-ARCH-E-002] 埋点覆盖三处：`InstallDetectorProvider.detectSources`（App Bundle / CLI 命令 / 环境变量 / 凭证文件逐项命中与否，含"上次成功来源缓存"命中/失效提示）、`FetchPipeline.runSequential`（每次 strategy 尝试按 `supportedLayers ∩ {quota, plan}` 各记一条，一次 fetch 同时贡献额度+档位时记两条）、`SubscriptionExpiryResolver.resolve`（每个 expiry source 尝试的成功/失败明细）#P0
- [x] [0.10.0-PM-A-014] Preferences 新增「日志」sidebar 页（`DiagnosticsSettingsView`），只读展示 `ProviderCheckLogStore` 落盘内容，支持刷新/复制全部/清空 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 历史记录-时间未记录

原迁移条目的历史Comments完整保留于[同源历史](issue_%E5%9C%A8%E6%A8%A1%E5%9E%8B%E5%81%8F%E5%A5%BD%E9%A1%B5%E8%A1%A5%E9%BD%90Antigravity%E5%BC%80%E5%85%B3.md#comments)，不从历史日志新增完成标记。

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
