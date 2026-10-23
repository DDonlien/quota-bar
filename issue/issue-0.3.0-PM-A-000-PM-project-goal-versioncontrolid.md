# PM-A：偏好设置与后续能力（激活）

- ID：`0.3.0-PM-A-000`。
- 类型：`PM`。
- 状态：进行中（原文同时包含已完成与未完成项）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `b550269a253e390d19ec221949fb30c44adf9e9e`；标题路径：任务清单 / Phase - v0.3.0 - UI 拖拽、订阅组语义与 dropdown 实时刷新 / PM-A：偏好设置与后续能力（激活）。
- 原稳定 ID：`0.3.0-PM-A-000`, `0.3.0-PM-A-001`, `0.3.0-PM-A-002`, `0.3.0-PM-A-003`, `0.3.0-PM-A-004`, `0.3.0-PM-A-005`, `0.3.0-PM-A-006`, `0.3.0-PM-A-007`, `0.3.0-PM-A-012`, `0.3.0-PM-A-008`, `0.3.0-PM-A-009`, `0.3.0-PM-A-010`, `0.3.0-PM-A-011`；不改写或重编号这些既有 ID。

## 当前需求与范围

> **2026-06-28 更新**：本组任务在 `feat/preferences` branch 落地第一版偏好设置窗口（macOS 26
> 系统设置风格，sidebar + detail，Liquid Glass），打通 `Cmd+,` 入口与 PreferencesStore
> 数据闭环。后续能力（手动添加 Provider / WidgetKit / CLI 等）暂留 P2 deferred。

- [x] [0.3.0-PM-A-000] 偏好设置窗口骨架：macOS 26 系统设置风格 sidebar + detail，Liquid Glass，`NavigationSplitView` + `Form`；`CodingPlanMenuApp` 用 SwiftUI `Settings` scene 注册并自动接入 `Cmd+,` 快捷键 #P1
- [x] [0.3.0-PM-A-001] sidebar 分组：默认组（无标题）放「通用」「模型」；「Quota Bar」组放「激活」「关于」；激活/关于项展示分组标题，未分组项不展示 #P1
- [x] [0.3.0-PM-A-002] 「通用」页：刷新间隔、浏览器 Cookie 来源、语言（中文 / English）、菜单栏图标模式（合并 / 拆分，说明随当前选项切换）、登录时启动 toggle（落地后接入 LoginService / SMAppService）#P1
- [x] [0.3.0-PM-A-003] 「模型」页：展示当前可配置的核心模型开关（Codex / MiniMax / Kimi / Claude / GLM），每行按「名称」+「供应商 | 当前真实接入方式（App / CLI / Web / API / 待接入）」展示；更多 Provider 的订阅获取进入后续需求 #P1
- [x] [0.3.0-PM-A-004] 「激活」页：展示未激活状态、激活邮箱输入和禁用态移除激活按钮；不展示占位设备 ID 或说明标题 #P1
- [x] [0.3.0-PM-A-005] 「关于」页：应用名 + 版本号 + 构建号（`Bundle.main` 读取）+ 开发者 Taobe + 检查更新 + 重置偏好按钮；不展示许可、平台和维护标题 #P1
- [x] [0.3.0-PM-A-006] 状态栏菜单恢复「偏好设置...」项（`Cmd+,`），点击触发 SwiftUI `Settings` scene；`openPreferences()` 方法从 NSSound.beep() stub 升级为 `NSApp.sendAction(Selector("showSettingsWindow:"), to: nil, from: nil)` #P1
- [x] [0.3.0-PM-A-007] `PreferencesStore.QuotaPreferences` 新增 `launchAtLogin: Bool` 字段（Codable 向后兼容，旧配置自动获得 `false`）#P1
- [x] [0.3.0-PM-A-012] 偏好设置视觉微调：左侧 sidebar 使用 macOS 26 原生 `NavigationSplitView` + `List(.sidebar)`，不手搓卡片背景；每页顶部使用固定 toolbar 标题（页面 icon + 标题，不显示返回/前进按钮）；说明小字与分割线遵循系统设置列表行样式，分割线保留左右 inset；Provider 等多对象列表收紧 padding 与开关尺寸；关于页保留应用信息、检查更新和重置入口；尽量移除侧边栏收起按钮 #P1
- [ ] [0.3.0-PM-A-008] 手动添加/移除 Provider 入口（覆盖自动探测结果）#P2 #deferred — 本次仅做"关闭自动探测结果"，手动添加不在本轮范围
- [ ] [0.3.0-PM-A-009] Provider 服务状态监控（incident 检测与展示）#P2 #deferred
- [ ] [0.3.0-PM-A-010] WidgetKit 桌面小组件 #P2 #deferred
- [ ] [0.3.0-PM-A-011] CLI 命令行工具（`quotabar status`）#P2 #deferred

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260630100319-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260630100319-utcp8-gpt5.md` @ `b550269a253e390d19ec221949fb30c44adf9e9e`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 还是不对，我说了，要用macos26的原生侧边栏组件

#### 完成工作

- [x] 左侧 sidebar 恢复 macOS 原生组件
- [x] 删除手工 sidebar card 背景
- [x] 新 app：`quota-bar/build/20260630-100256-preferences-main/QuotaBar.app`

#### 更新的需求 ID

- `[0.3.0-PM-A-012]`

#### 验证方式

- `cd quota-bar && swift build`
- `cd quota-bar && swift test`：20 tests in 4 suites passed
- `make app`：成功生成 `20260630-100256-preferences-main/QuotaBar.app`

#### 备注

- 原生 sidebar 与“隐藏 sidebar toggle”在 macOS 26 不同 build 上可能存在系统行为差异。本轮按用户优先级选择原生 sidebar 视觉。

### 20260630010159-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260630010159-utcp8-gpt5.md` @ `b550269a253e390d19ec221949fb30c44adf9e9e`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 为我做两个调整：
>
> 1. 所有选项的小字描述需要像 macOS 系统菜单一样，用横线分割之后再写上，参考附件2
> 2. 每一个页面需要有标题，标题可以参考 Veo Island 的设置选单，直接复刻左边的标题就行，注意 padding 就可以，参考附件一
> 3. 所有的（比如 provider 这边的）开关都有些太大了，请调整一下比例，参考附件 2。
> 4. 并且这种多个对象的页面，我觉得你的 padding 也有点问题，同样参考附件 2。
>
> 最后就是移除收起菜单左侧边栏的按钮

