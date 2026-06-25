import Foundation

/// Antigravity IDE / CLI 本地 dashboard 数据源。
///
/// Antigravity 在运行时会启动一个本地 language_server（IDE/App 模式或 `agy` CLI 模式），
/// 暴露 gRPC-Web HTTPS endpoint。本 Provider 优先调用 `RetrieveUserQuotaSummary`
/// 获取结构化的模型组配额摘要；不可用时降级到 `GetUserStatus` 按模型标签聚合。
///
/// 端点参考：
/// - `POST /exa.language_server_pb.LanguageServerService/RetrieveUserQuotaSummary`
///   Body: `{"forceRefresh":true}`
///   返回 `response.groups[]`，每个 group 包含 `displayName`、`description` 和
///   `buckets[]`，bucket 包含 `remainingFraction`、`resetTime`、`window`。
/// - `POST /exa.language_server_pb.LanguageServerService/GetUserStatus`
///   Body: `{"metadata":{"ideName":"antigravity","extensionName":"antigravity","locale":"en"},"wrapper_data":{}}`
///   返回 `userStatus.cascadeModelConfigData.clientModelConfigs[].quotaInfo`。
///
/// 注意：agy CLI 启动的 language_server 使用自签名 HTTPS 证书且不需要 CSRF token；
/// IDE/App 启动的 language_server 通常需要 `X-Codeium-Csrf-Token`。
final class AntigravityDashboardProvider: QuotaProvider, @unchecked Sendable {

    let id = "antigravity-dashboard"
    let kind: ProviderKind = .antigravity
    var displayName: String { kind.displayName }

    private let session: URLSession
    private let commandRunner: CommandRunning
    private let dateProvider: () -> Date

    init(
        session: URLSession? = nil,
        commandRunner: CommandRunning = SystemCommandRunner(),
        dateProvider: @escaping () -> Date = Date.init
    ) {
        // 本地 language_server 使用自签名证书，需要允许不安全 HTTPS。
        self.session = session ?? Self.makeTrustingSession()
        self.commandRunner = commandRunner
        self.dateProvider = dateProvider
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let fetchedAt = dateProvider()

        // 1. 找 language_server 进程
        let pid = try await findLanguageServerPID()
        guard let pid else {
            throw QuotaFetchError.sourceUnavailable(
                detail: "Antigravity IDE 未运行或未激活 workspace（找不到 language_server 进程）"
            )
        }

        // 2. 拿监听端口
        let endpoints = try await resolveEndpoints(pid: pid)

        // 3. 优先 RetrieveUserQuotaSummary 拿结构化配额摘要
        var lastError: Error?
        var summaryData: Data?
        for endpoint in endpoints {
            do {
                summaryData = try await fetchQuotaSummary(endpoint: endpoint, timeout: timeout)
                break
            } catch {
                lastError = error
                continue
            }
        }

        // 4. 摘要拿到后，并行/串行拿 GetUserStatus 用于 tier / email
        var userStatusData: Data?
        for endpoint in endpoints {
            do {
                userStatusData = try await fetchUserStatus(endpoint: endpoint, timeout: timeout)
                break
            } catch {
                lastError = error
                continue
            }
        }

        // 5. 解析：优先用摘要，fallback 用 GetUserStatus
        if let summaryData {
            let tier = userStatusData.flatMap { Self.parseTier(from: $0) }
            return try await parseQuotaSummary(
                data: summaryData,
                fetchedAt: fetchedAt,
                tier: tier
            )
        }

        if let userStatusData {
            return try await parseUserStatusResponse(data: userStatusData, fetchedAt: fetchedAt)
        }

        throw lastError ?? QuotaFetchError.sourceUnavailable(detail: "所有端口都失败")
    }

    // MARK: - 进程发现

    private func findLanguageServerPID() async throws -> Int32? {
        // 1. 先查找 language_server_macos 进程（IDE / App 模式）
        let lsResult = try await commandRunner.run(
            "/bin/sh",
            ["-c", "pgrep -f language_server_macos | head -1"]
        )
        let lsTrimmed = lsResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        if !lsTrimmed.isEmpty, let pid = Int32(lsTrimmed) {
            return pid
        }

        // 2. 查找 agy CLI 进程（多种匹配方式，避免路径差异）
        let agyPatterns = [
            "pgrep -x agy | head -1",
            "pgrep -f '[\\/]bin[\\/]agy' | head -1",
            "ps aux | grep -E '[a]gy$' | awk '{print $2}' | head -1",
            "ps aux | grep -E '[a]gy\\s' | awk '{print $2}' | head -1"
        ]
        for pattern in agyPatterns {
            let result = try await commandRunner.run(
                "/bin/sh",
                ["-c", pattern]
            )
            let trimmed = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, let pid = Int32(trimmed) {
                return pid
            }
        }

        return nil
    }

