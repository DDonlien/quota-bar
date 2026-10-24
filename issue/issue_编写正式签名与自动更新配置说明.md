# 编写正式签名与自动更新配置说明

- ID：`0.12.0-DOC-A-000`。
- 类型：`DOC`。
- 状态：待定 / 延后（沿用原需求记录）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.12.0 - 升级到 Developer ID 签名 + notarize / update/main: 升级文档与验收。
- 原稳定 ID：`0.12.0-DOC-A-000`, `0.12.0-DOC-A-001`, `0.12.0-DOC-A-002`, `0.12.0-QA-A-000`, `0.12.0-QA-A-001`, `0.12.0-QA-A-002`, `0.12.0-QA-A-003`, `0.12.0-QA-A-004`, `0.12.0-QA-A-005`, `0.12.0-QA-A-006`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.12.0-QA-A-000`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.12.0-DOC-A-000`、`0.12.0-DOC-A-001`、`0.12.0-DOC-A-002`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.12.0-QA-A-000-DOC-documentation-acceptance-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：update/main: 升级文档与验收。
- 同源任务：[核对正式签名更新与权限保留流程](issue_%E6%A0%B8%E5%AF%B9%E6%AD%A3%E5%BC%8F%E7%AD%BE%E5%90%8D%E6%9B%B4%E6%96%B0%E4%B8%8E%E6%9D%83%E9%99%90%E4%BF%9D%E7%95%99%E6%B5%81%E7%A8%8B.md)。

## 当前需求与范围

- [ ] [0.12.0-DOC-A-000] 写 `macos/scripts/cert-bootstrap.md`：用户首次配签名环境的 step-by-step（enroll / 生成 cert / 配 API Key / 验证），agent 后续 onboarding 流程直接引用（继承自 v0.11.0-DOC-A-002 #deferred）#P1
- [ ] [0.12.0-DOC-A-001] `macos/AGENTS.md` 的「发版流程」节从 v0.11.0-DOC-A-000 的 ad-hoc 版升级为 cert 版：本地 `make app`（Developer ID + notarize）→ `spctl --assess` 通过 → 推 main → 自动 nightly；需要发版时用 GitHub Actions 手动触发 `workflow_dispatch` 传 `vX.Y.Z` #P1
- [ ] [0.12.0-DOC-A-002] `README.md` 的「更新策略」节从 v0.11.0-DOC-A-001 的 best-effort 版升级为正式版：Developer ID 签名 + notarize 后 macOS TCC 权限（Accessibility / Screen Recording / Automation 等）更新后**形式化保留** + 如何手动重置忽略的版本 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
