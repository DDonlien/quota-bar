# Quota Bar

> macOS 菜单栏下拉应用，集中查看多项 AI 服务的订阅费用与额度状态。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![Platform: macOS 26](https://img.shields.io/badge/Platform-macOS%2026-blueviolet)](#requirements)
[![Swift: 6](https://img.shields.io/badge/Swift-6.2-orange)](#requirements)

Quota Bar 把 Codex、Claude、Antigravity、MiniMax、Kimi 等多家 AI 服务的剩余额度、刷新时间、订阅费用集中到一个紧凑的菜单栏下拉面板里，不需要切浏览器、查收件箱、记 cycle 时间。

> ⚠️ **本项目处于功能核心阶段**：界面骨架与「真实数据接入」已落地（P0 + P1 完成），但每个 provider 的数据源还在持续扩展。

---

## 功能

- **真实额度读取**（P0）：
  - Codex 优先读取 `~/.codex/auth.json`，用 OAuth Bearer 调 `wham/usage`，不依赖 Full Disk Access
  - Kimi 优先读取 Kimi Desktop token-store，合并 `GetSubscriptionStat`（Work + Code + 到期日）和 `GetSubscription`（订阅名 + 价格）；CLI OAuth 仅作为 Code-only fallback
  - GLM / Z Code 读取 `~/.zcode/v2/config.json` / `credentials.json`，优先调用 Z Code `billing/balance` 解析 GLM-5.2 / GLM-5-Turbo 日额度；quota API 不可用时读取 `coding-plan-cache.json` 展示真实 plan 状态但不伪造额度
  - 浏览器 Cookie 数据源保留为显式启用路径；默认刷新不主动读取 Safari / Chrome / Brave / Edge / Arc / Firefox Cookie，避免系统密码或 Full Disk Access 弹窗
  - 通过 `kSecReturnData: true` 真正读 Keychain 里的 OAuth token / API key
  - Codex / OpenAI 走 `https://chatgpt.com/backend-api/wham/usage` 拿主/周额度
  - 只有拿到真实 dashboard/usage 响应的服务才展示订阅档位和价格；未接入 provider 不显示占位 Plus/Pro
- **持久化与刷新语义**：
  - 偏好、来源索引和 last-known-good 快照保存到 `~/Library/Application Support/QuotaBar/`
  - 来源索引只保存 sourceKind/sourceId 等非敏感元信息，不复制 token、cookie、API key 或 refresh token
  - 快照仅用于启动、更新、重装或刷新中的 stale 过渡；刷新失败后会如实切到待配置、未订阅、已过期或抓取失败
- **可扩展的策略链**（P1）：
  - 每个 provider 暴露一组有序 `ProviderFetchStrategy`；Codex 顺序为 OAuth → Cookie → CLI 日志 → Keychain
  - `FetchPipeline` 支持串行 fallback 和并发合并两种模式
  - `TTYCommandRunner` 给交互式 CLI（codex /status、claude /login）提供 PTY
  - `LoginRunner` 一键跳到 Terminal.app 跑 `codex login`
- **TCC 引导**：
  - 默认数据链路不要求浏览器 Cookie 权限，不会在自动刷新时主动触发浏览器 Keychain / Full Disk Access 弹窗
  - 浏览器 Cookie 路径仅在显式启用后作为补充数据源运行；后续设置页完成前不作为默认路径
- **菜单栏下拉 UI**：
  - 总费用、可用订阅计数、各服务 5 小时 / 周额度条
  - 自动 5 分钟刷新 + 手动「立即刷新」，手动刷新不会关闭 dropdown
  - 状态色彩：可用 = 品牌色，待配置 = 灰色，刷新失败 = 橙色
  - 刷新时间短期显示「4 小时后 / 明天 / 后天」，更远日期显示具体日期
  - 价格按系统语言/地区选择显示货币；简体中文或中国区默认将 USD 订阅价按实时汇率换算成人民币

---

## 支持的 Provider

当前明确维护的 Provider：Codex、Claude、Kimi、MiniMax、Antigravity、GLM / Z Code。Gemini 已从主动展示路径移除，Google 系配额优先通过 Antigravity 获取。新增 provider 不使用“其他 provider”占位，必须先明确具体名称、安装/凭证/额度/过期日来源。

### 四层获取矩阵（开发基线）

Quota Bar 的刷新链路拆为四层：Provider 获取、额度获取、过期日获取、档位/费用获取。每一层都应保存“上次成功来源索引”，下次刷新优先复查该来源；复查失败后再按本表单元格里的优先级 fallback。归一化始终在最后执行：统一成 `ProviderSnapshot`、`QuotaWindow`、`subscriptionExpiresAt`、`subscriptionTier`、`monthlyPrice` 和明确的 availability。

优先级标记：`P1` 是该 provider 在该层的首选手段，`P2/P3/P4` 依次 fallback；`跳过` 表示明确不执行；`待验证` 表示只能作为调研项，未验证前不得执行或写入可信快照；`弱信号` 表示只能辅助判断，不能单独作为可用订阅或当前状态的依据。每层实际执行前还会先尝试该层的“上次成功来源索引”，成功则跳过同层其余手段。浏览器 Cookie / Browser dashboard 路径目前仅在显式启用后执行，不属于默认自动刷新链路。

#### 1. Provider 获取

| 可行方案 | Codex | Claude | Kimi | MiniMax | Antigravity | GLM / Z Code |
|---|---|---|---|---|---|---|
| App Bundle | P3：可选探测 `Codex.app` | P3：可选探测 `Claude.app` | P1：`com.moonshot.kimichat` | P1：`com.minimax.agent.cn` | P1：`com.google.antigravity` | P1：`dev.zcode.app` |
| 配置/凭证文件 | P1：`~/.codex/auth.json` | P1：`~/.claude/.credentials.json` | P2：`~/Library/Application Support/kimi-desktop/bridge-store/token-store.json`；P3：`~/.kimi-code/credentials/kimi-code.json` | P2：`~/.mmx/config.json`、`~/.mavis/config.yaml` | 待验证：本地配置路径未定 | P2：`~/.zcode/v2/config.json`、`~/.zcode/v2/credentials.json`；P3：`coding-plan-cache.json` 状态兜底 |
| CLI | P2：`codex` | P2：`claude` | P3：`kimi` | P3：`minimax` / `mmx`，命令名需统一验证 | P2：`antigravity` / `agy` | P3：`zcode-cli` |
| API / 环境变量 | 跳过：不作为发现主路径 | P4 弱信号：`ANTHROPIC_API_KEY` 只证明 API key | P4：`KIMI_AUTH_TOKEN` 可证明有 token | P4：MiniMax API key 可证明配置 | 跳过：不作为发现主路径 | P2：读取 Z Code plan config 后判断 |
| Browser 登录痕迹 | P4 弱信号：`chatgpt.com` | P4 弱信号：`claude.ai` | P4 弱信号：`kimi.com` / `kimi.moonshot.cn` | P4 弱信号：`minimax.chat` / `minimax.com` | 跳过 | 跳过 |
| 本地 RPC / 进程 | P2：`codex app-server` 可作为高置信来源 | 待验证 | 待验证 | 跳过：不优先 | P1：language_server / localhost 进程 | 待验证 |

#### 2. 额度获取

| 可行方案 | Codex | Claude | Kimi | MiniMax | Antigravity | GLM / Z Code |
|---|---|---|---|---|---|---|
| 配置文件 → API | P2：`auth.json` access token → `https://chatgpt.com/backend-api/wham/usage` | P1：Claude OAuth → Anthropic usage 或 Messages headers | P1：Kimi Desktop token-store access token → `GetSubscriptionStat` + `GetSubscription`；P2：CLI OAuth → Code-only `https://api.kimi.com/coding/v1/usages` | P1：`~/.mmx/config.json` / `~/.mavis/config.yaml` API key → `https://api.minimaxi.com/v1/coding_plan/remains` | 跳过：不优先 | P1：`~/.zcode/v2/config.json` 读启用 plan 的 API key/baseURL 后调 `zcode-plan/billing/balance`；P2：旧 `api/monitor/usage/quota/limit` 兼容；P3：`coding-plan-cache.json` 只读 plan 状态 |
| CLI 指令 | P4：`codex /status` 或 TTY fallback；不优先于 OAuth/RPC | 待验证：可作登录/状态辅助，额度命令未定 | P3：`kimi` 交互输入 `/usage` | 待验证：`mmx quota` / `minimax quota` 未确认，不猜测执行 | P2：`agy` CLI 运行时本地端口，继续用结构化 RPC 取额度；`agy models` 只作登录/可用性弱信号 | 待验证：`zcode-cli` 额度命令未定 |
| HTTP API 指令 | P2：`wham/usage`，解析 primary/secondary 或 headers | P1：`api.anthropic.com` rate-limit headers | P1：Kimi Desktop token 调 Web membership API 补完整额度；P2：Kimi coding usage | P1：MiniMax coding plan remains | P1：本地 endpoint 包装成 HTTP/gRPC-Web | P1：`https://zcode.z.ai/api/v1/zcode-plan/billing/balance?app_version=...` |
| RPC | P1：`codex app-server` → `account/rateLimits/read` | 待验证 | 待验证 | 待验证 | P1：language_server `GetUserStatus` | 待验证 |
| Browser dashboard | P3：`chatgpt.com` cookie 兜底，避免默认扫浏览器 | P2：`claude.ai/api/organizations → usage` | P3：`www.kimi.com/...GetSubscriptionStat`，只在显式启用浏览器 Cookie 后兜底 | P2：`api.minimax.chat/.../coding_plan/remains`，可能受 Cloudflare 限制 | 跳过 | 跳过 |
| 本地日志 | P4：`~/.codex/sessions/*.jsonl` 只能估算，不写强快照 | 待验证 | 跳过 | 跳过 | 跳过 | 跳过 |
| 自然语言问询 | 待验证：最后实验项，不作为可信来源 | 待验证：最后实验项 | 跳过：只接受 `/usage` 这类结构化命令，不用自由问答 | 跳过 | 跳过 | 跳过 |

#### 3. 过期日获取

| 可行方案 | Codex | Claude | Kimi | MiniMax | Antigravity | GLM / Z Code |
|---|---|---|---|---|---|---|
| 配置文件 / token payload | P2 弱信号：`id_token` 可读但可能 stale | P2 弱信号：Claude OAuth 可能有订阅类型，到期日不稳定 | 跳过：OAuth 通常不含订阅到期日 | 跳过：config 通常不含订阅到期日 | 跳过：通常没有 | 待验证：plan metadata |
| CLI 指令 | 待验证：`/status` 是否有 renewal/expiry 未定 | 待验证 | 跳过：`/usage` 多为额度重置，不等于订阅过期 | 待验证 | 待验证 | 待验证 |
| API 指令 | 跳过：`wham/usage` 主要给额度，不保证过期日 | 跳过：Anthropic usage 不等于 billing expiry | P1：Desktop token / Web membership `GetSubscriptionStat.subscriptionBalance.expireTime` | 跳过：`coding_plan/remains` 当前不返回过期日 | 待验证：`GetUserStatus` 可能返回 tier，不保证 expiry | 待验证：plan endpoint 是否返回 expiry |
| Browser API / DOM | P1：`chatgpt.com/account/manage` 或 billing/settings DOM | P1：`claude.ai/settings/plan` 或账号页 DOM | P2：Kimi API 已足够，Browser DOM 只做兜底 | P1：`minimaxi.com/user-center/payment/balance` DOM | P1：`antigravity.google/settings` 或 Google billing DOM 待验证 | P2：Z Code / z.ai 账号页待验证 |
| 邮件 / 账单文件 | 跳过 | 跳过 | 跳过 | 跳过 | 跳过 | 跳过 |
| 自然语言问询 | 跳过：不用于状态判定 | 跳过 | 跳过 | 跳过 | 跳过 | 跳过 |

#### 4. 档位与费用获取

| 可行方案 | Codex | Claude | Kimi | MiniMax | Antigravity | GLM / Z Code |
|---|---|---|---|---|---|---|
| API / 响应字段拿档位 | P1：`wham/usage.plan_type` → Plus/Pro | P1：Claude OAuth / account info 拿 plan，字段待稳定 | P1：Desktop token / Web membership `membership.level` / `GetSubscriptionStat` → Andante 等 | P1：`current_package_name` → TokenPlan/Plus/Pro 等 | P1：`GetUserStatus` → Plus/Pro/Ultra 等 | P2：plan endpoint 返回 plan id 时使用 |
| 配置文件拿档位 | P2 弱信号：`id_token` | P2：`.credentials.json` 可能有 subscriptionType | P2：Desktop token-store 的 subscription data / CLI OAuth 可辅助 | P2：config 不一定有 package，API 更准 | 待验证：本地 config | P1：`~/.zcode/v2/config.json` 的启用 plan；P2：`coding-plan-cache.json` 的 available/unavailable plan 状态 |
| CLI 拿档位 | 待验证：`/status` | 待验证 | P3：`/usage` 可能显示 membership | 待验证 | 待验证 | 待验证：`zcode-cli` |
| Browser DOM/API | P3：ChatGPT account/billing 兜底 | P3：Claude settings 兜底 | P2：Kimi membership API 已较好 | P3：MiniMax user-center 兜底 | P2：Google/Antigravity settings 兜底 | P3：z.ai / Z Code account 页兜底 |
| 费用知识映射 | P1：Plus $20 / Pro $200；本地汇率转人民币 | P2：需明确 Claude plan 定价表后映射 | P1：Andante/Moderato/Allegretto/Allegro → 知识映射 | P1：Coding Plan 档位 → 知识映射 | P1：Google AI Plus/Pro/Ultra → 知识映射 | P1：四种 builtin plan → 智谱/Z.ai 价格表映射 |

---

## 要求

- macOS 26 (Tahoe) 或更新
- Swift 6.2 / Xcode 26+
- 默认不要求 Full Disk Access；仅在后续显式启用浏览器 Cookie 数据源时才可能需要相关系统权限。Chromium 系浏览器 Cookie 还常需要 Keychain Safe Storage 解密，Full Disk Access 只能解决文件读取，不能单独替代浏览器/Keychain 授权

---

## 快速开始

### 安装（推荐）

从 [Releases](https://github.com/DDonlien/quota-bar/releases) 页面下载最新的 `QuotaBar-<sha>.dmg`，打开后把 **Quota Bar** 拖进 **Applications**，或在 DMG 窗口里直接双击运行。也可以访问主页 [quotabar.ddonlien.com](https://quotabar.ddonlien.com) 一键下载。

> 每个 push 到 `main` 都会自动构建一个新的 pre-release；CI 配置见 [`.github/workflows/release.yml`](./.github/workflows/release.yml)。
>
> 首次启动需要右键 → 打开（未签名 + 未公证）。

### 跑起来

```bash
git clone https://github.com/yourname/quota-bar.git
cd quota-bar/quota-bar
swift run
```

启动后：

1. 状态栏右上角出现「QB」图标（macOS 26）或 `chart.bar.fill` SF Symbol
2. 点开菜单栏图标查看已探测到的本地 App、CLI 或配置文件来源
3. Codex / Kimi / MiniMax / Z Code 使用本地配置、Desktop token 或 OAuth 路径，Antigravity 使用本地 RPC；浏览器 Cookie 不在默认刷新中自动执行

### 跑 web 主页（[quotabar.ddonlien.com](https://quotabar.ddonlien.com) 的本地版）

营销主页是独立 Astro 静态站，部署在 `web/` 子项目里。日常不需启动，但 PR 改到主页或新增 provider 卡片时本地预览用：

```bash
cd web
npm install
npm run dev      # 本地预览 http://localhost:4321
npm run build    # 构建到 web/dist/，CI 会把 dist/ 部署到 quotabar.ddonlien.com
```

依赖 `node 20+`（GitHub Actions 用 ubuntu-latest + setup-node@v4 也是 20）。

### 打包成 .app

```bash
cd quota-bar
./scripts/build-app.sh
```

每次运行都会在 `quota-bar/build/` 下生成一个以当前时间命名的子文件夹：

```text
quota-bar/build/
├── 20260620-193559/
│   └── QuotaBar.app
├── latest -> 20260620-193559/
└── ...
```

- 历史版本按时间保留，方便回滚对比
- `build/latest/QuotaBar.app` 始终指向最近一次构建，适合固定验证入口
- 可以拖到 Applications，或直接从 Finder 双击打开

> 注意：未签名 + 未公证的 .app 第一次启动需要右键 → 打开。

---

## 开发

### 目录结构

```text
.
├── quota-bar/                 # 实际 SwiftPM 包（PascalCase 标识符是 SPM 硬约束）
│   ├── Package.swift          # SPM 入口（依赖 SweetCookieKit）
│   ├── Sources/QuotaBar/
│   │   ├── QuotaModels.swift           # 领域模型：ProviderKind / QuotaWindow / Snapshot
│   │   ├── QuotaProvider.swift         # 数据源协议
│   │   ├── ProviderFetchStrategy.swift # ★ 策略 + Pipeline
│   │   ├── Strategies.swift            # ★ 已知 provider 的 pipeline 工厂
│   │   ├── BrowserCookieReader.swift   # SweetCookieKit 适配器
│   │   ├── BrowserCookieProvider.swift # Cookie 数据源
│   │   ├── DashboardEndpoints.swift    # 真实 endpoint + parser
│   │   ├── KeychainProvider.swift      # Keychain 数据源
│   │   ├── CLILogProvider.swift        # ~/.codex/sessions 估算
│   │   ├── TTYCommandRunner.swift      # ★ PTY 命令执行器
│   │   ├── LoginRunner.swift           # ★ 登录引导
│   │   ├── PrivacyAccessChecker.swift  # FDA 检测
│   │   ├── RefreshCoordinator.swift    # 主循环
│   │   ├── MenuView.swift              # SwiftUI 菜单内容
│   │   ├── StatusBarController.swift   # AppKit 宿主
│   │   └── ...
│   ├── scripts/build-app.sh   # 本地打包脚本
│   └── build/                 # 手工 build 产物（gitignored）
├── web/                       # 营销主页（Astro 静态站，部署到 quotabar.ddonlien.com）
│   ├── src/                   # 页面、组件、design tokens
│   ├── public/                # favicon 等静态资源
│   └── ...
├── .github/workflows/         # CI / Release
├── AGENTS.md                  # Agent 协作规范
├── REQUIREMENTS.md            # 需求追踪
├── DESIGN.md                  # 视觉规范
├── agent-log/                 # 任务执行日志
├── agent-template/            # Agent 协作文档模板
├── research/                  # 调研文档
├── reference/                 # 参考资料（不计入项目代码）
└── LICENSE                    # MIT
```

### 构建 & 运行测试

```bash
cd quota-bar
swift build          # debug 构建
swift run            # 启动菜单栏 App
swift build -c release
```

### 加一个新的 Provider

1. 在 `QuotaModels.swift` 的 `ProviderKind` 里加 case + 在所有 switch 里补全
2. 在 `DashboardEndpoints.swift` 里注册 endpoint + parser
3. 在 `Strategies.swift` 的 `ProviderPipelines.makePipelines()` 里加一行
4. 提交 PR

更复杂的 provider（如需要 OAuth in-app 流程）可以参考 CodexBar 的 ProviderImplementation 模式。

---

## 工作原理

### 数据流

```
RefreshCoordinator (5min 自动 + 手动)
        ↓
FetchPipeline (per ProviderKind)
        ↓
[Strategy 1] [Strategy 2] [Strategy 3]    ← 并发跑
        ↓
Merge by priority (available > needsConfig > notInstalled > fetchFailed)
        ↓
DashboardState → MenuView → 状态栏下拉
```

### TCC / Full Disk Access

macOS 把浏览器 Cookie 数据库划在 TCC 的「Full Disk Access」之后，没有公开 API 可以查询授权状态。对 Chrome / Edge / Arc / Brave 这类 Chromium 系浏览器来说，拿到 Cookie 数据库文件还不够，Cookie value 往往还需要 Keychain Safe Storage 解密，所以 Full Disk Access 只能解决“读文件”，不能单独替代浏览器/Keychain 授权。Quota Bar 当前默认不执行浏览器 Cookie 读取，避免自动刷新时弹出系统密码或权限弹窗。浏览器路径作为后续显式启用能力保留，调试时可用环境变量打开：

```bash
QUOTABAR_ENABLE_BROWSER_COOKIE=1 swift run
```

启用浏览器路径后，Quota Bar 用以下两种方式探测：

- **同步探测**：`PrivacyAccessChecker.hasFullDiskAccess()` 尝试打开 `~/Library/Cookies/Cookies.binarycookies`，失败则视为未授权。
- **运行时探测**：SweetCookieKit 在尝试解密 Chrome Cookie 时抛 `BrowserCookieError.accessDenied` → 转成 `ProviderAvailability.fetchFailed` → UI 显示横幅。

授权流程：点「打开系统设置」→ 系统设置 → 隐私与安全性 → 完全磁盘访问权限 → 勾选 Quota Bar → 重启。

### PTY 与登录引导

Codex / Claude 的 TUI 在无 TTY 时会拒绝交互。`TTYCommandRunner` 通过 `/usr/bin/script -q /dev/null` 借一个伪终端。`LoginRunner` 把 `codex login` / `claude /login` 等命令塞进 Terminal.app。

---

## 路线图

- [ ] Claude dashboard endpoint（org 发现 + `/usage` 解析）
- [ ] Trae Work 独立额度接入调研
- [ ] In-app OAuth（避免跳出 Terminal）
- [ ] 历史曲线 + 用量预测
- [ ] 通知：额度低于阈值时提醒
- [ ] 多账号切换

完整需求追踪见 [`REQUIREMENTS.md`](./REQUIREMENTS.md)。

---

## 贡献

欢迎 PR：

1. Fork → 新建分支 → 改代码
2. `swift build` 通过 + 在本地跑一遍
3. 提交 PR，描述清楚：
   - 对应哪个 ProviderKind
   - 引用的 dashboard endpoint + JSON 字段
   - 是否引入新依赖

需要避开的方向：

- 不要 `rm -rf` 任何浏览器 cookie 数据库（只读！）
- 不要把 token / cookie 值 log 到控制台

---

## License

[MIT](./LICENSE) — Tao Be, 2026.

### 致谢

- [SweetCookieKit](https://github.com/steipete/SweetCookieKit) by Peter Steinberger — 浏览器 Cookie 提取
- [CodexBar](https://github.com/steipete/CodexBar) by Peter Steinberger — 设计参考（strategy / pipeline / PTY 模式）
