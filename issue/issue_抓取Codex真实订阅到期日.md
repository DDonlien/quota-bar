---
title: 抓取Codex真实订阅到期日
id: 0.6.0-DATA-B-000
type: DATA
status: 待处理（原文未完成项保持未勾选）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`；标题路径：任务清单 / Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页） / DATA-B：Codex 真实订阅到期日（headless 抓订阅页）。'
原稳定 ID: '`0.6.0-DATA-B-000`, `0.6.0-DATA-B-001`, `0.6.0-DATA-B-002`, `0.6.0-DATA-B-001-test`；不改写或重编号这些既有 ID。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> Codex (chatgpt.com) 的 `/backend-api/wham/usage` 只返回 quota 窗口，**不返回订阅到期日**。需要 headless 抓 `chatgpt.com/account/manage` 或 `chatgpt.com/settings/billing` 页面，提取「Next billing date」「Renewal date」之类 DOM 文本。

- [ ] [0.6.0-DATA-B-000] `CodexHarvester` 实现：用 `WKWebViewHeadlessLoader` 加载 `https://chatgpt.com/account/manage`，DOM 提取续费日期；找不到返回 nil；超时/Cloudflare challenge 失败抛 `QuotaFetchError.transient` 让 pipeline 降级 #P1
- [ ] [0.6.0-DATA-B-001] `CodexAuthProvider` / `BrowserCookieProvider` Codex 路径新增 strategy：headless 抓订阅页 → 拿 `subscriptionExpiresAt`；和现有 quota 抓取并行，结果合并到 `ProviderSnapshot` #P1
- [ ] [0.6.0-DATA-B-002] Codex 到期日不能使用过期 `id_token` 的 `chatgpt_subscription_active_until` 继续展示；本地 auth 元数据 stale 但 quota 仍成功时，应隐藏日期或通过后续 WebView/DOM 授权源拿真实日期 #P1
- [ ] [0.6.0-DATA-B-001-test] 单元测试：mock HTML（含"Next billing on July 25, 2026"等常见模式）验证 `CodexHarvester` 解析出正确 `Date` #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260702145131-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260702145131-utcp8-gpt5.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 光codex不够，我需要一个：
> 首先设计一套完整链路
> 然后针对每个模型，设计：哪些节点可以跳过；每个节点需要如何特殊处理（比如有的cli是/usage，有的是/quota，如果用浏览器，每个网址不一样）

#### 完成工作

- 更新 `REQUIREMENTS.md`，新增需求 ID：
  - `0.9.0-ARCH-B-000`
  - `0.9.0-ARCH-B-001`
  - `0.9.0-ARCH-B-002`
  - `0.9.0-ARCH-B-003`
  - `0.9.0-ARCH-B-004`
  - `0.9.0-ARCH-B-005`
  - `0.9.0-ARCH-B-006`
- 形成统一获取链路和 provider 能力矩阵设计，将在回复中交付。

#### 更新的需求 ID

- `0.9.0-ARCH-B-000` 至 `0.9.0-ARCH-B-006`

#### 验证方式

- 文档变更，无构建验证。
- 使用 `rg` / `sed` 检查现有 pipeline、provider metadata 和需求上下文。

#### 备注

- 本次未改 Swift 实现代码。
- 工作区仍存在未跟踪日志文件，未进行 git add/commit。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260702170822-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260702170822-utcp8-gpt5.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

```text
- codex好了
- 弹窗不跳了
- 你似乎不会问我要任何权限，比如完全磁盘之类的，是用不到？我以为完全磁盘可以代替浏览器授权访问到浏览器的本地缓存？
- kimi 之前cli没登陆，登陆后5h和week额度政策，但work不行
- z code还是没额度
```

#### 完成工作

