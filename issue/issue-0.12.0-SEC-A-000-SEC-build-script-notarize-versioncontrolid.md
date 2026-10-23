# update/main: 升级 build script 签名 + notarize

- ID：`0.12.0-SEC-A-000`。
- 类型：`SEC`。
- 状态：阻塞（沿用原需求记录）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.12.0 - 升级到 Developer ID 签名 + notarize / update/main: 升级 build script 签名 + notarize。
- 原稳定 ID：`0.12.0-SEC-A-000`, `0.12.0-SEC-A-001`, `0.12.0-SEC-A-002`, `0.12.0-SEC-A-003`, `0.12.0-SEC-A-004`, `0.12.0-SEC-A-005`, `0.12.0-SEC-A-006`, `0.12.0-SEC-A-001-test`, `0.12.0-SEC-A-002-test`, `0.12.0-SEC-A-004-test`；不改写或重编号这些既有 ID。

## 当前需求与范围

> v0.12.0 的核心 SEC 任务：从 ad-hoc 升级到 Developer ID 签名 + notarize。
> 共享 v0.11.0 已锁定的 bundle id（`com.taobe.quotabar`），不重复声明。

- [ ] [0.12.0-SEC-A-000] 用户完成 Apple Developer Program enroll 并在本地 Keychain 生成 Developer ID Application cert；enroll + 审批是用户侧操作，agent 仅提供操作指引 #blocked — 用户前置操作，agent 不直接代执行（继承自原 v0.11.0 设计稿，2026-07-02 拆分）
- [ ] [0.12.0-SEC-A-001] `build-app.sh` 将 `--sign -` 改为 `--sign "Developer ID Application: <Name> (<TEAMID>)"`，并加 `--options runtime`（启用 Hardened Runtime，notarize 前置条件）；bundle id 沿用 v0.11.0-ARCH-A-000 锁定的 `com.taobe.quotabar`，不重新声明 #P1
- [ ] [0.12.0-SEC-A-002] `build-app.sh` 加 notarize 步骤：使用 App Store Connect API Key（.p8 文件）调 `xcrun notarytool submit`，等公证通过后 `xcrun stapler staple` 钉到 dmg；公证失败时 build script 立即 fail，产物不发出去 #P1
- [ ] [0.12.0-SEC-A-003] App Store Connect API Key（.p8 + Key ID + Issuer ID）写入本地 `macos/.env`（不进 Git，加入 `.gitignore`），build-app.sh 读 `.env` 注入 notarytool；`macos/.env.example` 提供模板；macos/AGENTS.md 写明 .env 字段含义 #P1
- [ ] [0.12.0-SEC-A-004] 在 v0.11.0-ARCH-A-000 已有 bundle id 稳定性测试基础上，扩展为 cert identifier 双重断言：`codesign -d --identifier` 输出 == `Info.plist.CFBundleIdentifier` == `--identifier` 参数（防止 Developer ID 签名时 identifier 漂移导致 TCC 权限被清）#P1
- [ ] [0.12.0-SEC-A-005] `release.yml` 注释从 `unsigned and not notarized` 更新为实际签名 + notarize 步骤（继承自 v0.11.0-CI-A-004 #deferred）#P1
- [ ] [0.12.0-SEC-A-006] helper 脚本 `install-update.sh` 同步升级为 Developer ID 签名 + notarize：v0.11.0-ARCH-A-003 解除、v0.11.0-TOOL-A-002 ad-hoc 路径替换为 Developer ID 路径、v0.11.0-TOOL-A-001 跳过 spctl 改为强制 verify（`codesign --verify` + `spctl --assess --type execute`）#P1
- [ ] [0.12.0-SEC-A-001-test] 测试 `build-app.sh` 在 cert 缺失时给出清晰错误并退出非零，不静默 fallback 到 ad-hoc #P1
- [ ] [0.12.0-SEC-A-002-test] 测试 notarize 失败的 dmg 不被 release.yml 误发到 GitHub Release（CI 步骤必须等公证通过；mock notarytool 返回非零）#P1
- [ ] [0.12.0-SEC-A-004-test] 测试 cert identifier 一致性：脚本生成的 `.app` 实际签名的 identifier 与 Info.plist `CFBundleIdentifier` 完全匹配 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260630234135-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260630234135-utcp8-gpt5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 关于页面，把build dev改成yymmdd.hhmmss.<branchname>
> title的上对齐，不对，比如这里的关于，应该横向和红绿灯、收起菜单按钮对齐
> 收起菜单按钮没有移除

补充：

> header的标签（图1）现在有一个实心的遮罩，但道理应该是fadeout半透明的，参考Macos26最佳实践或者vibesiland（图2）

#### 完成工作

- 关于页 build 号随 `.app` 打包写入 bundle，格式为 `260630.234111.preferences-main` 这类。
- 右侧 header 改为半透明材质渐隐覆盖层，不再用实心遮罩硬切滚动内容。
- 右侧 header 位置更接近 titlebar 顶部行。
- 增加 sidebar toggle 隐藏兜底逻辑。

#### 更新的需求 ID

- 延续偏好设置 UI polish 相关需求；本轮未新增独立需求 ID。

#### 验证方式

- `cd quota-bar && swift build`：通过。
- `cd quota-bar && swift test`：通过，20 个测试全部通过。
- `make app`：通过，产物为 `quota-bar/build/20260630-234111-preferences-main/QuotaBar.app`。
- `/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' quota-bar/build/latest/QuotaBar.app/Contents/Info.plist`：输出 `260630.234111.preferences-main`。

#### 备注

- 若 macOS 26 某个系统 build 的 sidebar toggle accessibility 文案不同，仍可能需要补充匹配条件；当前策略避免按坐标遮盖，优先不破坏原生 sidebar 视觉。

### 20260630234321-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260630234321-utcp8-gpt5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 更新路径并打包

#### 完成工作

- 新构建产物：`quota-bar/build/20260630-234308/QuotaBar.app`
- 最新快捷入口：`quota-bar/build/latest/QuotaBar.app`
- `latest` 指向：`/Users/taobe/Projects/GitHub/Personal/quota-bar/worktree/sub-expiry/quota-bar/build/20260630-234308`

#### 更新的需求 ID

- 无。

#### 验证方式

- `./scripts/build-app.sh`：Build complete
- `readlink quota-bar/build/latest`：指向当前 worktree 的 `20260630-234308`
- `find quota-bar/build -maxdepth 3 -type d -name 'QuotaBar.app'`：找到新 `.app`

#### 备注

- 未提交。
