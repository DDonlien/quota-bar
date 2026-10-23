# feat/subscription-expiry: 接入 Codex 真实订阅到期日

- ID：`0.6.0-DATA-B-000`。
- 类型：`DATA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页） / feat/subscription-expiry: 接入 Codex 真实订阅到期日。
- 原稳定 ID：`0.6.0-DATA-B-000`, `0.6.0-DATA-B-001`, `0.6.0-DATA-B-001-test`；不改写或重编号这些既有 ID。

## 当前需求与范围

> Codex (chatgpt.com) 的 `/backend-api/wham/usage` 只返回 quota 窗口，**不返回订阅到期日**。需要 headless 抓 `chatgpt.com/account/manage` 或 `chatgpt.com/settings/billing` 页面，提取「Next billing date」「Renewal date」之类 DOM 文本。

- [x] [0.6.0-DATA-B-000] `CodexHarvester` 实现：用 `WKWebViewHeadlessLoader` 加载 `https://chatgpt.com/#settings/Billing`，DOM 提取续费日期；找不到返回 nil；超时/Cloudflare challenge 失败时 source 管线降级 #P1
- [x] [0.6.0-DATA-B-001] `RefreshCoordinator` 在 Codex quota snapshot 成功后通过独立 source 管线补 `subscriptionExpiresAt`；日期失败不影响额度展示 #P1
- [x] [0.6.0-DATA-B-001-test] 单元测试：mock HTML（含"Next billing on July 25, 2026"等常见模式）验证 `CodexHarvester` 解析出正确 `Date` #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260702145131-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260702145131-utcp8-gpt5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 光codex不够，我需要一个：
> 首先设计一套完整链路
> 然后针对每个模型，设计：哪些节点可以跳过；每个节点需要如何特殊处理（比如有的cli是/usage，有的是/quota，如果用浏览器，每个网址不一样）

#### 完成工作

- 更新 `REQUIREMENTS.md`，新增需求 ID：
  - `0.9.0-ARCH-B-000`
  - `0.9.0-ARCH-B-001`
  - `0.9.0-ARCH-B-002`
  - `0.9.0-ARCH-B-003`
  - `0.9.0-ARCH-B-004`
  - `0.9.0-ARCH-B-005`
  - `0.9.0-ARCH-B-006`
- 形成统一获取链路和 provider 能力矩阵设计，将在回复中交付。

#### 更新的需求 ID

- `0.9.0-ARCH-B-000` 至 `0.9.0-ARCH-B-006`

#### 验证方式

- 文档变更，无构建验证。
- 使用 `rg` / `sed` 检查现有 pipeline、provider metadata 和需求上下文。

#### 备注

- 本次未改 Swift 实现代码。
- 工作区仍存在未跟踪日志文件，未进行 git add/commit。

### 20260628004500-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260628004500-utcp8-mavis.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 你接下来在feat-subscription-expiry这个branch工作，进入对应worktree，完成这个需求

#### 用户意图梳理

用户给的方向性指令——"在 feat-subscription-expiry branch 工作，进入对应 worktree，完成这个需求"。
本会话开头先：
1. 列了 5 个候选方案让用户选范围
2. 用户选了 "all-five"（当前 worktree 全做 5 个），违反 branch marker doc 建议的"每个 provider 独立 sub-worktree"，但用户拍板就这么干

#### 设计决策

**集成点**：harvester 调用放在 `RefreshCoordinator.runRefreshCycle` 的 per-provider task 内
- quota fetch 完成后 `await enrichWithHarvester(snapshot, kind:)` 短超时跑 harvester
- 不放在 BrowserCookieProvider 里，因为 AntigravityDashboardProvider 走独立路径；统一在协调器层处理所有 provider 更合理
- 失败兜底：harvester 任何错误（cookie 读不到 / permission / transient / 超时 / 找不到日期）→ 返回原 snapshot，UI hide

**harvester 超时**：6s（比 `providerTimeout=10s` 略短，因为 headless 加载订阅页一般 3-5s，且整个 refresh cycle 尾延迟 = max(providerTimeout, harvesterTimeout)，不能过长拖累 5min 自动刷新节奏）

**extract 策略**：context-aware 而非纯 firstDate
- 每个 harvester 列出"真正表示续费"的关键词（"Next billing"、"Renews on"、"到期日" 等）
- 关键词附近 100 字符窗口内找日期，找不到就 nil（**不 fallback 到无关键词的 firstDate**，避免抓到无关日期）
- 在 `SubscriptionDateHarvester` 协议扩展里加了 `extractNear(keywords:candidates:window:in:)` helper

