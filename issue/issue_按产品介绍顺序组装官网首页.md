---
title: 按产品介绍顺序组装官网首页
id: 0.1.0-FE-B-000
type: FE
status: 已完成（沿用原需求记录；本轮未重新执行产品验收）。
版本管理: Git。
来源: '`site/REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.1.0 - 主页首版 / website/main: 组装主页并接入下载链接。'
原稳定 ID: '`0.1.0-FE-B-000`, `0.1.0-FE-B-001`, `0.1.0-FE-B-002`；不改写或重编号这些既有 ID。'
拆分前ID: '`0.1.0-FE-B-000`（沿用旧ID，不新增编号）。'
本任务原稳定ID: '`0.1.0-FE-B-000`。'
状态范围: 上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
迁移前文件: '`issue/issue-0.1.0-FE-B-000-FE-landing-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。'
迁移前标题: 'website/main: 组装主页并接入下载链接。'
同源任务: '[通过GitHubRelease解析统一下载入口](issue_%E9%80%9A%E8%BF%87GitHubRelease%E8%A7%A3%E6%9E%90%E7%BB%9F%E4%B8%80%E4%B8%8B%E8%BD%BD%E5%85%A5%E5%8F%A3.md)。'
updated-time: '2026-10-24T16:22:34+00:00'
---

# Description

## 当前需求与范围

- [x] [0.1.0-FE-B-000] `index.astro` 组装所有 section，Hero / Providers / Features / Showcase / Footer 顺序 #FE

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

# Comments

## 20261023-174433_Agent

原记录标题：2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

## 历史记录-时间未记录

原记录标题：20260701-235200-utcp8-taobe-minimax-m3.md — 历史证据迁移

来源：`site/agent-log/20260701-235200-utcp8-taobe-minimax-m3.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

- 「把我在 main 上面打的最新的包绑定到这个下载按钮上，然后把最新版的 site 推送到 Vercel」

#### 完成工作

- `site/src/components/Nav.astro`：
  - 在 frontmatter 加 `LATEST_DMG_URL` 常量（写死 `nightly-c6317d05...` 的 `.dmg` release asset URL），注释说明：JS 不可用或首屏加载前的 fallback 直击 `.dmg`；动态 `UPDATE_DOWNLOAD` 会在 fetch 出更新 release 时再覆盖一次
  - `data-download` 链接的 `href` 从 `https://github.com/DDonlien/quota-bar/releases` 改为 `{LATEST_DMG_URL}`
- `site/src/components/Hero.astro`：
  - 同样的 `LATEST_DMG_URL` 常量
  - Hero 主 CTA 的 `href` 从 `/releases` 改为 `{LATEST_DMG_URL}`
- `site/.vercel/project.json`：vercel link 写入（gitignored，正常）

#### 更新的需求 ID

无（这是需求 `[0.1.0-FE-B-002] 所有 data-download 链接共享同一份 release 解析逻辑` 之上的微调：保持 JS 动态逻辑不动，仅升级静态 fallback；该 task 已在 `site/REQUIREMENTS.md` 标记完成）

#### 验证方式

1. `make site`：`astro build` 通过（1 page / 363ms / 0 error），`grep "QuotaBar-c6317d0.dmg" site/dist/index.html` 命中
2. `vercel ls quota-bar`：最新 production deployment = `quota-27k7tc2ob`，状态 Ready，3m 前
3. `vercel alias ls | grep quotabar.ddonlien.com`：source = `quota-27k7tc2ob`（不再是 10d 前的 `ckxngias4`）
4. `curl -sL https://quotabar.ddonlien.com/`：
   - HTTP/2 200 ✓
   - `QuotaBar-c6317d0.dmg` 命中 ✓（dist 里的硬编码 URL 与 release asset 一致）
   - `data-download` 实例数 = 2（Nav + Hero 都在）
5. `vercel ls | head` 确认 `taobe-team/site`（误建的项目）已被移除

#### 备注

- **核心改动只是 12 行两文件**：Nav.astro / Hero.astro 各加 6 行（1 个常量 + 1 处 href 替换 + 注释），保持 `index.astro` 里的动态 `UPDATE_DOWNLOAD` 逻辑原样
- **静态 vs 动态 fallback 双保险**：
  - 静态 fallback（本次 hardcode）兜底：无 JS / 首屏加载前 / fetch 失败的访客也能直击 `.dmg`
  - 动态 fallback（既有 JS）：未来 nightly 比当前 hardcode 的更新时，自动 fetch 覆盖 `href`
  - 副作用：每次发新 nightly 后，`LATEST_DMG_URL` 不更新也不会"出错" —— 动态 JS 会"修正"。但为了 SEO 和"复制粘贴分享"场景，"硬绑到最新"才是真"绑定"
- **Makefile `make deploy` 的坑**：`vercel 54.x` 起没有 `--yes` 跑不动，且没跑 `make link` 会默认开新项目。建议下次顺手把 Makefile 的 `deploy` target 改成 `cd site && vercel --prod --yes`，并写一个 check `site/.vercel/project.json` 是否存在、不存在则提示跑 `make link`。本次没改 Makefile（不在 prompt 范围）
- **working tree dirty 风险**：源改动（Nav.astro / Hero.astro）未 commit。如果用户在 main 上做别的修改、rebase、或 pull，可能会冲突；如果用户还要做更多网站改动，先 commit 这次 binding 改动更稳。等用户 review 后再决定 commit / push 风格
- **Vercel GitHub integration**：5m 前自动触发的 production 部署和这次的 CLI 部署并存。CLI 部署的产物 `quota-27k7tc2ob` 现在持有 `quotabar.ddonlien.com` alias；GitHub 集成下一次 push 触发的 production 部署大概率会同样被 alias 指向（取决于 Vercel 是否配置 production branch 直 promote）
- **release 资产大小**：4 个 nightly .dmg 大小都在 1.4–2.1 MB 区间（构建过程稳定，体积差异主要来自 Provider 数量的代码差异）

#### 后续未做

- `Nav.astro` / `Hero.astro` 的 `LATEST_DMG_URL` 没 commit
- `Makefile` `deploy` target 没自动加 `--yes` 和 link 检查
- `site/.vercel/project.json` 即使现在写入了，下次 `make clean`（`rm -rf site/.astro site/dist site/node_modules` 不带 `.vercel/`，所以不会误删）不影响
- 没把这次误建 `site` 项目 + 链接缺失 + Makefile 需要 `--yes` 这件事写进项目 AGENTS.md 或 memory，等用户拍板

原记录未提供完整 Agent / 模型详情及原执行会话链接，未补造。

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
