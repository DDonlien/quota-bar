# 在模型页展开各额度获取渠道的真实三态状态

- ID：`0.14.0-DATA-C-000`。
- 类型：`DATA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.14.0 - 大陆可达性兜底 + 额度节奏指示 + Kimi 额度修复 / sub/main: Preferences「每个渠道获取状态」— 模型页展开三态指示器。
- 原稳定 ID：`0.14.0-DATA-C-000`, `0.14.0-DATA-C-001`, `0.14.0-FE-C-000`, `0.14.0-FE-C-001`, `0.14.0-QA-D-000`, `0.14.0-QA-D-001`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 需求原文（用户反馈上面的 Work/Code 部分成功部分失败排查过程后提出）："我知道问题出在哪了。你可能
> 通过别的方式获取到了 Kimi work（也就是月额度），但是需要通过 web view 或别的方式才能获取到 Kimi 的
> 小时和周额度。但这时候，我们的交互又没有办法提示用户去做那些操作。我觉得这个事情无法预见，应该在
> preference 里面，去调整每个渠道获取的情况：1. 自动化获取的：正常显示。2. 当前 provider 没有获取到的：
> 应该跟获取到的在样式上有所区别。3. Web view：在没有授权的情况下，应该可以点击，展开进行手动授权。"
>
> 放置位置跟用户确认过：「模型」设置页每个 provider 行下方展开（而不是新开独立页面）。完整方案见
> `/Users/taobe/.claude/plans/eventual-sauteeing-leaf.md`。核心结论：`ProviderSourceIndexStore`
> 已经在每轮刷新时持久化了逐渠道的成功/失败记录（`FetchPipeline.recordSuccess`/`recordError`），
> `WebAuthorizationController.openAuthorization(for:)` + `WKWebViewHeadlessLoader.appSessionHasCookies`
> 也已经是 dropdown 现成在用的点击授权实现——这个功能本质是给已有的结构化数据加读取 API + 通知，
> 再加一层纯展示 UI，不需要改动 fetch pipeline 本身的任何行为。

- [x] [0.14.0-DATA-C-000] `ProviderSourceIndexStore` 新增 `records(for:layer:)` 读取 API + `save()` 末尾发 `.providerSourceIndexDidChange` 通知
- [x] [0.14.0-DATA-C-001] `Strategies.swift` 新增 `ProviderChannelDescriptor` + `ProviderPipelines.quotaChannels(for:)`（复用 `makePipelines()`，按 `supportedLayers.contains(.quota)` 过滤掉 keychain 这类不贡献额度数据的 strategy）
- [x] [0.14.0-FE-C-000] 新文件 `Preferences/ProviderChannelStatusView.swift`：`ProviderChannelStatusList`/`ProviderChannelRow`，三态渲染 + webview 未授权时的点击态（复用 `QuotaAuthPromptRow` 的 `.task`+`onTapGesture` 结构）；实现过程中发现并修掉一个真实的状态残留 bug——webview 渠道从"未授权"变成"刚成功"时，`needsWebAuth` 的异步检查不会因为 record 内容变化而重新触发（`.task(id:)` 绑的是不变的 `sourceId`），加了 `&& !isSuccess` 兜底，让"去授权"按钮在刚成功那一刻就消失，不用等下一次巧合触发的重新检查
- [x] [0.14.0-FE-C-001] `ModelsSettingsView` 加展开交互（`expandedProviders` 状态 + chevron 按钮 + 条件渲染 `ProviderChannelStatusList`），不改动现有静态 `providerSubtitle`/`providerAccessModes`
- [x] [0.14.0-QA-D-000] 新增测试：`QuotaPersistenceTests.recordsForKindReturnsAllChannelsIncludingFailures`（追加到已有文件，同一个 store 已经在测）+ 新文件 `ProviderChannelDescriptorTests.swift`。`swift test` 220/220 通过
- [x] [0.14.0-QA-D-001] 实机验证：computer-use 无法识别 `swift run`/本地 ad-hoc 签名的 `.app`（不是 Launch Services 里的正常安装应用，两次 `request_access` 均返回 not-installed），改用直接读取一次真实刷新周期后的 `provider-sources.json` 手工核对三态分类逻辑——真实数据（kimi-desktop-token 成功、kimi-auth 失败带 "refresh_token 已失效"、kimi-webview 未授权且 `failureCount=163`）按 `ProviderChannelRow` 的判定逻辑手工走一遍，三种状态分类结果均正确；像素级视觉效果仍需用户实机确认

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
