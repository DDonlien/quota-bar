import Foundation

/// Provider 工厂：根据可用数据源创建 Provider 列表。
///
/// 策略：为每个关心的 ProviderKind 创建多个数据源（Cookie / CLI / Keychain），
/// RefreshCoordinator 会并发调用它们，并自动合并/降级结果。
enum ProviderFactory {
    static func createProviders() -> [QuotaProvider] {
        let cookieReader = FilesystemCookieReader()
        let parser = PlaceholderDashboardParser()
        var providers: [QuotaProvider] = []

        // Codex: Cookie + CLI 日志 + Keychain
        providers.append(BrowserCookieProvider(
            id: "codex-cookie",
            kind: .codex,
            cookieReader: cookieReader,
            parser: parser
        ))
        providers.append(CLILogProvider(
            id: "codex-cli",
            kind: .codex
        ))
        providers.append(KeychainProvider(
            id: "codex-keychain",
            kind: .codex
        ))

        // MiniMax: Cookie + Keychain
        providers.append(BrowserCookieProvider(
            id: "minimax-cookie",
            kind: .minimax,
            cookieReader: cookieReader,
            parser: parser
        ))
        providers.append(KeychainProvider(
            id: "minimax-keychain",
            kind: .minimax
        ))

        // Kimi: Cookie + Keychain
        providers.append(BrowserCookieProvider(
            id: "kimi-cookie",
            kind: .kimi,
            cookieReader: cookieReader,
            parser: parser
        ))
        providers.append(KeychainProvider(
            id: "kimi-keychain",
            kind: .kimi
        ))

        return providers
    }
}
