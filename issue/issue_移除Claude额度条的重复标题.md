# 移除Claude额度条的重复标题

- ID：`0.10.0-BUG-A-008`。
- 类型：`ARCH`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 日志格式二次调整 + Claude 额度条标题统一 + 更新功能现状确认。
- 原稳定 ID：`0.10.0-ARCH-I-000`, `0.10.0-BUG-A-008`, `0.10.0-DOC-A-004`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.10.0-ARCH-I-000`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.10.0-BUG-A-008`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.10.0-ARCH-I-000-ARCH-claude-quota-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：sub/main: 日志格式二次调整 + Claude 额度条标题统一 + 更新功能现状确认。
- 同源任务：[以独立结果枚举与竖线格式记录诊断日志](issue_%E4%BB%A5%E7%8B%AC%E7%AB%8B%E7%BB%93%E6%9E%9C%E6%9E%9A%E4%B8%BE%E4%B8%8E%E7%AB%96%E7%BA%BF%E6%A0%BC%E5%BC%8F%E8%AE%B0%E5%BD%95%E8%AF%8A%E6%96%AD%E6%97%A5%E5%BF%97.md)、[核对真实GitHub仓库与DMG更新接入现状](issue_%E6%A0%B8%E5%AF%B9%E7%9C%9F%E5%AE%9EGitHub%E4%BB%93%E5%BA%93%E4%B8%8EDMG%E6%9B%B4%E6%96%B0%E6%8E%A5%E5%85%A5%E7%8E%B0%E7%8A%B6.md)。

## 当前需求与范围

共同范围与完整历史见[以独立结果枚举与竖线格式记录诊断日志](issue_%E4%BB%A5%E7%8B%AC%E7%AB%8B%E7%BB%93%E6%9E%9C%E6%9E%9A%E4%B8%BE%E4%B8%8E%E7%AB%96%E7%BA%BF%E6%A0%BC%E5%BC%8F%E8%AE%B0%E5%BD%95%E8%AF%8A%E6%96%AD%E6%97%A5%E5%BF%97.md)；本文件保留以下独立目标的原文。

- [x] [0.10.0-BUG-A-008] Claude 额度条标题统一：`ClaudeUsageWindowParser`（`DashboardEndpoints.swift`）和 `ClaudeStatusLineUsageProvider` 的 `five_hour`/`seven_day` 窗口 title 从 `"Session"`/`"Weekly"` 改成空字符串，跟 Codex 的 `primary`/`secondary` 窗口一致——这两个窗口只是同一份额度的两个时间维度，不是 Kimi Work/Code、MiniMax General/Video 那种需要区分的不同 scope，不应该显示前缀名称；legacy 的 `seven_day_sonnet`/`seven_day_opus` 分支保留各自的区分标题（它们是真正不同的 scope：不同模型的独立额度池）。相关测试改用 `periodSeconds` 而不是 `title` 区分窗口 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

原迁移条目的历史Comments完整保留于[同源历史](issue_%E4%BB%A5%E7%8B%AC%E7%AB%8B%E7%BB%93%E6%9E%9C%E6%9E%9A%E4%B8%BE%E4%B8%8E%E7%AB%96%E7%BA%BF%E6%A0%BC%E5%BC%8F%E8%AE%B0%E5%BD%95%E8%AF%8A%E6%96%AD%E6%97%A5%E5%BF%97.md#comments)，不从历史日志新增完成标记。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
