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
/// 每个 pipeline 只放**真正的数据拉取**strategy；**「已安装探测」由
/// RefreshCoordinator 在调用 pipeline 之前用 `InstallDetectorProvider`
/// 跑一次**（未安装的 kind 会被跳过，pipeline 全失败的已装 kind 会被
/// 标记为 needsConfiguration）。
///
/// Codex 的典型链路：
/// 1. **OAuth**（首选，`~/.codex/auth.json` → wham/usage，不需要 FDA）；
/// 2. **BrowserCookie**（兜底，已登录浏览器 → wham/usage）；
/// 3. **CLI Log**（兜底，~/.codex/sessions/*.jsonl 估算）；
/// 4. **Keychain**（再兜底，仅当以上都不可用时确认有无 token）。
enum ProviderPipelines {

    /// 给每个 ProviderKind 配一个 `InstallDetectorProvider`，用于
    /// RefreshCoordinator 前置判断「这个 service 到底装没装」。
    @MainActor
    static func makeInstallDetectors() -> [ProviderKind: InstallDetectorProvider] {
        var map: [ProviderKind: InstallDetectorProvider] = [:]
        for kind in ProviderKind.allCases {
            map[kind] = InstallDetectorProvider(
                id: "\(kind.rawValue)-install",
                kind: kind,
                candidateAppNames: candidateAppNames(for: kind)
            )
        }
        return map
    }

    private static func candidateAppNames(for kind: ProviderKind) -> [String] {
        switch kind {
        case .kimi: return ["Kimi"]
        case .minimax: return ["MiniMax Code", "MiniMax"]
        case .claude: return ["Claude"]
        case .cursor: return ["Cursor"]
        case .warp: return ["Warp"]
        case .trae: return ["TRAE", "TRAE SOLO", "Trae"]
        case .antigravity: return ["Antigravity"]
        case .gemini: return ["Gemini"]
        default: return []
        }
    }

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
            traePipeline(),
            antigravityPipeline(),
        ]
    }

    @MainActor
    private static func codexPipeline(cookieReader: BrowserCookieReader) -> FetchPipeline {
        FetchPipeline(
            kind: .codex,
            strategies: [
                QuotaProviderStrategy(CodexAuthProvider()),
                QuotaProviderStrategy(BrowserCookieProvider(id: "codex-cookie", kind: .codex, cookieReader: cookieReader)),
                QuotaProviderStrategy(CLILogProvider(id: "codex-cli", kind: .codex)),
                QuotaProviderStrategy(KeychainProvider(id: "codex-keychain", kind: .codex)),
            ],
            runMode: .sequential
        )
    }

    @MainActor
    private static func claudePipeline(cookieReader: BrowserCookieReader) -> FetchPipeline {
        FetchPipeline(
            kind: .claude,
            strategies: [
                QuotaProviderStrategy(BrowserCookieProvider(id: "claude-cookie", kind: .claude, cookieReader: cookieReader)),
                QuotaProviderStrategy(KeychainProvider(id: "claude-keychain", kind: .claude)),
            ],
            runMode: .sequential
        )
    }

    @MainActor
    private static func geminiPipeline(cookieReader: BrowserCookieReader) -> FetchPipeline {
        FetchPipeline(
            kind: .gemini,
            strategies: [
                QuotaProviderStrategy(BrowserCookieProvider(id: "gemini-cookie", kind: .gemini, cookieReader: cookieReader)),
                QuotaProviderStrategy(KeychainProvider(id: "gemini-keychain", kind: .gemini)),
            ],
            runMode: .sequential
        )
    }

    @MainActor
    private static func minimaxPipeline(cookieReader: BrowserCookieReader) -> FetchPipeline {
        FetchPipeline(
            kind: .minimax,
            strategies: [
                // 首选：~/.mavis/config.yaml 里的 API Key → 调 Coding Plan dashboard
                QuotaProviderStrategy(MiniMaxConfigProvider()),
                // 兜底：浏览器 Cookie / Keychain（web 已登录场景）
                QuotaProviderStrategy(BrowserCookieProvider(id: "minimax-cookie", kind: .minimax, cookieReader: cookieReader)),
                QuotaProviderStrategy(KeychainProvider(id: "minimax-keychain", kind: .minimax)),
            ],
            runMode: .sequential
        )
    }

    @MainActor
    private static func kimiPipeline(cookieReader: BrowserCookieReader) -> FetchPipeline {
        FetchPipeline(
            kind: .kimi,
            strategies: [
                QuotaProviderStrategy(KimiAuthProvider()),
                QuotaProviderStrategy(BrowserCookieProvider(id: "kimi-cookie", kind: .kimi, cookieReader: cookieReader)),
                QuotaProviderStrategy(KeychainProvider(id: "kimi-keychain", kind: .kimi)),
            ],
            runMode: .sequential
        )
    }

    @MainActor
    private static func traePipeline() -> FetchPipeline {
        FetchPipeline(
            kind: .trae,
            strategies: [
                QuotaProviderStrategy(KeychainProvider(id: "trae-keychain", kind: .trae)),
            ],
            runMode: .sequential
        )
    }

    @MainActor
    private static func antigravityPipeline() -> FetchPipeline {
        FetchPipeline(
            kind: .antigravity,
            strategies: [
                QuotaProviderStrategy(KeychainProvider(id: "antigravity-keychain", kind: .antigravity)),
            ],
            runMode: .sequential
        )
    }
}
