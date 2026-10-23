# update/main: 升级文档与验收

- ID：`0.12.0-QA-A-000`。
- 类型：`DOC`。
- 状态：待定 / 延后（沿用原需求记录）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.12.0 - 升级到 Developer ID 签名 + notarize / update/main: 升级文档与验收。
- 原稳定 ID：`0.12.0-DOC-A-000`, `0.12.0-DOC-A-001`, `0.12.0-DOC-A-002`, `0.12.0-QA-A-000`, `0.12.0-QA-A-001`, `0.12.0-QA-A-002`, `0.12.0-QA-A-003`, `0.12.0-QA-A-004`, `0.12.0-QA-A-005`, `0.12.0-QA-A-006`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [ ] [0.12.0-DOC-A-000] 写 `macos/scripts/cert-bootstrap.md`：用户首次配签名环境的 step-by-step（enroll / 生成 cert / 配 API Key / 验证），agent 后续 onboarding 流程直接引用（继承自 v0.11.0-DOC-A-002 #deferred）#P1
- [ ] [0.12.0-DOC-A-001] `macos/AGENTS.md` 的「发版流程」节从 v0.11.0-DOC-A-000 的 ad-hoc 版升级为 cert 版：本地 `make app`（Developer ID + notarize）→ `spctl --assess` 通过 → 推 main → 自动 nightly；需要发版时用 GitHub Actions 手动触发 `workflow_dispatch` 传 `vX.Y.Z` #P1
- [ ] [0.12.0-DOC-A-002] `README.md` 的「更新策略」节从 v0.11.0-DOC-A-001 的 best-effort 版升级为正式版：Developer ID 签名 + notarize 后 macOS TCC 权限（Accessibility / Screen Recording / Automation 等）更新后**形式化保留** + 如何手动重置忽略的版本 #P1
- [ ] [0.12.0-QA-A-000] 端到端冒烟（Developer ID 路径）：从空本地 checkout → enroll + 生成 cert + 配 API Key → `make app` 成功生成 Developer ID 签名 + notarize 的 dmg → `spctl --assess` 通过 → 推 main → 自动生成 nightly release → 在 app 内检查到 #P1
- [ ] [0.12.0-QA-A-001] 手动触发 semver workflow → 生成 `v0.12.0` release → 旧版 app 启动后能正确识别为新版本 → 走完下载 + 替换流程 → 新版 app 启动 → Accessibility 权限**形式化保留**（系统设置里仍显示已授权，可通过 `tccutil` 或 `sqlite3 ~/Library/Application Support/com.apple.TCC/TCC.db` 验证）#P1
- [ ] [0.12.0-QA-A-002] DMG 首次下载后 Gatekeeper 不拦截（双击直接打开，非「右键 → 打开」），继承自 v0.11.0-QA-A-002 #deferred #P1
- [ ] [0.12.0-QA-A-003] 重复运行「检查更新」不会刷屏 / 不会重复下载同版本 / 不会忽略用户主动重置（v0.11.0-QA-A-003 regression check，签名升级不影响此行为）#P1
- [ ] [0.12.0-QA-A-004] 60 次/小时限流边界：mock API 返回 `403 X-RateLimit-Remaining: 0` 时 app 提示「检查过于频繁，请稍后重试」而非永久拒服务（v0.11.0-QA-A-004 regression check）#P1
- [ ] [0.12.0-QA-A-005] helper 失败路径：mock 替换失败 → 主 app 检测到 `update-error.log` → 启动时弹「上次更新失败」通知，旧版继续运行不崩（v0.11.0-QA-A-005 regression check；helper 现在 Developer ID 签名，失败处理路径不变）#P1
- [ ] [0.12.0-QA-A-006] TCC 权限形式化断言（v0.12.0 验收核心）：旧版 app 已授权 Accessibility → 触发更新 → 安装新版 → 通过 `tccutil` / `sqlite3 ~/Library/Application Support/com.apple.TCC/TCC.db` 查新版 app 的授权状态（service = kTCCServiceAccessibility / kTCCServiceScreenCapture / kTCCServicePostEvent，client = `com.taobe.quotabar`），断言 auth_value = 2（allowed）而非 0（denied）#P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
