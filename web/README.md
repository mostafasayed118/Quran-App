# Quran Yahdi Web

Public website + online reader for قرآن يَهدي. Astro 7 static site — see
`docs/superpowers/specs/2026-10-17-quran-yahdi-web-design.md` for the full design.

## Dev
- `npm ci`
- `npm run dev` — dev server
- `npm run gates` — check + unit tests + build (required before every commit)
- `npm run test:e2e` — Playwright smoke (chromium; installs on first run)

## Data
Quran text lives in `src/data/` and is **generated, never hand-edited**:

```
dart run tools/export_web_data.dart   # from repo root; reads assets/db/quran.sqlite
```

Re-run it only when the app's DB changes; commit the regenerated JSON.

## Deploy
Cloudflare Pages project ← this repo; root directory `web`, output `dist`.
Preview per branch; production from `main`.
