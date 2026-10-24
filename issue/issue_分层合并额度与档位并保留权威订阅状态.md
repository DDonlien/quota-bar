# 分层合并额度与档位并保留权威订阅状态

- ID：`0.10.0-ARCH-B-000`。
- 类型：`ARCH`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 分组分层获取方案落地（5 agent × 4 信息）。
- 原稳定 ID：`0.10.0-ARCH-B-000`, `0.10.0-ARCH-B-000-test`, `0.10.0-ARCH-B-001`, `0.10.0-UI-C-000`, `0.10.0-ARCH-B-002`, `0.10.0-ARCH-B-003`, `0.10.0-ARCH-B-004`, `0.10.0-ARCH-B-005`, `0.10.0-DATA-B-005`, `0.10.0-UI-C-001`, `0.10.0-UI-C-002`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.10.0-ARCH-B-000`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.10.0-ARCH-B-000`、`0.10.0-ARCH-B-000-test`、`0.10.0-ARCH-B-005`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.10.0-ARCH-B-000-ARCH-agent-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：sub/main: 分组分层获取方案落地（5 agent × 4 信息）。
- 同源任务：[通过API与Headless来源补齐订阅到期日](issue_%E9%80%9A%E8%BF%87API%E4%B8%8EHeadless%E6%9D%A5%E6%BA%90%E8%A1%A5%E9%BD%90%E8%AE%A2%E9%98%85%E5%88%B0%E6%9C%9F%E6%97%A5.md)、[复用AppWebView会话并提供授权引导](issue_%E5%A4%8D%E7%94%A8AppWebView%E4%BC%9A%E8%AF%9D%E5%B9%B6%E6%8F%90%E4%BE%9B%E6%8E%88%E6%9D%83%E5%BC%95%E5%AF%BC.md)、[通过MiniMax真实CLI命令读取额度](issue_%E9%80%9A%E8%BF%87MiniMax%E7%9C%9F%E5%AE%9ECLI%E5%91%BD%E4%BB%A4%E8%AF%BB%E5%8F%96%E9%A2%9D%E5%BA%A6.md)、[恢复授权与偏好输入框的粘贴快捷键](issue_%E6%81%A2%E5%A4%8D%E6%8E%88%E6%9D%83%E4%B8%8E%E5%81%8F%E5%A5%BD%E8%BE%93%E5%85%A5%E6%A1%86%E7%9A%84%E7%B2%98%E8%B4%B4%E5%BF%AB%E6%8D%B7%E9%94%AE.md)、[恢复Dropdown偏好设置菜单入口](issue_%E6%81%A2%E5%A4%8DDropdown%E5%81%8F%E5%A5%BD%E8%AE%BE%E7%BD%AE%E8%8F%9C%E5%8D%95%E5%85%A5%E5%8F%A3.md)。

## 当前需求与范围

> 用户要求：现有 5 个 provider（Codex / Kimi / MiniMax / Antigravity / Z Code）的 4 种信息
> （安装情况、额度、过期日、档位和费用）都能正确获取，且用户最多只需在系统设置里做一次
> 常规操作（授予 Full Disk Access）。层级顺序：本地 API/RPC → CLI → 浏览器 Cookie（静默）→
> App 内 WebView 授权（一次登录，永久静默）。

- [x] [0.10.0-ARCH-B-000] `FetchPipeline.runSequential` 支持分层合并：首个成功来源做基底 snapshot，后续 strategy 只为缺失层（quota scope / plan）补数据；`expectedQuotaScopes` 声明 provider 完整额度的 scope 集合（Kimi = work + code）#P0 — `FetchPipeline.mergeLayers`
- [x] [0.10.0-ARCH-B-000-test] 分层合并测试：work-only 基底合并 CLI code 窗口、基底失败回退、同 scope 不重复追加 #P1 — `FetchPipelineLayeredMergeTests`
- [x] [0.10.0-ARCH-B-005] `QuotaFetchError.fallbackPriority`：`subscriptionExpired` / `notSubscribed`（服务端权威订阅状态）提升到最高优先级，管线全失败时不被权限/凭证类错误覆盖成「待配置」#P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260625113500-utcp8-glm5.md — 历史证据迁移

