# 建立独立计费订阅组及排序语义

- ID：`0.3.0-DATA-A-000`。
- 类型：`DATA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `b550269a253e390d19ec221949fb30c44adf9e9e`；标题路径：任务清单 / Phase - v0.3.0 - UI 拖拽、订阅组语义与 dropdown 实时刷新 / DATA-A：订阅组（subscription group）语义。
- 原稳定 ID：`0.3.0-DATA-A-000`, `0.3.0-DATA-A-001`, `0.3.0-DATA-A-002`, `String`, `0.3.0-DATA-A-003`, `0.3.0-DATA-A-004`, `0.3.0-DATA-A-005`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.3.0-DATA-A-000`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.3.0-DATA-A-000`、`0.3.0-DATA-A-001`、`0.3.0-DATA-A-002`、`0.3.0-DATA-A-003`、`0.3.0-DATA-A-004`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.3.0-DATA-A-000-DATA-subscription-group-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：DATA-A：订阅组（subscription group）语义。
- 同源任务：[恢复KimiWork已验证的浏览器额度路径](issue_%E6%81%A2%E5%A4%8DKimiWork%E5%B7%B2%E9%AA%8C%E8%AF%81%E7%9A%84%E6%B5%8F%E8%A7%88%E5%99%A8%E9%A2%9D%E5%BA%A6%E8%B7%AF%E5%BE%84.md)。

## 当前需求与范围

- [x] [0.3.0-DATA-A-000] `QuotaWindow` 增加 `subscriptionGroup` 字段，语义为「独立计费的订阅组」；fallback 到 `providerKind.rawValue`（未显式设的 parser 视为整个 provider = 1 个订阅组）#P1 — `QuotaModels.swift:subscriptionGroup`
- [x] [0.3.0-DATA-A-001] 所有 parser 显式设 subscriptionGroup：Codex=`"codex"`、Kimi=`"kimi"`（含 web + CLI 两条路径）、MiniMax CLI 按 `modelName.lowercased()`、Antigravity 主路径按 `group.displayName` / fallback 路径固定 `"Gemini"` + `"Other"` #P1
- [x] [0.3.0-DATA-A-002] `PreferencesStore.QuotaPreferences` 新增 `subscriptionGroupOrder: [String: [String]]` 字段（key = `providerKind.rawValue`），Codable 向后兼容（旧配置自动获得 `[:]`）#P1
- [x] [0.3.0-DATA-A-003] `ProviderSnapshot` 新增 `subscriptionGroups(customOrder:)` 与 `primarySubscriptionGroupWorstQuota(itemOrder:)` 两个方法：前者按订阅组分组（组顺序继承用户排序），后者取排序后第一个订阅组的 worst quota #P1
- [x] [0.3.0-DATA-A-004] 修正 `subscriptionGroups(customOrder:)` 的排序语义：`customOrder` 必须按订阅组 key 排序而不是 quota stableKey；Kimi Work / Code 无论来源如何都强制归为 `kimi` 单订阅组 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
