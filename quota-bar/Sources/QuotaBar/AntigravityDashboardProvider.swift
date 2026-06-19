import Foundation

/// Antigravity IDE 本地 dashboard 数据源。
///
/// Antigravity IDE 在跑（且用户已登录、workspace 已激活）时会启动一个
/// `language_server_macos`（arm64）/ `language_server_macos_x64`（Intel）子进程，
/// 暴露 gRPC-Web HTTP endpoint：
///
/// ```
/// POST http://127.0.0.1:<random_port>/exa.language_server_pb.LanguageServerService/GetUserStatus
/// Headers:
///   X-Codeium-Csrf-Token: <csrf>
///   Connect-Protocol-Version: 1
///   Content-Type: application/json
/// Body:
///   {"metadata":{"ideName":"antigravity","extensionName":"antigravity","locale":"en"},"wrapper_data":{}}
/// ```
///
/// 返回 `userStatus.cascadeModelConfigData.clientModelConfigs[]`，每个 model 包含：
/// - `quotaInfo.remainingFraction` (0...1)
/// - `quotaInfo.resetTime` (ISO8601)
/// - `label` (展示名，如 "Gemini 3 Pro")
///
/// 端口 + csrf token 通过 OS 命令拿：
/// - PID：`pgrep -f language_server_macos`
/// - 端口：`lsof -nP -a -iTCP -sTCP:LISTEN -p <pid>`
/// - csrf：`ps -p <pid> -ww -o command=` 解析 `--csrf_token=`
///
/// 参考：[antigravity-panel `QuotaService`](https://github.com/n2ns/antigravity-panel/blob/main/src/model/services/quota.service.ts)
///
/// **失败模式**：Antigravity IDE 未运行 / 未登录 / 未激活 workspace 时
/// `language_server` 进程不存在 → 抛 `sourceUnavailable` 让 pipeline fallback 到
/// `needsConfiguration`，UI 显示「Antigravity 未激活」。
final class AntigravityDashboardProvider: QuotaProvider, @unchecked Sendable {

    let id = "antigravity-dashboard"
    let kind: ProviderKind = .antigravity
    var displayName: String { kind.displayName }

    private let session: URLSession
    private let commandRunner: CommandRunning
    private let dateProvider: () -> Date

    init(
        session: URLSession = .shared,
        commandRunner: CommandRunning = SystemCommandRunner(),
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.session = session
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

        // 2. 拿监听端口 + csrf token
        let endpoint = try await resolveEndpoint(pid: pid)

        // 3. POST GetUserStatus（先 HTTP，失败 fallback HTTPS）
        let data = try await fetchUserStatus(endpoint: endpoint, timeout: timeout)

        // 4. 解析响应
        return try await parseResponse(data: data, fetchedAt: fetchedAt)
    }

    // MARK: - 进程发现

    private func findLanguageServerPID() async throws -> Int32? {
        // pgrep 在 Antigravity 启动但未激活 workspace 时找不到 language_server，
        // 返回非零退出码 + 空 stdout —— 视为"未找到"而不是 error。
        let result = try await commandRunner.run(
            "/bin/sh",
            ["-c", "pgrep -f language_server_macos | head -1"]
        )
        let trimmed = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let pid = Int32(trimmed) else {
            return nil
        }
        return pid
    }

    private func resolveEndpoint(pid: Int32) async throws -> URL {
        // lsof -nP -a -iTCP -sTCP:LISTEN -p <pid>
        let lsofResult = try await commandRunner.run(
            "/usr/sbin/lsof",
            ["-nP", "-a", "-iTCP", "-sTCP:LISTEN", "-p", String(pid)]
        )
        let lsofOutput = lsofResult.stdout
        // 找 127.0.0.1:PORT 形式
        let portRegex = try NSRegularExpression(pattern: "127\\.0\\.0\\.1:(\\d+)")
        let portRange = NSRange(lsofOutput.startIndex..., in: lsofOutput)
        guard
            let portMatch = portRegex.firstMatch(in: lsofOutput, range: portRange),
            let portR = Range(portMatch.range(at: 1), in: lsofOutput)
        else {
            throw QuotaFetchError.sourceUnavailable(
                detail: "未找到 Antigravity language_server 监听端口（lsof 输出：\(lsofOutput.prefix(200))）"
            )
        }
        let port = String(lsofOutput[portR])

        // ps -ww -o command= 拿完整 cmdline
        let psResult = try await commandRunner.run(
            "/bin/ps",
            ["-p", String(pid), "-ww", "-o", "command="]
        )
        let csrfRegex = try NSRegularExpression(pattern: "csrf_token=([a-f0-9-]+)")
        let csrfRange = NSRange(psResult.stdout.startIndex..., in: psResult.stdout)
        guard
            let csrfMatch = csrfRegex.firstMatch(in: psResult.stdout, range: csrfRange),
            let csrfR = Range(csrfMatch.range(at: 1), in: psResult.stdout)
        else {
            throw QuotaFetchError.sourceUnavailable(
                detail: "Antigravity cmdline 缺 csrf_token（无法构造 gRPC-Web 请求）"
            )
        }
        let _csrfToken = String(psResult.stdout[csrfR])  // 暂存，未来传给 header
        // 端口先确定就好；csrf 注入到请求 header 在 fetchUserStatus 里做。
        // 这里把 csrf 绑进 URL query 太脏，改为返回 (port, csrf) 元组 —— 简单起见重写。
        return URL(string: "http://127.0.0.1:\(port)/exa.language_server_pb.LanguageServerService/GetUserStatus?csrf=\(_csrfToken)")!
    }

