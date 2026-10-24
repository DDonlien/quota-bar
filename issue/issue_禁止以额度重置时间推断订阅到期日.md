# 禁止以额度重置时间推断订阅到期日

- ID：`0.6.0-ARCH-A-002`。
- 类型：`ARCH`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`；标题路径：任务清单 / Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页） / feat/subscription-expiry: 建立订阅日期抓取基础架构。
- 原稳定 ID：`0.6.0-ARCH-A-000`, `0.6.0-ARCH-A-001`, `0.6.0-ARCH-A-002`, `0.6.0-ARCH-A-003`, `0.6.0-ARCH-A-003-test`, `0.6.0-ARCH-A-001-test`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.6.0-ARCH-A-000`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.6.0-ARCH-A-002`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.6.0-ARCH-A-000-ARCH-subscription-foundation-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：feat/subscription-expiry: 建立订阅日期抓取基础架构。
- 同源任务：[建立订阅日期抓取协议与Headless加载器](issue_%E5%BB%BA%E7%AB%8B%E8%AE%A2%E9%98%85%E6%97%A5%E6%9C%9F%E6%8A%93%E5%8F%96%E5%8D%8F%E8%AE%AE%E4%B8%8EHeadless%E5%8A%A0%E8%BD%BD%E5%99%A8.md)。

## 当前需求与范围

共同范围与完整历史见[建立订阅日期抓取协议与Headless加载器](issue_%E5%BB%BA%E7%AB%8B%E8%AE%A2%E9%98%85%E6%97%A5%E6%9C%9F%E6%8A%93%E5%8F%96%E5%8D%8F%E8%AE%AE%E4%B8%8EHeadless%E5%8A%A0%E8%BD%BD%E5%99%A8.md)；本文件保留以下独立目标的原文。

- [x] [0.6.0-ARCH-A-002] 删 `ProviderSnapshot.init` 里 `quotas.compactMap(\.resetsAt).max()` fallback：找不到真实到期日时 `subscriptionExpiresAt = nil`（UI 自动不显示）；同时把 `subscriptionExpiresAt` 文档从"默认从 max(resetsAt) 推断"改成"nil = 不展示" #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

原迁移条目的历史Comments完整保留于[同源历史](issue_%E5%BB%BA%E7%AB%8B%E8%AE%A2%E9%98%85%E6%97%A5%E6%9C%9F%E6%8A%93%E5%8F%96%E5%8D%8F%E8%AE%AE%E4%B8%8EHeadless%E5%8A%A0%E8%BD%BD%E5%99%A8.md#comments)，不从历史日志新增完成标记。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
