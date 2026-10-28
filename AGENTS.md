---
target-repo-type: app
language: zh-CN
template-version: "v2.0.5-261028-071052"
---

# 通用规则

本部分适用于项目维护；技术栈规则只在涉及对应技术时生效，项目专用规则按实际情况填写。用户最新明确要求优先于模板和历史资料。

## 任务开始与事实来源

1. 先确认用户指定的项目、当前目录、适用规则和已有改动，再定位目标文件。父子 `AGENTS.md` 从父到子阅读；子规则补充局部约束，不重复通用规则。
2. 按任务需要阅读相关 Issue、实现契约、调用关系、架构、Schema 和设计文档，不全量阅读仓库或历史记录。`reference/`、外部仓库、示例和归档默认只作参考，不纳入修改范围。
3. 当前事实以用户最新要求、有效 Issue 和实际文件为依据；历史 Comments 与档案用于追溯。区分已确认事实、推断和待验证项，不凭猜测补齐未知信息；冲突和取舍要明确说明。
4. 普通任务不检查远端模板版本、不自动同步或升级模板。只有用户明确要求维护协作规范或同步模板时才处理 `source`；同步保留项目专用规则和已有改动。
5. 缺少文档不构成普通任务的阻塞。只在任务需要时创建有实际内容的文档，不为目录整齐补空的 `AGENTS.md`、`README.md`、`DESIGN.md` 或独立任务系统。

## 代码与改动范围

1. 只实现当前问题所需的最小改动，遵循现有技术栈、架构、目录和命名，优先复用已有机制。不添加推测性功能、预留扩展点、无需求的兼容分支或额外状态来源。
2. 清理限于当前任务涉及的死代码、重复逻辑、无效分支和冗余状态；不借重构扩大范围，不改写无关模块或用户已有改动。
3. 信任已明确的内部契约与框架保证，只在真实边界和已确认故障模式下做必要校验。不为假想场景重复添加回退、防御和空值检查。
4. 不吞掉错误，不用宽泛 `catch`、`rescue nil` 或静默默认值掩盖失败；无法恢复时保留定位上下文并明确失败。
5. 一次性操作不单独引入抽象；只有实际复用、稳定边界或能降低当前复杂度时才增加辅助层。注释解释意图；参数默认值、公式或上限变化时同步其效果和范围说明。
6. 重命名、移动和结构调整后，用 `rg` 等检查受影响的引用、链接、脚本参数和示例。只更新本任务影响到的文档，不为每次任务刷新全部文档。

## Headless、工具与检查边界

1. 优先通过文件、CLI、静态分析和其他 Headless 渠道工作，保证用户继续使用系统。不得为后台任务抢焦点、弹窗或擅自操作用户正在使用的应用。
2. 只检查本次实际操作所需的工具和权限；无关工具不可用不阻塞独立工作。Blender 与 UE Blueprint 按以下例外执行：
   - Blender 相关任务始终要求 Blender MCP 可用；不可用时停止依赖它的工作并报告，不自行换成其他渠道。
   - UE Blueprint 任务要求可操作目标 Blueprint 的 UE 编辑器 MCP 可用；操作前确认连接及所需读写能力。UE 非 Blueprint 的代码、配置和文档任务不一律要求 MCP。
   - Rider MCP 始终按任务需要调用，例如处理断点继续、读取断点上下文、编译或 build 信息；不作为所有 UE 或其他任务的固定前置条件。
   - Godot 优先直接修改代码并使用项目支持的 Headless 命令；不预设 MCP 必需，遇到具体限制再处理。
3. 先定义本次改动的成功标准。AI 主要检查代码、配置、数据和引用是否正确，按风险运行必要的已有测试、编译或静态检查；可逆、低影响改动不为形式新增测试，不重复执行无新信息的检查。
4. 视觉效果、交互体验、Playtest 和大量自动化验收默认由用户负责。未经当前任务明确要求，不使用 GUI / Computer Use 做视觉验收，不自行扩展为大批自动化验收，不为验收生成临时资产或发布包。
5. 实现、静态检查、测试、编译、运行时验证和用户验收分别记录。只有实际执行并取得结果的检查才能写为通过；编译或结构读回不代表视觉、交互或用户验收通过。
6. 工具不可用或权限受限时，报告具体动作、目标、原因、已完成范围，以及动作未执行、被拒绝、待处理或结果不明的状态；继续独立工作，不绕过权限。结果不明时先核实，不盲目重试。