    // MARK: - 端点解析

    private func resolveEndpoints(pid: Int32) async throws -> [AntigravityEndpoint] {
        let lsofResult = try await commandRunner.run(
            "/usr/sbin/lsof",
            ["-nP", "-a", "-iTCP", "-sTCP:LISTEN", "-p", String(pid)]
        )
        let lsofOutput = lsofResult.stdout

        let portRegex = try NSRegularExpression(pattern: "127\\.0\\.0\\.1:(\\d+)")
        let portRange = NSRange(lsofOutput.startIndex..., in: lsofOutput)
        let portMatches = portRegex.matches(in: lsofOutput, range: portRange)
        let ports = portMatches.compactMap { match -> String? in
            guard let r = Range(match.range(at: 1), in: lsofOutput) else { return nil }
            return String(lsofOutput[r])
        }
        guard !ports.isEmpty else {
            throw QuotaFetchError.sourceUnavailable(
                detail: "未找到 Antigravity language_server 监听端口"
            )
        }

        // 判断进程类型：IDE/App 需要 CSRF token，CLI 不需要
        let psResult = try await commandRunner.run(
            "/bin/ps",
            ["-p", String(pid), "-ww", "-o", "command="]
        )
        let commandLine = psResult.stdout
        let isCLI = Self.isCLIProcess(commandLine)

        let csrf: String
        if isCLI {
            csrf = ""
        } else {
            let csrfRegex = try NSRegularExpression(pattern: "csrf_token=([a-f0-9-]+)")
            let csrfRange = NSRange(commandLine.startIndex..., in: commandLine)
            csrf = csrfRegex.firstMatch(in: commandLine, range: csrfRange).flatMap { match -> String? in
                guard let r = Range(match.range(at: 1), in: commandLine) else { return nil }
                return String(commandLine[r])
            } ?? ""
        }

        return ports.flatMap { port -> [AntigravityEndpoint] in
            guard let portInt = Int(port), portInt > 0 else { return [] }
            return [
                AntigravityEndpoint(
                    scheme: "https",
                    host: "127.0.0.1",
                    port: portInt,
                    csrfToken: csrf,
                    requiresCSRF: !isCLI
                ),
                AntigravityEndpoint(
                    scheme: "http",
                    host: "127.0.0.1",
                    port: portInt,
                    csrfToken: csrf,
                    requiresCSRF: !isCLI
                )
            ]
        }
    }

    private static func isCLIProcess(_ commandLine: String) -> Bool {
        let lower = commandLine.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        // agy CLI 的 command line 通常就是 "agy" 或包含 antigravity-cli
        if lower == "agy" || lower.contains("antigravity-cli") || lower.contains("antigravity_cli") {
            return true
        }
        // 如果包含 language_server 路径但不是 IDE/App 路径，也认为是 CLI
        if lower.contains("language_server") {
            let isIDE = lower.contains("antigravity ide.app") || lower.contains("antigravity.app")
            return !isIDE
        }
        return false
    }

    // MARK: - 网络请求

