# 将应用包发布与下载链路迁移到VercelBlob

- ID：`0.15.0-CI-A-000`。
- 类型：`CI`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.15.0 - 7 天试用 + Creem 授权激活 + 发布链路迁移到 Vercel Blob / sub/main: 发布链路迁移到 Vercel Blob。
- 原稳定 ID：`0.15.0-CI-A-000`, `0.15.0-BE-B-000`, `0.15.0-BE-B-001`, `0.15.0-DOC-A-000`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.15.0-CI-A-000] `release.yml`：构建出 dmg 后上传到 Vercel Blob，并同时上传一份 `latest.json` manifest（`version`/`tag`/`notes`/`downloadUrl`/`publishedAt`/`size`）；GitHub Release 仍然创建（保留 tag 与源码归档）但不再附带 dmg 资产
- [x] [0.15.0-BE-B-000] `api/latest-release.mjs` 改为读 Blob 上的 `latest.json`，并**仍然输出 GitHub Release 数组的形状**（合成 `assets[0].browser_download_url` 指向 `/api/download-latest`）——这样彻底摆脱对 GitHub API 的运行时依赖（顺带解决大陆可达性），同时不需要为新老客户端维护两套解析
- [x] [0.15.0-BE-B-001] `api/download-latest.mjs` 改为从 Blob 流式转发 dmg，不再现查 GitHub release
- [x] [0.15.0-DOC-A-000] `AGENTS.md` 发版流程章节同步更新为新链路（Blob 托管 + Release 只放源码），并记录"≤v0.10.1 客户端会失去自动更新"这一既成事实，避免以后有人误以为是 bug

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
