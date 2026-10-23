# DATA-C：新 Provider 接入通用流程

- ID：`0.4.0-DATA-C-000`。
- 类型：`DATA`。
- 状态：待定 / 延后（沿用原需求记录）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `b550269a253e390d19ec221949fb30c44adf9e9e`；标题路径：任务清单 / Phase - v0.4.0 - 新 Provider 接入（zcode / 千问 / 其他） / DATA-C：新 Provider 接入通用流程。
- 原稳定 ID：`0.4.0-DATA-C-000`, `0.4.0-DATA-C-001`, `0.4.0-DATA-C-002`, `0.4.0-DATA-C-003`, `0.4.0-DATA-C-004`, `0.4.0-DATA-C-005`, `0.4.0-DATA-C-006`, `0.4.0-DATA-C-007`, `0.4.0-DATA-C-008`, `0.4.0-DATA-C-009`, `0.4.0-DATA-C-010`, `0.4.0-DATA-C-011`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [ ] [0.4.0-DATA-C-000] 文档化新 Provider 接入流程（`AGENTS.md` 或 `quota-bar/AGENTS.md`）：从「确认安装位置 → 找 dashboard API → 写 parser → 接入 pipeline → UI 验证」5 步模板，供后续 Provider 接入参考 #P2
- [ ] [0.4.0-DATA-C-001] Cursor 订阅/额度获取：确认 Cursor dashboard 或本地账号缓存来源，接入 parser 与 pipeline #P2
- [ ] [0.4.0-DATA-C-002] OpenAI Platform 订阅/额度获取：确认 API key / billing dashboard 可用来源，接入 parser 与 pipeline #P2
- [ ] [0.4.0-DATA-C-003] DeepSeek 订阅/额度获取：确认 dashboard endpoint / API key 用量接口，接入 parser 与 pipeline #P2
- [ ] [0.4.0-DATA-C-004] GitHub Copilot 订阅/额度获取：确认 GitHub token / Copilot dashboard 可用来源，接入 parser 与 pipeline #P2
- [ ] [0.4.0-DATA-C-005] OpenRouter 订阅/额度获取：确认 OpenRouter credits / usage API，接入 parser 与 pipeline #P2
- [ ] [0.4.0-DATA-C-006] Perplexity 订阅/额度获取：确认账号订阅状态和额度来源，接入 parser 与 pipeline #P2
- [ ] [0.4.0-DATA-C-007] Warp 订阅/额度获取：确认本地账号缓存或 dashboard 来源，接入 parser 与 pipeline #P2
- [ ] [0.4.0-DATA-C-008] Trae 订阅/额度获取：确认 Trae / Trae Work dashboard 或本地接口来源，接入 parser 与 pipeline #P2
- [ ] [0.4.0-DATA-C-009] Antigravity 订阅/额度获取：继续完善本地 dashboard probe，确认到期日/最后有效日和订阅组语义 #P2
- [ ] [0.4.0-DATA-C-010] Gemini 遗留订阅/额度获取策略：若用户仍需要 Google Gemini 独立展示，明确与 Antigravity 的边界后再接入 #P2 #deferred
- [ ] [0.4.0-DATA-C-011] GLM / 智谱 BigModel 订阅/额度获取：确认 BigModel / ChatGLM dashboard、API key 或本地配置来源，接入 parser 与 pipeline #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
