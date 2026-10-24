# 凭证缺失时继续尝试后续额度来源

- ID：`0.2.0-DATA-B-019`。
- 类型：`DATA`。
- 状态：进行中（原文同时包含已完成与未完成项）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`；标题路径：任务清单 / Phase - v0.2.0 - Quota Bar 核心功能 / DATA-B：订阅数据获取。
- 原稳定 ID：`0.2.0-DATA-B-000`, `0.2.0-DATA-B-001`, `0.2.0-DATA-B-002`, `0.2.0-DATA-B-003`, `0.2.0-DATA-B-004`, `0.2.0-DATA-B-005`, `0.2.0-DATA-B-009`, `0.2.0-DATA-B-010`, `0.2.0-DATA-B-011`, `0.2.0-DATA-B-012`, `0.2.0-DATA-B-013`, `0.2.0-DATA-B-006`, `0.2.0-DATA-B-007`, `0.2.0-DATA-B-008`, `0.2.0-DATA-B-014`, `0.2.0-DATA-B-015`, `0.2.0-DATA-B-016`, `0.2.0-DATA-B-017`, `0.2.0-DATA-B-018`, `0.2.0-DATA-B-019`, `0.2.0-DATA-B-020`, `0.2.0-DATA-B-021`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.2.0-DATA-B-000`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.2.0-DATA-B-019`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.2.0-DATA-B-000-DATA-subscription-data-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：DATA-B：订阅数据获取。
- 同源任务：[建立真实订阅额度的多来源获取与失败降级](issue_%E5%BB%BA%E7%AB%8B%E7%9C%9F%E5%AE%9E%E8%AE%A2%E9%98%85%E9%A2%9D%E5%BA%A6%E7%9A%84%E5%A4%9A%E6%9D%A5%E6%BA%90%E8%8E%B7%E5%8F%96%E4%B8%8E%E5%A4%B1%E8%B4%A5%E9%99%8D%E7%BA%A7.md)、[仅按真实订阅档位映射价格](issue_%E4%BB%85%E6%8C%89%E7%9C%9F%E5%AE%9E%E8%AE%A2%E9%98%85%E6%A1%A3%E4%BD%8D%E6%98%A0%E5%B0%84%E4%BB%B7%E6%A0%BC.md)、[按系统地区换算订阅价格币种](issue_%E6%8C%89%E7%B3%BB%E7%BB%9F%E5%9C%B0%E5%8C%BA%E6%8D%A2%E7%AE%97%E8%AE%A2%E9%98%85%E4%BB%B7%E6%A0%BC%E5%B8%81%E7%A7%8D.md)、[通过OAuth与Web接口获取Kimi额度](issue_%E9%80%9A%E8%BF%87OAuth%E4%B8%8EWeb%E6%8E%A5%E5%8F%A3%E8%8E%B7%E5%8F%96Kimi%E9%A2%9D%E5%BA%A6.md)、[展示已安装但尚未接入Dashboard的应用](issue_%E5%B1%95%E7%A4%BA%E5%B7%B2%E5%AE%89%E8%A3%85%E4%BD%86%E5%B0%9A%E6%9C%AA%E6%8E%A5%E5%85%A5Dashboard%E7%9A%84%E5%BA%94%E7%94%A8.md)、[接入Claude组织与usage接口解析额度](issue_%E6%8E%A5%E5%85%A5Claude%E7%BB%84%E7%BB%87%E4%B8%8Eusage%E6%8E%A5%E5%8F%A3%E8%A7%A3%E6%9E%90%E9%A2%9D%E5%BA%A6.md)、[由Antigravity接替Gemini主动额度采集](issue_%E7%94%B1Antigravity%E6%8E%A5%E6%9B%BFGemini%E4%B8%BB%E5%8A%A8%E9%A2%9D%E5%BA%A6%E9%87%87%E9%9B%86.md)、[支持选择Cookie来源浏览器](issue_%E6%94%AF%E6%8C%81%E9%80%89%E6%8B%A9Cookie%E6%9D%A5%E6%BA%90%E6%B5%8F%E8%A7%88%E5%99%A8.md)、[通过Web接口获取MiniMax额度与套餐费用](issue_%E9%80%9A%E8%BF%87Web%E6%8E%A5%E5%8F%A3%E8%8E%B7%E5%8F%96MiniMax%E9%A2%9D%E5%BA%A6%E4%B8%8E%E5%A5%97%E9%A4%90%E8%B4%B9%E7%94%A8.md)、[通过本地服务获取Antigravity额度](issue_%E9%80%9A%E8%BF%87%E6%9C%AC%E5%9C%B0%E6%9C%8D%E5%8A%A1%E8%8E%B7%E5%8F%96Antigravity%E9%A2%9D%E5%BA%A6.md)、[支持同一服务的多身份订阅](issue_%E6%94%AF%E6%8C%81%E5%90%8C%E4%B8%80%E6%9C%8D%E5%8A%A1%E7%9A%84%E5%A4%9A%E8%BA%AB%E4%BB%BD%E8%AE%A2%E9%98%85.md)、[调研TraeWork独立Provider接入](issue_%E8%B0%83%E7%A0%94TraeWork%E7%8B%AC%E7%AB%8BProvider%E6%8E%A5%E5%85%A5.md)。

## 当前需求与范围

共同范围与完整历史见[建立真实订阅额度的多来源获取与失败降级](issue_%E5%BB%BA%E7%AB%8B%E7%9C%9F%E5%AE%9E%E8%AE%A2%E9%98%85%E9%A2%9D%E5%BA%A6%E7%9A%84%E5%A4%9A%E6%9D%A5%E6%BA%90%E8%8E%B7%E5%8F%96%E4%B8%8E%E5%A4%B1%E8%B4%A5%E9%99%8D%E7%BA%A7.md)；本文件保留以下独立目标的原文。

- [x] [0.2.0-DATA-B-019] Provider pipeline 在首个数据源缺凭证时继续尝试后续数据源，避免 MiniMax/Kimi/Codex 因 API key 或 OAuth 缺失而跳过 Cookie/CLI fallback #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

原迁移条目的历史Comments完整保留于[同源历史](issue_%E5%BB%BA%E7%AB%8B%E7%9C%9F%E5%AE%9E%E8%AE%A2%E9%98%85%E9%A2%9D%E5%BA%A6%E7%9A%84%E5%A4%9A%E6%9D%A5%E6%BA%90%E8%8E%B7%E5%8F%96%E4%B8%8E%E5%A4%B1%E8%B4%A5%E9%99%8D%E7%BA%A7.md#comments)，不从历史日志新增完成标记。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
