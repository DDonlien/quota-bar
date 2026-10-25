---
title: 按用户环境定位并执行CLI命令
id: 0.10.0-ARCH-C-000
type: ARCH
status: 进行中（原文同时包含已完成与未完成项）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 面向全网用户的 hardcoded 路径 / 假设审计。'
原稳定 ID: '`0.10.0-ARCH-C-000`, `0.10.0-ARCH-C-001`, `0.10.0-DATA-B-013`, `0.10.0-DATA-B-014`, `0.10.0-QA-B-000`, `0.10.0-DATA-B-015`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.10.0-ARCH-C-000`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.10.0-ARCH-C-000`、`0.10.0-ARCH-C-001`、`0.10.0-DATA-B-013`、`0.10.0-QA-B-000`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.10.0-ARCH-C-000-ARCH-hardcoded-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'sub/main: 面向全网用户的 hardcoded 路径 / 假设审计。'
同源任务: '[在同service的Keychain条目中选取最新凭证](issue_%E5%9C%A8%E5%90%8Cservice%E7%9A%84Keychain%E6%9D%A1%E7%9B%AE%E4%B8%AD%E9%80%89%E5%8F%96%E6%9C%80%E6%96%B0%E5%87%AD%E8%AF%81.md)、[支持从Edge多个浏览器Profile读取Cookie](issue_%E6%94%AF%E6%8C%81%E4%BB%8EEdge%E5%A4%9A%E4%B8%AA%E6%B5%8F%E8%A7%88%E5%99%A8Profile%E8%AF%BB%E5%8F%96Cookie.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> 用户明确本应用是面向全网用户售卖的商用软件，不是只给开发者本人用；要求不管本机环境如何，按理论上可行的方案把实现做好，并检查全部实现有没有 hardcoded 路径。审计范围：全部 Provider 实现、CLI 路径探测、Keychain 查询、货币/价格假设、个人信息残留。

- [x] [0.10.0-ARCH-C-000] 新增 `CLICommandLocator` 共享工具：两级解析——先查一批常见固定安装目录（Homebrew 双架构、MacPorts、用户级 `~/.local/bin` 等），命中失败再退化到登录 shell 解析（`$SHELL -lc 'command -v <cmd>'`，source 用户真实 shell 配置，覆盖 nvm / asdf / pnpm 等任意版本管理器或自定义 PATH）；按命令名做进程内缓存（一次 App 生命周期只解析一次）；拒绝含 shell 元字符的命令名，防止拼进 `-lc` 字符串被注入 #P0 — 此前 `MiniMaxCommandProvider`/`AntigravityCLISessionProvider`/`ClaudeAuthStatusCLIProvider`/`InstallDetectorProvider` 各自维护一份不完整、互相不一致的固定路径清单，只覆盖 Homebrew 默认前缀，漏掉 nvm/asdf/pnpm/MacPorts 等真实用户会用到的安装方式
- [x] [0.10.0-ARCH-C-001] `MiniMaxCommandProvider` / `AntigravityCLISessionProvider` / `ClaudeAuthStatusCLIProvider` 改为默认走 `CLICommandLocator`（显式传入候选路径时仍走原候选列表，保持测试确定性）；`InstallDetectorProvider.findCommand` 同步改为委托 `CLICommandLocator`，移除原本因未设置 PATH 而形同虚设的裸 `which` fallback，四处路径探测收敛为单一实现 #P0
- [x] [0.10.0-DATA-B-013] 修正 `ClaudeAuthStatusCLIProvider` 的路径漂移 bug：existence 检查用的候选列表和实际执行的 `runProcess` 各自硬编码了一份独立列表，可能不一致；改为解析路径后作为参数传给 executor（与 MiniMax/Antigravity 两个 provider 已有模式一致）#P1
- [x] [0.10.0-QA-B-000] 审计确认无需改动的项：`NSHomeDirectory()` 全部用法均动态取当前用户主目录（非 hardcode）；代码/测试/README/REQUIREMENTS 无残留个人用户名、邮箱、真实 org ID；`PreferredCurrency`/`ExchangeRateProvider` 的 USD/CNY 双档设计是既有文档化范围，非 bug；未发现任何架构（arm64/x86_64）分支判断 #P2

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

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
