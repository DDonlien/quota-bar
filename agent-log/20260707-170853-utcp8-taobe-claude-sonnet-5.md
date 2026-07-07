# 用户原始 prompt

> 到是新了，但：
> 1. 我们这版本号管理也太混乱了
> 2. 为什么还能看到更新下载
>
>（附「关于」页截图：Build 260707.044858.main，检查更新区域显示"nightly-dcfff71e... 已发布"并提供下载/安装按钮）

# 启动运行时的分支和版本

- 分支：`main`
- 版本：`7f96d92`（用户已 push 上一轮四个 commit + 额外一次 `dcfff71 log` 提交）

# 任务开始时间

2026-07-07 约 17:00 +0800

# 任务结束时间

2026-07-07 17:08 +0800

# 任务结束时是否执行了提交

否——本轮完成了代码修复但未提交，留给用户确认后再决定是否提交/推送。

# 已阅读上下文

- `UpdateChecker.swift` 的 `UpdateReleaseParser.buildDate(fromBundleVersion:)`、`pickUpdate` 的 10 分钟缓冲逻辑。
- `macos/scripts/build-app.sh` 里 `BUNDLE_VERSION`/`VERSION` 环境变量的生成逻辑。
- `.github/workflows/release.yml` 确认 GitHub Actions runner 默认时区。

# 对话与行动记录

用户截图显示：App 已经是最新构建（Build 260707.044858.main，对应刚发布的 commit dcfff71），但「检查更新」区域却提示"nightly-dcfff71e0...已发布"、还能点"立即下载并安装"——也就是**它把自己当成了一个新版本**推荐给用户重新下载。

排查 `UpdateReleaseParser.buildDate(fromBundleVersion:)`：这个函数负责把 `CFBundleVersion`（形如 `260707.044858`）解析回一个 `Date`，用于跟 GitHub release 的 `publishedAt` 比较。发现它用 `formatter.timeZone = .current`（设备本地时区）去解析这个时间戳。但反查 `build-app.sh` 的 `BUNDLE_VERSION="$(date +%y%m%d.%H%M%S)"`——这里没加 `-u`，本地开发机构建时是本地时区，但 GitHub Actions 的 CI runner（`release.yml` 没有显式设时区）默认是 UTC，所以从 GitHub release 下载下来的构建，这个时间戳其实**永远是 UTC**。

也就是说：解析端假设"本地时区"，但生产端（CI）实际写的是 UTC——对一个 UTC+8 的用户来说，`buildDate` 会被解析成比真实 UTC 时刻早 8 小时。`pickUpdate` 里"新版本发布时间必须比当前构建时间晚 10 分钟以上才提示"这条本该防止"刚构建完还没等一会儿"这种误报的缓冲逻辑，因为这个 8 小时的偏移，对几乎任何 release（包括当前正在运行的这个构建自己）都会成立——这就是为什么用户明明装的就是最新版，还被提示"有更新"。

修复：解析端固定用 UTC（不再依赖设备时区），并且把 `build-app.sh` 也改成 `date -u`，让本地开发构建和 CI 构建的时区语义保持一致（否则本地测试这个功能时又会出现新的时区不一致）。

用户第二点"版本号管理太混乱"——查了 `build-app.sh` 顶部对 `VERSION` 环境变量的处理，发现这**不是一个没设计好的混乱状态**，而是一套刻意的双通道方案：不传 `VERSION` 时固定写 `"1.0"`（`UpdateChecker` 用这个值识别"这是 nightly 通道，不是正式版本号"）；传 `VERSION=vX.Y.Z` 给 `release.yml` 的 `workflow_dispatch` 才会真正写入一个语义化版本号，切到"稳定版对比稳定版"的更简单路径。目前项目从来没有真正触发过一次带 `VERSION` 的正式发版，所以用户看到的永远是"1.0 + 一长串时间戳"，这确实观感不友好，但根源是"还没剪过正式版"，不是这套设计本身坏了。在最终回复里如实说明这个区别，并建议如果想要更干净的版本号观感，可以剪一个真正的 `v0.1.0` 试试，而不是替用户做这个发版决定。

# 完成工作

- `UpdateChecker.swift`：`buildDate(fromBundleVersion:)` 的时区解析从 `.current` 改为固定 UTC。
- `macos/scripts/build-app.sh`：`BUNDLE_VERSION` 生成改用 `date -u`，本地构建和 CI 构建时区语义保持一致。
- `Tests/QuotaBarTests/UpdateCheckerTests.swift`：
  - 修正既有的 `parsesBuildDate` 测试——原来用 `Calendar.current` 读取解析结果，两边的"current"会互相抵消掩盖问题，改成显式用 UTC Calendar 读取，让这条测试本身在任何时区的机器上跑都有意义。
  - 新增回归测试 `freshlyInstalledBuildIsNotSelfUpdate`，直接复现真实事故的数量级（build 时间戳和 release 发布时间只差不到 1 分钟），断言"刚装好的构建不会把自己当成待更新版本"。
- 新包：`macos/build/20260707-170845-main/Quota Bar.app`（`build/latest` 已指向）。

# 更新的需求 ID

无新增——这是对已实现的 v0.11.0 UpdateChecker 功能的 bug 修复，未创建新任务 ID（后续如果需要正式记录可以补 `0.11.0-BUG` 系列 ID）。

# 更新的 README 或 DESIGN 章节

无——本轮是纯 bug 修复 + 测试，未涉及文档章节改动。

# 验证方式

- `swift build`：无警告无错误。
- `swift test`：181 tests in 42 suites 全部通过，包括新增的回归测试（在本机——一台非 UTC 时区的 Mac 上验证，正是能暴露这个 bug 的环境）。
- `./scripts/build-app.sh`：产包成功。
- 未做真实多时区环境的端到端验证（比如真的换一台 UTC 时区的机器测试前后行为差异）——本机是 UTC+8，足以复现和验证这个具体 bug，但没有交叉验证其他时区。

# 备注

- 未提交 git commit——按照"只在用户明确要求时才提交"的原则，这次没有像上一轮那样直接创建 commit，等用户看完这轮修复后再决定是否需要提交/推送。
- 这是本次多轮会话里第二次由"用户直接使用真实产物（打包后的 app / 网页 / 更新检查）"而不是靠我自己测试发现的真实 bug——第一次是 Claude Keychain 读取问题，这次是时区解析问题。两次都印证了"真实使用场景暴露的 bug，往往比代码走读更容易发现"这一点。
