# sub/main: 偏好设置摆设字段全面审计 + WebView 授权修复 + 移除浏览器 Cookie 文件读取

- ID：`0.10.0-BUG-A-014`。
- 类型：`ARCH`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 偏好设置摆设字段全面审计 + WebView 授权修复 + 移除浏览器 Cookie 文件读取。
- 原稳定 ID：`0.10.0-BUG-A-014`, `0.10.0-BUG-A-015`, `0.10.0-ARCH-K-000`, `0.10.0-ARCH-K-001`, `0.10.0-CLEAN-A-001`, `0.10.0-BUG-A-016`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户要求排查代码仓库里是否还有类似"刷新间隔"那种看着接通实际没用的摆设设置。审计（含一个只读排查 subagent）发现：`providerOverrides.isForcedVisible`、`incidentMonitoringEnabled`、`advanced` 的 `currencyCode`/`showResetDates` 都是没有 UI、没有消费方的纯死字段；`advanced.providerTimeoutSeconds` 有意图但从未接通到 `RefreshCoordinator.providerTimeout`（同一类"两份独立副本"问题）；`browserSource`（Cookie 来源选择）唯一的运行时效果被一个没有 UI 的环境变量挡死，对真实用户完全不可达。用户确认后要求：接通 `providerTimeoutSeconds`、删除纯死字段，并追问 browserSource 对应的浏览器 Cookie 文件读取路径是否已经被 App WebView 授权会话取代——核实后确认两者功能等价，用户要求直接删除浏览器 Cookie 文件读取整条路径，只保留 WebView 会话。
>
> 在执行删除前，用户报告了一个更紧急的真实 bug："打开 WebView 后即使登录了 Claude/Antigravity，仍然提示需要打开 WebView 授权，拿不到到期日/档位/金额"。排查确认这不是数据丢失（`FetchPipeline.mergeLayers` 纯追加，不会清空已成功的层），而是三个真实缺口：(1) Antigravity 的 pipeline 里根本没有注册任何 WebView 会话额度/档位策略——`missingTierNeedsAuth`/`QuotaAuthPromptRow` 只看 `webAuthorizationURL != nil` 就展示授权引导，对 Antigravity/Z Code 这种登录了也拿不到档位的 provider 是个兑现不了的承诺；(2) `WebAuthorizationController` 关闭授权窗口后不会触发任何刷新，用户登录完看到的还是登录前的失败状态；(3) 没有 `WKUIDelegate` 处理登录页常见的 `window.open()` 弹窗式 SSO，可能导致某些登录流程卡在半途。

- [x] [0.10.0-BUG-A-014] `ProviderKind.webViewQuotaCapableKinds` 新增静态集合（`WebAuthorizationController.swift`），显式声明哪些 provider 真的注册了能解出额度/档位的 WebView 会话策略（codex/claude/minimax/kimi）；`MenuView.PlanHeader.missingTierNeedsAuth`、`QuotaAuthPromptRow`、`.needsConfiguration` 分支三处判断都改为同时检查这个集合，不再对 Antigravity/Z Code 展示一个登录了也没用的"打开 WebView 授权"引导 #P0
- [x] [0.10.0-BUG-A-015] `WebAuthorizationController` 关闭主授权窗口时 post 新通知 `.webAuthorizationWindowDidClose`；`RefreshCoordinator` 订阅并调用 `refreshNow()`，登录完关掉窗口立即触发一次刷新，不用等 5 分钟自动周期或自己想起来手动刷新 #P0
- [x] [0.10.0-ARCH-K-000] `WebAuthorizationController` 新增 `WKUIDelegate` 实现（`createWebViewWith`/`webViewDidClose`），承接登录页用 `window.open()` 发起的 SSO 弹窗（尤其 Google 账号登录常见）；此前没有这个 delegate，WebKit 会静默丢弃这类弹窗请求，脚本以为窗口打开了，实际登录流程可能卡在半途 #P1
- [x] [0.10.0-ARCH-K-001] 彻底移除浏览器 Cookie 文件读取路径：删除 `FilesystemCookieReader`（Safari/Chrome/Firefox 真实文件读取，基于 SweetCookieKit）、`EdgeCookieReader.swift`（SQLite 直读）、`BrowserSourcePreference`/`browserSource` 偏好及其 UI、`browserCookieStrategiesEnabled`/`QUOTABAR_ENABLE_BROWSER_COOKIE` 环境变量开关、`AppDelegate.applyBrowserCookieKeychainPolicy()`、`Strategies.swift` 四个 pipeline 里的 `-cookie`/`-edge` 策略注册；`SubscriptionExpiryResolver`/`WKWebViewHeadlessLoader` 的浏览器 Cookie 兜底分支一并移除，只保留 App WebView 会话（`AppWebViewSessionCookieReader`）单一路径；`Package.swift` 移除 `SweetCookieKit` 依赖。核实过这条路径此前被环境变量挡死、对真实用户不可达，且和 App WebView 会话功能完全重叠，删除无回归风险 #P1 — 更新 `CodexAuthProviderInspectorThrowTests.swift`/`SubscriptionExpirySourcesTests.swift` 的调用签名，删除已整体过时的 `WKWebViewHeadlessLoaderTests.swift`（3 个测试全部针对被删除的浏览器 Cookie 入口路径）
- [x] [0.10.0-CLEAN-A-001] 删除纯死代码：`ProviderOverride.isForcedVisible`（无 UI、无消费方）、`incidentMonitoringEnabled`（同上）、`AdvancedPreferences.currencyCode`/`showResetDates`（同上）及各自的 getter/setter #P2
- [x] [0.10.0-BUG-A-016] 接通 `advanced.providerTimeoutSeconds`：新增 `ProviderTimeoutOption` 离散选项（10/15/20/30 秒，跟 `RefreshIntervalOption` 同一设计）+ `PreferencesStore.setProviderTimeout`/`currentProviderTimeoutOption`；`GeneralSettingsView` 新增「Provider 刷新超时」Picker；`StatusBarController`/`RefreshCoordinator` 启动时读取、运行中通过 `applyProviderTimeoutChange()` 实时同步——此前这个字段有意图（默认值 30，`RefreshCoordinator.providerTimeout` 默认值却是不同步的 10）但从未接通，跟 `refreshIntervalSeconds` 是同一类 bug #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260708-014500-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260708-014500-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 检查现在的代码仓库看是否还有类似的摆设设计
>
>（用户从 4 个选项里选择："你这里的3，我们现在应该没有方案用cookie了才对？" + "接通 advanced.providerTimeoutSeconds" + "删除纯死代码字段"）
>
> 执行并测试，确保不要出现任何问题。尤其是要确保现有的额度获取渠道是正常工作的，并且 WebView 能够按照预期完成它的工作，也就是获取过期日、档位或者金额信息。我目前测试下来，WebView 是不工作的。
>
> 打开 WebView 后，我即使在 Cloud 或者 Anti Gravity 的网站上进行了登录，它还是会提醒我打开 WebView 这个信息，也就是没有获取到任何目标的过期日这些信息。

