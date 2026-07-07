# 用户原始 prompt

> 但我看你最新的包claude还是没有额度？我给你的3个reference项目肯定是不需要通过webview之类的途径获取claude额度的，最多就是去系统设置里开，你看看怎么回事

# 启动运行时的分支和版本

- 分支：`main`
- 版本：`1bba4e3` + 此前五次会话的未提交改动

# 任务开始时间

2026-07-06 约 22:39 +0800

# 任务结束时间

2026-07-06 23:00 +0800

# 任务结束时是否执行了提交

未提交（累计六次会话改动都在工作区，等用户 review）。

# 已阅读上下文

- 尝试用 `log show`/`/usr/bin/log` 读取新打包 app 的实时运行日志，定位 Claude 管线卡在哪一步；发现 `log`（无路径版本）在当前 shell 环境里被拦截成别的东西（"too many arguments"），改用 `/usr/bin/log` 全路径可用，但发现 NSLog 输出对第三方未签名 app 大量显示为 `<private>` 或干脆检索不到自定义前缀文本——放弃日志路线，改用直接命令行复现。
- 直接跑 `env -i HOME="$HOME" /Users/taobe/.local/bin/claude auth status --json`（模拟我们代码里 `process.environment = ["HOME": ...]` 的精简环境）：复现出 `loggedIn: false`，而正常从交互式 shell 跑同一个命令是 `loggedIn: true, subscriptionType: "pro"`。
- 逐个加回环境变量二分定位：加回 `PATH` 无效，加回 `USER` 立即恢复正常（`loggedIn: true` + 完整字段）。
- grep 全部 `process.environment =` 赋值点，确认只有 `ClaudeAuthStatusCLIProvider`、`MiniMaxCommandProvider` 两处整体替换成精简环境；`AntigravityCLISessionProvider` 没设置（默认继承完整环境，不受影响）；`TTYCommandRunner.runRaw` 一直是正确的"继承 + 覆盖"写法。

# 对话与行动记录

用户的判断是对的：这跟 WebView、跟浏览器授权设计完全无关。真正的根因是我自己上一轮写的两个新 CLI provider（`ClaudeAuthStatusCLIProvider` 执行 `claude auth status`、`MiniMaxCommandProvider` 执行 `mmx quota show`）在拉起子进程时，把 `process.environment` 整体替换成了只有 `HOME`（或 `HOME` + `TERM`）——这是我图省事写的"传干净环境"，但 `claude` CLI 读取自己的登录态/Keychain 凭证时依赖 `USER` 这类变量识别当前用户身份，缺了它就会误判成"未登录"，即使 Keychain 里明明有真实凭证。这跟浏览器授权、跟 WebView 完全不搭边，是我自己代码里一个纯粹的"传参数传漏了"的 bug。

修复：两处都改成继承 `ProcessInfo.processInfo.environment`（完整父进程环境）后只覆盖必需的个别键（MiniMax 需要 `TERM=dumb` 抑制 TUI 输出），不再整体替换。

顺带把这次机会用完整：既然确认了 Keychain 里的凭证是真实、有效的，而 `ClaudeOAuthUsageProvider` 之前只读文件（`~/.claude/.credentials.json`，本机没有这个文件），给它加了 Keychain 兜底——文件不存在时改读 Keychain 里 `"Claude Code-credentials"` 这个条目（跟文件是同一份 JSON），同一套解析逻辑复用。这里刻意不设 `interactionNotAllowed`：读取另一个 App（Claude Code）写入的 Keychain 条目需要用户点一次「始终允许」，这正是用户说的"系统设置里开"那类一次性授权，跟我们对浏览器 Cookie Keychain 的静默降级要求（0.9.0-SEC-A-001）不是同一件事，不适用那条"绝不弹窗"的禁令。

# 完成工作

- `ClaudeAuthStatusCLIProvider.swift`：子进程环境从 `["HOME": ...]` 改为继承完整环境。
- `MiniMaxCommandProvider.swift`：子进程环境从 `["HOME": ..., "TERM": "dumb"]` 改为继承完整环境 + 覆盖 `TERM`。
- `ClaudeOAuthUsageProvider.swift`：新增 `ClaudeKeychainCredentialsReader`，`loadCredentials()` 改为文件优先、Keychain 兜底（取最近修改条目，允许一次性系统授权提示）。
- 新包：`macos/build/20260706-225934-main/Quota Bar.app`（`build/latest` 已指向）。

# 更新的需求 ID

- 新增并完成：`0.10.0-DATA-B-016`（子进程环境裁剪修复）、`0.10.0-DATA-B-017`（Claude Keychain 凭证兜底）

# 更新的 README 或 DESIGN 章节

无（实现层面的 bug 修复，不改变已记录的获取方案结论）。

# 验证方式

- `make test`：162 tests in 38 suites 全部通过。新增 `CLISubprocessEnvironmentTests`：生成一个真实可执行的 fake CLI 脚本（打印 `$USER`），用 provider **默认（非 mock）执行器**跑一遍，断言子进程里能看到真实 `USER`——直接对着这次的根因写回归测试，不是泛泛测试。
- `make app`：成功产包。
- 命令行直接复现修复前后的行为差异（`env -i HOME=... ` vs `env -i HOME=... USER=...`）。
- 未能端到端验证 Keychain 授权弹窗的完整流程——需要用户交互点「始终允许」，我这边无法代为点击；已关闭本次会话中为调试打开的旧包实例，避免残留后台进程。

# 备注

- 未提交 git commit。
- 用户装新包后大概率会看到一次系统 Keychain 授权弹窗（"quota-bar 想使用你钥匙串中的机密信息…Claude Code-credentials"），需要点「始终允许」；这是本机没有 `.credentials.json` 文件、走 Keychain 兜底路径时的正常一次性动作，点过一次后长期生效，不会每次刷新都弹。
- 这次 bug 提醒我一个模式：写"隔离子进程环境"这类代码时，默认应该是"继承 + 覆盖"（`TTYCommandRunner.runRaw` 已有的正确写法），而不是"从零构造一份精简环境"——后者极容易漏掉某个工具意想不到依赖的变量，且很难在开发机上凭空发现（因为开发机的 shell 环境天然是完整的，只有在真正走到"被裁剪的子进程"这条代码路径时才会暴露）。