## 版本管理与混合仓库

1. 按目标文件确认版本管理归属。一个项目可以同时使用 Git、Perforce 或更多系统；不能因发现 `.git` 就把所有文件当成 Git 管理，也不能因使用 Perforce 就忽略 Git 状态。同一文件受多个系统管理时，分别检查相关约束。
2. 检查限于当前工作副本、本任务目标路径及必要依赖，不递归检查其他 worktree、参考仓库或其他项目，不扫描整个 Perforce 服务端。遇到归属不明、冲突或锁定时先定位相关文件。
3. Git 只做必要的本地检查：确认仓库、当前分支 / worktree，以及目标文件的工作区和暂存改动；保留用户和其他任务的改动。普通任务不自动 fetch、pull、merge、rebase、切换分支或同步远端；确需远端基准时说明需要，并按用户授权执行。
   同步边界：仅处理任务规定的版本管理对象与资产范围；混合 Git / Perforce 不联动无关系统。Git 仅在任务需要且授权范围内同步当前工作分支与其已配置 upstream，不顺带 fetch 全部分支，不切换、同步或合并 main / mainline 或其他分支，未配置 upstream 时不猜测。Git 提交整合是分支级操作，不按单文件执行 pull；同步若会涉及任务范围外内容或本地未提交改动，先报告影响并按实际需要确认，不擅自覆盖、stash 或 reset。用户另行明确要求跨分支同步时按该授权执行；普通任务不因此新增先 pull / fetch 的前置步骤。
4. 未经明确授权，不创建 branch 或 worktree，不切换当前 checkout 的分支，不移动、删除或重定位 worktree。用户指定目标名称、feature 或目录不等于授权创建；已有目标可在用户指定范围内通过进入其现有目录使用，不存在时先说明。
5. 不擅自执行 `reset --hard`、`clean`、`restore`、覆盖式 checkout、强删分支或其他覆盖 / 回滚操作。结构示例只是布局说明，不授权创建、迁移或重命名实际工作区。
6. 只有目标文件涉及 Perforce 时，才确认对应连接、用户、client、Root / Stream 与文件映射，并对目标路径检查 opened、锁定和 pending change。未确认归属前不修改文件，也不重归类其他任务已 opened 的文件。
7. 需要修改 Perforce 文件时，按既有项目规则创建或复用本任务独立的 pending change；description 说明目的、范围和检查状态。同一任务复用该 change，结束时仅检查相关文件与 change，不把无关文件收入其中。
8. 默认不执行 Git commit、push、tag、PR 创建或 Perforce submit、shelve 等交付动作；当前任务必须有对应明确授权。单独的全局每日 commit 或用户手动 commit 流程不构成本任务提交授权。
9. 用户授权提交时，只纳入本任务范围并检查相应 diff / opened；commit、push、submit、发布分别报告，不能互相代替。授权 push 不得扩展为改写历史或操作其他远端。
10. 已获授权的远端操作复用当前配置与安全凭证，不静默修改 remote、认证或传输方式，不在命令、文档、Comments 或输出中暴露 token、cookie、API key 等敏感信息。

## Agent 创建分支与 Issue 关联

