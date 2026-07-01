# Product Preview 3 个 tab 全部切换为真实录屏 mp4

## 用户原始 prompt

- 链路前情：用户用 `/Users/taobe/Movies/reorder.gif`（22MB, 4.6s 录屏）替换了第 3 个 tab 的 DOM+CSS+JS 状态机（自研效果"完全不对"被推翻）
- 「你会直接给我mp4吗」→ 我解释 mp4 优势 + 3 个备选工具
- 「我会直接给你mp4」→ 等文件
- 「/Users/taobe/Desktop/detail_3s.mp4 /Users/taobe/Desktop/preview_3s.mp4 /Users/taobe/Desktop/reorder_3s.mp4 这3个，detail对应第二个tab，preview第一个，reorder第三个，都是3s」→ 收到 3 个 mp4
- 反馈 1：「视屏不要裁切，我给的尺寸是一样的，让这个控件适配这个尺寸」→ 改 aspect-ratio
- 反馈 2：「边框太丑了，看看人家vibeisland做的，然后底部的fadeout也学一下」→ 减轻 box-shadow + 加 ::after 渐变

## 启动运行时的分支和版本

- 分支：`site/main`
- worktree：`worktree/site-main/`
- HEAD：`c39bc64`（worktree 起点是上次 14:00 那次 fix commit）

## 任务开始时间

2026-07-01 16:00 (Asia/Shanghai)

## 任务结束时间

2026-07-01 17:58

## 任务结束时是否执行了提交

未提交（修改保留在 working tree，等用户 review）

## 已阅读上下文

- `site/src/components/ProductPreview.astro`（从 720 → 1333 → 654 → 547 行）
- `site/AGENTS.md`、`AGENTS.md`（协作规范）
- macOS `which ffmpeg`、`which sips`（ffmpeg 不可用；sips 不能转视频）
- 三个 mp4 源文件元数据（`mdls`）：preview_3s.mp4 3.0MB / detail_3s.mp4 3.2MB / reorder_3s.mp4 4.1MB，全部 1662×1080 / 3.0s
- 用户的 vibeisland 截图（laptop + 圆角 macOS 窗口风格，干净无可见边框）

## 对话与行动记录

1. 收到 3 个 mp4 → 复制到 `site/public/` → 删 22MB GIF（用 `mavis-trash` 移入回收站）
2. 替换 `data-tab-image` 三块 DOM：
   - monitor / approve / adjust 三个 `<div class="mockup mockup--xxx">` 全部换成 `<video class="mockup mockup--video" autoplay muted loop playsinline preload="metadata" width="1662" height="1080">`
   - src 对应 preview_3s.mp4 / detail_3s.mp4 / reorder_3s.mp4
   - 加 `aria-label` 无障碍标签（`<video>` 没有 alt）
3. 清理 CSS：
   - 删除旧 `.mockup__line*` / `.mockup__pill` / `.mockup--monitor` / `.mockup__statusbar` / `.mockup__grid` / `.mockup__row*` / `.mockup--approve` / `.mockup__detail*` / `.mockup__chip` / `.mockup__avatar` / `.mockup--adjust` / `.mockup__gif` 全部死代码
   - 新增 `.mockup--video`：`width:100%; height:100%; object-fit:cover; border-radius:inherit`
4. 用户反馈 #1（视频被裁切）→ 改 `.product-preview__window` 的 `aspect-ratio: 16/9` → `aspect-ratio: 1662 / 1080`（= 1.5389，视频原生比例）
5. 用户反馈 #2（边框太丑 + 底部 fadeout）→ 改 `.product-preview__window`：
   - box-shadow 减轻：`0 20px 40px -16px rgba(0,0,0,0.45)` + `0 0 0 1px rgba(255,255,255,0.04)`
   - 边角圆度从 12px 提到 16px
   - 新增 `::after`：`linear-gradient(to bottom, transparent 65%, rgba(0,0,0,0.55) 100%)`，z-index: 2，pointer-events: none
6. 验证：
   - `npm run build`：0 error / 424ms
   - Playwright 抓 3 个 tab 多帧（0.5s/1.0s/1.5s/2.0s/2.5s）
   - monitor 1.5s 看到菜单栏 + Quota Bar tooltip「Quota Bar · Codex 7% · Kimi 0% · MiniMax 71%」（核心卖点 "at a glance" 完美呈现）
   - reorder 1.0s 看到拖拽中，2.0s 看到拖完后的新顺序（Codex 排到第一）
   - detail 看到完整 dropdown + 4 个 MiniMax quota + footer
7. 写 agent log

## 完成工作

- `site/public/reorder.gif` — 删除（22MB 移入回收站）
- `site/public/preview_3s.mp4` — 新增（3.0MB）
- `site/public/detail_3s.mp4` — 新增（3.2MB）
- `site/public/reorder_3s.mp4` — 新增（4.1MB）
- `site/src/components/ProductPreview.astro` — DOM 替换 + CSS 重写（547 行，比之前 654 少 107 行；总公共资产从 25MB 降到 10.3MB）

## 更新的需求 ID

无（视觉资产替换，不是新需求）

## 更新的 README 或 DESIGN 章节

无（CSS token 没变；视觉风格继承 DESIGN.md）

## 验证方式

1. **Build**：`npm run build` → 0 error / 424ms / 1 page generated
2. **资源**：3 个 mp4 全部 200 OK（dev server PID 16179 / port 4321）
3. **比例**：窗口 AR = 1.5389、视频 AR = 1.5389，完全匹配，无裁切
4. **视觉验证**（playwright 截图）：
   - v2-monitor-1.5s.png：Glance tab + 菜单栏 + "Quota Bar · Codex 7% · Kimi 0% · MiniMax 71%" tooltip
   - v2-reorder-1.0s.png：拖拽进行中（Codex 卡片被抓起）
   - v2-reorder-2.0s.png：拖完后的新顺序（Codex 已到 #1）
   - v2-detail-2.5s.png：完整 dropdown + MiniMax 4 个 quota + footer
5. **底部 fadeout**：所有截图右下 / 底缘都能看到 dark overlay 渐入

## 备注

- **改动哲学**：用户在前一次 session 推翻了 DOM 状态机方案，原因是「效果完全不对」，这次直接采用真实录屏像素级方案，是更稳的选择
- **体积**：3 个 mp4 合计 10.3MB（旧 reorder.gif 单个 22MB，节省 12MB）
- **视频时长 vs tab 间隔**：视频 3s / 主 tab 间隔 4.3s，节奏不对齐但无感知问题（视频是循环的，tab 切换靠 opacity fade）
- **preload="metadata"**：避免首屏直接下载 ~10MB 视频，只取元数据，切换 tab 时再下载
- **未做 webm fallback**：mp4 + H.264 已被所有现代浏览器支持（Safari / Chrome / Firefox / Edge），webm 节省空间但对单 mp4 < 5MB 的场景收益小
- **dev server**：PID 16179 / port 4321 仍在运行；HMR 自动应用
- **git 状态**：working tree dirty（uncommitted），等用户 review 后再决定 commit / push
- **未做**：3 个视频自动循环 + 切换 fade 的协调（现状 OK，3 个 video 都 loop=true，aria-hidden 切换时只 fade 容器 opacity）