# Quota Bar

> macOS 菜单栏下拉应用，集中查看多项 AI 服务的订阅费用与额度状态。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![Platform: macOS 26](https://img.shields.io/badge/Platform-macOS%2026-blueviolet)](#requirements)
[![Swift: 6](https://img.shields.io/badge/Swift-6.2-orange)](#requirements)

Quota Bar 把 Codex、Claude、Gemini、MiniMax、Kimi 等多家 AI 服务的剩余额度、刷新时间、订阅费用集中到一个紧凑的菜单栏下拉面板里，不需要切浏览器、查收件箱、记 cycle 时间。

> ⚠️ **本项目处于功能核心阶段**：界面骨架与「真实数据接入」已落地（P0 + P1 完成），但每个 provider 的数据源还在持续扩展。

---

## 功能

- **真实额度读取**（P0）：
  - Codex 优先读取 `~/.codex/auth.json`，用 OAuth Bearer 调 `wham/usage`，不依赖 Full Disk Access
  - 通过 [SweetCookieKit](https://github.com/steipete/SweetCookieKit) 从 Safari / Chrome / Brave / Edge / Arc / Firefox 等浏览器里读 cookie
  - 通过 `kSecReturnData: true` 真正读 Keychain 里的 OAuth token / API key
  - Codex / OpenAI 走 `https://chatgpt.com/backend-api/wham/usage` 拿主/周额度
  - 只有拿到真实 dashboard/usage 响应的服务才展示订阅档位和价格；未接入 provider 不显示占位 Plus/Pro
- **可扩展的策略链**（P1）：
  - 每个 provider 暴露一组有序 `ProviderFetchStrategy`；Codex 顺序为 OAuth → Cookie → CLI 日志 → Keychain
  - `FetchPipeline` 支持串行 fallback 和并发合并两种模式
  - `TTYCommandRunner` 给交互式 CLI（codex /status、claude /login）提供 PTY
  - `LoginRunner` 一键跳到 Terminal.app 跑 `codex login`
- **TCC 引导**：
  - 仅当浏览器 Cookie 数据源实际需要 Full Disk Access 时，在状态栏菜单顶部显示引导横幅 + 「打开系统设置」按钮
  - SweetCookieKit 的 Keychain 弹框前置提示，告诉用户「Quota Bar 需要授权 Chrome Safe Storage」
- **菜单栏下拉 UI**：
  - 总费用、可用订阅计数、各服务 5 小时 / 周额度条
  - 自动 5 分钟刷新 + 手动「立即刷新」，手动刷新不会关闭 dropdown
  - 状态色彩：可用 = 品牌色，待配置 = 灰色，刷新失败 = 橙色
  - 刷新时间短期显示「4 小时后 / 明天 / 后天」，更远日期显示具体日期
  - 价格按系统语言/地区选择显示货币；简体中文或中国区默认将 USD 订阅价按实时汇率换算成人民币

---

## 支持的 Provider

| Provider | Cookie 读取 | Dashboard 接入 | CLI 路径 | Login 引导 |
|---|---|---|---|---|
| Codex / OpenAI | ✅ chatgpt.com | ✅ wham/usage | ✅ ~/.codex/sessions | ✅ codex login |
| Claude | ✅ claude.ai | 🚧 endpoint 在路上 | ✅ ~/.claude | ✅ claude /login |
| Gemini | ✅ gemini.google.com | 🚧 需要 Vertex AI | ✅ ~/.gemini | ✅ gemini auth login |
| MiniMax | ✅ minimax.chat | 🚧 | — | — |
| Kimi | ✅ kimi.moonshot.cn | 🚧 | — | — |

更多 provider（Cursor / Warp / DeepSeek / Copilot / OpenRouter / Perplexity）仅做 Cookie 探测，dashboard 端点尚未对接，欢迎提 PR。

---

## 要求

- macOS 26 (Tahoe) 或更新
- Swift 6.2 / Xcode 26+
- Full Disk Access（首次启动会提示授权，用于读浏览器 Cookie）

---

## 快速开始

### 安装（推荐）

从 [Releases](../../releases) 页面下载最新的 `QuotaBar-<sha>.dmg`，打开后把 **Quota Bar** 拖进 **Applications**，或在 DMG 窗口里直接双击运行。

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
2. 点开 → 顶部若有橙色横幅 → 点「打开系统设置」授权 Full Disk Access
3. 重启 quota-bar → 在任一支持的浏览器里登录过 Codex / Claude / Gemini 后，菜单里会出现真实额度

### 打包成 .app

```bash
cd quota-bar
./scripts/build-app.sh
```

产物在 `quota-bar/build/QuotaBar.app`，可以拖到 Applications。

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

macOS 把浏览器 Cookie 数据库划在 TCC 的「Full Disk Access」之后，没有公开 API 可以查询授权状态。Quota Bar 用以下两种方式探测：

- **同步探测**：`PrivacyAccessChecker.hasFullDiskAccess()` 尝试打开 `~/Library/Cookies/Cookies.binarycookies`，失败则视为未授权。
- **运行时探测**：SweetCookieKit 在尝试解密 Chrome Cookie 时抛 `BrowserCookieError.accessDenied` → 转成 `ProviderAvailability.fetchFailed` → UI 显示横幅。

授权流程：点「打开系统设置」→ 系统设置 → 隐私与安全性 → 完全磁盘访问权限 → 勾选 Quota Bar → 重启。

### PTY 与登录引导

Codex / Claude 的 TUI 在无 TTY 时会拒绝交互。`TTYCommandRunner` 通过 `/usr/bin/script -q /dev/null` 借一个伪终端。`LoginRunner` 把 `codex login` / `claude /login` 等命令塞进 Terminal.app。

---

## 路线图

- [ ] Claude dashboard endpoint（org 发现 + `/usage` 解析）
- [ ] Gemini Vertex AI 接入
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