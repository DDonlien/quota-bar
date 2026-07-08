# 用户原始 prompt

> 检查现在的代码仓库看是否还有类似的摆设设计
>
>（用户从 4 个选项里选择："你这里的3，我们现在应该没有方案用cookie了才对？" + "接通 advanced.providerTimeoutSeconds" + "删除纯死代码字段"）
>
> 执行并测试，确保不要出现任何问题。尤其是要确保现有的额度获取渠道是正常工作的，并且 WebView 能够按照预期完成它的工作，也就是获取过期日、档位或者金额信息。我目前测试下来，WebView 是不工作的。
>
> 打开 WebView 后，我即使在 Cloud 或者 Anti Gravity 的网站上进行了登录，它还是会提醒我打开 WebView 这个信息，也就是没有获取到任何目标的过期日这些信息。

# 启动运行时的分支和版本

- 分支：`main`
- 版本：`19e5e34`（用户已通过 GitHub Desktop 提交上一轮工作）

# 任务开始时间

2026-07-08 00:55 +0800

# 任务结束时间

2026-07-08 01:45 +0800

# 任务结束时是否执行了提交

否——按惯例留给用户确认后再决定是否提交/推送。

# 已阅读上下文

- `PreferencesStore.swift`/`RefreshCoordinator.swift`/`AppDelegate.swift`/`Strategies.swift`/`WebAuthorizationController.swift`/`MenuView.swift` 全文。
- `BrowserCookieReader.swift`/`EdgeCookieReader.swift`/`WKWebViewHeadlessLoader.swift`/`SubscriptionExpirySources.swift`/`BrowserCookieProvider.swift`/`ProviderFactory.swift` 全文。
- `.build/checkouts/SweetCookieKit` 确认 `BrowserCookieKeychainAccessGate` 是第三方包内部类型。
- 全部相关测试文件（`CodexAuthProviderInspectorThrowTests.swift`/`SubscriptionExpirySourcesTests.swift`/`WKWebViewHeadlessLoaderTests.swift`/`ProviderFetchStrategyTests.swift`）。

# 对话与行动记录

**第一部分：偏好设置摆设字段审计（延续上一轮）**

用户要求排查是否还有类似"刷新间隔"那种看着接通、实际没生效的设置。派了一个只读排查 subagent 系统过一遍 `QuotaPreferences` 全部字段，结果：`providerOverrides.isForcedVisible`、`incidentMonitoringEnabled`、`AdvancedPreferences.currencyCode`/`showResetDates` 都是没有 UI、没有任何运行时消费方的纯死字段；`advanced.providerTimeoutSeconds` 有意图（默认值 30）但从未真正接到 `RefreshCoordinator.providerTimeout`（后者默认值是不同步的 10——跟 `refreshIntervalSeconds` 一模一样的"两份独立副本"bug）；`browserSource`（Cookie 来源选择）的运行时效果被 `AppDelegate.applyBrowserCookieKeychainPolicy()` 一个环境变量挡死。

用户对 browserSource 提出反问："我们现在应该没有方案用 cookie 了才对？"——没有直接采纳我原来"简化成一个开关"的建议，而是让我先确认这个判断。查证 `Strategies.swift` 发现：所有 `-cookie`/`-edge` 策略都被 `browserCookieStrategiesEnabled`（读 `QUOTABAR_ENABLE_BROWSER_COOKIE` 环境变量）包住，且这个环境变量在任何 UI 里都设不了——对真实用户来说这条路径从一开始就是死的，`AppWebViewSessionCookieReader`（App WebView 会话）覆盖同一批 provider/endpoint 且无需 Full Disk Access/Keychain 弹窗，两者功能等价。用户确认后要求：接通 `providerTimeoutSeconds`、删除纯死字段、删除浏览器 Cookie 文件读取整条路径。

**第二部分：WebView 授权不工作（用户报告的真实 bug，优先级更高）**

用户报告登录 Claude/Antigravity 的 WebView 后仍然拿不到到期日/档位/金额。排查前用户已经明确要求"确保不要出现任何问题"，所以先查清楚这个 bug 再动手做删除，避免删除浏览器 Cookie 兜底路径后如果 WebView 本身还有 bug，用户会同时失去两条路径。

