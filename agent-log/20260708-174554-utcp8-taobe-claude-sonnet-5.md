# 用户原始 prompt

>（截图：Preferences「模型」页「API Key 配置」区块，MiniMax 行 subtitle 显示"待替换占位符 · 当前 `sk-xxx`"，Z Code 行展开编辑状态）
>
> 优化一下这里的视觉呈现，给opencode加上api配置功能

# 启动运行时的分支和版本

- 分支：`main`
- 版本：本轮基于上一轮（Antigravity dropdown 授权优先级修复）未提交的工作树继续，期间用户在独立会话里跑完了之前 `spawn_task` 派发的日志污染修复（`task_9a5b6e04`），已合并进同一份工作树（无需额外操作，见下方"对话与行动记录"）

# 任务开始时间

2026-07-08 17:37 +0800

# 任务结束时间

2026-07-08 17:46 +0800

# 任务结束时是否执行了提交

否——按惯例留给用户确认后再决定是否提交/推送。

# 已阅读上下文

- `Preferences/ModelsSettingsView.swift`（`APIKeyConfigRow` 全文）、`Preferences/SettingsComponents.swift`（`SettingsRow`/`SettingsSection`/`SettingsGroup` 全文）。
- `OpenCodeAuthProvider.swift` 全文、`ZCodeAuthProvider.swift` 里 `ZCodeManualKeyStore` 的实现作为参考模板。
- `OpenCodeAuthProviderTests.swift` 现有测试。

# 对话与行动记录

先确认了上一轮 `spawn_task` 派发的"测试污染真实诊断日志"任务（`task_9a5b6e04`）已经在用户的独立会话里跑完——检查发现那个会话直接在同一个工作目录（不是独立 worktree）里改的，改动已经在这份工作树里，不需要"合并"：`FetchPipeline` 新增了 `checkLog: ProviderCheckLog = .shared` 注入点，测试改成显式构造独立临时文件的 `ProviderCheckLog`，删掉了原来 `resetForTesting()` 直接清空 `.shared` 内存的黑魔法。跑了一遍 `swift build`/`swift test`（186 全过）并重新跑测试确认真实日志文件不再新增任何 "quota-source"/"plan-filler" 测试噪音，确认这份改动质量没问题、可以留着。

然后处理用户这轮的两个要求：

**视觉优化**：读代码定位到一个真实的渲染 bug——`APIKeyConfigRow.statusText`（当时是 `String`）里直接拼了字面量反引号（`"当前 \`\(current)\`"`），但它被传给 `SettingsRow.subtitle: String?`，内部走 `Text(subtitle)` 的 `StringProtocol` 初始化器，不会解析 Markdown（只有 `Text(_ key: LocalizedStringKey)` 才会），反引号只会原样显示成两个字符——跟截图里看到的一致。改法：把 `SettingsRow.subtitle` 的类型从 `String?` 改成 `Text?`（新增一个 `String?` 重载保持其余 5 处调用点不用改一行），`statusText` 返回类型也改成 `Text`，用 macOS 26 新的 `Text` 插值语法（`Text("... \(Text(value).font(...))")`）把技术性的值（占位符当前值 / 掩码后的 key）单独标成等宽字体——用编译器自己提示的写法，避免了 `+` 拼接在 macOS 26 SDK 上的 deprecation 警告。另外在「API Key 配置」区块顶部加了一行说明文字，对齐本页其余 section 的惯例（之前只有标题，缺上下文）。

**opencode API 配置**：opencode 本身是 BYOK 聚合器，没有真实额度接口——手动粘贴一个 key 的唯一作用是让没装官方 CLI 的用户也能让 Quota Bar 确认"我已经配置好了"。参考 `ZCodeManualKeyStore` 的模式新增 `OpenCodeManualKeyStore`（同样是 Quota Bar 自己独占的 JSON 文件），`OpenCodeAuthProvider.fetchSnapshot` 在真实 `auth.json` 没有任何已配置 provider 时回退检查这个手动 store，命中就返回 `.available` + 空 quotas + 档位 "BYOK"（手动 key 拿不到 auth.json 里具体是 Go 还是 Zen 的信息，统一按最保守的 BYOK 展示，不虚构一个更具体的档位）。写测试时特意让 `OpenCodeAuthProvider` 新增一个 `manualKeyConfigPath` 注入参数——记着上一个任务刚发现的教训（测试不注入独立文件会写穿真实用户文件），没有重蹈覆辙。

# 完成工作

- `Preferences/SettingsComponents.swift`：`SettingsRow.subtitle` 从 `String?` 改成 `Text?`（新增 `String?` 重载做向后兼容转发）。
- `Preferences/ModelsSettingsView.swift`：
  - `APIKeyConfigRow.statusText` 改成返回 `Text`，用等宽字体单独标出技术性的值，去掉字面量反引号。
  - `apiKeySection` 顶部加一行说明文字。
  - `reload()`/`save()`/`missingHint` 三处 switch 补上 `.opencode` 分支。
  - `providerAccessModes` 里 opencode 从 `["Config"]` 改成 `["Config", "API"]`。
- `WebAuthorizationController.swift`：`apiKeyCapableKinds` 加入 `.opencode`。
- `OpenCodeAuthProvider.swift`：新增 `OpenCodeManualKeyStore`（读/写/掩码，跟 `ZCodeManualKeyStore` 同款），`fetchSnapshot` 加手动 key 回退分支，`init` 新增可注入的 `manualKeyConfigPath` 参数。
- `Tests/QuotaBarTests/OpenCodeAuthProviderTests.swift`：补一条"回退到手动 key 走 BYOK"的测试，原有"missingCredentials"测试改成显式传两个独立临时路径；新增 `OpenCodeManualKeyStoreTests`（missing-by-default / save-read 掩码 / 拒绝空 key）。
- `REQUIREMENTS.md`：新增 `[0.10.0-BUG-A-021]`（反引号渲染修复）、`[0.10.0-PM-A-017]`（section 说明文字）、`[0.10.0-ARCH-L-004]`（opencode 手动 key），并把 `[0.10.0-INVESTIGATE-A-004]` 补充成"已跑完"的状态。

新包：`macos/build/20260708-174554-main/Quota Bar.app`（`build/latest` 已指向；`build/20260708-174449-main` 那次打包内容一致，代码没有变化，是重复产物）。

# 更新的需求 ID

- `[0.10.0-BUG-A-021]` `[0.10.0-PM-A-017]` `[0.10.0-ARCH-L-004]`

# 更新的 README 或 DESIGN 章节

- 无。

# 验证方式

- `swift build`：无警告无错误（含 macOS 26 SDK 的 `Text` 插值写法，避免了 `+` 拼接的 deprecation 警告）。
- `swift test`：190 tests in 43 suites 全部通过（本轮新增 4 个测试：opencode 手动 key 回退 1 个 + `OpenCodeManualKeyStoreTests` 3 个）。
- `./scripts/build-app.sh`：产包成功。
- **未做**：没能用 computer-use 实机截图验证——`request_access` 找不到这个 App（LSUIElement/accessory 模式的菜单栏 App，没有 Dock 图标，且是未签名的开发态打包产物，不在 Launch Services 常规索引里，request_access 的应用名匹配机制找不到它），已经如实告知用户，请他们自己在真机上确认视觉效果。

# 备注

- 未提交 git commit。
- 视觉改动没有实机截图验证，纯代码走读 + 理解 `Text`/`SettingsRow` 渲染逻辑得出的结论，建议用户实际打开 Preferences「模型」页确认一下等宽字体那段是否符合预期。
