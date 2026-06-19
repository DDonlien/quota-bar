# Agent 协作规范

本文件分为“标准内容”和“项目专用内容”。除非用户明确要求修改协作规范，否则只允许在“项目专用内容”下补充或调整，不修改标准内容。

## 标准内容

### 0. 文档缺失时先创建

- 如果当前仓库或当前子功能根目录没有 `AGENTS.md`，先阅读 `agent-template/AGENTS.md`，并在根目录创建属于该目录自己的 `AGENTS.md`。
- 如果没有 `REQUIREMENTS.md`，先阅读 `agent-template/REQUIREMENTS.md`，并在根目录创建属于该目录自己的 `REQUIREMENTS.md`。
- 如果没有 `DESIGN.md`，先阅读 `agent-template/DESIGN.md`，并在根目录创建属于该目录自己的 `DESIGN.md`。
- 如果没有 `README.md`，先阅读 `agent-template/README.md`，并在根目录创建属于该目录自己的 `README.md`。
- `AGENTS.md`、`REQUIREMENTS.md`、`DESIGN.md` 和 `README.md` 默认使用中文书写；除非用户特别说明，或术语、代码符号、专有名词本身应使用英文。
- `agent-template/` 中的文件只保留模板内容；项目真实说明写在根目录文档中。
- 上述创建的文件名必须全大写，其中 `AGENTS` 和 `REQUIREMENTS` 使用复数。
- `agent-template` 作为模板目录保留时，不应保留其自身 `.git` 等嵌套仓库资产。

### 1. 每次任务开始前

- 确认当前分支是用户希望工作的分支；分支切换由用户手动完成，Agent 不主动切换分支。
- 如果当前目录属于 git 仓库，先执行 `git pull`，确保任务基准更新到最新。
- 如果 `git pull` 失败、发生冲突，或提示需要人工处理，在日志和交付说明中记录原因。
- 阅读用户本次原始 prompt。
- 阅读当前目录适用的 `AGENTS.md`、`README.md`、`REQUIREMENTS.md`、`DESIGN.md` 和 `agent-log/` 中的相关日志。
- 检查 `REQUIREMENTS.md`，确认用户本次需求是否匹配已有需求、子需求、验收项或已标记的阻塞项。
- 如果仓库内有父级与子级 `AGENTS.md`，从父到子依次阅读；更具体目录的规则优先，但不得违反父级标准内容和用户明确要求。

### 2. 每次任务执行中

- 为每次任务执行创建一条新的执行日志，放在当前适用目录的 `agent-log/`。
- 日志命名规则：`YYYYMMDDHHMMSS-utcpN-model.md` 或 `YYYYMMDDHHMMSS-utcnN-model.md`。
- `utcpN` 表示 UTC 正偏移，`utcnN` 表示 UTC 负偏移；不要在文件名中使用 `+` 或 `-`。
- 使用任务完成时间作为日志文件名中的时间。
- 如果用户在同一次执行中补充或修正要求，把补充 prompt 原文和时间追加到同一条日志。
- 每条日志记录一次任务执行中的对话、行动和总结，并包含用户原始 prompt、启动运行时的分支和版本、开始时间、结束时间、是否提交、已阅读上下文、完成工作、需求更新、设计更新、验证方式和备注。

### 3. REQUIREMENTS.md 的维护标准

- `REQUIREMENTS.md` 使用 Obsidian 原生友好的 Markdown 格式。
- 不使用复杂表格，不使用 YAML 字段。
- 通过标题分级拆分阶段、模块和主题。
- 可执行需求必须有稳定 ID。
- 任务状态使用原生 Markdown checkbox：`- [ ]` 表示未完成，`- [x]` 表示已完成。
- 阻塞、延后、取消在任务后追加 `#blocked`、`#deferred` 或 `#cut`。
- 不静默删除需求；取消的需求保留并标记 `#cut`，附简短原因。
- 每次任务完成后，把已经完成的需求、子需求或验收项勾选为完成。

### 4. README.md 的维护纪律

- `README.md` 记录系统、仓库或应用的整体说明，而不是视觉规范或具体任务清单。
- 当系统范围、仓库结构、应用能力、运行方式或用户入口发生变化时，同步更新 `README.md`。
- 具体待办、验收项和任务状态写入 `REQUIREMENTS.md`。

### 5. DESIGN.md 维护纪律

- `DESIGN.md` 只记录视觉设计系统，不记录系统架构、数据模型、产品路线图或任务列表。
- 当品牌视觉、UI 风格、设计 token、组件外观、布局原则或可访问性规则变化时，同步更新 `DESIGN.md`。
- 如果视觉风格发生大幅改变，旧版本内容应归档到 `archive/design/`。

### 6. 父子文档关系

- 如果仓库内有明显的多个子功能、子应用、工具包或独立模块，应在根目录和每一层子功能根目录创建一套文档。
- 根目录 `README.md` 描述全局目标、共享约束、目录索引和跨子功能关系。
- 当任务只影响某个子功能时，优先更新该子功能文档；如影响全局规则或跨子功能关系，再同步更新父级文档。
- `reference/`、`references/`、`third_party/`、`vendor/`、`examples/` 等外部参考目录不纳入项目自身范围，除非用户明确要求整理或改造。

### 7. 工程默认规则

- 优先遵循仓库已有技术栈、目录结构、命名和风格。
- 保持改动聚焦在用户请求范围内。
- 不覆盖用户改动，不回滚无关文件。
- 行为、共享逻辑或用户可见流程发生变化时，补充或更新测试。
- 交付前运行相关验证命令；如果无法运行，说明原因并记录剩余风险。
- 搜索优先使用 `rg`。
- 手工编辑文件优先使用补丁方式，避免产生无关格式化或大范围重写。

## 项目专用内容

### 项目概况

- 项目名称：Quota Bar
- 产品简介：macOS 菜单栏下拉应用，用于展示 AI 订阅费用与额度状态。
- 主要用户：需要集中查看多项 AI 服务订阅与额度的个人用户。
- 当前阶段：界面原型阶段已完成；现进入功能核心阶段，目标是将静态 UI 升级为自动探测并展示真实 AI 订阅额度的菜单栏应用。

### 技术栈与命令

- 技术栈：Swift Package Manager、SwiftUI、AppKit、macOS 26。
- 开发命令：`cd quota-bar && swift run`
- 测试命令：当前暂无自动化测试。
- 构建命令：`cd quota-bar && swift build`
- 应用打包：`cd quota-bar && ./scripts/build-app.sh`

### 文档入口

- 项目说明：`README.md`
- 需求追踪：`REQUIREMENTS.md`
- 视觉规范：`DESIGN.md`
- 执行日志：`agent-log/`

### 目录索引

- `quota-bar/`：当前 macOS 菜单栏应用原型（SwiftPM 包，Package.swift 与 Sources/QuotaBar 目录遵循 PascalCase 硬约束）。
- `agent-template/`：Agent 协作文档模板。
- `reference/`：参考资料，不默认视为项目代码。

### 项目特殊约束

- 语言与命名：面向用户的文案默认中文；Swift 类型、属性、文件名沿用英文。
- 设计原则：优先贴近 macOS 26 Liquid Glass 风格，保持菜单栏下拉面板的轻量、紧凑和可扫读。
- 架构限制：实际额度、订阅同步和数据存储尚未定义；当前 UI 使用静态占位数据。
