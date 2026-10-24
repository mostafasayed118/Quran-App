# Quran Yahdi Web

Public website + online reader for قرآن يَهدي. Astro 7 static site — see
`docs/superpowers/specs/2026-10-17-quran-yahdi-web-design.md` for the full design.

## Features

- **Landing** (`/`) — hero with the name-source ayah, the 14-feature grid, the brand promise and download CTAs (GitHub Releases live; Play badge coming-soon).
- **Resume card** — the landing reads `qy:last-read` (written by the reader) and links straight back to the last ayah.
- **Reader** (`/surah/{n}`) — all 114 surahs with mushaf or imlaei view, font size and day/night themes; a `sr-only` plain-Arabic layer exposes every ayah to screen readers.
- **Audio** — per-surah recitations (mp3quran; trust-filtered list + committed snapshot fallback) with a persistent mini-player across navigation; `/reciters` browser with downloads.
- **Search** — bilingual full-text ayah search on `/quran` (Arabic index) and `/en/quran` (English index); client-side normalization, an alef-fold tier for rasm spellings, ranked in a worker.
- **Tafsir & translations** — curated app packs in a per-surah panel; fetched on demand, cached, off by default.
- **Per-ayah actions** — copy · share · bookmark (local-only) · listen (opens the surah player; per-ayah audio is a later phase).
- **About & Privacy** — `/about` mission + offline-first story; `/privacy` renders the repo `PRIVACY.md` single source (EN mirror from `PRIVACY.en.md`), now including the website's localStorage, geolocation and hosting flows; the footer links a contact address.
- **EN locale** — every route is mirrored at `/en/**` with LTR chrome (`lang="en"`), reader included; the header language switch round-trips.
- **English translation** — every `/en/surah/{n}` page pre-renders the Saheeh International translation under each ayah (SSR, indexable); the mushaf pages layout hides it.
- **Offline** — a versioned service worker caches visited pages/assets and serves `/offline/` (EN mirror `/en/offline/`) when the network is gone; the manifest handles installability.
- **Prayer times** — `/prayer-times` city index (156 cities, instant filter) + per-city pages with a 24-month table, today highlighted, month switcher and an imsakiah (imsak/iftar) view; times are precomputed in each city's local time.
- **Qibla** — `/qibla` client-side great-circle bearing to the Kaaba with an SVG compass; uses the device location (graceful denial → city picker).
- **404** — localized not-found page with search and home links; `noindex`, no canonical and no broken EN alternate.
- **SEO** — canonical + `hreflang` alternates + OG/Twitter meta per page; `sitemap.xml` lists both locales as `<loc>` (each with alternates and a build-date `<lastmod>`) and `robots.txt`; one static `WebSite` + `Organization` JSON-LD block per page.

## Dev

- `npm ci`
- `npm run dev` — dev server

## Scripts

| Script                 | Purpose                                                                                                                                                                                                                                                                                                                                       |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `npm run gates`        | `format:check` + `check` + `test` + `build` + `budget` + `test:e2e` — required before every commit; CI runs exactly this                                                                                                                                                                                                                      |
| `npm run format`       | Prettier write pass (`prettier-plugin-astro`)                                                                                                                                                                                                                                                                                                 |
| `npm run format:check` | Prettier check — the first gate                                                                                                                                                                                                                                                                                                               |
| `npm run check`        | `astro check` (TypeScript strict)                                                                                                                                                                                                                                                                                                             |
| `npm run test`         | Vitest unit tests (DOM-free)                                                                                                                                                                                                                                                                                                                  |
| `npm run test:e2e`     | Playwright specs (chromium; one-time setup: `npx playwright install chromium`)                                                                                                                                                                                                                                                                |
| `npm run budget`       | size + CSP gate: per-page JS (reader ≤ 30KB gzip, quran/EN quran/home/prayer-times ≤ 25KB), the lazy Arabic search index (≤ 240KB gzip) and the English index (≤ 360KB gzip), other lazy chunks, CSS, fonts, the largest HTML page (≤ 640KB, the EN surah pages carry the full translation), `dist/` < 2,000 files, and the CSP script hashes |
| `npm run build`        | static build → `dist/` (`npm run preview` serves it)                                                                                                                                                                                                                                                                                          |

## Security headers

`public/_headers` ships the CSP, HSTS, `X-Content-Type-Options`, `X-Frame-Options`,
`Referrer-Policy` and `Permissions-Policy`. `script-src` has **no** `'unsafe-inline'`: every inline
script is allowed by an exact `sha256-`, and `npm run budget` fails if a hash drifts from the
built HTML.

## Data

Quran text lives in `src/data/` and is **generated, never hand-edited**:

```
dart run tools/export_web_data.dart   # from repo root; reads assets/db/quran.sqlite
```

Re-run it only when the app's DB changes; commit the regenerated JSON.

The English reader's translation lives in `src/data/translation-en/` and is a **network snapshot**
(never hand-edited): the Saheeh International edition (`eng-safiurrahmanalm`) from
`fawazahmed0/quran-api`, pinned to commit `47ca096b0976443ba2eab2e45cdf0fb4096a2610`. Regenerate the
114 surah files and `src/data/search-index-en.json` together from the repo root:

```
node web/scripts/fetch-translation.mjs
```

The script validates 114 surahs / 6,236 contiguous ayahs. This snapshot is **not** checked by the
CI `data-drift` job (the fetch needs the network); the upstream project's own terms apply — verify
the translation license before commercial/store use. `src/data/translation-en/SOURCE.md` records the
exact source.

Prayer times live in `public/data/prayer-times/` and are **generated, never hand-edited**:

```
TZ=UTC dart run tools/export_web_prayer_times.dart   # from repo root; reads assets/data/cities.json
```

Windows does not honor `TZ` for this exporter, so adhan rounds in the host timezone; regenerate on
Linux/WSL or let CI do it, and never commit a Windows-generated shift.

Per-city shape: `{ city: { id, nameAr, nameEn, lat, lng, tz }, months: [{ y, m, days: [[fajr, sunrise, dhuhr, asr, maghrib, isha, imsak], ...] }] }` — minutes
since local midnight in the city's own timezone (DST-aware), Egyptian method, `imsak = fajr - 10`.
An isha that falls after local midnight (northern summers) is stored as `1440 + minutes`; render it
with `% 1440`. `index.json` lists every city (slug = `id`); the pages read it through the typed
loader in `src/lib/prayer-times.ts` (no `process.cwd()`), and the covered year window is derived
from the shipped data — never hardcoded in a page.
`tests/unit/prayer-window.test.ts` fails about three months before the committed window ends; the
monthly `web-gates` schedule runs it even without pushes, and the fix is to bump `startYear`/`endYear`
in `tools/export_web_prayer_times.dart`, regenerate with `TZ=UTC`, and commit the result.

## Deploy

Cloudflare Pages project ← this repo; root directory `web`, output `dist`.
Preview per branch; production from `main`.
After a production deploy, submit `https://quranyahdi.pages.dev/sitemap.xml` to Google Search Console (owner step).
