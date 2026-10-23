# sub/main: Kimi CLI OAuth 5 小时/周额度丢失修复

- ID：`0.14.0-BUG-A-000`。
- 类型：`QA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.14.0 - 大陆可达性兜底 + 额度节奏指示 + Kimi 额度修复 / sub/main: Kimi CLI OAuth 5 小时/周额度丢失修复。
- 原稳定 ID：`0.14.0-BUG-A-000`, `0.14.0-QA-C-000`, `0.14.0-DOC-B-000`, `0.14.0-BUG-B-000`, `0.14.0-BUG-B-001`, `0.14.0-QA-C-001`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 现象：用户反馈 Kimi 现在只能拿到月额度（Work，来自 `KimiDesktopTokenProvider`），拿不到 5 小时/周额度
> （Code，来自 `KimiAuthProvider`）。本机诊断日志（`provider-check.log`）复现同一症状，`kimi-auth` 持续报
> "Kimi refresh_token 已失效，请重新 kimi login"，而 `kimi-desktop-token` 持续成功。
>
> **根因分析**：`KimiAuthProvider` 是当前 Kimi pipeline 里唯一会**写回**凭证文件的 provider——刷新
> access_token 后调用 `persistCredentials` 把新 token 写回 `~/.kimi-code/credentials/kimi-code.json`，
> 而这份文件是 `kimi` CLI 自己的凭证存储，CLI 本身也可能独立管理/轮换这份凭证。`KimiDesktopTokenProvider`
> （一直工作正常）从不写回它读的 token store，是纯只读消费者。Kimi 的 OAuth 服务端大概率对 `refresh_token`
> 做单次轮换（用一次即失效换新），两个独立写者（真实 kimi CLI + Quota Bar 后台每 5 分钟一次的静默刷新）
> 竞争同一份 refresh_token 时，任何一方在另一方之后用"已经被对方用掉"的旧 refresh_token 去刷新，
> 服务端就会拒绝——这与观察到的"曾经能用、现在永久失败"的症状一致。
>
> 本次修复只解决"Quota Bar 主动写回、制造竞争"这一条架构性风险；如果用户本地 refresh_token 在修复前
> 已经被判定失效，仍需手动 `kimi login` 一次让 CLI 重新签发凭证——这一步无法通过代码修复回溯解决。

- [x] [0.14.0-BUG-A-000] `KimiAuthProvider.ensureFreshCredentials`/`forceRefresh` 仍在内存中执行 OAuth refresh（当次请求仍能成功），但去掉 `persistCredentials` 写回调用，不再往 `~/.kimi-code/credentials/kimi-code.json` 写任何内容——与 `KimiDesktopTokenProvider` 对齐为纯只读消费者，避免与真实 `kimi` CLI 竞争 refresh_token 轮换；已删除现在无调用方的 `persistCredentials` 方法本身
- [x] [0.14.0-QA-C-000] 新增 `KimiAuthProviderTests`：过期 access_token 触发 refresh 后凭证文件字节级不变；未过期 access_token 完全跳过 refresh endpoint。`swift test` 207/207 通过（含新增 2 个）
- [x] [0.14.0-DOC-B-000] `README.md` Kimi 一行补充说明：只读消费凭证文件、5 小时/周额度依赖 `kimi` CLI 自己的登录态，长期显示登录过期时需手动 `kimi login`

> **后续追加（同一 phase 内，用户实机截图反馈）**：上面的 `persistCredentials` 修复上线后，用户反馈
> Kimi dropdown 里仍然只看到月额度，且 Work 额度条样式（无节奏指示点）跟其他 provider 不一致——追查后
> 发现是两个独立的遗留问题，跟 `persistCredentials` 无关：
> 1. `KimiSubscriptionParser`（`kimi-desktop-token` 用的解析器）一直不写 `QuotaWindow.resetsAt`，
>    当初是为了避开一个"用 `resetsAt` 推断 `subscriptionExpiresAt`"的 fallback（见 0.6.0-DATA-A-002），
>    但那条 fallback 早在 0.6.0 就整个删掉了，顾虑已经过期——代码没跟着清，导致 v0.14.0 新加的节奏
>    指示点（sub/main 见上）在 Kimi 上永远没有数据可画。
> 2. `kimi-webview` 兜底层请求的端点 `GetSubscriptionStat`，用真实凭证直连验证后确认服务端已经
>    **404**（下线了）——未授权时表现为"未登录"，掩盖了"即使授权了也一样会失败"这个事实。
>
> 排查过程中一度怀疑修复没生效，最后定位到是本机同时跑着两个 QuotaBar 进程（一个是前一天的旧包、
> 一个是当次验证用的 `swift run`），共享同一份 `snapshots.json`/`provider-check.log`，旧进程的过期
> 写入覆盖了新进程的正确结果——不是代码问题，是本地验证环境污染，记录下来避免以后再被同样的假象
> 误导排查方向。

- [x] [0.14.0-BUG-B-000] `KimiSubscriptionParser.parse` 的 Work 窗口把 `resetsAt` 从 `nil` 改成
  `expireTime`（`refreshDescription` 早就在用同一个日期，写进 `resetsAt` 不引入新的不确定性）
- [x] [0.14.0-BUG-B-001] `DashboardEndpoints.endpoint(for: .kimi)`（`kimi-webview` 用的端点）从
  `GetSubscriptionStat` + `KimiSubscriptionStatParser` 改成跟 `KimiDesktopTokenProvider` 一致的
  `GetSubscription` + `KimiSubscriptionParser`
- [x] [0.14.0-QA-C-001] `KimiSubscriptionParserBalancesTests` 更新第一个测试的 `resetsAt` 断言；
  `swift test` 217/217 通过

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260718-214500-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260718-214500-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> （附截图：应用内「检查更新」报错「无法连接到 GitHub，请检查网络」）
> （附两份 ChatGPT 对话导出：第一份讨论更新检查大陆可达性问题，第二份讨论商业模式——开源自行编译 vs 官方付费版）
>
> 帮我完成下列 4 个任务，总是用中文回答我。执行之前，先把任务需求记录到 requirements 里面。
>
> 1. 更新检查/下载改成两步兜底：优先 GitHub，失败则自动访问 Vercel（Vercel 上应该总是能获取到最新的包）。
> 2. 新增功能：dropdown 的额度进度条上标识出「根据当前剩余时间推荐的使用量」节奏指示点（简洁、不张扬）。
> 3. Kimi 现在只能拿到月额度，拿不到 5 小时和周额度。
> 4. 官网 pricing 区块改成两张并排卡片：GitHub 免费自行编译 + 付费可下载版本（付费版激活功能本身先不做）。
> 5. 为 Vercel 网站补内容，解决 Creem 付款渠道审核不通过的问题（Privacy/Terms 死链接、页脚 Compare/Manage License/Affiliate 死链接）。
>
> （用户原文写"4 个任务"但实际列出 5 条，均已按 5 条独立事项处理，未追问此处的计数出入。）

#### 完成工作

- **macOS App**（`macos/Sources/QuotaBar/`）：
  - `KimiAuthProvider.swift`：移除写回凭证文件的逻辑，改为纯只读消费者。
  - `QuotaModels.swift`：`QuotaWindow` 新增 `idealRemainingFraction(relativeTo:)`。
  - `MenuView.swift`：`ProgressPill` 新增 `paceMarkerFraction` 参数 + 渲染逻辑，`QuotaRow` 接入。
  - `UpdateChecker.swift`：GitHub → Vercel 两步兜底（检查更新 + 下载 + 校验失败重试）。
  - `PreferencesStore.swift`：新增 `init(fileURL:)` 测试专用入口。
  - 新增测试：`KimiAuthProviderTests.swift`、`QuotaWindowTests.swift`、`UpdateCheckerFallbackTests.swift`（共 14 个新测试）。`swift test` 217/217 通过。
- **Vercel Functions**（仓库根目录新增）：`api/latest-release.mjs`、`api/download-latest.mjs`、`api/_lib/releases.mjs`。
- **官网**（`site/`）：
  - `src/pages/privacy.astro`、`src/pages/terms.astro`（新文件，中英双语）。
  - `src/components/Footer.astro`：修死链接、删 PRODUCT 列。
  - `src/components/Pricing.astro`：单卡 → 双卡并排。
  - `src/pages/index.astro`：下载脚本加 GitHub → Vercel 兜底。
  - `src/i18n/dict.ts`：新增/清理约 40 个 key。
  - `npm run build` 通过。
- **基础设施**：`vercel.json` 新增 `devCommand`；`.claude/launch.json` 新增 `vercel-dev` 配置。
- **GitHub 仓库可见性变更**：`DDonlien/quota-bar` 从 private 改为 public（用户在 `AskUserQuestion` 中明确选择；执行前完整扫描 git 历史确认无真实密钥泄漏）。
- **文档**：根目录 `REQUIREMENTS.md` 新增 `v0.14.0` phase（任务 1/2/3）+ `README.md` 补一行 Kimi 说明；`site/REQUIREMENTS.md` 新增 `v0.3.0` phase（任务 4/5），并记录了 `site/DESIGN.md` 相对当前实现已经漂移的既有事实（未在本次回溯修复，超出本次任务范围）。

#### 更新的需求 ID

- 根目录 `REQUIREMENTS.md`：`[0.14.0-BE-A-000]`、`[0.14.0-BE-A-001]`、`[0.14.0-FE-A-000..002]`、`[0.14.0-QA-A-000..001]`、`[0.14.0-DATA-B-000]`、`[0.14.0-FE-B-000..001]`、`[0.14.0-QA-B-000]`（`QA-B-001` 手动目测项 `#blocked`，留给用户实机确认视觉效果）、`[0.14.0-BUG-A-000]`、`[0.14.0-QA-C-000]`、`[0.14.0-DOC-B-000]`。
- `site/REQUIREMENTS.md`：`[0.3.0-UI-A-000..002]`、`[0.3.0-QA-A-000]`、`[0.3.0-CONTENT-A-000..001]`、`[0.3.0-FE-C-000]`、`[0.3.0-QA-B-000]`（`DOC-A-000` DESIGN.md 纠偏未做，仅记录漂移事实）。

