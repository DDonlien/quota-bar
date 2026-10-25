---
title: 在模型偏好页补齐Antigravity开关
id: 0.10.0-BUG-A-000
type: ARCH
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: Preferences provider 列表遗漏 + dropdown Claude 消失架构 bug + 分层诊断日志 + dropdown 显示规则重写。'
原稳定 ID: '`0.10.0-BUG-A-000`, `0.10.0-BUG-A-001`, `0.10.0-ARCH-E-000`, `0.10.0-ARCH-E-001`, `0.10.0-ARCH-E-002`, `0.10.0-PM-A-014`, `0.10.0-UI-B-000`, `0.10.0-UI-B-001`, `0.10.0-CLEAN-A-000`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.10.0-BUG-A-000`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.10.0-BUG-A-000`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.10.0-BUG-A-000-ARCH-preferences-provider-list-dropdown-claude-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'sub/main: Preferences provider 列表遗漏 + dropdown Claude 消失架构 bug + 分层诊断日志 + dropdown 显示规则重写。'
同源任务: '[按真实档位与额度完善Dropdown显示](issue_%E6%8C%89%E7%9C%9F%E5%AE%9E%E6%A1%A3%E4%BD%8D%E4%B8%8E%E9%A2%9D%E5%BA%A6%E5%AE%8C%E5%96%84Dropdown%E6%98%BE%E7%A4%BA.md)、[记录并展示Provider分层获取诊断日志](issue_%E8%AE%B0%E5%BD%95%E5%B9%B6%E5%B1%95%E7%A4%BAProvider%E5%88%86%E5%B1%82%E8%8E%B7%E5%8F%96%E8%AF%8A%E6%96%AD%E6%97%A5%E5%BF%97.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> 用户实测发现两个真实 bug：Preferences「模型」页 provider 列表漏了 Antigravity；dropdown 里 Claude 彻底不显示（比"没额度"更严重）。同时要求新增结构化分层获取诊断日志，并按详细规格重写 dropdown 名称栏/额度栏的显示逻辑。

- [x] [0.10.0-BUG-A-000] `ModelsSettingsView.visibleProviders` 补上 `.antigravity`（此前只有 codex/minimax/kimi/claude/glm 五项，agy 完全没有开关行）#P0

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260630004130-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260630004130-utcp8-gpt5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> ok，那不纠结了，我们继续实际在这个分支制作preference页面，先看一下最新状态是什么，尤其是是否存在Main比这个worktree在这个功能更加新的情况

#### 完成工作

- 当前 `preferences/main` 相对 merge-base `8d69017` 包含 Preferences 第一版、AppKit 窗口接管、视觉对齐、隐藏 sidebar toggle、背景浅灰等提交。
- `origin/main` 相对同一 merge-base 更新了仓库路径结构：SwiftPM 包从 `quota-bar/` 移到 `macos/`，站点从 `web/` 移到 `site/`，并更新 CI / Makefile / 文档；未发现 main 上存在比当前分支更新的 Preferences 页面实现。
- 本地 `main` 额外有 `1532061`（Restore main branch to project root）及站点/logo/文档相关改动；同样未发现 Preferences 页面更新。
- 当前 worktree 有未提交修改：
  - `PreferencesStore.swift` 新增 `RefreshIntervalOption`，保留底层 `refreshIntervalSeconds` 兼容旧配置。
  - `GeneralSettingsView.swift` 将刷新间隔从 slider 改为 menu picker，并给 picker/toggle 加 `.controlSize(.small)`。
  - 多个 Settings 页面将 section spacing 从 24 调到 20，`SettingsRow` vertical padding 从 10 调到 7。

#### 更新的需求 ID

- 无。本轮仅做状态检查；后续若继续采用“刷新间隔固定下拉”方案，应更新 `0.3.0-PM-A-002` 的验收描述。

#### 验证方式

- `git pull`
- `git fetch origin`
- `git status --short --branch`
- `git log --oneline --decorate --left-right --cherry-pick HEAD...origin/main`
- `git diff --stat HEAD..origin/main`
- `git diff --stat`

#### 备注

- 继续制作 Preferences 页面前，建议先决定是否把 `origin/main` 的 `quota-bar/` -> `macos/` 路径重构合入当前 worktree。若不先对齐，后续 Preferences 文件仍会继续落在旧路径，最终合并时需要手动迁移到 `macos/Sources/QuotaBar/Preferences/`。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260630004524-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260630004524-utcp8-gpt5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 现在有 preference 功能的最新的build是哪个？我打开了俩都没有对应功能。

#### 完成工作

- 新生成 Preferences 最新 build：
  `quota-bar/build/20260630-004456-preferences-main/QuotaBar.app`
- 当前快捷入口已刷新为：
  `quota-bar/build/latest/QuotaBar.app`
- 已验证最新二进制包含：
  - `PreferencesWindowController`
  - `GeneralSettingsView`
  - `RefreshIntervalOption`

#### 更新的需求 ID

- 无

#### 验证方式

- `find quota-bar/build -maxdepth 3 -name 'QuotaBar.app' -type d -print`
- `readlink quota-bar/build/latest`
- `strings quota-bar/build/latest/QuotaBar.app/Contents/MacOS/QuotaBar | rg 'PreferencesWindowController|RefreshIntervalOption|GeneralSettingsView|偏好设置'`
- `swift package clean`
- `make app`

