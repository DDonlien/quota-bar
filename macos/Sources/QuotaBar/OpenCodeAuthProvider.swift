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
    private let manualKeyConfigPath: String
    private let dateProvider: () -> Date

    init(
        authPaths: [String] = OpenCodeAuthProvider.defaultAuthPaths(
            environment: ProcessInfo.processInfo.environment
        ),
        // 注入点：测试用来避免读写 `OpenCodeManualKeyStore.defaultConfigPath` 背后
        // 真实用户机器上的 `~/Library/Application Support/QuotaBar/opencode-api-key.json`
        // （同类问题见 `FetchPipeline` 的 `checkLog` 注入点）。
        manualKeyConfigPath: String = OpenCodeManualKeyStore.defaultConfigPath,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.authPaths = authPaths
        self.manualKeyConfigPath = manualKeyConfigPath
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
        if let providerIDs = loadConfiguredProviderIDs(), !providerIDs.isEmpty {
            return ProviderSnapshot(
                kind: .opencode,
                subscriptionTier: Self.tierSummary(providerIDs: providerIDs),
                availability: .available,
                quotas: [],
                monthlyPrice: nil,
                fetchedAt: fetchedAt
            )
        }

        // 没装官方 CLI（找不到 auth.json）时，用户可能已经在「偏好设置 → 模型」页手动
        // 粘贴过一个 API Key（`OpenCodeManualKeyStore`）——跟 auth.json 里具体是哪个
        // 下游 provider 不同，手动粘贴的 key 无法反推出 Go/Zen/BYOK 里的具体档位，
        // 统一按 BYOK 展示（见 `OpenCodeManualKeyStore` 顶部说明）。
        if OpenCodeManualKeyStore.currentKeyState(configPath: manualKeyConfigPath).isConfigured {
            return ProviderSnapshot(
                kind: .opencode,
                subscriptionTier: "BYOK",
                availability: .available,
                quotas: [],
                monthlyPrice: nil,
                fetchedAt: fetchedAt
            )
        }

        throw QuotaFetchError.missingCredentials(
            detail: "未找到 opencode 凭证（~/.local/share/opencode/auth.json），请先运行 `opencode auth login`，或在「偏好设置 → 模型」里手动粘贴 API Key"
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

// MARK: - 手动 API Key 存储

/// opencode 没有官方额度接口（见文件顶部说明），手动粘贴的 key 唯一的作用是让
/// 没装官方 CLI（找不到 `~/.local/share/opencode/auth.json`）的用户也能让 Quota Bar
/// 确认"我已经配置好了"，展示成 `.available` + 空 quotas + "BYOK" 档位——跟真实
/// auth.json 解析出的 Go/Zen 具体档位不同，纯手动 key 拿不到那一层信息，统一按最
/// 保守的 BYOK 展示。存储格式和 `ZCodeAuthProvider.ZCodeManualKeyStore` 完全一致
/// （Quota Bar 自己独占的 JSON 文件，`{"apiKey": "..."}`），复制一份而不是共享类型
/// 是因为两者语义不同（Z Code 的 key 是真实调用凭证，这里只是"已配置"的确认信号）。
enum OpenCodeManualKeyStore {
    enum KeyInputState: Equatable {
        case missing
        case configured(masked: String)

        var isConfigured: Bool {
            if case .configured = self { return true }
            return false
        }
    }

    static var defaultConfigPath: String {
        QuotaBarDataDirectory.defaultURL().appendingPathComponent("opencode-api-key.json").path
    }

    static func currentKeyState(configPath: String = defaultConfigPath) -> KeyInputState {
        guard let key = readAPIKey(configPath: configPath), !key.isEmpty else {
            return .missing
        }
        let prefix = String(key.prefix(8))
        return .configured(masked: "\(prefix)···\(key.suffix(4))")
    }

    static func readAPIKey(configPath: String = defaultConfigPath) -> String? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let key = json["apiKey"]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !key.isEmpty
        else { return nil }
        return key
    }

    enum PersistError: LocalizedError {
        case emptyKey
        case writeFailed(underlying: String)

        var errorDescription: String? {
            switch self {
            case .emptyKey: return "API Key 不能为空"
            case .writeFailed(let detail): return "保存失败：\(detail)"
            }
        }
    }

    static func save(apiKey: String, configPath: String = defaultConfigPath) throws {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PersistError.emptyKey }

        let url = URL(fileURLWithPath: configPath)
        do {
            try QuotaBarDataDirectory.ensureExists(url.deletingLastPathComponent())
            let data = try JSONSerialization.data(withJSONObject: ["apiKey": trimmed])
            try data.write(to: url, options: .atomic)
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
        } catch {
            throw PersistError.writeFailed(underlying: error.localizedDescription)
        }
    }
}
