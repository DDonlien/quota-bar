# CodexBar 对比调研：quota-bar 为什么拿不到真实数据

> 调研日期：2026-06-18
> 调研人：mavis（agent）
> 对比对象：[CodexBar](https://github.com/steipete/CodexBar)（路径 `/Users/taobe/Projects/GitHub/Personal/sub-bro`）
> 调研范围：quota-bar SUB-A 模块当前进度 vs CodexBar 的数据获取机制

## 1. 背景

quota-bar 的目标是「macOS 菜单栏下拉应用，用于展示 AI 订阅费用与额度状态」。当前仓库正处在「界面原型 → 功能核心」的过渡阶段，多个 worktree 并行推进 P1 子需求：

| Worktree | 分支 | 职责 | 状态 |
|---|---|---|---|
| `quota-bar-sub-a` | `feat/sub-a-subscription-fetching` | 订阅数据获取 | ~55% 完成 |
| `quota-bar.ref-a` | `feature/ref-a` | 刷新机制 | 进行中 |
| `.worktrees/ui-c` | `feat/ui-c` | 动态数据展示 | 已完成（消费侧 API 预留） |
| `.worktrees/investigate-codex-bar` | `investigate/codex-bar` | 本调研 | 新建 |

用户问题：「为什么现在 quota-bar 完全没办法真实 get 到 mac 上有哪些可用 AI 服务、以及对应的额度」。

本文档通过对比 CodexBar（业界成熟参考实现）回答这个问题，并给出修复路径。

---

## 2. CodexBar 架构关键点（核心摘要）

CodexBar 是 steipete 开源的 macOS 菜单栏应用，已经支持 60+ AI 服务商（Codex / Claude / Gemini / Cursor / Kimi / MiniMax / Bedrock / Ollama / VertexAI / Grok / Mistral / Zai / DeepSeek / ...）。其架构核心有四点。

### 2.1 三层模块划分

```
┌────────────────────────────────────────┐
│ CodexBar (UI Layer)                    │
│ - StatusItemController / NSMenu       │
│ - ProviderImplementation × 53         │
│ - UsageStore (主刷新协调器)            │
└────────────────────────────────────────┘
              ↓ 调用
┌────────────────────────────────────────┐
│ CodexBarCore (Domain Layer)            │
│ - Providers/<Name>/                    │
│   · Descriptor（声明能力）              │
│   · Strategy × N（多种抓取尝试）         │
│   · Fetcher（实际 HTTP / PTY / RPC）    │
│   · CookieImporter（SweetCookieKit）    │
│ - ProviderDescriptorRegistry          │
│ - ProviderFetchPlan / Pipeline         │
│ - UsageFetcher / UsageSnapshot         │
│ - Host/PTY + Host/Process              │
└────────────────────────────────────────┘
              ↓ 调用
┌────────────────────────────────────────┐
│ 外部 SwiftPM: SweetCookieKit           │
│ - 直接解析 Safari/Chrome/Firefox cookie │
└────────────────────────────────────────┘
```

### 2.2 统一抽象：`ProviderFetchStrategy` + Pipeline

**这是 CodexBar 统一 60 个 Provider 的核心魔法**：

```swift
public protocol ProviderFetchStrategy: Sendable {
    var id: String { get }                       // "codex.cli" / "claude.oauth"
    var kind: ProviderFetchKind { get }          // cli / web / oauth / apiToken / localProbe
    func isAvailable(_ context: ProviderFetchContext) async -> Bool
    func fetch(_ context: ProviderFetchContext) async throws -> ProviderFetchResult
    func shouldFallback(on error: Error, context: ProviderFetchContext) -> Bool
}
```

每个 Provider 暴露一组**有序**的 strategy（CLI → OAuth → Web → API Token）。通用 pipeline 串行尝试，自动 fallback：

1. 调 `isAvailable(ctx)` → 不可用就跳过
2. 调 `fetch(ctx)` → 成功即返回
3. 失败时调 `shouldFallback` → true 才继续下一个

**加第 N 个 Provider 只需写一组 strategy，pipeline 自动处理多源 fallback**。

### 2.3 五种抓取模式

每个 Provider 通过 `SourceMode` 声明数据来源：

```swift
public enum ProviderSourceMode: String, CaseIterable, Sendable, Codable {
    case auto    // 智能选最优
    case web     // 只用浏览器 Cookie + Web API
    case cli     // 只用 CLI 进程（PTY 或子进程）
    case oauth   // OAuth token
    case api     // API key
}
```

### 2.4 真实可工作的实现路径（举例）

| Provider | 数据来源 | 登录方式 | 特殊处理 |
|---|---|---|---|
| **Codex** | CLI `app-server` JSON-RPC 调 `account/rateLimits/read`，或 PTY 跑 `/status`，或 OAuth 调 `wham/usage` | `codex login`（PTY 120s 超时） | 多账号 managed-codex；WebKit 离屏 headless WebView 抓 chatgpt.com |
| **Claude** | Web API `https://claude.ai/api/organizations/{org_id}/usage`（sessionKey cookie），或 CLI PTY，或 Admin API | `claude /login`（PTY `stopOnSubstrings: ["Successfully logged in"]`） | OAuth credentials 优先读 `~/.claude/.credentials.json`，回退 Keychain；多窗口 (5h/weekly/opus) |
| **Gemini** | HTTP quota endpoint（OAuth bearer） | 清掉旧 `~/.gemini/oauth_creds.json` + 启 Terminal 跑 `gemini` + 轮询文件重新生成 | timeout 时 fallback 到 `/usr/bin/curl` |
| **Kimi** | HTTP `kimi.gateway.billing.v1.BillingService/GetUsages`（Code API Key）或 Web（`kimi-auth` cookie） | kimi.com 登录 | JWT 解析 deviceId/sessionId 注入 header；优先 manual cookie → browser cookie (KimiCookieImporter) → env token |
| **MiniMax** | HTTP Coding Plan API（HERTZ-SESSION cookie）或 API Token | MiniMax 登录 | 还读 Chromium LocalStorage/IndexedDB 找 access_token；group_id 从 LocalStorage 推断；Region (.global/.cn) 区分 |
| **Cursor** | Web API `https://cursor.com/api/usage`（7 种候选 cookie） | `https://authenticator.cursor.sh/` + 轮询 CursorStatusProbe | 没有公开 API，纯 cookie 抓；Safari-first cookie 优先级 |

### 2.5 Cookie 读取机制

CodexBar **不通过 `security` CLI**（那是 Claude OAuth keychain 专用），而是直接解析 SQLite / binary 文件：

- Safari：`~/Library/Cookies/Cookies.binarycookies`（二进制 blob）
- Chromium：`~/Library/Application Support/<browser>/<Profile>/Cookies` 或 `Network/Cookies`（SQLite，**加密的 encrypted_value**）
- Firefox：`~/Library/Application Support/Firefox/Profiles/*.default/cookies.sqlite`

**Chrome 加密**：用 macOS Keychain "Chrome Safe Storage" 密码 → AES-GCM 解密。

通过外部 SPM 包 [SweetCookieKit](https://github.com/steipete/SweetCookieKit) 封装这一切。

### 2.6 PTY 与子进程抽象

```swift
// 交互式 CLI（Codex /status、Claude /login）
TTYCommandRunner {
    openpty() → 主/从 fd
    Process 启动二进制，stdin/stdout 接 PTY 从端
    滚动匹配（KMP）扫描输出
    状态机: Codex /status 自动识别 "Update available!" 跳过升级
    进程组隔离: setpgid + proc_listchildpids → SIGTERM → SIGKILL
}

// 非交互式命令（Gemini 的 curl fallback）
SubprocessRunner {
    Process + Pipe + terminationHandler
    DispatchSourceTimer 触发超时
    withTaskCancellationHandler 优雅取消
}
```

### 2.7 登录流程统一（LoginRunner）

每 Provider 一个 `LoginRunner`：

| Provider | Runner | 流程 |
|---|---|---|
| Codex | `CodexLoginRunner` | `Process` 跑 `codex login`，120s 超时 |
| Claude | `ClaudeLoginRunner` | PTY 跑 `claude /login`，匹配 "Successfully logged in" |
| Gemini | `GeminiLoginRunner` | 清旧 creds + 写临时 .command + NSWorkspace.open + 后台轮询 |
| Cursor | `CursorLoginRunner` | NSWorkspace.open 浏览器 + 轮询 CursorStatusProbe |

### 2.8 刷新机制

`UsageStore` 用 `Task.detached(priority: .utility)` + `Task.sleep(for: .seconds(wait))` 循环，默认 5 分钟：

```swift
self.timerTask = Task.detached(priority: .utility) { [weak self] in
    while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(wait))
        await self?.refresh()
    }
}
```

`withTaskGroup` 并行拉所有 provider；`coalesceIfRefreshing` 保证同 provider 不会并发拉；`generation token` 防 stale 写入。

菜单打开时按需刷新：若 snapshot 距上次 > N 秒且无 in-flight，先展示旧数据 + 后台触发刷新。

---

## 3. quota-bar SUB-A 现状

SUB-A worktree `feat/sub-a-subscription-fetching` 已实现以下 9 个 Swift 文件（**全部未 commit**，在工作区）：

| 文件 | 行数 | 职责 |
|---|---|---|
| `QuotaModels.swift` | 161 | `ProviderKind` (codex/minimax/kimi)、`QuotaWindow`、`ProviderAvailability` 四态、`ProviderSnapshot`、`QuotaFetchError` |
| `QuotaProvider.swift` | 31 | `protocol QuotaProvider { func fetch() async throws -> ProviderSnapshot }` |
| `BrowserCookieReader.swift` | 106 | 抽象 + `FilesystemCookieReader`（**占位**）+ `InMemoryCookieReader`（测试用） |
| `BrowserCookieProvider.swift` | 142 | Cookie → dashboard HTTP，`PlaceholderDashboardParser` |
| `CLILogProvider.swift` | 181 | 扫描 `~/.codex/sessions/*.jsonl` 估算 token |
| `KeychainProvider.swift` | 94 | Security framework 检测 OAuth token / API key 是否存在 |
| `ProviderFactory.swift` | 98 | 默认装配 7 个 Provider（3 cookie + 1 CLI + 3 keychain）+ `PriceParser` |
| `QuotaAggregator.swift` | 221 | `@MainActor` 聚合器，withTaskGroup 并行、stale 缓存、降级 |

UI 层已改造：`MenuView` 接收 `QuotaAggregator.State`，按 `ProviderAvailability` 四态渲染，stale 时整体 0.7 opacity。

### 3.1 每个 Provider 真实数据能力

| Provider | 数据来源 | 真实数据？ | 阻塞原因 |
|---|---|---|---|
| Codex Browser | Chrome SQLite cookie → dashboard HTTP | ❌ | sqlite3 解析是占位；endpoint=nil；沙盒需 Full Disk Access |
| Codex CLI | `~/.codex/sessions/*.jsonl` 扫描 | ⚠️ 取决于用户是否安装并用过 Codex CLI | JSONL 字段名/日期格式假设未验证 |
| Codex Keychain | Security.framework `SecItemCopyMatching` | ⚠️ 仅确认存在，不读额度 | service/account 名是猜的 |
| MiniMax Browser | 同 Codex Browser | ❌ | 同上 |
| MiniMax Keychain | 同 Codex Keychain | ❌ | 同上 |
| Kimi Browser | 同 Codex Browser | ❌ | 同上 |
| Kimi Keychain | 同 Codex Keychain | ❌ | 同上 |

**结论**：SUB-A 中**只有 Codex CLI 日志**这一条路径**可能**产出真实数据，其余 6 条全部走占位实现。0/3 Provider 有真实 endpoint 对接。

### 3.2 已达成 vs 未达成

按 REQUIREMENTS.md 的 SUB-A-000 ~ SUB-A-005 子需求看**全部勾选 [x]**，但实际可用度远低于此：

| 维度 | 完成度 |
|---|---|
| 协议 + 数据模型 | 100% |
| 框架装配（Provider 链 + 聚合器） | 100% |
| UI 改造 | 100% |
| Codex CLI 数据源 | 60%（框架完整，JSONL 格式未验证） |
| 浏览器 Cookie 数据源 | 20%（协议完整，实现是占位） |
| Keychain 数据源 | 40%（存在性检测实现，额度永远占位） |
| 真实端点协议对接 | 5% |
| **总体** | **约 55%** |

---

## 4. 关键差距分析

把 CodexBar 的能力与 quota-bar SUB-A 当前状态对比：

| 维度 | CodexBar | quota-bar SUB-A | 差距 |
|---|---|---|---|
| Provider 数量 | 60 | 3 (写死) | -57，DA-A 未集成 |
| 协议抽象 | `ProviderFetchStrategy` + Pipeline（串行 fallback） | `QuotaProvider` 单 fetch | 无 fallback 链 |
| 抓取模式 | auto/web/cli/oauth/api 5 选 | 无 SourceMode 概念 | 概念缺失 |
| Cookie 读取 | SweetCookieKit 真读 SQLite + 解密 | `FilesystemCookieReader` 占位返回 `[]` | **核心阻塞** |
| 真实 endpoint | 60 个 provider 都对接了真实 API | 全部 `dashboardEndpoint: nil` | **核心阻塞** |
| PTY 能力 | `TTYCommandRunner`（交互式 TUI） | 无 | Codex `/status` 类命令跑不起来 |
| 子进程能力 | `SubprocessRunner`（非交互式） | 无统一封装 | `which codex` 等探测命令散落 |
| Keychain | 读 token 内容 + 调用 API | 只检查存在性 + 占位额度 | 永远拿不到真数据 |
| 登录流程 | 13 个手写 `LoginRunner` | 无 | 用户没法登录 |
| 刷新机制 | 自动 5min + coalesce + generation token | 仅手动 + 菜单打开时 | 归 REF-A |
| 自动探测（DA-A） | `defaultEnabled` + Settings 开关 | 无 | Provider 列表写死 |

---

## 5. 为什么 quota-bar 现在拿不到真实数据（根因清单）

按可能性从高到低排列，每条都给出症状、根因、修复方向。

### 根因 #1：`FilesystemCookieReader` 是占位实现，永远返回 `[]` cookie

- **症状**：浏览器 Cookie 数据源对三家 Provider（codex / minimax / kimi）全部抛 `QuotaFetchError.missingCredentials("未在浏览器中找到 X 的登录态")`，UI 显示「待配置 · 需要登录相应服务」。
- **根因**：`BrowserCookieReader.swift` 第 77-84 行 `parseChromeCookieStore` 仅做 `FileManager.default.isReadableFile` 检查 + `_ = domains` + `return []`。**注释明确说**「避免引入额外的 C 依赖」。
- **影响范围**：3/7 Provider 全废。
- **修复方向**：
  1. 通过 SwiftPM 引入 [SweetCookieKit](https://github.com/steipete/SweetCookieKit) 或自实现 SQLite 解析 + Chrome encrypted_value AES-GCM 解密；
  2. 或先用 `security find-generic-password` 读 "Chrome Safe Storage" 拿到 key，再调 SQLCipher 解密；
  3. 或暂时用 `URLSession` + 用户手动粘贴 cookie（绕过 TCC）。

### 根因 #2：`BrowserCookieProvider` 的 `dashboardEndpoint` 全部为 `nil`

- **症状**：即便根因 #1 修好，拿到 cookie 后也不会发起任何请求；直接走 `parser.fallback(...)` 返回占位数据。
- **根因**：`ProviderFactory.defaultProviders` 第 24/30/36 行的 `dashboardEndpoint: nil`。三个 `BrowserCookieProvider` 都没有指定 endpoint URL。
- **影响范围**：浏览器路径全部失效。
- **修复方向**：
  - Codex：`https://chatgpt.com/backend-api/wham/usage`（需要 OpenAI OAuth token）
  - Kimi：`https://www.kimi.com/apiv2/kimi.gateway.billing.v1.BillingService/GetUsages`（需要 Code API Key 或 kimi-auth cookie）
  - MiniMax：`https://minimax.chat/...`（需要逆向，参考 CodexBar 的 MiniMaxProvider）

### 根因 #3：macOS TCC / Full Disk Access 未授权

- **症状**：即便根因 #1/#2 都修好，当应用以 adhoc 签名的命令行二进制运行时，读取 `~/Library/Application Support/Google/Chrome/Default/Cookies` 会被系统拒绝。
- **根因**：菜单栏应用 `LSUIElement=true`，未启用 App Sandbox 也不会申请 Full Disk Access。日志里明确写到"`CodingPlanMenu` 是 adhoc 签名的命令行可执行文件，Chrome cookie 读取在未授权时必然失败"。
- **修复方向**：
  1. 正式签名（Developer ID）+ Info.plist 添加 `NSAppleEventsUsageDescription`；
  2. 启动时检测权限缺失并弹引导；
  3. 或彻底绕过 TCC（用 `URLSession` 让用户手动粘贴 cookie）。

### 根因 #4：`KeychainProvider` 只检查存在性，不读额度

- **症状**：即便在 Keychain 中找到了 OAuth token，`KeychainProvider` 也返回 `.available` + 占位 `quotas=[1.0, 1.0]` 永远显示「等待首次刷新」。
- **根因**：`KeychainProvider.swift` 第 36-46 行 `hasCredential()` 只调 `SecItemCopyMatching(..., kSecReturnData: false)` 拿"是否存在"。注释解释"Keychain 不存储额度数据"，但本应**再用 token 去调服务商 API**——这一步完全没做。
- **影响范围**：3/7 Provider 永远假数据。
- **修复方向**：
  1. 改成 `kSecReturnData: true` 读 token 内容；
  2. 验证 `defaultKeychainService` / `defaultKeychainAccount` 实际值（`ai.openai.codex` / `com.minimax.code` / `com.moonshot.kimi` 是 agent 推测的，**未经验证**）；
  3. 拿到 token 后走真实 dashboard API（同根因 #2）。

### 根因 #5：`CLILogProvider` 的 JSONL 格式假设未验证

- **症状**：用户装了 Codex CLI 并使用过，但 `CLILogProvider` 拿到 0 tokens / 解析失败，UI 显示「Codex Plus 待配置」。
- **根因**：假设每行 JSON 是 `{"ts":"ISO8601","usage":{"input_tokens":N,"output_tokens":N,"total_tokens":N}}`；但 Codex CLI 实际 schema 可能不同。`ISO8601DateFormatter()` 默认也不接受 fractional seconds。
- **影响范围**：1/7 Provider（Codex CLI）部分不可用。
- **修复方向**：
  1. 在用户机器上真实打印 `~/.codex/sessions/*.jsonl` 第一行，对照 schema；
  2. 加更宽松的日期解析（`ISO8601DateFormatter` + `[.withInternetDateTime, .withFractionalSeconds]`）；
  3. 加 schema 兼容层：先严格模式，失败回退宽松字段名映射。

### 根因 #6：自动刷新 5min 定时器未实现（REF-A 范畴）

- **症状**：当前仅在菜单打开（`menuWillOpen`）和点击「立即刷新」时刷新；用户要求的"自动刷新间隔默认 5min"未生效。
- **根因**：本 worktree 是 SUB-A 单独切片，自动刷新归属 REF-A，在并行 worktree `feature/ref-a` 中实现。
- **修复方向**：等 REF-A worktree 合并；或在 SUB-A 内先加 `Timer.publish(every: 300)` 占位。

### 根因 #7：DA-A 未集成，Provider 列表写死 3 家

- **症状**：Claude、Gemini、Cursor、Warp 等用户可能订阅的服务完全不出现；`ProviderKind` 枚举只列 `codex / minimax / kimi`。
- **根因**：SUB-A 是单独切片，DA-A 自动探测在并行 worktree 中实现。`ProviderFactory.defaultProviders()` 返回固定 7 个 Provider。
- **修复方向**：等 DA-A worktree 合并后，把 `defaultProviders()` 改成接受 `[ProviderKind]` 参数。

### 根因 #8：无真实截图 / 手动验证

- **症状**：所有 UI 行为（状态点颜色、stale 半透明、警告角标、刷新 spinner）都只靠 NSLog 推断，没有截图证据。
- **根因**：日志明确写「accessory 应用无可见窗口、无法用 AppleScript 点击状态栏图标、未启用 Computer Use」。
- **修复方向**：用 Xcode UI 测试 / AppleScript `tell application "System Events"` 触发 click；或用 macOS screencapture API 配合定时任务截图。

---

## 6. 修复路径（按优先级）

### P0：核心阻塞，必须先解

1. **引入 SweetCookieKit 或自实现 SQLite 解析**（修根因 #1）
2. **对接三家真实 dashboard API**（修根因 #2）：
   - Codex: `wham/usage`（OAuth）
   - Kimi: `kimi.gateway.billing.v1.BillingService/GetUsages`
   - MiniMax: 逆向或参考 CodexBar 实现
3. **处理 macOS TCC**（修根因 #3）：先实现「检测权限 + 引导用户授权」UI 提示

### P1：体验改善，建议第二阶段

4. **KeychainProvider 改成读 token + 调 API**（修根因 #4）
5. **CLILogProvider 真实验证 JSONL 格式**（修根因 #5）
6. **引入 `ProviderFetchStrategy` + Pipeline**（来自 CodexBar）—— 把当前的"每 Provider 单一 fetch"改成"多 strategy 链 + 自动 fallback"
7. **实现 PTY 能力（`TTYCommandRunner`）**—— 让 Codex `/status` 这种交互式 TUI 能跑

### P2：长期演进，第三阶段再做

8. **LoginRunner 抽象 + 13 个手写 LoginFlow**（来自 CodexBar）—— 让用户能引导登录
9. **DA-A 集成**（修根因 #7）—— 让 Provider 列表动态化
10. **OAuth credentials 抽象（`xxxOAuthCredentialsStore`）**—— 让 Claude OAuth 这种"读别人 Keychain"路径可工作
11. **`ProviderMetadata` 标签（sessionLabel / weeklyLabel）**—— UI 通用化前置
12. **真实截图验证**（修根因 #8）—— UX 验收

---

## 7. 长期演进路径

参考 CodexBar 的成熟形态，quota-bar 的演进分四个阶段：

### 第 1 阶段（3 个 Provider 实战，本季度）

- 引入 `ProviderFetchStrategy` + `ProviderFetchPipeline`
- 引入 `UsageSnapshot` + `RateWindow` 统一返回模型
- 复用 CodexBar 的 `Sources/CodexBarCore/Providers/Codex/`（注意 LICENSE: MIT）
- 复用 `Sources/CodexBarCore/Host/PTY/TTYCommandRunner.swift`
- 引入 SweetCookieKit
- 解决 P0 三个根因

### 第 2 阶段（10 个 Provider，6-12 个月）

- 引入 LoginRunner 抽象
- 引入 `CookieHeaderCache`（Keychain + 30s 内存快照 + generation token）
- 引入 `ProviderMetadata` 标签
- 增加 Claude / Gemini / Cursor / Warp

### 第 3 阶段（30+ Provider，12-18 个月）

- 引入 SourcePlanner 动态策略选择
- 引入 `ProviderTokenResolver` 统一 env 变量解析
- 引入 `BrowserDetection` 三层缓存
- 增加 Bedrock / VertexAI / Ollama / Mistral / Zai / DeepSeek / Grok

### 第 4 阶段（60+ Provider，18 个月+）

- 拆分 CodexBarCore 为独立二进制（domain layer 独立编译）
- 引入描述文件驱动（参考 CodexBar 的 `ProviderCatalog`）
- 考虑 Swift Macro 自动注册（替代手写 `preconditionFailure`）
- 引入 Provider Descriptor schema (YAML/JSON)，让第三方 provider 可插拔

---

## 8. 参考资源

### CodexBar（sub-bro 仓库）

- 路径：`/Users/taobe/Projects/GitHub/Personal/sub-bro`
- 上游：https://github.com/steipete/CodexBar（MIT License）
- 关键文件：
  - `Sources/CodexBarCore/Providers/ProviderDescriptor.swift` — Provider 抽象
  - `Sources/CodexBarCore/Providers/ProviderFetchPlan.swift` — Strategy + Pipeline
  - `Sources/CodexBarCore/UsageFetcher.swift` — 统一返回模型
  - `Sources/CodexBarCore/Host/PTY/TTYCommandRunner.swift` — PTY 抽象
  - `Sources/CodexBarCore/Providers/Codex/` — Codex 实现（最完整）
  - `Sources/CodexBarCore/Providers/Claude/` — Claude 实现
  - `Sources/CodexBar/{Claude,Codex,Cursor,Gemini,...}LoginRunner.swift` — 登录流程
  - `Sources/Codex/CookieHeaderStore.swift` — Cookie Keychain 抽象

### 外部依赖

- [SweetCookieKit](https://github.com/steipete/SweetCookieKit) — 浏览器 cookie 直接解析

### 相关 worktree 与日志

- `quota-bar-sub-a/agent-log/20260618113346-utcp8-mavis.md` — SUB-A 实现日志
- `quota-bar/agent-log/20260618111226-utcp8-gpt5.md` — P1 需求规划
- `.worktrees/ui-c/agent-log/20260618113254-utcp8-mavis.md` — UI-C 实现日志

### quota-bar 内部文档

- `REQUIREMENTS.md` 第 56-63 行 SUB-A 模块
- `AGENTS.md` 项目阶段描述
- `README.md` 当前能力与限制

---

## 9. 一句话总结

**quota-bar 现在拿不到真实数据，是因为 SUB-A worktree 虽然搭好了"7 个 Provider + 聚合器 + UI"的完整骨架，但其中 6/7 条 Provider 的核心实现（cookie 读取、真实 endpoint、token 内容读取）全部是占位；只有 1 条 Codex CLI 日志扫描路径**有可能**产出真实数据。CodexBar 的成熟做法是引入 `ProviderFetchStrategy` + Pipeline 抽象、用 SweetCookieKit 真读浏览器 SQLite、对接每个 provider 的真实 API 端点——quota-bar 要走完同样的路，最少要先解决 P0 的三个根因（占位 cookie reader、nil endpoint、TCC 授权）。**