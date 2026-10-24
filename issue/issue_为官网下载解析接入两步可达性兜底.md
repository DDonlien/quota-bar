# 为官网下载解析接入两步可达性兜底

- ID：`0.14.0-FE-A-002`。
- 类型：`BE`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.14.0 - 大陆可达性兜底 + 额度节奏指示 + Kimi 额度修复 / update/main: 更新检查与下载的 GitHub → Vercel 两步兜底。
- 原稳定 ID：`0.14.0-BE-A-000`, `0.14.0-BE-A-001`, `0.14.0-FE-A-000`, `0.14.0-FE-A-001`, `0.14.0-FE-A-002`, `0.14.0-QA-A-000`, `0.14.0-QA-A-001`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.14.0-BE-A-000`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.14.0-FE-A-002`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.14.0-BE-A-000-BE-github-vercel-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：update/main: 更新检查与下载的 GitHub → Vercel 两步兜底。
- 同源任务：[提供GitHub到Vercel的更新检查与下载兜底](issue_%E6%8F%90%E4%BE%9BGitHub%E5%88%B0Vercel%E7%9A%84%E6%9B%B4%E6%96%B0%E6%A3%80%E6%9F%A5%E4%B8%8E%E4%B8%8B%E8%BD%BD%E5%85%9C%E5%BA%95.md)。

## 当前需求与范围

共同范围与完整历史见[提供GitHub到Vercel的更新检查与下载兜底](issue_%E6%8F%90%E4%BE%9BGitHub%E5%88%B0Vercel%E7%9A%84%E6%9B%B4%E6%96%B0%E6%A3%80%E6%9F%A5%E4%B8%8E%E4%B8%8B%E8%BD%BD%E5%85%9C%E5%BA%95.md)；本文件保留以下独立目标的原文。

- [x] [0.14.0-FE-A-002] `site/src/pages/index.astro` 的 `UPDATE_DOWNLOAD` 脚本重构为 `resolveFromGitHub()` ?? `resolveFromFallback()`：GitHub 失败时改请求同源 `/api/latest-release`，且下载链接本身也改成同源 `/api/download-latest`（不是原始 github.com 直链——GitHub 都连不上，直链大概率也连不上）；sessionStorage 缓存的是最终 href 而不是 release 对象，两条路径共享同一份缓存逻辑

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

原迁移条目的历史Comments完整保留于[同源历史](issue_%E6%8F%90%E4%BE%9BGitHub%E5%88%B0Vercel%E7%9A%84%E6%9B%B4%E6%96%B0%E6%A3%80%E6%9F%A5%E4%B8%8E%E4%B8%8B%E8%BD%BD%E5%85%9C%E5%BA%95.md#comments)，不从历史日志新增完成标记。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
