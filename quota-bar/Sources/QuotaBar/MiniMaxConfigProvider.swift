import Foundation

/// MiniMax 凭证源：从 `~/.mavis/config.yaml` 读取 provider.minimax.options.apiKey。
///
/// 区分"占位 API Key"（如 `sk-xxx`、`sk-your-key-here`、空）和真实 key：
/// - 占位 / 缺失 → `missingCredentials`（UI 显示"待配置"，并解释如何配置）
/// - 真实 key → 调 `https://api.minimaxi.com/v1/coding_plan/remains` 拿余额
///
/// **关于格式**：MiniMax 的 Coding Plan 用独立 API secret key（不是 web 登录的 JWT）。
/// Key 通常以 `eyJ...` 开头（与 web JWT 一样），但**用途不同** —— 必须由用户在
/// MiniMax 开放平台控制台 → Coding Plan 创建并填到 config.yaml 才有效。
final class MiniMaxConfigProvider: QuotaProvider, @unchecked Sendable {

    let id: String
    let kind: ProviderKind = .minimax
    var displayName: String { "MiniMax Config" }

    private let configPath: String
    private let dateProvider: () -> Date
    private let session: URLSession

    init(
        id: String = "minimax-config",
        configPath: String? = nil,
        session: URLSession = .shared,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.id = id
        self.configPath = configPath ?? NSString(string: "~/.mavis/config.yaml").expandingTildeInPath
        self.session = session
        self.dateProvider = dateProvider
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let apiKey = readAPIKey()

        guard let apiKey, !apiKey.isEmpty else {
            throw QuotaFetchError.missingCredentials(detail: "未在 ~/.mavis/config.yaml 配置 MiniMax API Key")
        }

        if isPlaceholder(apiKey) {
            throw QuotaFetchError.missingCredentials(
                detail: "MiniMax API Key 仍为占位符（\(apiKey)），请到 platform.minimaxi.com 创建 Coding Plan 并填入真实 Key"
            )
        }

        // 真实 key —— 调 Coding Plan dashboard。
        return try await fetchCodingPlanRemains(apiKey: apiKey, timeout: timeout)
    }

    // MARK: - 凭证读取

    private func readAPIKey() -> String? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
              let text = String(data: data, encoding: .utf8)
        else { return nil }

        // 简易 YAML 解析：找 `provider:` → `minimax:` → `options:` → `apiKey: <value>`
        // 不引第三方库；目标只是 mavis 的简单配置。
        let lines = text.split(separator: "\n", omittingEmptySubsequences: true)
            .map { String($0) }
        var inProvider = false
        var inMiniMax = false
        var inOptions = false
        var currentIndent = 0

        for raw in lines {
            let stripped = raw.trimmingCharacters(in: .whitespaces)
            let indent = raw.prefix(while: { $0 == " " }).count

            if stripped.isEmpty || stripped.hasPrefix("#") { continue }

            if stripped == "provider:" {
                inProvider = true
                inMiniMax = false
                inOptions = false
                currentIndent = indent
                continue
            }

            // provider 区块结束（缩进回落）
            if inProvider, indent <= currentIndent, !stripped.hasPrefix("-") {
                inProvider = false
                inMiniMax = false
                inOptions = false
            }

            if inProvider, stripped.hasPrefix("minimax:") {
                inMiniMax = true
                inOptions = false
                continue
            }

            if inMiniMax, stripped.hasPrefix("options:") {
                inOptions = true
                continue
            }

            if inMiniMax, inOptions, stripped.hasPrefix("apiKey:") {
                let value = stripped
                    .replacingOccurrences(of: "apiKey:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                // 去掉引号
                return value.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            }
        }

        return nil
    }

