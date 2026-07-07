import Foundation

/// Antigravity 真实 CLI 层：拉起 `agy` 交互会话后复用其本地 RPC 拿结构化额度。
///
/// 用户视角的 CLI 路径是「`agy` 进入交互 CLI → `/usage` 查看额度」。实现上不去
/// 驱动 TUI / 解析 ANSI 文本（脆弱，且 `agy --print "/usage"` 会把斜杠命令当自然
/// 语言 prompt 发给模型消耗额度，已实测确认），而是利用 agy 交互会话启动时自带
/// 的本地 gRPC-Web endpoint（`/usage` 面板的数据源就是它）：
///
/// 1. 若已有运行中的 agy / language_server 进程，本 provider 不会被走到
///    （管线里排在 `antigravity-rpc` / `antigravity-cli` 之后）；
/// 2. 用 `/usr/bin/script` 给 agy 一个 PTY（无 TTY 时 agy 拒绝启动交互会话）；
/// 3. 轮询等待其本地 RPC 就绪，委托 `AntigravityDashboardProvider(.cli)` 取
///    结构化额度（与 IDE 路径同一套解析）；
/// 4. 成功或超时后立即终止拉起的 agy 进程，不留后台会话。
final class AntigravityCLISessionProvider: QuotaProvider, @unchecked Sendable {

    let id = "antigravity-cli-session"
    let kind: ProviderKind = .antigravity
    var displayName: String { kind.displayName }

    /// 内部 RPC 取数器，默认委托 AntigravityDashboardProvider(.cli)；测试可注入。
    typealias InnerFetcher = @Sendable (TimeInterval) async throws -> ProviderSnapshot

    /// 一个正在运行的托管会话：可查询存活状态、可终止。
    protocol ManagedSession: Sendable {
        var isRunning: Bool { get }
        func terminate()
    }

    /// 会话启动器：给定 agy 可执行路径，拉起交互 PTY 会话。
    typealias SessionLauncher = @Sendable (String) throws -> any ManagedSession

    /// `nil` = 生产默认，交给 `CLICommandLocator` 动态解析；
    /// 非 nil = 测试专用，只在这些候选路径里找，不走 locator（保证测试确定性）。
    private let explicitCandidates: [String]?
    private let innerFetcher: InnerFetcher
    private let launchSession: SessionLauncher
    private let dateProvider: () -> Date
    /// 拉起会话后，第一次尝试 innerFetcher 前的等待（RPC 需要时间就绪）。
    private let initialSettleDelay: TimeInterval
    /// 每次 innerFetcher 失败后的重试间隔。
    private let retryInterval: TimeInterval

    init(
        executablePathCandidates: [String]? = nil,
        innerFetcher: InnerFetcher? = nil,
        launchSession: SessionLauncher? = nil,
        dateProvider: @escaping () -> Date = Date.init,
        initialSettleDelay: TimeInterval = 2,
        retryInterval: TimeInterval = 0.7
    ) {
        self.explicitCandidates = executablePathCandidates
        self.innerFetcher = innerFetcher ?? { timeout in
            try await AntigravityDashboardProvider(
                id: "antigravity-cli-session-rpc",
                processMode: .cli
            ).fetchSnapshot(timeout: timeout)
        }
        self.launchSession = launchSession ?? Self.launchAgyPTYSession
        self.dateProvider = dateProvider
        self.initialSettleDelay = initialSettleDelay
        self.retryInterval = retryInterval
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let agyPath: String
        if let explicitCandidates {
            guard let found = explicitCandidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
                throw QuotaFetchError.sourceUnavailable(detail: "未找到 agy CLI（已检查候选路径）")
            }
            agyPath = found
        } else {
            guard let found = await CLICommandLocator.locate("agy") else {
                throw QuotaFetchError.sourceUnavailable(detail: "未找到 agy CLI（已检查常见安装目录及登录 shell PATH）")
            }
            agyPath = found
        }

        let session = try launchSession(agyPath)
        defer { session.terminate() }

        if initialSettleDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(initialSettleDelay * 1_000_000_000))
        }

        let deadline = dateProvider().addingTimeInterval(max(initialSettleDelay + 1, timeout - 1))
        var lastError: Error = QuotaFetchError.transient(detail: "agy 会话 RPC 未在超时内就绪")
        while dateProvider() < deadline {
            guard session.isRunning else {
                throw QuotaFetchError.transient(detail: "agy 会话提前退出（可能未登录，先在终端跑一次 agy）")
            }
            do {
                return try await innerFetcher(3)
            } catch {
                lastError = error
                try? await Task.sleep(nanoseconds: UInt64(retryInterval * 1_000_000_000))
                continue
            }
        }
        throw (lastError as? QuotaFetchError)
            ?? QuotaFetchError.transient(detail: lastError.localizedDescription)
    }

    // MARK: - 默认 PTY 会话实现

    private final class AgyProcessSession: ManagedSession, @unchecked Sendable {
        private let process: Process
        private let stdinPipe: Pipe
        private let preexistingPIDs: Set<pid_t>

        init(process: Process, stdinPipe: Pipe, preexistingPIDs: Set<pid_t>) {
            self.process = process
            self.stdinPipe = stdinPipe
            self.preexistingPIDs = preexistingPIDs
        }

        var isRunning: Bool { process.isRunning }

        func terminate() {
            process.terminate()
            for pid in AntigravityCLISessionProvider.agyPIDs().subtracting(preexistingPIDs) {
                kill(pid, SIGTERM)
            }
            try? stdinPipe.fileHandleForWriting.close()
        }
    }

    private static func launchAgyPTYSession(agyPath: String) throws -> any ManagedSession {
        let preexistingPIDs = agyPIDs()

        let process = Process()
        // /usr/bin/script 提供 PTY，agy 交互会话才会启动（并拉起本地 RPC endpoint）。
        process.executableURL = URL(fileURLWithPath: "/usr/bin/script")
        process.arguments = ["-q", "/dev/null", agyPath]
        let stdinPipe = Pipe()  // 保持打开但不写入，避免 agy 读到 EOF 立即退出
        process.standardInput = stdinPipe
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            throw QuotaFetchError.sourceUnavailable(detail: "agy 启动失败：\(error.localizedDescription)")
        }
        return AgyProcessSession(process: process, stdinPipe: stdinPipe, preexistingPIDs: preexistingPIDs)
    }

    /// 当前所有 agy 进程 pid。
    private static func agyPIDs() -> Set<pid_t> {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-x", "agy"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return [] }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let pids = String(data: data, encoding: .utf8)?
            .split(separator: "\n")
            .compactMap { pid_t($0.trimmingCharacters(in: .whitespaces)) } ?? []
        return Set(pids)
    }
}
