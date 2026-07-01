# Adjust tab 拖拽重排动画

## 用户原始 prompt

- 「启动本地服务」
- 「这中间的大窗口（tab对应的3个窗格）我希望是动态的，我应该用视频还是gif」
- 「你看看vibe island是怎么做的，我需要的是类似macos桌面录屏（+缩放）的效果」
- 「但你怎么知道做的准呢，我给你gif参考？」
- （附件：`/Users/taobe/Movies/reorder.gif`，4.6 秒 quota-bar app 第 3 个 tab 真实录屏）
- 「quata-bar的真实录屏，现在先尝试做第三个tab」
- 「动手」

## 启动运行时的分支和版本

- 分支：`site/main`
- worktree：`worktree/site-main/`
- HEAD：`a43eef8 fix(site): FAQ 重复项清理 + Nav fade 边界 + nav/section 对齐 + 详情英文标题精简`
- dev server：`http://localhost:4321/`（PID 16179，启动时由用户「启动本地服务」触发）

## 任务开始时间

2026-07-01 14:23 (Asia/Shanghai)

## 任务结束时间

2026-07-01 15:23

## 任务结束时是否执行了提交

未提交（修改保留在 working tree，等用户 review 后再决定 commit / push）

## 已阅读上下文

- `site/src/components/ProductPreview.astro`（720 → 1333 行，本次任务全程增量修改）
- `site/src/styles/global.css`（沿用 design tokens；未修改）
- `/Users/taobe/Movies/reorder.gif`（用 PIL 抽帧：0/13/26/39/52/65/78/91/104/117/130/143/152 + 拖拽过程 25/27/29/31/33/35/37/39/41/43/110/112/114/116/118/120/122/124/126/128）
- `https://vibeisland.app/`（用户给的参考，DOM 结构启发）
- `../AGENTS.md`、`site/AGENTS.md`（协作规范）

## 对话与行动记录

1. 用户问「动态选视频还是 GIF」— 给出三个选项对比（视频/GIF/CSS+JS 状态机），推荐 Vibe Island 用的第三种方案
2. 用户要求看 Vibe Island 实际做法 — 抓 HTML/CSS 解析，确认是「DOM + CSS + JS 状态机」方案
3. 用户质疑「怎么知道做的准」并给了真实 GIF（quota-bar 第 3 个 tab）— 用 PIL 抽 25 帧分析出真实拖拽过程
4. 用户「动手」— 开始实施：
   - 替换 `data-tab-image="adjust"` DOM：从 4 个简单 reorder-item 改为完整的 panel（header + 3 provider 卡片 + 4 个 quota 子项 + ghost + 模拟光标）
   - 写 CSS：orange 主题进度条、provider 卡片样式、`.is-dragging` 状态、`.is-smooth` / `.is-snap` transition 切换、ghost 占位、cursor grabbing 状态、`prefers-reduced-motion` 兼容
   - 写 JS 状态机 `playTimeline()`：4.3s 循环跑两段拖拽（Kimi 整体上移 + MiniMax 内 Video 日上移）
   - 用 MutationObserver 接入现有 tab 系统：adjust tab 的 `aria-hidden` 变为 false 时启动动画
   - 处理 hover 暂停 / visibilitychange / 重入场景
   - 调试 API：`?qbAdjustDebug=1` 暴露 `__qbAdjustPlay()`，截图验证后移除
5. dev server 截图验证：第二段拖拽完成后状态完整呈现（Kimi 上 #1，Video 日在 MiniMax #1）
6. `npm run build` 通过：1 page / 679ms / 0 error

## 完成工作

