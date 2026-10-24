# 按真实档位与额度完善Dropdown显示

- ID：`0.10.0-BUG-A-001`。
- 类型：`ARCH`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: Preferences provider 列表遗漏 + dropdown Claude 消失架构 bug + 分层诊断日志 + dropdown 显示规则重写。
- 原稳定 ID：`0.10.0-BUG-A-000`, `0.10.0-BUG-A-001`, `0.10.0-ARCH-E-000`, `0.10.0-ARCH-E-001`, `0.10.0-ARCH-E-002`, `0.10.0-PM-A-014`, `0.10.0-UI-B-000`, `0.10.0-UI-B-001`, `0.10.0-CLEAN-A-000`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.10.0-BUG-A-000`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.10.0-BUG-A-001`、`0.10.0-UI-B-000`、`0.10.0-UI-B-001`、`0.10.0-CLEAN-A-000`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.10.0-BUG-A-000-ARCH-preferences-provider-list-dropdown-claude-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：sub/main: Preferences provider 列表遗漏 + dropdown Claude 消失架构 bug + 分层诊断日志 + dropdown 显示规则重写。
- 同源任务：[在模型偏好页补齐Antigravity开关](issue_%E5%9C%A8%E6%A8%A1%E5%9E%8B%E5%81%8F%E5%A5%BD%E9%A1%B5%E8%A1%A5%E9%BD%90Antigravity%E5%BC%80%E5%85%B3.md)、[记录并展示Provider分层获取诊断日志](issue_%E8%AE%B0%E5%BD%95%E5%B9%B6%E5%B1%95%E7%A4%BAProvider%E5%88%86%E5%B1%82%E8%8E%B7%E5%8F%96%E8%AF%8A%E6%96%AD%E6%97%A5%E5%BF%97.md)。

## 当前需求与范围

共同范围与完整历史见[在模型偏好页补齐Antigravity开关](issue_%E5%9C%A8%E6%A8%A1%E5%9E%8B%E5%81%8F%E5%A5%BD%E9%A1%B5%E8%A1%A5%E9%BD%90Antigravity%E5%BC%80%E5%85%B3.md)；本文件保留以下独立目标的原文。

- [x] [0.10.0-BUG-A-001] 修复 dropdown 里 Claude 完全不显示：根因是 `FetchPipeline.runSequential` 在只有 tier-only CLI 兜底层成功（`quotas=[]`）、且后续额度层全部失败时，仍返回 `availability=.available` 的"幽灵成功" snapshot；`RefreshCoordinator.applyProviderResult` 对 `.available` 原本判定 `keepAfterApply = !quotas.isEmpty`，导致这条 snapshot 被直接移除。`.available` 只可能来自至少一个 strategy 成功，不存在"什么都没有"的空 available，改为始终 `keepAfterApply = true`；额度缺失的展示交给 dropdown 新的"打开 WebView 授权"提示（0.10.0-UI-B-000）兜底，不再让整个 provider 消失 #P0
- [x] [0.10.0-UI-B-000] dropdown 名称栏重写（`PlanHeader`）：左侧 `<ProviderName> · <TierName>`（TierName 缺失时省略"·"）；右侧按"TierName 缺失 → 到期日缺失 → 都齐全"三级 cascade 决定显示"打开 WebView 授权"提示还是真实到期日+价格；价格缺失时整组（货币符号/费用/周期）直接不渲染，不再显示"—"占位；到期日显示不再要求价格同时存在（原逻辑错误地把两者耦合）#P1
- [x] [0.10.0-UI-B-001] dropdown 额度栏重写：`.available` 但 `quotas.isEmpty`（tier-only 兜底层成功、额度层还没拿到）时渲染新增的 `QuotaAuthPromptRow`——有 WebView 授权入口的 provider 显示蓝色可点击"打开 WebView 授权"，没有的显示灰色"暂无额度数据"；不再是空白 VStack #P1
- [x] [0.10.0-CLEAN-A-000] 删除已无调用方的 `ProviderSnapshot.displayName`（原 `"\(kind.displayName) \(subscriptionTier)"` 拼接，被 0.10.0-UI-B-000 拆成独立的 ProviderName/TierName 两个 Text 后不再需要）#P2

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

原迁移条目的历史Comments完整保留于[同源历史](issue_%E5%9C%A8%E6%A8%A1%E5%9E%8B%E5%81%8F%E5%A5%BD%E9%A1%B5%E8%A1%A5%E9%BD%90Antigravity%E5%BC%80%E5%85%B3.md#comments)，不从历史日志新增完成标记。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
