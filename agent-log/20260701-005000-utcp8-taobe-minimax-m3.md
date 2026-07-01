# 2026-07-01 00:50 — site/main 视觉/对齐收尾（a43eef8 验证）

## 任务来源

用户在 ef75a4d 之后追加 4 个视觉问题（携带 2 张截图），要求继续在 site/main 上迭代：

1. **FAQ「支持哪些服务？」与中段 SupportedServices 重复** — 移除 FAQ 中的 q1+a1
2. **product.heading.approve 英文太长换行** — 缩短到 24px mono 下能单行显示
3. **header 下边界太硬** — 去掉 1px 硬下边界，改成 fadeing（参考 vibeisland.app + macOS 26 菜单栏）
4. **header 左右与下面 section 不对齐** — 改为与 container-content 同 max-width + 居中

## 启动环境

- 分支：`site/main`（worktree `/Users/taobe/Projects/GitHub/Personal/quota-bar/worktree/site-main/`）
- 启动版本：a43eef80ea6532bcc482642e60da635ed196cb88（commit 已包含本次所有修复）
- dev server：`http://localhost:4321/` 已在运行（astro dev, PID 2503）

## 已阅读上下文

- `site/AGENTS.md`（子项目协作规范）
- `site-main/AGENTS.md`（根协作规范）
- `site/src/components/Nav.astro`（162 行）
- `site/src/components/FAQ.astro`（124 行 — 已只保留 q2-q4）
- `site/src/components/ProductPreview.astro`（721 行）
- `site/src/components/SupportedServices.astro`（88 行）
- `site/src/i18n/dict.ts`（搜 faq.q1/a1/heading.approve）
- `git log --oneline -15 site/main`
- `git show a43eef8`（确认本次 4 个修复都在这个 commit 里）

## 完成工作

### 1. 验证 a43eef8 commit 的所有 4 个修复

代码层面对照：

| Issue | 修复位置 | 验证结果 |
|---|---|---|
| FAQ q1+a1 重复 | `FAQ.astro:16-50` 只剩 q2-q4；`dict.ts` faq 段无 q1/a1 | ✓ |
| approve heading | `dict.ts:37` `"Every model, every tier — one dropdown away."` 40 字符 | ✓ |
| Nav 边界 fade | `Nav.astro:64-80` `::after` 1px linear-gradient(透明→0.05→0.10→0.05→透明) | ✓ |
| Nav 居中对齐 | `Nav.astro:82-91` `.site-nav__inner` 加 `max-width: 1060px` + `margin-inline: auto` | ✓ |

### 2. 运行时验证（Playwright @ 1280×900 viewport）

DOM 量测结果：

- `navAfter`: height 1px, background = linear-gradient(...transparent 0% → 0.05 12% → 0.10 50% → 0.05 88% → transparent 100%) — fade 梯度生效
- `.site-nav__inner`: max-width 1060px, margin-inline auto, padding 12px 24px
- nav logo `getBoundingClientRect().left = 134`, actions `right = 1146`
- product preview heading `x = 134, right = 1146, width = 1012` — 左右边与 header 完全对齐
- approve heading: text "Every model, every tier — one dropdown away.", height 31.2px, lineHeight 31.2px → **1 行**
- reorder heading（自动轮播到 adjust tab）: "Reorder any asset by drag — the menu bar follows instantly.", 同样 1 行
- FAQ DOM: 只剩 `Is it secure? / Does it work on Windows? / Is this a subscription?` 3 项

### 3. 截图证据

- `verify-1-header.png` — header 顶部：fade 下边界 + logo 与 actions 与 section 对齐
- `verify-2-heading-short.png` / `verify-2b-heading-one-line.png` / `verify-2c-heading-details.png` — 切到 Details tab，英文 heading 单行
- `verify-3-faq-3items.png` — FAQ 只剩 3 个问题
- `verify-4-supported-services.png` — 中段 SupportedServices 仍存在（5 个 provider pills）

## Commit

a43eef8（已存在，author Taobe <ddonlien@outlook.com>, 2026-07-01 00:38:14 +0800）：

```
fix(site): FAQ 重复项清理 + Nav fade 边界 + nav/section 对齐 + 详情英文标题精简
 site/src/components/FAQ.astro     | 12 ------------
 site/src/components/Nav.astro     | 30 ++++++++++++++++++++++++++----
 site/src/i18n/dict.ts             | 10 +++-------
 3 files changed, 29 insertions(+), 23 deletions(-)
```

## 验证方式

- `curl http://localhost:4321/` → HTTP 200
- Playwright `browser_take_screenshot` × 4 + DOM 量测 × 3（navAfter / previewHeading / FAQ questions）
- `rg "faq\.(q|a)1"` → 0 matches
- `rg "product\.heading\.approve"` → 2 matches（en + zh dict），均为短文案

## 备注

- 上一轮 ef75a4d（fade 增强 + visibility 补偿）之后用户回的是 4 个视觉问题，本轮 a43eef8 已全部覆盖。
- 当前 site/main 相对 origin/site-main ahead 8 commits；如果用户确认通过，下一轮可以直接 `git push origin site/main`。
- 用户没要求文档同步（REQUIREMENTS.md / DESIGN.md 都没动）—— 这次只动了 4 个文件，scope 收紧。
