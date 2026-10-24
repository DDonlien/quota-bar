# 排查ClaudeOAuth与Keychain凭证读取失败

- ID：`0.10.0-INVESTIGATE-A-000`。
- 类型：`UI`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: dropdown 全局规则纠正 + 日志页体验 + 日志内容可读性统一。
- 原稳定 ID：`0.10.0-UI-C-000`, `0.10.0-ARCH-G-000`, `0.10.0-BUG-A-005`, `0.10.0-UI-C-001`, `0.10.0-ARCH-G-001`, `0.10.0-ARCH-G-002`, `0.10.0-BUG-A-006`, `0.10.0-INVESTIGATE-A-000`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.10.0-ARCH-G-000`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.10.0-INVESTIGATE-A-000`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.10.0-ARCH-G-000-UI-dropdown-rules-experience-content-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：sub/main: dropdown 全局规则纠正 + 日志页体验 + 日志内容可读性统一。
- 同源任务：[保持日志页宽度并在日志变化后更新内容](issue_%E4%BF%9D%E6%8C%81%E6%97%A5%E5%BF%97%E9%A1%B5%E5%AE%BD%E5%BA%A6%E5%B9%B6%E5%9C%A8%E6%97%A5%E5%BF%97%E5%8F%98%E5%8C%96%E5%90%8E%E6%9B%B4%E6%96%B0%E5%86%85%E5%AE%B9.md)、[为仅有订阅档位的Provider显示灰色状态灯](issue_%E4%B8%BA%E4%BB%85%E6%9C%89%E8%AE%A2%E9%98%85%E6%A1%A3%E4%BD%8D%E7%9A%84Provider%E6%98%BE%E7%A4%BA%E7%81%B0%E8%89%B2%E7%8A%B6%E6%80%81%E7%81%AF.md)、[统一WebView授权提示的下划线规则](issue_%E7%BB%9F%E4%B8%80WebView%E6%8E%88%E6%9D%83%E6%8F%90%E7%A4%BA%E7%9A%84%E4%B8%8B%E5%88%92%E7%BA%BF%E8%A7%84%E5%88%99.md)、[统一诊断日志层级顺序与来源分类](issue_%E7%BB%9F%E4%B8%80%E8%AF%8A%E6%96%AD%E6%97%A5%E5%BF%97%E5%B1%82%E7%BA%A7%E9%A1%BA%E5%BA%8F%E4%B8%8E%E6%9D%A5%E6%BA%90%E5%88%86%E7%B1%BB.md)。

## 当前需求与范围

共同范围与完整历史见[保持日志页宽度并在日志变化后更新内容](issue_%E4%BF%9D%E6%8C%81%E6%97%A5%E5%BF%97%E9%A1%B5%E5%AE%BD%E5%BA%A6%E5%B9%B6%E5%9C%A8%E6%97%A5%E5%BF%97%E5%8F%98%E5%8C%96%E5%90%8E%E6%9B%B4%E6%96%B0%E5%86%85%E5%AE%B9.md)；本文件保留以下独立目标的原文。

- [x] [0.10.0-INVESTIGATE-A-000] 排查 Claude OAuth/Keychain 凭证读取失败：用户机器上 `claude auth status --json`（CLI 层）能成功返回 `subscriptionType: pro`，说明本机确实登录有效；但 `ClaudeOAuthUsageProvider` 的文件路径（`~/.claude/.credentials.json` 不存在，已确认）和 Keychain 路径（`security find-generic-password -s "Claude Code-credentials"` 确认条目真实存在，service/account 与代码预期完全匹配）都读不到有效 accessToken。代码走读未发现查询逻辑本身的 bug。最可能的解释：`build-app.sh` 用 ad-hoc 签名（`--sign -`）+ 固定 `--identifier`重签，但 ad-hoc 签名本身在每次重新构建后 CDHash 会变化，可能导致 macOS 对 Keychain 第三方条目的"始终允许"信任判定无法跨构建持久化——与已知的 TCC/Accessibility 权限持久化问题（v0.12.0 Developer ID 签名规划）是同一根因类别 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

原迁移条目的历史Comments完整保留于[同源历史](issue_%E4%BF%9D%E6%8C%81%E6%97%A5%E5%BF%97%E9%A1%B5%E5%AE%BD%E5%BA%A6%E5%B9%B6%E5%9C%A8%E6%97%A5%E5%BF%97%E5%8F%98%E5%8C%96%E5%90%8E%E6%9B%B4%E6%96%B0%E5%86%85%E5%AE%B9.md#comments)，不从历史日志新增完成标记。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
