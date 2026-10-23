# sub/main: 完成新 Provider 接入验收

- ID：`0.4.0-QA-A-001`。
- 类型：`QA`。
- 状态：阻塞（沿用原需求记录）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `1532061d80cab44eba9d5469836105dedd72a7e8`；标题路径：任务清单 / Phase - v0.4.0 - 新 Provider 接入（zcode / 千问 / 其他） / sub/main: 完成新 Provider 接入验收。
- 原稳定 ID：`0.4.0-QA-A-001`, `0.4.0-QA-A-002`, `0.4.0-DATA-B-000`, `0.4.0-QA-A-003`, `0.4.0-QA-A-004`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [ ] [0.4.0-QA-A-001] Z Code Provider：登录态正常时能在 dropdown 展示至少 1 个订阅组，下拉面板数字 / 状态灯 / bar 与其他 Provider 一致；未登录时降级到 `needsConfiguration` 不卡死
- [ ] [0.4.0-QA-A-002] 千问 Provider（实现后）：同上 #blocked — 依赖 [0.4.0-DATA-B-000]
- [ ] [0.4.0-QA-A-003] 文档已更新（README 列出已支持 Provider 清单 + 各 Provider 接入说明）
- [ ] [0.4.0-QA-A-004] `cd macos && swift build` / `swift run` 通过

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
