---
title: 识别同语义版本不同SHA的更新并记录过程
id: 0.14.1-BUG-A-000
type: DATA
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.14.1 - 更新检查的版本比较 bug + 检查过程写日志。'
原稳定 ID: '`0.14.1-BUG-A-000`, `0.14.1-DATA-A-000`, `0.14.1-QA-A-000`, `0.14.1-DOC-A-000`, `0.14.1-DOC-A-001`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.14.1-BUG-A-000`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.14.1-BUG-A-000`、`0.14.1-DATA-A-000`、`0.14.1-QA-A-000`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.14.1-BUG-A-000-DATA-bug-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: Phase - v0.14.1 - 更新检查的版本比较 bug + 检查过程写日志。
同源任务: '[要求main发包递增PATCH并保留文档例外](issue_%E8%A6%81%E6%B1%82main%E5%8F%91%E5%8C%85%E9%80%92%E5%A2%9EPATCH%E5%B9%B6%E4%BF%9D%E7%95%99%E6%96%87%E6%A1%A3%E4%BE%8B%E5%A4%96.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> **背景**：用户装的是 07-09 的旧包（`0.10.0-cdc842c`），「关于」页点检查更新显示"已是最新版本"，
> 但仓库当天（07-19）已经因为本 session 的一串修复发了 7 个新 release（全部还是 `0.10.0-*`，只有
> git sha 不同——见 `UpdateChecker.swift` 顶部注释，`VERSION` 文件只在 v0.11.0/v0.12.0 这类完整功能
> 阶段完成时才 bump，日常修复走"每次 push main 都发新 release"，不 bump 版本号）。用户最初要求"把
> 更新检查加入日志方便看问题"，但读代码直接定位到了根因：`UpdateReleaseParser.pickUpdate` 是
> 2026-07-07 那次改版定下的规则——只比较 `X.Y.Z`，完全忽略 git sha 后缀，本意是防"同一个 commit
> 重复打包被误判成有更新"；但实际发布节奏下，绝大多数发布之间 `X.Y.Z` 完全相同、只有 sha 不同，这条
> 规则会让这些发布永远不被判定为"有更新"——不是这次新引入的 bug，是环境（发布节奏）变了之后一条
> 旧决策反而错了，跟本 session 前面 Kimi `resetsAt` 那次是同一类情况。

- [x] [0.14.1-BUG-A-000] `UpdateReleaseParser.pickUpdate`：`X.Y.Z` 相同时新增一层判断——当前版本自己也带 sha 后缀时，改看 sha 是否不同（sha 内容寻址，同一个 commit 恒定，"重复打包同一个 commit"依然正确识别成不算更新，07-07 真正要避免的场景没有被重新引入）；当前版本是没有 sha 后缀的纯 `vX.Y.Z`（早期手动稳定版）时维持原规则不变，避免把"同版本号下的 ad-hoc 过程构建"误判成对一个已完成里程碑的更新
- [x] [0.14.1-DATA-A-000] 新增 `UpdateCheckLog`：直接复用「获取日志」页面的存储（`ProviderCheckLogStore`），不新开日志入口/UI；在 `fetchReleasesData`（GitHub/Vercel 两次尝试）、版本比较结果、下载、dmg 校验几个关键节点各记一行，格式跟现有 provider 日志行一致。`UpdateChecker` 新增 `checkLogStore` 注入点（默认 `.shared`），避免测试往真实日志文件写内容
- [x] [0.14.1-QA-A-000] 更新 `UpdateCheckerTests.swift`：原 `sameVersionDifferentShaIsNotAnUpdate` 断言的正是被本次修正推翻的旧行为，改写成 `sameVersionDifferentShaIsAnUpdate`（相同 X.Y.Z、不同 sha → 应识别成更新）+ 新增 `sameVersionSameShaIsNotAnUpdate`（相同 X.Y.Z、相同 sha → 仍不算更新，覆盖 07-07 真正想防的场景）；`onlyUpgradesToHigherSemver` 原有断言（纯 `vX.Y.Z` 不该被同版本号的 sha 构建判定为更新）保持通过，验证了"仅当前版本自带 sha 才触发新规则"这条边界是对的。`UpdateCheckerFallbackTests.swift` 补 `ephemeralCheckLogStore()` 注入点。`swift test` 221/221 通过；核实测试运行前后真实 `provider-check.log` 的大小/mtime 均未变化，确认注入生效

> **追加背景**：用户进一步指出这个 bug 频繁出现的深层原因——"自动编号机制完全不编号 patch"。
> 读 `AGENTS.md`「版本号维护规则」确认：规则字面上写的是"一般不 bump，或 bump PATCH"，技术上
> 允许 bump PATCH，但默认措辞（"大多数常规修复任务...VERSION 保持不变即可"）在实践中变成了
> "几乎从不 bump"——当天验证到的证据是同一个 `0.10.0` 底下堆了 7+ 次真实发布。这不是某次任务
> 执行疏忽，是规则默认值本身导向了错误的常态，直接把 0.14.1-BUG-A-000 那个 bug 的触发概率
> 拉到最高。修规则 + 立即应用（bump 当前累积的改动）。

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260720-114500-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260720-114500-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 本次日志覆盖的是上一份日志（`20260718-214500-utcp8-taobe-claude-sonnet-5.md`）结束之后、
> 同一个持续会话里发生的后续工作。会话中途经历过一次上下文压缩，本文件从压缩点之后的
> 真实交互重建，早于压缩点的内容以上一份日志为准。

会话延续自上一份日志记录的 5 项任务完成之后。期间用户依次提出（原文摘录，按发生顺序）：

