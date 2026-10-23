# sub/main: 验证

- ID：`0.15.0-QA-A-000`。
- 类型：`QA`。
- 状态：进行中（原文同时包含已完成与未完成项）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.15.0 - 7 天试用 + Creem 授权激活 + 发布链路迁移到 Vercel Blob / sub/main: 验证。
- 原稳定 ID：`0.15.0-QA-A-000`, `0.15.0-QA-A-001`, `0.15.0-QA-A-002`, `0.15.0-BE-B-002`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.15.0-QA-A-000] 新增单测：`LicenseState` 边界（第 0/6/7/8 天、已激活时忽略试用期、`licenseInvalid` 降级）、`LicenseManager` 的 fail-open 行为（mock 5xx 不吊销授权、明确 `status: expired` 才降级）；沿用现有 `URLProtocol` mock + 临时目录 store 注入模式，不碰真实用户状态
- [x] [0.15.0-QA-A-001] **Blob 链路端到端已验证**：用 Vercel CLI 建 public blob store（`quota-bar-releases`，自动注入 `BLOB_READ_WRITE_TOKEN` 到三个环境）+ 手动加 `BLOB_PUBLIC_BASE_URL`，token 经管道传入 GitHub Actions Secrets（值未落到任何输出）。`workflow_dispatch` 跑通一次真实发布：Blob 上传步骤执行、legacy fallback 被正确跳过、GitHub Release 不带 dmg；`curl` 确认 Blob 上 manifest 与 dmg 均可公开取到；重新部署后 `/api/latest-release` 已切到 Blob manifest（返回单条、资产 URL 指向 `/api/download-latest`），`/api/download-latest` 完整下载 2734775 字节且 `hdiutil verify` 校验 VALID
- [ ] [0.15.0-QA-A-002] **Creem 激活端到端待验证**（阻塞于用户侧前置条件）：需要用户在 Creem 后台确认 `prod_4NN9fUOfr2BU4L5NbaqFmo` 已开启 License Keys，并在 Vercel 配置 `CREEM_API_KEY`（密钥，Agent 不经手）。建议先用 Creem test mode 走一遍——`_lib/creem.mjs` 支持用 `CREEM_API_BASE_URL` 指向 `https://test-api.creem.io/v1`
- [x] [0.15.0-BE-B-002] `api/download-latest.mjs` 补 `HEAD` 导出：Vercel 不会把 HEAD 自动路由到 GET，实测 `curl -I` 撞 405，会被下载器/代理误读成"地址挂了"；复用 GET 逻辑取真实响应头后丢掉 body，避免手写一份跟 GET 不一致的头

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
