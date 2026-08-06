import Foundation
import Testing
@testable import QuotaBar

@Suite("App installation location")
struct AppInstallationTests {
    private let homeDirectory = URL(fileURLWithPath: "/Users/tester", isDirectory: true)

    @Test("accepts the system Applications directory")
    func acceptsSystemApplications() {
        let app = URL(fileURLWithPath: "/Applications/Quota Bar.app")
        #expect(QuotaBarAppInstallation.isInstalledAppBundle(app, homeDirectory: homeDirectory))
    }

    @Test("accepts the user's Applications directory")
    func acceptsUserApplications() {
        let app = URL(fileURLWithPath: "/Users/tester/Applications/Quota Bar.app")
        #expect(QuotaBarAppInstallation.isInstalledAppBundle(app, homeDirectory: homeDirectory))
    }

    @Test("rejects build and worktree app bundles")
    func rejectsDevelopmentBuilds() {
        let build = URL(fileURLWithPath: "/Users/tester/Projects/quota-bar/_builds/20260806/Quota Bar.app")
        let worktree = URL(fileURLWithPath: "/Users/tester/Projects/quota-bar/quota-bar_main/macos/build/Quota Bar.app")
        #expect(!QuotaBarAppInstallation.isInstalledAppBundle(build, homeDirectory: homeDirectory))
        #expect(!QuotaBarAppInstallation.isInstalledAppBundle(worktree, homeDirectory: homeDirectory))
    }

    @Test("rejects another app name in Applications")
    func rejectsOtherAppNames() {
        let otherApp = URL(fileURLWithPath: "/Applications/QuotaBar.app")
        #expect(!QuotaBarAppInstallation.isInstalledAppBundle(otherApp, homeDirectory: homeDirectory))
    }
}
