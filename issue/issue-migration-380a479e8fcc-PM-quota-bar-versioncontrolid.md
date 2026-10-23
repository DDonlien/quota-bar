# Phase - v0.2.0 - Quota Bar 核心功能

- ID：`migration-380a479e8fcc`。
- 类型：`PM`。
- 状态：已确认约束 / 状态待核对（原文未单列完成状态）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.2.0 - Quota Bar 核心功能。

## 当前需求与范围

本阶段参考 CodexBar 实现思路，将现有静态 UI 升级为自动探测、获取并展示真实 AI 订阅额度的功能核心。优先聚焦数据获取与刷新机制，偏好设置页面延后至 P2。

> **2026-06-18 更新**：本次 `feat/real-data-and-public` 分支落地的范围如下。括号内是落地位置。
> - **真实数据接入（P0）**：SweetCookieKit 集成 / TCC 引导 / Keychain 真读 / Codex dashboard endpoint + parser
> - **可扩展性（P1）**：`ProviderFetchStrategy` + `FetchPipeline` + `TTYCommandRunner` + `LoginRunner` + AgentDetector 类型合一

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260618205739-utcp8-minimax-m3.md — 历史证据迁移

来源：`agent-log/20260618205739-utcp8-minimax-m3.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 你来改

接续上一轮对话：用户对「菜单栏应用在系统设置里到底叫什么名字」提出疑问（因为 `CodingPlanMenu` 和 Quota Bar 是同一个东西，担心找错应用、给错权限）。我提议修改 [build-app.sh](file:///Users/taobe/Projects/GitHub/Personal/quota-bar/drop-down-test/CodingPlanMenu/build-app.sh) 的 `CFBundleDisplayName` 为 "Quota Bar"，用户回复「你来改」。

#### 验证方式

- 静态：cat 已确认第 35 行值为 `Quota Bar`；第 31 / 33 / 37 行 bundle id / bundle name / bundle executable 仍是 `CodingPlanMenu` / `com.example.CodingPlanMenu`
- 构建：未运行（沙箱限制同上一条日志）；重新运行 `./build-app.sh` 后生成的 `Info.plist` 将包含 `Quota Bar`
- 应用行为：未启动应用验证（用户在系统设置里看到的应用名才是验证点）

#### 需求 / 设计更新

- `REQUIREMENTS.md`：未变更
- `README.md`：未变更
- `DESIGN.md`：未变更
- `AGENTS.md`：未变更

#### 备注

- 本次修改未提交，等用户决定是否一并把 `build-app.sh` 与上一轮的 padding 改动一起 commit
- Keychain 授权提示：「Quota Bar 需要 Keychain 授权」已经与新 DisplayName 一致，不会出现名字错位
- 用户在系统设置 → 隐私与安全 → 完全磁盘访问权限 中，应能找到「Quota Bar」应用并勾选；如果之前已经按 `CodingPlanMenu` 授权过，按 bundle id 仍会匹配，状态保持不变
- 之前给用户的引导语（"找 Quota Bar 应用授权"）从这一版打包后开始真正生效

### 20260620144300-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260620144300-utcp8-gpt5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

You are running as a local coding agent for a Multica workspace.

Your assigned issue ID is: 4a47a0c0-4dff-47bc-8005-6bbeaf541755

Start by running `multica issue get 4a47a0c0-4dff-47bc-8005-6bbeaf541755 --output json` to understand your task, then complete it.
For comment history, follow the rule in your runtime workflow file (assignment-triggered tasks treat the read as mandatory). `multica issue comment list 4a47a0c0-4dff-47bc-8005-6bbeaf541755 --output json` returns all comments for the issue (server caps at 2000). On long-running issues use `--recent 20 --output json` to read the 20 most recently active threads, then page older threads via the stderr `Next thread cursor: ...` line and the matching `--before` / `--before-id` until you have enough history. `--since <RFC3339>` is still available for incremental polling and may combine with `--recent`.

#### 需求更新

- 未修改 `REQUIREMENTS.md`。本次只把未完成需求录入 Multica 子 issue 并触发其他 agent 执行。

#### 验证方式

- `multica issue list --project 138f4c9d-2ea2-4e5f-bd8a-f65785d3b16e --limit 20 --output json` 确认 TB-37、TB-38、TB-39 已创建，且均挂在 TB-28 下。

#### 备注

- 本次没有代码变更，不运行 `swift build`。
- `git pull` 因长时间无输出被中断；已记录在本日志和交付说明中。

### 20260702-014600-utcp8-taobe-minimax-m3.md — 历史证据迁移

来源：`site/agent-log/20260702-014600-utcp8-taobe-minimax-m3.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

