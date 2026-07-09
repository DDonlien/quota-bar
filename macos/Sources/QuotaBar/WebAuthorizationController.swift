import AppKit
import WebKit

@MainActor
final class WebAuthorizationController: NSObject, WKNavigationDelegate {
    static let shared = WebAuthorizationController()

    private var windows: [ProviderKind: NSWindow] = [:]
    /// 登录页常见的 `window.open()` 弹窗（多见于"用 Google/Microsoft 账号登录"这类
    /// SSO 跳转）。没有 `WKUIDelegate` 处理 `createWebViewWith` 的话，这类弹窗请求会
    /// 被静默丢弃——脚本以为窗口打开了，实际上界面上什么都不会出现，登录流程卡在
    /// 半途，用户看到的可能是主窗口一直转圈或者一个"请在弹出的窗口完成登录"的提示
    /// 却永远等不到那个弹窗。2026-07-08 排查"WebView 登录后仍拿不到数据"时确认
    /// 这是一个真实存在的缺口（Antigravity 走 Google 账号登录尤其容易触发）。
    /// 这里用数组强引用防止弹窗随 popup 的临时 WKWebView 一起被提前释放。
    private var popupWindows: [NSWindow] = []

    func openAuthorization(for kind: ProviderKind) {
        guard let url = kind.webAuthorizationURL else {
            NSSound.beep()
            return
        }

        if let window = windows[kind] {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 980, height: 720), configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 980, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(kind.displayName) WebView 授权"
        window.center()
        window.contentView = webView
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.identifier = NSUserInterfaceItemIdentifier(kind.rawValue)

        windows[kind] = window
        webView.load(URLRequest(url: url))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension WebAuthorizationController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        // 弹窗（没有 kind 标识）关闭时只需要清理强引用。
        if let index = popupWindows.firstIndex(where: { $0 === window }) {
            popupWindows.remove(at: index)
            return
        }

        guard let rawValue = window.identifier?.rawValue,
              let kind = ProviderKind(rawValue: rawValue)
        else { return }
        windows[kind] = nil

        // 关闭主授权窗口后立即触发一次刷新——此前这里什么都没做，用户登录完
        // 关掉窗口，dropdown 要么保持旧的失败状态直到下一个自动刷新周期（默认
        // 5 分钟）、要么用户得自己想起来手动点「立即刷新」，体感上跟"登录完全
        // 没用"没区别（2026-07-08 用户实测反馈）。不管这次登录有没有真的成功，
        // 触发一次刷新成本很低、且是用户此刻最可能期待发生的事。
        NotificationCenter.default.post(name: .webAuthorizationWindowDidClose, object: kind)
    }
}

extension WebAuthorizationController: WKUIDelegate {
    /// 处理登录页用 `window.open()` 发起的弹窗（多见于第三方 SSO）。默认没有这个
    /// delegate 方法时，WebKit 会静默丢弃这类请求——脚本发起的窗口永远不会真的
    /// 出现，依赖它完成的登录步骤（比如选择 Google 账号）也就永远卡住。这里新开
    /// 一个共享同一个 `WKWebViewConfiguration`（进而共享 `.default()` cookie
    /// store）的 WKWebView 承接这个请求，保证登录态最终写入的还是同一个
    /// data store，后续 `AppWebViewSessionCookieReader` 才读得到。
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        let width = windowFeatures.width?.doubleValue ?? 640
        let height = windowFeatures.height?.doubleValue ?? 720
        let popupWebView = WKWebView(frame: NSRect(x: 0, y: 0, width: width, height: height), configuration: configuration)
        popupWebView.navigationDelegate = self
        popupWebView.uiDelegate = self

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "登录"
        window.center()
        window.contentView = popupWebView
        window.isReleasedWhenClosed = false
        window.delegate = self

        popupWindows.append(window)
        window.makeKeyAndOrderFront(nil)
        return popupWebView
    }

    /// 页面调用 `window.close()`（常见于 SSO 弹窗完成登录后自行关闭）时同步关掉
    /// 对应的 NSWindow，不留一个空壳窗口。
    func webViewDidClose(_ webView: WKWebView) {
        guard let window = popupWindows.first(where: { $0.contentView === webView }) else { return }
        window.close()
    }
}

