import SwiftUI
import AppKit
import SweetCookieKit

@main
struct CodingPlanMenuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // 装上 SweetCookieKit 的 Keychain 提示回调。
        // 当浏览器解密 Cookie 时，macOS 会弹「Chrome Safe Storage」授权对话框。
        // 我们希望用户提前知道这是 quota-bar 触发的，而不是某个随机 App。
        BrowserCookieKeychainPromptHandler.handler = { context in
            let alert = NSAlert()
            alert.messageText = "Quota Bar 需要 Keychain 授权"
            alert.informativeText = """
                浏览器 Cookie 解密需要访问「\(context.label)」。
                接下来会弹出系统授权对话框，请允许。
                """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "继续")
            alert.addButton(withTitle: "取消")
            alert.runModal()
        }

        statusBarController = StatusBarController()
    }
}