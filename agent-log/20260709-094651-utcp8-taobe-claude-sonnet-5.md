# 用户原始 prompt

> （贴了一长段真实诊断日志，`opencode-webview` 连续多轮都是"Go 页面已加载但未解析出额度条"）看新的就好：（最新几行同样的失败）

# 启动运行时的分支和版本

- 分支：`main`
- 版本：本轮基于上一轮（opencode WebView 额度层接入）未提交的工作树继续

# 任务开始时间

2026-07-09 09:38 +0800

# 任务结束时间

2026-07-09 09:47 +0800

# 任务结束时是否执行了提交

否——按惯例留给用户确认后再决定是否提交/推送。

# 已阅读上下文

- 用户贴的真实诊断日志：从 `opencode-webview: 未登录`（cookie 还没有）→ `WebView 会话已失效或账号无 workspace`（cookie 有了但入口页没解出 workspace id）→ `Go 页面已加载但未解析出额度条`（workspace id 解出来了、Go 页也加载成功，但一条用量都没解析出来）的完整状态演变。
- `OpenCodeWorkspaceProvider.swift` 全文（上一轮刚写的解析器）。
- 用真实抓到的 `opencode-debug-go-page.html`（本轮新加的临时调试落盘）逐字核对。

# 对话与行动记录

上一轮刚接入的 `OpenCodeWorkspaceProvider` 解析器是照着 GitHub 上 sst/opencode 仓库的原始 JSX 源码（`lite-section.tsx`）写的正则，当时就在文档里承认"真实页面首跑仍可能有出入"——这次用户的真实日志验证了这个担心：workspace id 发现和 Go 页加载都成功了，但 `parseUsageItems` 连续多轮返回空。

没有继续对着 GitHub 源码猜第二次，而是先在 `fetchSnapshot` 里加了一段临时调试代码：解析失败时把 headless 加载到的真实 HTML 落盘到 App 自己的数据目录（`opencode-debug-go-page.html`），重新打包、杀掉旧进程重启，等了几秒后文件就生成了（说明用户之前已经登录过 opencode.ai，cookie 一直在）。直接读这个文件——终于看到真实的渲染结果，而不是源码猜测：

```html
<span data-slot="usage-value"><!--$-->0<!--/-->%</span>
<span data-slot="reset-time"><!--$-->重置于<!--/--> <!--$-->5 小时 0 分钟<!--/--></span>
```

真相：console 是 SolidStart 应用，SSR hydration 会在每一段动态文本前后自动插入 `<!--$-->`/`<!--/-->` 注释标记——这在源码（JSX 层面）里根本看不出来，是框架编译输出阶段自动加的。旧正则 `data-slot="usage-value"[^>]*>\s*(\d+)\s*%`（假设数字后面紧跟着 `%`）和 `data-slot="reset-time"[^>]*>([^<]*)`（假设开标签后到第一个 `<` 之间就是纯文本）两种写法，遇到这层注释都直接失配——这就是"页面加载成功但一条都解析不出来"的根因。

同时顺手核实了这次真实数据本身：滚动用量 0%（reset 18000 秒 = 5 小时，跟"5 小时 0 分钟"文案吻合）、每周 57%（reset 339437 秒 ≈ 3 天 22.27 小时，页面截断显示成"3 天 22 小时"）、每月 28%（reset 2562025 秒 ≈ 29 天 15.6 小时，显示"29 天 15 小时"）——上一轮猜的"rolling 窗口 = 5 小时"这个假设被真实数据直接验证对了。

# 完成工作

- `OpenCodeWorkspaceProvider.swift`：
  - `parseUsageItems` 改用 `NSRegularExpression` 非贪婪匹配拿到 `<span>...</span>` 之间的完整内容（而不是假设内容紧跟在开标签后）。
  - 新增 `stripHydrationComments`：统一剥掉 `<!--$-->`/`<!--/-->` 这类 SolidJS SSR hydration 注释标记，只留纯文本再解析数字/文案。
  - 验证通过后删除了临时调试代码（`debugDumpHTML` 函数 + `fetchSnapshot` 里的调用点）。
- `Tests/QuotaBarTests/OpenCodeWorkspaceProviderTests.swift`：把原来手写的（不含 hydration 注释的）fixture 换成真实抓到的 DOM 片段，新增一条 `stripHydrationComments` 单测直接覆盖这个坏味道。
- 清理了本机的调试落盘文件 `~/Library/Application Support/QuotaBar/opencode-debug-go-page.html`。
- `REQUIREMENTS.md`：新增 `[0.10.0-BUG-A-026]`。

新包：`macos/build/20260709-094651-main/Quota Bar.app`（`build/latest` 已指向），已重启本机开发态实例并**真机验证通过**：日志显示 `opencode-webview：获取到 3 条额度窗口`，过期日也正确带出（2026-08-07，跟月度重置日估算吻合）。

# 更新的需求 ID

- `[0.10.0-BUG-A-026]`

# 更新的 README 或 DESIGN 章节

- 无。

# 验证方式

- `swift build`：无警告无错误。
- `swift test`：195 tests in 44 suites 全部通过（新 fixture 换成真实 DOM + 新增 1 条 `stripHydrationComments` 测试）。
- 用真实落盘的完整 HTML 文件单独跑了一段临时 Swift 脚本验证解析逻辑（`percentText=0%/57%/28%`、`reset=重置于 5 小时 0 分钟` 等三条全部正确），验证通过后才删调试代码。
- `./scripts/build-app.sh`：产包成功，重启本机实例，等待一轮真实自动刷新——`provider-check.log` 确认 `opencode-webview：获取到 3 条额度窗口`、`过期日获取...成功...2026-08-07`。这是本次会话里第二次用"临时落盘真实数据 + 直接读取"的方法定位问题（第一次是 WebKit 崩溃报告），比单纯读日志文本或对着开源代码猜测更可靠。

# 备注

- 未提交 git commit。
- 这次的教训：即使核对过官方开源仓库的源码，框架层面的编译/渲染细节（这里是 SolidStart 的 SSR hydration 注释）源码里完全看不出来，headlessDOM 解析类的代码第一次上线后最好都用"失败时临时落盘真实 HTML"这个手法走一遍真实验证，而不是假设读源码就足够——本轮和上一轮踩的是同一类坑，值得记一下。
