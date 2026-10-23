# sub/main: opencode 探测 + 已配置态接入

- ID：`0.13.0-DATA-A-000`。
- 类型：`DATA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.13.0 - opencode Provider 支持（探测 + 诚实的"已配置"态） / sub/main: opencode 探测 + 已配置态接入。
- 原稳定 ID：`0.13.0-DATA-A-000`, `0.13.0-DATA-A-001`, `0.13.0-ARCH-A-000`, `0.13.0-FE-A-000`, `0.13.0-QA-A-000`, `0.13.0-QA-A-001`, `0.13.0-DOC-A-000`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.13.0-DATA-A-000] 在 `ProviderKind` enum 新增 `.opencode` 枚举值：`displayName = "opencode"`、`brandColor = #03B000`（取自 opencode.ai 官网配色）、`iconSymbol = "chevron.left.forwardslash.chevron.right"`、`cliCommands = ["opencode"]`、`credentialFiles = ["~/.local/share/opencode/auth.json"]`，无 `bundleIdentifier`（纯 CLI 工具）、无 `envVarNames`（BYOK 无单一规范环境变量）、无 `cookieDomains`（不采用浏览器方案）
- [x] [0.13.0-DATA-A-001] `OpenCodeAuthProvider` 实现：解析 `~/.local/share/opencode/auth.json`（支持 `XDG_DATA_HOME` 覆盖路径），按 provider id 罗列已配置的下游 provider；命中 `opencode-go` / `opencode` 时档位标签显示 `Go` / `Zen`，否则显示通用 `BYOK`；找不到凭证时报 `missingCredentials` → pipeline 兜底 `.needsConfiguration`
- [x] [0.13.0-ARCH-A-000] `Strategies.opencodePipeline()` 接入 `supportedProviderKinds` + `makePipelines()`，只有 `OpenCodeAuthProvider` 一层（无 fallback 层，明确不引入浏览器 cookie 方案）
- [x] [0.13.0-FE-A-000] `Preferences → 模型` 页 `ModelsSettingsView.visibleProviders` 同步加入 `.opencode`（避免重演 GLM/`.zcode` 那种"幽灵 kind 对不上真实 pipeline"的开关错位 bug），`providerVendor` / `providerAccessModes` 补齐 opencode 分支
- [x] [0.13.0-QA-A-000] 单元测试 `OpenCodeAuthProviderTests`：多 provider 解析、tier 优先级（Go > Zen > BYOK）、有凭证时返回 available + 空 quotas、无凭证时 missingCredentials
- [x] [0.13.0-QA-A-001] `swift build` + `swift test`（185 个测试全过，含新增 4 个）；并用本机真实 `~/.local/share/opencode/auth.json`（已配置 `opencode-go`）实测 `swift run` 全链路：探测成功 → 档位=Go、价格=未获取 → 诊断日志确认无额度层伪造
- [x] [0.13.0-DOC-A-000] `README.md`「支持的 Provider」加入 opencode，并补充独立说明段落解释为什么它不进四层获取矩阵

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260708-094500-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260708-094500-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 增加对opencode的支持，注意标准化实现（分层）最小化影响（其他的agent还在改别的东西）

#### 完成工作

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

#### 更新的需求 ID

- `[0.13.0-DATA-A-000]`、`[0.13.0-DATA-A-001]`、`[0.13.0-ARCH-A-000]`、`[0.13.0-FE-A-000]`、`[0.13.0-QA-A-000]`、`[0.13.0-QA-A-001]`、`[0.13.0-DOC-A-000]`（全部 v0.13.0，全部已勾选完成）

#### 验证方式

- `cd macos && swift build`：通过。
- `cd macos && swift test`：185/185 通过（含新增 4 个）。
- `swift run` 全量启动 app，用本机真实 `~/.local/share/opencode/auth.json`（已配置 opencode-go）跑一次完整刷新周期，核对 `~/Library/Application Support/QuotaBar/provider-check.log` 确认探测、档位获取均按预期成功且未伪造额度；验证后 kill 掉本次调试进程，未影响用户机器上原本在跑的正式 app 实例。

#### 备注

- 未引入浏览器 Cookie 抓取 opencode Go 私有 dashboard 的方案（用户在实现深度确认时明确选择了这条边界）；如果后续 opencode 官方推出稳定的额度/信用 API，可以在 `OpenCodeAuthProvider` 之后补一层真正的额度获取策略，不影响当前已落地的探测层。
- 调研过程中 clone 了 `github.com/opgginc/opencode-bar`（同类开源项目）到本地 scratchpad 只读参考，核实完 opencode 的 `auth.json` 真实字段结构（`opencode`/`opencode-go`/`anthropic` 等顶层 key，`key`/`access`/`token` 等凭证字段名）后已删除该 clone，未引入任何第三方代码或依赖。
