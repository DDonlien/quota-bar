import Foundation

/// 直接读取 MiniMax CLI 配置 (~/.mmx/config.json) 并使用 API key 获取额度。
///
/// 作为 pipeline 的首选：当用户安装了 `mmx` CLI 时，
/// 从 ~/.mmx/config.json 读取 API key，直接调用 api.minimaxi.com 的 API。
/// 这比执行 `mmx quota` CLI 更可靠（`mmx` 在非 tty 下不输出 TUI）。
final class MiniMaxCLIProvider: QuotaProvider, @unchecked Sendable {

    let id = "minimax-cli"
    let kind: ProviderKind = .minimax
    var displayName: String { kind.displayName }

    private let configPath: String
    private let dateProvider: () -> Date

    init(configPath: String = "\(NSHomeDirectory())/.mmx/config.json",
         dateProvider: @escaping () -> Date = Date.init) {
        self.configPath = configPath
        self.dateProvider = dateProvider
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let fetchedAt = dateProvider()

        let apiKey = try readAPIKey()
        let data = try await fetchQuotaData(apiKey: apiKey, timeout: timeout)

        return try await parseQuotaJSON(data: data, fetchedAt: fetchedAt)
    }

    // MARK: - 读取 ~/.mmx/config.json

    private func readAPIKey() throws -> String {
        guard FileManager.default.fileExists(atPath: configPath) else {
            throw QuotaFetchError.sourceUnavailable(detail: "~/.mmx/config.json 不存在，请先运行 `mmx auth login`")
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw QuotaFetchError.transient(detail: "~/.mmx/config.json 格式错误")
        }

        guard let apiKey = json["api_key"] as? String, !apiKey.isEmpty else {
            throw QuotaFetchError.missingCredentials(detail: "~/.mmx/config.json 中未找到 api_key")
        }

        return apiKey
    }

    // MARK: - 调用 API

    private func fetchQuotaData(apiKey: String, timeout: TimeInterval) async throws -> Data {
        guard let url = URL(string: "https://api.minimaxi.com/v1/coding_plan/remains") else {
            throw QuotaFetchError.transient(detail: "MiniMax API URL 无效")
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = timeout

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw QuotaFetchError.transient(detail: "MiniMax API 返回非 HTTP 响应")
        }

        switch http.statusCode {
        case 200..<300:
            return data
        case 401:
            throw QuotaFetchError.missingCredentials(detail: "MiniMax API Key 无效或已过期")
        default:
            throw QuotaFetchError.transient(detail: "MiniMax API HTTP \(http.statusCode)")
        }
    }

    /// 服务端表达「没有生效的 Token Plan 订阅」的错误文案。
    /// 实测（2026-07）：`mmx quota` / coding_plan/remains 在订阅到期后返回
    /// `"no active token plan subscription"`（HTTP 200 + 非 0 status_code）。
    static func indicatesNoActiveSubscription(_ message: String) -> Bool {
        let lowered = message.lowercased()
        return (lowered.contains("no active") && lowered.contains("subscription"))
            || lowered.contains("not subscribed")
            || lowered.contains("subscription expired")
    }

    // MARK: - JSON 解析

    private func parseQuotaJSON(data: Data, fetchedAt: Date) async throws -> ProviderSnapshot {
        try await MiniMaxQuotaResponseParser.parse(data: data, fetchedAt: fetchedAt)
    }
}

// MARK: - 共享响应解析

/// `coding_plan/remains` 形状的响应解析，供配置→API 路径（MiniMaxCLIProvider /
/// MiniMaxConfigProvider）和真实 CLI 命令路径（MiniMaxCommandProvider）复用。
enum MiniMaxQuotaResponseParser {
    static func parse(data: Data, fetchedAt: Date) async throws -> ProviderSnapshot {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw QuotaFetchError.transient(detail: "MiniMax quota JSON 解析失败")
        }

