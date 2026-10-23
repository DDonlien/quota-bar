# UI-B：核心组件实现

- ID：`migration-936bad7e025e`。
- 类型：`UI`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`web/REQUIREMENTS.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`；标题路径：任务清单 / Phase - v0.1.0 - 主页首版 / UI-B：核心组件实现。
- 原稳定 ID：`0.1.0-UI-B-000`, `0.1.0-UI-B-001`, `0.1.0-UI-B-002`, `0.1.0-UI-B-003`, `0.1.0-UI-B-004`, `0.1.0-UI-B-005`, `0.1.0-UI-B-006`, `0.1.0-UI-B-007`, `0.1.0-UI-B-008`, `0.1.0-UI-B-009`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.1.0-UI-B-000] `MenuBarMockup.astro`：纯 CSS/HTML 还原 macOS 26 菜单栏横条 + dropdown，支持 `hero` / `standalone` 两种 variant #UI
- [x] [0.1.0-UI-B-001] 菜单栏 vertical progress bar 组：6 根 bar，高度 = 剩余比例，呼吸循环动画，相位错开 #UI
- [x] [0.1.0-UI-B-002] dropdown 面板：6 个 provider 区块，每块含状态点 / 名称 / 档位 / 价格 / 多条进度条 #UI
- [x] [0.1.0-UI-B-003] 状态色规则与 `QuotaModels.swift` 一致：>0.3 绿 / ≤0.3 橙 / =0 红 #UI
- [x] [0.1.0-UI-B-004] `Nav.astro`：sticky 顶栏，logo + 锚点链接 + GitHub + 下载按钮 #UI
- [x] [0.1.0-UI-B-005] `Hero.astro`：首屏双栏，左文案 + 双 CTA，右 MenuBarMockup（hero variant） #UI
- [x] [0.1.0-UI-B-006] `ProviderGrid.astro`：6 家核心 provider 卡片网格 + 渠道 chip #UI
- [x] [0.1.0-UI-B-007] `Features.astro`：4 个深度卖点卡片（菜单栏即进度条 / 装上即用 / 精准额度 / 四渠道覆盖） #UI
- [x] [0.1.0-UI-B-008] `Showcase.astro`：dropdown 放大图 + 工作原理三步 + 隐私声明 #UI
- [x] [0.1.0-UI-B-009] `Footer.astro`：版权 + 免责声明（开源、非官方、本地读取） + 链接 #UI

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