#### 验证方式

- `swift build` + `swift test`：217/217 通过（含本次新增 14 个）。
- `npm run build`（site/）：通过，生成 4 个页面含新增的 `/privacy`、`/terms`。
- Vercel Functions：本地 `node` 直接调用 + `vercel dev`（通过 Browser 面板）双重验证，真实 GitHub 数据全链路字节级核对一致。
- 官网下载兜底逻辑：Browser 面板里用 monkeypatch `fetch` 模拟 GitHub 不可达，确认真的切到 Vercel 代理链接。
- Pricing 两卡布局：`getBoundingClientRect()` 精确几何验证桌面并排/移动堆叠两种断点（screenshot 工具本轮有滚动后偶发失败的环境问题，已改用等效的 DOM 几何验证代替，问题已记录）。
- Privacy/Terms 页面：Browser 面板实测中英文两个语言版本内容完整渲染，页脚死链接清零（全站 grep 确认）。
- 未做：macOS 端节奏指示点、Kimi 修复未在真实过期的 kimi CLI 会话上做端到端复测（后者需要用户重新 `kimi login` 才能验证，不是代码能单方面验证的）。

#### 备注

- 本次仓库可见性变更（private → public）是应用户明确选择执行的，执行前做了历史扫描但不构成法律意义上的"这个仓库绝对不含任何敏感信息"的保证——如果用户后续发现历史提交里有不想公开的内容，可能需要 BFG/filter-repo 级别的历史重写（超出本次任务范围，未处理）。
- Privacy/Terms 文案是尽力而为的合理起点，用于解除 Creem 审核的死链接问题，不是律师审阅过的正式法律文件；条款里"官方版定价/授权细节待最终确定"是有意留白，避免在用户自己还没决定 Creem vs 自建授权体系之前抢先做出具体承诺。

