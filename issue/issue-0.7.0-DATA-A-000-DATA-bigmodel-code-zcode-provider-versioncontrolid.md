# DATA-A：智谱 BigModel Z Code (zcode) Provider 接入

- ID：`0.7.0-DATA-A-000`。
- 类型：`DATA`。
- 状态：待处理（原文未完成项保持未勾选）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`；标题路径：任务清单 / Phase - v0.7.0 - 智谱 GLM Provider 接入（feat/glm-provider） / DATA-A：智谱 BigModel Z Code (zcode) Provider 接入。
- 原稳定 ID：`0.7.0-DATA-A-000`, `0.7.0-DATA-A-001`, `QuotaWindow`, `0.7.0-DATA-A-002`, `0.7.0-DATA-A-003`, `0.7.0-DATA-A-004`, `0.7.0-DATA-A-005`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 任务继承自 v0.4.0 phase 的 `### DATA-A：智谱 BigModel Z Code (zcode)`（4 项），但每项提升到 v0.7.0 phase 顶层，确保 `feat/glm-provider` branch 推进时有稳定的 v0.7.0 编号。

- [ ] [0.7.0-DATA-A-000] 在 `ProviderKind` enum 新增 `.zcode` 枚举值，`displayName = "Z Code"`、`brandColor`、`iconSymbol`、`bundleIdentifier = "dev.zcode.app"`、`credentialFiles = ["~/.zcode/v2/credentials.json"]`、`envVarNames = []` 等元数据补齐 #P1
- [ ] [0.7.0-DATA-A-001] `ZCodeAuthProvider` 实现：从 `~/.zcode/v2/config.json` 读启用 plan 的 API key + baseURL，对 plan endpoint 发 anthropic 兼容 API 拉 usage；解析剩余额度到 `[QuotaWindow]` #P1
- [ ] [0.7.0-DATA-A-002] 套餐映射：识别 `builtin:bigmodel-start-plan` / `builtin:bigmodel-coding-plan` / `builtin:zai-start-plan` / `builtin:zai-coding-plan` 4 种 plan，subscriptionGroup 按 plan 区分（每个 plan = 1 个订阅组）；价格映射到 `ProviderPricing` #P1
- [ ] [0.7.0-DATA-A-003] `ZcodeLoginRunner` + `InstallDetectorProvider`：探测 `dev.zcode.app` bundle 安装和 `~/.zcode/v2/config.json` 存在性，驱动 pipeline 串接 #P1
- [ ] [0.7.0-DATA-A-004] `Strategies.zcodePipeline()` 接入 `RefreshCoordinator`，凭证缺失时 fallback 到 Keychain / `needsConfiguration` 状态 #P1
- [ ] [0.7.0-DATA-A-005] web/DESIGN.md 中 `--provider-zcode` 的 brandColor 在 app DESIGN.md / QuotaModels 中同步落地（当前 web 占位 `#3866ff`，app 端选色待定）#P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
