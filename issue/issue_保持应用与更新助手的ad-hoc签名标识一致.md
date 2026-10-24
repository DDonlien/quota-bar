# 保持应用与更新助手的ad-hoc签名标识一致

- ID：`0.11.0-ARCH-A-000`。
- 类型：`ARCH`。
- 状态：进行中（原文同时包含已完成与未完成项）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.11.0 - 真实自动更新（ad-hoc 预开发版）+ semver 发版 / update/main: 维持 ad-hoc 签名 + 无 notarize 立场（预开发版）。
- 原稳定 ID：`0.11.0-ARCH-A-000`, `0.11.0-ARCH-A-001`, `0.11.0-ARCH-A-002`, `0.11.0-ARCH-A-003`, `0.12.0-SEC-A-006`, `0.11.0-ARCH-A-000-test`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 本 phase **不引入任何 cert 改动**；build script 维持 `--sign -` ad-hoc 签名，无 notarize、无 `--options runtime`、无 .p8 API Key。
> 正式升级到 Developer ID 签名 + notarize 在 v0.12.0 完成（phase header 已说明两者关系）。
> 本段落的 ARCH 任务是**为 v0.12.0 提前锁定资产**：bundle id 在 v0.11.0 阶段就锁死，v0.12.0 升级 cert 时直接复用，避免 TCC 权限被清。

- [x] [0.11.0-ARCH-A-000] 保持 bundle identifier `com.taobe.quotabar` 在所有 build 中不变；`build-app.sh` 内已 hardcode，本 phase 任何修改都不允许触碰该值（v0.12.0 升级 cert 时这是 TCC 权限保留的形式化前置条件）#P1
- [x] [0.11.0-ARCH-A-001] 保持 `--identifier com.taobe.quotabar` 重签名参数与 Info.plist 的 `CFBundleIdentifier` 一致；ad-hoc 模式下该参数是 macOS 识别「同一 app」的最重要依据，本 phase 不允许改动 #P1
- [x] [0.11.0-ARCH-A-002] build script 在本 phase 维持 `--sign -` ad-hoc 签名；**不引入** `--options runtime` / `xcrun notarytool` / .p8 API Key 任一项；v0.11.0 范围内任何与签名相关的改动都 defer 到 v0.12.0 #P1
- [x] [0.11.0-ARCH-A-003] helper 脚本 `install-update.sh` 同样 ad-hoc 签名；本机使用可接受，Gatekeeper 首次会拦截，本机授权一次后记住；v0.12.0 同步升级为 Developer ID 签名（见 [0.12.0-SEC-A-006]）#P1
- [ ] [0.11.0-ARCH-A-000-test] 测试每次 `build-app.sh` 跑完后，生成的 .app 的 `Info.plist.CFBundleIdentifier` == `--identifier` 参数值 == `com.taobe.quotabar`（断言三个值一致，防止 v0.12.0 升级 cert 时出现签名 identifier 与 bundle id 漂移）#P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
