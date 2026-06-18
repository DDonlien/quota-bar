import Foundation
import AppKit

/// 探测 macOS 隐私权限状态。
///
/// **为什么需要这个**：读取 Safari/Chrome 的 Cookie 数据库需要 Full Disk Access (FDA)。
/// macOS 没有公开 API 可以直接查询「FDA 是否已授权」，
/// 行业惯例是尝试打开一个已知受 TCC 保护的文件，看是否抛 `EACCES`。
///
/// 探测策略：尝试读取 `~/Library/Cookies/Cookies.binarycookies`。
/// - 未授权 FDA → `String(contentsOf:)` 抛 EACCES；
/// - 已授权 → 正常返回。
///
/// 这个检测在用户登录 Safari/Chrome 之后才稳定（不存在文件同样会"通过"，
/// 但配合 SweetCookieKit 的访问失败提示可以双保险）。
enum PrivacyAccessChecker {

    /// Full Disk Access 是否已授权。
    /// 第一次调用可能会触发一次磁盘 IO，结果会被 UI 缓存。
    static func hasFullDiskAccess() -> Bool {
        let probePath = NSHomeDirectory() + "/Library/Cookies/Cookies.binarycookies"
        guard FileManager.default.fileExists(atPath: probePath) else {
            // 文件不存在时不能直接判断为"已授权"，
            // 因为可能用户没登录过 Safari。但也无法证明"未授权"。
            // 返回 false 让 UI 显示引导，把决定权交给用户。
            return false
        }
        // 用 FileHandle 打开做最小权限探测 —— 读不到就视为未授权。
        return FileManager.default.isReadableFile(atPath: probePath)
    }

    /// 打开「系统设置 → 隐私与安全性 → 完全磁盘访问权限」面板。
    @MainActor
    static func openFullDiskAccessSettings() {
        // macOS 13+ 的 URL scheme；如果失败则退到通用 Privacy & Security。
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        } else if let fallback = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
            NSWorkspace.shared.open(fallback)
        }
    }
}