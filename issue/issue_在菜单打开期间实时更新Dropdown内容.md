# 在菜单打开期间实时更新Dropdown内容

- ID：`0.3.0-UI-A-004`。
- 类型：`UI`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`；标题路径：任务清单 / Phase - v0.3.0 - UI 拖拽、订阅组语义与 dropdown 实时刷新 / UI-A：拖拽排序与状态联动（语义升级）。
- 原稳定 ID：`0.3.0-UI-A-000`, `0.3.0-UI-A-001`, `0.3.0-UI-A-002`, `0.3.0-UI-A-003`, `0.3.0-UI-A-004`, `0.3.0-UI-A-005`, `0.3.0-UI-A-006`, `0.3.0-UI-A-007`, `0.3.0-UI-A-009`, `0.3.0-UI-A-010`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.3.0-UI-A-000`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.3.0-UI-A-004`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.3.0-UI-A-000-UI-sorting-state-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：UI-A：拖拽排序与状态联动（语义升级）。
- 同源任务：[拖拽排序Provider与订阅组并联动状态](issue_%E6%8B%96%E6%8B%BD%E6%8E%92%E5%BA%8FProvider%E4%B8%8E%E8%AE%A2%E9%98%85%E7%BB%84%E5%B9%B6%E8%81%94%E5%8A%A8%E7%8A%B6%E6%80%81.md)、[在计划头部显示订阅最后有效日期](issue_%E5%9C%A8%E8%AE%A1%E5%88%92%E5%A4%B4%E9%83%A8%E6%98%BE%E7%A4%BA%E8%AE%A2%E9%98%85%E6%9C%80%E5%90%8E%E6%9C%89%E6%95%88%E6%97%A5%E6%9C%9F.md)。

## 当前需求与范围

共同范围与完整历史见[拖拽排序Provider与订阅组并联动状态](issue_%E6%8B%96%E6%8B%BD%E6%8E%92%E5%BA%8FProvider%E4%B8%8E%E8%AE%A2%E9%98%85%E7%BB%84%E5%B9%B6%E8%81%94%E5%8A%A8%E7%8A%B6%E6%80%81.md)；本文件保留以下独立目标的原文。

- [x] [0.3.0-UI-A-004] dropdown 实时刷新：`MenuView` 用 `@ObservedObject` 绑定 `RefreshCoordinator`，菜单打开期间 SwiftUI 自动响应 `coordinator.state` 变化，NSHostingView 原地重渲染；`StatusBarController.observeCoordinator` 移除 `needsRebuild` 缓冲 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

原迁移条目的历史Comments完整保留于[同源历史](issue_%E6%8B%96%E6%8B%BD%E6%8E%92%E5%BA%8FProvider%E4%B8%8E%E8%AE%A2%E9%98%85%E7%BB%84%E5%B9%B6%E8%81%94%E5%8A%A8%E7%8A%B6%E6%80%81.md#comments)，不从历史日志新增完成标记。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
