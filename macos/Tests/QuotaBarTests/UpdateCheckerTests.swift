import Foundation
import Testing
@testable import QuotaBar

@Suite("UpdateChecker version logic")
struct UpdateCheckerTests {

    // MARK: - SemanticVersion（2026-07-07 改版：纯版本号比较，容忍 git sha 后缀）

    @Test("semver compares numerically not lexically")
    func semverNumericCompare() throws {
        let v2 = try #require(SemanticVersion(tag: "v0.2.0"))
        let v10 = try #require(SemanticVersion(tag: "v0.10.0"))
        #expect(v2 < v10)
        #expect(!(v10 < v2))
    }

    @Test("git short sha suffix is ignored, only X.Y.Z drives comparison")
    func gitShaSuffixIgnored() throws {
        // 新格式 `vX.Y.Z-<git-short-sha>`：sha 只是构建标识，不参与新旧比较——
        // 同一个 X.Y.Z，不管 sha 是什么，语义化版本号都相同。
        let plain = try #require(SemanticVersion(tag: "v0.10.0"))
        let withSha = try #require(SemanticVersion(tag: "v0.10.0-dcfff71"))
        #expect(plain == withSha)
        #expect(SemanticVersion(tag: "garbage") == nil)
        #expect(SemanticVersion(tag: "v0.2") == nil)
    }

    // MARK: - Release 解析（2026-07-07 改版：不再分 stable/nightly 通道）

    @Test("parses releases with valid version tags, skipping drafts and unparseable tags")
    func parsesReleases() {
        let data = Self.releasesJSON([
            Self.release(tag: "v0.11.0", prerelease: false, published: "2026-07-04T10:00:00Z", asset: "QuotaBar-v0.11.0.dmg"),
            Self.release(tag: "v0.10.0-0123abc", prerelease: false, published: "2026-07-05T10:00:00Z", asset: "QuotaBar-0123abc.dmg"),
            Self.release(tag: "v0.10.0", prerelease: false, published: "2026-07-01T10:00:00Z", asset: "QuotaBar-v0.10.0.dmg", draft: true),
            Self.release(tag: "weird-tag", prerelease: false, published: "2026-07-01T10:00:00Z", asset: nil),
        ])
        let candidates = UpdateReleaseParser.parse(data: data)
        #expect(candidates.count == 2)
        #expect(candidates.contains { $0.tag == "v0.11.0" })
        #expect(candidates.contains { $0.tag == "v0.10.0-0123abc" })
    }

    @Test("picks the highest semver above current, ignoring which one has a newer publish date")
    func picksHighestSemverRegardlessOfPublishDate() {
        // 特意让版本号更低的 release 发布时间更晚——验证比较只看版本号，不看时间。
        let candidates = UpdateReleaseParser.parse(data: Self.releasesJSON([
            Self.release(tag: "v0.9.0-aaaaaaa", prerelease: false, published: "2026-07-06T10:00:00Z", asset: "old.dmg"),
            Self.release(tag: "v0.11.0-bbbbbbb", prerelease: false, published: "2026-07-01T10:00:00Z", asset: "new.dmg"),
        ]))
        let picked = UpdateReleaseParser.pickUpdate(candidates: candidates, currentVersion: "v0.10.0-ccccccc")
        #expect(picked?.tag == "v0.11.0-bbbbbbb")
    }

    @Test("current version only upgrades to a strictly higher semver")
    func onlyUpgradesToHigherSemver() {
        let candidates = UpdateReleaseParser.parse(data: Self.releasesJSON([
            Self.release(tag: "v0.11.0-dcfff71", prerelease: false, published: "2026-07-04T10:00:00Z", asset: "s.dmg"),
        ]))
        #expect(UpdateReleaseParser.pickUpdate(candidates: candidates, currentVersion: "v0.11.0") == nil)
        #expect(UpdateReleaseParser.pickUpdate(candidates: candidates, currentVersion: "v0.10.2")?.tag == "v0.11.0-dcfff71")
    }

    /// 2026-07-19 修正：2026-07-07 那版把"同一个 X.Y.Z、不同 sha"整体判定成"不算
    /// 更新"，本意是防"同一个 commit 重复打包被误判成有更新"，但实际发布节奏是
    /// "每次 push main 都发新 release，VERSION 只在完整功能阶段完成时才 bump"——
    /// 这导致绝大多数真实发布之间 X.Y.Z 完全相同，只有 sha 不同，全部被那版逻辑
    /// 挡在外面：装了旧包的用户会一直卡在"已是最新版本"，即使中间已经发了一串
    /// 新版本。改成用 sha 是否相同判断（sha 是内容寻址的，同一个 commit 恒定），
    /// 既能识别出真实的新发布，又不会把"重复打包同一个 commit"误判成更新——
    /// 见下面 `sameVersionSameShaIsNotAnUpdate` 那个测试，覆盖的正是 07-07 真正
    /// 想防的场景。
    @Test("same X.Y.Z but a different build sha is offered as an update")
    func sameVersionDifferentShaIsAnUpdate() {
        let candidates = UpdateReleaseParser.parse(data: Self.releasesJSON([
            Self.release(tag: "v0.10.0-dcfff71", prerelease: false, published: "2026-07-07T04:49:52Z", asset: "n.dmg"),
        ]))
        let picked = UpdateReleaseParser.pickUpdate(candidates: candidates, currentVersion: "v0.10.0-eeeeeee")
        #expect(picked?.tag == "v0.10.0-dcfff71", "相同 X.Y.Z 但 sha 不同——说明有一次新发布没有 bump 版本号，应该被识别成待更新")
    }

    /// 07-07 真正想避免的场景：同一个 commit（sha 相同）重复打包，不该被判断成
    /// "有更新"——sha 是内容寻址的，同一个 commit 的 sha 恒定，天然满足这个要求。
    @Test("rebuilding the exact same commit is not offered as an update to itself")
    func sameVersionSameShaIsNotAnUpdate() {
        let candidates = UpdateReleaseParser.parse(data: Self.releasesJSON([
            Self.release(tag: "v0.10.0-dcfff71", prerelease: false, published: "2026-07-07T04:49:52Z", asset: "n.dmg"),
        ]))
        let picked = UpdateReleaseParser.pickUpdate(candidates: candidates, currentVersion: "v0.10.0-dcfff71")
        #expect(picked == nil, "相同 X.Y.Z、相同 sha（同一个 commit 重复打包）不应该被识别成待更新的新版本")
    }

    @Test("empty release list means up to date")
    func emptyList() {
        #expect(UpdateReleaseParser.pickUpdate(candidates: [], currentVersion: "v1.0.0") == nil)
    }

    @Test("unparseable current version yields no recommendation")
    func unparseableCurrentVersionYieldsNil() {
        let candidates = UpdateReleaseParser.parse(data: Self.releasesJSON([
            Self.release(tag: "v0.11.0", prerelease: false, published: "2026-07-04T10:00:00Z", asset: "s.dmg"),
        ]))
        #expect(UpdateReleaseParser.pickUpdate(candidates: candidates, currentVersion: "garbage") == nil)
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
