# Code Quality Audit + Remediation Record — Mobile App (`quran_yahdi`)

**Date:** 2026-10-20 · **Scope:** `lib/`, `test/`, `android/`, `tools/` (Flutter app only; the `web/` Astro site has its own report)
**Method:** read-only audit → a 6-wave remediation campaign with executor subagents → an independent re-audit. Every headline claim was re-verified at source by the PM.
**Weights:** Maintainability 20% · Clean Architecture 20% · Code Quality 20% · Security 25% · Performance 15%

## Baseline

| Item | Value |
|---|---|
| HEAD at audit time | `8a89d5c` (main) — `feat(app): bound the awaited boot inits` |
| Porcelain at audit time | `M .vscode/settings.json`, `?? INSTRUCTIONS.md` (owner debris, untouched) |
| Toolchain | Flutter 3.47.5 stable / Dart 3.13.4 · Windows PowerShell 5.1 |
| Scale | ~162 `lib/*.dart` files · 16 feature modules · 159 `test/` files |
| Stack | flutter_bloc 9.1.1 + freezed · get_it · go_router 18.1.0 · drift 2.35 · dio 5.11 · flutter_localizations/ARB · just_audio · adhan · hijri · geolocator · sensors_plus · flutter_local_notifications · app_links · share_plus |

## Score journey

| Dimension | Weight | Audit | After campaign | Final re-audit |
|---|---|---|---|---|
| Maintainability | 20% | 7.4 | 7.8 | **8.3** |
| Clean Architecture | 20% | 6.2 | 8.4 | **7.8** |
| Code Quality | 20% | 7.6 | 8.2 | **7.6** |
| Security | 25% | 8.2 | 8.5 | **8.2** |
| Performance | 15% | 7.8 | 8.2 | **8.2** |
| **Weighted** | | **7.5** | **8.2** | **8.02** |

Final arithmetic: `8.3×.20 + 7.8×.20 + 7.6×.20 + 8.2×.25 + 8.2×.15 = 1.66 + 1.56 + 1.52 + 2.05 + 1.23 = 8.02`

---

# PART 1 — The original audit (2026-10-20, pre-remediation)

## 1) Maintainability — 7.4/10 at audit time

The codebase was unusually disciplined for its size: architecture *test-enforced*, DI and routing centralized, localization complete, states uniformly immutable. The drags were polish-scale.

| Finding | Status |
|---|---|
| `lib/features/library/data/pack_downloader.dart:84` — `install()` ran ~157 lines (file 376 lines), the only hand-written file > 350 | **CLOSED** — split into 13 helpers; longest is `_writeTafsir` (38 lines) |
| `lib/features/library/presentation/ayah_sheet/library_sheet.dart:20` — class `LibrarySheet` in the `ayah_sheet/` folder; misleading name | **CLOSED** — renamed `AyahSheet`; the old name survives only as a documented compatibility alias (the frozen test imports the file by path) |
| `AGENTS.md:41` — documented "15 features" and a uniform `data/` + `presentation/` split; reality is 16 feature dirs with 4 exceptions | **CLOSED** — `AGENTS.md` restated with the exceptions |
| `lib/features/duas/presentation/duas_screen.dart:75,134` + `settings_screen.dart` (86-line `build()`) | **CLOSED** — the settings screen's `build()` was split into `SettingsScreen` + `_SettingsList` |
| `lib/core/theme/app_theme.dart:11` — no spacing scale; ~134 hardcoded size literals | **CLOSED** — `lib/core/theme/app_spacing.dart` (xs 4 / sm 8 / md 12 / lg 16 / xl 24); 101 literals replaced across 21 files, pixel-identical |
| `lib/features/recitation/presentation/playback/playback_cubit.dart:38` — mutable `_reciterName` outside the frozen state | **CLOSED** — derived from state |
| Documentation: 29 of 86 files > 40 lines had zero `///` docs | **CLOSED** — 2,559 `///` lines now in hand-written `lib/`; the composition root + every public cubit member are documented |

**Strengths kept:** `test/architecture_guard_test.dart:9` pins cross-feature edges; `lib/app/router.dart:84` centralizes all 19 routes; exactly one English literal in presentation code; all 24 state classes use `@Default` lists.

## 2) Clean Architecture — 6.2/10 at audit time

The skeleton was real (DIP seams `AyahSource`/`ReciterSource`/`CatalogSource`/`WirdProgressSink`, no UI imports in data layers, no navigation in cubits) but the domain layer was decorative and cross-feature coupling dominated.

