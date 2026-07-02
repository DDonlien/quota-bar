// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
  // 静态站点，部署到 Vercel / Netlify / GitHub Pages 都兼容。
  // Vercel 会自动识别 Astro，无需 adapter；本地 `vercel --prod` 即可部署。
  output: 'static',
  site: 'https://quotabar.ddonlien.com',
  compressHTML: true,
  build: {
    inlineStylesheets: 'auto',
  },
  integrations: [
    sitemap({
      // i18n 是客户端 JS 切换的：所有语言版本都指向同一个 URL，
      // hreflang 留给 Layout.astro 手动声明，这里不加。
      changefreq: 'weekly',
      priority: 0.8,
    }),
  ],
});
