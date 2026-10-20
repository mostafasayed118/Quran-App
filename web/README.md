# Quran Yahdi Web

Public website + online reader for قرآن يَهدي. Astro 7 static site — see
`docs/superpowers/specs/2026-10-17-quran-yahdi-web-design.md` for the full design.

## Features
- **Landing** (`/`) — hero with the name-source ayah, the 14-feature grid, the brand promise and download CTAs (GitHub Releases live; Play badge coming-soon).
- **Resume card** — the landing reads `qy:last-read` (written by the reader) and links straight back to the last ayah.
- **Reader** (`/surah/{n}`) — all 114 surahs with mushaf or imlaei view, font size and day/night themes; a `sr-only` plain-Arabic layer exposes every ayah to screen readers.
- **Audio** — per-surah recitations (mp3quran; trust-filtered list + committed snapshot fallback) with a persistent mini-player across navigation; `/reciters` browser with downloads.
- **Search** — full-text ayah search on `/quran` (generated index; client-side Arabic normalization + alef-fold tier for rasm spellings).
- **Tafsir & translations** — curated app packs in a per-surah panel; fetched on demand, cached, off by default.
- **Per-ayah actions** — copy · share · bookmark (local-only) · listen (opens the surah player; per-ayah audio is a later phase).
- **About & Privacy** — `/about` mission + offline-first story; `/privacy` renders the repo `PRIVACY.md` single source (EN mirror from `PRIVACY.en.md`).
- **EN locale** — every route is mirrored at `/en/**` with LTR chrome (`lang="en"`), reader included; the header language switch round-trips.
- **Prayer times** — `/prayer-times` city index (156 cities, instant filter) + per-city pages with a 24-month table, today highlighted, month switcher and an imsakiah (imsak/iftar) view; times are precomputed in each city's local time.
- **Qibla** — `/qibla` client-side great-circle bearing to the Kaaba with an SVG compass; uses the device location (graceful denial → city picker).
- **404** — localized not-found page with search and home links.
- **SEO** — canonical + `hreflang` alternates + OG/Twitter meta per page; `sitemap.xml` (AR+EN with alternates) and `robots.txt`.

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

Prayer times live in `public/data/prayer-times/` and are **generated, never hand-edited**:

```
dart run tools/export_web_prayer_times.dart   # from repo root; reads assets/data/cities.json
```

Per-city shape: `{ city: { id, nameAr, nameEn, lat, lng, tz }, months: [{ y, m, days: [[fajr, sunrise, dhuhr, asr, maghrib, isha, imsak], ...] }] }` — minutes
since local midnight in the city's own timezone (DST-aware), Egyptian method, `imsak = fajr - 10`.
An isha that falls after local midnight (northern summers) is stored as `1440 + minutes`; render it
with `% 1440`. `index.json` lists every city (slug = `id`); the pages read it at build time via `process.cwd()`.

## Deploy
Cloudflare Pages project ← this repo; root directory `web`, output `dist`.
Preview per branch; production from `main`.
After a production deploy, submit `https://quranyahdi.pages.dev/sitemap.xml` to Google Search Console (owner step).