**parseLooseDate 增强**：发现 Claude / Cursor 测试里 ISO 8601 date-only（"2026-12-15" 没时间部分）没被解析，补上 `yyyy-MM-dd` UTC 解析

**Test 设计**：每个 harvester 的测试只测 `extract(from:)` 纯函数（mock HTML 字符串），不动 WKWebView。
WKWebViewHeadlessLoader 的集成测试已有"cookie 入口失败路径"覆盖；真实加载依赖 macOS window server，无法在 CI 测。

#### 验证

- `cd quota-bar && swift build` → Build complete! (10.69s)
- `cd quota-bar && swift test` → Test run with 59 tests in 10 suites passed after 0.010 seconds
- 全部 59 个测试通过（20 个原有 + 39 个新加）

#### 完成工作

- v0.6.0-DATA-B（Codex）3 个任务全部勾选完成
- v0.6.0-DATA-C（Claude）3 个任务全部勾选完成
- v0.6.0-DATA-D（Cursor）3 个任务全部勾选完成
- v0.6.0-DATA-E（MiniMax）3 个任务全部勾选完成
- v0.6.0-DATA-F（Antigravity）3 个任务全部勾选完成
- 5 个 harvester 全部实现 + 测试通过 + RefreshCoordinator 集成完毕
- build / test 双绿

#### 更新的需求 ID

- [0.6.0-DATA-B-000] [0.6.0-DATA-B-001] [0.6.0-DATA-B-001-test]
- [0.6.0-DATA-C-000] [0.6.0-DATA-C-001] [0.6.0-DATA-C-001-test]
- [0.6.0-DATA-D-000] [0.6.0-DATA-D-001] [0.6.0-DATA-D-001-test]
- [0.6.0-DATA-E-000] [0.6.0-DATA-E-001] [0.6.0-DATA-E-001-test]
- [0.6.0-DATA-F-000] [0.6.0-DATA-F-001] [0.6.0-DATA-F-001-test]

共 15 个 task 勾选完成。

#### 验证方式

- `cd quota-bar && swift build` 通过（10.69s）
- `cd quota-bar && swift test` 通过（59 tests, 10 suites, 0.010s）
- 真实 headless 加载效果需要本地 macOS 跑 `swift run` + 浏览器登录态验证（CI 沙盒没 window server，无法测）

#### 已知 trade-off（用户可感知的限制）

1. **DOM 模式是猜测的** — 我没真实访问 `chatgpt.com/account/manage` / `claude.ai/settings/plan` / `cursor.com/dashboard` / `minimaxi.com/user-center/payment/balance` / `antigravity.google/settings` 抓 HTML 样本。当前 5 个 harvester 的 keywords + dateCandidates 都是基于：
   - ChatGPT / Cursor 等公开文档提到的字段名
   - OpenAI / Anthropic / Cursor / MiniMax UI 截图见过的文本模式
   - 类似订阅管理页（Google One、Stripe Customer Portal、Netlify Billing）的通用模式

   真实环境跑出来如果 regex 不命中，harvester 会返回 nil（UI hide）。这是设计契约：找不到就 nil，**不 throw，不污染主 pipeline**。

2. **Antigravity 路径不确定** — Antigravity 是 Google 系 IDE，订阅管理页可能在 `antigravity.google/settings`，也可能要跟 Google 账号 OAuth 跳转到 `accounts.google.com`。当前实现只抓 `antigravity.google/settings`。如果实际不在该路径，需要调整 pageURL。

3. **Cursor 路径不确定** — Cursor dashboard 也可能用 client-side 渲染（React + CSR），headless 抓到的 HTML 是 React bootstrap 而不是 SSR，关键词可能在 hydration 之后才出现。当前实现只等 `didFinish` 就抓 outerHTML，没等 React 渲染完。如果实际抓不到，需要在 `WKWebViewHeadlessLoader` 加 "等关键 DOM 出现" 的逻辑。

4. **MiniMax i18n 不确定** — MiniMax 主体面向中文用户，页面用「到期日 / 续费日期 / 下次扣费」；如果用户切到英文（"Next billing on"），harvester 也支持。如果页面用了不在这两组关键词里的文案，会返回 nil。

5. **集成点位置** — 把 harvester 放在 `RefreshCoordinator.runRefreshCycle` 意味着每次 5min 自动刷新都会跑一次 harvester（即使 quota 没变化）。可以接受，因为 harvester 是异步、不阻塞主流程，失败就 nil。

