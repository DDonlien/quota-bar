---
title: 建立安全且向后兼容的本地持久化模型
id: 0.9.0-ARCH-A-000
type: ARCH
status: 进行中（原文同时包含已完成与未完成项）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.9.0 - 持久化、来源索引与启动兜底 / sub/main: 建立安全持久化模型。'
原稳定 ID: '`0.9.0-ARCH-A-000`, `0.9.0-ARCH-A-001`, `0.9.0-ARCH-A-002`, `0.9.0-SEC-A-000`, `0.9.0-SEC-A-001`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.9.0-ARCH-A-000`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.9.0-ARCH-A-000`、`0.9.0-ARCH-A-001`、`0.9.0-ARCH-A-002`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.9.0-ARCH-A-000-ARCH-security-model-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'sub/main: 建立安全持久化模型。'
同源任务: '[禁止默认刷新主动触发浏览器凭证授权](issue_%E7%A6%81%E6%AD%A2%E9%BB%98%E8%AE%A4%E5%88%B7%E6%96%B0%E4%B8%BB%E5%8A%A8%E8%A7%A6%E5%8F%91%E6%B5%8F%E8%A7%88%E5%99%A8%E5%87%AD%E8%AF%81%E6%8E%88%E6%9D%83.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

- [ ] [0.9.0-ARCH-A-000] 定义 Quota Bar 自有持久化目录：`~/Library/Application Support/QuotaBar/`；偏好、来源索引、last-known-good 快照都放在该目录下，不新增 `~/.quota-bar` 作为主路径 #P1
- [ ] [0.9.0-ARCH-A-001] 设计持久化 schema version 与向后兼容策略；所有持久化文件必须带 `schemaVersion`，读取失败时安全丢弃并回到实时抓取，不阻塞 app 启动 #P1
- [ ] [0.9.0-ARCH-A-002] 明确安全边界：持久化文件不得保存 token、cookie、API key、refresh token 或浏览器 Cookie 明文；敏感凭证仍只读取原始服务配置、浏览器 Cookie 或 macOS Keychain #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260705-170000-utcp8-taobe-gpt-5.md — 历史证据迁移

来源：`agent-log/20260705-170000-utcp8-taobe-gpt-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

检查你最新merge进来的功能，似乎实现的并不好：
1. 我在sub/main应该已经移除了所有对浏览器弹窗密码要求授权的功能，现在main上打包的版本还是保留了
2. 打出来的包没有用最新的图标，之前main上已经是最新图标了

#### 完成工作

- `macos/Sources/QuotaBar/AppDelegate.swift`：不再注册浏览器 Cookie Keychain 预授权弹窗。
- `macos/scripts/build-app.sh`：重新打出 `Quota Bar.app`，复制最新 `QuotaBar.icns`，写入 `CFBundleIconFile=QuotaBar`，并让 `build/latest` 使用相对软链。
- `REQUIREMENTS.md`：新增并完成 `[0.9.0-SEC-A-000]`。
- 已重新本地打包：`macos/build/latest/Quota Bar.app`。

#### 更新的需求 ID

- `[0.9.0-SEC-A-000]`

#### 验证方式

- `bash -n macos/scripts/build-app.sh`
- `rg -n "BrowserCookieKeychainPromptHandler|Quota Bar 需要 Keychain 授权|CFBundleIconFile|QuotaBar.icns|APP_NAME=|QuotaBar.app" macos/Sources macos/scripts REQUIREMENTS.md README.md`
- `make test`：首次在沙箱内因 SwiftPM 用户级模块缓存权限失败；经用户授权在沙箱外重跑通过，109 个测试全绿。
- `make app`：成功生成 `macos/build/20260705-165755-main/Quota Bar.app`。
- `test -d 'macos/build/latest/Quota Bar.app' && test -f 'macos/build/latest/Quota Bar.app/Contents/Resources/QuotaBar.icns'`
- `plutil -lint 'macos/build/latest/Quota Bar.app/Contents/Info.plist'`
- `/usr/libexec/PlistBuddy -c 'Print :CFBundleName' -c 'Print :CFBundleDisplayName' -c 'Print :CFBundleIconFile' -c 'Print :QBDisplayBuild' 'macos/build/latest/Quota Bar.app/Contents/Info.plist'`
- `codesign --verify --deep --strict --verbose=2 'macos/build/latest/Quota Bar.app'`

#### 备注

- 本次只修 main，不改 sub/main。
- `WebView 授权`入口没有在本次移除；本次移除的是启动时主动注册的浏览器 Cookie Keychain 预授权提示。

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
