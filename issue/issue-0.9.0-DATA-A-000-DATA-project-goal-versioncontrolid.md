# DATA-A：来源索引缓存

- ID：`0.9.0-DATA-A-000`。
- 类型：`DATA`。
- 状态：进行中（原文同时包含已完成与未完成项）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`；标题路径：任务清单 / Phase - v0.9.0 - 持久化、来源索引与启动兜底 / DATA-A：来源索引缓存。
- 原稳定 ID：`0.9.0-DATA-A-000`, `0.9.0-DATA-A-001`, `0.9.0-DATA-A-002`, `0.9.0-DATA-A-003`, `0.9.0-DATA-A-004`, `0.9.0-DATA-A-005`, `0.9.0-DATA-A-006`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.9.0-DATA-A-000] 新增 provider 来源索引缓存，记录每个 Provider 上次成功的数据来源优先值（如 auth file / browser profile / CLI config / local RPC / Keychain 探测），用于下一次启动、更新、重装或刷新时优先尝试 #P1
- [x] [0.9.0-DATA-A-001] 来源索引只保存非敏感元信息：providerKind、sourceKind、sourceId、成功时间、失败次数、最后错误摘要、相关本地路径或浏览器 profile 标识；不保存凭证内容 #P1
- [x] [0.9.0-DATA-A-002] 当优先来源失败时，Provider pipeline 必须回到完整 fallback 规则继续抓取；若其他来源成功，更新来源索引；若全部失败，如实返回失败 / 待配置状态 #P1
- [x] [0.9.0-DATA-A-003] 浏览器 Cookie 和 CLI 配置与凭证使用同一来源索引机制：保存“上次哪个浏览器 / profile / CLI 配置路径有效”，不复制 Cookie 或配置文件内容 #P1
- [x] [0.9.0-DATA-A-004] 来源索引优先级必须尊重层覆盖范围：在一次刷新同时需要额度/档位/过期日时，完整来源优先于只覆盖单层的来源；例如 Kimi Desktop 不应被 Kimi CLI 的 Code-only 成功缓存遮蔽，Z Code auth 不应被 plan-cache 遮蔽 #P1
- [ ] [0.9.0-DATA-A-005] App 内 WebView 授权容器：用户显式点击登录/修复后打开 provider 专属 WebView，复用 WKWebsiteDataStore 持久 session；后续刷新可隐式读取该 WebView session 发 dashboard 请求，避免反复触发系统 Cookie/Keychain 弹窗 #P1
- [ ] [0.9.0-DATA-A-006] 下拉里支持 WebView 授权的 provider 在未获取到数据 / 待配置时，按 provider 链路顺序显示最后优先级的可点击文本「打开 WebView 授权」或「备用：打开 WebView 授权」；点击后打开 provider 专属登录页并持久化 WebView session，后续 Web dashboard strategy 可复用该 session #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
