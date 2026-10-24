# 拖拽排序Provider与订阅组并联动状态

- ID：`0.3.0-UI-A-000`。
- 类型：`UI`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.3.0 - UI 拖拽、订阅组语义与 dropdown 实时刷新 / sub/main: 支持订阅组拖拽排序与状态联动。
- 原稳定 ID：`0.3.0-UI-A-000`, `0.3.0-UI-A-001`, `0.3.0-UI-A-002`, `0.3.0-UI-A-003`, `0.3.0-UI-A-004`, `0.3.0-UI-A-005`, `0.3.0-UI-A-006`, `0.3.0-UI-A-007`, `0.3.0-UI-A-009`, `0.3.0-UI-A-010`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.3.0-UI-A-003`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.3.0-UI-A-000`、`0.3.0-UI-A-001`、`0.3.0-UI-A-002`、`0.3.0-UI-A-003`、`0.3.0-UI-A-005`、`0.3.0-UI-A-006`、`0.3.0-UI-A-007`、`0.3.0-UI-A-009`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.3.0-UI-A-003-UI-subscription-sorting-state-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：sub/main: 支持订阅组拖拽排序与状态联动。
- 同源任务：[在菜单打开期间实时更新Dropdown内容](issue_%E5%9C%A8%E8%8F%9C%E5%8D%95%E6%89%93%E5%BC%80%E6%9C%9F%E9%97%B4%E5%AE%9E%E6%97%B6%E6%9B%B4%E6%96%B0Dropdown%E5%86%85%E5%AE%B9.md)、[在计划头部显示订阅最后有效日期](issue_%E5%9C%A8%E8%AE%A1%E5%88%92%E5%A4%B4%E9%83%A8%E6%98%BE%E7%A4%BA%E8%AE%A2%E9%98%85%E6%9C%80%E5%90%8E%E6%9C%89%E6%95%88%E6%97%A5%E6%9C%9F.md)。

## 当前需求与范围

- [x] [0.3.0-UI-A-000] 用户可上下拖拽 Provider 和多订阅组 Provider 下的订阅组，顺序实时生效并持久化；单条 quota row 不单独拖拽 #P1
- [x] [0.3.0-UI-A-001] 拖拽后 Provider 左侧状态灯颜色取「按订阅组排序后第一个订阅组的最差 quota」；多订阅组 provider 拖订阅组、单订阅组 provider 拖动不影响取值 #P1 — `MenuView.statusColor(itemOrder: subscriptionGroupOrder)`
- [x] [0.3.0-UI-A-002] 拖拽后顶部菜单栏 bar 高度取「按订阅组排序后第一个订阅组的最差 quota」；bar 取值与 quota 拖拽顺序解耦，只跟订阅组顺序绑定 #P1 — `StatusBarController.statusBarQuota(for:)`
- [x] [0.3.0-UI-A-003] Provider 区块本身支持上下拖拽排序，顺序实时生效并持久化 #P1
- [x] [0.3.0-UI-A-005] 多订阅组 provider UI 拆分：单订阅组 provider（Codex / Kimi）保持原 UI（planHeader 带状态灯 + quota rows 平铺）；多订阅组 provider（MiniMax / Antigravity）渲染多个 `SubscriptionGroupBlock`，block 只作为拖拽边界，不额外显示子组 header 或独立状态灯 #P1
- [x] [0.3.0-UI-A-006] 拖拽两层作用域：provider 整体 / subscription group（仅同 provider 内，payload = `"<kind>:<groupKey>"`）；quota row 不单独拖拽，组内多条额度作为整组移动 #P1
- [x] [0.3.0-UI-A-007] 恢复多订阅组 UI 对齐关系：provider header 保留唯一状态灯；订阅组标题和组内 quota 行沿用单订阅组内容缩进，不因额外状态灯产生错位 #P1
- [x] [0.3.0-UI-A-009] 修正多订阅组 dropdown 视觉回归：移除 “Gemini/Other/General/Video” 这类独立子组标签行，恢复 quota row 与单组 provider 相同的左缩进；整组拖拽仍绑定在不可见 `SubscriptionGroupBlock` 上 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260624163000-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260624163000-utcp8-gpt5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 1. 问题诊断

