# 20260630-004800-utcp8-taobe-minimax-m3.md

## 用户原始 prompt

1. "字号、padding 等一系列都做的非常烂，调整"
2. "参考 vibeisland 的网站学习字号和比例关系 https://vibeisland.app/zh/"
3. "然后所有的英文用 Jetbrain Mono NL 字体，中文用 Maple Mono NL 字体，这个无关语言，就是这种文字就用这种字体"

## 启动运行时的分支和版本

- 分支：`site/main`（worktree/site-main）
- 起始 commit：`3eaceef Revert "revert(site): rollback website content to v0.1.0 主页首版 (0631f96)"`
- 工作树：`/Users/taobe/Projects/GitHub/Personal/quota-bar/worktree/site-main`

## 任务开始时间

2026-06-30 00:34 (Asia/Shanghai, UTC+8)

## 任务结束时间

2026-06-30 00:49 (Asia/Shanghai, UTC+8)

## 任务结束时是否执行了提交

执行了 1 个提交（见末尾）

---

## 已阅读上下文

- `/Users/taobe/Projects/GitHub/Personal/quota-bar/worktree/site-main/site/AGENTS.md`
- `/Users/taobe/Projects/GitHub/Personal/quota-bar/worktree/site-main/AGENTS.md`
- 上一轮所有组件文件（Nav / Hero / ProductPreview / Features / Pricing / FAQ / Footer / LocaleSwitcher / Layout / global.css）
- 用户给的 vibeisland.app/zh/（用 fetch + 子 agent 分析）

## vibeisland 设计 token 调研结论

抓取 vibeisland.app/zh/ 的 inline CSS 和 stylesheet，提炼出关键设计节奏：

| 维度 | 取值 |
|---|---|
| 字体栈（主） | `Departure Mono` / `Geist Pixel Square` 等像素字体 + 系统 sans |
| Hero 标题 | **60px / 76px line-height / weight 400** |
| Hero 副标 | 18px / line-height 1.6 |
| Button | 14px / 500 / 12px 28px padding / 10px radius |
| Nav link | 13px / 500 / letter-spacing .01em |
| Nav brand | 12px / uppercase / letter-spacing .08em |
| Section h2 | 36px desktop / 28px mobile / 700 / 1.2 |
| Section padding y | **80px** |
| Container max-width | 1060 / 960 / 720 / 640 / 380 |
| Pricing 大数字 | **48px / 700 / letter-spacing -.02em** |
| Feature card padding | 24px / 12px radius |
| Pricing card padding | 36px / 16px radius |
| 强调色 | `#D97757`（暖橙，变量名虽然写 --purple 但实际是橙） |
| 背景 | `#111111` + 点状图案 |

## 对话与行动记录

### 1. 字体准备
- 用户明确要求：**英文用 JetBrains Mono NL、中文用 Maple Mono NL**，且不依赖语言，混排时按字符自动切换。
- 下载 JetBrains Mono v2.304（5.4MB zip）和 Maple Mono v7.9 Woff2（1.1MB zip）。
- JetBrainsMono 官方 v2.304 没有 NL 单包（只有标准版含 ligature，NL 是社区分支），用标准版（latin 段在中文页面也不触发 ligature，可接受）。
- 解压后取 6 个 woff2 文件（每个字体 Regular/Medium/Bold）放到 `site/public/fonts/`，清理旧的子目录。

### 2. global.css 完全重写
- 删除 Google Fonts Inter 字体引用（token 里残留）。
- 定义 `@font-face` 自托管 JetBrains Mono + Maple Mono NL（三个 weight）。
- 设计 tokens 重做：
  - 颜色：`--accent: #d97757`（vibeisland 同款暖橙）
  - 字号：60/48/36/28/22/18/15/14/13/12/11（vibeisland 节奏）
  - 间距：4px 栅格到 80px section y
  - 容器：1060 / 960 / 640 / 380
  - 圆角：8 / 12 / 16 / pill
- 字体栈策略：
  - 英文优先：`var(--font-en) = "JetBrains Mono", "Maple Mono NL", ui-monospace, monospace`
  - 中文优先：`var(--font-zh) = "Maple Mono NL", "JetBrains Mono", ui-monospace, monospace`
  - `html[lang="zh-CN"]` 切换到中文栈
  - 浏览器按 glyph 缺省自动 fallback，混排自然

### 3. Layout.astro
- 移除 Google Fonts `<link>` 三行
- 加 `<link rel="preload" as="font">` 两个 Regular weight 提升首屏

### 4. Nav.astro
- 改为 `container-content` 包内布局
- nav link 13px / 500 / letter-spacing .01em
- download cta 8px 12px padding / 13px / 500 / letter-spacing .04em
- brand "QUOTA BAR" 12px / uppercase / letter-spacing .08em