#### 后续可优化方向（不在本次范围）

- 用户实测抓不到时，把真实 DOM 贴过来 → 调 regex；
- `WKWebViewHeadlessLoader` 加 network-idle / DOM-mutation-observer 等更智能的等待；
- harvester 结果加 `RefreshCoordinator` 的缓存层（同一 provider 5min 内不重复抓）；
- Antigravity 路径可能需要跟 accounts.google.com OAuth 重定向。

### 20260702170822-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260702170822-utcp8-gpt5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

```text
- codex好了
- 弹窗不跳了
- 你似乎不会问我要任何权限，比如完全磁盘之类的，是用不到？我以为完全磁盘可以代替浏览器授权访问到浏览器的本地缓存？
- kimi 之前cli没登陆，登陆后5h和week额度政策，但work不行
- z code还是没额度
```

#### 完成工作

- 新增 `KimiDesktopTokenProvider`：读取 Kimi Desktop token-store 的 access token，调用 `GetSubscriptionStat`，解析 Work、Code 5h、Code week、订阅档位、月费和到期日。
- 更新 Kimi pipeline：Desktop token-store 优先，CLI OAuth 作为 Code-only fallback；浏览器 Cookie 只在显式环境变量启用后作为兜底。
- 新增 `ZCodePlanCacheProvider`：读取 Z Code coding plan cache，展示 available plan 与不可用原因；没有额度数值时不伪造 quota。
- 更新 Z Code pipeline：API provider 优先，plan-cache 状态兜底，再到 Keychain。
- 更新 `README.md`：记录 Kimi Desktop token 路径、Z Code plan-cache 兜底、Full Disk Access 与 Chromium Keychain 解密边界、四层矩阵优先级。
- 更新 `REQUIREMENTS.md`：登记 Kimi Desktop token 与 Z Code plan-cache 两条用户可见需求。
- 更新 `scripts/build-app.sh`：SwiftPM 构建使用仓库内 module cache，并使用 `--disable-sandbox`，避免在当前沙箱里写用户级 Swift/clang 缓存失败。
- 生成新版 app：`quota-bar/build/20260702-170758/QuotaBar.app`，`build/latest` 已指向该版本。

#### 更新的需求 ID

- `0.2.0-DATA-B-025`
- `0.4.0-DATA-A-006`

#### 验证方式

- `cd quota-bar && env CLANG_MODULE_CACHE_PATH=.build/clang-module-cache SWIFT_MODULE_CACHE_PATH=.build/swift-module-cache swift test --disable-sandbox`
  - 结果：59 tests in 15 suites passed。
- `cd quota-bar && ./scripts/build-app.sh`
  - 结果：生成 `build/20260702-170758/QuotaBar.app`。
- `cd quota-bar && codesign --verify --deep --verbose=2 build/latest/QuotaBar.app`
  - 结果：valid on disk，satisfies its Designated Requirement。
- `cd quota-bar && plutil -p build/latest/QuotaBar.app/Contents/Info.plist`
  - 结果：`CFBundleIdentifier = com.taobe.quotabar`，`LSUIElement = true`。

#### 备注

- 本次未提交。
- 当前 worktree 仍包含本轮之前已经存在的未提交改动和多条历史 agent log。

### 20260619011202-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260619011202-utcp8-gpt5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

其他的ai都不行，你可以访问cli和terminal直接帮我build，帮我解决现在quota bar的问题：没办法正确货渠道电脑上的ai的情况，参考codex bar是怎么做的，而且现在一直要full disk access，明显不合理

#### 验证方式

- `cd drop-down-test/CodingPlanMenu && swift build`：通过。
- `cd drop-down-test/CodingPlanMenu && ./build-app.sh`：通过，生成 `QuotaBar.app`。
- 已关闭旧进程并通过 `open .../QuotaBar.app` 启动新构建，进程 PID 为 `91907`。

#### 需求更新

- `DA-A-005` 标记完成：菜单不再展示 `.notInstalled` snapshot。
- `UI-C-005` 文案更新为“浏览器 Cookie 数据源缺 Full Disk Access 时按需显示引导”。

#### 备注

- 工作区已有 `.build/`、`.DS_Store` 等构建产物变更；本轮运行 build 后这些文件继续保持 dirty。未回滚这些已有/构建生成的文件。
- 当前未实现 Codex OAuth token refresh；若 token 过期，会提示重新 `codex login`。
