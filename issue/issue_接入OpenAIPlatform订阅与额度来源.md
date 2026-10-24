# 接入OpenAIPlatform订阅与额度来源

- ID：`0.4.0-DATA-C-002`。
- 类型：`DATA`。
- 状态：待定 / 延后（沿用原需求记录）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `b550269a253e390d19ec221949fb30c44adf9e9e`；标题路径：任务清单 / Phase - v0.4.0 - 新 Provider 接入（zcode / 千问 / 其他） / DATA-C：新 Provider 接入通用流程。
- 原稳定 ID：`0.4.0-DATA-C-000`, `0.4.0-DATA-C-001`, `0.4.0-DATA-C-002`, `0.4.0-DATA-C-003`, `0.4.0-DATA-C-004`, `0.4.0-DATA-C-005`, `0.4.0-DATA-C-006`, `0.4.0-DATA-C-007`, `0.4.0-DATA-C-008`, `0.4.0-DATA-C-009`, `0.4.0-DATA-C-010`, `0.4.0-DATA-C-011`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.4.0-DATA-C-000`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.4.0-DATA-C-002`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.4.0-DATA-C-000-DATA-provider-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：DATA-C：新 Provider 接入通用流程。
- 同源任务：[文档化新Provider接入流程](issue_%E6%96%87%E6%A1%A3%E5%8C%96%E6%96%B0Provider%E6%8E%A5%E5%85%A5%E6%B5%81%E7%A8%8B.md)、[接入Cursor订阅与额度来源](issue_%E6%8E%A5%E5%85%A5Cursor%E8%AE%A2%E9%98%85%E4%B8%8E%E9%A2%9D%E5%BA%A6%E6%9D%A5%E6%BA%90.md)、[接入DeepSeek订阅与额度来源](issue_%E6%8E%A5%E5%85%A5DeepSeek%E8%AE%A2%E9%98%85%E4%B8%8E%E9%A2%9D%E5%BA%A6%E6%9D%A5%E6%BA%90.md)、[接入GitHubCopilot订阅与额度来源](issue_%E6%8E%A5%E5%85%A5GitHubCopilot%E8%AE%A2%E9%98%85%E4%B8%8E%E9%A2%9D%E5%BA%A6%E6%9D%A5%E6%BA%90.md)、[接入OpenRouter余额与额度来源](issue_%E6%8E%A5%E5%85%A5OpenRouter%E4%BD%99%E9%A2%9D%E4%B8%8E%E9%A2%9D%E5%BA%A6%E6%9D%A5%E6%BA%90.md)、[接入Perplexity订阅与额度来源](issue_%E6%8E%A5%E5%85%A5Perplexity%E8%AE%A2%E9%98%85%E4%B8%8E%E9%A2%9D%E5%BA%A6%E6%9D%A5%E6%BA%90.md)、[接入Warp订阅与额度来源](issue_%E6%8E%A5%E5%85%A5Warp%E8%AE%A2%E9%98%85%E4%B8%8E%E9%A2%9D%E5%BA%A6%E6%9D%A5%E6%BA%90.md)、[接入Trae及TraeWork订阅与额度来源](issue_%E6%8E%A5%E5%85%A5Trae%E5%8F%8ATraeWork%E8%AE%A2%E9%98%85%E4%B8%8E%E9%A2%9D%E5%BA%A6%E6%9D%A5%E6%BA%90.md)、[完善Antigravity日期与订阅组语义](issue_%E5%AE%8C%E5%96%84Antigravity%E6%97%A5%E6%9C%9F%E4%B8%8E%E8%AE%A2%E9%98%85%E7%BB%84%E8%AF%AD%E4%B9%89.md)、[明确Gemini与Antigravity边界后接入独立额度](issue_%E6%98%8E%E7%A1%AEGemini%E4%B8%8EAntigravity%E8%BE%B9%E7%95%8C%E5%90%8E%E6%8E%A5%E5%85%A5%E7%8B%AC%E7%AB%8B%E9%A2%9D%E5%BA%A6.md)、[接入智谱BigModel与GLM订阅额度来源](issue_%E6%8E%A5%E5%85%A5%E6%99%BA%E8%B0%B1BigModel%E4%B8%8EGLM%E8%AE%A2%E9%98%85%E9%A2%9D%E5%BA%A6%E6%9D%A5%E6%BA%90.md)。

## 当前需求与范围

共同范围与完整历史见[文档化新Provider接入流程](issue_%E6%96%87%E6%A1%A3%E5%8C%96%E6%96%B0Provider%E6%8E%A5%E5%85%A5%E6%B5%81%E7%A8%8B.md)；本文件保留以下独立目标的原文。

- [ ] [0.4.0-DATA-C-002] OpenAI Platform 订阅/额度获取：确认 API key / billing dashboard 可用来源，接入 parser 与 pipeline #P2

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

原迁移条目的历史Comments完整保留于[同源历史](issue_%E6%96%87%E6%A1%A3%E5%8C%96%E6%96%B0Provider%E6%8E%A5%E5%85%A5%E6%B5%81%E7%A8%8B.md#comments)，不从历史日志新增完成标记。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
