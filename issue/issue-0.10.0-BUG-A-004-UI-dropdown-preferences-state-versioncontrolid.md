# sub/main: 缓存优先级语义纠正 + dropdown 隐藏按钮与 Preferences 开关状态统一

- ID：`0.10.0-BUG-A-004`。
- 类型：`UI`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 缓存优先级语义纠正 + dropdown 隐藏按钮与 Preferences 开关状态统一。
- 原稳定 ID：`0.10.0-BUG-A-004`, `0.10.0-UI-B-004`, `0.10.0-ARCH-F-000`, `0.10.0-ARCH-F-001`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户纠正 0.10.0-BUG-A-002 的"完全不看缓存、恒定按声明顺序"过于绝对：正确语义是"每层如果有缓存，优先检查缓存；缓存没有返回结果，才按声明顺序完整跑一遍（不是默认就重跑）"。同时指出 dropdown 的隐藏（叉）按钮应该对所有没拿到真实额度的 provider 一致提供，且点击效果必须等同于 Preferences 里把该 provider 关掉——不能是"dropdown 里看不见了、后台还在正常刷新"的假隐藏。

- [x] [0.10.0-BUG-A-004] `FetchPipeline.effectiveOrder`/`cachedFirstStrategy`：只有当本轮所需的**全部**层（额度 + 档位）的「上次成功来源索引」一致指向同一个 strategy id 时，才把它提到最前单独先试一次；试完无论成败，剩余 strategy 依然按 pipeline 声明顺序完整跑一遍（跳过刚试过的那个，避免同一轮重复调用）。层与层之间不一致、或任一层完全没有缓存记录，都视为"信息不全"，直接走完整声明顺序，不取巧——这也是为什么 `quotaOnlySourceCannotShadowFullSource` 这条既有测试还能通过：它只给 quota 层记了缓存，跟 plan 层不一致。新增两条回归测试锁定"层一致时优先且提前于声明顺序"和"缓存来源本轮失败后仍完整 fallback"两种场景 #P0
- [x] [0.10.0-UI-B-004] dropdown 隐藏（叉）按钮从"只在 `.needsConfiguration` 出现"改为"所有没有真实额度数据的 provider 都出现"（`.needsConfiguration` / `.notSubscribed` / `.subscriptionExpired` / `.available` 但 `quotas.isEmpty`），已有真实额度的 provider 不提供（没有"不想用"的诉求，误触代价也更高）#P1
- [x] [0.10.0-ARCH-F-000] 删除 `RefreshCoordinator.hiddenKinds`（内存态、手动刷新会被 `clearHidden()` 清空的临时隐藏集合），改为统一读写 `PreferencesStore.isEnabled(kind:)`（持久化）。`hide(kind:)` 现在直接调用 `PreferencesStore.setEnabled(false, for:)`；`runRefreshCycle` 的 `activeProviders` 过滤也改读同一个持久化状态。dropdown 隐藏按钮和 Preferences「模型」页的开关现在是同一份状态的两个入口，任一边改动都会真正阻止该 provider 发起请求，而不是只在 UI 上视觉隐藏 #P0
- [x] [0.10.0-ARCH-F-001] `RefreshCoordinator` 新增 `applyEnabledFilterChange()`，订阅 `.quotaPreferencesDidChange` 通知：立即把刚被关闭的 provider 从 `state.snapshots` 摘掉；刚被重新启用但 `state.snapshots` 里还没有它的 provider，立刻触发一次 `refreshNow()`，不用等下一个 5 分钟自动周期 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
