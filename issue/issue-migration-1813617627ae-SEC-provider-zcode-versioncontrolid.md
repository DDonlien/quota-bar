# Phase - v0.4.0 - 新 Provider 接入（zcode / 千问 / 其他）

- ID：`migration-1813617627ae`。
- 类型：`SEC`。
- 状态：已确认约束 / 状态待核对（原文未单列完成状态）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`；标题路径：任务清单 / Phase - v0.4.0 - 新 Provider 接入（zcode / 千问 / 其他）。

## 当前需求与范围

> 用户电脑实测已装：
> - `/Applications/ZCode.app`（bundle id `dev.zcode.app`、version 3.1.2，智谱 BigModel Z Code 桌面 IDE），运行时主进程 + `zcode-cli` 进程在跑；
> - 千问桌面 App 未在 `/Applications`、`~/Applications`、`~/Library/Application Support` 找到，等用户确认实际安装位置。
>
> zcode 是 opencode 的 fork/skin（用 `https://opencode.ai/config.json` schema），走 anthropic 兼容 API；
> 凭证、配置、套餐额度本地缓存统一在 `~/.zcode/v2/` 目录下。

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260702151504-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260702151504-utcp8-gpt5.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 对比一下我给你的三个 reference，我们现在已经吸取他们的最佳实践了吗？
> 另外不需要所谓的其他 provider，如果你要做其他 provider，就明确具体哪个 provider
> 我们现在还应该增加的应该是 GLM

#### 完成工作

- `REQUIREMENTS.md` 范围修正：移除 v0.9.0 能力矩阵里的泛化 provider 列表，明确 GLM/Z Code 进入矩阵范围。

#### 更新的需求 ID

- `0.9.0-ARCH-B-005`

#### 验证方式

- 文档变更，无构建验证。

#### 备注

- 未修改 Swift 实现代码。

### 20260702151121-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260702151121-utcp8-gpt5.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 你这里链路写的有些混乱，我觉得应该分成3层：
> 1. provider获取
> 1.1. app bundle
> 1.2. 配置文件
> 1.3. cli
> 1.4. api
> 2. 额度获取
> 2.1. 配置文件
> 2.2. cli指令
> 2.3. api指令
> 2.4. rpc是什么？
> 2.x. 其他还有什么手段？通过 CLI 或者 API 直接发起自然语言问询，尝试让 AI 自己返回这个结果，有可能吗？浏览器在这里要怎么处理？
> 3. 过期日获取
> 3.1. 2.1. 配置文件
> 3.2. cli指令
> 3.3. api指令
> 3.x. 其他还有什么手段？通过 CLI 或者 API 直接发起自然语言问询，尝试让 AI 自己返回这个结果，有可能吗？浏览器在这里要怎么处理？
>
> 每次刷新时，执行逻辑应该是：
> 1. 先检查一遍所有的 provider；对于已有的 provider，应该用最近一次检查到它的手段进行复查，确保它还在；如果还在，跳过其余检查步骤；等所有已知的 provider 检查完了，按顺序把第一步跑一遍，检查新的，或者以已知手段没检查到的、老的 provider
> 2. 检查所有 provider 的额度，优先按照每个 provider 上次检查成功的额度检查手法检查。如果检查到了就完成；如果没检查到，按顺序全部都重新跑一遍额度获取手段
> 3. 检查过期日和额度一样，只不过具体检查的指令和位置可能不同，但逻辑也是一样的。先按上次成功的手法检查老的，检查不到就全部都跑一遍。
>
> 你现在应该先完善我列出的第一大段里所有的手法，然后结合第二大段，告诉我这个逻辑思路是否正确
>
> 然后你还应该列出3张表，每一张的纵轴分别是：
> 1. 第一步的可行方案
> 2. 第二步的可行方案
> 3. 第三步的可行方案
> 横轴是不同的 provider，然后单元格内容应该是针对这个 provider 的特殊处理或者检查方式。比如 Web 的话应该是对应的域名，CUI 的话应该是对应的指令

#### 完成工作

- 更新 `REQUIREMENTS.md`：
  - `0.9.0-ARCH-B-000` 至 `0.9.0-ARCH-B-008` 改为三层获取链路、来源索引、刷新逻辑、CLI/RPC、Browser、订阅状态归一化相关要求。
- 准备在回复中交付三层手法、刷新逻辑判断和三张 provider 矩阵。

#### 更新的需求 ID

- `0.9.0-ARCH-B-000`
- `0.9.0-ARCH-B-001`
- `0.9.0-ARCH-B-002`
- `0.9.0-ARCH-B-003`
- `0.9.0-ARCH-B-004`
- `0.9.0-ARCH-B-005`
- `0.9.0-ARCH-B-006`
- `0.9.0-ARCH-B-007`
- `0.9.0-ARCH-B-008`

#### 验证方式

- 文档变更，无构建验证。
- 使用 `rg` / `sed` 检查现有 provider 发现、endpoint、Codex/Kimi/MiniMax 等实现细节。

#### 备注

- 未修改 Swift 实现代码。
- 工作区仍有未跟踪 agent-log 文件，未执行 git add/commit。

### 20260702221858-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260702221858-utcp8-gpt5.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

zcode也没获取到啊

