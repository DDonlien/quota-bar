import Foundation
import AppKit

// MARK: - 版本模型（v0.11.0-FE-A-001/003）

/// GitHub Release tag 的两种发布通道。
enum UpdateChannel: String, Sendable {
    /// `vX.Y.Z` 形式的稳定版。
    case stable
    /// `nightly-<sha>` 形式的每日构建。
    case nightly
}

/// 语义化版本三段（不含 prerelease；`v0.11.0-rc1` 不算 stable）。
struct SemanticVersion: Comparable, Equatable, Sendable, CustomStringConvertible {
    let major: Int
    let minor: Int
    let patch: Int

    var description: String { "\(major).\(minor).\(patch)" }

    /// 解析 `v0.11.0` / `0.11.0`。带 prerelease 后缀（`-rc1`）返回 nil。
    init?(tag: String) {
        var raw = tag
        if raw.hasPrefix("v") { raw.removeFirst() }
        let parts = raw.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let major = Int(parts[0]),
              let minor = Int(parts[1]),
              let patch = Int(parts[2]),
              major >= 0, minor >= 0, patch >= 0
        else { return nil }
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
}

/// 一条可安装的远端 release。
struct UpdateCandidate: Equatable, Sendable {
    let tag: String
    let channel: UpdateChannel
    let semanticVersion: SemanticVersion?
    /// GitHub release 的发布时间，nightly 之间用它比新旧。
    let publishedAt: Date
    let releaseURL: URL
    /// dmg 资产下载地址；没有 dmg 资产的 release 不可自动安装。
    let assetURL: URL?
    let assetName: String?
    /// release body 截断后的变更摘要。
    let releaseNotes: String
}

// MARK: - GitHub Releases 解析

enum UpdateReleaseParser {
    static let semverTagPattern = #"^v\d+\.\d+\.\d+$"#
    static let nightlyTagPattern = #"^nightly-[0-9a-f]{7,40}$"#

    struct GitHubRelease: Decodable {
        struct Asset: Decodable {
            let name: String
            let browser_download_url: String
        }

        let tag_name: String
        let html_url: String
        let body: String?
        let draft: Bool
        let prerelease: Bool
        let published_at: String?
        let assets: [Asset]
    }

    /// 把 GitHub Releases API 响应解析为按通道分类的候选列表。
    /// draft 一律跳过；`prerelease == true` 只允许 nightly tag（semver 的 rc 等不进 stable 通道）。
    static func parse(data: Data) -> [UpdateCandidate] {
        guard let releases = try? JSONDecoder().decode([GitHubRelease].self, from: data) else {
            return []
        }
        let isoFraction = ISO8601DateFormatter()
        isoFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let iso = ISO8601DateFormatter()

        var candidates: [UpdateCandidate] = []
        for release in releases where !release.draft {
            let tag = release.tag_name
            let channel: UpdateChannel
            var semantic: SemanticVersion?
            if tag.range(of: semverTagPattern, options: .regularExpression) != nil,
               let version = SemanticVersion(tag: tag) {
                channel = .stable
                semantic = version
            } else if tag.range(of: nightlyTagPattern, options: .regularExpression) != nil {
                channel = .nightly
            } else {
                continue
            }
            guard let releaseURL = URL(string: release.html_url) else { continue }
            let publishedAt = release.published_at.flatMap {
                isoFraction.date(from: $0) ?? iso.date(from: $0)
            } ?? .distantPast
            let dmgAsset = release.assets.first { $0.name.lowercased().hasSuffix(".dmg") }
            candidates.append(UpdateCandidate(
                tag: tag,
                channel: channel,
                semanticVersion: semantic,
                publishedAt: publishedAt,
                releaseURL: releaseURL,
                assetURL: dmgAsset.flatMap { URL(string: $0.browser_download_url) },
                assetName: dmgAsset?.name,
                releaseNotes: Self.trimmedNotes(release.body)
            ))
        }
        return candidates
    }

