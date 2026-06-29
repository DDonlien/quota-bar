# Quota Bar · 营销主页

> Quota Bar macOS 应用的官方主页，部署在 [quotabar.ddonlien.com](https://quotabar.ddonlien.com)。

本目录是 Quota Bar 仓库的 site 子项目，负责应用对外展示和下载入口。macOS 应用本体在 [`../macos/`](../macos/)。

## 当前能力

- 单页 landing page，用 Astro 静态生成
- Hero 区：主打「菜单栏 progress bar 一眼看到额度」「无配置无菜单极简交互」
- Provider 网格：6 家核心服务（Antigravity / Codex / Claude / MiniMax / Kimi / Zcode）
- Features 区：4 个深度卖点
- Showcase 区：dropdown 放大图 + 工作原理三步
- 下载按钮：自动指向最新 nightly DMG（GitHub API 动态获取）

## 技术栈

- [Astro 5.x](https://astro.build)（静态输出）
- 原生 CSS（CSS custom properties 做 design tokens，无 Tailwind）
- TypeScript（strict 模式）
- 字体：SF Pro / `-apple-system`（贴合 macOS 原生）

## 快速开始

```bash
cd site
npm install
npm run dev      # http://localhost:4321
```

## 构建

```bash
npm run build    # 产出 dist/，纯静态 HTML/CSS/JS
npm run preview  # 本地预览构建产物
```

构建产物极轻量（约 76KB）。

## 部署到 Vercel

首次部署：

```bash
cd site
vercel           # 链接/创建项目
vercel --prod    # 部署到生产
```

之后到 Vercel 后台绑定自定义域名 `quotabar.ddonlien.com`。

> Vercel 会自动识别 Astro，无需 `vercel.json`。
> Root Directory 在 Vercel 项目设置里指向 `site/`。

## 目录结构

```text
site/
├── astro.config.mjs
├── package.json
├── tsconfig.json
├── public/favicon.svg
├── src/
│   ├── layouts/Layout.astro
│   ├── pages/index.astro
│   ├── components/
│   │   ├── Nav.astro
│   │   ├── Hero.astro
│   │   ├── MenuBarMockup.astro    # 核心视觉资产：纯 CSS 还原菜单栏 + dropdown
│   │   ├── ProviderGrid.astro
│   │   ├── Features.astro
│   │   ├── Showcase.astro
│   │   └── Footer.astro
│   └── styles/global.css          # design tokens
├── AGENTS.md                      # 本子项目协作规范
├── README.md                      # 本文件
├── REQUIREMENTS.md                # 需求追踪
├── DESIGN.md                      # 视觉规范
└── agent-log/                     # 执行日志
```

## 视觉素材说明

当前 Hero 和 Showcase 里的「菜单栏 + dropdown」是**纯 CSS/HTML mockup**（`MenuBarMockup.astro`），不是真实截图。

- 优点：轻量、所有设备完美渲染、随主题色变化
- 后续可替换：把真实应用截图放进 `public/`，按约定路径替换 `<MenuBarMockup />` 调用即可

Provider logo 当前用品牌色方块占位，后续可换成真实 SVG logo。

## 开发约定

- 颜色 token 集中在 `src/styles/global.css` 的 `:root`，与 macOS 应用 `QuotaModels.swift` 的 `brandColor` 保持一致
- 新增 provider 时同步更新：
  1. `global.css` 的 `--provider-<name>` 变量
  2. `MenuBarMockup.astro` 的 `providers` 数组
  3. `ProviderGrid.astro` 的 `providers` 数组
  4. macOS 应用 `QuotaModels.swift` 的 `brandColor`
- 文案默认中文；CSS 类名英文 kebab-case
- 不引入运行时框架（React/Vue/Tailwind），除非有明确的交互复杂度需求

## 文档入口

- 视觉规范：[`DESIGN.md`](./DESIGN.md)
- 需求追踪：[`REQUIREMENTS.md`](./REQUIREMENTS.md)
- 执行日志：[`agent-log/`](./agent-log/)
- 全局父级文档：[`../README.md`](../README.md)