    private func fetchQuotaSummary(endpoint: AntigravityEndpoint, timeout: TimeInterval) async throws -> Data {
        var request = URLRequest(
            url: endpoint.url(path: "/exa.language_server_pb.LanguageServerService/RetrieveUserQuotaSummary"),
            timeoutInterval: timeout
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("1", forHTTPHeaderField: "Connect-Protocol-Version")
        if endpoint.requiresCSRF, !endpoint.csrfToken.isEmpty {
            request.setValue(endpoint.csrfToken, forHTTPHeaderField: "X-Codeium-Csrf-Token")
        }
        request.httpBody = Data(#"{"forceRefresh":true}"#.utf8)

        return try await performRequest(request: request)
    }

    private func fetchUserStatus(endpoint: AntigravityEndpoint, timeout: TimeInterval) async throws -> Data {
        var request = URLRequest(
            url: endpoint.url(path: "/exa.language_server_pb.LanguageServerService/GetUserStatus"),
            timeoutInterval: timeout
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("1", forHTTPHeaderField: "Connect-Protocol-Version")
        if endpoint.requiresCSRF, !endpoint.csrfToken.isEmpty {
            request.setValue(endpoint.csrfToken, forHTTPHeaderField: "X-Codeium-Csrf-Token")
        }
        request.httpBody = Data(
            #"{"metadata":{"ideName":"antigravity","extensionName":"antigravity","locale":"en"},"wrapper_data":{}}"#.utf8
        )

        return try await performRequest(request: request)
    }

    private func performRequest(request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw QuotaFetchError.transient(detail: "Antigravity 返回非 HTTP 响应")
            }
            switch http.statusCode {
            case 200..<300:
                return data
            case 401, 403:
                throw QuotaFetchError.sourceUnavailable(
                    detail: "Antigravity csrf_token 无效（HTTP \(http.statusCode)），请重新启动 Antigravity IDE"
                )
            default:
                let body = String(data: data, encoding: .utf8) ?? ""
                throw QuotaFetchError.transient(
                    detail: "Antigravity HTTP \(http.statusCode)：\(body.prefix(100))"
                )
            }
        } catch let error as QuotaFetchError {
            throw error
        } catch {
            throw QuotaFetchError.transient(detail: "Antigravity 网络错误：\(error.localizedDescription)")
        }
    }

    // MARK: - 解析 Quota Summary

    private func parseQuotaSummary(
        data: Data,
        fetchedAt: Date,
        tier: String?
    ) async throws -> ProviderSnapshot {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw QuotaFetchError.transient(detail: "Antigravity 配额摘要非 JSON")
        }
        guard let response = json["response"] as? [String: Any],
              let groups = response["groups"] as? [[String: Any]]
        else {
            throw QuotaFetchError.transient(detail: "Antigravity 配额摘要缺少 response.groups")
        }

        let effectiveTier = tier  // 推断失败时不猜测，UI 只显示 Antigravity
        let windows: [QuotaWindow] = groups.compactMap { group -> QuotaWindow? in
            guard let displayName = group["displayName"] as? String else { return nil }
            guard let buckets = group["buckets"] as? [[String: Any]], let bucket = buckets.first else {
                return nil
            }
            let fraction = Self.parseFraction(bucket["remainingFraction"])
            let resetTimeStr = bucket["resetTime"] as? String
            let resetsAt = resetTimeStr.flatMap { Self.parseISO8601($0) }
            let windowKind = bucket["window"] as? String ?? ""
            let basePeriod = Self.windowPeriodSeconds(windowKind)

            // 优先用 resetTime - fetchedAt 得到精确周期；拿不到再用 window 推断
            let periodSeconds: TimeInterval? = {
                if let resetsAt {
                    let diff = resetsAt.timeIntervalSince(fetchedAt)
                    if diff > 0 { return diff }
                }
                return basePeriod
            }()

            let refreshDesc = resetsAt.map { QuotaResetText.description(for: $0, relativeTo: fetchedAt) } ?? "重置时间未知"

            return QuotaWindow(
                title: displayName,
                remainingFraction: max(0, min(1, fraction)),
                refreshDescription: refreshDesc,
                resetsAt: resetsAt,
                periodSeconds: periodSeconds,
                // Antigravity 每个 group（Gemini / Other / Claude 等）= 1 个独立订阅
                subscriptionGroup: displayName
            )
        }

        if windows.isEmpty {
            throw QuotaFetchError.transient(detail: "Antigravity 配额摘要为空")
        }

        return ProviderSnapshot(
            kind: .antigravity,
            subscriptionTier: effectiveTier,
            availability: .available,
            quotas: windows,
            monthlyPrice: await ProviderPricing.localizedMonthlyPrice(kind: .antigravity, tier: effectiveTier),
            fetchedAt: fetchedAt
        )
    }

    // MARK: - 解析 GetUserStatus

    private func parseUserStatusResponse(data: Data, fetchedAt: Date) async throws -> ProviderSnapshot {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw QuotaFetchError.transient(detail: "Antigravity 响应非 JSON")
        }
        guard let userStatus = json["userStatus"] as? [String: Any] else {
            throw QuotaFetchError.transient(detail: "Antigravity 响应缺 userStatus")
        }

