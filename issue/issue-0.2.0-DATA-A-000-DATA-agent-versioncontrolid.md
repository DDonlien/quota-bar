# DATA-A：Agent 自动探测

- ID：`0.2.0-DATA-A-000`。
- 类型：`DATA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `b550269a253e390d19ec221949fb30c44adf9e9e`；标题路径：任务清单 / Phase - v0.2.0 - Quota Bar 核心功能 / DATA-A：Agent 自动探测。
- 原稳定 ID：`0.2.0-DATA-A-000`, `0.2.0-DATA-A-001`, `0.2.0-DATA-A-002`, `0.2.0-DATA-A-003`, `0.2.0-DATA-A-004`, `0.2.0-DATA-A-005`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.2.0-DATA-A-000] 探测本地已安装的 AI 编程工具 CLI（如 Codex CLI、Claude CLI、Gemini CLI 等）#P1 — `AgentDetector.detectCLIProviders()`
- [x] [0.2.0-DATA-A-001] 探测浏览器中已登录的 AI 服务（通过 Safari / Chrome / Firefox 的 Cookie 或 LocalStorage）#P1 — `AgentDetector.detectBrowserProviders()`
- [x] [0.2.0-DATA-A-002] 探测本地安装的 AI IDE 或应用（如 Cursor、Warp 等）#P1 — `AgentDetector.detectAppProviders()`
- [x] [0.2.0-DATA-A-003] 探测环境变量或配置文件中的 API key（如 OpenAI、Anthropic、DeepSeek 等）#P1 — `AgentDetector.detectAPIKeyProviders()`
- [x] [0.2.0-DATA-A-004] 汇总探测结果，将每个 Agent 标记为「可用（已认证）」「待配置（需登录）」或「未安装」状态 #P1 — `DetectionResult.availableAgents` 等
- [x] [0.2.0-DATA-A-005] 探测结果决定菜单栏中展示哪些服务，不展示未安装或无需关注的服务 #P1 — `RefreshCoordinator` 过滤 `.notInstalled` snapshot

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
