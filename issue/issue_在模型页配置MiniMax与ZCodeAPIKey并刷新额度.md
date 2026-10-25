---
title: 在模型页配置MiniMax与ZCodeAPIKey并刷新额度
id: 0.10.0-ARCH-L-000
type: ARCH
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: dropdown 授权文案统一 + Preferences 新增 API Key 配置入口。'
原稳定 ID: '`0.10.0-BUG-A-017`, `0.10.0-ARCH-L-000`, `0.10.0-ARCH-L-001`, `0.10.0-PM-A-016`, `0.10.0-ARCH-L-002`, `0.10.0-DOC-A-006`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.10.0-BUG-A-017`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.10.0-ARCH-L-000`、`0.10.0-ARCH-L-001`、`0.10.0-PM-A-016`、`0.10.0-ARCH-L-002`、`0.10.0-DOC-A-006`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.10.0-BUG-A-017-ARCH-dropdown-preferences-api-key-configuration-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'sub/main: dropdown 授权文案统一 + Preferences 新增 API Key 配置入口。'
同源任务: '[按真实授权能力展示待配置提示](issue_%E6%8C%89%E7%9C%9F%E5%AE%9E%E6%8E%88%E6%9D%83%E8%83%BD%E5%8A%9B%E5%B1%95%E7%A4%BA%E5%BE%85%E9%85%8D%E7%BD%AE%E6%8F%90%E7%A4%BA.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

共同范围与完整历史见[按真实授权能力展示待配置提示](issue_%E6%8C%89%E7%9C%9F%E5%AE%9E%E6%8E%88%E6%9D%83%E8%83%BD%E5%8A%9B%E5%B1%95%E7%A4%BA%E5%BE%85%E9%85%8D%E7%BD%AE%E6%8F%90%E7%A4%BA.md)；本文件保留以下独立目标的原文。

- [x] [0.10.0-ARCH-L-000] 新增 `ProviderKind.apiKeyCapableKinds = [.minimax, .zcode]` 静态集合（跟 `webViewQuotaCapableKinds` 同一维护模式，新增/移除某 provider 的手动 key 支持时必须同步改这里）#P0
- [x] [0.10.0-ARCH-L-001] 新增 `ZCodeManualKeyStore`（`ZCodeAuthProvider.swift`）：Quota Bar 自己独占的 `~/Library/Application Support/QuotaBar/zcode-api-key.json`，供没装官方 Z Code CLI、只想手动粘贴 key 的用户使用；`ZCodeAuthProvider.configPaths` 把它排在最前，复用现有 `flattenStrings`/`isLikelyAPIKey` 通用解析逻辑识别，不需要额外解析代码 #P1 — `ZCodeAuthProviderTests`：missing-by-default、save/read 掩码显示、拒绝空 key 三个新测试
- [x] [0.10.0-PM-A-016] 「偏好设置 → 模型」页新增「API Key 配置」区块（`APIKeyConfigRow`），MiniMax 和 Z Code 各一行：展示"已配置 · 掩码 key"/"未配置"状态 + "配置/重置"按钮，点开后是原生 `SettingsRow` 风格的输入框（复用 dropdown 已有的 `APIKeyTextField`）；交互参考 Zed 的 provider 设置页（用户提供截图），视觉不复刻、沿用本页其余行的 macOS 26 原生风格。同步删除 dropdown 里原来 MiniMax 专属的内联输入框 `MiniMaxKeyInputField`（连带贯穿 5 层 View 的整条 `onSaveKey` 回调链），入口统一收敛到 Preferences #P0
- [x] [0.10.0-ARCH-L-002] 新增 `.providerCredentialsDidChange` 通知：Preferences 里保存 API key 成功后 post，`RefreshCoordinator` 订阅并 `refreshNow()`，不用等自动刷新周期——跟 `.webAuthorizationWindowDidClose` 同一类"用户刚做完授权动作应该立刻看到结果"的诉求 #P1
- [x] [0.10.0-DOC-A-006] 全面核对 `ModelsSettingsView.providerAccessModes` 跟 `Strategies.swift` 实际 pipeline 是否一致（用户反馈"这一页应该如实显示我们支持的获取模式"）：Codex/Kimi 的 "CLI" 改成更准确的 "Config"（默认 pipeline 没有真实 CLI 子进程执行）；Claude/Antigravity 补上遗漏的 "Keychain"；MiniMax/Z Code 统一用 "API" 标注——现在这个词对应一个真实可操作的能力（上面新增的手动输入入口），不再只是描述性标签 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 历史记录-时间未记录

原迁移条目的历史Comments完整保留于[同源历史](issue_%E6%8C%89%E7%9C%9F%E5%AE%9E%E6%8E%88%E6%9D%83%E8%83%BD%E5%8A%9B%E5%B1%95%E7%A4%BA%E5%BE%85%E9%85%8D%E7%BD%AE%E6%8F%90%E7%A4%BA.md#comments)，不从历史日志新增完成标记。

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
