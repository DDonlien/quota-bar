# 保持日志页宽度并在日志变化后更新内容

- ID：`0.10.0-UI-C-000`。
- 类型：`UI`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: dropdown 全局规则纠正 + 日志页体验 + 日志内容可读性统一。
- 原稳定 ID：`0.10.0-UI-C-000`, `0.10.0-ARCH-G-000`, `0.10.0-BUG-A-005`, `0.10.0-UI-C-001`, `0.10.0-ARCH-G-001`, `0.10.0-ARCH-G-002`, `0.10.0-BUG-A-006`, `0.10.0-INVESTIGATE-A-000`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.10.0-ARCH-G-000`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.10.0-UI-C-000`、`0.10.0-ARCH-G-000`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.10.0-ARCH-G-000-UI-dropdown-rules-experience-content-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：sub/main: dropdown 全局规则纠正 + 日志页体验 + 日志内容可读性统一。
- 同源任务：[为仅有订阅档位的Provider显示灰色状态灯](issue_%E4%B8%BA%E4%BB%85%E6%9C%89%E8%AE%A2%E9%98%85%E6%A1%A3%E4%BD%8D%E7%9A%84Provider%E6%98%BE%E7%A4%BA%E7%81%B0%E8%89%B2%E7%8A%B6%E6%80%81%E7%81%AF.md)、[统一WebView授权提示的下划线规则](issue_%E7%BB%9F%E4%B8%80WebView%E6%8E%88%E6%9D%83%E6%8F%90%E7%A4%BA%E7%9A%84%E4%B8%8B%E5%88%92%E7%BA%BF%E8%A7%84%E5%88%99.md)、[统一诊断日志层级顺序与来源分类](issue_%E7%BB%9F%E4%B8%80%E8%AF%8A%E6%96%AD%E6%97%A5%E5%BF%97%E5%B1%82%E7%BA%A7%E9%A1%BA%E5%BA%8F%E4%B8%8E%E6%9D%A5%E6%BA%90%E5%88%86%E7%B1%BB.md)、[排查ClaudeOAuth与Keychain凭证读取失败](issue_%E6%8E%92%E6%9F%A5ClaudeOAuth%E4%B8%8EKeychain%E5%87%AD%E8%AF%81%E8%AF%BB%E5%8F%96%E5%A4%B1%E8%B4%A5.md)。

## 当前需求与范围

> 用户截图指出一批具体问题：日志页清空后 ScrollView 收缩变窄；停留在日志页时新记录不会自动出现，要切一次 tab 才行；Claude 明明没拿到额度却是绿灯（状态灯全局规则错误）；灰色/蓝色 WebView 授权提示的下划线不统一；并贴了一段真实日志，指出 Kimi 的额度/档位两层看起来"交叉"、`kimi-desktop-token` 这类 MethodName 看不出属于哪一类来源、Z Code 额度层只跑了一次、以及追问 Claude 的 OAuth/Keychain 到底为什么读不到凭证。

- [x] [0.10.0-UI-C-000] `DiagnosticsSettingsView` 的日志 `ScrollView` 内容 `VStack` 加 `.frame(maxWidth: .infinity, alignment: .leading)`：清空后只剩一行短提示文字时，原来没有这个约束会让整个 ScrollView（进而整个设置页）收缩到刚好包住那行字的宽度 #P1
- [x] [0.10.0-ARCH-G-000] 新增 `Notification.Name.providerCheckLogDidChange`，`ProviderCheckLogStore.append`/`clear` 落盘后在主线程 post；`DiagnosticsSettingsView` 订阅它调用 `reload()`——停留在日志页时，刷新周期写入的新记录会实时出现，不用切一次 tab 才触发 `onAppear` 重新读取 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 2026-10-24 07:03:43 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
