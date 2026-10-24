# 精简开源卖点并明确付费专属功能

- ID：`0.3.3-CONTENT-A-000`。
- 类型：`CONTENT`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`site/REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.3.2 - 定价叙事从"限时免费"改为"$4.99 一次性购买 + 7 天试用" / site/main: 开源卡精简为 2 条 bullet，付费卡改为"继承开源 2 条 + 3 条付费专属"。
- 原稳定 ID：`0.3.3-CONTENT-A-000`, `0.3.3-CONTENT-A-001`, `0.3.3-QA-A-000`；不改写或重编号这些既有 ID。

## 当前需求与范围

> **背景**：用户看着实际渲染截图指出两张卡片的 bullet 列表应该有结构关系——开源卡只留 2 条最核心的，
> 付费卡展示"开源卡的全部内容 + 付费专属的增量"，而不是像之前那样各自维护一份互相独立、有重叠但不完全
> 一致的 4 条列表（旧付费卡的"无限服务追踪"/"Swift 原生级性能"其实开源版也有，不是真正的付费专属项，
> 这次一并借机去掉）。

- [x] [0.3.3-CONTENT-A-000] 开源卡 bullet 从 4 条砍到 2 条，只保留 `pricing.opensource.bullet.source`（完整无限制源代码）和 `pricing.opensource.bullet.community`（GitHub Issues 社区支持）；删掉 `pricing.opensource.bullet.features`（"功能与官方版一致"——一旦付费卡结构上继承开源卡内容，这句话变成多余的自我指涉）和 `pricing.opensource.bullet.compile`（"自行编译自行签名"，跟保留的"源代码"一条语义重叠），连同 i18n key 一起删除
- [x] [0.3.3-CONTENT-A-001] 付费卡 bullet 改成 5 条：前 2 条直接复用 `pricing.opensource.bullet.source`/`pricing.opensource.bullet.community` 这两个 key（不新建重复文案，避免以后开源卡文案改了付费卡忘记同步），后 3 条是新的付费专属项——`pricing.bullet.autoupdate`（自动更新）、`pricing.bullet.oneclick`（一键安装）、`pricing.bullet.support`（优先技术支持，沿用原 key）；删掉不再是真正付费专属的 `pricing.bullet.unlimited`（无限服务追踪）和 `pricing.bullet.swift`（Swift 原生级性能——这两者开源自编译版本功能上其实完全一样，写成付费专属是误导），`pricing.bullet.updates`（"无限会话及后续更新"）用更明确的 `pricing.bullet.autoupdate` 取代
- [x] [0.3.3-QA-A-000] `npm run build` 通过；全文 grep 确认删除的 5 个 key 无残留引用；Browser 面板 `get_page_text` 完整读出两张卡片渲染后的 bullet 列表，逐条核对跟预期一致（开源卡 2 条、付费卡 5 条且前 2 条与开源卡文案完全相同）——本次 Browser 面板的 `getBoundingClientRect`/`window.innerWidth` 精确几何读取再次失效（返回 `width:66`/`innerWidth:0` 等明显不合理的值，多个 tab 结果一致但截图也变全黑，判断是同一个 session 内已知的环境问题），`get_page_text` 不受影响、内容校验仍然可靠；等高对齐机制（`align-items: stretch` + `.pricing__cta { margin-top: auto }`）本身未改动，且上一版本改动（4 vs 4 条 bullet）时已用几何数据验证过有效

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
