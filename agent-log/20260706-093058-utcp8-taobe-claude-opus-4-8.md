# 用户原始 prompt

> 几个问题：
>
> * webview里不能快捷键粘贴
> * claude、antigravity用webview授权后依旧没有额度，其中agy应该优先走cli获取额度的，其实没必要走到webview；codex授权后也没有获得订阅到期日
> * 本来在main应该有的preference功能在dropdown里被移除了，这个功能是从preferences/main里merge（但没有通过git，ai手动代码merge）进来的
>
> 几个需要你确认的：
>
> * 现在我们是 标准化获取方案 -> 按照readme的逻辑为每个ai进行自定义排序 -> 针对每个ai进行自定义微调细节（quota的cli指令、网址）吗？还是hardcode实现的这些获取功能？
>
> 先跟我确认情况后我告诉你执行哪些

诊断确认后用户补充指令：

> 1. 修复
> 2. 所有的cli路径都应该是cli里执行命令；所有额度都应该遵守我们的5层排序逻辑，也就是按顺序判断是否获取到，没获取到退级；修复webview获取；
> 3. 修复，用这个桥，用json
> 4. 修复
> 5. 架构问题应该修复成这样：
>    1. 确保每一层的信息单独解耦获取
>    2. 确保每一层里的每个方案如实、按照配置顺序执行
>    3. 上述信息在readme里都有
>    4. 每一层针对每个ai的具体执行可以hardcode没关系，本来就很少改

# 启动运行时的分支和版本

- 分支：`main`
- 版本：`1bba4e3` + 前一会话（20260705-215117）未提交改动
- 同步预检：会话环境限制未执行 `git fetch --prune`。

# 任务开始时间

2026-07-06 08:40 +0800（约）

# 任务结束时间

2026-07-06 09:31 +0800

# 任务结束时是否执行了提交

未提交（与前一会话改动一起在工作区，等用户 review）。

# 已阅读上下文

- `README.md` 四层获取矩阵（52-101 行）
- `StatusBarController.swift`（偏好设置菜单项注释处）、`Preferences/PreferencesWindowController.swift`、preferences/main 分支的对应实现
- `BrowserCookieProvider.swift`（全文）、`BrowserCookieReader.swift`、`WKWebViewHeadlessLoader.swift`、`SubscriptionExpirySources.swift`、`CodexHarvester.swift`
- `AntigravityDashboardProvider.swift`（进程发现逻辑）、`agy --help`（确认无 quota 子命令）
- `MiniMaxCLIProvider.swift` / `MiniMaxConfigProvider.swift`
- `main.swift`（确认无 NSApp.mainMenu）

# 对话与行动记录

## 诊断轮（先确认后执行）

1. **WebView 无法粘贴**：accessory app 从不设置 `NSApp.mainMenu`，没有 Edit 菜单 → Cmd+V 无处派发。
2. **Claude/AGY webview 授权后无额度**：App WebView 会话（`WKWebsiteDataStore.default()`）只接到了过期日 headless 抓取，从未接到额度层；Claude 唯一额度来源是默认关闭的浏览器 Cookie 路径，webview 授权对额度零作用。AGY 的「CLI 层」实为发现运行中的 agy/language_server 进程打本地 RPC，`agy` 本身无 quota 子命令。
3. **Codex 授权后无到期日**：webview 会话有被 headless 用上，但 `chatgpt.com/#settings/Billing` 是 hash 路由 SPA，didFinish 时账单 DOM 未渲染，`extract returned nil`。
4. **偏好设置入口消失**：`PreferencesWindowController` 全套功能都在；只是 `StatusBarController` 的菜单项在手动 merge 时被留在注释里，注释还停留在「beep 占位」时代。
5. **架构确认**：标准化的骨架（协议 + pipeline + source 注册表）真实存在，但排序和细节全部 hardcode 在 Swift 里，不是配置驱动。

## 执行轮（用户确认「1 修复 / 2 CLI 真执行 + 5 层退级 + 修 webview / 3 用桥 + JSON / 4 修复 / 5 分层解耦按序执行」）

