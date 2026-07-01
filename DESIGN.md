# 视觉规范

## 视觉主题

- 关键词：传统 macOS 菜单栏 dropdown、原生 `NSMenu`、紧凑信息面板、额度进度。
- 整体气质：系统菜单、轻量、透明混合自然、清晰层级、可扫读。
- 应避免的气质：自绘浮窗感、固定灰色面板、网页卡片感、强营销感、过度装饰。

## 参考对象

- Hidden Bar：状态栏项目挂载原生 `NSMenu`，普通操作项由系统菜单绘制，图标尺寸紧凑。
- Mos：状态栏管理器使用 `NSStatusItem` + `NSMenu`，菜单项通过系统默认字体、padding、分隔线和快捷键展示。
- 系统电池 / Wi-Fi：复杂信息可放在菜单内容上部，但背景、圆角、透明和阴影仍由系统 dropdown 负责。

## 色彩

- 面板背景：由原生 `NSMenu` 绘制，不叠加固定灰色圆角底。
- 正文：使用系统 `primary`，随材质和系统外观保持自然对比。
- 次级文本：使用系统 `secondary`。
- 分隔线：系统主文本约 12% 透明度。
- 进度条背景：系统主文本约 8% 透明度。
- 进度条前景：系统蓝 `#0A7CFF`。
- 状态点：
  - Codex：绿色 `#35C85A`
  - MiniMax：红色 `#FF453A`
  - Kimi：橙色 `#FF9F0A`

## 字体

- 字体：系统字体 San Francisco，SwiftUI 中使用 `.system`。
- 原生菜单操作项：使用 `NSMenuItem` 默认字体、快捷键和高亮样式。
- 顶部标题：13 pt，medium。
- 顶部金额与计数：13 pt，regular，次级灰。
- 服务名称：白色（在菜单栏深色背景下保持清晰）。
- 订阅金额：13 pt，regular，次级灰。
- 计划头部「订阅/数据最后有效日期」：11 pt，regular，次级灰，等宽数字；在订阅金额左侧，gap 6 pt。语义上表达「该 provider 当前剩余额度过期日」。Hover 显示精确时间（`yyyy-MM-dd HH:mm:ss zzz` 本地时区，例如 `2026-06-25 22:00:00 GMT+8`），避免 `yyyy/M/d` 看不到时分的歧义。
- 额度标签：11 pt，medium。
- 刷新时间与百分比：11 pt，regular，次级灰。

## 间距与布局

- 菜单内容宽度：custom dashboard 约 292 pt，原生菜单根据最宽内容自动确定整体宽度。
- 菜单内容高度：custom dashboard 约 300 pt，下方操作项由 `NSMenu` 默认行高决定；顶部需保留足够空间避免 `NSMenuItem.view` 裁切文字。
- 菜单栏 status item 不使用固定 80 pt 宽度；长度随当前多 bar image 宽度增加，最小保持系统方形点击区域。
- 菜单栏多 bar 图标中，每个可用订阅对应 1 个垂直填充 bar；外框保留细白色圆角边框，不绘制额外蓝色胶囊底。bar 高度按该订阅最近重置 quota 窗口的剩余比例映射，0% 仍保留可见的最小高度；相邻 bar 紧贴排列（gap 1pt），每个 bar 自身带 2pt 圆角。bar 颜色使用白色（与服务名称白色对应，菜单栏图标整体保持统一简洁）。
- dropdown 额度进度条表达剩余额度健康状态：剩余比例 `<= 30%` 使用橙色，`> 30%` 使用系统蓝 `#0A7CFF`；不要用 provider brand color 表达进度条健康状态。
- 面板圆角、阴影和边缘：由 `NSMenu` 系统绘制。
- dashboard 内边距：水平 14 pt，顶部 16 pt，底部 10 pt。
- 分组之间使用 1 pt 分隔线。
- 服务状态点占 13 pt 左侧轨道并居中，对齐顶部标题第一个字的视觉中心；服务名、额度行和进度条从该轨道右侧开始，对齐顶部标题第二个字的左边缘。
- 进度条高度：6 pt，胶囊圆角；0% 不显示蓝色填充。

## 手动调参入口