        let tier = Self.parseTier(from: userStatus)

        var windows: [QuotaWindow] = []
        if let cascadeData = userStatus["cascadeModelConfigData"] as? [String: Any],
           let models = cascadeData["clientModelConfigs"] as? [[String: Any]]
        {
            // 按模型家族聚合；没有 remainingFraction 时按 0 处理（与 agy quota 一致）
            var geminiFraction: Double?
            var geminiResetsAt: Date?
            var claudeGPTFraction: Double?
            var claudeGPTResetsAt: Date?

            for model in models {
                guard let quotaInfo = model["quotaInfo"] as? [String: Any] else { continue }
                let fraction = Self.parseFraction(quotaInfo["remainingFraction"])
                let resetTimeStr = quotaInfo["resetTime"] as? String
                let resetsAt = resetTimeStr.flatMap { Self.parseISO8601($0) }
                let label = (model["label"] as? String) ?? ""

                let lower = label.lowercased()
                if lower.contains("gemini") {
                    geminiFraction = min(geminiFraction ?? 1.0, fraction)
                    geminiResetsAt = resetsAt ?? geminiResetsAt
                } else if lower.contains("claude") || lower.contains("gpt") {
                    claudeGPTFraction = min(claudeGPTFraction ?? 1.0, fraction)
                    claudeGPTResetsAt = resetsAt ?? claudeGPTResetsAt
                }
            }

            if geminiFraction != nil || geminiResetsAt != nil {
                let fraction = geminiFraction ?? 0.0
                let periodSeconds: TimeInterval? = geminiResetsAt.flatMap { r in
                    let diff = r.timeIntervalSince(fetchedAt)
                    return diff > 0 ? diff : nil
                }
                let refreshDesc = geminiResetsAt.map { QuotaResetText.description(for: $0, relativeTo: fetchedAt) } ?? "重置时间未知"
                windows.append(QuotaWindow(
                    title: "Gemini Models",
                    remainingFraction: max(0, min(1, fraction)),
                    refreshDescription: refreshDesc,
                    resetsAt: geminiResetsAt,
                    periodSeconds: periodSeconds,
                    // fallback 路径下，Antigravity 仍是 2 个独立订阅：Gemini + 其他（Claude/GPT）
                    subscriptionGroup: "Gemini"
                ))
            }

            if claudeGPTFraction != nil || claudeGPTResetsAt != nil {
                let fraction = claudeGPTFraction ?? 0.0
                let periodSeconds: TimeInterval? = claudeGPTResetsAt.flatMap { r in
                    let diff = r.timeIntervalSince(fetchedAt)
                    return diff > 0 ? diff : nil
                }
                let refreshDesc = claudeGPTResetsAt.map { QuotaResetText.description(for: $0, relativeTo: fetchedAt) } ?? "重置时间未知"
                windows.append(QuotaWindow(
                    title: "Claude and GPT models",
                    remainingFraction: max(0, min(1, fraction)),
                    refreshDescription: refreshDesc,
                    resetsAt: claudeGPTResetsAt,
                    periodSeconds: periodSeconds,
                    subscriptionGroup: "Other"
                ))
            }
        }

        if windows.isEmpty {
            throw QuotaFetchError.transient(
                detail: "Antigravity 响应里没有任何 model 配额（账号未登录或未激活？）"
            )
        }

