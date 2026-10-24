# 通过security命令读取ClaudeKeychain凭证

- ID：`0.10.0-BUG-A-007`。
- 类型：`ARCH`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 对照参考项目源码，Claude Keychain 读取改走 `security` CLI。
- 原稳定 ID：`0.10.0-BUG-A-007`, `0.10.0-ARCH-H-000`, `0.10.0-ARCH-H-000-test`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户直接问"你发的 4 个开源项目是怎么获得 claude 额度的"，要求对照 CodexBar / ClaudeBar / Claude-Usage-Tracker / ping-island 的真实源码，而不是继续靠猜。读了 CodexBar 的 `docs/KEYCHAIN_FIX.md` 和 `ClaudeOAuthCredentials.swift`、ClaudeBar 的 `ClaudeCredentialLoader.swift`，找到了此前 0.10.0-INVESTIGATE-A-000 一直没验证到的具体可执行修复。

- [x] [0.10.0-BUG-A-007] `ClaudeKeychainCredentialsReader.readCredentialsJSON()` 从直接调 `SecItemCopyMatching`（`kSecMatchLimitAll` + `kSecReturnData` + `kSecReturnAttributes` 一次性查询）改为 `Process` 调 `/usr/bin/security find-generic-password -s "Claude Code-credentials" -w`，参考 ClaudeBar 的真实实现（`ClaudeCredentialLoader.loadFromKeychain`）。关键原因：`/usr/bin/security` 是 CDHash 永不变的 Apple 签名系统二进制，用户「始终允许」的信任记在它的身份上，不受本项目 ad-hoc 签名（`--sign -`）每次重新构建后 CDHash 变化的影响——而直接调 Security.framework 时信任是记在自己 App 的签名身份上的，这正是 0.10.0-INVESTIGATE-A-000 排查时怀疑的根因。CodexBar 的 `docs/KEYCHAIN_FIX.md` 也独立佐证了"不同查询形状 macOS 分别记忆授权"这一点（它们用了另一种解法：把 metadata-only 查询和单条 secret-data 查询拆成两次不同形状的调用）#P0
- [x] [0.10.0-ARCH-H-000] `ClaudeOAuthUsageProvider` 新增 `keychainReader` 注入点（默认走真实 `readCredentialsJSON`），修复了顺手改动暴露的测试隔离问题：原来两个"应该抛 missingCredentials"的测试因为直接调用真实 Keychain 读取，在已登录 Claude Code 的开发机上会意外读到真实凭证、进而对 `api.anthropic.com` 发起真实网络请求；现在测试显式注入返回 nil 的 reader #P0
- [x] [0.10.0-ARCH-H-000-test] 新增 `ClaudeKeychainCredentialsReaderTests`：验证对一个真实不存在的占位 service 名调用 `readViaSecurityCLI` 返回 nil（跨机器确定性成立，不依赖开发机是否登录过 Claude）#P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
