# sub/main: 支持 Provider 增量刷新

- ID：`0.3.0-FE-A-000`。
- 类型：`FE`。
- 状态：进行中（原文同时包含已完成与未完成项）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.3.0 - UI 拖拽、订阅组语义与 dropdown 实时刷新 / sub/main: 支持 Provider 增量刷新。
- 原稳定 ID：`0.3.0-FE-A-000`, `0.3.0-FE-A-001`, `0.3.0-FE-A-002`, `0.3.0-FE-A-003`, `0.3.0-FE-A-004`, `0.3.0-FE-A-005`, `0.3.0-FE-A-006`, `0.3.0-UI-A-008`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 旧实现：所有 provider 并发 fetch，但只在**全部完成**后才把 `state` 整体替换为新值——
> 即使 dropdown 已经能"实时刷新"（v0.3.0-UI-A-004），用户看到的也只是"白屏 → 一次完整数据出现"。
> 新实现：探测到安装后立刻注入 `.loading` placeholder，provider 完成一个就 apply 一个、
> publish 一次 `state`，UI 立即响应。菜单栏 bar 也按完成顺序逐个"动态增长"。

- [x] [0.3.0-FE-A-000] `ProviderAvailability` 新增 `.loading` 枚举值 + `ProviderSnapshot.loading(kind:)` 工厂：占位 snapshot，quotas 为空、tier/price 为 nil、`isStale = false`；UI 渲染为骨架 #P1 — `QuotaModels.swift`
- [x] [0.3.0-FE-A-001] `RefreshCoordinator.runRefreshCycle` 重写为 streaming：探测安装 → 立即按用户偏好顺序 seed `.loading` placeholders → 用 `withTaskGroup` 并发跑每个 provider → 每个 provider 完成（含 fallback）立即调用 `applyProviderResult` 在原位置替换 placeholder → 全部完成后计算最终 `refreshState` #P1 — `RefreshCoordinator.swift:runRefreshCycle`
- [x] [0.3.0-FE-A-002] `state.lastUpdated` 在每个 provider 完成时推进（`max(prev, fetchedAt)`），让顶部"上次更新 HH:mm"逐 provider 前进，用户看到"数据正在流入" #P1 — `RefreshCoordinator.applyProviderResult`
- [x] [0.3.0-FE-A-003] `MenuView.PlanSection` 加 `case .loading: QuotaSkeleton()`：loading snapshot 直接走骨架分支；`ReadyStateView` 把 `isLoading` 改为派生自 `snapshot.availability == .loading`，per-snapshot 独立判断 #P1 — `MenuView.swift`
- [x] [0.3.0-FE-A-004] `StatusBarController.drawableSnapshots` / `remainingFraction` / `makeBarsImage` 处理 `.loading`：bar 高度 50%、alpha 0.4（dimmed），区别于 needsConfiguration（alpha 1.0 50%）；tooltip 在 loading 时显示「刷新中」而不是 50% #P1 — `StatusBarController.swift`
- [x] [0.3.0-FE-A-005] `pickBestSnapshot` 和 `FetchPipeline.merge` 的 availability 优先级加上 `.loading`（priority 2，介于 needsConfiguration=3 和 notInstalled=1 之间），避免 exhaustiveness warning 影响新 case #P1
- [x] [0.3.0-FE-A-006] 拖拽订阅组后，菜单栏 bar 与当前可见状态灯立即按新的第一订阅组 worst quota 刷新；菜单打开期间 preferences 变化也触发 SwiftUI 重算 #P1
- [ ] [0.3.0-UI-A-008] 多订阅组 provider 的每个子组状态灯显示该子组自身 worst quota #cut 用户明确不需要每个子组独立状态灯，改由 provider header 唯一灯显示第一组 worst quota

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260625104200-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260625104200-utcp8-mavis.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 1. 用户反馈的核心问题

旧实现流程：
1. 探测所有安装的 provider
2. 用 `withTaskGroup` 并发跑所有 pipeline
3. **等所有完成** → `await for ... in group` 退出循环
4. 一次性把全部结果合并后赋给 `state`（`@Published`）
5. SwiftUI 在 `@ObservedObject` 绑定下响应 state 变化（v0.3.0-UI-A-004 已实现）

