---
title: 通过GitHubReleases检查应用更新
id: 0.11.0-FE-A-000
type: FE
status: 进行中（原文同时包含已完成与未完成项）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.11.0 - 真实自动更新（ad-hoc 预开发版）+ semver 发版 / update/main: 实现 UpdateChecker（GitHub Releases API）。'
原稳定 ID: '`0.11.0-FE-A-000`, `0.11.0-FE-A-001`, `0-9a-f`, `0.11.0-FE-A-002`, `0.11.0-FE-A-003`, `0.11.0-FE-A-004`, `0.11.0-FE-A-005`, `0.11.0-FE-A-006`, `0.11.0-FE-A-007`, `0.11.0-FE-A-000-test`, `0.11.0-FE-A-003-test`；不改写或重编号这些既有 ID。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> 调公开 API，无需鉴权（60 req/IP/h 限流单用户自用足够）。解析 semver + nightly 两种 tag，取「当前 channel 视角下的最新可用版本」。

- [x] [0.11.0-FE-A-000] 新增 `macos/Sources/QuotaBar/UpdateChecker.swift`：使用 `URLSession` 调 `https://api.github.com/repos/DDonlien/quota-bar/releases?per_page=30`，不鉴权 #P1
- [x] [0.11.0-FE-A-001] `UpdateChecker` 解析 release list：semver tag 用 `^v\d+\.\d+\.\d+$` 正则匹配（不匹配 prerelease 如 `v0.11.0-rc1`），nightly tag 用 `^nightly-[0-9a-f]{7,40}$` 匹配 #P1
- [x] [0.11.0-FE-A-002] `UpdateChecker` 状态机：`idle` / `checking` / `updateAvailable(remoteVersion, channel, releaseURL, assetURL, releaseNotes)` / `upToDate(currentVersion)` / `error(message)`；使用 `@MainActor @Published` 暴露给 SwiftUI #P1
- [x] [0.11.0-FE-A-003] 版本比较：semver 段按三段数字比（`v0.10.0` < `v0.11.0` < `v0.2.0` 不成立）；nightly 之间用日期戳 `YYMMDD.HHMMSS.branch` 字符串字典序比（等价于时间序）；semver stable 永远优先于 nightly 推荐 #P1
- [x] [0.11.0-FE-A-004] `UpdateChecker` 暴露 `currentVersion: String`（`Bundle.main.CFBundleShortVersionString`）和 `currentBuild: String`（`Bundle.main.CFBundleVersion`）便于比较 #P1
- [x] [0.11.0-FE-A-005] 检查默认在「关于」页打开时后台触发一次；用户也可手动点「检查更新」按钮触发；触发时 `idle` → `checking` → 终态 #P1
- [x] [0.11.0-FE-A-006] 网络超时 10s；错误状态展示中文友好提示（「无法连接到 GitHub，请检查网络」），不暴露原始 API 错误；限流命中（403 with X-RateLimit-Remaining: 0）时显示「检查过于频繁，请稍后重试」#P1
- [x] [0.11.0-FE-A-007] `UpdateChecker` 缓存上次检查结果到 `PreferencesStore.QuotaPreferences.lastUpdateCheck: Date?`；同一 session 内 `AboutSettingsView` 重新打开时若 5min 内已查过不重复请求 #P1
- [ ] [0.11.0-FE-A-000-test] mock `URLProtocol` 喂各种 release JSON：纯 nightly / 纯 semver / 混合 / prerelease / 空 list / 限流 403 / 网络超时；验证 state machine 正确转移 #P1
- [x] [0.11.0-FE-A-003-test] 版本比较单元测试：`v0.2.0 < v0.10.0`（数字比）、`v0.2.0-rc1 < v0.2.0`（prerelease 不进 stable 比）、`v0.2.0 stable > nightly-<sha>`（stable 优先）、`nightly-260701 < nightly-260702`（日期戳字典序）#P1 — 实现偏差：nightly tag 本身是 `nightly-<sha>` 无日期戳，改用 GitHub release `published_at` 比较新旧，本地构建时间从 `CFBundleVersion`（YYMMDD.HHMMSS）解析；测试见 `UpdateCheckerTests`

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260702143521-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260702143521-utcp8-gpt5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> /Users/taobe/Projects/GitHub/Reference
> 看看这三个参考项目，看看他们是怎么实现额度获取的
>
> 另外：即使只是按需的时候跳弹窗，要求输入密码并允许从而获取 cookie，这个体验也非常非常差。
>
> 我们要么找到别的方法，不跳弹窗，只通过长期的系统设置就能获取到 cookie；要么找别的 work around，也就是不依赖这个浏览器 cookie 的获取
>
> 但在那之前，我们要先解决额度本身准确获取的问题。
>
> 这个 cookie 如果只和过期日有关，你就先别管；如果和别的也有关，就一起看。

