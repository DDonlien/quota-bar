import Foundation
import Testing
@testable import QuotaBar

// MARK: - WKWebViewHeadlessLoader 入口失败路径测试
//
// **覆盖范围**：cookie 入口阶段的失败（empty / permission / cookie store unavailable）。
// **不覆盖**：真实 WKWebView 加载（macOS 沙盒/CI 没 window server，init 会失败）——
// 真实加载在 app 实际运行时验。
//
// 真实 WKWebView 行为依赖 macOS window server，无法在 headless CI 中测。
// 但本测试至少保证：
// 1. cookie 为空时立即抛 `missingCredentials`，**不进入** WKWebView 路径；
// 2. cookieReader 抛错时正确映射到 `permissionRequired` / `missingCredentials` / `transient`。

@Suite("WKWebViewHeadlessLoader — cookie 入口失败路径")
@MainActor
struct WKWebViewHeadlessLoaderEntryTests {

    @Test("cookies 为空时抛 missingCredentials（不进 WKWebView）")
    func emptyCookies() async {
        let loader = WKWebViewHeadlessLoader(cookieReader: InMemoryCookieReader(cookies: []))
        do {
            _ = try await loader.load(
                url: URL(string: "https://chatgpt.com/#settings/Billing")!,
                kind: .codex,
                timeout: 5,
                identifier: "test-empty"
            )
            Issue.record("应该抛 missingCredentials 但没抛")
        } catch let error as QuotaFetchError {
            switch error {
            case .missingCredentials:
                break  // 期望
            default:
                Issue.record("应该是 missingCredentials，实际是 \(error)")
            }
        } catch {
            Issue.record("应该是 QuotaFetchError，实际是 \(error)")
        }
    }

    @Test("permission denied 映射为 permissionRequired")
    func permissionDenied() async {
        let denyingReader = ThrowingCookieReader(error: FilesystemCookieReader.ReaderError.privacyAccessDenied(
            browser: "Safari",
            hint: "需要 Full Disk Access"
        ))
        let loader = WKWebViewHeadlessLoader(cookieReader: denyingReader)
        do {
            _ = try await loader.load(
                url: URL(string: "https://chatgpt.com/#settings/Billing")!,
                kind: .codex,
                timeout: 5,
                identifier: "test-perm"
            )
            Issue.record("应该抛 permissionRequired 但没抛")
        } catch let error as QuotaFetchError {
            switch error {
            case .permissionRequired:
                break
            default:
                Issue.record("应该是 permissionRequired，实际是 \(error)")
            }
        } catch {
            Issue.record("应该是 QuotaFetchError，实际是 \(error)")
        }
    }

    @Test("cookie store unavailable 映射为 missingCredentials")
    func cookieStoreUnavailable() async {
        let denyingReader = ThrowingCookieReader(error: FilesystemCookieReader.ReaderError.cookieStoreUnavailable(
            browser: "Chrome"
        ))
        let loader = WKWebViewHeadlessLoader(cookieReader: denyingReader)
        do {
            _ = try await loader.load(
                url: URL(string: "https://chatgpt.com/#settings/Billing")!,
                kind: .codex,
                timeout: 5,
                identifier: "test-no-store"
            )
            Issue.record("应该抛 missingCredentials 但没抛")
        } catch let error as QuotaFetchError {
            switch error {
            case .missingCredentials:
                break
            default:
                Issue.record("应该是 missingCredentials，实际是 \(error)")
            }
        } catch {
            Issue.record("应该是 QuotaFetchError，实际是 \(error)")
        }
    }
}

// MARK: - 测试替身

/// 每次 readCookies 都抛固定错误的 cookie reader，便于测错误映射。
private struct ThrowingCookieReader: BrowserCookieReader {
    let error: Error
    func readCookies(matching domains: [String]) async throws -> [HTTPCookie] {
        throw error
    }
}
