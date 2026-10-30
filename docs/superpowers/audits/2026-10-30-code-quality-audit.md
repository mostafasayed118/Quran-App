# Code Quality Audit — Quran Yahdi (`quran_yahdi`) — 2026-10-30

**Mode:** read-only. No file was created, edited, or deleted during the audit.
**Scope:** `lib/`, `test/`, `android/`, `ios/` config, `tools/`, CI workflows, `web/public/_headers` (the Astro site is a separate campaign and was not audited beyond its headers/CSP).
**Method:** 5 parallel read-only dimension lanes (maintainability, clean architecture, code quality, security, performance) → integrator re-verified the load-bearing citations at source → weighted score with shown arithmetic → `docs/superpowers/plans/2026-10-30-top5-remediation.md`.

> **Live-tip warning (2026-10-30 01:38).** This report is a snapshot at `c76063a`.
> While it was being written, a concurrent session began landing the
> maintainability findings; HEAD was `418d0d0` at publication and still moving.
> Closed at that tip: single write path (`e9d72f0`, parity test still owed),
> LibraryCubit seam (`43ff3b4`), `platformLocalizations()` pin (`a209db4`),
> `core/widgets` doc comments (`aa6cca4`), duplicate `ReminderScheduler`
> (`7203d45`), `async_view` + `hadith_browse` renames (`d4c3104`), and the SDD
> ledger is now tracked (`d633ff0`). Re-run the gates and re-check every finding
> against the live tip before acting on this report.
>
> **Remediation landed (2026-10-30, on top of `248d3ab`).** W1 `7d3983c`
> (asset ships the 6,236-row index + stamp; +0.86 MB), W3 `e712e64`,
> W4 `7045a96`, W5 `b90ea1a`, W2b `3099912` (khatma insert + update parity,
> forced thresholds). Combined gate: format **0 changed** · analyze **0** ·
> tests **828/828** (13 new). The top-5 is fully closed.

## Baseline

| Item | Value |
|---|---|
| HEAD at audit time | `c76063a4eaf24f5174cd0ab500dcb1d86128dde1` — `feat(quran): a dead-end surah filter hands its words to the verse search` (live tip moved to `418d0d0` during publication — see the warning above) |
| Branch / remote | `fix/perf-audit-2026-10-27` · `origin/main` == HEAD (0 unpushed) |
| Porcelain | `.vscode/settings.json` (M), `INSTRUCTIONS.md` (??), `assets/icons/logo_1.png` (??), `assets/icons/logo_2.png` (??), `web/design-concepts/` (??) — owner debris, untouched |
| Toolchain | Flutter 3.47.5 stable / Dart 3.13.4 · Windows PowerShell 5.1 |
| Scale | 211 `lib/*.dart` files · 34,018 non-blank LOC (38,045 total) · 248 `test/` files · 21,871 test LOC · 16 features |
| Stack | flutter_bloc 9.1.1 + freezed · get_it · go_router 18.1.0 · drift 2.35 · dio 5.11 · `flutter_localizations`/ARB · just_audio · flutter_local_notifications · geolocator · sensors_plus · adhan · hijri · app_links · share_plus · file_picker |

## Gates (run by the integrator at this tip)

| Gate | Result |
|---|---|
| `flutter analyze` | **0 issues** (36.5 s) |
| `dart format --output=none --set-exit-if-changed lib test tools` | **462 files, 0 changed** |
| `flutter test` | **815 / 815 passed** (1 min 48 s) |
| Prior remediation ancestors | **14 / 14 present** (`87524cc` … `739db0f`) |
| ARB parity (lane evidence) | **216 AR = 216 EN**, 0 one-sided |

## Scorecard

| Dimension | Score | Weight | Contribution |
|---|---:|---:|---:|
| Security | **8.6** / 10 | 25% | 2.150 |
| Maintainability | **7.5** / 10 | 20% | 1.500 |
| Clean architecture | **7.5** / 10 | 20% | 1.500 |
| Code quality | **8.0** / 10 | 20% | 1.600 |
| Performance | **7.0** / 10 | 15% | 1.050 |
| **Overall weighted** | **7.8 / 10** | 100% | **`8.6×.25 + 7.5×.20 + 7.5×.20 + 8.0×.20 + 7.0×.15 = 7.80`** |

