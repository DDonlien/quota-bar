import Foundation

/// Claude 配置文件 → API 数据源：OAuth access token 直调 Anthropic 官方 usage
/// 端点，不依赖浏览器 Cookie 或 App WebView 会话。
///
/// 端点与响应形状经 CodexBar（`ClaudeOAuthUsageFetcher`）与 Claude Code CLI 自身
/// 行为交叉验证：
/// - `GET https://api.anthropic.com/api/oauth/usage`
/// - Header：`Authorization: Bearer <accessToken>` + `anthropic-beta: oauth-2025-04-20`
/// - 响应字段与 web session 的 `organizations/{id}/usage` 完全一致
///   （`five_hour` / `seven_day` / `seven_day_sonnet` / `seven_day_opus`），
///   由 `ClaudeUsageWindowParser` 统一解析。
///
/// **凭证来源两级**：Claude Code 按版本/平台把 OAuth 凭证写在 `~/.claude/.credentials.json`
/// 文件**或** macOS Keychain（service `"Claude Code-credentials"`），文件优先、
/// 文件不存在时退化到 Keychain。两者是同一份 JSON（`claudeAiOauth.{accessToken,
/// subscriptionType,...}`），经 CodexBar `ClaudeOAuthCredentialModels` 交叉验证。
///
/// 读 Keychain 里**另一个 App**（Claude Code）写入的条目需要用户一次性授权
/// （系统会弹「quota-bar 想使用你钥匙串中的机密信息」，点一次「始终允许」后
/// 长期生效，等价于其他 app 常见的一次性系统权限授权，不是浏览器登录）。
///
/// `subscriptionType` 字段（如 `"pro"`）可直接当档位使用，不需要额外请求。
final class ClaudeKeychainCredentialsReader {
    static let service = "Claude Code-credentials"

    /// 读取 Keychain 中 `"Claude Code-credentials"` 条目的原始数据（同
    /// `~/.claude/.credentials.json` 的 JSON 文本）。找不到、拒绝或解析失败时返回 nil。
    ///
    /// 用 `/usr/bin/security find-generic-password -w` 而不是直接调
    /// `SecItemCopyMatching`——2026-07-07 排查 Claude Keychain 长期读不到凭证的问题时，
    /// 对照 ClaudeBar（`ClaudeCredentialLoader.loadFromKeychain`）真实实现发现的关键
    /// 差异：`/usr/bin/security` 是 Apple 签名的系统二进制，代码签名/CDHash 永远不变；
    /// 用户点一次「始终允许」后，这份信任记在 `/usr/bin/security` 的身份上。而我们
    /// 之前直接在自己进程里调 `SecItemCopyMatching`，授权会记在自己 App 的签名身份
    /// 上——本项目目前是 ad-hoc 签名（`--sign -`），每次 `build-app.sh` 重新构建后
    /// CDHash 都会变化，这份授权大概率没法跨构建持久化。改走系统 `security` CLI 后，
    /// 信任只需要对 `/usr/bin/security` 建立一次，不受我们自己重新签名/重新构建影响。
    static func readCredentialsJSON() async -> Data? {
        await readViaSecurityCLI(service: service)
    }

    /// 实际执行 `/usr/bin/security find-generic-password -w` 的部分单独抽出来，
    /// 让 `service` 可以在测试里换成一个真实不存在的占位名（终态一定是"找不到"，
    /// 不依赖开发机上是否真的装了 Claude Code 或登录过）。
    static func readViaSecurityCLI(service: String) async -> Data? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", service, "-w"]
        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = FileHandle.nullDevice

        return await withCheckedContinuation { (continuation: CheckedContinuation<Data?, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try process.run()
                } catch {
                    continuation.resume(returning: nil)
                    return
                }
                let output = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                guard process.terminationStatus == 0,
                      let text = String(data: output, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines),
                      !text.isEmpty,
                      let data = text.data(using: .utf8)
                else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: data)
            }
        }
    }
}
final class ClaudeOAuthUsageProvider: QuotaProvider, @unchecked Sendable {
    let id = "claude-oauth"
    let kind: ProviderKind = .claude
    var displayName: String { kind.displayName }

