# web/ — Quran Yahdi Web (Astro 7, static site)

## What this is

The public website + online reader for قرآن يَهدي. Astro 7, `output: 'static'`, TypeScript
strict, **one** production dependency (`astro`). No server, no auth, no database, no client
framework. Deployed to Cloudflare Pages (root directory `web`, output `dist`).

The Flutter app in `lib/` is a separate owner-supervised campaign — do not couple the two.

## Layout

| Path | Owns |
|---|---|
| `src/pages/**` | Routes only. AR at the root, EN mirrored under `/en/**`. A route wires a layout + a page component; it holds no logic. |
| `src/components/pages/*.astro` | The page views (one per feature). |
| `src/components/*.astro` | Shared components (header, footer, mini player, panels). |
| `src/lib/*.ts` | **All** domain logic and data access: pure functions, typed loaders, the i18n dictionary, the reader modules. |
| `src/data/**`, `public/data/**` | **Generated.** Never hand-edited (see *Data* below). |
| `public/manifest.webmanifest`, `public/icon-*.png` | Static install assets; the brand script regenerates the icons from `src/assets/brand/logo-master.png`. |
| `public/.well-known/security.txt` | Security contact (RFC 9116). |
| `src/styles/**` | Global tokens + the global stylesheet. |
| `scripts/*.mjs` | The budget gate, the OG image generator, and the reciter snapshot fetch; `scripts/prepare_brand_assets.py` writes the brand/PWA icons. |
| `tests/unit/**` | Vitest (DOM-free — `vitest.config.ts` has no jsdom). |
| `tests/e2e/**` | Playwright (the behavioural contract for the reader, player, layout and locales). |

## Rules

- **`lib/` is the only place for logic.** No `process.cwd()` file reads, no raw `src/data/**`
  imports outside `src/lib/`, no `import.meta.glob` outside `src/lib/`.
- **Dependency direction:** `pages → components/pages → components → lib`. A `lib/` module never
  imports a component, and there are no cycles.
- **Every user-visible string** goes through `src/lib/strings.ts` (`StringKey` + `t(locale, key)`);
  the AR and EN maps stay symmetric.
- **Every page carries canonical + `ar`/`en`/`x-default` alternates, OG/Twitter meta and one static
  `WebSite`/`Organization` JSON-LD block.** The 404 is deliberately `noindex` and omits canonical.
- **TypeScript strict:** no `any`, no `@ts-ignore`, no `as any`. `npm run check` is the gate.
- **The client JS budget is a gate, not a wish.** `npm run budget` measures the REAL closure
  (static *and* dynamic imports) of seven pages — reader, quran index, home, prayer-times index,
  one prayer-times city, reciters and the English home — and enforces: per-page JS (reader
  ≤ 30 KB gzip, quran/home/prayer-times/reciters/en-home ≤ 25 KB), the lazy search index
  (≤ 240 KB gzip), other lazy chunks (the verse-search worker included), the CSS bundle
  (linked stylesheets *and* inline `<style>`), the font payload, the runtime-fetched
  prayer-times JSON, the largest built HTML page, the `dist/` file count, and the CSP script
  hashes.
- **CSP:** `script-src 'self'` — no `'unsafe-inline'`. Every inline script is covered by an exact
  `sha256-` in `public/_headers`. Adding or editing an inline script means re-running
  `npm run budget` and pasting the hashes it prints into `public/_headers`; the gate fails on drift.
  `style-src` needs no `'unsafe-inline'` because `astro.config.mjs` sets
  `build.inlineStylesheets: 'never'`. `require-trusted-types-for 'script'` is deliberately absent:
  Astro's `<ClientRouter>` (shipped in `BaseLayout`) assigns `innerHTML` and parses with
  `DOMParser`, so the directive would break every SPA navigation.
- **Pinned upstream sources:** the tafsir and translation packs are fetched from `cdn.jsdelivr.net`
  at an immutable commit SHA, never at a tag. The un-pin guard is a unit test.
- **Accessibility is a requirement:** skip link, `main tabindex="-1"`, the `sr-only` plain-Arabic
  layer, `:focus-visible`, reduced-motion support.
- **Generated data is committed.** The Dart export tools write `src/data/**` (Quran text/search
  index) and `public/data/prayer-times/**`; `scripts/fetch-reciters.mjs` writes the reciter snapshot;
  `scripts/generate-og.mjs` writes `public/og/**`.

## Gates — all must pass before a commit

`npm run gates` = `check` → `test` → `build` → `budget` → `test:e2e`.
CI (`.github/workflows/web.yml`) runs exactly this battery, plus `npm audit --omit=dev`.

| Script | Purpose |
|---|---|
| `npm run check` | `astro check` — TypeScript strict, 0 errors |
| `npm run test` | Vitest unit tests (DOM-free) |
| `npm run build` | static build → `dist/` (≈550 pages: 114 surahs × 2 locales + the rest) |
| `npm run budget` | the size/CSP gate described above |
| `npm run test:e2e` | Playwright specs (chromium: `npx playwright install chromium`) |

## Data

Quran text lives in `src/data/` and is **generated, never hand-edited**:

```
dart run tools/export_web_data.dart   # from repo root; reads assets/db/quran.sqlite
```

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
loader in `src/lib/prayer-times.ts` (no `process.cwd()`), and the year window is derived from the
shipped data — never hardcoded.
`tests/unit/prayer-window.test.ts` fails about three months before the committed window ends; the
monthly `web-gates` schedule runs it even without pushes, and the fix is to bump `startYear`/`endYear`
in `tools/export_web_prayer_times.dart`, regenerate with `TZ=UTC`, and commit the result.

## Deploy

Cloudflare Pages project ← this repo; root directory `web`, output `dist`.
Preview per branch; production from `main`.
After a production deploy, submit `https://quranyahdi.pages.dev/sitemap.xml` to Google Search Console (owner step).

### Deploy runbook

- **Rollback:** Cloudflare dashboard → Pages → the project → Deployments → the last known-good
  deployment → **Rollback**. No code change is needed; this is an owner step.
- **Post-deploy checks:** `/` returns 200 with a `Content-Security-Policy` whose hash list matches
  `npm run budget`; `/sitemap.xml` returns 200 with 554 `<loc>` (AR + EN); an unknown path returns
  404 with `robots noindex`; `/.well-known/assetlinks.json` carries the current release fingerprint.
- **Deploy config:** the build command, output dir (`dist`), Node version, env vars, branch
  mapping and custom-domain settings are dashboard-only. Keep them in sync with `package.json`
  (`engines`) and this file; changing them is an owner step.
- **Domain migration:** the origin is hardcoded in `astro.config.mjs`, `src/lib/urls.ts`,
  `public/robots.txt` and `scripts/generate-og.mjs`. Change all four, regenerate the 114 OG cards
  (`npm run og`), and re-run the gates.
- **Open:** no `wrangler.toml`/`_redirects` in the repo; no service worker (offline reading is a
  P5 item; the manifest is installability only); no analytics (tracker-free by design); no
  ESLint/Prettier gate (adding one is a dependency decision).

## Docs

- Full design: `docs/superpowers/specs/2026-10-17-quran-yahdi-web-design.md`
- Astro reference: <https://docs.astro.build>