**Verdict:** production-grade engineering with unusually strong enforcement for a solo Flutter codebase. No critical or high-severity issue survived verification. The residual risk is concentrated in first-run boot work, a duplicated backup write path, field-by-field state rebuilding, one DI contract that is documented but false, and four Low security-hardening gaps.

### Trend (not directly comparable)

| Audit | Commit | Scale | Tests | Weighted |
|---|---|---|---:|---:|
| 2026-10-20 final re-audit | — | 162 files | — | 8.02 |
| 2026-10-22 independent | `1a71532` | 167 files · 18,221 lines | 600 | 8.1 |
| **2026-10-30 (this)** | `c76063a` | 211 files · 34,018 non-blank | 815 | **7.80** |

The codebase grew ~87% in hand-written lines while keeping every gate green; the lower number reflects the larger surface and a stricter, deeper rubric, not a regression of the previously closed findings (all 14 remediation commits are ancestors, and the guards/pins they added still pass).

---

## 1) Maintainability — 7.5 / 10

The 16-feature layout matches the documented `data/` + `presentation/` split, including every documented exception (`home`/`settings` presentation-only, `notifications` data-only, `quran`/`recitation` with `domain/`). 211 files produce zero orphan files and zero unreferenced public types; there are no `TODO/FIXME/HACK` markers and no `// ignore:` suppressions in hand-written code. Deductions: two files >400 lines, two ~100-line `build()` methods, a 121-line method with two write paths, and documentation thinner than the code (139/302 types carry a doc comment; 0/10 `lib/core/widgets/` files do).

| Sev | File:line | Evidence | Fix |
|---|---|---|---|
| Med | `lib/features/backup/data/backup_service.dart:231` | `_writePlan` is 121 lines; the sequential path (:283-322) and the `_db.batch` path (:324-350) duplicate the khatma insert/update block | Build one row list, then feed `_flush(rows, batched:)`; keep the khatma companion in one variable — **CLOSED `e9d72f0` (code); parity test owed** |
| Med | `lib/features/notifications/data/reminder_scheduler.dart:8` | `abstract interface class ReminderScheduler implements ReminderSchedulerPort` re-declares the port's two members verbatim; four near-identical names share the folder | Delete the feature interface and implement the core port directly — **CLOSED `7203d45`** |
| Med | `lib/app/router.dart:140` vs `lib/app/di/injector.dart:165` | `LibraryCubit` is built through `getIt.registerFactory`, the other 17 route cubits inline in the router | Pick one seam (injector factories for all) — **CLOSED `43ff3b4`** (router now builds all 18 route cubits; injector factory dropped) |
| Med | `lib/core/db/app_database.dart:37-87` | `beforeOpen` permanently runs duplicate-repair `DELETE`s + `DROP/CREATE INDEX` on every launch; `onUpgrade` only handles `from < 2` | Move the repairs into a versioned `onUpgrade` step; keep only `CREATE … IF NOT EXISTS` in `beforeOpen` |
| Med | `lib/features/backup/presentation/backup_section.dart:22` · `lib/features/recitation/presentation/playback/player_sheet.dart:104` | 99- and 102-line `build()` methods with mixed responsibilities (state switch + layout + navigation) † | Extract named sub-widgets |
| Low | `lib/core/widgets/` (10 files) | 0/10 files carry a leading doc comment while `lib/core/domain/` is heavily documented | One-line `///` per public widget — **CLOSED `aa6cca4`** |
| Low | `docs/superpowers/plans/2026-10-28-post-audit-remediation.md:41` | Defers binding rulings to `.superpowers/sdd/postaudit/ledger.md`, which is **untracked** (`git ls-files` → 0) | Move the ledger under `docs/superpowers/` — **CLOSED `d633ff0`** (`docs/superpowers/plans/2026-10-28-post-audit-remediation-ledger.md`) |
| Low | `lib/features/library/presentation/hadith_browse/hadith_cubit.dart` | Folder `hadith_browse/` holds `HadithCubit`/`HadithState`/`HadithScreen` while siblings match their folder name | Rename symbols to `HadithBrowse*` or the folder to `hadith/` — **CLOSED `d4c3104`** (folder is now `hadith/`) |
| Low | `lib/core/widgets/async_view.dart:3` | File contains `LoadingView` + `ErrorView`; no `AsyncView` type exists | Rename the file — **CLOSED `d4c3104`** (`loading_and_error_views.dart`) |