1. **Edit 主菜单**（`AppDelegate.installMainMenu`）：App + 编辑菜单（撤销/重做/剪切/拷贝/粘贴/全选），target nil 沿响应链派发，WKWebView / NSTextField 均可用。
2. **偏好设置菜单项恢复**：`偏好设置...`（Cmd+,）→ `PreferencesWindowController.shared.show()`。
3. **WebView 会话桥接到额度层**：新增 `AppWebViewSessionCookieReader`（读 `WKWebsiteDataStore.default()`，可注入测试）；`ProviderSourceKind` 新增 `.webViewSession`；Codex / Claude / Kimi / MiniMax 四条管线在 keychain 之前追加 `<kind>-webview` 策略（`BrowserCookieProvider` 复用，零逻辑重复）。Claude 由此获得默认唯一无弹窗额度路径。
4. **Kimi cookie 流程翻新**：`fetchKimiSnapshot` 主请求切到 `GetSubscription`（Work + 档位 + 价格 + 续费日），已下线的 `GetSubscriptionStat` 降为可选兼容；日期带 `.browserAPI/.high` 来源标记。
5. **Codex 到期日 browserAPI**：`SubscriptionExpirySource` 新增可执行的 `SubscriptionExpiryAPIRequest`；resolver 的 `.browserAPI` case 真正执行（会话 Cookie 两级：App WebView 会话 → 浏览器 Cookie）；注册 `codex-accounts-check`（`chatgpt.com/backend-api/accounts/check/v4-2023-04-27` 的 `entitlement.expires_at`，活跃订阅优先、多账号取最晚）为 P1，headless 账单页降为兜底。
6. **headless SPA settle**：`WKWebViewHeadlessLoader` didFinish 后延迟 2s 再提取 outerHTML（超时 task 仍守门）。
7. **MiniMax 真实 CLI 命令层**：新增 `MiniMaxCommandProvider`（`mmx quota show --output json`，候选路径查找 mmx、干净环境执行、超时强杀、剥离非 JSON 噪声、`{"error":...}` no-active-subscription → notSubscribed）；共享解析抽为 `MiniMaxQuotaResponseParser`；接入管线为配置→API 之后第三层。
8. **权威订阅状态优先**：`QuotaFetchError.fallbackPriority` 将 `subscriptionExpired` / `notSubscribed` 提到最高，避免被权限/凭证错误覆盖成「待配置」。
9. **README 矩阵对齐**：矩阵前言新增「来源手段的五级排序」（本地 App/RPC → 本地配置/API → CLI 命令 → 浏览器 Cookie → App WebView 会话）+ 分层合并说明；额度表新增「App WebView 会话」行；Kimi/MiniMax/Codex 各单元格按实现更新（GetSubscription、mmx 已验证、accounts/check P1、DOM 降兜底）。

# 完成工作

- 新包：`macos/build/20260706-093055-main/Quota Bar.app`（`build/latest` 已指向）。
- AGY 额度维持本地 RPC（IDE / agy 进程），不走 webview——与用户「agy 没必要走到 webview」一致；`agy` CLI 无 quota 子命令，进程 RPC 即其 CLI 层。

# 更新的需求 ID

- 新增并完成：`0.10.0-ARCH-B-002`（webview 额度桥）、`0.10.0-ARCH-B-003`（browserAPI 可执行 source + Codex accounts/check）、`0.10.0-ARCH-B-004`（SPA settle）、`0.10.0-ARCH-B-005`（订阅状态错误优先级）、`0.10.0-DATA-B-005`（MiniMax 真实 CLI 层）、`0.10.0-UI-C-001`（Edit 菜单）、`0.10.0-UI-C-002`（偏好设置入口恢复）

# 更新的 README 或 DESIGN 章节

- `README.md`：四层获取矩阵前言新增五级来源排序 + 分层合并说明；额度表新增 App WebView 会话行；Kimi / MiniMax / Codex 过期日与额度单元格按实现更新。
- `DESIGN.md`：未更新。

# 验证方式

- `make test`：134 tests in 31 suites 全部通过（新增 `WebViewSessionBridgeTests`：cookie 域过滤、四管线 webview 层位置、CodexAccountsCheckParser 三态、MiniMaxCommandProvider 四态；更新两处与新行为冲突的旧断言并注明原因）。
- `make app`：成功产包，ad-hoc 签名 + helper + 图标齐全。
- `swift build` 无 error / warning。

# 备注

- 未提交 git commit；工作区同时含前一会话（弹窗/Kimi/到期日/自动更新）与本会话改动。
- `accounts/check` 的响应形状来自社区通用实践，尚未用真实会话验证（用户 webview 已登录 chatgpt，装新包刷新即可见真章）；失败时自动退级 headless（现在带 2s settle）再退级隐藏。
- 架构现状与目标的差距（用户已认可）：分层解耦 + 按序退级已由 `FetchPipeline.runSequential` 分层合并 + 独立 expiry resolver 落地；每层对每个 AI 的具体端点/命令仍 hardcode（用户明确「本来就很少改，没关系」）。
- MiniMax 订阅当前已到期，`mmx` 输出 error 包裹 → UI 应显示「未订阅/已到期」而非待配置；续费后 CLI 成功输出的真实形状若与 remains 不同，`MiniMaxCommandProvider.parseCommandOutput` 会以 transient 退级到配置→API 层，不会误报。
