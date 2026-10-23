# sub/main: 面向全网用户的 hardcoded 路径 / 假设审计

- ID：`0.10.0-ARCH-C-000`。
- 类型：`ARCH`。
- 状态：进行中（原文同时包含已完成与未完成项）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 面向全网用户的 hardcoded 路径 / 假设审计。
- 原稳定 ID：`0.10.0-ARCH-C-000`, `0.10.0-ARCH-C-001`, `0.10.0-DATA-B-013`, `0.10.0-DATA-B-014`, `0.10.0-QA-B-000`, `0.10.0-DATA-B-015`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户明确本应用是面向全网用户售卖的商用软件，不是只给开发者本人用；要求不管本机环境如何，按理论上可行的方案把实现做好，并检查全部实现有没有 hardcoded 路径。审计范围：全部 Provider 实现、CLI 路径探测、Keychain 查询、货币/价格假设、个人信息残留。

- [x] [0.10.0-ARCH-C-000] 新增 `CLICommandLocator` 共享工具：两级解析——先查一批常见固定安装目录（Homebrew 双架构、MacPorts、用户级 `~/.local/bin` 等），命中失败再退化到登录 shell 解析（`$SHELL -lc 'command -v <cmd>'`，source 用户真实 shell 配置，覆盖 nvm / asdf / pnpm 等任意版本管理器或自定义 PATH）；按命令名做进程内缓存（一次 App 生命周期只解析一次）；拒绝含 shell 元字符的命令名，防止拼进 `-lc` 字符串被注入 #P0 — 此前 `MiniMaxCommandProvider`/`AntigravityCLISessionProvider`/`ClaudeAuthStatusCLIProvider`/`InstallDetectorProvider` 各自维护一份不完整、互相不一致的固定路径清单，只覆盖 Homebrew 默认前缀，漏掉 nvm/asdf/pnpm/MacPorts 等真实用户会用到的安装方式
- [x] [0.10.0-ARCH-C-001] `MiniMaxCommandProvider` / `AntigravityCLISessionProvider` / `ClaudeAuthStatusCLIProvider` 改为默认走 `CLICommandLocator`（显式传入候选路径时仍走原候选列表，保持测试确定性）；`InstallDetectorProvider.findCommand` 同步改为委托 `CLICommandLocator`，移除原本因未设置 PATH 而形同虚设的裸 `which` fallback，四处路径探测收敛为单一实现 #P0
- [x] [0.10.0-DATA-B-013] 修正 `ClaudeAuthStatusCLIProvider` 的路径漂移 bug：existence 检查用的候选列表和实际执行的 `runProcess` 各自硬编码了一份独立列表，可能不一致；改为解析路径后作为参数传给 executor（与 MiniMax/Antigravity 两个 provider 已有模式一致）#P1
- [x] [0.10.0-DATA-B-014] `KeychainProvider.readToken()` 的 service-only（account=nil）查询路径改为 `kSecMatchLimitAll` 取全部匹配项后按 `kSecAttrModificationDate` 选最近修改的一条，而不是 Keychain 内部枚举顺序里任意一条——覆盖重装 / 多版本 CLI 各自写入同 service 不同条目的场景 #P1
- [x] [0.10.0-QA-B-000] 审计确认无需改动的项：`NSHomeDirectory()` 全部用法均动态取当前用户主目录（非 hardcode）；代码/测试/README/REQUIREMENTS 无残留个人用户名、邮箱、真实 org ID；`PreferredCurrency`/`ExchangeRateProvider` 的 USD/CNY 双档设计是既有文档化范围，非 bug；未发现任何架构（arm64/x86_64）分支判断 #P2
- [ ] [0.10.0-DATA-B-015] `EdgeCookieReader` 硬编码只读 `Microsoft Edge/Default` 单一 profile，多 profile（如工作/个人分账号）用户可能登录在非 Default profile 中；浏览器 Cookie 路径当前已是显式启用的最后兜底层，非默认路径，暂不提升优先级 #P2 #deferred — 呼应既有 `0.2.0-DATA-B-008` 多浏览器/多 profile 选择的 deferred 项，一并留待后续处理

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
