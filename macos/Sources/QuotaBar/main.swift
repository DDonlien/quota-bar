import AppKit

// Quota Bar 进程入口。
//
// 之前用 SwiftUI `App` 协议 + `@NSApplicationDelegateAdaptor` 启动，但这条路在
// 菜单栏 accessory app 下有连锁问题：
//   1. SwiftUI 启动时主动创建第一个 Window/Settings scene，弹出空窗口；
//   2. `NSApp.sendAction(Selector("showSettingsWindow:"), ...)` 在 .accessory 模式下
//      走不通，偏好窗口无法通过 sendAction 触发。
//
// 这里改用纯 AppKit 启动：完全由 main.swift 持有 NSApplication 生命周期，
// AppDelegate 由我们自己设到 NSApp.delegate 上，偏好窗口由
// `PreferencesWindowController` 单例独立管理。这样 SwiftUI scene system 不会
// 在启动时擅自创建任何窗口。
let app = NSApplication.shared
// AppDelegate / StatusBarController / PreferencesWindowController 都是 @MainActor
// 类型。main.swift 顶层不在 actor context 中，但 macOS app 入口保证在 main thread，
// Swift 6 strict concurrency 下用 `assumeIsolated` 把后续整段切到 MainActor 上。
// `app.run()` 同步阻塞直到 app 终止，所以 assumeIsolated 闭包也不会提前 return。
MainActor.assumeIsolated {
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
}
