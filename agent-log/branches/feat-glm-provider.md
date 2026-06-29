# feat/glm-provider

## 用途

v0.7.0 phase 智谱 BigModel Z Code (zcode) Provider 接入的独立工作线。

zcode 是智谱 BigModel 的桌面 IDE（`/Applications/ZCode.app`、bundle id
`dev.zcode.app`），是 opencode 的 fork/skin，走 anthropic 兼容 API。
凭证、配置、套餐额度本地缓存统一在 `~/.zcode/v2/` 目录下。

## 关联 Phase / Task

`v0.7.0-DATA-A-000~005`：
- ProviderKind enum 增 `.zcode` + 元数据
- `ZCodeAuthProvider` 实现
- 4 种 plan 套餐映射（bigmodel-start/coding + zai-start/coding）
- `ZcodeLoginRunner` + `InstallDetectorProvider`
- `Strategies.zcodePipeline()` 接入
- app DESIGN.md 同步 zcode brandColor

`v0.7.0-FE-A-000~001`：菜单栏 bar 集成 + 状态灯验证
`v0.7.0-DOC-A-000`：README Provider 列表

## 起点

- 基于 main `@ 8d69017`
- v0.4.0 phase 已完成 zcode 安装调研（device 端实测）

## 当前状态

init — 暂无实际工作。

## 后续入口

工作顺序建议：

1. **ProviderKind 元数据** — 先把 `.zcode` 枚举值和元数据补齐，让 build 通过
   （DATA-A-000）
2. **ZCodeAuthProvider** — 从 `~/.zcode/v2/config.json` 读启用 plan 的 API key
   + baseURL，发 anthropic 兼容 API 拉 usage（DATA-A-001）
3. **套餐映射** — 4 种 plan 区分 subscriptionGroup + 价格映射（DATA-A-002）
4. **LoginRunner + InstallDetector** — bundle 探测 + config 存在性（DATA-A-003）
5. **Pipeline 接入** — `Strategies.zcodePipeline()` + RefreshCoordinator 串接
   （DATA-A-004）
6. **app DESIGN 同步** — web/DESIGN.md 占位 `#3866ff` 在 app 端落地（DATA-A-005）

每步完成后跑 `swift build` + 现有测试，确保不破坏其他 provider。