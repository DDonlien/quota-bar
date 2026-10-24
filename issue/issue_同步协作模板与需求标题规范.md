# 同步协作模板与需求标题规范

- ID：`0.8.0-DOC-A-000`。
- 类型：`DOC`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`；标题路径：任务清单 / Phase - v0.8.0 - 仓库结构适配新 Agent 模板 / sub/main: 按交付物职责重命名顶层目录。
- 原稳定 ID：`0.8.0-DOC-A-000`, `0.8.0-DOC-A-001`, `0.8.0-DOC-A-002`, `0.8.0-DOC-A-003`, `0.8.0-DOC-A-004`, `0.8.0-DOC-A-005`, `0.8.0-DOC-A-006`, `0.8.0-DOC-A-007`, `0.8.0-DOC-A-008`, `0.8.0-DOC-A-010`, `0.8.0-DOC-A-009`, `0.8.0-DOC-A-011`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.8.0-DOC-A-000`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.8.0-DOC-A-000`、`0.8.0-DOC-A-004`、`0.8.0-DOC-A-005`、`0.8.0-DOC-A-011`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.8.0-DOC-A-000-DOC-directories-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：sub/main: 按交付物职责重命名顶层目录。
- 同源任务：[将macOS交付目录迁移为macos](issue_%E5%B0%86macOS%E4%BA%A4%E4%BB%98%E7%9B%AE%E5%BD%95%E8%BF%81%E7%A7%BB%E4%B8%BAmacos.md)、[将营销主页目录迁移为site](issue_%E5%B0%86%E8%90%A5%E9%94%80%E4%B8%BB%E9%A1%B5%E7%9B%AE%E5%BD%95%E8%BF%81%E7%A7%BB%E4%B8%BAsite.md)、[调整main与其他工作副本的容器布局](issue_%E8%B0%83%E6%95%B4main%E4%B8%8E%E5%85%B6%E4%BB%96%E5%B7%A5%E4%BD%9C%E5%89%AF%E6%9C%AC%E7%9A%84%E5%AE%B9%E5%99%A8%E5%B8%83%E5%B1%80.md)。

## 当前需求与范围

- [x] [0.8.0-DOC-A-000] 参考新的 `agent-template/AGENTS.md` 更新根 `AGENTS.md` 标准内容与项目专用内容 #docs #P1
- [x] [0.8.0-DOC-A-004] 清理 `agent-template/` 中嵌套 `.git` 和模板历史日志，仅保留模板文件与日志模板文件 #docs #P1
- [x] [0.8.0-DOC-A-005] 将根 `REQUIREMENTS.md` 与 `site/REQUIREMENTS.md` 的三级标题迁移为新模板要求的 `branch-name: feature description` 结构，保留既有稳定 ID #docs #P1
- [x] [0.8.0-DOC-A-011] 修改 `agent-template/AGENTS.md`：`main` 默认保留在根目录，非 `main` worktree 使用单数 `worktree/` #docs #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
