# sub/main: Creem 激活的服务端代理（Vercel）

- ID：`0.15.0-BE-A-000`。
- 类型：`BE`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.15.0 - 7 天试用 + Creem 授权激活 + 发布链路迁移到 Vercel Blob / sub/main: Creem 激活的服务端代理（Vercel）。
- 原稳定 ID：`0.15.0-BE-A-000`, `0.15.0-BE-A-001`, `0.15.0-BE-A-002`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.15.0-BE-A-000] 新增 `api/activate.mjs`：`POST {key, instanceName}` → 服务端带 `CREEM_API_KEY` 调 `POST https://api.creem.io/v1/licenses/activate` → 回传精简结果（`status`/`instanceId`/`expiresAt`/`activation`/`activationLimit`），绝不回传或记录 API key；入参做长度与字符校验，避免被当成任意转发代理
- [x] [0.15.0-BE-A-001] 新增 `api/validate.mjs`：`POST {key, instanceId}` → 代理 `POST https://api.creem.io/v1/licenses/validate`，供 App 定期复验
- [x] [0.15.0-BE-A-002] 两个 endpoint 共用 `api/_lib/creem.mjs`（base URL、鉴权头、错误归一化）；`CREEM_API_KEY` 缺失时返回明确的 503 而不是 500，方便区分"没配环境变量"和"Creem 侧故障"

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
