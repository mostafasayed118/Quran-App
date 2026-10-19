// @ts-check
import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://quranyahdi.pages.dev',
  output: 'static',
  i18n: {
    defaultLocale: 'ar',
    locales: ['ar', 'en'],
    routing: { prefixDefaultLocale: false },
  },
  vite: { server: { fs: { allow: ['..'] } } },
});
