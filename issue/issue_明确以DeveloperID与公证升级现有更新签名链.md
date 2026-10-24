# 明确以DeveloperID与公证升级现有更新签名链

- ID：`migration-0ec020168ec6`。
- 类型：`DOC`。
- 状态：待定 / 延后（沿用原需求记录）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.12.0 - 升级到 Developer ID 签名 + notarize。

## 当前需求与范围

> **承接 v0.11.0**：v0.11.0 已完成 update 机制全部建设（UpdateChecker / helper / UI / 状态机 / semver / ad-hoc 签名），bundle identifier 在 v0.11.0 阶段锁死为 `com.taobe.quotabar`。
> v0.12.0 在 v0.11.0 基础上**仅升级签名链 + notarize**，**不重写 update 流程本身**。v0.11.0 的所有 FE / UI / TOOL / CI / 部分 DOC / QA 任务保持不动，本 phase 只追加签名相关任务。
>
> **v0.11.0 → v0.12.0 的具体 delta**（延续性边界，越小越好）：
> - **改的**：`build-app.sh` 签名身份（`--sign -` → `Developer ID Application: <Name> (<TEAMID>)` + `--options runtime`）、新增 `xcrun notarytool submit` + `xcrun stapler staple`、helper 脚本同步升级签名、`release.yml` 注释更新、cert 一致性断言、相关文档。
> - **不改的**：UpdateChecker / 状态机 / 版本比较 / UI / 偏好设置 / semver workflow / GitHub Actions `workflow_dispatch` 触发逻辑。
> - **共享资产**：`com.taobe.quotabar` bundle id（v0.11.0-ARCH-A-000 锁死）+ 状态机 + helper 替换逻辑（v0.11.0-TOOL-A-000/003/004/005）。
>
> **与 v0.11.0 任务的交叉引用**：
> - v0.11.0-ARCH-A-000 锁定的 bundle id → v0.12.0-SEC-A-001 升级签名时直接复用
> - v0.11.0-ARCH-A-002 不引入 cert 改动的承诺 → v0.12.0 解除，签名相关任务落地
> - v0.11.0-ARCH-A-003 helper ad-hoc 签名 → v0.12.0-SEC-A-006 同步升级
> - v0.11.0-TOOL-A-001 跳过 spctl → v0.12.0-SEC-A-006 强制加 spctl
> - v0.11.0-UI-A-003 best-effort 文案 → v0.12.0-UI-A-XXX 改写为「正式形式化保障」
> - v0.11.0-CI-A-004 维持注释 → v0.12.0-SEC-A-005 更新注释
> - v0.11.0-DOC-A-002 cert-bootstrap.md #deferred → v0.12.0-DOC-A-000 落地
> - v0.11.0-QA-A-002 Gatekeeper #deferred → v0.12.0-QA-A-002 实现
>
> **前置依赖（用户侧）**：enroll Apple Developer Program（$99/年）→ 审批通过 → 本地 Keychain 生成 Developer ID Application cert → 在 App Store Connect 创建 API Key（`.p8`）用于 `xcrun notarytool`。enroll + 审批是用户侧操作，agent 仅提供操作指引。
>
> **worktree 拆分**：仍在 `update/main` worktree 推进（与 v0.11.0 同一分支，避免反复创建 worktree）。

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 2026-10-24 07:03:43 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