    /// 检测 API Key 是不是占位符（用户没填真实 key）。
    private func isPlaceholder(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return true }
        let lowered = trimmed.lowercased()
        let placeholderPatterns = [
            "sk-xxx", "sk-your", "sk-placeholder", "sk-test",
            "your-api-key", "your_key", "changeme", "todo", "replace-me"
        ]
        if placeholderPatterns.contains(where: { lowered.contains($0) }) {
            return true
        }
        // 短于 20 字符基本是占位
        return trimmed.count < 20
    }

    // MARK: - Dashboard 调用

    private func fetchCodingPlanRemains(apiKey: String, timeout: TimeInterval) async throws -> ProviderSnapshot {
        let url = URL(string: "https://api.minimaxi.com/v1/coding_plan/remains")!
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw QuotaFetchError.transient(detail: "MiniMax Coding Plan 响应异常")
        }

        if http.statusCode == 401 || http.statusCode == 403 {
            // Key 鉴权失败 —— 提示用户重检查
            throw QuotaFetchError.transient(
                detail: "MiniMax API Key 无效（HTTP \(http.statusCode)），请到 platform.minimaxi.com 重新生成"
            )
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw QuotaFetchError.transient(
                detail: "MiniMax Coding Plan 拉取失败（HTTP \(http.statusCode)）：\(body.prefix(100))"
            )
        }

        return parseCodingPlanRemains(data: data)
    }

    /// 解析 `https://api.minimaxi.com/v1/coding_plan/remains` 响应：
    /// ```json
    /// {
    ///   "model_remains": [{"model_name": "MiniMax-M2", "remains": 500}, ...],
    ///   "current_package_name": "Plus",
    ///   "current_package_id": 1,
    ///   "remains": ["unlimited" | 500],
    ///   "tool_remains": [...],
    ///   "base_resp": {"status_code": 0, "status_msg": "success"}
    /// }
    /// ```
    private func parseCodingPlanRemains(data: Data) -> ProviderSnapshot {
        let fetchedAt = dateProvider()
        let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
        let baseResp = json["base_resp"] as? [String: Any]
        let statusCode = (baseResp?["status_code"] as? NSNumber)?.intValue ?? -1

        if statusCode != 0 {
            let msg = baseResp?["status_msg"] as? String ?? "未知错误"
            // 仍认为不是 fatal error，让 UI 显示 fetchFailed
            return ProviderSnapshot(
                kind: .minimax,
                subscriptionTier: nil,
                availability: .fetchFailed(reason: "MiniMax Coding Plan 返回错误：\(msg)"),
                quotas: [],
                monthlyPrice: nil,
                fetchedAt: fetchedAt
            )
        }

        let packageName = json["current_package_name"] as? String
        let packageId = (json["current_package_id"] as? NSNumber)?.intValue

        // 解析剩余额度：remains 是 ["unlimited" | <int>]
        let remains = json["remains"] as? [Any] ?? []
        var windowSeconds: TimeInterval = 5 * 3600  // 默认 5 小时窗口
        if let windowRaw = (json["window_seconds"] as? NSNumber)?.doubleValue
            ?? (json["cycle_window_seconds"] as? NSNumber)?.doubleValue,
           windowRaw > 0 {
            windowSeconds = windowRaw
        }

        var quotas: [QuotaWindow] = []
        if let first = remains.first {
            let fraction: Double
            if let s = first as? String, s.lowercased() == "unlimited" {
                fraction = 1.0
            } else if let n = (first as? NSNumber)?.doubleValue {
                // 这里无法拿到 limit —— 保守给个分数（remains / max(remains, 100)）
                let assumedMax = max(n, 100)
                fraction = min(1.0, n / assumedMax)
            } else {
                fraction = 0
            }
            let resetsAt = fetchedAt.addingTimeInterval(windowSeconds)
            quotas.append(QuotaWindow(
                title: "5小时额度",
                remainingFraction: fraction,
                refreshDescription: QuotaResetText.description(for: resetsAt, relativeTo: fetchedAt),
                resetsAt: resetsAt,
                periodSeconds: windowSeconds
            ))
        }

        // 价格（MiniMax Coding Plan 套餐价格已知；按 packageName 推断）
        let monthlyPrice = mapMonthlyPrice(packageName: packageName, packageId: packageId)

        return ProviderSnapshot(
            kind: .minimax,
            subscriptionTier: packageName.map {
                ProviderPricing.normalizedTier($0).flatMap { $0 } ?? $0
            },
            availability: .available,
            quotas: quotas,
            monthlyPrice: monthlyPrice,
            fetchedAt: fetchedAt
        )
    }

    private func mapMonthlyPrice(packageName: String?, packageId: Int?) -> String? {
        // MiniMax 公开定价（来源：platform.minimaxi.com Coding Plan）
        // 注意：API 不直接返回价格，按套餐名映射；找不到时返回 nil。
        let name = packageName?.lowercased() ?? ""
        let priceUSD: Double?
        switch name {
        case "starter": priceUSD = 29
        case "plus": priceUSD = 49
        case "max": priceUSD = 119
        case "plus-highspeed", "plus_highspeed": priceUSD = 98
        case "max-highspeed", "max_highspeed": priceUSD = 199
        case "ultra-highspeed", "ultra_highspeed": priceUSD = 899
        default: priceUSD = nil
        }
        guard let priceUSD else { return nil }
        // 简化为 CNY（用户在中国区，¥ 比 $ 更直观）
        let cny = priceUSD * 7.25  // 用近似汇率
        return String(format: "¥%.0f/月", cny)
    }
}
