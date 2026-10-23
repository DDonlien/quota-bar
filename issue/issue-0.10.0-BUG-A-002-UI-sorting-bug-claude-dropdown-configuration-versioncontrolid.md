# sub/main: 日志上线首日实测反馈——排序 bug、Claude 价格 bug、dropdown 待配置态显示规则

- ID：`0.10.0-BUG-A-002`。
- 类型：`UI`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 日志上线首日实测反馈——排序 bug、Claude 价格 bug、dropdown 待配置态显示规则。
- 原稳定 ID：`0.10.0-BUG-A-002`, `0.10.0-BUG-A-003`, `0.10.0-UI-B-002`, `0.10.0-UI-B-003`, `0.10.0-PM-A-015`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 上线新日志当天用户实测发现：Z Code 等 `.needsConfiguration` provider 在 dropdown 里同时显示原始技术性 reason 文本和 WebView 授权按钮，观感混乱；`.notSubscribed` 应该用统一"未订阅或订阅已过期"文案而不是拼原始 reason；日志页标签"获取日志"应简化为"日志"。用户直接读了一段真实日志，进一步发现两个此前没被注意到的真实 bug（这正是新增诊断日志的价值——第一次实测就抓出真问题）。

- [x] [0.10.0-BUG-A-002] `FetchPipeline.orderedStrategies` 删除"按上次成功来源缓存重排"逻辑：原实现只要任一层有缓存的 preferred source，就把所有 `supportedLayers` 覆盖满三层的 strategy 整体提到最前，与各自在数组里的声明位置无关。实测复现两处真实错误：Kimi 的 `kimi-webview`（声明最后、本该是最后一道兜底）排到 `kimi-auth`（声明第二、真正的常规 CLI OAuth 层）前面；Claude 的 `claude-auth-status-cli`（P3 兜底）因为是"上次成功来源"排到 `claude-statusline`（声明第一、零权限 P1）前面。**中间态**先改成恒定按数组声明顺序执行、完全不看缓存；用户随后指出这也不对（见 0.10.0-BUG-A-004），最终版本是"缓存优先试、失败才完整走声明顺序" #P0
- [x] [0.10.0-BUG-A-003] `ClaudeAuthStatusCLIProvider.parseStatusOutput` 补上 `ProviderPricing.localizedMonthlyPrice(kind: .claude, tier:)` 调用：此前硬编码 `monthlyPrice: nil`，导致只靠这条 CLI 兜底层拿到档位（如 "Pro"）的用户永远看不到价格，即使 `ProviderPricing` 里已经有 `(.claude, "pro") → $20` 的映射。价格是从档位名字查静态公开定价表，不是"伪造额度"，跟这里保持为空的 quotas 是两回事 #P0
- [x] [0.10.0-UI-B-002] dropdown `.needsConfiguration` 分支重写：不确定是否订阅时（拿数据失败、凭证问题等），有 `webAuthorizationURL` 的 provider 只显示清爽的「打开 WebView 授权」按钮，不再同时堆一段原始技术性 reason 文本；没有授权入口的才退回显示原始 reason #P1
- [x] [0.10.0-UI-B-003] dropdown `.notSubscribed` 分支重写：改为统一显示"未订阅或订阅已过期"（灰色，无按钮），不再拼接原始 reason；这个状态只在服务端明确告知"没有有效订阅"时触发，跟"不清楚是否订阅"的 `.needsConfiguration` 是两种不同确定性，不应该用同一种"待配置 · reason"文案 #P1
- [x] [0.10.0-PM-A-015] Preferences sidebar「获取日志」标签简化为「日志」#P2

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
