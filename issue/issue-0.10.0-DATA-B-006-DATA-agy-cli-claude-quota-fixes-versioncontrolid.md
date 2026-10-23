# sub/main: AGY 真实 CLI 层 + Claude 额度修复 + 获取方案审计

- ID：`0.10.0-DATA-B-006`。
- 类型：`DATA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: AGY 真实 CLI 层 + Claude 额度修复 + 获取方案审计。
- 原稳定 ID：`0.10.0-DATA-B-006`, `0.10.0-DATA-B-007`, `0.10.0-DATA-B-008`, `0.10.0-DOC-A-001`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户用 `agy` 进入交互 CLI、`/usage` 查看额度演示了真实操作路径；同时反馈 Claude webview 授权后仍无额度；并指出 README 矩阵存在同列多个同优先级（Codex 两个 P2、GLM 两个 P2 两个 P3 等）的错误，要求全面审计矩阵与实现一致性。

- [x] [0.10.0-DATA-B-006] `AntigravityCLISessionProvider`：IDE / 已运行 agy 进程都不可用时，拉起临时 `agy` 交互会话（`/usr/bin/script` 提供 PTY）、复用其本地 RPC（委托 `AntigravityDashboardProvider(.cli)`）取结构化额度，成功或超时后立即终止会话；接入 antigravity 管线排在 `antigravity-cli` 之后、keychain 之前 #P0 — 不驱动 `/usage` TUI 文本解析（`agy --print "/usage"` 实测会被当自然语言 prompt 消耗额度，明确排除）
- [x] [0.10.0-DATA-B-007] `ClaudeDashboardParser` 改用真实响应形状：`five_hour`/`seven_day`/`seven_day_sonnet`/`seven_day_opus` 顶层字段（经 CodexBar `ClaudeWebAPIFetcher` 与 Claude-Usage-Tracker `ClaudeAPIService` 两个独立参考实现交叉验证），修复此前只认 `usage`/`limits` wrapper key、对真实响应恒返回空数组的 bug；`usageURL(from:)` 增加多 org 优先级（chat 能力 > 非 api-only > 第一个）避免选中纯计费 org #P0 — 根因确认：Claude 一直没额度不是弹窗/授权问题，是 parser 形状写错
- [x] [0.10.0-DATA-B-008] CLI 命令探测支持**候选命令名列表**（`ProviderKind.cliCommands`）：MiniMax 实际命令是 `mmx`（旧 `minimax` 保留兼容）、Antigravity 实际命令是 `agy`（旧 `antigravity` 保留兼容），候选同类同优先级、命中即止；`InstallDetectorProvider.findCommand` 增加 Homebrew / `~/.local/bin` 等候选目录直查（GUI app 的 launchd PATH 不含这些路径，此前 `which` 单独查找会失败）#P0
- [x] [0.10.0-DOC-A-001] README 四张矩阵表全面审计重写：统一「同列内优先级唯一、同格内多个同类文件/命令共享格优先级」规则，修复 Codex 两个 P2、GLM 两个 P2 两个 P3 等冲突；Provider 获取表改为反映实际统一探测顺序（凭证文件 → App Bundle → CLI → 环境变量）；额度/过期日/档位表按当前实现逐格核对（Kimi GetSubscription、MiniMax mmx 已验证、Codex accounts/check P1、Claude 待验证标记等）#P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
