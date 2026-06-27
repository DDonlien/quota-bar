# feat/website

## 用途

`web/` 子项目（营销主页）的独立工作线。当前 `web/` 已落地 v0.1.0 主页首版
（按 `web/REQUIREMENTS.md`）：纯 CSS/HTML mockup 还原菜单栏 + dropdown，
6 家 provider 卡片，4 个卖点，下载按钮动态取最新 nightly DMG。CI 自动
build + deploy 到 `quotabar.ddonlien.com`（v0.5.0-CI-A-001 落地）。

后续工作线主要做内容扩展 + 交互增强，跟 app 主仓 `quota-bar/` 改动解耦。

## 关联 Phase / Task

- `web/REQUIREMENTS.md` 现有任务列表（PM / FE / DOC 等）
- `v0.5.0-CI-A-001`：CI 自动 build web（已落地）

## 起点

- 基于 main `@ 8d69017`
- `web/` 目录已含 Astro 项目完整骨架（astro.config / src / public / package.json）

## 当前状态

init — 暂无实际工作。

## 后续入口

`web/` 子项目有自己的 `web/AGENTS.md` / `web/REQUIREMENTS.md` /
`web/DESIGN.md` / `web/agent-log/` 四件套（v0.1.0-DOC-A 落地），所有改动
遵循那套约定。

可能的下一步方向：

1. **Provider 卡片对齐 v0.6.0+ 实际接入列表** — 主页现在列了 6 家 provider，
   但 main 上 v0.7.0 之后还要加 Z Code。需要保持主页文案与 `quota-bar/`
   `ProviderKind` 同步。
2. **下载链接自动化增强** — 当前 dynamic 取 latest nightly DMG，可加 fallback
   + SHA256 校验。
3. **SEO / OG image / favicon 系列** — 主页分享卡片体验。
4. **Dark mode 适配** — 主页目前只跟随系统，需要验证 macOS 26 Liquid Glass
   风格的暗色视觉。