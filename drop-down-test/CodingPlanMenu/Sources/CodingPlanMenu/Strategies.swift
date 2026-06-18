import Foundation

// MARK: - 把现有 QuotaProvider 适配成 ProviderFetchStrategy
//
// 这样 P0 写好的 BrowserCookieProvider / KeychainProvider / CLILogProvider
// 能直接被 FetchPipeline 复用，无需重写。

/// 把任意 `QuotaProvider` 包成 `ProviderFetchStrategy` 的薄适配层。
struct QuotaProviderStrategy: ProviderFetchStrategy {
    let id: String
    let kind: ProviderKind
    var displayName: String { inner.displayName }
    private let inner: QuotaProvider

    init(_ provider: QuotaProvider) {
        self.id = provider.id
        self.kind = provider.kind
        self.inner = provider
    }

    func fetch(timeout: TimeInterval) async throws -> ProviderSnapshot {
        try await inner.fetchSnapshot(timeout: timeout)
    }
}

// MARK: - 已知 Pipeline 工厂

/// 为每个 ProviderKind 创建一组有序的 strategy（fallback 链）。
///
/// Codex 的典型链路：
/// 1. **BrowserCookie**（首选，已登录浏览器 → wham/usage）；
/// 2. **CLI Log**（兜底，~/.codex/sessions/*.jsonl 估算）；
/// 3. **Keychain**（再兜底，仅当 cookie + 日志都不可用时确认有无 token）。
enum ProviderPipelines {

    @MainActor
    static func makePipelines(
        cookieReader: BrowserCookieReader = FilesystemCookieReader()
    ) -> [FetchPipeline] {
        [
            codexPipeline(cookieReader: cookieReader),
            claudePipeline(cookieReader: cookieReader),
            geminiPipeline(cookieReader: cookieReader),
            minimaxPipeline(cookieReader: cookieReader),
            kimiPipeline(cookieReader: cookieReader),
        ]
    }

    @MainActor
    private static func codexPipeline(cookieReader: BrowserCookieReader) -> FetchPipeline {
        FetchPipeline(
            kind: .codex,
            strategies: [
                QuotaProviderStrategy(BrowserCookieProvider(id: "codex-cookie", kind: .codex, cookieReader: cookieReader)),
                QuotaProviderStrategy(CLILogProvider(id: "codex-cli", kind: .codex)),
                QuotaProviderStrategy(KeychainProvider(id: "codex-keychain", kind: .codex)),
            ]
        )
    }

    @MainActor
    private static func claudePipeline(cookieReader: BrowserCookieReader) -> FetchPipeline {
        FetchPipeline(
            kind: .claude,
            strategies: [
                QuotaProviderStrategy(BrowserCookieProvider(id: "claude-cookie", kind: .claude, cookieReader: cookieReader)),
                QuotaProviderStrategy(KeychainProvider(id: "claude-keychain", kind: .claude)),
            ]
        )
    }

    @MainActor
    private static func geminiPipeline(cookieReader: BrowserCookieReader) -> FetchPipeline {
        FetchPipeline(
            kind: .gemini,
            strategies: [
                QuotaProviderStrategy(BrowserCookieProvider(id: "gemini-cookie", kind: .gemini, cookieReader: cookieReader)),
                QuotaProviderStrategy(KeychainProvider(id: "gemini-keychain", kind: .gemini)),
            ]
        )
    }

    @MainActor
    private static func minimaxPipeline(cookieReader: BrowserCookieReader) -> FetchPipeline {
        FetchPipeline(
            kind: .minimax,
            strategies: [
                QuotaProviderStrategy(BrowserCookieProvider(id: "minimax-cookie", kind: .minimax, cookieReader: cookieReader)),
                QuotaProviderStrategy(KeychainProvider(id: "minimax-keychain", kind: .minimax)),
            ]
        )
    }

    @MainActor
    private static func kimiPipeline(cookieReader: BrowserCookieReader) -> FetchPipeline {
        FetchPipeline(
            kind: .kimi,
            strategies: [
                QuotaProviderStrategy(BrowserCookieProvider(id: "kimi-cookie", kind: .kimi, cookieReader: cookieReader)),
                QuotaProviderStrategy(KeychainProvider(id: "kimi-keychain", kind: .kimi)),
            ]
        )
    }
}