---
title: 抓取Codex真实订阅到期日
id: 0.6.0-DATA-B-000
type: DATA
status: 待处理（原文未完成项保持未勾选）。
版本管理: Git。
来源: '`REQUIREMENTS.md` @ `b550269a253e390d19ec221949fb30c44adf9e9e`；标题路径：任务清单 / Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页） / DATA-B：Codex 真实订阅到期日（headless 抓订阅页）。'
原稳定 ID: '`0.6.0-DATA-B-000`, `0.6.0-DATA-B-001`, `0.6.0-DATA-B-001-test`；不改写或重编号这些既有 ID。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

> Codex (chatgpt.com) 的 `/backend-api/wham/usage` 只返回 quota 窗口，**不返回订阅到期日**。需要 headless 抓 `chatgpt.com/account/manage` 或 `chatgpt.com/settings/billing` 页面，提取「Next billing date」「Renewal date」之类 DOM 文本。

- [ ] [0.6.0-DATA-B-000] `CodexHarvester` 实现：用 `WKWebViewHeadlessLoader` 加载 `https://chatgpt.com/account/manage`，DOM 提取续费日期；找不到返回 nil；超时/Cloudflare challenge 失败抛 `QuotaFetchError.transient` 让 pipeline 降级 #P1
- [ ] [0.6.0-DATA-B-001] `CodexAuthProvider` / `BrowserCookieProvider` Codex 路径新增 strategy：headless 抓订阅页 → 拿 `subscriptionExpiresAt`；和现有 quota 抓取并行，结果合并到 `ProviderSnapshot` #P1
- [ ] [0.6.0-DATA-B-001-test] 单元测试：mock HTML（含"Next billing on July 25, 2026"等常见模式）验证 `CodexHarvester` 解析出正确 `Date` #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260619011202-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260619011202-utcp8-gpt5.md` @ `b550269a253e390d19ec221949fb30c44adf9e9e`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

其他的ai都不行，你可以访问cli和terminal直接帮我build，帮我解决现在quota bar的问题：没办法正确货渠道电脑上的ai的情况，参考codex bar是怎么做的，而且现在一直要full disk access，明显不合理

#### 验证方式

- `cd drop-down-test/CodingPlanMenu && swift build`：通过。
- `cd drop-down-test/CodingPlanMenu && ./build-app.sh`：通过，生成 `QuotaBar.app`。
- 已关闭旧进程并通过 `open .../QuotaBar.app` 启动新构建，进程 PID 为 `91907`。

#### 需求更新

- `DA-A-005` 标记完成：菜单不再展示 `.notInstalled` snapshot。
- `UI-C-005` 文案更新为“浏览器 Cookie 数据源缺 Full Disk Access 时按需显示引导”。

#### 备注

- 工作区已有 `.build/`、`.DS_Store` 等构建产物变更；本轮运行 build 后这些文件继续保持 dirty。未回滚这些已有/构建生成的文件。
- 当前未实现 Codex OAuth token refresh；若 token 过期，会提示重新 `codex login`。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-070408_Agent

原记录标题：2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 20261024-162234_Codex

按用户最新手写模板迁移属性和正文结构，保留任务语义、来源、原始状态及历史内容；本次未重新执行业务验收。

原版本关联记录（照录来源，不将本次文档迁移提交当作业务实施提交）：
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。

本次执行环境未提供具体模型标识，未补造 Model-Detail。

[本次文档迁移对话](codex://threads/01a157b3-610c-73b4-ae06-163c0f8490d3)
