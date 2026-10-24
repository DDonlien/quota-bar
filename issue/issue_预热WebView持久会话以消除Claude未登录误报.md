# 预热WebView持久会话以消除Claude未登录误报

- ID：`0.10.0-BUG-A-019`。
- 类型：`API`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: claude-webview「未登录」误报的真正根因——WKWebsiteDataStore 冷启动未预热。
- 原稳定 ID：`0.10.0-BUG-A-019`, `0.10.0-INVESTIGATE-A-003`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户对上一条 `0.10.0-INVESTIGATE-A-002` 的结论明确反驳，贴出一段覆盖 11:06–11:58（约 52 分钟、50+ 轮刷新）的完整日志：`claude-webview` 连续约 50 分钟每轮都报"未登录"，用户确认自己全程已经在 App 内 WebView 登录过；直到用户手动重新打开一次登录窗口之后，`claude-webview` 才在当天 11:58:05 首次成功。用户同时提出疑问："之前的某个版本 Claude 能完全正常获取额度、即使不依赖 WebView"，怀疑本轮会话引入了回归。

- [x] [0.10.0-BUG-A-019] 根因定位：全 App 范围内，除了 `WebAuthorizationController.openAuthorization` 这一次性登录窗口外，没有任何代码会创建 `WKWebView` 实例；而 `RefreshCoordinator.start()` 在 `StatusBarController` 初始化时就立即触发第一轮刷新（`AppDelegate.applicationDidFinishLaunching` → `StatusBarController()` → `coordinator.start()`），也就是说冷启动后很可能一次 `WKWebView` 都没创建过，`WKWebsiteDataStore.default()` 背后的 WebKit 网络进程/Cookie 存储从未被真正初始化，`httpCookieStore.allCookies()`（`AppWebViewSessionCookieReader`/`BrowserCookieReader.swift:40`）因此长期停留在"进程未就绪"的空态，即使磁盘上早已持久化了真实登录 Cookie——这跟用户描述的现象（已登录但读不到、手动重开登录窗口后突然恢复）完全吻合。修复：新增 `WebKitSessionWarmup`（`WKWebViewHeadlessLoader.swift`），在 `AppDelegate.applicationDidFinishLaunching` 里于 `StatusBarController()` 构造之前，先创建一个不可见（frame `.zero`、不挂窗口）的 `WKWebView` 并 `await` 一次 `httpCookieStore.allCookies()`，强制该 data store 提前完成初始化——效果等价于用户手动打开一次登录窗口，但不需要用户参与，且发生在第一轮刷新的 Cookie 读取之前 #P0
- [x] [0.10.0-INVESTIGATE-A-003] 排查用户提出的"回归"疑虑："我什么都没改，但之前的版本 Claude 不依赖 WebView 也能正常获取额度"：贴的日志显示 `claude-oauth` 的失败原因在 11:56:27 从"限流，稍后重试"变成了"Claude OAuth token 已过期，请重新 claude login"——这是本地 OAuth token 真实过期（需要用户重新 `claude login`），是账号/凭证的自然状态变化，不是本项目代码在本轮会话里引入的回归。合理的完整解释：用户本地 OAuth token 在今天之前一直有效，`claude-oauth` 一直单独就能覆盖额度，`claude-webview` 这条本来就存在的冷启动 bug 全程处于"从未被真正需要过、所以从未被注意到"的潜伏状态；今天 token 过期后，`claude-oauth` 第一次真正失效，`claude-webview` 变成唯一还有希望的层，这个潜伏已久的 bug 才第一次变得"要命"、被用户观测到——不是回归，是同一个一直存在的 bug 第一次有了被暴露的条件。已在上条一并修复；同时建议用户重新执行一次 `claude login` 刷新真实 OAuth token（`claude-oauth` 仍然是最直接、最快的额度层，WebView 只是兜底）#P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260708-120712-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260708-120712-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 没道理呀，我什么都没改，但你之前的某个版本（我没记错的话，今天凌晨之前的版本。）Claude 能完全正常地获取到额度，即使不依赖 WebView。像我们之前参考的那些 Bar 类的应用，它们也完全不依赖 WebView 就能实现额度获取。
>
> 另外要注意的是，WebView 里面我也已经登录了，只是你没有获取到 WebView 的授权，这是我之前就在跟你说的bug。
>
> 然后重开应用之后，等了一会儿，Claude 就又有额度了。我期间打开过一次 WebView 的那个页面，我不知道是不是有这个的影响。
>
>（贴了一段完整真实诊断日志，2026-07-08 11:06:10 至 11:58:33，覆盖约 50+ 轮刷新周期）

#### 完成工作

- `WKWebViewHeadlessLoader.swift`：新增 `WebKitSessionWarmup`（`@MainActor enum`），创建一个不可见（frame `.zero`、不挂窗口）的 `WKWebView` 并 `await` 一次 `httpCookieStore.allCookies()`，强制 `.default()` data store 提前完成初始化。
- `AppDelegate.swift`：`applicationDidFinishLaunching` 改为在 `Task { @MainActor in ... }` 里先 `await WebKitSessionWarmup.warmUp()`，再构造 `StatusBarController()`（进而触发 `coordinator.start()` 和第一轮刷新）——保证读 Cookie 之前 data store 已经预热过。
- `REQUIREMENTS.md`：新增 `[0.10.0-BUG-A-019]`（根因定位 + 修复）、`[0.10.0-INVESTIGATE-A-003]`（回归疑虑排查结论：不是回归，是同一个潜伏 bug 第一次被暴露），并在 `0.10.0-INVESTIGATE-A-002` 词条后追加一行注明其结论已被推翻。
- 未做：给用户建议重新执行一次 `claude login` 刷新真实 OAuth token（这是账号侧动作，只能建议，不能代劳）。

新包：`macos/build/20260708-120611-main/Quota Bar.app`（`build/latest` 已指向）。

#### 更新的需求 ID

- `[0.10.0-BUG-A-019]` `[0.10.0-INVESTIGATE-A-003]`

#### 验证方式

- `swift build`：无警告无错误。
- `swift test`：186 tests in 42 suites 全部通过（本轮未新增/删除测试——`WebKitSessionWarmup` 直接创建真实 `WKWebView`/`WKWebsiteDataStore`，不适合在单元测试里跑，行为需要用户在真实环境里重新验证）。
- `./scripts/build-app.sh`：产包成功。
- 未做额外的本机独立进程实证测试——检查发现用户当前只有一个 Quota Bar 实例在跑（PID 66993，11:56 启动，大概率就是用户重开后仍在用的那个实例），为了不重复上一轮"多开实例互相干扰"的问题，这次没有再启动一个独立验证进程，改为请用户直接退出现有实例、换成新包重新测试。

#### 备注

- 未提交 git commit。
- 建议用户：(1) 退出当前运行的 Quota Bar 实例，改用新包 `build/latest` 重新启动，验证 Claude 额度是否从第一轮刷新就能通过 WebView 拿到（不需要再手动重开登录窗口）；(2) 顺手执行一次 `claude login` 刷新已过期的 OAuth token，`claude-oauth` 仍然是最快最直接的额度层。
- 这个修复对 `claude-webview`/`minimax-webview`/`kimi-webview`/`codex-webview` 四个 provider 应该都有效——它们共用同一个 `AppWebViewSessionCookieReader`，根因和修复都在读取层，不是某个 provider 专属的问题。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