#### 完成工作

- [x] 所有页面顶部显示页面标题（图标 + 标题）
- [x] 设置项说明文字改为分隔线下说明
- [x] Provider 等多对象列表更紧凑，分隔线缩进与文本区域对齐
- [x] 开关尺寸调小
- [x] 移除侧边栏收起按钮
- [x] 生成新 app：`quota-bar/build/20260630-010051-preferences-main/QuotaBar.app`

#### 更新的需求 ID

- `[0.3.0-PM-A-012]` 新增并完成

#### 验证方式

- `git pull`
- `cd quota-bar && swift build`
- `cd quota-bar && swift test`：20 tests in 4 suites passed
- `make app`：成功生成 `20260630-010051-preferences-main/QuotaBar.app`

#### 备注

- 本轮保留了上一轮尚未提交的刷新间隔改动：`RefreshIntervalOption` 与通用页刷新间隔下拉框。它们与当前视觉调整同属 Preferences 页面工作线，最终提交时应一起整理提交说明。

### 20260701144539-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260701144539-utcp8-gpt5.md` @ `b550269a253e390d19ec221949fb30c44adf9e9e`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 第二行这四个是“选项”你实际应该按照我们支持的方式“显示”

#### 完成工作

- 模型页第二行现在按真实接入方式展示。
- 不再给 Codex / Kimi / Claude 硬塞 API 或 App。
- MiniMax 保留 CLI / Web / API，因为当前确有 CLI、Cookie Web 和 API key config provider。

#### 更新的需求 ID

- 更新 `[0.3.0-PM-A-003]`

#### 验证方式

- `cd quota-bar && swift build`：通过。
- `cd quota-bar && swift test`：通过，20 个测试全部通过。
- `make app`：通过，产物为 `quota-bar/build/20260701-144516-preferences-main/QuotaBar.app`。

#### 备注

- 当前展示语义为“现有 pipeline 支持/待接入”，不是 provider 理论能力清单。