结果：**虽然 SwiftUI 能响应 state 变化，但 state 本身只在所有 pipeline 都完成时才更新一次**。用户看到的体验是"白屏 → 一瞬间全部数据出现"，中间没有任何 provider 完成时的中间态。即使不关 dropdown，新数据也是在所有 provider 都完成之后才一次性出现，跟"白屏 → 一次性出现"没区别。

而且菜单栏 bar 也只在所有快照替换完成时才一次性重画，没有"逐步增加"的视觉。

#### 5. 验证

- `cd quota-bar && swift build`：通过 ✅
- 仅有一个预先存在的 warning（`MiniMaxConfigProvider.swift:346` 未使用变量 `prefix`），与本次修改无关。
- 旧的 ProviderFetchStrategy 和 RefreshCoordinator 里的 priority closure 加上 `.loading` 后编译通过。

#### 6. 用户手验清单（运行时验证）

跑 `cd quota-bar && swift run` 后：

1. **首启动 streaming**：
   - 启动瞬间 dropdown（如果打开）应看到所有 active provider 的骨架行，菜单栏看到 dimmed 50% bar 占位。
   - 1~3 秒内骨架逐个被真实数据替换，菜单栏 bar 从 dimmed 跳变为实际高度。
2. **手动刷新（立即刷新）**：
   - 点菜单「立即刷新」→ dropdown 立刻变骨架 → 逐个回填真实数据，菜单栏 bar 短暂全 dimmed → 逐个变亮。
   - **不关 dropdown** 也能看到完整 streaming 过程。
3. **多 provider 并发完成顺序**：
   - Antigravity / Codex / Kimi / MiniMax 启动时间差异大（IDE 探测快、Cookie 读取中、CLI 调用慢），观察到完成顺序随机 → 真实数据按完成顺序逐个出现。
4. **菜单栏动态增长**：
   - 启动瞬间菜单栏有 N 个 dimmed 50% bar（N = active kinds 数）→ 逐个变全亮、bar 高度按真实 remainingFraction 调整。
   - 不要 spinner（注释里强调过"刷新中不切换图标"）。
5. **首启动 dropdown 实时刷新**：
   - 打开 dropdown 不关 → 等自动刷新（5min）或点"立即刷新" → dropdown 内部原地刷新（已有 v0.3.0-UI-A-004 保证）。
6. **可访问 Console.app** 看 `QuotaBar:` 开头的 NSLog：每个 provider 完成会打 `✅ <kind> done` log。

#### 7. 后续可能改进（未做）

- **保留旧数据 re-refresh**：在 `ProviderSnapshot` 加 `isRefreshingNow: Bool` 字段，让重刷新期间保留旧数据 + 显示骨架覆盖层 / spinner。当前是骨架完全替换，flicker 短暂可接受。
- **per-provider 进度**：如果某个 provider 特别慢（>2s），可以在 UI 显示「Codex 还在刷新... 已等 3s」之类提示。当前没有。
- **retry backoff**：失败的 provider 在下一次自动刷新之前不重试（每次都重新走 pipeline）。当前行为不变。

#### 完成工作

- 数据层：`.loading` availability + `ProviderSnapshot.loading(kind:)` 工厂。
- 协调器：`runRefreshCycle` 重写为 streaming，per-provider 增量 publish state。
- 协调器：`applyProviderResult` 新方法，failure fallback 复用原逻辑。
- dropdown：`.loading` case 走骨架，`ReadyStateView` 派生 per-snapshot isLoading。
- 菜单栏：loading snapshot 画 dimmed 50% bar，tooltip 显示「刷新中」。
- pipeline priority：`.loading` 加进 exhaustive switch。
- 文档：REQUIREMENTS.md v0.3.0-FE-A 子区块新增 6 条需求。

#### 更新的需求 ID

新增：