Largest hand-written files: `lib/features/library/data/pack_downloader.dart` **530**, `lib/features/quran/presentation/reader/reader_screen.dart` **437**.

## 2) Clean architecture — 7.5 / 10

The strongest dimension in enforcement. `test/architecture_guard_test.dart` resolves relative and `package:` imports, asserts `core→features` = 0, `feature→app` = 0, `presentation→foreign data` = 0, and pins the **exact** live edge set (`quran->library`, `quran->recitation`) with planted-violation tests. Every feature `data/` file is Flutter-free. Ports (`AyahLookup`, `CitySource`, `PrayerTimesPort`, `LastReadMarker`, `WirdProgressSink`, `ReminderSchedulerPort`) are cohesive and have real consumers. Deductions:

| Sev | File:line | Evidence | Fix |
|---|---|---|---|
| Med | `lib/app/router.dart:205` (+ `:225-226`, `:265`) vs `lib/app/di/injector.dart:138-169` | Repositories register only when a loader is passed; the router resolves `getIt<AzkarRepository>()` unconditionally. `injector.dart:70-73` claims a missing loader "degrades to its empty state"; it actually throws `unregistered type`. Production is safe because `lib/main.dart:34-43` always passes every loader | Register with an empty-loader fallback (as `CityRepository` does), or guard `getIt.isRegistered` + redirect |
| Med | `lib/features/recitation/presentation/downloads/downloads_cubit.dart:4,31` | `package:dio` `CancelToken` is part of the presentation layer; the queue/cancel/retry algorithm lives in the cubit | Return a transport-agnostic cancellation handle from `data/` |
| Med | `lib/features/backup/presentation/backup_cubit.dart:7-12` | `file_picker` / `share_plus` / `path_provider` / `dart:io` I/O and a `FLUTTER_TEST` branch in the cubit | Move to `backup/data/backup_io.dart`; inject from the router |
| Med | `lib/core/domain/ayah_lookup.dart:13-31` · `lib/features/quran/data/ayah_source.dart:12` | The ports' primary signatures speak drift rows (`Future<List<Ayah>>`), so DIP stops at the seam | New code on `AyahRef`/`SurahRef`; move row adapters out of `presentation/` |
| Med | `test/architecture_guard_test.dart:17,203` | `_importRe` matches single quotes only; no `part`/`part of` scan; only the first URI of a conditional import; the data-layer rule ignores `flutter/services.dart` and `dart:ui` | Match `['"]`, scan every conditional URI and `part`, ban all `package:flutter/` + `dart:ui` in `data/`; add planted tests |
| Med | `lib/features/quran/presentation/reader/reader_state.dart:21-22` | Stores `ayahs` **and** the fully derived `mushafPages` — two sources of truth that can diverge on `copyWith(ayahs:)` | Derive pages at the view boundary |
| Low | `lib/core/di/injector.dart:9` | `export 'package:quran_yahdi/app/di/injector.dart';` — a core→app edge the guard cannot see. **Documented compatibility shim** (`:1-9`, AGENTS.md) | Add a guard allowlist entry and retire it when the frozen test imports move |
| Low | `lib/features/settings/presentation/settings_cubit.dart:238-278` · `playback_cubit.dart:127-132` | Seven switch extractors and hand-rebuilt `PlaybackState.playing(...)` instead of `copyWith` | `state.copyWith` behind a ready check |
| Low | `lib/features/library/presentation/ayah_sheet/library_sheet.dart:53` | `widget.downloader ?? GetIt.instance<PackDownloader>()` — service-locator resolution inside a widget | Pass the downloader through the reader/provider |
| Low | `lib/app/di/injector.dart:50,86` | `_configured` is not cleared by `getIt.reset()`, so a later `configureDependencies` is a silent no-op | Reset the flag in a `@visibleForTesting` hook |
| Low | `lib/features/quran/domain/verse.dart:18` · `recitation/data/reciter_repository.dart:36` | Rendering cleanup (`stripAyahEndMarker`) in the entity file; URL building used directly by presentation | Move to a text util / playback data seam |

## 3) Code quality — 8.0 / 10

