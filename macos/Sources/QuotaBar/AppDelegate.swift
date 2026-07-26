import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        Self.installMainMenu()
        // 必须先于 `StatusBarController()`（内部会立即 `coordinator.start()` 触发
        // 第一轮刷新）完成——见 `WebKitSessionWarmup` 顶部说明：冷启动后如果没有
        // 任何 WKWebView 被创建过，`WKWebsiteDataStore.default()` 的 Cookie 存储
        // 可能长期读不到已持久化的登录态，导致 claude-webview 等一直误报"未登录"。
        // 试用起点要在任何 UI 读取授权状态之前落盘，否则第一次启动时
        // 「关于」「激活」两个页面会各自算出一个略有偏差的起点。
        LicenseManager.shared.refreshState()

        Task { @MainActor in
            await WebKitSessionWarmup.warmUp()
            statusBarController = StatusBarController()
            notifyIfLastUpdateFailed()
            // 复验放在最后、且是 fail-open 的：它既不该拖慢启动，也不该在
            // 网络不通时影响任何既有功能（见 `LicenseManager.revalidateIfDue`）。
            await LicenseManager.shared.revalidateIfDue()
        }
    }

    /// v0.11.0-TOOL-A-004：helper 替换失败会写 update-error.log；
    /// 启动时检测并提示一次，然后清除标记。
    private func notifyIfLastUpdateFailed() {
        guard let detail = UpdateChecker.consumeUpdateErrorLog() else { return }
        let alert = NSAlert()
        alert.messageText = "上次更新失败"
        alert.informativeText = "Quota Bar 上次自动更新未完成，当前仍在运行旧版本。\n\n\(detail.trimmingCharacters(in: .whitespacesAndNewlines))"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "知道了")
        alert.runModal()
    }

    /// accessory（LSUIElement）app 默认没有 `NSApp.mainMenu`，macOS 的
    /// Cmd+C / Cmd+V 等快捷键靠菜单项 keyEquivalent 派发给第一响应者——
    /// 没有 Edit 菜单，WebView 授权窗口、偏好设置输入框都无法粘贴。
    /// 菜单栏本身不可见（accessory 不显示菜单栏），只为快捷键派发服务。
    static func installMainMenu() {
        let mainMenu = NSMenu()

        // App 菜单（占位，保证 Edit 不是第一项）
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "退出 Quota Bar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // Edit 菜单：标准编辑动作，target 为 nil → 沿响应链派发（WKWebView / NSTextField 都响应）
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "编辑")
        editMenu.addItem(withTitle: "撤销", action: Selector(("undo:")), keyEquivalent: "z")
        let redoItem = NSMenuItem(title: "重做", action: Selector(("redo:")), keyEquivalent: "Z")
        redoItem.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(redoItem)
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "剪切", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "拷贝", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        NSApp.mainMenu = mainMenu
    }
}