- 新增 `KimiDesktopTokenProvider`：读取 Kimi Desktop token-store 的 access token，调用 `GetSubscriptionStat`，解析 Work、Code 5h、Code week、订阅档位、月费和到期日。
- 更新 Kimi pipeline：Desktop token-store 优先，CLI OAuth 作为 Code-only fallback；浏览器 Cookie 只在显式环境变量启用后作为兜底。
- 新增 `ZCodePlanCacheProvider`：读取 Z Code coding plan cache，展示 available plan 与不可用原因；没有额度数值时不伪造 quota。
- 更新 Z Code pipeline：API provider 优先，plan-cache 状态兜底，再到 Keychain。
- 更新 `README.md`：记录 Kimi Desktop token 路径、Z Code plan-cache 兜底、Full Disk Access 与 Chromium Keychain 解密边界、四层矩阵优先级。
- 更新 `REQUIREMENTS.md`：登记 Kimi Desktop token 与 Z Code plan-cache 两条用户可见需求。
- 更新 `scripts/build-app.sh`：SwiftPM 构建使用仓库内 module cache，并使用 `--disable-sandbox`，避免在当前沙箱里写用户级 Swift/clang 缓存失败。
- 生成新版 app：`quota-bar/build/20260702-170758/QuotaBar.app`，`build/latest` 已指向该版本。

#### 更新的需求 ID

- `0.2.0-DATA-B-025`
- `0.4.0-DATA-A-006`

#### 验证方式

- `cd quota-bar && env CLANG_MODULE_CACHE_PATH=.build/clang-module-cache SWIFT_MODULE_CACHE_PATH=.build/swift-module-cache swift test --disable-sandbox`
  - 结果：59 tests in 15 suites passed。
- `cd quota-bar && ./scripts/build-app.sh`
  - 结果：生成 `build/20260702-170758/QuotaBar.app`。
- `cd quota-bar && codesign --verify --deep --verbose=2 build/latest/QuotaBar.app`
  - 结果：valid on disk，satisfies its Designated Requirement。
- `cd quota-bar && plutil -p build/latest/QuotaBar.app/Contents/Info.plist`
  - 结果：`CFBundleIdentifier = com.taobe.quotabar`，`LSUIElement = true`。

#### 备注

- 本次未提交。
- 当前 worktree 仍包含本轮之前已经存在的未提交改动和多条历史 agent log。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260629014432-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260629014432-utcp8-mavis.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 开一个新的branch: sub/main，并创建对应的worktree，处理现在订阅过期的情况：我的codex已经过期了但却刷出了"月额度"我估计其他的过期也没处理

#### 验证

- `cd .worktrees/sub-main/quota-bar && swift build` → Build complete! (2.38s), 0 warning
- `cd .worktrees/sub-main/quota-bar && swift test` → 39 tests in 8 suites passed

#### 更新的需求 ID

- 新增 `v0.8.0` 完整 phase：
  - `### ARCH-A`：4 个 task（基础架构，全部完成）
  - `### DATA-A`：7 个 task + 2 个测试任务（Codex 订阅过期识别，全部完成）
  - `### UI-A`：4 个 task（UI 表现，全部完成）
  - `### DATA-B`：5 个 task（其他 provider inspector 模式，全部 deferred / cut，登记）

#### 验证方式

- `swift build` 通过 0 warning
- `swift test` 39 tests passed
- ground truth 验证：用真实 `~/.codex/auth.json` 跑 inspector + 用 refresh_token 跑 wham/usage 验证 parser 在 plan_type=free 时返回 nil
- 测试覆盖：JWT 4 路径 / inspector 6 路径 / parser free 路径 / statusColor 安全 / SubscriptionStatus 语义

#### 备注

- **v0.8.0 只覆盖 Codex**：user 触发 case 是 Codex，且 Codex 的 id_token 字段是已知。Claude/Cursor/Antigravity/MiniMax 的同类检测都登记为 deferred（v0.8.0-DATA-B-000/001/002/003），等 v0.6.0 第二批 headless 抓订阅页落地后沿用同模式做。
- **"返回 snapshot 而不是 throw"是关键设计**：throw 会让 pipeline 走到 BrowserCookie / CLILog 仍然显示 5h+weekly 误数据。返回 marker snapshot 让 pipeline 立即返回，UI 切到 "订阅已过期" 灰标。
- **不验证 JWT 签名**：安全模型是"已经持有 token → 验签无意义"，攻击者有 root 就能改本机 UI。
- **可能需要后续**：
  1. 选 v0.8.0-DATA-B-001 (Cursor) 推进一步：Cursor dashboard 页面抓"Plan renews on..." 文本
  2. 选 v0.8.0-DATA-B-000 (Claude)：解析 claude.ai session token 的 membership 字段
  3. 合并到 main 后开 `feat/codex-subscription-expiry` branch 进一步打磨（暂时不必要）