Verified hygiene: 0 `print`/`debugPrint`, 0 TODO/FIXME/HACK (the initial "6" was a case-insensitive match on `toDouble`), 0 commented-out code, 0 lint suppressions, 0 raw-exception strings in any `presentation/` file, all 72 catches are typed `on <Type>`, 216/216 ARB parity, and 0 hardcoded Arabic literals in `presentation/`. The tripwire counts `!` and `Colors.` were inflated by generated code and `AppColors.` (`!` real = 4; real `Colors.` = 5; `Color(0x` = 16, all in `app_colors.dart:4-20`).

| Sev | File:line | Evidence | Fix |
|---|---|---|---|
| Med | `lib/features/settings/presentation/settings_cubit.dart:94,124,148,178,202` | 6 `SettingsState.ready(...)` sites rebuild all 7 fields; `_prayerEnabledOf(SettingsFailed) => true` (:250-254) invents a value | `SettingsReady.copyWith`; when not ready, refuse the mutation — never emit invented data |
| Med | `test/*` — 34 relative `_test.dart` imports | `test/asma_screen_test.dart:12` imports `asma_repository_test.dart`; `cairoCity` is defined in 4 places; `_FakePlaybackService` in 11 files and already divergent | Move `cairoCity`, `FakePrayerTimeService`, `FakePlaybackService`, `FakeReminderScheduler` into `test/support/`; delete the copies |
| Med | `lib/core/utils/arabic_search.dart:23` | `RegExp(r'\s+')` rebuilt per call; `azkar_repository.dart:123-125` normalizes 3× per item per keystroke | Hoist `final _whitespace`; normalize the query once |
| Med | `lib/features/notifications/data/reminder_scheduling.dart:52` | `} on Object {` with only a comment — a permanently failing scheduler is undiagnosable | Add the standard `dev.log(..., name: 'quran_yahdi/reminders')` |
| Low | `lib/features/recitation/data/audio_downloader.dart:194` | `} on Object catch (_) {}` — the only empty catch, hidden by the `_` wildcard | Log inside it |
| Low | `lib/app/app.dart:51-52` | `locale: const Locale('ar')` with `supportedLocales: [ar, en]`; no runtime path selects `en` | Honour the device locale or drop `en` and document AR-only |
| Low | `lib/features/quran/presentation/index/surah_index_screen.dart:89` | `revelationType == 'makkah'` magic string — any other value silently renders "Madinah" | Parse to an enum at the data boundary |
| Low | `lib/core/utils/app_routes.dart:55-57` + `surah_index_screen.dart:92` | Doc says omitting `ayah` keeps the surah-only form; caller passes `ayah: 0` → `?surah=1&ayah=0` | Treat `<= 0` as absent and name `kNoAyah` |
| Low | `test/prayer_log_repository_test.dart:18-19` | Two `DateTime.now()` reads can straddle midnight | Capture `now` once |
| Low | `analysis_options.yaml:4-7` | Excludes `**/*.g.dart` but not `**/*.freezed.dart`; `empty_catches` is defeated by `_`; `avoid_slow_async_io` absent while `await …exists()` appears 8× | Add exclusions/rules deliberately |

## 4) Security — 8.6 / 10

Verified controls: no credentials in tracked files (`.env` and `android/key.properties` proven ignored via `git check-ignore`), no cleartext endpoint, no SQL string interpolation (`quran_search_repository.dart:22-23,60-68`, `hadith_store.dart:54-62`), no archive extraction, no WebView, no clipboard use. Packs are HTTPS+host-allowlisted at parse time and sha256-pinned before promotion; sizes are capped from declared bytes. Backups are bounded (2 MiB, checked before read) and redacted (city coordinates), and the plaintext-at-rest decision is documented. Deep links are exact-host + range-clamped (`deep_links.dart:23-52`, `router.dart:296-303`). `PUBLISH_RELEASE` hard-fails without a keystore (`android/app/build.gradle:84-89`). Web CSP has no `'unsafe-inline'`/`'unsafe-eval'`, plus `frame-ancestors 'none'`, `nosniff`, `Referrer-Policy`, and HSTS. No High/Critical finding.

