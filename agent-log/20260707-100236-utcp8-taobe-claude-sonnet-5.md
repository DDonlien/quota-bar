# 用户原始 prompt

> preferences里provider你直接漏了agy
>
> dropdown里直接没有claude
>
> 然后，preferences里增加日志，日志规则如下：
> 首先，我们的检查应该是从第一层到第四层，每一个 provider 单独顺序检查，provider 和 provider 之间并发检查。
> 如果现在不是这样，修改。
>
> 日志结构如下：
> `<yyyy.mm.dd_hh.mm.ss> - <IntendedProviderName>: <CheckStep>, <MethodName>: <Result>`
> 其中checkstep对应1～4层的check本身的名字，methodname对应方案名字，result如实返回即可
>
> 日志输出的顺序规范如下：
> 1. 同一个Intended Provider Name的内容总是连续输出
> 2. Check step 总是按实际执行顺序输出。
> 3. 同一个 check step 里面的 method name 总是按实际执行顺序连续输出。
> 4. 如果调用了缓存值，或者是缓存值无效，fallback 到默认顺序，result 里面应该明示；能够抓取到的信息、抓取成功与否、以及失败的理由，result 里面应该明示；
>
> 然后，dropdown里统一显示规则：
> （详见对话——名称栏 `<ProviderName> · <TierName>` 左对齐 + `<最后到期日> <货币符号><费用>/<周期>` 右对齐的完整 cascade 规则；额度栏 `<SegmentName>` + 进度条 + 剩余百分比，拿不到时蓝色「打开 WebView 授权」）

# 启动运行时的分支和版本

- 分支：`main`
- 版本：`1bba4e3` + 此前七次会话的未提交改动（本次是第八次）

# 任务开始时间

2026-07-07 约 09:00 +0800

# 任务结束时间

2026-07-07 10:02 +0800

# 任务结束时是否执行了提交

未提交（累计八次会话改动都在工作区，等用户 review）。

# 已阅读上下文

- `Preferences/ModelsSettingsView.swift`：`visibleProviders` 硬编码列表缺 `.antigravity`。
- `RefreshCoordinator.swift`：`applyProviderResult` 对 `.available` 的 `keepAfterApply` 判断、`runRefreshCycle` 的 `withTaskGroup` 并发结构、`detectInstallReasons` 的并发探测。
- `ProviderFetchStrategy.swift`：`FetchPipeline.runSequential` 分层合并逻辑、`orderedStrategies` 的缓存优先排序。
- `InstallDetectorProvider.swift`：`detectSources` 的 App Bundle / CLI / 环境变量 / 凭证文件四类探测顺序。
- `SubscriptionExpirySources.swift`：`SubscriptionExpiryResolver.resolve` 的过期日 source 遍历顺序。
- `QuotaModels.swift`：`ProviderSnapshot`/`ProviderKind`/`ProviderPricing` 数据模型，确认 `monthlyPrice` 已经是本地化好的字符串（含货币符号+汇率转换+"/月"后缀）。
- `MenuView.swift`：`PlanHeader`/`PlanSection`/`QuotaRows` 现有渲染逻辑。
- `WebAuthorizationController.swift`：`webAuthorizationURL` 已覆盖 codex/claude/kimi/minimax/antigravity/zcode 六个真实 provider。

# 对话与行动记录

**Bug 1（agy 漏了）**：`ModelsSettingsView.visibleProviders` 硬编码数组确实漏了 `.antigravity`，一行修复。

**Bug 2（Claude 在 dropdown 完全不显示，比"没额度"更严重）**：追查后定位到一个真实的架构性 bug，而不是数据源问题——`FetchPipeline.runSequential` 在只有 tier-only 兜底层（`ClaudeAuthStatusCLIProvider`，只贡献档位不贡献额度）成功、后续所有额度层（WebView 会话等）都失败时，会返回 `availability = .available` 但 `quotas = []` 的"幽灵成功" snapshot。而 `RefreshCoordinator.applyProviderResult` 里 `.available` 分支原本写的是 `keepAfterApply = !newSnapshot.quotas.isEmpty`——这条 snapshot 因为 quotas 为空被直接从 `state.snapshots` 里移除，Claude 就这样从 dropdown 里彻底消失，而不是显示"待授权"之类的状态。用直接读代码 + 复盘可复现路径的方式定位，没有靠猜。修复：`.available` 只可能来自至少一个 strategy 成功（不存在"什么都没有"的空 available），所以改成始终 `keepAfterApply = true`；额度为空的展示交给新的 dropdown 额度栏「打开 WebView 授权」提示接住（见下）。

