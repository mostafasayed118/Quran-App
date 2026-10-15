# Quran Yahdi (قرآن يَهدي) — Full Rebuild Design Spec

Date: 2026-10-15 · Status: APPROVED by owner (all 4 design sections + 15 UI mockups)
Replaces/assets-follows: `RECOVERY_PLAN.md` (the new build supersedes its fix-in-place path)

## 1. Goal

Rebuild the existing Quran-App into **قرآن يَهدي** — a complete, professional, simple Islamic app
for Android first (Play Store), with every feature working **online AND offline**.
Free for Muslims: no ads, no subscriptions, no paywalls, ever.

Owner: Mustafa Sayed (mostafasayed118). Sole maintainer. Code written by delegated AI executor
agents under a PM (dispatch briefs → independent review at source → integration), PM does not implement.

## 2. Approved Decisions Log

| # | Decision | Value |
|---|---|---|
| D1 | Scope v1 | Quran + prayer times/adhan + qibla + recitations (online/offline) + tafsir/translations + azkar + tasbih + duas + ruqyah + zakat + hijri calendar + asma ul husna + worship tracking — ALL in first store release |
| D2 | Languages | Full i18n from day one: Arabic (default) + English (ARB files) |
| D3 | Monetization | Not present. No ad SDK, no IAP, no subscriptions |
| D4 | App name | قرآن يَهدي — store display: "Quran Yahdi" |
| D5 | Launch order | Android first → Play Store. iOS code-ready (no conditional code), publishing deferred (Apple $99 + cloud builds later) |
| D6 | Visual direction | Modern + Islamic touch. Palette: beige `#F1EAD7`, emerald `#3E6B58` (dark `#2E5244`, light `#E4EEE9`), gold accent `#E3A53E`, page bg `#EFE9DA`, ink `#232D28` |
| D7 | Build strategy | **Rebuild `lib/` in the same repo** (keep git history, keep usable assets), delete legacy code |
| D8 | State management | **flutter_bloc / cubit + Freezed** (owner's stack — review-speed beats boilerplate) |
| D9 | Backend | **Supabase = thin layer only**: content manifest, remote config; RLS on all tables. The app core MUST remain fully functional offline |
| D10 | Audio CDN | Recitations stream/download from **mp3quran.net** (free). Never host large audio on Supabase (egress cost) — Supabase serves text packs/manifest only |

## 3. Architecture

Feature-first clean architecture:

```
lib/
├── app/            # bootstrap, go_router, theme, l10n bootstrap
├── core/
│   ├── db/         # drift database + tables + migrations
│   ├── network/    # dio client, download manager, connectivity
│   ├── widgets/    # shared widgets, ayah text widget,RTL helpers
│   ├── theme/      # tokens = D6 palette; light + dark ThemeData
│   └── utils/      # arabic numerals, date/hijri helpers, errors
└── features/
    ├── quran/          # surah index, ayah reader, mushaf pages, bookmarks, khatma
    ├── recitation/     # player (just_audio + audio_service), reciter list, downloads
    ├── library/        # tafsirs + translations + hadith browsing, pack downloads (Supabase manifest)
    ├── prayer_times/   # local calculation, notifications (flutter_local_notifications + timezone)
    ├── qibla/          # geolocator + compass
    ├── azkar/          # azkar categories + per-item counter
    ├── tasbih/         # counter (haptics, cycles)
    ├── duas/           # duas + ruqyah (bundled content)
    ├── worship/        # prayer tracker (streaks), khatma progress (drift)
    ├── knowledge/      # zakat calculator, hijri calendar, 99 names
    └── settings/       # language, fonts, download manager, backup toggle (later)
```

### Stack

| Concern | Choice |
|---|---|
| State | flutter_bloc (cubit) + Freezed |
| Routing | go_router (deep-link ready) |
| DB | drift (SQLite): quran text, bookmarks, downloads cache, tracker, khatma |
| Prayer times | local astronomical calc (adhan algorithm, e.g. `adhan_dart`) — zero network |
| Audio | just_audio + audio_service (background + media notification) |
| HTTP | dio (streaming downloads with progress) |
| i18n | flutter_localizations + intl + ARB; RTL-first |
| Backend | supabase_flutter (manifest/remote config; future backup) |
| Fonts | HafsSmart (`quran`), me_quran, Cairo or Tajawal (UI) — bundled in assets |
| Platforms | Android only in build (minSdk 24, target from Flutter defaults). Remove `web/ linux/ windows/ macos/` dirs from repo. iOS paths untouched-but-unbuilt |
| App ID | `com.mostafasayed.quranyahdi` (Android + iOS reserved same) |
| Versioning | 1.0.0+1 first store release |

## 4. Verified Data Sources (live-verified 2026-10-15) + Content Model

| Source | Serves | Notes |
|---|---|---|
| quran.com API v4 (`api.quran.com`) | surah metadata, scripts, recitation endpoints | free, no key |
| fawazahmed0/quran-api (jsDelivr CDN) | 440+ translations / 98 languages as static JSON | no rate limits; mirror-able |
| spa5k/tafsir_api (jsDelivr CDN) | 123 tafsirs (AR: Tabari, Ibn Kathir, Qurtubi, Baghawi, Saadi, Muyassar… EN: Ibn Kathir, Jalalayn…) | MIT; **pin exact release tags**; fallback domains fastly/gcore jsdelivr + raw.githubusercontent |
| fawazahmed0/hadith-api (jsDelivr CDN) | canonical hadith books + grades + translations | no rate limits |
| mp3quran.net API v3 | reciters + full mp3 files | live-verified |
| alquran.cloud | text/translation fallback | live-verified |
| aladhan.com | qibla/hijri fallback endpoints | base live-verified; timings param format to verify at integration |
| Supabase (ours) | `content_manifest` + `app_config` tables; later: anonymous cloud backup | RLS mandatory; edge functions for anything sensitive |

**No-API content (bundled assets):** azkar, duas, ruqyah, asma ul husna — static JSON from
open datasets (e.g. Hisn al-Muslim), validated in-repo.

### Offline-first model

1. **Ships in the bundle (works on first launch, no network):**
   complete Quran (uthmani + imlaei texts), tafsir al-Muyassar, English Saheeh Intl translation,
   all azkar/duas/ruqyah/asma, prayer-times computation, qibla bearing computation.
2. **On-demand (online once, cached to drift forever after):**
   additional tafsirs/translations/hadith packs — URLs resolved from Supabase manifest
   (manifest points at public CDNs or Supabase Storage mirrors).
3. **Audio:** streaming by ayah/surah from mp3quran; explicit per-surah / whole-reciter download
   manager; downloads stored app-private, deletable from settings.
4. Resilience rule: every fetch follows cache-first → network → last-known-good; CDNs always
   have a fallback domain; failures degrade to bundled content, never to an error void.

## 5. Drift Schema (draft)

- `surahs (id, name_ar, name_en, revelation_type, ayah_count, pages_start, pages_end)`
- `ayahs (id(1..6236), surah_id, number_in_surah, juz, page, line_start, line_end, text_uthmani, text_imlaei, sajda)`
- `bookmarks (id, ayah_id, note?, created_at)` — multi-bookmark
- `khatma_progress (id, ayah_id, target, updated_at)`
- `prayer_log (date, fajr, dhuhr, asr, maghrib, isha)` — booleans
- `installed_packs (pack_id, kind, language, title, size_mb, version, installed_at)`
- `pack_cache (pack_id, entity JSON rows)` or per-pack tables generated at import
- `settings (key, value)` — mirrors the few legacy shared_preferences keys during migration
- `downloads (id, reciter_id, surah_id, status, bytes, path)`

## 6. Design System

Tokens from D6; approved mockups (15 screens) live at
`.superpowers/brainstorm/513-1792059072/content/all-screens.html` (authoritative navigation & screen
inventory): splash, home (next-prayer hero + feature grid + continue-reading), surah index w/ search,
ayah reader (chips: tafsir/translation + mini player), mushaf page mode, recitations/reciters,
prayer times + adhan toggles, qibla compass, azkar + per-item counter, tasbih dial, duas/ruqyah,
worship tracker (streak + khatma), zakat + hijri calendar, asma ul husna, settings + download manager.
Dark mode: same tokens inverted (emerald-dark surfaces, beige text).
Accessibility: 48px min touch targets, Semantics on all interactive elements, textScale up to 2.0 must survive.

## 7. Quality Gates (every wave, no exceptions)

- **Dependency freshness (owner requirement):** every package MUST be the latest stable version
  at the time its wave runs (verify on pub.dev before adding; no deprecated/unmaintained packages;
  `pubspec.lock` committed every wave). Re-check freshness at W7 before release.
- `flutter analyze` = 0 issues (flutter_lints from day one)
- `dart format` — clean
- Unit tests REQUIRED for computational logic: prayer calculation, zakat, hijri conversion,
  arabic numeral conversion, download manager state machine
- Widget tests for critical screens: quran reader, home, mushaf paging
- GitHub Actions CI (analyze + test on every push) — first time this repo has CI
- No secrets in repo (none needed — all public APIs keyless; Supabase anon key allowed in app)

## 8. Release Pipeline (W7)

1. Release keystore created OUTSIDE the repo (`key.properties` + `.gitignore`)
2. `flutter build appbundle`; store listing assets (icon 1024, 2+ phone screenshots, feature graphic)
3. Privacy policy page (app is local-first; location only for prayer/qibla, stored on device)
4. Internal testing track → owner manual QA → promote to production
5. iOS: code stays iOS-clean; publishing deferred until Apple Developer account + Codemagic (future decision)

## 9. Implementation Waves (PM → executor briefs → PM review at source)

| Wave | Scope | Key risk |
|---|---|---|
| W0 | Scaffold: clean-arch skeleton, theme tokens, go_router, l10n (AR/EN), drift core, DI, bloc infra, delete legacy `lib/`, prune platform dirs | foundation-only oversight |
| W1 | Quran core: bundle SQLite build step, surah index, ayah reader, mushaf pages (page-grid via built-in page metadata), bookmarks, khatma shell | mushaf page fidelity |
| W2 | Recitations: player + audio_service, reciter list (mp3quran), download manager, offline playback | audio service lifecycle |
| W3 | Prayer times (local calc + madhab/method settings), adhan notifications, qibla compass | notification scheduling + battery |
| W4 | Azkar + counter, tasbih, duas, ruqyah, asma ul husna (bundled content) | content datasets accuracy |
| W5 | Worship tracker (streaks, prayer log), zakat calculator, hijri calendar | date/edge cases |
| W6 | Library: multi-tafsir/translation/hadith browsing + pack download manager + Supabase manifest | CDN tag-pinning, fallbacks |
| W7 | Full EN i18n sweep, dark mode, release hygiene (zero debug tooling in deps), store assets, release engineering | release checklist |

Each wave: PM writes English executor brief (scope, frozen-test rules, gate counts, explicit
pathspec commits, no push) → executor implements in isolated worktree → PM independently verifies
at source (re-runs gates, spot-checks claims) → integrates.

## 10. Explicit Non-Goals (v1)

- iOS store publish · subscriptions/ads · accounts/auth · cloud backup (post-v1 via Supabase,
  anonymous) · tafsir word-by-word highlighting · social features · remote wiping of anything