1. 本节命名要求只适用于用户明确授权 Agent 创建分支的场景。Agent 可以建议隔离任务，但建议、用户给出名称或本规则本身均不等于创建授权；人工手动创建的分支由人工决定是否遵循。已有分支不追溯重命名，worktree 创建与分支切换仍须明确授权。
2. 使用 `user-name/target-branch-name[/usage-name]`，例如 `taobe/main/feature-name`；末段按实际需要表达功能或用途。名称中的目标分支只是语义标识，实际创建基准以用户授权与 Git 事实为准，不据名称反推真实祖先。
3. 创建前检查完整 Git ref 名称及前缀冲突，例如已有 `taobe/main` 会阻止创建 `taobe/main/feature-name`。遇到冲突先报告，不自动重命名、移动或删除已有分支，也不自行换一个名称创建。
4. 分支用途与 Issue 没有固定的一对一、一对多或多对多约束；一个任务可跨分支和多次提交，分支也可涉及多个任务。按实际改动关联 Issue，不通过分支名推导任务关系。
5. 每次已获授权的提交使用 Summary 首行概括改动，不放 Issue 编号；Detail 正常说明原因、具体改动与必要检查。Detail 后空一行，在整个提交消息末尾统一使用单行 `Issues: issue-00001, issue-00007`；只有一个也写 `Issues: issue-00001`，UID 去重并以逗号加空格分隔。Git 原生只解析 trailer 的键和值，UID 列表及关联语义由本规范约定，不宣称 Git 内建 Issue 关联。
6. Issue UID 在每个仓库内唯一；同一 Git common repository 的所有分支和 worktree 共用命名域，不能按分支或工作副本各自重新起号。`uid` 使用保留前导零的五位十进制字符串，例如 `"00001"`。同一 Issue 延续相同 UID，不同 Issue 不得重号；分配前检查本仓库已有 UID 与并行分配。保留既有 `id`、UID 和历史关联，不截短旧 ID / UUID 生成新 UID，也不因移动或改名重编号。
7. 提交与 Issue 为多对多关联：每个实际相关提交都记录对应 UID，一次提交可关联多个 Issue，不以是否修改 `issue.md` 判断，也不创建或移动原生 `refs/tags`。`commit-related` 反向保存填写时已存在的完整真实 Git hash / P4 changelist，并在对应 Comment 首部引用；保留全部已有真实关联。记录提交自身的 hash 留待下一次实际 Issue 更新补入，不为自引用无限追加提交，不改写历史 commit 消息。

## Issue 维护标准

1. 活动需求、任务、检查与交接统一写入当前工作副本的 `issue/`。标准路径为 `project-name/worktree(如有)/issue/issue_任务描述.md`；没有 worktree 时为 `project-name/issue/...`。`worktree(如有)` 表示已有实际工作区，不要求目录字面名为 `worktree`。
2. 属性统一使用兼容 Obsidian 的 YAML frontmatter，可在模板默认属性上扩展。保留已有 `uid`、`id`、类型、拆分关联及 `parent` 等关系；不因新增 UID 改写旧编号、文件名或引用目标。UID 为仓库内唯一的五位十进制字符串，保留前导零；同一 Git common repository 的分支和 worktree 统一查重，不使用跨仓库共享编号池。
3. 文件名只用原语言的具体任务描述；类型只在 frontmatter 中记录，不加任何版本编号后缀。具体命名与版本记录见下文“Issue 文件命名与版本关联”。
4. `issue/issue_template.md` 是唯一模板文件，`type: template` 表示模板身份。新版默认属性为 `uid`、`type`、`status`、`importance`、`emergency`、`updated-time`、`created-time`、`start-time`、`closed-time`、`created-version`、`closed-version`、`estimated-workhour`、`actual-workhour`、`commit-related`、`tags`。正文仅有 `# Description` 和 `# Comments` 两个一级标题，不为格式补空内容；已有扩展属性继续保留。
5. 开始实现前先搜索已有匹配 Issue。用户提出的核心行为、数据、界面、内容或可感知工程能力应落入最具体的 Issue；一次性解释或咨询不强制创建。归入已有任务或记录已授权的新任务不需要额外确认，也不意味着授权创建分支或 worktree。
6. `Description` 维护具体对象、目标行为、范围、当前事实与阻塞；属性记在 frontmatter。可使用 Markdown 原生语法、子标题、列表、checkbox 和行内图片；子分组只作为 Description 内容渲染，不新增 myIssue 专用分组。实现、检查与用户验收按实际需要表达。
7. `# Comments` 只追加。每条 Comment 用二级标题 `## YYYYMMDD-HHMMSS_Name_Model-Detail`，人类记录省略 Model-Detail；AI 的 Name 是实际执行 Agent；Model-Detail 必须按“厂牌-确切版本-规模/型号档位-推理级别-是否选择加速模式”记录五个维度，例如 `GPT-6.1-SOL-MAX-FAST`，不能用 `GPT`、`GPT-6` 或系列名代替确切版本。仅在有可验证执行元信息时填写；加速维度明确用 `FAST`、`NONFAST`（已核实未选择加速）或 `UNKNOWN`，不得把响应速度、订阅档位、服务优先级当作选择了加速。每个未知维度写 `UNKNOWN` 并在正文说明不可核实，不以当前配置回填历史参数。每次任务执行完成后记录，标题时间为实际记录时间。涉及提交时，在该条开头用 Obsidian 引用格式 `>` 记录真实 Git commit hash / P4 changelist，并汇总到 `commit-related` 列表；同一 Issue 可涉及多个 change。该条末尾用 `>` 引用有来源依据的真实会话深度链接。行内图片使用 `issue/attachment`。Description 维护当前事实，历史 Comment 与来源保留；时间、Agent、模型、提交或原会话无法追溯时说明缺失，不补造，不照抄模板示例，也不把文档迁移对话冒充业务执行对话。
8. `- [ ]` 为未完成，`- [x]` 仅表示该条明确范围已完成；实现、检查、用户验收分别列项。部分子项完成不能勾完父项；待用户验收时应明确保留该状态，不因实现或编译通过而标为整项完成。
9. 阻塞、延后、取消使用 `#blocked`、`#deferred`、`#cut` 并写清原因；取消条目保留，不静默删除。未执行的检查保持未完成，确实不适用时说明理由。
10. 具体测试是所属功能 Issue 的子项，可沿用 `<parent>-test` ID。QA 仍是有效类型；不要只为宣布阶段完成而制造独立 QA、验证或完成定义 Issue。Phase、工作线和父子关系按实际需要记录，不再依赖 branch 标题组织任务。
11. 更新 Issue 时精准修改相关 Description、属性和对应 Comments，不为整理格式批量改写无关历史、删除或重编号既有 ID；不额外维护一套平行需求文件或执行日志。
12. 旧活动 `REQUIREMENTS.md` 与 `agent-log/` 在任务和有效证据迁入 Issue 后移除，不维护两套工作制度。保留旧 ID / 来源，完整历史可由已核实 Git 历史追溯；未跟踪或未提交的独有内容必须先保全到本次版本化来源副本。明确停用的模板档案继续只作历史，不把其中示例迁成真实任务。

