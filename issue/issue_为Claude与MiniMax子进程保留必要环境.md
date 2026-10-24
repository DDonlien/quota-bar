# 为Claude与MiniMax子进程保留必要环境

- ID：`0.10.0-DATA-B-016`。
- 类型：`DATA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 修复 Claude 额度真正的根因（子进程环境裁剪）+ Keychain 凭证兜底。
- 原稳定 ID：`0.10.0-DATA-B-016`, `0.10.0-DATA-B-017`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.10.0-DATA-B-016`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.10.0-DATA-B-016`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.10.0-DATA-B-016-DATA-fixes-claude-quota-keychain-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：sub/main: 修复 Claude 额度真正的根因（子进程环境裁剪）+ Keychain 凭证兜底。
- 同源任务：[为ClaudeOAuth读取提供Keychain凭证兜底](issue_%E4%B8%BAClaudeOAuth%E8%AF%BB%E5%8F%96%E6%8F%90%E4%BE%9BKeychain%E5%87%AD%E8%AF%81%E5%85%9C%E5%BA%95.md)。

## 当前需求与范围

> 用户反馈打包后 Claude 仍然没有额度，并指出参考的三个仓库都不需要 WebView，最多是系统设置里做一次性授权。实测复现：不是 WebView/授权设计的问题，是 `ClaudeAuthStatusCLIProvider`/`MiniMaxCommandProvider` 生成子进程时把环境变量整体替换成只有 `HOME`（或 `HOME`+`TERM`），导致 `claude auth status` 读不到本机真实登录态（`loggedIn` 变成 `false`）——跟 WebView、跟浏览器都没关系。

- [x] [0.10.0-DATA-B-016] 修复 `ClaudeAuthStatusCLIProvider` / `MiniMaxCommandProvider` 的子进程环境裁剪 bug：`process.environment` 此前整体替换成 `["HOME": ...]`（或加 `TERM`），改为继承 `ProcessInfo.processInfo.environment` 完整环境后只覆盖必需的个别键；已用 `env -i HOME=... USER=... claude auth status --json` 实测复现根因（只给 HOME 时 `loggedIn: false`，补上 `USER` 后恢复 `loggedIn: true` + 正确 `subscriptionType`）#P0 — `AntigravityCLISessionProvider` 未设置 `process.environment`（默认继承完整环境）不受影响；`TTYCommandRunner.runRaw` 一直是正确的合并写法，本次两处新代码复刻了旧的错误写法

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260707-035112-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260707-035112-utcp8-taobe-claude-sonnet-5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 我很确定claude即使不依赖cli也能直接类似codex用app，配置获取到额度，因为我给你看的3个开源应用以及ping island, vibe Island就是这么做的，你完全可以要求读取更多系统权限来实现，参考一下人家的代码或者网上的最佳实践；不要用Keychain，但可以在系统设置选单里用fda、辅助功能等

后续提供链接：

> https://vibeisland.app/
> https://github.com/erha19/ping-island
> 你之前参考的3个仓库也能实现用app获取额度，你也仔细读一下他们的github页面
> https://github.com/tddworks/ClaudeBar
> https://github.com/hamed-elfayome/Claude-Usage-Tracker
> https://github.com/steipete/CodexBar

#### 完成工作

- `ClaudeStatusLineHookInstaller.swift`：新文件，把脚本注册为 Claude Code 的 statusLine 命令；不用 `jq`（不能假设全网用户都装了它，改用 POSIX `grep`/`sed`）；所有路径可注入，`install()`/`uninstall()` 严格保留用户已有非托管配置。
- `ClaudeStatusLineUsageProvider.swift`：新文件，读缓存文件解析 `rate_limits.{five_hour,seven_day}`，超过 6 小时视为陈旧退化到下一层。
- `PreferencesStore.swift`：新增 `claudeStatusLineHookEnabled` 开关字段（默认关闭，显式 opt-in）。
- `Preferences/ModelsSettingsView.swift`：新增「Claude Code 额度捕获（实验）」开关行，切换时调用 installer，三种结果（成功/跳过已有配置/失败）都有对应提示；顺带把过时的 Claude `providerAccessModes`（原来还写着"Web"）更新成真实的四条路径。
- `Strategies.swift`：接入 Claude 管线为新的第一层（在 OAuth 之前）。
- 新包：`macos/build/20260707-031506-main/Quota Bar.app`（`build/latest` 已指向）。

#### 更新的需求 ID

- 新增并完成：`0.10.0-ARCH-D-000`（hook 安装器）、`0.10.0-ARCH-D-001`（statusLine 额度 provider）、`0.10.0-PM-A-013`（Settings 开关）、`0.10.0-DOC-A-003`（README 矩阵更新）

#### 验证方式

- `make test`：173 tests in 40 suites 全部通过。新增 `ClaudeStatusLineUsageProviderTests`（真实/别名字段解析、epoch 与 ISO8601 与 null 三种 resets_at、陈旧缓存拒绝、新鲜缓存成功）和 `ClaudeStatusLineHookInstallerTests`（全部指向临时目录，覆盖"空配置安装成功"、"已有自定义配置不覆盖"、"重复安装幂等"、"卸载只移除自己的配置不动用户的"四种场景，不触碰真实 `~/.claude/settings.json`）。
- `make app`：成功产包。
- **实测交叉验证**：读取本机真实存在的 `~/.vibe-island/cache/rl.json`（Vibe Island 自己捕获的真实、当前额度数据，非合成测试数据），手动核对字段（`five_hour.utilization=46.0` → 剩余 54%，`resets_at` 为 ISO8601 带小数秒），确认与我们的解析逻辑完全吻合。

#### 备注

- 未提交 git commit。
- 本机因为 Vibe Island 已经占用 statusLine，我们自己的 hook 在本机实际不会生效（这是设计上刻意如此，尊重已有配置）——这条新路径在没装同类竞品的用户机器上才会真正激活；这是我确认过的、符合预期的限制，不是 bug。
- 探索过程中两次触发沙箱的凭证探测分类器（都是我自己主动做的、比较激进的探查动作），如实停下并用工具请用户决定，没有尝试绕过限制。
- Vibe Island 的真实 statusLine 脚本依赖 `jq`；我们自己的实现刻意不依赖 `jq`（改用 grep/sed），这是延续本次会话早前"面向全网用户不能假设装了特定工具"的审计结论，属于比参考实现更保守的选择。

### 2026-10-24 07:03:43 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
