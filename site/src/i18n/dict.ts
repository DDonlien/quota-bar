// 翻译字典。结构以"语义块"为单位，方便按区域编辑。
//   - key 用 flatten dot 命名（'nav.changelog'）
//   - 类型安全：Dict 类型要求每个 key 在两套语言里都存在。
//   - 若某 key 在目标 locale 缺失，自动 fallback 到英文。

export const SUPPORTED_LOCALES = ["en", "zh"] as const;
export type Locale = (typeof SUPPORTED_LOCALES)[number];

export const LOCALE_LABELS: Record<Locale, string> = {
  en: "EN",
  zh: "中文",
};

export type Dict = Record<string, string>;

// ───── English (fallback) ─────
const en: Dict = {
  // Nav
  "nav.changelog": "Changelog",
  "nav.download": "Download",

  // Hero
  "hero.title.line1": "Never lose track of",
  "hero.title.lead": "your",
  "hero.title.tail": "quotas",
  // 英文版强制单行（mobile 除外）：与中文"提前掌握额度上限"语义对等
  "hero.subtitle": "Stay ahead of every limit.",
  "hero.cta.download": "Download for Free",
  "hero.cta.docs": "View Pricing",

  // ProductPreview (3 个 tab：总览 / 详情 / 调整)
  // 英文用单字短词 — 不换行 + 直接传达动作
  "product.tab.monitor": "Glance",
  "product.tab.approve": "Detail",
  "product.tab.adjust": "Reorder",
  "product.heading.monitor": "Glance your quotas right from the menu bar — no windows, no clicks.",
  "product.heading.approve": "Every model, every tier — one dropdown away.",
  "product.heading.adjust": "Reorder any asset by drag — the menu bar follows instantly.",

  // Features (9 cards)
  "feature.1.title": "Multi-Service Support",
  "feature.1.desc": "Track GitHub, OpenAI, Vercel, and custom endpoints all in one place.",
  "feature.2.title": "Menu Bar Integration",
  "feature.2.desc": "Glanceable status bars right in your macOS menu bar for quick access.",
  "feature.3.title": "Custom Alerts",
  "feature.3.desc": "Get notified before you hit your limits and blow your budget.",
  "feature.4.title": "Native Performance",
  "feature.4.desc": "Built with Swift for minimal resource usage. Fast, light, and invisible.",
  "feature.5.title": "Secure & Private",
  "feature.5.desc": "Your API keys never leave your machine. Fully private and secure.",
  "feature.6.title": "Auto-Refresh",
  "feature.6.desc": "Real-time sync with your service usage data automatically.",
  "feature.7.title": "Native by Design",
  "feature.7.desc": "Mirrors macOS native UI — feels built into the system.",
  "feature.8.title": "One-Click Access",
  "feature.8.desc": "Detailed stats dropdown with a single click from the menu bar.",
  "feature.9.title": "Drag-to-Reorder",
  "feature.9.desc": "Drag any asset in the dropdown panel — the menu bar instantly follows your new order.",

  // Supported Services — provider pills + app/web/cli 提示
  "services.heading": "Supported Services",
  "services.note": "Available quota data varies across app, web, and CLI.",

  // Pricing — Beta 限时免费：现在下载即可在正式版发布时自动获得 Pro 授权
  "pricing.badge": "7-Day Free Trial",
  "pricing.heading": "Quota Bar Pro — $4.99, one time",
  "pricing.subheading": "Every download includes a full 7-day free trial of Pro — no credit card required.",
  "pricing.plan.name": "Quota Bar Pro",
  "pricing.plan.note": "One-time purchase · includes future updates",
  "pricing.bullet.autoupdate": "Automatic updates",
  "pricing.bullet.oneclick": "One-click install",
  "pricing.bullet.support": "Priority Support",
  "pricing.cta": "Start Free Trial",
  "pricing.support.hint": "Payment issues? taobe@ddonlien.com",

  // Pricing — Open Source card (build-it-yourself track, sits next to the Pro card)
  "pricing.opensource.badge": "Open Source",
  "pricing.opensource.plan.name": "Build it yourself",
  "pricing.opensource.amount": "Free",
  "pricing.opensource.note": "Full source on GitHub · same features",
  "pricing.opensource.bullet.source": "Complete, unrestricted source code",
  "pricing.opensource.bullet.community": "Community support via GitHub Issues",
  "pricing.opensource.cta": "View on GitHub",

  // FAQ
  // q1 「What services are supported?」已删除 — 与中段 SupportedServices section 重复
  "faq.heading": "Frequently Asked Questions",
  "faq.q2": "Is it secure?",
  "faq.a2":
    "Absolutely. Your API keys and data never leave your local machine. Quota Bar communicates directly with the service providers.",
  "faq.q3": "Does it work on Windows?",
  "faq.a3":
    "No, Quota Bar is exclusively built for macOS to deeply integrate with the menu bar and deliver native performance.",
  "faq.q4": "Is this a subscription?",
  "faq.a4":
    "No! Quota Bar is a one-time purchase. You get lifetime access to the current features and all future minor updates.",

  // Changelog page (in-site, not linking out to GitHub)
  "changelog.heading": "Changelog",
  "changelog.subheading": "What's new in Quota Bar, straight from the build log.",
  "changelog.back": "← Back to home",
  "changelog.v10.version": "v0.10.0",
  "changelog.v10.date": "Jul 8, 2026",
  "changelog.v10.title": "Steadier quota refresh",
  "changelog.v10.bullet1": "Added quota detection support for opencode",
  "changelog.v10.bullet2": "Fixed refresh interval and timeout settings not taking effect",
  "changelog.v10.bullet3": "Versioning switched fully to Semantic Versioning",
  "changelog.v9.version": "v0.9.0",
  "changelog.v9.date": "Jul 7, 2026",
  "changelog.v9.title": "Auto-update & diagnostics",
  "changelog.v9.bullet1": "The app can now auto-update without an Apple Developer certificate",
  "changelog.v9.bullet2": "Added per-provider diagnostic logs so auth failures are easy to spot",
  "changelog.v9.bullet3": "Fixed quota fetching for Kimi, Codex, MiniMax, and Claude",
  "changelog.v9.bullet4": "Redesigned the dropdown's display rules to cut visual noise",
  "changelog.v5.version": "v0.5.0",
  "changelog.v5.date": "Jul 3, 2026",
  "changelog.v5.title": "More subscription services",
  "changelog.v5.bullet1": "Merged in quota tracking for several more subscription-based services",
  "changelog.v5.bullet2": "Unified fetch pipeline makes adding new services faster",
  "changelog.v2.version": "v0.2.0",
  "changelog.v2.date": "Jul 1, 2026",
  "changelog.v2.title": "Preferences arrive",
  "changelog.v2.bullet1": "Brand-new Preferences window for display and refresh behavior",
  "changelog.v2.bullet2": "Added GLM as a supported service",
  "changelog.v2.bullet3": "Added subscription-expiry reminders",
  "changelog.v1.version": "v0.1.0",
  "changelog.v1.date": "Jun 29, 2026",
  "changelog.v1.title": "First beta",
  "changelog.v1.bullet1": "Menu bar shows live quota bars for Codex, MiniMax, and Kimi",
  "changelog.v1.bullet2": "One-click refresh and a Preferences entry point",

  // Footer
  "footer.tagline": "Visualize your API Quotas in your Menu Bar",
  "footer.col.legal": "LEGAL",
  "footer.link.privacy": "Privacy",
  "footer.link.terms": "Terms",

  // Privacy policy
  "privacy.back": "← Back to home",
  "privacy.heading": "Privacy Policy",
  "privacy.updated": "Last updated: July 19, 2026",
  "privacy.intro": "Quota Bar is a macOS menu bar app that reads your locally-stored AI provider credentials (API keys, OAuth tokens, session cookies) to display your remaining usage quotas. This page explains exactly what data the app and this website touch, and — just as importantly — what they never do.",
  "privacy.s1.title": "1. What the macOS app reads, and where it goes",
  "privacy.s1.body1": "To show your quota bars, Quota Bar reads credential files, Keychain entries, and local config that each AI provider's own official tool (Claude Code, Codex, Kimi, MiniMax, Antigravity, Z Code, opencode, etc.) already stores on your Mac. It uses those credentials to call each provider's own official API directly from your machine — the same way their own CLI or app would.",
  "privacy.s1.body2": "None of that data — your credentials, tokens, cookies, quota numbers, or account identifiers — is ever sent to Quota Bar's own servers. There is no account system, no login, and no telemetry SDK built into the app. Your quota data is computed and displayed entirely on your device.",
  "privacy.s1.body3": "The only network requests the app makes to a Quota Bar–operated domain (quotabar.ddonlien.com) are anonymous update checks — asking \"what's the latest version?\" and, if needed, downloading the installer. These requests carry no account identifier, no credentials, and no usage data.",
  "privacy.s2.title": "2. Local storage on your Mac",
  "privacy.s2.body1": "Cached quota snapshots, preferences, and diagnostic logs are stored locally under ~/Library/Application Support/QuotaBar/. This data stays on your device; it is not synced to any cloud service. You can delete it at any time by removing that folder.",
  "privacy.s3.title": "3. This website (quotabar.ddonlien.com)",
  "privacy.s3.body1": "This site uses no third-party analytics, no advertising trackers, and sets no tracking cookies. It only uses your browser's local storage for two functional purposes: remembering your language preference, and briefly caching the resolved download link so repeat visits don't hit the update API unnecessarily. Neither is used to identify or track you.",
  "privacy.s3.body2": "As with any website, our hosting provider (Vercel) may log standard technical request data (IP address, user agent, timestamp) for security and operational purposes, under Vercel's own privacy policy.",
  "privacy.s4.title": "4. Third-party services",
  "privacy.s4.body1": "When Quota Bar fetches your quota from an AI provider (e.g. Anthropic, OpenAI, Moonshot/Kimi, MiniMax, Google), that request goes directly from your Mac to that provider using your own credentials, and is governed by that provider's own privacy policy — not this one. Source code and releases are hosted on GitHub, and downloads may be served through GitHub or through our Vercel-hosted mirror, both governed by their respective providers' policies.",
  "privacy.s5.title": "5. Children's privacy",
  "privacy.s5.body1": "Quota Bar is a developer tool and is not directed at children. We do not knowingly collect information from children.",
  "privacy.s6.title": "6. Changes to this policy",
  "privacy.s6.body1": "If this policy changes in a meaningful way, we'll update the date at the top of this page. Continued use of the app or site after a change means you accept the update.",
  "privacy.s7.title": "7. Contact",
  "privacy.s7.body1": "Questions about this policy? Email taobe@ddonlien.com.",

  // Terms of service
  "terms.back": "← Back to home",
  "terms.heading": "Terms of Service",
  "terms.updated": "Last updated: July 19, 2026",
  "terms.intro": "These terms govern your use of Quota Bar (the macOS app) and quotabar.ddonlien.com (this website). By downloading, installing, or using Quota Bar, or by using this site, you agree to these terms.",
  "terms.s1.title": "1. What Quota Bar is",
  "terms.s1.body1": "Quota Bar is a menu bar utility for macOS that reads locally-stored credentials for various AI coding tools and displays your remaining subscription/API quota. It does not modify your accounts, does not consume your quota by itself, and does not act on your behalf with any provider beyond read-only usage queries.",
  "terms.s2.title": "2. Open source and official builds",
  "terms.s2.body1": "Quota Bar's source code is publicly available on GitHub, and building it yourself is completely free — this path is never gated behind any payment. We also offer an officially signed and notarized build for anyone who prefers a ready-to-run install with automatic updates: it includes a free 7-day trial of the full Pro feature set, no credit card required. After the trial, continued use is a one-time purchase of $4.99 (not a subscription) that includes future updates. License activation details — such as how many Macs a license covers and how to recover a lost license — will be published on this page before the paid build ships. Checkout, once available, will be handled by our payment provider, who acts as merchant of record for that purchase and is responsible for payment processing, applicable tax, and refunds under its own policy.",
  "terms.s3.title": "3. No warranty",
  "terms.s3.body1": "Quota Bar is provided \"as is,\" without warranty of any kind, express or implied, including but not limited to fitness for a particular purpose, accuracy of displayed quota data, or uninterrupted availability. Quota numbers are read from third-party APIs we don't control and may be delayed, incomplete, or wrong.",
  "terms.s4.title": "4. Limitation of liability",
  "terms.s4.body1": "To the maximum extent permitted by law, we are not liable for any indirect, incidental, or consequential damages arising from your use of Quota Bar or this website, including reliance on displayed quota data to make usage decisions.",
  "terms.s5.title": "5. Acceptable use",
  "terms.s5.body1": "Don't use Quota Bar to abuse, scrape, or overload any third-party provider's API beyond normal quota-checking use. You're responsible for complying with each AI provider's own terms of service when Quota Bar reads and queries their APIs on your behalf, locally, using your own credentials.",
  "terms.s6.title": "6. Changes",
  "terms.s6.body1": "We may update these terms as the product evolves (for example, once official-build licensing is finalized). We'll update the date at the top of this page when we do.",
  "terms.s7.title": "7. Contact",
  "terms.s7.body1": "Questions about these terms? Email taobe@ddonlien.com.",
};

