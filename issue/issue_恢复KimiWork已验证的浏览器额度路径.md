# 恢复KimiWork已验证的浏览器额度路径

- ID：`0.3.0-DATA-A-005`。
- 类型：`DATA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`；标题路径：任务清单 / Phase - v0.3.0 - UI 拖拽、订阅组语义与 dropdown 实时刷新 / DATA-A：订阅组（subscription group）语义。
- 原稳定 ID：`0.3.0-DATA-A-000`, `0.3.0-DATA-A-001`, `0.3.0-DATA-A-002`, `String`, `0.3.0-DATA-A-003`, `0.3.0-DATA-A-004`, `0.3.0-DATA-A-005`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.3.0-DATA-A-000`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.3.0-DATA-A-005`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.3.0-DATA-A-000-DATA-subscription-group-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：DATA-A：订阅组（subscription group）语义。
- 同源任务：[建立独立计费订阅组及排序语义](issue_%E5%BB%BA%E7%AB%8B%E7%8B%AC%E7%AB%8B%E8%AE%A1%E8%B4%B9%E8%AE%A2%E9%98%85%E7%BB%84%E5%8F%8A%E6%8E%92%E5%BA%8F%E8%AF%AD%E4%B9%89.md)。

## 当前需求与范围

共同范围与完整历史见[建立独立计费订阅组及排序语义](issue_%E5%BB%BA%E7%AB%8B%E7%8B%AC%E7%AB%8B%E8%AE%A1%E8%B4%B9%E8%AE%A2%E9%98%85%E7%BB%84%E5%8F%8A%E6%8E%92%E5%BA%8F%E8%AF%AD%E4%B9%89.md)；本文件保留以下独立目标的原文。

- [x] [0.3.0-DATA-A-005] 恢复 Kimi Work 已验证数据路径：Work/Code 三条额度只由浏览器 `kimi-auth` cookie 调 `GetSubscriptionStat` 产生；`KimiAuthProvider` 保持 CLI Code-only fallback；`GetSubscription` tier/price 请求失败或超时不得阻塞 Work 额度显示 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

原迁移条目的历史Comments完整保留于[同源历史](issue_%E5%BB%BA%E7%AB%8B%E7%8B%AC%E7%AB%8B%E8%AE%A1%E8%B4%B9%E8%AE%A2%E9%98%85%E7%BB%84%E5%8F%8A%E6%8E%92%E5%BA%8F%E8%AF%AD%E4%B9%89.md#comments)，不从历史日志新增完成标记。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
