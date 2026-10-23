# sub/main: API Key 配置行展开态的对齐问题

- ID：`0.10.0-BUG-A-028`。
- 类型：`UI`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: API Key 配置行展开态的对齐问题。
- 原稳定 ID：`0.10.0-BUG-A-028`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户给了一张 Z Code 展开编辑态的截图，指出三点：不应该多一条分割线；输入框应该直接代替原来的灰字占位符；输入框左端要跟名称对齐、保存按钮要跟取消按钮对齐。

- [x] [0.10.0-BUG-A-028] 根因：`APIKeyConfigRow` 展开编辑态之前是叠两个 `SettingsRow` + 一个 `SettingsDivider(leading: 36)` 拼出来的——多出的分割线就是这么来的；输入框那一整行（`TextField` + 「保存」按钮）传给的是第二个 `SettingsRow` 的 `label:` 参数而不是 `subtitle:`（`SettingsRow.subtitle` 类型是 `Text`，塞不进一个可交互控件），导致同时传的 `subtitleLeading: 36` 对它完全不生效——`label` 从 `horizontalPadding`（16pt）算起，没有对齐到名称文字的 36pt 起始位置；「保存」按钮也不在跟「取消」同一个 trailing 列里，是紧跟在 `label` HStack 内部的输入框右边。修复：不再复用 `SettingsRow`，改成手动拼一个 `VStack`（跟 `SettingsRow` 完全一致的 padding/字号/颜色常量保持视觉统一）：名称行和「取消/配置」按钮共享一个 `HStack`（trailing 列），下面直接跟一行——非编辑态是灰字状态说明，编辑态换成 `TextField` + 「保存」按钮，`.padding(.leading, 36)` 手动对齐到名称文字下方；「保存」跟随 `TextField` 在同一个 `HStack` 里、贴着行末，跟上一行「取消」按钮共享同一个右边界。整个过程没有再引入任何分割线 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260709-104022-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260709-104022-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

>（截图：Z Code 展开编辑态，名称行下面多了一条分割线，再下面才是灰字"未配置..."，再下面是 TextField + 保存按钮，输入框和保存按钮都明显往左偏、没跟上面对齐）
>
> 处理一下这里展开的对齐关系：
> 首先不应该额外加一条分割线
> 让输入框代替原来的灰色字体占位符就好了
> 确保输入框左端和名称正常对齐，保存按钮和取消按钮对齐

#### 完成工作

- `Preferences/ModelsSettingsView.swift`：`APIKeyConfigRow.body` 整个重写，不再调用 `SettingsRow`/`SettingsDivider`，改成手动 `VStack` + `.padding(.leading, 36)` 对齐。

#### 更新的需求 ID

- `[0.10.0-BUG-A-028]`

#### 验证方式

- `swift build`：无警告无错误。
- `swift test`：195 tests in 44 suites 全部通过（纯 UI 布局改动，无行为变化，未新增/删除测试）。
- `./scripts/build-app.sh`：产包成功，重启本机开发态实例指向新包，方便用户直接确认视觉效果。

#### 备注

- 未提交 git commit。
- 没能用 computer-use 实机截图验证（同前几轮的原因：accessory 模式 + 未签名开发态包不在系统应用索引里），这次是纯代码走读 + 手算 padding 数值确认对齐关系（16pt 外边距 + 24pt 图标 + 12pt 间距 = 36pt，跟 `.padding(.leading, 36)` 精确对上），建议用户打开 Preferences「模型」页展开一个 provider 的 API Key 配置确认。
