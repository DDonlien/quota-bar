# sub/main: 调研阿里通义千问桌面 App

- ID：`0.4.0-DATA-B-001`。
- 类型：`DATA`。
- 状态：阻塞（沿用原需求记录）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.4.0 - 新 Provider 接入（zcode / 千问 / 其他） / sub/main: 调研阿里通义千问桌面 App。
- 原稳定 ID：`0.4.0-DATA-B-000`, `0.4.0-DATA-B-001`, `0.4.0-DATA-B-002`, `0.4.0-DATA-B-003`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [ ] [0.4.0-DATA-B-000] 用户确认千问桌面 App 实际安装路径（`/Applications` / `~/Applications` / DMG 挂载点 / 第三方目录） #blocked — 用户已声明"已装"但实际未在常见位置发现，需要确认
- [ ] [0.4.0-DATA-B-001] 在 `ProviderKind` enum 新增 `.qwen` 枚举值，元数据补齐（`bundleIdentifier` 等安装探测需要用户提供）#blocked — 依赖 [0.4.0-DATA-B-000]
- [ ] [0.4.0-DATA-B-002] `QwenAppProvider` 实现：dashboard endpoint 走浏览器 Cookie 路径（参考 Kimi `BrowserCookieProvider` + `KimiSubscriptionStatParser`），凭证从浏览器 Cookie 读取 #blocked — 依赖 [0.4.0-DATA-B-000]
- [ ] [0.4.0-DATA-B-003] `Strategies.qwenPipeline()` 接入 `RefreshCoordinator`，bundle 安装但 Cookie 未登录时降级到 `needsConfiguration` #blocked — 依赖 [0.4.0-DATA-B-002]

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
