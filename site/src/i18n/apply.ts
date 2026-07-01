// 客户端运行时：
//   1. 从 localStorage / navigator.language 检测当前 locale
//   2. 把字典 + 检测结果 inline 进 HTML（同步阻塞解析），保证首次绘制前已就绪
//   3. 切换器触发 setLocale() 改 html 属性 + 写 localStorage + 重扫 DOM
//
// 设计取舍：
//   - 用 SSR 输出的"双套文案 + CSS 切 display:none"模式：
//     SSR 时 <html> 没有 data-locale 属性，CSS 默认 [:not([data-locale])] → 显示英文版，
//     然后 head 里的同步脚本立刻设置 data-locale，中文浏览器秒切，无 FOUC
//   - DOM 同步替换 vs CSS 切显示：选了 CSS 切显示
//     (1) 0 JS 开销，无 React/Vue 抖动
//     (2) 切换瞬间完成（改 attribute）
//     (3) HTML 体积稍大（~3KB，可接受）

import { SUPPORTED_LOCALES, type Locale } from "./dict";

const STORAGE_KEY = "qb_locale";

/**
 * 从 navigator.language / navigator.languages 识别目标 locale。
 * 规则：
 *   - 任意 zh-* 或 zh → "zh"
 *   - 其它 → "en"
 *   - SSR / 早期脚本执行时 navigator 可能未就绪，返回 null
 */
export function detectFromNavigator(): Locale | null {
  if (typeof navigator === "undefined") return null;
  const langs =
    navigator.languages && navigator.languages.length
      ? navigator.languages
      : navigator.language
        ? [navigator.language]
        : [];
  for (const l of langs) {
    const tag = String(l).toLowerCase();
    if (tag === "zh" || tag.startsWith("zh-")) return "zh";
  }
  return "en";
}

/** 决定当前 locale：localStorage 优先 → navigator → fallback。 */
export function resolveLocale(): Locale {
  if (typeof window === "undefined") return "en";
  try {
    const stored = window.localStorage.getItem(STORAGE_KEY);
    if (stored && (SUPPORTED_LOCALES as readonly string[]).includes(stored)) {
      return stored as Locale;
    }
  } catch {
    /* localStorage 可能被禁用/超容量，忽略 */
  }
  return detectFromNavigator() ?? "en";
}

/** 把 locale 持久化。 */
export function persistLocale(locale: Locale): void {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.setItem(STORAGE_KEY, locale);
  } catch {
    /* ignore */
  }
}

/**
 * 应用 locale 到 document：改 <html lang> 和 <html data-locale>。
 * 不需要重扫 DOM（CSS 自动按 attribute 切显示）。
 */
export function applyLocale(locale: Locale): void {
  if (typeof document === "undefined") return;
  document.documentElement.lang = locale === "zh" ? "zh-CN" : "en";
  document.documentElement.setAttribute("data-locale", locale);
  document.dispatchEvent(
    new CustomEvent("qb:locale-change", { detail: { locale } })
  );
}