#### 备注

- 如果用户双击新包仍看不到 Preferences，优先怀疑旧 QuotaBar 进程仍在运行。菜单栏应用双击新 `.app` 时，macOS 可能只激活已有实例，不会自动替换成新二进制；应先从菜单里退出旧 Quota Bar，或用 Activity Monitor 结束旧进程，再打开最新 build。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260707-100236-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260707-100236-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> preferences里provider你直接漏了agy
>
> dropdown里直接没有claude
>
> 然后，preferences里增加日志，日志规则如下：
> 首先，我们的检查应该是从第一层到第四层，每一个 provider 单独顺序检查，provider 和 provider 之间并发检查。
> 如果现在不是这样，修改。
>
> 日志结构如下：
> `<yyyy.mm.dd_hh.mm.ss> - <IntendedProviderName>: <CheckStep>, <MethodName>: <Result>`
> 其中checkstep对应1～4层的check本身的名字，methodname对应方案名字，result如实返回即可
>
> 日志输出的顺序规范如下：
> 1. 同一个Intended Provider Name的内容总是连续输出
> 2. Check step 总是按实际执行顺序输出。
> 3. 同一个 check step 里面的 method name 总是按实际执行顺序连续输出。
> 4. 如果调用了缓存值，或者是缓存值无效，fallback 到默认顺序，result 里面应该明示；能够抓取到的信息、抓取成功与否、以及失败的理由，result 里面应该明示；
>
> 然后，dropdown里统一显示规则：
> （详见对话——名称栏 `<ProviderName> · <TierName>` 左对齐 + `<最后到期日> <货币符号><费用>/<周期>` 右对齐的完整 cascade 规则；额度栏 `<SegmentName>` + 进度条 + 剩余百分比，拿不到时蓝色「打开 WebView 授权」）

#### 完成工作

- `Preferences/ModelsSettingsView.swift`：`visibleProviders` 补 `.antigravity`。
- `RefreshCoordinator.swift`：`.available` 的 `keepAfterApply` 改为恒 true；`detectInstallReasons`/per-provider task 里接入 `ProviderCheckLog.flush(kind:)`。
- `ProviderFetchStrategy.swift`：`runSequential` 接入 `logSourceOrdering`/`logAttempt`。
- `InstallDetectorProvider.swift`：`detectSources` 四类探测逐项记录命中/未命中 + 缓存来源提示。
- `SubscriptionExpirySources.swift`：`resolve` 每个 source 尝试记录成功/失败。
- `ProviderCheckLog.swift`（新文件）：`ProviderCheckLog` actor + `ProviderCheckLogStore`。
- `Preferences/DiagnosticsSettingsView.swift`（新文件）+ `PreferencesSection.swift`/`PreferencesScene.swift`：新增「获取日志」页。
- `MenuView.swift`：`PlanHeader` 名称栏重写、新增 `QuotaAuthPromptRow`、`PlanSection` 额度栏分支重写。
- `QuotaModels.swift`：删除死代码 `ProviderSnapshot.displayName`。
- 测试：新增 `ProviderCheckLogTests.swift`（3 个用例：交错并发下按 provider 分组连续+内部顺序正确、空缓冲区不写入、行格式匹配正则）。
- 新包：`macos/build/20260707-100229-main/Quota Bar.app`（`build/latest` 已指向）。

#### 更新的需求 ID

- 新增并完成：`0.10.0-BUG-A-000`（agy 缺失）、`0.10.0-BUG-A-001`（Claude 消失架构 bug）、`0.10.0-ARCH-E-000`（ProviderCheckLog）、`0.10.0-ARCH-E-001`（确认现有并发架构已符合要求）、`0.10.0-ARCH-E-002`（三处埋点）、`0.10.0-PM-A-014`（获取日志页）、`0.10.0-UI-B-000`（名称栏重写）、`0.10.0-UI-B-001`（额度栏重写）、`0.10.0-CLEAN-A-000`（删除死代码）

#### 验证方式

- `swift build`：全程无警告无错误。
- `swift test`：176 tests in 41 suites 全部通过（新增 3 个 `ProviderCheckLogTests`）。
- `./scripts/build-app.sh`：产包成功，`build/latest` 已更新。
- 未做真实 GUI 交互验证（未启动打包后的 app 手动点开 dropdown/Preferences 截图核对），仅靠单元测试 + 代码走读确认逻辑正确；这是本次验证的已知局限，如实告知用户。

#### 备注

- 未提交 git commit。
- `ProviderCheckLogStore.append`/`clear` 从 `queue.async` 改成了 `queue.sync`：写测试时发现异步落盘会导致 `flush` 之后立刻 `readRecentLines()` 读不到数据（真实的竞态，不是测试脏），因为日志本身调用频率很低（每 provider 每刷新周期一次），改成同步换取"flush 完成即可读"的正确性是合理的取舍。
- Claude tier-only 幽灵 available 这个 bug 的教训：`.available` 状态原本被 UI 层隐含假设为"一定有额度"，加入 tier-only 兜底层（上一次会话新增的 `ClaudeAuthStatusCLIProvider`）之后这个假设不再成立，但当时没有同步检查 `RefreshCoordinator` 的过滤逻辑——这次是靠用户实测反馈才发现，说明"分层合并"类的架构改动需要连带检查所有下游对 availability 语义的隐含假设。

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