**日志系统**：用户要求"provider 内顺序检查、provider 间并发检查"，如果现在不是就改。实际读代码确认：`RefreshCoordinator` 对安装探测和 pipeline+过期日两个阶段都已经用 `withTaskGroup` 做 provider 间并发；`FetchPipeline.runSequential`、`SubscriptionExpiryResolver.resolve` 内部都是严格 for 循环顺序执行——这条架构要求其实已经成立，不需要改并发模型本身，只需要新增日志埋点如实反映这个已有结构。

新增 `ProviderCheckLog`（actor）+ `ProviderCheckLogStore`：
- 按用户规定的行格式：`<yyyy.mm.dd_hh.mm.ss> - <ProviderName>: <CheckStep>, <MethodName>: <Result>`
- CheckStep 直接对应 README 里已经存在的「四层获取矩阵」命名：`Provider 获取` / `额度获取` / `过期日获取` / `档位与费用获取`，不用另造一套名字。
- MethodName 用每个 strategy 已有的 `id`（如 `claude-statusline`、`claude-oauth`、`codex-auth`）——这个 id 本来就是 `ProviderSourceIndexStore` 持久化用的标识，复用它而不是另起一套命名，避免未来两处定义漂移。
- 排序规则里最关键的一条是"同一个 provider 的内容总是连续输出"——但 provider 之间是并发跑的，如果每条记录即时落盘，物理上会交错。解法：按 provider 内存缓冲，`flush(kind:)` 在该 provider 本轮全部工作（安装探测 / 额度 / 过期日 / 档位）结束时才整段落盘，缓冲区内部天然保持真实调用顺序，落盘后自然满足"连续+顺序"两条规则。
- 埋点覆盖三处：`InstallDetectorProvider.detectSources`（App Bundle/CLI/环境变量/凭证文件逐项命中/未命中，含"上次成功来源缓存"命中或失效的提示）、`FetchPipeline.runSequential`（每次 strategy 尝试按 `supportedLayers ∩ {quota, plan}` 各记一条——一次 fetch 同时贡献额度和档位时会记两条，如实反映"这一次物理调用对两层各有什么贡献"）、`SubscriptionExpiryResolver.resolve`（每个 expiry source 尝试的成功/失败）。
- Preferences 新增「获取日志」页（`DiagnosticsSettingsView`），只读展示 + 刷新/复制/清空。

**dropdown 显示规则重写**：按用户给的详细规格重写 `PlanHeader`（名称栏）和额度栏：
- 名称栏左侧 `ProviderName · TierName`（TierName 缺失省略"·"）；右侧按"TierName 缺失 → 到期日缺失 → 都齐全"三级 cascade：TierName 都没有就假设价格/到期日/周期也一并没有，整个右侧显示一个灰色下划线「打开 WebView 授权」；TierName 有但到期日没有，只在到期日位置显示同样式提示；价格缺失时整组（货币符号/费用/周期）直接不渲染，不再显示"—"占位（这是本次修复的一个真实小 bug：之前到期日的显示错误地要求"价格必须同时存在"才显示，这个耦合没有依据，已解耦）。
- 额度栏：`.available` 但 `quotas.isEmpty` 时渲染新的 `QuotaAuthPromptRow`——有 WebView 授权入口的显示蓝色可点击「打开 WebView 授权」，没有的显示灰色「暂无额度数据」，替代之前的空白 VStack。
- 清理：`ProviderSnapshot.displayName`（原来拼 `"Provider Tier"` 一个字符串）在拆成独立 ProviderName/TierName 两个 Text 后已无调用方，直接删除。

