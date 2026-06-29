# 任务清单

## Phase - v0.1.0 - 主页首版

### PM-A：范围与信息架构

- [x] [0.1.0-PM-A-000] 确认主页技术方案：Astro 静态站 + 原生 CSS + TypeScript #PM
- [x] [0.1.0-PM-A-001] 确认主页目录位置：仓库根目录 `web/` 子项目 #PM
- [x] [0.1.0-PM-A-002] 确认 Hero 主打卖点：「菜单栏 progress bar 一眼看到额度」+「无配置无菜单极简交互」 #PM
- [x] [0.1.0-PM-A-003] 确认视觉素材策略：先用纯 CSS/HTML mockup 占位，后续替换为真实截图 #PM
- [x] [0.1.0-PM-A-004] 确认部署目标：Vercel，绑定 `quotabar.ddonlien.com` #PM

### FE-A：项目骨架与构建

- [x] [0.1.0-FE-A-000] 初始化 Astro 5.x 项目（package.json / astro.config.mjs / tsconfig.json） #FE
- [x] [0.1.0-FE-A-001] 配置静态输出 `output: 'static'`，site URL 指向 `quotabar.ddonlien.com` #FE
- [x] [0.1.0-FE-A-002] 创建 favicon.svg（三段进度条 logo） #FE
- [x] [0.1.0-FE-A-003] 创建 `.gitignore`（dist / node_modules / .vercel / .astro） #FE
- [x] [0.1.0-FE-A-004] `npm install` 成功，无致命依赖错误 #FE
- [x] [0.1.0-FE-A-005] `npm run build` 成功，产出 `dist/`（约 76KB） #FE

### UI-A：Design Tokens 与布局

- [x] [0.1.0-UI-A-000] 编写 `src/styles/global.css`，集中定义 design tokens（颜色/字体/间距/圆角/阴影/动效） #UI
- [x] [0.1.0-UI-A-001] Provider 品牌色与 macOS 应用 `QuotaModels.swift` `brandColor` 保持一致 #UI
- [x] [0.1.0-UI-A-002] 创建 `Layout.astro`（HTML 骨架 + meta + OG + 滚动入场动画脚本） #UI
- [x] [0.1.0-UI-A-003] 通用工具类：`.container` / `.btn` / `.section` / `.reveal` #UI

### UI-B：核心组件实现

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

### FE-B：主页组装与下载链接

- [x] [0.1.0-FE-B-000] `index.astro` 组装所有 section，Hero / Providers / Features / Showcase / Footer 顺序 #FE
- [x] [0.1.0-FE-B-001] 下载按钮客户端 JS：调 GitHub `/releases?per_page=1` 取最新 nightly DMG 直链，30 分钟 sessionStorage 缓存，失败 fallback 到 releases 列表页 #FE
- [x] [0.1.0-FE-B-002] 所有 `data-download` 链接共享同一份 release 解析逻辑 #FE

### UI-C：响应式与可访问性

- [x] [0.1.0-UI-C-000] 断点 960px / 768px / 640px：双栏 → 单栏，网格 → 单列 #UI
- [x] [0.1.0-UI-C-001] 移动端 Hero 文案居中，mockup 单列堆叠，dropdown 浮动动画关闭 #UI
- [x] [0.1.0-UI-C-002] 导航在 768px 以下隐藏锚点链接 #UI
- [x] [0.1.0-UI-C-003] 装饰性 SVG 标 `aria-hidden="true"`，mockup 容器用 `role="img"` + `aria-label` #UI
- [x] [0.1.0-UI-C-004] 尊重 `prefers-reduced-motion: reduce`，动效降级为瞬时切换 #UI

### DOC-A：文档同步

- [x] [0.1.0-DOC-A-000] 创建 `web/AGENTS.md`（继承父级 + web 子项目专用内容） #DOC
- [x] [0.1.0-DOC-A-001] 创建 `web/README.md`（项目说明、命令、目录结构、视觉素材说明） #DOC
- [x] [0.1.0-DOC-A-002] 创建 `web/DESIGN.md`（主页视觉规范，颜色 token 与 macOS 应用对齐） #DOC
- [x] [0.1.0-DOC-A-003] 创建 `web/REQUIREMENTS.md`（本文件） #DOC
- [x] [0.1.0-DOC-A-004] 创建 `web/agent-log/` 并写入首版执行日志 #DOC
- [x] [0.1.0-DOC-A-005] 根目录 `REQUIREMENTS.md` 新增「营销主页」Phase 索引 #DOC
- [x] [0.1.0-DOC-A-006] 根目录 `README.md` 目录索引追加 `web/` 条目 #DOC

