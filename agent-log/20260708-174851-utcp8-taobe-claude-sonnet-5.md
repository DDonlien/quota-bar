# 用户原始 prompt

> 日志页特别卡，肯定有问题，这么简单的功能（加上我的mac配置很高）其他页面都不卡

# 启动运行时的分支和版本

- 分支：`main`
- 版本：本轮基于上一轮（API Key 配置行视觉优化 + opencode 手动 Key 支持）未提交的工作树继续

# 任务开始时间

2026-07-08 17:47 +0800

# 任务结束时间

2026-07-08 17:49 +0800

# 任务结束时是否执行了提交

否——按惯例留给用户确认后再决定是否提交/推送。

# 已阅读上下文

- `Preferences/DiagnosticsSettingsView.swift` 全文。
- `ProviderCheckLog.swift`（`ProviderCheckLogStore.readRecentLines`/`append` 全文）。

# 对话与行动记录

用户明确指出"这么简单的功能"却卡、且排除了硬件因素（Mac 配置高）和其他页面（都不卡）——这个排除法本身就指向问题出在这一屏自己的渲染方式，不是日志系统整体设计或磁盘 I/O。

直接读 `DiagnosticsSettingsView.logView` 的实现：`ScrollView` 里包了一个 `VStack`（不是 `LazyVStack`），`ForEach` 遍历 `lines` 渲染 `Text`。`lines` 来自 `ProviderCheckLogStore.readRecentLines()`，默认 `limit: 2000`——也就是说日志攒得够多之后，这个 `VStack` 每次渲染都要立即创建、布局 2000 个 `Text` 视图，而 `ScrollView` 的可视区域只有 360pt 高，实际同时能看到的不过 20 多行。`VStack` 不像 `LazyVStack` 那样只创建进入视口的子视图，是 SwiftUI 里一个经典的性能反模式——列表数据量越大，这个反模式的代价越明显。

更关键的是触发频率：页面订阅了 `.providerCheckLogDidChange`，每个 provider 完成一轮 fetch 调 `ProviderCheckLog.flush(kind:)` 就会 post 一次这个通知——一次刷新周期最多 7 个 provider，短时间内最多 7 次 `reload()`，每次都要把这 2000 个 `Text` 视图重新整个铺一遍。这就是"简单功能却很卡"的真正原因：不是磁盘读取慢（读几百 KB 文本是毫秒级），也不是通知太频繁本身有问题，是这一屏选错了容器类型，让本该只做局部工作的"刷新一行"变成了"重新布局全部 2000 行"。

# 完成工作

- `Preferences/DiagnosticsSettingsView.swift`：`logView` 里的 `VStack` 改成 `LazyVStack`，只创建实际进入视口的行。

# 更新的需求 ID

- `[0.10.0-BUG-A-022]`

# 更新的 README 或 DESIGN 章节

- 无。

# 验证方式

- `swift build`：无警告无错误。
- `swift test`：190 tests in 43 suites 全部通过（纯渲染容器改动，无行为变化，未新增测试）。
- `./scripts/build-app.sh`：产包成功，重启了本机正在跑的开发态实例指向新包（`macos/build/20260708-174851-main`），方便用户直接在真实使用场景里感受是否还卡。

# 备注

- 未提交 git commit。
- 没能用 computer-use 实机验证卡顿是否真的消失（跟上一轮同样的原因：accessory 模式 + 未签名开发态包，`request_access` 匹配不到这个 App），请用户直接在新启动的实例里打开「偏好设置 → 日志」页确认。
- 如果切换到 `LazyVStack` 后卡顿依然存在，下一步可疑点：`readRecentLines()` 默认 `limit: 2000` 仍然偏大，可以考虑降到几百行；或者进一步排查 `.textSelection(.enabled)` 在 AppKit 后端每个 `Text` 实例的开销是否需要挪到容器层级统一设置——但这两个都是"如果还卡"的备选项，本轮先验证 `LazyVStack` 这个最直接、最可能命中的根因是否已经解决问题。