排查确认三个真实缺口，都不是"数据丢失"（`FetchPipeline.mergeLayers` 是纯追加逻辑，之前已经验证过这一点不会重新引入）：

1. **Antigravity 架构性缺口**：`antigravityPipeline()` 从来没有注册任何 WebView 会话额度/档位策略（只有 rpc → cli → cli-session → keychain），Antigravity 的 `webAuthorizationURL` 只服务于订阅到期日的 headless DOM 抓取。但 `MenuView.PlanHeader.missingTierNeedsAuth`/`QuotaAuthPromptRow`/`.needsConfiguration` 分支的判断只看 `webAuthorizationURL != nil`，对 Antigravity/Z Code 展示了一个登录了也不可能兑现的"打开 WebView 授权"引导——这正是用户"登录了还是提示"的根因。
2. **登录完不会自动刷新**：`WebAuthorizationController.windowWillClose` 只清理内部字典，从来没有触发任何刷新，用户登录完关掉窗口，看到的还是登录前的失败状态，得等 5 分钟自动周期或自己想起来手动点刷新。
3. **没有 `WKUIDelegate`**：登录页常见的"用 Google 账号登录"等 `window.open()` 弹窗式 SSO，没有 delegate 处理的话 WebKit 会静默丢弃，可能导致登录卡在半途（Antigravity 走 Google 账号尤其容易触发）。

修复了全部三处，然后才继续执行浏览器 Cookie 路径删除。

**第三部分：删除浏览器 Cookie 文件读取路径**

逐个厘清依赖关系后删除：`FilesystemCookieReader`/`EdgeCookieReader.swift`、`BrowserSourcePreference`/`browserSource` 偏好+UI、`browserCookieStrategiesEnabled`/环境变量开关、`AppDelegate.applyBrowserCookieKeychainPolicy()`、四个 pipeline 里的 `-cookie`/`-edge` 策略、`SubscriptionExpiryResolver`/`WKWebViewHeadlessLoader` 的浏览器 Cookie 兜底分支、`Package.swift` 的 `SweetCookieKit` 依赖。第一次 `swift build`（增量）通过，但 `rm -rf .build && swift build`（全量重建）才真正暴露出 `BrowserCookieProvider.swift` 里遗留的 `import SweetCookieKit`——这是本轮唯一一次增量构建"看起来没问题、全量重建才报错"的情况，提醒自己以后大范围删除依赖后要做一次干净重建再下结论。

# 完成工作

**WebView 修复**：
- `WebAuthorizationController.swift`：新增 `ProviderKind.webViewQuotaCapableKinds` 静态集合；新增 `WKUIDelegate`（`createWebViewWith`/`webViewDidClose`）；`windowWillClose` post `.webAuthorizationWindowDidClose` 通知。
- `MenuView.swift`：`missingTierNeedsAuth`/`QuotaAuthPromptRow`/`.needsConfiguration` 分支三处都加上 `webViewQuotaCapableKinds` 检查。
- `RefreshCoordinator.swift`：订阅 `.webAuthorizationWindowDidClose` 触发 `refreshNow()`。

**偏好设置摆设字段清理**：
- `PreferencesStore.swift`：删除 `isForcedVisible`（字段+getter+setter）、`incidentMonitoringEnabled`（字段+setter）、`AdvancedPreferences.currencyCode`/`showResetDates`；新增 `ProviderTimeoutOption` + `setProviderTimeout`/`currentProviderTimeoutOption`。
- `GeneralSettingsView.swift`：新增「Provider 刷新超时」Picker；删除「Cookie 来源」整个 section + binding。
- `StatusBarController.swift`/`RefreshCoordinator.swift`：`providerTimeout` 启动时读取偏好、运行中通过 `applyProviderTimeoutChange()` 同步。

