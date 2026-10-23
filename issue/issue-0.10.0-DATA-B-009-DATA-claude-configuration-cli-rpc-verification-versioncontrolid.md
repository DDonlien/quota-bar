# sub/main: Claude 配置 / CLI / RPC 三项验证与实现

- ID：`0.10.0-DATA-B-009`。
- 类型：`DATA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: Claude 配置 / CLI / RPC 三项验证与实现。
- 原稳定 ID：`0.10.0-DATA-B-009`, `0.10.0-DATA-B-010`, `0.10.0-DATA-B-011`, `0.10.0-DATA-B-012`, `0.10.0-DOC-A-002`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户要求验证 README 里 Claude 的三处「待验证」（配置文件→API、CLI、本地 RPC），并提示可参考已下载的 CodexBar/ClaudeBar/Claude-Usage-Tracker 三个参考仓库交叉核实。核实后发现均可转为确定结论并直接实现，而不只是更新文档。

- [x] [0.10.0-DATA-B-009] `ClaudeOAuthUsageProvider`：读 `~/.claude/.credentials.json` 的 `claudeAiOauth.accessToken`/`subscriptionType`，直调 `GET https://api.anthropic.com/api/oauth/usage`（`anthropic-beta: oauth-2025-04-20`），响应字段与 web session 端点一致，复用抽出的 `ClaudeUsageWindowParser`；接入 Claude 管线为新 P1（配置文件 → API），排在 App WebView 会话之前，401→missingCredentials、429→transient #P0 — 端点/字段经 CodexBar `ClaudeOAuthUsageFetcher` 源码交叉验证，未接触本机 Keychain
- [x] [0.10.0-DATA-B-010] `ClaudeAuthStatusCLIProvider`：执行 `claude auth status --json`（实测确认非交互、结构化、无副作用），失败/未登录抛 `missingCredentials`；只贡献订阅档位（`subscriptionType`），不伪造额度；接入管线为 OAuth provider 之后的 CLI 层，供凭证文件缺失（如仅 Keychain 存储）时兜底档位 #P1
- [x] [0.10.0-DATA-B-011] 修正 `KeychainProvider` 对 Claude 的 service/account 猜测：`defaultKeychainService` 从虚构的 `"com.anthropic.claude"` 改为经 CodexBar 源码确认的真实 Keychain generic password service 名 `"Claude Code-credentials"`；`defaultKeychainAccount` 支持返回 `nil`（service-only 匹配，不再要求固定 account——Claude Code 写入的 account 属性是运行时动态值，无法硬编码）；`KeychainProvider`/`hasToken` 的 account 参数改为可选，其余 provider 行为不变 #P1
- [x] [0.10.0-DATA-B-012] `ProviderPricing` 新增 Claude Pro 价格映射（$20/月，官网公开价确认）；Max（5x/20x）等更高档位的 `subscriptionType` 字符串未经真实账号验证，不猜测映射 #P2
- [x] [0.10.0-DOC-A-002] README 额度/过期日/档位表按上述验证结果更新：Claude 配置→API 从「待验证」改为已验证 P1（含端点/字段说明）；本地 RPC 从「待验证」改为「跳过：已核实无本地 RPC 可用」（`claude gateway` 是企业 auth/telemetry 代理非用量接口）；CLI 命令行从「待验证」改为「跳过额度：已核实无结构化额度 CLI」+ 档位表新增 P3 `claude auth status`；过期日表「配置文件/token payload」从「待验证」改为「跳过：`expiresAt` 是 access token 有效期非订阅到期日」（与 Kimi OAuth 同类陷阱）；「CLI 指令」从「待验证」改为「跳过：已核实不返回到期日」#P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