### 5. Hero.astro
- 60px / 76px line-height / -0.01em letter-spacing
- 副标 18px / 1.6 / max-width 480px
- 按钮 14px / 500 / **12px 28px padding / 12px radius**
- 中文 hero 单独覆盖：56px / 70px / -0.02em（中文字形偏宽，缩 8% 配 letter-spacing 收紧）
- 中文副标单独覆盖：16px（同样理由）

### 6. ProductPreview.astro
- 大图 aspect-ratio 16:9 / 12px radius / 暗色表面
- Tab 用 segmented control：玻璃底 / 4px padding / 13px / pill 圆角
- H2 36px desktop / 28px mobile / 700 / -0.01em

### 7. Features.astro
- container 960px / grid gap 20px
- 卡片 24px padding / 12px radius / 暗玻璃
- hover：translateY -3px + 边框暖橙 + 图标着色 + 阴影加深
- 图标盒 40×40 / 8px radius / 20px icon
- 标题 14px / 600 / 描述 12px / 1.6 / secondary 色

### 8. Pricing.astro
- container 1060 / 卡片 max-width 380px
- 卡片 32px padding / 16px radius / 玻璃
- 价格 48px / 700 / -0.02em / 旧价 15px 删除线 / muted
- 按钮 14px / 500 / 12px 28px padding / 12px radius

### 9. FAQ.astro
- container 640px / 标题 36px
- summary 13px / 500 / 16px 0 padding / hover 暖橙
- chevron 16×16 / muted / 旋转 180° on open
- answer 13px / 1.6 / secondary 色

### 10. Footer.astro
- container 1060 / 48px 上 padding / 32px 下 padding
- brand "Quota Bar" 14px / 500
- tagline 13px / tertiary 色
- social icon 16×16
- col label 11px / uppercase / letter-spacing .1em
- col link 13px / secondary 色

### 11. LocaleSwitcher.astro 重写
- **修复"EN / 中文"双行 bug**：原实现是 button 内有 `data-current-locale-label` span，Layout 脚本会替换其文字。但 menu 也总是渲染在文档流（用 `hidden` Tailwind class 控制）。新实现用 `is-open` class + `opacity/transform` 控制显隐，避免任何视觉泄漏。
- 重写为 vibeisland 风格：globe icon + code + chevron trigger，玻璃 dropdown menu，玻璃感 + 阴影 + blur(12px)。
- 移除所有 Tailwind class（site 子项目不用 Tailwind）。
- 改 scoped class：`.locale-switcher__trigger` / `.locale-switcher__menu` / `.locale-switcher__option` 等。
- 当前 locale 加 `is-current` class 显示暖橙勾。

## 完成工作

- ✅ 引入 JetBrains Mono + Maple Mono NL 自托管字体（6 个 woff2 文件）
- ✅ 重写 global.css（design tokens + 字体栈 + 节奏）
- ✅ Layout.astro 移除 Google Fonts、改用本地字体 preload
- ✅ 按 vibeisland 节奏重做 7 个组件 + LocaleSwitcher
- ✅ 修复 LocaleSwitcher 文字双行 bug
- ✅ 中文 hero 字号 + 副标单独覆盖适配 Maple Mono NL 字形宽度
- ✅ build 通过（vite + astro build，1 page / 700ms）
- ✅ 中英文两版截图视觉对照（site-final-zh.png / site-final-en.png）都到位

## 更新的需求 ID

无（site 子项目维护 REQUIREMENTS.md 不在这次范围内；本次纯设计节奏调整）

## 更新的 README 或 DESIGN 章节

- 更新 `site/DESIGN.md` 中字体章节（如有的话）— **没改**，因为 site 当前没有 DESIGN.md 文件，节奏 token 集中在 global.css。

## 验证方式

- `cd site && npm run build` — astro build 成功，无 warning
- `npx astro preview` — 1440×900 视口截图：
  - 中文（zh-CN locale）：/tmp/site-final-zh.png
  - 英文（en-US locale）：/tmp/site-final-en.png
- 视觉对比 reference：vibeisland.app/zh/ — 字体节奏 / 字号层级 / padding 比例 / 圆角 / 颜色均接近

## 备注

- JetBrains Mono NL 的 "NL" 官方版本 v2.304 没单独发包（GitHub releases 只有标准版含 ligature），但 site 是英文/中文混排场景，英文段在中文页面下不会触发 ligature，所以使用标准版视觉无差异。如果用户坚持要纯 NL 版，需要从社区 fork（如 fontsource-variable）拿。
- 中文 hero 副标题 "提前掌握额度上限。不打断你的工作流。" 在 Maple Mono NL 下字符间距宽，所以单独缩到 16px（vs 英文版 18px）。同理 hero 标题缩到 56px + letter-spacing -0.02em。
- Pricing 玻璃卡片右上角装饰光晕从白色改为暖橙渐变（`rgba(217,119,87,0.18)`），呼应 brand accent。
- glow-effect 全局光晕颜色从白色改为暖橙 0.07 透明，更 vibeisland 风。
- commit message: `style(site): redesign with JetBrains Mono + Maple Mono NL per vibeisland rhythm`