# website/main: 组装主页并接入下载链接

- ID：`0.1.0-FE-B-000`。
- 类型：`FE`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`site/REQUIREMENTS.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`；标题路径：任务清单 / Phase - v0.1.0 - 主页首版 / website/main: 组装主页并接入下载链接。
- 原稳定 ID：`0.1.0-FE-B-000`, `0.1.0-FE-B-001`, `0.1.0-FE-B-002`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.1.0-FE-B-000] `index.astro` 组装所有 section，Hero / Providers / Features / Showcase / Footer 顺序 #FE
- [x] [0.1.0-FE-B-001] 下载按钮客户端 JS：调 GitHub `/releases?per_page=1` 取最新 nightly DMG 直链，30 分钟 sessionStorage 缓存，失败 fallback 到 releases 列表页 #FE
- [x] [0.1.0-FE-B-002] 所有 `data-download` 链接共享同一份 release 解析逻辑 #FE

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