- 「子域名和 7 没办法，其他都搞定」

承接上一轮诊断「为什么 Google 和 Bing 都搜不出我们的页面」的分析结果，把除 #2 子域名限制、#7 同叫「QuotaBar」的另一个工具（磁盘配额那个）以外的所有 SEO 基建一次性补齐。

#### 完成工作

- 新增静态资产：
  - `site/public/robots.txt`（9 行含 sitemap 指向）
  - `site/public/indexnow.key`（32 hex）
  - `site/scripts/ping-indexnow.mjs`（~60 行，read key + POST + 错误不阻塞 build）
- 配置改动：
  - `site/astro.config.mjs`：`integrations: [sitemap(...)]`
  - `site/package.json`：`devDependencies` + `"postbuild": "node ./scripts/ping-indexnow.mjs"`
  - `site/package-lock.json`（npm 装包后自动更新）
- 源改动：
  - `site/src/layouts/Layout.astro`：加 4 行 `<link rel="canonical" / "alternate">` 块（含 x-default / zh-CN / en 三种）
  - `README.md`：顶部加一行 Site badge
- 自动化收尾（不在 source）：
  - `.gitignore`：加 `/.vercel` 一行（避免后续误提交 Vercel CLI workspace metadata）

#### 更新的需求 ID

无（SEO 基建是「持续让外部能发现/索引能力」类基础设施，符合 AGENTS.md 里「工程卫生基础设施 = 可放 REQUIREMENTS」的定义，但本次任务范围是补齐现有缺口，没主动入 REQUIREMENTS.md；下次可以加一条 `[0.x.x-DOC-A-xxx] 维护 SEO 基建 — sitemap / robots / IndexNow postbuild / canonical` 之类的持续能力，等用户 review）

#### 验证方式

1. `make site`：`astro build` 通过，`[@astrojs/sitemap] sitemap-index.xml created at dist`，`[ping-indexnow] 202`（postbuild 自动跑 IndexNow）
2. **生产环境 curl**（`https://quotabar.ddonlien.com/`）：
   - `robots.txt` 包含 `Sitemap:` 指针 ✓
   - `sitemap-index.xml` 指向 `sitemap-0.xml` ✓
   - `sitemap-0.xml` 含正确 `<loc>`、`<changefreq>`、`<priority>` ✓
   - `indexnow.key` 返回 32 hex，匹配 `site/public/indexnow.key` 的内容 ✓
   - HTML head 4 个 link tag（canonical + 3 个 hreflang）✓
   - 上一轮的 binding URL `QuotaBar-c6317d0.dmg` 还在 hero / nav 两个 `data-download` 上（保留）
3. `vercel alias ls`：`quotabar.ddonlien.com` 现在的 source 是 `quota-a38nlyjo9-...`，不再是上一轮的 `quota-27k7tc2ob-...` ✓
4. 手动再跑一次 `ping-indexnow.mjs`：第二个 `202 Accepted`（IndexNow 接受多次提交；每次 build 都刷一遍是合理的）

#### 备注