把用户的 4 条反馈对到当前实现上：

- **#1 拖拽有效**：`QuotaItemDropDelegate.performDrop` 和 `ProviderDropDelegate.performDrop` 正确写入
  `quotaItemOrder` / `providerOrder` 并发出 `quotaPreferencesDidChange` 通知。
- **#2 拖拽不响应**：双 bug。
  - `StatusBarController` 已监听 `quotaPreferencesDidChange` 调 `refreshStatusItemAppearance()`，所以菜单栏 bar 路径理论上 OK。
  - 但 **dropdown 的 SwiftUI tree 没有响应**：`MenuView` 是 `NSHostingView` 包装，每次靠 `rebuildMenu()` 重建。
    `rebuildMenu()` 只在 `coordinator.$state` 变化时触发，preferences 变化不会触发，所以 dropdown 内 `PlanHeader` 的
    `statusColor` 永远是拖拽前的值。
- **#4 取最不健康**：当前 `statusColor(itemOrder:)` 内部用 `primaryQuota(itemOrder:)` 取排序后第一个，
  与"任一归零则全废"的 provider 语义不一致。`StatusBarController.statusBarQuota(for:)` 同样取 `primaryQuota`。
- **#3 Kimi 1 组 3 条**：数据层面要看走哪条路径。
  - Web 路径（`BrowserCookieProvider` + `KimiSubscriptionStatParser`）已经能解 3 条：Work 1月 + Code 1周 + Code 5h。
  - CLI 路径（`KimiAuthProvider`）URL 写死 `https://api.kimi.com/coding/v1/usages`，只能拿到 Code 2 条，没有 Work。
  - UI 层面 `QuotaRows.orderedQuotas` 已经是平铺不分组的，"1 组 3 条"视觉上已经满足。

#### 3. 验证

- `cd quota-bar && swift build`：通过 ✅
- 唯一 warning（`MiniMaxConfigProvider.swift:346` 未使用变量）是预先存在的，与本次修改无关。

#### 完成工作

- 实现「状态灯 / 菜单栏 bar 用整组最不健康 quota」的规则（worstQuota + statusColor / statusBarQuota 切换）。
- 修复 dropdown 内状态灯不响应拖拽排序的 bug（preferences 变化触发 menu rebuild）。
- 行为变化：
  - 之前：bar/status 取排序后第一个 quota 的 remainingFraction。
  - 之后：bar/status 取整组 remainingFraction 最小值；拖拽只影响 dropdown 内 3 条进度条的展示顺序。

#### 更新的需求 ID

- `[0.3.0-UI-A-001]` 拖拽后 Provider 左侧状态灯颜色取最上方额度对象的剩余比例 → **修订**为「取整组最不健康（min remaining）」。
- `[0.3.0-UI-A-002]` 拖拽后顶部菜单栏 bar 高度取最上方额度对象的剩余比例 → **修订**为「取整组最不健康（min remaining）」。
- `[0.2.0-UI-A-007]` 调整 dropdown 额度进度条颜色语义：>30% 蓝色、0~30% 橙色 → 沿用，bar/灯颜色规则不变。

#### 验证方式

- `cd quota-bar && swift build`：通过 ✅
- 运行后验证：
  1. 打开 dropdown，拖动 Kimi 区块内的 Work 1月 到最上面，关闭后再打开，状态灯应反映整组最不健康（min）而非第一个。
  2. 菜单栏 bar 高度应反映 Kimi 整组最不健康的 quota（与拖拽顺序无关）。
  3. 拖拽 Provider 区块顺序（Codex/MiniMax/Kimi 互调），关闭 dropdown 后再打开，顺序应已持久化。

#### 备注

