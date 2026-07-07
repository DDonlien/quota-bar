# 用户原始 prompt

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

# 启动运行时的分支和版本

- 分支：`main`
- 版本：`1bba4e3` + 前两次会话（20260705-215117、20260706-093058）未提交改动

# 任务开始时间

2026-07-06 约 17:00 +0800

# 任务结束时间

2026-07-06 17:57 +0800

# 任务结束时是否执行了提交

未提交（三次会话改动累积在工作区，等用户 review）。

# 已阅读上下文

- `InstallDetectorProvider.swift`、`QuotaModels.swift`（cliCommand/credentialFiles 元数据）
- `AntigravityDashboardProvider.swift`（processMode 设计、进程/端口发现）
- 实测：`agy --print "/usage"` 被当自然语言 prompt 消耗（模型回复"我没有 /usage 内建命令"），确认不能驱动 print 模式；`/usr/bin/script -q /dev/null agy` 拉起后 `lsof` 确认本地监听端口出现
- CodexBar 全套 Claude 实现：`ClaudeWebAPIFetcher.swift`（1274 行）、`ClaudeCredentialRouting.swift`、`ClaudeUsageProbe.swift`（ClaudeBar，用 SwiftTerm 驱动 PTY + `/usage` TUI）
- Claude-Usage-Tracker 的 `ClaudeAPIService.swift` / `AutoStartSessionService.swift`（与 CodexBar 交叉验证同一响应形状）

# 对话与行动记录

## 1. README 矩阵优先级审计 + 重写

规则：同列内每个手段唯一优先级；同一格里多个文件/命令视为同类，共享该格优先级、命中即止（呼应用户「不同 .json 文件同样优先级」的说法）。全部四张表按此规则 + 当前实现重写，包括：
- Provider 获取表改为反映 `InstallDetectorProvider.prioritize` 的实际统一顺序（凭证文件 → App Bundle → CLI → 环境变量）；
- 额度表行序即五级来源排序，新增「App WebView 会话」独立行；
- 过期日/档位表逐格核对当前代码（Kimi GetSubscription、MiniMax mmx 已验证、Codex accounts/check P1 等）。

## 2. AGY 真实 CLI 层

用户截图 + 描述确认：`agy` 是交互式 CLI，`/usage` 是其内建 slash command（非 print 模式可用）。设计：`AntigravityCLISessionProvider` 用 `/usr/bin/script` 给 agy 一个 PTY（无 TTY 会拒绝启动交互会话），拉起后不解析 TUI 文本，而是委托 `AntigravityDashboardProvider(.cli)` 复用其已验证的本地 RPC 解析逻辑；轮询等 RPC 就绪，成功/超时后立即终止会话。接入管线排在已运行 agy/language_server 进程之后、keychain 之前。

顺带发现并修：`ProviderKind.cliCommand` 硬编码的命令名是错的（`minimax`/`antigravity`），实际是 `mmx`/`agy`；改为 `cliCommands: [String]` 候选列表（同类同优先级，命中即止）；`InstallDetectorProvider.findCommand` 补 Homebrew / `~/.local/bin` 等候选目录直查（launchd PATH 不含这些路径，纯 `which` 会探测失败）。

## 3. Claude 额度失败根因调查

参考三个仓库交叉验证：CodexBar `ClaudeWebAPIFetcher.swift` 与 Claude-Usage-Tracker `ClaudeAPIService.swift` 独立确认 `organizations/{orgId}/usage` 的真实响应形状是**顶层固定字段** `five_hour` / `seven_day` / `seven_day_sonnet` / `seven_day_opus`（各自 `{"utilization": 0-100, "resets_at": ISO8601}`），完全不在任何 `usage`/`limits`/`quota` wrapper 下。

对照我们的 `ClaudeDashboardParser.flattenUsageCandidates`：只认那几个 wrapper key 下的**数组**，five_hour 等是单个 dict 不是数组，递归 fallback（`dict.values.flatMap`）对非 dict/array 叶子值直接返回空——**对真实响应恒等于空数组**。这是 Claude 从一开始就没额度的根因，跟 webview 授权/弹窗无关，是 parser 写错了 JSON 形状。

顺带发现：`usageURL(from:)` 原实现选「第一个有 uuid 的 org」，多 org 账号（团队/企业）可能选中纯 API 计费 org 导致 usage 端点返回空。参考 CodexBar 的选择逻辑（优先 chat 能力 > 非 api-only > 第一个）补上。

ClaudeBar（第三个参考）用完全不同的路径：`SwiftTerm` 渲染 `claude` CLI 的 `/usage` TUI 输出——比 webview 更重，本次未采用（我们已有更轻的 webview 会话桥）。

# 完成工作

- `DashboardEndpoints.swift`：`ClaudeDashboardParser` 改为直接解析真实字段（Session/Weekly/Weekly (Sonnet|Opus) 三个窗口），保留旧 flatten 逻辑作 schema 变化时的防御性 fallback；`usageURL` 加多 org 优先级选择。
- `AntigravityCLISessionProvider.swift`：新文件，PTY 会话管理抽成可注入的 `SessionLauncher`/`ManagedSession`（不依赖真实 agy 二进制即可单测）。
- `QuotaModels.swift` / `InstallDetectorProvider.swift`：CLI 命令探测改候选列表 + 补目录直查。
- `README.md`：四张矩阵表全部重写，新增五级来源排序说明段落（上一会话）+ 本轮的同格同优先级规则落实。
- 新包：`macos/build/20260706-175720-main/Quota Bar.app`（`build/latest` 已指向）。

# 更新的需求 ID

- 新增并完成：`0.10.0-DATA-B-006`（AGY CLI session provider）、`0.10.0-DATA-B-007`（Claude parser 真实形状修复）、`0.10.0-DATA-B-008`（CLI 候选命令名 + 目录直查）、`0.10.0-DOC-A-001`（README 矩阵审计重写）

# 更新的 README 或 DESIGN 章节

- `README.md`：四张获取矩阵表全部重写（Provider/额度/过期日/档位与费用）。

# 验证方式

- `make test`：145 tests in 33 suites 全部通过。新增：`ClaudeDashboardParserTests`（真实形状解析、sonnet 优先 opus、org 选择优先级、wrapper 兼容）、`AntigravityCLISessionProviderTests`（二进制缺失、重试到成功、会话提前退出、超时放弃，全部通过依赖注入不碰真实进程）。
- `make app`：成功产包。
- 手动实测（只读、无副作用）：`agy --print "/usage"` 确认会被当 prompt 消耗（已排除该路径）；`/usr/bin/script -q /dev/null agy` 拉起后 `lsof` 确认本地端口出现，随后正确清理进程。

# 备注

- 未提交 git commit；三次会话（弹窗/Kimi/到期日/更新、webview 桥/AGY/偏好设置/矩阵初稿、AGY CLI/Claude 修复/矩阵重写）的改动都在同一工作区。
- Claude 修复是本次最有把握的一处——三个独立参考实现（CodexBar、Claude-Usage-Tracker，以及 ClaudeBar 反向确认它们不走 web API）交叉验证了响应形状，不是猜测。
- AGY CLI session provider 的真实端到端（拉起 agy 交互会话、走完整 pipeline 拿到额度）还没有跑过，只验证了「PTY 拉起后端口出现」这一个环节；建议用户装包后实测一次待 IDE/agy 会话都不在跑的情况。
- README 矩阵仍有多处「待验证」标记（Claude CLI 额度命令、GLM 若干字段等）——如实标注未验证，不是遗漏。
