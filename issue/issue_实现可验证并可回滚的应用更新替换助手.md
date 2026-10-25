---
title: 实现可验证并可回滚的应用更新替换助手
id: 0.11.0-TOOL-A-000
type: ARCH
status: 进行中（原文同时包含已完成与未完成项）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.11.0 - 真实自动更新（ad-hoc 预开发版）+ semver 发版 / update/main: 写轻量 helper 替换脚本。'
原稳定 ID: '`0.11.0-ARCH-A-003`, `0.12.0-SEC-A-006`, `0.11.0-TOOL-A-000`, `0.11.0-TOOL-A-001`, `0.11.0-TOOL-A-002`, `0.11.0-TOOL-A-003`, `0.11.0-TOOL-A-004`, `0.11.0-TOOL-A-005`, `0.11.0-TOOL-A-000-test`, `0.11.0-TOOL-A-001-test`；不改写或重编号这些既有 ID。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> 选 B 方案：app 后台下载 dmg → 提示用户重启 → helper 挂载 dmg → 替换 `/Applications/Quota Bar.app` → 重启 app。
> 本 phase helper 用 ad-hoc 签名（依赖 [0.11.0-ARCH-A-003]）；v0.12.0 同步升级为 Developer ID（见 [0.12.0-SEC-A-006]）。
> ad-hoc 签名下 `spctl --assess` 会拒绝（因为 macOS 不认 ad-hoc 为有效签名），所以 v0.11.0 阶段只跑 `codesign --verify`，跳过 spctl；v0.12.0 起两者都跑。

- [x] [0.11.0-TOOL-A-000] 新增 `macos/scripts/install-update.sh`：接受 dmg 路径参数 → 挂载 dmg → 复制 .app 到 `/Applications/Quota Bar.app`（覆盖现有）→ 卸载 dmg → 退出码反映成功 / 失败 #P1
- [x] [0.11.0-TOOL-A-001] `install-update.sh` 替换前 verify 签名：`codesign --verify --verbose=2 <.app>`；ad-hoc 签名下**跳过** `spctl --assess`（ad-hoc 永远被拒，跳过不视为不通过）；任一失败立即终止，避免安装未签名包导致 TCC 权限被清。v0.12.0 升级 Developer ID 后强制加 `spctl --assess --type execute --verbose=2` 检查（见 [0.12.0-SEC-A-006]）#P1
- [x] [0.11.0-TOOL-A-002] `install-update.sh` 走 `build-app.sh` 同一签名流程（v0.11.0 是 ad-hoc，v0.12.0 升级为 Developer ID + notarize）；产物 `install-update` 与主 .app 一起打包进 dmg 内的 `tools/` 目录（dmg 用户从 Applications 拖到 Applications 的常规用法不会暴露它，仅 app 启动时通过 `Bundle.main.bundleURL.deletingLastPathComponent()` 等方式定位）#P1 — 实现偏差：helper 打包进 .app 的 `Contents/Resources/install-update.sh`（随主包 ad-hoc 签名整体覆盖），主 app 通过 `Bundle.main.url(forResource:)` 定位；比 dmg tools/ 目录更不易被用户误删
- [x] [0.11.0-TOOL-A-003] `install-update.sh` 在替换前等主 app 进程退出（`pkill -x "QuotaBar"` + 短暂 sleep 等待进程清理），避免 file lock；超时 5s 后强杀 #P1
- [x] [0.11.0-TOOL-A-004] 替换失败时（disk full / 权限不足 / 签名 verify 失败）回滚：保留旧 .app，把失败原因写 `~/Library/Application Support/QuotaBar/update-error.log`；主 app 启动时检测该文件并弹「上次更新失败」通知 #P1
- [x] [0.11.0-TOOL-A-005] `install-update.sh` 支持 `--dry-run` 模式：不实际替换，仅打印将要执行的操作；CI / 开发调试使用 #P1
- [ ] [0.11.0-TOOL-A-000-test] helper 集成测试：mock dmg 挂载 + 写一个 .app stub，验证 dry-run 不写盘、正常模式正确复制、失败模式回滚 + 写 error log #P1
- [ ] [0.11.0-TOOL-A-001-test] helper 拒绝未签名 / 签名错误的 dmg，给出明确错误码 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-070343_Agent

原记录标题：2026-10-24 07:03:43 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-162234_Codex

按用户最新手写模板迁移属性和正文结构，保留任务语义、来源、原始状态及历史内容；本次未重新执行业务验收。

原版本关联记录（照录来源，不将本次文档迁移提交当作业务实施提交）：
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。

本次执行环境未提供具体模型标识，未补造 Model-Detail。

[本次文档迁移对话](codex://threads/01a157b3-610c-73b4-ae06-163c0f8490d3)
