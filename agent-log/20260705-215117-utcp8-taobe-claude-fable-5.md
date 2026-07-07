# 用户原始 prompt

> 先阅读这个仓库，然后：
>
> 1. 修复错误：
> 1. 打出来的包还是在弹窗要权限
> 2. kimi的work的额度还是没有
> 3. kimi, codex, minimax的到期日都查不出来（我的minimax应该是过期了，今天）
>
> 检查所有分支上的所有agent-log里的对话，看看
> - 最后一个被我确认kimi的work额度正确的是哪个分支的哪个包
> - 最后一个被我确认kimi、minimax、codex日期正确的是哪个分支的哪个包
> - 最后一个被我确认没有尝试弹窗的问题的是哪个分支的哪个包
>
> 用现有的代码，结合你认为的最优实践，配合我在sub/main设计的分组分层获取方案，确保现在定义的5个agent的4种信息（安装情况、额度、过期日、档位和费用）都能在最多只让用户进行常规（系统菜单里）一次性操作正确获取到
> 2. 添加不需要apple签名的应用更新功能，我们之前应该有所定义，但你也可以按照最优实践来

# 启动运行时的分支和版本

- 分支：`main`
- 版本：`1bba4e3`（Restore browser prompt removal and app icon build）
- 同步预检：会话环境限制未执行 `git fetch --prune`；本地工作区开始时干净。

# 任务开始时间

2026-07-05 20:30 +0800（约）

# 任务结束时间

2026-07-05 21:55 +0800

# 任务结束时是否执行了提交

未提交（改动全部在工作区，等用户 review）。

# 已阅读上下文

- `AGENTS.md` / `README.md` / `REQUIREMENTS.md`（全量）
- 全部 7 个分支的 agent-log（按 blob 去重后 144 个文件，重点精读 2026-06-30 ~ 07-05 的 sub/main、sub/expiry、main 日志）
- `macos/Sources/QuotaBar/` 关键源码：Strategies、ProviderFetchStrategy、RefreshCoordinator、SubscriptionExpirySources、WKWebViewHeadlessLoader、KimiDesktopTokenProvider、KimiAuthProvider、DashboardEndpoints、MiniMaxCLIProvider、MiniMaxConfigProvider、CodexAuthProvider、BrowserCookieReader、PrivacyAccessChecker、AppDelegate、MenuView、PreferencesStore、AboutSettingsView
- SweetCookieKit 源码（`.build/checkouts`）：`BrowserCookieKeychainAccessGate`、`ChromeCookieImporter`
- 本机运行时证据：`~/Library/Logs/QuotaBar.log`、`~/Library/Application Support/QuotaBar/{provider-sources,snapshots}.json`
- 真实接口探测（只读，不落敏感值）：Kimi `GetSubscriptionStat`（404）/ `GetSubscription`（200 含 balances）、Kimi `coding/v1/usages`（desktop token 401）、Codex `wham/usage`（plus 生效）、Codex OAuth refresh（refresh_token_reused，确认不可自行 refresh）、`mmx quota`（no active token plan subscription）

# 对话与行动记录

## 一、agent-log 排查结论（三项「最后确认正确」）

1. **Kimi Work 额度**：sub/main 分支，包 `quota-bar/build/20260702-221845/QuotaBar.app`（基于 6fe1b70 + 未提交修复，后提交为 c3f11a6）。用户在 20260702223030 日志 prompt 里确认「kimi额度对了，订阅名称有了」。数据路径 = KimiDesktopTokenProvider 复合请求 GetSubscriptionStat（Work+Code）+ GetSubscription（订阅名/价格）。
2. **三家日期**没有单一「全对」的包，分别为：
   - MiniMax：sub/expiry 分支，包 `build/20260630-234xxx`（14945f6 + 未提交 source pipeline，后提交为 9ecb46e）。用户在 20260701001745 prompt 确认「minimax对的（到期日/最后有效日）」，来源是 headless 平台页 + FDA 授权后的浏览器 Cookie。
   - Kimi：sub/main c3f11a6 时期（20260702223030 会话修复为 GetSubscription.nextBillingTime 减 1 天）后未再被投诉，但也没有明确确认。
   - Codex：从未有活跃订阅日期被确认；最接近的是 sub/main c266f6e 时期 20260702013307 日志中 CodexSubscriptionInspector 输出「到期 2026/6/25」被认定为 inspector 的正确输出（但 auth.json 陈旧，续费后不更新）。
