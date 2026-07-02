# SEO bootstrap：让搜索引擎开始收录 Quota Bar 主页

## 用户原始 prompt

- 「子域名和 7 没办法，其他都搞定」

承接上一轮诊断「为什么 Google 和 Bing 都搜不出我们的页面」的分析结果，把除 #2 子域名限制、#7 同叫「QuotaBar」的另一个工具（磁盘配额那个）以外的所有 SEO 基建一次性补齐。

## 启动运行时的分支和版本

- 分支：`main`（root worktree）
- HEAD：`c6317d0 build(app): package latest main app`（上一轮 deploy 后没动 main）

## 任务开始时间

2026-07-02 01:35 (Asia/Shanghai)

## 任务结束时间

2026-07-02 01:46

## 任务结束时是否执行了提交

未提交。SEO 改动全部保留在 working tree，等用户 review 后再决定 commit / push。建议 commit 分两笔：
- `feat(site): SEO bootstrap — sitemap + robots + canonical + IndexNow + i18n hreflang`
- `docs(readme): 顶部加 Site badge 强化外链`

不过 `site/dist/` 已部署到生产（Vercel alias `quotabar.ddonlien.com` 现在指向新部署 `quota-a38nlyjo9`，而不是上一轮的 `quota-27k7tc2ob`），所以 source 落后于 deployed 是常态 —— 等用户 commit 就不一致了。

## 已阅读上下文

- 上一轮的 `agent-log/20260701-235200-utcp8-taobe-minimax-m3.md`（binding + 第一次 deploy 上下文）
- `site/astro.config.mjs`（已配 `site: 'https://quotabar.ddonlien.com'`；可直接喂给 sitemap 集成）
- `site/src/layouts/Layout.astro`（head 结构齐：title / description / og: / twitter:，缺 canonical & hreflang）
- `site/src/pages/index.astro`（之前 user 的 `UPDATE_DOWNLOAD` 客户端动态取最新 release 的 JS 在这）
- `site/src/components/Nav.astro` + `Hero.astro`（上一轮的下载按钮 binding 改动保留）
- `site/package.json`（只装 `astro`；无 `@astrojs/sitemap`；无 postbuild hook）
- 根 `README.md`（已经有 `https://quotabar.ddonlien.com` 出现，但只在「快速开始」段，顶部缺一个明显的 badge link）
- 根 `agent-template/AGENTS.md` + 根 `AGENTS.md`（协作规范）

## 对话与行动记录

1. **摸清现有 site 配置**：Astro config 已设 `site`，可接 `@astrojs/sitemap`；Layout.astro 缺 canonical / hreflang
2. **生成 IndexNow key**：`node -e "console.log(require('crypto').randomBytes(16).toString('hex'))"` → `4a2e358df210cf26c68de0dadf014d13`（写进 `site/public/indexnow.key`）
3. **`npm i -D @astrojs/sitemap`**：装出 3.7.3；记入 `site/package.json` `devDependencies`
4. **写静态资产**：
   - `site/public/robots.txt`（`User-agent: * / Allow: / / Sitemap: https://quotabar.ddonlien.com/sitemap-index.xml`）
   - `site/public/indexnow.key`（纯 key 文本，让 Vercel 静态托管它以满足 IndexNow 的 keyLocation 验证）
5. **接 sitemap 集成**：`astro.config.mjs` 加 `integrations: [sitemap({ changefreq: 'weekly', priority: 0.8 })]`；注释说明 hreflang 由 Layout.astro 手动声明（i18n 是同一 URL 不同 locale，不分页）
6. **Layout.astro 加 canonical & hreflang**：用 `new URL(Astro.url.pathname, Astro.site).href` 拼规范 URL；同时声明 `x-default` / `zh-CN` / `en` 三种 alternate，所有 alternate 都指向同一个 URL（因为 i18n 不换 URL）
7. **写 postbuild hook**：新建 `site/scripts/ping-indexnow.mjs`，行为：
   - 读 `site/public/indexnow.key`
   - key 不存在或格式异常就 `console.warn` 跳过（不阻塞 build）
   - POST `{ host, key, keyLocation, urlList: [site] }` 到 `https://api.indexnow.org/indexnow`
   - 2xx 打 ✓；4xx/5xx 打 ✗ 但不 fail build（best-effort）
   - 注册到 `site/package.json` 的 `postbuild` 字段（`npm run build` 自动触发）
8. **README 加 Site badge**：根 README 顶部加一排 shields.io badge：`[![Site](...website?url=https://quotabar.ddonlien.com)](https://quotabar.ddonlien.com)`，GitHub 渲染时既是显眼链接，也是首页爬虫可见的外链
9. **构建 + sitemap 自动产出**：`make site` → astro build → `@astrojs/sitemap` 打印 `sitemap-index.xml created at dist` → postbuild 自动跑 `ping-indexnow.mjs` → `IndexNow 202 Accepted`（Bing/Yandex 等秒级收录入队）
10. **部署到 Vercel**：
    - 第一波 `vercel --prod --yes`：在 upload 阶段撞 5000-file-rate-limit 报错
    - 第二波加 `--archive=tgz` 把 mp4 等打包 → 上传 OK → Vercel 跑 build（npm ci + npm run build）→ Production `https://quota-a38nlyjo9-taobe-team.vercel.app` → Aliased `https://quota-bar.vercel.app`
    - `vercel alias ls` 确认 `quotabar.ddonlien.com` 现在 alias 到 `quota-a38nlyjo9-...`
11. **线上端到端验证**（curl 直打域名）：
    - `robots.txt`：`User-agent: * / Allow: / / Sitemap: https://quotabar.ddonlien.com/sitemap-index.xml` ✓
    - `sitemap-index.xml` 引用 `sitemap-0.xml` ✓
    - `sitemap-0.xml` 含 `<loc>https://quotabar.ddonlien.com/</loc>` + `changefreq=weekly` + `priority=0.8` ✓
    - `indexnow.key` 返回 `4a2e358df210cf26c68de0dadf014d13`（keyLocation 验证用） ✓
    - HTML 头部：`<link rel="canonical">` + 3 个 `hreflang`（x-default/zh-CN/en）✓
12. **手动补一次 IndexNow ping**（保险）：再跑一次 `node scripts/ping-indexnow.mjs` → `202 Accepted`
13. **顺手发现 git diff 还动了 `.gitignore`**：加了 `.vercel` 一行 —— 是上一轮 `vercel rm` / `vercel ls` 在 root 跑时被 CLI 写的 workspace metadata（`./.vercel/repo.json` 等）。`.gitignore` 加它是对的

## 完成工作

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

## 更新的需求 ID

无（SEO 基建是「持续让外部能发现/索引能力」类基础设施，符合 AGENTS.md 里「工程卫生基础设施 = 可放 REQUIREMENTS」的定义，但本次任务范围是补齐现有缺口，没主动入 REQUIREMENTS.md；下次可以加一条 `[0.x.x-DOC-A-xxx] 维护 SEO 基建 — sitemap / robots / IndexNow postbuild / canonical` 之类的持续能力，等用户 review）

## 更新的 README 或 DESIGN 章节

- 根 `README.md`：顶部 badge 区域加 `Site` badge（指向 `quotabar.ddonlien.com`），放在现有 License / Platform / Swift 三个 badge 之后
- DESIGN.md / site/README.md：本次没动

## 验证方式

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

## 备注

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
