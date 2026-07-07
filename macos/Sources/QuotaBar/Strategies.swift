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

    var sourceKind: ProviderSourceKind {
        if id.contains("keychain") { return .keychain }
        if id.contains("webview") { return .webViewSession }
        if id.contains("cookie") || id.contains("edge") { return .browserCookie }
        if id == "codex-cli" { return .localLog }
        // "minimax-cli" 是历史命名遗留——实际实现读 `~/.mmx/config.json` 的 API key
        // 直调 `coding_plan/remains`，并不真的执行 `mmx` 命令（真正的 CLI 层是
        // `minimax-mmx-cli`）。放在下面的 `id.contains("cli")` 通配之前特判掉，
        // 避免被误分类成「CLI 命令」。
        if id == "minimax-cli" { return .configFile }
        if id.contains("cli") { return .cli }
        if id.contains("config") || id.contains("auth") || id.contains("zcode") { return .configFile }
        if id.contains("dashboard") { return .rpc }
        return .api
    }

    var supportedLayers: Set<ProviderFetchLayer> {
        if id.contains("keychain") {
            return [.provider]
        }
        if id == "codex-cli" {
            return [.quota]
        }
        if id == "kimi-auth" {
            return [.quota]
        }
        if id == "zcode-plan-cache" {
            return [.provider, .plan]
        }
        return [.quota, .expiration, .plan]
    }

    var sourceMetadata: [String: String] {
        var metadata: [String: String] = ["displayName": displayName]
        if id.contains("edge") {
            metadata["browser"] = "Edge"
        } else if id.contains("cookie") {
            metadata["browser"] = "default"
        }
        let domains = kind.cookieDomains
        if !domains.isEmpty {
            metadata["domains"] = domains.joined(separator: ",")
        }
        return metadata
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
/// 2. **Keychain**（兜底，仅确认是否存在凭证，不生成额度）；
/// 3. **BrowserCookie / CLI Log** 默认关闭，只在显式调试开关下启用，避免权限弹窗和假 100% 额度。
enum ProviderPipelines {

    /// 给每个 ProviderKind 配一个 `InstallDetectorProvider`，用于
    /// RefreshCoordinator 前置判断「这个 service 到底装没装」。
    @MainActor
    static func makeInstallDetectors() -> [ProviderKind: InstallDetectorProvider] {
        var map: [ProviderKind: InstallDetectorProvider] = [:]
        for kind in supportedProviderKinds {
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
        case .zcode: return ["ZCode", "Z Code"]
        case .gemini: return ["Gemini"]
        default: return []
        }
    }

    static let supportedProviderKinds: [ProviderKind] = [
        .codex,
        .claude,
        .minimax,
        .kimi,
        .antigravity,
        .zcode,
    ]

    private static var browserCookieStrategiesEnabled: Bool {
        boolEnvironmentFlag("QUOTABAR_ENABLE_BROWSER_COOKIE")
    }

    private static var codexLogEstimateEnabled: Bool {
        boolEnvironmentFlag("QUOTABAR_ENABLE_CODEX_LOG_ESTIMATE")
    }

    private static func boolEnvironmentFlag(_ name: String) -> Bool {
        guard let raw = ProcessInfo.processInfo.environment[name]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !raw.isEmpty else {
            return false
        }
        return ["1", "true", "yes", "on"].contains(raw)
    }

    @MainActor
    static func makePipelines(
        cookieReader: BrowserCookieReader = FilesystemCookieReader(),
        edgeCookieReader: BrowserCookieReader = EdgeCookieReader()
    ) -> [FetchPipeline] {
        [
            codexPipeline(cookieReader: cookieReader),
            claudePipeline(cookieReader: cookieReader, edgeCookieReader: edgeCookieReader),
            minimaxPipeline(cookieReader: cookieReader, edgeCookieReader: edgeCookieReader),
            kimiPipeline(cookieReader: cookieReader, edgeCookieReader: edgeCookieReader),
            antigravityPipeline(),
            zcodePipeline(),
        ]
    }

    @MainActor
    private static func codexPipeline(cookieReader: BrowserCookieReader) -> FetchPipeline {
        var strategies: [ProviderFetchStrategy] = [
            QuotaProviderStrategy(CodexAuthProvider()),
        ]
        if browserCookieStrategiesEnabled {
            strategies.append(QuotaProviderStrategy(BrowserCookieProvider(id: "codex-cookie", kind: .codex, cookieReader: cookieReader)))
        }
        if codexLogEstimateEnabled {
            strategies.append(QuotaProviderStrategy(CLILogProvider(id: "codex-cli", kind: .codex)))
        }
        // 最后一层：App 内 WebView 授权会话（一次登录，永久静默）。
        strategies.append(QuotaProviderStrategy(BrowserCookieProvider(id: "codex-webview", kind: .codex, cookieReader: AppWebViewSessionCookieReader())))
        strategies.append(QuotaProviderStrategy(KeychainProvider(id: "codex-keychain", kind: .codex)))

        return FetchPipeline(
            kind: .codex,
            strategies: strategies,
            runMode: .sequential
        )
    }

    @MainActor
    private static func claudePipeline(
        cookieReader: BrowserCookieReader,
        edgeCookieReader: BrowserCookieReader
    ) -> FetchPipeline {
        var strategies: [ProviderFetchStrategy] = [
            // 首选：Claude Code statusLine hook 本地缓存（见 ClaudeStatusLineHookInstaller）。
            // 纯文件读取，零权限、零子进程；用户未启用或缓存过期时自然落到下一层。
            QuotaProviderStrategy(ClaudeStatusLineUsageProvider()),
            // 第二：~/.claude/.credentials.json 的 OAuth access token 直调
            // api.anthropic.com/api/oauth/usage（配置文件 → API，无需浏览器/WebView）。
            QuotaProviderStrategy(ClaudeOAuthUsageProvider()),
            // 第二：真实 CLI 命令补档位。Claude 没有结构化额度 CLI（/usage 只有
            // 交互 TUI），`claude auth status --json` 是唯一可用的非交互结构化
            // 输出，只贡献 subscriptionType（档位），凭证文件已带该字段时不会被走到。
            QuotaProviderStrategy(ClaudeAuthStatusCLIProvider()),
        ]
        if browserCookieStrategiesEnabled {
            strategies.append(QuotaProviderStrategy(BrowserCookieProvider(id: "claude-edge", kind: .claude, cookieReader: edgeCookieReader)))
            strategies.append(QuotaProviderStrategy(BrowserCookieProvider(id: "claude-cookie", kind: .claude, cookieReader: cookieReader)))
        }
        // OAuth 凭证文件缺失/过期时的兜底：App 内 WebView 授权会话
        // （organizations → usage 二段请求），同样无弹窗。
        strategies.append(QuotaProviderStrategy(BrowserCookieProvider(id: "claude-webview", kind: .claude, cookieReader: AppWebViewSessionCookieReader())))
        strategies.append(QuotaProviderStrategy(KeychainProvider(id: "claude-keychain", kind: .claude)))

        return FetchPipeline(
            kind: .claude,
            strategies: strategies,
            runMode: .sequential
        )
    }

    @MainActor
    private static func minimaxPipeline(
        cookieReader: BrowserCookieReader,
        edgeCookieReader: BrowserCookieReader
    ) -> FetchPipeline {
        var strategies: [ProviderFetchStrategy] = [
            // 首选：本地配置 → API（~/.mmx/config.json 的 API key 直调 coding_plan/remains）
            QuotaProviderStrategy(MiniMaxCLIProvider()),
            // 第二：~/.mavis/config.yaml 里的 API Key
            QuotaProviderStrategy(MiniMaxConfigProvider()),
            // 第三：真实 CLI 命令（mmx quota show --output json）——
            // 让 mmx 自己处理鉴权/region/token 刷新，Quota Bar 只消费结构化输出。
            QuotaProviderStrategy(MiniMaxCommandProvider()),
        ]
        if browserCookieStrategiesEnabled {
            strategies.append(QuotaProviderStrategy(BrowserCookieProvider(id: "minimax-edge", kind: .minimax, cookieReader: edgeCookieReader)))
            strategies.append(QuotaProviderStrategy(BrowserCookieProvider(id: "minimax-cookie", kind: .minimax, cookieReader: cookieReader)))
        }
        // 最后一层：App 内 WebView 授权会话。
        strategies.append(QuotaProviderStrategy(BrowserCookieProvider(id: "minimax-webview", kind: .minimax, cookieReader: AppWebViewSessionCookieReader())))
        strategies.append(QuotaProviderStrategy(KeychainProvider(id: "minimax-keychain", kind: .minimax)))

        return FetchPipeline(
            kind: .minimax,
            strategies: strategies,
            runMode: .sequential
        )
    }

    @MainActor
    private static func kimiPipeline(
        cookieReader: BrowserCookieReader,
        edgeCookieReader: BrowserCookieReader
    ) -> FetchPipeline {
        var strategies: [ProviderFetchStrategy] = [
            // 首选：Kimi Desktop token → GetSubscription，拿 Work 月额度 + 档位 +
            // 价格 + 订阅到期日，不触发浏览器 Cookie / Keychain 弹窗。
            QuotaProviderStrategy(KimiDesktopTokenProvider()),
            // 第二：Kimi CLI OAuth（coding/v1/usages），Code 5h/周额度来源；
            // desktop token 成功时也会通过分层合并补齐 code scope。
            QuotaProviderStrategy(KimiAuthProvider()),
        ]
        if browserCookieStrategiesEnabled {
            // 显式启用后再用 Web Cookie 补 Work 月度额度、Code 周额度、Code 5h 额度以及 Andante 档位/价格。
            strategies.append(QuotaProviderStrategy(BrowserCookieProvider(id: "kimi-edge", kind: .kimi, cookieReader: edgeCookieReader)))
            strategies.append(QuotaProviderStrategy(BrowserCookieProvider(id: "kimi-cookie", kind: .kimi, cookieReader: cookieReader)))
        }
        // 最后一层：App 内 WebView 授权会话（desktop token 缺失时补 Work/档位/价格/日期）。
        strategies.append(QuotaProviderStrategy(BrowserCookieProvider(id: "kimi-webview", kind: .kimi, cookieReader: AppWebViewSessionCookieReader())))
        strategies.append(QuotaProviderStrategy(KeychainProvider(id: "kimi-keychain", kind: .kimi)))

        return FetchPipeline(
            kind: .kimi,
            strategies: strategies,
            runMode: .sequential,
            // Kimi 完整额度 = Work（desktop token）+ Code（CLI OAuth），
            // 任一来源单独成功都只有一半 scope，需要分层合并。
            expectedQuotaScopes: ["work", "code"]
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
                // 首选：Antigravity IDE 本地 language_server gRPC-Web endpoint
                QuotaProviderStrategy(AntigravityDashboardProvider(id: "antigravity-rpc", processMode: .languageServer)),
                // 第二：已在运行的 agy CLI 进程暴露的本地 gRPC-Web endpoint。它不是
                // 自然语言问询，而是 CLI 运行时本地 RPC，仍然返回结构化 quota JSON。
                QuotaProviderStrategy(AntigravityDashboardProvider(id: "antigravity-cli", processMode: .cli)),
                // 第三：真实 CLI 层——IDE / agy 都没在跑时，拉起一个临时 agy 会话
                // （等价于用户手动 `agy` + `/usage`），取完结构化额度立即退出。
                QuotaProviderStrategy(AntigravityCLISessionProvider()),
                // 最后兜底：Keychain 只能证明有凭证，不能生成额度。
                QuotaProviderStrategy(KeychainProvider(id: "antigravity-keychain", kind: .antigravity)),
            ],
            runMode: .sequential
        )
    }

    @MainActor
    private static func zcodePipeline() -> FetchPipeline {
        FetchPipeline(
            kind: .zcode,
            strategies: [
                QuotaProviderStrategy(ZCodeAuthProvider()),
                QuotaProviderStrategy(ZCodePlanCacheProvider()),
                QuotaProviderStrategy(KeychainProvider(id: "zcode-keychain", kind: .zcode)),
            ],
            runMode: .sequential
        )
    }
}