## Issue 文件命名与版本关联

1. 活动文件采用 `issue_任务描述.md`，不带任何版本编号后缀。任务描述按源语言如实、连贯记录，中文不翻译，英文词用连字符；说明具体对象与动作 / 目标，不能只写 search、storage 等主题桶。文件名不放类型或旧 A-001 等编号；类型和旧稳定 ID 只留在 frontmatter，类型沿用下节 16 类含义。
2. 同一文件混装多个可独立实施 / 交付的目标时，按实际任务拆分并保留原 ID、来源、历史与真实状态。属于同一目标的实现细节、依赖和验收子项留在该任务内，不机械地逐 checkbox、逐日志创建文件。语义重名时用具体对象、范围或动作消歧，不恢复无意义编号。
3. 对应执行涉及的 Git commit hash / P4 changelist 在该条 Comment 首部以 `>` 引用，并保存到 `commit-related` 列表，可涉及多个 change；不使用 `controlled-version` 等单值属性代替多次提交关联，也不写入文件名。只记录有依据的关联，不拿当前 HEAD、需求快照或文档整理提交冒充业务实施提交。
4. 新版保留 `created-version`、`closed-version`、`start-time`、`closed-time`、`estimated-workhour`、`actual-workhour` 字段；未知值留空，不从模板示例日期、Git 时间或历史日志猜填版本、实际时间和工时。已有 `recorded-version` 数据作为兼容扩展保留，不放回新版默认属性，也不自动转换为新版本字段。`completed-time` 与 `closed-time` 不视为同义字段；保留既有 `completed-time`、`parent`、`id` 等扩展和引用。
5. 没有相关 Git / P4 编号或内容发布版本时无需填占位；不为补值 fetch、切分支或扩大检查范围。实际提交生成后再记录真实完整 hash；记录文件自己的提交 hash 留到下一次实际更新补充，不为追写自身 hash 连续追加提交，也不改写历史。
6. `issue/issue_template.md` 保持模板文件名与模板身份；实际 Issue 使用模板的 frontmatter、两个一级正文标题及 Comment 二级标题格式。命名与记录方式调整不改变实现、检查和用户验收的真实完成度。

