---
title: 核对正式签名更新与权限保留流程
id: 0.12.0-QA-A-000
type: DOC
status: 待定 / 延后（沿用原需求记录）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.12.0 - 升级到 Developer ID 签名 + notarize / update/main: 升级文档与验收。'
原稳定 ID: '`0.12.0-DOC-A-000`, `0.12.0-DOC-A-001`, `0.12.0-DOC-A-002`, `0.12.0-QA-A-000`, `0.12.0-QA-A-001`, `0.12.0-QA-A-002`, `0.12.0-QA-A-003`, `0.12.0-QA-A-004`, `0.12.0-QA-A-005`, `0.12.0-QA-A-006`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.12.0-QA-A-000`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.12.0-QA-A-000`、`0.12.0-QA-A-001`、`0.12.0-QA-A-002`、`0.12.0-QA-A-003`、`0.12.0-QA-A-004`、`0.12.0-QA-A-005`、`0.12.0-QA-A-006`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.12.0-QA-A-000-DOC-documentation-acceptance-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'update/main: 升级文档与验收。'
同源任务: '[编写正式签名与自动更新配置说明](issue_%E7%BC%96%E5%86%99%E6%AD%A3%E5%BC%8F%E7%AD%BE%E5%90%8D%E4%B8%8E%E8%87%AA%E5%8A%A8%E6%9B%B4%E6%96%B0%E9%85%8D%E7%BD%AE%E8%AF%B4%E6%98%8E.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

共同范围与完整历史见[编写正式签名与自动更新配置说明](issue_%E7%BC%96%E5%86%99%E6%AD%A3%E5%BC%8F%E7%AD%BE%E5%90%8D%E4%B8%8E%E8%87%AA%E5%8A%A8%E6%9B%B4%E6%96%B0%E9%85%8D%E7%BD%AE%E8%AF%B4%E6%98%8E.md)；本文件保留以下独立目标的原文。

- [ ] [0.12.0-QA-A-000] 端到端冒烟（Developer ID 路径）：从空本地 checkout → enroll + 生成 cert + 配 API Key → `make app` 成功生成 Developer ID 签名 + notarize 的 dmg → `spctl --assess` 通过 → 推 main → 自动生成 nightly release → 在 app 内检查到 #P1
- [ ] [0.12.0-QA-A-001] 手动触发 semver workflow → 生成 `v0.12.0` release → 旧版 app 启动后能正确识别为新版本 → 走完下载 + 替换流程 → 新版 app 启动 → Accessibility 权限**形式化保留**（系统设置里仍显示已授权，可通过 `tccutil` 或 `sqlite3 ~/Library/Application Support/com.apple.TCC/TCC.db` 验证）#P1
- [ ] [0.12.0-QA-A-002] DMG 首次下载后 Gatekeeper 不拦截（双击直接打开，非「右键 → 打开」），继承自 v0.11.0-QA-A-002 #deferred #P1
- [ ] [0.12.0-QA-A-003] 重复运行「检查更新」不会刷屏 / 不会重复下载同版本 / 不会忽略用户主动重置（v0.11.0-QA-A-003 regression check，签名升级不影响此行为）#P1
- [ ] [0.12.0-QA-A-004] 60 次/小时限流边界：mock API 返回 `403 X-RateLimit-Remaining: 0` 时 app 提示「检查过于频繁，请稍后重试」而非永久拒服务（v0.11.0-QA-A-004 regression check）#P1
- [ ] [0.12.0-QA-A-005] helper 失败路径：mock 替换失败 → 主 app 检测到 `update-error.log` → 启动时弹「上次更新失败」通知，旧版继续运行不崩（v0.11.0-QA-A-005 regression check；helper 现在 Developer ID 签名，失败处理路径不变）#P1
- [ ] [0.12.0-QA-A-006] TCC 权限形式化断言（v0.12.0 验收核心）：旧版 app 已授权 Accessibility → 触发更新 → 安装新版 → 通过 `tccutil` / `sqlite3 ~/Library/Application Support/com.apple.TCC/TCC.db` 查新版 app 的授权状态（service = kTCCServiceAccessibility / kTCCServiceScreenCapture / kTCCServicePostEvent，client = `com.taobe.quotabar`），断言 auth_value = 2（allowed）而非 0（denied）#P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 历史记录-时间未记录

原迁移条目的历史Comments完整保留于[同源历史](issue_%E7%BC%96%E5%86%99%E6%AD%A3%E5%BC%8F%E7%AD%BE%E5%90%8D%E4%B8%8E%E8%87%AA%E5%8A%A8%E6%9B%B4%E6%96%B0%E9%85%8D%E7%BD%AE%E8%AF%B4%E6%98%8E.md#comments)，不从历史日志新增完成标记。

原记录时间、具体执行 Agent、模型与原会话未记录，未补造。

## 20261024-070343_Agent

原记录标题：2026-10-24 07:03:43 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-162234_Codex

按用户最新手写模板迁移属性和正文结构，保留任务语义、来源、原始状态及历史内容；本次未重新执行业务验收。

原版本关联记录（照录来源，不将本次文档迁移提交当作业务实施提交）：
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。

本次执行环境未提供具体模型标识，未补造 Model-Detail。

[本次文档迁移对话](codex://threads/01a157b3-610c-73b4-ae06-163c0f8490d3)
