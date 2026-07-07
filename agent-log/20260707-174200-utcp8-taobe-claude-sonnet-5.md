# 用户原始 prompt

> 更新应该基于最新的包的版本号而不是发布日期/时间来，否则如果我打两个一样的包呢？
>
> 版本号的规则如下：
> vx.x.x-gitnumber
> 前半部分由你维护，你每次执行修改的时候，判断修改的量，决定是否要修改、改哪一位；把这个任务加入AGENTS.md，修改的话同步纳入log；后面的部份直接用git版本号的字符串，类似附件？
>
> dropdown里的x有问题：
> 按了不会直接更新显示状态（隐藏），需要开关dropdown
> Zcode 和 GLM 没有关联上，只有 MiniMax 现在看是关联上了，按了在preferences里能同步。
>
>（附图：一段形如 `-dcfff71.d...` 的版本字符串片段）

# 启动运行时的分支和版本

- 分支：`main`
- 版本：`dcfff71`（用户自己提交的 "log" commit，本轮开始时的 HEAD）

# 任务开始时间

2026-07-07 约 17:10 +0800

# 任务结束时间

2026-07-07 17:42 +0800

# 任务结束时是否执行了提交

否——本轮完成了代码修复但未提交，按惯例留给用户确认后再决定是否提交/推送。

# 已阅读上下文

- `UpdateChecker.swift` 全文（`UpdateChannel`/`SemanticVersion`/`UpdateCandidate`/`UpdateReleaseParser`/`UpdateChecker` 现状）。
- `macos/scripts/build-app.sh`、`.github/workflows/release.yml` 现有的 `VERSION` 环境变量双通道逻辑。
- `ModelsSettingsView.swift`、`RefreshCoordinator.swift`（上一轮已定位的 dropdown 隐藏/Preferences 关联问题）。
- 全仓库 grep 确认 `.channel`/`UpdateChannel`/`currentBuildDate`/`buildDate(from` 只在 `UpdateChecker.swift` 出现，改动无外部涟漪。

# 对话与行动记录

用户这轮提了三个独立问题，逐一处理：

**1. 更新检查改为纯版本号比较。** 用户直接点出核心问题：如果依赖发布/构建时间比较，同一个版本打两次包（时间戳不同、内容相同）会被误判成"有更新"——这也是上一轮时区 bug 修复"治标不治本"的地方，只要还依赖时间就永远有踩时区/时钟的风险。改为彻底不看时间：

- `SemanticVersion.init?(tag:)` 从"必须严格三段数字、有任何 `-suffix` 就拒绝"改成"剥离首个 `-` 之后的任意内容再解析 X.Y.Z"，这样 `v0.10.0-dcfff71` 能正确解析出 `0.10.0`，sha 部分只是构建标识、不参与比较。
- 删掉 `UpdateChannel` 枚举、`UpdateCandidate.channel`/`publishedAt` 字段、`buildDate(fromBundleVersion:)`、`pickUpdate` 的 `currentBuildDate` 参数和 10 分钟发布时间缓冲逻辑。
- `pickUpdate` 简化成一句话：候选里 `X.Y.Z` 最高且严格大于当前版本的那个；没有就是最新。
- 新增仓库根目录 `VERSION` 文件（内容 `0.10.0`），作为版本号唯一权威来源。`build-app.sh` 改为读这个文件 + `git rev-parse --short HEAD`，始终写 `CFBundleShortVersionString = "<VERSION>-<sha>"`，删掉原来"空值走 1.0 / `VERSION=vX.Y.Z` 走 semver"的双通道分支。`release.yml` 同步：去掉 `workflow_dispatch` 的手动 `version` 输入，push main 和手动触发统一走同一条"读 VERSION 文件打 tag"路径，不再区分 `nightly-<sha>` 和 `vX.Y.Z` 两种 tag。
- `AboutSettingsView` 去掉 `version == "1.0"` 的 nightly 特殊展示分支。
- `UpdateCheckerTests.swift` 全面重写：删掉所有 channel/发布时间相关测试，新增"git sha 后缀被忽略只比 X.Y.Z"、"发布时间更新但版本号更低不会被选中"、"相同 X.Y.Z 不同 sha 不算更新"三个针对性场景。
- 按用户要求把这套规则写进了 `AGENTS.md` 项目专用内容的新小节「版本号维护规则」：`vX.Y.Z-<sha>` 格式、`VERSION` 文件权威来源、Agent 按改动量级判断 PATCH/MINOR/MAJOR 的启发式（对应 REQUIREMENTS.md 是否开新 Phase）、每次改动 `VERSION` 必须在 agent-log 里写明原因。本轮判断：这批都是发现于用户实测的 bug 修复 + 版本号方案本身的架构调整，仍算在尚未正式发布过的 v0.10.0 批次里，**未 bump `VERSION`**（保持 `0.10.0`），后续如果这批修复要单独发一个版本，再决定是否 bump PATCH。

