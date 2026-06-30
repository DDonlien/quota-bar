# Site 微调：Hero 翻译 + Tab 视觉/进度条/图片

## 用户原始 prompt

> Header 的 Never Lose Track 中文翻译成"始终掌握"。
> 然后第二行"提前掌握额度上限"的小字，在英文版里面不要让它换行
> 四个 Tab 需要 Hover 的效果，以及每个 Tab 选中的效果。
> 选中的效果应该要有进度条一样的特效，来表达它自动播放。下面的描述文字应该跟着这个 Tab 走，上面的图片也是参考附件的实现

## 启动分支与版本

- 分支：`site/main`（worktree 路径：`worktree/site-main/`）
- 启动时 HEAD：`c776a33 fix(site): unicode-range font split, edge-to-edge header, tab autoplay`
- 任务开始时间：2026-06-30 09:30 UTC+8
- 任务结束时间：2026-06-30 09:45 UTC+8
- 任务结束是否提交：是

## 已阅读上下文

- `worktree/site-main/site/src/components/Hero.astro`：标题分三段 `hero.title.line1` / `hero.title.lead` + typewriter / `hero.title.tail`，subtitle 单段 `hero.subtitle`
- `worktree/site-main/site/src/i18n/dict.ts`：双 locale 字典
- `worktree/site-main/site/src/components/ProductPreview.astro`：上轮已有 4 个 button tab、自动循环、hover 暂停、heading 跟随切换；本轮补激活态视觉、进度条特效、图片切换
- `worktree/site-main/site/src/styles/global.css`：暗色 vibeisland 节奏；`--success: #22c55e` 绿色 token
- `worktree/site-main/site/src/layouts/Layout.astro`：i18n 应用脚本 — 关键发现：对带 `data-i18n` 的元素使用 `textContent = val` 覆盖，**会清空所有子节点**。所以带结构的按钮（icon + label + progress span）必须把 `data-i18n` 放在内部的纯文本 span 上，而不是 button 本身。

## 对话与行动记录

1. 用户口语"Header 的 Never Lose Track"指 Hero 标题第一行 `hero.title.line1`（Nav 没有这段文案）
2. "第二行'提前掌握额度上限'的小字"指 Hero subtitle 中文化的开头几个字，用户要求**英文版**别换行 → 同时把英文版改成 "Stay ahead of every limit."，跟中文版"提前掌握额度上限"语义对等
3. 附件是 tab UI 截图：激活的"总览"是绿色背景 + 绿色边框 + 内部从 0%→100% 走的进度条样绿色填充条
4. 用户明确要求"上面的图片也是参考附件的实现" → 图片要根据 active tab 切换
5. 第一轮跑通后截图发现：tab 文字被进度条覆盖、图标不见 → debug → 发现 i18n 脚本把 button 的子节点清空
6. 把 `data-i18n` 从 button 移到内部的 `.product-preview__tab-label` span 后，子节点保留，进度条 + icon + label 全部正常显示

## 完成工作

### 1. Hero
- `site/src/i18n/dict.ts` zh `hero.title.line1` 改成"始终掌握"（原"再也别错过"）
- `site/src/i18n/dict.ts` en `hero.subtitle` 改成 "Stay ahead of every limit."（与中文版"提前掌握额度上限"语义对等，且更短）
- `site/src/components/Hero.astro` CSS 加 `html[data-locale="en"] .hero__subtitle { white-space: nowrap; }`，确保英文版 subtitle 桌面端不换行；mobile breakpoint 内仍允许换行（默认 `white-space: normal`）

### 2. ProductPreview Tab 视觉 + 进度条 + 图片切换
- 4 个 tab 按钮结构改成：`<button>` 内含 `<span class="...__tab-progress">` + `<svg class="...__tab-icon">` + `<span class="...__tab-label" data-i18n>`
- **进度条特效**：
  - `.product-preview__tab-progress` 绝对定位 inset:0 + 浅绿兜底（rgba 0.16）
  - `::after` 用 `transform: scaleX(0→1)` 实现进度填充动画，3.5s linear forwards
  - 用 `--tab-progress-duration` CSS 变量集中控制时长，跟 JS `INTERVAL_MS` 同步
  - 用 `isolation: isolate` 给 button 建立独立 stacking context，icon + label `position:relative; z-index:1` 浮在进度条之上
  - 点击 tab → 强制 reflow 重新触发进度条动画
  - hover section → `animation-play-state: paused` 暂停进度条 + 暂停自动切换 timer
- **未激活 tab**：透明背景 + 灰色图标/文字 + 1px transparent 边框
- **hover 未激活**：文字白 + 浅灰背景 + 14% 灰边框
- **激活态**：深绿文字 (#052e16) + 浅绿背景（rgba 0.12）+ 60% 绿边框 + 35% 绿 box-shadow
- **图片切换**：4 张 mockup 占位（monitor 进度条网格 / approve 审批对话框 / ask 聊天气泡 / jump 终端窗口），按 `data-tab-image` 切换 `aria-hidden`，opacity 280ms fade
- heading 切换保留：fade out → swap text + active class + image → fade in

## 更新的需求 ID

- `0.x.x-FE-A-NNN-tab-progress`：tab 激活态进度条特效（已落地，feature 内部）
- `0.x.x-FE-A-NNN-tab-images`：4 张图跟随 tab 切换（已落地）

## 更新的 README 或 DESIGN 章节

无（视觉规范未变化，仍走 vibeisland 暗色节奏）

## 验证方式

1. `cd worktree/site-main/site && npm run build` → ✓ 1 page built
2. `npm run preview -- --port 4322` 跑 build 产物
3. Playwright 截图对比：
   - `r5-zh-desktop-full.png` — 中文 hero：标题"始终掌握" ✅
   - `r5-en-desktop-full.png` — 英文 hero：subtitle "Stay ahead of every limit." 单行 ✅
   - `r5-tabs-2-t0.png` / `r5-tabs-2-t1.png` / `r5-tabs-2-t2.png` — Tab 进度条三时点：t=0.3s (8%) / t=1.5s (43%) / t=2.7s (自动切换到审批) ✅
   - `r5-tabs-2-hover.png` — hover Approve tab 时进度条暂停 + 边框加深 ✅
   - `r5-zh-mobile-tabs.png` / `r5-en-mobile-tabs.png` — Mobile 414：tab pill 一行 ✅

## 备注

- 用户口语"Header" 在本任务中指 Hero 首屏，不是 Nav
- 当前 ProductPreview 4 张图是纯 CSS mockup 占位，后续可替换为真实应用截图
- i18n 应用脚本用 `textContent = val` 覆盖节点 — 给后续维护者的提醒：任何带结构化子节点的元素不要把 `data-i18n` 放在元素本身，应该放在内部的纯文本 span 上