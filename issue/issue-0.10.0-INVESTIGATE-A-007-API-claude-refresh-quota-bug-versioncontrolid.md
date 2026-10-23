# sub/main: Claude 又刷新不到额度——排查是否是 bug

- ID：`0.10.0-INVESTIGATE-A-007`。
- 类型：`API`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: Claude 又刷新不到额度——排查是否是 bug。
- 原稳定 ID：`0.10.0-INVESTIGATE-A-007`, `0.10.0-BUG-A-029`；不改写或重编号这些既有 ID。

## 当前需求与范围

> "看下log，又刷新不到 claude了，which肯定是可用的，感觉是某种bug"（附一段真实诊断日志，2026.07.10 起 Claude 的额度获取开始出现新的失败原因："Cookie 已过期，请重新登录"）。

- [x] [0.10.0-INVESTIGATE-A-007] 读真实诊断日志核实：`claude-webview` 层这次的失败详情从此前的"获取到 N 条额度窗口｜成功"变成了"来源 claude-webview：Cookie 已过期，请重新登录｜失败"——这是 `BrowserCookieProvider.performRequest` 收到 Anthropic 服务端返回的 `401/403` 后产生的信号，代表 App 本地存的 Cookie 对象确实还在、但服务端已经不认这个会话了（真实的服务端 session 过期，不是"没登录"，也不是本地判断逻辑的 bug）。同一轮里 CLI 层（`claude-auth-status-cli`）拿到了档位/价格但拿不到额度窗口、oauth 层被限流——三层凑不出完整数据，所以 dropdown 目前展示的是"暂无额度数据"这个终态文案。修复方式是用户手动重新走一次 WebView 授权（重新登录 claude.ai），不是代码改动 #P1
- [x] [0.10.0-BUG-A-029] 顺带定位到一个真实 UX 缺口：`firstPendingAuthRemediationTier()` 判断 WebView tier"已完成"只看本地是否存有该 provider dashboard 域的 Cookie 对象（`appSessionHasCookies`），不看服务端这次请求实际是否还认这个 Cookie；所以"Cookie 对象还在、但服务端已判定过期"这种情况下，dropdown 会误判 WebView tier 已完成、直接展示终态"暂无额度数据"，而不是重新引导用户去重新授权——这本该是最贴切的修复提示。这次没有动这处：要把"上一次请求具体是哪种失败"这个信号一路传回 `ProviderSnapshot` 目前没有现成字段，属于有真实架构成本的改动，先记录、留作后续单独任务，不在这次顺手改掉 #P2

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
