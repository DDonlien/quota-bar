import AppKit
import SwiftUI

@MainActor
class StatusBarController: NSObject, NSMenuDelegate {
    private let menu = NSMenu()

    var statusItem: NSStatusItem

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        configureStatusItem()
        configureMenu()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        if let image = NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: "Quota Bar") {
            image.isTemplate = true
            image.size = NSSize(width: 17, height: 17)
            button.image = image
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyDown
        } else {
            button.title = "QB"
        }

        button.toolTip = "Quota Bar"
        statusItem.menu = menu
    }

    private func configureMenu() {
        menu.delegate = self
        menu.autoenablesItems = false
        rebuildMenu()
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        let dashboardItem = NSMenuItem()
        let dashboardView = NSHostingView(rootView: MenuView())
        dashboardView.frame = NSRect(
            x: 0,
            y: 0,
            width: MenuDashboardStyle.width,
            height: MenuDashboardStyle.height
        )
        dashboardView.wantsLayer = true
        dashboardView.layer?.backgroundColor = NSColor.clear.cgColor
        dashboardItem.view = dashboardView
        menu.addItem(dashboardItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(makeMenuItem(title: "立即刷新", systemSymbolName: "arrow.clockwise", action: #selector(refreshNow)))
        menu.addItem(makeMenuItem(title: "偏好设置...", systemSymbolName: "gearshape", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(makeMenuItem(title: "退出", systemSymbolName: "xmark.square", action: #selector(quit), keyEquivalent: "q"))
    }

    private func makeMenuItem(
        title: String,
        systemSymbolName: String,
        action: Selector,
        keyEquivalent: String = ""
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        item.isEnabled = true

        if let image = NSImage(systemSymbolName: systemSymbolName, accessibilityDescription: title) {
            image.isTemplate = true
            image.size = NSSize(width: 14, height: 14)
            item.image = image
        }

        return item
    }

    @objc private func refreshNow() {
        // Static prototype: real refresh behavior will be defined with data sync.
    }

    @objc private func openPreferences() {
        NSSound.beep()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
