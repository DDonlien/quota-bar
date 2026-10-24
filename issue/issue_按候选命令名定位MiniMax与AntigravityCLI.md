# 按候选命令名定位MiniMax与AntigravityCLI

- ID：`0.10.0-DATA-B-008`。
- 类型：`DATA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: AGY 真实 CLI 层 + Claude 额度修复 + 获取方案审计。
- 原稳定 ID：`0.10.0-DATA-B-006`, `0.10.0-DATA-B-007`, `0.10.0-DATA-B-008`, `0.10.0-DOC-A-001`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.10.0-DATA-B-006`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.10.0-DATA-B-008`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.10.0-DATA-B-006-DATA-agy-cli-claude-quota-fixes-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：sub/main: AGY 真实 CLI 层 + Claude 额度修复 + 获取方案审计。
- 同源任务：[通过临时agy会话读取Antigravity额度](issue_%E9%80%9A%E8%BF%87%E4%B8%B4%E6%97%B6agy%E4%BC%9A%E8%AF%9D%E8%AF%BB%E5%8F%96Antigravity%E9%A2%9D%E5%BA%A6.md)、[按真实响应解析Claude五小时与周额度](issue_%E6%8C%89%E7%9C%9F%E5%AE%9E%E5%93%8D%E5%BA%94%E8%A7%A3%E6%9E%90Claude%E4%BA%94%E5%B0%8F%E6%97%B6%E4%B8%8E%E5%91%A8%E9%A2%9D%E5%BA%A6.md)、[核对README获取矩阵的来源优先级](issue_%E6%A0%B8%E5%AF%B9README%E8%8E%B7%E5%8F%96%E7%9F%A9%E9%98%B5%E7%9A%84%E6%9D%A5%E6%BA%90%E4%BC%98%E5%85%88%E7%BA%A7.md)。

## 当前需求与范围

共同范围与完整历史见[通过临时agy会话读取Antigravity额度](issue_%E9%80%9A%E8%BF%87%E4%B8%B4%E6%97%B6agy%E4%BC%9A%E8%AF%9D%E8%AF%BB%E5%8F%96Antigravity%E9%A2%9D%E5%BA%A6.md)；本文件保留以下独立目标的原文。

- [x] [0.10.0-DATA-B-008] CLI 命令探测支持**候选命令名列表**（`ProviderKind.cliCommands`）：MiniMax 实际命令是 `mmx`（旧 `minimax` 保留兼容）、Antigravity 实际命令是 `agy`（旧 `antigravity` 保留兼容），候选同类同优先级、命中即止；`InstallDetectorProvider.findCommand` 增加 Homebrew / `~/.local/bin` 等候选目录直查（GUI app 的 launchd PATH 不含这些路径，此前 `which` 单独查找会失败）#P0

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

原迁移条目的历史Comments完整保留于[同源历史](issue_%E9%80%9A%E8%BF%87%E4%B8%B4%E6%97%B6agy%E4%BC%9A%E8%AF%9D%E8%AF%BB%E5%8F%96Antigravity%E9%A2%9D%E5%BA%A6.md#comments)，不从历史日志新增完成标记。

### 2026-10-24 07:03:43 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
