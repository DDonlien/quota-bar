# 用户原始 prompt

> 这个应用不是只给我用的，而是要面向全网用户，作为一个售卖的应用。
>
> 所以你不要管我本地有没有可用的环境或资源，你按照理论上可行的方案把它们做好就行。请全量检查一下所有的实现。顺便也检查一下，有没有路径之类的是 hardcoded 的

# 启动运行时的分支和版本

- 分支：`main`
- 版本：`1bba4e3` + 此前四次会话的未提交改动

# 任务开始时间

2026-07-06 约 20:00 +0800

# 任务结束时间

2026-07-06 20:59 +0800

# 任务结束时是否执行了提交

未提交（累计五次会话改动都在工作区，等用户 review）。

# 已阅读上下文

- `grep` 全仓库 `/opt/homebrew`、`/usr/local/bin`、`NSHomeDirectory()` 等路径模式，逐个分类判断是否为「只在我的机器上成立」的假设。
- 逐个通读 `MiniMaxCommandProvider`、`AntigravityCLISessionProvider`、`ClaudeAuthStatusCLIProvider`、`InstallDetectorProvider` 的路径探测逻辑，发现三处独立、互相不一致的固定路径清单。
- 通读 `KeychainProvider.readToken()`，评估 service-only 查询在多条历史条目场景下的正确性。
- 检查 `ProviderPricing`/`PreferredCurrency`/`ExchangeRateProvider` 的货币假设范围。
- 检查 `EdgeCookieReader` 的 profile 假设。
- grep 全部 source/test 文件搜索本机个人信息残留（用户名、邮箱、org ID）。
- grep 架构相关判断（arm64/x86_64/uname）。

# 对话与行动记录

用户明确了产品定位：面向全网用户售卖，不是给自己用的工具。这改变了审计标准——不能用「我本机测试通过」当作完成标准，要按「任意用户的任意合理环境配置」去验证。

## 发现的核心问题：三份互相不一致的 hardcoded CLI 路径清单

`MiniMaxCommandProvider`（mmx）、`AntigravityCLISessionProvider`（agy）、`ClaudeAuthStatusCLIProvider`（claude）都各自维护了一份写死的候选路径列表（`/opt/homebrew/bin/xxx`、`/usr/local/bin/xxx`、`~/.local/bin/xxx`），只覆盖 Homebrew 默认前缀和最常见的用户级目录。真实用户群体里大量存在的安装方式完全没覆盖：nvm/asdf 管理的 node 全局包、pnpm 的全局 bin 目录、MacPorts、任何自定义 PATH 追加——这些用户装了 CLI、终端里能跑通，但我们的 GUI app（继承 launchd 精简 PATH）完全找不到，会误判为「未安装」。

顺带发现一个真实 bug：`ClaudeAuthStatusCLIProvider` 的「存在性检查」用一份候选列表，实际执行 `runProcess` 又独立硬编码了另一份列表——两份列表当时内容相同所以没暴露，但设计上是不一致的、后续维护会漂移。

## 修复：引入统一的 `CLICommandLocator`

两级解析：先查一批常见固定目录（快、覆盖多数默认安装），找不到再退化到「登录 shell 解析」——`$SHELL -lc 'command -v <cmd>'`，这样会 source 用户真实的 shell 配置文件，只要用户在自己终端里能跑通这个命令，这里就能解析到，不用穷举 nvm/asdf/pnpm 各自的路径规律。按命令名做进程内缓存，避免每 5 分钟自动刷新都重新触发一次较慢的 shell 解析。加了命令名字符白名单，防止被拼进 `-lc` 字符串的极端情况下出现命令注入。

三个 CLI provider 改为默认走这个共享实现（测试仍可显式传候选列表保证确定性，不受影响）；`InstallDetectorProvider.findCommand` 也切过来统一实现，顺带删掉了原来因为没设置 PATH 而形同虚设的裸 `which` fallback。

`InstallDetectorProvider.detectSources`/`detectPreferredSource`/`findCommand` 因此改为 `async`，同步更新了 `RefreshCoordinator.swift` 里唯一的调用点。

## 修复：Keychain 多条历史条目场景