| Sev | File:line | Evidence | Fix |
|---|---|---|---|
| Low | `lib/features/recitation/data/audio_downloader.dart:124-128` | `_dio.get(...)` without `followRedirects: false`; `isTrustedAudioServer` (`reciter_repository.dart:86-92`) gates only the initial URL; audio has no integrity pin | Reject non-allowlisted redirect hops, or `followRedirects: false` + manual revalidation |
| Low | `android/app/src/main/res/xml/data_extraction_rules.xml:3-10` + `lib/core/db/connection.dart:218-219` | Rules exclude only `database`/`sharedpref`, but the DB is opened in `getApplicationSupportDirectory()` → Android `file` domain, so the DB and packs ride D2D transfer; contradicts `docs/superpowers/specs/2026-10-24-backup-encryption-decision.md:19-20` | Add `<exclude domain="file" path="."/>` (and `root`/`external` if used) — or accept D2D and correct the doc |
| Low | `lib/features/backup/data/backup_merger.dart:28-36`, `:72-85` | Bookmarks lack the 1..6236 clamp that last-read already has; `targetPages` is unclamped | Apply `kBackupMaxAyahId` and clamp `targetPages` to `KhatmaProgress.targetChoices` |
| Low | `.github/workflows/ci.yml:11-12,35-36` | Actions pinned to mutable tags; no `permissions:` block (the web workflow already pins SHAs and sets `contents: read`) | Pin to commit SHAs; add `permissions: contents: read` |
| Low | `android/gradle/wrapper/gradle-wrapper.properties:5` | No `distributionSha256Sum`; no `gradle/verification-metadata.xml` | Add the checksum and Gradle verification metadata |

## 5) Performance — 7.0 / 10

Strong baseline: DB on a background isolate with WAL, large JSON decoding on `Isolate.run`, position stream capped at 1 Hz, per-row `BlocSelector` in the reader/downloads, lazy lists, aspect-scoped `MediaQuery` reads, bounded pack cache (2 entries / 24 MB) with single-flight and a global decode queue, no image widgets, no `AnimationController`, all cubits cancel subscriptions on `close`. The score is held down by first-open work and a few rebuild scopes.

| Sev | File:line | Evidence | Fix |
|---|---|---|---|
| Med | `lib/core/db/connection.dart:229-231` + `lib/core/db/search_index.dart:27-29` | `await _ensureSearchIndex(db)` before the executor is returned; the bundled 3.3 MB DB has no `search_index_version` stamp (verified: `tools/build_quran_db.dart` has no `ayah_search`/stamp logic), so **every fresh install** awaits 6,236 normalization+inserts before the first query | Prebuild `ayah_search` + stamp in the asset generator, or return the executor first and build post-frame behind a "preparing search" state |
| Med | `lib/features/quran/presentation/reader/reader_screen.dart:233,392` + `verse.dart:19-27` | `stripAyahEndMarker` allocates `runes.toList()` + a new `String` per visible card per rebuild | Precompute once in `Verse` |
| Med | `lib/features/azkar/presentation/azkar_screen.dart:257-271` | One `BlocBuilder<AzkarCubit>` wraps the reciting `ListView`; every counter tap re-emits the whole state and rebuilds all visible prose cards | Per-row `BlocSelector<…, int>` on `remaining[i]` |
| Low | `lib/core/db/app_database.dart:51-68` | 2 full-table dedupe scans + 2 index drops/rebuilds on every DB open | Version-gated one-time repair |
| Low | `lib/features/recitation/presentation/playback/player_sheet.dart:107` | Whole sheet rebuilds on every 1 Hz position tick, including mid-drag † | `buildWhen` ignoring position while dragging |
| Low | `lib/features/quran/data/quran_search_repository.dart:24,40-46` | A second full `COUNT(*) … LIKE %token%` scan per search (the index cannot serve a leading wildcard) | Count only on page 1, or return `hasMore` |
| Low | `lib/features/azkar/data/azkar_repository.dart:112-136` · `core/utils/arabic_search.dart:27-31` | Query and every item normalized per keystroke, no debounce | Normalize the query once; cache normalized item text |
| Low | `lib/features/duas/presentation/duas_cubit.dart:106-107` | N+1: 2 queries × 9 ruqyah entries, same surah re-queried | One range query + distinct-surah lookup |
| Low | `lib/features/home/presentation/home_screen.dart:185-188` · `hijri_screen.dart:123-126` | `GridView.count(shrinkWrap: true, physics: NeverScrollableScrollPhysics())` inside an outer `ListView` | `SliverGrid` in a `CustomScrollView`, or `Wrap` |
| Low | `lib/features/library/data/hadith_store.dart:43-50` | `_ensureTable()` + `COUNT(*)` on every paged window | Cache "table ready / imported" per pack |

