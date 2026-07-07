import Foundation

/// Claude 真实 CLI 层：执行 `claude auth status --json` 补档位/登录状态。
///
/// 实测确认（`claude --version` 2.1.201）：`claude auth status --json`（`--json`
/// 是默认输出格式）是非交互、结构化、无副作用的命令，输出形如：
/// ```json
/// {"loggedIn": true, "authMethod": "claude.ai", "apiProvider": "firstParty",
///  "email": "...", "orgId": "...", "orgName": "...", "subscriptionType": "pro"}
/// ```
/// 不返回额度数值——Claude Code 没有类似 `mmx quota show` 的结构化额度 CLI
/// 命令，`/usage` 只存在于交互 TUI（ClaudeBar 为此需要接入 SwiftTerm 渲染终端，
/// 本项目未采用这条更重的路径）。
///
/// 本 provider 只贡献「档位」层：`~/.claude/.credentials.json` 通常已经带
/// `subscriptionType`（见 `ClaudeOAuthUsageProvider`），本 provider 是文件缺失该
/// 字段时的兜底，由 `FetchPipeline` 的分层合并机制在缺档位时才会被调用。
final class ClaudeAuthStatusCLIProvider: QuotaProvider, @unchecked Sendable {
    let id = "claude-auth-status-cli"
    let kind: ProviderKind = .claude
    var displayName: String { kind.displayName }

    /// 命令执行器：输入（可执行路径, 参数），返回 stdout。测试可注入。
    typealias CommandExecutor = @Sendable (String, [String], TimeInterval) async throws -> Data

    /// `nil` = 生产默认，交给 `CLICommandLocator` 动态解析；
    /// 非 nil = 测试专用，只在这些候选路径里找，不走 locator（保证测试确定性）。
    private let explicitCandidates: [String]?
    private let executor: CommandExecutor
    private let dateProvider: () -> Date

    init(
        executablePathCandidates: [String]? = nil,
        executor: CommandExecutor? = nil,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.explicitCandidates = executablePathCandidates
        self.executor = executor ?? Self.runProcess
        self.dateProvider = dateProvider
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let fetchedAt = dateProvider()
        let claudePath: String
        if let explicitCandidates {
            guard let found = explicitCandidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
                throw QuotaFetchError.sourceUnavailable(detail: "未找到 claude CLI（已检查候选路径）")
            }
            claudePath = found
        } else {
            guard let found = await CLICommandLocator.locate("claude") else {
                throw QuotaFetchError.sourceUnavailable(detail: "未找到 claude CLI（已检查常见安装目录及登录 shell PATH）")
            }
            claudePath = found
        }
        let stdout = try await executor(claudePath, ["auth", "status", "--json"], timeout)
        return try await Self.parseStatusOutput(stdout, fetchedAt: fetchedAt)
    }

    static func parseStatusOutput(_ data: Data, fetchedAt: Date) async throws -> ProviderSnapshot {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw QuotaFetchError.transient(detail: "无法解析 claude auth status 输出")
        }
        guard (json["loggedIn"] as? Bool) == true else {
            throw QuotaFetchError.missingCredentials(detail: "claude CLI 未登录，请先运行 claude 登录")
        }
        let subscriptionType = json["subscriptionType"] as? String
        // 只贡献档位，不伪造额度：quotas 留空，交给 mergeLayers 只合并 tier/price。
        // 价格不算"伪造额度"——它是从档位名字静态映射来的公开定价（见
        // `ProviderPricing.usdMonthlyPrice`），跟这里没拿到的额度数值是两回事；
        // 之前这里硬编码成 nil，导致只靠这条 CLI 兜底层拿到档位的用户永远看不到
        // 价格（2026-07-07 由新增的分层诊断日志暴露，日志显示"档位=Pro，
        // 价格=未获取"）。
        return ProviderSnapshot(
            kind: .claude,
            subscriptionTier: ProviderPricing.normalizedTier(subscriptionType),
            availability: .available,
            quotas: [],
            monthlyPrice: await ProviderPricing.localizedMonthlyPrice(kind: .claude, tier: subscriptionType),
            fetchedAt: fetchedAt
        )
    }

    private static let runProcess: CommandExecutor = { path, arguments, timeout in
        try await withThrowingTaskGroup(of: Data.self) { group in
            group.addTask {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
                    DispatchQueue.global(qos: .userInitiated).async {
                        let process = Process()
                        process.executableURL = URL(fileURLWithPath: path)
                        process.arguments = arguments
                        // 继承完整父进程环境（而不是只给 HOME）：`claude auth status`
                        // 读取自身 Keychain/凭证存储时依赖 USER 等变量正确识别当前用户
                        // 身份，替换成精简环境会导致它读不到已登录状态（已实测复现：
                        // 只给 HOME 时报 loggedIn=false，补上 USER 后恢复正常）。
                        process.environment = ProcessInfo.processInfo.environment
                        let stdoutPipe = Pipe()
                        process.standardOutput = stdoutPipe
                        process.standardError = FileHandle.nullDevice
                        do {
                            try process.run()
                        } catch {
                            continuation.resume(throwing: QuotaFetchError.sourceUnavailable(
                                detail: "claude 启动失败：\(error.localizedDescription)"
                            ))
                            return
                        }
                        let output = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                        process.waitUntilExit()
                        continuation.resume(returning: output)
                    }
                }
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw QuotaFetchError.transient(detail: "claude auth status 执行超时（\(Int(timeout))s）")
            }
            guard let first = try await group.next() else {
                throw QuotaFetchError.sourceUnavailable(detail: "claude auth status 无输出")
            }
            group.cancelAll()
            return first
        }
    }
}
