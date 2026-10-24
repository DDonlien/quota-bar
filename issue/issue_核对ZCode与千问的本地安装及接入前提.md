# 核对ZCode与千问的本地安装及接入前提

- ID：`migration-1813617627ae`。
- 类型：`SEC`。
- 状态：已确认约束 / 状态待核对（原文未单列完成状态）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`；标题路径：任务清单 / Phase - v0.4.0 - 新 Provider 接入（zcode / 千问 / 其他）。

## 当前需求与范围

> 用户电脑实测已装：
> - `/Applications/ZCode.app`（bundle id `dev.zcode.app`、version 3.1.2，智谱 BigModel Z Code 桌面 IDE），运行时主进程 + `zcode-cli` 进程在跑；
> - 千问桌面 App 未在 `/Applications`、`~/Applications`、`~/Library/Application Support` 找到，等用户确认实际安装位置。
>
> zcode 是 opencode 的 fork/skin（用 `https://opencode.ai/config.json` schema），走 anthropic 兼容 API；
> 凭证、配置、套餐额度本地缓存统一在 `~/.zcode/v2/` 目录下。

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