extension Notification.Name {
    /// App 内 WebView 授权窗口关闭。`object` 是对应的 `ProviderKind`。
    /// `RefreshCoordinator` 订阅它触发一次刷新，见该类型里的说明。
    static let webAuthorizationWindowDidClose = Notification.Name("com.quotabar.webAuthorizationWindowDidClose")
}

extension ProviderKind {
    var webAuthorizationURL: URL? {
        switch self {
        case .codex, .openai:
            return URL(string: "https://chatgpt.com/")
        case .claude:
            return URL(string: "https://claude.ai/")
        case .kimi:
            return URL(string: "https://www.kimi.com/")
        case .minimax:
            return URL(string: "https://www.minimax.io/")
        case .antigravity:
            return URL(string: "https://antigravity.google/g1-upgrade")
        case .zcode:
            return URL(string: "https://z.ai/")
        case .opencode:
            // `/auth` 已登录时 302 到 `/workspace/{lastSeenWorkspaceID}`、未登录时进
            // 登录流程（`routes/auth/index.ts`）——两种状态都落在正确的页面上。
            return URL(string: "https://opencode.ai/auth")
        default:
            return nil
        }
    }

    /// `Strategies.swift` 里真正注册了「用 `AppWebViewSessionCookieReader` 读取会话
    /// Cookie → 调 dashboard JSON API 拿档位/价格/额度」这条策略（`xxx-webview`）的
    /// provider 集合——目前是 codex/claude/minimax/kimi。Antigravity 和 Z Code
    /// 虽然也有 `webAuthorizationURL`（能打开登录窗口），但那个窗口只服务于订阅
    /// 到期日的 headless DOM 抓取（见 `SubscriptionExpirySources`），完全没有接入
    /// 任何能解出档位/价格的 dashboard 接口——对这两个 provider 来说，登录完
    /// WebView 并不会让缺失的档位/价格出现。
    ///
    /// 这是 2026-07-08 用户实测反馈"登录 WebView 后 Antigravity 仍然提示需要授权"
    /// 时定位到的根因：`MenuView.PlanHeader.missingTierNeedsAuth` 之前只看
    /// `webAuthorizationURL != nil` 就展示"打开 WebView 授权"，没有像
    /// `canOfferWebAuthorizationForDate` 那样先确认这条能力真的存在——对 Antigravity
    /// 来说这个提示从一开始就是个不可能兑现的承诺。修改 `Strategies.swift` 里对应
    /// pipeline 的 `-webview` 策略时，必须同步维护这个集合，否则两边会像
    /// `refreshIntervalSeconds` 那次一样出现"看着接通了、实际没有"的漂移。
    static let webViewQuotaCapableKinds: Set<ProviderKind> = [.codex, .openai, .claude, .minimax, .kimi, .opencode]

    /// Provider kinds where Quota Bar accepts a **manually pasted** API key（在
    /// 「偏好设置 → 模型」页有对应的输入框）：MiniMax（`MiniMaxConfigProvider`，写
    /// `~/.mavis/config.yaml`）、Z Code（`ZCodeManualKeyStore`，写 Quota Bar 自己的
    /// `zcode-api-key.json`，见该类型顶部说明）。跟 `webViewQuotaCapableKinds` 一样
    /// 是手动维护的能力声明——新增/移除一个 provider 的手动 key 输入支持时要同步改
    /// 这里，否则 dropdown 里的引导文案会跟实际能力脱节（2026-07-08 用户反馈"agy/
    /// opencode/zcode 为什么不显示打开 WebView 授权"时定的这套两级判断规则）。
    static let apiKeyCapableKinds: Set<ProviderKind> = [.minimax, .zcode, .opencode]

    /// 授权补救途径，按用户 2026-07-08 定的优先级排列：FDA（伤害性最小且一次性，
    /// 目前未实现，永远不会出现在结果里）> WebView（App 内一次性登录，见
    /// `webViewQuotaCapableKinds`）> API Key（手动粘贴，见 `apiKeyCapableKinds`）。
    enum AuthRemediationTier {
        case webView
        case apiKey
    }