来源：`agent-log/20260625113500-utcp8-glm5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 2. 关键决策（AskUserQuestion 确认）

- **技术栈**：Astro 静态站（参考站点 vibeisland 同款，首屏极快、SEO 最佳）。
- **Hero 主打**：「菜单栏 progress bar 一眼看到额度」+「无配置无菜单极简交互」。
- **视觉素材**：先用纯 CSS/HTML mockup 占位，后续替换为真实截图。
- **目录位置**：根目录新建 `web/` 子项目。

#### 5. 验证

- `npm run build`：通过 ✅
- `npm run preview` + curl：HTTP 200，`<title>Quota Bar — AI 订阅额度，一眼可见</title>` ✅
- HTML 结构检查：含 35+ 处关键类名（dropdown / hero-mockup / menubar / provider / quota__fill），所有组件正确渲染 ✅

#### 完成工作

- 落地 `web/` Astro 营销主页首版，可直接 `vercel --prod` 部署。
- 核心视觉资产 `MenuBarMockup` 用纯 CSS/HTML 还原 macOS 26 菜单栏 + dropdown，带循环动画，不依赖任何截图。
- 6 家核心 provider（Antigravity / Codex / Claude / MiniMax / Kimi / Zcode）卡片网格，品牌色与 macOS 应用一致。
- 下载按钮动态指向最新 nightly DMG，带缓存和 fallback。
- 完整文档同步（web 子项目四件套 + 根目录索引）。

#### 更新的需求 ID

- `web/REQUIREMENTS.md` 新增 Phase `v0.1.0 - 主页首版`，含 PM-A / FE-A / UI-A / UI-B / FE-B / UI-C / DOC-A / QA-A 共 8 个任务区块、30+ 条 task，全部勾选完成（除 `0.1.0-QA-A-004` Vercel 部署 #deferred）。
- 根 `REQUIREMENTS.md` 顶部新增子功能索引指向 `web/REQUIREMENTS.md`。

#### 验证方式

- `cd web && npm install`：成功 ✅
- `cd web && npm run build`：成功，产出 `dist/`（约 76KB）✅
- `cd web && npm run preview` + curl 验证：HTTP 200，标题正确 ✅
- HTML 结构检查：35+ 处关键类名匹配，所有组件正确渲染 ✅
- Vercel 部署：**未执行**（由用户触发，命令已写入 `web/README.md`）。

#### 备注

- **GitHub 仓库地址**：`https://github.com/DDonlien/quota-bar`（从 `.git/config` 确认，README 原占位 `yourname` 已修正）。
- **Zcode 品牌色 `#3866ff` 为占位**：macOS 应用 `QuotaModels.swift` 当前 14 个 ProviderKind 里尚无 zcode，主页先行；应用接入 zcode 后需同步校准真实品牌色。
- **Provider 价格统一显示 `$20/月`**：mockup 演示用，非真实数据；真实价格映射逻辑在 macOS 应用 `ProviderPricing.localizedMonthlyPrice`。
- **未提交**：所有改动留在工作区，等待用户 review。`git status` 会显示新增的 `web/` 目录、根 `README.md` / `REQUIREMENTS.md` 修改。
- **部署步骤（用户执行）**：
  1. `cd web && vercel`（首次链接/创建项目，Root Directory 选 `web/`）
  2. `vercel --prod`
  3. Vercel 后台 → Settings → Domains → 添加 `quotabar.ddonlien.com`，按提示配置 DNS。
- **后续可替换项**：Hero / Showcase 的 MenuBarMockup 可换真实截图（放进 `web/public/`）；ProviderGrid 的品牌色方块可换真实 SVG logo。

### 20260629112200-utcp8-gpt5.md — 历史证据迁移

来源：`site/agent-log/20260629112200-utcp8-gpt5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 这里换行，然后 AI 做成一个动态效果，会删除然后又重新打字，新打出来的应该是橙色的各家 agent 的名字

#### 1. 需求解读

用户截图（reference 风格）里 Hero 标题是 "Never lose track of your AI quotas"。要求把 "AI" 换成**动态打字机效果**：
- 删除当前 → 重新打字
- 轮播的词 = Quota Bar 实际支持的 agent：`Antigravity / Codex / Claude / MiniMax / Kimi / Zcode`（共 6 个，从 `Layout.astro` description 提取）
- 新打出来的文字 = **橙色**

#### 4. 验证

用 Node + CDP（chrome remote debugging protocol）写了 12 行小脚本 `/tmp/cdp-screenshot.js`，在 0 / 500 / 1500 / 2500 / 4000 / 5500 / 8000ms 截 7 张图，同时通过 Runtime.evaluate 读 `data-typewriter` 的 textContent。

观察到的文字序列：
- 0ms: "Antigra"（打字中）
- 500ms: "Antigravity"（打完 + 光标）
- 1500ms: "Antigravity"（停留中）
- 2500ms: "Co"（已删完 Antigravity，开始打 Codex）
- 4000ms: "Codex"（打完 + 光标）
- 5500ms: "Claude"
- 8000ms: "MiniMax"

**结论**：✅ 打字机 + 删除 + 6 agent 轮播 + 橙色渐变 + 闪烁光标全部生效。

#### 完成工作

- Hero 标题改成 6 agent 名字轮播（Antigravity / Codex / Claude / MiniMax / Kimi / Zcode）
- 橙色渐变（`#f59e0b → #d97706`）打字机效果
- 闪烁光标
- 尊重 `prefers-reduced-motion`

#### 更新的需求 ID