| Finding | Status |
|---|---|
| `lib/core/di/injector.dart:8` — **core** imported 35 feature classes (inverted dependency) | **CLOSED** — the composition root moved to `lib/app/di/injector.dart`; `lib/core/di/injector.dart` is a 10-line re-export shim with **0** feature imports |
| 5–6 cubits imported other features' **data** layers (`settings_cubit.dart:5`, `home_cubit.dart:6`, `prayer_times_cubit.dart:6`, `qibla_cubit.dart:6`, `duas_cubit.dart:9`) | **CLOSED** — they depend on ports in `lib/core/domain/`; cross-feature edges fell **11 → 3** |
| Drift rows (`Surah`, `Ayah`, `ReciterRow`) leaked into presentation signatures | **CLOSED** — domain entities + repository mappers; the legacy row-typed port members stay only because 4 frozen test doubles implement them |
| `lib/core/di/injector.dart:126` + `lib/app/router.dart:113` — route cubits were shared `lazySingleton`s (state leaked between visits) | **CLOSED** — route cubits are `registerFactory`; the app-wide download queue and the player stay shared on purpose |
| `lib/core/di/injector.dart:97` registered `CityRepository` conditionally while the router resolved it unconditionally | **CLOSED** — registered unconditionally with an empty-catalog fallback |
| No domain layer for search/filter rules; raw `error.toString()` in 7 cubits | **CLOSED** — ports in `core/domain`; no raw exception string reaches any state |

**Verified at the final re-audit:** `lib/core/**` → features = **0** · features → `lib/app/` = **0** · feature presentation → another feature's data = **0** · `getIt<` inside `lib/features/` = **0** (constructor injection throughout).

## 3) Code Quality — 7.6/10 at audit time

Hygiene was already excellent (0 `print`, 0 TODO, 0 force-unwrap, 0 `setState`, 0 `FutureBuilder`); the defects were duplication, a write-only error field and split state naming.

