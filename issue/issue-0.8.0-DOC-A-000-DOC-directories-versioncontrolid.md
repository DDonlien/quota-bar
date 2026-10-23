# sub/main: 按交付物职责重命名顶层目录

- ID：`0.8.0-DOC-A-000`。
- 类型：`DOC`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.8.0 - 仓库结构适配新 Agent 模板 / sub/main: 按交付物职责重命名顶层目录。
- 原稳定 ID：`0.8.0-DOC-A-000`, `0.8.0-DOC-A-001`, `0.8.0-DOC-A-002`, `0.8.0-DOC-A-003`, `0.8.0-DOC-A-004`, `0.8.0-DOC-A-005`, `0.8.0-DOC-A-006`, `0.8.0-DOC-A-007`, `0.8.0-DOC-A-008`, `0.8.0-DOC-A-010`, `0.8.0-DOC-A-009`, `0.8.0-DOC-A-011`, `0.8.0-DOC-A-012`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.8.0-DOC-A-000] 参考新的 `agent-template/AGENTS.md` 更新根 `AGENTS.md` 标准内容与项目专用内容 #docs #P1
- [x] [0.8.0-DOC-A-001] 将 macOS 原生应用目录从 `quota-bar/` 迁移为 `macos/`，并同步 README、Makefile、CI、Release 配置中的命令与路径 #docs #P1
- [x] [0.8.0-DOC-A-002] 将营销主页目录从 `web/` 迁移为 `site/`，并同步子项目文档、Vercel 配置和 CI 构建路径 #docs #P1
- [x] [0.8.0-DOC-A-003] 将 Git worktree 工作目录从 `.worktrees/` 迁移为 `worktrees/`，并通过 `git worktree move` 保持 Git 元数据一致 #docs #P1
- [x] [0.8.0-DOC-A-004] 清理 `agent-template/` 中嵌套 `.git` 和模板历史日志，仅保留模板文件与日志模板文件 #docs #P1
- [x] [0.8.0-DOC-A-005] 将根 `REQUIREMENTS.md` 与 `site/REQUIREMENTS.md` 的三级标题迁移为新模板要求的 `branch-name: feature description` 结构，保留既有稳定 ID #docs #P1
- [x] [0.8.0-DOC-A-006] 按更新后的 `agent-template/AGENTS.md` 将 worktree 目录统一为单数 `worktree/` #docs #P1
- [x] [0.8.0-DOC-A-007] 将 `main` 分支也迁入 `worktree/main/`，项目容器根目录不再作为开发工作区 #docs #P1 #cut 已验证不适合 GitHub Desktop / Agent 发现模型，改回 main 在根目录
- [x] [0.8.0-DOC-A-008] 将主仓库 Git 元数据迁入 `.repo/.git`，并修复所有 worktree 的 gitdir 指向 #docs #P1 #cut 已随 [0.8.0-DOC-A-010] 还原为根目录 `.git`
- [x] [0.8.0-DOC-A-009] 同步 README、AGENTS、REQUIREMENTS、日志中的 `.repo/` + `worktree/` 结构说明 #docs #P1 #cut 已改为 main 根目录 + 单数 `worktree/` 结构说明
- [x] [0.8.0-DOC-A-010] 将 `main` 分支恢复到项目根目录，保留其他分支在单数 `worktree/` 下，兼容 GitHub Desktop / Codex / Agent 发现模型 #docs #P1
- [x] [0.8.0-DOC-A-011] 修改 `agent-template/AGENTS.md`：`main` 默认保留在根目录，非 `main` worktree 使用单数 `worktree/` #docs #P1
- [x] [0.8.0-DOC-A-012] 按 `agent-template/app-agent-template/AGENTS.md` 将项目整理为容器目录 + `main/` + 平铺 branch worktree + `_builds/` 结构，并同步当前 `AGENTS.md` / `README.md` 参考内容 #docs #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260713-092558-utcp8-taobe-gpt-5.md — 历史证据迁移

来源：`agent-log/20260713-092558-utcp8-taobe-gpt-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 我把main的资产迁移到了quota-bar/main，并且把所有worktree平铺在了根目录；帮我整理一下仓库，然后根据/Users/taobe/Projects/GitHub/Personal/agent-template/app-agent-template 更新agents文档里的文件夹结构参考内容

#### 完成工作

- Git 已正确识别 8 个 worktree：`main`、`claude/elastic-burnell-98d339`、`dropdown/main`、`menubar/main`、`preferences/main`、`site/main`、`sub/expiry`、`sub/main`。
- 新结构为：项目容器 + `main/` + 与 `main/` 平级的 branch worktree + 容器级 `_builds/`。
- `build-app.sh` 继续使用 `Quota Bar.app` 和 `QuotaBar.icns`，只改变新构建产物的容器级落点。

#### 更新的需求 ID

- `[0.8.0-DOC-A-012]`

#### 验证方式

- `git worktree list`：8 个 worktree 均显示正确的平铺绝对路径，无 `prunable`。
- `bash -n macos/scripts/build-app.sh`：通过。
- `git diff --check`：通过。
- 第一次 `make test` 暴露了移动 worktree 后旧 `.build` 缓存中的绝对路径；执行 `swift package clean` 后重新运行 `make test`，205 个测试、45 个 suite 全部通过。
- `make app`：成功生成 `../_builds/20260713-092510-main/Quota Bar.app`，并更新 `../_builds/latest`。
- `plutil -lint`、包内 `QuotaBar.icns` 存在性检查、`CFBundleName` / `CFBundleDisplayName` / `CFBundleExecutable` / `CFBundleIconFile` 检查和 `codesign --verify --deep --strict`：全部通过。
- 当前 active docs 中已无旧的 `worktree/`、`macos/build` 或 `build/latest` 结构引用。

#### 备注

- 远端同步因 DNS 无法解析 `github.com` 未完成；本轮没有根据远端变化做任何合并判断。
- `main` 工作区原有的源码改动、测试改动、未跟踪日志和 `macos/build/latest` 改动均保留，未执行提交。
