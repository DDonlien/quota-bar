# 用户原始 prompt

> 3个问题：
> 1. dropdown不规范，zcode要么就是webview授权，要么就确定（之前没说）没有订阅，显示灰色字未订阅；另外，只有在明确获取到额度/订阅信息是未订阅，显示"未订阅或订阅已过期"，如果只是不清楚是否订阅，显示webview授权按钮
> 2. 日志叫日志就好，不用叫获取日志
> 3. 查看这个日志：为什么很多provider的额度、档位信息只走了1个方案就没有走其他fallback了？
>（附完整 `provider-check.log` 片段，覆盖 Z Code / MiniMax / Claude / Kimi / Codex / Antigravity）

# 启动运行时的分支和版本

- 分支：`main`
- 版本：`1bba4e3` + 此前八次会话的未提交改动（本次是第九次）

# 任务开始时间

2026-07-07 约 10:05 +0800

# 任务结束时间

2026-07-07 10:19 +0800

# 任务结束时是否执行了提交

未提交（累计九次会话改动都在工作区，等用户 review）。

# 已阅读上下文

- `MenuView.swift`：`PlanSection.body` 里 `.needsConfiguration`/`.notSubscribed` 分支、`StatusRow` 结构。
- `ProviderFetchStrategy.swift`：`orderedStrategies(for:)` 的"缓存优先重排"逻辑。
- `ClaudeAuthStatusCLIProvider.swift`：`parseStatusOutput` 的 `monthlyPrice` 赋值。
- `Tests/QuotaBarTests/ProviderFetchStrategyTests.swift`：`quotaOnlySourceCannotShadowFullSource` 测试，确认重排逻辑原本要保护的场景。
- 用户贴出的真实 `provider-check.log` 片段——上一轮刚上线的诊断日志，第一次实测就抓出了两个之前没被注意到的真实 bug。

# 对话与行动记录

**问题 3 最关键，也是这次真正的"根因排查"**：用户直接贴了一段真实日志问"为什么很多 provider 只走了 1 个方案就没 fallback"。逐个 provider 对照日志重新走一遍代码：

- Kimi 的日志显示顺序是 `kimi-desktop-token → kimi-webview（失败）→ kimi-auth（成功）`——但 `Strategies.swift` 里声明的顺序明明是 `[kimi-desktop-token, kimi-auth, ..., kimi-webview, kimi-keychain]`，kimi-webview 应该是最后一道兜底，怎么会在 kimi-auth 之前被尝试？
- Claude 的日志显示第一个被尝试的是 `claude-auth-status-cli`（一个只贡献档位的 P3 兜底层），而不是声明第一位、零权限的 `claude-statusline`。

顺着这两个反常现象查到 `FetchPipeline.orderedStrategies(for:)`：这个函数只要发现"上次成功来源索引"里有任何一层的缓存记录，就会把**所有**`supportedLayers`覆盖满三层（quota+expiration+plan）的 strategy 整体提到最前面，跟这些 strategy 各自在数组里声明的位置完全无关。而 `QuotaProviderStrategy.supportedLayers` 对没有特殊 id 模式匹配的 strategy 一律默认给三层全覆盖——这意味着 kimi-webview（一个昂贵的最后兜底）和 kimi-desktop-token（真正应该最先尝试的首选）在这个算法眼里"同样完整"，纯粹因为声明顺序之外的巧合被提前。这是一个真实的架构 bug，不是数据源问题：用户从一开始就反复强调"必须严格按声明顺序退级"，这个缓存重排在悄悄违反这条契约。

检查了这个函数唯一对应的测试 `quotaOnlySourceCannotShadowFullSource`——发现它的验证目标（"不该让一个只覆盖单层的缓存来源抢在一个覆盖更全的来源前面"）在**完全不做任何重排、只按数组声明顺序执行**的情况下也天然成立（测试里"full"就是声明在"partial"前面）。也就是说这个重排逻辑本身要解决的问题，声明顺序已经解决了，之前是重复建设还带来副作用。于是直接删除整套重排逻辑，`orderedStrategies` 改成恒定返回声明顺序；`runSequential` 本身"拿到完整层就提前 break"已经是唯一需要的效率优化，不需要额外一层重排。

顺带在同一个函数追查时，发现 Claude 的日志还有一条更直接的信息：`档位与费用获取, claude-auth-status-cli: 成功，档位=Pro，价格=未获取`——档位明明拿到了，价格却是"未获取"。查 `ClaudeAuthStatusCLIProvider.parseStatusOutput`：这个 provider 硬编码 `monthlyPrice: nil`，从来没调用 `ProviderPricing.localizedMonthlyPrice`，即便 `ProviderPricing` 里已经有 `(.claude, "pro") → $20` 的真实映射。这是一处遗漏——档位和价格分属两个独立维度，"不伪造额度"这条设计原则本来只该管 quotas 留空，被写代码时误连带把价格也留空了。已修复为跟 Codex/Kimi/Antigravity 等 provider 一致的写法，调用价格映射表。

