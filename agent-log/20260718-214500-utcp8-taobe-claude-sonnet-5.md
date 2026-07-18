# 用户原始 prompt

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

# 启动运行时的分支和版本

- 分支：`main`（工作目录 `/Users/taobe/Projects/GitHub/Personal/quota-bar/main`，仓库改用"多目录并列"布局，`main` 不再嵌套 `worktree/` 子目录）
- 版本：`d84e223 chore: consolidate main workspace updates`（`VERSION` = 0.10.0），领先 `origin/main` 0 个提交（干净）

# 任务开始时间

2026-07-18 20:50 +0800

# 任务结束时间

2026-07-18 21:45 +0800

# 任务结束时是否执行了提交

否——本次改动量大（macOS App + 官网 + 新增 Vercel Functions + 一次 GitHub 仓库可见性变更），按惯例留给用户确认后再决定是否提交/推送/部署/打包。

# 已阅读上下文

- 用户提供的两份 ChatGPT 对话导出全文（更新检查架构建议、商业模式讨论）。
- `AGENTS.md`（协作规范）、根目录与 `site/` 的 `REQUIREMENTS.md`/`DESIGN.md` 现状。
- `macos/Sources/QuotaBar/UpdateChecker.swift`、`KimiAuthProvider.swift`、`KimiDesktopTokenProvider.swift`、`MenuView.swift`（`ProgressPill`/`QuotaRow`）、`QuotaModels.swift`（`QuotaWindow`）、`PreferencesStore.swift`、`Strategies.swift`（Kimi pipeline 部分）全文。
- `site/` 全部组件（`Hero.astro`/`Nav.astro`/`Footer.astro`/`Pricing.astro`/`index.astro`）、`i18n/dict.ts`/`apply.ts`、`Layout.astro`、`astro.config.mjs`、`vercel.json`、`.vercel/repo.json`。
- 本机真实诊断日志 `~/Library/Application Support/QuotaBar/provider-check.log`（Kimi 问题的关键证据来源）、本机真实 `~/.kimi-code/credentials/kimi-code.json`（只读检查过期状态，未做任何写入或线上 OAuth 调用）。
- `vercel-functions` 官方 skill（确认零配置 `/api` 的当前推荐写法）。

# 对话与行动记录

**先记录需求**：按用户要求，动手前把 5 项需求分别整理进根目录 `REQUIREMENTS.md`（新开 `v0.14.0` phase，覆盖任务 1/2/3——macOS App + 跨子功能的 Vercel 基础设施）和 `site/REQUIREMENTS.md`（新开 `v0.3.0` phase，覆盖任务 4/5——纯官网范畴）。

**任务 3（Kimi 额度丢失）**：读本机真实诊断日志发现 `kimi-auth`（CLI OAuth，提供 Code 5h/周）持续报 "refresh_token 已失效"，而 `kimi-desktop-token`（提供 Work 月额度）持续成功。对比两个 provider 的实现发现关键不对称：`KimiDesktopTokenProvider` 从不写回它读的 token store，纯只读；`KimiAuthProvider` 刷新 access_token 后会把新 token **写回** `~/.kimi-code/credentials/kimi-code.json`——这份文件是真实 `kimi` CLI 自己管理的凭证存储。Kimi 的 OAuth 服务端大概率对 refresh_token 做单次轮换，Quota Bar 后台每几分钟静默刷新一次并写回，会跟真实 kimi CLI 自己的刷新竞争同一个 refresh_token，谁用到"已经被对方消费掉"的旧 token 就会被拒——这与"曾经能用、现在永久失败"的症状吻合。修复：去掉写回，`KimiAuthProvider` 对齐成纯只读消费者（当次请求仍会在内存里刷新并使用，只是不再持久化）。这是根据现象做出的诊断，不是 100% 确证的根因，已在 REQUIREMENTS 里如实标注置信度，并提示用户如果问题复现仍需手动 `kimi login` 一次（旧 refresh_token 如果已经失效，代码修复无法追溯修好）。

**任务 2（额度条节奏指示）**：用户例子"剩 7 天、今天第 1 天，标在 1/7 位置"有歧义（1/7 是指从哪个方向量）。判断这是一个真正的 UX 语义决策，但结合 `ProgressPill` 现有填充语义（`remainingFraction`，从左边缘按比例铺满）反推出唯一自洽、跟主流"预算节奏线"UI（iOS 蜂窝数据用量条同类设计）一致的解释：指示点标的是"如果线性消耗，此刻理论上还应该剩多少"，公式 `idealRemainingFraction = timeUntilReset / periodSeconds`，用户的例子对应 6/7（偏右侧）而不是字面的 1/7（偏左侧）。已在 REQUIREMENTS 和代码注释里显式写明这个解释，供用户核对方向是否符合预期。