- **Kimi 1 组 3 条的数据源问题未在此任务处理**。当前 Kimi pipeline 顺序（`Strategies.swift:139-152`）：
  1. `kimi-edge` (BrowserCookieProvider) → 3 条（Work 1月 + Code 1周 + Code 5h）✅
  2. `kimi-cookie` (BrowserCookieProvider) → 3 条
  3. `kimi-auth` (KimiAuthProvider, CLI) → 2 条（缺 Work）
  4. `kimi-keychain`
  - 若用户浏览器已登录 kimi.com 并有 Full Disk Access，Kimi 走 Web 路径能拉到 3 条。
  - 若 Cookie 拿不到，fallback 到 CLI 路径就只有 2 条。
  - 已在对话中与用户确认 Kimi 当前实际显示条数，**待用户反馈后决定是否扩展 KimiAuthProvider 拉 work scope**。
- 旧的 `primaryQuota(itemOrder:)` 方法保留，未被调用方使用，保留以备未来按"取第一个"展示的子服务（如 MultiProvider 多账号）场景。
- `worstQuota` 与 `primaryQuota` 共存：前者是组语义（任一归零则全废），后者是子服务语义（只看第一个），未来按 provider 区分时按需调用。

### 20260625135810-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260625135810-utcp8-mavis.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 在每一个大的供应商的价格左边，加上同样是灰色字的更新日期，也就是什么时候过期（比如2026/6/25代表6/25是最后的有效天，26才用不了）；在一个新的 worktree 实现这个功能

#### 完成工作

- `ProviderSnapshot` 新增 `subscriptionExpiresAt: Date?`（默认从 quota resetsAt 推断）。
- `PlanHeader` 在价格左侧展示灰色 11pt 日期 `2026/6/25`（无前导零、`en_US_POSIX` 格式、`Asia/Shanghai` 解读）。
- 需求 `0.3.0-UI-A-010` 完成。
- DESIGN.md / REQUIREMENTS.md 同步。

#### 更新的需求 ID

- 新增并完成：`[0.3.0-UI-A-010]`

#### 验证方式

- `cd quota-bar && swift build`：通过 ✅
  - 仍有 1 个 pre-existing warning（`MiniMaxConfigProvider.swift:346` 的 `prefix` 未使用），与本次修改无关。
- 没有运行 `swift run` / `build-app.sh`：本轮只做 UI 静态层改动，不涉及运行行为；
  下次打包或手验时 dropdown 应能直接看到「价格左边」多了灰色日期。

#### 备注

- **未提交**：保持 worktree 工作区原样，方便用户先看 diff 再决定是否合并到 main。
- **不在 main 留下改动**：所有改动都落在 worktree（`.worktrees/price-update-date/`），main worktree 的 dirty 状态（v0.3.0 收尾）原封未动。
- **默认推断的语义**：`max(quota.resetsAt)` 是「当前显示的剩余额度过期最晚的那条」，与用户描述的「什么时候过期」在直觉上吻合。
  - Codex 5h + 周额度 → 取周额度的 resetsAt（≈ 7 天后）。
  - Kimi Code + Work → 取 Work 月额度的 resetsAt。
  - MiniMax / Antigravity 多订阅组：每个订阅组各自的 `max(resetsAt)` 仍按 subscriptionGroup 隔离。
- **后续可扩展点**：
  - 某 provider parser 如果能从 API 拿到更明确的「订阅账单日 / 服务到期日」（不是 quota reset），可以在 `fetchSnapshot` 末尾显式传 `subscriptionExpiresAt:` 覆盖默认推断。
  - 当前没有「数据有效性」独立的字段；如果将来想做「数据陈旧提醒」（`isStale` 之外），可以再加 `dataStaleAfter: Date?` 字段。
- **没引入新依赖**、没动 ABI、没改公共协议签名（仅在 `ProviderSnapshot` 内部加可选参数 + 默认值，对所有调用方向后兼容）。

### 20260624230928-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260624230928-utcp8-mavis.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 5. 验证

- `cd quota-bar && swift build`：通过 ✅
- 唯一 warning（`MiniMaxConfigProvider.swift:346` 未使用变量）是预先存在的，与本次修改无关。
- 另一个 warning（`EdgeCookieReader.swift:42` 未使用变量）也是预先存在的。
- 全量 grep 旧 API `primaryGroupWorstQuota` / `groupedQuotas` 无残留。
- 用户跑起来手验清单见 "验证方式" 章节。