---

## Top 5 issues, ranked

1. **First-open search-index rebuild blocks the DB executor** — `lib/core/db/connection.dart:229-231`, `lib/core/db/search_index.dart:27-29`. Every fresh install / content bump waits on 6,236 inserts before the first screen can query. **Fix:** prebuild `ayah_search` + stamp `search_index_version` in `tools/build_quran_db.dart`, or hand the executor out first and build behind a visible "preparing search" state. — **CLOSED `7d3983c`** (asset now carries 6,236 rows + the stamp).
2. **Backup single-write-path parity test owed** — `lib/features/backup/data/backup_service.dart:231-350`. The 121-line dual-path `_writePlan` was refactored to one companion list + `_writeKhatma` at `e9d72f0` **with no test**. **Fix:** add the below/above-threshold parity test that dumps and compares the four tables. — **CLOSED `3099912`** (khatma insert + update, forced thresholds, table dumps).
3. **Settings mutations can emit invented values** — `lib/features/settings/presentation/settings_cubit.dart:94-202` + `:250-254`. After a failed load, `_prayerEnabledOf` returns `true`, so one toggle emits a "ready" state with fabricated settings. **Fix:** `SettingsReady.copyWith`, and refuse mutations when not ready. — **CLOSED `e712e64`**.
4. **Router resolves optionally-registered repositories** — `lib/app/router.dart:205` vs `lib/app/di/injector.dart:138-169`. Production is safe (main passes all loaders), but the documented fallback is false and a degraded boot/test without an asset crashes on navigation. **Fix:** empty-loader fallback like `CityRepository`, or `isRegistered` guard + redirect. — **CLOSED `7045a96`**.
5. **Audio redirect is not re-validated** — `lib/features/recitation/data/audio_downloader.dart:124-128`. The `mp3quran.net` allowlist covers only the first URL; Dio follows up to 5 redirects and audio has no sha256 pin. **Fix:** `followRedirects: false` + per-hop scheme/host check. — **CLOSED `b90ea1a`** (3-hop manual chain, every hop re-validated).

**Runner-up:** per-launch `DELETE` / `DROP INDEX` / `CREATE INDEX` in `app_database.dart:51-68` → versioned repair step.

## Verification corrections (lane claim → checked at source)

| Claim | Correction |
|---|---|
| "6 TODO/FIXME lines" | **0** — the match was `toDouble` under a case-insensitive search |
| "`192` bang operators / `79 Colors.`" | Generated code and `AppColors.` — real counts are **4** `!` and **5** `Colors.` |
| "core→app export is High" | It is the **documented compatibility shim** (`lib/core/di/injector.dart:1-9`, AGENTS.md) — downgraded to Low/documented debt |
| "Router missing registration is High" | **Medium** — `lib/main.dart:34-43` always passes every loader; only tests/degraded boots hit it |
| "6,236 inserts on every open" | Only when the index is missing/stale (`search_index.dart:28`): fresh install or content bump, not every launch |

## Method & limits

- Five parallel read-only lanes; the integrator re-opened the top citations (`connection.dart`, `search_index.dart`, `app_database.dart`, `injector.dart`, `router.dart`, `backup_service.dart`, `settings_cubit.dart`, `audio_downloader.dart`, `data_extraction_rules.xml`, `app.dart`, `main.dart`, `core/di/injector.dart`, `search_index.dart`). Citations marked **†** were not re-opened and rest on lane evidence.
- Not checked: no runtime profile, no frame timings, no memory dump, no live TLS/redirect probe, no dependency CVE scanner, no merged-manifest or APK/AAB inspection, no device test. `web/` was checked only at the headers/CSP/CI level.
- Test counts are the integrator's own: 815 passed, exit 0. `dart format` = 0 changed. Analyze = 0.
- No file was edited, created, or deleted inside the repository; the test log was written to `%TEMP%`.