3. **无弹窗**：sub/main 分支，包 `quota-bar/build/20260702-163447/QuotaBar.app`（afc75b1 + 未提交修复，后提交为 6fe1b70）。用户在 20260702170822 prompt 确认「弹窗不跳了」。关键修复 = 默认 pipeline 移除浏览器 Cookie strategy。

## 二、三个 bug 的根因

1. **弹窗回归**：main 合并 sub/expiry 后，`RefreshCoordinator.enrichWithSubscriptionExpiry` 每轮刷新对每个 available snapshot 跑 headless 过期日抓取，`WKWebViewHeadlessLoader` 用 `FilesystemCookieReader`（SweetCookieKit）按 `Browser.defaultImportOrder` 读浏览器 Cookie —— Chromium 系解密要读 Keychain 的 "Chrome Safe Storage"，触发系统密码弹窗。1bba4e3 只移除了「预授权提示注册」，没有移除触发源。
2. **Kimi Work 缺失**：Kimi 服务端于 2026-07 前后**下线了 `GetSubscriptionStat`（404）**。KimiDesktopTokenProvider 以它为主请求 → 整体失败 → 回落 CLI OAuth（Code-only、Trial 档、无日期）。本机实测确认 Work 额度数据已迁移到 `GetSubscription.balances[]`（FEATURE_OMNI，amountUsedRatio）。
3. **三家日期查不出**：
   - Kimi：同上（日期在 GetSubscription.nextBillingTime，主请求 404 后拿不到）；
   - Codex：`auth.json` JWT 的 `chatgpt_subscription_active_until` 停在 6/25（用户 7/1 续费但 CLI 未刷新缓存），代码正确地拒绝展示过期日期 → 无日期；headless 兜底因 Cookie 弹窗/未登录失败；refresh_token 已被 CLI 轮换，App 不可自行 refresh；
   - MiniMax：订阅**今天（2026-07-05）到期**，`coding_plan/remains` 返回 `no active token plan subscription`，旧代码映射成「待配置」而不是「订阅已过期」。

## 三、修复实现（全部落在 main 工作区）

1. **弹窗（0.9.0-SEC-A-001）**：`AppDelegate` 启动即设 `BrowserCookieKeychainAccessGate.isDisabled = true`（SweetCookieKit 自带开关，Chromium 解密直接失败而不弹窗），仅用户在偏好设置显式选 Chrome 才放开；偏好变化时重新应用。Safari/Firefox 文件 Cookie 在 FDA 授权后仍可静默读取——这就是「最多一次系统设置常规操作」。
2. **Kimi（0.2.0-DATA-B-028）**：`KimiSubscriptionParser.parse` 新增从 `balances[]` 解析 Work 月额度；`KimiDesktopTokenProvider` 主请求切到 `GetSubscription`（Work + Andante 档位 + ¥49/月 + nextBillingTime→减 1 天 = 7/8 最后有效日，带 `.api/.high` 来源标记），`GetSubscriptionStat` 降级为兼容路径。
3. **分层合并（0.10.0-ARCH-B-000）**：`FetchPipeline.runSequential` 实现分组分层获取：首个成功来源做基底，后续 strategy 只补缺失层（quota scope / plan）；新增 `expectedQuotaScopes`（Kimi = work+code），Code 5h/周由 CLI OAuth 合并进 desktop token 基底。
4. **过期日 resolver（0.10.0-ARCH-B-001）**：snapshot 已带日期直接采用（修复「有日期还去跑 headless」的 bug）；headless 优先 App 自有 WebView 会话（`WKWebsiteDataStore.default()`，WebAuthorizationController 一次登录后永久静默），浏览器 Cookie 退居其次且默认无弹窗。
5. **MiniMax（0.10.0-DATA-B-004）**：`no active token plan subscription` 映射为 `.notSubscribed`，UI 显示订阅失效而非「待配置」。
6. **UI（0.10.0-UI-C-000）**：dropdown 中「有额度但缺日期且日期依赖 headless 订阅页」的 provider（Codex/MiniMax 等），价格左侧显示「授权获取日期」可点击引导。
7. **自动更新（v0.11.0，无 Apple 签名）**：
   - `UpdateChecker.swift`：GitHub Releases API（10s 超时、403 限流文案、5min 抑制）、semver/nightly 双通道比较（stable 永远优先）、后台下载 + 进度、`hdiutil verify` 校验、helper 安装、忽略版本 + 重置；
   - `scripts/install-update.sh`：等进程退出（5s 超时强杀）→ 挂载 dmg → `codesign --verify`（ad-hoc 阶段跳过 spctl）→ 备份替换 `/Applications/Quota Bar.app` → 失败回滚 + 写 `update-error.log` → 重新拉起；`--dry-run` 支持；随包分发在 `Contents/Resources/`；
   - `build-app.sh`：`VERSION` 环境变量严格校验（garbage 立即 fail）、写 `CFBundleShortVersionString`、打包 helper；
   - `release.yml`：`workflow_dispatch` 传 `version=vX.Y.Z` 走 semver 稳定版发布，push main 保持 nightly；
   - `AboutSettingsView`：完整状态机 UI（检查/可更新/下载进度/校验/安装/已最新/错误 + best-effort 文案）；
   - `AppDelegate` 启动检测 `update-error.log` 弹「上次更新失败」；
   - `PreferencesStore` 新增 `lastUpdateCheck` / `ignoredVersions`（Codable 向后兼容）。

