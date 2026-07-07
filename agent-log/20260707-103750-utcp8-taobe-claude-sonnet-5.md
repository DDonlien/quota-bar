# 用户原始 prompt

> 纠正你的逻辑，我们正确的顺序应该是：
> 每个provider的每个层，如果有缓存，优先检查缓存；如果缓存没有返回结果，按顺序全都跑一遍（不是默认就重跑）
>
> dropdown还有一个一致性问题：所有没获取到额度的provider应该都提供叉图标按钮，现在只有zcode有，叉了以后dropdown里隐藏，但刷新还是正常刷新，等效于在preferences里关闭（确保能同步状态且preferences里的provider按钮也是同样的效果和逻辑）

# 启动运行时的分支和版本

- 分支：`main`
- 版本：`1bba4e3` + 此前九次会话的未提交改动（本次是第十次）

# 任务开始时间

2026-07-07 约 10:22 +0800

# 任务结束时间

2026-07-07 10:37 +0800

# 任务结束时是否执行了提交

未提交（累计十次会话改动都在工作区，等用户 review）。

# 已阅读上下文

- 上一轮（`20260707-101937` agent-log）里刚把 `FetchPipeline.orderedStrategies` 改成"完全不看缓存、恒定按声明顺序"，用户这次明确指出这个中间态过于绝对。
- `Tests/QuotaBarTests/ProviderFetchStrategyTests.swift`：`quotaOnlySourceCannotShadowFullSource` 这条既有测试，用来校验新实现是否还能保持它原本要保护的性质。
- `RefreshCoordinator.swift`：`hiddenKinds`（内存态）、`hide(kind:)`、`clearHidden()`、`refreshNow()` 里对 `clearHidden()` 的调用、`runRefreshCycle` 里 `activeProviders` 的过滤条件。
- `PreferencesStore.swift`：`isEnabled(kind:)`/`setEnabled(_:for:)`——发现这两个方法此前在整个代码库里**没有任何调用方**读取，Preferences 里切开关只是把状态写盘，没有任何地方真正用它过滤 provider；真正在起过滤作用的是 `RefreshCoordinator.hiddenKinds`，一个纯内存态、且在每次手动刷新时会被 `clearHidden()` 清空的集合。
- `MenuView.swift`：`PlanHeader.body` 里 `HideButton` 目前嵌在 `case .needsConfiguration` 分支内，只有这个 availability 状态才会渲染。

# 对话与行动记录

**第一个问题（缓存排序纠正）**：上一轮我把"缓存重排"整个删掉、改成恒定按声明顺序，用户明确指出这不对——正确逻辑应该是"每层如果有缓存，先试缓存；缓存没有结果，再按顺序完整跑一遍"，也就是缓存是一个**优先尝试的快捷方式**，不是被完全忽略，也不是像上上一版那样野蛮地把"覆盖全部层"的 strategy 一律提到最前。

按这个纠正重新实现：新增 `cachedFirstStrategy(for:)`，只有当本轮请求的**全部**层（额度 + 档位）的「上次成功来源索引」**一致**指向同一个 strategy id 时，才信任并把它作为第一个尝试对象；`effectiveOrder(for:)` 把这个缓存优先来源放最前，后面跟着**完整的**声明顺序列表（跳过刚试过的那个，避免同一轮内对同一个 strategy 打两次一模一样的请求）。

实现过程中先写了一版用 `compactMap` 收集非 nil 的 preferredId 再判断"是否只有一个值"——这个写法有个隐蔽 bug：`compactMap` 会把"这一层压根没有缓存记录"（nil）直接丢弃，等效于把"缺失"和"被忽略"混同，导致只要有一层有缓存、其他层没有记录，也会被误判成"一致"。用既有测试 `quotaOnlySourceCannotShadowFullSource` 一测就跑出来了（因为它就是"quota 层有缓存、plan 层没有"这个精确场景）：`.subscriptionTier` 断言从预期的 "Full" 变成了 "Partial"。修好后改成保留每层原始的 `String?`（包括 nil），要求全部层都显式等于同一个非 nil 值才算"一致"，这条测试恢复通过。

之后专门新增两条测试锁定这次纠正后的精确语义：
1. 两层都指向同一个"声明第二"的来源时，它确实会被优先尝试（即使排在声明第一的前面）；
2. 缓存来源这次失败时，完整的声明顺序 fallback 依然会把剩下的 strategy 跑一遍，不会因为"试过缓存"就提前放弃。

**第二个问题（隐藏按钮一致性 + 状态同步）**：追查后发现这不只是"UI 显示不一致"，而是一个真实的架构缺口——`PreferencesStore.isEnabled`/`setEnabled` 这两个方法在整个代码库里**完全没有被读取**，Preferences「模型」页切开关只是把状态写盘，从没有任何地方真正拿它过滤 provider；真正起作用的是 `RefreshCoordinator.hiddenKinds`，一个纯内存态集合，而且这个集合在**每次手动点「立即刷新」时都会被 `clearHidden()` 清空**——这正好解释了用户观察到的"叉了以后 dropdown 隐藏，但刷新还是正常刷新"：隐藏状态本身就是脆弱的、易失的，跟 Preferences 完全是两套互不知情的机制。

