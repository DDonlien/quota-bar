# update/main: 更新检查与下载的 GitHub → Vercel 两步兜底

- ID：`0.14.0-BE-A-000`。
- 类型：`BE`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.14.0 - 大陆可达性兜底 + 额度节奏指示 + Kimi 额度修复 / update/main: 更新检查与下载的 GitHub → Vercel 两步兜底。
- 原稳定 ID：`0.14.0-BE-A-000`, `0.14.0-BE-A-001`, `0.14.0-FE-A-000`, `0.14.0-FE-A-001`, `0.14.0-FE-A-002`, `0.14.0-QA-A-000`, `0.14.0-QA-A-001`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.14.0-BE-A-000] 仓库根目录新增 `api/latest-release.mjs` + `api/_lib/releases.mjs`（Vercel Node Serverless Function，零配置 `/api` 约定，Web-standard `export async function GET()` 签名，经 vercel-functions 官方 skill 确认是当前推荐写法）：服务端请求 `https://api.github.com/repos/DDonlien/quota-bar/releases?per_page=30`，原样转发 GitHub 的 JSON 数组结构（不改形状，客户端复用现有 `UpdateReleaseParser.parse`），带 `Cache-Control: s-maxage=60, stale-while-revalidate=300`
- [x] [0.14.0-BE-A-001] 仓库根目录新增 `api/download-latest.mjs`：服务端解析当前最新可安装 release（tag 能解析出语义化版本号 + 有 `.dmg` 资产），把上游 `fetch()` 拿到的 `ReadableStream` 直接作为 `Response` body 转发（零配置流式，不缓冲整份文件），`Content-Type`/`Content-Disposition`/`Content-Length` 透传；只代理固定的"最新版"目标，不接受任意 URL 参数
- [x] [0.14.0-FE-A-000] `UpdateChecker.performCheck` 重构为 `fetchReleasesData(from:)` 两次调用（GitHub 直连 → 失败后 Vercel `fallbackReleasesURL`）；限流（403 + `X-RateLimit-Remaining: 0`）直接报限流文案、不浪费一次 fallback；两者都失败才进最终错误态，文案改为不点名具体平台的「暂时无法检查更新，请稍后重试」
- [x] [0.14.0-FE-A-001] `UpdateChecker.downloadAndInstall`：拆出 `startDownload(from:)` + `retryDownloadWithFallbackOrFail`，网络层失败**或 `hdiutil verify` 校验失败**（某些网络环境会用 HTTP 200 返回假内容而不是直接连接失败，只有校验能发现）都会触发一次 `fallbackDownloadURL` 重试；`downloadTriedFallback` 标记避免死循环，两次都失败才提示"下载失败，请稍后重试或前往官网手动下载"
- [x] [0.14.0-FE-A-002] `site/src/pages/index.astro` 的 `UPDATE_DOWNLOAD` 脚本重构为 `resolveFromGitHub()` ?? `resolveFromFallback()`：GitHub 失败时改请求同源 `/api/latest-release`，且下载链接本身也改成同源 `/api/download-latest`（不是原始 github.com 直链——GitHub 都连不上，直链大概率也连不上）；sessionStorage 缓存的是最终 href 而不是 release 对象，两条路径共享同一份缓存逻辑
- [x] [0.14.0-QA-A-000] 新增 `UpdateCheckerFallbackTests.swift`（4 个测试：primary 成功不碰 fallback / primary 失败自动 fallback 成功 / 两者都失败报通用错误不点名平台 / 限流直接报错不浪费 fallback）；顺带给 `PreferencesStore` 补一个 `init(fileURL:)` 测试专用入口（原来硬编码单例真实路径，没法在测试里隔离，现在跟其余 store 的临时目录注入模式对齐）。`swift test` 217/217 通过
- [x] [0.14.0-QA-A-001] 真实验证（非 mock）：本地 `node` 直接跑 `api/_lib/releases.mjs` против真实 GitHub API，`pickLatestDmgRelease` 选出 `v0.10.0-cdc842c`；`api/latest-release.mjs`/`api/download-latest.mjs` 的 `GET()` 直接调用，下载流字节数（2,545,835）与 GitHub 资产 `size` 字段完全一致；新增 `.claude/launch.json` 的 `vercel-dev` 配置 + `vercel.json` 的 `devCommand`（原来没有，`vercel dev` 会在仓库根目录找不到 `astro` 命令），通过 Browser 面板跑起 `vercel dev`，确认 `/api/latest-release`、`/api/download-latest` 都是 200、字节数对得上；把官网下载脚本的 `resolveFromGitHub`/`resolveFromFallback` 原样搬到浏览器里跑，用 monkeypatch 的 `fetch` 模拟 GitHub 不可达，确认真的会切到 `/api/download-latest`

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260707-122419-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260707-122419-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 为已经做的修改创建一些commit，然后检查一下github和vercel，告诉我如果我现在（以后）push，从网站上下载app的用户能自动收到检查更新的推送吗？

#### 完成工作

- 创建 4 个本地 commit，覆盖十三次会话的全部未提交改动，工作区已干净。
- 无代码改动（本轮是提交 + 只读排查）。

#### 更新的需求 ID

无新增——本轮不涉及功能改动。

#### 验证方式

- `git status`：确认全部改动已提交、工作区干净。
- `git log --oneline`：确认 4 个 commit 按预期顺序生成。
- `gh run list` / `gh run view --log-failed`：核对 workflow 真实运行结果，不是猜测。
- 未 push——按用户原话只要求"检查一下"和"告诉我"，没有要求实际推送，所以只停留在本地 commit + 只读排查。

#### 备注

- 未执行 `git push`——用户的问题是"如果我现在（以后）push"，是假设性提问，不是要求立即推送；只做了本地提交和只读的远程状态排查。
- 提交分组是按主题而不是按原始会话阶段做的回顾性重建，无法保证每个中间 commit 单独 checkout 出来都能独立编译通过（尤其 Group A/B 之间，同一个文件如 `QuotaModels.swift`、`ProviderFetchStrategy.swift` 在两组之间有概念上的重叠，只能按"改动的主要动机"分到其中一组）；最终状态（全部 4 个 commit 叠加后）已通过 `swift build`/`swift test` 验证，这个验证过的是最终状态，不是逐个 commit 验证的。如实记录这个已知局限。
- 顺手发现一个跟本次任务无关的既有问题：`ci.yml` 因为 runner 版本落后于 `Package.swift` 的 `swift-tools-version` 要求，每次 push 都会失败（14 秒内报错，从没真正跑过测试）。没有擅自修，留给用户决定是否需要处理。