- dashboard 的宽高、padding、分隔线间距、行距、字号、字重、状态点轨道和进度条高度集中在 `macos/Sources/QuotaBar/MenuView.swift` 的 `MenuDashboardStyle`。
- `MenuDashboardStyle.height` 调整 custom dashboard 的高度；如果底部内容被原生菜单项裁切，优先增加该值。
- `MenuDashboardStyle.topPadding`、`horizontalPadding`、`bottomPadding` 调整 dashboard 内边距。
- `MenuDashboardStyle.summaryWeight`、`planNameWeight`、`quotaTitleWeight` 调整主要文字粗细。
- `StatusBarController.swift` 中 `NSHostingView` 使用同一组 `MenuDashboardStyle.width` / `height`，无需重复修改。

## 组件风格

- 下拉面板：`NSMenu` 承载，不使用自绘 `NSWindow` dropdown。
- 顶部汇总：两行左右对齐，左侧黑色标题，右侧灰色数值。
- 服务标题行：左侧状态圆点和服务名，右侧「订阅/数据最后有效日期（灰、小字）」+「月费（次级灰、13pt）」。`needsConfiguration` 时右侧换为隐藏按钮，日期不展示；当 `subscriptionExpiresAt == nil` / `monthlyPrice == nil` / `availability != .available` 时右侧只渲染月费 Text，HStack 自动收缩、Spacer 把价格推回右边缘，不留空隙、不跳行。
- 额度行：上方一行标签、刷新时间和百分比，下方一条进度。
- 底部操作：使用原生 `NSMenuItem`，包含图标、标题、系统高亮和快捷键。

## 偏好设置窗口

- 整体参考 macOS 26 系统设置与 Vibe Island 设置页：左侧 sidebar 使用 SwiftUI/macOS 原生 `NavigationSplitView` + `List(.sidebar)` 绘制，不手搓卡片背景；系统负责侧边栏材质、圆角、选中态和 Liquid Glass 效果。右侧 detail 独立滚动，窗口底色使用系统 `windowBackgroundColor`。
- 每个 detail 页面顶部使用系统设置风格 toolbar 行：左侧为当前页面彩色 icon，页面标题 17 pt semibold 与 icon 基线对齐；header 与下方内容使用同一水平 inset，icon 与标题保持紧凑间距；不显示返回/前进按钮。标题层覆盖在滚动内容之上，使用系统 `.bar` 材质和向下渐隐的 mask，避免滚动内容被实心遮罩硬切。
- 设置分区使用 13 pt semibold 小标题 + 圆角矩形 group。group 内多行对象列表（例如 Provider 列表）保持紧凑行高，分割线从文本区域起始处对齐，不从卡片最左边贯穿。
- 设置项标题和说明小字属于同一个内容块：标题用 13 pt primary，说明用 11 pt secondary，直接位于标题下方；分隔线只用于区分不同设置项或不同对象，不在标题与说明之间额外插入短线。
- Provider 等多对象列表的图标控制在约 24 pt，开关使用更小的 `.mini` 控件尺寸，避免整行显得厚重。
- 通用页这类单设置项说明较长的页面，允许在同一 row 内用横线把标题/控件行与说明行隔开；横线保留左右 inset，不顶到 group 边缘，并在上下保留足够 breathing room，避免说明文字贴线。
- 通用页语言选项只提供「中文 / English」；菜单栏图标模式说明只描述当前选项，不在同一行同时解释合并和拆分。模型页 provider 行按「名称」+「供应商 | 当前真实接入方式」组织，访问模式从 App / CLI / Web / API / 待接入中按现有 pipeline 实际支持情况显示，不把未接入方式当作已支持能力展示。激活页只展示「未激活」状态、激活邮箱输入和禁用态「移除激活」按钮；不展示占位设备 ID、说明标题或本机标题。关于页不展示「应用」「链接」「维护」section 标题，不展示许可、平台、仓库/下载链接列表，只保留应用信息、开发者 Taobe、检查更新按钮与重置偏好入口。
- 关于页 build 号优先读取 `QBDisplayBuild`，fallback 到 `CFBundleVersion`；打包脚本写入格式为 `yymmdd.hhmmss.<branchname>`，branch 名中的 `/` 统一替换为 `-`。
- 偏好设置窗口尽量移除侧边栏收起按钮；sidebar 始终作为主要导航存在。若系统原生 sidebar 在特定 macOS 26 build 下强制显示控件，优先保留原生 sidebar 视觉，而不是改回自绘 sidebar。

## 动效

- 当前原型不使用显式动效。
- 后续如加入刷新或展开状态，应使用系统级短时长缓动，避免夸张转场。

## 可访问性

- 保持文本在当前菜单宽度内不截断关键数值，尤其是服务名、刷新时间、百分比和底部操作。
- 颜色不作为唯一信息来源；实际功能阶段应补充文本状态。
- 退出按钮保留明确文字标签。
