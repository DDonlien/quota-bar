# 用户原始 prompt

>（附件："2 sub.svg"、"2 sub-front.svg" —— 两个参考图标，展示同一组两个 bar 在"正常叠放"和"反转叠放"两种情况下的样子）
>
> 增加菜单栏图标的一个新功能：分层显示
>
> * 实心的bar只用于显示最小时间单位（比如5h）的额度
> * 然后一个虚线资产用于显示第二层时间单位（比如1week）的额度
> * 如果第二层比第一层少，参考附件2的叠加情况（叠加在第一层前）
> * 最左、右的2个bar的顶部外侧圆角应该只有在接近顶部的时候有，降下来了就没有了，自然过渡

# 启动运行时的分支和版本

- 分支：`main`
- 版本：本轮基于上一轮（opencode Go 价格固定）未提交的工作树继续

# 任务开始时间

2026-07-09 22:40 +0800

# 任务结束时间

2026-07-09 22:56 +0800

# 任务结束时是否执行了提交

否——按惯例留给用户确认后再决定是否提交/推送。

# 已阅读上下文

- 两张参考 SVG：逐字节读完，确认了两件事——(1) "2 sub.svg" 里纹理层（对角线 hatch pattern）画在实心层**之前**（次短周期更高时的正常情况），"2 sub-front.svg" 里实心层画在纹理层**之前**（次短周期更矮时的反转情况，纹理层的路径压根没有顶部圆角，因为它离容器顶部太远）；(2) 纹理层的具体样式是 45° 对角线阵列，`fill="#626262"` 灰色、`opacity 0.5`。
- `StatusBarController.swift` 全文（`makeBarsImage`/`BarsImageLayout`/`barPath`/`remainingFraction`/`statusBarQuota`）。
- `QuotaModels.swift` 的 `primarySubscriptionGroupWorstQuota`/`subscriptionGroups` 全文，确认现有的"取最紧张额度"逻辑跟这次要做的"固定取最短/次短周期"是两套完全不同的选择方式。

# 对话与行动记录

先读两张参考 SVG 确认了叠放规则的精确含义：`fill` 属性画在后面的元素在 SVG 里视觉上位于前面（后画的盖住先画的）——"2 sub.svg"（正常情况）里纹理层先画、实心层后画，纹理层是背景、实心层在前；"2 sub-front.svg"（反转情况）刚好反过来。同时注意到"front"版本里纹理层的路径完全没有顶部圆角（纯直角），进一步印证了"圆角要不要看这一层离容器顶部有多近"这个规则。

确认现有 bar 计算逻辑（`primarySubscriptionGroupWorstQuota`）是按"剩余最少"选值——同一个 provider 在不同时刻，5 小时和周额度谁更紧张会互换身份，这跟这次要做的"实心永远是最短周期、纹理永远是次短周期"是完全不同的选择方式，不能复用，需要新写一个按周期长短排序的选择方法。

实现完之后没有直接相信自己的推理，而是写了一个临时渲染脚本（`ZZZRenderIconPreviewTests.swift`，验证完就删）把 `makeBarsImage` 的真实渲染结果导成放大 8 倍的 PNG，直接肉眼核对——这一步直接抓到一个真实 bug：反转情况下（次短周期更矮、叠在实心层前面）纹理层用的是半透明白色斜线，画在已经是纯白色的实心层上完全没有对比度，视觉上等于什么都没画。改成 `.destinationOut` 复合模式——把斜线"擦"进已经画好的实心区域，露出底下的菜单栏背景——不管纹理层底下是透明画布还是已经填满的实心层，都能看出纹理。重新渲染验证，两种叠放情况都正确了。又追加渲染了一组"最左/中间/最右"分别是接近满格/中等高度/几乎用尽的对照，直接肉眼确认：最左 bar 接近满格时顶部有自然的圆角、中间 bar 即使很高也保持直角、最右 bar 几乎用尽时是纯直角——三者都符合预期。