---

#### 补充 prompt（2026-07-18 21:58 +0800）

> "do it"（用户对"要提交、打包、部署官网吗"的确认）

#### 补充执行记录

按用户确认，把上述 5 项改动拆成 5 个按主题划分的 commit（`3610061` 更新兜底、`11e5086` Kimi 修复、`4fdf89e` 节奏指示点、`09cd69d` 官网双卡+法律页、`3fe2684` 文档），推到 `origin/main`。

`git push` 同时触发了 GitHub Actions（CI + Release 两个 workflow）和 Vercel 的 git 集成部署：
- **Vercel**：自动构建部署成功（`dpl_5iekAqXx9Hre3kAFsdwc21niwikv`，`state: READY`），不需要额外操作。
- **CI workflow 失败**（`macos-14`/`macos-15` runner 报 `package 'macos' is using Swift tools version 6.2.0 but the installed version is 5.10.0`）——核实过这是**跟本次改动完全无关的既有问题**：`Package.swift` 要求 Swift 6.2，但 `ci.yml` 用的 runner 镜像（`macos-14`/`macos-15`）预装的还是 Swift 5.10；`release.yml` 用的是 `macos-26`，工具链版本对得上。未处理（不在本次任务范围，且是纯 CI 配置问题，修复方案是把 `ci.yml` 的 runner 也换成 `macos-26`，留给用户或后续任务决定）。
- **Release workflow 第一次也失败**，但原因是另一个真实、跟本次 5 项任务无关的既有 bug：`build-app.sh` 早前一次"仓库整理"改成把产物输出到 checkout **父目录**下的 `_builds/latest`（配合本机"`main` + 平级 worktree 目录"布局），但 `.github/workflows/release.yml` 的"Build .dmg"步骤还在找旧路径 `$GITHUB_WORKSPACE/macos/build/latest`——从那次改动之后，Release 应该一直在这一步失败。这个 bug 直接挡住了本次"打包部署"的验收，且修复范围极小、明确（改一行路径），所以单独开一个 commit（`b57b78b`）修掉并重新推送，未跟前面 5 个 commit 混在一起。