- `[0.3.0-FE-A-000]` `ProviderAvailability.loading` + `ProviderSnapshot.loading(kind:)` 工厂。
- `[0.3.0-FE-A-001]` `runRefreshCycle` 重写为 streaming：探测 → seed placeholder → per-provider apply。
- `[0.3.0-FE-A-002]` `state.lastUpdated` 每次 provider 完成都推进。
- `[0.3.0-FE-A-003]` `MenuView.PlanSection` 加 `.loading` case；`ReadyStateView` per-snapshot `isLoading` 派生。
- `[0.3.0-FE-A-004]` `StatusBarController` 处理 `.loading`：dimmed 50% bar + tooltip「刷新中」。
- `[0.3.0-FE-A-005]` `pickBestSnapshot` / `FetchPipeline.merge` 优先级 closure 加 `.loading` case。

#### 验证方式

- `cd quota-bar && swift build`：通过 ✅
- 用户手验清单见上文「6. 用户手验清单」。

#### 备注

- **隐藏 / 重刷新 flicker**：当前重刷新瞬间所有 snapshot 会从真实数据 → 骨架 → 真实数据（依次回填）。如果用户觉得这个 flicker 不舒服，再加 `isRefreshingNow` 字段保留旧数据。本轮先按用户原话「先显示刷新中，等获取到再显示具体的值」实现。
- **`primarySubscriptionGroupWorstQuota` 不变**：streaming 只改 coordinator 发布时机，不改 quota 取值逻辑。
- **fetchFailed 的隐藏时机**：applyProviderResult 里把 fetchFailed snapshot 从 state.snapshots 移除，但仅当 replaceAt 成功（state 里确实有 placeholder）。如果 placeholder 已被某种异常路径移除，applyProviderResult 会 fallback 走 `if let index = ... else if keepAfterApply`，不会重复插入。
- **state.lastUpdated 在 hide()/clearHidden() 时的语义**：hide() 现在直接清空 state.snapshots 不会动 lastUpdated；如果用户 hide 掉所有 provider，lastUpdated 仍保留上一次刷新时间。这是合理的——「我最后一次成功刷新是什么时候」与「当前可见几个 provider」是两件事。
- **v0.3.0-UI-A-004 是 streaming 的前提**：没有 @ObservedObject 绑定 coordinator，per-provider publish 不会触发 UI 更新。当前这套已就位，所以 streaming 直接受益。

### 20260702151504-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260702151504-utcp8-gpt5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 对比一下我给你的三个 reference，我们现在已经吸取他们的最佳实践了吗？
> 另外不需要所谓的其他 provider，如果你要做其他 provider，就明确具体哪个 provider
> 我们现在还应该增加的应该是 GLM

#### 完成工作

- `REQUIREMENTS.md` 范围修正：移除 v0.9.0 能力矩阵里的泛化 provider 列表，明确 GLM/Z Code 进入矩阵范围。

#### 更新的需求 ID

- `0.9.0-ARCH-B-005`

#### 验证方式

- 文档变更，无构建验证。

#### 备注

- 未修改 Swift 实现代码。

### 20260702151121-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260702151121-utcp8-gpt5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 你这里链路写的有些混乱，我觉得应该分成3层：
> 1. provider获取
> 1.1. app bundle
> 1.2. 配置文件
> 1.3. cli
> 1.4. api
> 2. 额度获取
> 2.1. 配置文件
> 2.2. cli指令
> 2.3. api指令
> 2.4. rpc是什么？
> 2.x. 其他还有什么手段？通过 CLI 或者 API 直接发起自然语言问询，尝试让 AI 自己返回这个结果，有可能吗？浏览器在这里要怎么处理？
> 3. 过期日获取
> 3.1. 2.1. 配置文件
> 3.2. cli指令
> 3.3. api指令
> 3.x. 其他还有什么手段？通过 CLI 或者 API 直接发起自然语言问询，尝试让 AI 自己返回这个结果，有可能吗？浏览器在这里要怎么处理？
>
> 每次刷新时，执行逻辑应该是：
> 1. 先检查一遍所有的 provider；对于已有的 provider，应该用最近一次检查到它的手段进行复查，确保它还在；如果还在，跳过其余检查步骤；等所有已知的 provider 检查完了，按顺序把第一步跑一遍，检查新的，或者以已知手段没检查到的、老的 provider
> 2. 检查所有 provider 的额度，优先按照每个 provider 上次检查成功的额度检查手法检查。如果检查到了就完成；如果没检查到，按顺序全部都重新跑一遍额度获取手段
> 3. 检查过期日和额度一样，只不过具体检查的指令和位置可能不同，但逻辑也是一样的。先按上次成功的手法检查老的，检查不到就全部都跑一遍。
>
> 你现在应该先完善我列出的第一大段里所有的手法，然后结合第二大段，告诉我这个逻辑思路是否正确
>
> 然后你还应该列出3张表，每一张的纵轴分别是：
> 1. 第一步的可行方案
> 2. 第二步的可行方案
> 3. 第三步的可行方案
> 横轴是不同的 provider，然后单元格内容应该是针对这个 provider 的特殊处理或者检查方式。比如 Web 的话应该是对应的域名，CUI 的话应该是对应的指令