## Issue 类型

类型继承旧 REQUIREMENTS 规范的含义，现由本文件定义；新增类型须经用户明确同意。

- DOC：文档、说明、协作规范、需求整理、知识库维护。
- PM：产品目标、范围定义、路线图、优先级、验收标准。
- UX：用户体验、信息架构、用户路径、交互流程、可用性。
- UI：界面视觉、设计系统、组件外观、响应式与可访问性。
- FE：前端应用、客户端界面、状态管理、前端工程化。
- BE：后端服务、业务逻辑、服务端接口、任务调度。
- API：对外或内部接口契约、协议、Schema、SDK 集成边界。
- DB：数据库、数据模型、迁移脚本、索引、查询与持久化。
- DATA：内容数据、配置数据、导入导出、数据清洗、数据质量。
- CONTENT：文案、素材、关卡、数值、运营内容等非代码内容资产。
- QA：测试策略、自动化测试、人工验收、质量检查、回归验证。
- OPS：部署、运维、监控、日志、告警、备份与恢复。
- CI：持续集成、构建流水线、发布流程、版本管理自动化。
- SEC：安全、权限、隐私、合规、密钥与敏感信息处理。
- ARCH：系统架构、技术选型、模块边界、跨模块约束。
- TOOL：开发工具、脚本、CLI、代码生成器、内部效率工具。

## 目录、文档与工作区

1. 新目录优先按交付物 / 职责命名，使用小写和连字符，按需创建，不预建空目录。既有路径不因模板自动迁移；约定文档名与 Issue 稳定 ID / 类型允许保留其规定大小写。
2. App 交付物可用 `ios/`、`macos/`、`web/`；官网用 `site/`，管理后台用 `admin/`。同一交付物的前后端可在其内部细分。Game 交付物见项目专用规则。
3. 使用既有 worktree 时，Issue 放在所操作工作区自己的根目录。可采用以下布局；它不要求项目启用 worktree，也不授权改动现有布局：
   ```text
   project-name/
     issue/                     # 不使用 worktree 时
       issue_任务描述.md
   project-name/
     existing-workspace/        # 使用 worktree 时，名称遵循现有约定
       AGENTS.md
       issue/
         issue_任务描述.md
       <deliverable>/
   ```
4. 初始化项目时选择 App 或 Game 子模板，按实际需要复制，包含适用的隐藏配置；不带入模板仓库的 `.git`、历史档案或个人 IDE 配置，不误删项目自身的 Git / CI 配置。初始化不隐含创建分支、worktree 或启用新的版本管理系统。
5. `AGENTS.md` 放协作约束、目录索引与命令；`README.md` 放对外用途、当前能力和入口；`DESIGN.md` 放视觉规范；`issue/` 放具体任务和当前状态。默认中文，术语、代码标识符和既有文件名按实际需要保留。
6. 子功能只在有独立维护需要时补充局部文档；父级索引已有入口，子级继承公共说明。任务默认共用当前工作副本的 `issue/`，用路径和关联 ID 表达子功能范围，不为每层目录另建任务系统。

## README.md 维护纪律

1. 面向第一次看到项目的读者，说明是什么、解决什么问题、当前能力、运行入口和文档指针。每段简明，不复制详细文档。
2. 协作与结构规则指向 `AGENTS.md`，任务指向 `issue/`，视觉指向 `DESIGN.md`，架构 / API / 配置参考指向对应专门文档。只链接实际存在的文件。
3. 项目用途、范围、状态或用户入口变化时更新；不把内部待办、验收细项和完整目录清单塞入 README。

## DESIGN.md 维护纪律

1. `DESIGN.md` 记录视觉设计系统：颜色、字体、间距、布局、组件、动效、响应式和可访问性约束，不承载系统架构或具体任务。
2. 视觉规则变化时按实际内容更新；没有 UI 或本次不涉及视觉规范时，不强制创建或补齐。已有“不适用”说明可保留。
3. 大幅改变设计方向且需保留旧稿时，归档到 `archive/design/` 并更新引用；不为普通样式修正批量创建历史文件。

## 版本、构建与周期维护

