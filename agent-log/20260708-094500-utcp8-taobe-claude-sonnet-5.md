# 用户原始 prompt

> 增加对opencode的支持，注意标准化实现（分层）最小化影响（其他的agent还在改别的东西）

# 启动运行时的分支和版本

- 分支：`claude/elastic-burnell-98d339`（worktree，非 `main`）
- 版本：`19e5e34 Unify versioning and update-checker to semver-only`（`VERSION` = 0.10.0）

# 任务开始时间

2026-07-08 09:20 +0800

# 任务结束时间

2026-07-08 09:45 +0800

# 任务结束时是否执行了提交

否——按惯例留给用户确认后再决定是否提交/推送。

# 已阅读上下文

- `AGENTS.md`（协作规范、Provider 接入流程惯例、REQUIREMENTS/README/DESIGN 维护纪律）。
- `macos/Sources/QuotaBar/QuotaModels.swift`（`ProviderKind` 枚举与元数据结构）、`Strategies.swift`（pipeline 工厂、`supportedProviderKinds`）、`InstallDetectorProvider.swift`、`RefreshCoordinator.swift`（探测/刷新/持久化流程）、`ClaudeAuthStatusCLIProvider.swift`（tier-only fallback 先例）、`ZCodeAuthProvider.swift`（config 文件解析先例）、`Preferences/ModelsSettingsView.swift`（"幽灵 kind" 教训注释）。
- 调研 opencode 官方文档（`opencode.ai/docs/zen`、`opencode.ai/docs/config`）、`opgginc/opencode-bar`（GitHub 上已实现的同类 macOS 菜单栏 App，clone 到 scratchpad 只读参考其 `OpenCodeProvider` / `OpenCodeZenProvider` / `OpenCodeGoProvider` / `TokenManager` 源码，核实完後已删除本地 clone，未引入任何依赖或代码复制）。

# 对话与行动记录

用户要求"增加对 opencode 的支持"，并特别强调"标准化实现（分层）"和"最小化影响（其他 agent 还在改别的东西）"。先通读现有 Provider 分层架构（`ProviderKind` 元数据层 → `InstallDetectorProvider` 探测层 → `FetchPipeline`/`Strategies` 数据层 → `RefreshCoordinator` 合并/持久化层 → `ModelsSettingsView`/`MenuView` 展示层），确认新增 Provider 的标准路径。

调研 opencode 本身的数据来源发现它是 BYOK 聚合 CLI，没有稳定的额度百分比接口：
- Zen（其自家 pay-as-you-go 网关）的 credits API 会返回 `Not Found`（`opgginc/opencode-bar` 的 `OpenCodeProvider.swift` 明确按 404/"Not Found" 特殊处理，说明这条路线不稳定）；
- Go（其自家订阅）有真实的 5h/周/月用量百分比，但只能靠抓一个未公开的私有 dashboard 网页（`opencode.ai/workspace/<id>/go`）+ 浏览器 auth cookie 才能拿到，没有官方文档，React server component 的 payload 结构随时可能变。

因此在动手写代码前，用 `AskUserQuestion` 向用户确认实现深度（仅探测+诚实"已配置"态 / 再加本地 CLI 的 PAYG 花费展示 / 再加 Go 订阅的私有 dashboard 抓取），用户选择了第一种（探测 + 诚实"已配置"态，不引入浏览器 cookie 抓取未公开页面的方案）。

据此实现标准分层接入：

1. **元数据层**（`QuotaModels.swift`）：`ProviderKind` 新增 `.opencode`，补齐 `displayName`/`brandColor`（`#03B000`，取自 opencode.ai 官网 CSS 里唯一的高饱和度强调色）/`iconSymbol`/`cliCommands`/`credentialFiles`，`cookieDomains`/`envVarNames`/`bundleIdentifier` 均保持空（纯 CLI、BYOK 无单一规范环境变量、无桌面 App）。
2. **探测层**：`credentialFiles`/`cliCommands` 元数据是 `InstallDetectorProvider` 的唯一输入，新增枚举值后自动获得探测能力，无需改动 `InstallDetectorProvider.swift` 本身；额外给 `AgentDetector.swift`（legacy、当前未接入 UI 但仍在编译）的 `checkCLIAuthenticated` 补了 `.opencode` 分支，避免它落到 `default: return true` 的错误兜底。
3. **数据层**（新文件 `OpenCodeAuthProvider.swift`）：解析 `~/.local/share/opencode/auth.json`（支持 `XDG_DATA_HOME` 覆盖），按 provider id 判断已配置了哪些下游 provider；命中 `opencode-go`/`opencode` 时档位显示 `Go`/`Zen`，否则 `BYOK`；quotas 留空，对齐 `ClaudeAuthStatusCLIProvider` 的 tier-only fallback 先例（不伪造额度百分比）。
4. **Pipeline 接入**（`Strategies.swift`）：新增 `opencodePipeline()`（只有 `OpenCodeAuthProvider` 一层，无 fallback），接入 `supportedProviderKinds` 和 `makePipelines()`。
5. **展示层**（`ModelsSettingsView.swift`）：`visibleProviders` 加入 `.opencode`，`providerVendor`/`providerAccessModes` 补齐分支——特别注意到这个文件里有一段注释记录了之前 `.glm` vs `.zcode` "幽灵 kind" 的教训（Preferences 页手写的 `visibleProviders` 列表如果不跟 `Strategies.supportedProviderKinds` 保持一致，会导致开关和真实 pipeline 对不上），照此教训同步更新。

