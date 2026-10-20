# WW1 — Web SEO tools (prayer times · imsakiah · qibla) — Wave Brief (executor-ready)

**STATUS: READY TO DISPATCH** · Owner-ratified (benchmark roadmap WW1) · Date: 2026-10-19.

You are a fresh web executor session in `E:\old_flutter\Quran-App-master` (branch `main`). Shell: PowerShell 5.1 (no `&&`; use `;`). Single writer for YOUR files (`web/**`, `tools/**`, docs only if listed). **NO PUSH.** Parallel sessions may hold app WIP — never touch or stage `lib/`, `test/` except as listed.

## Goal

Static SEO tool pages for the site (no runtime deps, no server): per-city prayer times + imsakiah, and a qibla tool — reusing the app's trusted prayer-time computation at EXPORT time (precomputed data), Arabic-first with EN mirrors.

## Ground truth (verified 2026-10-19)

- Site: `web/` Astro static (`output: 'static'`), i18n `ar` default + `en` mirrors; Header nav has quran/reciters links; strings in `web/src/lib/strings.ts` (additive+symmetric dict); sitemap built by `web/src/lib/sitemap.ts` + `web/src/pages/sitemap.xml.ts`; data pipeline precedent: `tools/export_web_data.dart` (reads `assets/db/quran.sqlite` via drift → writes `web/src/data/**`); cities live in `assets/data/cities.json` (156 cities).
- Gates: `npm run gates` = check (astro check) + vitest + build + budget (`web/scripts/check-budgets.mjs`) + `npx playwright test` for e2e. No new npm dependencies (budget + house rule).

## Commits

**C1 — `feat(web-tools): prayer-times export (precomputed, 24 months)`**
- New `tools/export_web_prayer_times.dart`: reads `assets/data/cities.json`; reuses the app's `adhan` package + the app's calculation settings (Egyptian method default — mirror `lib/features/prayer/` usage exactly); generates **2026-01-01 → 2027-12-31** for every city (24 months; covers Ramadan 1448/2027).
- Output: `web/public/data/prayer-times/<slug>.json` — compact shape: `{ city: {...}, months: [{ y, m, days: [[fajrMin, sunriseMin, dhuhrMin, asrMin, maghribMin, ishaMin, imsakMin], ...] }] }` (minutes since midnight; imsak = fajr − 10). Slug: ASCII (derive from the city entry; stable). Plus `web/public/data/prayer-times/index.json` (slugs + names).
- **Size guard:** if the total exceeds 12 MB, STOP and report (PM decides: trim cities vs compact further).
- Test (vitest): index lists all cities; one sampled city = 24 months; per-day ordering fajr < sunrise < dhuhr < asr < maghrib < isha; mins within [0,1440).
- Pathspec: `tools/export_web_prayer_times.dart`, `web/public/data/prayer-times/**`, the new test.

**C2 — `feat(web): prayer-times pages + imsakiah view`**
- `/prayer-times/index.astro` + `/en/prayer-times/index.astro`: city grid with instant client filter (reuse `surah-filter` idioms); links to city pages.
- `/prayer-times/[slug].astro` + en mirror: SSR the CURRENT month table (highlight today), a month switcher (client fetch of the city JSON, re-render table; works without URL state), and an «إمساكية» toggle that swaps the table into the imsakiah layout (imsak/iftar columns for Ramadan, full month grid). Follow house tokens/CSS + AR-Indic digits (`lib/arabic-digits.ts`).
- strings: additive pairs (`navPrayerTimes`, `ptTitle`, `ptToday`, `ptMonth`, `ptImsak`, `ptFajr`… as needed — symmetric AR/EN).
- Header nav: add «المواقيت» link (AR/EN). Sitemap: extend `lib/sitemap.ts` + `sitemap.xml.ts` with the new routes (+ its unit test).
- e2e: cities index renders + filter narrows; one city page renders today's row highlighted + month switch changes the table; en mirror 200 + lang switch; meta title present.
- Pathspec: `web/src/pages/prayer-times/**`, `web/src/pages/en/prayer-times/**`, `web/src/components/**` (new page component if needed), `web/src/lib/strings.ts`, `web/src/lib/sitemap.ts`, `web/src/pages/sitemap.xml.ts`, `web/src/components/Header.astro`, `web/tests/**` (new specs + updated sitemap test).

**C3 — `feat(web): qibla tool`**
- `web/src/lib/qibla.ts` — pure great-circle initial-bearing (Kaaba 21.4225, 39.8262) + tests (Cairo ≈ 136°±1; Makkah ≈ 0/360; another known city spot-check).
- `/qibla/index.astro` + en mirror: «استخدم موقعي» (Geolocation API, graceful denial → city picker over the same cities index) → bearing + an SVG compass rose positioned by the computed angle + short how-to text. Fully client-side.
- strings additive; sitemap + e2e (page 200, denial path shows picker).
- Pathspec: `web/src/lib/qibla.ts`, `web/src/pages/qibla/**`, en mirror, strings, sitemap*, tests.

**C4 — `docs(web): tools notes`** (only if useful): a short section in `web/README.md` documenting the export tool + data shape.
- Pathspec: `web/README.md`.

## Gates (each commit + final)
`npm run gates` green (check 0/0/0 · vitest suites counted · build pages counted · budgets PASS) + `npx playwright test` green (counted) at the final tip. Budgets must keep reader/quran within caps; dist page count within `/2000`. Record exact numbers in the report.

## STOP list
Any new npm dependency · any `lib/**`/`test/**`/`assets/**` change · freezing/editing existing web tests (add new; extend sitemap expectations inside the existing sitemap test only if it is additive — otherwise add a new spec) · size guard breach · NO PUSH.
