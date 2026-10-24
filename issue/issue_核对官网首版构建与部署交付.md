# 核对官网首版构建与部署交付

- ID：`0.1.0-QA-A-000`。
- 类型：`QA`。
- 状态：阻塞（沿用原需求记录）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`site/REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.1.0 - 主页首版 / website/main: 完成主页首版验收。
- 原稳定 ID：`0.1.0-QA-A-000`, `0.1.0-QA-A-001`, `0.1.0-QA-A-002`, `0.1.0-QA-A-003`, `0.1.0-QA-A-004`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.1.0-QA-A-000] `npm run build` 通过，无构建错误 #QA
- [x] [0.1.0-QA-A-001] `npm run preview` 本地可访问，HTTP 200，标题正确 #QA
- [x] [0.1.0-QA-A-002] 所有 section 正确渲染（HTML 含 35+ 处关键类名） #QA
- [x] [0.1.0-QA-A-003] 相关文档已更新（site 子项目四件套 + 根目录索引） #QA
- [ ] [0.1.0-QA-A-004] Vercel 部署成功并绑定 `quotabar.ddonlien.com` #QA #blocked — Vercel 生产部署已 Ready，`quota-bar.vercel.app` 可访问；自定义域 DNS 当前解析到 `198.18.1.43`，需在 DNSPod 配置 `A quotabar.ddonlien.com 76.76.21.21`

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260628005258-utcp8-gpt5.md — 历史证据迁移

来源：`site/agent-log/20260628005258-utcp8-gpt5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 完成工作

- 创建 branch：`website/deployment`
- 创建 worktree：`.worktrees/website-deployment/`
- 通过浏览器复现官网不可访问。
- 确认 Vercel 生产部署和默认域名可访问，部署产物不是故障根因。
- 定位故障根因：`quotabar.ddonlien.com` DNS 未按 Vercel 要求配置，当前解析到 `198.18.1.43`，导致连接被关闭。
- 更新 `web/REQUIREMENTS.md` 中 `[0.1.0-QA-A-004]` 为 `#blocked`，记录 DNSPod 需配置的 A 记录。

#### 更新的需求 ID

- `[0.1.0-QA-A-004]`：从 `#deferred` 更新为 `#blocked`，备注改为 Vercel Ready + DNS 记录待修复。

#### 验证方式

- `git worktree list`：确认 `.worktrees/website-deployment` 存在并位于 `website/deployment`。
- 浏览器打开 `https://quotabar.ddonlien.com`：失败，`net::ERR_CONNECTION_CLOSED`。
- 浏览器打开 `https://quota-bar.vercel.app`：成功，主页内容正常。
- `curl` / `dig`：确认自定义域 DNS 解析异常。
- `vercel domains inspect quotabar.ddonlien.com`：确认 Vercel 要求配置 `A quotabar.ddonlien.com 76.76.21.21`。

#### 备注

- 修复动作应在 DNSPod 中完成：添加或修改 `quotabar` 子域 A 记录，指向 `76.76.21.21`。如果存在冲突的 A/CNAME/AAAA 记录，需删除冲突记录后等待 DNS 生效。
- `quota-bar.vercel.app` 当前可作为临时访问入口。

### 2026-10-24 07:03:43 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