#### 6. 数据点交叉验证

- Antigravity parser 主路径（groups[].displayName）：每个 group 1 个 window，subscriptionGroup = displayName。`displayName` 实际取值需要 IDE 启动后从 console log 确认；用户在 questionnaire 中描述是 "Gemini" + "Other"，所以 fallback 路径已固定对应这两个字符串（与主路径如果返回 "Gemini" / "Other" 字面值则对齐）。
- MiniMax CLI parser：subscriptionGroup = `modelName.lowercased()`。如果 `model_remains[].model_name` 在用户账号里是 "General" / "Video"，则 subscriptionGroup = "general" / "video"；如果 API 返回别的命名（如 "Pro"），订阅组 key 也会跟着变。
- Codex / Kimi 都是单订阅组，subscriptionGroup 直接写死 provider kind，行为稳定。

#### 完成工作

- **语义修正**：v0.3.0-UI-A 拖拽排序语义从"取最上方 quota"升级为"按订阅组排序，取第一个订阅组的最差 quota"。
- **数据层**：QuotaWindow.subscriptionGroup 字段 + 所有 parser 显式化 + ProviderSnapshot 新方法。
- **偏好层**：PreferencesStore.subscriptionGroupOrder 字段。
- **取值层**：bar 高度 / dropdown 状态灯改用 subscription group 维度排序取值。
- **UI 层**：
  - MenuView 改用 @ObservedObject，dropdown 实时刷新。
  - 多订阅组 provider UI 拆分为多个可独立拖拽的 sub-section。
  - 拖拽三层（provider / subscription group / quota row）作用域清晰，跨层拖拽静默忽略。
- **新 Provider 准备**：zcode 已确认安装位置和数据结构（`~/.zcode/v2/`），千问待用户确认实际安装路径。

#### 更新的需求 ID

- `[0.3.0-UI-A-000]` 用户可上下拖拽某个 Provider 下的具体额度对象 → 沿用，行为不变。
- `[0.3.0-UI-A-001]` 拖拽后 Provider 左侧状态灯颜色取最上方额度对象的剩余比例 → **修订**为「按订阅组排序，取第一个订阅组的最差 quota；多订阅组 provider 拖订阅组、单订阅组 provider 拖动不影响取值」。
- `[0.3.0-UI-A-002]` 拖拽后顶部菜单栏 bar 高度取最上方额度对象的剩余比例 → **修订**为「按订阅组排序，取第一个订阅组的最差 quota；与 quota 拖拽顺序解耦」。
- `[0.3.0-UI-A-003]` Provider 区块本身支持上下拖拽排序 → 沿用。

#### 新增的需求 ID（v0.3.0 内补充）

- `[0.3.0-DATA-A-000]` `QuotaWindow` 增加 `subscriptionGroup` 字段，语义为「独立计费的订阅组」，fallback 到 `providerKind.rawValue`。
- `[0.3.0-DATA-A-001]` 所有 parser 显式设 subscriptionGroup：Codex=`"codex"`、Kimi=`"kimi"`、MiniMax 按 `modelName.lowercased()`、Antigravity 按 `group.displayName`（fallback 路径固定 `"Gemini"` / `"Other"`）。
- `[0.3.0-DATA-A-002]` `PreferencesStore` 新增 `subscriptionGroupOrder[providerKind]` 持久化订阅组排序偏好。
- `[0.3.0-DATA-A-003]` `ProviderSnapshot` 新增 `subscriptionGroups(customOrder:)` 与 `primarySubscriptionGroupWorstQuota(itemOrder:)`。
- `[0.3.0-UI-A-004]` dropdown 实时刷新：`MenuView` 用 `@ObservedObject` 绑定 coordinator，菜单打开期间 SwiftUI 自动响应 state 变化，去掉 `rebuildMenu` 在 `isMenuOpen` 态下的 `needsRebuild` 缓冲。
- `[0.3.0-UI-A-005]` 多订阅组 provider UI 拆分：单订阅组保持原 UI；多订阅组渲染多个 `SubscriptionGroupBlock`，每个 block 带自己的订阅组 header + 状态灯 + quota rows，独立可拖。
- `[0.3.0-UI-A-006]` 拖拽三层作用域：provider 整体 / subscription group（仅同 provider 内）/ quota row（仅同 subscription group 内），跨作用域 drop 静默忽略。