### 20260701003450-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260701003450-utcp8-gpt5.md` @ `b550269a253e390d19ec221949fb30c44adf9e9e`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 移除这几个选项：
> - 模型：cursor、gemini、openai、deepseek、copilot、oupenrouter、perplexity、warp、trae、antigravity，把这些订阅的获取加入requirements，
> - 激活：说明、当前状态和本机的标题文字移除，保留未激活做成2行，第二行是一个文字输入，输入激活邮箱；
> - 关于：移除许可，开发者显示Taobe，移除维护的标题，移除平台
>
> 修改这几个选项：
> - 模型：加上GLM（智谱的模型）
> - 菜单栏：图标模式：改成合并、拆分就好
> - 激活：增加一个移除激活的按钮，设备id你显示的是啥？

补充：

> 侧边栏收起的按钮还在，记得移除

#### 完成工作

- 模型页显示范围和 GLM 已调整。
- 通用页图标模式文案已调整。
- 激活页和关于页结构已按用户要求精简。
- 设备 ID 占位已移除；此前显示的是基于 app bundle path hash 派生的伪 ID，并非真实硬件 ID。
- 侧边栏 visibility 改为固定显示，避免用户折叠 sidebar。
- requirements 和 DESIGN 已同步。

#### 更新的需求 ID

- 更新 `[0.3.0-PM-A-003]`
- 更新 `[0.3.0-PM-A-004]`
- 更新 `[0.3.0-PM-A-005]`
- 新增 `[0.4.0-DATA-C-001]` 到 `[0.4.0-DATA-C-011]`

#### 验证方式

- `cd quota-bar && swift build`：通过。
- `cd quota-bar && swift test`：通过，20 个测试全部通过。
- `make app`：通过，产物为 `quota-bar/build/20260701-003340-preferences-main/QuotaBar.app`。

#### 备注

- 本轮只从模型设置页隐藏未展示 provider，不从底层 enum 或数据 pipeline 移除它们，避免破坏历史偏好和后续订阅获取任务。

### 20260701143409-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260701143409-utcp8-gpt5.md` @ `b550269a253e390d19ec221949fb30c44adf9e9e`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 通用里增加语言选项，中文和英文
> 菜单栏的图标，不要一次性显示两个信息，合并就显示合并的描述，拆分就显示拆分的就好，也不用“合并：”
> 未激活的状态不应该能够移除激活
> provider需要跟随这个顺序展示内容：
> 名称（比如codex）
> 供应商（比如OpenAI）| 访问模式（App, CLI, Web，支持多少显示多少)
> Agy你somehow获取不到了

补充：

> 访问模式还有API，虽然现在其实不支持

#### 完成工作

- 通用页语言选项已添加。
- 菜单栏图标模式说明按当前模式单独展示。
- 未激活状态下移除激活按钮禁用。
- 模型页 provider 元信息结构已调整并包含 API 模式。
- Agy 安装探测补强。
- requirements / design 已同步。

#### 更新的需求 ID

- 更新 `[0.3.0-PM-A-002]`
- 更新 `[0.3.0-PM-A-003]`
- 更新 `[0.3.0-PM-A-004]`

#### 验证方式

- `cd quota-bar && swift build`：通过。
- `cd quota-bar && swift test`：通过，20 个测试全部通过。
- `make app`：通过，产物为 `quota-bar/build/20260701-143345-preferences-main/QuotaBar.app`。

#### 备注

- 语言选项当前先持久化偏好，实际全局文案切换需要后续接入本地化资源。
- API 访问模式先作为 provider 能力标签展示，不代表当前所有 API 路径都已接入真实额度获取。

### 20260630092645-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260630092645-utcp8-gpt5.md` @ `b550269a253e390d19ec221949fb30c44adf9e9e`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 首先，顶部的空间和对齐关系有一些问题。这个 Header 在右边的部分应该永远不动，参考右侧 Dynamic Island 的设计，并且它应该在顶部进行对齐，现在的对齐关系也不对，然后你新加的线，感觉 padding 也不太对，至少不是 macOS 26 标准实现，这个你检查一下，其他的元素和对齐关系也有类似的问题；模型这里问题最大。你已经用线区分模型和模型了，就不要在线和线之间再加一条两边不到顶的短线区分标题和正文了，看看附件 3，Mac 的系统自己是怎么做的。

#### 完成工作

