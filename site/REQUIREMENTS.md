# 任务清单

## Phase - v0.1.0 - 主页首版

### website/main: 定义主页范围与信息架构

- [x] [0.1.0-PM-A-000] 确认主页技术方案：Astro 静态站 + 原生 CSS + TypeScript #PM
- [x] [0.1.0-PM-A-001] 确认主页目录位置：仓库根目录 `site/` 子项目 #PM
- [x] [0.1.0-PM-A-002] 确认 Hero 主打卖点：「菜单栏 progress bar 一眼看到额度」+「无配置无菜单极简交互」 #PM
- [x] [0.1.0-PM-A-003] 确认视觉素材策略：先用纯 CSS/HTML mockup 占位，后续替换为真实截图 #PM
- [x] [0.1.0-PM-A-004] 确认部署目标：Vercel，绑定 `quotabar.ddonlien.com` #PM

### website/main: 建立 Astro 站点骨架

- [x] [0.1.0-FE-A-000] 初始化 Astro 5.x 项目（package.json / astro.config.mjs / tsconfig.json） #FE
- [x] [0.1.0-FE-A-001] 配置静态输出 `output: 'static'`，site URL 指向 `quotabar.ddonlien.com` #FE
- [x] [0.1.0-FE-A-002] 创建 favicon.svg（三段进度条 logo） #FE
- [x] [0.1.0-FE-A-003] 创建 `.gitignore`（dist / node_modules / .vercel / .astro） #FE
- [x] [0.1.0-FE-A-004] `npm install` 成功，无致命依赖错误 #FE
- [x] [0.1.0-FE-A-005] `npm run build` 成功，产出 `dist/`（约 76KB） #FE

### website/main: 建立主页 Design Tokens 与布局

- [x] [0.1.0-UI-A-000] 编写 `src/styles/global.css`，集中定义 design tokens（颜色/字体/间距/圆角/阴影/动效） #UI
- [x] [0.1.0-UI-A-001] Provider 品牌色与 macOS 应用 `QuotaModels.swift` `brandColor` 保持一致 #UI
- [x] [0.1.0-UI-A-002] 创建 `Layout.astro`（HTML 骨架 + meta + OG + 滚动入场动画脚本） #UI
- [x] [0.1.0-UI-A-003] 通用工具类：`.container` / `.btn` / `.section` / `.reveal` #UI

### website/main: 实现主页核心组件

- [x] [0.1.0-UI-B-000] `MenuBarMockup.astro`：纯 CSS/HTML 还原 macOS 26 菜单栏横条 + dropdown，支持 `hero` / `standalone` 两种 variant #UI
- [x] [0.1.0-UI-B-001] 菜单栏 vertical progress bar 组：6 根 bar，高度 = 剩余比例，呼吸循环动画，相位错开 #UI
- [x] [0.1.0-UI-B-002] dropdown 面板：6 个 provider 区块，每块含状态点 / 名称 / 档位 / 价格 / 多条进度条 #UI
- [x] [0.1.0-UI-B-003] 状态色规则与 `QuotaModels.swift` 一致：>0.3 绿 / ≤0.3 橙 / =0 红 #UI
- [x] [0.1.0-UI-B-004] `Nav.astro`：sticky 顶栏，logo + 锚点链接 + GitHub + 下载按钮 #UI
- [x] [0.1.0-UI-B-005] `Hero.astro`：首屏双栏，左文案 + 双 CTA，右 MenuBarMockup（hero variant） #UI
- [x] [0.1.0-UI-B-006] `ProviderGrid.astro`：6 家核心 provider 卡片网格 + 渠道 chip #UI
- [x] [0.1.0-UI-B-007] `Features.astro`：4 个深度卖点卡片（菜单栏即进度条 / 装上即用 / 精准额度 / 四渠道覆盖） #UI
- [x] [0.1.0-UI-B-008] `Showcase.astro`：dropdown 放大图 + 工作原理三步 + 隐私声明 #UI
- [x] [0.1.0-UI-B-009] `Footer.astro`：版权 + 免责声明（开源、非官方、本地读取） + 链接 #UI

### website/main: 组装主页并接入下载链接

- [x] [0.1.0-FE-B-000] `index.astro` 组装所有 section，Hero / Providers / Features / Showcase / Footer 顺序 #FE
- [x] [0.1.0-FE-B-001] 下载按钮客户端 JS：调 GitHub `/releases?per_page=1` 取最新 nightly DMG 直链，30 分钟 sessionStorage 缓存，失败 fallback 到 releases 列表页 #FE
- [x] [0.1.0-FE-B-002] 所有 `data-download` 链接共享同一份 release 解析逻辑 #FE

### website/main: 完成响应式与可访问性

