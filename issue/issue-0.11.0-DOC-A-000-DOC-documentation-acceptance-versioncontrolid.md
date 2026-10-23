# update/main: 更新流程文档与验收

- ID：`0.11.0-DOC-A-000`。
- 类型：`DOC`。
- 状态：进行中（原文同时包含已完成与未完成项）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.11.0 - 真实自动更新（ad-hoc 预开发版）+ semver 发版 / update/main: 更新流程文档与验收。
- 原稳定 ID：`0.11.0-DOC-A-000`, `0.12.0-DOC-A-001`, `0.11.0-DOC-A-001`, `0.12.0-DOC-A-002`, `0.11.0-DOC-A-002`, `0.12.0-DOC-A-000`, `0.11.0-QA-A-000`, `0.11.0-QA-A-001`, `0.11.0-UI-A-003`, `0.11.0-QA-A-002`, `0.12.0-QA-A-002`, `0.11.0-QA-A-003`, `0.11.0-QA-A-004`, `0.11.0-QA-A-005`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.11.0-DOC-A-000] `macos/AGENTS.md` 加一节「发版流程（ad-hoc 预开发版）」：本地 `make app`（ad-hoc 签名）→ 推 main → 自动 nightly（ad-hoc DMG，首次打开需「右键 → 打开」）；需要发版时用 GitHub Actions 手动触发 `workflow_dispatch` 传 `vX.Y.Z`。v0.12.0 升级 cert 后本节再扩展签名 + notarize 步骤（见 [0.12.0-DOC-A-001]）#P1
- [x] [0.11.0-DOC-A-001] `README.md` 加「更新策略（ad-hoc 预开发版）」段：自动更新如何工作 + 哪些 macOS 权限**通常会保留（best-effort）** + 如何手动重置忽略的版本。v0.12.0 升级后正式改写为「Developer ID 签名后形式化保障」（见 [0.12.0-DOC-A-002]）#P1
- [ ] [0.11.0-DOC-A-002] 写 `macos/scripts/cert-bootstrap.md`：用户首次配签名环境的 step-by-step（enroll / 生成 cert / 配 API Key / 验证）#deferred v0.12.0 — 本 phase 不引入 cert，文档先不写；v0.12.0 升级时落地（见 [0.12.0-DOC-A-000]）
- [ ] [0.11.0-QA-A-000] 端到端冒烟（ad-hoc 路径）：从空本地 checkout → `make app` 成功生成 ad-hoc 签名的 dmg → 推 main → 自动生成 nightly release → 在 app 内检查到。Gatekeeper 首次拦截预期内、本机授权一次后记住 #P1
- [ ] [0.11.0-QA-A-001] 手动触发 semver workflow → 生成 `v0.11.0` release → 旧版 app 启动后能正确识别为新版本 → 走完下载 + 替换流程 → 新版 app 启动 → Accessibility 权限**通常仍在**（best-effort，不保证；ad-hoc 签名下 macOS 可能把它当新 app，UI 文案已在 [0.11.0-UI-A-003] 明确告知）#P1
- [ ] [0.11.0-QA-A-002] DMG 首次下载后 Gatekeeper 行为符合 ad-hoc 预期：双击有「无法验证开发者」警告，需「右键 → 打开」或「系统设置 → 仍要打开」；本机授权后不再拦截 #deferred v0.12.0 — v0.11.0 维持 ad-hoc，Gatekeeper 不拦截是 v0.12.0 目标（见 [0.12.0-QA-A-002]）
- [ ] [0.11.0-QA-A-003] 重复运行「检查更新」不会刷屏 / 不会重复下载同版本 / 不会忽略用户主动重置 #P1
- [ ] [0.11.0-QA-A-004] 60 次/小时限流边界：mock API 返回 `403 X-RateLimit-Remaining: 0` 时 app 提示「检查过于频繁，请稍后重试」而非永久拒服务 #P1
- [ ] [0.11.0-QA-A-005] helper 失败路径：mock 替换失败 → 主 app 检测到 `update-error.log` → 启动时弹「上次更新失败」通知，旧版继续运行不崩 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260702-140400-utcp8-minimax-m3.md — 历史证据迁移