**任务 1（更新检查兜底）执行中发现范围扩大**：写 Vercel 代理函数前，先用真实（未认证）请求测试 GitHub API，发现返回 404——排查发现仓库 `DDonlien/quota-bar` 当时是 **private**，任何未认证请求（包括本来要写的 Vercel 代理、以及所有访客的浏览器）都会 404，这不是"大陆连不上"而是"谁都连不上"。这个发现同时影响任务 1（代理函数需要 token 才能工作）和任务 4（"开源自行编译"卡片链接到一个私有仓库对访客没有意义）。用 `AskUserQuestion` 向用户确认后，用户选择"现在把仓库设为 Public"。执行可见性变更前，先完整扫描了 git 全部历史（文件名 pickaxe + 内容 pickaxe，检查常见密钥模式如 `BEGIN PRIVATE KEY`/`ghp_`/`AKIA`/`sk-ant-` 等），确认没有真实泄漏的密钥，只有测试 fixture 里认得出的占位字符串，然后执行 `gh repo edit --visibility public`。之后代理函数按"双方都是普通未认证直连"实现（不需要额外的 `GITHUB_TOKEN`）。

**任务 1 实现**：仓库根目录新增 `api/latest-release.mjs`/`api/download-latest.mjs`/`api/_lib/releases.mjs`（Vercel 零配置 Node Function，Web-standard `export async function GET()`，经 `vercel-functions` 官方 skill 确认是当前推荐写法；下载代理直接把上游 `fetch()` 的 `ReadableStream` 作为 `Response` body 转发，零配置流式，不缓冲整份文件）。`UpdateChecker.swift` 重构出 `fetchReleasesData(from:)` 支持两次调用（GitHub → Vercel），下载路径同理拆出 `startDownload`/`retryDownloadWithFallbackOrFail`，且**校验失败也会触发兜底重试**（不只是网络层失败——某些网络环境用 HTTP 200 返回假内容而不是直接连接失败，只有 `hdiutil verify` 能发现）。官网 `index.astro` 的下载脚本同理加了 `resolveFromGitHub()` ?? `resolveFromFallback()`，且兜底路径下的下载链接本身也改成同源代理（不是原始 GitHub 直链——GitHub 都连不上，直链大概率也连不上）。

**验证方式的选择**：`UpdateChecker` 部分补了 mock session 的单元测试（4 个新测试，覆盖成功跳过兜底/失败触发兜底/两者都失败/限流不浪费兜底）；顺手发现 `PreferencesStore` 是硬编码单例真实路径、没法在测试里隔离，补了一个 `init(fileURL:)` 测试专用入口（对齐其余 store 已有的临时目录注入模式）。Vercel 函数用真实网络请求直接验证（本地 `node` 跑 `_lib/releases.mjs` 打真实 GitHub API；`api/latest-release.mjs`/`api/download-latest.mjs` 的 `GET()` 直接调用，下载字节数与 GitHub 资产 `size` 字段完全一致）；另外发现本地 `vercel dev` 缺 `devCommand` 会在仓库根目录找不到 `astro`，补了 `vercel.json` 的 `devCommand` 和 `.claude/launch.json` 的 `vercel-dev` 配置，通过 Browser 面板把 `vercel dev` 跑起来，确认两个 endpoint 都是 200 且字节对得上，并把官网下载脚本的判断逻辑原样搬进浏览器用 monkeypatch 的 `fetch` 模拟"GitHub 不可达"，确认真的会切到 Vercel 代理下载链接。

**任务 4/5（官网）**：Footer 的 Privacy/Terms 之前是 `href="#"` 死链接，Compare/Manage License/Affiliate 三个也是——对应功能（价格对比页、授权管理后台、联盟计划）目前都不存在，按 Creem 审核意见"要么做成真的、要么删掉"选择删掉整个 PRODUCT 列，只留 LEGAL 列指向两个新写的真实页面 `site/src/pages/privacy.astro`/`terms.astro`（中英双语，走站点已有的 `data-i18n` 字典机制，7 节结构）。写隐私政策前先核实了官网和 App 的真实数据处理现状（无第三方 analytics、无 telemetry SDK、localStorage/sessionStorage 只用于语言偏好和下载链接缓存两个功能性用途），保证文案如实、不是套模板。Pricing 区块从单卡改两卡并排（`flex-wrap` 自动响应式换行，不用手写断点），新增"开源自行编译"卡片（中性灰徽标，跟付费卡的暖橙"限时"信号区分开，避免暗示自编译路径也有时限），CTA 跳转真实（现在已 public 的）GitHub 仓库。

