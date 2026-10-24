# 在菜单Tracking期间立即刷新偏好变更

- ID：`0.10.0-BUG-A-009`。
- 类型：`ARCH`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 更新检查改为纯版本号比较 + dropdown 隐藏按钮实时刷新 + GLM/Z Code 开关关联修复。
- 原稳定 ID：`0.10.0-ARCH-J-000`, `0.10.0-ARCH-J-001`, `0.10.0-ARCH-J-002`, `0.10.0-DOC-A-005`, `0.10.0-BUG-A-009`, `0.10.0-BUG-A-010`, `0.10.0-QA-A-001`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.10.0-ARCH-J-000`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.10.0-BUG-A-009`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.10.0-ARCH-J-000-ARCH-dropdown-refresh-glm-code-fixes-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：sub/main: 更新检查改为纯版本号比较 + dropdown 隐藏按钮实时刷新 + GLM/Z Code 开关关联修复。
- 同源任务：[以语义版本号比较更新并统一VERSION来源](issue_%E4%BB%A5%E8%AF%AD%E4%B9%89%E7%89%88%E6%9C%AC%E5%8F%B7%E6%AF%94%E8%BE%83%E6%9B%B4%E6%96%B0%E5%B9%B6%E7%BB%9F%E4%B8%80VERSION%E6%9D%A5%E6%BA%90.md)、[将模型开关关联到实际ZCodeProvider](issue_%E5%B0%86%E6%A8%A1%E5%9E%8B%E5%BC%80%E5%85%B3%E5%85%B3%E8%81%94%E5%88%B0%E5%AE%9E%E9%99%85ZCodeProvider.md)。

## 当前需求与范围

共同范围与完整历史见[以语义版本号比较更新并统一VERSION来源](issue_%E4%BB%A5%E8%AF%AD%E4%B9%89%E7%89%88%E6%9C%AC%E5%8F%B7%E6%AF%94%E8%BE%83%E6%9B%B4%E6%96%B0%E5%B9%B6%E7%BB%9F%E4%B8%80VERSION%E6%9D%A5%E6%BA%90.md)；本文件保留以下独立目标的原文。

- [x] [0.10.0-BUG-A-009] `RefreshCoordinator` 的 `.quotaPreferencesDidChange` 订阅从 `.receive(on: RunLoop.main)` 改为 `.receive(on: DispatchQueue.main)`：`RunLoop.main` 默认用 `.default` run loop mode，dropdown 的 `NSMenu` 鼠标 tracking 期间是 `.eventTracking` mode，`.default` 模式排的任务要等菜单关闭才会跑，这正是"点了叉不会立刻隐藏，要关闭再打开 dropdown 才生效"的根因；`hide(kind:)` 额外同步直接调用一次 `applyEnabledFilterChange()`，不完全依赖异步通知链路的时机 #P0

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

原迁移条目的历史Comments完整保留于[同源历史](issue_%E4%BB%A5%E8%AF%AD%E4%B9%89%E7%89%88%E6%9C%AC%E5%8F%B7%E6%AF%94%E8%BE%83%E6%9B%B4%E6%96%B0%E5%B9%B6%E7%BB%9F%E4%B8%80VERSION%E6%9D%A5%E6%BA%90.md#comments)，不从历史日志新增完成标记。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
