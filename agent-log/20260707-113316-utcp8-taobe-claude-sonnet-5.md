# 用户原始 prompt

> 我发你的4个开源项目是怎么获得claude额度的

# 启动运行时的分支和版本

- 分支：`main`
- 版本：`1bba4e3` + 此前十一次会话的未提交改动（本次是第十二次）

# 任务开始时间

2026-07-07 约 11:22 +0800

# 任务结束时间

2026-07-07 11:33 +0800

# 任务结束时是否执行了提交

未提交（累计十二次会话改动都在工作区，等用户 review）。

# 已阅读上下文

- 上一轮排查 Claude Keychain 读取失败到"代码走读没发现 bug、最可能是 ad-hoc 签名 CDHash 不稳定"就停在了猜测阶段，标记 `#blocked`。
- 用户这次直接要求对照真正的参考项目源码，而不是继续靠猜。

# 对话与行动记录

用 `gh api` 搜了用户之前给过的 4 个参考仓库（CodexBar、ClaudeBar、Claude-Usage-Tracker、ping-island）里跟 `"Claude Code-credentials"` 相关的文件，直接命中两份关键材料：

**CodexBar 的 `docs/KEYCHAIN_FIX.md`**：这是它们自己维护的一份"当前 Keychain 行为"说明文档，里面直接写明了这类第三方 Keychain 条目访问的真实坑：查询按"是否要 `kSecReturnData`""是否 `kSecMatchLimitAll`"这些形状分别被 macOS 记忆授权，同一个"始终允许"点击不一定覆盖所有查询形状。他们的解法是把查询拆成两段——先用不带 `kSecReturnData` 的 metadata-only 查询（非交互）挑出最新一条，再针对这一条单独发起"读密钥数据"的查询（这个才允许弹窗）。我们原来的实现是把 `kSecMatchLimitAll` + `kSecReturnData` + `kSecReturnAttributes` 全揉在一次查询里——跟 CodexBar 文档里描述的"容易读不到"的形状高度吻合。

**ClaudeBar 的 `ClaudeCredentialLoader.swift`**：更直接——它压根不用 `Security.framework`，直接 `Process` 调 `/usr/bin/security find-generic-password -s "Claude Code-credentials" -w`。这个做法解决的是本项目当前更本质的问题：`/usr/bin/security` 是 Apple 签名、CDHash 永远不变的系统二进制；用户点一次「始终允许」，这份信任记在 `/usr/bin/security` 的身份上，不受调用它的父进程是谁影响。而直接在自己进程里调 `SecItemCopyMatching`，信任是记在自己 App 的代码签名身份上的——本项目目前是 ad-hoc 签名（`build-app.sh` 的 `--sign -`），每次重新构建二进制 CDHash 都会变，这份信任大概率没法跨构建持久化，这正是上一轮排查时怀疑但没能验证的根因。

两份材料相互印证，指向同一个可执行的具体修复：把 `ClaudeKeychainCredentialsReader.readCredentialsJSON()` 从直接调 `SecItemCopyMatching` 改成 shell 出 `/usr/bin/security` CLI，采用 ClaudeBar 验证过的真实做法（比 CodexBar 那套"两段式 Security.framework + 大量 prompt cooldown/preflight 状态管理"更简单，且更直接绕开了本项目当前 ad-hoc 签名的不稳定性，不需要等 v0.12.0 Developer ID 签名才能生效）。

改完后跑测试暴露了一个真实的连带问题：两个原本"应该抛 `missingCredentials`"的测试，因为直接调用真实 Keychain 读取，在这台已经登录过 Claude Code 的开发机上意外读到了真实凭证，转而对 `api.anthropic.com` 发起了真实网络请求，导致测试失败。这其实是测试隔离设计的缺口被新实现放大了——原来的 Security.framework 版本在 CI/沙箱环境里大概率本来就读不到东西所以"侥幸"没暴露这个问题，现在换成真实可用的 `security` CLI 反而在开发机上"生效"了，把潜在的测试隔离问题带到了台面上。加了一个 `keychainReader` 注入点修复。

# 完成工作

- `ClaudeOAuthUsageProvider.swift`：`ClaudeKeychainCredentialsReader.readCredentialsJSON()` 重写为 `Process` 调 `/usr/bin/security find-generic-password -w`；抽出 `readViaSecurityCLI(service:)` 便于测试注入不存在的占位 service 名；`ClaudeOAuthUsageProvider` 新增 `keychainReader` 构造参数（默认走真实实现）；`loadCredentials()` 改为 `async`。
- `Tests/QuotaBarTests/ClaudeOAuthUsageProviderTests.swift`：两个原本会意外读到真实 Keychain 数据的测试改为注入 `keychainReader: { nil }`；新增 `ClaudeKeychainCredentialsReaderTests` 验证不存在的 service 返回 nil。
- 新包：`macos/build/20260707-113301-main/Quota Bar.app`（`build/latest` 已指向）。

# 更新的需求 ID

- `0.10.0-INVESTIGATE-A-000`：去掉 `#blocked` 标记（问题排查本身已完成，具体修复见下面新条目）。
- 新增并完成：`0.10.0-BUG-A-007`（Keychain 读取改走 security CLI）、`0.10.0-ARCH-H-000`（keychainReader 注入点 + 测试隔离修复）、`0.10.0-ARCH-H-000-test`（新增测试）。

# 更新的 README 或 DESIGN 章节

- `README.md`：原「已知问题：ad-hoc 签名可能导致第三方 Keychain 条目读取不稳定」小节改写为「Claude Keychain 读取：为什么改走 `/usr/bin/security` CLI」，完整记录 CodexBar 文档和 ClaudeBar 源码这两处交叉验证的发现，以及具体修复内容。

# 验证方式

- `swift build`：无警告无错误。
- `swift test`：179 tests in 42 suites 全部通过（含新增的 `ClaudeKeychainCredentialsReaderTests`，以及修复隔离问题后重新通过的两个 `missingCredentials` 测试）。
- `./scripts/build-app.sh`：产包成功。
- 未做真实 GUI 交互验证——这次的修复本身有没有彻底解决"Claude 额度获取"这个最终诉求，仍然需要用户在真实打包的 app 里实际观察是否还会弹出/正确处理系统 Keychain 授权对话框，这点在当前工具条件下做不到，如实告知。

# 备注

- 未提交 git commit。
- 这一轮是"用户直接要求对照参考实现"带来突破的典型例子：上一轮凭代码走读 + 猜测（ad-hoc 签名 CDHash 不稳定）已经把方向猜对了大半，但没有具体到"该怎么改"；读了 CodexBar 的内部文档和 ClaudeBar 的真实源码后，不仅证实了这个猜测，还直接给出了一个已经被验证过、更简单的具体解法（shell 出系统 `security` CLI），而不需要自己重新发明一套 CodexBar 那种复杂的两段式查询 + prompt 状态机。
- 顺手改动暴露并修复了一个真实的测试隔离缺口（测试意外依赖开发机真实 Keychain 状态、意外发起真实网络请求）——这类问题往往要等实现从"读不到东西"变成"真的能读到东西"才会暴露，这次算是提前在自己机器上发现并堵上了。
