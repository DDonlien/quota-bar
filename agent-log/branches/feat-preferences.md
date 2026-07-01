# feat/preferences

## 用途

偏好设置面板（P2 deferred）后续实现的独立工作线。当前 main 上已经把菜单里的
"偏好设置..."项隐藏（commit `e522a1b`），因为 `openPreferences()` 只是个
`NSSound.beep()` 占位，没真实面板可以打开。

> 注：branch 名称原为 `feat/hide-preferences`，2026-06-28 重命名为
> `feat/preferences`（方向从"先隐藏再恢复"转为"直接实现偏好面板"，
> 更贴合 v0.3.0-PM-A-000 的最终目标）。

等 v0.3.0-PM-A-000 偏好设置页面真正落地时，再从这个 branch 恢复菜单项 + 实现
PreferencesView。

## 关联 Phase / Task

- `v0.3.0-PM-A-000` 偏好设置页面 / 窗口：Provider 开关、刷新间隔自定义、高级选项 #P2 #deferred
- `v0.3.0-PM-A-001~006` 偏好设置相关 sub-task（手动添加 Provider / 浏览器选择 / 图标模式 / incident / WidgetKit / CLI）

## 起点

- 基于 main `@ 8d69017`（Step 1 收尾后）
- 由 `e522a1b feat(ui): hide preferences menu item` 落地的隐藏状态作为前置

## 当前状态

init — 暂无实际工作。

## 后续入口

- 重新暴露菜单项：解注释 `StatusBarController.swift` buildMenu 中相关行
- 实现 PreferencesView：建议 SwiftUI Form + Settings 风格（macOS 13+ `Settings` scene）
- 把 Provider 开关 / 刷新间隔 / 高级选项落到 PreferencesView