补充：你不行就把web view做了，这样一次webview授权后面自己可以一直隐式获取

#### 完成工作

- Kimi：
  - 修复 `kimiCodeUsedRatio` 未用于 Code 5h/周额度的问题。
  - 防止 CLI Code-only 来源遮蔽 Desktop token 完整来源。
- Z Code：
  - 明确识别服务端空 plans/balances 为“未返回可渲染额度”，不把 plan-cache 的 available 当额度成功。
  - 保留本轮实测结论：当前启用 Start plan API key 可请求成功，但服务端返回空余额。
- 架构：
  - 修复 source index 排序规则，完整来源优先于部分来源。
  - 登记 App 内 WebView 授权容器为后续 P1 需求。
- 打包：
  - 新包：`quota-bar/build/20260702-221845/QuotaBar.app`
  - latest：`quota-bar/build/latest/QuotaBar.app`

#### 更新的需求 ID

- 新增并完成：`0.2.0-DATA-B-027`
- 新增并完成：`0.4.0-DATA-A-008`
- 新增并完成：`0.9.0-DATA-A-004`
- 新增未完成：`0.9.0-DATA-A-005`

#### 验证方式

- `git pull`：通过，已是最新。
- 真实接口探测：
  - Kimi membership API：HTTP 200，确认字段结构。
  - Z Code billing API：HTTP 200 但空 `plans` / `balances`，确认当前不是本地凭证缺失。
- `cd quota-bar && env CLANG_MODULE_CACHE_PATH=.build/clang-module-cache SWIFT_MODULE_CACHE_PATH=.build/swift-module-cache swift test --disable-sandbox`
  - 62 tests passed。
- `cd quota-bar && ./scripts/build-app.sh`
  - 成功生成并签名 `build/20260702-221845/QuotaBar.app`。

#### 备注

- Antigravity 本轮检查中未发现运行中的 Antigravity/language_server 进程；若 IDE 未运行或未激活 workspace，当前显示“待配置”符合“不用缓存假装可用”的需求。
- Z Code 当前服务端对 Start plan 返回空余额；WebView 可以作为后续授权容器做，但需要独立实现 UI 和持久 WKWebsiteDataStore，不建议在本轮热修中塞入半成品。

### 20260702215620-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260702215620-utcp8-gpt5.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

```text
还是没有好：kimi有额度但没有work额度，没有正确的订阅名，但有正确的订阅费用；zcode没有好；看看附件的沟通有没有参考价值
```

附件：

- `/Users/taobe/Downloads/ChatGPT-macOS App 无密码授权.md`
- 截图显示：Kimi 只有 Code 5h / Code 周额度，显示 `Kimi Trial（已购）`；Z Code 显示 `BigModel Start` 但无 quota bar。

#### 完成工作

- `KimiDesktopTokenProvider` 改为复合请求：
  - 必需：`GetSubscriptionStat` 获取 Work + Code + 到期日；
  - 可选：`GetSubscription` 获取 Andante/Moderato 等订阅名和价格；
  - 请求增加 `Cookie: kimi-auth=<token>`、`x-msh-platform`、`connect-protocol-version` 等 Web 端 header，降低 Desktop token 被服务端区别对待的概率；
  - 本地 `currentMembershipLevel=15` 只作为最后兜底映射到 Andante。
- `KimiSubscriptionStatParser` 增强 Work 解析：
  - 支持 `amountUsedRatio`；
  - 支持 `used/total`；
  - 支持 `remaining/total`。
- `ZCodeAuthProvider` 改为优先解析 `zcode-plan/billing/balance`：
  - 从 `~/.zcode/v2/config.json` 的 `https://zcode.z.ai/api/v1/zcode-plan/anthropic` 推导到 `billing/balance`；
  - 解析 GLM-5.2 / GLM-5-Turbo 的 daily token quota；
  - 保留旧 `api/monitor/usage/quota/limit` parser 作为兼容 fallback。
- `ProviderPricing.normalizedTier` 增加 `zcode-v3-start-plan-*` / `zcode-v3-coding-plan-*` 的可读名称映射。
- Kimi 安装探测加入 Desktop token-store 路径。
- 更新 `README.md` 和 `REQUIREMENTS.md`。
- 打包新版 app：`quota-bar/build/20260702-215511/QuotaBar.app`，`build/latest` 已指向该版本。

#### 更新的需求 ID

- `0.2.0-DATA-B-026`
- `0.4.0-DATA-A-007`

#### 验证方式

- `cd quota-bar && env CLANG_MODULE_CACHE_PATH=.build/clang-module-cache SWIFT_MODULE_CACHE_PATH=.build/swift-module-cache swift test --disable-sandbox`
  - 结果：60 tests in 15 suites passed。
- `cd quota-bar && ./scripts/build-app.sh`
  - 结果：生成 `build/20260702-215511/QuotaBar.app`。
- `cd quota-bar && codesign --verify --deep --verbose=2 build/latest/QuotaBar.app`
  - 结果：valid on disk，satisfies its Designated Requirement。

#### 备注

- 本次未提交。
- 本次没有打印或保存任何 token / API key 原文。
- Z Code 的 live API 请求未在 agent 环境中直接发出；依据来自本机 Z Code 日志中的成功请求和响应结构，并用单元测试覆盖 parser。
