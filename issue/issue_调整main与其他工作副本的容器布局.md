# 调整main与其他工作副本的容器布局

- ID：`0.8.0-DOC-A-003`。
- 类型：`DOC`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.8.0 - 仓库结构适配新 Agent 模板 / sub/main: 按交付物职责重命名顶层目录。
- 原稳定 ID：`0.8.0-DOC-A-000`, `0.8.0-DOC-A-001`, `0.8.0-DOC-A-002`, `0.8.0-DOC-A-003`, `0.8.0-DOC-A-004`, `0.8.0-DOC-A-005`, `0.8.0-DOC-A-006`, `0.8.0-DOC-A-007`, `0.8.0-DOC-A-008`, `0.8.0-DOC-A-010`, `0.8.0-DOC-A-009`, `0.8.0-DOC-A-011`, `0.8.0-DOC-A-012`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.8.0-DOC-A-000`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.8.0-DOC-A-003`、`0.8.0-DOC-A-006`、`0.8.0-DOC-A-007`、`0.8.0-DOC-A-008`、`0.8.0-DOC-A-009`、`0.8.0-DOC-A-010`、`0.8.0-DOC-A-012`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.8.0-DOC-A-000-DOC-directories-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：sub/main: 按交付物职责重命名顶层目录。
- 同源任务：[同步协作模板与需求标题规范](issue_%E5%90%8C%E6%AD%A5%E5%8D%8F%E4%BD%9C%E6%A8%A1%E6%9D%BF%E4%B8%8E%E9%9C%80%E6%B1%82%E6%A0%87%E9%A2%98%E8%A7%84%E8%8C%83.md)、[将macOS交付目录迁移为macos](issue_%E5%B0%86macOS%E4%BA%A4%E4%BB%98%E7%9B%AE%E5%BD%95%E8%BF%81%E7%A7%BB%E4%B8%BAmacos.md)、[将营销主页目录迁移为site](issue_%E5%B0%86%E8%90%A5%E9%94%80%E4%B8%BB%E9%A1%B5%E7%9B%AE%E5%BD%95%E8%BF%81%E7%A7%BB%E4%B8%BAsite.md)。

## 当前需求与范围

共同范围与完整历史见[同步协作模板与需求标题规范](issue_%E5%90%8C%E6%AD%A5%E5%8D%8F%E4%BD%9C%E6%A8%A1%E6%9D%BF%E4%B8%8E%E9%9C%80%E6%B1%82%E6%A0%87%E9%A2%98%E8%A7%84%E8%8C%83.md)；本文件保留以下独立目标的原文。

- [x] [0.8.0-DOC-A-003] 将 Git worktree 工作目录从 `.worktrees/` 迁移为 `worktrees/`，并通过 `git worktree move` 保持 Git 元数据一致 #docs #P1
- [x] [0.8.0-DOC-A-006] 按更新后的 `agent-template/AGENTS.md` 将 worktree 目录统一为单数 `worktree/` #docs #P1
- [x] [0.8.0-DOC-A-007] 将 `main` 分支也迁入 `worktree/main/`，项目容器根目录不再作为开发工作区 #docs #P1 #cut 已验证不适合 GitHub Desktop / Agent 发现模型，改回 main 在根目录
- [x] [0.8.0-DOC-A-008] 将主仓库 Git 元数据迁入 `.repo/.git`，并修复所有 worktree 的 gitdir 指向 #docs #P1 #cut 已随 [0.8.0-DOC-A-010] 还原为根目录 `.git`
- [x] [0.8.0-DOC-A-009] 同步 README、AGENTS、REQUIREMENTS、日志中的 `.repo/` + `worktree/` 结构说明 #docs #P1 #cut 已改为 main 根目录 + 单数 `worktree/` 结构说明
- [x] [0.8.0-DOC-A-010] 将 `main` 分支恢复到项目根目录，保留其他分支在单数 `worktree/` 下，兼容 GitHub Desktop / Codex / Agent 发现模型 #docs #P1
- [x] [0.8.0-DOC-A-012] 按 `agent-template/app-agent-template/AGENTS.md` 将项目整理为容器目录 + `main/` + 平铺 branch worktree + `_builds/` 结构，并同步当前 `AGENTS.md` / `README.md` 参考内容 #docs #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

原迁移条目的历史Comments完整保留于[同源历史](issue_%E5%90%8C%E6%AD%A5%E5%8D%8F%E4%BD%9C%E6%A8%A1%E6%9D%BF%E4%B8%8E%E9%9C%80%E6%B1%82%E6%A0%87%E9%A2%98%E8%A7%84%E8%8C%83.md#comments)，不从历史日志新增完成标记。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
