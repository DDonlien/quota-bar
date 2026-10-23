# update/main: 后台下载 + 提示重启安装

- ID：`0.11.0-FE-A-008`。
- 类型：`FE`。
- 状态：进行中（原文同时包含已完成与未完成项）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.11.0 - 真实自动更新（ad-hoc 预开发版）+ semver 发版 / update/main: 后台下载 + 提示重启安装。
- 原稳定 ID：`0.11.0-FE-A-008`, `0.11.0-FE-A-009`, `0.11.0-FE-A-010`, `0.11.0-FE-A-011`, `0.11.0-FE-A-012`, `0.11.0-FE-A-008-test`, `0.11.0-FE-A-010-test`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 选 B 方案的下半段：检查到更新 → 提示 → 后台下载 → 签名 verify → 调 helper 替换 → 重启 app。
> 状态机在 v0.11.0-FE-A-002 基础上扩展。

- [x] [0.11.0-FE-A-008] 检测到更新后展示 banner：「v0.11.0 已发布」+ 变更摘要（`body` 字段截前 500 字，去掉 markdown 强调符号）+ 三个按钮：稍后提醒 / 查看 GitHub Release / 立即下载并安装 #P1
- [x] [0.11.0-FE-A-009] 选「立即下载并安装」→ 后台下载 dmg 到 `~/Library/Application Support/QuotaBar/updates/QuotaBar-<ver>.dmg`；进度通过 `URLSessionTaskDelegate.urlSession(_:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)` 反馈百分比 #P1
- [x] [0.11.0-FE-A-010] 下载完成 + 签名 verify 通过 → 弹「更新已下载，立即重启并安装？」对话框；用户确认后调 `Process.run` 启动 dmg 内 `tools/install-update.sh`；helper 退出后用同一 `Process.run` 启动 `/Applications/Quota Bar.app` 重新拉起主程序 #P1
- [x] [0.11.0-FE-A-011] 状态机扩展：`idle` / `checking` / `updateAvailable` / `downloading(progress: Double)` / `verifying` / `downloaded` / `installing` / `upToDate` / `error(message)`；每个状态都有对应 UI 展示 #P1
- [x] [0.11.0-FE-A-012] 同一版本 24h 内「稍后提醒」不重复提示；用户可在「关于」页点「重置忽略」清空 ignoredVersions #P1 — 实现偏差：「稍后提醒」= 永久忽略该版本 tag（自动检查跳过、手动检查仍会提示），配合关于页「重置已忽略的版本」入口；比 24h 计时更可预期
- [ ] [0.11.0-FE-A-008-test] mock 下载失败 / 签名 verify 失败的 dmg，验证状态机正确转 `error` 且不调 helper；mock 重复触发同版本，验证 24h 抑制逻辑 #P1
- [ ] [0.11.0-FE-A-010-test] 启动 helper 失败时回退到「请手动从 GitHub 下载」提示，不卡死 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
