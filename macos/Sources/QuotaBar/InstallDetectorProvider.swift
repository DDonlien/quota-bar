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
        let detections = await detectSources()

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

    func detectSources(preferredSourceId: String? = nil) async -> [InstallDetection] {
        if let preferredSourceId,
           let detection = await detectPreferredSource(sourceId: preferredSourceId) {
            await ProviderCheckLog.shared.record(
                kind: kind, step: .provider, method: detection.sourceKind.checkLogLabel,
                outcome: .success, detail: "命中上次成功来源缓存（\(detection.sourceId)）：\(detection.detail)"
            )
            return [detection]
        }
        if let preferredSourceId {
            await ProviderCheckLog.shared.record(
                kind: kind, step: .provider, method: "上次成功来源索引",
                outcome: .failure, detail: "缓存来源（\(preferredSourceId)）已失效，回退到默认顺序全量探测"
            )
        }

        var detections: [InstallDetection] = []

        if !candidateAppNames.isEmpty || kind.bundleIdentifier != nil {
            if let appPath = findAppPath() {
                detections.append(InstallDetection(
                    sourceKind: .appBundle,
                    sourceId: "appBundle:\(kind.bundleIdentifier ?? appPath)",
                    detail: "App 已装（\(appPath)）",
                    metadata: ["path": appPath]
                ))
                await ProviderCheckLog.shared.record(kind: kind, step: .provider, method: "App Bundle", outcome: .success, detail: appPath)
            } else {
                await ProviderCheckLog.shared.record(kind: kind, step: .provider, method: "App Bundle", outcome: .failure, detail: "未找到")
            }
        }

        // 同一服务的 CLI 在不同安装渠道叫不同名字（mmx/minimax、agy/antigravity），
        // 按候选顺序探测，命中第一个即止（同类同优先级，不重复登记）；未命中的候选
        // 也逐个记录，如实反映实际探测顺序。
        var cliHit = false
        for command in kind.cliCommands {
            if cliHit {
                await ProviderCheckLog.shared.record(kind: kind, step: .provider, method: "CLI 命令 \(command)", outcome: .skipped, detail: "已命中同类候选，不再检查")
                continue
            }
            if let path = await findCommand(command) {
                detections.append(InstallDetection(
                    sourceKind: .cli,
                    sourceId: "cli:\(command)",
                    detail: "CLI 已装（\(path)）",
                    metadata: ["command": command, "path": path]
                ))
                await ProviderCheckLog.shared.record(kind: kind, step: .provider, method: "CLI 命令 \(command)", outcome: .success, detail: path)
                cliHit = true
            } else {
                await ProviderCheckLog.shared.record(kind: kind, step: .provider, method: "CLI 命令 \(command)", outcome: .failure, detail: "未找到")
            }
        }

        for envName in kind.envVarNames {
            if let value = ProcessInfo.processInfo.environment[envName], !value.isEmpty {
                detections.append(InstallDetection(
                    sourceKind: .environment,
                    sourceId: "environment:\(envName)",
                    detail: "\(envName) 已配置",
                    metadata: ["name": envName]
                ))
                await ProviderCheckLog.shared.record(kind: kind, step: .provider, method: "环境变量 \(envName)", outcome: .success, detail: "已配置")
            } else {
                await ProviderCheckLog.shared.record(kind: kind, step: .provider, method: "环境变量 \(envName)", outcome: .failure, detail: "未配置")
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
                await ProviderCheckLog.shared.record(kind: kind, step: .provider, method: "凭证文件 \(path)", outcome: .success, detail: "文件存在")
            } else {
                await ProviderCheckLog.shared.record(kind: kind, step: .provider, method: "凭证文件 \(path)", outcome: .failure, detail: "文件不存在")
            }
        }

        return prioritize(detections)
    }

    private func detectPreferredSource(sourceId: String) async -> InstallDetection? {
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
            if let path = await findCommand(command) {
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
            case .api, .rpc, .browserCookie, .webViewSession, .keychain, .localLog, .unknown: return 4
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

    /// 委托给 `CLICommandLocator`：先查常见安装目录，找不到再退化到登录 shell
    /// 解析（覆盖 nvm / asdf / pnpm / 任意自定义 PATH），结果按进程生命周期缓存。
    private func findCommand(_ command: String) async -> String? {
        await CLICommandLocator.locate(command)
    }
}
