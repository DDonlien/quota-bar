import Foundation
import AppKit

// MARK: - 版本模型（v0.11.0-FE-A-001/003，2026-07-07 改版：纯版本号比较）
//
// 2026-07-07 用户明确指出：更新判断必须基于"最新包的版本号"，不能基于发布时间/
// 构建时间——同一个 commit 打两次包，时间戳会不一样，但内容完全相同，不该被判断
// 成"有更新"（这也是同一天早些时候那个时区解析 bug 的根本教训：只要还依赖时间
// 比较，就永远有踩上时区/时钟这类问题的风险）。
//
// 新版本号格式：`vX.Y.Z-<git-short-sha>`（例如 `v0.10.0-dcfff71`），写入
// `CFBundleShortVersionString`。`X.Y.Z` 由 Agent 维护（见 AGENTS.md「版本号维护
// 规则」），`<git-short-sha>` 由 `build-app.sh` 自动追加，只用来标识"具体是哪次
// 构建"，**不参与新旧判断**——新旧只看 `X.Y.Z` 语义化版本号谁更大。不再区分
// "stable/nightly 两条通道"：每一次发布都带着有意义的版本号，直接比大小即可。

/// 语义化版本三段。容忍任意 `-<suffix>` 后缀（如 git short sha）、忽略其内容，
/// 只解析 `X.Y.Z` 部分用于比较。
struct SemanticVersion: Comparable, Equatable, Sendable, CustomStringConvertible {
    let major: Int
    let minor: Int
    let patch: Int

    var description: String { "\(major).\(minor).\(patch)" }

    /// 解析 `v0.11.0`、`0.11.0`、`v0.11.0-dcfff71` 等。`-` 之后的任何内容
    /// （通常是 git short sha）都会被忽略，不影响解析出的 `X.Y.Z`。
    init?(tag: String) {
        var raw = tag
        if raw.hasPrefix("v") { raw.removeFirst() }
        if let dashIndex = raw.firstIndex(of: "-") {
            raw = String(raw[raw.startIndex..<dashIndex])
        }
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
    let semanticVersion: SemanticVersion
    let releaseURL: URL
    /// dmg 资产下载地址；没有 dmg 资产的 release 不可自动安装。
    let assetURL: URL?
    let assetName: String?
    /// release body 截断后的变更摘要。
    let releaseNotes: String
}

// MARK: - GitHub Releases 解析

enum UpdateReleaseParser {
    /// `vX.Y.Z` 或 `vX.Y.Z-<git-short-sha>`；sha 部分是可选的（历史上手动
    /// `workflow_dispatch` 发的纯 `vX.Y.Z` 稳定版也认）。
    static let versionTagPattern = #"^v\d+\.\d+\.\d+(-[0-9a-f]{7,40})?$"#

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