**浏览器 Cookie 路径删除**（11 个源文件 + 2 个测试文件）：
- 删除：`EdgeCookieReader.swift`、`WKWebViewHeadlessLoaderTests.swift`。
- 大改：`BrowserCookieReader.swift`（删 `FilesystemCookieReader`）、`Strategies.swift`（删 `-cookie`/`-edge` 注册 + `cookieReader`/`edgeCookieReader` 参数）、`SubscriptionExpirySources.swift`（`SubscriptionExpiryResolver` 删 `cookieReader` 参数，`sessionCookies`/`loadHeadlessHTML` 只保留 App session 分支）、`WKWebViewHeadlessLoader.swift`（删 `load(url:kind:...)`/`load(url:cookieDomains:...)`，只保留 `loadUsingAppSession`）。
- 小改：`PreferencesStore.swift`、`GeneralSettingsView.swift`、`AppDelegate.swift`、`ProviderFactory.swift`、`BrowserCookieProvider.swift`、`RefreshCoordinator.swift`、`Package.swift`（删 `SweetCookieKit` 依赖）。
- 测试：更新 `CodexAuthProviderInspectorThrowTests.swift`（2 处 `makePipelines` 调用签名）、`SubscriptionExpirySourcesTests.swift`（2 处 `SubscriptionExpiryResolver` 调用签名）。

**文档**：`README.md` 多处更新（五级 → 四级来源排序、删除浏览器 Cookie 相关矩阵行/致谢/目录结构注释、重写 TCC/FDA 章节）；`REQUIREMENTS.md` 新增 6 个任务 ID。

新包：`macos/build/20260708-013538-main/Quota Bar.app`（`build/latest` 已指向）。

# 更新的需求 ID

- `[0.10.0-BUG-A-014]` `[0.10.0-BUG-A-015]` `[0.10.0-ARCH-K-000]` `[0.10.0-ARCH-K-001]` `[0.10.0-CLEAN-A-001]` `[0.10.0-BUG-A-016]`

# 更新的 README 或 DESIGN 章节

- README：功能列表、四级来源排序、额度/过期日两张矩阵表、要求、快速开始、目录结构、日志章节、TCC/FDA 章节、致谢，共约 10 处。
- DESIGN：无改动。

# 验证方式

- `swift build`：增量与 `rm -rf .build` 全量重建均通过（全量重建暴露了一处遗漏的 `import SweetCookieKit`，已修复）。
- `swift test`：178 tests in 41 suites 全部通过（减少 3 个：删除的 `WKWebViewHeadlessLoaderTests.swift` 整体针对已移除路径）。
- `./scripts/build-app.sh`：产包成功。
- 尝试用 computer-use 工具实际点击运行中的 app 验证，但发现同时有 3 个 `Quota Bar` 进程在跑（用户 `/Applications` 里的真实日常使用实例、本次新打的开发包、以及一个 2026-06-30 遗留的旧开发包），继续会有干扰真实登录会话/真实 Cookie 的风险，判断后放弃这条路径，只 kill 掉了自己刚启动的那个开发包实例，没有碰用户的真实实例。**这意味着"登录 Claude/Antigravity 后立即看到额度"这个端到端场景没有用真实交互验证过**——代码逻辑上应该已经解决（Antigravity 不再展示兑现不了的授权引导；Claude/Codex/MiniMax/Kimi 登录完会自动触发刷新），但建议用户自己实际测一次确认。

# 备注

- 未提交 git commit。
- 关于 Antigravity：这次只是不再对用户展示"登录了就能拿到档位"这种不成立的承诺，**没有**新增任何能让 Antigravity 真的通过 WebView 拿到档位/价格的机制——目前没有已知的 antigravity 网页端 JSON API 或稳定 DOM 结构可用，如果之后想让这个真的工作，需要先确认 antigravity.google 后台是否存在可复用的账单/套餐接口。
- 用户应当自测的具体场景：(1) 打开 Claude 的 WebView 登录一次，关闭窗口后不用手动刷新，几秒内 dropdown 应该自动更新；(2) Antigravity 现在应该不再显示"打开 WebView 授权"这个针对档位的提示（除非到期日缺失，那种情况下提示仍然合理，只服务于日期）；(3) Preferences 里新出现的「Provider 刷新超时」选项调大后，Antigravity 这类较慢的 provider 应该更少超时失败；(4)「通用」页里原来的「Cookie 来源」选项已经整个消失，这是预期行为。
