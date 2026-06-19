import Foundation
import AppKit

/// Provider 登录引导执行器。
///
/// 触发场景：
/// - `QuotaFetchError.missingCredentials` 被聚合器捕获；
/// - 用户点击状态栏菜单里的「登录 XXX」按钮；
/// - 启动时发现某 provider 已安装但未登录。
///
/// 抽象设计：
/// - `loginCommand`：可以生成 shell 命令（如 `codex login`、`claude /login`）；
/// - `loginHint`：给 UI 显示的人话说明（如「在打开的终端里粘贴一次性登录链接」）；
/// - `postLogin`：登录完成后重新探测凭证（子类可重写）。
///
/// 当前实现统一调用 `open -a Terminal <shell command>`，把用户领到 Terminal.app 完成 OAuth。
/// 后续可以替换成 in-app WKWebView 走 OAuth redirect，避免跳出 App。
protocol LoginRunner: Sendable {
    var kind: ProviderKind { get }
    var displayName: String { get }
    var loginCommand: String { get }
    var loginHint: String { get }

    /// 触发登录流程。
    @MainActor func launchLogin() throws
}

extension LoginRunner {
    @MainActor
    func launchLogin() throws {
        let script = """
        tell application "Terminal"
            activate
            do script "\(loginCommand)"
        end tell
        """
        let appleScript = NSAppleScript(source: script)
        var errorInfo: NSDictionary?
        let success = appleScript?.executeAndReturnError(&errorInfo) != nil
        if !success {
            // AppleScript 失败时退回到 `open` 命令
            NSWorkspace.shared.open(URL(string: "terminal://") ?? URL(fileURLWithPath: "/"))
        }
    }
}

// MARK: - 已知 provider 的实现

struct CodexLoginRunner: LoginRunner {
    let kind: ProviderKind = .codex
    var displayName: String { "Codex" }
    var loginCommand: String { "codex login" }
    var loginHint: String { "在打开的终端里粘贴一次性登录链接，登录完成后本应用会自动重新拉取额度。" }
}

struct ClaudeLoginRunner: LoginRunner {
    let kind: ProviderKind = .claude
    var displayName: String { "Claude" }
    var loginCommand: String { "claude /login" }
    var loginHint: String { "在 Claude CLI 里走完 OAuth，登录完成后会自动重新拉取额度。" }
}

struct GeminiLoginRunner: LoginRunner {
    let kind: ProviderKind = .gemini
    var displayName: String { "Gemini" }
    var loginCommand: String { "gemini auth login" }
    var loginHint: String { "在终端里完成 Google 账号授权。" }
}

enum LoginRunnerFactory {
    static func runner(for kind: ProviderKind) -> LoginRunner? {
        switch kind {
        case .codex: return CodexLoginRunner()
        case .claude: return ClaudeLoginRunner()
        case .gemini: return GeminiLoginRunner()
        default: return nil
        }
    }
}