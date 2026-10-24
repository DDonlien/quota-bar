# 按刷新轮次倒序展示并配置保留诊断日志

- ID：`0.10.0-FEAT-A-004`。
- 类型：`QA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 诊断日志按刷新轮次分隔 + 可配置保留轮数 + 新的在最上面。
- 原稳定 ID：`0.10.0-FEAT-A-004`, `0.10.0-FEAT-A-005`, `0.10.0-FEAT-A-006`, `0.10.0-CLEAN-A-004`, `0.10.0-QA-A-002`；不改写或重编号这些既有 ID。

## 当前需求与范围

> "看下log...另外日志增加2个功能：\n* 每一次刷新之间做分割，做成：换行 / [刷新额度] - yyyy.dd.mm - hh.mm.ss / 换行\n* 然后增加一个保留次数功能，决定保存最近几次刷新的日志，不要像现在这样无限保存\n* 确保是新的在上面"

- [x] [0.10.0-FEAT-A-004] `RefreshCoordinator.runRefreshCycle()` 最前面（早于任何 provider 的 record/flush）新增调用 `ProviderCheckLog.shared.beginCycle(retainCycles:)`，往日志文件写入一条 `[刷新额度] - <时间戳>` 分隔头，让这一轮的全部日志行都跟在这条头后面。时间戳格式沿用日志本来就在用的 `yyyy.MM.dd_HH.mm.ss`（跟用户原话里的 `yyyy.dd.mm` 不完全一致，为了跟已有每行时间戳格式统一没有另起一套）#P1
- [x] [0.10.0-FEAT-A-005] `ProviderCheckLogStore` 新增 `readRecentLines()` 的分轮解析：先按 `[刷新额度]` 分隔头把文件切成一个个轮次块，再把**块的顺序**整体反转（块内每一行原有的先后顺序不变），使最新一轮排在最上面——磁盘上的物理写入顺序完全不变，只有读出来展示的顺序变了，不需要改动任何 append 逻辑 #P1
- [x] [0.10.0-FEAT-A-006] 新增可配置的保留轮数：`AdvancedPreferences.logRetentionCycles`（默认 20）+ `LogRetentionOption`（10/20/50/100 档）+ `PreferencesStore.setLogRetentionCycles`/`currentLogRetentionOption`；`DiagnosticsSettingsView` 按钮行里加一个 `Picker` 让用户直接切换。`beginCycle` 每次写分隔头之后都会调用新增的 `truncateToRecentCycles`，超出保留轮数的最旧轮次直接从磁盘删掉，替换掉原来"只按 4000 行硬截断、轮次概念上无限保存"的行为（`truncateIfNeeded` 按行数硬截断保留作为兜底，两者不冲突）#P1
- [x] [0.10.0-CLEAN-A-004] 设计取舍：一开始按用户原话字面加了"换行 + 头 + 换行"，但 `readRecentLines()`/`truncateIfNeeded()` 全部用 `content.split(separator: "\n", omittingEmptySubsequences: true)` 解析文件——这个选项会把文件里所有字面空行在读取/截断这两步全部吃掉，字面空行永远不可能真正保留下来、更不可能展示出来。改成分隔头本身不含字面空行（跟其余日志行一样只带一个尾随换行符），"换行"的视觉间隔改在 `DiagnosticsSettingsView.logView` 展示层实现：识别 `line.hasPrefix("[刷新额度]")` 的行，加大上下 padding + 加粗 + 强调色，效果等价但不依赖一个实际上不可能生效的存储层假设 #P2
- [x] [0.10.0-QA-A-002] `swift test` 全量 205 个测试通过（原 203 基线 + `ProviderCheckLogTests` 新增 2 条：`beginCycleOrdersNewestFirst` 验证跨轮次新的在最上面、轮内顺序不乱；`beginCycleTrimsOldestCyclesBeyondRetention` 验证超出保留轮数后旧轮次被截断）。重新打包、真机重启验证：真实日志文件里 `[刷新额度] - 2026.07.10_11.28.08` 分隔头正确插入在这一轮全部 provider 日志之前 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260710-112900-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260710-112900-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 看下log，又刷新不到 claude了，which肯定是可用的，感觉是某种bug；另外日志增加2个功能：
>
> * 每一次刷新之间做分割，做成：
>    * 换行
>    * [刷新额度] - yyyy.dd.mm - hh.mm.ss
>    * 换行
> * 然后增加一个保留次数功能，决定保存最近几次刷新的日志，不要像现在这样无限保存
> * 确保是新的在上面
>
>（附一段真实诊断日志，2026.07.10 11:09:13 起，展示 Claude 出现新的失败原因"Cookie 已过期，请重新登录"）

#### 完成工作

- `PreferencesStore.swift`：`AdvancedPreferences.logRetentionCycles` 字段（自定义 Codable 向后兼容）、`LogRetentionOption` 枚举、`PreferencesStore.setLogRetentionCycles`/`currentLogRetentionOption`。
- `ProviderCheckLog.swift`：`ProviderCheckLog.beginCycle(retainCycles:)`；`ProviderCheckLogStore.beginCycle(at:retainCycles:)`、`splitIntoCycles`、`truncateToRecentCycles`、重写 `readRecentLines()`（按轮次块反转，块内顺序不变）。
- `RefreshCoordinator.swift`：`runRefreshCycle()` 最前面调用 `ProviderCheckLog.shared.beginCycle(retainCycles:)`。
- `Preferences/DiagnosticsSettingsView.swift`：新增保留轮数 `Picker`；`logView` 对 `[刷新额度]` 头行做加粗/强调色/额外 padding 处理。
- `Tests/QuotaBarTests/ProviderCheckLogTests.swift`：新增 2 个测试。
- `REQUIREMENTS.md`：新增 `[0.10.0-INVESTIGATE-A-007]` `[0.10.0-BUG-A-029]` `[0.10.0-FEAT-A-004]` `[0.10.0-FEAT-A-005]` `[0.10.0-FEAT-A-006]` `[0.10.0-CLEAN-A-004]` `[0.10.0-QA-A-002]`。

新包：`macos/build/20260710-112745-main/Quota Bar.app`（`build/latest` 已指向），已重启本机开发态实例。

#### 更新的需求 ID

- `[0.10.0-INVESTIGATE-A-007]` `[0.10.0-BUG-A-029]` `[0.10.0-FEAT-A-004]` `[0.10.0-FEAT-A-005]` `[0.10.0-FEAT-A-006]` `[0.10.0-CLEAN-A-004]` `[0.10.0-QA-A-002]`

#### 验证方式

- `swift build`：无警告无错误。
- `swift test`：205 tests in 45 suites 全部通过（203 基线 + 2 新增：`beginCycleOrdersNewestFirst`、`beginCycleTrimsOldestCyclesBeyondRetention`）。
- `./scripts/build-app.sh`：产包成功，杀掉旧进程后重启本机实例。
- **真机验证**：重启后等待一次真实刷新周期，直接读 `~/Library/Application Support/QuotaBar/provider-check.log`，确认 `[刷新额度] - 2026.07.10_11.28.08` 分隔头正确出现在这一轮全部 provider 日志行之前；同时确认 Claude 这一轮的真实失败详情仍是"Cookie 已过期，请重新登录"，印证诊断结论。

#### 备注

- 未提交 git commit。
- 时间戳格式用的是日志本来就在用的 `yyyy.MM.dd_HH.mm.ss`，跟用户原话字面写的 `yyyy.dd.mm` 不完全一致——为了跟已有每行时间戳格式统一，没有另起一套格式；已在 REQUIREMENTS.md 里注明。
- "换行"需求没有按字面在文件里写入空行，而是在展示层用视觉间距实现——根因是现有读取/截断逻辑会把字面空行整体吃掉，属于发现代码实际行为后主动做的设计修正，还没跟用户当面确认这个解读，回复里需要说清楚。
- Claude "Cookie 已过期"对应的 dropdown 误判缺口（本该重新引导用户登录，却展示"暂无额度数据"）已记录为 `[0.10.0-BUG-A-029]`，这次没有动，留作后续任务。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
