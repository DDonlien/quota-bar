# 删除无消费方的偏好字段与访问器

- ID：`0.10.0-CLEAN-A-001`。
- 类型：`ARCH`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 偏好设置摆设字段全面审计 + WebView 授权修复 + 移除浏览器 Cookie 文件读取。
- 原稳定 ID：`0.10.0-BUG-A-014`, `0.10.0-BUG-A-015`, `0.10.0-ARCH-K-000`, `0.10.0-ARCH-K-001`, `0.10.0-CLEAN-A-001`, `0.10.0-BUG-A-016`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.10.0-BUG-A-014`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.10.0-CLEAN-A-001`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.10.0-BUG-A-014-ARCH-webview-fixes-cookie-files-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：sub/main: 偏好设置摆设字段全面审计 + WebView 授权修复 + 移除浏览器 Cookie 文件读取。
- 同源任务：[补齐WebView真实授权能力与SSO弹窗处理](issue_%E8%A1%A5%E9%BD%90WebView%E7%9C%9F%E5%AE%9E%E6%8E%88%E6%9D%83%E8%83%BD%E5%8A%9B%E4%B8%8ESSO%E5%BC%B9%E7%AA%97%E5%A4%84%E7%90%86.md)、[移除浏览器Cookie文件读取路径及相关偏好](issue_%E7%A7%BB%E9%99%A4%E6%B5%8F%E8%A7%88%E5%99%A8Cookie%E6%96%87%E4%BB%B6%E8%AF%BB%E5%8F%96%E8%B7%AF%E5%BE%84%E5%8F%8A%E7%9B%B8%E5%85%B3%E5%81%8F%E5%A5%BD.md)、[接通Provider刷新超时偏好](issue_%E6%8E%A5%E9%80%9AProvider%E5%88%B7%E6%96%B0%E8%B6%85%E6%97%B6%E5%81%8F%E5%A5%BD.md)。

## 当前需求与范围

共同范围与完整历史见[补齐WebView真实授权能力与SSO弹窗处理](issue_%E8%A1%A5%E9%BD%90WebView%E7%9C%9F%E5%AE%9E%E6%8E%88%E6%9D%83%E8%83%BD%E5%8A%9B%E4%B8%8ESSO%E5%BC%B9%E7%AA%97%E5%A4%84%E7%90%86.md)；本文件保留以下独立目标的原文。

- [x] [0.10.0-CLEAN-A-001] 删除纯死代码：`ProviderOverride.isForcedVisible`（无 UI、无消费方）、`incidentMonitoringEnabled`（同上）、`AdvancedPreferences.currencyCode`/`showResetDates`（同上）及各自的 getter/setter #P2

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

原迁移条目的历史Comments完整保留于[同源历史](issue_%E8%A1%A5%E9%BD%90WebView%E7%9C%9F%E5%AE%9E%E6%8E%88%E6%9D%83%E8%83%BD%E5%8A%9B%E4%B8%8ESSO%E5%BC%B9%E7%AA%97%E5%A4%84%E7%90%86.md#comments)，不从历史日志新增完成标记。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