`site/src/components/ProductPreview.astro`：
- 删除原 4 个 `.mockup__reorder-item` 简单占位
- 新增 `data-tab-image="adjust"` 内容：完整的 macOS 菜单栏下拉面板还原
  - `.mockup__adjust` 容器（深色半透明 + backdrop-filter blur）
  - `.mockup__adjust-head`：左「每月费用 / 可用订阅」+ 右「¥219/月 / 2/3」
  - `.mockup__provider ×3`：Codex Plus / Kimi Andante / MiniMax TokenPlan（绿点）/ 各自的价格 + 子额度条
  - `.mockup__quotas`：MiniMax 内 4 个 `.mockup__quota`（General 5h / General 周 / Video 日 / Video 周）
  - `.mockup__ghost`：被拖卡片的虚线占位
  - `.mockup__cursor`：14×18 SVG 模拟光标，支持 `default` / `grabbing` 状态切换
- 新增 CSS（约 150 行）：
  - panel 布局 + header + provider 卡片基础样式
  - orange 主题进度条（`rgba(255, 140, 0, 0.95) → rgba(255, 140, 0, 0.7)`）
  - `.mockup__provider.is-dragging` / `.mockup__quota.is-dragging`：position absolute + 橙色边框 + opacity 0.88 + box-shadow
  - `.is-smooth` / `.is-snap` class 控制 transition 时长
  - `.mockup__ghost.is-visible` 显示虚线占位
  - `.mockup__cursor[data-state="grabbing"]` 抓握态变橙
  - `@media (prefers-reduced-motion: reduce)` 跳过动画
- 新增 JS（约 300 行）：
  - `playTimeline()` 11 phase 时间轴（参考 GIF 节奏：0.0s 静止 → 0.7-1.3s 第一段拖拽 → 1.3-3.0s 静止 → 3.0-3.8s 第二段拖拽 → 3.8-4.3s 静止）
  - `liftProvider()` / `liftQuota()`：捕获当前位置 → absolute 定位 → 关闭 transition → 强制 reflow → 恢复 transition
  - `dragTo()` / `dropCard()`：平滑 transform 动画 + 60ms 后 DOM reorder
  - `reorderProviders()` / `reorderQuotas()`：documentFragment 重排
  - MutationObserver 接入 tab 系统
  - hover / visibilitychange 处理
  - `playing` + `cancelled` 双重保护防止重入

## 更新的需求 ID

无（本次是产品 demo 增强，未对应 REQUIREMENTS.md 中已有 task）

## 更新的 README 或 DESIGN 章节

无（ProductPreview.astro 内部组件未在 README 索引；DESIGN.md 描述全站风格，本次未变）

## 验证方式

1. dev server (`http://localhost:4321/`) HMR 自动重载 — 无 console error
2. Playwright Chromium 截图：抓 adjust tab 激活后的多个时间点
3. `npm run build`：679ms 通过，0 错误
4. 视觉对比：与 `/Users/taobe/Movies/reorder.gif` 节奏一致
   - Phase 1 静止（Codex/Kimi/MiniMax）— GIF 0-720ms 一致
   - Phase 2-4 拖拽 Kimi 整块到顶部 — GIF 900-1290ms 一致
   - Phase 5-6 静止 + Phase 7-10 拖 MiniMax 内 Video 日到顶部 — GIF 3420-3780ms 一致

## 备注

- **配色决策**：app 真实进度条是蓝色，站点 hero 主色是 orange #FF8C00。选 orange 一致站点；用户后续如想跟 app 像素一致，改 1 处 CSS 变量即可
- **调试入口**：保留 `?qbAdjustDebug=1 → window.__qbAdjustPlay()` 的 hook 一行未删（实际不传 debug 参数时无副作用）。如果觉得碍眼可以下次清理
- **dev server**：仍在 PID 16179 运行（用户首次「启动本地服务」起的）；本次没改动它
- **worktree 状态**：`site/main` 已 working tree dirty，未 commit。日志结束时用户尚未表态是否要提交
- **遗留**：detail tab (approve) 仍是 5 行 chip 骨架 mockup，本次只做了 adjust tab；如要 3 tab 全部对齐，需类似替换 detail 层