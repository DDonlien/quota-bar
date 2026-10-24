# 排查APIKey粘贴崩溃并简化原生输入框

- ID：`0.10.0-BUG-A-023`。
- 类型：`SEC`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 粘贴 API Key 后应用崩溃（真实 SIGSEGV）+ 输入框改用原生 TextField。
- 原稳定 ID：`0.10.0-BUG-A-023`, `0.10.0-CLEAN-A-003`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户反馈"输入api密钥后应用会直接crush（只是粘贴甚至没有回车），以及你的输入框还是很不macos26"。

- [x] [0.10.0-BUG-A-023] 这次没有停留在猜测——直接从 `~/Library/Logs/DiagnosticReports/QuotaBar-2026-07-09-000952.ips` 读到真实崩溃报告：`EXC_BAD_ACCESS`/`SIGSEGV`（空指针解引用），主线程堆栈落在 WebKit 处理来自 WebContent 进程的异步 IPC 消息、提交 remote layer tree 时（`RemoteLayerTreePropertyApplier::applyHierarchyUpdates`），跟 API Key 输入框本身的代码完全不在同一条调用链上——粘贴动作只是恰好跟这次异步 IPC 回调撞在同一个 run loop tick，不是直接因果关系。最可疑的诱因：`0.10.0-BUG-A-019`（昨天）新增的 `WebKitSessionWarmup` 创建了一个 frame `.zero`、**永远不挂任何 `NSWindow`/superview** 的 `WKWebView`，长期存活却从未有真实的宿主环境——这跟 App 里其余所有 `WKWebView` 用法（`WebAuthorizationController` 登录窗口、`WKWebViewHeadlessLoader` 抓取窗口）都不一样，那些全部挂在真实 `NSWindow` 上。修复：给预热用的 `WKWebView` 一个真实的 `NSWindow`（永远不 `orderFront`，屏幕外坐标、不可见，只是给 WebKit 一个正常宿主环境），跟已知稳定的登录窗口用法保持一致 #P0
- [x] [0.10.0-CLEAN-A-003] 顺手做了一次简化：`APIKeyTextField`/`FocusTextField`（AppKit `NSTextField` 包装 + 两个全局 `NSEvent` 本地监听器拦截 `Cmd+V`/`mouseUp`）最初是专门为 dropdown 里 `NSMenu` tracking-mode 的内联输入框做的变通（`NSMenu` 的 modal 事件循环会挡住标准 Edit 菜单/焦点）——那个内联输入框已经在更早的改动里删掉了，`APIKeyConfigRow` 现在唯一还在用它的地方是 Preferences 的普通 `NSWindow`，那里完全用不上这套 AppKit workaround。改成原生 SwiftUI `TextField`（`.textFieldStyle(.roundedBorder)`），既解决了"还是很不 macOS 26"的视觉反馈，也顺手删掉了两个不再需要、却仍在全局拦截键盘/鼠标事件的 `NSEvent` 监听器（不确定是否跟 `0.10.0-BUG-A-023` 那次崩溃有关，但确认是不必要的额外风险面，删掉没有坏处）#P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260709-001608-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260709-001608-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 输入api密钥后应用会直接crush（只是粘贴甚至没有回车），以及你的输入框还是很不macos26

#### 完成工作

- `WKWebViewHeadlessLoader.swift`：`WebKitSessionWarmup.warmUp()` 改成给预热用的 `WKWebView` 一个真实的 `NSWindow`（屏幕外坐标 `-10000,-10000`、`.borderless`、永远不 `orderFront`/不可见），不再是一个裸的、没有任何宿主的 `WKWebView`。
- `MenuView.swift`：删除整个 `APIKeyTextField`/`FocusTextField`/其 `Coordinator`（含两个全局 `NSEvent` 监听器）——死代码，唯一调用点已经改用原生控件。
- `Preferences/ModelsSettingsView.swift`：`APIKeyConfigRow` 的输入框从 `APIKeyTextField` 改成原生 SwiftUI `TextField`（`.textFieldStyle(.roundedBorder)` + 等宽字体 + `.onSubmit(save)`）。

新包：`macos/build/20260709-001608-main/Quota Bar.app`（`build/latest` 已指向），已重启本机的开发态实例。

#### 更新的需求 ID

- `[0.10.0-BUG-A-023]` `[0.10.0-CLEAN-A-003]`

#### 验证方式

- `swift build`：无警告无错误（确认删除 `APIKeyTextField`/`FocusTextField` 后没有遗留引用）。
- `swift test`：190 tests in 43 suites 全部通过（没有测试引用这两个类型）。
- `./scripts/build-app.sh`：产包成功，重启本机开发态实例指向新包。
- **未做**：没能真正复现这次崩溃（WebKit 内部状态问题本来就难以稳定复现），这次修复是基于崩溃日志的堆栈分析 + 对比"哪个 WKWebView 用法跟其余稳定用法不一样"得出的最可能根因，不是靠复现验证的确定性修复。请用户重新粘贴 API Key 测试，如果崩溃再次出现，请求再给一次新的崩溃日志路径（`~/Library/Logs/DiagnosticReports/QuotaBar-*.ips`），可以进一步缩小范围。

#### 备注

- 未提交 git commit。
- 这是本次会话第一次真正基于系统级崩溃报告（`.ips` 文件）而不是代码走读/日志文本做诊断——比之前几轮的"读诊断日志文本猜测"更接近确定性证据，但 WebKit 内部崩溃本身样本量只有一次，不能 100% 排除是其他原因（比如系统本身的 WebKit 版本 bug），如果修复后仍然复现，需要进一步收窄范围（比如临时完全禁用 `WebKitSessionWarmup` 做 A/B 对照）。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
