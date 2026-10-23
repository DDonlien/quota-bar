# sub/main: 修正可用订阅计数语义

- ID：`0.4.0-UI-B-000`。
- 类型：`UI`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.4.0 - 新 Provider 接入（zcode / 千问 / 其他） / sub/main: 修正可用订阅计数语义。
- 原稳定 ID：`0.4.0-UI-B-000`, `0.4.0-UI-B-001`；不改写或重编号这些既有 ID。

## 当前需求与范围

> Bug 修复：顶部「可用订阅 N/M」之前只看 `availability == .available`，导致 Kimi 红灯（worst quota 已耗尽）时 N/M 仍显示 4/4，与状态灯颜色不一致。
> 修复后 N/M 与状态灯走同一逻辑：top group worst quota `remainingFraction > 0` 才计为可用，红灯不计。

- [x] [0.4.0-UI-B-000] `DashboardState.availableCount` 改为只统计 `.available` 且 top subscription group worst quota `remainingFraction > 0` 的 snapshot；与 `ProviderSnapshot.statusColor(itemOrder:)` 的红灯判定走完全相同的逻辑（避免出现"灯红但 N/M 不动"的割裂）#bugfix — `QuotaModels.swift:availableCount`
- [x] [0.4.0-UI-B-001] `DashboardState.availabilityText` 同步标记 `@MainActor`（因 `availableCount` 需要读 `PreferencesStore.shared`，后者是 MainActor 隔离）#bugfix — `QuotaModels.swift:availabilityText`

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260625134800-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260625134800-utcp8-mavis.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 1. 问题定位

**用户报告**：dropdown 顶部「可用订阅 4/4」与状态灯显示不一致——Kimi 已红灯（worst quota 耗尽），但数字仍是 4/4，应为 3/4。

**根因**：

`DashboardState.availableCount` 的旧实现只判断 `availability == .available`：

```swift
var availableCount: Int {
    snapshots.filter { $0.availability == .available }.count
}
```

而 `ProviderSnapshot.statusColor(itemOrder:)` 对 `.available` 还有更细的判定：

```swift
case .available:
    let worstFraction = primarySubscriptionGroupWorstQuota(itemOrder: itemOrder)?.remainingFraction ?? 1.0
    if worstFraction == 0 {
        return Color.red      // ← 这条路径没反映到 availableCount
    } else if worstFraction <= 0.3 {
        return Color.orange
    } else {
        return Color.green
    }
```

也就是说：**红灯 = `availability == .available` 但 worst quota 已归零**，而 `availableCount` 没看 `remainingFraction`，把红灯也计入了。

Kimi 是单订阅组，top group = 整组，worst == 0 → 红灯 → 应该 3/4。

#### 2. 修复范围控制

用户明确要求"不要修改任何其他已经实现的功能"。检查所有用到 `.availability == .available` 的地方：

| 位置 | 是否改 | 理由 |
|------|--------|------|
| `DashboardState.availableCount` | ✅ 改 | 这是 bug 所在 |
| `DashboardState.totalMonthlyCostText` | ❌ 不改 | 用户订阅了 Kimi，即使耗尽也要算月费 |
| `DashboardState.hasAnyAvailable` | ❌ 不改 | 用于 `isInitialLoading` 判定（loading vs ready），与红灯无关 |
| `StatusBarController.drawableSnapshots` | ❌ 不改 | 菜单栏 bar 画图逻辑独立，与计数无关 |
| `MenuView` 的 `availableCount` 显示 | ❌ 不改 | 通过 `state.availabilityText` 自动跟随 availableCount |
| `ProviderSnapshot.statusColor` | ❌ 不改 | 用户对当前灯色满意，只是不满 N/M |
| streaming refresh 行为 | ❌ 不改 | 与 bug 无关 |

#### 5. 验证

- `cd quota-bar && swift build`：通过 ✅
- 无新增 warning。
- 用户场景验证（用户已在手验）：
  - Kimi 红灯（worst quota 归零）→ `availableCount` 不计 → N/M 从 4/4 变成 3/4
  - 其他三个 provider 灯绿或橙 → 仍计为可用
  - 多订阅组 provider（如 Antigravity）：只看 top group——用户把健康组拖到顶部后，状态灯变绿 → 同时 N/M 计为可用；用户把耗尽组拖到顶部后，状态灯变红 → 同时 N/M 不计。逻辑一致。

#### 完成工作

- 修 `DashboardState.availableCount`：红灯（top group worst quota = 0）不计为可用。
- 修 `DashboardState.availabilityText`：加 `@MainActor` 注解。
- 同步更新 `REQUIREMENTS.md`：v0.4.0-UI-B 子区块新增 2 条 bugfix 需求。
- 用 `build-app.sh` 打包成 `.app` bundle。

#### 更新的需求 ID

新增：

- `[0.4.0-UI-B-000]` `DashboardState.availableCount` 改为只统计 `.available` 且 top subscription group worst quota `remainingFraction > 0` 的 snapshot；与 `statusColor(itemOrder:)` 红灯判定逻辑完全一致。
- `[0.4.0-UI-B-001]` `DashboardState.availabilityText` 同步标记 `@MainActor`（因 `availableCount` 需要读 MainActor 隔离的 `PreferencesStore.shared`）。

#### 验证方式

- `cd quota-bar && swift build`：通过 ✅
- 用户场景验证（用户已在手验）：Kimi 红灯 → N/M 从 4/4 变为 3/4。
- 回归验证：streaming refresh、状态灯、菜单栏 bar、cost 显示、拖拽排序均未变。

#### 备注

- **MainActor 隔离的连锁影响**：`availableCount` 是 `DashboardState`（Sendable struct）的计算属性，原本是非隔离。加 `@MainActor` 后，所有调用方必须在 MainActor 上调用——恰好所有调用方都是 SwiftUI View body（隐式 MainActor）或 `@MainActor` 的 `RefreshCoordinator`，没有破坏。
- **为什么不在 ProviderSnapshot 上加 `isEffectivelyAvailable` 共享属性**：会让 Sendable struct 暴露 MainActor 依赖的属性，污染类型边界。当前只有 `availableCount` 这一处使用，没必要共享。如果未来需要其他地方（比如某个 badge 或 status icon）也做相同判定，可以再抽出来并显式传 itemOrder。
- **为什么 `totalMonthlyCostText` 不一起改**：用户订阅了 Kimi，即使 quota 耗尽，下个月还是要交钱。cost 应该反映「订阅状态」而不是「当下可用性」。如果将来想区分（如 cost 显示但加个"已耗尽"标签），单独处理。
- **AGENTS.md 约束遵守**：
  - 没新建 Phase（[0.4.0-UI-B] 挂在已有 v0.4.0 下，不算新建）。
  - 没有改动无关文件（RefreshCoordinator / MenuView / StatusBarController 等都没动）。
  - 改动聚焦在用户报告的 bug 上，最小化（只改 `availableCount` + 连锁加 `@MainActor` 到 `availabilityText`）。
  - 提前读 AGENTS.md 确认打包命令（`./scripts/build-app.sh`），按项目约束执行。
