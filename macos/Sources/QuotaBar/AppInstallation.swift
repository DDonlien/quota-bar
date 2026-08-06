import Foundation

/// Locations that are treated as installed app bundles.
///
/// Development builds under `_builds` or a worktree are deliberately excluded
/// so they cannot register themselves as login items.
enum QuotaBarAppInstallation {
    static let appBundleName = "Quota Bar.app"

    static func isInstalledAppBundle(
        _ bundleURL: URL,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> Bool {
        let appURL = bundleURL.standardizedFileURL
        guard appURL.lastPathComponent == appBundleName else { return false }

        let parentURL = appURL.deletingLastPathComponent()
        let systemApplicationsURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        let userApplicationsURL = homeDirectory
            .appendingPathComponent("Applications", isDirectory: true)
            .standardizedFileURL

        return parentURL == systemApplicationsURL || parentURL == userApplicationsURL
    }
}
