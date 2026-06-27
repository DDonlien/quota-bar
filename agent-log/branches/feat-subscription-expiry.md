# feat/subscription-expiry

## 用途

v0.6.0 phase 第二批工作的独立工作线 — 5 个 headless provider 的订阅到期日
抓取（Codex / Claude / Cursor / MiniMax / Antigravity）。

v0.6.0 第一批已在 main 落地：
- ARCH-A-000~003：harvester 协议 + WKWebView wrapper + fallback 改 hide
- DATA-A-000~002（Kimi）：从 `subscriptionBalance.expireTime` 提取

第二批这 5 个 provider 都有 dashboard endpoint / 订阅页，需要用
`WKWebViewHeadlessLoader` 抓页面 + DOM 解析续费日期。

## 关联 Phase / Task

- `v0.6.0-DATA-B-000~001-test`：Codex (chatgpt.com/account/manage)
- `v0.6.0-DATA-C-000~001-test`：Claude (claude.ai/settings/plan)
- `v0.6.0-DATA-D-000~001-test`：Cursor (cursor.com/dashboard)
- `v0.6.0-DATA-E-000~001-test`：MiniMax (minimaxi.com/user-center/payment/balance)
- `v0.6.0-DATA-F-000~001-test`：Antigravity (antigravity.google)

## 起点

- 基于 main `@ 8d69017`
- 与 ARCH 协议兼容（`SubscriptionDateHarvester.harvest(from:)` 接口已固定）
- 与 Kimi `KimiSubscriptionStatParser.parseSubscriptionExpiresAt(data:)` 接口对齐

## 当前状态

init — 暂无实际工作。

## 后续入口

每个 provider 一个独立 worktree / branch 子线，互不阻塞：

```
.worktrees/feat-sub-expiry-codex      feat/sub-expiry-codex
.worktrees/feat-sub-expiry-claude     feat/sub-expiry-claude
.worktrees/feat-sub-expiry-cursor     feat/sub-expiry-cursor
.worktrees/feat-sub-expiry-minimax    feat/sub-expiry-minimax
.worktrees/feat-sub-expiry-antigrav   feat/sub-expiry-antigravity
```

每个 worktree 完成一个 provider 后 ff merge 回这个 branch，5 个齐了再 ff merge 回 main。