来源：`agent-log/20260702-140400-utcp8-minimax-m3.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 做2个版本：
> - 我没有 apple developer program 的最优雅版本
> - 有的情况下的理想实现版本
> 存入 requirements
> 确保尽量具备延续性（不要说有和没有是要推翻重写，把没有 Apple Developer Program 的情况，认为是有 Apple Developer Program 的一种前置预开发）

#### 用户诉求

用户要求把 v0.11.0 拆成两个版本：
1. **没有 Apple Developer Program** 的最优雅版本（ad-hoc 预开发版）
2. **有 Apple Developer Program** 的理想实现版本（Developer ID + notarize）

**关键约束**：确保延续性 —— 没有 cert 的情况是**有 cert 情况的前置预开发**，不是两个独立 feature 的平行实现。v0.12.0 应该是 v0.11.0 的**升级**（仅改签名链），而不是 v0.11.0 的**重写**。

#### 完成工作

- [x] v0.11.0 phase header 重写为"ad-hoc 预开发版"
- [x] v0.11.0 SEC 段（6 个 task）整段删除
- [x] v0.11.0 新增 `update/main: 维持 ad-hoc 签名 + 无 notarize 立场（预开发版）` 段（5 个 ARCH task + 1 test）
- [x] v0.11.0 TOOL-A-001 / TOOL-A-002 改写为 ad-hoc 视角
- [x] v0.11.0 UI-A-003 / DOC-A-000 / DOC-A-001 / QA-A-000 / QA-A-001 改写为 ad-hoc 视角
- [x] v0.11.0 CI-A-004 内容改写为"维持注释"
- [x] v0.11.0 DOC-A-002 / QA-A-002 标记 #deferred v0.12.0
- [x] 追加 v0.12.0 phase，含 3 个子节、~20 个 task
- [x] 本日志

#### 验证方式

- [x] `git diff REQUIREMENTS.md` 显示 v0.11.0 改动 + v0.12.0 新增，未影响 v0.0.0 ~ v0.10.0
- [x] 所有 v0.11.0 task 走 `[0.11.0-*-A-NNN]` 格式
- [x] 所有 v0.12.0 task 走 `[0.12.0-*-A-NNN]` 格式
- [x] 严格遵守"测试任务为子任务"（`<parent>-test`）
- [x] v0.11.0 SEC 段删除有 phase header 说明（"延续到 v0.12.0 的设计边界"段）
- [x] v0.11.0 → v0.12.0 的交叉引用全部显式标注（v0.12.0 phase header 有"交叉引用"段）
- [x] 未提交

#### 备注

- **关键架构洞察**：v0.11.0 与 v0.12.0 的关系不是两个 feature，是**同一 feature 的两个 phase**。v0.11.0 把 update 机制跑通，v0.12.0 把签名链升级。中间共享：bundle id（v0.11.0-ARCH-A-000 锁死）、UpdateChecker / 状态机、helper 替换逻辑、UI 框架。
- **隐含的工程价值**：v0.11.0 ad-hoc 预开发版的真正价值不是省 $99，而是**让用户在不投入 cert 成本前就能验证 update 流程**。如果 v0.11.0 阶段发现 UpdateChecker / helper 逻辑有 bug，v0.12.0 升级时不会拖入 cert 复杂度。
- **用户偏好映射**：
  - "测试任务为子任务" → 所有 test 走 `<parent>-test`
  - "不要 `### QA-A：xxx` 顶层 block" → QA 任务挂在 `update/main: 更新流程文档与验收` 段下
  - "任务稳定 ID 不变" → v0.11.0 既有 task 全部保留 ID，只改内容
- **未走 ask_user**：用户说"做2个版本"明确同意拆分；worktree 命名延续 v0.11.0 既有 `update/main` 约定；不需要弹窗确认。
- **潜在 follow-up**：v0.12.0 落地时如果用户对 cert 流程有更多想法（比如要不要走 CI 签），agent 可以在 SEC 段追加 task；当前 SEC 段已留有 A-007+ 空间。

### 20260702-105700-utcp8-minimax-m3.md — 历史证据迁移