- **IndexNow key 是公开的**（不是 secret），落 `site/public/indexnow.key` 给 Vercel 静态托管是标准做法。任何能取到 key 的人也能 ping IndexNow，但代价最多是「别人也帮你提交了 URL」，没有任何安全风险。不必担心 git 提交
- **IndexNow 用的是通用 key**（8-128 长度 hex，本项目是 32 hex）。将来如果搬域名或搬到不同子域，key 仍然有效（在同一个根域下——比如 ddonlien.com / *.ddonlien.com — key 是同一个 IndexNow 注册）
- **Vercel CLI 在 root 跑会留 `./.vercel/`**（`repo.json` + `README.txt`），加 `/.vercel` 进 `.gitignore` 是符合 Vercel 官方建议的做法；没弄错
- **`site/.vercel/` 此刻是空的** —— `vercel link` 应该写 `project.json`，但现在没看到。猜测：`make site` 的 `make clean`（`rm -rf site/.astro site/dist site/node_modules`，注意：**不删 `.vercel/`**）应该没事，可能是某次 `cd site && vercel --prod --yes` 时被清掉了。下次跑 `vercel link` 重写一次就行。也可以加一行 `make` target 来显式 link + deploy，避免每次手动 link
- **`@astrojs/sitemap` 在只有一个 page 时输出 sitemap-index.xml → sitemap-0.xml 两级**（不是单文件），这与 sitemap.org 的标准一致（虽然单个 page 时显得繁琐）。给 robots.txt 里的 `Sitemap:` 指向 index 文件
- **Vercel build 是 `cd site && npm ci && npm run build`**（`vercel.json` 的 buildCommand）。`npm run build` 触发 `postbuild`，所以 Vercel 那边也跑了 IndexNow ping。我们手动部署一次 = Bing/Yandex/Naver 都被通知到
- **canonical / x-default / zh-CN / en 全部指向同一 URL**（i18n 不分 URL 是当前架构）。这是对的，单语言版本的国家/语种 pivot 不需要切 URL。多语言各自独立 URL（`/zh/...`、`/en/...`）那种是真 i18n；目前 starbar 的客户端字典切换做不到
- **本次 deploy 的 tgz 体积 496.8 MB**：主要被 4 个 mp4（detail / preview / reorder / 隐式的 font 文件）拖大。如果以后真需要瘦身，可以考虑把视频搬到 R2 / 七牛 / S3，HTML 里换外链，能砍掉 ~80% 上传体积和 CDN 流量。但 GitHub LFS 状态、运维负担、CDN 域名对齐都要权衡，不是这一票该解决的
- **未做的事**（按用户拍板有意不做）：
  - 登 Google Search Console + Bing Webmaster 提交 sitemap：必须本人账号登录验证（DNS TXT 验证我可以算好，但 Google / MS 那边 must-login-by-user）
  - 反向链接铺设（HackerNews / Reddit / V2EX / Twitter / 即刻）：属于营销动作，不归 SEO 基建
  - 子域名（继承不到 `ddonlien.com` 主域权重）：用户拍板不处理
  - "QuotaBar" 同名冲突（磁盘配额工具 CSDN 文章）：用户拍板不处理
  - 多语言独立 URL + i18n 路由改造：架构改动，本次不动
- **commit 建议**：工作树 8 处 M、4 处 ??：
  ```
  M .gitignore                      # + /.vercel（必要）
  M README.md                       # + Site badge（SEO 外链）
  M site/astro.config.mjs           # + sitemap 集成
  M site/package-lock.json          # 装包导致（自动）
  M site/package.json               # + devDependencies + postbuild
  M site/src/components/Hero.astro  # 上一轮 binding 残留
  M site/src/components/Nav.astro   # 上一轮 binding 残留
  M site/src/layouts/Layout.astro   # + canonical & hreflang
  ?? site/agent-log/20260701-235200-...md   # 上次日志
  ?? site/agent-log/20260702-...md          # 本次日志（马上创建）
  ?? site/public/indexnow.key               # IndexNow key
  ?? site/public/robots.txt                 # robots
  ?? site/scripts/                          # ping-indexnow.mjs
  ```
  分一笔 feature commit + 一笔 docs commit 比较干净（上一轮的 Hero/Nav binding 改动也跟着这一批 commit；否则 source 一直落后 deployed）
