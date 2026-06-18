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
    private let account: String
    private let dateProvider: () -> Date

    init(
        id: String,
        kind: ProviderKind,
        keychainService: String? = nil,
        account: String? = nil,
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

        if let data = result as? Data, let token = String(data: data, encoding: .utf8) {
            return token.isEmpty ? nil : token
        }
        if let token = result as? String {
            return token.isEmpty ? nil : token
        }
        return nil
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let fetchedAt = dateProvider()
        guard let token = readToken(), !token.isEmpty else {
            throw QuotaFetchError.missingCredentials(detail: "Keychain 中无凭证")
        }

        // 仅返回「凭证可用」的占位快照；真实额度需要后续通过 token 调对应 dashboard。
        return ProviderSnapshot(
            kind: kind,
            availability: .available,
            quotas: [
                QuotaWindow(title: "5小时额度", remainingFraction: 1.0, refreshDescription: "等待 dashboard 首次刷新"),
                QuotaWindow(title: "周额度", remainingFraction: 1.0, refreshDescription: "等待 dashboard 首次刷新")
            ],
            monthlyPrice: kind.fallbackMonthlyPrice,
            fetchedAt: fetchedAt
        )
    }

    /// 仅探测 Keychain 中是否存在凭证，不读取具体内容。
    /// 用于不希望触发 keychain 弹窗的快速路径。
    static func hasToken(service: String, account: String) -> Bool {
        let context = LAContext()
        context.interactionNotAllowed = true
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context
        ]
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }
}

extension ProviderKind {
    var defaultKeychainService: String {
        switch self {
        case .codex: return "ai.openai.codex"
        case .minimax: return "com.minimax.code"
        case .kimi: return "com.moonshot.kimi"
        case .claude: return "com.anthropic.claude"
        case .gemini: return "com.google.gemini"
        default: return "com.quotabar.\(rawValue)"
        }
    }

    var defaultKeychainAccount: String {
        switch self {
        case .codex: return "oauth-token"
        case .minimax: return "api-key"
        case .kimi: return "session"
        case .claude: return "claude.ai-session"
        case .gemini: return "gemini-session"
        default: return "default"
        }
    }
}