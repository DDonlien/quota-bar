# FE-A：刷新机制

- ID：`0.2.0-FE-A-003`。
- 类型：`FE`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`；标题路径：任务清单 / Phase - v0.2.0 - Quota Bar 核心功能 / FE-A：刷新机制。
- 原稳定 ID：`0.2.0-FE-A-000`, `0.2.0-FE-A-001`, `0.2.0-FE-A-002`, `0.2.0-FE-A-003`, `0.2.0-FE-A-004`, `0.2.0-FE-A-005`, `0.2.0-FE-A-006`, `0.2.0-FE-A-007`, `0.2.0-FE-A-008`, `0.2.0-FE-A-009`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.2.0-FE-A-000] 支持手动刷新：点击菜单中的「立即刷新」触发全量数据更新，且 dropdown 保持打开 #P1
- [x] [0.2.0-FE-A-001] 支持自动刷新，默认间隔 5 分钟，允许在偏好设置中修改（P2 实现设置页）#P1
- [x] [0.2.0-FE-A-002] 刷新时在 UI 中展示「上次更新时间」和刷新状态（如 spinning indicator）#P1
- [x] [0.2.0-FE-A-003] 单次刷新超时或失败时，不阻塞 UI，其他服务数据正常展示 #P1
- [x] [0.2.0-FE-A-004] 顶部菜单栏图标根据可用状态动态变化：正常 / 警告 / 错误 #P1 — 4 态（normal / refreshing / warning / error）+ 最低 remaining% 数字徽标，`StatusBarController.refreshStatusItemAppearance()`
- [x] [0.2.0-FE-A-005] 菜单栏改为多 bar 视图（Liquid Glass 风格）：每个已配置订阅画 1 个垂直 bar，bar 数 = `.available` 订阅数，bar 颜色 = brand color，bar 顺序 = dashboard 顺序，bar 高度 = 最近重置 quota 的 remainingFraction；用完的（0%）仍画最小 bar 保证知情；未配置（needsConfiguration/notInstalled/fetchFailed）不画 bar #P1 — `StatusBarController.makeBarsImage()`
- [x] [0.2.0-FE-A-006] 菜单栏 status item 占位宽度随实际 bar image 宽度变化；在满足参考图圆角视觉的前提下，避免窄图标仍占 80pt 或 bar 间出现异常缝隙 #P1
- [x] [0.2.0-FE-A-007] 修正菜单栏图标绘制宽度与实际占位宽度不一致的问题，避免截图中 bar 图标视觉宽度较窄但 status item 点击/占位区域明显过宽 #P1
- [x] [0.2.0-FE-A-008] 校准菜单栏多 bar 的数值来源和高度映射，确保每个 bar 真实反映对应服务当前额度状态，而不是使用与实际剩余额度不匹配的占位或无效数值 #P1
- [x] [0.2.0-FE-A-009] 修正菜单栏 bar 绘制样式：当前 bar 圆角没有按预期绘制，应参考此前参考图恢复圆角外观，并确保高低不同的 bar 在小尺寸菜单栏图标中仍清晰可辨 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260620204220-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260620204220-utcp8-gpt5.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 再增加一个需求，bar的绘制不对，圆角没画，参考我之前的参考图

#### 完成工作

- 已更新 `REQUIREMENTS.md`：
  - 调整 `[0.2.0-FE-A-006]`，避免旧的“无圆角”约束与新需求冲突。
  - 新增 `[0.2.0-FE-A-009]`：修正菜单栏 bar 绘制样式，参考此前参考图恢复圆角外观。

#### 更新的需求 ID

- 更新：`0.2.0-FE-A-006`
- 新增：`0.2.0-FE-A-009`

#### 验证方式

- `python3` 自定义格式检查：通过，确认 `REQUIREMENTS.md` 的标题和任务 ID 仍符合新版规则。

#### 备注

- 未运行 `swift build`，本次仅修改 Markdown 需求记录，不执行实现。

### 20260620205908-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260620205908-utcp8-gpt5.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 处理这4个task，我的参考图如下：[原创应用](https://www.figma.com/design/zAky4WvzPYWbQSjOE7hrE1/%E5%8E%9F%E5%88%9B%E5%BA%94%E7%94%A8?node-id=106-649&t=FqJCnIGbfe80yLpv-4)
> - [ ] [0.2.0-FE-A-005] 菜单栏改为多 bar 视图（Liquid Glass 风格）：每个已配置订阅画 1 个垂直 bar，bar 数 = `.available` 订阅数，bar 颜色 = brand color，bar 顺序 = dashboard 顺序，bar 高度 = 最低 remainingFraction；用完的（0%）仍画最小 bar 保证知情；未配置（needsConfiguration/notInstalled/fetchFailed）不画 bar #P1 — `StatusBarController.makeBarsImage()`
> - [ ] [0.2.0-FE-A-006] 菜单栏 status item 占位宽度随实际 bar image 宽度变化；在满足参考图圆角视觉的前提下，避免窄图标仍占 80pt 或 bar 间出现异常缝隙 #P1
> - [ ] [0.2.0-FE-A-007] 修正菜单栏图标绘制宽度与实际占位宽度不一致的问题，避免截图中 bar 图标视觉宽度较窄但 status item 点击/占位区域明显过宽 #P1
> - [ ] [0.2.0-FE-A-008] 校准菜单栏多 bar 的数值来源和高度映射，确保每个 bar 真实反映对应服务当前额度状态，而不是使用与实际剩余额度不匹配的占位或无效数值 #P1
> - [ ] [0.2.0-FE-A-009] 修正菜单栏 bar 绘制样式：当前 bar 圆角没有按预期绘制，应参考此前参考图恢复圆角外观，并确保高低不同的 bar 在小尺寸菜单栏图标中仍清晰可辨 #P1

#### 完成工作

- `StatusBarController.swift`
  - 多 bar 只绘制真实可用且有 quota 数据的订阅。
  - bar 高度、tooltip 百分比统一来自最低剩余比例。
  - status item 宽度直接跟随 bar image 宽度，避免额外过宽占位。
  - bar 使用圆角绘制，低高度 bar 仍保持可辨识。
- `DESIGN.md`
  - 同步菜单栏多 bar 的圆角、高度映射和最小高度规则。
- `REQUIREMENTS.md`
  - 勾选本次完成的 FE-A 005-009。

#### 更新的需求 ID

- `0.2.0-FE-A-005`
- `0.2.0-FE-A-006`
- `0.2.0-FE-A-007`
- `0.2.0-FE-A-008`
- `0.2.0-FE-A-009`

#### 验证方式

- `cd quota-bar && swift build`：通过。
- 再次执行 `cd quota-bar && swift build`：通过。

#### 备注

- 未执行提交。
- 本次未通过运行中的 macOS 菜单栏截图做视觉验收；代码层面已消除固定额外宽度和无圆角绘制问题。
