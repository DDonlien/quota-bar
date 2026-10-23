# sub/main: 建立安全持久化模型

- ID：`0.9.0-ARCH-A-000`。
- 类型：`ARCH`。
- 状态：进行中（原文同时包含已完成与未完成项）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.9.0 - 持久化、来源索引与启动兜底 / sub/main: 建立安全持久化模型。
- 原稳定 ID：`0.9.0-ARCH-A-000`, `0.9.0-ARCH-A-001`, `0.9.0-ARCH-A-002`, `0.9.0-SEC-A-000`, `0.9.0-SEC-A-001`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [ ] [0.9.0-ARCH-A-000] 定义 Quota Bar 自有持久化目录：`~/Library/Application Support/QuotaBar/`；偏好、来源索引、last-known-good 快照都放在该目录下，不新增 `~/.quota-bar` 作为主路径 #P1
- [ ] [0.9.0-ARCH-A-001] 设计持久化 schema version 与向后兼容策略；所有持久化文件必须带 `schemaVersion`，读取失败时安全丢弃并回到实时抓取，不阻塞 app 启动 #P1
- [ ] [0.9.0-ARCH-A-002] 明确安全边界：持久化文件不得保存 token、cookie、API key、refresh token 或浏览器 Cookie 明文；敏感凭证仍只读取原始服务配置、浏览器 Cookie 或 macOS Keychain #P1
- [x] [0.9.0-SEC-A-000] App 启动时不得注册浏览器 Cookie Keychain 预授权弹窗；默认刷新链路不得主动触发浏览器密码 / 权限提示 #P0
- [x] [0.9.0-SEC-A-001] 默认禁用 SweetCookieKit 的 Chromium Keychain 解密（`BrowserCookieKeychainAccessGate.isDisabled = true`），杜绝 "Chrome Safe Storage" 密码弹窗；仅当用户在偏好设置显式选择 Chrome 浏览器来源时放开。订阅过期日 headless source 也随之默认无弹窗：优先 App 自有 WebView 会话，其次 Safari/Firefox 文件 Cookie（FDA 已授权时静默）#P0 — `AppDelegate.applyBrowserCookieKeychainPolicy`

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260705-170000-utcp8-taobe-gpt-5.md — 历史证据迁移

来源：`agent-log/20260705-170000-utcp8-taobe-gpt-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

检查你最新merge进来的功能，似乎实现的并不好：
1. 我在sub/main应该已经移除了所有对浏览器弹窗密码要求授权的功能，现在main上打包的版本还是保留了
2. 打出来的包没有用最新的图标，之前main上已经是最新图标了

#### 完成工作

- `macos/Sources/QuotaBar/AppDelegate.swift`：不再注册浏览器 Cookie Keychain 预授权弹窗。
- `macos/scripts/build-app.sh`：重新打出 `Quota Bar.app`，复制最新 `QuotaBar.icns`，写入 `CFBundleIconFile=QuotaBar`，并让 `build/latest` 使用相对软链。
- `REQUIREMENTS.md`：新增并完成 `[0.9.0-SEC-A-000]`。
- 已重新本地打包：`macos/build/latest/Quota Bar.app`。

#### 更新的需求 ID

- `[0.9.0-SEC-A-000]`

#### 验证方式

- `bash -n macos/scripts/build-app.sh`
- `rg -n "BrowserCookieKeychainPromptHandler|Quota Bar 需要 Keychain 授权|CFBundleIconFile|QuotaBar.icns|APP_NAME=|QuotaBar.app" macos/Sources macos/scripts REQUIREMENTS.md README.md`
- `make test`：首次在沙箱内因 SwiftPM 用户级模块缓存权限失败；经用户授权在沙箱外重跑通过，109 个测试全绿。
- `make app`：成功生成 `macos/build/20260705-165755-main/Quota Bar.app`。
- `test -d 'macos/build/latest/Quota Bar.app' && test -f 'macos/build/latest/Quota Bar.app/Contents/Resources/QuotaBar.icns'`
- `plutil -lint 'macos/build/latest/Quota Bar.app/Contents/Info.plist'`
- `/usr/libexec/PlistBuddy -c 'Print :CFBundleName' -c 'Print :CFBundleDisplayName' -c 'Print :CFBundleIconFile' -c 'Print :QBDisplayBuild' 'macos/build/latest/Quota Bar.app/Contents/Info.plist'`
- `codesign --verify --deep --strict --verbose=2 'macos/build/latest/Quota Bar.app'`

#### 备注

- 本次只修 main，不改 sub/main。
- `WebView 授权`入口没有在本次移除；本次移除的是启动时主动注册的浏览器 Cookie Keychain 预授权提示。
