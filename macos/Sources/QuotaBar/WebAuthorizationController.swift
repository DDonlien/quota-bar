import AppKit
import WebKit

@MainActor
final class WebAuthorizationController: NSObject, WKNavigationDelegate {
    static let shared = WebAuthorizationController()

    private var windows: [ProviderKind: NSWindow] = [:]

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
        guard let window = notification.object as? NSWindow,
              let rawValue = window.identifier?.rawValue,
              let kind = ProviderKind(rawValue: rawValue)
        else { return }
        windows[kind] = nil
    }
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
        default:
            return nil
        }
    }
}
