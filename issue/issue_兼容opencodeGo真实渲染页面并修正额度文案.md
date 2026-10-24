# 兼容opencodeGo真实渲染页面并修正额度文案

- ID：`0.10.0-BUG-A-026`。
- 类型：`API`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: opencode Go 页解析器真实首跑 0 结果的修复。
- 原稳定 ID：`0.10.0-BUG-A-026`, `0.10.0-BUG-A-027`；不改写或重编号这些既有 ID。

## 当前需求与范围

> `0.10.0-DATA-B-019` 刚接入就被用户实测的真实日志打脸：`opencode-webview` 能正确发现 workspace id、加载 Go 页，但连续多轮都是"Go 页面已加载但未解析出额度条"——解析器完全没工作。

- [x] [0.10.0-BUG-A-026] 根因：`parseUsageItems` 最初是照 sst/opencode 仓库里的原始 JSX 源码写的正则，但 console 是 SolidStart 应用，真实渲染出的 HTML 会被 SSR hydration 在每段动态文本前后插入 `<!--$-->`/`<!--/-->` 注释标记（如 `<span data-slot="usage-value"><!--$-->0<!--/-->%</span>`），源码里根本看不出这层——数字和 `%`/文字之间被注释隔开，旧正则 `\d+\s*%`（数字/百分号相邻）和 `[^<]*`（reset-time 取值遇到第一个 `<` 就停）两种写法都直接失配。定位方式：给 `fetchSnapshot` 加了一段临时调试代码，在解析失败时把渲染后的 HTML 落盘到 App 自己的数据目录，重新打包、等真实一轮刷新命中失败分支后，直接读这个文件拿到了用户真实登录会话下的原始 DOM——不是继续对着 GitHub 源码猜。修复：`usage-value`/`reset-time` 都先用非贪婪正则拿到 `<span>...</span>` 之间的完整内容，新增 `stripHydrationComments` 统一剥掉里面的 HTML 注释再解析纯文本。用真实落盘的 HTML 直接验证过（三条用量：滚动 0%/重置 5 小时、每周 57%/重置 3 天 22 小时、每月 28%/重置 29 天 15 小时，跟页面上 SolidJS 传过来的 `resetInSec` 原始数据吻合），验证通过后删掉了临时调试代码 #P0 — 用真实抓到的 DOM 片段替换了 `OpenCodeWorkspaceProviderTests` 里原来手写的 fixture，新增一条 `stripHydrationComments` 单测；真机重新打包验证 `opencode-webview：获取到 3 条额度窗口`，过期日也顺带对上（月度重置日代理）
- [x] [0.10.0-BUG-A-027] 用户截图指出 opencode 三条额度的重置时间栏跟其余 provider 格式不统一（显示 opencode.ai 页面原文"重置于 5 小时..."/"重置于 3 天 22..."，其余 provider 是统一的 "4h59m"/"6d15h" 紧凑格式）。根因：`OpenCodeWorkspaceProvider` 直接把页面上的 i18n 原文塞进了 `refreshDescription`，没有走 MiniMax/Z Code 等其余 provider 都在用的共享格式化函数 `QuotaResetText.description(for:relativeTo:)`。修复：改成用已经解析出的 `resetsAt` 时间调用同一个函数生成 `refreshDescription`，页面原文只留作 `parseResetSeconds` 的解析输入，不再直接展示给用户。真机验证（`snapshots.json` 落盘结果）：三条额度分别是 `5h0m`/`3d22h`/`29d15h`，跟 Codex/Claude 那一栏的格式完全一致 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260709-095234-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260709-095234-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

>（截图：dropdown，opencode · Go 三条额度的右侧时间栏显示"重置于 5 小时..."/"重置于 3 天 22..."/"重置于 29 天 1..."，跟 Codex/Claude 的 "4h59m"/"4d0h"/"6d15h" 格式不一致）
>
> 可以看到额度但是描述不对，我们应该严格统一重制时间的文本描述 参考一下其他的模型用的描述方式，应该是类似xxdxxh这样

#### 完成工作