// ───── 中文 (zh) ─────
const zh: Dict = {
  // Nav
  "nav.changelog": "更新日志",
  "nav.download": "下载",

  // Hero
  "hero.title.line1": "始终掌握",
  "hero.title.lead": "你的",
  "hero.title.tail": "配额",
  "hero.subtitle": "提前掌握额度上限，不打断你的工作流。",
  "hero.cta.download": "免费下载",
  "hero.cta.docs": "查看定价",

  // ProductPreview (3 个 tab：总览 / 详情 / 调整)
  "product.tab.monitor": "总览",
  "product.tab.approve": "详情",
  "product.tab.adjust": "调整",
  "product.heading.monitor": "不打开任何页面，在菜单栏直接看到你的额度。",
  "product.heading.approve": "在下拉菜单里看清所有模型、不同分层的全部维度信息。",
  "product.heading.adjust": "拖一拖就能调整额度显示顺序，菜单栏实时跟随。",

  // Features
  "feature.1.title": "多服务支持",
  "feature.1.desc": "GitHub、OpenAI、Vercel 以及自定义 endpoint，一站式统一追踪。",
  "feature.2.title": "菜单栏集成",
  "feature.2.desc": "状态栏进度条直接挂在 macOS 菜单栏，扫一眼就到位。",
  "feature.3.title": "自定义告警",
  "feature.3.desc": "额度快见底时主动提醒，避免用超爆预算。",
  "feature.4.title": "原生级性能",
  "feature.4.desc": "纯 Swift 实现，资源占用极低——轻、快、无感存在。",
  "feature.5.title": "安全与隐私",
  "feature.5.desc": "API key 仅存于本机，永远不上传第三方。",
  "feature.6.title": "自动刷新",
  "feature.6.desc": "实时同步服务用量数据，无需手动刷新。",
  "feature.7.title": "原生样式呈现",
  "feature.7.desc": "全部组件对齐 macOS 原生规范，跟系统浑然一体。",
  "feature.8.title": "一键查看详情",
  "feature.8.desc": "菜单栏单击即弹下拉面板，详细数据一目了然。",
  "feature.9.title": "自由排序",
  "feature.9.desc": "下拉面板里直接拖拽任意一项，菜单栏的顺序实时跟随。",

  // Supported Services — provider pills + app/web/cli 提示
  "services.heading": "支持哪些服务",
  "services.note": "使用 app、web 和 cli 时，能获取到的额度信息会有所不同。",

  // Pricing — Beta 限时免费：现在下载，正式版发布时自动获得 Pro 授权
  "pricing.badge": "7 天免费试用",
  "pricing.heading": "Quota Bar Pro，一次性 $4.99",
  "pricing.subheading": "每次下载都包含 7 天完整功能免费试用，无需信用卡。",
  "pricing.plan.name": "Quota Bar Pro",
  "pricing.plan.note": "一次性购买 · 包含未来更新",
  "pricing.bullet.autoupdate": "自动更新",
  "pricing.bullet.oneclick": "一键安装",
  "pricing.bullet.support": "优先技术支持",
  "pricing.cta": "开始免费试用",
  "pricing.support.hint": "付款问题请联系 taobe@ddonlien.com",

  // Pricing — 开源自行编译卡片（跟 Pro 卡片并排）
  "pricing.opensource.badge": "开源",
  "pricing.opensource.plan.name": "自行编译",
  "pricing.opensource.amount": "免费",
  "pricing.opensource.note": "GitHub 完整源码 · 功能相同",
  "pricing.opensource.bullet.source": "完整、无限制的源代码",
  "pricing.opensource.bullet.community": "通过 GitHub Issues 获得社区支持",
  "pricing.opensource.cta": "前往 GitHub",

  // FAQ
  // q1 「支持哪些服务？」已删除 — 与中段 SupportedServices section 重复
  "faq.heading": "常见问题",
  "faq.q2": "数据安全吗？",
  "faq.a2":
    "绝对安全。API key 和数据都只存在本机，Quota Bar 直接与服务提供方通讯，不经第三方服务器。",
  "faq.q3": "支持 Windows 吗？",
  "faq.a3":
    "不支持。Quota Bar 专为 macOS 构建，与菜单栏深度集成、追求原生性能。",
  "faq.q4": "是订阅制吗？",
  "faq.a4":
    "不是！Quota Bar 一次性买断，你将获得当前所有功能以及后续小版本更新的终身使用权。",

  // Changelog page（站内，不跳转 GitHub）
  "changelog.heading": "更新日志",
  "changelog.subheading": "Quota Bar 的每一次迭代，都记在这里。",
  "changelog.back": "← 返回首页",
  "changelog.v10.version": "v0.10.0",
  "changelog.v10.date": "2026-07-08",
  "changelog.v10.title": "更稳定的配额刷新",
  "changelog.v10.bullet1": "新增 opencode 配额检测支持",
  "changelog.v10.bullet2": "修复刷新间隔与超时时间设置不生效的问题",
  "changelog.v10.bullet3": "版本号全面切换为语义化版本（SemVer）",
  "changelog.v9.version": "v0.9.0",
  "changelog.v9.date": "2026-07-07",
  "changelog.v9.title": "自动更新与诊断日志",
  "changelog.v9.bullet1": "无需 Apple 开发者证书即可自动更新",
  "changelog.v9.bullet2": "新增按服务的诊断日志，授权失败时一目了然",
  "changelog.v9.bullet3": "修复 Kimi / Codex / MiniMax / Claude 的额度抓取问题",
  "changelog.v9.bullet4": "重新设计下拉面板的信息展示规则，减少视觉噪音",
  "changelog.v5.version": "v0.5.0",
  "changelog.v5.date": "2026-07-03",
  "changelog.v5.title": "更多订阅类服务",
  "changelog.v5.bullet1": "合并多个订阅类服务的额度追踪支持",
  "changelog.v5.bullet2": "打通统一的配额抓取 pipeline，新服务接入更快",
  "changelog.v2.version": "v0.2.0",
  "changelog.v2.date": "2026-07-01",
  "changelog.v2.title": "偏好设置上线",
  "changelog.v2.bullet1": "全新的偏好设置界面，可自定义显示与刷新行为",
  "changelog.v2.bullet2": "新增 GLM 服务支持",
  "changelog.v2.bullet3": "新增订阅到期提醒",
  "changelog.v1.version": "v0.1.0",
  "changelog.v1.date": "2026-06-29",
  "changelog.v1.title": "首个 Beta 版本",
  "changelog.v1.bullet1": "菜单栏实时显示 Codex / MiniMax / Kimi 三项配额进度条",
  "changelog.v1.bullet2": "一键刷新、偏好设置入口",

  // Footer
  "footer.tagline": "在菜单栏里可视化你的 API 配额",
  "footer.col.legal": "法律",
  "footer.link.privacy": "隐私政策",
  "footer.link.terms": "服务条款",

  // Privacy policy
  "privacy.back": "← 返回首页",
  "privacy.heading": "隐私政策",
  "privacy.updated": "最后更新：2026 年 7 月 19 日",
  "privacy.intro": "Quota Bar 是一款 macOS 菜单栏应用，读取你本地已保存的 AI 服务凭证（API Key、OAuth token、会话 Cookie）来展示剩余额度。这个页面准确说明 App 和本网站到底会接触哪些数据——以及同样重要的：它们绝不会做什么。",
  "privacy.s1.title": "1. macOS App 读取什么数据，数据去了哪里",
  "privacy.s1.body1": "为了显示额度条，Quota Bar 会读取各个 AI 服务自己官方工具（Claude Code、Codex、Kimi、MiniMax、Antigravity、Z Code、opencode 等）本来就保存在你 Mac 上的凭证文件、Keychain 条目和本地配置。它用这些凭证直接从你的电脑向各服务商自己的官方 API 发起请求——跟它们自己的 CLI 或 App 做的事情完全一样。",
  "privacy.s1.body2": "这些数据——你的凭证、token、Cookie、额度数字、账号标识——都不会被发送到 Quota Bar 自己的服务器。这个 App 没有账号系统、没有登录、内部也没有任何遥测（telemetry）SDK。你的额度数据完全在你自己的设备上计算和展示。",
  "privacy.s1.body3": "App 唯一会访问 Quota Bar 自己域名（quotabar.ddonlien.com）的请求，是匿名的更新检查——询问「最新版本是什么」，以及必要时下载安装包。这些请求不携带任何账号标识、凭证或额度数据。",
  "privacy.s2.title": "2. 保存在你 Mac 本地的数据",
  "privacy.s2.body1": "缓存的额度快照、偏好设置和诊断日志保存在本地 ~/Library/Application Support/QuotaBar/ 目录下。这些数据只留在你的设备上，不会同步到任何云服务。你随时可以删除这个目录来清除它们。",
  "privacy.s3.title": "3. 本网站（quotabar.ddonlien.com）",
  "privacy.s3.body1": "本网站不使用任何第三方数据分析工具，不投放广告追踪，也不设置任何追踪型 Cookie。它只把浏览器本地存储用于两个功能性用途：记住你的语言偏好，以及短暂缓存已解析出的下载链接，避免重复访问反复请求更新接口。两者都不用于识别或追踪你。",
  "privacy.s3.body2": "和所有网站一样，我们的托管服务商（Vercel）出于安全和运维目的，可能会记录标准的技术请求数据（IP 地址、User Agent、时间戳），这部分受 Vercel 自己的隐私政策约束。",
  "privacy.s4.title": "4. 第三方服务",
  "privacy.s4.body1": "当 Quota Bar 从某个 AI 服务商（如 Anthropic、OpenAI、月之暗面/Kimi、MiniMax、Google）拉取你的额度时，这个请求是从你的 Mac 直接发往该服务商，使用你自己的凭证，受该服务商自己的隐私政策约束——不受本政策约束。源代码和发布包托管在 GitHub 上，下载可能经由 GitHub 或我们在 Vercel 上的镜像提供，两者分别受各自服务商的政策约束。",
  "privacy.s5.title": "5. 儿童隐私",
  "privacy.s5.body1": "Quota Bar 是一款面向开发者的工具，不面向儿童。我们不会有意收集儿童的信息。",
  "privacy.s6.title": "6. 政策变更",
  "privacy.s6.body1": "如果本政策发生实质性变化，我们会更新本页顶部的日期。变更后继续使用本 App 或本网站，即视为你接受该更新。",
  "privacy.s7.title": "7. 联系方式",
  "privacy.s7.body1": "对本政策有疑问？发邮件到 taobe@ddonlien.com。",

  // Terms of service
  "terms.back": "← 返回首页",
  "terms.heading": "服务条款",
  "terms.updated": "最后更新：2026 年 7 月 19 日",
  "terms.intro": "本条款约束你对 Quota Bar（macOS App）和 quotabar.ddonlien.com（本网站）的使用。下载、安装或使用 Quota Bar，或使用本网站，即表示你同意本条款。",
  "terms.s1.title": "1. Quota Bar 是什么",
  "terms.s1.body1": "Quota Bar 是一款 macOS 菜单栏工具，读取本地保存的各类 AI 编程工具凭证，展示你剩余的订阅/API 额度。它不会修改你的账号，不会自行消耗你的额度，除了只读的用量查询之外不会代表你对任何服务商执行任何操作。",
  "terms.s2.title": "2. 开源与官方版本",
  "terms.s2.body1": "Quota Bar 的源代码公开在 GitHub 上，自行编译使用完全免费——这条路径永远不需要付费。我们也提供经过官方签名和公证的构建版本，供希望开箱即用、并享有自动更新的用户使用：这个版本自带 7 天完整 Pro 功能免费试用，无需信用卡；试用结束后继续使用需要一次性购买 $4.99（不是订阅），价格已包含未来的功能更新。授权激活的具体细节——例如一份授权覆盖几台 Mac、丢失后如何找回——会在付费版本正式上线前公布在本页面。结算届时将由我们的支付服务商处理，该服务商作为这笔交易的 Merchant of Record，负责支付处理、相关税费与退款，遵循其自身政策。",
  "terms.s3.title": "3. 不提供担保",
  "terms.s3.body1": "Quota Bar 按「现状」提供，不提供任何明示或暗示的担保，包括但不限于特定用途适用性、展示额度数据的准确性，或不中断的可用性。额度数字读取自我们不掌控的第三方 API，可能延迟、不完整或有误。",
  "terms.s4.title": "4. 责任限制",
  "terms.s4.body1": "在法律允许的最大范围内，我们不对因使用 Quota Bar 或本网站（包括依赖展示的额度数据做出使用决策）而产生的任何间接、附带或衍生损失承担责任。",
  "terms.s5.title": "5. 合理使用",
  "terms.s5.body1": "请勿利用 Quota Bar 滥用、爬取或对任何第三方服务商的 API 造成超出正常额度查询范围的负载。当 Quota Bar 在本地使用你自己的凭证代表你读取、查询这些服务商的 API 时，你需要自行遵守各服务商自己的服务条款。",
  "terms.s6.title": "6. 条款变更",
  "terms.s6.body1": "随着产品迭代（例如官方版本授权方案最终确定后），我们可能会更新本条款。变更时会更新本页顶部的日期。",
  "terms.s7.title": "7. 联系方式",
  "terms.s7.body1": "对本条款有疑问？发邮件到 taobe@ddonlien.com。",
};

export const dictionaries: Record<Locale, Dict> = { en, zh };

/** 取字符串：优先目标 locale，缺失则 fallback 英文，再缺失则原样返回。 */
export function t(locale: Locale, key: string): string {
  return dictionaries[locale]?.[key] ?? dictionaries.en[key] ?? key;
}
