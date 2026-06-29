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
- [ ] [0.1.0-QA-A-004] Vercel 部署成功并绑定 `quotabar.ddonlien.com` #QA #deferred — 部署动作由用户触发，命令已写入 README

## Phase - v0.2.0 - 视觉素材升级（延后）

### website/main: 升级主页真实视觉素材

- [ ] [0.2.0-UI-A-000] 用真实应用截图替换 Hero 的 MenuBarMockup #UI #P2 #deferred — 当前纯 CSS mockup 已可用，截图由用户录制后放进 `public/` 替换
- [ ] [0.2.0-UI-A-001] 用真实 SVG logo 替换 ProviderGrid 的品牌色方块占位 #UI #P2 #deferred
- [ ] [0.2.0-UI-A-002] 补充 OG 分享图（1200×630），当前仅文字 meta #UI #P2 #deferred

### website/main: 增强站点 SEO 与多语言能力

- [ ] [0.2.0-FE-A-000] 添加 sitemap.xml 和 robots.txt #FE #P2 #deferred
- [ ] [0.2.0-FE-A-001] 添加 JSON-LD 结构化数据（SoftwareApplication） #FE #P2 #deferred
- [ ] [0.2.0-FE-A-002] 中英双语切换 #FE #P3 #deferred