#### 完成工作

- 得出产品策略建议：先解决 Codex 额度准确性，不应把 `id_token` 的订阅过期字段作为当前真相；Codex 额度应优先走 OAuth access/refresh token 或 Codex RPC/CLI，浏览器 cookie 降级为可选补充。
- 得出权限策略建议：Full Disk Access 只能解决读取某些文件路径的问题，不能优雅消除 Chromium cookie 解密需要访问 Keychain safe storage 的系统弹窗；最佳 workaround 是避免系统浏览器 cookie 作为核心路径，改用 CLI/OAuth、本应用内登录、手动 token/header 或 provider 官方/半官方接口。

#### 更新的需求 ID

无。本次只做调查与方案判断。

#### 验证方式

- 使用 `rg`、`find`、`sed` 阅读三个参考项目的 README 和关键 Swift 源码。
- 未运行本项目构建或测试，因为本次未修改实现代码。

#### 备注

- 当前工作区已有未跟踪日志文件 `agent-log/20260702141144-utcp8-gpt5.md`，本次未处理其 git 状态。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260618210258-utcp8-minimax-m3.md — 历史证据迁移

来源：`agent-log/20260618210258-utcp8-minimax-m3.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 太复杂了，这么做：
>
> 创建一个 github action，每次提交自动打包，发到 release，我从 release 里下载 .dmg 直接拖到 application（甚至直接在 dmg 里双击）测试

#### 验证方式

- 静态：yml 语法可在 GitHub web editor / `actionlint` 校验
- CI：本地无法跑（沙箱限制）；用户 push 到 main 后看 Actions tab
- 应用：用户从 Releases 下载 dmg → 拖到 Applications → 启动 → 验证

#### 需求 / 设计更新

- `REQUIREMENTS.md`：未变更（CI 自动化不构成新需求点）
- `README.md`：已更新（入口指向 Releases）
- `DESIGN.md`：未变更
- `AGENTS.md`：未变更

#### 备注

- push 触发后第一次跑可能要装 SweetCookieKit 的依赖（10s 左右），会被 SPM cache 命中
- 如果 `macos-26` runner 不存在，`build` job 会立刻报「no matching runner」，届时把两个 `runs-on` 改成 `macos-15` + 升级到 Xcode 26 即可（release job 复用 build job 的 cache，重 build 几乎免费）
- 用户在系统设置里看到的应用名仍是 "Quota Bar"（DisplayName 修改与本任务无关，但本 workflow 用了相同的 plist 字符串）
- 没改 `APP_NAME`：`.app` 文件夹与二进制仍是 `CodingPlanMenu.app` / `CodingPlanMenu`（与上一轮 DisplayName 修改保持一致）
- 用户每次 push 后会得到一个 prerelease，列表里会按时间倒序排列；如要"稳定版"再另外用 tag 触发 release，目前未做（用户没要求）

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-070408_Agent

原记录标题：2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-162234_Codex

按用户最新手写模板迁移属性和正文结构，保留任务语义、来源、原始状态及历史内容；本次未重新执行业务验收。

原版本关联记录（照录来源，不将本次文档迁移提交当作业务实施提交）：
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。

本次执行环境未提供具体模型标识，未补造 Model-Detail。

[本次文档迁移对话](codex://threads/01a157b3-610c-73b4-ae06-163c0f8490d3)
