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

## Phase - v0.3.1 - Creem 复审前的法律页面 SSR 化 + Terms 内容更新 + 联系邮箱统一

> **背景**：用户提供第二份 ChatGPT 对话记录，内容是拿 v0.3.0 修完后的线上网站再核对一遍 Creem 的三点
> dead-link 反馈。结论：Footer/Privacy/Terms 三处死链接在代码层面确实已经解决，但顺带发现两个新问题：
> 1. `privacy.astro`/`terms.astro` 的正文 `<h2>`/`<p>` 全部是空标签，靠 `Layout.astro` 里的同步
>    `data-i18n` 脚本在客户端注入文字——真实浏览器里因为脚本在 `<head>` 同步跑完才解析 `<body>`，
>    不会有可见的空白闪烁，但不跑 JS 的抓取路径（审核机器人、链接预览器、纯文本工具）拿到的原始
>    HTML 里正文是空的，只有标题。对隐私/条款这类合规敏感页面，这是真实缺陷，不是"能用就行"。
> 2. `terms.s2`（开源与官方版本）还写着"官方版本的定价与授权细节仍在最终确定中"，但首页 `#pricing`
>    区块此时已经在展示确定的 $14.99 一次性价格、Beta 下载者上线时自动转终身 Pro——条款文本和
>    实际售卖页面互相矛盾。
>
> 另外用户本次明确要求：联系邮箱统一为 `taobe@ddonlien.com`。现状是三处不一致：Footer 版权行 +
> Privacy/Terms 联系方式用的是从未验证过是否收信的 `hi@quotabar.app`（Creem 上一轮反馈里也点名问过
> 这个地址是否真实可用）；Pricing 卡片的支付支持提示用的是另一个不相关域名 `taobe@freshli4.com`。

### site/main: 法律页面正文改为 SSR 直出

- [x] [0.3.1-FE-A-000] `privacy.astro`/`terms.astro`：frontmatter 改为 `import { dictionaries } from "../i18n/dict"` 取 `dictionaries.en`，原本空着的 `<h2 data-i18n=…></h2>`/`<p data-i18n=…></p>` 改为直接把对应 key 的英文原文当子节点渲染；`data-i18n` 属性原样保留不动，`Layout.astro` 现有的同步头部脚本在真实浏览器里依然会按访客 locale 正常覆盖——只是不再需要脚本执行才有内容，不跑 JS 的抓取路径也能读到完整英文正文。直接引用 `dictionaries.en` 而不是在 `.astro` 里手抄一份文案，避免以后改 `dict.ts` 忘记同步这两个页面。顺带修正 `privacy.astro` 里一处过时注释（原写"s3 和 s4 各有 2 段正文"，实际是 s1 有 3 段、s3 有 2 段，s4 只有 1 段）

### site/main: Terms 商业条款更新 + 联系邮箱统一

- [x] [0.3.1-CONTENT-A-000] `dict.ts` 的 `terms.s2.body1`（中英文）重写：去掉"pricing ... still being finalized"占位语言，改为陈述跟 `Pricing.astro` 一致的已确定事实——自行编译永远免费不受付费限制；官方版一次性购买（不是订阅），价格含未来更新；Beta 期间免费，Beta 下载者上线时自动获得完整 Pro 授权。授权激活的具体机制（一份授权覆盖几台 Mac、丢失后如何找回）仍未定案，如实写"会在付费版上线前公布"，不编造具体数字。加一句 vendor-中立的结算声明（支付服务商作为 Merchant of Record 负责支付/税费/退款），不点名 Creem——支付渠道本身还没最终决定
- [x] [0.3.1-CONTENT-A-001] 联系邮箱统一改为 `taobe@ddonlien.com`：`Footer.astro` 版权行、`dict.ts` 的 `privacy.s7.body1`/`terms.s7.body1`/`pricing.support.hint`（中英文共 6 处），以及 `Pricing.astro` 里对应的静态 fallback 文案。`grep -rn "hi@quotabar\.app\|taobe@freshli4\.com"` 确认全站无残留，新邮箱精确命中 8 处
- [x] [0.3.1-CONTENT-A-002] Privacy/Terms 的 "Last updated" 日期（中英文共 4 处）从 2026-07-18 推进到 2026-07-19，跟本次正文变更保持一致（两个页面各自的 `s6`/`terms.s6` 章节本来就承诺"内容有实质变化会更新这个日期"）
- [x] [0.3.1-QA-A-000] `npm run build` 通过；直接 grep 构建产物 `dist/privacy/index.html`/`dist/terms/index.html`（原始响应 HTML，不是渲染后 DOM）确认正文段落已经是真实文字、不再是空 `<h2></h2>`/`<p></p>`；Browser 面板跑 `astro dev` 实测 `/privacy`、`/terms`、`/` 三个页面，`get_page_text` 逐段核对中文 locale 下的正文（含新的 terms.s2 商业条款）都正确显示；`document.querySelector` 核对 Footer 版权行、Pricing 支付提示、Privacy/Terms 联系方式四处邮箱均为 `taobe@ddonlien.com`