    private let credentialsPath: String
    private let endpoint: URL
    private let session: URLSession
    private let dateProvider: () -> Date
    private let keychainReader: @Sendable () async -> Data?

    init(
        credentialsPath: String? = nil,
        endpoint: URL = URL(string: "https://api.anthropic.com/api/oauth/usage")!,
        session: URLSession = .shared,
        dateProvider: @escaping () -> Date = Date.init,
        // 测试专用注入点：默认走真实 `/usr/bin/security` CLI 读取本机 Keychain；
        // 测试传入一个固定返回 nil（或固定数据）的闭包，避免测试环境的行为
        // 依赖开发机上真实存在的 Keychain 条目（曾经因为直接调用真实读取
        // 导致两个"应该抛 missingCredentials"的测试意外读到本机真实凭证、
        // 转而对 api.anthropic.com 发起真实网络请求）。
        keychainReader: @escaping @Sendable () async -> Data? = ClaudeKeychainCredentialsReader.readCredentialsJSON
    ) {
        self.credentialsPath = credentialsPath ?? NSHomeDirectory() + "/.claude/.credentials.json"
        self.endpoint = endpoint
        self.session = session
        self.dateProvider = dateProvider
        self.keychainReader = keychainReader
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let fetchedAt = dateProvider()
        let credentials = try await loadCredentials()

        var request = URLRequest(url: endpoint, timeoutInterval: timeout)
        request.httpMethod = "GET"
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // OAuth usage 端点要求该 beta header（与 CodexBar 生产实现一致）。
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw QuotaFetchError.transient(detail: "Claude usage 返回非 HTTP 响应")
        }
        switch http.statusCode {
        case 200..<300:
            break
        case 401:
            throw QuotaFetchError.missingCredentials(detail: "Claude OAuth token 已过期，请重新 claude login")
        case 429:
            throw QuotaFetchError.transient(detail: "Claude usage 端点限流，稍后重试")
        default:
            throw QuotaFetchError.transient(detail: "Claude usage HTTP \(http.statusCode)")
        }

        guard let windows = ClaudeUsageWindowParser.parse(data: data), !windows.isEmpty else {
            throw QuotaFetchError.transient(detail: "无法解析 Claude usage 响应")
        }

        let tier = ProviderPricing.normalizedTier(credentials.subscriptionType)
        let monthlyPrice = await ProviderPricing.localizedMonthlyPrice(kind: .claude, tier: credentials.subscriptionType)

        return ProviderSnapshot(
            kind: .claude,
            subscriptionTier: tier,
            availability: .available,
            quotas: windows,
            monthlyPrice: monthlyPrice,
            fetchedAt: fetchedAt
        )
    }

    private struct Credentials {
        let accessToken: String
        let subscriptionType: String?
    }

    /// 凭证形状（文件与 Keychain 一致，经 CodexBar `ClaudeOAuthCredentialModels`
    /// 交叉验证）：
    /// ```json
    /// {"claudeAiOauth": {"accessToken": "...", "subscriptionType": "pro", ...}}
    /// ```
    ///
    /// 文件优先；文件不存在或解析失败时退化到 Keychain（Claude Code 较新版本
    /// 可能只写 Keychain，不落文件——本机实测确认过这个情况）。
    private func loadCredentials() async throws -> Credentials {
        if let fileData = try? Data(contentsOf: URL(fileURLWithPath: credentialsPath)),
           let credentials = Self.parseCredentials(fileData) {
            return credentials
        }
        if let keychainData = await keychainReader(),
           let credentials = Self.parseCredentials(keychainData) {
            return credentials
        }
        throw QuotaFetchError.missingCredentials(
            detail: "未找到 Claude OAuth 凭证（\(credentialsPath) 与 Keychain 均无有效 accessToken），请先运行 claude 登录"
        )
    }

    private static func parseCredentials(_ data: Data) -> Credentials? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let oauth = json["claudeAiOauth"] as? [String: Any],
              let accessToken = (oauth["accessToken"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !accessToken.isEmpty
        else {
            return nil
        }
        return Credentials(accessToken: accessToken, subscriptionType: oauth["subscriptionType"] as? String)
    }
}
