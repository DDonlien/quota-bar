# sub/main: dropdown 全局规则纠正 + 日志页体验 + 日志内容可读性统一

- ID：`0.10.0-ARCH-G-000`。
- 类型：`UI`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: dropdown 全局规则纠正 + 日志页体验 + 日志内容可读性统一。
- 原稳定 ID：`0.10.0-UI-C-000`, `0.10.0-ARCH-G-000`, `0.10.0-BUG-A-005`, `0.10.0-UI-C-001`, `0.10.0-ARCH-G-001`, `0.10.0-ARCH-G-002`, `0.10.0-BUG-A-006`, `0.10.0-INVESTIGATE-A-000`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户截图指出一批具体问题：日志页清空后 ScrollView 收缩变窄；停留在日志页时新记录不会自动出现，要切一次 tab 才行；Claude 明明没拿到额度却是绿灯（状态灯全局规则错误）；灰色/蓝色 WebView 授权提示的下划线不统一；并贴了一段真实日志，指出 Kimi 的额度/档位两层看起来"交叉"、`kimi-desktop-token` 这类 MethodName 看不出属于哪一类来源、Z Code 额度层只跑了一次、以及追问 Claude 的 OAuth/Keychain 到底为什么读不到凭证。

- [x] [0.10.0-UI-C-000] `DiagnosticsSettingsView` 的日志 `ScrollView` 内容 `VStack` 加 `.frame(maxWidth: .infinity, alignment: .leading)`：清空后只剩一行短提示文字时，原来没有这个约束会让整个 ScrollView（进而整个设置页）收缩到刚好包住那行字的宽度 #P1
- [x] [0.10.0-ARCH-G-000] 新增 `Notification.Name.providerCheckLogDidChange`，`ProviderCheckLogStore.append`/`clear` 落盘后在主线程 post；`DiagnosticsSettingsView` 订阅它调用 `reload()`——停留在日志页时，刷新周期写入的新记录会实时出现，不用切一次 tab 才触发 `onAppear` 重新读取 #P1
- [x] [0.10.0-BUG-A-005] `ProviderSnapshot.statusColor` 的 `.available` 分支修复：`primarySubscriptionGroupWorstQuota` 为 nil（tier-only 兜底层成功、额度层还没拿到，如 Claude 常见的 CLI-only 状态）时，原来用 `?? 1.0` 兜底把"不知道剩多少"当成"剩 100%"画绿灯；改为这种情况下返回灰色"未知"灯，跟 loading/needsConfiguration 同一套语义 #P0
- [x] [0.10.0-UI-C-001] 统一 WebView 授权提示的下划线规则：header 里两处灰色引导（TierName 缺失 / 到期日缺失）保持下划线；`QuotaAuthPromptRow`（额度栏蓝色引导）去掉误加的 `.underline()`——颜色本身已经表明可点击，蓝色 + 下划线是重复强调，之前两者没统一 #P1
- [x] [0.10.0-ARCH-G-001] 诊断日志层输出顺序修正：`FetchPipeline.logAttempt` 原来用 `relevantLayers.sorted(by: { $0.rawValue < $1.rawValue })` 按字母序排（"plan" < "quota"），导致同一次成功调用先输出「档位与费用获取」再输出「额度获取」，跟额度层排 README 四层矩阵第 2 层、档位排第 4 层的既定顺序自相矛盾，看起来像"交叉"。改为固定用 `[.quota, .plan]` 显式顺序 #P0
- [x] [0.10.0-ARCH-G-002] 诊断日志 MethodName 统一：新增 `ProviderSourceKind.checkLogLabel`/`SubscriptionExpirySourceKind.checkLogLabel`，把 Provider 获取/额度获取/档位与费用获取/过期日获取四层的 MethodName 统一改成同一套分类词汇（"配置/凭证 → API"「CLI 命令」「本地 App / RPC」「App WebView 会话」「浏览器 Cookie」「Keychain」等，对应 README 五级来源排序的用词），不再直接用 `kimi-desktop-token` 这类单看名字猜不出类别的 strategy id 当 MethodName；具体 id 移到 `result` 里（格式："来源 <id>：<结果>"）#P0
- [x] [0.10.0-BUG-A-006] 修正 `QuotaProviderStrategy.sourceKind` 对 `"minimax-cli"` 的误分类：这个 id 是历史命名遗留，实际实现读 `~/.mmx/config.json` 的 API key 直调 `coding_plan/remains`，并不真的执行 `mmx` 命令（真正的 CLI 层是另一个 id `minimax-mmx-cli`），原来的 `id.contains("cli")` 通配会把它错分类成"CLI 命令"；新增日志用到 `checkLogLabel` 后这个误分类会直接暴露给用户，借这次统一顺手修掉 #P1
- [x] [0.10.0-INVESTIGATE-A-000] 排查 Claude OAuth/Keychain 凭证读取失败：用户机器上 `claude auth status --json`（CLI 层）能成功返回 `subscriptionType: pro`，说明本机确实登录有效；但 `ClaudeOAuthUsageProvider` 的文件路径（`~/.claude/.credentials.json` 不存在，已确认）和 Keychain 路径（`security find-generic-password -s "Claude Code-credentials"` 确认条目真实存在，service/account 与代码预期完全匹配）都读不到有效 accessToken。代码走读未发现查询逻辑本身的 bug。最可能的解释：`build-app.sh` 用 ad-hoc 签名（`--sign -`）+ 固定 `--identifier`重签，但 ad-hoc 签名本身在每次重新构建后 CDHash 会变化，可能导致 macOS 对 Keychain 第三方条目的"始终允许"信任判定无法跨构建持久化——与已知的 TCC/Accessibility 权限持久化问题（v0.12.0 Developer ID 签名规划）是同一根因类别 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
