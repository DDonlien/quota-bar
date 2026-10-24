# 按额度周期分层绘制菜单栏bar

- ID：`0.10.0-FEAT-A-001`。
- 类型：`QA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 菜单栏图标分层显示（新功能）。
- 原稳定 ID：`0.10.0-FEAT-A-001`, `0.10.0-FEAT-A-002`, `0.10.0-FEAT-A-003`, `0.10.0-QA-A-001`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户提供两张参考 SVG（"2 sub.svg"/"2 sub-front.svg"）+ 需求描述：实心 bar 固定显示最短周期额度（比如 5 小时），一个虚线/纹理层显示次短周期额度（比如周额度）；如果次短周期比最短周期剩得少，纹理层要叠在实心层前面（参考图 2 的叠放关系）；最左/最右两个 bar 的顶部外侧圆角只在接近容器顶部时才有，bar 变矮后圆角要自然过渡消失，不能凭空浮在中间。

- [x] [0.10.0-FEAT-A-001] `QuotaModels.swift` 新增 `ProviderSnapshot.primarySubscriptionGroupTopTwoQuotasByPeriod(itemOrder:)`：按周期长短（不是剩余多少）从第一个订阅组里排出最短 + 次短两条额度——跟已有的 `primarySubscriptionGroupWorstQuota`（按"剩余最少"选值，可能是 5 小时也可能是周额度，取决于哪个更紧张）是完全不同的选择逻辑，这里身份固定，不会因为剩余比例变化而互换 #P1
- [x] [0.10.0-FEAT-A-002] `StatusBarController` 新增 `layeredFractions(for:)`：套用新的选层方法算出 primary（固定最短周期）/secondary（固定次短周期，只有一条 quota 时为 nil）两个比例；`makeBarsImage` 每个 bar 最多画两层，叠放顺序按谁更高决定——次短周期更高（更常见）时纹理层先画成背景、实心层叠在前面；次短周期更矮时实心层先画、纹理层叠在前面。纹理层的画法是裁剪到 bar 形状内的 45° 手绘斜线阵列（图标只有个位数 pt 宽，`NSColor(patternImage:)` 那套在这个尺度下不好精确控制）——关键坑点：纹理层叠在**已经画满的实心层前面**时，半透明白色斜线画在纯白底上完全没有对比度，视觉上等于没画；改用 `.destinationOut` 复合模式把斜线"擦"进已经画好的实心区域、露出底下的菜单栏背景，不管纹理层底下是透明画布还是已经不透明都看得清（这个 bug 是渲染测试图直接肉眼看出来的，不是靠猜） #P0
- [x] [0.10.0-FEAT-A-003] `BarsImageLayout.barPath` 重写：最左/最右 bar 的顶部圆角改成跟"bar 顶边离容器顶边的距离"挂钩的 `adaptiveTopRadius`——距离为 0（bar 顶到頂）给足 `barRadius`，距离达到 `barRadius` 或更远收缩到 0，中间线性过渡；底部圆角固定不受影响（bar 永远贴底）。原来的三个重复分支（单 bar/最左/最右各自手写贝塞尔路径）合并成一个支持四角各自独立半径的 `roundedRectPath` 辅助函数，减少重复代码。分层显示下两层各自独立按自己的高度算顶部圆角，不受另一层影响 #P1
- [x] [0.10.0-QA-A-001] 把 `makeBarsImage`/`layeredFractions`/`BarsImageLayout` 从 `private` 松到默认 internal，配合 `@testable import` 直接单元测试（`StatusBarLayeredBarsTests`，8 个测试：选层逻辑、`layeredFractions` 各状态分支、顶部圆角自然过渡、中间 bar 恒定直角）。另外写了一个临时渲染脚本，把真实渲染结果导出成放大 8 倍的 PNG（叠一层深色背景，因为图标本身是白色内容+透明背景，直接看白底 PNG 完全看不见）直接肉眼核对——就是靠这张图发现了上面 `0.10.0-FEAT-A-002` 里说的"白色斜线叠在纯白底上完全看不见"的 bug，验证完两种叠放情况 + 圆角自然过渡都正确后删掉了这个临时脚本，不留在正式测试里 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260709-225553-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260709-225553-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

>（附件："2 sub.svg"、"2 sub-front.svg" —— 两个参考图标，展示同一组两个 bar 在"正常叠放"和"反转叠放"两种情况下的样子）
>
> 增加菜单栏图标的一个新功能：分层显示
>
> * 实心的bar只用于显示最小时间单位（比如5h）的额度
> * 然后一个虚线资产用于显示第二层时间单位（比如1week）的额度
> * 如果第二层比第一层少，参考附件2的叠加情况（叠加在第一层前）
> * 最左、右的2个bar的顶部外侧圆角应该只有在接近顶部的时候有，降下来了就没有了，自然过渡

#### 完成工作

- `QuotaModels.swift`：新增 `ProviderSnapshot.primarySubscriptionGroupTopTwoQuotasByPeriod(itemOrder:)`。
- `StatusBarController.swift`：
  - 新增 `layeredFractions(for:)`。
  - `makeBarsImage` 改成按层高决定叠放顺序，纹理层用 `fillHatched`（45° 手绘斜线，裁剪到 bar 形状；`erasing` 参数区分"背景层用半透明白线"还是"叠在实心层前用 `.destinationOut` 擦除"）。
  - `BarsImageLayout.barPath` 重写：最左/最右 bar 的顶部圆角改用 `adaptiveTopRadius`（按 bar 顶边离容器顶边的距离线性插值），原来三个重复分支合并成一个支持四角独立半径的 `roundedRectPath`。
  - `makeBarsImage`/`layeredFractions`/`BarsImageLayout` 从 `private` 改成 internal，方便测试直接访问。
- 新增 `Tests/QuotaBarTests/StatusBarLayeredBarsTests.swift`（8 个测试）。
- `REQUIREMENTS.md`：新增 `[0.10.0-FEAT-A-001]` `[0.10.0-FEAT-A-002]` `[0.10.0-FEAT-A-003]` `[0.10.0-QA-A-001]`。

新包：`macos/build/20260709-225553-main/Quota Bar.app`（`build/latest` 已指向），已重启本机开发态实例。

#### 更新的需求 ID

- `[0.10.0-FEAT-A-001]` `[0.10.0-FEAT-A-002]` `[0.10.0-FEAT-A-003]` `[0.10.0-QA-A-001]`

#### 验证方式

- `swift build`：无警告无错误。
- `swift test`：203 tests in 45 suites 全部通过（新增 8 个：选层逻辑 3 个、`layeredFractions` 3 个、圆角/中间 bar 几何 2 个）。
- **真实渲染验证**（这次的关键验证手段，不是靠猜）：写了一个临时测试脚本调用 `makeBarsImage` 生成真实 `NSImage`，导出放大 8 倍 + 深色背景的 PNG，直接用 Read 工具肉眼查看——第一轮就抓到"白色斜线叠白底看不见"的真实渲染 bug，修完后重新渲染确认两种叠放情况、以及"最左满格有圆角/中间恒定直角/最右几乎用尽也是直角"的圆角过渡效果都符合预期，验证完删掉了临时脚本。
- `./scripts/build-app.sh`：产包成功，已重启本机实例。

#### 备注

- 未提交 git commit。
- 目前只处理"最短 + 次短"两层，第三层及以后的周期（比如 Kimi Work 的月额度）在菜单栏图标里被忽略，只在 dropdown 里完整展示——这是用户需求描述里明确只提到"两层"，没有再往上扩展。
- 纹理层的具体视觉参数（斜线间距 2pt、线宽 0.75pt、透明度 0.45/erase 0.45）是照着图标实际像素尺寸（bar 宽度只有 4-14pt）估的，不是精确复刻参考 SVG 的间距比例——图标这么小，真按 SVG 里的密度画斜线在实际菜单栏尺度下大概率糊成一片，这次选了在渲染测试图里肉眼看着清楚的参数，如果用户实机看效果觉得纹理太密/太疏，这几个数字可以再调。
- 建议用户实机确认一下效果：真实场景需要一个 provider 同时有"最短周期"和"次短周期"两条不同 quota（比如 Claude 的 5 小时+周，或 Codex 的 5 小时+周）才能看到分层效果；只有一条 quota 的 provider（比如 opencode）会保持单层画法，不受影响。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
