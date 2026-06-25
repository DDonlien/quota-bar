# Agent 协作规范 · web/

本文件继承根目录 [`../AGENTS.md`](../AGENTS.md) 的标准内容；项目专用内容见下文。标准内容不在此重复，冲突时以根目录标准内容和用户明确要求为准。

## 项目专用内容

### 项目概况

- 项目名称：Quota Bar 营销主页（web 子项目）
- 产品简介：Quota Bar macOS 应用的营销 landing page，用 Astro 构建静态站点，部署到 Vercel，绑定 `quotabar.ddonlien.com`。
- 主要用户：想了解 / 下载 Quota Bar 的访客。
- 当前阶段：主页首版已落地；视觉素材目前用纯 CSS/HTML mockup 占位，后续可替换为真实应用截图。

### 技术栈与命令

- 技术栈：Astro 5.x（静态输出 `output: 'static'`）、原生 CSS（CSS custom properties 做 design tokens，不用 Tailwind）、TypeScript（严格模式）。
- 开发命令：`cd web && npm run dev` → `http://localhost:4321`
- 构建命令：`cd web && npm run build` → 产出 `web/dist/`
- 本地预览构建产物：`cd web && npm run preview`
- 部署：`cd web && vercel --prod`（首次需 `vercel` 链接项目，再到 Vercel 后台绑定 `quotabar.ddonlien.com` 域名）

### 文档入口

- 子项目说明：`web/README.md`
- 视觉规范：`web/DESIGN.md`
- 需求追踪：`web/REQUIREMENTS.md`
- 执行日志：`web/agent-log/`
- 全局父级文档：`../AGENTS.md`、`../README.md`、`../REQUIREMENTS.md`、`../DESIGN.md`

### 目录索引

- `web/src/pages/index.astro`：主页入口，组装所有 section。
- `web/src/layouts/Layout.astro`：HTML 骨架 + meta + 滚动入场动画脚本。
- `web/src/styles/global.css`：design tokens（颜色 / 字体 / 间距 / 圆角 / 阴影 / 动效）。
- `web/src/components/`：UI 组件
  - `Nav.astro`：顶部导航条（logo + 锚点链接 + GitHub + 下载按钮）。
  - `Hero.astro`：首屏，主打「菜单栏 progress bar + 极简交互」。
  - `MenuBarMockup.astro`：**核心视觉资产**，纯 CSS/HTML 像素级还原 macOS 26 菜单栏 + dropdown，支持 `hero` / `standalone` 两种 variant。
  - `ProviderGrid.astro`：6 家核心 provider 卡片网格。
  - `Features.astro`：4 个深度卖点卡片。
  - `Showcase.astro`：dropdown 放大图 + 工作原理三步。
  - `Footer.astro`：版权 + 免责声明 + 链接。
- `web/public/favicon.svg`：站点图标（三段进度条 logo）。
- `web/astro.config.mjs`：Astro 配置（静态输出、site URL）。

### 项目特殊约束

- **语言与命名**：面向用户的文案默认中文；HTML `lang="zh-CN"`；CSS 类名沿用英文 kebab-case。
- **视觉一致性**：颜色 token 必须与 macOS 应用 `QuotaModels.swift` 的 `brandColor` 保持一致（详见 `web/DESIGN.md`）。新增 provider 颜色时同步更新两边。
- **不引入运行时框架**：当前为纯静态站，不引入 React / Vue / Tailwind；如未来需要复杂交互再评估。
- **下载链接**：CI 产出的是 `nightly-<sha>` prerelease（不进 `/releases/latest` API），下载按钮通过客户端 JS 调 `/releases?per_page=1` 取最新 DMG，失败 fallback 到 releases 列表页。
- **不动 Swift 代码**：本子项目只做 web，macOS 应用改动在 `../quota-bar/`。