#### 完成工作

- 更新 `REQUIREMENTS.md`：
  - `0.9.0-ARCH-B-000` 至 `0.9.0-ARCH-B-008` 改为三层获取链路、来源索引、刷新逻辑、CLI/RPC、Browser、订阅状态归一化相关要求。
- 准备在回复中交付三层手法、刷新逻辑判断和三张 provider 矩阵。

#### 更新的需求 ID

- `0.9.0-ARCH-B-000`
- `0.9.0-ARCH-B-001`
- `0.9.0-ARCH-B-002`
- `0.9.0-ARCH-B-003`
- `0.9.0-ARCH-B-004`
- `0.9.0-ARCH-B-005`
- `0.9.0-ARCH-B-006`
- `0.9.0-ARCH-B-007`
- `0.9.0-ARCH-B-008`

#### 验证方式

- 文档变更，无构建验证。
- 使用 `rg` / `sed` 检查现有 provider 发现、endpoint、Codex/Kimi/MiniMax 等实现细节。

#### 备注

- 未修改 Swift 实现代码。
- 工作区仍有未跟踪 agent-log 文件，未执行 git add/commit。

### 20260707-114834-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260707-114834-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 微调一下日志格式：层级（比如provider）｜方案（比如配置）｜结果（成功/失败）｜日志内容，否则现在有点难读
>
> 然后开始制作preferences里的更新功能，我现在没有apple开发者签名，所以你应该要用requirements里记录的workaround
>
> 另外，截图里的功能我不开现在也能获取到claude code额度了，还需要吗？
>
> 然后dropdown里要统一额度条的小标题：如果是kimi这种区分code, work、minimax这种区分general video的情况，提供名称；如果是codex这种其实只有2个时间维度的情况，就不显示名称，claude我理解没错的话应该是codex的情况

#### 完成工作

- `ProviderCheckLog.swift`：新增 `Outcome` 枚举，`record` 签名改为 `outcome:` + `detail:`，行格式改为管道分隔。
- `InstallDetectorProvider.swift`：11 处调用点改用新签名。
- `ProviderFetchStrategy.swift`：`logSourceOrdering`/`logAttempt` 改用新签名。
- `SubscriptionExpirySources.swift`：10 处调用点改用新签名（脚本化替换 8 处 + 手动改 2 处特殊分支）。
- `DashboardEndpoints.swift`：`ClaudeUsageWindowParser` 的 `five_hour`/`seven_day` title 改为空字符串。
- `ClaudeStatusLineUsageProvider.swift`：同样的 title 改动。
- 测试：`ProviderCheckLogTests.swift` 全面更新 + 新增 `.skipped` 测试；`ClaudeStatusLineUsageProviderTests.swift`/`ClaudeDashboardParserTests.swift`/`ClaudeOAuthUsageProviderTests.swift` 里靠 title 区分窗口的断言改用 `periodSeconds`。
- 新包：`macos/build/20260707-114720-main/Quota Bar.app`（`build/latest` 已指向）。

