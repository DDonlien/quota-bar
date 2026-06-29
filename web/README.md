# Quota Bar · 营销主页

> Quota Bar macOS 应用的官方主页，部署在 [quotabar.ddonlien.com](https://quotabar.ddonlien.com)。

本目录是 Quota Bar 仓库的 web 子项目，负责应用对外展示和下载入口。macOS 应用本体在 [`../quota-bar/`](../quota-bar/)。

## 当前能力

- 单页 landing page，用 Astro 静态生成
- Hero 区：Antigravity / Codex / Claude / MiniMax / Kimi / Zcode 等的 Quota Bar 打字机轮播标题
- Product Preview 区：macOS 应用截图 + 4 tab（监控 / 审批 / 提问 / 跳转）
- Features 区：9 个深度卖点卡片（vibeisland 风格 + hover 特效）
- Pricing 区：Quota Bar Pro 一次性买断
- FAQ 区：常见问题 4 个
- Footer：版权 + 链接
- 下载按钮：自动指向最新 nightly DMG（GitHub API 动态获取）
- **中英双语**：浏览器/系统语言自动检测，Nav 提供手动切换并写 `localStorage` 记忆

## 技术栈

- [Astro 5.x](https://astro.build)（静态输出）
- Tailwind CDN（开发用）+ 局部 CSS（design tokens）
- TypeScript（strict 模式）
- 字体：JetBrains Mono NL（拉丁字符）+ 系统中文 fallback（`PingFang SC` / `Hiragino Sans GB` / `Microsoft YaHei`）

## 快速开始

```bash
cd web
npm install
npm run dev      # http://localhost:4321
```

## 构建

```bash
npm run build    # 产出 dist/，纯静态 HTML/CSS/JS
npm run preview  # 本地预览构建产物
```

构建产物约 50KB（未压缩）。

## 部署到 Vercel

首次部署：

```bash
cd web
vercel           # 链接/创建项目
vercel --prod    # 部署到生产
```

之后到 Vercel 后台绑定自定义域名 `quotabar.ddonlien.com`。

> Vercel 会自动识别 Astro，无需 `vercel.json`。
> Root Directory 在 Vercel 项目设置里指向 `web/`。

## 目录结构

```text
web/
├── astro.config.mjs
├── package.json
├── tsconfig.json
├── public/
│   ├── favicon.svg
│   └── fonts/                       # JetBrains Mono + Maple Mono 本地 woff2
├── src/
│   ├── i18n/                        # 双语字典 + locale 检测
│   │   ├── dict.ts                  # en / zh 翻译字典
│   │   └── apply.ts                 # detectFromNavigator / resolveLocale
│   ├── layouts/Layout.astro         # HTML 骨架 + i18n head 同步脚本
│   ├── pages/index.astro            # 主页入口
│   ├── components/
│   │   ├── Nav.astro                # 顶部导航
│   │   ├── LocaleSwitcher.astro     # 语言切换菜单（EN / 中文）
│   │   ├── Hero.astro               # Hero + typewriter
│   │   ├── ProductPreview.astro     # 产品预览 + 4 tab
│   │   ├── Features.astro           # 9 张 feature 卡片
│   │   ├── Pricing.astro            # 一次性买断 pro 套餐
│   │   ├── FAQ.astro                # 4 个常见问题
│   │   └── Footer.astro
│   └── styles/global.css            # design tokens
├── AGENTS.md                        # 本子项目协作规范
├── README.md                        # 本文件
├── REQUIREMENTS.md                  # 需求追踪
├── DESIGN.md                        # 视觉规范
└── agent-log/                       # 执行日志
```

## i18n 工作机制

- **字典**：`src/i18n/dict.ts` 里 `{ en: {...}, zh: {...} }`，约 60 个 key
- **检测顺序**：`localStorage.qb_locale` > `navigator.languages` > fallback `en`
- **zh 判定规则**：`navigator.language` 以 `zh` 开头（含 `zh-CN` / `zh-TW` / `zh-HK`）一律归 zh（不分简繁）
- **HTML 渲染**：Astro SSR 输出英文原文，`<head>` 同步 inline 脚本立刻读取 locale 并替换 `[data-i18n]` 节点的 textContent；浏览器 first paint 已看到正确语言
- **手动切换**：Nav 顶部地球图标 → 下拉选 EN / 中文 → 写 `localStorage` + 派发 `qb:locale-change` 事件 → 全站立即切换；Hero typewriter 按 locale 选不同 agent 列表（当前两种语言共用同一组英文专有名词，结构上为未来本地化名称预留扩展位）

新增翻译：在 `src/i18n/dict.ts` 加 key + 在组件里加 `<span data-i18n="key">English fallback</span>`。

## 视觉素材说明

Hero 区下方 Product Preview 里的「应用截图」是占位图（`googleusercontent` URL），后续替换为真实 macOS 应用截图。

Provider 品牌色未在主页中展示（旧的 ProviderGrid 已被移除），目前仅 Features / Pricing 强调能力点；如未来加回，需同步与 macOS 应用 `QuotaModels.swift` 的 `brandColor`。

## 开发约定

- 文案默认中文；CSS 类名英文 kebab-case
- 所有面向用户的文案都加 `data-i18n` 标记；新增文案时**必须同时在 `dict.ts` 里加 en + zh**（编译时不强校验，PR review 时关注）
- 不引入运行时框架（React/Vue），除非有明确的交互复杂度需求（Tailwind CDN 当前是开发期使用）

## 文档入口

- 视觉规范：[`DESIGN.md`](./DESIGN.md)
- 需求追踪：[`REQUIREMENTS.md`](./REQUIREMENTS.md)
- 执行日志：[`agent-log/`](./agent-log/)
- 全局父级文档：[`../README.md`](../README.md)
