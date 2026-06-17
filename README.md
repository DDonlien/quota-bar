# Quota Bar

Quota Bar 是一个 macOS 菜单栏下拉应用原型，用于集中展示 AI 服务订阅费用与额度状态。当前仓库处于界面和产品方向探索阶段，实际数据同步、订阅管理和额度计算逻辑尚未实现。

## 当前能力

- 在 macOS 菜单栏显示一个状态图标。
- 点击状态图标后展示一个玻璃质感 dropdown 面板。
- 面板中以静态数据展示每月费用、可用订阅数量、各订阅服务与 5 小时/周额度进度。
- 支持点击面板底部“退出”结束应用。

## 快速开始

```bash
cd drop-down-test/CodingPlanMenu
swift run
```

## 构建

```bash
cd drop-down-test/CodingPlanMenu
swift build
./build-app.sh
```

## 目录结构

```text
.
├── AGENTS.md
├── README.md
├── REQUIREMENTS.md
├── DESIGN.md
├── agent-log/
├── agent-template/
├── drop-down-test/
│   └── CodingPlanMenu/
└── reference/
```

## 文档入口

- Agent 协作规范：`AGENTS.md`
- 需求与验收追踪：`REQUIREMENTS.md`
- 视觉规范：`DESIGN.md`
- 执行日志：`agent-log/`

## 边界与限制

- 当前不包含真实订阅数据接入。
- 当前不包含额度刷新、通知、配置、登录或持久化功能。
- 当前 UI 数据为静态占位，用于等待后续实际功能定义。
