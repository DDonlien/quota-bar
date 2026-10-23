# sub/main: 更新检查改为纯版本号比较 + dropdown 隐藏按钮实时刷新 + GLM/Z Code 开关关联修复

- ID：`0.10.0-ARCH-J-000`。
- 类型：`ARCH`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 更新检查改为纯版本号比较 + dropdown 隐藏按钮实时刷新 + GLM/Z Code 开关关联修复。
- 原稳定 ID：`0.10.0-ARCH-J-000`, `0.10.0-ARCH-J-001`, `0.10.0-ARCH-J-002`, `0.10.0-DOC-A-005`, `0.10.0-BUG-A-009`, `0.10.0-BUG-A-010`, `0.10.0-QA-A-001`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户实测发现三个问题：装好最新构建后「关于」页仍提示"有更新"（根因见 0.10.0-DOC-A-004 之后的时区 bug 修复只是治标）；用户明确指出更新判断不该依赖发布/构建时间，同一版本重复打包不该被当成"有更新"，要求改成纯版本号比较，并给出 `vX.Y.Z-<git-sha>` 格式规则、X.Y.Z 由 Agent 维护；dropdown 隐藏（叉）按钮点击后要关闭再打开 dropdown 才生效；Preferences「模型」页的 Z Code/GLM 开关与 dropdown 隐藏状态没有关联（只有 MiniMax 是好的）。

- [x] [0.10.0-ARCH-J-000] `UpdateChecker.swift` 彻底移除按发布/构建时间比较的设计：删除 `UpdateChannel` 枚举与 `UpdateCandidate.channel`/`publishedAt` 字段、`buildDate(fromBundleVersion:)`、`pickUpdate` 的 `currentBuildDate` 参数和 10 分钟缓冲逻辑；`SemanticVersion.init?(tag:)` 改为剥离首个 `-` 之后的任意后缀（如 git short sha）再解析 `X.Y.Z`；`pickUpdate` 简化为纯语义化版本号比较——取候选中 `X.Y.Z` 最高且严格大于当前版本的那个，同一 `X.Y.Z`（不管 sha 是否不同）不算更新 #P0
- [x] [0.10.0-ARCH-J-001] 新增仓库根目录 [`VERSION`](../VERSION) 文件（内容 `0.10.0`）作为版本号唯一权威来源；`build-app.sh` 改为读取该文件 + `git rev-parse --short HEAD`，始终写入 `CFBundleShortVersionString = "<VERSION>-<sha>"`，移除原来的 `VERSION` 环境变量 + 空值走 `"1.0"` 的双通道分支；`.github/workflows/release.yml` 同步移除 `workflow_dispatch` 的手动 `version` 输入，push main / 手动触发都统一走"读 VERSION 文件 + 当前 sha 打 tag"这一条路径，不再产出 `nightly-<sha>` 与 `vX.Y.Z` 两种 tag #P0
- [x] [0.10.0-ARCH-J-002] `AboutSettingsView` 移除 `version == "1.0"` 的 nightly 特殊展示分支：所有版本都是真实 `X.Y.Z-sha`，"已是最新版本"直接显示 `v\(version)` #P1
- [x] [0.10.0-DOC-A-005] `AGENTS.md` 新增「版本号维护规则」小节：`VERSION` 文件权威来源、Agent 按改动量级判断 PATCH/MINOR/MAJOR 的启发式、每次改动 `VERSION` 必须在 agent-log 里写明原因；`README.md`「更新策略」章节同步改写，不再提 nightly/stable 两条通道 #P1 #cut 旧工作制度已由本轮 Issue 流程替代；原勾选只保留历史事实。
- [x] [0.10.0-BUG-A-009] `RefreshCoordinator` 的 `.quotaPreferencesDidChange` 订阅从 `.receive(on: RunLoop.main)` 改为 `.receive(on: DispatchQueue.main)`：`RunLoop.main` 默认用 `.default` run loop mode，dropdown 的 `NSMenu` 鼠标 tracking 期间是 `.eventTracking` mode，`.default` 模式排的任务要等菜单关闭才会跑，这正是"点了叉不会立刻隐藏，要关闭再打开 dropdown 才生效"的根因；`hide(kind:)` 额外同步直接调用一次 `applyEnabledFilterChange()`，不完全依赖异步通知链路的时机 #P0
- [x] [0.10.0-BUG-A-010] `ModelsSettingsView.visibleProviders` 把幽灵 kind `.glm`（从未接入任何真实 pipeline）换成实际在跑的 `.zcode`——此前 Preferences 切 "GLM" 开关和 dropdown 隐藏 "Z Code" 是两个完全独立的 `ProviderOverride` 记录，互不影响；`providerVendor(.zcode)` 的展示文案从 `"Z Code"` 改为更准确的 `"智谱 / Z.ai"` #P0
- [x] [0.10.0-QA-A-001] `UpdateCheckerTests` 全面重写以匹配新 API：删除所有 channel/发布时间相关测试（`stablePreferredOverNightly`、`nightlyRecommendedByPublishDate`、`parsesBuildDate` 等），新增覆盖"git sha 后缀被忽略"、"发布时间更新但版本号更低的候选不会被选中"、"相同 X.Y.Z 不同 sha 不算更新"三个场景 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260707-174200-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260707-174200-utcp8-taobe-claude-sonnet-5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

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

#### 完成工作

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

#### 更新的需求 ID

- `[0.10.0-ARCH-J-000]` `[0.10.0-ARCH-J-001]` `[0.10.0-ARCH-J-002]`
- `[0.10.0-DOC-A-005]`
- `[0.10.0-BUG-A-009]` `[0.10.0-BUG-A-010]`
- `[0.10.0-QA-A-001]`

#### 验证方式

- `swift build`：无警告无错误。
- `swift test`：180 tests in 42 suites 全部通过。
- `./scripts/build-app.sh`：产包成功；`PlistBuddy -c "Print :CFBundleShortVersionString"` 验证输出为 `0.10.0-dcfff71`，格式符合预期。
- 未做真实端到端验证（比如真的推一个 tag 看 GitHub Actions 跑出来的 release 是否符合新格式，或者真的在 dropdown 里点叉验证 UI 层面即时隐藏）——这两处改动逻辑清晰、根因明确，但受限于当前工具条件无法验证 GitHub Actions 实际运行效果和真实鼠标点击下的 UI 行为。

#### 备注

- 未提交 git commit——按照"只在用户明确要求时才提交"的原则，等用户确认这轮修复后再决定是否需要提交/推送。
- `VERSION` 文件未 bump（保持 `0.10.0`）：本轮改动仍是同一批"尚未正式发布过"的 v0.10.0 修复与架构调整，没有新增独立于已有范围的用户可感知功能。下次如果这批修复本身要作为一个独立可下载版本发出去，需要重新评估是否该 bump PATCH。
- `.glm` 这个 `ProviderKind` 枚举本身仍然存在（只是不再出现在 `ModelsSettingsView.visibleProviders` 里），是否要整体删除是一个独立的清理决策，本轮未处理。
