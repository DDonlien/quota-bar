import SwiftUI
import AppKit

@MainActor
class StatusBarController: NSObject {
    private let dropdownSize = NSSize(width: 286, height: 462)

    var statusItem: NSStatusItem
    var dropdownWindow: NSWindow?
    var clickMonitor: Any?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "creditcard.fill", accessibilityDescription: "Coding Plan")
            button.action = #selector(toggleMenu)
            button.target = self
        }
    }

    @objc func toggleMenu() {
        if let window = dropdownWindow, window.isVisible {
            closeWindow()
        } else {
            showWindow()
        }
    }

    func showWindow() {
        if let window = dropdownWindow {
            window.setIsVisible(true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: dropdownSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .statusBar
        window.isReleasedWhenClosed = false
        window.isMovable = false
        window.isMovableByWindowBackground = false

        let glass = NSGlassEffectView()
        glass.cornerRadius = 14
        glass.style = .regular
        glass.clipsToBounds = true
        glass.frame = NSRect(origin: .zero, size: dropdownSize)
        glass.autoresizingMask = [.width, .height]

        let menuView = MenuView(closeAction: { [weak self] in
            self?.closeWindow()
        })
        let hostingController = NSHostingController(rootView: menuView)
        hostingController.view.frame = glass.bounds
        hostingController.view.autoresizingMask = [.width, .height]
        glass.contentView = hostingController.view

        window.contentView = glass
        dropdownWindow = window

        positionWindow(window)
        NSApp.activate(ignoringOtherApps: true)
        window.setIsVisible(true)
        window.makeKeyAndOrderFront(nil)

        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let window = self?.dropdownWindow, window.isVisible {
                let clickLocation = NSEvent.mouseLocation
                if !NSPointInRect(clickLocation, window.frame) {
                    self?.closeWindow()
                }
            }
        }
    }

    func closeWindow() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
        dropdownWindow?.setIsVisible(false)
    }

    func positionWindow(_ window: NSWindow) {
        guard let button = statusItem.button, let screen = button.window?.screen ?? NSScreen.main else {
            if let mainScreen = NSScreen.main {
                window.setFrameOrigin(NSPoint(x: mainScreen.frame.midX - 125, y: mainScreen.frame.midY - 222))
            }
            return
        }

        let buttonFrameInWindow = button.convert(button.bounds, to: nil)
        let buttonFrameOnScreen = button.window?.convertToScreen(buttonFrameInWindow) ?? buttonFrameInWindow
        let screenFrame = screen.visibleFrame

        let windowWidth = dropdownSize.width
        let windowHeight = dropdownSize.height
        let gap: CGFloat = 4

        var originX = buttonFrameOnScreen.midX - windowWidth / 2
        var originY = buttonFrameOnScreen.minY - windowHeight - gap

        originX = max(screenFrame.minX + 8, min(originX, screenFrame.maxX - windowWidth - 8))
        if originY < screenFrame.minY + 8 {
            originY = buttonFrameOnScreen.maxY + gap
        }

        window.setFrameOrigin(NSPoint(x: originX, y: originY))
    }
}
