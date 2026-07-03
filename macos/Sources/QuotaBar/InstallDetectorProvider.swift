import Foundation
import AppKit

/// 「已安装」探测 Provider。
///
/// 作为 pipeline 的第一步：先确认本机**至少有 App/CLI/env 凭证**之一，
/// 否则直接 `sourceUnavailable` → `.notInstalled` → UI 过滤掉。
///
/// 解决的核心问题：
/// - 本机**完全没装**的服务（比如 Claude，没 App 没 CLI 也没 web 登录）
///   不应该出现在 dashboard 里。
/// - 但只要检测到任何一种存在方式，就以 `needsConfiguration` 显示，
///   让用户知道「我装了/有凭证，但 dashboard 数据没拿到」。
///
/// 检测项：
/// 1. **App Bundle**：用 `NSWorkspace` + 候选 App 名探测（沿用 `AppBundleProvider` 思路）；
/// 2. **CLI 命令**：`kind.cliCommand` 指定的可执行命令是否在 PATH；
/// 3. **环境变量凭证**：`kind.envVarNames` 列出的环境变量是否有值。
final class InstallDetectorProvider: QuotaProvider, @unchecked Sendable {
    struct InstallDetection: Sendable, Hashable {
        let sourceKind: ProviderSourceKind
        let sourceId: String
        let detail: String
        let metadata: [String: String]
    }

    let id: String
    let kind: ProviderKind
    var displayName: String { kind.displayName }

    /// App 在文件系统的可能名字（不含 `.app` 后缀），用于 fallback 探测。
    private let candidateAppNames: [String]

    init(id: String, kind: ProviderKind, candidateAppNames: [String] = []) {
        self.id = id
        self.kind = kind
        self.candidateAppNames = candidateAppNames
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let detections = detectSources()

        guard !detections.isEmpty else {
            throw QuotaFetchError.sourceUnavailable(
                detail: "未检测到 \(kind.displayName) 的 App/CLI/凭证"
            )
        }

        return ProviderSnapshot(
            kind: kind,
            availability: .needsConfiguration(reason: detections.map(\.detail).joined(separator: "；")),
            quotas: [],
            monthlyPrice: nil,
            fetchedAt: Date()
        )
    }

    func detectSources(preferredSourceId: String? = nil) -> [InstallDetection] {
        if let preferredSourceId,
           let detection = detectPreferredSource(sourceId: preferredSourceId) {
            return [detection]
        }

        var detections: [InstallDetection] = []

        if let appPath = findAppPath() {
            detections.append(InstallDetection(
                sourceKind: .appBundle,
                sourceId: "appBundle:\(kind.bundleIdentifier ?? appPath)",
                detail: "App 已装（\(appPath)）",
                metadata: ["path": appPath]
            ))
        }

        if let command = kind.cliCommand, let path = findCommand(command) {
            detections.append(InstallDetection(
                sourceKind: .cli,
                sourceId: "cli:\(command)",
                detail: "CLI 已装（\(path)）",
                metadata: ["command": command, "path": path]
            ))
        }

        for envName in kind.envVarNames {
            if let value = ProcessInfo.processInfo.environment[envName], !value.isEmpty {
                detections.append(InstallDetection(
                    sourceKind: .environment,
                    sourceId: "environment:\(envName)",
                    detail: "\(envName) 已配置",
                    metadata: ["name": envName]
                ))
            }
        }

        for path in kind.credentialFiles {
            let expanded = (path as NSString).expandingTildeInPath
            if FileManager.default.fileExists(atPath: expanded) {
                detections.append(InstallDetection(
                    sourceKind: .configFile,
                    sourceId: "configFile:\(path)",
                    detail: "凭证文件存在（\(path)）",
                    metadata: ["path": path]
                ))
            }
        }

        return prioritize(detections)
    }

    private func detectPreferredSource(sourceId: String) -> InstallDetection? {
        if sourceId.hasPrefix("appBundle:"),
           let appPath = findAppPath() {
            return InstallDetection(
                sourceKind: .appBundle,
                sourceId: "appBundle:\(kind.bundleIdentifier ?? appPath)",
                detail: "App 已装（\(appPath)）",
                metadata: ["path": appPath]
            )
        }

        if sourceId.hasPrefix("cli:") {
            let command = String(sourceId.dropFirst("cli:".count))
            if let path = findCommand(command) {
                return InstallDetection(
                    sourceKind: .cli,
                    sourceId: "cli:\(command)",
                    detail: "CLI 已装（\(path)）",
                    metadata: ["command": command, "path": path]
                )
            }
        }

        if sourceId.hasPrefix("environment:") {
            let name = String(sourceId.dropFirst("environment:".count))
            if let value = ProcessInfo.processInfo.environment[name], !value.isEmpty {
                return InstallDetection(
                    sourceKind: .environment,
                    sourceId: "environment:\(name)",
                    detail: "\(name) 已配置",
                    metadata: ["name": name]
                )
            }
        }

        if sourceId.hasPrefix("configFile:") {
            let rawPath = String(sourceId.dropFirst("configFile:".count))
            let expanded = (rawPath as NSString).expandingTildeInPath
            if FileManager.default.fileExists(atPath: expanded) {
                return InstallDetection(
                    sourceKind: .configFile,
                    sourceId: "configFile:\(rawPath)",
                    detail: "凭证文件存在（\(rawPath)）",
                    metadata: ["path": rawPath]
                )
            }
        }

        return nil
    }

    private func prioritize(_ detections: [InstallDetection]) -> [InstallDetection] {
        let rank: (ProviderSourceKind) -> Int = { sourceKind in
            switch sourceKind {
            case .configFile: return 0
            case .appBundle: return 1
            case .cli: return 2
            case .environment: return 3
            case .api, .rpc, .browserCookie, .keychain, .localLog, .unknown: return 4
            }
        }
        return detections.sorted {
            let ra = rank($0.sourceKind)
            let rb = rank($1.sourceKind)
            if ra != rb { return ra < rb }
            return $0.sourceId < $1.sourceId
        }
    }

    // MARK: - App 路径搜索

    private func findAppPath() -> String? {
        let home = NSHomeDirectory()
        let searchDirs = [
            "/Applications",
            "/Applications/Utilities",
            "\(home)/Applications",
            "\(home)/Applications/Utilities",
        ]

        if let bundleID = kind.bundleIdentifier,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return url.path
        }

        for name in candidateAppNames {
            for dir in searchDirs {
                let candidate = "\(dir)/\(name).app"
                if FileManager.default.fileExists(atPath: candidate) {
                    return candidate
                }
            }
        }

        return nil
    }

    // MARK: - CLI 探测

    private func findCommand(_ command: String) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = [command]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let path = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if let path, !path.isEmpty {
                    return path
                }
            }
        } catch {
            return nil
        }
        return nil
    }
}
