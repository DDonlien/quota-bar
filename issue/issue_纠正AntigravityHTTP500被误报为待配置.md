---
title: 纠正AntigravityHTTP500被误报为待配置
id: 0.10.0-BUG-A-020
type: ARCH
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: dropdown「未获取到授权」误报 + 授权补救优先级规则重新定义。'
原稳定 ID: '`0.10.0-BUG-A-020`, `0.10.0-ARCH-L-003`, `0.10.0-INVESTIGATE-A-004`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.10.0-BUG-A-020`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.10.0-BUG-A-020`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.10.0-BUG-A-020-ARCH-dropdown-rules-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'sub/main: dropdown「未获取到授权」误报 + 授权补救优先级规则重新定义。'
同源任务: '[按已实现能力确定Provider授权补救层级](issue_%E6%8C%89%E5%B7%B2%E5%AE%9E%E7%8E%B0%E8%83%BD%E5%8A%9B%E7%A1%AE%E5%AE%9AProvider%E6%8E%88%E6%9D%83%E8%A1%A5%E6%95%91%E5%B1%82%E7%BA%A7.md)、[隔离Provider抓取测试的日志文件](issue_%E9%9A%94%E7%A6%BBProvider%E6%8A%93%E5%8F%96%E6%B5%8B%E8%AF%95%E7%9A%84%E6%97%A5%E5%BF%97%E6%96%87%E4%BB%B6.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> 用户看到 Antigravity 订阅到期当天，dropdown 显示"未获取到授权"，指出这不合理——Antigravity 明明是"没有额度"（订阅过期），而不是"没有登录"，且质问"同样的代码，昨天还能获取到授权"。借这个具体案例，用户完整定义了一套新的 dropdown 额度提示规则：(1) 任何途径获得额度就如实显示；(1.1) 非授权途径明确判定"已过期/未订阅"时展示对应定论文案（`.subscriptionExpired`/`.notSubscribed`，MiniMax 现状正确）；(2) 所有非授权途径都试过仍无额度时，才展示授权途径引导，且按 FDA（未实现不展示）> WebView > API 的优先级展示第一个这个 provider 真正支持的补救入口；(3) 只有当所有该 provider 支持的授权途径都已确认完成授权但仍无额度时，才展示"没有额度信息"这类终态文案。

- [x] [0.10.0-BUG-A-020] 定位 Antigravity 具体误报根因：`antigravity-cli`/`antigravity-cli-session` 返回的 HTTP 500（`GetCascadeModelConfigData() is nil`）在 `AntigravityDashboardProvider` 里映射成 `QuotaFetchError.transient`（模糊错误，不是明确的"订阅已过期"信号，不满足用户规则 1.1 的"额度信息明确已过期"标准），`RefreshCoordinator.availabilityFallback` 对 `.transient` + 已检测到 App 安装的情况统一映射成 `.needsConfiguration`；而 `MenuView` 的 `.needsConfiguration` 分支此前对"两种授权能力都不支持"的 provider 一律展示"未获取到授权"——但 Antigravity 既不是 `webViewQuotaCapableKinds`（登录窗口只服务到期日抓取，不产出额度，见 `webViewQuotaCapableKinds` 顶部说明）也不是 `apiKeyCapableKinds`，也没有 FDA，对这个 provider 来说根本不存在任何授权补救动作可以提示用户去做——"未获取到授权"是个兑现不了的承诺 #P0

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260708-121652-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260708-121652-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

>（截图：dropdown，Antigravity 显示"未获取到授权"）
>
> 然后记住，除非我特别要求，否则总是用中文回答我。
>
> 另外，你自己看一下日志，现在 Antigravity 怎么可能是"未获取到授权"呢？
>
> 我现在应该是没有额度，因为我的订阅在今天已经过期了。但它不应该是"未获取到授权"，因为 literally 同样的代码，昨天你还能获取到授权。
>
> 检查一下是哪里出错了。
>
> dropdown的额度提示信息还是错误的，我给你完整整理一遍。
>
> 1. 任何途径获得了额度，就如实显示额度。
> 1.1. 如果非授权途径能获得额度信息，并且额度信息是明确的已经过期，那就显示未订阅或已过期，这个是可接受的，比如你现在的 MiniMax
>
> 2. 如果所有非授权途径（也就是除去 WebView 和 API，包括未来如果我们要做 FDA 或者 Cookie）都已经尝试了，但依然没有获取到额度，那就显示授权途径的提示。
>
> 授权途径的提示按照如下顺序优先展示：
> • 优先是 FDA（因为它是伤害性最小且一次性的）
> • 其次是 WebView
> • 其次是 API
>
> 当然，如果我们现在实际上没有 FDA，就不显示 FDA。
>
> 如果上一个授权形式完成了授权，但没有获取到额度，就提示下一个。
>
> 只有上述途径全都授权完了，才显示"未获取到授权"。也就是说，只有所有的途径都尝试完了，并且授权都是成功的（比如能得到确认的成功反馈，但就是没有额度），才能确定这个模型是不返回额度的，此时显示"没有额度信息"。
>
> 按照这个规则，首先我没有尝试 API，你就不应该 Antigravity 显示"未获取到授权"，我 code 也不应该显示"没有额度信息"。