这两个 bug 是新增诊断日志系统上线第一天就被实测抓出来的，验证了这套日志本身的价值。

**问题 1（Z Code 等待配置态显示混乱）**：现有 `.needsConfiguration` 分支会同时渲染一段原始技术性 reason 文本（例如日志里那种 `builtin:bigmodel-coding-plan: coding_plan_not_entitled；...` 拼接串）和一个「打开 WebView 授权」按钮，两个一起出现，观感确实混乱。按用户的规则重写：不确定是否订阅（`.needsConfiguration`，即拿数据失败/凭证问题等，还不知道到底有没有订阅）→ 只显示清爽的授权按钮，不展示原始 reason；确定没有订阅（`.notSubscribed`，服务端已经明确告知）→ 显示统一的灰色定论文案「未订阅或订阅已过期」，不带按钮。两种状态语义完全不同（前者"不知道"，后者"已确认"），不该用同一套"待配置 · reason"文案。

**问题 2**：Preferences sidebar 标签从「获取日志」简化为「日志」，一行改动。

# 完成工作

- `ProviderFetchStrategy.swift`：删除 `orderedStrategies` 的缓存重排逻辑，恒定按声明顺序执行；`logSourceOrdering` 改写措辞明确"仅供参考，不改变执行顺序"。
- `ClaudeAuthStatusCLIProvider.swift`：`parseStatusOutput` 改为 `async`，调用 `ProviderPricing.localizedMonthlyPrice(kind: .claude, tier:)` 补上价格。
- `MenuView.swift`：`.needsConfiguration` 分支按"有无 WebView 授权入口"分流（只给按钮 / 只给原始 reason，二选一，不再同时出现）；`.notSubscribed` 分支改为固定文案「未订阅或订阅已过期」；`StatusRow` 精简掉不再使用的 `actionTitle`/`action` 参数。
- `Preferences/PreferencesSection.swift`：sidebar 标签「获取日志」→「日志」。
- `README.md`：同步更新数据流/诊断日志/dropdown 章节，补充"排序恒等于声明顺序，不受缓存影响"的说明，以及待配置态两种确定性的显示规则。
- 测试：更新 `ClaudeOAuthUsageProviderTests.swift` 里 `ClaudeAuthStatusCLIProvider parsing` 套件的三个测试为 `async`，新增价格非空断言。
- 新包：`macos/build/20260707-101930-main/Quota Bar.app`（`build/latest` 已指向）。

# 更新的需求 ID

- 新增并完成：`0.10.0-BUG-A-002`（strategy 排序重排 bug）、`0.10.0-BUG-A-003`（Claude 价格丢失 bug）、`0.10.0-UI-B-002`（needsConfiguration 分支重写）、`0.10.0-UI-B-003`（notSubscribed 分支重写）、`0.10.0-PM-A-015`（日志标签简化）

# 更新的 README 或 DESIGN 章节

- `README.md`「数据流」/「获取诊断日志」：补充"执行顺序恒等于声明顺序，不受上次成功来源缓存影响"的说明及背后教训。
- `README.md`「菜单栏下拉 UI」：新增"待配置态"条目，说明"不清楚是否订阅"与"确定没有订阅"两种确定性的不同展示规则。

# 验证方式

- `swift build`：无警告无错误。
- `swift test`：176 tests in 41 suites 全部通过，包括原本用来保护"缓存不能让部分覆盖来源抢在完整来源前面"这条性质的 `quotaOnlySourceCannotShadowFullSource`——确认删除重排逻辑后，靠自然声明顺序就已经满足该测试。
- `./scripts/build-app.sh`：产包成功。
- 未做真实 GUI 交互验证（未启动打包后的 app 手动核对 Z Code/Claude 显示效果），仍是靠单元测试 + 代码走读 + 用户提供的真实日志确认逻辑；这点如实告知。

# 备注

- 未提交 git commit。
- 这一轮最大的收获是方法论上的：上一轮刚上线的结构化诊断日志，第一次真实使用就直接暴露了两个此前完全没被注意到的架构性 bug（strategy 排序、Claude 价格丢失）——不是靠猜、也不是靠再加一层日志去调试日志，而是用户直接读原始记录发现的不合理之处，反向定位到代码。这印证了当初做这套日志系统是值得的。
- `orderedStrategies` 删除重排逻辑后，`sourceIndexStore`/`preferredSourceID` 在 pipeline 排序层面已经不再被使用，仅保留给"安装探测的 preferredSourceId 快速路径"（`InstallDetectorProvider.detectPreferredSource`，性质不同、继续保留）和"缓存 snapshot 的来源标注"（`RefreshCoordinator.snapshotCacheSourceRecord`，纯展示用途、继续保留）两处合理场景使用；没有变成完全的死代码。
