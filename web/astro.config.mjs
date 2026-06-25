// @ts-check
import { defineConfig } from 'astro/config';

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
});