    /// body 截前 500 字并去掉 markdown 强调符号（v0.11.0-FE-A-008）。
    static func trimmedNotes(_ body: String?) -> String {
        guard var text = body?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return ""
        }
        for token in ["**", "__", "`", "###", "##", "#"] {
            text = text.replacingOccurrences(of: token, with: "")
        }
        if text.count > 500 {
            text = String(text.prefix(500)) + "…"
        }
        return text
    }

    /// 在候选中挑「当前版本视角下应推荐的更新」。
    ///
    /// 规则（v0.11.0-FE-A-003）：
    /// - 当前是 semver 版：只推荐更高的 semver stable；
    /// - 当前是 nightly（`CFBundleShortVersionString == "1.0"` 的开发/每日构建）：
    ///   有任何 semver stable 就优先推荐 stable，否则推荐比当前构建时间新的 nightly；
    /// - 找不到就返回 nil（已是最新）。
    static func pickUpdate(
        candidates: [UpdateCandidate],
        currentVersion: String,
        currentBuildDate: Date?
    ) -> UpdateCandidate? {
        let stable = candidates
            .filter { $0.channel == .stable && $0.assetURL != nil }
            .sorted { ($0.semanticVersion ?? SemanticVersion(tag: "v0.0.0")!) > ($1.semanticVersion ?? SemanticVersion(tag: "v0.0.0")!) }
        let nightly = candidates
            .filter { $0.channel == .nightly && $0.assetURL != nil }
            .sorted { $0.publishedAt > $1.publishedAt }

        if let currentSemantic = SemanticVersion(tag: currentVersion) {
            // 当前是稳定版：只比 semver。
            if let best = stable.first,
               let bestVersion = best.semanticVersion,
               bestVersion > currentSemantic {
                return best
            }
            return nil
        }

        // 当前是 nightly / 开发构建：stable 永远优先推荐。
        if let best = stable.first {
            return best
        }
        if let bestNightly = nightly.first {
            if let buildDate = currentBuildDate {
                // 加 10 分钟余量，避免同一次 CI 构建被误判为新版本。
                return bestNightly.publishedAt > buildDate.addingTimeInterval(10 * 60) ? bestNightly : nil
            }
            return bestNightly
        }
        return nil
    }

    /// 从 `CFBundleVersion`（`YYMMDD.HHMMSS`）解析本地构建时间。
    static func buildDate(fromBundleVersion bundleVersion: String?) -> Date? {
        guard let bundleVersion else { return nil }
        let parts = bundleVersion.split(separator: ".")
        guard parts.count >= 2, parts[0].count == 6, parts[1].count == 6 else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMdd.HHmmss"
        formatter.timeZone = .current
        return formatter.date(from: "\(parts[0]).\(parts[1])")
    }
}

// MARK: - UpdateChecker（v0.11.0-FE-A-000...012）

@MainActor
final class UpdateChecker: NSObject, ObservableObject {
    enum State: Equatable {
        case idle
        case checking
        case updateAvailable(UpdateCandidate)
        case downloading(progress: Double)
        case verifying
        case downloaded(UpdateCandidate, dmgPath: URL)
        case installing
        case upToDate(currentVersion: String)
        case error(message: String)
    }

    static let shared = UpdateChecker()

    @Published private(set) var state: State = .idle