#### 新增的需求 ID（v0.4.0 占位）

- `[0.4.0-DATA-A-000]` 智谱 BigModel Z Code (zcode) Provider 接入：bundle id `dev.zcode.app`、数据目录 `~/.zcode/v2/`、当前启用 plan `builtin:bigmodel-start-plan`（baseURL `https://zcode.z.ai/api/v1/zcode-plan/anthropic`），走 anthropic 兼容 API 拉额度。
- `[0.4.0-DATA-B-000]` 阿里通义千问桌面 App Provider 接入：等用户确认实际安装路径（`/Applications`、`~/Applications` 暂未发现 bundle）。

#### 验证方式

- `cd quota-bar && swift build`：通过 ✅
- 运行后验证（4 条手验 + 1 条新 Provider）：
  1. **单订阅组（Codex / Kimi）**：dropdown 显示 1 个 section，状态灯在 planHeader 上；拖 quota row 顺序变化**不影响** bar/灯（bar 仍取整组 worst）。
  2. **多订阅组（MiniMax / Antigravity，IDE 已启动场景）**：dropdown 显示 provider section + 多个 sub-section，每个 sub-section 带自己的状态灯；**拖动 sub-section 排序**应让 bar 高度 / 状态灯跟着变（取最前 sub-section 的 worst）。
  3. **dropdown 实时刷新**：打开 dropdown 不关 → 等自动刷新 / 点"立即刷新" → dropdown 内容应原地刷新，不需要关掉重开。
  4. **bar 高度变化**：观察菜单栏 bar 高度随 sub-section 排序变化（最容易看到的是 Antigravity 拖一个 group 到顶部，bar 跟着变）。
  5. **新 Provider**：zcode / 千问 Provider 等用户确认细节后单独开发。

#### 备注

- **Antigravity 实际 displayName 需验证**：用户描述 "Gemini" + "Other"，主路径 parser 按 `group.displayName` 设 subscriptionGroup，但 IDE 返回什么字面值需要 console log 确认。如果主路径实际返回 "Gemini Models" / "Claude Models"，sub-section header 会显示 "Gemini Models" / "Claude Models" 而不是 "Gemini" / "Other"，但语义仍正确（每个 group 一个订阅组）。
- **千问桌面 App 位置待确认**：已经搜了常见路径，未发现。可能的安装位置：DMG 挂载点、`/Applications/Utilities`、第三方目录，或实际未安装。建议用户执行 `ls /Applications | grep -iE "qwen|tongyi|通义"` 手动确认。
- **placeholder provider**：当前 `PlaceholderProviders` 不显式设 subscriptionGroup，依赖 fallback（`providerKind.rawValue`）。这是合理的——placeholder 的场景下多订阅组不会触发（每个 placeholder provider 只输出 1 组）。
- **拖拽三层冲突处理**：跨层 drop（如把 subscription group 拖到 quota row 区域）会被对应 DropDelegate 静默忽略——因为 payload 字符串解析失败。这样不会 crash，也不会误更新排序。
- **PreferencesStore 字段向后兼容**：新增的 `subscriptionGroupOrder` 字段在 Codable 解码时是 optional，旧配置自动获得 `[:]` 默认值，逻辑层 fallback 到 `subscriptionGroups(customOrder: [])` 的原始顺序（即按数据源的 quota 顺序）。

### 20260625121542-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260625121542-utcp8-gpt5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> Kimi Work 没有恢复，而且你刚刚改到一半，有一瞬间是恢复了的，只是最后打包的版本又没有，你也可以参考附件 2 的模型日志之前的版本
> 对齐也没有恢复
> - 参考一下附件 2 的这份模型日志之前版本的样式
> 整组拖动也做错了
> - 对于像 video 日额度、video 周额度这样的对象，它们是一个整组，不需要单独的那个 video 那一行的标签
>
> 现在只有整个模型的拖动排序功能（比如kimi和codex之间拖动排序）以及动态刷新功能是对的

