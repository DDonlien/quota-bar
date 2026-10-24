# 统一官网联系邮箱

- ID：`0.3.1-CONTENT-A-001`。
- 类型：`CONTENT`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`site/REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.3.1 - Creem 复审前的法律页面 SSR 化 + Terms 内容更新 + 联系邮箱统一 / site/main: Terms 商业条款更新 + 联系邮箱统一。
- 原稳定 ID：`0.3.1-CONTENT-A-000`, `0.3.1-CONTENT-A-001`, `0.3.1-CONTENT-A-002`, `0.3.1-QA-A-000`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.3.1-CONTENT-A-000`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.3.1-CONTENT-A-001`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.3.1-CONTENT-A-000-CONTENT-terms-business-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：site/main: Terms 商业条款更新 + 联系邮箱统一。
- 同源任务：[按已确定定价更新商业条款及日期](issue_%E6%8C%89%E5%B7%B2%E7%A1%AE%E5%AE%9A%E5%AE%9A%E4%BB%B7%E6%9B%B4%E6%96%B0%E5%95%86%E4%B8%9A%E6%9D%A1%E6%AC%BE%E5%8F%8A%E6%97%A5%E6%9C%9F.md)。

## 当前需求与范围

共同范围与完整历史见[按已确定定价更新商业条款及日期](issue_%E6%8C%89%E5%B7%B2%E7%A1%AE%E5%AE%9A%E5%AE%9A%E4%BB%B7%E6%9B%B4%E6%96%B0%E5%95%86%E4%B8%9A%E6%9D%A1%E6%AC%BE%E5%8F%8A%E6%97%A5%E6%9C%9F.md)；本文件保留以下独立目标的原文。

- [x] [0.3.1-CONTENT-A-001] 联系邮箱统一改为 `taobe@ddonlien.com`：`Footer.astro` 版权行、`dict.ts` 的 `privacy.s7.body1`/`terms.s7.body1`/`pricing.support.hint`（中英文共 6 处），以及 `Pricing.astro` 里对应的静态 fallback 文案。`grep -rn "hi@quotabar\.app\|taobe@freshli4\.com"` 确认全站无残留，新邮箱精确命中 8 处

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

原迁移条目的历史Comments完整保留于[同源历史](issue_%E6%8C%89%E5%B7%B2%E7%A1%AE%E5%AE%9A%E5%AE%9A%E4%BB%B7%E6%9B%B4%E6%96%B0%E5%95%86%E4%B8%9A%E6%9D%A1%E6%AC%BE%E5%8F%8A%E6%97%A5%E6%9C%9F.md#comments)，不从历史日志新增完成标记。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
