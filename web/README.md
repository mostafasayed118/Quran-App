# Quran Yahdi Web

Public website + online reader for قرآن يَهدي. Astro 7 static site — see
`docs/superpowers/specs/2026-10-17-quran-yahdi-web-design.md` for the full design.

## Features
- **Reader** (`/surah/{n}`) — all 114 surahs with mushaf or imlaei view, font size and day/night themes; a `sr-only` plain-Arabic layer exposes every ayah to screen readers.
- **Audio** — per-surah recitations (mp3quran; trust-filtered list + committed snapshot fallback) with a persistent mini-player across navigation; `/reciters` browser with downloads.
- **Search** — full-text ayah search on `/quran` (generated index; client-side Arabic normalization + alef-fold tier for rasm spellings).
- **Tafsir & translations** — curated app packs in a per-surah panel; fetched on demand, cached, off by default.
- **Per-ayah actions** — copy · share · bookmark (local-only) · listen (opens the surah player; per-ayah audio is a later phase).

## Dev
- `npm ci`
- `npm run dev` — dev server

## Scripts

| Script | Purpose |
|---|---|
| `npm run gates` | `check` + `test` + `build` + `budget` — required before every commit |
| `npm run check` | `astro check` (TypeScript strict) |
| `npm run test` | Vitest unit tests |
| `npm run test:e2e` | Playwright smoke (chromium; one-time setup: `npx playwright install chromium`) |
| `npm run budget` | post-build gates: reader JS ≤ 30KB gzip, `dist/` < 2,000 files |
| `npm run build` | static build → `dist/` (`npm run preview` serves it) |

## Data
Quran text lives in `src/data/` and is **generated, never hand-edited**:

```
dart run tools/export_web_data.dart   # from repo root; reads assets/db/quran.sqlite
```

Re-run it only when the app's DB changes; commit the regenerated JSON.

## Deploy
Cloudflare Pages project ← this repo; root directory `web`, output `dist`.
Preview per branch; production from `main`.