未登记独立 requirement。如后续要为 v0.2.x 收尾时再补。

#### 验证方式

- `curl http://localhost:4321/` 验证 `data-typewriter="Antigravity|Codex|Claude|MiniMax|Kimi|Zcode"` 出现在 HTML 中
- Node + CDP 脚本（`/tmp/cdp-screenshot.js`，已删除）截 7 张图 + 读 textContent 验证状态机
- 截图保存在 `/tmp/website-screenshots/typewriter-*.png`

#### 备注

- 用 `<script is:inline>` 是必须的：参考上一轮 log，Astro 5 默认会重写 `<script>` 的 src，导致 Tailwind CDN 失效；同样问题会影响这里的打字机 JS
- 6 个 agent 名字直接来自 `Layout.astro` description 字段：Supports Antigravity, Codex, Claude, MiniMax, Kimi, Zcode
- 标题字号（`text-5xl md:text-6xl`）+ 父级 `text-center` + `max-w-4xl` 没改，宽度跳变对整体排版影响小
- product preview 图（macbook 笔记本）还没加载出来（Google user content URL 在 headless chrome 偶尔慢），但这不是本次修改影响

### 20260625113500-utcp8-glm5.md — 历史证据迁移

来源：`site/agent-log/20260625113500-utcp8-glm5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 2. 关键决策（AskUserQuestion 确认）

- **技术栈**：Astro 静态站（参考站点 vibeisland 同款，首屏极快、SEO 最佳）。
- **Hero 主打**：「菜单栏 progress bar 一眼看到额度」+「无配置无菜单极简交互」。
- **视觉素材**：先用纯 CSS/HTML mockup 占位，后续替换为真实截图。
- **目录位置**：根目录新建 `web/` 子项目。

#### 5. 验证

- `npm run build`：通过 ✅
- `npm run preview` + curl：HTTP 200，`<title>Quota Bar — AI 订阅额度，一眼可见</title>` ✅
- HTML 结构检查：含 35+ 处关键类名（dropdown / hero-mockup / menubar / provider / quota__fill），所有组件正确渲染 ✅

#### 完成工作

- 落地 `web/` Astro 营销主页首版，可直接 `vercel --prod` 部署。
- 核心视觉资产 `MenuBarMockup` 用纯 CSS/HTML 还原 macOS 26 菜单栏 + dropdown，带循环动画，不依赖任何截图。
- 6 家核心 provider（Antigravity / Codex / Claude / MiniMax / Kimi / Zcode）卡片网格，品牌色与 macOS 应用一致。
- 下载按钮动态指向最新 nightly DMG，带缓存和 fallback。
- 完整文档同步（web 子项目四件套 + 根目录索引）。

#### 更新的需求 ID

- `web/REQUIREMENTS.md` 新增 Phase `v0.1.0 - 主页首版`，含 PM-A / FE-A / UI-A / UI-B / FE-B / UI-C / DOC-A / QA-A 共 8 个任务区块、30+ 条 task，全部勾选完成（除 `0.1.0-QA-A-004` Vercel 部署 #deferred）。
- 根 `REQUIREMENTS.md` 顶部新增子功能索引指向 `web/REQUIREMENTS.md`。

#### 验证方式

- `cd web && npm install`：成功 ✅
- `cd web && npm run build`：成功，产出 `dist/`（约 76KB）✅
- `cd web && npm run preview` + curl 验证：HTTP 200，标题正确 ✅
- HTML 结构检查：35+ 处关键类名匹配，所有组件正确渲染 ✅
- Vercel 部署：**未执行**（由用户触发，命令已写入 `web/README.md`）。

#### 备注

- **GitHub 仓库地址**：`https://github.com/DDonlien/quota-bar`（从 `.git/config` 确认，README 原占位 `yourname` 已修正）。
- **Zcode 品牌色 `#3866ff` 为占位**：macOS 应用 `QuotaModels.swift` 当前 14 个 ProviderKind 里尚无 zcode，主页先行；应用接入 zcode 后需同步校准真实品牌色。
- **Provider 价格统一显示 `$20/月`**：mockup 演示用，非真实数据；真实价格映射逻辑在 macOS 应用 `ProviderPricing.localizedMonthlyPrice`。
- **未提交**：所有改动留在工作区，等待用户 review。`git status` 会显示新增的 `web/` 目录、根 `README.md` / `REQUIREMENTS.md` 修改。
- **部署步骤（用户执行）**：
  1. `cd web && vercel`（首次链接/创建项目，Root Directory 选 `web/`）
  2. `vercel --prod`
  3. Vercel 后台 → Settings → Domains → 添加 `quotabar.ddonlien.com`，按提示配置 DNS。
- **后续可替换项**：Hero / Showcase 的 MenuBarMockup 可换真实截图（放进 `web/public/`）；ProviderGrid 的品牌色方块可换真实 SVG logo。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