# 完成工作

- `Preferences/ModelsSettingsView.swift`：`visibleProviders` 补 `.antigravity`。
- `RefreshCoordinator.swift`：`.available` 的 `keepAfterApply` 改为恒 true；`detectInstallReasons`/per-provider task 里接入 `ProviderCheckLog.flush(kind:)`。
- `ProviderFetchStrategy.swift`：`runSequential` 接入 `logSourceOrdering`/`logAttempt`。
- `InstallDetectorProvider.swift`：`detectSources` 四类探测逐项记录命中/未命中 + 缓存来源提示。
- `SubscriptionExpirySources.swift`：`resolve` 每个 source 尝试记录成功/失败。
- `ProviderCheckLog.swift`（新文件）：`ProviderCheckLog` actor + `ProviderCheckLogStore`。
- `Preferences/DiagnosticsSettingsView.swift`（新文件）+ `PreferencesSection.swift`/`PreferencesScene.swift`：新增「获取日志」页。
- `MenuView.swift`：`PlanHeader` 名称栏重写、新增 `QuotaAuthPromptRow`、`PlanSection` 额度栏分支重写。
- `QuotaModels.swift`：删除死代码 `ProviderSnapshot.displayName`。
- 测试：新增 `ProviderCheckLogTests.swift`（3 个用例：交错并发下按 provider 分组连续+内部顺序正确、空缓冲区不写入、行格式匹配正则）。
- 新包：`macos/build/20260707-100229-main/Quota Bar.app`（`build/latest` 已指向）。

# 更新的需求 ID

- 新增并完成：`0.10.0-BUG-A-000`（agy 缺失）、`0.10.0-BUG-A-001`（Claude 消失架构 bug）、`0.10.0-ARCH-E-000`（ProviderCheckLog）、`0.10.0-ARCH-E-001`（确认现有并发架构已符合要求）、`0.10.0-ARCH-E-002`（三处埋点）、`0.10.0-PM-A-014`（获取日志页）、`0.10.0-UI-B-000`（名称栏重写）、`0.10.0-UI-B-001`（额度栏重写）、`0.10.0-CLEAN-A-000`（删除死代码）

# 更新的 README 或 DESIGN 章节

- `README.md`「数据流」：把过时的"并发跑 strategy"图替换成真实的"provider 间并发、provider 内严格顺序"结构图，并新增「获取诊断日志」小节说明日志格式/排序规则/落地位置。
- `README.md`「功能」的「菜单栏下拉 UI」条目：补充获取日志页、Antigravity 开关，以及名称栏/额度栏新显示规则的完整说明。

# 验证方式

- `swift build`：全程无警告无错误。
- `swift test`：176 tests in 41 suites 全部通过（新增 3 个 `ProviderCheckLogTests`）。
- `./scripts/build-app.sh`：产包成功，`build/latest` 已更新。
- 未做真实 GUI 交互验证（未启动打包后的 app 手动点开 dropdown/Preferences 截图核对），仅靠单元测试 + 代码走读确认逻辑正确；这是本次验证的已知局限，如实告知用户。

# 备注

- 未提交 git commit。
- `ProviderCheckLogStore.append`/`clear` 从 `queue.async` 改成了 `queue.sync`：写测试时发现异步落盘会导致 `flush` 之后立刻 `readRecentLines()` 读不到数据（真实的竞态，不是测试脏），因为日志本身调用频率很低（每 provider 每刷新周期一次），改成同步换取"flush 完成即可读"的正确性是合理的取舍。
- Claude tier-only 幽灵 available 这个 bug 的教训：`.available` 状态原本被 UI 层隐含假设为"一定有额度"，加入 tier-only 兜底层（上一次会话新增的 `ClaudeAuthStatusCLIProvider`）之后这个假设不再成立，但当时没有同步检查 `RefreshCoordinator` 的过滤逻辑——这次是靠用户实测反馈才发现，说明"分层合并"类的架构改动需要连带检查所有下游对 availability 语义的隐含假设。