- [x] 右侧 detail header 固定在顶部，不随 ScrollView 滚动
- [x] Provider 列表移除标题与说明之间的短线，只保留不同 Provider 之间的分割线
- [x] 说明文字规则改为 macOS 系统设置列表行语义
- [x] 将 Preferences 根容器从 `NavigationSplitView` 改为固定 sidebar + detail split，避开系统自动插入的 sidebar toggle
- [x] 新 app：`quota-bar/build/20260630-092825-preferences-main/QuotaBar.app`

#### 更新的需求 ID

- `[0.3.0-PM-A-012]` 文案修正：固定 header、行与行之间分割，标题与说明不额外插线。

#### 验证方式

- `cd quota-bar && swift build`
- `cd quota-bar && swift test`：20 tests in 4 suites passed
- `make app`：成功生成 `20260630-092825-preferences-main/QuotaBar.app`

#### 备注

- `NavigationSplitView` 会在部分系统状态下自动插入 sidebar toggle；本轮改用固定 split 布局规避该行为。

### 20260630095256-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260630095256-utcp8-gpt5.md` @ `b550269a253e390d19ec221949fb30c44adf9e9e`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 你左侧的卡片完全没用swift（macos26）的标准组件啊，一点都不liquid glass，你也可以看看附件6的右半部分；右侧的标题（通用这些）位置是对的，返回/前进按钮不需要，有icon就行
> group的上下padding不对，参考一下附件2的系统菜单；
> 附件3的分割线左侧的padding应该和右侧一样
> 附件4的未激活没用分割线，说明移除
> 附件5的第一个分割线左边的padding和右侧不一致；重制按钮下没有分割线；链接移除，应用和链接的文字都移除，给我一个“检查更新”的按钮

#### 用户补充 prompt

> 我说错了，应该是右边也不到底
>
> 然后激活和关于页，对齐关系都检查一下，不是很标准（参考macos最佳实践）

#### 完成工作

- [x] Header：icon + title，无返回/前进按钮
- [x] Sidebar：系统材质 Liquid Glass 风格卡片
- [x] Group/Row：上下 padding 调整
- [x] 模型页：分割线左右 inset 一致
- [x] 激活页：移除未激活说明
- [x] 关于页：检查更新按钮、移除链接列表、重置说明分割线
- [x] 新 app：`quota-bar/build/20260630-095133-preferences-main/QuotaBar.app`

#### 更新的需求 ID

- `[0.3.0-PM-A-012]`

#### 验证方式

- `cd quota-bar && swift build`
- `cd quota-bar && swift test`：20 tests in 4 suites passed
- `make app`：成功生成 `20260630-095133-preferences-main/QuotaBar.app`

#### 备注

- 关于页「检查更新」当前打开 GitHub Releases 页面，后续如需要可接入真正的更新检查服务。

### 20260630093952-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260630093952-utcp8-gpt5.md` @ `b550269a253e390d19ec221949fb30c44adf9e9e`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 我才注意到，左侧的菜单栏为什么没有用 macOS 26 标准的卡片效果，而是整个嵌入的？这不对啊。参考附件。
>
> 此外，通用这个页面所有的文字和它里面的小字，应该是用横线分行的。
>
> 模型这个页面的横线两边应该顶到头，现在只有右边顶到头了
>
> 然后这个标题的尺寸和位置，应该和系统菜单栏右半部分那个“返回”和“前进”的按钮在同一个位置、对齐关系。

#### 用户补充 prompt

> 我说错了，应该是右边也不到底
>
> 然后激活和关于页，对齐关系都检查一下，不是很标准（参考macos最佳实践）

#### 完成工作

- [x] 左侧 sidebar 卡片化
- [x] 右侧 header 改成 toolbar 行
- [x] 通用页标题/说明用横线分行
- [x] 模型页分割线两侧保留 inset
- [x] 激活 / 关于页对齐关系统一
- [x] 新 app：`quota-bar/build/20260630-093934-preferences-main/QuotaBar.app`

#### 更新的需求 ID

- `[0.3.0-PM-A-012]`

#### 验证方式

- `cd quota-bar && swift build`
- `cd quota-bar && swift test`：20 tests in 4 suites passed
- `make app`：成功生成 `20260630-093934-preferences-main/QuotaBar.app`

#### 备注

- 由于当前窗口外观高度依赖 macOS 26 的系统材质和 List sidebar 渲染，仍以用户实机截图作为最终视觉验收来源。