- [x] [0.1.0-UI-C-000] 断点 960px / 768px / 640px：双栏 → 单栏，网格 → 单列 #UI
- [x] [0.1.0-UI-C-001] 移动端 Hero 文案居中，mockup 单列堆叠，dropdown 浮动动画关闭 #UI
- [x] [0.1.0-UI-C-002] 导航在 768px 以下隐藏锚点链接 #UI
- [x] [0.1.0-UI-C-003] 装饰性 SVG 标 `aria-hidden="true"`，mockup 容器用 `role="img"` + `aria-label` #UI
- [x] [0.1.0-UI-C-004] 尊重 `prefers-reduced-motion: reduce`，动效降级为瞬时切换 #UI

### website/main: 同步主页子项目文档

- [x] [0.1.0-DOC-A-000] 创建 `site/AGENTS.md`（继承父级 + site 子项目专用内容） #DOC
- [x] [0.1.0-DOC-A-001] 创建 `site/README.md`（项目说明、命令、目录结构、视觉素材说明） #DOC
- [x] [0.1.0-DOC-A-002] 创建 `site/DESIGN.md`（主页视觉规范，颜色 token 与 macOS 应用对齐） #DOC
- [x] [0.1.0-DOC-A-003] 创建 `site/REQUIREMENTS.md`（本文件） #DOC
- [x] [0.1.0-DOC-A-004] 创建 `site/agent-log/` 并写入首版执行日志 #DOC
- [x] [0.1.0-DOC-A-005] 根目录 `REQUIREMENTS.md` 新增「营销主页」Phase 索引 #DOC
- [x] [0.1.0-DOC-A-006] 根目录 `README.md` 目录索引追加 `site/` 条目 #DOC

### website/main: 完成主页首版验收

- [x] [0.1.0-QA-A-000] `npm run build` 通过，无构建错误 #QA
- [x] [0.1.0-QA-A-001] `npm run preview` 本地可访问，HTTP 200，标题正确 #QA
- [x] [0.1.0-QA-A-002] 所有 section 正确渲染（HTML 含 35+ 处关键类名） #QA
- [x] [0.1.0-QA-A-003] 相关文档已更新（site 子项目四件套 + 根目录索引） #QA
- [ ] [0.1.0-QA-A-004] Vercel 部署成功并绑定 `quotabar.ddonlien.com` #QA #blocked — Vercel 生产部署已 Ready，`quota-bar.vercel.app` 可访问；自定义域 DNS 当前解析到 `198.18.1.43`，需在 DNSPod 配置 `A quotabar.ddonlien.com 76.76.21.21`

## Phase - v0.2.0 - 视觉素材升级（延后）

### website/main: 升级主页真实视觉素材

- [ ] [0.2.0-UI-A-000] 用真实应用截图替换 Hero 的 MenuBarMockup #UI #P2 #deferred — 当前纯 CSS mockup 已可用，截图由用户录制后放进 `public/` 替换
- [ ] [0.2.0-UI-A-001] 用真实 SVG logo 替换 ProviderGrid 的品牌色方块占位 #UI #P2 #deferred
- [ ] [0.2.0-UI-A-002] 补充 OG 分享图（1200×630），当前仅文字 meta #UI #P2 #deferred

### website/main: 增强站点 SEO 与多语言能力

- [ ] [0.2.0-FE-A-000] 添加 sitemap.xml 和 robots.txt #FE #P2 #deferred
- [ ] [0.2.0-FE-A-001] 添加 JSON-LD 结构化数据（SoftwareApplication） #FE #P2 #deferred
- [ ] [0.2.0-FE-A-002] 中英双语切换 #FE #P3 #deferred

> **文档漂移说明（2026-07-18）**：v0.2.0 之后主页实际经历了一次未被本文件记录的重大改版（"vibeisland"
> 暗色 + 暖橙强调视觉、i18n 双语字典、Pricing/FAQ/SupportedServices 等新组件），`site/DESIGN.md` 的颜色
> token 也随之整体替换但文档未同步更新。本次（v0.3.0）不回溯补写这段历史，只从当前真实代码状态继续推进；
> `site/DESIGN.md` 会在本 phase 顺带修正为实际 token（详见下方 DOC 任务）。

## Phase - v0.3.0 - 开源/付费双轨定价卡 + Creem 合规必需页面

> **背景**：用户提供了两份 ChatGPT 对话记录。第一份是更新检查大陆可达性问题（对应根目录
> `REQUIREMENTS.md` v0.14.0 phase）。第二份是商业模式讨论，最终结论是"完整开源、自行编译永久免费；
> 官方签名版一次性付费；不做 Provider 数量限制"的双轨模式（类似 Keka），但**付费版的激活机制本身
> 用户明确要求暂不实现**（还在考虑接入 Creem 还是自建）。本 phase 只做官网呈现层：在 `#pricing` 区块
> 并排放置「开源自行编译」和「付费官方版」两张卡片，不涉及任何实际支付/授权逻辑改动。
>
> 同时，用户在申请 Creem 收款渠道时被拒，原因是页脚 Privacy / Terms / Compare / Manage License /
> Affiliate 全部指向死的 `#` hash 链接、且没有可访问的 Privacy Policy / Terms of Service 内容。
> Creem 审核意见明确给出两个选项："make the footer links functional or remove them"——
> Privacy 和 Terms 是收款渠道审核的硬性要求，必须做成真实页面；Compare / Manage License / Affiliate
> 对应的功能（价格对比页、授权管理后台、联盟推广计划）目前都不存在，选择**移除**而不是做假的占位页面。