#### 完成工作

- `WebAuthorizationController.swift`：新增 `ProviderKind.AuthRemediationTier`（`.webView`/`.apiKey`，FDA 未实现不建模）和 `availableAuthRemediationTiers` 计算属性，按 FDA > WebView > API 优先级排好序，只包含这个 provider 真正支持的 tier。
- `MenuView.swift`：
  - `.needsConfiguration` 分支改用 `availableAuthRemediationTiers.first` 做 switch：`.webView` → 「打开 WebView 授权」按钮；`.apiKey` → 灰字指向 Preferences；`nil`（一个 tier 都不支持）→ 「暂无额度数据」（不再是「未获取到授权」）。
  - `QuotaAuthPromptRow` 同步改成同一套 `availableAuthRemediationTiers` 判断（之前只判断 WebView，现在也会展示 API Key 引导），保证同一个 provider 不会因为落在 `.available`+空 quotas 还是 `.needsConfiguration` 两个不同 availability 分支而展示不一致的文案。
- `REQUIREMENTS.md`：新增 `[0.10.0-BUG-A-020]`（Antigravity 误报根因）、`[0.10.0-ARCH-L-003]`（`availableAuthRemediationTiers` + 两处调用点统一）、`[0.10.0-INVESTIGATE-A-004]`（顺手发现的测试污染真实日志文件问题，已用 `spawn_task` 单独派发，不在本轮修复）。
- 用 `spawn_task` 派发了一个独立后台任务（`task_9a5b6e04`）：`swift test` 时 `ProviderFetchStrategyTests.swift` 的 stub（"quota-source"/"plan-filler"）没有给 `ProviderCheckLog` 注入独立临时文件，写穿了真实用户机器的 `provider-check.log`——排查 Antigravity 问题时在真实日志里翻到了这两条测试噪音数据，跟当前任务无关，先记下来单独处理。

新包：`macos/build/20260708-121652-main/Quota Bar.app`（`build/latest` 已指向）。

#### 更新的需求 ID

- `[0.10.0-BUG-A-020]` `[0.10.0-ARCH-L-003]` `[0.10.0-INVESTIGATE-A-004]`

#### 验证方式

- `swift build`：无警告无错误。
- `swift test`：186 tests in 42 suites 全部通过（本轮未新增/删除测试——纯 UI 文案/优先级判断改动，行为需要用户在真实环境里用刚才打的包重新验证 Antigravity 的展示是否变成"暂无额度数据"）。
- `./scripts/build-app.sh`：产包成功。

#### 备注

- 未提交 git commit。
- 范围说明：本轮只实现了"按 FDA > WebView > API 优先级展示第一个这个 provider 真正支持的 tier"，没有实现用户规则里更细的一层——"如果优先级更高的 tier（比如 WebView）已经确认完成授权，但还是拿不到额度，就自动展示下一个 tier（比如 API）的引导"。这需要单独追踪"每个 tier 是否已经完成授权"的状态（目前 `QuotaFetchError`/`ProviderAvailability` 的错误分类还没有为此建模——`missingCredentials` vs `transient` 已经能区分"没登录"和"登录了但请求失败"，但还没有把这个信号一路传到 UI 层做 tier 升级判断），如果用户之后遇到"WebView 明明登录了但还是没有 API 引导"这类情况，需要再单独扩展。
- 已知这次没处理的具体点：MiniMax 目前是唯一同时具备 WebView 和 API 两个 tier 的 provider，这次改动让它在 `.needsConfiguration`/空 quotas 分支下默认优先展示 WebView 引导（而不是像之前一样固定展示 API 引导）——如果用户实际使用习惯是"更喜欢直接填 API Key，不想开 WebView 登录"，可能需要反馈调整（但这是用户本轮明确给出的优先级规则，按规则实现的默认行为）。

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
