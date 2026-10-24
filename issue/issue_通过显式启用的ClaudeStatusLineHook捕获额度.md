# 通过显式启用的ClaudeStatusLineHook捕获额度

- ID：`0.10.0-ARCH-D-000`。
- 类型：`ARCH`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: Claude statusLine hook 额度捕获（不依赖 Keychain 的 app 化方案）。
- 原稳定 ID：`0.10.0-ARCH-D-000`, `0.10.0-ARCH-D-001`, `0.10.0-PM-A-013`, `0.10.0-DOC-A-003`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户指出 3 个参考仓库 + 新提供的 ping-island、vibe island 都能"像 Codex 一样用 app/配置拿额度"，要求不用 Keychain，可以用 FDA/辅助功能等系统权限。查 ping-island 源码（`HookInstaller.swift`）发现真正机制：Claude Code CLI 的 `statusLine` hook 会把包含 `rate_limits` 的 JSON 喂给用户配置的 statusLine 命令——这是 Claude Code 自己的官方能力，不需要 OAuth token、不需要 Keychain、不需要子进程。本机已安装的 Vibe Island（同类闭源商用 App，`~/.vibe-island/bin/vibe-island-statusline`）用完全相同的手法验证了这一机制真实有效。

- [x] [0.10.0-ARCH-D-000] `ClaudeStatusLineHookInstaller`：把一个极小脚本（不依赖 `jq`，只用 POSIX `grep`/`sed`）注册为 `~/.claude/settings.json` 的 `statusLine.command`，捕获 Claude Code 自己渲染终端状态栏时携带的 payload（含 `rate_limits`）到本地缓存文件；若用户已有非本安装器写入的 statusLine 配置则不覆盖、返回 `.skippedExistingStatusLine`（与 ping-island `isManagedStatusLine` 逻辑一致）；提供 `install()`/`uninstall()`，路径全部可注入以便测试不触碰真实文件 #P0
- [x] [0.10.0-ARCH-D-001] `ClaudeStatusLineUsageProvider`：读取上述缓存文件，解析 `rate_limits.{five_hour,seven_day}`（`used_percentage`/`utilization` 同义字段，`resets_at` 支持 epoch 数字/ISO8601/缺失三种形态，字段形状经 ping-island 测试夹具与本机 Vibe Island 真实缓存 `~/.vibe-island/cache/rl.json` 双重交叉验证）；缓存超过 6 小时视为陈旧，退化到下一层（配置文件/Keychain → API），不展示过期数字 #P0 — 接入 Claude 管线为新 P1（在 OAuth 之前），零权限、零子进程，是本次「不用 Keychain、app 自己能拿到」诉求里唯一完全不涉及 Keychain 的路径
- [x] [0.10.0-PM-A-013] 「模型」偏好页新增「Claude Code 额度捕获（实验）」开关（`PreferencesStore.claudeStatusLineHookEnabled`），显式 opt-in 才会修改用户的 `~/.claude/settings.json`；开启成功/跳过（已有自定义 statusLine）/失败三种结果都有对应提示文案；关闭时只移除本安装器写入的 statusLine 引用，不动用户自己的配置 #P1
- [x] [0.10.0-DOC-A-003] README 额度获取表新增「本地 hook 缓存（Claude 专属）」行，标注为 Claude 新的默认 P1（原配置/凭证 → API 降为 P2，App WebView 会话降为 P3），注明经 ping-island 源码与本机 Vibe Island 真实缓存交叉验证 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 2026-10-24 07:03:43 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
