# ARCH-B：四层获取链路与 Provider 能力矩阵

- ID：`0.9.0-ARCH-B-000`。
- 类型：`ARCH`。
- 状态：进行中（原文同时包含已完成与未完成项）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`；标题路径：任务清单 / Phase - v0.9.0 - 持久化、来源索引与启动兜底 / ARCH-B：四层获取链路与 Provider 能力矩阵。
- 原稳定 ID：`0.9.0-ARCH-B-000`, `0.9.0-ARCH-B-001`, `0.9.0-ARCH-B-002`, `0.9.0-ARCH-B-003`, `0.9.0-ARCH-B-004`, `0.9.0-ARCH-B-005`, `0.9.0-ARCH-B-006`, `0.9.0-ARCH-B-007`, `0.9.0-ARCH-B-008`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.9.0-ARCH-B-000] 将获取体系拆为四层独立链路：Provider 获取、额度获取、过期日获取、档位/费用获取；四层分别维护来源索引、跳过规则、失败语义和 last-known-good 写入资格 #P1
- [ ] [0.9.0-ARCH-B-001] Provider 获取层支持 App Bundle、配置/凭证文件、CLI 命令、API Key/环境变量、浏览器登录痕迹等发现手段；刷新时先用上次成功手段复查已知 provider，成功则跳过其余发现手段，再跑完整发现链查找新增或丢失的 provider #P1
- [ ] [0.9.0-ARCH-B-002] 额度获取层支持配置文件读 token/API key 后调用 usage API、CLI 指令、HTTP API 指令、本地 RPC、浏览器 dashboard、手动 token/header、App 内 WebView 登录 session、最后可选自然语言问询；刷新时先用上次成功额度手段，失败后再按能力矩阵全量 fallback #P1
- [ ] [0.9.0-ARCH-B-003] 过期日获取层复用额度层的来源索引机制，但允许使用不同 endpoint、CLI 指令、DOM 抽取或账号页 API；过期日结果不得阻塞额度刷新，且必须标记来源可靠性 #P1
- [x] [0.9.0-ARCH-B-004] 为每个 Provider 定义四张能力矩阵，分别记录 Provider 获取、额度获取、过期日获取、档位/费用获取的可用节点、优先级、跳过条件、权限风险、交互成本、失败后 fallback 规则和是否允许写入快照 #P1
- [x] [0.9.0-ARCH-B-005] Provider 能力矩阵必须覆盖明确接入范围：Codex、Claude、Kimi、MiniMax、Antigravity、GLM/Z Code；不再登记“其他 provider”占位，新增 provider 必须先明确具体名称、安装/凭证/额度/过期日来源后再进入矩阵 #P1
- [ ] [0.9.0-ARCH-B-006] CLI/RPC 节点必须显式登记每个 provider 的命令、交互输入、输出格式和 parser；已验证命令与未验证猜测必须分开记录，未知命令不得执行 #P1
- [ ] [0.9.0-ARCH-B-007] Browser 节点必须显式登记每个 provider 的登录域名、cookie 名称、dashboard URL、HTTP 方法、必要 header、follow-up 请求、parser 和是否可能触发 Keychain/Full Disk Access；默认不扫描所有浏览器，优先使用来源索引或用户选择的浏览器/profile #P1
- [ ] [0.9.0-ARCH-B-008] 订阅状态归一化必须区分「可用」「已过期」「未订阅」「待配置」「抓取失败」「未安装」；只有可靠过期日距离当前时间在一个自然周内时显示已过期，超过一周或从未订阅显示未订阅 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
