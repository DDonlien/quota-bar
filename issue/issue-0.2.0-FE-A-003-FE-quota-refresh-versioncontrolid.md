# sub/main: 提供额度刷新机制

- ID：`0.2.0-FE-A-003`。
- 类型：`FE`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`；标题路径：任务清单 / Phase - v0.2.0 - Quota Bar 核心功能 / sub/main: 提供额度刷新机制。
- 原稳定 ID：`0.2.0-FE-A-000`, `0.2.0-FE-A-001`, `0.2.0-FE-A-002`, `0.2.0-FE-A-003`, `0.2.0-FE-A-004`, `0.2.0-FE-A-005`, `0.2.0-FE-A-006`, `0.2.0-FE-A-007`, `0.2.0-FE-A-008`, `0.2.0-FE-A-009`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.2.0-FE-A-000] 支持手动刷新：点击菜单中的「立即刷新」触发全量数据更新，且 dropdown 保持打开 #P1
- [x] [0.2.0-FE-A-001] 支持自动刷新，默认间隔 5 分钟，允许在偏好设置中修改（P2 实现设置页）#P1
- [x] [0.2.0-FE-A-002] 刷新时在 UI 中展示「上次更新时间」和刷新状态（如 spinning indicator）#P1
- [x] [0.2.0-FE-A-003] 单次刷新超时或失败时，不阻塞 UI，其他服务数据正常展示 #P1
- [x] [0.2.0-FE-A-004] 顶部菜单栏图标根据可用状态动态变化：正常 / 警告 / 错误 #P1 — 4 态（normal / refreshing / warning / error）+ 最低 remaining% 数字徽标，`StatusBarController.refreshStatusItemAppearance()`
- [x] [0.2.0-FE-A-005] 菜单栏改为多 bar 视图（Liquid Glass 风格）：每个已配置订阅画 1 个垂直 bar，bar 数 = `.available` 订阅数，bar 颜色 = brand color，bar 顺序 = dashboard 顺序，bar 高度 = 最近重置 quota 的 remainingFraction；用完的（0%）仍画最小 bar 保证知情；未配置（needsConfiguration/notInstalled/fetchFailed）不画 bar #P1 — `StatusBarController.makeBarsImage()`
- [x] [0.2.0-FE-A-006] 菜单栏 status item 占位宽度随实际 bar image 宽度变化；在满足参考图圆角视觉的前提下，避免窄图标仍占 80pt 或 bar 间出现异常缝隙 #P1
- [x] [0.2.0-FE-A-007] 修正菜单栏图标绘制宽度与实际占位宽度不一致的问题，避免截图中 bar 图标视觉宽度较窄但 status item 点击/占位区域明显过宽 #P1
- [x] [0.2.0-FE-A-008] 校准菜单栏多 bar 的数值来源和高度映射，确保每个 bar 真实反映对应服务当前额度状态，而不是使用与实际剩余额度不匹配的占位或无效数值 #P1
- [x] [0.2.0-FE-A-009] 修正菜单栏 bar 绘制样式：当前 bar 圆角没有按预期绘制，应参考此前参考图恢复圆角外观，并确保高低不同的 bar 在小尺寸菜单栏图标中仍清晰可辨 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260620204220-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260620204220-utcp8-gpt5.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 再增加一个需求，bar的绘制不对，圆角没画，参考我之前的参考图

#### 完成工作

- 已更新 `REQUIREMENTS.md`：
  - 调整 `[0.2.0-FE-A-006]`，避免旧的“无圆角”约束与新需求冲突。
  - 新增 `[0.2.0-FE-A-009]`：修正菜单栏 bar 绘制样式，参考此前参考图恢复圆角外观。

#### 更新的需求 ID

- 更新：`0.2.0-FE-A-006`
- 新增：`0.2.0-FE-A-009`

#### 验证方式

- `python3` 自定义格式检查：通过，确认 `REQUIREMENTS.md` 的标题和任务 ID 仍符合新版规则。

#### 备注

- 未运行 `swift build`，本次仅修改 Markdown 需求记录，不执行实现。

### 20260620205908-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260620205908-utcp8-gpt5.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 处理这4个task，我的参考图如下：[原创应用](https://www.figma.com/design/zAky4WvzPYWbQSjOE7hrE1/%E5%8E%9F%E5%88%9B%E5%BA%94%E7%94%A8?node-id=106-649&t=FqJCnIGbfe80yLpv-4)
> - [ ] [0.2.0-FE-A-005] 菜单栏改为多 bar 视图（Liquid Glass 风格）：每个已配置订阅画 1 个垂直 bar，bar 数 = `.available` 订阅数，bar 颜色 = brand color，bar 顺序 = dashboard 顺序，bar 高度 = 最低 remainingFraction；用完的（0%）仍画最小 bar 保证知情；未配置（needsConfiguration/notInstalled/fetchFailed）不画 bar #P1 — `StatusBarController.makeBarsImage()`
> - [ ] [0.2.0-FE-A-006] 菜单栏 status item 占位宽度随实际 bar image 宽度变化；在满足参考图圆角视觉的前提下，避免窄图标仍占 80pt 或 bar 间出现异常缝隙 #P1
> - [ ] [0.2.0-FE-A-007] 修正菜单栏图标绘制宽度与实际占位宽度不一致的问题，避免截图中 bar 图标视觉宽度较窄但 status item 点击/占位区域明显过宽 #P1
> - [ ] [0.2.0-FE-A-008] 校准菜单栏多 bar 的数值来源和高度映射，确保每个 bar 真实反映对应服务当前额度状态，而不是使用与实际剩余额度不匹配的占位或无效数值 #P1
> - [ ] [0.2.0-FE-A-009] 修正菜单栏 bar 绘制样式：当前 bar 圆角没有按预期绘制，应参考此前参考图恢复圆角外观，并确保高低不同的 bar 在小尺寸菜单栏图标中仍清晰可辨 #P1

#### 完成工作

- `StatusBarController.swift`
  - 多 bar 只绘制真实可用且有 quota 数据的订阅。
  - bar 高度、tooltip 百分比统一来自最低剩余比例。
  - status item 宽度直接跟随 bar image 宽度，避免额外过宽占位。
  - bar 使用圆角绘制，低高度 bar 仍保持可辨识。
- `DESIGN.md`
  - 同步菜单栏多 bar 的圆角、高度映射和最小高度规则。
- `REQUIREMENTS.md`
  - 勾选本次完成的 FE-A 005-009。

#### 更新的需求 ID

- `0.2.0-FE-A-005`
- `0.2.0-FE-A-006`
- `0.2.0-FE-A-007`
- `0.2.0-FE-A-008`
- `0.2.0-FE-A-009`

#### 验证方式

- `cd quota-bar && swift build`：通过。
- 再次执行 `cd quota-bar && swift build`：通过。

#### 备注

- 未执行提交。
- 本次未通过运行中的 macOS 菜单栏截图做视觉验收；代码层面已消除固定额外宽度和无圆角绘制问题。

### 20260629201000-utcp8-claude.md — 历史证据迁移

来源：`site/agent-log/20260629201000-utcp8-claude.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 增加中文，并完成翻译，并增加对系统/浏览器语言的抓取，从而实现默认语言的选用

