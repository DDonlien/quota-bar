# 明确试用授权与Blob发布链路的产品决策

- ID：`migration-a56852fe5c89`。
- 类型：`SEC`。
- 状态：已确认约束 / 状态待核对（原文未单列完成状态）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.15.0 - 7 天试用 + Creem 授权激活 + 发布链路迁移到 Vercel Blob。

## 当前需求与范围

> **背景**：官网定价已经在 v0.3.2 改成"$4.99 一次性购买 + 7 天免费试用"，但 App 侧完全没有对应实现——
> `ActivationSettingsView` 只是个 UI 空壳（存一个 `activationEmail`，`isActivated` 硬编码 `false`），既没有
> 试用期概念也没有任何授权校验，官网也还没有真正的购买入口。本 phase 把这条链路补齐。
>
> **用户提供的 Creem 信息**：产品 ID `prod_4NN9fUOfr2BU4L5NbaqFmo`，checkout 链接
> `https://www.creem.io/payment/prod_4NN9fUOfr2BU4L5NbaqFmo`，以及官方 embed.js 按钮片段。
>
> **两个关键产品决策（跟用户确认过）**：
> 1. **试用到期只锁自动更新，额度功能照常**。理由：项目开源、任何人都能免费自行编译，硬锁核心功能会让
>    付费版反而不如免费自编译版好用；付费真正卖的是"签名公证 + 自动更新 + 一键安装"这份省事，所以惩罚
>    点落在便利性上才自洽。
> 2. **构建包托管走 Vercel Blob**（GitHub Action 构建完上传，`/api/download-latest` 改为从 Blob 取），
>    GitHub Release 只保留源码。
>
> **架构约束**：Creem 的 license 校验 API 需要 `x-api-key`（密钥），绝对不能进客户端二进制——必须在
> Vercel 上加一层服务端代理，App 只跟自己的域名说话。
>
> **已知破坏性影响（用户已知悉并接受）**：GitHub Release 不再带 dmg 后，所有已安装的 ≤v0.10.1 客户端
> 会永久失去自动更新——旧客户端是"GitHub 直连成功就不再走 Vercel 兜底"，而 GitHub 侧会返回"有 release
> 但没有 .dmg 资产"，`pickUpdate` 因此永远返回 nil。当前处于 Beta、实际用户仅开发者本人，判断可接受；
> 迁移后需要手动安装一次新包才能重新接上更新链路。
>
> **需要用户在外部系统完成的前置动作（Agent 无法代劳，涉及密钥/后台设置）**：
> - Creem 后台确认 `prod_4NN9fUOfr2BU4L5NbaqFmo` 已开启 **License Keys**（未开启则买家收不到 key，整套激活无从谈起）
> - Vercel 项目 Settings → Environment Variables 添加 `CREEM_API_KEY`
> - Vercel 开通 Blob 存储，并把 `BLOB_READ_WRITE_TOKEN` 同时配到 Vercel 环境变量和 GitHub Actions Secrets

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
