# update/main: 引入 semver 发版路径

- ID：`0.11.0-CI-A-000`。
- 类型：`CI`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.11.0 - 真实自动更新（ad-hoc 预开发版）+ semver 发版 / update/main: 引入 semver 发版路径。
- 原稳定 ID：`0.11.0-CI-A-000`, `0.11.0-CI-A-001`, `0.11.0-CI-A-002`, `0.11.0-CI-A-003`, `0.11.0-CI-A-004`, `0.12.0-SEC-A-005`, `0.11.0-CI-A-002-test`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 保留 nightly 作为默认 push 自动打包路径；新增 `workflow_dispatch` 触发的 semver 发版路径。
> 引入 semver 并不意味着丢弃 nightly —— nightly 仍是 dev 日常节奏，semver 是「对外稳定版」标记。

- [x] [0.11.0-CI-A-000] `release.yml` 新增 `workflow_dispatch` 输入项 `version`（形如 `v0.11.0`），触发 semver 发版；main 自动 push 路径继续产出 `nightly-<sha>` 不变 #P1
- [x] [0.11.0-CI-A-001] semver 发版路径 tag = `version` 输入值（如 `v0.11.0`）、`prerelease: false`；产物上传到同名 GitHub Release；DMG 名称 `QuotaBar-<version>.dmg`；macOS `CFBundleShortVersionString` 同步写入 `0.11.0`（去前导 `v`）#P1
- [x] [0.11.0-CI-A-002] `build-app.sh` 接受 `VERSION` 环境变量：默认空时走 nightly 行为（`CFBundleShortVersionString = "1.0"` 保持），传入 `v0.11.0` 时写入 `CFBundleShortVersionString = "0.11.0"`；脚本内对 `VERSION` 走严格 `vX.Y.Z` 校验，非合法格式立即 fail，不静默回退 #P1
- [x] [0.11.0-CI-A-003] `CFBundleVersion` / `QBDisplayBuild` 统一日期戳 `YYMMDD.HHMMSS.branch`（当前已部分实现，验证 nightly 与 semver 两条路径都走同一逻辑）#P1
- [x] [0.11.0-CI-A-004] `release.yml` 注释维持 `unsigned and not notarized`，与本 phase ad-hoc 实际行为一致；v0.12.0 升级 cert 时再更新注释为实际签名 + notarize 步骤（升级版见 [0.12.0-SEC-A-005]）#P1
- [x] [0.11.0-CI-A-002-test] 测试 `build-app.sh` 在 `VERSION=v0.11.0` / `VERSION=` / `VERSION=garbage` 三种情况下 Info.plist 写入行为分别正确 #P1 — 2026-07-05 手动验证：garbage 立即 fail、v0.11.0 写入 0.11.0、空写入 1.0

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
