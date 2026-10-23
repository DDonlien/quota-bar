# website/main: 建立 Astro 站点骨架

- ID：`0.1.0-FE-A-000`。
- 类型：`FE`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`site/REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.1.0 - 主页首版 / website/main: 建立 Astro 站点骨架。
- 原稳定 ID：`0.1.0-FE-A-000`, `0.1.0-FE-A-001`, `0.1.0-FE-A-002`, `0.1.0-FE-A-003`, `0.1.0-FE-A-004`, `0.1.0-FE-A-005`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.1.0-FE-A-000] 初始化 Astro 5.x 项目（package.json / astro.config.mjs / tsconfig.json） #FE
- [x] [0.1.0-FE-A-001] 配置静态输出 `output: 'static'`，site URL 指向 `quotabar.ddonlien.com` #FE
- [x] [0.1.0-FE-A-002] 创建 favicon.svg（三段进度条 logo） #FE
- [x] [0.1.0-FE-A-003] 创建 `.gitignore`（dist / node_modules / .vercel / .astro） #FE
- [x] [0.1.0-FE-A-004] `npm install` 成功，无致命依赖错误 #FE
- [x] [0.1.0-FE-A-005] `npm run build` 成功，产出 `dist/`（约 76KB） #FE

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
