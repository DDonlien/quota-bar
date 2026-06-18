# Changelog

All notable changes to Quota Bar will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added (P0 — real data wiring)
- SweetCookieKit as SPM dependency for cross-browser cookie extraction
- `FilesystemCookieReader` backed by SweetCookieKit (`BrowserCookieClient` +
  `Browser.defaultImportOrder`)
- `PrivacyAccessChecker` to probe Full Disk Access and open System Settings
- Orange "需要 Full Disk Access" banner in status bar menu with
  "打开系统设置" button
- SweetCookieKit keychain prompt handler installed in `CodingPlanMenuApp`
- `KeychainProvider.readToken()` that actually reads the secret
  (`kSecReturnData: true`)
- `DashboardEndpoints` registry with real Codex endpoint
  (`https://chatgpt.com/backend-api/wham/usage`) and JSON parser for
  `rate_limit.primary_window` / `secondary_window`
- `BrowserCookieProvider` rewritten to send a manual `Cookie:` header and
  map 401/403 to `missingCredentials`
- `ProviderFactory` extended to Codex / Claude / Gemini / MiniMax / Kimi

### Added (P1 — extensibility layer)
- `ProviderFetchStrategy` protocol
- `FetchPipeline` (parallel + sequential modes) for ordered strategy
  fallback and priority-based merge
- `QuotaProviderStrategy` adapter so P0 providers slot into pipelines
  without rewriting
- `ProviderPipelines.makePipelines()` factory returning canonical
  Codex / Claude / Gemini / MiniMax / Kimi pipelines
- `TTYCommandRunner` for PTY-backed command execution (`/usr/bin/script`
  + Process) with timeout / SIGTERM / SIGKILL escalation
- `LoginRunner` protocol + Codex / Claude / Gemini concrete runners
  (AppleScript → Terminal.app)
- `AgentProvider` collapsed into `ProviderKind` (single source of truth);
  `ProviderKind` now exposes `iconSymbol` / `cliCommand` /
  `bundleIdentifier` / `envVarNames` / `cookieDomains`

### Changed
- `StatusBarController` now wires to `RefreshCoordinator` and observes
  `$state` / `$isRefreshing` via Combine
- `MenuDashboardStyle` adds `summarySpacing` / `sectionSpacing` /
  `quotaRowsSpacing` / `quotaRowSpacing` / `contentBlockSpacing` /
  `permissionBannerTitleSize` / `permissionBannerBodySize`
- `.gitignore` covers `.build/` / `.swiftpm/` / `.DS_Store` / Xcode / IDE
  artifacts / `.worktrees/`

### Fixed
- `StatusBarController` no longer calls `MenuView()` with no arguments
- `MenuDashboardStyle.height` reference replaced with dynamic
  `fittingSize` calculation
- Swift 6 main-actor-isolated `deinit` issue in `StatusBarController`

## [0.1.0] — 2026-06-01

### Added
- Static placeholder menu bar UI showing 3 providers (Codex / MiniMax /
  Kimi) with brand colors and dummy quota bars
- Status bar controller with system symbol icon (`chart.bar.fill`)
- Menu items: 立即刷新 / 偏好设置 / 退出
- AGENTS.md / REQUIREMENTS.md / DESIGN.md / agent-log/ project docs

[Unreleased]: https://github.com/yourname/quota-bar/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/yourname/quota-bar/releases/tag/v0.1.0