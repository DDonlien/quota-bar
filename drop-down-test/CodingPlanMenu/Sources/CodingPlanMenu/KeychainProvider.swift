import Foundation
import Security
import LocalAuthentication

/// Keychain 数据源。
///
/// 作用是检查 macOS Keychain 中是否存在对应 Provider 的 OAuth token / API key。
///
/// 注意：Keychain **不存储额度数据**，所以本 Provider 只能确定
/// 「凭证是否可用」，额度本身仍需通过 BrowserCookie / CLI 日志等渠道获取。
/// 这里返回 `.available` 并附带占位额度，便于 UI 区分：
/// - `.available` + 占位额度 = 「有凭证，等首次拉取」
/// - `.available` + 真实额度 = 「数据已就绪」
/// - `.needsConfiguration` = 「缺凭证，引导用户登录」
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

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let fetchedAt = dateProvider()
        if hasCredential() {
            return ProviderSnapshot(
                kind: kind,
                availability: .available,
                quotas: [
                    QuotaWindow(title: "5小时额度", remainingFraction: 1.0, refreshDescription: "等待首次刷新"),
                    QuotaWindow(title: "周额度", remainingFraction: 1.0, refreshDescription: "等待首次刷新")
                ],
                monthlyPrice: kind.fallbackMonthlyPrice,
                fetchedAt: fetchedAt
            )
        } else {
            throw QuotaFetchError.missingCredentials(
                detail: "无凭证"
            )
        }
    }

    private func hasCredential() -> Bool {
        let context = LAContext()
        context.interactionNotAllowed = true

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}

extension ProviderKind {
    var defaultKeychainService: String {
        switch self {
        case .codex: return "ai.openai.codex"
        case .minimax: return "com.minimax.code"
        case .kimi: return "com.moonshot.kimi"
        default: return "com.quotabar.\(rawValue)"
        }
    }

    var defaultKeychainAccount: String {
        switch self {
        case .codex: return "oauth-token"
        case .minimax: return "api-key"
        case .kimi: return "session"
        default: return "default"
        }
    }
}