#### 完成工作

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

#### 更新的需求 ID

- `[0.10.0-BUG-A-014]` `[0.10.0-BUG-A-015]` `[0.10.0-ARCH-K-000]` `[0.10.0-ARCH-K-001]` `[0.10.0-CLEAN-A-001]` `[0.10.0-BUG-A-016]`

#### 验证方式

- `swift build`：增量与 `rm -rf .build` 全量重建均通过（全量重建暴露了一处遗漏的 `import SweetCookieKit`，已修复）。
- `swift test`：178 tests in 41 suites 全部通过（减少 3 个：删除的 `WKWebViewHeadlessLoaderTests.swift` 整体针对已移除路径）。
- `./scripts/build-app.sh`：产包成功。
- 尝试用 computer-use 工具实际点击运行中的 app 验证，但发现同时有 3 个 `Quota Bar` 进程在跑（用户 `/Applications` 里的真实日常使用实例、本次新打的开发包、以及一个 2026-06-30 遗留的旧开发包），继续会有干扰真实登录会话/真实 Cookie 的风险，判断后放弃这条路径，只 kill 掉了自己刚启动的那个开发包实例，没有碰用户的真实实例。**这意味着"登录 Claude/Antigravity 后立即看到额度"这个端到端场景没有用真实交互验证过**——代码逻辑上应该已经解决（Antigravity 不再展示兑现不了的授权引导；Claude/Codex/MiniMax/Kimi 登录完会自动触发刷新），但建议用户自己实际测一次确认。

#### 备注

- 未提交 git commit。
- 关于 Antigravity：这次只是不再对用户展示"登录了就能拿到档位"这种不成立的承诺，**没有**新增任何能让 Antigravity 真的通过 WebView 拿到档位/价格的机制——目前没有已知的 antigravity 网页端 JSON API 或稳定 DOM 结构可用，如果之后想让这个真的工作，需要先确认 antigravity.google 后台是否存在可复用的账单/套餐接口。
- 用户应当自测的具体场景：(1) 打开 Claude 的 WebView 登录一次，关闭窗口后不用手动刷新，几秒内 dropdown 应该自动更新；(2) Antigravity 现在应该不再显示"打开 WebView 授权"这个针对档位的提示（除非到期日缺失，那种情况下提示仍然合理，只服务于日期）；(3) Preferences 里新出现的「Provider 刷新超时」选项调大后，Antigravity 这类较慢的 provider 应该更少超时失败；(4)「通用」页里原来的「Cookie 来源」选项已经整个消失，这是预期行为。

### 20260703191614-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260703191614-utcp8-gpt5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> webview是一个单独的浏览器吗？似乎有一些mfa授权问题，另外你站点没挑对吧……光弹窗倒是实现了
> 另外agy为啥需要webview之前有别的手段能获取到额度呀
>
> 而且agy按照我们之前的设计，本地rpc之后的顺序应该是cli？cli我确定可用的
>
> webview不是应该移除，而是按照我们之前那个流程设计是最后优先级
>
> 你应该再检查一遍这个想的很好的四层设计是不是有真的实现

