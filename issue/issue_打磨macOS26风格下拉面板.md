---
title: 打磨macOS26风格下拉面板
id: 0.1.0-UI-A-000
type: UI
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.1.0 - Dropdown 视觉原型 / sub/main: 打磨 macOS 26 风格下拉面板。'
原稳定 ID: '`0.1.0-UI-A-000`, `0.1.0-UI-A-001`, `0.1.0-UI-A-002`, `0.1.0-UI-A-003`, `0.1.0-UI-A-004`, `0.1.0-UI-A-005`, `0.1.0-UI-A-006`, `0.1.0-UI-A-007`, `0.1.0-UI-A-008`, `0.1.0-UI-A-009`, `0.1.0-UI-A-010`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.1.0-UI-A-004`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.1.0-UI-A-000`、`0.1.0-UI-A-001`、`0.1.0-UI-A-002`、`0.1.0-UI-A-003`、`0.1.0-UI-A-004`、`0.1.0-UI-A-005`、`0.1.0-UI-A-006`、`0.1.0-UI-A-009`、`0.1.0-UI-A-010`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.1.0-UI-A-004-UI-macos-panel-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'sub/main: 打磨 macOS 26 风格下拉面板。'
同源任务: '[启动后仅显示菜单栏图标并按点击打开面板](issue_%E5%90%AF%E5%8A%A8%E5%90%8E%E4%BB%85%E6%98%BE%E7%A4%BA%E8%8F%9C%E5%8D%95%E6%A0%8F%E5%9B%BE%E6%A0%87%E5%B9%B6%E6%8C%89%E7%82%B9%E5%87%BB%E6%89%93%E5%BC%80%E9%9D%A2%E6%9D%BF.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

- [x] [0.1.0-UI-A-000] 将现有 dropdown 页面改为用户截图所示的 macOS 26 风格 #ui #P0
- [x] [0.1.0-UI-A-001] 顶部展示"每月费用 ¥150/月"和"可用订阅 2/3"
- [x] [0.1.0-UI-A-002] 按订阅服务分组展示 Codex Plus、MiniMax Plus、Kimi Plus
- [x] [0.1.0-UI-A-003] 每个订阅展示彩色状态点、月费、5 小时额度和周额度进度条
- [x] [0.1.0-UI-A-004] 底部展示自动刷新说明、上次刷新时间和退出入口
- [x] [0.1.0-UI-A-005] 保持当前为静态 UI，占位等待后续实际功能
- [x] [0.1.0-UI-A-006] 修正 dropdown 可读性问题，避免顶部、底部和关键字段在当前静态数据下被裁切或省略 #ui #P0
- [x] [0.1.0-UI-A-009] 下拉面板使用系统玻璃材质参与背景混合，不使用固定灰色面板覆盖材质 #ui #P0
- [x] [0.1.0-UI-A-010] 调整 dropdown 字号接近系统菜单层级，避免标题和服务名过大 #ui #P0

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260629104500-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260629104500-utcp8-mavis.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> B，并且我也有发你参考图 /var/folders/x1/nj8gw6sj3tz36zt026sy8h2m0000gn/T/TemporaryItems/NSIRD_screencaptureui_P6vUFc/截屏2026-06-29 10.30.02.png

#### 完成工作

- [x] 新建 `SettingsComponents.swift`（4 个组件：Section / Group / Row / Divider）
- [x] `PreferencesSection.swift`：加 `tint: Color` 属性
- [x] `PreferencesScene.swift`：sidebar 彩色 icon + Section("title")，detail 用 ScrollView + 自定义组件
- [x] 重写 `GeneralSettingsView`（slider 拆两行）
- [x] 重写 `ModelsSettingsView`
- [x] 重写 `ActivationSettingsView`
- [x] 重写 `AboutSettingsView`
- [x] `PreferencesWindowController`：titlebar transparent + .fullSizeContentView
- [x] `swift build`：0 warning
- [x] `swift test`：20 tests in 4 suites passed
- [x] `make app`：打 .app（build/20260629-104317-feat-preferences/）
- [x] 启动验证：`lsappinfo` 查 windows=NULL（不弹空窗）
- [x] commit `e6a188d`

#### 更新的需求 ID

- `v0.3.0-PM-A-006` 偏好设置窗口——视觉风格升级到 macOS 26 系统设置

#### 验证方式

- `swift build`：0 warning
- `swift test`：20 tests in 4 suites passed
- 启动 .app：windows=NULL（空窗口 bug 持续修复）
- 视觉验证：让用户跑 .app，⌘, 打开偏好窗口，对比参考图

#### 备注

- 已知 trade-off：
  - `titlebarAppearsTransparent` + `.fullSizeContentView` 让 traffic light 浮在 sidebar 顶部，
    第一个 row 可能会被遮挡。**需要用户实机验证**，如有遮挡给 sidebar 加顶部 padding。
  - sidebar 选中行不手染蓝后，macOS 26 会自动用 glass 高亮（跟系统设置一致）。
  - Detail section title 改用 13pt semibold primary（小标题），与参考图「系统」「展开」等风格一致。
- `agent-log/branches/feat-preferences.md` 没更新（之前轮没建），下个 phase 收尾时统一建。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260630-004605-utcp8-taobe-gpt-5.md — 历史证据迁移

来源：`agent-log/20260630-004605-utcp8-taobe-gpt-5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 把它改成相对链接，也就是获取这个 latest 文件夹所在的同一层级的其他文件夹中最新的那个链接

#### 完成工作

- `macos/build/latest` 规则改为相对软链。
- `build-app.sh` 不再把绝对路径写入 `latest`。
- README 与需求记录已同步。

#### 更新的需求 ID

- 新增并完成 `0.5.0-ENG-A-004`。

#### 验证方式

- `bash -n macos/scripts/build-app.sh` 通过。
- `readlink macos/build/latest` 返回 `20260626-160957`。
- `test -d macos/build/latest/QuotaBar.app` 通过。
- `git diff --stat` 确认仅修改 README、REQUIREMENTS 与打包脚本。

#### 备注

- 本次未执行 `make app`，避免额外生成新的 `.app` 构建产物；已用脚本语法检查与现有构建链接解析验证规则。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-070343_Agent

原记录标题：2026-10-24 07:03:43 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-162234_Codex

按用户最新手写模板迁移属性和正文结构，保留任务语义、来源、原始状态及历史内容；本次未重新执行业务验收。

原版本关联记录（照录来源，不将本次文档迁移提交当作业务实施提交）：
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。

本次执行环境未提供具体模型标识，未补造 Model-Detail。

[本次文档迁移对话](codex://threads/01a157b3-610c-73b4-ae06-163c0f8490d3)