| Finding | Status |
|---|---|
| Arabic normalization duplicated in `arabic_search.dart:25` and `city_repository.dart:90` | **CLOSED** — one implementation (the fold core is exported; the city variant's whitespace behavior is preserved deliberately) |
| Two divergent byte→MB formatters (`library_screen.dart:175`, `reciter_surahs_screen.dart:290`) | **CLOSED** — one `lib/core/utils/format_bytes.dart` (one decimal, both sides) |
| Arabic digit mapping written twice (`arabic_numbers.dart:16,28`) | **CLOSED** — proven equal over −100000…100000 |
| Write-only `message:` field holding raw exceptions in 7 error states | **CLOSED** — field removed; diagnostics go to `dev.log`; the reader's distinct reason became `ReaderState.failed(emptySurahId:)` with a new localized key |
| Three spellings of one convention (`loaded`/`error`/`failed`) | **CLOSED** — all 18 states are `loading`/`ready`/`failed`; `initial` collapsed into `loading`; qibla got a real `failed` variant; compatibility typedefs keep the frozen tests compiling |
| Copy-pasted qibla test fakes | **CLOSED** — moved to `test/support/fakes.dart` (4 files, imports only; assertions byte-identical) |
| `analysis_options.yaml` barely stricter than stock `flutter_lints` | **CLOSED** — 47 lints added, each tried individually and kept only at 0 findings; the 24 that would have demanded a mass rewrite are documented as rejected |
| `duas_cubit.dart:85-96` force-unwraps | **CLOSED** (6 sites) — 28 more remain across the tree and are listed below |

## 4) Security — 8.2/10 at audit time

A well-defended client-only app: no accounts, no server, no hardcoded secrets, no cleartext HTTP, no WebView, no archive extraction, no raw SQL interpolation. The two real gaps were a release-signing fail-soft and a read-before-size-check.

| Finding | Status |
|---|---|
| `android/app/build.gradle:56` — release builds fell back to `signingConfigs.debug` | **CLOSED** — a store-bound build now hard-fails: `PUBLISH_RELEASE=true` (env) or `-PpublishRelease=true`, plus a new `publish` build type that requires the release signing config. Local release builds keep the documented debug-signed fail-soft; CI only warns |
| `lib/features/backup/presentation/backup_cubit.dart:60` — the file was fully read *before* the 2 MB cap | **CLOSED** — the on-disk length is checked before the read; the bytes of an oversized file never reach memory |
| `lib/features/library/data/library_catalog.dart:112` — `sha256` optional | **CLOSED** — a remote pack must be pinned (per-file or per-surah for tafsir); the real bundled catalog passes with 0 gaps (9/9 pinned) |
| `assets/data/library_catalog.json:1` — tafsir pinned to the mutable tag `v1.2.2` | **CLOSED** — pinned to commit `eb82bb6294efe30ad5c135c03b1864afaa70e855`; the bytes at the SHA were proven identical to the tag |
| `reciter_repository.dart:79` — mp3quran payload not hash-verified | **PARTIAL (accepted)** — upstream mutates the list, so a hard hash pin is wrong; the allowlist + a sanity floor (≥1 trusted row + ≥1 pinned featured reciter) replaces it, with the reason documented in the code |
| `AndroidManifest.xml` — `MediaButtonReceiver` exported with no permission | **CLOSED** — `android:permission="android.permission.BIND_MEDIA_BUTTON"` added |

**Additional findings closed during the campaign (found by the re-audit):** GPS coordinates were being written into the **shared** backup file (now the city travels as id + names only, and the import restores the selection by id) · the deep link clamped the surah but not the ayah (now 1..286) · the backup importer logged the raw error, and a `jsonDecode` error embeds a snippet of the user's file (now only `error.runtimeType` is logged) · the `AudioService` stays exported without a permission (see the open items).

## 5) Performance — 7.8/10 at audit time

Genuinely disciplined: background-isolate SQLite with WAL, a lazy reader, chunked download hashing, a bounded pack-projection cache.

| Finding | Status |
|---|---|
| `lib/main.dart:39` — boot awaited two plugin inits (8 s caps) **before** `runApp` | **CLOSED** — `runApp` now runs first; the inits moved behind the first frame with 1.5 s caps, fail-open, and **queued-not-dropped** requests (a reminder set during the init window is applied when the plugin reports ready) |
| `khatma_repository.dart:94` — `WHERE ayahs.page = ?` was unindexed (6236-row scan) | **CLOSED** — `idx_ayahs_page` added in the same idempotent `beforeOpen` block; `idx_downloads_status` added for the downloads screen |
| `pack_downloader.dart:248` — the install sniff returned the whole decoded tree across the isolate port | **CLOSED** — the sniff now returns a shape verdict + projection, computed inside the worker isolate |
| `pack_downloader.dart:136` — per-surah `utf8.decode` + `jsonDecode` on the UI isolate (114×) | **CLOSED** — off the UI isolate, batched per window instead of per surah, with bounded (4) download concurrency and `BytesBuilder`/`Uint8List` bodies (zero-copy port transfer) |
| `reader_cubit.dart:89` + `reader_screen.dart:138` — every bookmark emission rebuilt the whole reader Scaffold | **CLOSED** — a `buildWhen` guard plus a per-verse `BlocSelector`; the per-build `indexWhere` moved to `initState` |
| `notifications_binding.dart:173` — every reload cancelled and re-scheduled all alarms | **CLOSED** — a plan fingerprint short-circuits the platform round-trip when nothing changed |
| `backup_cubit.dart:70` — the backup file was decoded on the UI isolate | **CLOSED** — decoded in a worker isolate (with an inline fallback under `FLUTTER_TEST`) |
| `lib/core/db/connection.dart:24` — the 3.27 MB SQLite asset was loaded whole on the UI isolate | **CLOSED** — the asset copy + the re-seed now run on a worker isolate; the UI isolate only receives the executor |
| `just_audio_playback_service.dart:12` — the `AudioPlayer` was never disposed | **CLOSED** — a `DisposablePlaybackService` capability interface; `close()` disposes when present (the 6 frozen doubles still compile) |
| `reciter_repository.dart:121` — the reciters body was parsed on the UI isolate | **CLOSED** — parsed in a worker isolate; the allowlist and the sanity floor still run on the parsed rows |

---

# PART 2 — The campaign

Six waves, each with executor subagents, disjoint file ownership, a STOP list, and gates after every wave. The mobile suite was frozen at **598 tests** throughout and ended at **598/598**.

| Wave | Scope | Result |
|---|---|---|
| W1 | Mobile security & data integrity (6 fixes) | landed; 2 rulings applied (the CI trigger became `PUBLISH_RELEASE`, the pin gate moved to the loader) |
| W1b | Mobile security follow-up | the CI trigger now fires only for store-bound builds, so the pipeline stays green; the catalog pin is enforced at the loader (9/9 packs, 0 gaps) |
| W3 | Mobile architecture | composition root, 5 core ports, domain entities, DI lifetimes, state normalization, `message` removal |
| W4 | Mobile performance | boot ordering, 2 indexes, reader rebuild scope, notification fingerprint, isolate offloads, `install()` split |
| W4b | Mobile maintainability & quality | de-duplication, spacing scale, `AyahSheet` rename, shared test fakes, ~318 doc comments |
| W5 | Boot-readiness regression fix | the tri-state background-audio guard and the queued-not-dropped notification plan (both regressions were introduced by W4 and caught by the PM before commit) |

**Gate results at the final state:** `flutter analyze` → **No issues found!** (16.3 s) · `flutter test` → **598/598 passed** (2:39) · working tree: 192 changed files, +4,423 / −2,473.

## Deviations and disclosures

- **Frozen-test edits (4 + 2 files, disclosed):** `test/qibla_{screen,lifecycle,quality_probe,compass_availability}_test.dart` (the duplicated fakes moved to `test/support/fakes.dart` — imports only, assertions byte-identical) and `web/tests/unit/{content-packs,headers}.test.ts` (the pinned tafsir URL follows the source pin; the expected header-block list follows the two intentional cache blocks). No assertion was weakened and the suite count did not change.
- **Compatibility shims kept on purpose:** `lib/core/di/injector.dart` (the frozen tests import it), the `LibrarySheet` typedef (the frozen test imports the file by path), the `AyahLookup` row-typed members (4 frozen doubles implement the port) and the `PlaybackInitial` typedef (4 frozen tests name it).
- **No `@Deprecated` on the compat typedefs:** it would turn the frozen tests' usages into analyzer infos and break the 0-issues gate; a doc comment marks them instead.
- **`analysis_options.yaml`** gained 47 lints; 24 more were tried and rejected because each would have demanded a mass rewrite (`require_trailing_commas` alone would touch 639 sites). The rejected list is recorded in the wave report.
- **Two regressions were introduced and caught before commit** (the moved plugin init made "not yet initialized" look like "unavailable", and dropped a reminder set in the first 1.5 s). Both are fixed and covered by the frozen suite.
- **Not verified on a device:** the isolate paths (DB asset copy, pack/backup/reciters decode) and the `publish` build type — the wave could only prove them structurally.

---

# PART 3 — Final re-audit (independent, 2026-10-20)

**Mobile: 8.02/10** — Maintainability 8.3 · Clean Architecture 7.8 · Code Quality 7.6 · Security 8.2 · Performance 8.2

## Still open (verified true at source)

| # | Issue | Fix |
|---|---|---|
| 1 | `lib/features/quran/presentation/reader/reader_screen.dart:16` imports another feature's **Cubit** | move to a `core/domain` port |
| 2 | `lib/features/notifications/data/reminder_planner.dart` → `tracker/data/prayer_log_repository.dart` (data → data) | port it |
| 3 | `lib/features/qibla/presentation/qibla_state.dart:15` has no `loading` variant (the cubit boots into `ready`) | add `loading` |
| 4 | `lib/features/library/data/library_catalog.dart:80` — an 85-line `fromJson` | split |
| 5 | 28 force-unwraps remain (e.g. `reciter_repository.dart:62`) | bind locals |
| 6 | `lib/features/library/data/pack_downloader.dart` is now the largest hand-written file (608 lines) | split by concern |
| 7 | `AppSpacing` reaches 23 of 164 files | adopt repo-wide |
| 8 | `lib/features/prayer/presentation/prayer_times/prayer_times_screen.dart:107` and `backup_codec.dart:211` force-unwrap a state field | pattern-match the state |
| 9 | `lib/core/domain/ayah_lookup.dart:1` still makes `core/domain` depend on the drift schema | keep, but the coupling is real |
| 10 | The `FLUTTER_TEST` fallback means the isolate paths are never exercised by the suite | add an isolate-backed test (needs an owner grant: the suite is frozen) |

## Accepted trade-offs (deliberate, documented in code)

| Item | Verdict |
|---|---|
| The row-typed `AyahLookup` members | Accepted — pinned by 4 frozen doubles; the domain path is clean via `AyahLookupRefs` |
| `test/architecture_guard_test.dart:9` pins 11 cross-feature edges while 3 are live | Real but low risk — pruning is a test-only edit (the suite is frozen) |
| `library_sheet.dart` keeps its old file name | Accepted — the frozen test imports it by path; the alias keeps it honest |
| The `AudioService` is exported with no permission | **Real risk (low)** — `just_audio_background` requires it for the MediaBrowserService role; the owner may rule on `BIND_MEDIA_BROWSER_SERVICE` |
| The bundled-catalog pin rides on the loader, not `fromJson` | Accepted with a gap — synthetic frozen fixtures have no hashes; both live paths are covered |
| The reciters payload is TLS-only, not hash-verified | Accepted — upstream mutates it; the host allowlist + the sanity floor + the committed snapshot are the controls |

**The single highest-value remaining action is not code: the hardened tree is UNCOMMITTED.**
`git show HEAD:lib/...` still ships the pre-remediation app. Until the campaign is committed (and pushed in an owner-GO window), the audit scores describe the working tree only.