## Phase - v0.3.2 - 定价叙事从"限时免费"改为"$4.99 一次性购买 + 7 天试用"

> **背景**：用户明确要求去掉"Get Pro Free / 限时免费·Beta 专享"这套叙事——不再讲"现在下载就永久
> 免费"，直接卖 $4.99，用 7 天免费试用替代原本的"Beta 免费转正"钩子。这一步也让上一个 phase 里改到
> $4.99 的那个"划掉的旧价"数字（`$0` 现价 + `$4.99` 划线价两段式）失去意义，一并简化成单一价格展示。

- [x] [0.3.2-CONTENT-A-000] `Pricing.astro` 付费卡片：徽标从"Limited Time · Beta Exclusive"改成"7-Day Free Trial"；`.pricing__amount` 从"`$0` 现价 + `$4.99` 划线价"两段式简化成单一 `$4.99`（删掉 `.pricing__amount-old` 节点和对应死 CSS 规则）；note 从"Free during Beta · $4.99 at launch"改成"One-time purchase · includes future updates"；CTA 从"Get Pro Free"改成"Start Free Trial"；section 级 `pricing.heading`/`pricing.subheading` 从"免费送 Pro"叙事改成"$4.99 一次性购买 + 7 天试用"叙事；中英文同步，`Pricing.astro` 静态 fallback 跟 `dict.ts` 保持一致
- [x] [0.3.2-CONTENT-A-001] `terms.s2.body1`（中英文）同步重写：去掉"Beta 下载者上线时自动获得终身 Pro"，改成"官方版自带 7 天完整 Pro 功能免费试用、试用结束后一次性购买 $4.99"；开源免费、授权激活细节待定、vendor-中立 MoR 声明三处不变
- [x] [0.3.2-QA-A-000] `npm run build` 通过；全文 grep 确认无 "Get Pro Free"/"免费领取 Pro"/"free for life"/"永久免费送"/"Beta 专享"/"Beta Exclusive"/`amount-old` 残留；Browser 面板 `document.querySelector` 精确核对付费卡片 badge/amount/note/cta 四处文案，`getBoundingClientRect` 确认两张定价卡去掉划线价后依然等高对齐（均 444px、同一 top）——本次 Browser 面板滚动截图失效（session 内已知的环境问题，`get_page_text`/`javascript_tool` 不受影响），改用几何数据代替截图验证

### site/main: 开源卡精简为 2 条 bullet，付费卡改为"继承开源 2 条 + 3 条付费专属"

> **背景**：用户看着实际渲染截图指出两张卡片的 bullet 列表应该有结构关系——开源卡只留 2 条最核心的，
> 付费卡展示"开源卡的全部内容 + 付费专属的增量"，而不是像之前那样各自维护一份互相独立、有重叠但不完全
> 一致的 4 条列表（旧付费卡的"无限服务追踪"/"Swift 原生级性能"其实开源版也有，不是真正的付费专属项，
> 这次一并借机去掉）。

