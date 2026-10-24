# 为opencode提供独立手动APIKey存储

- ID：`0.10.0-ARCH-L-004`。
- 类型：`PM`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: API Key 配置行视觉优化 + opencode 手动 Key 支持。
- 原稳定 ID：`0.10.0-BUG-A-021`, `0.10.0-PM-A-017`, `0.10.0-ARCH-L-004`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.10.0-BUG-A-021`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.10.0-ARCH-L-004`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.10.0-BUG-A-021-PM-api-key-configuration-visual-optimization-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：sub/main: API Key 配置行视觉优化 + opencode 手动 Key 支持。
- 同源任务：[精简APIKey配置行文案并修复反引号显示](issue_%E7%B2%BE%E7%AE%80APIKey%E9%85%8D%E7%BD%AE%E8%A1%8C%E6%96%87%E6%A1%88%E5%B9%B6%E4%BF%AE%E5%A4%8D%E5%8F%8D%E5%BC%95%E5%8F%B7%E6%98%BE%E7%A4%BA.md)。

## 当前需求与范围

共同范围与完整历史见[精简APIKey配置行文案并修复反引号显示](issue_%E7%B2%BE%E7%AE%80APIKey%E9%85%8D%E7%BD%AE%E8%A1%8C%E6%96%87%E6%A1%88%E5%B9%B6%E4%BF%AE%E5%A4%8D%E5%8F%8D%E5%BC%95%E5%8F%B7%E6%98%BE%E7%A4%BA.md)；本文件保留以下独立目标的原文。

- [x] [0.10.0-ARCH-L-004] opencode 加入 `ProviderKind.apiKeyCapableKinds`，新增 `OpenCodeManualKeyStore`（`OpenCodeAuthProvider.swift`，跟 `ZCodeManualKeyStore` 同款设计：Quota Bar 自己独占的 `~/Library/Application Support/QuotaBar/opencode-api-key.json`）。`OpenCodeAuthProvider.fetchSnapshot` 在 `~/.local/share/opencode/auth.json` 没有任何已配置 provider 时，回退检查这个手动 key store——存在就返回 `.available` + 空 quotas + 档位 "BYOK"（手动粘贴的 key 反推不出 auth.json 里具体是 Go/Zen 哪一档，统一按最保守的 BYOK 展示）。`OpenCodeAuthProvider` 新增 `manualKeyConfigPath` 注入参数（避免重蹈 `0.10.0-INVESTIGATE-A-004` 的覆辙，测试不碰真实文件）。`APIKeyConfigRow` 的 `reload`/`save`/`missingHint` 三处 switch 补上 `.opencode` 分支；`providerAccessModes` 里 opencode 的获取模式从 `["Config"]` 改成 `["Config", "API"]` #P1 — 新增 `OpenCodeManualKeyStoreTests`（missing-by-default/save-read 掩码/拒绝空 key）+ `OpenCodeAuthProviderTests` 补一条手动 key 回退成功的测试

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

原迁移条目的历史Comments完整保留于[同源历史](issue_%E7%B2%BE%E7%AE%80APIKey%E9%85%8D%E7%BD%AE%E8%A1%8C%E6%96%87%E6%A1%88%E5%B9%B6%E4%BF%AE%E5%A4%8D%E5%8F%8D%E5%BC%95%E5%8F%B7%E6%98%BE%E7%A4%BA.md#comments)，不从历史日志新增完成标记。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
