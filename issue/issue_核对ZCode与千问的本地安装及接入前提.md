# 核对ZCode与千问的本地安装及接入前提

- ID：`migration-1813617627ae`。
- 类型：`SEC`。
- 状态：已确认约束 / 状态待核对（原文未单列完成状态）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.4.0 - 新 Provider 接入（zcode / 千问 / 其他）。

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

### 20260702221858-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260702221858-utcp8-gpt5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

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

### 20260702163509-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260702163509-utcp8-gpt5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

只有minimax和agy是对的，kimi和zcode获取不到，还是在问我要浏览器权限（弹窗要了密码），codex有额度但额度不对（都是100%，明明之前还是对的）

补充：ok kimi似乎只是慢

#### 完成工作

- 新测试包：`quota-bar/build/20260702-163447/QuotaBar.app`
- `quota-bar/build/latest` 已指向该测试包。
- 默认自动刷新不会主动读取浏览器 Cookie。
- Codex 不再因陈旧 `auth.json` 的过期日提前跳过真实 usage 请求，也不会默认用本地日志估算冒充真实额度。
- Z Code UI 将显示 API key/plan/endpoint 的真实失败原因，而不是只显示 App 安装状态。

#### 更新的需求 ID

- `[0.2.0-DATA-B-022]`
- `[0.2.0-DATA-B-023]`
- `[0.2.0-DATA-B-024]`
- `[0.4.0-DATA-A-005]`

#### 验证方式

- `swift test`
- `./scripts/build-app.sh`
- `plutil -p build/latest/QuotaBar.app/Contents/Info.plist`
- `codesign --verify --deep --verbose=2 build/latest/QuotaBar.app`
- `codesign -dv build/latest/QuotaBar.app`

#### 备注

- 本次未提交 git commit。
- 未清理用户本机 `Application Support/QuotaBar` 文件；代码会在读取阶段过滤不可信的 Codex 本地日志估算缓存。

### 20260702215620-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260702215620-utcp8-gpt5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

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

### 2026-10-24 07:03:43 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