        let baseResp = json["base_resp"] as? [String: Any]
        let statusCode = (baseResp?["status_code"] as? NSNumber)?.intValue ?? -1
        if statusCode != 0 {
            let msg = baseResp?["status_msg"] as? String ?? "未知错误"
            if MiniMaxCLIProvider.indicatesNoActiveSubscription(msg) {
                // 服务端权威信号：Token Plan 订阅不存在 / 已到期。
                // 映射成 notSubscribed 而不是「待配置」，UI 显示订阅已失效。
                throw QuotaFetchError.notSubscribed(detail: "MiniMax Coding Plan 订阅已到期或未订阅")
            }
            throw QuotaFetchError.transient(detail: "MiniMax quota API 错误：\(msg)")
        }

        let modelRemains = json["model_remains"] as? [[String: Any]] ?? []
        let packageName = (json["current_package_name"] as? String) ?? "TokenPlan"
        var windows: [QuotaWindow] = []

        for model in modelRemains {
            guard let modelName = model["model_name"] as? String else { continue }

            let startTimeMs = (model["start_time"] as? NSNumber)?.doubleValue
            let endTimeMs = (model["end_time"] as? NSNumber)?.doubleValue
            let weeklyStartTimeMs = (model["weekly_start_time"] as? NSNumber)?.doubleValue
            let weeklyEndTimeMs = (model["weekly_end_time"] as? NSNumber)?.doubleValue

            // 1. Interval 额度（短期，如 5小时/24小时）
            let intervalRemainingPercent = (model["current_interval_remaining_percent"] as? NSNumber)?.doubleValue ?? 100
            let intervalFraction = intervalRemainingPercent / 100.0
            let intervalEndDate: Date? = endTimeMs.map { Date(timeIntervalSince1970: $0 / 1000) }
            let intervalResetText = intervalEndDate.map { QuotaResetText.description(for: $0, relativeTo: fetchedAt) } ?? "重置时间未知"
            let intervalPeriod: TimeInterval? = if let start = startTimeMs, let end = endTimeMs {
                (end - start) / 1000
            } else { nil }

            // Interval 时长描述（已弃用，由框架根据 periodSeconds 自动生成本地化周期标签）
            let _ = if let period = intervalPeriod {
                if period >= 86400 {
                    "\(Int(period / 86400))天"
                } else if period >= 3600 {
                    "\(Int(period / 3600))小时"
                } else if period >= 60 {
                    "\(Int(period / 60))分钟"
                } else {
                    "\(Int(period))秒"
                }
            } else { "短期" }

            windows.append(QuotaWindow(
                title: modelName.capitalized,
                remainingFraction: intervalFraction,
                refreshDescription: intervalResetText,
                resetsAt: intervalEndDate,
                periodSeconds: intervalPeriod,
                // MiniMax 每个 model_name（General / Video 等）= 1 个独立订阅，组内 5h + 周窗口共享额度
                subscriptionGroup: modelName.lowercased()
            ))

            // 2. 周额度
            let weeklyRemainingPercent = (model["current_weekly_remaining_percent"] as? NSNumber)?.doubleValue ?? 100
            let weeklyFraction = weeklyRemainingPercent / 100.0
            let weeklyEndDate: Date? = weeklyEndTimeMs.map { Date(timeIntervalSince1970: $0 / 1000) }
            let weeklyResetText = weeklyEndDate.map { QuotaResetText.description(for: $0, relativeTo: fetchedAt) } ?? "重置时间未知"
            let weeklyPeriod: TimeInterval? = if let start = weeklyStartTimeMs, let end = weeklyEndTimeMs {
                (end - start) / 1000
            } else { 7 * 86400 }

            windows.append(QuotaWindow(
                title: modelName.capitalized,
                remainingFraction: weeklyFraction,
                refreshDescription: weeklyResetText,
                resetsAt: weeklyEndDate,
                periodSeconds: weeklyPeriod,
                subscriptionGroup: modelName.lowercased()
            ))
        }

        guard !windows.isEmpty else {
            throw QuotaFetchError.transient(detail: "MiniMax quota 无额度数据")
        }

        let tier = packageName
        let monthlyPrice = await ProviderPricing.localizedMonthlyPrice(kind: .minimax, tier: tier)

        return ProviderSnapshot(
            kind: .minimax,
            subscriptionTier: tier,
            availability: .available,
            quotas: windows,
            monthlyPrice: monthlyPrice,
            fetchedAt: fetchedAt
        )
    }
}