#### 更新的需求 ID

- 新增并完成：`0.10.0-ARCH-I-000`（日志格式二次调整）、`0.10.0-BUG-A-008`（Claude 额度条标题统一）、`0.10.0-DOC-A-004`（更新功能现状确认，非新建）。

#### 验证方式

- `swift build`：无警告无错误。
- `swift test`：180 tests in 42 suites 全部通过。
- `./scripts/build-app.sh`：产包成功。
- 更新功能这项没有做新的功能验证——因为没有新增任何代码，只是读代码确认现状（backend 状态机、UI 绑定、release workflow 产出 dmg 资产、仓库地址匹配）。
- 未做真实 GUI 交互验证（比如真的点一次"检查更新"看是否弹出正确的更新提示）。

#### 备注

- 未提交 git commit。
- 这轮"更新功能"这一项是本次会话第一次遇到"用户以为要新建、实际已经建好了"的情况——直接如实告知比闷头重新实现一遍更负责任，也避免了在已经完整、测试过的状态机上做不必要的改动。
- statusLine 功能去留的问题特意没有替用户做决定，只给了利弊分析——这是一个纯粹的产品/体验取舍，不是技术正确性问题，应该留给用户自己判断。

### 20260808-224640-utcp8-taobe-deepseek-v4-flash.md — 历史证据迁移

