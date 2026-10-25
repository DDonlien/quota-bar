---
title: 精简APIKey配置行文案并修复反引号显示
id: 0.10.0-BUG-A-021
type: PM
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: API Key 配置行视觉优化 + opencode 手动 Key 支持。'
原稳定 ID: '`0.10.0-BUG-A-021`, `0.10.0-PM-A-017`, `0.10.0-ARCH-L-004`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.10.0-BUG-A-021`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.10.0-BUG-A-021`、`0.10.0-PM-A-017`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.10.0-BUG-A-021-PM-api-key-configuration-visual-optimization-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'sub/main: API Key 配置行视觉优化 + opencode 手动 Key 支持。'
同源任务: '[为opencode提供独立手动APIKey存储](issue_%E4%B8%BAopencode%E6%8F%90%E4%BE%9B%E7%8B%AC%E7%AB%8B%E6%89%8B%E5%8A%A8APIKey%E5%AD%98%E5%82%A8.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> 用户给了一张「API Key 配置」区块的截图，要求"优化一下这里的视觉呈现，给opencode加上api配置功能"。

- [x] [0.10.0-BUG-A-021] 修复 `APIKeyConfigRow.statusText` 里字面量反引号原样显示的问题：`SettingsRow.subtitle` 原本是 `String?`，走 `Text(_ content: some StringProtocol)` 初始化器，不会像 `Text(_ key: LocalizedStringKey)` 那样解析 Markdown，"当前 `sk-xxx`" 里的反引号只会被渲染成两个字面字符，而不是等宽代码样式。改法：`SettingsRow.subtitle` 类型改成 `Text?`（新增一个 `String?` 重载保持其余 5 处调用点不用改），`statusText` 用 `Text` 插值把技术性的值（占位符当前值 / 掩码后的 key）单独标成等宽字体，跟说明文字拼在一起 #P1
- [x] [0.10.0-PM-A-017] 「API Key 配置」区块顶部加一行说明文字（"给没有官方登录方式、或不想装官方 CLI 的 Provider 手动粘贴 API Key，仅保存在本机。"），对齐本页其余 section（Claude 额度捕获等）都有说明文字的惯例，之前这个区块顶部只有标题，缺少上下文 #P2

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260708-174554-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260708-174554-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

>（截图：Preferences「模型」页「API Key 配置」区块，MiniMax 行 subtitle 显示"待替换占位符 · 当前 `sk-xxx`"，Z Code 行展开编辑状态）
>
> 优化一下这里的视觉呈现，给opencode加上api配置功能

#### 完成工作

- `Preferences/SettingsComponents.swift`：`SettingsRow.subtitle` 从 `String?` 改成 `Text?`（新增 `String?` 重载做向后兼容转发）。
- `Preferences/ModelsSettingsView.swift`：
  - `APIKeyConfigRow.statusText` 改成返回 `Text`，用等宽字体单独标出技术性的值，去掉字面量反引号。
  - `apiKeySection` 顶部加一行说明文字。
  - `reload()`/`save()`/`missingHint` 三处 switch 补上 `.opencode` 分支。
  - `providerAccessModes` 里 opencode 从 `["Config"]` 改成 `["Config", "API"]`。
- `WebAuthorizationController.swift`：`apiKeyCapableKinds` 加入 `.opencode`。
- `OpenCodeAuthProvider.swift`：新增 `OpenCodeManualKeyStore`（读/写/掩码，跟 `ZCodeManualKeyStore` 同款），`fetchSnapshot` 加手动 key 回退分支，`init` 新增可注入的 `manualKeyConfigPath` 参数。
- `Tests/QuotaBarTests/OpenCodeAuthProviderTests.swift`：补一条"回退到手动 key 走 BYOK"的测试，原有"missingCredentials"测试改成显式传两个独立临时路径；新增 `OpenCodeManualKeyStoreTests`（missing-by-default / save-read 掩码 / 拒绝空 key）。
- `REQUIREMENTS.md`：新增 `[0.10.0-BUG-A-021]`（反引号渲染修复）、`[0.10.0-PM-A-017]`（section 说明文字）、`[0.10.0-ARCH-L-004]`（opencode 手动 key），并把 `[0.10.0-INVESTIGATE-A-004]` 补充成"已跑完"的状态。

新包：`macos/build/20260708-174554-main/Quota Bar.app`（`build/latest` 已指向；`build/20260708-174449-main` 那次打包内容一致，代码没有变化，是重复产物）。

#### 更新的需求 ID

- `[0.10.0-BUG-A-021]` `[0.10.0-PM-A-017]` `[0.10.0-ARCH-L-004]`

#### 验证方式

- `swift build`：无警告无错误（含 macOS 26 SDK 的 `Text` 插值写法，避免了 `+` 拼接的 deprecation 警告）。
- `swift test`：190 tests in 43 suites 全部通过（本轮新增 4 个测试：opencode 手动 key 回退 1 个 + `OpenCodeManualKeyStoreTests` 3 个）。
- `./scripts/build-app.sh`：产包成功。
- **未做**：没能用 computer-use 实机截图验证——`request_access` 找不到这个 App（LSUIElement/accessory 模式的菜单栏 App，没有 Dock 图标，且是未签名的开发态打包产物，不在 Launch Services 常规索引里，request_access 的应用名匹配机制找不到它），已经如实告知用户，请他们自己在真机上确认视觉效果。

#### 备注

- 未提交 git commit。
- 视觉改动没有实机截图验证，纯代码走读 + 理解 `Text`/`SettingsRow` 渲染逻辑得出的结论，建议用户实际打开 Preferences「模型」页确认一下等宽字体那段是否符合预期。

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
