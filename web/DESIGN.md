# 视觉规范 · web/

本文件是 Quota Bar 营销主页（`web/`）的视觉规范。它只描述 web 主页的视觉风格，不记录 macOS 应用本身或任务列表。

> 注意：macOS 应用本体的视觉规范在 [`../DESIGN.md`](../DESIGN.md)。两者颜色 token 保持一致，但应用范围不同。

## 视觉主题

- 关键词：macOS 26 Liquid Glass、浅色、半透明、克制动效、原生控件质感。
- 整体气质：克制、可信、轻量、聚焦产品本身；不喧宾夺主。
- 应避免的气质：强营销感、夸张动效、霓虹渐变、拟物过度、暗黑赛博风。

## 参考对象

- [Vibe Island](https://vibeisland.app/zh/)：单页 landing 的信息架构和克制动效参考。
- macOS 26 系统菜单栏、控制中心：玻璃材质、圆角、轻投影。
- Apple 官网产品页：大留白、清晰层级、渐变背景点缀。

## 色彩

所有颜色以 CSS custom property 形式集中定义在 `src/styles/global.css` 的 `:root`，组件通过 `var(--xxx)` 引用。

### 背景与表面

| Token | 值 | 用途 |
|---|---|---|
| `--bg` | `#f5f5f7` | 页面主背景（macOS 26 window backdrop） |
| `--bg-elevated` | `#ffffff` | 卡片 / 下拉面板表面 |
| `--bg-glass` | `rgba(255,255,255,0.72)` | Liquid Glass 半透明面板 |
| `--bg-menu-bar` | `rgba(246,246,248,0.82)` | 菜单栏横条半透明 |

### 文字

| Token | 值 | 用途 |
|---|---|---|
| `--text-primary` | `#1d1d1f` | 标题 |
| `--text-secondary` | `#6e6e73` | 正文 |
| `--text-tertiary` | `#8e8e93` | 辅助说明 |

### 品牌色

| Token | 值 | 用途 |
|---|---|---|
| `--brand` | `#0a7cff` | Quota Bar 主色（系统蓝，与 macOS 应用一致） |
| `--brand-hover` | `#0066e0` | 主色 hover |
| `--brand-soft` | `rgba(10,124,255,0.12)` | 主色软背景（chip / 标签） |

### 状态色（与 `QuotaModels.swift` `statusColor` 一致）

| Token | 值 | 语义 |
|---|---|---|
| `--status-green` | `#35c85a` | 充足（fraction > 0.3） |
| `--status-orange` | `#ff9f0a` | 告警（fraction ≤ 0.3） |
| `--status-red` | `#ff453a` | 耗尽（fraction = 0） |

### Provider 品牌色（从 `QuotaModels.swift` `brandColor` 提取）

| Token | 值 | Provider |
|---|---|---|
| `--provider-antigravity` | `#1a73e8` | Antigravity |
| `--provider-codex` | `#35c85a` | Codex |
| `--provider-claude` | `#d4a574` | Claude |
| `--provider-minimax` | `#ff453a` | MiniMax |
| `--provider-kimi` | `#ff9f0a` | Kimi |
| `--provider-zcode` | `#3866ff` | Zcode（智谱，占位） |

> Zcode 目前在 macOS 应用 `QuotaModels.swift` 里尚未作为独立 ProviderKind 存在，主页先行占位；应用接入后同步校准真实品牌色。

## 字体

- 字体栈：`-apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Helvetica Neue", "PingFang SC", "Microsoft YaHei", system-ui, sans-serif`
- 等宽：`"SF Mono", "JetBrains Mono", ui-monospace, Menlo, monospace`（用于数字徽标 / `font-variant-numeric: tabular-nums`）
- 字重：标题 700/800，正文 400，强调 500/600
- `font-feature-settings: "ss01", "cv01"`（启用 SF 的可选字形）

### 字号层级

| Token | 值 | 用途 |
|---|---|---|
| `--text-xs` | 0.75rem (12px) | 辅助 / 标签 |
| `--text-sm` | 0.875rem (14px) | 次要正文 |
| `--text-base` | 1rem (16px) | 正文 |
| `--text-lg` | 1.125rem (18px) | 卡片标题 |
| `--text-xl` | 1.375rem (22px) | 小节标题 |
| `--text-2xl` | 1.75rem (28px) | — |
| `--text-3xl` | 2.25rem (36px) | 章节大标题 |
| `--text-4xl` | 3rem (48px) | 响应式 Hero 标题（移动端） |
| `--text-5xl` | 3.75rem (60px) | Hero 主标题 |

## 间距与布局

- 栅格基准：8px（`--space-1` = 4px … `--space-9` = 96px）
- 最大内容宽度：`--max-width` = 1120px
- 导航高度：`--nav-height` = 60px
- 章节内边距：`padding-block: var(--space-9)`（96px）

### 圆角（macOS 控件尺度）

| Token | 值 | 用途 |
|---|---|---|
| `--radius-sm` | 8px | 小按钮 / 图标容器 |
| `--radius-md` | 12px | 卡片图标 / 小卡片 |
| `--radius-lg` | 20px | 主卡片 / dropdown 面板 |
| `--radius-xl` | 28px | 大容器 |
| `--radius-pill` | 999px | 按钮 / chip / 进度条 |

### 阴影（macOS 26 的轻柔投影）

| Token | 描述 |
|---|---|
| `--shadow-sm` | 微浮起（chip / 小元素） |
| `--shadow-md` | 卡片 hover |
| `--shadow-lg` | dropdown / 大卡片 |
| `--shadow-xl` | Hero mockup 浮层 |

## 组件风格

### 按钮

- `.btn--primary`：品牌蓝实心 + 蓝色投影，hover 加深 + 投影扩大，active 缩放 0.97。
- `.btn--ghost`：半透明白底 + 细边框 + `backdrop-filter: blur`，hover 边框加深。
- `.btn--lg`：加大 padding 和字号，用于 Hero CTA。

### 卡片（Provider / Feature）

- 白底 + 1px 浅边框 + 大圆角（`--radius-lg`）
- hover：`translateY(-4px)` + `--shadow-lg` + 边框加深
- 弹性缓动 `--ease-spring`，时长 `--duration-base`（0.25s）

### MenuBarMockup（核心视觉资产）

- **dropdown 面板**：`--bg-glass` + `backdrop-filter: blur(40px) saturate(1.4)`，大圆角，`--shadow-xl`。
- **菜单栏横条**：`--bg-menu-bar` + `blur(20px) saturate(1.5)`，顶部圆角，28px 高。
- **vertical progress bar 组**：每根 4×16px，底部对齐，圆角 2px，fill 高度 = 剩余比例（min 8%）。
- **status 色规则**（与 `QuotaModels.swift` 一致）：`>0.3` 绿 / `≤0.3` 橙 / `=0` 红。
- **价格数字**：`font-variant-numeric: tabular-nums`。

## 动效

原则：克制、短时长、系统级缓动，不用 Framer Motion 这类重动效库。

| 动效 | 实现 | 时长 |
|---|---|---|
| 滚动入场 | `IntersectionObserver` 触发 `.reveal` → `.is-visible`，opacity + translateY | 0.5s |
| 按钮 hover/active | transform + background transition | 0.15s |
| 卡片 hover | translateY + shadow | 0.25s |
| 菜单栏 bar 呼吸 | `@keyframes bar-breathe`，opacity + brightness 循环 | 4s，6 根 bar 错开 0.4s 相位 |
| dropdown 浮动 | `@keyframes dropdown-float`，translateY ±6px | 6s |
| 进度条填充 | width transition | 0.8s |

所有动效都尊重 `@media (prefers-reduced-motion: reduce)`，降级为瞬时切换。

## 响应式

- 断点：960px（双栏 → 单栏）、768px（网格 → 单列）、640px（页脚换列）。
- 移动端 Hero：文案居中，mockup 单列堆叠，dropdown 浮动动画关闭。
- 导航在 768px 以下隐藏锚点链接，保留 logo + GitHub + 下载。

## 可访问性

- 颜色不作为唯一信息来源：状态色同时配文字百分比。
- 所有装饰性 SVG 标 `aria-hidden="true"`。
- mockup 容器用 `role="img"` + `aria-label` 描述。
- 键盘可达：所有链接和按钮原生可聚焦。
- 尊重 `prefers-reduced-motion`。