- [x] [0.3.3-CONTENT-A-000] 开源卡 bullet 从 4 条砍到 2 条，只保留 `pricing.opensource.bullet.source`（完整无限制源代码）和 `pricing.opensource.bullet.community`（GitHub Issues 社区支持）；删掉 `pricing.opensource.bullet.features`（"功能与官方版一致"——一旦付费卡结构上继承开源卡内容，这句话变成多余的自我指涉）和 `pricing.opensource.bullet.compile`（"自行编译自行签名"，跟保留的"源代码"一条语义重叠），连同 i18n key 一起删除
- [x] [0.3.3-CONTENT-A-001] 付费卡 bullet 改成 5 条：前 2 条直接复用 `pricing.opensource.bullet.source`/`pricing.opensource.bullet.community` 这两个 key（不新建重复文案，避免以后开源卡文案改了付费卡忘记同步），后 3 条是新的付费专属项——`pricing.bullet.autoupdate`（自动更新）、`pricing.bullet.oneclick`（一键安装）、`pricing.bullet.support`（优先技术支持，沿用原 key）；删掉不再是真正付费专属的 `pricing.bullet.unlimited`（无限服务追踪）和 `pricing.bullet.swift`（Swift 原生级性能——这两者开源自编译版本功能上其实完全一样，写成付费专属是误导），`pricing.bullet.updates`（"无限会话及后续更新"）用更明确的 `pricing.bullet.autoupdate` 取代
- [x] [0.3.3-QA-A-000] `npm run build` 通过；全文 grep 确认删除的 5 个 key 无残留引用；Browser 面板 `get_page_text` 完整读出两张卡片渲染后的 bullet 列表，逐条核对跟预期一致（开源卡 2 条、付费卡 5 条且前 2 条与开源卡文案完全相同）——本次 Browser 面板的 `getBoundingClientRect`/`window.innerWidth` 精确几何读取再次失效（返回 `width:66`/`innerWidth:0` 等明显不合理的值，多个 tab 结果一致但截图也变全黑，判断是同一个 session 内已知的环境问题），`get_page_text` 不受影响、内容校验仍然可靠；等高对齐机制（`align-items: stretch` + `.pricing__cta { margin-top: auto }`）本身未改动，且上一版本改动（4 vs 4 条 bullet）时已用几何数据验证过有效

### site/main: 定价卡 CTA 按钮对齐

> **背景**：用户看着实际渲染截图指出两张卡片的 CTA 按钮不在同一水平线上——根因是付费卡按钮下面还有
> 一行"付款问题请联系…"支付提示，把按钮往上顶了一截，开源卡没有对应内容、按钮直接贴卡片底部，两边
> 因为按钮之后的内容高度不同，被 `.pricing__cta { margin-top: auto }` 顶出了不同的位置。

- [x] [0.3.4-FE-A-000] 开源卡 CTA 按钮下面加一个 `.pricing__support.pricing__support--placeholder`（`aria-hidden="true"`，内容是 `&nbsp;`）：跟付费卡真正的支付提示段落用同一个基础 class（同字号、同 `margin-top`），只加 `visibility: hidden` 隐藏，这样两张卡"按钮之后还有多高的内容"完全一致，`margin-top: auto` 把两个按钮顶到同一条线上是结构上保证的，不是靠肉眼调 margin 数值凑出来的
- [x] [0.3.4-QA-A-000] `npm run build` 通过；`get_page_text` 确认占位段落不泄漏可见文本（GitHub 按钮和下方 FAQ 区块之间没有多余空行/文字，`aria-hidden` + 空内容按预期不进可访问性文本流）——本次 Browser 面板 `getBoundingClientRect`/`window.innerWidth` 精确几何读取和滚动截图都失效（重启预览服务器、开新 tab 两种恢复手段都试了，仍然拿不到可用的像素级对齐证据，判断是本 session 里反复出现的同一个环境问题），未能补一张实际对齐后的截图；对齐结论基于 CSS 机制推理——占位元素复用真实支付提示行的同一个 class（相同 `font-size`/`margin-top`/单行文本），两者贡献的布局高度在 CSS 层面就是恒等的，不依赖内容长度巧合吻合