- user 的实际过期日 `2026-06-25`，本次 commit 后可在自己的 Mac 上 `swift run` 直接看到修复效果。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260619011202-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260619011202-utcp8-gpt5.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

其他的ai都不行，你可以访问cli和terminal直接帮我build，帮我解决现在quota bar的问题：没办法正确货渠道电脑上的ai的情况，参考codex bar是怎么做的，而且现在一直要full disk access，明显不合理

#### 验证方式

- `cd drop-down-test/CodingPlanMenu && swift build`：通过。
- `cd drop-down-test/CodingPlanMenu && ./build-app.sh`：通过，生成 `QuotaBar.app`。
- 已关闭旧进程并通过 `open .../QuotaBar.app` 启动新构建，进程 PID 为 `91907`。

#### 需求更新

- `DA-A-005` 标记完成：菜单不再展示 `.notInstalled` snapshot。
- `UI-C-005` 文案更新为“浏览器 Cookie 数据源缺 Full Disk Access 时按需显示引导”。

#### 备注

- 工作区已有 `.build/`、`.DS_Store` 等构建产物变更；本轮运行 build 后这些文件继续保持 dirty。未回滚这些已有/构建生成的文件。
- 当前未实现 Codex OAuth token refresh；若 token 过期，会提示重新 `codex login`。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260702141144-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260702141144-utcp8-gpt5.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 我可以让用户去开启 Full Disk Access、辅助功能以及录制权限，因为这些都包含在设置选单里，操作非常常规。
>
> 但是，如果让用户在弹窗里面进行操作，这就太不常规了。你要想一想有没有什么 workaround
>
> 已过期的逻辑很简单：
>
> 1. 首先你要确保现在“我的”获取是正确的
> 2. 其次在正确的前提下，根据过期日显示状态：
>    (a) 如果最近的过期日是在一个自然周内，就显示为“已过期”
>    (b) 如果超过一个自然周，不管你是新的还是没有订，直接显示“未订阅”就行但是 auth.json 的 id_token 有问题这件事也很奇怪。
>
> 因为实际上我 Codex 的应用读的就是 .codex-auth.json 里面的东西，而我 Codex 应用本身（也就是你自己）是可以正常 running 的，那这里面的信息怎么可能错呢？你实际上读一下不就知道了？

#### 完成工作

- 确认 `id_token` 订阅元信息确实陈旧，不能单独作为当前订阅状态真相。
- 确认 Codex 能运行与 `id_token` 订阅字段正确不是同一件事：本机 `access_token` 仍有效到 2026-07-06，运行态可能依赖 access token / refresh token，而不是依赖已过期的 id_token payload。
- 初步方案：
  - 订阅真相优先使用当前可验证的服务端 usage / dashboard / 刷新后的 token 信息。
  - `id_token` 只作为本地线索，不能短路真实抓取。
  - `.free` / 从未订阅 与 `.expired` 分离；超过一个自然周的过期也归为“未订阅”。
  - 浏览器权限不要走连续弹窗；改为设置页/系统设置入口 + 用户主动授权/选择浏览器来源。

#### 更新的需求 ID

无。

#### 验证方式

- `git pull`
- `ls -la ~/.codex ~/.codex/auth.json ~/.codex-auth.json`
- `stat -f ... ~/.codex/auth.json ~/.codex-auth.json`
- Node.js 只读解析 `~/.codex/auth.json` 的非敏感 JWT payload 字段。
- Node.js HTTPS 调用 wham/usage 尝试失败，记录 TLS 证书不匹配原因。

#### 备注

- 中途一次文本搜索意外匹配到 auth.json 中的 refresh_token 行；未在答复中复述 token。后续调查应避免直接 `rg` auth 文件内容，改用结构化脚本只输出非敏感字段。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-070408_Agent

原记录标题：2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-162234_Codex

按用户最新手写模板迁移属性和正文结构，保留任务语义、来源、原始状态及历史内容；本次未重新执行业务验收。

原版本关联记录（照录来源，不将本次文档迁移提交当作业务实施提交）：
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。

本次执行环境未提供具体模型标识，未补造 Model-Detail。

[本次文档迁移对话](codex://threads/01a157b3-610c-73b4-ae06-163c0f8490d3)