1. 项目版本以指定的单一权威来源为准，脚本和 CI 从该来源读取。版本递增遵循项目发布约定；没有既定要求的普通任务不自行发版或递增版本。递增时同步相关展示并在 Issue 说明依据。
2. 默认不额外生成安装包、引擎导出、压缩包或其他发布产物。用户本次要求生成时，用既有构建工具从权威源生成，不把派生产物当成第二份手工维护源。
3. 只有明确授权的周期维护才跨仓库同步、整理或提交；每个仓库独立处理，不覆盖正在变化或归属不明的内容，不 force push 或改写历史。
4. 周期复盘只读取授权时间窗内可访问的记录，区分用户习惯、通用纠正、任务纠正和推断。仅把重复、可执行、可验证且已去重的规则提炼到标准模板，并须有修改规范的授权。

# 技术栈专用规则

## Bento H5 PPT

涉及 Bento 幻灯片时，使用当前环境可用的 `bento-slides` skill 和项目约定；仅在需要该操作时检查工具，不为普通任务自动安装或更新全局 skill。

## TypeScript

1. 以仓库实际 `tsconfig`、包管理器和 scripts 为准，不猜测版本或命令。
2. 保持类型边界明确；`unknown` 先收窄，只有说明原因时才使用 `any`、`@ts-ignore` 或等价逃逸。
3. 类型检查、测试、构建和真实交互分别记录，按本次改动选择必要项目脚本。

## 项目专用内容

<!-- local-agent-template-rollout:v2.0.1-261023-173015 -->
> 通用规则来源于本地 `DDonlien/agent-template` `v2.0.1-261023-173015`。项目自己的范围、命令和技术契约继续有效；旧模板中要求 REQUIREMENTS / agent-log 双写、例行远端同步与提交的通用制度已停用。
>
> 项目任务以当前工作副本根 `issue/` 为唯一工作入口，正文维护当前事实，Comments 追加历史。旧工作文档在有可追溯迁移映射和 Git 历史 / 版本化来源副本后移除；未把历史日志机械创建为新任务。Issue 使用 Obsidian YAML frontmatter 和 Description / Comments 两个一级标题；文件名仅为 issue_原语言任务描述.md。真实 Git / P4 编号在对应 Comment 首部以 `>` 引用并汇总到 commit-related；该条末尾以 `>` 引用真实会话链接。recorded-version 仅保留已有兼容数据，不再列为默认属性。
<!-- /local-agent-template-rollout -->


### 项目概况

- 项目名称：Quota Bar
- 产品简介：macOS 菜单栏下拉应用，用于展示 AI 订阅费用与额度状态；同时包含官方营销主页。
- 主要用户：需要集中查看多项 AI 服务订阅与额度的个人用户，以及想了解 / 下载 Quota Bar 的访客。
- 当前阶段：macOS 应用已进入真实 Provider 接入、订阅到期日和发布自动化阶段；营销主页首版已落地；仓库结构采用项目容器 + `main/` + 平铺 branch worktree + `_builds/` 的模式。

### 技术栈与命令

- 技术栈：Swift Package Manager、SwiftUI、AppKit、macOS 26；Astro 5.x、TypeScript、原生 CSS。
- 统一入口：优先使用当前工作区根目录的 `Makefile`。
- 开发命令：`make run`（等价于 `cd macos && swift run`）；站点开发为 `cd site && npm run dev`。
- 测试命令：`make test`（等价于 `cd macos && swift test`）。
- 构建命令：`make build`（等价于 `cd macos && swift build`）；站点构建为 `make site`。
- 应用打包：`make app`（等价于 `cd macos && ./scripts/build-app.sh`）。
- 发布命令：`make deploy`（部署 `site/` 到 Vercel，首次需先 `make link`）。
- 发版流程（ad-hoc 预开发版）：本地 `make app` 或推 main 都会读取根目录 `VERSION` 文件 + 当前 commit short sha，产出 `v<VERSION>-<sha>` 的 ad-hoc 签名包（首次打开需「右键 → 打开」）。签名升级（Developer ID + notarize）见 issue/ 中原 v0.12.0 需求及其来源映射。
- **安装包分发（v0.15.0 起）**：CI 把 dmg 上传到 **Vercel Blob**，同时写一份 `releases/latest.json` manifest（见 `scripts/upload-release.mjs`）；GitHub Release 只保留 tag 与源码归档，**不再附带 dmg**。客户端与官网都通过 `api/latest-release.mjs` / `api/download-latest.mjs` 拿版本信息和安装包，下载流量始终走自有域名。
  - 兼容闸门：`BLOB_READ_WRITE_TOKEN`（GitHub Actions Secret）没配时，`release.yml` 自动退回旧路径把 dmg 挂到 GitHub Release，发版不会中断。
  - 已知既成事实：迁移完成后，**≤v0.10.1 的旧客户端会永久失去自动更新**——它们先问 GitHub，那边返回"有 release 但无 dmg 资产"就不会再走兜底，于是永远判定"已是最新"。这不是 bug，需要手动装一次新包才能重新接上更新链路。
  - 因此 `UpdateChecker` 的查询顺序从 v0.15.0 起是「官网 endpoint 优先 → GitHub 降级」，跟 v0.14.0 时相反；改动这个顺序前先读 `UpdateChecker.primaryReleasesURL` 上的说明。