1. 附真实 dropdown 截图，指出 Kimi 仍然只有月额度、且月额度进度条样式跟其他 provider 不一样；随后追加一段更详细的技术判断和三点 Preferences 功能需求：
   > "我知道问题出在哪了。你可能通过别的方式获取到了 Kimi work（也就是月额度），但是需要通过 web view 或别的方式才能获取到 Kimi 的小时和周额度。但这时候，我们的交互又没有办法提示用户去做那些操作。我觉得这个事情无法预见，应该在 preference 里面，去调整每个渠道获取的情况：1. 自动化获取的：正常显示。2. 当前 provider 没有获取到的：应该跟获取到的在样式上有所区别。3. Web view：在没有授权的情况下，应该可以点击，展开进行手动授权。"
   > "另外，Kimi 的月额度进度条在 drop down 里面的样式跟别人还是不一样，这个你没有做对，这肯定是错的，而且它也没有用量的提示。"
2. 附一份 ChatGPT 对话导出（讨论 Creem Store 归属 + 网站复审前自查），要求："根据附件的对话优化一下网站设计。联络邮箱留 taobe@ddonlien.com"，随后针对同一份对话里的两条具体反馈（Terms 定价文案与 Pricing 不一致、法律页面正文靠 JS 填充）再次确认处理，并追加："统一成正式版价格4.99 美元"。
3. 附一张 Pricing 卡片截图："get pro free 也不要，就是卖 4.99，说明有 7 天试用就好"。
4. 附一张 bullet 列表截图："这个部分，左边应该只保留 2 条，然后右边是'左边的所有内容'再加上付费内容的添头（自动更新、一键安装、优先技术支持）"。
5. 附一张 CTA 按钮截图："这俩按钮对齐高度"。
6. 确认推送："推送"。
7. 附「关于」页截图（版本 `0.10.0-cdc842c`，检查更新显示"已是最新版本"）："我的老版本检查不到更新啊，把更新检查加入日志方便看问题"。
8. "这里一个额外问题：你的自动编号机制完全不编号 patch 啊，所以才会更频繁的有这个问题"。

#### 完成工作

- **macOS App**（`macos/Sources/QuotaBar/`）：
  - `DashboardEndpoints.swift`：`KimiSubscriptionParser` 补 `resetsAt`；`.kimi` webview 端点改用 `GetSubscription`。
  - 新文件 `Preferences/ProviderChannelStatusView.swift`；`QuotaPersistence.swift`（`ProviderSourceIndexStore` 读取 API + 通知）；`Strategies.swift`（`quotaChannels(for:)`）；`ModelsSettingsView.swift`（展开交互）。
  - `UpdateChecker.swift`：`pickUpdate` sha 比较修正；新增 `UpdateCheckLog` + `checkLogStore` 注入点；下载/校验流程补日志。
  - 测试：更新/新增覆盖上述改动的用例，`swift test` 221/221 通过。
- **官网**（`site/`）：
  - `src/pages/privacy.astro`、`terms.astro`：正文改 SSR 直出。
  - `src/components/Pricing.astro`：定价叙事重写（$4.99 + 7 天试用）、bullet 列表重构、CTA 对齐占位段落。
  - `src/components/Footer.astro`、`src/i18n/dict.ts`：邮箱统一为 `taobe@ddonlien.com`，新增/清理若干 pricing/changelog key。
  - `src/pages/changelog.astro`：新增 `v10-1` 条目。
- **仓库根目录**：`VERSION` 0.10.0 → 0.10.1；`AGENTS.md`「版本号维护规则」改写为默认必须 bump PATCH。

#### 更新的需求 ID

- 根目录 `REQUIREMENTS.md`：`v0.14.0` phase 新增 `[0.14.0-BUG-B-000..001]`、`[0.14.0-QA-C-001]`、`[0.14.0-DATA-C-000..001]`、`[0.14.0-FE-C-000..001]`、`[0.14.0-QA-D-000..001]`；新开 `v0.14.1` phase（`[0.14.1-BUG-A-000]`、`[0.14.1-DATA-A-000]`、`[0.14.1-QA-A-000]`）。
- `site/REQUIREMENTS.md`：新开 `v0.3.1` phase（`[0.3.1-FE-A-000]`、`[0.3.1-CONTENT-A-000..002]`、`[0.3.1-QA-A-000]`）、`v0.3.2` phase（`[0.3.2-CONTENT-A-000..001]`、`[0.3.2-QA-A-000]`）、`v0.3.3` phase（`[0.3.3-CONTENT-A-000..001]`、`[0.3.3-QA-A-000]`）、`v0.3.4` phase（`[0.3.4-FE-A-000]`、`[0.3.4-QA-A-000]`）。

#### 验证方式

- `swift build` + `swift test`：221/221 通过。
- `npm run build`（site/）：每一轮改动均通过，Browser 面板做内容/DOM 级校验（多次因本 session 已知的截图/几何读取环境问题改用等效验证方式，已在过程记录里如实说明）。
- 推送后核实：GitHub Actions CI + Release 均 success；直接读取线上 `quotabar.ddonlien.com` 的原始 HTTP 响应确认 Vercel 部署内容与预期一致。
- 更新检查测试运行前后核实真实 `provider-check.log` 大小/mtime 未变化，确认日志注入的测试隔离生效。
- 未做：Preferences 渠道状态功能的像素级视觉效果、Kimi 修复在真实设备上的长期稳定性，仍需用户后续实机确认。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-070408_Agent

原记录标题：2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-162234_Codex

按用户最新手写模板迁移属性和正文结构，保留任务语义、来源、原始状态及历史内容；本次未重新执行业务验收。

原版本关联记录（照录来源，不将本次文档迁移提交当作业务实施提交）：
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。

本次执行环境未提供具体模型标识，未补造 Model-Detail。

[本次文档迁移对话](codex://threads/01a157b3-610c-73b4-ae06-163c0f8490d3)
