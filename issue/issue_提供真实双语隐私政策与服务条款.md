# 提供真实双语隐私政策与服务条款

- ID：`0.3.0-CONTENT-A-000`。
- 类型：`CONTENT`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`site/REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.3.0 - 开源/付费双轨定价卡 + Creem 合规必需页面 / site/main: Privacy Policy + Terms of Service + 页脚死链接修复。
- 原稳定 ID：`0.3.0-CONTENT-A-000`, `0.3.0-CONTENT-A-001`, `0.3.0-FE-C-000`, `0.3.0-QA-B-000`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.3.0-CONTENT-A-000] 新增 `site/src/pages/privacy.astro`：真实 Privacy Policy 内容（7 节，中英双语 i18n key），如实描述 Quota Bar 的数据处理方式——调研确认 macOS App 无任何 telemetry SDK、无账号系统，Provider 凭证只用于直连各服务商自己的官方 API，从不上传到 Quota Bar 自己的服务器；App 唯一会碰的自有域名请求是 v0.14.0 新增的匿名更新检查；官网本身无第三方 analytics/广告追踪/追踪 Cookie，仅用 localStorage/sessionStorage 做语言偏好和下载链接缓存两个功能性用途
- [x] [0.3.0-CONTENT-A-001] 新增 `site/src/pages/terms.astro`：真实 Terms of Service 内容（7 节，中英双语），软件按现状提供、免责声明、开源自行编译与官方签名版的关系（官方版定价/授权细节明确写"待最终确定"，不提前承诺具体条款）、合理使用范围
- [x] [0.3.0-FE-C-000] `Footer.astro`：`footer.link.privacy`/`footer.link.terms` 改为真实 `href="/privacy"`/`href="/terms"`；移除整个 PRODUCT 列（`footer.link.compare`/`footer.link.manage`/`footer.link.affiliate`/`footer.col.product` 连同 i18n key 一并删除——对应功能不存在，遵循 Creem 审核意见"移除"而非做假页面），页脚从两列变一列（LEGAL）
- [x] [0.3.0-QA-B-000] `npm run build` 通过，生成 `/privacy/index.html`、`/terms/index.html`；用 Browser 面板跑 `astro dev` 实测：中文（默认）和英文（切 locale）两个语言版本内容都完整渲染、7 个小节标题和正文都对得上；`read_page` 确认页脚只剩 LEGAL 一列、Privacy/Terms 是真实 `/privacy`/`/terms` 链接，点击 Terms 链接真的跳转到 Terms 页且标题正确；全站搜索确认不再有任何 `href="#"` 死链接

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
