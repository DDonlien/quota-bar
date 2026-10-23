# ARCH-A：持久化模型与目录约束

- ID：`0.9.0-ARCH-A-000`。
- 类型：`ARCH`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`；标题路径：任务清单 / Phase - v0.9.0 - 持久化、来源索引与启动兜底 / ARCH-A：持久化模型与目录约束。
- 原稳定 ID：`0.9.0-ARCH-A-000`, `0.9.0-ARCH-A-001`, `0.9.0-ARCH-A-002`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.9.0-ARCH-A-000] 定义 Quota Bar 自有持久化目录：`~/Library/Application Support/QuotaBar/`；偏好、来源索引、last-known-good 快照都放在该目录下，不新增 `~/.quota-bar` 作为主路径 #P1
- [x] [0.9.0-ARCH-A-001] 设计持久化 schema version 与向后兼容策略；所有持久化文件必须带 `schemaVersion`，读取失败时安全丢弃并回到实时抓取，不阻塞 app 启动 #P1
- [x] [0.9.0-ARCH-A-002] 明确安全边界：持久化文件不得保存 token、cookie、API key、refresh token 或浏览器 Cookie 明文；敏感凭证仍只读取原始服务配置、浏览器 Cookie 或 macOS Keychain #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