验证：
- `swift build` 全量通过；过程中发现另外两处硬编码的 `ProviderKind` 穷尽 switch（`StatusBarController.brandNSColor`、`ModelsSettingsView.providerVendor`/`providerAccessModes`）编译报错缺分支，逐一补齐。
- `swift test` 185 个测试全过（181 原有 + 新增 4 个 `OpenCodeAuthProviderTests`：多 provider 解析、tier 优先级、有凭证 available、无凭证 missingCredentials）。
- 端到端验证：本机恰好已安装并使用过 opencode（`~/.local/share/opencode/auth.json` 里配置了 `opencode-go`），`swift run` 启动完整 app 后，`provider-check.log` 显示 `opencode | 档位与费用获取 | 成功 | 来源 opencode-auth：档位=Go，价格=未获取`，额度层如实标注"未获取到额度窗口"（不是错误，是诚实的空态）；核对后确认这条不进 `snapshots.json` 磁盘缓存是 `RefreshCoordinator.updateSnapshotCache` 里"空 quotas 不落盘"的既有通用规则（`quota=Claude tier-only` fallback 也是同样行为），不是新引入的问题。验证完成后 kill 掉本次临时启动的调试进程，未影响用户机器上已经在跑的正式 app 实例。

# 完成工作

- `macos/Sources/QuotaBar/QuotaModels.swift`：`ProviderKind` 新增 `.opencode` 及全部元数据分支。
- `macos/Sources/QuotaBar/OpenCodeAuthProvider.swift`（新文件）：opencode `auth.json` 解析 + tier-only 快照。
- `macos/Sources/QuotaBar/Strategies.swift`：`opencodePipeline()` + 接入 `supportedProviderKinds`/`makePipelines()`。
- `macos/Sources/QuotaBar/Preferences/ModelsSettingsView.swift`：`visibleProviders`/`providerVendor`/`providerAccessModes` 补齐 opencode。
- `macos/Sources/QuotaBar/AgentDetector.swift`：`checkCLIAuthenticated` 补 `.opencode` 分支。
- `macos/Sources/QuotaBar/StatusBarController.swift`：`brandNSColor` 补 `.opencode` 分支（构建期间发现的穷尽 switch 遗漏，一并修）。
- `macos/Tests/QuotaBarTests/OpenCodeAuthProviderTests.swift`（新文件）：4 个单元测试。
- `README.md`：「支持的 Provider」列表加入 opencode；四层获取矩阵后新增独立说明段落解释为什么 opencode 不进矩阵；「跑起来」引导文案同步。
- `REQUIREMENTS.md`：新增 `## Phase - v0.13.0 - opencode Provider 支持`，任务全部勾选完成，并注明本 phase 暂不 bump `VERSION`（详见下方说明）。
- **未 bump `VERSION` 文件**：v0.11.0/v0.12.0（自动更新 + Developer ID 签名）已在 REQUIREMENTS.md 规划但尚未全部完成，可能有其他 agent 正在推进；`VERSION` 目前是 0.10.0，落后于这两个已规划未完成的 phase。现在直接 bump 到 0.13.0 会造成版本语义混乱（暗示 0.11/0.12 已完成）且可能与并发 agent 的工作冲突，因此按用户"最小化影响"的要求，把 `VERSION` 的实际 bump 时机留给后续统一处理。

# 更新的需求 ID

- `[0.13.0-DATA-A-000]`、`[0.13.0-DATA-A-001]`、`[0.13.0-ARCH-A-000]`、`[0.13.0-FE-A-000]`、`[0.13.0-QA-A-000]`、`[0.13.0-QA-A-001]`、`[0.13.0-DOC-A-000]`（全部 v0.13.0，全部已勾选完成）

# 更新的 README 或 DESIGN 章节

- `README.md`：「支持的 Provider」、「四层获取矩阵」后的 opencode 独立说明段、「跑起来」引导。
- `DESIGN.md`：未改动——`DESIGN.md` 不追踪具体 Provider 品牌色（zcode 品牌色的类似追踪在 `site/DESIGN.md`，属于营销站子项目，本次未涉及 site，未改动）。

# 验证方式

- `cd macos && swift build`：通过。
- `cd macos && swift test`：185/185 通过（含新增 4 个）。
- `swift run` 全量启动 app，用本机真实 `~/.local/share/opencode/auth.json`（已配置 opencode-go）跑一次完整刷新周期，核对 `~/Library/Application Support/QuotaBar/provider-check.log` 确认探测、档位获取均按预期成功且未伪造额度；验证后 kill 掉本次调试进程，未影响用户机器上原本在跑的正式 app 实例。

# 备注

- 未引入浏览器 Cookie 抓取 opencode Go 私有 dashboard 的方案（用户在实现深度确认时明确选择了这条边界）；如果后续 opencode 官方推出稳定的额度/信用 API，可以在 `OpenCodeAuthProvider` 之后补一层真正的额度获取策略，不影响当前已落地的探测层。
- 调研过程中 clone 了 `github.com/opgginc/opencode-bar`（同类开源项目）到本地 scratchpad 只读参考，核实完 opencode 的 `auth.json` 真实字段结构（`opencode`/`opencode-go`/`anthropic` 等顶层 key，`key`/`access`/`token` 等凭证字段名）后已删除该 clone，未引入任何第三方代码或依赖。