统一方案：删除 `hiddenKinds`/`clearHidden()`，`RefreshCoordinator.hide(kind:)` 直接调用 `PreferencesStore.setEnabled(false, for:)`（持久化），`runRefreshCycle` 的 `activeProviders` 过滤也改读 `PreferencesStore.isEnabled(kind:)`；新增 `applyEnabledFilterChange()` 订阅 `.quotaPreferencesDidChange` 通知，任一边（dropdown 叉按钮或 Preferences 开关）改动后，立刻把新禁用的 provider 从 `state.snapshots` 摘掉，把新启用但还没数据的 provider 立刻触发一次刷新（不用等 5 分钟自动周期）。这样两个入口现在是同一份持久化状态的两个视图，效果和逻辑完全一致。

同时把隐藏按钮的可见性从"只在 `.needsConfiguration`"扩大为"所有没有真实额度数据的状态"（`.needsConfiguration` / `.notSubscribed` / `.subscriptionExpired` / `.available` 但 `quotas.isEmpty`），已经有真实额度的 provider 不提供（没有"不想用"的诉求）。

# 完成工作

- `ProviderFetchStrategy.swift`：新增 `effectiveOrder(for:)`/`cachedFirstStrategy(for:)`，替换上一轮"完全不看缓存"的实现；`logSourceOrdering` 措辞相应更新。
- `RefreshCoordinator.swift`：删除 `hiddenKinds`/`clearHidden()`；`hide(kind:)` 改为持久化调用；新增 `applyEnabledFilterChange()`；`activeProviders` 过滤改读 `PreferencesStore.isEnabled`。
- `MenuView.swift`：`PlanHeader` 新增 `canHide` 计算属性，`HideButton` 从嵌在 `.needsConfiguration` 分支里移到始终可能渲染的位置（按 `canHide` 决定）；顺带把只剩一个 `default` 分支的 `switch` 简化成 `if`。
- 测试：`ProviderFetchStrategyTests.swift` 新增两条测试（缓存一致时优先尝试、缓存失败后完整 fallback）+ 新增 `ThrowingStubStrategy`。
- 新包：`macos/build/20260707-103743-main/Quota Bar.app`（`build/latest` 已指向）。

# 更新的需求 ID

- 新增并完成：`0.10.0-BUG-A-004`（缓存优先级语义纠正）、`0.10.0-UI-B-004`（隐藏按钮可见范围扩大）、`0.10.0-ARCH-F-000`（hiddenKinds → PreferencesStore 统一）、`0.10.0-ARCH-F-001`（`applyEnabledFilterChange` 即时同步）
- 更新：`0.10.0-BUG-A-002` 描述补充说明它是被后续纠正的中间态

# 更新的 README 或 DESIGN 章节

- `README.md`「获取诊断日志」：更新执行顺序说明为"缓存一致时优先试、否则完整走声明顺序"，如实记录这条规则是两次用户纠正后定型的。
- `README.md`「菜单栏下拉 UI」：新增「隐藏按钮」条目，说明其可见范围和与 Preferences 开关的状态同步关系。

# 验证方式

- `swift build`：无警告无错误。
- `swift test`：178 tests in 41 suites 全部通过，包括修复重新加回的既有测试 `quotaOnlySourceCannotShadowFullSource` 和两条新增的缓存优先级回归测试。
- `./scripts/build-app.sh`：产包成功。
- **未覆盖的部分**：`RefreshCoordinator`/`PreferencesStore` 的隐藏-启用同步逻辑（`applyEnabledFilterChange`）没有自动化测试——`PreferencesStore` 是硬编码单例（`init()` 没有可注入的测试目录），`RefreshCoordinator` 也没有现成的测试夹具支持独立实例化 + mock provider，搭这套测试基础设施超出本次修复的范围；这部分只做了代码走读验证，如实告知这是已知的验证缺口。也没有做真实 GUI 交互验证。

# 备注

- 未提交 git commit。
- 这是同一个"来源优先级排序"逻辑在两次会话里被连续纠正三次（原始 bug → 中间态"完全不看缓存" → 现在这版"缓存优先、失败才完整 fallback"）——每次纠正都对应一条新增的回归测试，现在这块逻辑的测试覆盖比最初写的时候扎实得多。
- 发现 `PreferencesStore.isEnabled`/`setEnabled` 长期是死代码（没有调用方）这件事，是本次排查隐藏按钮问题时的副产品，不是用户直接指出的——如实记录这是我在解决报告的问题时顺带发现并修复的一个更深层的架构缺口。