### QA-A：首版完成定义

- [x] [0.1.0-QA-A-000] `npm run build` 通过，无构建错误 #QA
- [x] [0.1.0-QA-A-001] `npm run preview` 本地可访问，HTTP 200，标题正确 #QA
- [x] [0.1.0-QA-A-002] 所有 section 正确渲染（HTML 含 35+ 处关键类名） #QA
- [x] [0.1.0-QA-A-003] 相关文档已更新（web 子项目四件套 + 根目录索引） #QA
- [ ] [0.1.0-QA-A-004] Vercel 部署成功并绑定 `quotabar.ddonlien.com` #QA #deferred — 部署动作由用户触发，命令已写入 README

- [x] [0.2.0-UI-A-000] 用真实应用截图替换 Hero 的 MenuBarMockup #UI
- [x] [0.2.0-UI-A-001] 用真实 SVG logo 替换 ProviderGrid 的品牌色方块占位 #UI #cut — 页面重构移除 ProviderGrid
- [ ] [0.2.0-UI-A-002] 补充 OG 分享图（1200×630），当前仅文字 meta #UI #P2 #deferred

### FE-A：站点增强

- [ ] [0.2.0-FE-A-000] 添加 sitemap.xml 和 robots.txt #FE #P2 #deferred
- [ ] [0.2.0-FE-A-001] 添加 JSON-LD 结构化数据（SoftwareApplication） #FE #P2 #deferred
- [x] [0.2.0-FE-A-002] 中英双语切换 #FE #P3 — un-deferred，拆 0.8.0 子任务后完成

## Phase - v0.8.0 - 双语 i18n + Locale 自动检测

### FE-A：双语基础设施

- [x] [0.8.0-FE-A-001] `src/i18n/dict.ts` — en / zh 翻译字典（约 60 个 key，语义块分组） #FE
- [x] [0.8.0-FE-A-002] `src/i18n/apply.ts` — `detectFromNavigator` + `resolveLocale` + `applyLocale` 工具 #FE
- [x] [0.8.0-FE-A-003] Layout.astro：`<head>` 同步 inline 脚本注入字典 + 检测 locale + 设 `<html lang>` 和 `data-locale` #FE
- [x] [0.8.0-FE-A-004] Layout.astro：body 末尾 inline 脚本扫描 `[data-i18n]` 节点替换 textContent / placeholder / aria-label / title；监听 `qb:locale-change` 事件增量切换 #FE
- [x] [0.8.0-FE-A-005] 切换器 LocaleSwitcher.astro：地球图标 + EN/中文 下拉菜单；点选 → 写 `localStorage` + dispatch `qb:locale-change` #FE

### FE-B：组件文案双语化

- [x] [0.8.0-FE-B-001] Nav.astro：Changelog / Download 按钮文案加 `data-i18n` #FE
- [x] [0.8.0-FE-B-002] Hero.astro：title.line1 / lead / tail / subtitle / CTA + typewriter agent 列表按 locale 切换（data-words-en / data-words-zh） #FE
- [x] [0.8.0-FE-B-003] ProductPreview.astro：tab 标签（监控 / 审批 / 提问 / 跳转）+ heading #FE
- [x] [0.8.0-FE-B-004] Features.astro：改前端 map 循环，9 张卡 title + desc 双语 #FE
- [x] [0.8.0-FE-B-005] Pricing.astro：heading / subheading / plan name / note / 5 bullets / CTA / 支持提示 #FE
- [x] [0.8.0-FE-B-006] FAQ.astro：4 个问答双语 #FE
- [x] [0.8.0-FE-B-007] Footer.astro：tagline / 列标题 / 5 个链接 #FE

### QA-A：i18n 验证

- [x] [0.8.0-QA-A-001] `npm run build` 通过，HTML 注入字典 58 key + `[data-i18n]` 标记全覆盖 #QA
- [x] [0.8.0-QA-A-002] Playwright 验证 5 场景：en 浏览器 / zh 浏览器 / 手动切换 zh / 手动切换回 en / localStorage 覆盖 navigator #QA
- [x] [0.8.0-QA-A-003] 切换菜单 UI 显示 LocaleSwitcher 当前态勾选 ✓ + 切换瞬时无 FOUC #QA
- [x] [0.8.0-QA-A-004] `README.md` 增「i18n 工作机制」章节 + 目录索引同步（移除 MenuBarMockup / ProviderGrid / Showcase，引入 ProductPreview / Pricing / FAQ / LocaleSwitcher） #QA