`KeychainProvider` 的 service-only 查询（account 未知时）原来用 `kSecMatchLimitOne` 拿"任意一条"匹配——如果用户重装过 Claude Code 或装过多个版本，同一 service 下可能有多条历史条目，拿到的不一定是当前有效的那条。改为 `kSecMatchLimitAll` 取全部匹配后按 `kSecAttrModificationDate` 选最近修改的一条。

## 审计确认「不是 bug」的几项

- 全部 `NSHomeDirectory()` 用法都是动态取当前用户主目录，天然适配任意用户，不是 hardcode。
- 货币逻辑（`PreferredCurrency` 只支持 USD/CNY 两档）是既有文档化的范围（README 已写明简体中文/中国区默认转人民币，其他地区默认 USD），不是遗漏。
- 没有任何架构（arm64/x86_64）判断分支——Homebrew 双前缀路径已经被新 locator 同时覆盖，不需要按架构分流。
- 全部源码、测试、README、REQUIREMENTS 里没有残留本机用户名、邮箱、真实 org ID。

## 记录但本轮未修的一项

`EdgeCookieReader` 只读 Edge 浏览器的 `Default` profile，多 profile 用户（工作/个人分账号）如果登录在非 Default profile 会读不到。这个路径本身已经是显式启用的最后兜底层（不在默认零配置流程里），且 REQUIREMENTS 里已有对应的 `0.2.0-DATA-B-008`（多浏览器/多 profile 选择）deferred 项——不是新发现的遗漏，只是把它和这次审计关联起来，留待后续一起处理，没有临时拼凑一个不完整的修复。

# 完成工作

- `CLICommandLocator.swift`：新文件，共享 CLI 路径解析（常见目录 + 登录 shell 兜底 + 缓存 + 注入防护）。
- `MiniMaxCommandProvider.swift` / `AntigravityCLISessionProvider.swift` / `ClaudeAuthStatusCLIProvider.swift`：改用共享 locator，保留测试用的显式候选列表通道；修复 Claude provider 的路径漂移 bug。
- `InstallDetectorProvider.swift`：`findCommand` 委托给 locator，`detectSources`/`detectPreferredSource` 改为 async。
- `RefreshCoordinator.swift`：同步更新调用点加 `await`。
- `KeychainProvider.swift`：service-only 查询改为取最近修改的条目。
- 新包：`macos/build/20260706-205827-main/Quota Bar.app`（`build/latest` 已指向）。

# 更新的需求 ID

- 新增并完成：`0.10.0-ARCH-C-000`（CLICommandLocator）、`0.10.0-ARCH-C-001`（三 provider + InstallDetectorProvider 统一改用）、`0.10.0-DATA-B-013`（Claude CLI 路径漂移修复）、`0.10.0-DATA-B-014`（Keychain 最近条目）、`0.10.0-QA-B-000`（审计确认无需改动项）
- 新增未完成：`0.10.0-DATA-B-015`（EdgeCookieReader 多 profile，标记 deferred，关联已有 `0.2.0-DATA-B-008`）

# 更新的 README 或 DESIGN 章节

无（本轮是实现层面的健壮性修复，未改变 provider 获取方案或矩阵结论，不需要改 README）。

# 验证方式

- `make test`：160 tests in 37 suites 全部通过。新增 `CLICommandLocatorTests`（系统二进制查找、未知命令返回 nil、缓存一致性、shell 元字符注入防护、缓存重置）。
- `make app`：成功产包。
- 全仓库 grep 核查：无残留个人信息、无架构分支判断、`NSHomeDirectory()` 全部动态取值。

# 备注

- 未提交 git commit。
- `CLICommandLocator` 的登录 shell 解析路径未在真实 nvm/asdf/pnpm 环境下端到端验证过（本机没有这些环境）——设计上是标准做法（VSCode 等主流 app 处理"GUI app PATH 不全"问题时用的同一套思路），但真实生效情况建议后续在装了这些工具链的机器上验证一次。
- KeychainProvider 的"取最近条目"逻辑没有写自动化测试——写入/读取真实 Keychain 条目的测试容易 flaky 且会污染开发者本机 Keychain，与现有代码库里"KeychainProvider 完全没有单元测试"的既有边界一致，选择不引入这类测试。