第二次 Release run（`29647287531`）Swift build + 打包 + 发布全部成功，生成 `v0.10.0-b57b78b` release。用真实请求核对了完整链路：GitHub Release 的 dmg 资产 2,588,312 字节；`https://quotabar.ddonlien.com/api/latest-release` 认出的最新 tag 就是 `v0.10.0-b57b78b`；`https://quotabar.ddonlien.com/api/download-latest` 返回同样 2,588,312 字节；`https://quotabar.ddonlien.com/privacy`、`/terms` 都是 HTTP 200。本次会话新增的 GitHub → Vercel 兜底链路，以及官网的 Privacy/Terms/双卡改动，都已经在生产环境验证通过，不只是本地。

本地 `make app` 打的包（`0.10.0-3fe2684`，在提交 CI 修复之前）已经被这次真正的 CI 发布（`0.10.0-b57b78b`）取代，仅作为发布前的快速验证用途，未再单独处理。

#### 补充完成工作

- `.github/workflows/release.yml`：修正 dmg 打包步骤的 `APP` 路径，从旧的 `$GITHUB_WORKSPACE/macos/build/latest` 改为 `$(dirname "$GITHUB_WORKSPACE")/_builds/latest`，对齐 `build-app.sh` 实际的产物位置。
- 5 个功能 commit + 2 个 CI 修复 commit 已推送到 `origin/main`。
- 官网已通过 Vercel 自动部署上线；macOS App 新版本已通过 GitHub Release 发布（`v0.10.0-b57b78b`）。

#### 补充（2026-07-18 22:10 +0800）：CI workflow runner 版本修复

用户追问"CI WORKFLOW 是什么"，说明后用户确认"顺手修了"。`ci.yml` 的 `macos-14`/`macos-15` 矩阵改成单一 `macos-26`（跟 `release.yml` 保持一致），去掉了已经没有实际验证价值的双系统矩阵（两边工具链都太旧，`swift package resolve` 一步就全灭）。推送后确认 CI 转绿（`29648586058`，1m14s 通过）。commit `220b4f9`。