    /// GitHub Releases API 地址（测试可注入 mock URLProtocol 的 session）。
    private let releasesURL: URL
    private let session: URLSession
    private let preferences: PreferencesStore
    private var downloadTask: URLSessionDownloadTask?
    private var downloadCandidate: UpdateCandidate?

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    var currentBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }

    init(
        releasesURL: URL = URL(string: "https://api.github.com/repos/DDonlien/quota-bar/releases?per_page=30")!,
        session: URLSession? = nil,
        preferences: PreferencesStore = .shared
    ) {
        self.releasesURL = releasesURL
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 10
            self.session = URLSession(configuration: config)
        }
        self.preferences = preferences
        super.init()
    }

    // MARK: 检查

    /// 触发一次检查。`userInitiated == false`（关于页自动触发）时 5 分钟内不重复请求。
    func check(userInitiated: Bool = false) {
        if case .checking = state { return }
        if case .downloading = state { return }
        if case .installing = state { return }
        if !userInitiated,
           let last = preferences.preferences.lastUpdateCheck,
           Date().timeIntervalSince(last) < 5 * 60 {
            return
        }

        state = .checking
        Task { [weak self] in
            await self?.performCheck(userInitiated: userInitiated)
        }
    }

    private func performCheck(userInitiated: Bool) async {
        var request = URLRequest(url: releasesURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("QuotaBar", forHTTPHeaderField: "User-Agent")

        let data: Data
        do {
            let (body, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                state = .error(message: "无法连接到 GitHub，请检查网络")
                return
            }
            if http.statusCode == 403,
               (http.value(forHTTPHeaderField: "X-RateLimit-Remaining") ?? "") == "0" {
                state = .error(message: "检查过于频繁，请稍后重试")
                return
            }
            guard (200..<300).contains(http.statusCode) else {
                state = .error(message: "无法连接到 GitHub，请检查网络")
                return
            }
            data = body
        } catch {
            state = .error(message: "无法连接到 GitHub，请检查网络")
            return
        }

        preferences.setLastUpdateCheck(Date())

        let candidates = UpdateReleaseParser.parse(data: data)
        let buildDate = UpdateReleaseParser.buildDate(fromBundleVersion: currentBuild)
        guard var update = UpdateReleaseParser.pickUpdate(
            candidates: candidates,
            currentVersion: currentVersion,
            currentBuildDate: buildDate
        ) else {
            state = .upToDate(currentVersion: currentVersion)
            return
        }

        // 用户主动点「检查更新」时无视忽略列表；自动检查尊重忽略列表。
        if !userInitiated, preferences.preferences.ignoredVersions.contains(update.tag) {
            state = .upToDate(currentVersion: currentVersion)
            return
        }
        // 避免 body 为空时 UI 出现空段落。
        if update.releaseNotes.isEmpty {
            update = UpdateCandidate(
                tag: update.tag,
                channel: update.channel,
                semanticVersion: update.semanticVersion,
                publishedAt: update.publishedAt,
                releaseURL: update.releaseURL,
                assetURL: update.assetURL,
                assetName: update.assetName,
                releaseNotes: "（该版本没有提供变更说明）"
            )
        }
        state = .updateAvailable(update)
    }

    // MARK: 稍后提醒 / 忽略

    func ignoreCurrentUpdate() {
        if case .updateAvailable(let candidate) = state {
            preferences.ignoreVersion(candidate.tag)
        }
        state = .idle
    }

    func resetIgnoredVersions() {
        preferences.resetIgnoredVersions()
    }

    // MARK: 下载

    func downloadAndInstall() {
        guard case .updateAvailable(let candidate) = state,
              let assetURL = candidate.assetURL else {
            return
        }
        downloadCandidate = candidate
        state = .downloading(progress: 0)

        let task = session.downloadTask(with: assetURL) { [weak self] tempURL, response, error in
            Task { @MainActor [weak self] in
                self?.handleDownloadCompletion(tempURL: tempURL, response: response, error: error)
            }
        }
        downloadTask = task
        observeProgress(of: task)
        task.resume()
    }

    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        if let candidate = downloadCandidate {
            state = .updateAvailable(candidate)
        } else {
            state = .idle
        }
    }

    private var progressObservation: NSKeyValueObservation?

    private func observeProgress(of task: URLSessionDownloadTask) {
        progressObservation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            Task { @MainActor [weak self] in
                guard let self, case .downloading = self.state else { return }
                self.state = .downloading(progress: progress.fractionCompleted)
            }
        }
    }

    private func handleDownloadCompletion(tempURL: URL?, response: URLResponse?, error: Error?) {
        progressObservation = nil
        downloadTask = nil
        guard let candidate = downloadCandidate else {
            state = .idle
            return
        }
        if error != nil {
            state = .error(message: "下载失败，请稍后重试或前往 GitHub 手动下载")
            return
        }
        guard let tempURL else {
            state = .error(message: "下载失败，请稍后重试或前往 GitHub 手动下载")
            return
        }

        // 移动到 ~/Library/Application Support/QuotaBar/updates/
        let updatesDir = Self.updatesDirectory()
        let fileName = candidate.assetName ?? "QuotaBar-\(candidate.tag).dmg"
        let target = updatesDir.appendingPathComponent(fileName)
        do {
            try FileManager.default.createDirectory(at: updatesDir, withIntermediateDirectories: true)
            try? FileManager.default.removeItem(at: target)
            try FileManager.default.moveItem(at: tempURL, to: target)
        } catch {
            state = .error(message: "无法保存更新文件：\(error.localizedDescription)")
            return
        }

        state = .verifying
        Task { [weak self] in
            await self?.verifyDownloadedDMG(candidate: candidate, dmgPath: target)
        }
    }

    private func verifyDownloadedDMG(candidate: UpdateCandidate, dmgPath: URL) async {
        // ad-hoc 阶段（v0.11.0）验证 = dmg 结构校验（hdiutil verify）。
        // Developer ID 阶段（v0.12.0）在 helper 里再加 codesign / spctl 双验证。
        let ok = await Self.runProcess("/usr/bin/hdiutil", ["verify", dmgPath.path])
        guard ok else {
            try? FileManager.default.removeItem(at: dmgPath)
            state = .error(message: "更新包校验失败，已删除下载文件")
            return
        }
        state = .downloaded(candidate, dmgPath: dmgPath)
    }

    // MARK: 安装（helper 替换，v0.11.0-TOOL-A）

    /// 弹确认后调 helper：helper 等主进程退出 → 挂载 dmg → 替换
    /// /Applications/Quota Bar.app → 重新拉起。主 app 在启动 helper 后立即退出。
    func installDownloadedUpdate() {
        guard case .downloaded(_, let dmgPath) = state else { return }
        guard let helperURL = Self.helperScriptURL() else {
            state = .error(message: "更新助手缺失，请前往 GitHub 手动下载安装")
            return
        }

        state = .installing
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [helperURL.path, dmgPath.path]
        // helper 独立于主进程运行；输出丢给日志文件由 helper 自己管理。
        do {
            try process.run()
        } catch {
            state = .error(message: "无法启动更新助手：\(error.localizedDescription)")
            return
        }
        // 主动退出让 helper 完成替换。helper 内部会等待进程消失并在完成后 relaunch。
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApp.terminate(nil)
        }
    }

    // MARK: 启动时检测上次更新失败（v0.11.0-TOOL-A-004）

    static func updateErrorLogURL() -> URL {
        URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support/QuotaBar/update-error.log")
    }

    /// 主 app 启动时调用：存在 update-error.log 则提示上次更新失败，并清掉标记。
    static func consumeUpdateErrorLog() -> String? {
        let url = updateErrorLogURL()
        guard let content = try? String(contentsOf: url, encoding: .utf8),
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        try? FileManager.default.removeItem(at: url)
        return content
    }

    // MARK: 工具

    static func updatesDirectory() -> URL {
        URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support/QuotaBar/updates", isDirectory: true)
    }

    /// helper 脚本随 .app 打包在 Contents/Resources/install-update.sh。
    static func helperScriptURL() -> URL? {
        if let bundled = Bundle.main.url(forResource: "install-update", withExtension: "sh") {
            return bundled
        }
        // SwiftPM 直跑（开发态）：从源码目录取。
        let devPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // QuotaBar/
            .deletingLastPathComponent() // Sources/
            .deletingLastPathComponent() // macos/
            .appendingPathComponent("scripts/install-update.sh")
        return FileManager.default.fileExists(atPath: devPath.path) ? devPath : nil
    }

    private static func runProcess(_ launchPath: String, _ arguments: [String]) async -> Bool {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: launchPath)
                process.arguments = arguments
                process.standardOutput = FileHandle.nullDevice
                process.standardError = FileHandle.nullDevice
                do {
                    try process.run()
                    process.waitUntilExit()
                    continuation.resume(returning: process.terminationStatus == 0)
                } catch {
                    continuation.resume(returning: false)
                }
            }
        }
    }
}