- **付费与授权（v0.15.0 起）**：7 天试用，到期后**只停用自动更新**，额度获取等核心功能不受影响（开源可自编译，锁核心功能会让付费版不如免费版好用）。授权走 Creem license key，校验必须经 `api/activate.mjs` / `api/validate.mjs` 服务端代理——`CREEM_API_KEY` 绝不能进客户端二进制。复验对网络/服务端故障 **fail open**，只有 Creem 明确返回非 active 才降级。

### 版本号维护规则

- 格式：`vX.Y.Z-<git-short-sha>`（如 `v0.10.0-dcfff71`）。`X.Y.Z` 是唯一的“新旧”判断依据——`UpdateChecker` 纯比语义化版本号，不看发布时间、构建时间戳或 sha；`-<sha>` 只标识"具体是哪次构建"，同一个 `X.Y.Z` 重复打包（哪怕 sha 不同）不会被判定为"有更新"。这是 2026-07-07 从"按发布/构建时间比较"改过来的，起因是时区解析 bug 导致的虚假更新提示——只要还依赖时间比较就永遍有踩时区/时钟的风险，所以彻底改成纯版本号比较。
- 唯一权威来源：`main/` 工作区根目录的 [`VERSION`](VERSION) 文件，内容就是 `X.Y.Z`（无前导 `v`，无 sha）。`macos/scripts/build-app.sh` 和 `.github/workflows/release.yml` 都从这个文件读取，不再有 nightly/stable 两条通道或 workflow_dispatch 手动输入版本号的机制。
- **`X.Y.Z` 由 Agent 维护，每次执行修改任务时自行判断 bump 哪一位**（2026-07-19 修正：这条规则原来写的是"常规修复一般不 bump，或 bump PATCH"，实践下来变成了"几乎从不 bump PATCH"——同一个 `X.Y.Z` 底下堆了几十次真实发布，版本号本身失去辨识度，`UpdateChecker` 也一度因此漏判"有更新"，见 `UpdateChecker.swift` 里 2026-07-19 那条注释。现在把默认行为改成"必须 bump PATCH"，不再留"一般不 bump"这个退路）：
  - **默认：任何会被推到 main、触发 Release workflow 打出新包的提交，都必须 bump PATCH（Z）**——bug 修复、文案/样式调整、依赖升级等不引入用户可感知新能力的改动都算在内；
  - 新增功能、新 Provider、新一层获取策略、UI 交互规则调整等用户可感知的新能力 → bump MINOR（Y）（顺带把 PATCH 归零），通常对应 issue/ 中明确对应的新功能范围与目标版本；
  - 破坏性变更（数据格式不兼容、架构性重写、需要用户手动干预迁移）→ bump MAJOR（X）（顺带把 MINOR/PATCH 归零）；
  - 不 bump 的例外——仅限完全不会被打包发布的改动：纯文档/注释、`issue/README.md` 记录、`issue/issue_建立项目协作基础.md` 勾选状态更新、`DESIGN.md` 这类不影响任何代码或站点内容的文件。拿不准时按"要 bump"处理，而不是按"不 bump"处理——错判的代价是版本号多跳一位（无害），不是漏跳导致更新机制再次失效。
