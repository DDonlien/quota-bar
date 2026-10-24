# 为ClaudeCLI档位结果补齐本地价格

- ID：`0.10.0-BUG-A-003`。
- 类型：`UI`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 日志上线首日实测反馈——排序 bug、Claude 价格 bug、dropdown 待配置态显示规则。
- 原稳定 ID：`0.10.0-BUG-A-002`, `0.10.0-BUG-A-003`, `0.10.0-UI-B-002`, `0.10.0-UI-B-003`, `0.10.0-PM-A-015`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.10.0-BUG-A-002`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.10.0-BUG-A-003`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.10.0-BUG-A-002-UI-sorting-bug-claude-dropdown-configuration-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：sub/main: 日志上线首日实测反馈——排序 bug、Claude 价格 bug、dropdown 待配置态显示规则。
- 同源任务：[保持FetchPipeline声明的来源优先顺序](issue_%E4%BF%9D%E6%8C%81FetchPipeline%E5%A3%B0%E6%98%8E%E7%9A%84%E6%9D%A5%E6%BA%90%E4%BC%98%E5%85%88%E9%A1%BA%E5%BA%8F.md)、[统一未配置与未订阅状态的面板提示](issue_%E7%BB%9F%E4%B8%80%E6%9C%AA%E9%85%8D%E7%BD%AE%E4%B8%8E%E6%9C%AA%E8%AE%A2%E9%98%85%E7%8A%B6%E6%80%81%E7%9A%84%E9%9D%A2%E6%9D%BF%E6%8F%90%E7%A4%BA.md)、[将获取日志偏好页标签简化为日志](issue_%E5%B0%86%E8%8E%B7%E5%8F%96%E6%97%A5%E5%BF%97%E5%81%8F%E5%A5%BD%E9%A1%B5%E6%A0%87%E7%AD%BE%E7%AE%80%E5%8C%96%E4%B8%BA%E6%97%A5%E5%BF%97.md)。

## 当前需求与范围

共同范围与完整历史见[保持FetchPipeline声明的来源优先顺序](issue_%E4%BF%9D%E6%8C%81FetchPipeline%E5%A3%B0%E6%98%8E%E7%9A%84%E6%9D%A5%E6%BA%90%E4%BC%98%E5%85%88%E9%A1%BA%E5%BA%8F.md)；本文件保留以下独立目标的原文。

- [x] [0.10.0-BUG-A-003] `ClaudeAuthStatusCLIProvider.parseStatusOutput` 补上 `ProviderPricing.localizedMonthlyPrice(kind: .claude, tier:)` 调用：此前硬编码 `monthlyPrice: nil`，导致只靠这条 CLI 兜底层拿到档位（如 "Pro"）的用户永远看不到价格，即使 `ProviderPricing` 里已经有 `(.claude, "pro") → $20` 的映射。价格是从档位名字查静态公开定价表，不是"伪造额度"，跟这里保持为空的 quotas 是两回事 #P0

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

原迁移条目的历史Comments完整保留于[同源历史](issue_%E4%BF%9D%E6%8C%81FetchPipeline%E5%A3%B0%E6%98%8E%E7%9A%84%E6%9D%A5%E6%BA%90%E4%BC%98%E5%85%88%E9%A1%BA%E5%BA%8F.md#comments)，不从历史日志新增完成标记。

### 2026-10-24 07:03:43 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