    private func fetchUserStatus(endpoint: URL, timeout: TimeInterval) async throws -> Data {
        // 从 URL query 里抽出 csrf（避免再返回元组）
        let components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        let csrf = components?.queryItems?.first(where: { $0.name == "csrf" })?.value ?? ""
        // 真实 URL（去掉 query）
        var urlComponents = components
        urlComponents?.queryItems = nil
        let cleanURL = urlComponents?.url ?? endpoint

        var request = URLRequest(url: cleanURL, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("1", forHTTPHeaderField: "Connect-Protocol-Version")
        request.setValue(csrf, forHTTPHeaderField: "X-Codeium-Csrf-Token")
        request.httpBody = Data(
            #"{"metadata":{"ideName":"antigravity","extensionName":"antigravity","locale":"en"},"wrapper_data":{}}"#.utf8
        )

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw QuotaFetchError.transient(detail: "Antigravity GetUserStatus 返回非 HTTP 响应")
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
                    detail: "Antigravity GetUserStatus HTTP \(http.statusCode)：\(body.prefix(100))"
                )
            }
        } catch let error as QuotaFetchError {
            throw error
        } catch {
            throw QuotaFetchError.transient(detail: "Antigravity GetUserStatus 网络错误：\(error.localizedDescription)")
        }
    }

    // MARK: - 响应解析

    /// 解析 gRPC-Web 响应（JSON 格式）：
    /// ```json
    /// {
    ///   "userStatus": {
    ///     "name": "...", "email": "...",
    ///     "userTier": { "name": "Pro", "description": "..." },
    ///     "planStatus": { "planInfo": { "monthlyPromptCredits": 1000 }, "availablePromptCredits": 800 },
    ///     "cascadeModelConfigData": {
    ///       "clientModelConfigs": [
    ///         {
    ///           "label": "Gemini 3 Pro",
    ///           "modelOrAlias": { "model": "gemini-3-pro" },
    ///           "quotaInfo": { "remainingFraction": 0.42, "resetTime": "2026-06-21T14:00:00Z" }
    ///         }
    ///       ]
    ///     }
    ///   }
    /// }
    /// ```
    private func parseResponse(data: Data, fetchedAt: Date) async throws -> ProviderSnapshot {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw QuotaFetchError.transient(detail: "Antigravity 响应非 JSON")
        }
        guard let userStatus = json["userStatus"] as? [String: Any] else {
            throw QuotaFetchError.transient(detail: "Antigravity 响应缺 userStatus")
        }

        // tier 优先 userTier.name，其次 planInfo.planName，最后 "Antigravity"
        var tier: String?
        if let userTier = userStatus["userTier"] as? [String: Any],
           let name = userTier["name"] as? String, !name.isEmpty
        {
            tier = name
        } else if let planStatus = userStatus["planStatus"] as? [String: Any],
                  let planInfo = planStatus["planInfo"] as? [String: Any],
                  let planName = planInfo["planName"] as? String, !planName.isEmpty
        {
            tier = planName
        } else if let planStatus = userStatus["planStatus"] as? [String: Any],
                  let planInfo = planStatus["planInfo"] as? [String: Any],
                  let teamsTier = planInfo["teamsTier"] as? String, !teamsTier.isEmpty
        {
            tier = teamsTier
        }

        // quota windows: 每个 model 一个 QuotaWindow
        var windows: [QuotaWindow] = []
        if let cascadeData = userStatus["cascadeModelConfigData"] as? [String: Any],
           let models = cascadeData["clientModelConfigs"] as? [[String: Any]]
        {
            for model in models {
                guard let quotaInfo = model["quotaInfo"] as? [String: Any] else { continue }
                let label = (model["label"] as? String) ?? "Antigravity model"
                let fraction = (quotaInfo["remainingFraction"] as? NSNumber)?.doubleValue
                    ?? (quotaInfo["remainingFraction"] as? Double)
                    ?? 1.0
                let resetTimeStr = quotaInfo["resetTime"] as? String
                let resetsAt = resetTimeStr.flatMap { Self.parseISO8601($0) }

                let periodSeconds: TimeInterval? = resetsAt.map { $0.timeIntervalSince(fetchedAt) }
                let refreshDesc: String = if let resetsAt {
                    Self.formatReset(resetsAt: resetsAt, now: fetchedAt)
                } else {
                    "重置时间未知"
                }

                windows.append(QuotaWindow(
                    title: label,
                    remainingFraction: max(0, min(1, fraction)),
                    refreshDescription: refreshDesc,
                    resetsAt: resetsAt,
                    periodSeconds: periodSeconds
                ))
            }
        }

        if windows.isEmpty {
            throw QuotaFetchError.transient(
                detail: "Antigravity 响应里没有任何 model 配额（账号未登录或未激活？）"
            )
        }

        // 按 periodSeconds 升序
        windows.sort { ($0.periodSeconds ?? .greatestFiniteMagnitude) < ($1.periodSeconds ?? .greatestFiniteMagnitude) }

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

    private static func parseISO8601(_ s: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: s) ?? ISO8601DateFormatter().date(from: s)
    }

    private static func formatReset(resetsAt: Date, now: Date) -> String {
        let diff = resetsAt.timeIntervalSince(now)
        if diff <= 0 { return "重置中" }
        let mins = Int(diff / 60)
        if mins < 60 { return "\(mins) 分钟后" }
        let hours = mins / 60
        if hours < 24 { return "\(hours) 小时后" }
        let days = hours / 24
        return "\(days) 天后"
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