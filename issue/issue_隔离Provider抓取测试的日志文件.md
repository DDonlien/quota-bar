# 隔离Provider抓取测试的日志文件

- ID：`0.10.0-INVESTIGATE-A-004`。
- 类型：`ARCH`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: dropdown「未获取到授权」误报 + 授权补救优先级规则重新定义。
- 原稳定 ID：`0.10.0-BUG-A-020`, `0.10.0-ARCH-L-003`, `0.10.0-INVESTIGATE-A-004`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.10.0-BUG-A-020`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.10.0-INVESTIGATE-A-004`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.10.0-BUG-A-020-ARCH-dropdown-rules-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：sub/main: dropdown「未获取到授权」误报 + 授权补救优先级规则重新定义。
- 同源任务：[纠正AntigravityHTTP500被误报为待配置](issue_%E7%BA%A0%E6%AD%A3AntigravityHTTP500%E8%A2%AB%E8%AF%AF%E6%8A%A5%E4%B8%BA%E5%BE%85%E9%85%8D%E7%BD%AE.md)、[按已实现能力确定Provider授权补救层级](issue_%E6%8C%89%E5%B7%B2%E5%AE%9E%E7%8E%B0%E8%83%BD%E5%8A%9B%E7%A1%AE%E5%AE%9AProvider%E6%8E%88%E6%9D%83%E8%A1%A5%E6%95%91%E5%B1%82%E7%BA%A7.md)。

## 当前需求与范围

共同范围与完整历史见[纠正AntigravityHTTP500被误报为待配置](issue_%E7%BA%A0%E6%AD%A3AntigravityHTTP500%E8%A2%AB%E8%AF%AF%E6%8A%A5%E4%B8%BA%E5%BE%85%E9%85%8D%E7%BD%AE.md)；本文件保留以下独立目标的原文。

- [x] [0.10.0-INVESTIGATE-A-004] 顺手核实了一处无关但真实存在的问题：跑 `swift test` 时，`ProviderFetchStrategyTests.swift` 里的测试 stub（"quota-source"/"plan-filler"）没有给 `ProviderCheckLog` 注入独立临时文件，写穿了真实用户机器上的 `~/Library/Application Support/QuotaBar/provider-check.log`——已用 `spawn_task` 单独派发（`task_9a5b6e04`），后续由用户在独立会话里跑完：`FetchPipeline` 新增 `checkLog: ProviderCheckLog = .shared` 注入点，测试改成显式构造独立临时文件的 `ProviderCheckLog`，删掉了原来靠 `ProviderCheckLog.resetForTesting()` 直接清空 `.shared` 内存缓冲区的黑魔法；验证过重跑测试后真实日志文件不再新增任何测试数据 #P2

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

原迁移条目的历史Comments完整保留于[同源历史](issue_%E7%BA%A0%E6%AD%A3AntigravityHTTP500%E8%A2%AB%E8%AF%AF%E6%8A%A5%E4%B8%BA%E5%BE%85%E9%85%8D%E7%BD%AE.md#comments)，不从历史日志新增完成标记。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
