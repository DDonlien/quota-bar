# 按已实现能力确定Provider授权补救层级

- ID：`0.10.0-ARCH-L-003`。
- 类型：`ARCH`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: dropdown「未获取到授权」误报 + 授权补救优先级规则重新定义。
- 原稳定 ID：`0.10.0-BUG-A-020`, `0.10.0-ARCH-L-003`, `0.10.0-INVESTIGATE-A-004`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.10.0-BUG-A-020`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.10.0-ARCH-L-003`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.10.0-BUG-A-020-ARCH-dropdown-rules-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：sub/main: dropdown「未获取到授权」误报 + 授权补救优先级规则重新定义。
- 同源任务：[纠正AntigravityHTTP500被误报为待配置](issue_%E7%BA%A0%E6%AD%A3AntigravityHTTP500%E8%A2%AB%E8%AF%AF%E6%8A%A5%E4%B8%BA%E5%BE%85%E9%85%8D%E7%BD%AE.md)、[隔离Provider抓取测试的日志文件](issue_%E9%9A%94%E7%A6%BBProvider%E6%8A%93%E5%8F%96%E6%B5%8B%E8%AF%95%E7%9A%84%E6%97%A5%E5%BF%97%E6%96%87%E4%BB%B6.md)。

## 当前需求与范围

共同范围与完整历史见[纠正AntigravityHTTP500被误报为待配置](issue_%E7%BA%A0%E6%AD%A3AntigravityHTTP500%E8%A2%AB%E8%AF%AF%E6%8A%A5%E4%B8%BA%E5%BE%85%E9%85%8D%E7%BD%AE.md)；本文件保留以下独立目标的原文。

- [x] [0.10.0-ARCH-L-003] 新增 `ProviderKind.availableAuthRemediationTiers`（`WebAuthorizationController.swift`）：按用户定的 FDA > WebView > API 优先级，只列出这个 provider 真正实现了的补救 tier（目前 FDA 未实现，永远为空）。`MenuView` 的 `.needsConfiguration` 分支和 `QuotaAuthPromptRow`（`.available` + 空 quotas 的兄弟状态，此前只判断 WebView、完全没考虑 API Key，MiniMax 落到这个分支时会静默漏掉 API 引导）统一改用这个属性做展示决策：列表第一项是 `.webView` → 「打开 WebView 授权」按钮；`.apiKey` → 「在 Preferences 中通过 API Key 授权」；列表为空 → 不再展示任何"去授权"文案，改成跟 opencode 现有展示一致的诚实文案"暂无额度数据"。同时修正了此前 `.needsConfiguration` 分支里 API 判断排在 WebView 判断前面的顺序（跟用户"WebView 优先于 API"的规则相反，之前会让 MiniMax 一律先展示 API 引导、永远不会展示 WebView 授权按钮）#P0 — 范围说明：只实现了"按优先级展示第一个可用 tier"，没有实现"如果优先级更高的 tier 已确认完成授权但仍无额度，就自动升级展示下一个 tier"这层更细的判断（那需要单独建模"每个 tier 是否已完成授权"的状态，`QuotaFetchError`/`ProviderAvailability` 目前还没有这个维度），先按优先级固定展示第一个 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

原迁移条目的历史Comments完整保留于[同源历史](issue_%E7%BA%A0%E6%AD%A3AntigravityHTTP500%E8%A2%AB%E8%AF%AF%E6%8A%A5%E4%B8%BA%E5%BE%85%E9%85%8D%E7%BD%AE.md#comments)，不从历史日志新增完成标记。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
