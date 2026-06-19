import Foundation

/// 本地 CLI 日志数据源。
///
/// 当前实现只覆盖 Codex CLI 的会话日志（`~/.codex/sessions/*.jsonl`）。
/// 每行 JSON 形如：
/// ```json
/// {"ts":"2026-06-18T03:14:00Z","usage":{"input_tokens":1234,"output_tokens":567}}
/// ```
///
/// 通过汇总最近 5 小时/最近 7 天的 token 用量，按配额上限估算剩余比例。
/// 如果日志不存在或不可读，抛 `sourceUnavailable` 让聚合器降级为 `notInstalled`。
final class CLILogProvider: QuotaProvider, @unchecked Sendable {

    let id: String
    let kind: ProviderKind
    var displayName: String { kind.displayName }

    private let sessionWindow: TimeInterval
    private let weeklyWindow: TimeInterval
    private let sessionLimit: Int
    private let weeklyLimit: Int
    private let sessionsRoot: URL
    private let fileManager: FileManager
    private let dateProvider: () -> Date

    init(
        id: String,
        kind: ProviderKind,
        sessionWindow: TimeInterval = 5 * 60 * 60,
        weeklyWindow: TimeInterval = 7 * 24 * 60 * 60,
        sessionLimit: Int = 5_000_000,
        weeklyLimit: Int = 50_000_000,
        sessionsRoot: URL? = nil,
        fileManager: FileManager = .default,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.id = id
        self.kind = kind
        self.sessionWindow = sessionWindow
        self.weeklyWindow = weeklyWindow
        self.sessionLimit = sessionLimit
        self.weeklyLimit = weeklyLimit
        self.sessionsRoot = sessionsRoot
            ?? fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent(".codex/sessions", isDirectory: true)
        self.fileManager = fileManager
        self.dateProvider = dateProvider
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        guard fileManager.fileExists(atPath: sessionsRoot.path) else {
            throw QuotaFetchError.sourceUnavailable(
                detail: "未安装"
            )
        }

        let (sessionTokens, weeklyTokens) = try await scanTokenUsage()
        let fetchedAt = dateProvider()

        let sessionFraction = max(0, 1.0 - Double(sessionTokens) / Double(max(sessionLimit, 1)))
        let weeklyFraction = max(0, 1.0 - Double(weeklyTokens) / Double(max(weeklyLimit, 1)))

        return ProviderSnapshot(
            kind: kind,
            availability: .available,
            quotas: [
                QuotaWindow(
                    title: "5小时额度",
                    remainingFraction: sessionFraction,
                    refreshDescription: refreshDescription(window: sessionWindow, fetchedAt: fetchedAt),
                    resetsAt: fetchedAt.addingTimeInterval(sessionWindow),
                    periodSeconds: sessionWindow
                ),
                QuotaWindow(
                    title: "周额度",
                    remainingFraction: weeklyFraction,
                    refreshDescription: refreshDescription(window: weeklyWindow, fetchedAt: fetchedAt),
                    resetsAt: fetchedAt.addingTimeInterval(weeklyWindow),
                    periodSeconds: weeklyWindow
                )
            ],
            monthlyPrice: kind.fallbackMonthlyPrice,
            fetchedAt: fetchedAt
        )
    }

    private func scanTokenUsage() async throws -> (session: Int, weekly: Int) {
        try await Task.detached(priority: .userInitiated) { [sessionsRoot, sessionWindow, weeklyWindow, fileManager] in
            let contents = try fileManager.contentsOfDirectory(
                at: sessionsRoot,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
            let now = Date()
            let weeklyCutoff = now.addingTimeInterval(-weeklyWindow)
            let sessionCutoff = now.addingTimeInterval(-sessionWindow)

            var weeklyTokens = 0
            var sessionTokens = 0

            for fileURL in contents where fileURL.pathExtension == "jsonl" {
                guard let data = try? Data(contentsOf: fileURL, options: [.mappedIfSafe]),
                      let text = String(data: data, encoding: .utf8) else { continue }
                for line in text.split(whereSeparator: \.isNewline) {
                    guard let lineData = line.data(using: .utf8),
                          let entry = try? JSONDecoder.iso.decode(LogEntry.self, from: lineData) else {
                        continue
                    }
                    if entry.timestamp >= weeklyCutoff {
                        weeklyTokens += entry.usage.totalTokens
                    }
                    if entry.timestamp >= sessionCutoff {
                        sessionTokens += entry.usage.totalTokens
                    }
                }
            }
            return (sessionTokens, weeklyTokens)
        }.value
    }

    private func refreshDescription(window: TimeInterval, fetchedAt: Date) -> String {
        return QuotaResetText.description(for: fetchedAt.addingTimeInterval(window), relativeTo: fetchedAt)
    }
}

// MARK: - JSON 形状

private struct LogEntry: Decodable {
    let timestamp: Date
    let usage: Usage

    enum CodingKeys: String, CodingKey {
        case timestamp = "ts"
        case usage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try container.decode(String.self, forKey: .timestamp)
        if let date = ISO8601DateFormatter().date(from: raw) {
            self.timestamp = date
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .timestamp,
                in: container,
                debugDescription: "无效 ISO8601 时间戳：\(raw)"
            )
        }
        self.usage = try container.decode(Usage.self, forKey: .usage)
    }
}

private struct Usage: Decodable {
    let inputTokens: Int
    let outputTokens: Int
    let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case totalTokens = "total_tokens"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.inputTokens = try container.decodeIfPresent(Int.self, forKey: .inputTokens) ?? 0
        self.outputTokens = try container.decodeIfPresent(Int.self, forKey: .outputTokens) ?? 0
        if let total = try container.decodeIfPresent(Int.self, forKey: .totalTokens) {
            self.totalTokens = total
        } else {
            self.totalTokens = self.inputTokens + self.outputTokens
        }
    }
}

private extension JSONDecoder {
    static let iso: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
}
