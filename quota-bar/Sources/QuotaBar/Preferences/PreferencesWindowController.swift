import AppKit
import SwiftUI

/// Quota Bar 偏好设置窗口控制器（单例）。
///
/// 设计动机：SwiftUI `Settings` scene 在 `.accessory` 菜单栏 app + `AppDelegate`
/// 组合下行为不可靠 —— `NSApp.sendAction(Selector("showSettingsWindow:"), ...)`
/// 会被默默吞掉（responder chain 上没人接，SwiftUI 内部管理的 Settings window
/// 在 .accessory 模式下被阻止显示）。菜单项点击 / ⌘, 之后没有任何反应。
///
/// 修复方案：完全用 AppKit 接管偏好窗口生命周期，SwiftUI 只负责 content。
/// - 首次 `show()` 时 lazy 创建 NSWindow（NSHostingController 包 PreferencesScene）；
/// - `isReleasedWhenClosed = false`：⌘W 关窗后下次 ⌘, 仍能复用同一实例；
/// - 不切换 `setActivationPolicy`：菜单栏 app 保持 `.accessory`，窗口能正常显示在屏幕中央，
///   不弹 dock icon、不出现在 ⌘⇥ 应用切换里。
@MainActor
final class PreferencesWindowController: NSWindowController {
    static let shared = PreferencesWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 580),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "偏好设置"
        // 视觉对齐 macOS 26 系统设置（参考 Vibe Island 复刻）：
        // - titlebar 透明 + fullSizeContentView：traffic light 浮在 sidebar 顶部
        //   （不再有独立 titlebar 分割线）
        // - titleVisibility .hidden：把 title 让给 SwiftUI NavigationSplitView
        //   的 inline toolbar title（`navigationTitle`）
        // - backgroundColor .clear：让 SwiftUI 端 `.regularMaterial` 玻璃背景透出
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = .clear
        window.contentViewController = NSHostingController(rootView: PreferencesScene())
        window.isReleasedWhenClosed = false
        window.center()
        window.identifier = NSUserInterfaceItemIdentifier("QuotaBarPreferencesWindow")
        window.collectionBehavior.insert(.fullScreenAuxiliary)
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("PreferencesWindowController 不支持 NSCoder 初始化")
    }

    /// 显示偏好窗口。如已显示则聚焦到前台；如已关闭则重新 makeKey。
    func show() {
        NSApp.activate(ignoringOtherApps: true)
        guard let window = window else { return }
        if window.isVisible {
            window.makeKeyAndOrderFront(nil)
        } else {
            // 关掉之后 SwiftUI state 仍然在 window 持有的 contentViewController 里，
            // 重新 orderFront 即可，sidebar 选中项 / 开关状态会保留。
            window.makeKeyAndOrderFront(nil)
        }
    }
}
