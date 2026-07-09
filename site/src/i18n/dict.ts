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
  "pricing.badge": "Limited Time · Beta Exclusive",
  "pricing.heading": "Download now, get Pro free for life",
  "pricing.subheading": "We're still in Beta — every Beta downloader gets a full Pro license automatically at launch.",
  "pricing.plan.name": "Quota Bar Pro",
  "pricing.plan.note": "Free during Beta · $14.99 at launch",
  "pricing.bullet.unlimited": "Unlimited Services Tracking",
  "pricing.bullet.support": "Priority Support",
  "pricing.bullet.updates": "Unlimited sessions & future updates",
  "pricing.bullet.swift": "Native Swift Performance",
  "pricing.cta": "Get Pro Free",
  "pricing.support.hint": "Payment issues? taobe@freshli4.com",

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
  "footer.col.product": "PRODUCT",
  "footer.col.legal": "LEGAL",
  "footer.link.compare": "Compare",
  "footer.link.manage": "Manage License",
  "footer.link.affiliate": "Affiliate",
  "footer.link.privacy": "Privacy",
  "footer.link.terms": "Terms",
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
  "pricing.badge": "限时免费 · Beta 专享",
  "pricing.heading": "现在下载，正式版 Pro 永久免费送",
  "pricing.subheading": "产品仍处于 Beta 阶段，所有当前下载用户都会在正式版发布时自动获得 Pro 授权。",
  "pricing.plan.name": "Quota Bar Pro",
  "pricing.plan.note": "Beta 期间免费 · 正式价 $14.99",
  "pricing.bullet.unlimited": "无限服务追踪",
  "pricing.bullet.support": "优先技术支持",
  "pricing.bullet.updates": "无限会话及后续更新",
  "pricing.bullet.swift": "Swift 原生级性能",
  "pricing.cta": "免费领取 Pro",
  "pricing.support.hint": "付款问题请联系 taobe@freshli4.com",

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
  "footer.col.product": "产品",
  "footer.col.legal": "法律",
  "footer.link.compare": "功能对比",
  "footer.link.manage": "授权管理",
  "footer.link.affiliate": "推广合作",
  "footer.link.privacy": "隐私政策",
  "footer.link.terms": "服务条款",
};

export const dictionaries: Record<Locale, Dict> = { en, zh };

/** 取字符串：优先目标 locale，缺失则 fallback 英文，再缺失则原样返回。 */
export function t(locale: Locale, key: string): string {
  return dictionaries[locale]?.[key] ?? dictionaries.en[key] ?? key;
}
