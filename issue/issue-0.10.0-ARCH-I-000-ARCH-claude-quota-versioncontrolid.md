# sub/main: 日志格式二次调整 + Claude 额度条标题统一 + 更新功能现状确认

- ID：`0.10.0-ARCH-I-000`。
- 类型：`ARCH`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 日志格式二次调整 + Claude 额度条标题统一 + 更新功能现状确认。
- 原稳定 ID：`0.10.0-ARCH-I-000`, `0.10.0-BUG-A-008`, `0.10.0-DOC-A-004`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户反馈日志格式"冒号逗号混排"不好读，要求改成管道分隔的层级/方案/结果/内容；截图指出 Claude 的额度条显示"Session"/"Weekly"前缀，跟 Codex 只显示周期标签不一致；询问 Preferences 更新功能现状（要求走 v0.11.0 记录的 ad-hoc 签名 workaround，不是 v0.12.0 的 Developer ID 方案）。

- [x] [0.10.0-ARCH-I-000] `ProviderCheckLog` 行格式从 `<Provider>: <Step>, <Method>: <Result>`（冒号逗号混排，成败判断混在自由文本里）改成 `<Provider> | <Step> | <Method> | <成功/失败/跳过> | <详细内容>`：新增独立的 `Outcome` 枚举（`.success`/`.failure`/`.skipped`），跟自由文本的 `detail` 彻底分开，一眼就能扫到成败，不用从长句子里找"成功"/"失败"字样。改动覆盖 `InstallDetectorProvider`/`ProviderFetchStrategy`/`SubscriptionExpirySources` 三处全部约 22 个调用点；`ProviderCheckLogTests` 同步更新 + 新增 `.skipped` 状态的落盘测试 #P0
- [x] [0.10.0-BUG-A-008] Claude 额度条标题统一：`ClaudeUsageWindowParser`（`DashboardEndpoints.swift`）和 `ClaudeStatusLineUsageProvider` 的 `five_hour`/`seven_day` 窗口 title 从 `"Session"`/`"Weekly"` 改成空字符串，跟 Codex 的 `primary`/`secondary` 窗口一致——这两个窗口只是同一份额度的两个时间维度，不是 Kimi Work/Code、MiniMax General/Video 那种需要区分的不同 scope，不应该显示前缀名称；legacy 的 `seven_day_sonnet`/`seven_day_opus` 分支保留各自的区分标题（它们是真正不同的 scope：不同模型的独立额度池）。相关测试改用 `periodSeconds` 而不是 `title` 区分窗口 #P1
- [x] [0.10.0-DOC-A-004] 确认 Preferences 更新功能（`UpdateChecker.swift` + `AboutSettingsView.swift` + `install-update.sh` + `release.yml`）已在 v0.11.0 完整落地并接入真实 `DDonlien/quota-bar` 仓库，release workflow 也确认真实产出 `.dmg` 资产；本轮未发现需要新增的缺口，仅做现状确认，不重复建设 #P2

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
