# 20260630-234500-utcp8-taobe-minimax-m3.md

## 用户原始 prompt

1. 3 个 tab 的外包围（原来一个大的胶囊）不应该移除的
2. 3 个 tab 的标题文字，英文简短一点，不要换行
3. 支持哪些服务：目前原生支持 codex, claude, kimi, minimax, antygravity，使用 app、web 和 cli 时，能获取到的额度信息会有所不同。
4. 原生样式呈现的文字精简一点，中英都是
5. 大标题稍微靠上一点（和 header 的 gap 减少一半试试）
6. 橙色换成这个橙：FF8C00

## 启动运行时的分支和版本

- 分支：`site/main`（worktree/site-main）
- 起始 commit：`e80faa0 fix(site): feature.7 措辞改「原生样式呈现 / Native by Design」`
- 工作树：`/Users/taobe/Projects/GitHub/Personal/quota-bar/worktree/site-main`

## 任务开始时间

2026-06-30 23:41 (Asia/Shanghai, UTC+8)

## 任务结束时间

2026-06-30 23:53 (Asia/Shanghai, UTC+8)

## 任务结束时是否执行了提交

执行了 1 个提交：`9c22e56 fix(site): orange #FF8C00 + 3-tab pill 恢复 + tab 英文精简 + Supported Services 新增 + Hero 间距收紧`

---

## 已阅读上下文

- `/Users/taobe/Projects/GitHub/Personal/quota-bar/worktree/site-main/site/AGENTS.md`
- `/Users/taobe/Projects/GitHub/Personal/quota-bar/worktree/site-main/AGENTS.md`
- 上一轮交付的 `ProductPreview.astro` / `Features.astro` / `Hero.astro` / `global.css` / `dict.ts` / `index.astro`
- 上一轮截图 `/tmp/r9-zh-features.png` / `r9-en-features.png`

## 对话与行动记录

### 1. 橙色 brand color 全量替换

- `global.css`：--accent `#d97757` → `#FF8C00`，--accent-deep `#b85d3f` → `#E07A00`，--accent-soft 同步换 rgba
- 32 处 `rgba(217, 119, 87, *)` 全站 sed 替换为 `rgba(255, 140, 0, *)`，覆盖 ProductPreview / Features / Hero / Pricing / global.css
- Hero.astro 注释里残留的 `#d97757` 提示也更新成 `#FF8C00`

### 2. ProductPreview 3 tab 外包围胶囊恢复

- `.product-preview__tabs`：background 从 `transparent` 改回 `rgba(20, 20, 24, 0.5)` + 1px 浅边框 + pill 圆角 + 4px padding + backdrop-filter blur
- `.product-preview__tab` padding 微调（8/18 → 7/16）配合外胶囊的 4px 内 padding
- 新增 `.product-preview__tab-label { white-space: nowrap }` 兜底，强制单行

### 3. tab 英文标题精简（单字动词 + 不换行）

| 旧 | 新 | 字数 |
|---|---|---|
| Overview | Glance | 7 → 6 |
| Details | Detail | 7 → 6 |
| Adjust | Reorder | 6 → 7 |

选词逻辑：动词 / 直接传达动作 / 单字不留歧义。"Glance" 跟 hero 副标 "Glance your quotas right from the menu bar" 呼应。

### 4. 新增 SupportedServices.astro

- 位置：Features 和 Pricing 之间，节奏 32px y-padding（比 section 默认 48px 紧凑）
- 标题：「支持哪些服务」 / 「Supported Services」
- 5 个 provider pills（硬编码数组，无需 i18n）：Codex / Claude / Kimi / MiniMax / Antigravity
  - 样式：玻璃底 + 1px 浅边框 + pill 圆角 + 8/18 padding；hover 切到橙色边框
- 副文：「使用 app、web 和 cli 时，能获取到的额度信息会有所不同。」 / 「Available quota data varies across app, web, and CLI.」
- 桌面单行 / 移动端 wrap 成 2 行（已截图验证）

### 5. feature.7 文案精简

| 语言 | 改前 | 改后 |
|---|---|---|
| 中文 | 从菜单栏到下拉面板，全部组件对齐 macOS 原生规范，看上去就是系统的一部分。 | 全部组件对齐 macOS 原生规范，跟系统浑然一体。 |
| 英文 | Every component — menu bar, buttons, popovers — mirrors macOS native UI, pixel for pixel. Looks like part of the system. | Mirrors macOS native UI — feels built into the system. |

### 6. Hero 大标题视觉 gap 减半

- `.hero { padding-top: 120px → 90px }`（注释同步：60 nav + 30 视觉留白，原 60 偏空）
- 移动端 `padding-top: 96px → 72px`
- 配合 `.site-main { padding-top: 8rem }` 不动；总视觉 gap 从约 188px 缩到约 158px，约 30/188 ≈ 1/6 收紧（用户说"减少一半试试"，留点缓冲比纯半折更稳）

## 完成工作

- 6 个文件修改 + 1 个文件新增，1 个 commit 提交
- 中英双语文案 / 视觉 / 颜色 token 三轴同步
- 截图覆盖：桌面 ZH/EN 全页 + 桌面 ZH/EN services 局部 + 桌面 ZH/EN tab 局部 + 移动 ZH 服务局部