### site/main: 官网 Design Tokens 文档纠偏

- [ ] [0.3.0-DOC-A-000] 重写 `site/DESIGN.md` 的颜色/字体/间距 token 表，与 `site/src/styles/global.css` 当前真实值对齐（暗色背景 `--bg:#0f0f11`、暖橙强调 `--accent:#FF8C00`、Mono Sans 字体栈等），不再描述已废弃的浅色 Liquid Glass 方案 #P2

### site/main: 开源 / 付费双轨定价卡片

- [x] [0.3.0-UI-A-000] `Pricing.astro` 的 `.pricing__card-wrap` 从单卡改为两卡并排（`display:flex; flex-wrap:wrap; align-items:stretch; gap:24px`，超出可用宽度自动换行堆叠，不需要额外写断点），保留现有 Pro 卡片内容和逻辑不变，新增一张「开源自行编译」卡片，`.pricing__card { display:flex; flex-direction:column }` + CTA `margin-top:auto` 让两卡等高、按钮底部对齐
- [x] [0.3.0-UI-A-001] 开源卡片内容："Build it yourself"（自行编译）、中性灰徽标（跟付费卡的暖橙"限时"徽标区分开，避免暗示这条路径也是限时的）、说明源码功能与官方版一致需自行编译签名、outline 风格 CTA 按钮跳转 `https://github.com/DDonlien/quota-bar`（新标签页）；同宽（380px）同圆角/边框语言，视觉平级而非主次关系
- [x] [0.3.0-UI-A-002] i18n：`dict.ts` 新增 9 个 `pricing.opensource.*` key（badge/plan.name/amount/note/4 条 bullet/cta），中英文都补全
- [x] [0.3.0-QA-A-000] `npm run build` 通过；Browser 面板实测（`getBoundingClientRect` 精确几何验证，规避了本次会话里 screenshot 工具的一个滚动后截图偶发失败的环境问题）：桌面宽度两卡 380×442px 严格等高、同一行（top 相同）、间距 24px、水平居中；收窄到移动宽度后自动换行堆叠（同 left、不同 top）；DOM 内容核对 badge/plan name/amount/CTA 文案与链接全部正确

### site/main: Privacy Policy + Terms of Service + 页脚死链接修复

- [x] [0.3.0-CONTENT-A-000] 新增 `site/src/pages/privacy.astro`：真实 Privacy Policy 内容（7 节，中英双语 i18n key），如实描述 Quota Bar 的数据处理方式——调研确认 macOS App 无任何 telemetry SDK、无账号系统，Provider 凭证只用于直连各服务商自己的官方 API，从不上传到 Quota Bar 自己的服务器；App 唯一会碰的自有域名请求是 v0.14.0 新增的匿名更新检查；官网本身无第三方 analytics/广告追踪/追踪 Cookie，仅用 localStorage/sessionStorage 做语言偏好和下载链接缓存两个功能性用途
- [x] [0.3.0-CONTENT-A-001] 新增 `site/src/pages/terms.astro`：真实 Terms of Service 内容（7 节，中英双语），软件按现状提供、免责声明、开源自行编译与官方签名版的关系（官方版定价/授权细节明确写"待最终确定"，不提前承诺具体条款）、合理使用范围
- [x] [0.3.0-FE-C-000] `Footer.astro`：`footer.link.privacy`/`footer.link.terms` 改为真实 `href="/privacy"`/`href="/terms"`；移除整个 PRODUCT 列（`footer.link.compare`/`footer.link.manage`/`footer.link.affiliate`/`footer.col.product` 连同 i18n key 一并删除——对应功能不存在，遵循 Creem 审核意见"移除"而非做假页面），页脚从两列变一列（LEGAL）
- [x] [0.3.0-QA-B-000] `npm run build` 通过，生成 `/privacy/index.html`、`/terms/index.html`；用 Browser 面板跑 `astro dev` 实测：中文（默认）和英文（切 locale）两个语言版本内容都完整渲染、7 个小节标题和正文都对得上；`read_page` 确认页脚只剩 LEGAL 一列、Privacy/Terms 是真实 `/privacy`/`/terms` 链接，点击 Terms 链接真的跳转到 Terms 页且标题正确；全站搜索确认不再有任何 `href="#"` 死链接