来源：`agent-log/20260702-105700-utcp8-minimax-m3.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 帮我增加一个功能到应用：现在的检查更新是假的，我需要是真的，先给我点建议：是从 github 还是从 vercel 获取最新的包？

> 引入 smver，保留 nightly 作为常规的打包、推送，如果需要 smver 更新版本单独调用另一个打包指令并在 commit 或者指令中写入版本号
> B
> 我不知道你说的鉴权是什么？更新后我希望 app 能保留之前所有的系统权限和设置的

> 多问一句，签名要怎么获得？

> 加入 requirements

#### 完成工作

- [x] 在 `REQUIREMENTS.md` 末尾追加 v0.11.0 phase（共 7 个子节、约 50 条 task）
- [x] 本日志

#### 更新的需求 ID

新增 phase：

- **Phase - v0.11.0 - 真实自动更新 + semver 发版 + 代码签名公证**
  - `update/main: 引入 semver 发版路径`（CI-A-000 ~ 004 + 1 test）
  - `update/main: 接入 Apple Developer ID 签名 + notarize`（SEC-A-000 blocked ~ 004 + 3 tests）
  - `update/main: 写轻量 helper 替换脚本`（TOOL-A-000 ~ 005 + 2 tests）
  - `update/main: 实现 UpdateChecker（GitHub Releases API）`（FE-A-000 ~ 007 + 2 tests）
  - `update/main: 后台下载 + 提示重启安装`（FE-A-008 ~ 012 + 2 tests）
  - `update/main: 更新检查 UI 改造`（UI-A-000 ~ 004 + 1 test）
  - `update/main: 更新流程文档与验收`（DOC-A-000 ~ 002 + QA-A-000 ~ 005）

稳定 ID 分配：

- `[0.11.0-CI-A-000]` ~ `[0.11.0-CI-A-004]` + 1 test
- `[0.11.0-SEC-A-000]` ~ `[0.11.0-SEC-A-004]` + 3 tests
- `[0.11.0-TOOL-A-000]` ~ `[0.11.0-TOOL-A-005]` + 2 tests
- `[0.11.0-FE-A-000]` ~ `[0.11.0-FE-A-012]` + 4 tests
- `[0.11.0-UI-A-000]` ~ `[0.11.0-UI-A-004]` + 1 test
- `[0.11.0-DOC-A-000]` ~ `[0.11.0-DOC-A-002]`
- `[0.11.0-QA-A-000]` ~ `[0.11.0-QA-A-005]`

#### 验证方式

- [x] `git diff REQUIREMENTS.md` 末尾追加 v0.11.0 phase，未影响既有 phase
- [x] 所有 task ID 走 `[0.11.0-*-A-NNN]` 格式，`<parent>-test` 模式正确
- [x] 未触碰 README / DESIGN / AGENTS.md / 任何代码文件
- [x] 严格遵守"任务不进顶层 meta-check block" / "测试任务为子任务" 等用户偏好
- [x] 命名规则：`## Phase - vX.Y.Z - description` + `### branch-name: feature description`
- [x] 未提交

#### 备注

- **worktree 拆分决策**：所有任务集中在 `update/main` 单 worktree，因为：
  1. semver / 签名 / helper / UpdateChecker / UI 是同一交付节奏
  2. helper 强依赖 SEC 段（签名脚本），强行拆开 worktree 反而割裂
  3. 现有 worktree 模式（`dropdown/main` `menubar/main` 等）都是一 feature 一 worktree
  - 后续如果需要把 helper 拆成独立二进制 + 独立签名链，再单独拆 worktree
- **命名对齐**：proposed `update/main` 与现有 `dropdown/main` / `menubar/main` / `preferences/main` / `site/main` / `sub/main` / `sub/expiry` 对齐
- **关键依赖**：`SEC-A-000`（用户 enroll Apple Developer）阻塞所有 helper 任务（TOOL 段）和 UpdateChecker 落地（FE 段需要真实签名 dmg 才能 verify）
- **隐含 bug 修复**：v0.11.0-SEC-A-004 显式断言 bundle id / signature identifier 不变 —— 这是「TCC 权限更新后保留」承诺的形式化保障
- **未走 ask_user**：用户说"加入 requirements" 明确同意落地；worktree 命名遵循既有项目约定，不需要弹窗确认
