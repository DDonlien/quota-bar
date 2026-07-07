# Quota Bar

> macOS 菜单栏下拉应用，集中查看多项 AI 服务的订阅费用与额度状态。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![Platform: macOS 26](https://img.shields.io/badge/Platform-macOS%2026-blueviolet)](#requirements)
[![Swift: 6](https://img.shields.io/badge/Swift-6.2-orange)](#requirements)
[![Site](https://img.shields.io/website?url=https%3A%2F%2Fquotabar.ddonlien.com&logo=safari&label=quotabar.ddonlien.com)](https://quotabar.ddonlien.com)

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
  - 偏好设置窗口支持通用、模型、激活、日志、关于页面，可调整刷新间隔、浏览器 Cookie 来源、语言、菜单栏图标模式和 Provider 开关（含 Antigravity）
  - 状态色彩：可用（有真实额度且比例充足）= 绿色，可用但额度告急 = 橙/红，**没有真实额度数据（不管什么原因）= 灰色**，待配置 = 灰色，刷新失败 = 橙色；灰色/蓝色引导文字的下划线规则统一为"灰色都带下划线、蓝色都不带"
  - 刷新时间短期显示「4 小时后 / 明天 / 后天」，更远日期显示具体日期
  - 价格按系统语言/地区选择显示货币；简体中文或中国区默认将 USD 订阅价按实时汇率换算成人民币
  - **名称栏**（左对齐 `ProviderName · TierName`，右对齐 `到期日 货币符号费用/周期`）：
    - TierName 未拿到（非授权流程也拿不到）→ 假设价格/到期日/周期同样拿不到，右侧整块显示灰色下划线「打开 WebView 授权」，点击打开该 provider 的 WebView 登录
    - TierName 拿到但到期日未拿到 → 到期日位置单独显示同样式的「打开 WebView 授权」，价格/周期正常显示
    - 价格未拿到（不区分是真的没有——如 API pay-as-you-go——还是暂未获取）→ 货币符号/费用/周期整组直接不渲染，不再显示「—」占位
  - **额度栏**：非授权流程完全拿不到额度时（provider 只探测到"存在"但额度层还没成功），显示蓝色可点击「打开 WebView 授权」，而不是空白
  - **额度条小标题命名规则**：只有当同一 provider 内多条额度确实是不同 scope 时才显示名称（Kimi 的 Work/Code、MiniMax 的 General/Video）；如果只是同一份额度的不同时间维度（Codex 的 5 小时/周、Claude 的 5 小时/周），就不显示名称，只显示周期标签本身
  - **待配置态**：区分"不清楚是否订阅"和"确定没有订阅"两种确定性——不清楚时（拿数据失败/凭证问题等）只显示一个清爽的「打开 WebView 授权」按钮，不堆原始技术性错误文本；确定没有有效订阅时（服务端明确告知）显示灰色定论文案「未订阅或订阅已过期」，不带按钮
  - **隐藏按钮**：所有还没拿到真实额度数据的 provider（待配置 / 未订阅 / 已过期 / tier-only 空额度）都提供叉图标；点击等同于在 Preferences「模型」页把该 provider 的开关关掉——两者是同一份持久化状态（`PreferencesStore.isEnabled`），任一边改动都会让该 provider 真正停止发起请求，不是只在 dropdown 里视觉隐藏、后台仍正常刷新的假隐藏；已经有真实额度的 provider 不提供这个按钮

---

## 支持的 Provider

---

## 支持的 Provider

当前明确维护的 Provider：Codex、Claude、Kimi、MiniMax、Antigravity、GLM / Z Code。Gemini 已从主动展示路径移除，Google 系配额优先通过 Antigravity 获取。新增 provider 不使用“其他 provider”占位，必须先明确具体名称、安装/凭证/额度/过期日来源。

### 四层获取矩阵（开发基线）

Quota Bar 的刷新链路拆为四层：Provider 获取、额度获取、过期日获取、档位/费用获取。每一层都应保存“上次成功来源索引”，下次刷新优先复查该来源；复查失败后再按本表单元格里的优先级 fallback。归一化始终在最后执行：统一成 `ProviderSnapshot`、`QuotaWindow`、`subscriptionExpiresAt`、`subscriptionTier`、`monthlyPrice` 和明确的 availability。

优先级标记：`P1` 是该 provider 在该层的首选手段，`P2/P3/P4` 依次 fallback；`跳过` 表示明确不执行；`待验证` 表示只能作为调研项，未验证前不得执行或写入可信快照；`弱信号` 表示只能辅助判断，不能单独作为可用订阅或当前状态的依据。每层实际执行前还会先尝试该层的“上次成功来源索引”，成功则跳过同层其余手段。

**来源手段的五级排序**（同一信息层内按此顺序退级，`FetchPipeline.runSequential` 分层合并落地）：

1. **本地 App / RPC**：运行中的本地进程端点（Antigravity language_server / agy）；
2. **本地配置 / 凭证 → API**：读本地 token/API key 直调服务端结构化接口（Codex auth.json、Kimi desktop token、MiniMax config、Z Code config）；
3. **CLI 命令**：真实执行 CLI 并消费结构化输出（`mmx quota show --output json`），让 CLI 自己处理鉴权与刷新；
4. **浏览器 Cookie**：仅显式启用后执行；Safari/Firefox 文件读取在 FDA 授权后静默，Chromium 系默认被 Keychain gate 挡掉（绝不弹窗）；
5. **App WebView 会话**（默认启用，最后一层）：用户在 App 内 WebView 登录一次（`WKWebsiteDataStore.default()` 持久保存），之后所有 dashboard API / headless 抓取静默复用该会话，不碰浏览器、不碰 Keychain。

首个成功来源做基底 snapshot；基底缺层（额度 scope 不全 / 档位 / 价格）时继续用后续来源补齐（例如 Kimi：desktop token 给 Work+档位+日期，CLI OAuth 补 Code 5h/周）。

#### 1. Provider 获取（安装探测）

实现为全 provider 统一顺序（`InstallDetectorProvider.prioritize`）：凭证/配置文件 → App Bundle → CLI 命令 → 环境变量；浏览器登录痕迹与本地 RPC 不参与安装探测。列内每个手段有唯一优先级；同一格里的多个文件/命令属于同类，共享该格优先级、命中即止。

| 可行方案 | Codex | Claude | Kimi | MiniMax | Antigravity | GLM / Z Code |
|---|---|---|---|---|---|---|
| 配置/凭证文件 | P1：`~/.codex/auth.json` | P1：`~/.claude/.credentials.json` | P1：desktop `token-store.json`、`~/.kimi-code/credentials/kimi-code.json`（同类同优先级） | P1：`~/.mmx/config.json`、`~/.mavis/config.yaml`（同类同优先级） | 跳过：无稳定本地凭证文件 | P1：`~/.zcode/v2/config.json`、`~/.zcode/v2/credentials.json`（同类同优先级） |
| App Bundle | P2：可选探测 `Codex.app` | P2：可选探测 `Claude.app` | P2：`com.moonshot.kimichat` | P2：`com.minimax.agent.cn` | P1：`com.google.antigravity` | P2：`dev.zcode.app` |
| CLI 命令存在 | P3：`codex` | P3：`claude` | P3：`kimi` | P3：`mmx`、`minimax`（候选名同类同优先级） | P2：`agy`、`antigravity`（候选名同类同优先级） | P3：`zcode-cli` |
| 环境变量 | 跳过：不作为发现路径 | P4 弱信号：`ANTHROPIC_API_KEY` 只证明 API key | 跳过 | 跳过 | 跳过 | P4 弱信号：`ZHIPUAI_API_KEY` / `BIGMODEL_API_KEY`（归 GLM kind） |
| Browser 登录痕迹 | 跳过：不参与安装探测 | 跳过：同左 | 跳过：同左 | 跳过：同左 | 跳过：同左 | 跳过：同左 |
| 本地 RPC / 进程 | 跳过：不参与安装探测（`codex app-server` 属额度层待验证项） | 跳过 | 跳过 | 跳过 | 跳过：运行中进程只服务额度层 | 跳过 |

#### 2. 额度获取

行顺序即五级来源排序。「显式启用」行不占默认 P 序（启用后插在 App WebView 会话之前执行）。Claude 额外多一行「本地 hook 缓存」——不是通用五级排序的一部分，是该 provider 独有的机制（见下）。

| 可行方案 | Codex | Claude | Kimi | MiniMax | Antigravity | GLM / Z Code |
|---|---|---|---|---|---|---|
| 本地 hook 缓存（Claude 专属，默认最前，用户 opt-in） | 不适用 | **P1（已验证，用户 opt-in）**：注册 Claude Code `statusLine` hook（`~/.claude/settings.json`），捕获其自身渲染终端状态栏时携带的 `rate_limits`（跟官方 `/usage` 面板同一份数据）到本地缓存文件；纯文件读取，零权限、零子进程；不覆盖用户已有 statusLine 配置；缓存超过 6 小时视为陈旧退化到下一层。经开源项目 [ping-island](https://github.com/erha19/ping-island) 源码交叉验证机制，并在本机实测：已安装的 [Vibe Island](https://vibeisland.app/)（同类闭源商用 App）用同一手法写的 `~/.vibe-island/cache/rl.json` 字段形状与本实现完全一致 | 不适用 | 不适用 | 不适用 | 不适用 |
| 本地 App / RPC | 待验证：`codex app-server` → `account/rateLimits/read`（未实现，不占 P 序） | 跳过：已核实无本地 RPC 可用（`claude gateway` 是企业 auth/telemetry 代理需 YAML 配置，非用量查询接口；无 app-server/language_server 等价物，2026-07-06 用 `claude --help` 核实） | 跳过 | 跳过 | P1：language_server / 运行中 agy 进程的本地 gRPC-Web（`RetrieveUserQuotaSummary` + `GetUserStatus`，同类同优先级） | 跳过 |
| 配置/凭证 → API | P1：`auth.json` access token → `chatgpt.com/backend-api/wham/usage` | P2（已验证）：`~/.claude/.credentials.json` 的 `claudeAiOauth.accessToken` → `api.anthropic.com/api/oauth/usage`（`anthropic-beta: oauth-2025-04-20`，字段与 web session 一致；经 CodexBar `ClaudeOAuthUsageFetcher` 交叉验证，2026-07-06 实现）；文件缺失时退化到 Keychain `"Claude Code-credentials"`（同一份 JSON，见 0.10.0-DATA-B-017） | P1：desktop token → `GetSubscription`（Work 额度/档位/价格/续费日；`GetSubscriptionStat` 已被服务端下线仅作兼容）；P2：CLI OAuth → `api.kimi.com/coding/v1/usages`（Code 5h/周，分层合并补 scope） | P1：`~/.mmx/config.json`、`~/.mavis/config.yaml` API key → `api.minimaxi.com/v1/coding_plan/remains`（同类同优先级） | 跳过：无凭证直调云端 API 的路径 | P1：`~/.zcode/v2/config.json` → `zcode-plan/billing/balance`（旧 `api/monitor/usage/quota/limit` 同类兼容 fallback） |
| CLI 命令 | 跳过：`codex /status` 是交互 TUI，不作结构化额度源 | 跳过额度：已核实无结构化额度 CLI（`/usage` 只有交互 TUI，ClaudeBar 为此需接入 SwiftTerm 渲染终端）；`claude auth status --json` 已验证可用但只给登录/档位，见档位表 | 跳过：`kimi /usage` 交互 TUI，暂不驱动 | P2：`mmx quota show --output json`（已验证非 TTY 可用；订阅到期输出 `{"error":...}` → notSubscribed） | P2：拉起临时 agy 会话（等价用户 `agy` + `/usage`）复用其本地 RPC 取结构化额度，取完即退 | 待验证：`zcode-cli` 额度命令未定 |
| 浏览器 Cookie dashboard | 显式启用：chatgpt cookie 兜底 | 显式启用：`organizations → usage` | 显式启用：`GetSubscription` | 显式启用：`coding_plan/remains`（可能受 Cloudflare 限制） | 跳过 | 跳过 |
| App WebView 会话（默认最后一层） | P2：同 dashboard 端点，用 App 会话 cookie | P3（OAuth 配置文件/Keychain 均不可用时兜底，无弹窗）：`organizations → usage`，字段与 OAuth 路径相同（`five_hour`/`seven_day`/`seven_day_sonnet`/`seven_day_opus`，经 CodexBar / Claude-Usage-Tracker 交叉验证，2026-07-06 修复 parser 误认 wrapper key 导致恒空的 bug） | P3：`GetSubscription`（desktop token 缺失时补 Work/档位/价格/日期） | P3：`coding_plan/remains` | 跳过：额度走本地 RPC / CLI | 跳过 |
| 本地日志估算 | 显式启用：`~/.codex/sessions/*.jsonl` 只能估算，不写强快照 | 待验证 | 跳过 | 跳过 | 跳过 | 跳过 |
| 自然语言问询 | 跳过：斜杠命令会被 `--print` 当成 prompt 消耗额度（已实测），永不使用 | 跳过 | 跳过 | 跳过 | 跳过：同 Codex 实测教训 | 跳过 |

#### 3. 过期日获取

| 可行方案 | Codex | Claude | Kimi | MiniMax | Antigravity | GLM / Z Code |
|---|---|---|---|---|---|---|
| 配置文件 / token payload | P1：JWT `chatgpt_subscription_active_until`，**仅未过期时采用**（陈旧即隐藏不误报） | 跳过：`.credentials.json` 的 `expiresAt` 是 access token 有效期（短期、会自动刷新），不是订阅到期日，与 Kimi OAuth `expires_at` 同类陷阱（2026-07-06 经 CodexBar 源码核实） | 跳过：OAuth 不含订阅到期日 | 跳过：config 不含订阅到期日 | 跳过 | 待验证：plan metadata |
| 会话 API（App WebView 会话 → 浏览器 Cookie） | P2：`accounts/check` 的 `entitlement.expires_at`（JSON 稳定，替代 SPA DOM） | 跳过：无已知 billing JSON API | P1：`GetSubscription.nextBillingTime`（desktop token / WebView 会话 / 浏览器 Cookie 同类同优先级；续费日 → 本地自然日减 1 = 最后有效日） | 跳过：`coding_plan/remains` 不返回日期 | 待验证：RPC `GetUserStatus` 是否带 expiry | 待验证 |
| CLI 指令 | 跳过 | 跳过：已核实 `claude auth status --json` 不返回订阅到期日（仅 email/org/subscriptionType） | 跳过：`/usage` 是额度重置，不是订阅到期 | 待验证 | 待验证 | 待验证 |
| Headless DOM（App WebView 会话 → 浏览器 Cookie，didFinish 后 settle 2s） | P3：账单页兜底（hash 路由 SPA 提取不稳定） | P1：`claude.ai/new#settings/billing` | P2：membership 页兜底 | P1：`platform.minimaxi.com/console/plan` | P1：`antigravity.google/settings`（提取成功率待验证） | 待验证：z.ai / Z Code 账号页 |
| 邮件 / 账单文件 | 跳过 | 跳过 | 跳过 | 跳过 | 跳过 | 跳过 |
| 自然语言问询 | 跳过：不用于状态判定 | 跳过 | 跳过 | 跳过 | 跳过 | 跳过 |

#### 4. 档位与费用获取

| 可行方案 | Codex | Claude | Kimi | MiniMax | Antigravity | GLM / Z Code |
|---|---|---|---|---|---|---|
| API 响应字段拿档位 | P1：`wham/usage.plan_type` → Plus/Pro | P1：WebView 会话 organizations/usage 响应（字段待稳定） | P1：`GetSubscription.goods.title`（Andante 等）+ `amounts.priceInCents`（**真实价格，非映射**） | P1：`current_package_name` → TokenPlan/Plus 等 | P1：`GetUserStatus` → tier | P1：`billing/balance` 的 plan 字段 |
| 配置文件拿档位 | P3 弱信号：JWT plan_type（可能陈旧） | **P2（已验证）**：`.credentials.json` 的 `claudeAiOauth.subscriptionType`（如 `"pro"`），与额度请求同一次文件读取 | P2：token-store `currentMembershipLevel` 兜底映射（15 → Andante） | 跳过：config 无档位字段 | 跳过 | P2：config 启用 plan id、`coding-plan-cache.json` 状态（同类同优先级） |
| CLI 拿档位 | 跳过 | P3（已验证）：`claude auth status --json` → `subscriptionType`；`.credentials.json` 通常已带同字段（P2），CLI 只在文件缺失（如仅 Keychain 存储）时兜底 | 跳过 | 待验证：`mmx quota show` 输出的 package 字段未确认 | 跳过：与 API 行同源（RPC 响应） | 待验证 |
| Browser DOM/API | 显式启用：billing 页兜底 | 显式启用：settings 兜底 | 显式启用：membership API 兜底 | 显式启用：user-center 兜底 | 跳过 | 跳过 |
| 费用知识映射 | P2：Plus $20 / Pro $200 → 本地汇率转人民币 | P4：Pro 已映射 $20（官网公开价，2026-07-06 确认）；Max（5x/20x）等更高档位的 `subscriptionType` 具体字符串未经真实账号验证，不猜测映射 | 跳过：真实价格已由 API 返回 | P2：Coding Plan 档位价格表 | P2：Google AI Plus/Pro/Ultra 价格表 | P3：四种 builtin plan → 智谱/Z.ai 价格表 |

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
cd quota-bar/macos
swift run
```

启动后：

1. 状态栏右上角出现「QB」图标（macOS 26）或 `chart.bar.fill` SF Symbol
2. 点开菜单栏图标查看已探测到的本地 App、CLI 或配置文件来源
3. Codex / Kimi / MiniMax / Z Code 使用本地配置、Desktop token 或 OAuth 路径，Antigravity 使用本地 RPC；浏览器 Cookie 不在默认刷新中自动执行

### 跑 site 主页（[quotabar.ddonlien.com](https://quotabar.ddonlien.com) 的本地版）

营销主页是独立 Astro 静态站，按新模板目录规则部署在 `site/` 子项目里。日常不需启动，但 PR 改到主页或新增 provider 卡片时本地预览用：

```bash
cd site
npm install
npm run dev      # 本地预览 http://localhost:4321
npm run build    # 构建到 site/dist/，CI 会把 dist/ 部署到 quotabar.ddonlien.com
```

依赖 `node 20+`（GitHub Actions 用 ubuntu-latest + setup-node@v4 也是 20）。

### 打包成 .app

```bash
cd macos
./scripts/build-app.sh
```

每次运行都会在 `macos/build/` 下生成一个以当前时间命名的子文件夹：

```text
macos/build/
├── 20260620-193559/
│   └── Quota Bar.app
├── latest -> 20260620-193559/
└── ...
```

- 历史版本按时间保留，方便回滚对比
- `build/latest/Quota Bar.app` 是相对软链，始终指向 `build/` 同级时间戳目录中最新的一次构建，适合固定验证入口
- 可以拖到 Applications，或直接从 Finder 双击打开

> 注意：未签名 + 未公证的 .app 第一次启动需要右键 → 打开。

---

## 开发

### 本地 worktree 布局

本机协作环境保留 `main` 在项目根目录，其他长期分支放在单数 `worktree/` 目录下。GitHub Desktop、Codex、其他 Agent 和 IDE 默认打开项目根目录即可识别 repo、读取根文档，并看到其他 worktree。

```text
quota-bar/
├── .git/           # Git 元数据
├── macos/          # main 分支中的 macOS 应用
├── site/           # main 分支中的营销主页
└── worktree/
    └── ...         # 其他分支工作区
```

### 目录结构

```text
.
├── macos/                 # 实际 SwiftPM 包（PascalCase 标识符是 SPM 硬约束）
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
├── site/                       # 营销主页（Astro 静态站，部署到 quotabar.ddonlien.com）
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
cd macos
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
安装探测（withTaskGroup，provider 间并发）
        ↓
┌─ Codex ──────┐  ┌─ Claude ─────┐  ┌─ Kimi ───────┐   ← provider 间并发
│ FetchPipeline │  │ FetchPipeline │  │ FetchPipeline │      （withTaskGroup）
│ Strategy 1    │  │ Strategy 1    │  │ Strategy 1    │
│   ↓ 失败降级   │  │   ↓ 失败降级   │  │   ↓ 失败降级   │   ← provider 内严格顺序
│ Strategy 2    │  │ Strategy 2    │  │ Strategy 2    │      （runSequential，
│   ↓ 分层合并   │  │   ↓ 分层合并   │  │   ↓ 分层合并   │       非并发）
│ ...           │  │ ...           │  │ ...           │
│   ↓           │  │   ↓           │  │   ↓           │
│ 过期日 resolver│  │ 过期日 resolver│  │ 过期日 resolver│
└──────┬────────┘  └──────┬────────┘  └──────┬────────┘
       └──────────────────┴──────────────────┘
                           ↓
              DashboardState → MenuView → 状态栏下拉
```

同一时间，每个 provider 的每一步（安装探测 / 额度获取 / 过期日获取 / 档位与费用获取）都会写一条结构化诊断日志，见下方「获取诊断日志」。

### 获取诊断日志

Preferences → 「日志」页（`DiagnosticsSettingsView`）展示 `ProviderCheckLog` 落盘的记录（`~/Library/Application Support/QuotaBar/provider-check.log`），格式：

```
<yyyy.mm.dd_hh.mm.ss> - <ProviderName> | <CheckStep> | <MethodName> | <成功/失败/跳过> | <详细内容>
```

（2026-07-07 按用户反馈从冒号/逗号混排的旧格式改成管道分隔，把"成败"从自由文本里拆成独立字段，更好扫读。）

- `CheckStep` 对应上面「四层获取矩阵」的四层：`Provider 获取` / `额度获取` / `过期日获取` / `档位与费用获取`。同一次调用如果同时覆盖额度+档位（比如一个 API 响应里两者都有），固定按「额度获取」在前、「档位与费用获取」在后输出（对应矩阵里第 2/4 层的顺序），不按内部枚举的字母序排——否则会出现"看起来先查了档位、才查额度"的错觉。
- `MethodName` 是统一的来源分类标签（`ProviderSourceKind.checkLogLabel` / `SubscriptionExpirySourceKind.checkLogLabel`）：「配置/凭证 → API」「CLI 命令」「本地 App / RPC」「App WebView 会话」「浏览器 Cookie」「Keychain」等，跟 README 五级来源排序用的是同一套词汇；具体是哪个 strategy（如 `kimi-desktop-token`、`claude-oauth`）放在最后的详细内容里写成"来源 `<id>`：..."，不直接拿 id 当 MethodName——id 本身猜不出属于哪一类来源。
- 第四栏是独立的 `成功`/`失败`/`跳过`（明确没有尝试，比如已命中同类候选、该层无来源可配置）三态之一，不用从最后一栏的自由文本里猜。
- 排序规则：同一个 provider 的行总是连续输出（provider 间虽然并发跑，但按 provider 缓冲、该 provider 本轮全部结束才整段落盘）；同一 provider 内部的 check step / method name 按真实执行顺序输出（因为 provider 内部本来就是严格顺序执行，见上面数据流图）。
- 最后一栏如实写明：命中/未命中、是否用了「上次成功来源缓存」、成功拿到的信息摘要、失败原因。
- 日志页停留期间也会实时刷新（`providerCheckLogDidChange` 通知），不需要切一次 Preferences 的 tab 才看到新记录；清空日志后展示区域也不会跟着收缩变窄。
- **执行顺序**：只有当本轮所需的**全部**层（额度 + 档位）的「上次成功来源缓存」一致指向**同一个**来源时，才会把它提到最前单独先试一次；试完无论成败，剩余 strategy 依然按 pipeline 声明顺序完整跑一遍（跳过刚试过的那个，避免同一轮重复调用同一个来源）。层与层之间指向不同来源、或任一层完全没有缓存记录，都视为"信息不全"，直接按声明顺序完整探测，不做任何取巧重排。这条规则本身也是 2026-07-07 用户两次实测纠正后定型的：先发现"缓存让声明靠后的兜底层抢到声明靠前的常规层前面"（改成完全不看缓存），又被纠正"缓存应该优先试、只是失败了才整套重跑"（定型为现在这版）。

### TCC / Full Disk Access

macOS 把浏览器 Cookie 数据库划在 TCC 的「Full Disk Access」之后，没有公开 API 可以查询授权状态。对 Chrome / Edge / Arc / Brave 这类 Chromium 系浏览器来说，拿到 Cookie 数据库文件还不够，Cookie value 往往还需要 Keychain Safe Storage 解密，所以 Full Disk Access 只能解决“读文件”，不能单独替代浏览器/Keychain 授权。Quota Bar 当前默认不执行浏览器 Cookie 读取，避免自动刷新时弹出系统密码或权限弹窗。浏览器路径作为后续显式启用能力保留，调试时可用环境变量打开：

```bash
QUOTABAR_ENABLE_BROWSER_COOKIE=1 swift run
```

启用浏览器路径后，Quota Bar 用以下两种方式探测：

- **同步探测**：`PrivacyAccessChecker.hasFullDiskAccess()` 尝试打开 `~/Library/Cookies/Cookies.binarycookies`，失败则视为未授权。
- **运行时探测**：SweetCookieKit 在尝试解密 Chrome Cookie 时抛 `BrowserCookieError.accessDenied` → 转成 `ProviderAvailability.fetchFailed` → UI 显示横幅。

授权流程：点「打开系统设置」→ 系统设置 → 隐私与安全性 → 完全磁盘访问权限 → 勾选 Quota Bar → 重启。

### Claude Keychain 读取：为什么改走 `/usr/bin/security` CLI

2026-07-07 排查 Claude OAuth 额度获取失败时确认：用户机器上 `claude auth status --json`（CLI 层）能成功返回真实登录态和档位，证明本机登录确实有效；`~/.claude/.credentials.json` 确认不存在；用 `security find-generic-password` 核实过 Keychain 里 `"Claude Code-credentials"` 条目真实存在，service/account 与代码预期完全匹配——但 `ClaudeOAuthUsageProvider` 原本直接调 `SecItemCopyMatching`（`kSecMatchLimitAll` + `kSecReturnData` + `kSecReturnAttributes` 一次性查询）读不到。

对照用户提供的参考项目源码找到关键差异：
- **CodexBar**（`docs/KEYCHAIN_FIX.md` + `ClaudeOAuthCredentials.swift`）把查询拆成两段：先用不带 `kSecReturnData` 的 metadata-only 查询（非交互）挑出最新的一条，再用 `kSecValuePersistentRef` 针对那一条单独查密钥数据（允许弹一次系统授权）。CodexBar 自己的文档写明："one path is a direct secret-data read for the key item, the fallback path is a key/service access query... this is OS/keychain ACL behavior"——不同查询形状（是否要 `kSecReturnData`、是否 `kSecMatchLimitAll`）macOS 会分别记忆授权，混在一次请求里的形状不一定拿得到已授权的信任。
- **ClaudeBar**（`ClaudeCredentialLoader.loadFromKeychain`）压根不走 `Security.framework`，直接 `Process` 调 `/usr/bin/security find-generic-password -s "Claude Code-credentials" -w`。

第二种做法解决了本项目当前更本质的问题：`/usr/bin/security` 是 Apple 签名、CDHash 永远不变的系统二进制；用户点一次「始终允许」，这份信任记在 `/usr/bin/security` 的身份上。而直接在自己进程里调 `SecItemCopyMatching`，信任记在自己 App 的签名身份上——本项目当前是 ad-hoc 签名（`--sign -`），每次 `build-app.sh` 重新构建二进制 CDHash 都会变化，这份信任大概率没法跨构建持久化（跟已知的 TCC/Accessibility 权限持久化问题、v0.12.0 计划迁移 Developer ID 签名要解决的是同一根因类别）。

已改为 `ClaudeKeychainCredentialsReader` 走 `/usr/bin/security` CLI（`ClaudeOAuthUsageProvider.swift`），不再直接调 Security.framework。这个改动本身在当前工具条件下未能用真实打包 app 交互验证是否彻底解决弹窗/持久化问题（需要观察实际系统授权对话框行为），但至少去掉了一个已知会不稳定的具体环节，并且是三个参考实现里两个（CodexBar 概念上、ClaudeBar 直接）都验证过的真实可行路径。

### PTY 与登录引导

Codex / Claude 的 TUI 在无 TTY 时会拒绝交互。`TTYCommandRunner` 通过 `/usr/bin/script -q /dev/null` 借一个伪终端。`LoginRunner` 把 `codex login` / `claude /login` 等命令塞进 Terminal.app。

### 更新策略（ad-hoc 预开发版）

自动更新不依赖 Apple Developer 签名（v0.11.0 阶段全程 ad-hoc）。

版本号规则（2026-07-07 改版）：每个构建的 tag 和 `CFBundleShortVersionString` 都是
`vX.Y.Z-<git-short-sha>`（如 `v0.10.0-dcfff71`）。`X.Y.Z` 来自仓库根目录的
[`VERSION`](./VERSION) 文件，由 Agent 按改动量级判断是否/如何 bump（规则见
[AGENTS.md](./AGENTS.md#版本号维护规则)）；`-<sha>` 只是构建标识，**不参与新旧判断**。
不再区分"stable/nightly 两条通道"——`UpdateChecker` 纯按 `X.Y.Z` 语义化版本号比大小，
完全不看发布时间/构建时间/sha，同一个 `X.Y.Z` 无论打包多少次、时间戳差多少，都不会被
误判成"有更新"（修复了此前一版靠时间戳比较、时区解析错误导致的虚假更新提示）。

1. 「偏好设置 → 关于」打开时后台调 GitHub Releases API 检查一次（5 分钟内不重复请求，也可手动点「检查更新」）；
2. 解析所有 tag 能匹配 `vX.Y.Z(-sha)?` 的 release，取 `X.Y.Z` 最高且严格大于当前版本的那个；
3. 「立即下载并安装」→ 后台下载 dmg 到 `~/Library/Application Support/QuotaBar/updates/` → `hdiutil verify` 校验 → 确认后调 `install-update.sh` helper 替换 `/Applications/Quota Bar.app` 并自动重启；
4. 替换失败时保留旧版并写 `update-error.log`，下次启动提示「上次更新失败」；
5. macOS 权限设置（Full Disk Access 等）更新后**通常会保留**（bundle id `com.taobe.quotabar` 与签名 identifier 稳定），但 ad-hoc 签名下这是 best-effort；Developer ID + notarize 的形式化保障在 v0.12.0 落地；
6. 「稍后提醒」会忽略该版本（自动检查跳过），可在「关于」页「重置已忽略的版本」恢复。

发版：push main 或手动触发 `Release` workflow 都会读取 `VERSION` 文件 + 当前 commit 的
short sha，打一个 `v<VERSION>-<sha>` tag 并发布同名 GitHub Release（写入
`CFBundleShortVersionString`）。

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
