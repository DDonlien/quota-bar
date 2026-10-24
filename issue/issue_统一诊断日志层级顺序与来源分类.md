# 统一诊断日志层级顺序与来源分类

- ID：`0.10.0-ARCH-G-001`。
- 类型：`UI`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: dropdown 全局规则纠正 + 日志页体验 + 日志内容可读性统一。
- 原稳定 ID：`0.10.0-UI-C-000`, `0.10.0-ARCH-G-000`, `0.10.0-BUG-A-005`, `0.10.0-UI-C-001`, `0.10.0-ARCH-G-001`, `0.10.0-ARCH-G-002`, `0.10.0-BUG-A-006`, `0.10.0-INVESTIGATE-A-000`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.10.0-ARCH-G-000`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.10.0-ARCH-G-001`、`0.10.0-ARCH-G-002`、`0.10.0-BUG-A-006`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.10.0-ARCH-G-000-UI-dropdown-rules-experience-content-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：sub/main: dropdown 全局规则纠正 + 日志页体验 + 日志内容可读性统一。
- 同源任务：[保持日志页宽度并在日志变化后更新内容](issue_%E4%BF%9D%E6%8C%81%E6%97%A5%E5%BF%97%E9%A1%B5%E5%AE%BD%E5%BA%A6%E5%B9%B6%E5%9C%A8%E6%97%A5%E5%BF%97%E5%8F%98%E5%8C%96%E5%90%8E%E6%9B%B4%E6%96%B0%E5%86%85%E5%AE%B9.md)、[为仅有订阅档位的Provider显示灰色状态灯](issue_%E4%B8%BA%E4%BB%85%E6%9C%89%E8%AE%A2%E9%98%85%E6%A1%A3%E4%BD%8D%E7%9A%84Provider%E6%98%BE%E7%A4%BA%E7%81%B0%E8%89%B2%E7%8A%B6%E6%80%81%E7%81%AF.md)、[统一WebView授权提示的下划线规则](issue_%E7%BB%9F%E4%B8%80WebView%E6%8E%88%E6%9D%83%E6%8F%90%E7%A4%BA%E7%9A%84%E4%B8%8B%E5%88%92%E7%BA%BF%E8%A7%84%E5%88%99.md)、[排查ClaudeOAuth与Keychain凭证读取失败](issue_%E6%8E%92%E6%9F%A5ClaudeOAuth%E4%B8%8EKeychain%E5%87%AD%E8%AF%81%E8%AF%BB%E5%8F%96%E5%A4%B1%E8%B4%A5.md)。

## 当前需求与范围

共同范围与完整历史见[保持日志页宽度并在日志变化后更新内容](issue_%E4%BF%9D%E6%8C%81%E6%97%A5%E5%BF%97%E9%A1%B5%E5%AE%BD%E5%BA%A6%E5%B9%B6%E5%9C%A8%E6%97%A5%E5%BF%97%E5%8F%98%E5%8C%96%E5%90%8E%E6%9B%B4%E6%96%B0%E5%86%85%E5%AE%B9.md)；本文件保留以下独立目标的原文。

- [x] [0.10.0-ARCH-G-001] 诊断日志层输出顺序修正：`FetchPipeline.logAttempt` 原来用 `relevantLayers.sorted(by: { $0.rawValue < $1.rawValue })` 按字母序排（"plan" < "quota"），导致同一次成功调用先输出「档位与费用获取」再输出「额度获取」，跟额度层排 README 四层矩阵第 2 层、档位排第 4 层的既定顺序自相矛盾，看起来像"交叉"。改为固定用 `[.quota, .plan]` 显式顺序 #P0
- [x] [0.10.0-ARCH-G-002] 诊断日志 MethodName 统一：新增 `ProviderSourceKind.checkLogLabel`/`SubscriptionExpirySourceKind.checkLogLabel`，把 Provider 获取/额度获取/档位与费用获取/过期日获取四层的 MethodName 统一改成同一套分类词汇（"配置/凭证 → API"「CLI 命令」「本地 App / RPC」「App WebView 会话」「浏览器 Cookie」「Keychain」等，对应 README 五级来源排序的用词），不再直接用 `kimi-desktop-token` 这类单看名字猜不出类别的 strategy id 当 MethodName；具体 id 移到 `result` 里（格式："来源 <id>：<结果>"）#P0
- [x] [0.10.0-BUG-A-006] 修正 `QuotaProviderStrategy.sourceKind` 对 `"minimax-cli"` 的误分类：这个 id 是历史命名遗留，实际实现读 `~/.mmx/config.json` 的 API key 直调 `coding_plan/remains`，并不真的执行 `mmx` 命令（真正的 CLI 层是另一个 id `minimax-mmx-cli`），原来的 `id.contains("cli")` 通配会把它错分类成"CLI 命令"；新增日志用到 `checkLogLabel` 后这个误分类会直接暴露给用户，借这次统一顺手修掉 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

原迁移条目的历史Comments完整保留于[同源历史](issue_%E4%BF%9D%E6%8C%81%E6%97%A5%E5%BF%97%E9%A1%B5%E5%AE%BD%E5%BA%A6%E5%B9%B6%E5%9C%A8%E6%97%A5%E5%BF%97%E5%8F%98%E5%8C%96%E5%90%8E%E6%9B%B4%E6%96%B0%E5%86%85%E5%AE%B9.md#comments)，不从历史日志新增完成标记。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