# 完成工作

- 新包：`macos/build/20260705-215039-main/Quota Bar.app`（`build/latest` 已指向）。
- 5 agent × 4 信息矩阵（默认零弹窗）：安装探测（全部本地）；额度（Codex=auth.json、Kimi=desktop token+CLI 分层合并、MiniMax=CLI/API key、AGY=本地 RPC（需 IDE/CLI 运行）、Z Code=本地 API（服务端当前返回空余额））；档位/费用（同源）；过期日（Kimi=API、Codex/MiniMax=WebView 一次授权或 FDA+Safari、MiniMax 当前正确显示「订阅已到期」）。

# 更新的需求 ID

- 新增并完成：`0.2.0-DATA-B-028`、`0.9.0-SEC-A-001`、`0.10.0-DATA-B-004`、`0.10.0-ARCH-B-000(+test)`、`0.10.0-ARCH-B-001`、`0.10.0-UI-C-000`
- v0.11.0 勾选 37 项（CI-A-000..004+test、ARCH-A-000..003、TOOL-A-000..005、FE-A-000..012、UI-A-000..004、DOC-A-000/001），4 项带实现偏差备注（helper 位置、nightly 比较依据、稍后提醒语义、CI-A-002-test 手动验证）；QA 项与部分自动化测试项保留未勾选。

# 更新的 README 或 DESIGN 章节

- `README.md`：新增「更新策略（ad-hoc 预开发版）」章节。
- `AGENTS.md`：技术栈与命令新增「发版流程（ad-hoc 预开发版）」。
- `DESIGN.md`：未更新。

# 验证方式

- `make test`：125 tests in 28 suites 全部通过（新增 FetchPipelineLayeredMergeTests、KimiSubscriptionParserBalancesTests、UpdateCheckerTests、MiniMaxSubscriptionMappingTests）。
- `make app`：成功产包，`codesign --verify --deep --strict` 通过，helper 以可执行权限存在于 Resources，`CFBundleIconFile=QuotaBar`。
- `VERSION=garbage/v0.11.0/空` 三种打包路径手动验证 Info.plist 写入正确。
- `install-update.sh --dry-run` 与错误路径（缺参数=64、dmg 不存在=1）手动验证；dry-run 不写 error log。
- 真实接口探测确认 Kimi 新 schema 解析规则与线上响应一致（Andante / ¥49 / nextBillingTime 7/9 → UI 7/8 / Work amountUsedRatio=1）。

# 备注

- 未提交 git commit，改动等用户 review。
- Codex 活跃订阅的续费日**没有无弹窗的本地来源**（auth.json JWT 会陈旧、refresh token 不能动、wham/usage 不带日期）；正确日期需用户点一次「授权获取日期」在 App 内 WebView 登录 chatgpt.com，之后永久静默。陈旧 JWT 日期在订阅活跃时会被正确隐藏（不误报）。
- Antigravity 额度依赖本地运行中的 IDE language_server 或 agy 会话进程；两者都不在时显示待配置是符合设计的。
- Z Code 服务端对 Start plan 返回空余额（coding_plan_not_entitled ×3），额度层待服务端有数据后自动恢复。
- 本机 `provider-sources.json` / `snapshots.json` 未清理；新逻辑会在下次刷新时自然覆盖 kimi 缓存。
- 更新功能的 E2E（真实 GitHub release 下载替换）需要 main 推送产出新 nightly 后在真机验证（v0.11.0-QA-A-000/001 未勾选）。
