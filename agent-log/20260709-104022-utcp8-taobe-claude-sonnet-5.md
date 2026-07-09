# 用户原始 prompt

>（截图：Z Code 展开编辑态，名称行下面多了一条分割线，再下面才是灰字"未配置..."，再下面是 TextField + 保存按钮，输入框和保存按钮都明显往左偏、没跟上面对齐）
>
> 处理一下这里展开的对齐关系：
> 首先不应该额外加一条分割线
> 让输入框代替原来的灰色字体占位符就好了
> 确保输入框左端和名称正常对齐，保存按钮和取消按钮对齐

# 启动运行时的分支和版本

- 分支：`main`
- 版本：本轮基于上一轮（opencode 重置时间格式统一）未提交的工作树继续

# 任务开始时间

2026-07-09 10:36 +0800

# 任务结束时间

2026-07-09 10:40 +0800

# 任务结束时是否执行了提交

否——按惯例留给用户确认后再决定是否提交/推送。

# 已阅读上下文

- `Preferences/ModelsSettingsView.swift` 的 `APIKeyConfigRow` 全文。
- `Preferences/SettingsComponents.swift` 的 `SettingsRow` 实现（`subtitleLeading` 只作用于 `subtitle:` 参数，不作用于 `label:`）。

# 对话与行动记录

读代码定位到三个问题的同一个根因：`APIKeyConfigRow` 展开编辑态是叠两个 `SettingsRow` 拼出来的——第一个展示名称/状态/配置按钮，第二个（`isEditing` 时）在前面加一个 `SettingsDivider(leading: 36)`，展示 TextField + 保存按钮。

- 分割线：就是这个额外插入的 `SettingsDivider`。
- 对齐：`SettingsRow` 的 `subtitleLeading` 参数只会应用在 `subtitle:` 这个专门的 `Text` 参数上；但输入框那一整行（TextField + 保存按钮）因为不是纯文本，没法塞进 `subtitle:`（类型是 `Text`），只能塞进 `label:` 参数——而 `subtitleLeading` 对 `label:` 完全不生效，所以整行是从 `horizontalPadding`（16pt）开始的，没有对齐到名称文字实际起始的 36pt（图标 24pt + 间距 12pt）位置；保存按钮也是紧跟在输入框右边（在 `label` 内部），不在跟"取消"共享的 trailing 列里。
- 灰字占位符没被替代：第一个 `SettingsRow` 无论是否 `isEditing` 都会展示 `statusText`，所以编辑态下灰字和输入框同时存在。

三个问题本质是同一处结构问题——`SettingsRow` 的 subtitle 机制塞不下一个可交互控件。解法：整个 `APIKeyConfigRow` 不再复用 `SettingsRow`，手动拼一个 `VStack`（照抄 `SettingsRow` 的 padding/字号/颜色常量，保持跟页面其余行视觉一致）：名称 + 取消/配置按钮共享一个 `HStack`（构成 trailing 对齐列）；下面直接跟一行，`isEditing` 时是 `TextField` + 保存按钮（用 `.padding(.leading, 36)` 手动对齐到名称文字下方，保存按钮紧跟输入框、贴着行末，天然跟上一行的取消按钮共享同一个右边界），非编辑态时是原来的灰字状态说明——两者互斥，不会同时出现。全程不再引入任何分割线。

# 完成工作

- `Preferences/ModelsSettingsView.swift`：`APIKeyConfigRow.body` 整个重写，不再调用 `SettingsRow`/`SettingsDivider`，改成手动 `VStack` + `.padding(.leading, 36)` 对齐。

# 更新的需求 ID

- `[0.10.0-BUG-A-028]`

# 更新的 README 或 DESIGN 章节

- 无。

# 验证方式

- `swift build`：无警告无错误。
- `swift test`：195 tests in 44 suites 全部通过（纯 UI 布局改动，无行为变化，未新增/删除测试）。
- `./scripts/build-app.sh`：产包成功，重启本机开发态实例指向新包，方便用户直接确认视觉效果。

# 备注

- 未提交 git commit。
- 没能用 computer-use 实机截图验证（同前几轮的原因：accessory 模式 + 未签名开发态包不在系统应用索引里），这次是纯代码走读 + 手算 padding 数值确认对齐关系（16pt 外边距 + 24pt 图标 + 12pt 间距 = 36pt，跟 `.padding(.leading, 36)` 精确对上），建议用户打开 Preferences「模型」页展开一个 provider 的 API Key 配置确认。