    /// 把 GitHub Releases API 响应解析成候选列表——只要 tag 能解析出语义化版本号
    /// 就算候选，不再区分"stable/nightly 通道"。draft 一律跳过。
    static func parse(data: Data) -> [UpdateCandidate] {
        guard let releases = try? JSONDecoder().decode([GitHubRelease].self, from: data) else {
            return []
        }

        var candidates: [UpdateCandidate] = []
        for release in releases where !release.draft {
            let tag = release.tag_name
            guard tag.range(of: versionTagPattern, options: .regularExpression) != nil,
                  let version = SemanticVersion(tag: tag),
                  let releaseURL = URL(string: release.html_url)
            else { continue }
            let dmgAsset = release.assets.first { $0.name.lowercased().hasSuffix(".dmg") }
            candidates.append(UpdateCandidate(
                tag: tag,
                semanticVersion: version,
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

    /// 在候选中挑「比当前版本号更高的最新版本」。纯语义化版本号比较，不看发布
    /// 时间/构建时间——同一个版本号（哪怕是不同 commit、不同次打包）不算更新，
    /// 避免"重复打包同一个版本被误判成有更新"。解析不出当前版本号时保守返回
    /// nil（不弹提示，而不是猜）。
    static func pickUpdate(
        candidates: [UpdateCandidate],
        currentVersion: String
    ) -> UpdateCandidate? {
        guard let currentSemantic = SemanticVersion(tag: currentVersion) else { return nil }
        let best = candidates
            .filter { $0.assetURL != nil }
            .max { $0.semanticVersion < $1.semanticVersion }
        guard let best, best.semanticVersion > currentSemantic else { return nil }
        return best
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
    /// 大陆可达性兜底（v0.14.0）：`releasesURL` 直连失败时改请求这个同源 Vercel endpoint，
    /// 它服务端原样转发 GitHub 的 release 数组（见仓库根目录 `api/latest-release.mjs`），
    /// 客户端复用同一套 `UpdateReleaseParser`，不需要额外的解析逻辑。
    private let fallbackReleasesURL: URL
    /// 同上，dmg 资产下载的兜底：服务端流式转发当前最新 release 的 dmg（`api/download-latest.mjs`）。
    private let fallbackDownloadURL: URL
    private let session: URLSession
    private let preferences: PreferencesStore
    private var downloadTask: URLSessionDownloadTask?
    private var downloadCandidate: UpdateCandidate?
    /// 本轮下载是否已经尝试过 Vercel 兜底——避免死循环重复 fallback。
    private var downloadTriedFallback = false

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    var currentBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }

    init(
        releasesURL: URL = URL(string: "https://api.github.com/repos/DDonlien/quota-bar/releases?per_page=30")!,
        fallbackReleasesURL: URL = URL(string: "https://quotabar.ddonlien.com/api/latest-release")!,
        fallbackDownloadURL: URL = URL(string: "https://quotabar.ddonlien.com/api/download-latest")!,
        session: URLSession? = nil,
        preferences: PreferencesStore = .shared
    ) {
        self.releasesURL = releasesURL
        self.fallbackReleasesURL = fallbackReleasesURL
        self.fallbackDownloadURL = fallbackDownloadURL
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

    private enum ReleaseFetchOutcome {
        case success(Data)
        case rateLimited
        case failed
    }

    /// 单次尝试：请求给定 URL 的 release 列表。`releasesURL`（GitHub 直连）和
    /// `fallbackReleasesURL`（Vercel 兜底）都走这个方法，返回同一套结果类型。
    private func fetchReleasesData(from url: URL) async -> ReleaseFetchOutcome {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("QuotaBar", forHTTPHeaderField: "User-Agent")
        do {
            let (body, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return .failed }
            if http.statusCode == 403,
               (http.value(forHTTPHeaderField: "X-RateLimit-Remaining") ?? "") == "0" {
                return .rateLimited
            }
            guard (200..<300).contains(http.statusCode) else { return .failed }
            return .success(body)
        } catch {
            return .failed
        }
    }

    /// 两步兜底（v0.14.0）：优先 GitHub 直连；失败（网络错误/超时/非 2xx，不含限流）时
    /// 自动改请求 Vercel 同源 endpoint；限流直接报限流文案，不浪费一次 fallback 尝试
    /// （限流是 GitHub 自己的问题，Vercel 服务端可能同样受限）。两者都失败才报通用错误，
    /// 错误文案不再点名具体平台——技术细节留给调用方自行看日志，不是这里的职责。
    private func performCheck(userInitiated: Bool) async {
        let data: Data
        switch await fetchReleasesData(from: releasesURL) {
        case .success(let body):
            data = body
        case .rateLimited:
            state = .error(message: "检查过于频繁，请稍后重试")
            return
        case .failed:
            switch await fetchReleasesData(from: fallbackReleasesURL) {
            case .success(let body):
                data = body
            case .rateLimited, .failed:
                state = .error(message: "暂时无法检查更新，请稍后重试")
                return
            }
        }

        preferences.setLastUpdateCheck(Date())

        let candidates = UpdateReleaseParser.parse(data: data)
        guard var update = UpdateReleaseParser.pickUpdate(
            candidates: candidates,
            currentVersion: currentVersion
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
                semanticVersion: update.semanticVersion,
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
        downloadTriedFallback = false
        state = .downloading(progress: 0)
        startDownload(from: assetURL)
    }

    private func startDownload(from url: URL) {
        let task = session.downloadTask(with: url) { [weak self] tempURL, response, error in
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
        downloadTriedFallback = false
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
        guard error == nil, let tempURL else {
            retryDownloadWithFallbackOrFail(candidate: candidate)
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
            // 校验失败也走兜底重试，不只是网络层失败——某些网络环境会用 HTTP 200
            // 返回一段假内容（而不是直接连接失败/超时），这种"看起来下载成功但内容
            // 不对"的情况只有 dmg 结构校验这一步能发现。
            retryDownloadWithFallbackOrFail(candidate: candidate)
            return
        }
        state = .downloaded(candidate, dmgPath: dmgPath)
    }

    /// 下载/校验失败的统一兜底入口（v0.14.0）：第一次失败自动改用 Vercel 兜底地址重试；
    /// 已经是第二次失败（`downloadTriedFallback == true`）才真正报错，避免死循环。
    private func retryDownloadWithFallbackOrFail(candidate: UpdateCandidate) {
        guard !downloadTriedFallback else {
            state = .error(message: "下载失败，请稍后重试或前往官网手动下载")
            return
        }
        downloadTriedFallback = true
        state = .downloading(progress: 0)
        startDownload(from: fallbackDownloadURL)
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
