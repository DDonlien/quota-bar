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
  "hero.cta.docs": "View Documentation",

  // ProductPreview
  "product.tab.monitor": "Monitor",
  "product.tab.approve": "Approve",
  "product.tab.ask": "Ask",
  "product.tab.jump": "Jump",
  "product.heading": "All your quotas, at a glance.",
  "product.heading.monitor": "All your quotas, at a glance.",
  "product.heading.approve": "Approve permissions without leaving your flow.",
  "product.heading.ask": "Answer your agent's questions with one click.",
  "product.heading.jump": "Jump straight back to the terminal that needs you.",

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
  "feature.7.title": "Dark Mode Native",
  "feature.7.desc": "Perfect fit for the macOS aesthetic. Looks great day or night.",
  "feature.8.title": "One-Click Access",
  "feature.8.desc": "Detailed stats dropdown with a single click from the menu bar.",
  "feature.9.title": "API Key Management",
  "feature.9.desc": "Securely store and switch between multiple keys for various services.",

  // Pricing
  "pricing.heading": "Ready to upgrade your workflow?",
  "pricing.subheading": "One-time purchase. No subscriptions.",
  "pricing.plan.name": "Quota Bar Pro",
  "pricing.plan.note": "Lifetime license",
  "pricing.bullet.unlimited": "Unlimited Services Tracking",
  "pricing.bullet.alerts": "Advanced Custom Alerts",
  "pricing.bullet.support": "Priority Support",
  "pricing.bullet.updates": "Unlimited sessions & future updates",
  "pricing.bullet.swift": "Native Swift Performance",
  "pricing.cta": "Get Quota Bar Pro",
  "pricing.support.hint": "Payment issues? hi@quotabar.app",

  // FAQ
  "faq.heading": "Frequently Asked Questions",
  "faq.q1": "What services are supported?",
  "faq.a1":
    "We currently support GitHub, OpenAI, Claude, Vercel, and many more out of the box. You can also configure custom endpoints to track virtually anything.",
  "faq.q2": "Is it secure?",
  "faq.a2":
    "Absolutely. Your API keys and data never leave your local machine. Quota Bar communicates directly with the service providers.",
  "faq.q3": "Does it work on Windows?",
  "faq.a3":
    "No, Quota Bar is exclusively built for macOS to deeply integrate with the menu bar and deliver native performance.",
  "faq.q4": "Is this a subscription?",
  "faq.a4":
    "No! Quota Bar is a one-time purchase. You get lifetime access to the current features and all future minor updates.",

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
  "hero.cta.docs": "查看文档",

  // ProductPreview
  "product.tab.monitor": "监控",
  "product.tab.approve": "审批",
  "product.tab.ask": "提问",
  "product.tab.jump": "跳转",
  "product.heading": "一眼看清所有订阅配额。",
  "product.heading.monitor": "一眼看清所有订阅配额。",
  "product.heading.approve": "不离开工作流就能完成权限审批。",
  "product.heading.ask": "Agent 提问时，点一下就给出答案。",
  "product.heading.jump": "一步跳回那个需要你的终端标签。",

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
  "feature.7.title": "原生深色模式",
  "feature.7.desc": "贴合 macOS 视觉语言，昼夜都好看。",
  "feature.8.title": "一键查看详情",
  "feature.8.desc": "菜单栏单击即弹下拉面板，详细数据一目了然。",
  "feature.9.title": "API Key 管理",
  "feature.9.desc": "安全保存并在多个 key 之间快速切换。",

  // Pricing
  "pricing.heading": "准备升级你的工作流？",
  "pricing.subheading": "一次性买断，无任何订阅。",
  "pricing.plan.name": "Quota Bar Pro",
  "pricing.plan.note": "终身授权",
  "pricing.bullet.unlimited": "无限服务追踪",
  "pricing.bullet.alerts": "高级自定义告警",
  "pricing.bullet.support": "优先技术支持",
  "pricing.bullet.updates": "无限会话及后续更新",
  "pricing.bullet.swift": "Swift 原生级性能",
  "pricing.cta": "购买 Quota Bar Pro",
  "pricing.support.hint": "付款问题请联系 hi@quotabar.app",

  // FAQ
  "faq.heading": "常见问题",
  "faq.q1": "支持哪些服务？",
  "faq.a1":
    "目前原生支持 GitHub、OpenAI、Claude、Vercel 等多项服务；你也可以配置自定义 endpoint 来追踪任何想要的内容。",
  "faq.q2": "数据安全吗？",
  "faq.a2":
    "绝对安全。API key 和数据都只存在本机，Quota Bar 直接与服务提供方通讯，不经第三方服务器。",
  "faq.q3": "支持 Windows 吗？",
  "faq.a3":
    "不支持。Quota Bar 专为 macOS 构建，与菜单栏深度集成、追求原生性能。",
  "faq.q4": "是订阅制吗？",
  "faq.a4":
    "不是！Quota Bar 一次性买断，你将获得当前所有功能以及后续小版本更新的终身使用权。",

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