- `OpenCodeWorkspaceProvider.swift`：`fetchSnapshot` 构造 `QuotaWindow` 时，`refreshDescription` 改用 `QuotaResetText.description(for: resetsAt, relativeTo: now)`，不再直接使用页面原文。

#### 更新的需求 ID

- `[0.10.0-BUG-A-027]`

#### 验证方式

- `swift build`：无警告无错误。
- `swift test`：195 tests in 44 suites 全部通过（`parseUsageItems`/`parseResetSeconds` 本身的解析逻辑没变，不需要改测试）。
- `./scripts/build-app.sh`：产包成功，重启本机实例，等一轮真实刷新后直接读 `~/Library/Application Support/QuotaBar/snapshots.json` 落盘结果确认：opencode 三条额度的 `refreshDescription` 分别是 `5h0m`/`3d22h`/`29d15h`，跟 Codex（`4h59m`）/Claude（`4h46m`）的格式完全一致。

#### 备注

- 未提交 git commit。
- 这是个小疏漏，本该在上一轮实现时就注意到（其他 provider 都是这个惯例），这次是用户截图对比才发现。

### 20260709-094651-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260709-094651-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> （贴了一长段真实诊断日志，`opencode-webview` 连续多轮都是"Go 页面已加载但未解析出额度条"）看新的就好：（最新几行同样的失败）

#### 完成工作

- `OpenCodeWorkspaceProvider.swift`：
  - `parseUsageItems` 改用 `NSRegularExpression` 非贪婪匹配拿到 `<span>...</span>` 之间的完整内容（而不是假设内容紧跟在开标签后）。
  - 新增 `stripHydrationComments`：统一剥掉 `<!--$-->`/`<!--/-->` 这类 SolidJS SSR hydration 注释标记，只留纯文本再解析数字/文案。
  - 验证通过后删除了临时调试代码（`debugDumpHTML` 函数 + `fetchSnapshot` 里的调用点）。
- `Tests/QuotaBarTests/OpenCodeWorkspaceProviderTests.swift`：把原来手写的（不含 hydration 注释的）fixture 换成真实抓到的 DOM 片段，新增一条 `stripHydrationComments` 单测直接覆盖这个坏味道。
- 清理了本机的调试落盘文件 `~/Library/Application Support/QuotaBar/opencode-debug-go-page.html`。
- `REQUIREMENTS.md`：新增 `[0.10.0-BUG-A-026]`。

新包：`macos/build/20260709-094651-main/Quota Bar.app`（`build/latest` 已指向），已重启本机开发态实例并**真机验证通过**：日志显示 `opencode-webview：获取到 3 条额度窗口`，过期日也正确带出（2026-08-07，跟月度重置日估算吻合）。

#### 更新的需求 ID

- `[0.10.0-BUG-A-026]`

#### 验证方式

- `swift build`：无警告无错误。
- `swift test`：195 tests in 44 suites 全部通过（新 fixture 换成真实 DOM + 新增 1 条 `stripHydrationComments` 测试）。
- 用真实落盘的完整 HTML 文件单独跑了一段临时 Swift 脚本验证解析逻辑（`percentText=0%/57%/28%`、`reset=重置于 5 小时 0 分钟` 等三条全部正确），验证通过后才删调试代码。
- `./scripts/build-app.sh`：产包成功，重启本机实例，等待一轮真实自动刷新——`provider-check.log` 确认 `opencode-webview：获取到 3 条额度窗口`、`过期日获取...成功...2026-08-07`。这是本次会话里第二次用"临时落盘真实数据 + 直接读取"的方法定位问题（第一次是 WebKit 崩溃报告），比单纯读日志文本或对着开源代码猜测更可靠。

#### 备注

- 未提交 git commit。
- 这次的教训：即使核对过官方开源仓库的源码，框架层面的编译/渲染细节（这里是 SolidStart 的 SSR hydration 注释）源码里完全看不出来，headlessDOM 解析类的代码第一次上线后最好都用"失败时临时落盘真实 HTML"这个手法走一遍真实验证，而不是假设读源码就足够——本轮和上一轮踩的是同一类坑，值得记一下。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
