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
  // fs.allow is dev-server-only and REQUIRED: the privacy pages import the repo-root
  // PRIVACY.md / PRIVACY.en.md as the single source (web/src/pages/privacy.astro:5,
  // web/src/pages/en/privacy.astro:5). Accepted risk (owner-approved 2026-10-19): local
  // dev surface only — production serves the static dist. See ledger.
  vite: { server: { fs: { allow: ['..'] } } },
});
