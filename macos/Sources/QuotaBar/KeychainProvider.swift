import Foundation
import Security
import LocalAuthentication

/// Keychain 数据源。
///
/// 作用是检查 macOS Keychain 中是否存在对应 Provider 的 OAuth token / API key，
/// 并把读到的 token 透出去给后续 dashboard 请求使用。
///
/// **注意**：Keychain **不存储额度数据**，所以本 Provider 只能确定
/// 「凭证是否可用」，额度本身仍需通过 BrowserCookie / CLI 日志等渠道获取。
final class KeychainProvider: QuotaProvider, @unchecked Sendable {

    let id: String
    let kind: ProviderKind
    var displayName: String { kind.displayName }

    private let keychainService: String
    /// `nil` 表示不按 account 过滤，只按 service 匹配第一条（Claude Code 的
    /// Keychain 条目 account 是运行时动态值，不是固定字符串，见下方
    /// `defaultKeychainAccount` 注释）。
    private let account: String?
    private let dateProvider: () -> Date

    init(
        id: String,
        kind: ProviderKind,
        keychainService: String? = nil,
        account: String?? = nil,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.id = id
        self.kind = kind
        self.keychainService = keychainService ?? kind.defaultKeychainService
        self.account = account ?? kind.defaultKeychainAccount
        self.dateProvider = dateProvider
    }

    /// 读取 Keychain 中保存的 token。
    ///
    /// - Returns: token 字符串（OAuth bearer、API key 等），不存在时返回 `nil`。
    func readToken() -> String? {
        let context = LAContext()
        context.interactionNotAllowed = true

        guard let account else {
            // service-only 匹配（account 未知/动态）：同一 service 下可能有多条历史
            // 条目（重装 / 多版本 CLI 各自写入），取最近修改的一条，而不是
            // Keychain 内部枚举顺序里任意一条——否则可能读到过期/失效的旧凭证。
            return Self.readNewestToken(service: keychainService, context: context)
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return Self.extractToken(from: result)
    }

    private static func readNewestToken(service: String, context: LAContext) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecUseAuthenticationContext as String: context
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let items = result as? [[String: Any]], !items.isEmpty else {
            return nil
        }
        let newest = items.max { a, b in
            let dateA = a[kSecAttrModificationDate as String] as? Date ?? .distantPast
            let dateB = b[kSecAttrModificationDate as String] as? Date ?? .distantPast
            return dateA < dateB
        }
        guard let data = newest?[kSecValueData as String] as? Data else { return nil }
        return Self.extractToken(from: data)
    }

    private static func extractToken(from result: Any?) -> String? {
        if let data = result as? Data, let token = String(data: data, encoding: .utf8) {
            return token.isEmpty ? nil : token
        }
        if let token = result as? String {
            return token.isEmpty ? nil : token
        }
        return nil
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        guard let token = readToken(), !token.isEmpty else {
            throw QuotaFetchError.sourceUnavailable(detail: "Keychain 中无凭证")
        }

        throw QuotaFetchError.sourceUnavailable(detail: "Keychain 只能确认凭证，无法读取订阅额度")
    }

    /// 仅探测 Keychain 中是否存在凭证，不读取具体内容。
    /// 用于不希望触发 keychain 弹窗的快速路径。
    static func hasToken(service: String, account: String?) -> Bool {
        let context = LAContext()
        context.interactionNotAllowed = true
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context
        ]
        if let account {
            query[kSecAttrAccount as String] = account
        }
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }
}

extension ProviderKind {
    var defaultKeychainService: String {
        switch self {
        case .codex: return "ai.openai.codex"
        case .minimax: return "com.minimax.code"
        case .kimi: return "com.moonshot.kimi"
        // 经 CodexBar (`ClaudeOAuthCredentialsStore.claudeKeychainService`) 交叉验证的
        // 真实 Claude Code Keychain generic password service 名。此前
        // "com.anthropic.claude" 是猜测值，从未匹配到真实条目。
        case .claude: return "Claude Code-credentials"
        case .gemini: return "com.google.gemini"
        default: return "com.quotabar.\(rawValue)"
        }
    }

    /// `nil` 表示查询时不按 account 过滤（服务名唯一匹配）。
    /// Claude Code 写入 Keychain 时 account 属性是运行时动态值（非固定字符串，
    /// 见 CodexBar 对应实现按 service 查询后回读 `kSecAttrAccount` 的做法），
    /// 无法硬编码，因此返回 nil 走 service-only 匹配。
    var defaultKeychainAccount: String? {
        switch self {
        case .codex: return "oauth-token"
        case .minimax: return "api-key"
        case .kimi: return "session"
        case .claude: return nil
        case .gemini: return "gemini-session"
        default: return "default"
        }
    }
}