**2. dropdown 隐藏按钮不实时刷新。** 根因：`RefreshCoordinator` 订阅 `.quotaPreferencesDidChange` 用的是 `.receive(on: RunLoop.main)`，Combine 默认走 `RunLoop.Mode.default`；但点击 dropdown 里的叉这个瞬间，正处于 `NSMenu` 的鼠标 tracking loop（`.eventTracking` mode）里，`.default` 模式排的任务要等菜单关闭、tracking loop 退出才会执行——这正是"要关闭再打开 dropdown 才生效"的机制。改为 `.receive(on: DispatchQueue.main)`（GCD 主队列走 common run loop mode，不受 tracking mode 影响），并且让 `hide(kind:)` 额外同步直接调一次 `applyEnabledFilterChange()`，双重保险不完全依赖异步通知链路的时机。

**3. Z Code / GLM 开关关联不上。** 读 `ModelsSettingsView.visibleProviders` 发现列表里写的是 `.glm`，但 `Strategies.supportedProviderKinds` 从来没把 `.glm` 接进任何真实 pipeline——dropdown 里实际运行、实际能被隐藏的是 `.zcode`。两个不同的 `ProviderKind` 枚举值意味着两套完全独立的 `PreferencesStore.providerOverrides` 记录，互不影响，这就是为什么切 "GLM" 开关没反应、dropdown 隐藏 "Z Code" 也不会同步回 Preferences。改成用真正在跑的 `.zcode`，vendor 文案顺手从 `"Z Code"` 改成更准确的 `"智谱 / Z.ai"`。`.glm` 枚举本身没删（还在别处当遗留 metadata 用，删除是另一件事，本轮不做无关扩大）。

# 完成工作

- `macos/Sources/QuotaBar/UpdateChecker.swift`：移除时间比较相关的一切（channel、buildDate、发布时间缓冲），`SemanticVersion` 容忍 git sha 后缀，`pickUpdate` 简化为纯语义化版本号比较。
- `macos/Sources/QuotaBar/Preferences/AboutSettingsView.swift`：移除 `"1.0"` nightly 特殊分支。
- `macos/scripts/build-app.sh`：读取根目录 `VERSION` 文件 + git short sha 生成 `CFBundleShortVersionString`，移除 `VERSION` 环境变量双通道逻辑。
- `.github/workflows/release.yml`：移除 `workflow_dispatch` 手动 version 输入和 nightly/semver 双路径，统一成"读 VERSION 文件打 tag"单路径。
- 新增 `/Users/taobe/Projects/GitHub/Personal/quota-bar/VERSION`（内容 `0.10.0`）。
- `macos/Sources/QuotaBar/RefreshCoordinator.swift`：`.quotaPreferencesDidChange` 订阅改用 `DispatchQueue.main`；`hide(kind:)` 增加同步直调 `applyEnabledFilterChange()`。
- `macos/Sources/QuotaBar/Preferences/ModelsSettingsView.swift`：`visibleProviders` 把 `.glm` 换成 `.zcode`，vendor 文案改为"智谱 / Z.ai"。
- `macos/Tests/QuotaBarTests/UpdateCheckerTests.swift`：全面重写匹配新 API。
- `AGENTS.md`：新增「版本号维护规则」小节。
- `README.md`：「更新策略」章节改写，去掉 nightly/stable 通道描述。
- `REQUIREMENTS.md`：v0.10.0 phase 新增一个 sub/main 章节，登记本轮 7 个任务 ID（`0.10.0-ARCH-J-000/001/002`、`0.10.0-DOC-A-005`、`0.10.0-BUG-A-009/010`、`0.10.0-QA-A-001`）。
- 新包：`macos/build/20260707-173519-main/Quota Bar.app`（`build/latest` 已指向），已用 `PlistBuddy` 验证 `CFBundleShortVersionString` 正确写成 `0.10.0-dcfff71`。

# 更新的需求 ID

- `[0.10.0-ARCH-J-000]` `[0.10.0-ARCH-J-001]` `[0.10.0-ARCH-J-002]`
- `[0.10.0-DOC-A-005]`
- `[0.10.0-BUG-A-009]` `[0.10.0-BUG-A-010]`
- `[0.10.0-QA-A-001]`

# 更新的 README 或 DESIGN 章节

- README：「更新策略（ad-hoc 预开发版）」章节改写。
- DESIGN：无改动。

# 验证方式

- `swift build`：无警告无错误。
- `swift test`：180 tests in 42 suites 全部通过。
- `./scripts/build-app.sh`：产包成功；`PlistBuddy -c "Print :CFBundleShortVersionString"` 验证输出为 `0.10.0-dcfff71`，格式符合预期。
- 未做真实端到端验证（比如真的推一个 tag 看 GitHub Actions 跑出来的 release 是否符合新格式，或者真的在 dropdown 里点叉验证 UI 层面即时隐藏）——这两处改动逻辑清晰、根因明确，但受限于当前工具条件无法验证 GitHub Actions 实际运行效果和真实鼠标点击下的 UI 行为。

# 备注

- 未提交 git commit——按照"只在用户明确要求时才提交"的原则，等用户确认这轮修复后再决定是否需要提交/推送。
- `VERSION` 文件未 bump（保持 `0.10.0`）：本轮改动仍是同一批"尚未正式发布过"的 v0.10.0 修复与架构调整，没有新增独立于已有范围的用户可感知功能。下次如果这批修复本身要作为一个独立可下载版本发出去，需要重新评估是否该 bump PATCH。
- `.glm` 这个 `ProviderKind` 枚举本身仍然存在（只是不再出现在 `ModelsSettingsView.visibleProviders` 里），是否要整体删除是一个独立的清理决策，本轮未处理。
