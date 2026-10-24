# 复用AppWebView会话并提供授权引导

- ID：`0.10.0-UI-C-000`。
- 类型：`ARCH`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 分组分层获取方案落地（5 agent × 4 信息）。
- 原稳定 ID：`0.10.0-ARCH-B-000`, `0.10.0-ARCH-B-000-test`, `0.10.0-ARCH-B-001`, `0.10.0-UI-C-000`, `0.10.0-ARCH-B-002`, `0.10.0-ARCH-B-003`, `0.10.0-ARCH-B-004`, `0.10.0-ARCH-B-005`, `0.10.0-DATA-B-005`, `0.10.0-UI-C-001`, `0.10.0-UI-C-002`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.10.0-ARCH-B-000`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.10.0-UI-C-000`、`0.10.0-ARCH-B-002`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.10.0-ARCH-B-000-ARCH-agent-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：sub/main: 分组分层获取方案落地（5 agent × 4 信息）。
- 同源任务：[分层合并额度与档位并保留权威订阅状态](issue_%E5%88%86%E5%B1%82%E5%90%88%E5%B9%B6%E9%A2%9D%E5%BA%A6%E4%B8%8E%E6%A1%A3%E4%BD%8D%E5%B9%B6%E4%BF%9D%E7%95%99%E6%9D%83%E5%A8%81%E8%AE%A2%E9%98%85%E7%8A%B6%E6%80%81.md)、[通过API与Headless来源补齐订阅到期日](issue_%E9%80%9A%E8%BF%87API%E4%B8%8EHeadless%E6%9D%A5%E6%BA%90%E8%A1%A5%E9%BD%90%E8%AE%A2%E9%98%85%E5%88%B0%E6%9C%9F%E6%97%A5.md)、[通过MiniMax真实CLI命令读取额度](issue_%E9%80%9A%E8%BF%87MiniMax%E7%9C%9F%E5%AE%9ECLI%E5%91%BD%E4%BB%A4%E8%AF%BB%E5%8F%96%E9%A2%9D%E5%BA%A6.md)、[恢复授权与偏好输入框的粘贴快捷键](issue_%E6%81%A2%E5%A4%8D%E6%8E%88%E6%9D%83%E4%B8%8E%E5%81%8F%E5%A5%BD%E8%BE%93%E5%85%A5%E6%A1%86%E7%9A%84%E7%B2%98%E8%B4%B4%E5%BF%AB%E6%8D%B7%E9%94%AE.md)、[恢复Dropdown偏好设置菜单入口](issue_%E6%81%A2%E5%A4%8DDropdown%E5%81%8F%E5%A5%BD%E8%AE%BE%E7%BD%AE%E8%8F%9C%E5%8D%95%E5%85%A5%E5%8F%A3.md)。

## 当前需求与范围

共同范围与完整历史见[分层合并额度与档位并保留权威订阅状态](issue_%E5%88%86%E5%B1%82%E5%90%88%E5%B9%B6%E9%A2%9D%E5%BA%A6%E4%B8%8E%E6%A1%A3%E4%BD%8D%E5%B9%B6%E4%BF%9D%E7%95%99%E6%9D%83%E5%A8%81%E8%AE%A2%E9%98%85%E7%8A%B6%E6%80%81.md)；本文件保留以下独立目标的原文。

- [x] [0.10.0-UI-C-000] dropdown 中「有额度但缺订阅到期日、且日期依赖 headless 订阅页」的 provider，价格左侧显示「授权获取日期」可点击引导，打开 App 内 WebView 登录一次后自动获取 #P1 — `MenuView.PlanHeader.canOfferWebAuthorizationForDate`
- [x] [0.10.0-ARCH-B-002] App WebView 会话桥接到**额度层**：`AppWebViewSessionCookieReader` 读 `WKWebsiteDataStore.default()`，与 `BrowserCookieProvider` 组合复用全部 dashboard endpoint / parser；作为 Codex / Claude / Kimi / MiniMax 额度管线的最后一层默认启用（无弹窗）。Claude 由此获得默认唯一的额度路径（organizations → usage）#P0 — 用户反馈「claude/antigravity 用 webview 授权后依旧没有额度」的修复

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

原迁移条目的历史Comments完整保留于[同源历史](issue_%E5%88%86%E5%B1%82%E5%90%88%E5%B9%B6%E9%A2%9D%E5%BA%A6%E4%B8%8E%E6%A1%A3%E4%BD%8D%E5%B9%B6%E4%BF%9D%E7%95%99%E6%9D%83%E5%A8%81%E8%AE%A2%E9%98%85%E7%8A%B6%E6%80%81.md#comments)，不从历史日志新增完成标记。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