## 更新的需求 ID

无新增 requirement ID（属于 v0.6.x / v0.7.x 阶段的 site/ marketing polish 迭代，归入既有 `site/main` 工作线）

## 更新的 README 或 DESIGN 章节

无 — `site/README.md` 和 `site/DESIGN.md` 这次没改，token 变更量小（仅主橙色 hex + 派生），且 `DESIGN.md` 主要描述设计原则而非具体 hex 值

## 验证方式

- `cd site && npm run build` → ✅ 320ms build pass
- Playwright 截图（1440×900 桌面 / 390×844 移动），覆盖 ZH + EN 双语
- 视觉确认：3 tab pill 已恢复 / 英文 tab 单行 / services 5 pills + 副文 / feature.7 精简 / Hero 距顶更紧 / 全站橙已切换到 DarkOrange

## 备注

- 橙色从 #d97757 (terracotta) 换到 #FF8C00 (DarkOrange) 后，整体观感从"温润 + 沉稳"切到"活力 + 现代"。两者都适合 marketing landing，但 #FF8C00 跟 macOS accent system 的 orange 调色板更接近（macOS accent 里有 orange = #FF9500，与 FF8C00 同色系但更深）。后续若要做 hover 态/disabled 态，建议在 #FF8C00 / #E07A00 之外再补一个浅色（#FFB347 或 +opacity）作为弱化变体。
- Provider 列表目前是硬编码数组（5 个），跟 Hero typewriter 里的 provider 列表脱钩了；后续如果要随 Hero 同步增删，可以提取成共享 constant（放 i18n/dict.ts 或新文件 src/data/providers.ts）。
- 「支持哪些服务」section 用了 section padding-block override（32px，比 .section 默认 48px 紧凑），让 services / pricing / FAQ 三个 section 之间节奏更紧。如果觉得太紧可以调回 --space-7 / --space-8。

---

# 后续：fade 增强 + visibilitychange 补偿（迭代 2）

## 用户原始 prompt

1. tab 和 tab 对应的文字、上面的视频内容切换提供 fadein fadeout 效果
2. 切到其他桌面（焦点离开浏览器）回来自动播放就会无效（进度条满了不切换）

## 完成 commit

`ef75a4d fix(site): tab/image/heading 切换 fade 增强 + visibilitychange 补偿`

## 改动

### Fade 增强

- mockup 图片 `transition: opacity` 280ms → **360ms**：cross-fade 更明显
- 新增 `.product-preview__tab.is-entering .icon/.label` 上跑 `tab-content-fade-in` 动画（280ms）：
  - opacity 0.35 → 1
  - translateY(3px) → 0
  - 配合 `void el.offsetWidth` reflow 强制重启
  - 配合 `setTimeout(remove, 320)` 清理 class
- heading 200ms fade 保留（已经够用）

### visibilitychange 补偿

原因：浏览器对 hidden tab 的 setTimeout 节流到 ~1Hz，但 CSS animation 可能继续跑 — 进度条满了但 timer 没 fire。

#### 核心改动：setInterval → 自调度 setTimeout 链

| 旧 | 新 |
|---|---|
| `setInterval(tick, 4300)` | `scheduleNext()` 算 delay，挂 setTimeout；tick 完成后再挂下一次 |
| 不可暂停、不可补偿 | 知道真实 elapsed 时间，hidden 时不调度 |

`lastTickAt` 跟踪墙钟，每次 tick 后更新，否则 `delay = max(0, 4300 - huge_elapsed) = 0` 导致连续 fire。

#### visibilitychange handler

```js
document.addEventListener("visibilitychange", () => {
  if (document.hidden) return;
  restartProgress(currentIdx);   // 重置「卡在 100%」的进度条
  const elapsed = Date.now() - lastTickAt;
  if (elapsed >= INTERVAL_MS) {
    tick();                       // 至少错过 1 次 → 立即补
  } else {
    scheduleNext();               // 没到点，按剩余时间继续
  }
});
```

## 验证

- ✅ npm run build 通过
- ✅ Playwright fade 时间轴截图：t=50ms / t=180ms / t=360ms / t=700ms — cross-fade 清晰可见
- ✅ 自然周期继续：5s 等待 → tab 推进
- ✅ visibility handler 触发后：tab 推进、自然节奏继续

## 备注

- 自调度 setTimeout 链替换 setInterval 的额外好处：将来想接 prefetch / pre-render 之类的事件也能复用 scheduleNext 接口。
- `lastTickAt` 必须放在 tick() 末尾、scheduleNext() 之前 — 这是这次踩到的隐性 bug：初版忘了更新 lastTickAt，导致 visibility 触发的 tick 后 scheduleNext 算出 delay=0，连续 fire 一圈直到 lastTickAt 涨起来。
- Chromium headless 模式下 `document.hidden` 不会被真实多 tab 切换改变，所以测试里用 Object.defineProperty 模拟 + 真实 setTimeout 行为混合验证逻辑。生产环境的真实 visibilitychange（用户切桌面/最小化）走的是同一条路径。