顺手把 `makeBarsImage`/`layeredFractions`/`BarsImageLayout` 从 `private` 松到默认 internal，配合 `@testable import` 写了 8 个真正的单元测试（选层逻辑、`layeredFractions` 各状态分支、顶部圆角过渡、中间 bar 恒定直角），不是只靠临时渲染脚本这一次性验证。

# 完成工作

- `QuotaModels.swift`：新增 `ProviderSnapshot.primarySubscriptionGroupTopTwoQuotasByPeriod(itemOrder:)`。
- `StatusBarController.swift`：
  - 新增 `layeredFractions(for:)`。
  - `makeBarsImage` 改成按层高决定叠放顺序，纹理层用 `fillHatched`（45° 手绘斜线，裁剪到 bar 形状；`erasing` 参数区分"背景层用半透明白线"还是"叠在实心层前用 `.destinationOut` 擦除"）。
  - `BarsImageLayout.barPath` 重写：最左/最右 bar 的顶部圆角改用 `adaptiveTopRadius`（按 bar 顶边离容器顶边的距离线性插值），原来三个重复分支合并成一个支持四角独立半径的 `roundedRectPath`。
  - `makeBarsImage`/`layeredFractions`/`BarsImageLayout` 从 `private` 改成 internal，方便测试直接访问。
- 新增 `Tests/QuotaBarTests/StatusBarLayeredBarsTests.swift`（8 个测试）。
- `REQUIREMENTS.md`：新增 `[0.10.0-FEAT-A-001]` `[0.10.0-FEAT-A-002]` `[0.10.0-FEAT-A-003]` `[0.10.0-QA-A-001]`。

新包：`macos/build/20260709-225553-main/Quota Bar.app`（`build/latest` 已指向），已重启本机开发态实例。

# 更新的需求 ID

- `[0.10.0-FEAT-A-001]` `[0.10.0-FEAT-A-002]` `[0.10.0-FEAT-A-003]` `[0.10.0-QA-A-001]`

# 更新的 README 或 DESIGN 章节

- 无。

# 验证方式

- `swift build`：无警告无错误。
- `swift test`：203 tests in 45 suites 全部通过（新增 8 个：选层逻辑 3 个、`layeredFractions` 3 个、圆角/中间 bar 几何 2 个）。
- **真实渲染验证**（这次的关键验证手段，不是靠猜）：写了一个临时测试脚本调用 `makeBarsImage` 生成真实 `NSImage`，导出放大 8 倍 + 深色背景的 PNG，直接用 Read 工具肉眼查看——第一轮就抓到"白色斜线叠白底看不见"的真实渲染 bug，修完后重新渲染确认两种叠放情况、以及"最左满格有圆角/中间恒定直角/最右几乎用尽也是直角"的圆角过渡效果都符合预期，验证完删掉了临时脚本。
- `./scripts/build-app.sh`：产包成功，已重启本机实例。

# 备注

- 未提交 git commit。
- 目前只处理"最短 + 次短"两层，第三层及以后的周期（比如 Kimi Work 的月额度）在菜单栏图标里被忽略，只在 dropdown 里完整展示——这是用户需求描述里明确只提到"两层"，没有再往上扩展。
- 纹理层的具体视觉参数（斜线间距 2pt、线宽 0.75pt、透明度 0.45/erase 0.45）是照着图标实际像素尺寸（bar 宽度只有 4-14pt）估的，不是精确复刻参考 SVG 的间距比例——图标这么小，真按 SVG 里的密度画斜线在实际菜单栏尺度下大概率糊成一片，这次选了在渲染测试图里肉眼看着清楚的参数，如果用户实机看效果觉得纹理太密/太疏，这几个数字可以再调。
- 建议用户实机确认一下效果：真实场景需要一个 provider 同时有"最短周期"和"次短周期"两条不同 quota（比如 Claude 的 5 小时+周，或 Codex 的 5 小时+周）才能看到分层效果；只有一条 quota 的 provider（比如 opencode）会保持单层画法，不受影响。
