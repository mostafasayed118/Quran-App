# Quran Yahdi Web — Design Spec (موقع قرآن يَهدي)

Date: 2026-10-17 · Status: design APPROVED (visual companion session `8076-1792263740`, approved mockup:
`.superpowers/brainstorm/8076-1792263740/content/manuscript-v4-logo.html`) · This spec: awaiting owner review
Owner: Mustafa Sayed (mostafasayed118) · Host repo: `Quran-App` — the web project lives in `web/`

---

## 1. Goal

A public website for the **قرآن يَهدي / Quran Yahdi** app that:

1. **Reads Quran online** — 114 surah pages, instantly indexable by search engines, with recitation audio, tafsir/translations, search, bookmarks — same content sources as the app.
2. **Is the official home for the app** — landing, feature showcase, download CTA, privacy policy URL (required by Play Store), about.
3. **Links to the app via share URLs** — every surah/ayah has a canonical URL that opens the installed Android app when tapped (App Links), else opens the web reader.

Non-negotiables (inherited from the app's charter): **free forever — no ads, no subscriptions, no accounts, no tracking.** Runs on 100% free infrastructure.

## 2. Locked Decisions (owner-approved in this session)

| # | Decision | Value |
|---|---|---|
| W1 | Scope v1 | Landing + full online reader. No dashboards, no accounts. |
| W2 | App ↔ web integration | **Share links only.** No sync, no backend. App Links (verified) + web share builder. |
| W3 | Languages v1 | **Arabic (default) + English** — full i18n from day one. |
| W4 | Domain | Free `*.pages.dev` subdomain (target `quranyahdi.pages.dev`, fallback `quran-yahdi-web.pages.dev`). Moving to a custom domain later requires an app-side update (assetlinks + store release) — documented in §8. |
| W5 | Stack | **Astro 7.x (static-first) + React islands + Tailwind CSS 4 + TypeScript**, hosted on **Cloudflare Pages free tier**. No server runtime in v1. |
| W6 | Visual identity | «المَصحف» — locked in v4: warm-paper day theme + logo-green night theme (exact tokens in §3.9; sampled from the real logo file). Logo in the nav. |
| W7 | Data source of truth | Quran text generated **at build time from the app's shipped `assets/db/quran.sqlite`** (byte-identical to the app). |
| W8 | Repo layout | `web/` subfolder inside `Quran-App` repo; design docs under `docs/superpowers/specs/`. |
| W9 | Quality gates | `astro check` + `vitest` + `npm run build` green before every commit; small Playwright smoke; performance budget (§5). |
| W10 | Deployment | Cloudflare Pages connected to GitHub — preview per branch, production from `main`. GitHub Actions runs the gates (workflow path-filtered to `web/**`). |

Note (2026-10-18, P2 close-out): the W5 Tailwind v4 layer remains **wired-but-unused** through P2 — all styling is the token CSS layer (§3.9). Adopt-or-drop is a recorded owner decision for a later wave; this spec stands as-is either way.

## 3. Architecture

### 3.1 Stack detail

| Concern | Choice |
|---|---|
| Framework | Astro 7 (`output: 'static'`), `@astrojs/react` for interactive islands |
| Styling | Tailwind CSS 4 + a small design-token layer (§3.9) as CSS custom properties |
| i18n | Astro built-in i18n routing (`ar` default at `/`, `en` at `/en/`), RTL/LTR switch, hreflang + per-locale sitemap |
| Client state | `localStorage` only (settings, bookmarks, last-read). No cookies. |
| QA | `astro check` (TS strict), Vitest (unit), Playwright (smoke), `astro build` |
| Node | 22.x (Astro 7 minimum is 22.22) |

### 3.2 Repo layout

```
Quran-App/
├── lib/ assets/ android/ ...        # Flutter app (untouched by web work)
├── tools/
│   └── export_web_data.dart         # NEW — data generator (§3.3)
├── web/                             # NEW — Astro project
│   ├── src/
│   │   ├── pages/                   # /, /quran, /surah/[n], /reciters, /about, /privacy, 404
│   │   ├── components/              # Astro components + React islands (player, search, panels)
│   │   ├── data/                    # GENERATED + COMMITTED (surahs.json, ayahs/*.json, search-index.json)
│   │   ├── assets/brand/            # logo-master.png (copy) + generated sizes
│   │   ├── styles/tokens.css        # §3.9 tokens
│   │   └── lib/                     # arabic normalization, url builders, storage helpers
│   ├── public/                      # .well-known/assetlinks.json, fonts/*.woff2, favicon set, robots.txt
│   ├── tests/                       # vitest + playwright
│   └── astro.config.mjs, package.json
└── docs/superpowers/specs/2026-10-17-quran-yahdi-web-design.md   # this file
```

### 3.3 Data pipeline (build-time, committed output)

- `tools/export_web_data.dart` — same pattern as the existing `tools/build_quran_db.dart` (Dart + drift native, proven on this machine): reads `assets/db/quran.sqlite` via the app's schema (`Surahs`, `Ayahs` tables) and writes:
  - `web/src/data/surahs.json` — 114 records (id, nameAr, nameEn, revelationType, ayahCount, pages)
  - `web/src/data/ayahs/<1..114>.json` — per surah: ayahs (numberInSurah, juz, page, textUthmani, textImlaei, sajda)
  - `web/src/data/search-index.json` — raw Imlaei `i` records; normalization applied client-side (§3.5 refinement)
- **Sanity gates in the generator**: 114 surahs, 6236 ayahs, spot-checks vs known ayahs (الفاتحة، آية الكرسي tail, النور ٣٥); non-zero exit on mismatch.
- Output is **committed** (Quran text is immutable); Cloudflare build needs only Node — no Dart on CI.
- Regeneration is manual (`dart run tools/export_web_data.dart`) and documented in `web/README.md`.

### 3.4 Runtime data sources (all free, CORS verified 2026-10-17)

| Need | Source | Notes |
|---|---|---|
| Audio recitations + reciter list | `mp3quran.net/api/v3` + its CDN | API returns `Access-Control-Allow-Origin: *`; audio streamed directly. Same source the app uses. |
| Translations | `cdn.jsdelivr.net` — fawazahmed0/quran-api editions | `*` CORS; fetched per surah on demand |
| Tafsir | `cdn.jsdelivr.net` — spa5k/tafsir_api (pinned tag) | per surah `{n}.json`, fetched on demand |
| Hadith packs | **out of scope v1** (app keeps them; web library phase later) | |

Fallback hardening: the reciter list is snapshotted at build time (`web/src/data/reciters-snapshot.json`) and used if the live API fails.

### 3.5 Search (client-side)

- Index built by the generator: per ayah `{s, a, t}` where `t` = normalized text — tashkeel/tatweel removed, alef/hamza forms unified (أإآٱ→ا), ى→ي; ة kept as-is with a ه-variant indexed as alias (users often type ه).
- Lazy-loaded (`/search-index.json`, ~gz 300–400KB expected) on first search; cached in `localStorage`/Cache Storage.
- Matching: normalized substring + word-prefix match, ranked by (exact > prefix > contains), max 50 results, result → `/surah/{s}#ayah-{a}`.
- **Refinement (as-built, 2026-10-18, P2 — supersedes the build-time-normalized wording above):** the generator emits **raw `i` records** (`{s, a, t}`, `t` = raw imlaei text) in `search-index.json`; normalization lives **once in TS** (`normalizeArabic`, `web/src/lib/arabic.ts`) and is applied **client-side at load**. A second, **alef-fold tolerant tier** (`foldArabic` — bare alefs dropped, `web/src/lib/search.ts`) additionally matches rasm spellings like «السموات» vs the typist «السماوات»; tolerant hits carry a rank offset so **strict hits always rank first**.

### 3.6 Audio (v1 = per-surah, parity with app)

- Reciter picker (list from §3.4) → surah list → play; **persistent mini-player across navigation** via Astro `<ClientRouter />` + `transition:persist` (audio element survives page swaps).
- Download link = plain `download` anchor to the mp3 (no custom download manager on web v1).
- **Per-ayah audio is phase 2** (needs an ayah-level audio source/timings — decision deferred; the approved mockup's per-ayah «استمع» will map to opening the surah player until then).

### 3.7 Translations & tafsir display

- Reader side-panel (desktop) / bottom sheet (mobile): pick one translation + one tafsir from the same curated list the app uses (`assets/data/library_catalog.json` is the pack catalog reference); fetched per surah on demand; attribution line per edition per `docs/store/licensing-matrix.md` constraints.
- Default state: **off** (clean reading page), remembered in `localStorage`.

### 3.8 i18n (AR/EN)

- `/` = Arabic (RTL). `/en/` = English (LTR). Same surah routes mirrored: `/surah/18` ↔ `/en/surah/18`.
- UI strings: typed dictionary in `web/src/lib/strings.ts` (mirrors the app's ARB terminology where applicable — e.g., «المصحف», «التلاوات», prayer-free scope).
- Quran text always Arabic script; in EN mode the translation panel defaults to Saheeh International (if enabled).
- SEO: per-locale `<title>`, description, canonical, `hreflang` (ar/en/x-default), sitemap per locale.

### 3.9 Day/Night design tokens (LOCKED — from approved v4)

**Never hardcode hexes in components — use the token layer.**

| Token | Day «ورقة المَصحف» | Night «أخضر اللوجو» |
|---|---|---|
| `--bg-solid` | `#F2ECDD` | gradient `#012E2B → #012A27 → #012321` |
| `--ink` | `#232D28` | `#F0E0C6` |
| `--muted` | `rgba(35,45,40,.6)` | `rgba(240,224,198,.55)` |
| `--muted-strong` (added during P1 for AA on normal-size chrome text; --muted unchanged; enforced by the contrast test) | `rgba(35,45,40,.72)` | `rgba(240,224,198,.62)` |
| `--hairline` | `rgba(35,45,40,.12)` | `rgba(240,224,198,.13)` |
| `--frame` / `--frame2` | `rgba(201,169,106,.85)` / `rgba(62,107,88,.30)` | `rgba(201,169,106,.5)` / `rgba(201,169,106,.2)` |
| `--accent` | `#3E6B58` | `#E3A53E` |
| `--btn-bg` / `--btn-ink` | `#3E6B58` / `#F7F3E8` | `#E3A53E` / `#161006` |
| `--gold-line` | `#C9A96A` | `rgba(216,179,106,.6)` |
| `--gold-ink` (medal numerals) | `#7E5C1D` (AA margin — enforced by web/tests/unit/contrast.test.ts) | `#D8B36A` |
| `--surface` (ring gap) | `#F2ECDD` | `#012A27` |
| `--player-bg` (added during P2 — mini-player scrim; a tokens.css-only value, enforced by the token rule) | `rgba(242,236,221,.92)` | `rgba(1,42,39,.92)` |

- Origin: night green `#012A27` + cream `#F0E0C6` sampled **from the real logo file** (`Dark Green Quran Logo.png`, 1254×1254). Day family carried from the app tokens (beige paper).
- Theme switch: `data-theme` attribute + CSS vars; preference in `localStorage`; inline no-flash script; defaults to `prefers-color-scheme`.
- Typography: **HafsSmart** (Quran text — woff2, **never subset** — Quran shaping), **Cairo** reg/bold (UI). Arabic: no `letter-spacing`, line-height ≥1.6 body / 2.0+ for ayah display.
- Ornaments: `۝` (U+06DD) hero ayah ends, `۞` (U+06DE) dividers, ayah-number **CSS double-ring medallion** with Arabic-Indic numerals (١٢٣).
- Logo in nav: circular crop of the master file; on night it intentionally blends into the same-green canvas (cream calligraphy only visible) — locked behavior.
- Light-theme gold text uses `--gold-ink` `#7E5C1D` (WCAG AA on paper); night uses `#D8B36A`. Contrast verified in implementation tests (§5).

### 3.10 App integration (share links) — phase P4

- **Web side** (part of this repo): `web/public/.well-known/assetlinks.json` — `com.mostafasayed.quranyahdi` + release keystore SHA-256 (fingerprint is public by design; generated from the release signing setup).
- **App side** (small Flutter work, shipped with the next store release — before first Play release):
  - `AndroidManifest.xml`: `autoVerify` intent-filter for `https://<project>.pages.dev` `pathPrefix="/surah"` (+ `/en/surah`).
  - Deep-link handling: URL → app reader route for that surah + ayah scroll (route mapping verified against `lib/app/router.dart` at implementation — go_router is deep-link ready already).
  - Reader share button → builds `https://<project>.pages.dev/surah/{n}#ayah-{a}` and shares (mechanism decided at P4 against the app's existing capabilities; **any new app dependency needs owner approval**).
- **Web side UX**: «افتح في التطبيق» button (`intent://` fallback) + Android smart banner.
- Verification method (documented at P4): `adb shell pm verify-app-links --re-verify com.mostafasayed.quranyahdi` + on-device browser tap test with a real share URL.
- iOS: `apple-app-site-association` added when iOS ships (same domain; noted, not v1).

## 4. Pages (v1 inventory)

| Route (AR) | EN mirror | Content |
|---|---|---|
| `/` | `/en/` | Landing: hero (ayah + kicker + CTAs), «متابعة القراءة» card (localStorage), feature grid (14 app features summarized), brand promise strip, download CTA (Play store badge + GitHub Releases APK until store publish), footer |
| `/quran` | `/en/quran` | Surah index: 114 cards/list with search-by-name/number + full-text search entry (§3.5) |
| `/surah/{1..114}` | `/en/surah/{n}` | Reader (§3.6–3.9): header (name, chips, reciter picker, play), ayah blocks + medallions, per-ayah actions (copy · share · tafsir/translation panel), settings (font size, script uthmani/imlaei, theme), prev/next surah, mini-player |
| `/reciters` | `/en/reciters` | Reciter list → surah list → play/download |
| `/about` | `/en/about` | About the app + project story |
| `/privacy` | `/en/privacy` | Rendered from repo `PRIVACY.md` (single source; Play Store URL) |
| 404 | 404 | Localized not-found with search + home links |

Deep links: `/surah/{n}#ayah-{a}` is the share format (anchors are static in the HTML — no JS needed to land).

Note: the approved mockup's nav showed «المكتبة» and «تدبّر» — those items are **not** v1 routes; v1 nav = المصحف · التلاوات · بحث + theme toggle. They return in P5 (library) or when their pages exist. The mockup is the visual-language reference; this table is the page truth.

## 5. Quality, gates & budgets

- **Gates per commit**: `npm run check` (astro check, TS strict) · `npm run test` (Vitest) · `npm run build` (must pass). `dist/` is built by CI/Pages and never committed.
- **Vitest musts**: generator sanity (already gated in Dart), Arabic normalization cases, search ranking cases, share-URL builder, assetlinks JSON validity, file-count budget (dist < 2,000 files — Cloudflare free cap is 20,000).
- **Playwright smoke** (1 spec, chromium): open `/surah/2` → expects 286 ayah blocks & title; theme toggle flips `data-theme`; search «الرحمن» returns ayah results that link into `/surah/55#ayah-…`; RTL direction on `/`, LTR on `/en/`.
- **Performance budget (reader page)**: shipped JS ≤ 30KB gzip before any interaction on `/surah/*` (islands load on demand), LCP ≤ 2.5s on Slow-4G profile, CLS < 0.1. Fonts: woff2 + preload only HafsSmart on reader.
- **Accessibility**: WCAG AA in both themes (all token pairs verified in a Vitest contrast test), visible focus, 48px targets, ARIA labels localized, `prefers-reduced-motion` respected.
- **CI**: `.github/workflows/web.yml` — triggers on `web/**` + `tools/export_web_data.dart`, runs gates on ubuntu, Node 22.

## 6. Deployment (Cloudflare Pages — free tier, verified limits 2026-10-17)

- Pages project ← GitHub repo, **root directory `web/`**, build `npm ci && npm run build`, output `dist`, Node 22.
- Preview deployment per branch/PR; production on `main` push.
- Free tier facts (checked): 500 builds/month, 1 concurrent build, 20k files/site, 25MiB/file, **unlimited bandwidth/requests** — Ramadan-scale traffic is absorbed at zero cost.
- `assetlinks.json` and all `.well-known` files ship as static files under `web/public/`.
- Analytics: **optional, later** — Cloudflare Web Analytics (cookieless); off by default until owner opts in.

## 7. Phases

| Phase | Scope | Exit gate |
|---|---|---|
| **P1 Foundation** | `web/` scaffold (Astro+React+TW4+TS), token layer + fonts + logo assets, data generator + committed data, `/surah/[n]` static reader (text only, AR), `/quran` index, theme switch, first deploy to `*.pages.dev` | live preview URL + gates green + Playwright smoke v1 |
| **P2 Experience** ✅ *(implemented 2026-10-18 — web commits `5cc3149..3a58ea7`, 14 commits)* | audio player + reciters page, translations/tafsir panel, search, settings persistence, bookmarks (resume → P3; `qy:last-read` storage deferred with its consumer), copy/share builders, per-ayah actions | gates + perf budget + smoke v2 — met |
| **P3 Official site** | full landing, about, privacy (from PRIVACY.md), EN locale complete, SEO (sitemap/hreflang/OG basics), download CTAs | gates + Lighthouse ≥90 mobile + sitemap submitted |
| **P4 App links** | assetlinks.json + Flutter intent-filter/deep-link/share (+ any app dependency = owner approval), verification on real device | verified open-in-app on device; docs updated |
| **P5 Later (not v1)** | PWA offline reading, mushaf page mode (line data available in DB), per-ayah pages for SEO, per-ayah audio, OG images per surah, analytics opt-in, hadith library | new spec/plan per item |

## 8. Risks & mitigations

| Risk | Mitigation |
|---|---|
| App Links verification on `*.pages.dev` uncertain | Verify first thing in P4 with a real device; documented fallback = `intent://` button + smart banner (still good UX), or owner acquires a domain later (documented cost: app re-release for assetlinks) |
| mp3quran API drift/downtime | Build-time reciter snapshot fallback; audio failure → localized inline error with retry (app discipline) |
| HafsSmart woff2 shaping fidelity | No subsetting; render-test page with shaped ayahs (﴿﴾ chains, sajda marks) in P1 before sign-off |
| Quran text fidelity | Generated from the shipped `quran.sqlite`; sanitized to byte-matching JSON; spot-check tests |
| JS creep on reading pages | Islands architecture + build-time bundle budget test |
| Cloudflare free limits | Verified headroom (114×2 pages + assets ≈ hundreds of files, not thousands) |
| Attribution/licenses | Reuse `docs/store/licensing-matrix.md` constraints; fonts license files copied into `web/public/fonts/`; pack attribution shown in UI |

## 9. Success criteria (v1)

1. Public URL on `*.pages.dev` serving AR + EN, day + night, all 114 surahs with audio and tafsir/translations.
2. Every surah/ayah shareable; on a device with the app (post-P4) the link **opens the app**.
3. Gates green in CI on every merge; Lighthouse mobile ≥ 90 across the board on `/surah/2` (AR).
4. Zero-cost infrastructure end to end. No accounts, no cookies, no third-party trackers.

## 10. Out of scope (explicit)

Accounts/sync, prayer times, qibla, azkar/tasbih/duas on web (app-only for v1), hadith library, community features, admin tooling, custom domain purchase, iOS app links (deferred with iOS publishing).

---

### Appendix A — Asset inventory for P1

| Asset | Source | Web treatment |
|---|---|---|
| Quran text | `assets/db/quran.sqlite` | generator → committed JSON (§3.3) |
| Logo master | `E:\old_flutter\Quran-web\Dark Green Quran Logo.png` (1254×1254) | copied into `web/src/assets/brand/logo-master.png`; derivatives: nav 64, favicon 32/16, apple-touch 180, og-base 1200×630 |
| HafsSmart `assets/fonts/HafsSmart_08.ttf` | app repo | → `HafsSmart_08.woff2` (no subset) |
| Cairo `assets/fonts/Cairo-{Regular,Bold}.ttf` | app repo | → woff2 ×2 |
| me_quran `assets/fonts/me_quran.ttf` | app repo | fallback Quran font (woff2) |
| Pack catalog | `assets/data/library_catalog.json` | reference list for translations/tafsir picker |

### Appendix B — Approved mockup trail (visual companion session)

`.superpowers/brainstorm/8076-1792263740/content/`: `design-directions.html` (3 directions) → `system-daynight.html` (merge proposal) → `manuscript-v2.html` (paper-only night) → `manuscript-v3.html` (first green) → **`manuscript-v4-logo.html` (APPROVED)**. Note: `.superpowers/` is gitignored — this spec carries the enforceable definition.
