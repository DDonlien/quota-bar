# 建立独立计费订阅组及排序语义

- ID：`0.3.0-DATA-A-000`。
- 类型：`DATA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.3.0 - UI 拖拽、订阅组语义与 dropdown 实时刷新 / sub/main: 建立订阅组语义。
- 原稳定 ID：`0.3.0-DATA-A-000`, `0.3.0-DATA-A-001`, `0.3.0-DATA-A-002`, `String`, `0.3.0-DATA-A-003`, `0.3.0-DATA-A-004`, `0.3.0-DATA-A-005`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.3.0-DATA-A-000`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.3.0-DATA-A-000`、`0.3.0-DATA-A-001`、`0.3.0-DATA-A-002`、`0.3.0-DATA-A-003`、`0.3.0-DATA-A-004`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.3.0-DATA-A-000-DATA-subscription-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：sub/main: 建立订阅组语义。
- 同源任务：[恢复KimiWork已验证的浏览器额度路径](issue_%E6%81%A2%E5%A4%8DKimiWork%E5%B7%B2%E9%AA%8C%E8%AF%81%E7%9A%84%E6%B5%8F%E8%A7%88%E5%99%A8%E9%A2%9D%E5%BA%A6%E8%B7%AF%E5%BE%84.md)。

## 当前需求与范围

- [x] [0.3.0-DATA-A-000] `QuotaWindow` 增加 `subscriptionGroup` 字段，语义为「独立计费的订阅组」；fallback 到 `providerKind.rawValue`（未显式设的 parser 视为整个 provider = 1 个订阅组）#P1 — `QuotaModels.swift:subscriptionGroup`
- [x] [0.3.0-DATA-A-001] 所有 parser 显式设 subscriptionGroup：Codex=`"codex"`、Kimi=`"kimi"`（含 web + CLI 两条路径）、MiniMax CLI 按 `modelName.lowercased()`、Antigravity 主路径按 `group.displayName` / fallback 路径固定 `"Gemini"` + `"Other"` #P1
- [x] [0.3.0-DATA-A-002] `PreferencesStore.QuotaPreferences` 新增 `subscriptionGroupOrder: [String: [String]]` 字段（key = `providerKind.rawValue`），Codable 向后兼容（旧配置自动获得 `[:]`）#P1
- [x] [0.3.0-DATA-A-003] `ProviderSnapshot` 新增 `subscriptionGroups(customOrder:)` 与 `primarySubscriptionGroupWorstQuota(itemOrder:)` 两个方法：前者按订阅组分组（组顺序继承用户排序），后者取排序后第一个订阅组的 worst quota #P1
- [x] [0.3.0-DATA-A-004] 修正 `subscriptionGroups(customOrder:)` 的排序语义：`customOrder` 必须按订阅组 key 排序而不是 quota stableKey；Kimi Work / Code 无论来源如何都强制归为 `kimi` 单订阅组 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260706-175720-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260706-175720-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> agy是用agy指令进入cli，然后/usage就能看到额度
> reademe里有很多细节错误，我怀疑也是实现错误：codex的provider有两个p2；glm有两个p2两个p3（同一类里不同的.json文件视作类似cli两个指令一样，同样优先级）其他的还有很多我不一一例举了
> 每次改完打包到build，规则你自己看下

（截图显示：`agy` 进入交互 CLI 后 `/usage View model quota usage` 是内建 slash command）

后续补充：

> 继续任务，然后：
>
> claude没获取到额度，看看为什么，也可以参考其他类似app的实现：
> /Users/taobe/Projects/GitHub/Reference/CodexBar
> /Users/taobe/Projects/GitHub/Reference/ClaudeBar
> /Users/taobe/Projects/GitHub/Reference/Claude-Usage-Tracker

#### 完成工作

- `DashboardEndpoints.swift`：`ClaudeDashboardParser` 改为直接解析真实字段（Session/Weekly/Weekly (Sonnet|Opus) 三个窗口），保留旧 flatten 逻辑作 schema 变化时的防御性 fallback；`usageURL` 加多 org 优先级选择。
- `AntigravityCLISessionProvider.swift`：新文件，PTY 会话管理抽成可注入的 `SessionLauncher`/`ManagedSession`（不依赖真实 agy 二进制即可单测）。
- `QuotaModels.swift` / `InstallDetectorProvider.swift`：CLI 命令探测改候选列表 + 补目录直查。
- `README.md`：四张矩阵表全部重写，新增五级来源排序说明段落（上一会话）+ 本轮的同格同优先级规则落实。
- 新包：`macos/build/20260706-175720-main/Quota Bar.app`（`build/latest` 已指向）。

#### 更新的需求 ID

- 新增并完成：`0.10.0-DATA-B-006`（AGY CLI session provider）、`0.10.0-DATA-B-007`（Claude parser 真实形状修复）、`0.10.0-DATA-B-008`（CLI 候选命令名 + 目录直查）、`0.10.0-DOC-A-001`（README 矩阵审计重写）

#### 验证方式

- `make test`：145 tests in 33 suites 全部通过。新增：`ClaudeDashboardParserTests`（真实形状解析、sonnet 优先 opus、org 选择优先级、wrapper 兼容）、`AntigravityCLISessionProviderTests`（二进制缺失、重试到成功、会话提前退出、超时放弃，全部通过依赖注入不碰真实进程）。
- `make app`：成功产包。
- 手动实测（只读、无副作用）：`agy --print "/usage"` 确认会被当 prompt 消耗（已排除该路径）；`/usr/bin/script -q /dev/null agy` 拉起后 `lsof` 确认本地端口出现，随后正确清理进程。

#### 备注

- 未提交 git commit；三次会话（弹窗/Kimi/到期日/更新、webview 桥/AGY/偏好设置/矩阵初稿、AGY CLI/Claude 修复/矩阵重写）的改动都在同一工作区。
- Claude 修复是本次最有把握的一处——三个独立参考实现（CodexBar、Claude-Usage-Tracker，以及 ClaudeBar 反向确认它们不走 web API）交叉验证了响应形状，不是猜测。
- AGY CLI session provider 的真实端到端（拉起 agy 交互会话、走完整 pipeline 拿到额度）还没有跑过，只验证了「PTY 拉起后端口出现」这一个环节；建议用户装包后实测一次待 IDE/agy 会话都不在跑的情况。
- README 矩阵仍有多处「待验证」标记（Claude CLI 额度命令、GLM 若干字段等）——如实标注未验证，不是遗漏。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
