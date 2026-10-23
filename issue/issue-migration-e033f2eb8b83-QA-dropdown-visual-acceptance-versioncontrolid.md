# sub/main: 完成 Dropdown 视觉原型验收

- ID：`migration-e033f2eb8b83`。
- 类型：`QA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.1.0 - Dropdown 视觉原型 / sub/main: 完成 Dropdown 视觉原型验收。
- 原稳定 ID：`0.1.0-QA-A-001`, `0.1.0-QA-A-002`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.1.0-QA-A-001] 相关文档已更新
- [x] [0.1.0-QA-A-002] 相关构建命令已执行或记录无法执行原因

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260707-101937-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260707-101937-utcp8-taobe-claude-sonnet-5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 3个问题：
> 1. dropdown不规范，zcode要么就是webview授权，要么就确定（之前没说）没有订阅，显示灰色字未订阅；另外，只有在明确获取到额度/订阅信息是未订阅，显示"未订阅或订阅已过期"，如果只是不清楚是否订阅，显示webview授权按钮
> 2. 日志叫日志就好，不用叫获取日志
> 3. 查看这个日志：为什么很多provider的额度、档位信息只走了1个方案就没有走其他fallback了？
>（附完整 `provider-check.log` 片段，覆盖 Z Code / MiniMax / Claude / Kimi / Codex / Antigravity）

#### 完成工作

- `ProviderFetchStrategy.swift`：删除 `orderedStrategies` 的缓存重排逻辑，恒定按声明顺序执行；`logSourceOrdering` 改写措辞明确"仅供参考，不改变执行顺序"。
- `ClaudeAuthStatusCLIProvider.swift`：`parseStatusOutput` 改为 `async`，调用 `ProviderPricing.localizedMonthlyPrice(kind: .claude, tier:)` 补上价格。
- `MenuView.swift`：`.needsConfiguration` 分支按"有无 WebView 授权入口"分流（只给按钮 / 只给原始 reason，二选一，不再同时出现）；`.notSubscribed` 分支改为固定文案「未订阅或订阅已过期」；`StatusRow` 精简掉不再使用的 `actionTitle`/`action` 参数。
- `Preferences/PreferencesSection.swift`：sidebar 标签「获取日志」→「日志」。
- `README.md`：同步更新数据流/诊断日志/dropdown 章节，补充"排序恒等于声明顺序，不受缓存影响"的说明，以及待配置态两种确定性的显示规则。
- 测试：更新 `ClaudeOAuthUsageProviderTests.swift` 里 `ClaudeAuthStatusCLIProvider parsing` 套件的三个测试为 `async`，新增价格非空断言。
- 新包：`macos/build/20260707-101930-main/Quota Bar.app`（`build/latest` 已指向）。

#### 更新的需求 ID

- 新增并完成：`0.10.0-BUG-A-002`（strategy 排序重排 bug）、`0.10.0-BUG-A-003`（Claude 价格丢失 bug）、`0.10.0-UI-B-002`（needsConfiguration 分支重写）、`0.10.0-UI-B-003`（notSubscribed 分支重写）、`0.10.0-PM-A-015`（日志标签简化）

#### 验证方式

- `swift build`：无警告无错误。
- `swift test`：176 tests in 41 suites 全部通过，包括原本用来保护"缓存不能让部分覆盖来源抢在完整来源前面"这条性质的 `quotaOnlySourceCannotShadowFullSource`——确认删除重排逻辑后，靠自然声明顺序就已经满足该测试。
- `./scripts/build-app.sh`：产包成功。
- 未做真实 GUI 交互验证（未启动打包后的 app 手动核对 Z Code/Claude 显示效果），仍是靠单元测试 + 代码走读 + 用户提供的真实日志确认逻辑；这点如实告知。

#### 备注

- 未提交 git commit。
- 这一轮最大的收获是方法论上的：上一轮刚上线的结构化诊断日志，第一次真实使用就直接暴露了两个此前完全没被注意到的架构性 bug（strategy 排序、Claude 价格丢失）——不是靠猜、也不是靠再加一层日志去调试日志，而是用户直接读原始记录发现的不合理之处，反向定位到代码。这印证了当初做这套日志系统是值得的。
- `orderedStrategies` 删除重排逻辑后，`sourceIndexStore`/`preferredSourceID` 在 pipeline 排序层面已经不再被使用，仅保留给"安装探测的 preferredSourceId 快速路径"（`InstallDetectorProvider.detectPreferredSource`，性质不同、继续保留）和"缓存 snapshot 的来源标注"（`RefreshCoordinator.snapshotCacheSourceRecord`，纯展示用途、继续保留）两处合理场景使用；没有变成完全的死代码。
