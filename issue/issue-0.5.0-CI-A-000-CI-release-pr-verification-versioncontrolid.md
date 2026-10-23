# CI-A：发布自动化 + PR 验证（围绕 3 件事）

- ID：`0.5.0-CI-A-000`。
- 类型：`CI`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `b550269a253e390d19ec221949fb30c44adf9e9e`；标题路径：任务清单 / Phase - v0.5.0 - 发布自动化与工程卫生 / CI-A：发布自动化 + PR 验证（围绕 3 件事）。
- 原稳定 ID：`0.5.0-CI-A-000`, `0.5.0-CI-A-001`, `0.5.0-CI-A-002`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 1. **修改后在本地自动打包** —— `AGENTS.md` 已要求（`./scripts/build-app.sh`），不需要 GitHub
>    代码自动化，agent 遵守 AGENTS 即可，无需本 phase 任务。
> 2. **提交后自动打包到 Release** —— 需要 GitHub Actions 自动化。
> 3. **PR 合并前自动验证** —— 工程卫生类，需要 GitHub Actions。

- [x] [0.5.0-CI-A-000] 已存在 `.github/workflows/release.yml` 在 main push 触发里加 `./quota-bar/scripts/build-app.sh` 步骤（确保 main push 后自动产 .app 并发到 pre-release）；用户可感知：每个 commit 都自动有可下载的 .app #P1
- [x] [0.5.0-CI-A-001] `release.yml` 加 `cd web && npm ci && npm run build` 步骤，让营销主页（quotabar.ddonlien.com）跟着主仓一起更新 #P2
- [x] [0.5.0-CI-A-002] 新增 `.github/workflows/pr-check.yml`：PR 触发时跑 `swift build`（PR 合并前自动验证，避免坏改动进 main）#P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
