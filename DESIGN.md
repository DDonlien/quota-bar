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
- 订阅名称：14 pt，regular。
- 订阅金额：13 pt，regular，次级灰。
- 额度标签：11 pt，medium。
- 刷新时间与百分比：11 pt，regular，次级灰。

## 间距与布局

- 菜单内容宽度：custom dashboard 约 292 pt，原生菜单根据最宽内容自动确定整体宽度。
- 菜单内容高度：custom dashboard 约 300 pt，下方操作项由 `NSMenu` 默认行高决定；顶部需保留足够空间避免 `NSMenuItem.view` 裁切文字。
- 菜单栏 status item 不使用固定 80 pt 宽度；长度随当前多 bar image 宽度增加，最小保持系统方形点击区域。
- 菜单栏多 bar 图标中，每个可用订阅对应 1 个垂直矩形 bar；bar 本体无圆角，bar 之间不出现圆角缝隙。
- 面板圆角、阴影和边缘：由 `NSMenu` 系统绘制。
- dashboard 内边距：水平 14 pt，顶部 16 pt，底部 10 pt。
- 分组之间使用 1 pt 分隔线。
- 服务状态点占 13 pt 左侧轨道并居中，对齐顶部标题第一个字的视觉中心；服务名、额度行和进度条从该轨道右侧开始，对齐顶部标题第二个字的左边缘。
- 进度条高度：6 pt，胶囊圆角；0% 不显示蓝色填充。

## 手动调参入口

- dashboard 的宽高、padding、分隔线间距、行距、字号、字重、状态点轨道和进度条高度集中在 `drop-down-test/CodingPlanMenu/Sources/CodingPlanMenu/MenuView.swift` 的 `MenuDashboardStyle`。
- `MenuDashboardStyle.height` 调整 custom dashboard 的高度；如果底部内容被原生菜单项裁切，优先增加该值。
- `MenuDashboardStyle.topPadding`、`horizontalPadding`、`bottomPadding` 调整 dashboard 内边距。
- `MenuDashboardStyle.summaryWeight`、`planNameWeight`、`quotaTitleWeight` 调整主要文字粗细。
- `StatusBarController.swift` 中 `NSHostingView` 使用同一组 `MenuDashboardStyle.width` / `height`，无需重复修改。

## 组件风格

- 下拉面板：`NSMenu` 承载，不使用自绘 `NSWindow` dropdown。
- 顶部汇总：两行左右对齐，左侧黑色标题，右侧灰色数值。
- 服务标题行：左侧状态圆点和服务名，右侧月费。
- 额度行：上方一行标签、刷新时间和百分比，下方一条进度。
- 底部操作：使用原生 `NSMenuItem`，包含图标、标题、系统高亮和快捷键。

## 动效

- 当前原型不使用显式动效。
- 后续如加入刷新或展开状态，应使用系统级短时长缓动，避免夸张转场。

## 可访问性

- 保持文本在当前菜单宽度内不截断关键数值，尤其是服务名、刷新时间、百分比和底部操作。
- 颜色不作为唯一信息来源；实际功能阶段应补充文本状态。
- 退出按钮保留明确文字标签。
