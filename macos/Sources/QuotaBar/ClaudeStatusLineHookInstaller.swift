import Foundation

/// 把一个极小的脚本注册为 Claude Code 的 `statusLine` hook 命令。
///
/// **原理**（经开源项目 [ping-island](https://github.com/erha19/ping-island) 源码
/// 交叉验证，`PingIsland/Services/Hooks/HookInstaller.swift`）：Claude Code CLI
/// 在交互会话里每次渲染终端状态栏时，会把一份 JSON 通过 stdin 喂给
/// `~/.claude/settings.json` 里配置的 `statusLine.command`，其中包含
/// `rate_limits.{five_hour,seven_day}`——跟 Claude Code 自己 `/usage` 面板展示的
/// 是同一份数据。这条路径不需要 OAuth token、不需要 Keychain、不需要每次刷新
/// 拉起子进程——写脚本时捕获一次，之后只是纯文件读取。
///
/// **代价**：
/// - 只有在用户有过（或正在有）交互式 Claude Code 会话时，缓存才会被写入/刷新；
///   长时间没跑过 `claude` 时缓存会变陈旧，由 `ClaudeStatusLineUsageProvider`
///   按 mtime 判断新鲜度。
/// - 需要修改用户的 `~/.claude/settings.json`——因此本安装器**只在用户在偏好设置
///   里显式打开开关时才执行**，不随 App 启动静默生效；关闭开关会移除脚本引用。
/// - 如果用户已经有自己的 statusLine 配置（不是本安装器写的），本安装器不会
///   覆盖它，也不会尝试串联多个 statusLine 命令——这种情况下额度捕获不会生效，
///   与 ping-island 的行为一致（优先尊重用户已有配置）。
struct ClaudeStatusLineHookInstaller {
    static let shared = ClaudeStatusLineHookInstaller()

    let settingsPath: String
    let scriptDirectory: String
    let scriptName: String
    let cacheDirectory: String

    init(
        settingsPath: String? = nil,
        scriptDirectory: String? = nil,
        scriptName: String = "claude-statusline.sh",
        cacheDirectory: String? = nil
    ) {
        self.settingsPath = settingsPath ?? NSHomeDirectory() + "/.claude/settings.json"
        self.scriptDirectory = scriptDirectory ?? NSHomeDirectory() + "/Library/Application Support/QuotaBar/hooks"
        self.scriptName = scriptName
        self.cacheDirectory = cacheDirectory ?? NSHomeDirectory() + "/Library/Application Support/QuotaBar"
    }

    var scriptPath: String {
        scriptDirectory + "/" + scriptName
    }

    /// statusLine 缓存文件路径（脚本写入、`ClaudeStatusLineUsageProvider` 读取）。
    var cachePath: String {
        cacheDirectory + "/claude-statusline-cache.json"
    }

    enum InstallResult: Equatable {
        case installed
        /// 用户已有别的 statusLine 配置，未覆盖，额度捕获不会生效。
        case skippedExistingStatusLine
        case failed(String)
    }

    @discardableResult
    func install() -> InstallResult {
        do {
            try writeScript()
        } catch {
            return .failed("写入脚本失败：\(error.localizedDescription)")
        }

        var json = (try? readSettingsJSON()) ?? [:]
        if let existing = json["statusLine"] as? [String: Any], !isManagedStatusLine(existing) {
            return .skippedExistingStatusLine
        }
        json["statusLine"] = ["type": "command", "command": scriptPath]
        do {
            try writeSettingsJSON(json)
        } catch {
            return .failed("写入 \(settingsPath) 失败：\(error.localizedDescription)")
        }
        return .installed
    }

    /// 关闭开关时调用：只移除「本安装器写入的」statusLine 引用，不动用户自己的配置；
    /// 脚本文件本身保留（无害，未被引用就不会再被调用）。
    func uninstall() {
        guard var json = try? readSettingsJSON(),
              let existing = json["statusLine"] as? [String: Any],
              isManagedStatusLine(existing)
        else { return }
        json.removeValue(forKey: "statusLine")
        try? writeSettingsJSON(json)
    }

    private func isManagedStatusLine(_ statusLine: [String: Any]) -> Bool {
        (statusLine["command"] as? String) == scriptPath
    }

    private func readSettingsJSON() throws -> [String: Any] {
        let data = try Data(contentsOf: URL(fileURLWithPath: settingsPath))
        return (try JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    private func writeSettingsJSON(_ json: [String: Any]) throws {
        try FileManager.default.createDirectory(
            at: URL(fileURLWithPath: settingsPath).deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: URL(fileURLWithPath: settingsPath), options: .atomic)
    }

    /// 脚本本身不依赖 `jq`（不能假设全网用户都装了它）：用 POSIX `grep`/`sed`
    /// 做最基本的展示文本提取，真正的 JSON 解析全部留给 Swift 侧
    /// （`ClaudeStatusLineUsageProvider`）。
    private func writeScript() throws {
        try FileManager.default.createDirectory(
            at: URL(fileURLWithPath: scriptDirectory),
            withIntermediateDirectories: true
        )
        let script = """
        #!/bin/bash
        # 由 Quota Bar 自动生成/管理，见 ClaudeStatusLineHookInstaller.swift。
        # 捕获 Claude Code statusLine payload（含 rate_limits）到本地缓存文件，
        # 供 Quota Bar 读取额度；不依赖 jq，只用 POSIX 工具。
        input="$(cat)"
        mkdir -p "\(cacheDirectory)"
        printf '%s' "$input" > "\(cachePath)"
        model="$(printf '%s' "$input" | grep -o '"display_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\\1/')"
        if [ -n "$model" ]; then
          printf '[%s] Quota Bar' "$model"
        else
          printf 'Quota Bar'
        fi
        """
        let url = URL(fileURLWithPath: scriptPath)
        try Data(script.utf8).write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    }
}
