# sub/main: 诊断日志误报"额度获取失败"修正

- ID：`0.10.0-BUG-A-011`。
- 类型：`TOOL`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 诊断日志误报"额度获取失败"修正。
- 原稳定 ID：`0.10.0-BUG-A-011`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户贴了一段真实日志问"为什么 claude、antigravity 额度一会有一会没有，日志里都是失败"。排查确认额度数据本身没有被覆盖或丢弃——`FetchPipeline.mergeLayers` 是纯追加逻辑，已经拿到的额度不会被后续失败的来源清空；dropdown 显示的其实是刷新过程中某一刻的瞬时状态（Antigravity 的 `antigravity-cli-session` 要拉起一个临时 `agy` 会话，整轮加上过期日 resolver 耗时近 20 秒，比 Codex/Kimi 这类本地文件直读的 provider 慢一个数量级，中途截图容易看到还没刷新完的旧状态）。但排查过程中确实发现日志本身有一处误报：分层合并阶段，某个来源只是为了补档位（plan）层被重试，如果它失败，日志会连带记一条"额度获取失败"，即使额度早就被更早的来源满足——这正是用户看到"日志里都是失败"这种误导观感的来源之一。

- [x] [0.10.0-BUG-A-011] `FetchPipeline.logAttempt` 新增 `onlyLayers` 参数：分层合并阶段（`runSequential` 的补层分支）调用时传入 `missing`（本轮实际缺失、值得重试的层），不再无条件按 `strategy.supportedLayers` 全量记录；这样一个只支持补档位场景下失败的来源，不会在「额度获取」步骤留下一条虚假的失败记录（额度早已被更早的来源满足）。首次尝试（`merged == nil` 时）不受影响，此时确实在为全部所需层探测 #P1 — `ProviderFetchStrategyTests.mergeBranchFailureOnlyLogsMissingLayer`

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260707-221500-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260707-221500-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> （附截图：dropdown 显示 Codex/Claude 有真实额度，Antigravity 灰点、只有"备用：打开 WebView 授权"提示，没有任何额度条）
>
> （附一段真实诊断日志，Antigravity/Claude 两个 provider 的完整分层探测记录）
>
> 为什么我claude、antigravity额度一会有一会没有，日志里都是失败

#### 完成工作

- `macos/Sources/QuotaBar/ProviderFetchStrategy.swift`：`logAttempt` 新增可选 `onlyLayers` 参数；`runSequential` 补层分支的三处调用（成功/`QuotaFetchError`/其他 error）都传入 `missing`。
- `macos/Tests/QuotaBarTests/ProviderFetchStrategyTests.swift`：新增 `mergeBranchFailureOnlyLogsMissingLayer` 回归测试 + 两个专用 stub strategy（`QuotaOnlyStubStrategy`/`ThrowingBothLayersStubStrategy`），验证"额度已满足、后续来源只是为了补档位"场景下不会误报额度失败。
- `REQUIREMENTS.md`：v0.10.0 phase 新增 `[0.10.0-BUG-A-011]`。
- 未修改任何"额度获取本身"的逻辑——确认过这部分没有 bug，不做无必要的改动。

#### 更新的需求 ID

- `[0.10.0-BUG-A-011]`

#### 验证方式

- `swift build`：无警告无错误。
- `swift test`：181 tests in 42 suites 全部通过（含新增回归测试）。
- 未做真实端到端验证（比如真的用一台跑着 Antigravity 的机器触发一次刷新、掐着秒表在中途截图复现"灰点"状态）——时序解释在逻辑上自洽且与代码读取结果一致，但没有用真实产物重现那个具体的 20 秒窗口。

#### 备注

- 未提交 git commit。
- 给用户的说明重点：(1) 额度数据本身没有被丢弃，是刷新过程中的时序造成截图看到了旧状态；(2) Claude 的 OAuth token 已过期，需要用户自己重新 `claude login` 才能让这条路径恢复；(3) 日志的"额度获取失败"误报已经修复，以后类似情况日志会更准确地反映"这次失败其实是为了补档位，跟额度无关"。