#### 完成工作

- `AntigravityDashboardProvider` 新增 `ProcessMode`：
  - `.languageServer`：只找 IDE/language_server。
  - `.cli`：只找 `agy` CLI 进程。
  - `.any`：保持兼容。
- `Strategies.antigravityPipeline()` 调整为 RPC → CLI → Keychain。
- `ProviderFetchStrategyTests` 新增 Antigravity pipeline 顺序测试。
- `README.md` 四层矩阵更新 AGY CLI 额度层说明。
- `REQUIREMENTS.md` 新增 `0.2.0-DATA-B-028`，并修正 `0.9.0-DATA-A-006` 的 WebView 最后优先级语义。
- 打包新版本：`quota-bar/build/20260703-191601/QuotaBar.app`。

#### 更新的需求 ID

- `0.2.0-DATA-B-028`
- `0.9.0-DATA-A-006`

#### 验证方式

- `agy models`
  - 结果：成功列出 Gemini / Claude / GPT-OSS 模型。
- `curl -sk POST https://127.0.0.1:59941/.../RetrieveUserQuotaSummary`
  - 结果：HTTP 200，返回 Gemini weekly 0%、Claude/GPT weekly 100% 等结构化额度。
- `cd quota-bar && env CLANG_MODULE_CACHE_PATH=.build/clang-module-cache SWIFT_MODULE_CACHE_PATH=.build/swift-module-cache swift test --disable-sandbox`
  - 结果：通过，65 个 Swift Testing 测试通过。
- `cd quota-bar && ./scripts/build-app.sh`
  - 结果：通过，生成 `/Users/taobe/Projects/GitHub/Personal/quota-bar/worktree/sub-main/quota-bar/build/20260703-191601/QuotaBar.app`。

#### 备注

- 四层设计当前是“部分实现”：来源索引、快照缓存、strategy 层声明已经存在；但 provider/quota/expiration/plan 还没有被执行器拆成四个真正独立的刷新任务。
- WebView 当前仍是授权窗口，尚未变成可复用的 Web dashboard strategy。

### 20260703190832-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260703190832-utcp8-gpt5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 很奇怪的是，菜单栏里有agy的额度，但是下拉里显示没有，我不知道是哪里错了？
> web view的功能似乎也还没实现，我的想法是下拉里支持webview的如果没获取到，提供一个可点击的文本引导用户打开webview浏览器授权

#### 完成工作

- 修复 AGY 菜单栏/下拉状态不一致的误导性展示。
- 新增 WebView 授权容器基础能力，支持 Codex/OpenAI、Claude、Kimi、MiniMax、Antigravity、Z Code 的登录页入口；Antigravity 后续需标为备用入口，不作为主额度链路。
- 新增 `StatusBarControllerTests` 覆盖 `needsConfiguration` 不绘制菜单栏占位 bar。
- 更新 `REQUIREMENTS.md`：
  - `0.2.0-FE-A-010`
  - `0.9.0-DATA-A-006`
- 打包新版本：`quota-bar/build/20260703-190820/QuotaBar.app`。

#### 更新的需求 ID

- `0.2.0-FE-A-010`
- `0.9.0-DATA-A-006`

#### 验证方式

- `cd quota-bar && env CLANG_MODULE_CACHE_PATH=.build/clang-module-cache SWIFT_MODULE_CACHE_PATH=.build/swift-module-cache swift test --disable-sandbox`
  - 结果：通过，64 个 Swift Testing 测试通过。
- `cd quota-bar && ./scripts/build-app.sh`
  - 结果：通过，生成 `/Users/taobe/Projects/GitHub/Personal/quota-bar/worktree/sub-main/quota-bar/build/20260703-190820/QuotaBar.app`。

#### 备注

- 当前 WebView 只完成“用户可点击打开并持久登录”的授权容器；各 provider 后续还需要新增 Web dashboard strategy，才能用该 WebView session 隐式请求额度/过期日。

### 20260618165946-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260618165946-utcp8-mavis.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 Prompt

- 上一轮决策：license=MIT（默认）, cookie=SweetCookieKit（推荐）, tcc=detect+UI引导（推荐）
- 用户目标：先完成 P0 + P1，并把项目公开给社区用，但属于个人项目

#### 3. 验证构建

- `swift build` → Build complete!（0.86s）
- `swift run` 启动 4s 不崩溃

#### 验证方式

- `swift build` 通过
- `swift run` 启动后 4 秒存活
- 待续：完成 P0 后用真实 cookie / CLI / Keychain 数据回归

#### 备注

- LICENSE 默认采用 MIT，若用户要求换 Apache 2.0 / BSD-3 跟我说一声
- main 工作区现在还残留一些 .build/ 编译产物修改（git status 里能看到），与本次工作无关
