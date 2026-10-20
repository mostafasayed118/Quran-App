// @ts-check
import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://quranyahdi.pages.dev',
  output: 'static',
  // Every component's <style> ships as one hashed stylesheet instead of being
  // inlined into the page, so the CSP needs no 'unsafe-inline' for styles.
  // (Astro's 'always' means "always inline"; 'never' is the external stylesheet.)
  build: { inlineStylesheets: 'never' },
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
