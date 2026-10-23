# site/main: Terms 商业条款更新 + 联系邮箱统一

- ID：`0.3.1-CONTENT-A-000`。
- 类型：`CONTENT`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`site/REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.3.1 - Creem 复审前的法律页面 SSR 化 + Terms 内容更新 + 联系邮箱统一 / site/main: Terms 商业条款更新 + 联系邮箱统一。
- 原稳定 ID：`0.3.1-CONTENT-A-000`, `0.3.1-CONTENT-A-001`, `0.3.1-CONTENT-A-002`, `0.3.1-QA-A-000`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.3.1-CONTENT-A-000] `dict.ts` 的 `terms.s2.body1`（中英文）重写：去掉"pricing ... still being finalized"占位语言，改为陈述跟 `Pricing.astro` 一致的已确定事实——自行编译永远免费不受付费限制；官方版一次性购买（不是订阅），价格含未来更新；Beta 期间免费，Beta 下载者上线时自动获得完整 Pro 授权。授权激活的具体机制（一份授权覆盖几台 Mac、丢失后如何找回）仍未定案，如实写"会在付费版上线前公布"，不编造具体数字。加一句 vendor-中立的结算声明（支付服务商作为 Merchant of Record 负责支付/税费/退款），不点名 Creem——支付渠道本身还没最终决定
- [x] [0.3.1-CONTENT-A-001] 联系邮箱统一改为 `taobe@ddonlien.com`：`Footer.astro` 版权行、`dict.ts` 的 `privacy.s7.body1`/`terms.s7.body1`/`pricing.support.hint`（中英文共 6 处），以及 `Pricing.astro` 里对应的静态 fallback 文案。`grep -rn "hi@quotabar\.app\|taobe@freshli4\.com"` 确认全站无残留，新邮箱精确命中 8 处
- [x] [0.3.1-CONTENT-A-002] Privacy/Terms 的 "Last updated" 日期（中英文共 4 处）从 2026-07-18 推进到 2026-07-19，跟本次正文变更保持一致（两个页面各自的 `s6`/`terms.s6` 章节本来就承诺"内容有实质变化会更新这个日期"）
- [x] [0.3.1-QA-A-000] `npm run build` 通过；直接 grep 构建产物 `dist/privacy/index.html`/`dist/terms/index.html`（原始响应 HTML，不是渲染后 DOM）确认正文段落已经是真实文字、不再是空 `<h2></h2>`/`<p></p>`；Browser 面板跑 `astro dev` 实测 `/privacy`、`/terms`、`/` 三个页面，`get_page_text` 逐段核对中文 locale 下的正文（含新的 terms.s2 商业条款）都正确显示；`document.querySelector` 核对 Footer 版权行、Pricing 支付提示、Privacy/Terms 联系方式四处邮箱均为 `taobe@ddonlien.com`

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