        return ProviderSnapshot(
            kind: .antigravity,
            subscriptionTier: tier,
            availability: .available,
            quotas: windows,
            monthlyPrice: await ProviderPricing.localizedMonthlyPrice(kind: .antigravity, tier: tier),
            fetchedAt: fetchedAt
        )
    }

    // MARK: - 工具

    private static func parseTier(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let userStatus = json["userStatus"] as? [String: Any]
        else {
            return nil
        }
        return parseTier(from: userStatus)
    }

    private static func parseTier(from userStatus: [String: Any]) -> String? {
        let planStatus = userStatus["planStatus"] as? [String: Any]
        let planInfo = planStatus?["planInfo"] as? [String: Any]
        let planName = planInfo?["planName"] as? String ?? ""
        let userTier = userStatus["userTier"] as? [String: Any]
        let userTierName = userTier?["name"] as? String ?? ""
        let teamsTier = planInfo?["teamsTier"] as? String ?? ""

        let lowerPlan = planName.lowercased()
        let lowerUserTier = userTierName.lowercased()

        // 1. userTier.name 中明确出现 Pro/Plus/Ultra 时优先采用
        //    description 经常包含升级引导（如 "upgrade to Pro"），不能作为直接证据。
        if let explicit = explicitTier(in: userTierName) {
            return explicit
        }

        // 2. 启发式：planInfo.planName 显示 "Pro" 但 userTier 是 Starter Quota 时，
        //    实际 Google AI 订阅往往是 Plus（$4.99），而不是 Antigravity 工作区层面的 Pro。
        //    因为 Starter Quota 通常对应 Free / Google AI Plus 用户的基础配额。
        if lowerPlan.contains("pro"),
           lowerUserTier.contains("starter")
        {
            return "Plus"
        }

        // 3. planInfo.planName
        if let tier = normalizedTierKeyword(planName) {
            return tier
        }

        // 4. userTier.name（清理后）
        let cleanedUserTier = userTierName
            .replacingOccurrences(of: "Antigravity ", with: "")
            .replacingOccurrences(of: "Antigravity", with: "")
            .trimmingCharacters(in: .whitespaces)
        if let tier = normalizedTierKeyword(cleanedUserTier) {
            return tier
        }

        // 5. teamsTier
        if !teamsTier.isEmpty {
            let cleanTier = teamsTier.replacingOccurrences(of: "TEAMS_TIER_", with: "")
            return normalizedTierKeyword(cleanTier) ?? cleanTier.capitalized
        }

        return nil
    }

    private static func explicitTier(in text: String) -> String? {
        let lower = text.lowercased()
        if lower.contains("ultra") { return "Ultra" }
        if lower.contains("pro") && !lower.contains("promo") { return "Pro" }
        if lower.contains("plus") { return "Plus" }
        return nil
    }

    private static func normalizedTierKeyword(_ text: String) -> String? {
        let lower = text.lowercased()
        if lower.contains("ultra") { return "Ultra" }
        if lower.contains("pro") { return "Pro" }
        if lower.contains("plus") { return "Plus" }
        return nil
    }

    private static func parseFraction(_ value: Any?) -> Double {
        if let num = value as? NSNumber { return num.doubleValue }
        if let d = value as? Double { return d }
        if let s = value as? String, let d = Double(s) { return d }
        return 0.0
    }

    private static func windowPeriodSeconds(_ window: String) -> TimeInterval? {
        switch window.lowercased() {
        case "five_hour", "5h", "five-hour": return 5 * 3600
        case "weekly": return 7 * 86400
        case "daily": return 86400
        case "monthly": return 30 * 86400
        default: return nil
        }
    }

    private static func parseISO8601(_ s: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: s) ?? ISO8601DateFormatter().date(from: s)
    }

    private static func makeTrustingSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config, delegate: TrustingURLSessionDelegate(), delegateQueue: nil)
    }
}

// MARK: - 端点模型

private struct AntigravityEndpoint {
    let scheme: String
    let host: String
    let port: Int
    let csrfToken: String
    let requiresCSRF: Bool

    func url(path: String) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.port = port
        components.path = path
        if !csrfToken.isEmpty {
            components.queryItems = [URLQueryItem(name: "csrf", value: csrfToken)]
        }
        return components.url!
    }
}

// MARK: - 自签名证书信任

private final class TrustingURLSessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate, @unchecked Sendable {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }
}

// MARK: - 命令运行抽象

protocol CommandRunning: Sendable {
    func run(_ executable: String, _ arguments: [String]) async throws -> CommandResult
}

struct CommandResult: Sendable {
    let stdout: String
    let stderr: String
    let exitCode: Int32
}

/// 默认实现：用 `Process` 跑命令（非 PTY，足够 pgrep/lsof/ps 这种一次性查询）。
struct SystemCommandRunner: CommandRunning {
    func run(_ executable: String, _ arguments: [String]) async throws -> CommandResult {
        let result = try await TTYCommandRunner.runNonPTY(executable: executable, arguments: arguments, timeout: 5)
        return CommandResult(stdout: result.stdout, stderr: result.stderr, exitCode: result.exitCode)
    }
}