来源：`agent-log/20260808-224640-utcp8-taobe-deepseek-v4-flash.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 检查并确保所有其他 provider 的类似问题都解决；然后提交

#### 完成工作

- `macos/Sources/QuotaBar/ProviderFetchStrategy.swift`：`mergeLayers` 对 `.subscriptionExpired`/`.notSubscribed` addition 返回 marker 合并结果（availability 用 addition、quotas 清空、tier/price/expiresAt 保留 base 值）。
- `macos/Sources/QuotaBar/OpenCodeWorkspaceProvider.swift`：Go 推广页（无订阅）改返回 `.notSubscribed` marker。
- `macos/Sources/QuotaBar/DashboardEndpoints.swift`：`KimiSubscriptionParser.indicatesNoActivePlan(data:now:)`（`subscribed == false` 优先，`nextBillingTime` 已过兜底）；`parseDate` 改 static。
- `macos/Sources/QuotaBar/KimiDesktopTokenProvider.swift`：GetSubscription 响应命中信号 → 返回 `.notSubscribed` marker。
- `macos/Sources/QuotaBar/BrowserCookieProvider.swift`：Kimi webview 路径同一检查。
- 测试：`FetchPipelineLayeredMergeTests`（marker 传播 ×2 + 管线级 ×1 + stub 改造）、`KimiSubscriptionParserBalancesTests`（判定 ×4）、`KimiDesktopTokenProviderTests`（marker ×1）。
- `REQUIREMENTS.md`：`0.10.0-DATA-B-006` 登记完成（审计结论 + 三处修复 + Antigravity 后续登记）。
- 提交 `git commit`（工作区全部改动，含上一任务）。

#### 更新的需求 ID

- [x] `0.10.0-DATA-B-006`（新增：其余 provider 同类问题审计 + mergeLayers marker 传播 + opencode/Kimi 修复）
- 上一任务的 `0.10.0-DATA-B-005` 随提交一并合入

#### 验证方式

- `cd macos && swift test`：273 条全过（上一任务 265 + 本任务新增 8）。
- 行为推演：Claude「CLI 已登录 + 订阅过期」→ cli tier-only 基底 + webview marker → mergeLayers 覆盖为 notSubscribed（保留 Pro/价格）；opencode 无订阅 → auth tier-only + webview marker → notSubscribed；Kimi 过期 → desktop/webview 返回 marker 短路；Kimi 有效（用户当前状态）→ `subscribed: true` → 不受影响。

#### 备注

- Antigravity 过期识别维持现状：`GetUserStatus.planStatus.planInfo` 只确认 planName 字段，无真实过期响应样本可验证判定边界，登记为 `0.10.0-DATA-B-001`/`-006` 的后续工作（README 矩阵里对应格本就是「待验证」）。
- Kimi 的 `status` 字符串字段（`SUBSCRIPTION_STATUS_ACTIVE`）未用作判定——未知取值集合，布尔 + 日期两个信号已足够；未来若发现 `subscribed` 对试用账号语义不同再回来修正。
- 提交信息：`fix: 统一订阅过期识别——mergeLayers 传播 notSubscribed marker + opencode/Kimi 补漏`（实际以 `git log` 为准）。

### 20260707-103750-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260707-103750-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 纠正你的逻辑，我们正确的顺序应该是：
> 每个provider的每个层，如果有缓存，优先检查缓存；如果缓存没有返回结果，按顺序全都跑一遍（不是默认就重跑）
>
> dropdown还有一个一致性问题：所有没获取到额度的provider应该都提供叉图标按钮，现在只有zcode有，叉了以后dropdown里隐藏，但刷新还是正常刷新，等效于在preferences里关闭（确保能同步状态且preferences里的provider按钮也是同样的效果和逻辑）

#### 完成工作

- `ProviderFetchStrategy.swift`：新增 `effectiveOrder(for:)`/`cachedFirstStrategy(for:)`，替换上一轮"完全不看缓存"的实现；`logSourceOrdering` 措辞相应更新。
- `RefreshCoordinator.swift`：删除 `hiddenKinds`/`clearHidden()`；`hide(kind:)` 改为持久化调用；新增 `applyEnabledFilterChange()`；`activeProviders` 过滤改读 `PreferencesStore.isEnabled`。
- `MenuView.swift`：`PlanHeader` 新增 `canHide` 计算属性，`HideButton` 从嵌在 `.needsConfiguration` 分支里移到始终可能渲染的位置（按 `canHide` 决定）；顺带把只剩一个 `default` 分支的 `switch` 简化成 `if`。
- 测试：`ProviderFetchStrategyTests.swift` 新增两条测试（缓存一致时优先尝试、缓存失败后完整 fallback）+ 新增 `ThrowingStubStrategy`。
- 新包：`macos/build/20260707-103743-main/Quota Bar.app`（`build/latest` 已指向）。

#### 更新的需求 ID

- 新增并完成：`0.10.0-BUG-A-004`（缓存优先级语义纠正）、`0.10.0-UI-B-004`（隐藏按钮可见范围扩大）、`0.10.0-ARCH-F-000`（hiddenKinds → PreferencesStore 统一）、`0.10.0-ARCH-F-001`（`applyEnabledFilterChange` 即时同步）
- 更新：`0.10.0-BUG-A-002` 描述补充说明它是被后续纠正的中间态

#### 验证方式

- `swift build`：无警告无错误。
- `swift test`：178 tests in 41 suites 全部通过，包括修复重新加回的既有测试 `quotaOnlySourceCannotShadowFullSource` 和两条新增的缓存优先级回归测试。
- `./scripts/build-app.sh`：产包成功。
- **未覆盖的部分**：`RefreshCoordinator`/`PreferencesStore` 的隐藏-启用同步逻辑（`applyEnabledFilterChange`）没有自动化测试——`PreferencesStore` 是硬编码单例（`init()` 没有可注入的测试目录），`RefreshCoordinator` 也没有现成的测试夹具支持独立实例化 + mock provider，搭这套测试基础设施超出本次修复的范围；这部分只做了代码走读验证，如实告知这是已知的验证缺口。也没有做真实 GUI 交互验证。

#### 备注

- 未提交 git commit。
- 这是同一个"来源优先级排序"逻辑在两次会话里被连续纠正三次（原始 bug → 中间态"完全不看缓存" → 现在这版"缓存优先、失败才完整 fallback"）——每次纠正都对应一条新增的回归测试，现在这块逻辑的测试覆盖比最初写的时候扎实得多。
- 发现 `PreferencesStore.isEnabled`/`setEnabled` 长期是死代码（没有调用方）这件事，是本次排查隐藏按钮问题时的副产品，不是用户直接指出的——如实记录这是我在解决报告的问题时顺带发现并修复的一个更深层的架构缺口。
