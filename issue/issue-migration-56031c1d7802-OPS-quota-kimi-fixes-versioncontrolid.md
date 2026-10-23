# Phase - v0.14.0 - 大陆可达性兜底 + 额度节奏指示 + Kimi 额度修复

- ID：`migration-56031c1d7802`。
- 类型：`OPS`。
- 状态：已确认约束 / 状态待核对（原文未单列完成状态）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.14.0 - 大陆可达性兜底 + 额度节奏指示 + Kimi 额度修复。

## 当前需求与范围

> **背景**：用户截图显示应用内「检查更新」报错「无法连接到 GitHub，请检查网络」——`UpdateChecker.swift`
> 直连 `api.github.com` 检查版本、直连 `github.com/.../releases/download/...` 下载 dmg，这两条请求在中国大陆
> 网络环境下都可能不可达。同一问题也存在于官网：`site/src/pages/index.astro` 的 `UPDATE_DOWNLOAD` 脚本
> 同样在**访客浏览器端**直连 `api.github.com` 取最新 dmg 直链，官网下载按钮在大陆同样可能失效。
>
> 用户参考了附带的 ChatGPT 对话（推荐"客户端永远只访问自己的域名，GitHub 只做构建/发布源"的架构），
> 但明确简化为自己的落地方案："两步备份验证：1. 优先访问 GitHub 更新下载；2. 不行则自动访问 Vercel，
> Vercel 上应该总是能获取到最新的包。" 采用**实时服务端代理**而不是 CI 构建时同步镜像文件：
> Vercel Serverless Function 在请求时现查 GitHub Releases API + 现拉 dmg 资产转发，无需改动
> `.github/workflows/release.yml`（发布流水线不变、风险最小），因为 Vercel 项目 Root Directory 是仓库根目录
> （`.vercel/repo.json` 的 `directory: "."` 已确认），新增 `/api/*.js` 在仓库根目录生效。
>
> **成本提示**：QuotaBar.app 当前约 6.5MB，dmg 预计个位数到十几 MB，每次 fallback 触发的流式转发对 Vercel
> 带宽成本可忽略；仅在 GitHub 直连失败时才会触发，日常不产生额外流量。
>
> **执行中发现的意外前提（2026-07-18）**：调研发现 GitHub 仓库 `DDonlien/quota-bar` 当时是 **private**——
> 未认证请求（包括本来要写的 Vercel 代理、以及所有访客浏览器）访问 `api.github.com` 一律 404，这不是"大陆连不上"
> 而是"谁都连不上"（404，不是超时/连接失败）。这也解释了官网下载按钮为什么一直在悄悄 fallback 到构建时
> hardcode 的旧 dmg 直链（`catch` 静默吞掉了失败）。跟用户确认后（见本 phase 顶部决策），已执行
> `gh repo edit --visibility public`（执行前完整扫描过 git 全部历史的文件名 + 内容 pickaxe，确认没有真实
> 泄漏的密钥/私钥/token，只有测试 fixture 里的占位字符串如 `sk-ant-xxx`）。仓库现在是 public，本 phase 的
> 代理函数按"两者都是未认证的正常直连"实现，不需要额外的 `GITHUB_TOKEN`。

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
