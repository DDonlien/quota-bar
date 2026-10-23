# sub/main: 建立 last-known-good 快照

- ID：`0.9.0-DATA-B-000`。
- 类型：`DATA`。
- 状态：待处理（原文未完成项保持未勾选）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.9.0 - 持久化、来源索引与启动兜底 / sub/main: 建立 last-known-good 快照。
- 原稳定 ID：`0.9.0-DATA-B-000`, `0.9.0-DATA-B-001`, `0.9.0-DATA-B-002`, `0.9.0-DATA-B-003`, `0.9.0-DATA-B-004`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [ ] [0.9.0-DATA-B-000] 新增 last-known-good 快照文件，保存每个 provider 最近一次真实刷新成功的额度、订阅状态、订阅过期时间、价格、档位、fetchedAt、sourceKind 与是否 stale 等信息 #P1
- [ ] [0.9.0-DATA-B-001] App 启动时先读取 last-known-good 快照作为 stale 初始展示，再异步刷新真实数据；UI 必须清晰标记 stale，避免误以为是最新数据 #P1
- [ ] [0.9.0-DATA-B-002] 刷新失败时可以保留 last-known-good 展示，但必须保留失败状态或 stale 标记，不能把旧快照伪装成本次成功刷新 #P1
- [ ] [0.9.0-DATA-B-003] last-known-good 快照写入前进行脱敏，不保存任何 token、cookie、API key、完整账号 ID 或浏览器 cookie 内容 #P1
- [ ] [0.9.0-DATA-B-004] 快照写入只发生在真实刷新成功或明确订阅过期状态确认后；占位 loading、未安装、纯抓取失败不得覆盖 last-known-good 快照 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