补充 prompt：

> 关于 Kimi Work 检查之前版本的代码，我们之前是实现过的，你不用自己创新

#### 完成工作

- `MenuView.swift`
  - 去掉多订阅组 provider 的可见子组标签行。
  - 不再显示子组状态灯。
  - 组内多条 quota 仍由同一个 `SubscriptionGroupBlock` 包裹，拖动时作为整组移动。
  - 多组 quota rows 恢复与单组 provider 一致的左侧缩进。
- `KimiAuthProvider.swift`
  - 撤回 CLI OAuth 调 `GetSubscriptionStat` 的尝试，恢复旧职责：只作为 Code-only fallback。
- `BrowserCookieProvider.swift`
  - Kimi cookie 路径先拉 `GetSubscriptionStat`，确保 Work/Code 三条额度不被可选 tier/price 请求阻塞。
  - `GetSubscription` 改为可选短超时补充，失败不影响额度。
- `REQUIREMENTS.md`
  - 更新 `0.3.0-UI-A-005` 说明。
  - 新增并完成 `0.3.0-UI-A-009`。
  - 新增并完成 `0.3.0-DATA-A-005`。

#### 更新的需求 ID

- `[0.3.0-DATA-A-005]`
- `[0.3.0-UI-A-005]`
- `[0.3.0-UI-A-009]`

#### 验证方式

- `cd quota-bar && swift build`
  - 通过。
  - 仍有既有 warning：`MiniMaxConfigProvider.swift` 的 `prefix` 未使用、`EdgeCookieReader.swift` 的 `placeholders` 未使用。
- `cd quota-bar && ./scripts/build-app.sh`
  - 通过。
  - 生成：`quota-bar/build/20260625-121436/QuotaBar.app`
  - `quota-bar/build/latest/QuotaBar.app` 已指向最新版本。

#### 备注

- 未执行提交。
- 本轮没有回滚其它模型/用户造成的工作区改动。
- 若用户运行后 Kimi 仍只显示 Code，需要优先查看 Console 中 `QuotaBar: [kimi-cookie]` 日志，确认 Edge/Chrome cookie 路径是否成功读取到 `kimi-auth` 并请求 `GetSubscriptionStat`；不应再通过 CLI OAuth endpoint 创造 Work 数据。

### 20260624155839-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260624155839-utcp8-gpt5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 完成工作

- 实现额度对象（QuotaRow）级上下拖拽排序，顺序持久化到 `preferences.json` 的 `quotaItemOrder`。
- Provider 区块支持上下拖拽排序，顺序持久化到 `preferences.json` 的 `providerOrder`。
- Provider 左侧状态灯与顶部菜单栏 bar 高度均取用户排序后最上方额度对象的剩余比例。
- 修复 `BrowserCookieProvider.swift` 因 `Result.getError()` 导致的编译失败。

#### 更新的需求 ID

- `[0.3.0-UI-A-000]` 用户可上下拖拽某个 Provider 下的具体额度对象，顺序实时生效并持久化
- `[0.3.0-UI-A-001]` 拖拽后 Provider 左侧状态灯颜色取最上方额度对象的剩余比例
- `[0.3.0-UI-A-002]` 拖拽后顶部菜单栏 bar 高度取最上方额度对象的剩余比例
- `[0.3.0-UI-A-003]` Provider 区块本身支持上下拖拽排序，顺序实时生效并持久化

#### 验证方式

- `cd quota-bar && swift build` 成功。
- 运行后验证：下拉菜单中额度对象可拖拽、Provider 区块可拖拽、状态灯/菜单栏 bar 与最上方对象联动。

#### 备注

- 旧的 `quotaGroupOrder` 字段保留在 `QuotaPreferences` 中以保证向后兼容，但新代码不再写入该字段。
- Provider 排序变更通过监听 `NotificationCenter.quotaPreferencesDidChange` 立即反映在下拉菜单，无需等待下次刷新。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
