# 支持从Edge多个浏览器Profile读取Cookie

- ID：`0.10.0-DATA-B-015`。
- 类型：`ARCH`。
- 状态：进行中（原文同时包含已完成与未完成项）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 面向全网用户的 hardcoded 路径 / 假设审计。
- 原稳定 ID：`0.10.0-ARCH-C-000`, `0.10.0-ARCH-C-001`, `0.10.0-DATA-B-013`, `0.10.0-DATA-B-014`, `0.10.0-QA-B-000`, `0.10.0-DATA-B-015`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.10.0-ARCH-C-000`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.10.0-DATA-B-015`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.10.0-ARCH-C-000-ARCH-hardcoded-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：sub/main: 面向全网用户的 hardcoded 路径 / 假设审计。
- 同源任务：[按用户环境定位并执行CLI命令](issue_%E6%8C%89%E7%94%A8%E6%88%B7%E7%8E%AF%E5%A2%83%E5%AE%9A%E4%BD%8D%E5%B9%B6%E6%89%A7%E8%A1%8CCLI%E5%91%BD%E4%BB%A4.md)、[在同service的Keychain条目中选取最新凭证](issue_%E5%9C%A8%E5%90%8Cservice%E7%9A%84Keychain%E6%9D%A1%E7%9B%AE%E4%B8%AD%E9%80%89%E5%8F%96%E6%9C%80%E6%96%B0%E5%87%AD%E8%AF%81.md)。

## 当前需求与范围

共同范围与完整历史见[按用户环境定位并执行CLI命令](issue_%E6%8C%89%E7%94%A8%E6%88%B7%E7%8E%AF%E5%A2%83%E5%AE%9A%E4%BD%8D%E5%B9%B6%E6%89%A7%E8%A1%8CCLI%E5%91%BD%E4%BB%A4.md)；本文件保留以下独立目标的原文。

- [ ] [0.10.0-DATA-B-015] `EdgeCookieReader` 硬编码只读 `Microsoft Edge/Default` 单一 profile，多 profile（如工作/个人分账号）用户可能登录在非 Default profile 中；浏览器 Cookie 路径当前已是显式启用的最后兜底层，非默认路径，暂不提升优先级 #P2 #deferred — 呼应既有 `0.2.0-DATA-B-008` 多浏览器/多 profile 选择的 deferred 项，一并留待后续处理

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

原迁移条目的历史Comments完整保留于[同源历史](issue_%E6%8C%89%E7%94%A8%E6%88%B7%E7%8E%AF%E5%A2%83%E5%AE%9A%E4%BD%8D%E5%B9%B6%E6%89%A7%E8%A1%8CCLI%E5%91%BD%E4%BB%A4.md#comments)，不从历史日志新增完成标记。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
