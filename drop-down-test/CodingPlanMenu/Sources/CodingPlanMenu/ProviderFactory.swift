import Foundation
import SweetCookieKit

/// Provider 工厂：根据可用数据源创建 Provider 列表。
///
/// 策略：为每个关心的 ProviderKind 创建多个数据源（Cookie / CLI / Keychain），
/// RefreshCoordinator 会并发调用它们，并自动合并/降级结果。
///
/// Cookie 数据源使用 SweetCookieKit（`FilesystemCookieReader` 适配器），
/// 它会按 `Browser.defaultImportOrder` 在所有安装的浏览器里找匹配的 cookie。
enum ProviderFactory {
    static func createProviders() -> [QuotaProvider] {
        let cookieReader = FilesystemCookieReader()
        var providers: [QuotaProvider] = []

        // Codex: Cookie (wham/usage) + CLI 日志 + Keychain
        providers.append(BrowserCookieProvider(id: "codex-cookie", kind: .codex, cookieReader: cookieReader))
        providers.append(CLILogProvider(id: "codex-cli", kind: .codex))
        providers.append(KeychainProvider(id: "codex-keychain", kind: .codex))

        // Claude: Cookie (claude.ai) + Keychain（session key 备查）
        providers.append(BrowserCookieProvider(id: "claude-cookie", kind: .claude, cookieReader: cookieReader))
        providers.append(KeychainProvider(id: "claude-keychain", kind: .claude))

        // Gemini: Cookie + Keychain（Vertex AI API key 备查）
        providers.append(BrowserCookieProvider(id: "gemini-cookie", kind: .gemini, cookieReader: cookieReader))
        providers.append(KeychainProvider(id: "gemini-keychain", kind: .gemini))

        // MiniMax: Cookie + Keychain
        providers.append(BrowserCookieProvider(id: "minimax-cookie", kind: .minimax, cookieReader: cookieReader))
        providers.append(KeychainProvider(id: "minimax-keychain", kind: .minimax))

        // Kimi: Cookie + Keychain
        providers.append(BrowserCookieProvider(id: "kimi-cookie", kind: .kimi, cookieReader: cookieReader))
        providers.append(KeychainProvider(id: "kimi-keychain", kind: .kimi))

        return providers
    }
}