import Foundation

/// opencode 支持：opencode 本身是 BYOK 聚合 CLI（`https://opencode.ai`），本身没有
/// 官方额度百分比接口——调研确认：
/// - Zen（opencode 自家 pay-as-you-go 网关）的 credits API 会返回 `Not Found`（未上线/不稳定）；
/// - Go（opencode 自家订阅）的用量只能靠抓一个未公开的私有 dashboard 网页 + 浏览器 auth cookie，
///   没有官方文档、结构随时可能变。
///
/// 因此本 provider 只贡献「已配置」档位（对齐 `ClaudeAuthStatusCLIProvider` 的「tier-only,
/// 不伪造额度」先例）：读 `~/.local/share/opencode/auth.json`（XDG Base Directory 规范路径，
/// `opencode auth login` / `/connect` 写入的凭证文件），确认至少配置了一个下游 provider 就返回
/// `.available` + 空 quotas；找不到文件或文件里没有任何凭证则报 `missingCredentials`，
/// 由 pipeline 兜底成 `.needsConfiguration`。
final class OpenCodeAuthProvider: QuotaProvider, @unchecked Sendable {
    let id = "opencode-auth"
    let kind: ProviderKind = .opencode
    var displayName: String { kind.displayName }

    private let authPaths: [String]
    private let dateProvider: () -> Date

    init(
        authPaths: [String] = OpenCodeAuthProvider.defaultAuthPaths(
            environment: ProcessInfo.processInfo.environment
        ),
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.authPaths = authPaths
        self.dateProvider = dateProvider
    }

    /// 候选路径按优先级排列：`XDG_DATA_HOME` 覆盖（若设置）在前，标准 `~/.local/share` 兜底。
    static func defaultAuthPaths(environment: [String: String]) -> [String] {
        var paths: [String] = []
        if let xdgDataHome = environment["XDG_DATA_HOME"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !xdgDataHome.isEmpty {
            paths.append("\(xdgDataHome)/opencode/auth.json")
        }
        paths.append("~/.local/share/opencode/auth.json")
        return paths
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let fetchedAt = dateProvider()
        guard let providerIDs = loadConfiguredProviderIDs(), !providerIDs.isEmpty else {
            throw QuotaFetchError.missingCredentials(
                detail: "未找到 opencode 凭证（~/.local/share/opencode/auth.json），请先运行 `opencode auth login`"
            )
        }

        return ProviderSnapshot(
            kind: .opencode,
            subscriptionTier: Self.tierSummary(providerIDs: providerIDs),
            availability: .available,
            quotas: [],
            monthlyPrice: nil,
            fetchedAt: fetchedAt
        )
    }

    private func loadConfiguredProviderIDs() -> [String]? {
        for rawPath in authPaths {
            let path = (rawPath as NSString).expandingTildeInPath
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { continue }
            if let ids = Self.parseConfiguredProviderIDs(data: data), !ids.isEmpty {
                return ids
            }
        }
        return nil
    }

    /// 解析 `auth.json`：顶层是「provider id → 凭证对象」的字典（如 `anthropic`、`opencode`、
    /// `opencode-go`、`github-copilot` 等），凭证对象里用 `key` / `access` / `token` /
    /// `apiKey` / `value` 之一存实际密钥或 OAuth access token。
    static func parseConfiguredProviderIDs(data: Data) -> [String]? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return root.compactMap { key, value -> String? in
            guard let entry = value as? [String: Any], hasCredential(entry) else { return nil }
            return key
        }.sorted()
    }

    private static func hasCredential(_ entry: [String: Any]) -> Bool {
        let secretKeys = ["key", "access", "token", "apiKey", "value"]
        for secretKey in secretKeys {
            if let secret = entry[secretKey] as? String,
               !secret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return true
            }
        }
        return false
    }

    /// 用已配置的 provider id 生成一个简短「档位」标签：命中 opencode 自家的
    /// Go / Zen 网关时用其品牌名，否则展示纯 BYOK 语义（避免暗示某个具体档位/价格）。
    static func tierSummary(providerIDs: [String]) -> String {
        if providerIDs.contains("opencode-go") { return "Go" }
        if providerIDs.contains("opencode") { return "Zen" }
        return "BYOK"
    }
}
