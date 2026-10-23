# sub/main: check() 门禁覆盖手动路径

- ID：`0.15.3-BUG-A-000`。
- 类型：`DATA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.15.3 - 检查更新门禁补全（手动点击此前会绕过）+ 测试隔离 + flaky 修复 / sub/main: check() 门禁覆盖手动路径。
- 原稳定 ID：`0.15.3-BUG-A-000`, `0.15.3-BUG-A-001`, `0.15.3-DATA-A-000`, `0.15.3-QA-A-000`, `0.15.3-QA-A-001`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.15.3-BUG-A-000] `UpdateChecker.check()` 原本门禁条件是 `!userInitiated && !licenseAllowsAutomaticUpdates`——只挡自动/后台触发，手动点击（`userInitiated: true`）完全绕过。改成门禁对两条路径统一生效：`!licenseAllowsAutomaticUpdates` 就挡，不再看是谁触发的
- [x] [0.15.3-BUG-A-001] 挡住后的反馈按触发方式分层：手动点击要给可见反馈（`state = .error("检查更新需要激活…")`），不能让用户点了按钮却像什么都没发生；自动/后台触发保持静默（不改 `state`），不必每次打开关于页或每轮后台轮询都跳一条错误
- [x] [0.15.3-DATA-A-000] `licenseStateProvider` 从"构造后可改的公开 var（默认闭包读 `LicenseManager.shared`）"改成正规的 init 参数注入点，对齐 `preferences`/`checkLogStore` 已有的 DI 模式
- [x] [0.15.3-QA-A-000] 新增 `manualCheckBlockedWhenUnlicensed` / `automaticCheckSkippedWhenUnlicensedStaysQuiet` 两个测试，断言门禁生效时**不发起真实请求**且两种触发方式的可见状态符合各自预期。修复过程中顺带发现：收紧门禁前，`UpdateCheckerFallbackTests.swift` 里全部 4 个用 `userInitiated: true` 构造 `UpdateChecker` 的既有测试都没有注入 `licenseStateProvider`，靠默认值悄悄读了 `LicenseManager.shared.state`——也就是跑测试这台机器当下真实的试用状态；这次改动让门禁真正对 `userInitiated: true` 生效后，这 4 个测试因为开发机试用已过期而集体变红，暴露了这个此前一直存在但被"手动检查不受门禁约束"这个旧设计意外掩盖的测试隔离漏洞。已给全部 4 处补上确定的 `.trial(daysRemaining: 7)` 注入
- [x] [0.15.3-QA-A-001] 顺带修一个跑全套件时撞见的无关 flaky：`ResetCountdownTests.ticksBySecondUnderAnHour` 里 `reset`/`now` 各自独立调用 `Date()`，两次调用间的真实间隔（哪怕零点几毫秒）会让 `Int(seconds)` 截断出 89 而不是预期的 90，慢机器/高负载下偶发。改成从同一个 `now` 派生 `reset`，时间差恒为 90 秒

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