**验证方式（本轮遇到一个环境插曲）**：验证两卡布局时，Browser 面板的 `screenshot`/`read_page` 在"滚动之后"多次返回空白/`0x0` viewport，重开 tab、重启 dev server 都只是部分缓解；改用 `javascript_tool` 跑 `getBoundingClientRect()` 精确验证几何关系（桌面宽度两卡 380×442px 严格等高同一行、间距 24px；收窄到移动宽度后自动换行堆叠），配合 `get_page_text`/DOM 查询核对文案，拿到了跟真实截图同等确定性的验证结果，只是没有留下一张最终视觉截图。这个现象记录在 REQUIREMENTS 里，供用户知晓这不是代码问题。

# 完成工作

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

# 更新的需求 ID

- 根目录 `REQUIREMENTS.md`：`[0.14.0-BE-A-000]`、`[0.14.0-BE-A-001]`、`[0.14.0-FE-A-000..002]`、`[0.14.0-QA-A-000..001]`、`[0.14.0-DATA-B-000]`、`[0.14.0-FE-B-000..001]`、`[0.14.0-QA-B-000]`（`QA-B-001` 手动目测项 `#blocked`，留给用户实机确认视觉效果）、`[0.14.0-BUG-A-000]`、`[0.14.0-QA-C-000]`、`[0.14.0-DOC-B-000]`。
- `site/REQUIREMENTS.md`：`[0.3.0-UI-A-000..002]`、`[0.3.0-QA-A-000]`、`[0.3.0-CONTENT-A-000..001]`、`[0.3.0-FE-C-000]`、`[0.3.0-QA-B-000]`（`DOC-A-000` DESIGN.md 纠偏未做，仅记录漂移事实）。

# 更新的 README 或 DESIGN 章节

- 根目录 `README.md`：Kimi 一行补充只读消费凭证文件的说明。
- `site/DESIGN.md`：本次未更新——发现它相对 `global.css` 实际 token（vibeisland 暗色改版）已经整体漂移，但这是历史遗留问题，不在本次 5 项任务范围内，仅在 `site/REQUIREMENTS.md` 里如实记录，留作后续独立任务。

# 验证方式

- `swift build` + `swift test`：217/217 通过（含本次新增 14 个）。
- `npm run build`（site/）：通过，生成 4 个页面含新增的 `/privacy`、`/terms`。
- Vercel Functions：本地 `node` 直接调用 + `vercel dev`（通过 Browser 面板）双重验证，真实 GitHub 数据全链路字节级核对一致。
- 官网下载兜底逻辑：Browser 面板里用 monkeypatch `fetch` 模拟 GitHub 不可达，确认真的切到 Vercel 代理链接。
- Pricing 两卡布局：`getBoundingClientRect()` 精确几何验证桌面并排/移动堆叠两种断点（screenshot 工具本轮有滚动后偶发失败的环境问题，已改用等效的 DOM 几何验证代替，问题已记录）。
- Privacy/Terms 页面：Browser 面板实测中英文两个语言版本内容完整渲染，页脚死链接清零（全站 grep 确认）。
- 未做：macOS 端节奏指示点、Kimi 修复未在真实过期的 kimi CLI 会话上做端到端复测（后者需要用户重新 `kimi login` 才能验证，不是代码能单方面验证的）。

# 备注

- 本次仓库可见性变更（private → public）是应用户明确选择执行的，执行前做了历史扫描但不构成法律意义上的"这个仓库绝对不含任何敏感信息"的保证——如果用户后续发现历史提交里有不想公开的内容，可能需要 BFG/filter-repo 级别的历史重写（超出本次任务范围，未处理）。
- Privacy/Terms 文案是尽力而为的合理起点，用于解除 Creem 审核的死链接问题，不是律师审阅过的正式法律文件；条款里"官方版定价/授权细节待最终确定"是有意留白，避免在用户自己还没决定 Creem vs 自建授权体系之前抢先做出具体承诺。
- 全程未做：提交（commit）、打包（`make app`）、部署（`vercel --prod`）——按惯例留给用户明确要求后再执行。