    /// 这个 provider 实际可用的授权补救途径，按上面的优先级排好序——只包含真正
    /// 实现了的能力，没有的 tier（目前是 FDA）不会出现在列表里。
    ///
    /// 背景：用户反馈 Antigravity 在非授权途径（本地 CLI/RPC）全部失败后，dropdown
    /// 显示"未获取到授权"——但 Antigravity 既不支持 WebView 额度会话（登录窗口只服务
    /// 于到期日抓取，见 `webViewQuotaCapableKinds` 顶部说明）也不支持手动 API Key，
    /// 也就是说根本没有任何授权补救动作可以提示用户去做，"未获取到授权"这句话是
    /// 一个兑现不了的承诺。用这个数组的「是否为空」来判断：为空就不该展示任何"去
    /// 授权"文案，只能诚实展示"暂无额度数据"（跟 opencode 这类纯 BYOK provider 现有
    /// 的展示逻辑保持一致，见 `QuotaAuthPromptRow`）。
    ///
    /// 注：这里只解决"该展示哪个 tier 的入口文案"，不实现"如果优先级更高的 tier
    /// 已经完成授权但还是拿不到额度，就展示下一个 tier"这层更细的升级判断——那需要
    /// 单独追踪"每个 tier 是否已经完成授权"的状态，目前的 `QuotaFetchError`/
    /// `ProviderAvailability` 还没有为此建模，先按优先级固定展示第一个可用 tier。
    var availableAuthRemediationTiers: [AuthRemediationTier] {
        var tiers: [AuthRemediationTier] = []
        if webAuthorizationURL != nil && ProviderKind.webViewQuotaCapableKinds.contains(self) {
            tiers.append(.webView)
        }
        if ProviderKind.apiKeyCapableKinds.contains(self) {
            tiers.append(.apiKey)
        }
        return tiers
    }

    /// 该 provider 的手动 API Key 是否已经真实配置（占位符不算）。
    /// 各 kind 读各自的 key 存储，跟「偏好设置 → 模型」页 `APIKeyConfigRow`
    /// 展示"已配置"状态用的是同一套判断。
    var manualAPIKeyIsConfigured: Bool {
        switch self {
        case .minimax:
            if case .configured = MiniMaxConfigProvider.currentKeyState() { return true }
            return false
        case .zcode:
            return ZCodeManualKeyStore.currentKeyState().isConfigured
        case .opencode:
            return OpenCodeManualKeyStore.currentKeyState().isConfigured
        default:
            return false
        }
    }

    /// 按优先级返回第一个**还没完成授权**的补救 tier；全部已完成（或本来就没有任何
    /// tier）返回 nil——nil 意味着 UI 不该再展示任何"去授权"引导，只能显示
    /// "暂无额度数据"这类终态文案。
    ///
    /// 这是用户 2026-07-08 规则里"如果上一个授权形式完成了授权但没有获取到额度，
    /// 就提示下一个；全部授权完了才显示没有额度信息"那一层的落地（此前只实现了
    /// "按优先级展示第一个可用 tier"，不看它是否已经完成——2026-07-09 用户实测
    /// opencode 保存 key 后 dropdown 依然提示"在 Preferences 中通过 API Key 授权"，
    /// 命中的正是这个缺口）：
    /// - `.webView` 已完成 = App 内 WebView 会话存储里有该 provider dashboard 域的
    ///   Cookie（跟 `claude-webview` 等策略判断"已登录"是同一个检查）；
    /// - `.apiKey` 已完成 = 对应的手动 key 存储里有真实 key（见上）。
    func firstPendingAuthRemediationTier() async -> AuthRemediationTier? {
        for tier in availableAuthRemediationTiers {
            switch tier {
            case .webView:
                let authorized = await WKWebViewHeadlessLoader.appSessionHasCookies(for: dashboardCookieDomains)
                if !authorized { return .webView }
            case .apiKey:
                if !manualAPIKeyIsConfigured { return .apiKey }
            }
        }
        return nil
    }
}
