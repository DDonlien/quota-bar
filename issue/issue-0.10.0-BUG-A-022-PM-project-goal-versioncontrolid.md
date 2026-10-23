# sub/main: 「日志」偏好页明显卡顿

- ID：`0.10.0-BUG-A-022`。
- 类型：`PM`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 「日志」偏好页明显卡顿。
- 原稳定 ID：`0.10.0-BUG-A-022`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户反馈"日志页特别卡，肯定有问题，这么简单的功能（加上我的mac配置很高）其他页面都不卡"。

- [x] [0.10.0-BUG-A-022] 根因：`DiagnosticsSettingsView.logView` 用的是 `VStack`（不是 `LazyVStack`）包住 `ForEach`，而 `ProviderCheckLogStore.readRecentLines()` 默认最多返回 2000 行——`VStack` 会立即创建/布局全部 2000 个 `Text` 行，不管 360pt 高的可视区域实际只显示约 25 行；页面订阅了 `.providerCheckLogDidChange`（一次刷新周期里最多 7 个 provider 各 flush 一次、各触发一次通知）会调用 `reload()`，每次都要重新铺满这 2000 个视图——这正是"这么简单的功能却很卡"的原因：不是日志系统本身重，是这一屏渲染方式选错了容器。改成 `LazyVStack` 后只创建实际进入视口的行，滚动/刷新开销跟总行数基本无关 #P0

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260708-174851-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260708-174851-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 日志页特别卡，肯定有问题，这么简单的功能（加上我的mac配置很高）其他页面都不卡

#### 完成工作

- `Preferences/DiagnosticsSettingsView.swift`：`logView` 里的 `VStack` 改成 `LazyVStack`，只创建实际进入视口的行。

#### 更新的需求 ID

- `[0.10.0-BUG-A-022]`

#### 验证方式

- `swift build`：无警告无错误。
- `swift test`：190 tests in 43 suites 全部通过（纯渲染容器改动，无行为变化，未新增测试）。
- `./scripts/build-app.sh`：产包成功，重启了本机正在跑的开发态实例指向新包（`macos/build/20260708-174851-main`），方便用户直接在真实使用场景里感受是否还卡。

#### 备注

- 未提交 git commit。
- 没能用 computer-use 实机验证卡顿是否真的消失（跟上一轮同样的原因：accessory 模式 + 未签名开发态包，`request_access` 匹配不到这个 App），请用户直接在新启动的实例里打开「偏好设置 → 日志」页确认。
- 如果切换到 `LazyVStack` 后卡顿依然存在，下一步可疑点：`readRecentLines()` 默认 `limit: 2000` 仍然偏大，可以考虑降到几百行；或者进一步排查 `.textSelection(.enabled)` 在 AppKit 后端每个 `Text` 实例的开销是否需要挪到容器层级统一设置——但这两个都是"如果还卡"的备选项，本轮先验证 `LazyVStack` 这个最直接、最可能命中的根因是否已经解决问题。