- 每次修改 `VERSION` 文件都必须在对应 Issue 的 Comments 里明确写出：改了哪一位、为什么这么判断（对应哪个改动/Phase）。

### 打包/推送时的 site 同步规则

- 每次打包（`make app`）或推送 main（触发 Release workflow）时，如果本次改动更新了 `VERSION` 文件（即版本号发生了 bump），必须同步在 `site/src/pages/changelog.astro` 对应的 `site/src/i18n/dict.ts` 里追加一条新版本记录（`changelog.v<majorminor>.version` / `.date` / `.title` / `.bullet1..N`，中英文都要写），面向用户总结这次改动带来的可感知变化；不要照抄 commit message 或 `CHANGELOG.md` 的开发者向措辞。
- 每次打包或推送时，如果本次改动增加或减少了 macOS 应用支持的 Provider（`ProviderKind` 新增/移除成员），必须同步更新营销主页：
  - `site/src/components/Hero.astro` 的 `AGENTS_EN` / `AGENTS_ZH` 打字机轮播数组。
  - `site/src/components/SupportedServices.astro` 的 `PROVIDERS` 数组。
  - `site/src/layouts/Layout.astro` 的默认 `description`（SEO 描述里列举的服务名单）。
- 上述 Provider 名单变化通常也构成一次版本号 bump（新 Provider 属于用户可感知新能力，见上文版本号维护规则），因此按第一条规则同步更新 changelog 即可，不需要重复记录。
- 如果一次任务既没有 bump 版本号、也没有增删 Provider，不需要触碰 `site/` 下的上述文件。

### 文档入口

- 项目说明：`README.md`
- 需求追踪：`issue/issue_建立项目协作基础.md`
- 视觉规范：`DESIGN.md`
- 执行日志：`issue/README.md`

### 目录索引

- `<project-name>/`：项目容器目录，不直接开发。
- `main/`：`main` 分支工作区，包含 `.git/`、根文档和交付物目录。
- `<branch-worktree-name>/`：非 `main` 分支的 Git worktree 工作区，与 `main/` 平级。
- `_builds/`：容器级本地打包产物，不进 Git。
- `<deliverable>/`：交付物目录，如 `macos/`、`site/`；其中 `macos/` 是 SwiftPM macOS 原生菜单栏应用，`site/` 是 Astro 营销主页。
- `agent-template/`：Agent 协作文档模板；只保留模板文件和日志模板，不保留嵌套 `.git` 或模板历史日志。
- `issue/README.md`：当前工作区执行日志。
- `reference/`：参考资料，不默认视为项目代码。
- `research/`：调研文档。
- `.github/workflows/`：CI、PR check 和 Release 自动化。

### 子功能文档入口

- `site/`：Quota Bar 官方营销主页；文档入口为 `site/AGENTS.md`、`site/README.md`、`issue/issue_确定官网技术方案与首屏卖点.md`、`site/DESIGN.md`、`issue/README.md`。

### 项目特殊约束

- 语言与命名：面向用户的文案默认中文；Swift 类型、属性、文件名沿用英文；目录名按新模板优先表达交付物 / 职责，使用小写和连字符。
- Worktree 约束：项目容器不直接开发；`main` 保留在 `main/`，其他长期分支与 `main/` 平级。日常任务未指定分支时在 `main/` 执行；指定分支时进入对应的平级 worktree 目录。
- 设计原则：macOS 应用优先贴近 macOS 26 Liquid Glass 风格，保持菜单栏下拉面板轻量、紧凑、可扫读；营销主页保持克制、可信、聚焦产品。
- 架构限制：Provider 额度、订阅到期日、订阅组排序和数据存储以本地解析为主；不得把用户 token、cookie 或额度数据上传到外部服务器。
- 授权与引用边界：`reference/`、外部参考项目和 `agent-template/` 的演示内容不默认纳入项目自身范围；引用第三方实现时保留来源说明。
- 安全、隐私或合规要求：浏览器 Cookie、Keychain、CLI 日志和本地配置文件只读访问；日志和控制台输出不得包含 token、cookie、API key 或完整个人账号标识。