#### 验证

Playwright 5 场景截图：
- `i18n-en-default.png` — 英文浏览器 → 全部英文
- `i18n-zh-default.png` — 中文浏览器 → 全部中文
- `i18n-menu-open-en.png` — 切换菜单弹层 + 当前态 ✓ 勾
- `i18n-after-pick-zh.png` — 英文 → 用户切到中文 → 全部中文
- `i18n-after-pick-en.png` — 中文 → 用户切到英文 → 全部英文
- `i18n-persisted-zh-despite-en-nav.png` — 英文浏览器 + localStorage='zh' → 中文（持久化生效）

`Hero` typewriter 在切换 locale 时销毁旧实例、按新词列表重建 — 实测每次 `qb:locale-applied` 事件触发后 Antigravity / Codex / Claude / MiniMax / Kimi / Zcode 重新轮播。

#### 完成工作

- `src/i18n/dict.ts`（58 个 key，en + zh 两套）
- `src/i18n/apply.ts`（locale 检测 + 持久化 + 应用）
- `src/components/LocaleSwitcher.astro`（Nav 切换菜单，含点击外部关闭、Esc 关闭、固定定位 bbox 计算）
- `src/layouts/Layout.astro`：head 字典注入 + locale 检测 + body 末尾 i18n 同步替换
- `src/components/Nav.astro`：import LocaleSwitcher、Changelog/Download 按钮加 `data-i18n`
- `src/components/Hero.astro`：title 三段拆分 + typewriter 双语词表 + 重建逻辑
- `src/components/ProductPreview.astro`：4 tab + heading 双语
- `src/components/Features.astro`：数组循环 + 9 张卡双语
- `src/components/Pricing.astro`：heading / 副 / plan / 5 bullets / CTA / 提示 全双语
- `src/components/FAQ.astro`：4 个问答双语
- `src/components/Footer.astro`：tagline + 列标题 + 5 链接双语
- `README.md`：增「i18n 工作机制」章节 + 目录索引同步
- `REQUIREMENTS.md`：un-defer `[0.2.0-FE-A-002]`，新建 Phase v0.8.0 双语 i18n 子任务并全部完成

#### 更新的需求 ID

- `[0.2.0-FE-A-002] 中英双语切换` — **完成**（un-deferred → 完成）
- 新建 `Phase v0.8.0 - 双语 i18n + Locale 自动检测`，全部子任务完成

#### 验证方式

- `npm run build` 通过；`dist/index.html` 含 `QB_I18N`（58 个 key） + 58 个 `[data-i18n]` 节点
- Playwright 5 场景截图已存 `/tmp/website-screenshots/i18n-*.png`
- 持久化测试：手动注入 `localStorage.qb_locale='zh'`，新会话里 navigator=en 也展示中文
- Hero typewriter locale 切换后正常轮播新词
- 切换菜单 UI：点击 → 显示 EN / 中文（带当前态 ✓）→ 选中 → 关闭菜单 + 全站替换 + typewriter 重建

#### 备注

- 字体策略已支持中英混排（JetBrains Mono NL + 系统中文 fallback），中英混排无需额外改动
- Astro frontmatter 里 `define:vars` 不能传 string（JSON.stringify 结果），必须传对象
- `is:inline` 脚本的"同步替换 [data-i18n]" 必须放在 body 末尾（slot 后），不能在 head 跑（querySelectorAll 找不到还没解析的 DOM 节点）
- LocaleSwitcher 切换器位置用了 `position: fixed` + `getBoundingClientRect()` 计算，避免被父级 `transform` / `overflow` 影响
- Phase v0.8.0 是个纯功能 / UI 任务；目前测试只跑了 Playwright 自动化截图，没有 xcode / vitest / 等其它 test 基础设施（QA 任务做得粗，符合"够用就够"）
