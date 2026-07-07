import Foundation
import Testing
@testable import QuotaBar

@Suite("UpdateChecker version logic")
struct UpdateCheckerTests {

    // MARK: - SemanticVersion（v0.11.0-FE-A-003-test）

    @Test("semver compares numerically not lexically")
    func semverNumericCompare() throws {
        let v2 = try #require(SemanticVersion(tag: "v0.2.0"))
        let v10 = try #require(SemanticVersion(tag: "v0.10.0"))
        #expect(v2 < v10)
        #expect(!(v10 < v2))
    }

    @Test("prerelease tags are not valid stable versions")
    func prereleaseRejected() {
        #expect(SemanticVersion(tag: "v0.2.0-rc1") == nil)
        #expect(SemanticVersion(tag: "v0.2.0" ) != nil)
        #expect(SemanticVersion(tag: "garbage") == nil)
    }

    // MARK: - Release 解析（v0.11.0-FE-A-000-test）

    @Test("parses mixed semver and nightly releases, skipping drafts and odd tags")
    func parsesMixedReleases() {
        let data = Self.releasesJSON([
            Self.release(tag: "v0.11.0", prerelease: false, published: "2026-07-04T10:00:00Z", asset: "QuotaBar-v0.11.0.dmg"),
            Self.release(tag: "nightly-0123abc", prerelease: true, published: "2026-07-05T10:00:00Z", asset: "QuotaBar-0123abc.dmg"),
            Self.release(tag: "v0.11.0-rc1", prerelease: true, published: "2026-07-03T10:00:00Z", asset: "QuotaBar-rc.dmg"),
            Self.release(tag: "v0.10.0", prerelease: false, published: "2026-07-01T10:00:00Z", asset: "QuotaBar-v0.10.0.dmg", draft: true),
            Self.release(tag: "weird-tag", prerelease: false, published: "2026-07-01T10:00:00Z", asset: nil),
        ])
        let candidates = UpdateReleaseParser.parse(data: data)
        #expect(candidates.count == 2)
        #expect(candidates.contains { $0.tag == "v0.11.0" && $0.channel == .stable })
        #expect(candidates.contains { $0.tag == "nightly-0123abc" && $0.channel == .nightly })
    }

    @Test("stable is always preferred over nightly for nightly builds")
    func stablePreferredOverNightly() {
        let candidates = UpdateReleaseParser.parse(data: Self.releasesJSON([
            Self.release(tag: "nightly-0123abc", prerelease: true, published: "2026-07-05T10:00:00Z", asset: "n.dmg"),
            Self.release(tag: "v0.11.0", prerelease: false, published: "2026-07-01T10:00:00Z", asset: "s.dmg"),
        ]))
        let picked = UpdateReleaseParser.pickUpdate(
            candidates: candidates,
            currentVersion: "1.0",
            currentBuildDate: ISO8601DateFormatter().date(from: "2026-07-04T00:00:00Z")
        )
        #expect(picked?.tag == "v0.11.0")
    }

    @Test("newer nightly recommended when no stable exists")
    func nightlyRecommendedByPublishDate() {
        let candidates = UpdateReleaseParser.parse(data: Self.releasesJSON([
            Self.release(tag: "nightly-0123abc", prerelease: true, published: "2026-07-05T10:00:00Z", asset: "n.dmg"),
        ]))
        let older = UpdateReleaseParser.pickUpdate(
            candidates: candidates,
            currentVersion: "1.0",
            currentBuildDate: ISO8601DateFormatter().date(from: "2026-07-04T00:00:00Z")
        )
        #expect(older?.tag == "nightly-0123abc")

        let newerLocal = UpdateReleaseParser.pickUpdate(
            candidates: candidates,
            currentVersion: "1.0",
            currentBuildDate: ISO8601DateFormatter().date(from: "2026-07-06T00:00:00Z")
        )
        #expect(newerLocal == nil)
    }

    @Test("stable current version only upgrades to higher semver")
    func stableOnlyUpgradesToHigherSemver() {
        let candidates = UpdateReleaseParser.parse(data: Self.releasesJSON([
            Self.release(tag: "v0.11.0", prerelease: false, published: "2026-07-04T10:00:00Z", asset: "s.dmg"),
            Self.release(tag: "nightly-0123abc", prerelease: true, published: "2026-07-05T10:00:00Z", asset: "n.dmg"),
        ]))
        #expect(UpdateReleaseParser.pickUpdate(candidates: candidates, currentVersion: "0.11.0", currentBuildDate: nil) == nil)
        #expect(UpdateReleaseParser.pickUpdate(candidates: candidates, currentVersion: "0.10.2", currentBuildDate: nil)?.tag == "v0.11.0")
    }

    @Test("empty release list means up to date")
    func emptyList() {
        #expect(UpdateReleaseParser.pickUpdate(candidates: [], currentVersion: "1.0", currentBuildDate: nil) == nil)
    }

    // MARK: - 构建时间解析

    @Test("parses build date from CFBundleVersion timestamp")
    func parsesBuildDate() throws {
        let date = try #require(UpdateReleaseParser.buildDate(fromBundleVersion: "260705.213000"))
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour], from: date)
        #expect(comps.year == 2026)
        #expect(comps.month == 7)
        #expect(comps.day == 5)
        #expect(comps.hour == 21)
        #expect(UpdateReleaseParser.buildDate(fromBundleVersion: "1") == nil)
        #expect(UpdateReleaseParser.buildDate(fromBundleVersion: nil) == nil)
    }

    // MARK: - release notes 清洗

    @Test("release notes strip markdown emphasis and cap at 500 chars")
    func notesTrimming() {
        let long = String(repeating: "字", count: 600)
        let trimmed = UpdateReleaseParser.trimmedNotes("## Title **bold** `code`\n" + long)
        #expect(!trimmed.contains("**"))
        #expect(!trimmed.contains("##"))
        #expect(trimmed.count <= 502)
    }

    // MARK: - fixtures

    private static func release(
        tag: String,
        prerelease: Bool,
        published: String,
        asset: String?,
        draft: Bool = false
    ) -> [String: Any] {
        var json: [String: Any] = [
            "tag_name": tag,
            "html_url": "https://github.com/DDonlien/quota-bar/releases/tag/\(tag)",
            "body": "release body for \(tag)",
            "draft": draft,
            "prerelease": prerelease,
            "published_at": published,
            "assets": [[String: Any]](),
        ]
        if let asset {
            json["assets"] = [[
                "name": asset,
                "browser_download_url": "https://github.com/DDonlien/quota-bar/releases/download/\(tag)/\(asset)",
            ]]
        }
        return json
    }

    private static func releasesJSON(_ releases: [[String: Any]]) -> Data {
        try! JSONSerialization.data(withJSONObject: releases)
    }
}

@Suite("MiniMax subscription state mapping")
struct MiniMaxSubscriptionMappingTests {
    @Test("server no-active-subscription messages are recognized")
    func recognizesNoActiveSubscription() {
        #expect(MiniMaxCLIProvider.indicatesNoActiveSubscription("no active token plan subscription"))
        #expect(MiniMaxCLIProvider.indicatesNoActiveSubscription("No Active Coding Plan Subscription"))
        #expect(MiniMaxCLIProvider.indicatesNoActiveSubscription("subscription expired"))
        #expect(!MiniMaxCLIProvider.indicatesNoActiveSubscription("rate limit exceeded"))
        #expect(!MiniMaxCLIProvider.indicatesNoActiveSubscription("internal error"))
    }
}
