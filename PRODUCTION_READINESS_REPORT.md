# Production Readiness Audit — Quran Yahdi (`quran_yahdi`)

> **Verdict: NOT PRODUCTION-READY for a public Android release at this commit.**
> The engineering foundations are strong, but four confirmed release blockers, a cluster of
> high-severity reliability and data-integrity defects, and a store-readiness gap make a
> public upload unsafe today. The application is a credible **internal / closed-testing
> candidate** after the P0 items in §15 are closed.

| | |
|---|---|
| Repository | `E:\old_flutter\Quran-App-master` |
| Application | Quran Yahdi / قرآن يَهدي — offline-first Quran companion |
| Audited commit | `d39c1f7136f1e0947b4746d5d57c9c852b1a8e63` |
| Branch | `fix/perf-audit-2026-10-27` (0 unpushed vs `origin/main`) |
| Audit date | 2026-10-30 |
| Toolchain | Flutter 3.47.5 stable · Dart 3.13.4 |
| Shipped target | Android (`applicationId com.mostafasayed.quranyahdi`); iOS is scaffold-only |
| Mode | The audit was read-only. The 2026-10-30 security remediation pass is recorded in §18 and modified the files listed there. |
| Method | 8 parallel read-only dimension subagents + orchestrator gates + direct source re-verification of the load-bearing claims |

---

## 0. Audit metadata and evidence standard

- **Gates were executed by the orchestrator**, not inferred from documentation:
  - `flutter --version` → Flutter 3.47.5 / Dart 3.13.4.
  - `flutter analyze` → **exit 0**, `No issues found!` (78.3 s).
  - `flutter test` → **exit 0**, `+828: All tests passed!` at audit time; after the
    2026-10-30 security pass the suite was **841/841** (§18), after the functional pass
    **850/850** (§19), **856/856** after the performance/accessibility pass (§20), and
    **877/877** at the final cross-cutting state (§23).
- **No build, no device run, no store-console access, no live API probing** was performed in
  this audit. Claims that require those are marked **Needs verification** in §16.
- The orchestrator re-opened the source for every P0 and P1 finding and for the contrast,
  plural, retry, permission, scheduling, R8, manifest, and release-artifact claims. Findings
  that rest on a lane's citation only are labeled **Lane** in the verification columns.
- No secret value appears in this report. `android/key.properties` and
  `android/local.properties` were not opened; only `git check-ignore` was used.
- **Read-only proof:** at the start of the audit and again immediately before this report was
  written, `git status --porcelain` was identical: `M .vscode/settings.json`,
  `?? INSTRUCTIONS.md`, `?? assets/icons/logo_1.png`, `?? assets/icons/logo_2.png`,
  `?? web/design-concepts/` — all pre-existing owner debris. `git rev-parse HEAD` did not change
  during the audit. The only addition during the audit was this report; the later security
  remediation is listed in §18 and is not part of the read-only audit claim.

---

## 1. Executive summary

### 1.1 Verdict

**Do not ship this build to production.** The codebase is not amateur work — its architecture
guard, typed error handling, offline-first data model, security baseline, and 828-test suite
are better than most solo Flutter projects. The problem is not craft; it is that several
**user-facing promises do not hold in production conditions**, and the **release process
around the code is not yet trustworthy**.

### 1.2 The four confirmed release blockers

1. **Reminders cannot deliver what the app promises.** The planner schedules exactly one
   prayer alarm (`prayerReminderId = 1`) and stops at the first future prayer; nothing
   re-plans after it fires, and there is no boot receiver. A user who enables only prayer
   reminders is never asked for the Android 13+ notification permission. In practice a
   user can receive one prayer notification per cold start — or none at all.
2. **The verified store artifact is stale.** The last signed AAB was built from `76da2d7`;
   **20 commits** touching `lib/`, `assets/`, `android/`, or `pubspec.yaml` have landed since,
   including a rewrite of the 4 MB Quran database. `versionCode` is still `3`, and the store
   screenshots were captured from that older build.
3. **CI produces an ungated, debug-signed artifact named like a release.** The
   `release-artifact` job has no `needs: analyze-test`, does not set `PUBLISH_RELEASE=true`,
   and uploads `app-release-aab` / `app-release-apk` built with the debug key.
4. **Content licensing is not cleared.** The project's own licensing matrix still marks the
   two Quran fonts, the Siraj tafsir text, and the mp3quran listing terms as
   `FLAG → OPEN-FOR-OWNER`. A store launch on that basis carries takedown risk.

A fifth blocker is **conditional on the Play Console**: if Play App Signing is enabled (it is
mandatory for new apps), the live `assetlinks.json` pins only the local upload certificate,
so Android App Links will silently stop opening the app. This must be verified before release.

### 1.3 What is genuinely strong

- **Enforced architecture:** `test/architecture_guard_test.dart` pins the exact permitted
  feature edges; `core → features` and `feature → app` are zero; every feature `data/` file is
  Flutter-free except one known `dart:ui` import in notifications.
- **State discipline:** 146 `isClosed` guards, typed `on <Type>` catches, per-feature stale
  response tokens, and route-scoped cubits closed by `RouteCubitScope`.
- **Security baseline:** no tracked secrets on any ref, no WebView, no analytics SDK, HTTPS-only
  endpoints, parameterized SQL everywhere, sha256-pinned packs, 2 MiB backup cap with setting
  whitelist and coordinate redaction, signature-level permissions on exported services,
  exact-host deep-link validation, and a fail-closed `PUBLISH_RELEASE` signing path.
- **Offline-first design:** the full Quran (114 surahs / 6,236 ayahs) ships on-device; the
  search index is prebuilt and stamped; plugins initialize behind the first frame with
  1.5 s fail-open caps; the DB runs on a background isolate with WAL.
- **Test volume and gate hygiene:** 828 passing tests, 0 analyzer issues, deterministic
  in-memory drift harnesses, real MethodChannel fakes, and explicit regression tests for the
  last remediation wave.

### 1.4 What this means

The work needed is **bounded and specific**, not a rewrite. The critical path is:
fix the reminder engine and permission prompt; harden the download/pack/backup/DB recovery
paths; rebuild and re-verify the signed artifact; gate the CI release job; close licensing;
then do a signed-device smoke pass. The accessibility and localization polish (contrast,
Arabic plurals, RTL chevrons) is P1 because it affects every user but does not by itself
prevent task completion.

---

## 2. Scope, method, limitations

### 2.1 Scope

Audited: `lib/`, `test/`, `integration_test/`, `assets/`, `android/`, `ios/` configuration,
`.github/workflows/`, `tools/`, `docs/store/`, `PRIVACY.md` / `PRIVACY.en.md`, and the
`web/public/.well-known/assetlinks.json` contract. `web/**` (the Astro site) was **not**
audited beyond the App Links file and the CI security contrast; it is a separate campaign.

### 2.2 Method

Eight read-only lanes ran in parallel:

1. Feature completeness and end-to-end user journeys.
2. Architecture, DI, state management, code quality.
3. Security and Android/iOS platform configuration.
4. Data integrity, remote reliability, error handling, resilience.
5. Performance, startup, memory, resource usage.
6. UX, accessibility, localization, RTL.
7. Testing strategy, coverage, CI execution.
8. Build, release, deployment, store readiness.

The orchestrator then ran the objective gates, re-read the load-bearing files, and reconciled
contradictory claims. Where a lane's claim did not reproduce, it was corrected or downgraded
(see §17.3).

### 2.3 Limitations

- **No device, emulator, APK, AAB, or merged manifest was inspected.** Permission merging,
  effective `targetSdk`, plugin-contributed components, 16 KB ELF alignment, and runtime
  notification/sensor/audio behavior are therefore unproven.
- **No runtime profiling.** Startup time, frame times, memory, and battery claims are static
  code analysis and are labeled accordingly.
- **No CVE/advisory database.** Dependency claims are pinned versions, never "known safe".
- **No store console.** Highest uploaded `versionCode`, Play App Signing state, closed-testing
  eligibility, and policy outcomes are unknown.
- **No live TLS/DNS probe** of the three remote hosts.
- **No iOS build.** iOS is a template without a Podfile, signing team, associated domains, or
  privacy manifest; it is out of scope for the current Android release.
- Roughly 35 of the 253 test files were read line-by-line; the rest were counted and
  keyword-scanned. The 72.05 % coverage figure in `coverage/lcov.info` is **stale and
  unverified** (§12.3).

---

## 3. Phase 1 — Project discovery

### 3.1 Stack and scale

| Item | Value |
|---|---|
| Framework / language | Flutter 3.47.5 / Dart 3.13.4 |
| State | `flutter_bloc ^9.1.1` cubits + `freezed` immutable states |
| DI | `get_it ^9.3.0`; `lib/app/di/injector.dart` is the composition root |
| Routing | `go_router ^18.1.0` (20 routes) |
| Local DB | `drift ^2.35.2`, SQLite on a background isolate, WAL at runtime |
| HTTP | `dio ^5.11.1` (+ `http ^1.6.0`) |
| Audio | `just_audio ^0.10.6` + `just_audio_background 0.0.1-beta.17` |
| Notifications | `flutter_local_notifications ^22.3.2` + `timezone ^0.11.2` |
| Device | `geolocator ^14.0.1`, `sensors_plus ^7.1.1`, `adhan ^2.0.0+1`, `hijri ^3.0.1` |
| Platform glue | `app_links ^7.2.2`, `share_plus ^13.3.1`, `file_picker ^13.1.0` |
| l10n | `flutter_localizations` + ARB (`ar` template, `en` mirror, generated files committed) |
| Scale | 210 `lib/**/*.dart` files · 34,021 lines · 16 features · 253 test files · 4 integration files |
| Assets | 12.6 MB on disk, ~5.34 MB declared in the bundle: DB 4.17 MB, fonts 1.09 MB, data 0.07 MB |
| Shipped data | 114 surahs, 6,236 ayahs, prebuilt `ayah_search` (6,236 rows), 156 cities, 75 azkar, 40 duas, 99 names, 3 library packs |

### 3.2 Architecture

- `lib/app/` + `lib/main.dart` compose the app; `lib/core/` owns DB, domain ports, theme,
  l10n, utils, and shared widgets; `lib/features/<feature>/` owns `data/` + `presentation/`
  (with `quran/domain/` and `recitation/domain/` + `playback/` as documented exceptions).
- The composition root is the only layer that imports every feature. `lib/core/di/injector.dart`
  is a documented compatibility shim re-exporting the app injector.
- Route-scoped cubits are created in `lib/app/router.dart` through `RouteCubitScope`; app-scoped
  `PlaybackCubit` and `DownloadsCubit` are lazy singletons because they must survive navigation.
- Ports (`AyahLookup`, `CitySource`, `PrayerTimesPort`, `LastReadMarker`, `WirdProgressSink`,
  `ReminderSchedulerPort`) are cohesive and have real consumers.
- The architecture guard pins the exact live cross-feature edges (`quran → library`,
  `quran → recitation`) and has planted-violation tests.

### 3.3 Data and remote services

- **Bundled content:** `assets/db/quran.sqlite` (4,173,824 B) with Uthmani/Imlaei text and a
  prebuilt search index; content version and search-index version are stamped in `settings`.
- **Remote:** `https://mp3quran.net/api/v3/reciters` (catalog), `https://quranyahdi.pages.dev`
  (deep links / privacy), and `https://cdn.jsdelivr.net` (three pinned library packs). All HTTPS.
- **Accounts / backend / payments:** none. No authentication, no server-side user data, no ads,
  no analytics, no crash-reporting SDK.
- **Backups:** plaintext JSON, 2 MiB import cap, settings whitelist, city coordinates redacted;
  the plaintext-at-rest decision is documented in
  `docs/superpowers/specs/2026-10-24-backup-encryption-decision.md`.

### 3.4 Platform and release configuration

- `applicationId` / `namespace`: `com.mostafasayed.quranyahdi`; `version: 1.0.0+3`.
- `minSdk` 24, `compileSdk` / `targetSdk` inherited from Flutter 3.47.5 (36 on this toolchain).
- Release signing reads `android/key.properties` (gitignored, present only on the owner machine);
  `PUBLISH_RELEASE=true` fails the build when the keystore is absent.
- Android manifest: launcher activity `exported` with `singleTop` and empty `taskAffinity`;
  media browser/media button services are signature-permission-gated; notification receiver is
  `exported=false`; `allowBackup=false`; no storage/camera/microphone/contacts permissions.
- CI: `ci.yml` (analyze, format, test, release artifacts on push) and `web.yml` (the Astro site).
- **No build flavors or environment split:** there is one production configuration; the three
  remote hosts are compile-time constants. That is acceptable for a single-environment v1, but
  there is no staging path to exercise a catalog or CDN change before users see it.

### 3.5 Feature inventory

| Feature | Routes / surface | State | Summary |
|---|---|---|---|
| Home | `/home` | Partial | Next-prayer card + continue reading + 14-tile grid; card does not tick, failures have no retry |
| Surah index | `/quran` | Partial | 114 surahs, instant name/number filter, verse-search hand-off; failure is a dead end |
| Quran search | `/quran/search` | Complete | Keyset paging, stale-response guard, substring LIKE (no ranking) |
| Reader (verses + mushaf) | `/quran/reader` | Partial | Both modes, bookmarks, share, ayah sheet; continue-reading only advances in mushaf mode; no juz/sajda/prev-next/font size |
| Bookmarks | `/bookmarks` | Complete | Live page 1 + keyset older pages; delete has no confirm/undo |
| Ayah sheet | modal | Partial | Works only for installed packs; no `tafsir`-kind pack ships |
| Reciter catalog | `/recitation` | Complete | Remote mp3quran catalog, host allowlist, offline cache, soft-fail banner |
| Reciter surahs / downloads | `/recitation/reciter` | Partial | Per-surah download only; no global queue, resume, or download-all |
| Playback / mini player | bottom sheet | Complete (scope gap) | Seek, background audio, MediaItem; mini player only on 2 of 20 routes |
| Library packs | `/library` | Partial | 3 packs; no version/update path; no cancel; multi-file install has no retry |
| Hadith browser | `/library/hadith` | Partial | 10 per page, prev/next only; no search or book/chapter TOC |
| Prayer times | `/prayer-times` | Partial | Countdown, day rollover, pull-to-refresh; calculation method hard-coded Egyptian |
| City picker | `/prayer-times/city` | Complete | 156 cities, search, GPS nearest-city, denial snackbar |
| Reminders | settings + boot | **Broken for prayer-only users** | One alarm at a time; no recurrence; no boot receiver; permission prompt gated on azkar |
| Qibla | `/qibla` | Partial | Raw magnetometer only; no tilt compensation or accuracy UI |
| Azkar | `/azkar` | Partial | 13 collections / 75 items, search, counters; counters ephemeral |
| Tasbih | `/tasbih` | Complete | Count + target persist; no dhikr text; hydration race |
| Duas / Ruqyah | `/duas` | Complete | 40 duas + 9 ruqyah entries, categories, Quran ranges |
| Asma ul-Husna | `/asma` | Complete | 99 names + detail overlay; system back exits the screen |
| Worship tracker / khatma | `/worship` | Partial | Khatma plan and reader hand-off; prayer log is today-only |
| Zakat | `/zakat` | Partial | Correct math and Arabic-digit parsing; no validation, no persistence |
| Hijri calendar | `/hijri` | Partial | Month nav + today highlight; no weekday header; 9sp Gregorian line |
| Settings | `/settings` | Partial | 3 reminder switches, times, permission hint, backup, licenses; no about/version |
| Backup export/import | embedded | Partial | Preview + transactional merge + reschedule; skipped entries are silently dropped |
| Deep links / notification taps | — | Complete | Exact host + clamped surah/ayah; cold and warm routing pinned by unit tests |
| Licenses | pushed from settings | Complete | Asset licenses + `showLicensePage` |

### 3.6 Documentation and governance

The repo has unusually strong in-repo governance: `AGENTS.md`, an append-only
`docs/campaign-ledger.md`, a 2026-10-30 code-quality audit, remediation plans with commit
hashes, a store runbook, a licensing matrix, and a data-safety answer sheet. This audit treats
documented-kept and known-closed items as such and focuses on what those documents do **not**
cover: production delivery, store compliance, and real-user failure modes.

---

## 4. Objective gate results

| Gate | Command | Result | Evidence |
|---|---|---|---|
| Toolchain | `flutter --version` | Flutter 3.47.5 / Dart 3.13.4 | stdout |
| Static analysis | `flutter analyze` | **PASS** — 0 issues, 78.3 s | `%TEMP%\opencode\audit_analyze.log` |
| Tests | `flutter test` | **PASS** — 828/828, exit 0 | `%TEMP%\opencode\audit_test.log` |
| Coverage | not run | **UNVERIFIED** — `coverage/lcov.info` is dated 2026-10-24, 99 commits behind HEAD | file mtime + git log |
| Release build | not run | **NOT ASSESSED** — read-only audit | — |
| Device smoke | not run | **NOT ASSESSED** | — |
| Format gate | not run | **NOT ASSESSED** — CI runs it; local run not repeated | — |

Passing tests are **not** evidence of production readiness: the suite does not boot the real
app in CI, does not run on a device, and does not exercise the wiring between search results,
deep links, notification taps, and the router.

---

## 5. Production-readiness scorecard

Weights reflect release risk for a first public Android launch, not code aesthetics.

| Dimension | Score | Weight | Contribution | Rationale |
|---|---:|---:|---:|---|
| Release & deployment readiness | **4.5** | 20 % | 0.90 | Stale artifact, frozen versionCode, ungated debug-signed CI artifacts, uncleared licensing, no R8/obfuscation, no monitoring/rollback |
| Functional completeness | **5.5** | 15 % | 0.825 | Core reading is solid; reminders are structurally one-shot; continue-reading is frozen in verse mode; downloads/hadith/juz/sajda/font size are partial |
| Security | **8.0** | 15 % | 1.20 | No confirmed high/medium exploitable issue; strong baseline; residual low gaps (pack redirects, FINE location, D2D DB, supply chain) |
| Data integrity & resilience | **5.5** | 15 % | 0.825 | Silent partial backup restore, orphaned downloads, ghost pack files, stale seed rollback, no DB corruption recovery, tasbih race |
| Architecture & code quality | **7.2** | 15 % | 1.08 | Strong boundaries and state discipline; app-scoped state leaks across route surfaces; a few unguarded async paths |
| Testing & QA | **6.3** | 10 % | 0.63 | 828 tests and strong unit coverage; integration tests absent from CI; critical wiring untested; coverage gate absent |
| UX, accessibility, localization | **5.5** | 10 % | 0.55 | Gold-as-text contrast failures, zero Arabic plurals, RTL chevron bugs, missing retries/confirmations, typography gaps |
| **Overall** | **6.0 / 10** | 100 % | **6.01** | `4.5×.20 + 5.5×.15 + 8.0×.15 + 5.5×.15 + 7.2×.15 + 6.3×.10 + 5.5×.10 = 6.01` |

**Interpretation.** This is a strong codebase with a weak release posture. The prior
2026-10-30 code-quality audit scored 7.8/10 on a different rubric (maintainability,
architecture, quality, security, performance); the two numbers are **not comparable**. That
audit answered "is this well built?" This one answers "can it be put in front of real users
tomorrow?" The answer is no until the P0 items are closed.

---

## 6. Phase 2 — Feature completeness and user journeys

### 6.1 Summary

All 20 routes resolve; no screen is orphaned; there are no `TODO`/`FIXME` stubs and no
hardcoded Arabic in `presentation/`. The incompleteness is concentrated in **features that
work only under ideal conditions**: reminders when the app is opened, downloads when the
network never drops, backups when every entry is well-formed, and the reader when the user
stays in mushaf mode.

### 6.2 Release blockers and high-severity findings

#### FUN-01 — Reminder engine is one-shot and prayer-only users are never prompted

**Severity:** Blocker · **Verification:** Direct

**Evidence:**
- `lib/features/notifications/data/reminder_planner.dart:10` — one fixed `prayerReminderId = 1`.
- `lib/features/notifications/data/reminder_planner.dart:70-92` — the prayer loop breaks on the
  first future prayer; no `matchDateTimeComponents` anywhere (grep count: 0).
- `lib/features/notifications/data/notifications_binding.dart:324-332` — `zonedSchedule` is
  called without a daily repeat component.
- `lib/features/settings/presentation/settings_cubit.dart:92-106` — `setPrayerEnabled` persists
  and re-plans but never calls `ensurePermissions()`; the only `ensurePermissions()` calls are
  in the azkar and wird paths (`:121`, `:168`).
- `lib/main.dart:138-149` — the boot permission grace runs only when `azkarEnabled == true`.
- `android/app/src/main/AndroidManifest.xml:83` — the manifest comment confirms “No boot
  receiver in v1”; there is no `RECEIVE_BOOT_COMPLETED` permission.

**Impact.** A user who installs the app, enables only “تذكير الصلاة”, and closes it receives at
most one prayer notification per cold start (often zero, because Android 13+ denies
`POST_NOTIFICATIONS` and the app never asks). Azkar and wird reminders fire once per plan and
then stop. The headline reminder feature silently fails in the exact usage pattern it exists
for.

**Remediation.** Schedule every remaining prayer of the day under distinct ids
(`prayerReminderId + slot`), add `matchDateTimeComponents: DateTimeComponents.time` for daily
azkar/wird, re-plan on `AppLifecycleState.resumed`, and either add a boot receiver / WorkManager
job or document and enforce “open the app daily”. Request notification + exact-alarm permissions
on **any** reminder toggle, and surface a denied state for the prayer switch too.

#### FUN-02 — Continue-reading never advances in the default verse mode

**Severity:** High · **Verification:** Direct

**Evidence:** `lib/features/quran/presentation/reader/reader_cubit.dart:77` saves the marker on
load; `:157` saves it only from `onMushafPageChanged` (wired at
`lib/features/quran/presentation/reader/reader_screen.dart:376`). The verse list has no
scroll/visibility observer; `saveAyahId` has exactly those two call sites.

**Impact.** A user who reads half of Al-Baqarah in the default verse mode returns Home and is
still offered ayah 1. The primary re-engagement card is effectively frozen for the most common
reading mode.

**Remediation.** Track the first visible ayah in the verse list (throttled to ~1 Hz) and persist
it through the same repository, mirroring the mushaf path.

### 6.3 Additional feature findings

| ID | Sev | Finding | Evidence | Impact | Fix | Verification |
|---|---|---|---|---|---|---|
| FUN-03 | High | Qibla heading is computed from the raw magnetometer only; no tilt compensation, no accuracy signal, no calibration flow | `lib/features/qibla/data/heading_service.dart:9-17,39-40`; `qibla_screen.dart:126-129` | The needle is systematically wrong when the phone is held upright; a religious direction error with no warning | Use a fused rotation vector / `orientationEventStream`, show accuracy + calibration prompt, keep the static bearing as fallback | Direct |
| FUN-04 | High | Zakat inputs have no formatters, no inline validation, no persistence; any unparseable string becomes `0` and flips the verdict to “no zakat” | `zakat_screen.dart:197-232`; `zakat_calculator.dart:24-26`; route creates `ZakatCubit()` per entry | A typo can produce a wrong religious-financial verdict; every visit starts empty | `inputFormatters`, `errorText` when a non-empty field parses to 0, persist the input snapshot, format with grouping/currency | Direct |
| FUN-05 | Med | Prayer tracker renders only today; the repository already supports any day | `tracker_screen.dart:58-61,147-150`; `tracker_cubit.dart:223-236` | A forgotten day becomes an uncorrectable miss; no backfill | Add day navigation or “mark yesterday” | Lane |
| FUN-06 | Med | Reader has no juz navigation, no sajda markers, no prev/next surah, no font-size control, and does not persist verse-vs-mushaf mode | `reader_screen.dart:92-115`; `reader_state.dart:23`; `verse.dart:38-52`; `tables.dart:32,46` | Users can only navigate by surah; sajda verses are unmarked; reading preference resets every visit | Add a juz index, sajda badge, prev/next chevrons, persisted mode + font scale | Lane |
| FUN-07 | Med | Hadith browser is a 10-per-page linear list with no search and no book/chapter TOC | `hadith_cubit.dart:24,65-78`; `hadith_screen.dart:79-165` | A ~7,000-hadith pack is effectively unsearchable | Add text search over `hadith_entries.body` and/or a book selector | Lane |
| FUN-08 | Med | No global downloads screen, storage total, “download all”, or queue that survives app kill | `router.dart:94-375`; `reciter_surahs_screen.dart:139-142`; `downloads_cubit.dart:39-55` | 114 taps for a full reciter; queue lost on restart; stuck rows unreconciled | Add a Downloads route fed by `listDone()` + a reconciled persisted queue | Lane |
| FUN-09 | Med | The backup settings whitelist omits `prayer_reminder_enabled` | `backup_inventory.dart:65-72` vs `reminder_settings.dart:14,93-98` | Restore on a new device silently re-enables prayer reminders for a user who turned them off | Add the key to the whitelist and reminder-relevant keys | Lane |
| FUN-10 | Med | Home’s next-prayer card is computed once and never ticks | `home_cubit.dart:83-88`; `home_screen.dart:66-104` | Leaving Home open past a prayer keeps advertising a passed prayer as “next” | Add a minute ticker or re-plan when the shown time passes | Lane |
| FUN-11 | Med | Installed library packs are never checked for a newer catalog version; `isInstalled(packId, version)` has zero callers | `pack_downloader.dart:476-482`; `library_screen.dart:134-147` | Content corrections require an app release; stale packs are invisible | Wire a version check → “update” affordance | Lane |
| FUN-12 | Low | Azkar counters are ephemeral and have no reset; opening a search hit starts at item 0 | `azkar_cubit.dart:77-107`; `azkar_screen.dart:296-303` | A stray back press zeroes a session; search lands at the top | Persist per-collection counters for the day; add reset; open at the hit index | Lane |
| FUN-13 | Low | Tasbih has no dhikr text and counts past the target | `tasbih_screen.dart:79-82`; `tasbih_cubit.dart:60-73` | Users must know the phrase by heart; “target reached” keeps counting | Offer standard phrases and clamp/restart at target | Lane |

---

## 7. Phase 3 — Architecture and code quality

### 7.1 Verdict

**7.2/10.** The architecture is the strongest dimension: boundaries are enforced by a test, DI
lifetimes are correct where they matter, and cubit discipline is uniform. The residual risk is
not layering — it is **app-scoped state displayed through route-scoped surfaces**, plus a
handful of unguarded async paths.

### 7.2 Findings

| ID | Sev | Finding | Evidence | Impact | Fix | Verification |
|---|---|---|---|---|---|---|
| ARC-01 | High | A failed default-reciter lookup emits `PlaybackState.failed` without stopping the previous track; the mini player is mounted on only 2 of 20 routes | `playback_cubit.dart:151-167`; `mini_player_bar.dart:35`; mounts at `reader_screen.dart:138` and `reciter_surahs_screen.dart:82` | UI says “failed” while audio keeps playing; from 18 routes there is no in-app pause/stop, only the OS notification | Stop before emitting `failed`; host one mini player in the app shell | Direct |
| ARC-02 | Med | `/reader` and `/reciter` resolve `getIt<PlaybackCubit>()` / `DownloadsCubit` unconditionally even though they are registered only when `audioRootResolver != null` | `router.dart:319-321,344-349`; `injector.dart:167-180` | A degraded boot or a test without an audio root crashes on a primary route; the `/library` guard pattern was not applied here | Register the cubits unconditionally with a null-safe downloader seam, or guard + redirect | Lane |
| ARC-03 | Med | Pack install progress lives in the route-scoped `LibraryCubit` while the work belongs to the app-scoped `PackDownloader` | `library_cubit.dart:57-75`; `pack_downloader.dart:102-111` | Leaving `/library` mid-install and returning shows 0 % until it jumps to installed | Move progress into the downloader (stream/ValueListenable) and mirror it in the cubit | Lane |
| ARC-04 | Low | `BookmarksCubit.remove` is the only cubit mutation with no `try/catch`; caller is a bare `onPressed` | `bookmarks_cubit.dart:56-65`; `bookmarks_screen.dart:82` | A DB failure becomes an unhandled async error with no feedback; the row stays | Wrap in the standard typed catch + `dev.log`; restore/mark the row | Lane |
| ARC-05 | Low | Reader share discards the `Future` with no `unawaited` and no catch | `reader_screen.dart:322` | A `PlatformException` becomes an unhandled async error | `unawaited(... .catchError(log))` or a shared helper | Lane |
| ARC-06 | Low | Backup export deletes the temp file in `finally` immediately after `SharePlus.share` resolves | `backup_cubit.dart:236-244` | A receiver that reads the URI lazily can get a missing/empty file | Keep the temp file for the session, or hand over `XFile.fromData` | Lane |
| ARC-07 | Low | `AyahSheetCubit` starts I/O in its constructor, violating the project’s own “route cubits start in `start()`” contract | `ayah_sheet_cubit.dart:26-28`; `route_cubit_scope.dart:9-14` | Load work runs outside the mount lifecycle and cannot be sequenced by the scope | Make it `start()` and call from `initState` | Lane |
| ARC-08 | Low | Cold-start deep-link routing waits behind both plugin inits (up to ~1.5 s) and can override where the user already navigated; the link stream has no `onError` and is never cancelled | `main.dart:82-88,120-180` | A cold link can land late on the wrong screen; a platform stream error is uncaught | Resolve `getInitialLink()` before `runApp` and use it as `initialLocation`; add `onError` | Lane |
| ARC-09 | Low | `player_sheet.dart` has zero tests; the null-track branch schedules `Navigator.maybePop()` on every build | `player_sheet.dart:113-116,193-196`; `mini_player_bar.dart:124` | Double-pop could close the underlying reader; the newest surface can regress silently | Extract the sheet decision; widget-test seek/stop/pop exactly once | Lane |

### 7.3 Structural strengths

- `test/architecture_guard_test.dart` pins the exact edge set and has planted-violation tests.
- `RouteCubitScope` closes cubits on unmount/identity change; every DB stream and subscription
  has a matching `close()`/`cancel()`.
- 146 `isClosed` guards and 72 typed catches; no raw exception strings in `presentation/`.
- App-scoped `PlaybackCubit` and `DownloadsCubit` are deliberate and documented; the problem is
  their **UI surface**, not their lifetime.

### 7.4 Known guard gaps

`test/architecture_guard_test.dart:17` matches single-quoted imports only, does not scan `part`
directives or every conditional-import URI, and the data-layer rule ignores `package:flutter/`
and `dart:ui`. No violation exists today (`notifications_binding.dart:1` is the one live
`dart:ui` import), but the guard is weaker than its documentation suggests.

---

## 8. Phase 4 — Security audit

### 8.1 Verdict

**8.0/10. No confirmed High or Medium exploitable vulnerability in the inspected source.**
The app has no accounts, no backend user data, no WebView, no analytics, no ads, and no
cryptographic claims beyond sha256 integrity checks. The residual risk is release-artifact
hygiene, one over-broad permission, one redirect-class control applied inconsistently, and
device-to-device backup scope.

This is a statement about what could be inspected read-only — not a clean bill of health.

### 8.2 Confirmed security findings

| ID | Sev | Finding | Evidence | Impact | Fix | Verification |
|---|---|---|---|---|---|---|
| SEC-01 | Low | Library pack downloads follow redirects with Dio defaults; only the initial URL’s scheme is checked. Audio was hardened (`followRedirects: false`, 3-hop manual chain) but packs were not | `pack_downloader.dart:282-285,313-316`; contrast `audio_downloader.dart:127-159`; `library_catalog.dart:22` | A redirecting CDN response can fan a request to any host. Content integrity still holds because every bundled pack is sha256-pinned, and an `https → http` hop dies on the cleartext policy | Reuse the audio redirect validator or add a per-hop `https` + `cdn.jsdelivr.net` check | Direct |
| SEC-02 | Low | `ACCESS_FINE_LOCATION` is declared but never used; the only consumer requests `LocationAccuracy.medium` | `AndroidManifest.xml:7-8`; `location_service.dart:50-55` | A broader system prompt than the feature needs; weaker Play Data-safety justification | Drop `ACCESS_FINE_LOCATION`; keep coarse | Direct |
| SEC-03 | Low | `data_extraction_rules.xml` excludes only `database`/`sharedpref`, but the DB lives in `getApplicationSupportDirectory()` → Android `file` domain | `data_extraction_rules.xml:3-10`; `connection.dart:218-219` | Bookmarks, prayer log, khatma, city, and downloaded packs ride device-to-device transfer; contradicts the documented intent | Add `<exclude domain="file" path="."/>` (plus `root`/`external` if used) or correct the decision doc | Direct |
| SEC-04 | Low | CI actions use mutable tags and `ci.yml` has no `permissions:` block | `ci.yml:11-12,35-36,43,48`; contrast `web.yml:39-40,88,92` | Supply-chain and least-privilege gap; the web workflow already does it correctly | Pin SHAs; add `permissions: contents: read` | Direct |
| SEC-05 | Low | Gradle wrapper is gitignored and `distributionSha256Sum` is absent | `android/.gitignore:1,4,5`; `gradle-wrapper.properties:5` | Non-reproducible builds and unverified Gradle bytes | Commit the wrapper and pin the checksum | Lane |
| SEC-06 | Low | Backup export is plaintext and has no size guard; the importer caps at 2 MiB, so the app can export a file it will later reject | `backup_service.dart:57-68`; `backup_codec.dart:225-227` | A large long-lived install can produce an unrestorable backup; plaintext at rest is documented | Assert export size before sharing; surface a warning; document retention | Lane |
| SEC-07 | Low | Debug and release share `applicationId`; no `applicationIdSuffix` | `android/app/build.gradle:47-61` | Testers cannot install debug beside the store build; easier to confuse artifacts | Add `.debug` suffix and update `tools/device_smoke.ps1` | Lane |

### 8.3 Controls verified at source

- **Secrets:** `git ls-files` + content regex across `lib/ android/ ios/ tools/ test/ .github/
  pubspec.yaml assets/` → 0 hits; `android/key.properties`, `android/local.properties`, `.env`,
  keystores, and PEMs were **never tracked on any ref**; all are gitignored.
- **Android surface:** only the launcher activity is exported without a signature permission;
  media browser/media button services are gated by `BIND_MEDIA_BROWSER_SERVICE` /
  `BIND_MEDIA_BUTTON`; notification receiver is `exported=false`; task affinity is empty.
- **Permissions:** no storage, contacts, camera, microphone, background location, `AD_ID`, or
  `QUERY_ALL_PACKAGES`; `SCHEDULE_EXACT_ALARM` only, with an inexact fallback;
  `FOREGROUND_SERVICE_MEDIA_PLAYBACK` + `mediaPlayback` type are correct.
- **Deep links:** exact scheme + host, `int.tryParse`, surah clamped 1..114, ayah clamped
  1..286 from the fragment only, no query parameter read. `flutter_deeplinking_enabled=false`
  prevents Flutter’s own handler from pushing raw URLs into the router.
- **Network:** exactly three HTTPS hosts; no `http://` literal; no `BadCertificateCallback` or
  custom trust override; timeouts on every path; audio has a 3-hop manual chain and a 64 MiB
  ceiling; packs are sha256-verified before promotion; no archive extraction.
- **SQL:** every user-derived value is a bound `?`/`Variable`, including the dynamic multi-token
  `LIKE` builder and the hadith import.
- **Release hardening:** `PUBLISH_RELEASE=true` without a keystore throws; the `publish` variant
  hard-fails in `afterEvaluate`; no fallback signing config.
- **Privacy:** no analytics/telemetry/crash SDK; location is one-shot, when-in-use, medium
  accuracy, and only the nearest city id is persisted — coordinates are not stored.

### 8.4 OWASP MASVS coverage

| Category | Result |
|---|---|
| MASVS-AUTH | **N/A** — no accounts, login, tokens, or server identity |
| MASVS-STORAGE | Reviewed; app-private DB/prefs, bounded/redacted backup; gaps SEC-03, SEC-06 |
| MASVS-CRYPTO | **N/A-ish** — only sha256 integrity verification, correctly applied |
| MASVS-NETWORK | Reviewed; HTTPS-only, 3 hosts; gap SEC-01 |
| MASVS-PLATFORM | Reviewed in depth; gap SEC-02, iOS parity |
| MASVS-CODE | Reviewed; no dynamic code, WebView, archive extraction, or object deserialization; parameterized SQL |
| MASVS-RESILIENCE | Partially N/A by design; no anti-tamper requirement for a free Quran app |
| MASVS-PRIVACY | Strong: no trackers, no accounts, no ads, on-device location only |

### 8.5 Scope limitations

No merged manifest, no APK/AAB, no live TLS probe, no CVE database, no dynamic analysis, no iOS
build. `POST_NOTIFICATIONS` is merged from the notifications plugin, not declared in this
repo’s manifest; a plugin change could silently drop it. The assetlinks fingerprint was not
validated against any built artifact.

---

## 9. Phases 5–6 — Data integrity, reliability, and error handling

### 9.1 Verdict

**5.5/10.** The happy path is well engineered — transactional backup merges, sha256 gates,
atomic `.part` promotion for audio, WAL, and background isolates. The failure paths are where
the app loses data: interrupted downloads, malformed backups, stale seed files, and a corrupt
database have no reconciliation.

### 9.2 High-severity findings

#### DAT-01 — Interrupted audio downloads are never reconciled

**Severity:** High · **Verification:** Direct + Lane

**Evidence:** `audio_downloader.dart:188-231` marks the row `downloading`, writes
`<surah>.mp3.part`, then promotes and marks `done`. `downloads_cubit.dart:39-46` hydrates only
`status == done` rows; nothing sweeps `downloading` rows or deletes `*.part`. `removeDownload`
is reachable only from a `done` row.

**Impact.** Kill the app at 40 %: the row stays `downloading` forever, the surah renders as
not downloaded, retry restarts from byte 0, and the orphan `.part` cannot be cleaned from the
UI. If the kill lands between promote and the `done` write, a complete file sits on disk while
the app streams from the network and the next attempt overwrites it.

**Remediation.** On startup, mark `downloading`/`queued` rows failed, delete orphan `.part`
files, and promote rows whose target file exists at the recorded size. Add resume or at least
per-surah retry, plus a global downloads surface.

#### DAT-02 — Pack installs have no retry/resume and a non-atomic promote/register order

**Severity:** High · **Verification:** Direct

**Evidence:** `pack_downloader.dart:144-147` promotes the `.part` file, then inserts the
`installed_packs` row, then imports hadith. The `on Object` handler at `:149-153` deletes the
**part** file — already renamed away — so a DB failure leaves a full pack file with no row.
The multi-request loop at `:217-259` has no per-request retry/backoff, and one 5xx discards
every already-fetched surah. Progress lives in `library_cubit.dart:57-75`, not in the
app-scoped downloader.

**Impact.** One flaky response destroys a 114-file install and burns the full quota on retry;
a failed registration leaves an invisible multi-MB ghost pack; leaving `/library` mid-install
resets the progress bar to 0 %.

**Remediation.** Retry each request 2–3 times with jittered backoff; persist per-surah
completion or write one temp file per surah; register and promote in one transaction; move
progress into `PackDownloader`; treat “row without file” as not installed.

#### DAT-03 — Backup restore silently drops malformed entries and writes unvalidated IDs

**Severity:** High · **Verification:** Direct

**Evidence:** `backup_codec.dart:153-160` counts `skippedEntries`; `backup_cubit.dart:91-99`
receives `BackupDecodeSuccess` but keeps only `result.document`; `BackupState.preview` has no
skipped field; `backup_section.dart:38-51,138-148` never shows it. `backup_merger.dart:28-38`
accepts any bookmark `ayahId` (last-read is clamped 1..6236), and `:72-86` accepts any
`targetPages`.

**Impact.** A slightly malformed backup (e.g. 300 bookmarks missing `createdAt`, 40 prayer days
with a non-string day) restores “successfully” with 340 entries missing. A crafted or
future-schema file can insert a bookmark whose ayah does not exist: the bookmarks screen uses
an inner join, so the row is invisible and permanently undeletable, and it is re-exported in
every future backup. An out-of-range khatma row wedges the wird card.

**Remediation.** Carry `skippedEntries` into the preview and success state; render a warning;
fail closed above a threshold (e.g. >5 % skipped); clamp bookmark ids and `targetPages`; add a
startup repair for orphan bookmark rows.

#### DAT-04 — No database corruption recovery; a stale seed temp can roll content back

**Severity:** High · **Verification:** Direct

**Evidence:** `connection.dart:140` (`writeAssetOffUiIsolate`) returns immediately when the
target exists. The content re-seed writes to a fixed `quran_yahdi.seed.tmp` (`:199-208`) and
deletes it in `finally`; a process kill inside that window leaves the stale file, and the next
content bump reuses it, seeds old rows, and stamps the new `content_version`. `connection.dart:
217-232` swallows seed/search-index failures and hands the executor to `LazyDatabase` anyway;
`AppDatabase.beforeOpen` then fails on every query.

**Impact.** (a) A damaged SQLite file bricks every screen on every launch with a generic error
and no reset path. (b) A killed content update can permanently revert corrected Quran text
while reporting success; only clearing app data fixes it.

**Remediation.** `PRAGMA quick_check` at open; on failure move the file aside and re-copy the
asset with a localized one-time notice. Delete any pre-existing seed path before writing (or
use a unique temp name) and validate 114 surahs / 6,236 ayahs before stamping the version.

### 9.3 Additional data/resilience findings

| ID | Sev | Finding | Evidence | Impact | Fix | Verification |
|---|---|---|---|---|---|---|
| DAT-05 | High | Tasbih hydration race: a tap before the stored snapshot loads persists `1` and discards the stored count | `tasbih_cubit.dart:36-72` | A long-running count (e.g. 500) is silently lost | Start in loading, gate `increment`, or merge taps after hydration | Direct |
| DAT-06 | Med | Khatma pointer uses an unguarded read-modify-write; two overlapping page changes can move progress backwards | `khatma_repository.dart:59-67`; `reader_cubit.dart:151-166` | “My progress reset” after a fast swipe | Conditional `UPDATE … WHERE ayah_id < ?`; treat 0 rows as no-op | Lane |
| DAT-07 | Med | Reciter catalog refresh deletes and reinserts all rows; downloads keep only a string `reciter_id`, with no FK or cleanup | `reciter_repository.dart:187-190,224-226`; `tables.dart:125-141` | A renumbered/dropped moshaf orphans downloaded audio and dead-ends the reciter screen | Tombstone removed rows or add a cleanup surface for orphaned downloads | Lane |
| DAT-08 | Med | Audio bytes are accepted on HTTP 200 alone; a captive-portal HTML page with no content-length can be promoted as a finished MP3 | `audio_downloader.dart:195-225` | A green “downloaded” row that fails to play forever; only delete can recover | Require a minimum plausible size and sniff `ID3`/MP3 frame bytes or reject `text/html` | Lane |
| DAT-09 | Med | Reminder settings write to the DB before the re-plan; a failed re-plan leaves the UI showing the old value while storage holds the new one | `settings_cubit.dart:96-105` | A switch snaps back, then shows on after re-entry; user cannot trust the state | Treat rescheduling as best-effort and emit the confirmed value, or roll back on failure | Lane |
| DAT-10 | Med | Permanently denied location opens the system location toggle, not the app permission page | `location_service.dart:31-37,42-49`; `city_picker_cubit.dart` | “Locate me” becomes a permanent dead end | Distinguish `deniedForever` and call `Geolocator.openAppSettings()` | Lane |
| DAT-11 | Med | Backup export has no size guard and deletes the temp file immediately after share resolves | `backup_service.dart:57-68`; `backup_cubit.dart:231-244` | The app can export a file its own importer rejects; a lazy consumer can read a deleted path | Measure against `kBackupMaxBytes`; defer deletion | Lane |
| DAT-12 | Low | `prayer_log.day` is a `dateTime` primary key; “one row per day” depends on every writer calling `dateOnly()` | `tables.dart:79-96` | A future writer can create a second row for the same day and silently reset the streak | Store `yyyy-mm-dd` TEXT or a generated date column with a unique index | Lane |
| DAT-13 | Low | Pack uninstall deletes the file first, then the row, then the hadith index | `pack_downloader.dart:456-474` | A failed row delete leaves “installed” with a missing file and an empty ayah sheet | Delete row/index first, file last; treat missing file as not installed | Lane |
| DAT-14 | Low | Reminder plan fingerprint is in-memory only; every pull-to-refresh on prayer times re-cancels and re-schedules platform alarms | `prayer_times_cubit.dart:142-151`; `notifications_binding.dart:312` | Platform-channel churn on a routine gesture | Persist the last applied plan or compare to the DB state | Lane |

### 9.4 Flows that can get stuck

1. **Prayer reminders** — after the scheduled prayer fires, no further alarm exists until a
   cold start (FUN-01).
2. **Audio download** — a killed run leaves a `downloading` row and an orphan `.part`; retry
   restarts from zero (DAT-01).
3. **Reciter surahs** — a reciter removed from the catalog lands on a generic failed screen
   with no retry; its downloaded audio is unreachable (DAT-07).
4. **Wird/khatma** — an out-of-range plan row shows the setup card and `finishWirdToday`
   silently no-ops (DAT-03).
5. **Library pack** — “installed” row + missing file renders an empty translation/hadith page
   with no error and no re-download prompt (DAT-02).
6. **First-run offline reciters** — `_kickOnce` latches after one failed refresh; the screen
   shows “no reciters” with no retry action (Lane).
7. **Qibla** — a heading stream `onDone` marks the compass unavailable and never rebinds until
   a pause/resume or screen re-entry (Lane).

---

## 10. Phase 7 — Performance and resource usage

### 10.1 Verdict

**Static performance is good, with localized hot spots.** Startup does no I/O before
`runApp`; the DB is lazy; the 4 MB asset copy and content re-seed run on a worker isolate;
plugins initialize behind the first frame under 1.5 s caps; the shipped DB already carries the
search index; the position stream is 1 Hz; lists are lazy; no image widgets or animation
controllers exist.

No runtime profiling was performed. The numbers below are file sizes, row counts, and
call-site counts, not measured frame times.

### 10.2 Quantified facts

| Fact | Value | How measured |
|---|---|---|
| Bundled DB | 4,173,824 B · 1,019 pages | file size + read-only `PRAGMA` |
| DB rows | 6,236 ayahs · 114 surahs · 6,236 search rows | read-only SQLite query |
| Shipped fonts | 4 files · 1,090,284 B | file enumeration |
| Shipped data JSON | 6 files · 72,761 B | file enumeration |
| Declared bundle payload | ≈ 5.34 MB | sum of DB + fonts + data + licenses |
| Unshipped build input | `assets/json/hafs_smart_v8.json` 7,760,927 B, 0 `lib/` references | `git ls-files` + grep |
| DDL per DB open | 11 statements + 2 PRAGMAs (5 creates, 2 dedupe scans, 2 drops, 2 index creates) | `app_database.dart:37-87` |
| Boot-window DB round trips | ~11 (7 settings/city reads + 3 home reads + 1 catalog stream) | call-site census |
| Prayer countdown ticker | 3,600 wakes/hour with ≤1 emission/minute | `prayer_times_screen.dart:87-93`; `prayer_times_cubit.dart:135` |
| Tasbih writes | 1 transaction + 1 full-body rebuild per tap | `tasbih_cubit.dart:60-73,93-100` |

### 10.3 Findings

| ID | Sev | Finding | Evidence | Impact | Fix | Verification |
|---|---|---|---|---|---|---|
| PERF-01 | Med | A cold ayah-sheet read decodes the entire installed pack file, not one surah; the cache is keyed `packId#surah`, so every surah change re-parses the whole file | `pack_reader.dart:47-49,65-66,230-245,302-326`; `ayah_sheet_cubit.dart:34-45` | Multi-second spinner and a large transient tree when switching surah; two packs are parsed serially | Build a per-surah index at install, store rows like `hadith_entries`, or cache the full pack within a byte budget | Lane |
| PERF-02 | Low-Med | ~11 serialized DB round trips in the boot window, 7 of them single-key settings reads | `main.dart:82-88`; `reminder_settings.dart:25-71`; `home_cubit.dart:70-75` | Extra latency behind the cold DB open before the home card paints | One `SELECT … WHERE key IN (…)` snapshot; join the home card | Lane |
| PERF-03 | Low-Med | Every tasbih tap writes one transaction and rebuilds the whole body; no debounce/coalescing | `tasbih_cubit.dart:60-73,93-100` | Flash write amplification and frame bursts on a rapid-tap surface | In-memory count + 1–2 s debounce + flush on pause; `BlocSelector` on the number | Lane |
| PERF-04 | Low | Reciter catalog refresh has no single-flight; first launch can fetch and rewrite the table twice | `reciter_repository.dart:129-191,202-207`; `main.dart:97-106`; `reciters_cubit.dart:69-73` | Duplicate HTTP + `DELETE`/`insertAll` at the coldest moment | Share the in-flight `Future` | Lane |
| PERF-05 | Low | Qibla subscribes to the magnetometer for the route’s lifetime; pushing the city picker keeps it streaming; no sampling period is set | `qibla_screen.dart:57-71,109`; `heading_service.dart:39-40` | Sensor/CPU drain while the compass is covered | RouteAware pause/resume + explicit `samplingPeriod` | Lane |
| PERF-06 | Low | Prayer countdown timer ticks every second for a minute-granularity label | `prayer_times_screen.dart:87-93`; `prayer_times_cubit.dart:135` | 59 wasted wake-ups per minute on a long-lived screen | One-shot timer to the next minute boundary | Lane |
| PERF-07 | Low | No font warm-up for the two Quran faces; first use decodes ~460 KB / ~300 KB and re-lays out text | `pubspec.yaml:76-89`; `grep FontLoader/precache` = 0 | Possible first-open text flash/relayout | Warm both families offstage behind the first frame | Lane |
| PERF-08 | Low | Bookmarks re-map page 1 + every loaded older page into fresh objects on each emission; `_older` is unbounded | `bookmarks_cubit.dart:117-133,150-192` | Churn proportional to how far the user paged | Cache `Verse` objects; align by id ranges | Lane |
| PERF-09 | Low | Mushaf page builds its entire `TextSpan` list inside `itemBuilder` on every page build | `reader_screen.dart:377-398` | Page-turn smoothness on low-end devices; shaping dominates, not spans | Memoize spans per `(page, locale, brightness)`; measure before optimizing | Lane |
| PERF-10 | Low | One tracker checkbox tap triggers six queries; `markedDaysRange` binds 400 dates | `tracker_cubit.dart:62-88,223-236`; `prayer_log_repository.dart:89-126` | Slower toggle feedback and wasted binding work | Flip the bool locally; use `day >= ?` on the PK | Lane |

### 10.4 Measurements still required

Cold-start and time-to-first-frame (DevTools timeline / `am start -W`), raster and UI times for
mushaf page turns and tasbih taps, memory before/after 10 reader surahs and 20 ayah-sheet
switches, `EXPLAIN QUERY PLAN` for the LIKE search and bookmark joins, APK/AAB size with and
without R8, and battery stats for the qibla sensor while covered.

---

## 11. Phase 8 — UX, accessibility, and localization

### 11.1 Verdict

**5.5/10.** The visual language is coherent and the dark theme is solid, but several
accessibility failures affect every user, and the Arabic localization is missing the plural
machinery the language requires. The app is Arabic-first and RTL; English ARB keys exist but
are unreachable because the locale is hard-coded to `ar` (known/deferred).

### 11.2 Contrast failures (computed, WCAG 2.2)

| Pair | Ratio | Verdict |
|---|---:|---|
| Body text on card (`#232D28` / `#FFFDF7`) | 13.97 | AAA |
| White on emerald primary button (`#FFFFFF` / `#3E6B58`) | 6.09 | AA / AAA-large |
| `goldText` on card (`#8A5A14` / `#FFFDF7`) | 5.81 | AA ✔ |
| **Raw gold as text on card** (zakat verdict, dua citation) | **2.12** | **FAIL** |
| **Raw gold as text on page** (tasbih “done”) | **1.78** | **FAIL** |
| **White `onSecondary` on gold** | **2.16** | **FAIL** (unused trap) |
| **SnackBar text on gold** | ≈**1.9** | **FAIL** |
| **Completed azkar card at `Opacity 0.45`** | **2.63** | **FAIL** |
| Dark body text (`#E8E2D2` / `#16201B`) | 12.92 | AAA |

### 11.3 Findings

| ID | Sev | Finding | Evidence | Impact | Fix | Verification |
|---|---|---|---|---|---|---|
| UX-01 | High | The shared failure arm is one centered `Text` with no retry; 19 `errorPane` call sites, 18 of which have no retry (the reader adds its own) | `loading_and_error_views.dart:14-22`; `error_pane.dart:8`; call sites include `home_screen.dart:87`, `surah_index_screen.dart:40`, `settings_screen.dart:31` | Any transient DB/asset failure dead-ends the route; Home is worst because it only reloads on resume/pop-back | Add optional `onRetry` to `ErrorView`/`errorPane` and wire each cubit’s reload | Direct |
| UX-02 | High | Raw gold is used as a foreground in three screens and as a SnackBar background in one; completed azkar cards drop to 45 % opacity | `app_theme.dart:34-37,66-67`; `tasbih_screen.dart:47`; `zakat_screen.dart:142-146`; `duas_screen.dart:212-216`; `reciter_surahs_screen.dart:89-94`; `azkar_screen.dart:292-295` | The tasbih “done”, zakat verdict, dua citation, and default-reciter toast are near-unreadable in light mode; finished azkar text effectively disappears | Use `AppTheme.goldText(context)` for text; use primary/onPrimary for the SnackBar; dim only the surface/check, not the body | Direct |
| UX-03 | High | Zero ICU plural entries in either ARB (0 of 216); Arabic needs zero/one/two/few/many/other | `app_ar.arb:89,143,186,361` (`{count} سورة`, `{count} ذكر`, `قبل {days} أيام`, `باقي نحو {days} يوم`) | “٢ ذكر”, “٣ سورة”, “٥ يوم”, “قبل ١١ أيام” — reads as machine-translated on the most visible counters | Convert to `{count, plural, zero{} one{} two{} few{} many{} other{}}` in AR and mirror in EN | Direct |
| UX-04 | Med-High | RTL chevrons are double-mirrored: the code selects `chevron_left` in RTL, but the icon already has `matchTextDirection: true` | `surah_index_screen.dart:105-109`; `hijri_screen.dart:82-110` | Every surah row shows a backward-pointing chevron; Hijri month buttons flip glyphs but keep LTR positions | Always use `chevron_right` and let `Directionality` mirror it; fix the Hijri nav order | Direct |
| UX-05 | Med-High | No `PopScope` anywhere; Azkar’s reciting sub-state and Asma’s detail overlay are not routes | `azkar_screen.dart:67-90`; `asma_screen.dart:53-61`; grep `PopScope` = 0 | System back/gesture exits the whole feature instead of closing the sheet/recitation | Add `PopScope` handling to both | Lane |
| UX-06 | Med | Bookmark delete is one tap, no confirm, no undo, no snackbar; the cubit call has no catch | `bookmarks_screen.dart:79-83`; `bookmarks_cubit.dart:56-58` | Users can lose a long-lived bookmark collection; a DB failure is unhandled | Confirm-or-undo (SnackBarAction) + typed catch | Lane |
| UX-07 | Med | Tasbih body is a non-scrolling `Column` with a fixed 220 dp dial; no bottom inset | `tasbih_screen.dart:29-51,83-87` | Overflows in landscape/split-screen; nav bar can cover the reset button | `SingleChildScrollView`/`LayoutBuilder` + scroll padding | Lane |
| UX-08 | Med | Hijri day cells: 9sp Gregorian line, “today” by background colour only, no `Semantics` | `hijri_screen.dart:123-135,139-173` | Low-vision, colour-blind, and screen-reader users cannot read the calendar | ≥11sp line, outline/dot for today, per-cell semantics label | Lane |
| UX-09 | Med | Only Cairo Regular (400) and Bold (700) ship, but the code requests w500/w600; no `textTheme`; 17 ad-hoc font sizes | `pubspec.yaml:85-88`; `app_theme.dart:71-101`; `reciters_screen.dart:158`; `library_screen.dart:198`; `hijri_screen.dart:160` | Hierarchy silently flattens; the UI reads as under-designed | Add SemiBold or map w500/w600→w700; define an M3 `textTheme`; delete per-widget sizes | Lane |
| UX-10 | Med | Reciter/hadith AppBar titles are two-line Columns inside a fixed 56 dp toolbar | `reciter_surahs_screen.dart:33-45`; `hadith_screen.dart:49-65` | Clipped/overflow at textScale 2.0 | Single-line title + move the subtitle to the body, or scale `toolbarHeight` | Lane |
| UX-11 | Low-Med | Reciters empty state is a raw centered Text instructing “download the catalog” while the only affordance is an app-bar refresh icon | `reciters_screen.dart:62-68`; `app_ar.arb:87` | First-run/offline users are told to do something not on screen | Use `EmptyState` with a refresh action | Lane |
| UX-12 | Low-Med | The star button’s tooltip/screen-reader label is “مختارات” (featured) but the action is “set as default”; the current default is never marked | `reciter_surahs_screen.dart:50-54` | TalkBack hears the wrong label; users cannot see which reciter is default | New ARB key, filled/outlined star, `Semantics(toggled:)` | Lane |
| UX-13 | Low | `formatHm` always emits 24-hour Arabic-Indic time and ignores `alwaysUse24HourFormat`; player clock shows `97:20` instead of `1:37:20`; dead zakat key uses Western digits | `arabic_numbers.dart:52-56`; `settings_screen.dart:175-190`; `player_sheet.dart:58-62`; `app_ar.arb:206-207` | Picker/list mismatch; wrong-looking durations; inconsistent digits | Honor the device 12/24-hour preference; use `h:mm:ss` when hours > 0; delete dead keys | Lane |
| UX-14 | Low | Home/Asma grids use fixed 3 columns with fixed aspect ratio | `home_screen.dart:185-191,270-276`; `asma_screen.dart:153-160` | Tablet tiles become huge; 2× labels ellipsize on 360 dp phones | `SliverGridDelegateWithMaxCrossAxisExtent`; allow 3 lines | Lane |
| UX-15 | Low | Tasbih dial and azkar counters have no live-region semantics | `tasbih_screen.dart:71-90`; `azkar_screen.dart:296-303,362-379` | Screen-reader users are not told when the count changes | `Semantics(button:true, label:, value:, liveRegion:true)` | Lane |

### 11.4 State coverage (main screens)

`L` loading · `E` empty · `F` error · `R` retry · `PR` pull-to-refresh

| Screen | L | E | F | R | PR |
|---|---|---|---|---|---|
| Home | ✔ | n/a | ✔ | ✘ | ✘ |
| Quran index | ✔ | ✔ | ✔ | ✘ | ✘ |
| Reader | ✔ | ✔ | ✔ | ✔ | ✘ |
| Quran search | ✔ | ✔ | ✔ | tail only | ✘ |
| Bookmarks | ✔ | ✔ | ✔ | tail only | ✘ |
| Reciters | ✔ | ✔ (no action) | ✔ | app-bar refresh | ✘ |
| Reciter surahs | ✔ | n/a | ✔ | per-row download | ✘ |
| Library | ✔ | n/a | ✔ | per-pack | ✘ |
| Hadith | ✔ | ✘ | ✔ | ✘ | ✘ |
| Prayer times | ✔ | ✔ | ✔ | ✘ | ✔ |
| City picker | ✔ | ✔ | ✔ | ✘ | ✘ |
| Qibla | ✔ | ✔ | ✔ | ✘ | ✘ |
| Azkar | ✔ | ✔ | ✔ | ✘ | ✘ |
| Duas | ✔ | ✔ | ✔ | ✘ | ✘ |
| Tracker | ✔ | n/a | ✔ | ✘ | ✘ |
| Zakat | — | — | — | — | — |
| Hijri | ✔ | n/a | ✔ | ✘ | ✘ |
| Asma | ✔ | ✔ | ✔ | ✘ | ✘ |
| Settings + backup | ✔ | n/a | ✔ | tile re-tap | ✘ |

### 11.5 Device-verification list

Tasbih landscape/split-screen overflow; Hijri grid at textScale 2.0; backup preview dialog at
≥1.5; player sheet at 2.0; surah chevron direction; TalkBack pass on tasbih, azkar, Hijri,
Asma; Home grid label truncation at 2× on a real 360 dp phone.

---

## 12. Phase 9 — Testing and QA

### 12.1 Inventory

- **253** files under `test/` = 250 test files + 3 support files (`fakes.dart`, `host.dart`,
  `test_db.dart`); **~825** static `test(`/`testWidgets(` call sites; **828** runtime cases in
  the executed suite.
- **42** Quran tests (reader, index, search, bookmarks), **33** recitation, **34** core/app,
  **21** prayer, **18** library, **11** backup, **10** each for notifications/qibla/*, **4**
  integration files (3 journeys + harness).
- Quality is high for a solo project: the suite uses real in-memory drift, the real notification
  plugin over a mock MethodChannel, real Dio adapters, real temp filesystems, and injected
  clocks. Only one production fake exists (`test/support/fakes.dart:15`).

### 12.2 Findings

| ID | Sev | Finding | Evidence | Risk | Fix | Verification |
|---|---|---|---|---|---|---|
| TST-01 | High | CI runs only `flutter test` (`test/`), never `integration_test/`; the only tests that boot DI + router + plugins are decorative | `ci.yml:26`; `integration_test/` 4 files; no workflow/script reference anywhere | A `main()`/router/plugin wiring regression ships green | Add an emulator job (`android-emulator-runner`) and a signed-release smoke | Direct |
| TST-02 | Med | Coverage is stale and ungated: `coverage/lcov.info` is dated 2026-10-24 (99 commits behind), 72.05 % (5,961/8,273), no `--coverage` in CI, no threshold | `coverage/lcov.info`; `ci.yml`; `.gitignore:47` | Nobody knows the current coverage; the bar cannot be enforced | Regenerate at HEAD, record it, add `--coverage` + a ratchet threshold | Direct |
| TST-03 | Med | Search-result tap → reader is untested; the screen test only asserts a row renders | `quran_search_screen.dart:174`; `quran_search_screen_test.dart:68` | A wrong surah/ayah parameter opens the wrong verse with a green suite | Router-backed tap test asserting the exact `surah`/`ayah` | Lane |
| TST-04 | Med | Deep-link and notification-tap wiring is untested; only the pure mapper functions are pinned | `main.dart:120-180`; `deep_link_routing_test.dart`; `notification_payload_routing_test.dart` | Deleting the listener leaves every link dead while tests pass | Seam the listener/tap handler and assert cold + warm navigation | Lane |
| TST-05 | Med | `player_sheet.dart` (196 lines, seek/stop/auto-close) has zero test references | `player_sheet.dart`; `grep` over `test/` and `integration_test/` | The newest user-facing surface can regress silently; double-pop risk | Widget-test seek once, stop pops once, duration 0 disables the slider | Lane |
| TST-06 | Low-Med | The only runtime remote catalog has no timeout/5xx/connection-error tests; pack/audio timeouts are similarly untested | `reciter_repository.dart:131`; `reciter_repository_test.dart`; `pack_downloader.dart:46-47`; `audio_downloader.dart:15-16` | Offline/timeout UX lands in the wrong state or hangs | Fake client throwing `TimeoutException`/`DioException`; assert localized failure and old catalog retained | Lane |
| TST-07 | Low-Med | Time-based tests use two `DateTime.now()` reads and real-clock streak fixtures | `prayer_log_repository_test.dart:18-19`; `tracker_cubit_test.dart:46,59,70` | Midnight/DST-boundary flake (“works at 10 am”) | Inject a fixed `DateTime(2026,3,15)` | Lane |
| TST-08 | Low | Some tests inflate coverage without validating production behavior: `page_contract_test` asserts a fake’s own constants; `smoke_test` asserts the widget it mounted; `router_test` checks 14 of 20 paths | `page_contract_test.dart:5,19-33`; `smoke_test.dart:37-42`; `router_test.dart:11-28` | False confidence; a missing route or an error-page boot passes | Delete/point at real sources; assert `HomeScreen` and all 20 routes | Lane |
| TST-09 | Low | CI runs codegen but never checks the tree is clean afterward; `integration_test/` is not in the format gate | `ci.yml:22-25`; contrast `web.yml:79-124` | Stale generated `.g.dart`/`.freezed.dart` compiles into a release while CI is green | `git diff --exit-code` after codegen; add `integration_test` to format | Lane |

### 12.3 Regression protection for the last remediation wave

All five fixes have real tests: `search_index_asset_stamp_test.dart` (6,236 rows + stamp),
`settings_failed_state_guard_test.dart` (zero writes/emissions), `optional_features_degrade_test.dart`,
`audio_redirect_guard_test.dart` (bad hop never requested, part cleanup), and
`backup_write_path_parity_test.dart` (identical table dumps). This is a genuine strength.

### 12.4 Critical journeys with no integration coverage

1. Search → tap result → land on the exact ayah.
2. Download → offline playback with the real audio plugin and notification.
3. Backup export → share → import → preview → confirm → restart.
4. Reminder schedule → fire → tap (warm and cold launch) → correct screen.
5. Deep link cold and warm.
6. Pack install through sha256/host gates → open tafsir/hadith.
7. First-run boot on a clean install, including the Android worker-isolate path.
8. Qibla with real sensors and permission denial.
9. Kill/restart mid-download and mid-import.
10. Mushaf paging → wird progress → tracker persistence.

---

## 13. Phase 10 — Build, release, and deployment

### 13.1 Verdict

**4.5/10.** The build configuration itself is sound: correct `applicationId`, targetSdk 36,
fail-closed signing, no store-restricted permissions, and a sensible minSdk. The **release
process** around it is not ready: the verified artifact is stale, the version code is frozen,
CI can publish a debug-signed bundle, licensing is open, and there is no crash-monitoring or
rollback plan.

### 13.2 Findings

#### REL-01 — The verified store artifact predates HEAD; versionCode is still 3

**Severity:** Blocker · **Verification:** Direct

**Evidence:** `pubspec.yaml:5` (`version: 1.0.0+3`); `docs/store/play-console-setup.md:15-25`
pins the verified AAB to `76da2d7`; `git log 76da2d7..HEAD -- lib assets android pubspec.yaml
pubspec.lock` = **20 commits**, including `7d3983c` (4 MB DB rewrite and search-index ship).

**Impact.** Uploading the recorded AAB ships a binary missing 20 commits. Rebuilding from HEAD
reuses versionCode 3, which Play rejects if 3 was ever uploaded, or forces a bump mid-window.
The 11 store screenshots were captured from the older `+3` build.

**Remediation.** Bump to `1.0.0+4`, rebuild with `PUBLISH_RELEASE=true`, record the new SHA-256
and `apksigner`/`jarsigner` output, re-shoot any screen whose UI changed, and update the
“Last verified” row.

#### REL-02 — CI release artifacts are debug-signed, ungated, and named like releases

**Severity:** Blocker · **Verification:** Direct

**Evidence:** `.github/workflows/ci.yml:31-52` — `release-artifact` has no
`needs: analyze-test`, sets no `PUBLISH_RELEASE`, and uploads `app-release-apk` /
`app-release-aab`. `android/app/build.gradle:90-94` only logs a warning under `CI=true`.

**Impact.** A red test suite still produces a publishable-looking bundle. The artifact is
debug-signed and will not match the App Links certificate. If it were ever uploaded without
Play App Signing, the debug key could become the permanent signing identity.

**Remediation.** Add `needs: [analyze-test]`; either inject a CI keystore with
`PUBLISH_RELEASE=true` or rename the artifacts `debug-signed-*` and stop uploading the AAB;
gate the job on the keystore’s presence.

#### REL-03 — Content licensing is not cleared

**Severity:** Blocker · **Verification:** Direct (docs)

**Evidence:** `docs/store/licensing-matrix.md` still marks the two Quran fonts
(rows 2), the Siraj tafsir text (row 4), and mp3quran listing terms (row 11) as
`FLAG → OPEN-FOR-OWNER`; `docs/store/play-console-setup.md:107-122` repeats the open items;
`assets/fonts/` contains only `Cairo-OFL.txt`.

**Impact.** A store launch on that basis carries takedown/IP risk that no code patch can fix.

**Remediation.** Obtain written redistribution terms for the fonts, confirm quranenc text
terms, and confirm mp3quran’s terms for listing; otherwise swap or withdraw the affected
assets before launch.

#### REL-04 (conditional) — Play App Signing will break App Links unless the Play certificate is added

**Severity:** Blocker if Play App Signing is enabled · **Verification:** Needs verification

**Evidence:** `web/public/.well-known/assetlinks.json` pins a single SHA-256 fingerprint
(redacted here) against `com.mostafasayed.quranyahdi`; the ledger identifies it as the local
owner keystore certificate and already notes the Play-signing caveat.

**Impact.** New apps use Play App Signing by default. Installed copies are signed with Google’s
app-signing certificate, so `autoVerify` fails and `https://quranyahdi.pages.dev/...` links open
in the browser instead of the app.

**Remediation.** After the first upload, copy the SHA-256 from Play Console → App integrity →
App signing key certificate into `assetlinks.json` alongside the upload cert, redeploy, and
verify the live file.

### 13.3 Additional release findings

| ID | Sev | Finding | Evidence | Release impact | Fix | Verification |
|---|---|---|---|---|---|---|
| REL-05 | High | No R8, resource shrinking, ProGuard rules, or Dart obfuscation/symbol archive | `android/app/build.gradle:74-110` (no `minifyEnabled`/`shrinkResources`/`proguardFiles` anywhere); `ci.yml:41-42` | 68.9 MB AAB; recoverable Dart symbols; unsymbolicated future crash traces | Enable R8 + `shrinkResources` + ProGuard keeps; add `--obfuscate --split-debug-info` and archive symbols per release | Direct |
| REL-06 | Med | No adaptive icon (`mipmap-anydpi-v26` absent), no monochrome icon, and the branded splash is lost on Android 12+ (`values-v31` omits `windowSplashScreenBackground`) | `res/` listing; `pubspec.yaml:39-43`; `values-v31/styles.xml` | Legacy-looking launcher icon and a white/black launch window on modern devices | Adaptive foreground/background + monochrome; set `windowSplashScreenBackground=#f1ead7` | Direct |
| REL-07 | Med | `compileSdk`/`minSdk`/`targetSdk` are inherited from the local Flutter install; no `.fvmrc` pins the SDK for local builds | `build.gradle:33,52-53`; no `.fvmrc` | A different Flutter on the owner machine silently changes the store artifact’s SDK levels | Pin explicit SDK levels and add `.fvmrc` | Lane |
| REL-08 | Med | No crash reporting, no staged-rollout plan, no rollback runbook; Play vitals are the only signal | `pubspec.yaml` (no Sentry/Firebase/Crashlytics); `play-console-setup.md:102-104` | A shipped regression is invisible until reviews/vitals; the only remedy is “halt rollout” | Add a privacy-compatible crash channel or a documented beta/vitals process; write the rollback policy | Direct |
| REL-09 | Med | The device smoke gate installs `app-debug.apk` and only asserts “process alive + no FATAL”; it never touches the signed store artifact | `tools/device_smoke.ps1:16`; `play-console-setup.md:102-104` | The store binary is never exercised before users get it | Smoke the release-signed APK from the internal track | Lane |
| REL-10 | Med | The release runbook uses bash env-assignment syntax on a PowerShell 5.1 machine, and `flutter build apk --split-per-abi` omits `--release` (builds debug) | `README.md:59-61`; `AGENTS.md:30` | Copy-paste failure; the “direct APK” line silently produces debug artifacts | `$env:PUBLISH_RELEASE="true"; flutter build appbundle --release`; add `--release` to the split line | Direct |
| REL-11 | Med | Gradle wrapper is gitignored (`gradle-wrapper.jar`, `gradlew`, `gradlew.bat`) and has no `distributionSha256Sum` | `android/.gitignore:1,4,5`; `gradle-wrapper.properties:5` | A clean clone cannot run the documented `./gradlew assemblePublish`; wrapper bytes are unverified | Commit the wrapper and pin the checksum, or document only `flutter build` | Lane |
| REL-12 | Low | `android:label` is hardcoded Arabic; no `values-en/strings.xml`, no `localeConfig` | `AndroidManifest.xml:11` | English-locale users get an Arabic launcher name; Android 13 per-app language has no entry | Move to `@string/app_name`, add `values-en` and `locales_config.xml` | Lane |
| REL-13 | Low | Debug and release share `applicationId`; no `versionNameSuffix` | `build.gradle:47-61` | Debug and store builds cannot coexist; testers must uninstall | Add `.debug` suffix and update the smoke script | Lane |
| REL-14 | Low | A 7.4 MB `assets/json/hafs_smart_v8.json` is tracked but not declared in `pubspec.yaml` and has no `lib/` reference | `tools/build_quran_db.dart:18`; `pubspec.yaml:70-74` | Repo bloat only; not shipped | Move under `tools/` or delete | Direct |
| REL-15 | Low | Very new toolchain (AGP 9.1, Gradle 9.3.1, Kotlin 2.3.20) with AGP-9 escape hatches enabled (`android.newDsl=false`, `builtInKotlin=false`) | `settings.gradle`; `gradle.properties:8,10-12` | Guaranteed AGP 10 breakage; migration debt | Schedule the AGP 10 migration; drop Jetifier | Lane |
| REL-16 | Low | No build flavors or environment split; all remote endpoints are compile-time constants | `reciter_repository.dart` (`recitersApiEndpoint`); `library_catalog.json`; no `flavorDimensions` in `build.gradle` | No staging path to validate a catalog/CDN change; every test uses production hosts | Add a `--dart-define` endpoint seam if remote content grows; otherwise document the single-environment decision | Direct |

### 13.4 Release-readiness checklist

| Item | Status | Evidence |
|---|---|---|
| `applicationId` matches store and assetlinks | **PASS** | `build.gradle:49`; `assetlinks.json` |
| targetSdk meets the 2026 Play floor (36) | **PASS** | inherited from Flutter 3.47.5 |
| minSdk / compileSdk sane | **PASS** | 24 / 36 |
| Release signing wired from a gitignored keystore | **PASS** | `build.gradle:63-72`; `android/.gitignore:11` |
| Store build fails closed without a key | **PASS** | `build.gradle:84-89,118-129` |
| No tracked secrets on any ref | **PASS** | `git ls-files` + regex |
| Verified artifact matches HEAD | **FAIL** | REL-01 (20 commits, DB changed) |
| versionCode monotonic and bumped | **FAIL** | `pubspec.yaml:5` still `+3` |
| Signing cert matches live App Links | **UNKNOWN** | REL-04 |
| Manifest permissions vs Play policy | **PASS** | no restricted permissions |
| Notification / FGS permissions | **PASS (with dependency)** | merged from plugin; not repo-declared |
| Cleartext blocked | **PASS** | targetSdk ≥28 default; all hosts HTTPS |
| App Links path scoping | **PASS** | `AndroidManifest.xml:42-49`; live assetlinks 200 |
| R8 / shrink / obfuscation | **FAIL** | REL-05 |
| 16 KB page-size compliance | **UNKNOWN** | needs build inspection |
| Wrapper reproducibility | **FAIL** | REL-11 |
| Generated-code reproducibility | **FAIL** | no `git diff --exit-code` after codegen |
| CI gates before artifacts | **FAIL** | REL-02 |
| CI Flutter version pinned | **PASS** | 3.47.5 |
| CI actions pinned | **FAIL** | mutable tags (known) |
| Tag / release automation | **FAIL** | none |
| Store listing assets present | **PASS** | 512 icon, 1024×500 feature, 11 screenshots 1080×2160 |
| Screenshots match the artifact | **FAIL** | REL-01 |
| Privacy policy live and accurate | **PARTIAL** | live 200; “only user-initiated downloads” is inaccurate (first-launch catalog refresh) |
| Data-safety answers vs code | **PASS** | no telemetry/accounts/ads; location on-device |
| Licensing cleared | **FAIL** | REL-03 |
| Crash monitoring / rollback | **FAIL** | REL-08 |

### 13.5 iOS

iOS is **not shipped** and is not part of the current Android release scope. It is nevertheless
not “almost ready”: there is no `Podfile`, no `DEVELOPMENT_TEAM`, no associated-domains
entitlement, no AASA file, no `PrivacyInfo.xcprivacy`, and no macOS CI job. The plist itself is
sane (ATS default, one location string, `UIBackgroundModes: audio`, deployment target 15.0).
Treat iOS as a separate project, not a follow-up commit.

---

## 14. Consolidated risk ranking (top 20)

| Rank | ID | Severity | Issue | Area |
|---:|---|---|---|---|
| 1 | FUN-01 | Blocker | Reminder engine is one-shot; prayer-only users never prompted | Functional |
| 2 | REL-01 | Blocker | Verified store artifact is 20 commits stale; versionCode frozen | Release |
| 3 | REL-02 | Blocker | CI debug-signed, ungated release artifacts | Release |
| 4 | REL-03 | Blocker | Font/tafsir/mp3quran licensing unresolved | Legal |
| 5 | REL-04 | Blocker (conditional) | Play App Signing will break App Links | Release |
| 6 | DAT-03 | High | Backup restores “successfully” with silently missing/undeletable data | Data |
| 7 | DAT-01 | High | Interrupted audio downloads never reconciled; no resume | Data |
| 8 | DAT-02 | High | Pack installs have no retry; ghost packs and lost progress | Data |
| 9 | DAT-04 | High | No DB corruption recovery; stale temp can revert content | Data |
| 10 | UX-01 | High | 18 screens have no retry; Home is a dead end | UX |
| 11 | FUN-02 | High | Continue-reading never advances in verse mode | Functional |
| 12 | UX-02 | High | Gold-as-text contrast 1.78–2.2:1; completed azkar 2.63:1 | Accessibility |
| 13 | UX-03 | High | Zero Arabic ICU plurals | Localization |
| 14 | FUN-03 | High | Qibla uses raw magnetometer; no tilt/accuracy | Functional |
| 15 | FUN-04 | High | Zakat validation/persistence gaps can mislead a financial-religious verdict | Functional |
| 16 | DAT-05 | High | Tasbih hydration race loses the stored count | Data |
| 17 | ARC-01 | High | Playback failure leaves old audio playing; mini player on 2 routes | Architecture |
| 18 | TST-01 | High | Integration tests are not run in CI | Testing |
| 19 | REL-05 | High | No R8/shrink/obfuscation/symbol archive | Release |
| 20 | REL-08 | Med-High | No crash monitoring, staged rollout, or rollback plan | Operations |

---

## 15. Remediation roadmap

### P0 — before any Play upload (blocking)

| # | Work | Files | Effort |
|---:|---|---|---|
| 1 | Fix reminder scheduling: per-prayer ids, daily repeat or re-plan on resume/boot, permission prompt for every toggle, denied-state UI | `reminder_planner.dart`, `notifications_binding.dart`, `settings_cubit.dart`, `main.dart`, manifest | M (2–3 d) |
| 2 | Bump `1.0.0+4`, rebuild signed AAB/APK, re-verify signature/version/size, re-shoot changed screens, update the runbook | `pubspec.yaml`, `docs/store/*` | S (1 d) |
| 3 | Gate and correct CI: `needs: analyze-test`, `PUBLISH_RELEASE` or renamed debug artifacts, keystore-gated upload, SHA-pin actions, `permissions: contents: read` | `ci.yml`, `build.gradle` | S (0.5 d) |
| 4 | Close licensing: written font terms, quranenc confirmation, mp3quran terms, or swap/withdraw | `docs/store/licensing-matrix.md`, assets | Owner/external |
| 5 | After first upload, add the Play app-signing certificate to `assetlinks.json` and verify live | `web/public/.well-known/assetlinks.json` | S (hours) |
| 6 | Run a signed-release device smoke: install, cold boot, reader, audio, notification, deep link, backup round-trip | device | S (1 d) |

### P1 — before public launch

1. **Error recovery:** add `onRetry` to `ErrorView`/`errorPane` and wire every failed state
   (UX-01).
2. **Reader continuity:** persist first visible ayah in verse mode (FUN-02).
3. **Download integrity:** startup reconciliation, delete orphan `.part`, retry/resume, global
   downloads screen (DAT-01, DAT-02, FUN-08).
4. **Backup integrity:** surface `skippedEntries`, fail-closed threshold, clamp ids
   (DAT-03).
5. **DB recovery:** `quick_check`, corrupt-file quarantine/re-copy, unique seed temp + row-count
   validation (DAT-04).
6. **Qibla accuracy:** fused orientation + calibration/accuracy UI (FUN-03).
7. **Accessibility/localization:** replace raw gold with `goldText`, fix azkar opacity, add
   Arabic plurals, fix RTL chevrons, add missing confirmations/semantics (UX-02..UX-15).
8. **App-wide mini player and playback failure stop** (ARC-01).
9. **CI integration smoke:** emulator job or at minimum a signed-release smoke on every
   release (TST-01).
10. **R8 + obfuscation + symbol archive** (REL-05).
11. **Crash/rollback plan and staged rollout** (REL-08).
12. **Zakat validation/persistence** (FUN-04).

### P2 — first post-launch update

- Pack reader per-surah index (PERF-01).
- Boot query snapshot (PERF-02), tasbih write debounce (PERF-03), reciter single-flight
  (PERF-04), qibla/prayer tickers (PERF-05/06), font warm-up (PERF-07).
- Reader juz/sajda/prev-next/font size/mode persistence (FUN-06).
- Hadith search/TOC (FUN-07).
- Tracker day navigation (FUN-05), pack update path (FUN-11).
- Adaptive icon/splash (REL-06), SDK pinning (REL-07), README/runbook corrections (REL-10).

### P3 — backlog / owner decisions

- iOS project (separate scope).
- English locale activation (currently unreachable by design).
- Monitoring/telemetry decision (privacy-first constraint).
- AGP 10 migration, Gradle wrapper commit, dead 7.4 MB JSON removal.

---

## 16. Manual verification checklist

These cannot be settled from the repository and must be checked before release:

1. **Play App Signing state and app-signing SHA-256** — decides REL-04.
2. **Highest uploaded `versionCode` on every track** — decides whether `+4` is sufficient.
3. **16 KB page-size compliance** — `zipalign -c -P 16 -v 4` on the release APK and the Play
   Console upload warning.
4. **Merged manifest** — effective `targetSdk`, `POST_NOTIFICATIONS`, plugin-contributed
   services, and export flags.
5. **Signed-release device smoke** — cold boot, 3 prayer notifications across a day boundary,
   azkar/wird recurrence, notification tap warm/cold, deep link warm/cold, download kill/restart,
   backup export→import→restart, qibla indoors.
6. **Runtime performance** — cold start, frame times for mushaf page turn and tasbih, memory
   after 10 surahs and 20 ayah-sheet switches, `EXPLAIN QUERY PLAN` for LIKE search.
7. **Dependency advisories** — `dart pub outdated` + OSV/GHSA; `just_audio_background` is the
   highest-churn pin (0.0.1-beta.17).
8. **Store policy** — closed-testing eligibility (12 testers × 14 days for new personal
   accounts), screenshot ratio acceptance, exact-alarm declaration.
9. **Licensing** — written font terms, quranenc terms, mp3quran terms.
10. **iOS** — only if iOS becomes in-scope: Podfile, team, AASA, privacy manifest, macOS CI.

---

## 17. Methods, files, and corrections

### 17.1 Files read directly by the orchestrator

`AGENTS.md`, `README.md`, `pubspec.yaml`, `.github/workflows/ci.yml`,
`android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle`,
`docs/store/play-console-setup.md`, `docs/store/licensing-matrix.md`,
`docs/superpowers/audits/2026-10-30-code-quality-audit.md`, `docs/campaign-ledger.md` (tail),
`lib/main.dart`, `lib/app/router.dart`, `lib/app/di/injector.dart`,
`lib/core/db/connection.dart`, `lib/core/widgets/loading_and_error_views.dart`,
`lib/features/quran/presentation/reader/reader_cubit.dart`,
`lib/features/quran/presentation/reader/reader_screen.dart` (targeted),
`lib/features/notifications/data/reminder_planner.dart`,
`lib/features/notifications/data/notifications_binding.dart` (targeted),
`lib/features/settings/presentation/settings_cubit.dart` (targeted),
`lib/features/recitation/presentation/playback/playback_cubit.dart` (targeted),
`lib/features/recitation/data/audio_downloader.dart` (targeted),
`lib/features/recitation/presentation/downloads/downloads_cubit.dart` (targeted),
`lib/features/library/data/pack_downloader.dart` (targeted),
`lib/features/backup/presentation/backup_cubit.dart` (targeted),
`lib/features/backup/data/backup_codec.dart` (grep), `lib/features/tasbih/presentation/tasbih_cubit.dart`,
`lib/features/qibla/data/heading_service.dart`,
`lib/features/quran/presentation/index/surah_index_screen.dart` (targeted),
`lib/core/theme/app_theme.dart` (targeted),
`lib/l10n/app_ar.arb` (key scan), `web/public/.well-known/assetlinks.json`.

### 17.2 Lane coverage

Each of the eight lanes read between 30 and 80 files and returned a "files read" list; those
lists are summarized in the lane sections above. The orchestrator did not re-open every
medium/low citation; those rows are marked **Lane** in the verification columns. Every P0 and
P1 row is marked **Direct** unless it explicitly depends on a device/store check.

### 17.3 Corrections made during integration

| Lane claim | Correction |
|---|---|
| "Packs are host-allowlisted at parse time" (inherited from the earlier audit) | At this HEAD only the **scheme** is checked (`library_catalog.dart:22`); the trust anchor is the sha256 pins, not a host allowlist. Downgraded to SEC-01. |
| "19 retry-less error panes" | There are **19** `errorPane` call sites; the reader adds its own retry, so **18** render the retry-less view. |
| "ErrorView has no retry anywhere" | True for the shared widget; the reader and pagination tails have their own retry affordances. |
| "No notification permission prompt for prayer" | Confirmed: the boot grace is gated on `azkarEnabled`; only the azkar/wird paths call `ensurePermissions`. |
| "A stale seed file is reused" | Confirmed at `connection.dart:140`: `writeAssetOffUiIsolate` returns when the target exists, and the fixed `quran_yahdi.seed.tmp` is that target. |
| "Store build is debug-signed" | Confirmed for **CI** by the workflow comment and the absence of `key.properties`; the local owner build is documented and was previously `jarsigner`-verified, but no artifact was inspected in this audit. |
| "iOS is broken" | It is **unbuilt and out of scope**, not a regression; the concrete gaps are listed in §13.5. |

### 17.4 Explicit non-claims

- This audit does **not** claim the app is secure because no high-severity issue was found. It
  claims only that no high/medium exploitable issue was found within the inspected source and
  configuration.
- This audit does **not** claim the 828 passing tests prove correctness. They prove the tested
  behavior at this commit.
- This audit does **not** claim the absence of a vulnerability in the backend, CDN, or store
  account. Those were out of scope.
- This audit does **not** recommend a rewrite. Every remediation above is targeted.

---

## 18. Security remediation — 2026-10-30

**Scope:** the security findings in §8 and the release-security items in §13. No
authentication, authorization, or API/backend findings apply: the app has no accounts,
sessions, roles, tokens, payments, or server-side user data. No hardcoded credentials were
found in tracked files; no secret value is reproduced in this report.

**Baseline:** `HEAD d39c1f7` plus this security pass. `flutter analyze` = **0 issues**;
`flutter test` = **841/841 passed**; format gate = **0 changed**.

### 18.1 Status summary

| Finding | Status | Change |
|---|---|---|
| SEC-01 | **Fixed** | Pack downloads now follow redirects manually, validate every hop against HTTPS + `cdn.jsdelivr.net` + default port, and fail closed after 3 hops |
| SEC-02 | **Fixed** | Removed `ACCESS_FINE_LOCATION`; kept coarse-only; added explicit `android:usesCleartextTraffic="false"` |
| SEC-03 | **Fixed** | Added `<exclude domain="file" path="."/>` to both cloud-backup and device-transfer rules |
| SEC-04 | **Fixed** | Added top-level `permissions: contents: read`; pinned all three actions to full commit SHAs |
| SEC-05 | **Partially Fixed** | Added verified `distributionSha256Sum`; unignored the wrapper. The wrapper files are present but still untracked until the owner commits them |
| SEC-06 | **Partially Fixed** | Export now refuses a payload over `kBackupMaxBytes` before sharing; the post-share temp-file deletion and plaintext-at-rest decision remain |
| REL-02 | **Partially Fixed** | Release job now `needs: [analyze-test]`; artifacts renamed `debug-signed-*`. CI is still debug-signed because no keystore is available there |
| REL-04 | **Needs Verification** | App Links still pin only the upload certificate; the Play app-signing SHA-256 requires Play Console access |
| REL-05 | **Unresolved** | R8/shrink/obfuscation not enabled; needs plugin keep rules and a signed-device smoke. Not a confirmed vulnerability; deferred |
| SEC-07 | **Unresolved** | Debug and release still share `applicationId`; adding `.debug` requires updating the device smoke script; deferred |
| Authentication / authorization / API | **N/A** | No accounts, tokens, roles, backend, or payments exist in this app |
| Hardcoded secrets / secrets in logs | **No finding** | No tracked credentials found; no secret value was printed or changed; no rotation or revocation is required |

### 18.2 Detail and evidence

#### SEC-01 — Pack redirect validation

- **Files:** `lib/features/library/data/pack_redirect_guard.dart` (new),
  `lib/features/library/data/pack_downloader.dart`.
- **Change:** `_fetchTrustedPack` sets `followRedirects: false`, accepts 3xx only long enough
  to read `Location`, drains the redirect body, and resolves each hop through
  `resolveTrustedPackRedirect`. The guard requires `https`, the `cdn.jsdelivr.net` host, and
  the default port; it rejects `http`, foreign hosts, lookalike hosts, non-443 ports, and
  chains longer than 3 hops. The downloader wraps a guard failure in `PackFailure`, so the
  partial file is cleaned and no installed row is written.
- **Rationale:** the previous code let Dio follow up to five redirects without re-checking the
  destination. The catalog pins the initial URL, but not a redirect. This restores the same
  trust boundary on every hop.
- **Tests:** `test/pack_redirect_guard_test.dart` — 7 cases: trusted HTTPS, http/foreign/
  lookalike/non-443 rejection, relative + absolute trusted resolution, foreign absolute
  rejection, downloader foreign redirect (asserts the foreign URI is never requested), http
  redirect, and the 3-hop cap. `followRedirects` is asserted `false` at the adapter.
- **Result:** all 7 pass. Existing pack tests (18), integrity tests, single-flight, and index
  prime tests remain green.
- **Remaining risk:** the **initial** catalog URL is still governed only by the bundled
  catalog's HTTPS check, not by a host allowlist. The catalog is bundled and pinned; a future
  remote catalog must add its host to `kTrustedPackHosts`. No live CDN redirect was probed.

#### SEC-02 — Least-privilege location and cleartext

- **Files:** `android/app/src/main/AndroidManifest.xml`.
- **Change:** removed `ACCESS_FINE_LOCATION`; kept `ACCESS_COARSE_LOCATION`; added
  `android:usesCleartextTraffic="false"` explicitly.
- **Rationale:** the only consumer requests `LocationAccuracy.medium`, which does not need
  fine location. The explicit cleartext flag removes reliance on the targetSdk default.
- **Tests:** `test/security_platform_config_test.dart` asserts coarse present, fine absent,
  and cleartext false. A debug APK was built and the **merged** manifest was inspected:
  `ACCESS_FINE_LOCATION` is absent, `ACCESS_COARSE_LOCATION` is present,
  `POST_NOTIFICATIONS` is merged from the notification plugin, `usesCleartextTraffic="false"`,
  `allowBackup="false"`, and `dataExtractionRules="@xml/data_extraction_rules"`.
- **Result:** pass (`flutter build apk --debug` exit 0, 59.6 s).
- **Remaining risk:** the coarse-only permission flow has not been exercised on a device. If a
  future feature needs precise location, it must add the permission and a Play Data-safety
  justification deliberately.

#### SEC-03 — Device-to-device data extraction

- **Files:** `android/app/src/main/res/xml/data_extraction_rules.xml`.
- **Change:** added `<exclude domain="file" path="."/>` to both `cloud-backup` and
  `device-transfer`.
- **Rationale:** the drift DB and downloaded packs live in `getApplicationSupportDirectory()`,
  which is the Android `file` domain, not `database`. Excluding only `database`/`sharedpref`
  left the user DB in D2D transfer.
- **Tests:** `test/security_platform_config_test.dart` asserts exactly two `domain="file"`
  excludes; XML parses.
- **Remaining risk:** D2D behavior was not exercised on a device; `allowBackup="false"` and the
  rules now agree on intent.

#### SEC-04 — CI least privilege and action pinning

- **Files:** `.github/workflows/ci.yml`.
- **Change:** added `permissions: contents: read`; replaced `@v4`/`@v2` tags with full commit
  SHAs for `actions/checkout`, `subosito/flutter-action`, and `actions/upload-artifact`.
- **Rationale:** mutable tags can be moved; least-privilege limits a compromised workflow step.
- **Tests:** `test/security_platform_config_test.dart` asserts permissions, no mutable tags,
  and 40-hex SHAs; the file parses as YAML.
- **Remaining risk:** Dependabot or the owner must keep the SHAs current; a stale pin is a
  maintenance cost, not a vulnerability. The first GitHub Actions run after this change should
  be watched: if `upload-artifact` requires `actions: write` under the new top-level
  permissions block, add that permission explicitly rather than removing the block.

#### SEC-05 — Gradle wrapper pinning

- **Files:** `android/gradle/wrapper/gradle-wrapper.properties`, `android/.gitignore`.
- **Change:** added `distributionSha256Sum=17f277867f6914d61b1aa02efab1ba7bb439ad652ca485cd8ca6842fccec6e43`
  (verified against `services.gradle.org` and the local distribution zip); removed
  `gradle-wrapper.jar`, `/gradlew`, and `/gradlew.bat` from `.gitignore`.
- **Rationale:** a clean clone must be able to run the wrapper and verify the downloaded
  distribution bytes.
- **Tests:** `test/security_platform_config_test.dart` asserts the checksum and the unignored
  paths.
- **Remaining risk / required action:** `android/gradle/wrapper/gradle-wrapper.jar`,
  `android/gradlew`, and `android/gradlew.bat` are present in the working tree but **untracked**.
  The owner must include them in the next commit (explicit pathspecs) for a clean clone to be
  reproducible. No file was staged or committed in this pass.

#### SEC-06 — Backup export size guard

- **Files:** `lib/features/backup/presentation/backup_cubit.dart`.
- **Change:** after `BackupService.exportJson()`, the cubit measures
  `utf8.encode(json).length`; if it exceeds `kBackupMaxBytes` it throws `_BackupTooLarge`
  before `_shareJson`. The existing catch emits `BackupFailed(duringExport: true)`.
- **Rationale:** the importer rejects files over 2 MiB; exporting a larger file produced an
  unrestorable backup. The app must not emit a file its own importer rejects.
- **Tests:** `test/backup_export_size_guard_test.dart` — oversized export shares nothing and
  emits export failure; a within-cap export still shares and reaches `BackupExported`.
  Existing backup section/service/parity tests remain green.
- **Remaining risk:** the export temp file is still deleted in `finally` immediately after
  `SharePlus.share` resolves (`ARC-06`/`DAT-11`). That can make a lazily-read share target see
  a missing file. Plaintext-at-rest remains the documented owner decision.

#### REL-02 — CI release artifact gating and naming

- **Files:** `.github/workflows/ci.yml`.
- **Change:** `release-artifact` now `needs: [analyze-test]`; artifact names changed from
  `app-release-apk`/`app-release-aab` to `debug-signed-apk`/`debug-signed-aab`; the job comment
  states that store artifacts are built locally with `PUBLISH_RELEASE=true`.
- **Rationale:** a red test suite can no longer produce an artifact; the artifact name no
  longer implies a store-ready binary.
- **Tests:** `test/security_platform_config_test.dart` asserts the gate and names; YAML parses.
- **Remaining risk:** CI still builds with the debug key. A store-bound AAB must be built on the
  owner machine with the owner keystore; injecting a CI keystore is an owner decision.

#### REL-04 — App Links under Play App Signing

- **Status:** **Needs Verification**.
- **Why:** `web/public/.well-known/assetlinks.json` still pins one SHA-256 fingerprint. The
  Play App Signing certificate is not available in the workspace.
- **Required external action:** after the first Play upload, copy the app-signing SHA-256 from
  Play Console → App integrity → App signing key certificate into `assetlinks.json`, redeploy,
  and verify `adb shell pm get-app-links` plus a cold `https://quranyahdi.pages.dev/...` link.
- **Do not mark fixed until that evidence exists.**

#### REL-05 — R8 / obfuscation

- **Status:** **Unresolved** (deferred).
- **Why:** enabling R8/resource shrinking and `--obfuscate --split-debug-info` changes the
  release binary and can break reflection-based plugins (audio service, notifications,
  file picker). It needs plugin keep rules and a signed-device smoke, which are outside this
  security pass. It is a release-hardening item, not a confirmed exploitable vulnerability.

#### SEC-07 — Debug/release application identity

- **Status:** **Unresolved** (deferred).
- **Why:** adding `applicationIdSuffix ".debug"` changes the package id used by
  `tools/device_smoke.ps1` and the install/launch checks. It should land in the same change as
  the smoke-script update, in the release phase.

### 18.3 Tests executed

| Command | Result |
|---|---|
| `flutter test test/pack_redirect_guard_test.dart test/backup_export_size_guard_test.dart test/security_platform_config_test.dart` | **13/13 passed**, exit 0 |
| `flutter test test/pack_downloader_test.dart test/pack_integrity_test.dart test/pack_install_single_flight_test.dart test/pack_install_index_prime_test.dart test/backup_section_test.dart test/backup_service_test.dart test/backup_write_path_parity_test.dart test/audio_redirect_guard_test.dart` | **57/57 passed**, exit 0 |
| `flutter test` (full suite) | **841/841 passed**, exit 0 (baseline 828 + 13 new) |
| `flutter analyze` | **0 issues** |
| `dart format --output=none --set-exit-if-changed lib test tools` | **471 files, 0 changed** |
| `flutter build apk --debug` | **exit 0**, `app-debug.apk` built in 59.6 s |
| Merged debug manifest inspection | **FINE absent, COARSE present, cleartext false, allowBackup false, dataExtractionRules present** |
| AndroidManifest + data-extraction XML parse | **OK** |
| `ci.yml` YAML parse (PyYAML) | **OK** |

### 18.4 Remaining release blockers after this security pass

This pass closes the low-severity platform/network findings and reduces the CI/release-artifact
risk, but it does **not** make the app production-ready. The following blockers remain from
the main report:

- **REL-01** — the verified AAB is stale and `versionCode` is still 3.
- **REL-03** — font/tafsir/mp3quran licensing is not cleared.
- **REL-04** — Play App Signing certificate not in `assetlinks.json`.
- **REL-02 / SEC-05 / SEC-06 / SEC-07** — CI is still debug-signed; wrapper files are untracked;
  backup temp-file lifetime and debug identity remain.
- **FUN-01** — reminders are still one-shot and prayer-only users are not prompted.
- **DAT-01/02/03/04** — download, pack, backup, and DB recovery paths still carry the data-loss
  findings from the main report.
- **REL-05** — R8/obfuscation remains deferred.

No claim is made that the application is fully secure. The findings that were not changed are
listed above with their original IDs so they cannot be mistaken for closed items.

---

## 19. Functional remediation — 2026-10-30

**Scope:** verified functional defects from §6 and Phase 1 of `PRODUCTION_REMEDIATION_PLAN.md`.
The app has no authentication, authorization, or backend workflow in scope. No existing test
was edited; one fix was reverted because an existing test pins the old behavior.

### 19.1 Status summary

| Finding | Status | Change |
|---|---|---|
| DAT-06 | **Fixed** | Khatma pointer now uses one conditional `UPDATE … WHERE ayah_id < ?`; concurrent page changes cannot move it backwards |
| FUN-02 | **Fixed** | The verse list reports its first visible ayah; `ReaderCubit` persists it through the existing last-read path (deduped per verse) |
| FUN-10 | **Fixed** | `HomeCubit` schedules a one-shot refresh when the shown prayer time passes and cancels it on close/reload |
| DAT-09 | **Fixed** | Settings write, emit the confirmed value, then re-plan best-effort; a failed permission probe is reported as denied without hiding the committed setting |
| ARC-01 | **Fixed** | Every playback failure path (reciter lookup, no reciter, load failure) stops the service before emitting `failed` |
| FUN-04 | **Partially Fixed** | Invalid zakat input is rejected with a field error and a "fix the fields" verdict; input persistence across visits is still not implemented |
| DAT-05 | **Unresolved** | Blocked by the frozen test `test/tasbih_hydration_race_test.dart`, which explicitly pins the old "early tap discards the stored count" behavior. The prototype fix was reverted; an owner ruling is required before changing that test |

### 19.2 Detail and evidence

#### DAT-06 — Khatma concurrent pointer regression

- **Files:** `lib/features/tracker/data/khatma_repository.dart`.
- **Change:** `advanceTo` keeps the single-row lookup, then writes with
  `WHERE id = ? AND ayah_id < ?`. The database, not the stale in-memory read, decides whether
  the pointer moves.
- **Rationale:** two overlapping page changes could both read the same old pointer and the
  slower writer could persist a smaller ayah id.
- **Tests:** `test/khatma_concurrent_advance_test.dart` — 20 interleaved forward/backward
  `advanceTo` calls; the pointer lands on the maximum (119), never the backward value.
- **Result:** pass. Existing `test/khatma_repository_test.dart` remains green.

#### FUN-02 — Continue-reading in verse mode

- **Files:** `lib/features/quran/presentation/reader/reader_cubit.dart`,
  `lib/features/quran/presentation/reader/reader_screen.dart`.
- **Change:** the verse list now owns an `ItemPositionsListener`; it reports the first visible
  index to `ReaderCubit.onVisibleAyah`. The cubit drops duplicate/zero ids and persists through
  the existing `_saveLastRead` path. The initial load seeds `_lastVisibleAyahId` so the first
  layout does not re-save the same verse.
- **Rationale:** last-read was only written on load and on mushaf page change, so the Home
  continue-reading card never advanced in the default verse mode.
- **Tests:** `test/reader_visible_ayah_test.dart` — scrolling from ayah 1 to 2 to 3 records
  `[1, 2, 3]`; a duplicate 2 and an invalid 0 add no writes.
- **Result:** pass. Existing reader cubit/screen/wird/write-safety tests remain green.
- **Limitation:** the widget-level scroll gesture is not re-tested here; the listener wiring is
  covered by the existing reader screen tests compiling and passing, and the cubit behavior is
  unit-tested.

#### FUN-10 — Home next-prayer refresh

- **Files:** `lib/features/home/presentation/home_cubit.dart`.
- **Change:** after a ready state with a future prayer, a one-shot `Timer` fires one second
  after the prayer time and calls `reload()`. `reload()` and `close()` cancel the pending timer.
- **Rationale:** the card computed "next" once and never ticked, so a Home screen left open kept
  advertising a passed prayer.
- **Tests:** `test/home_prayer_refresh_test.dart` — a prayer 30 seconds ahead causes a second
  `nextPrayer` call after 31 seconds; the cubit is closed before the test ends so no timer leaks.
- **Result:** pass. Existing home cubit/screen/continue-reading tests remain green.
- **Limitation:** background/resume behavior still relies on the existing lifecycle reload;
  the new timer handles the foreground case.

#### DAT-09 — Settings UI/persisted divergence

- **Files:** `lib/features/settings/presentation/settings_cubit.dart`.
- **Change:** every mutator now writes first, emits the confirmed value, then calls
  `_rescheduleBestEffort()`. A failed notification-permission probe is caught and reported as
  denied; it no longer prevents the committed setting from appearing. A failed write still
  keeps the last confirmed state.
- **Rationale:** the old order wrote the DB, then re-planned, then emitted. A re-plan failure
  left storage changed and the switch showing the old value.
- **Tests:** `test/settings_reschedule_failure_test.dart` — a scheduler that always throws on
  `scheduleAll`; enabling azkar and changing the time still show the committed value and persist
  it. Existing write-failure/serialization tests remain green.
- **Result:** pass.
- **Limitation:** the actual platform schedule may be stale until the next boot/settings load;
  this is the documented best-effort reminder behavior, not a fake success.

#### ARC-01 — Playback failure leaves audio playing

- **Files:** `lib/features/recitation/presentation/playback/playback_cubit.dart`.
- **Change:** `_stopBestEffort()` is called before emitting `PlaybackState.failed` on the
  default-reciter lookup error, the empty-catalog branch, and the load failure branch. The
  episode check is re-run after the stop so a superseded attempt cannot resurrect a failure.
- **Rationale:** the failure strip could sit above a track that was still audible.
- **Tests:** `test/playback_failure_stop_test.dart` — a throwing reciter lookup and a failing
  `loadAndPlay` both leave a `PlaybackFailed` state and exactly one stop call.
- **Result:** pass. Existing playback/race/start-contract tests remain green.

#### FUN-04 — Zakat invalid input (partial)

- **Files:** `lib/features/zakat/data/zakat_calculator.dart`,
  `lib/features/zakat/presentation/zakat_screen.dart`, `lib/l10n/app_ar.arb`,
  `lib/l10n/app_en.arb`, generated l10n files.
- **Change:** added `parseDecimalOrNull`; `parseDecimal` now delegates to it. The screen marks
  any non-empty field whose text is not a finite non-negative number with
  `zakatInvalidNumber`, and replaces the verdict with `zakatFixInputs` while any field is
  invalid. Arabic-Indic digits and separators still parse.
- **Rationale:** `parseDecimal` collapsed malformed text to 0, which could silently produce a
  "no zakat" verdict.
- **Tests:** `test/zakat_invalid_input_test.dart` — `abc`, `12.5.6`, `-4` return null;
  `١٢٫٥` returns 12.5; the widget shows the field error and warning for `abc`, and both clear
  when the field becomes `10`. Existing zakat math/screen/quality tests remain green.
- **Result:** pass.
- **Remaining:** the input snapshot is still not persisted across route visits. This is the
  second half of FUN-04 and remains open.

#### DAT-05 — Tasbih hydration race (blocked)

- **Status:** **Unresolved** — no code change retained.
- **Why:** `test/tasbih_hydration_race_test.dart` explicitly pins the current behavior: an
  early tap produces count 1 and the stored snapshot (41) must not overwrite it. The requested
  fix produces 42 (stored count + tap), which contradicts that pin. The prototype code change
  and the temporary test rewrite were reverted; `git status` shows no tasbih source or test
  change.
- **Required action:** an owner ruling on the intended behavior and permission to update that
  frozen test. Until then, a fast tap before hydration can still overwrite the stored count.

### 19.3 Tests executed

| Command | Result |
|---|---|
| `flutter test test/tasbih_hydration_race_test.dart test/tasbih_cubit_test.dart test/khatma_concurrent_advance_test.dart test/reader_visible_ayah_test.dart test/home_prayer_refresh_test.dart test/settings_reschedule_failure_test.dart test/playback_failure_stop_test.dart test/zakat_invalid_input_test.dart` | **15/15 passed**, exit 0 |
| `flutter test` (full suite) | **850/850 passed**, exit 0 (final run after the reader first-position guard) |
| `flutter analyze` | **0 issues** |
| `dart format --output=none --set-exit-if-changed lib test tools` | **477 files, 0 changed** |
| `flutter gen-l10n` | completed; generated AR/EN l10n updated |

**Frozen-test note:** no existing test file remains modified. The temporary rewrite of
`test/tasbih_hydration_race_test.dart` was restored byte-for-byte from `HEAD`; the new
functional tests are separate files.

### 19.4 Modified files

- `lib/features/tracker/data/khatma_repository.dart`
- `lib/features/quran/presentation/reader/reader_cubit.dart`
- `lib/features/quran/presentation/reader/reader_screen.dart`
- `lib/features/home/presentation/home_cubit.dart`
- `lib/features/settings/presentation/settings_cubit.dart`
- `lib/features/recitation/presentation/playback/playback_cubit.dart`
- `lib/features/zakat/data/zakat_calculator.dart`
- `lib/features/zakat/presentation/zakat_screen.dart`
- `lib/l10n/app_ar.arb`, `lib/l10n/app_en.arb`, generated `lib/l10n/app_localizations*.dart`
- New tests: `test/khatma_concurrent_advance_test.dart`,
  `test/reader_visible_ayah_test.dart`, `test/home_prayer_refresh_test.dart`,
  `test/settings_reschedule_failure_test.dart`, `test/playback_failure_stop_test.dart`,
  `test/zakat_invalid_input_test.dart`
- `PRODUCTION_READINESS_REPORT.md` (this section)

### 19.5 Remaining functional defects

- **DAT-05** — blocked on the frozen-test ruling (above).
- **FUN-04** — zakat input persistence across visits.
- **DAT-01 / DAT-02 / DAT-03 / DAT-04** — download reconciliation, pack atomicity/retry,
  backup skipped-entry reporting, and DB corruption/seed recovery remain from §9.
- **FUN-01** — reminder recurrence/permission remains the main release blocker.
- **FUN-03** — qibla tilt/accuracy remains.
- **FUN-05 / FUN-06 / FUN-07 / FUN-08 / FUN-09 / FUN-11 / FUN-12 / FUN-13** — tracker
  backfill, reader feature gaps, hadith search/TOC, downloads surface, backup whitelist,
  pack updates, azkar persistence, tasbih dhikr text.
- **UX-01** — the shared `ErrorView` still has no retry across most screens.

### 19.6 Known limitations

- No device/emulator run was performed for these functional changes; the new tests use widget
  and in-memory DB harnesses. A signed-device smoke is still required for Home timing,
  reader scrolling, settings/notification rescheduling, playback stop, and zakat input.
- The full suite count is **850/850**; the report does not claim a precise delta from the
  earlier 841 because the test inventory changed while the frozen tasbih test was restored.
- No backend/authentication workflow exists, so no auth-dependent navigation or authorization
  path was changed.

---

## 20. Performance, usability, and accessibility remediation — 2026-10-30

**Scope:** verified UX/accessibility/performance findings from §11 and §10. No production
device or profiler was available; numerical performance improvements are not claimed. The
changes below are structural or verified by widget/unit tests.

### 20.1 Status summary

| Finding | Status | Change |
|---|---|---|
| UX-02 | **Fixed** | Raw gold foregrounds replaced with `AppTheme.goldText`; SnackBar uses primary/onPrimary; completed azkar opacity 0.45 → 0.8; `onSecondary` ink |
| UX-07 | **Fixed** | Tasbih body is scrollable with the app's bottom-inset padding; landscape no longer overflows |
| UX-08 | **Fixed** | Hijri Gregorian line 9sp → 11sp; today gets an outline as well as a fill; each cell has a dual-calendar semantics label |
| UX-11 | **Fixed** | Reciters empty state uses `EmptyState` with a visible refresh action when the catalog is empty |
| UX-12 | **Partially Fixed** | Star tooltip now says "set as default"; the current default is still not visually marked |
| UX-14 | **Fixed** | Home and Asma grids use max-cross-axis-extent delegates instead of fixed 3 columns |
| UX-15 | **Partially Fixed** | Tasbih dial has a button/live-region semantics label and value; azkar counters still lack a live-region label |
| PERF-04 | **Fixed** | Reciter catalog refresh is single-flight: concurrent boot warm-up + screen refresh share one HTTP request and one table rewrite |
| UX-04 | **Unresolved** | RTL chevron fix blocked by `quran_core_quality_probe_test.dart`, which pins the current icon choice |
| PERF-06 | **Unresolved** | Prayer ticker fix blocked by `prayer_times_ticker_test.dart`, which pumps 1 second and expects an immediate countdown update |
| UX-09 / UX-10 / UX-13 | **Unresolved** | Typography tokens, two-line app-bar scaling, and 12/24-hour formatting remain |
| PERF-01/02/03/05/07/08/09/10 | **Unresolved** | Pack index, boot-query snapshot, tasbih write debounce, qibla sensor lifecycle, font warm-up, bookmark remap, mushaf span cache, tracker query count remain |

### 20.2 Detail and evidence

#### UX-02 — Contrast on accent text and toasts

- **Files:** `lib/core/theme/app_theme.dart`,
  `lib/features/tasbih/presentation/tasbih_screen.dart`,
  `lib/features/zakat/presentation/zakat_screen.dart`,
  `lib/features/duas/presentation/duas_screen.dart`,
  `lib/features/azkar/presentation/azkar_screen.dart`,
  `lib/features/recitation/presentation/reciter_surahs/reciter_surahs_screen.dart`.
- **Change:** all foreground uses of `colors.secondary` now use
  `AppTheme.goldText(context)` (5.81:1 on the card, 4.88:1 on the page); the
  default-reciter SnackBar uses `primary`/`onPrimary` (6.09:1); completed azkar cards use
  opacity 0.8 instead of 0.45; `ColorScheme.onSecondary` is ink instead of white.
- **Rationale:** the raw gold token is a light accent; as text it measured 1.78–2.12:1.
  The WCAG token test already pinned the correct `goldText` tone.
- **Tests:** `test/contrast_call_sites_test.dart` checks the zakat verdict and tasbih done copy
  resolve to `AppColors.goldText`; existing `test/wcag_contrast_test.dart` and
  `theme_test.dart` remain green.
- **Result:** pass. The actual rendered contrast is token-computed, not device-measured.

#### UX-07 — Tasbih landscape overflow

- **Files:** `lib/features/tasbih/presentation/tasbih_screen.dart`.
- **Change:** the fixed `Column` is wrapped in `SingleChildScrollView` with
  `appScrollPadding`; the dial and chips retain their sizes, so 360-height landscape can
  scroll instead of overflowing.
- **Tests:** `test/tasbih_landscape_test.dart` — 640×360 logical viewport at textScale 2.0;
  no exception, dial and reset affordance present.
- **Result:** pass. No pixel-level layout measurement was taken.

#### UX-08 — Hijri calendar accessibility

- **Files:** `lib/features/hijri/presentation/hijri_screen.dart`,
  `lib/l10n/app_ar.arb`, `lib/l10n/app_en.arb`, generated l10n.
- **Change:** Gregorian day line 9sp → 11sp; today has a 1.4px primary outline in addition to
  the fill; each cell is wrapped in `Semantics` with
  `hijriCellSemantics(hijri, gregorian)` and the today suffix. `excludeSemantics: true`
  prevents the two bare numbers from being read separately.
- **Tests:** `test/hijri_semantics_test.dart` enables the semantics tree and finds
  `RegExp('هجري')` labels; existing `hijri_screen_test.dart` still finds the today tooltip and
  the dual label.
- **Result:** pass. TalkBack/VoiceOver behavior was not exercised on a device.

#### UX-11 — Reciters empty state

- **Files:** `lib/features/recitation/presentation/reciters/reciters_screen.dart`.
- **Change:** the raw centered text is now `EmptyState`; when the catalog is empty, it shows a
  visible `refresh` action wired to `RecitersCubit.refresh()`.
- **Rationale:** the old copy told the user to download the catalog while the only control was
  an app-bar icon.
- **Tests:** existing `reciters_screen_test.dart` (including the empty-index case) remains
  green; no new test was added for the action because the cubit's refresh is already covered.
- **Result:** pass.
- **Remaining:** the action is not separately asserted for call count.

#### UX-12 — Default-reciter label

- **Files:** `lib/features/recitation/presentation/reciter_surahs/reciter_surahs_screen.dart`,
  `lib/l10n/app_ar.arb`, `lib/l10n/app_en.arb`, generated l10n.
- **Change:** the star button tooltip is now `setAsDefaultReciter` instead of `featured`.
- **Remaining:** the current default is still not marked with a filled star/`Semantics(toggled:)`;
  that needs the selected-reciter state in the screen. Status is **Partially Fixed**.

#### UX-14 — Responsive grids

- **Files:** `lib/features/home/presentation/home_screen.dart`,
  `lib/features/asma/presentation/asma_screen.dart`.
- **Change:** `GridView.count(crossAxisCount: 3)` is replaced by
  `GridView.extent(maxCrossAxisExtent: 140)` and
  `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 130)`.
- **Rationale:** fixed 3 columns made tiles huge on tablets and ellipsized labels at 2× on
  narrow phones.
- **Tests:** existing home/Asma widget tests remain green. No tablet-width test was added;
  this is a qualitative layout improvement.

#### UX-15 — Tasbih counter semantics (partial)

- **Files:** `lib/features/tasbih/presentation/tasbih_screen.dart`.
- **Change:** the dial is a `Semantics(button: true, label: loc.tasbih, value: count,
  liveRegion: true)`.
- **Tests:** `test/tasbih_landscape_test.dart` finds the `'السبحة'` semantics label with the
  semantics tree enabled.
- **Remaining:** the azkar remaining badge still has no live-region semantics.

#### PERF-04 — Reciter catalog single-flight

- **Files:** `lib/features/recitation/data/reciter_repository.dart`.
- **Change:** `refreshFromApi` now returns a shared in-flight `Future`; the first caller starts
  the request, concurrent callers join it, and the gate clears on completion/failure so a
  later retry still works.
- **Rationale:** first-launch boot warm-up and `RecitersCubit._kickOnce` can both refresh the
  empty table, causing two HTTP GETs and two `DELETE`/`insertAll` rewrites.
- **Tests:** `test/reciter_refresh_single_flight_test.dart` — a gated local HTTP server sees
  exactly one request for two concurrent calls and one persisted row. Existing
  `reciter_repository_test.dart` remains green.
- **Result:** pass; this is a measured request-count improvement in the test harness.

### 20.3 Tests executed

| Command | Result |
|---|---|
| `flutter test test/tasbih_landscape_test.dart test/hijri_semantics_test.dart test/reciter_refresh_single_flight_test.dart test/contrast_call_sites_test.dart` | **6/6 passed**, exit 0 |
| Affected existing suites (tasbih, hijri, reciters, home, asma, azkar, duas, zakat, theme, WCAG) | **41/41 passed**, exit 0 |
| `flutter test` (full suite) | **856/856 passed**, exit 0 |
| `flutter analyze` | **0 issues** |
| `dart format --output=none --set-exit-if-changed lib test tools` | **481 files, 0 changed** |

No `flutter test --coverage` was run in this pass; the last measured coverage is stale and is
not quoted.

### 20.4 Remaining technical debt and risks

- **Blocked by frozen tests:** UX-04 (surah chevron) and PERF-06 (1-second prayer ticker) need
  owner approval to update the tests that pin the current behavior.
- **Not implemented:** UX-09 (type tokens/weights), UX-10 (two-line app bars), UX-13 (12/24-hour
  and long-duration formatting), UX-15 (azkar live region).
- **Performance:** PERF-01/02/03/05/07/08/09/10 remain. No numerical performance claim is made;
  the only measured change is the single-flight request count.
- **Visual risk:** the contrast and grid changes affect rendered layouts; store screenshots
  and a device pass should be repeated before release.
- **Accessibility risk:** semantics labels were tested in the widget tree, not with TalkBack or
  VoiceOver on a physical device.
- **No new dependencies** were added.

---

## 21. Architecture remediation — 2026-10-30

| Finding | Status | Change |
|---|---|---|
| ARC-02 | **Fixed** | Audio downloader, `DownloadsCubit` and `PlaybackCubit` are registered unconditionally; a missing writable audio root now fails only when a download starts |
| ARC-03 | **Fixed** | Pack progress is owned by the app-scoped `PackDownloader` (`progress` snapshot + broadcast stream); `LibraryCubit` seeds and mirrors it, so route re-entry no longer resets to 0 % |
| ARC-09 | **Fixed** | Player-sheet tests cover seek, stop/auto-close, and long-track clock; the stop button no longer pops the sheet explicitly (one state-driven pop only) |
| ARC-07 | **Unresolved** | Moving `AyahSheetCubit` I/O to `start()` requires editing five frozen tests that construct the cubit and expect auto-start |
| ARC-05 | **Unresolved** | Reader share still discards the platform future |
| ARC-08 | **Unresolved** | Cold-link initial routing and app-lifetime link listener remain |

**Files:** `lib/app/di/injector.dart`,
`lib/features/library/data/pack_downloader.dart`,
`lib/features/library/presentation/library_cubit.dart`,
`lib/features/recitation/presentation/playback/player_sheet.dart`.

**Tests added:** `test/audio_di_registration_test.dart` (1),
`test/library_progress_stream_test.dart` (2), `test/player_sheet_test.dart` (3).

**Validation:** targeted architecture tests pass; the full suite is **876/876**, analyze **0**,
format **0 changed**. The progress stream controller is intentionally app-lifetime (the
downloader is a singleton); it is not closed per route.

---

## 22. Data integrity remediation — 2026-10-30

| Finding | Status | Change |
|---|---|---|
| DAT-01 | **Fixed** | `AudioDownloader.reconcileOnStart` sweeps interrupted `downloading`/`queued` rows: a complete target becomes `done`, a missing one becomes `failed`, and orphan `.part` files are removed. `DownloadsCubit` runs it once before the first transfer |
| DAT-02 | **Fixed** | A promoted pack file is deleted if the registry insert fails; uninstall now removes the row/index before the file |
| DAT-13 | **Fixed** | Uninstall ordering is row/index first, file last, so a failed delete cannot leave an installed row with no file |
| DAT-03 | **Partially Fixed** | Bookmarks and khatma rows are range-clamped; rejected counts are surfaced in the preview. Codec-level skipped entries are still not carried into the preview |
| DAT-08 | **Fixed** | An HTTP 200 response with an HTML content type is rejected before promotion |
| DAT-04 | **Unresolved** | No `quick_check`/corrupt-file recovery or stale-seed repair |
| DAT-07 | **Unresolved** | Reciter catalog refresh can still orphan downloaded audio |
| DAT-12 | **Unresolved** | `prayer_log.day` remains a `dateTime` primary key; a schema migration is still owed |

**Files:** `lib/features/recitation/data/audio_downloader.dart`,
`lib/features/recitation/presentation/downloads/downloads_cubit.dart`,
`lib/features/library/data/pack_downloader.dart`,
`lib/features/backup/data/backup_merger.dart`,
`lib/features/backup/data/backup_service.dart`,
`lib/features/backup/presentation/backup_section.dart`, ARB + generated l10n.

**Tests:** `test/audio_download_reconcile_test.dart` (2),
`test/audio_content_type_test.dart` (1),
`test/pack_register_failure_test.dart` (1),
`test/backup_merge_validation_test.dart` (3). Targeted data-integrity suites:
**32/32 passed**.

**Backend limitation:** this app has no application backend, accounts, RLS, or server-side
authorization. The only remote services are the mp3quran catalog and the jsDelivr content CDN;
no backend change is claimed. The local drift DB is the trusted boundary for these fixes.

---

## 23. QA and coverage close-out — 2026-10-30

### 23.1 New tests in this pass

| Test file | Cases | Workflow protected |
|---|---:|---|
| `test/search_to_reader_navigation_test.dart` | 1 | Search result tap opens the reader at the exact surah:ayah (TST-03) |
| `test/reciter_refresh_failure_test.dart` | 3 | Catalog timeout, 5xx, and connection failure leave the catalog untouched (TST-06) |
| `test/azkar_system_back_test.dart` | 1 | System back exits reciting mode, not the Azkar feature (UX-05) |
| `test/asma_system_back_test.dart` | 1 | System back dismisses the name sheet, not the Asma feature (UX-05) |
| `test/player_sheet_test.dart` | 3 | Player sheet seek, stop/auto-close, and long-track clock (ARC-09/UX-13) |
| `test/security_platform_config_test.dart` | 6 | Manifest/CI/wrapper/SDK/debug-identity release boundaries |

Earlier in the same working tree: pack redirects (7), backup export size (2), khatma
concurrency (1), reader continuity (1), Home refresh (1), settings reschedule (2), playback
failure stop (2), zakat invalid input (2), tasbih landscape/semantics (2), Hijri semantics (1),
reciter single-flight (1), contrast call sites (2), audio DI (1), library progress (2),
backup merge validation (3), audio reconcile (2), audio content type (1), pack register
failure (1).

### 23.2 Commands and actual results

| Command | Result |
|---|---|
| `flutter test` (final full suite) | **877/877 passed**, exit 0 |
| `flutter test --coverage` (coverage run) | **876/876 passed**, exit 0 (one log-hygiene test added afterwards; no lib change) |
| `flutter analyze` | **0 issues** |
| `dart format --output=none --set-exit-if-changed lib test tools` | **492 files, 0 changed** |
| Raw lcov total | **73.15 %** — 7,161 / 9,790 lines |
| Hand-written Dart (excludes `*.g.dart`, `*.freezed.dart`, generated l10n) | **89.08 %** — 6,169 / 6,925 lines across 155 files |

The raw number includes generated code; the hand-written figure is the meaningful one for this
suite. Coverage was measured at the final working-tree state, not copied from the stale
2026-10-24 report.

### 23.3 Unavailable tests and remaining high-risk gaps

- **Integration tests are not run in CI** (TST-01). The three `integration_test` journeys need
  an emulator/device; no emulator job exists.
- **No device run** was performed for audio playback, notifications, sensors, downloads, or
  the signed release artifact.
- **Deep-link and notification-tap wiring** still has only mapper tests (TST-04).
- **Frozen tests:** the weak `page_contract_test`, `smoke_test`, and `router_test` were not
  edited; TST-08 remains.
- **Backup skipped-entry UI** is not covered end-to-end; the merge-level rejected count is.
- **Most important untested scenarios:** search result → reader on a device; cold/warm deep
  link; cold/warm notification tap; kill/restart during a download; backup export → share →
  import → restart; real audio background/notification; qibla sensor; release-signature smoke.

---

## 24. Release configuration remediation — 2026-10-30

| Finding | Status | Change |
|---|---|---|
| REL-07 | **Fixed** | `compileSdk = 36`, `minSdk = 24`, `targetSdk = 36` are explicit; `.fvmrc` pins Flutter 3.47.5 |
| REL-12 | **Fixed** | Launcher label moved to `@string/app_name` with `values/` + `values-en/`; `android:localeConfig` + `locales_config.xml` added |
| REL-13 | **Fixed** | Debug build gets `.debug` applicationId/versionName suffix; device smoke script accepts an explicit package id |
| REL-10 | **Partially Fixed** | README uses PowerShell env syntax and `--release` for split APKs; the store runbook still needs a final pass |
| REL-05 | **Unresolved** | R8/minify/shrink/obfuscation are still off; enabling them needs plugin keep rules and a signed-device smoke |
| REL-06 | **Unresolved** | Adaptive/monochrome icon and Android 12+ splash background are still missing |
| REL-01 | **Unresolved** | `versionCode` remains 3 and the verified AAB predates the current tree; do not upload until the console's highest code is checked and the artifact rebuilt |
| REL-02 | **Partially Fixed** | CI release job is gated and artifacts are named `debug-signed-*`; CI is still debug-signed |
| REL-03 | **External** | Licensing remains owner/legal-gated |
| REL-04 | **External** | Play App Signing certificate still needs to be added to `assetlinks.json` |
| REL-08 | **External** | Crash monitoring/rollback/staged rollout remains an owner decision |

**Build validation (actual):**

| Command | Result |
|---|---|
| `flutter build apk --release` | **exit 0**, 187.1 s; `app-release.apk` **70,876,095 B** |
| `aapt dump badging` on the APK | `package com.mostafasayed.quranyahdi`, `versionCode 3`, `versionName 1.0.0`, `sdkVersion 24`, `targetSdkVersion 36`, label `قرآن يَهدي` |
| `apksigner verify --print-certs` | **V2 signature verified**; owner cert `CN=Mostafa Sayed, … C=EG` |
| `zipalign -c -P 16 -v 4` | **Verification successful** (16 KB alignment) |
| `flutter build appbundle --release` | **exit 0**, 52.6 s; `app-release.aab` **69,615,315 B** |
| `jarsigner -verify -certs` on the AAB | **jar verified** |

No artifact was uploaded or published. The build emitted a non-fatal warning that a
`packages/cupertino_icons/CupertinoIcons` font was expected but not bundled; `lib/` contains no
`CupertinoIcons` reference, so this is dependency-originated. Re-check any plugin screen that
might use a Cupertino glyph on a device.

**Signing requirements:** `android/key.properties` is present on the owner machine and
gitignored; CI has no keystore. A store-bound build must use `PUBLISH_RELEASE=true` (or
`-PpublishRelease=true`) and fail closed without the owner key.

**Store submission still requires manual verification:** highest uploaded versionCode, Play
App Signing status/certificate, 16 KB ELF alignment, licensing clearance, screenshot freshness,
data-safety answers, and an internal-track smoke of the signed AAB.

---

## 25. Observability, privacy, and incident readiness — 2026-10-30

| Finding | Status | Change |
|---|---|---|
| REL-08 | **Partially Fixed** | Added `docs/operations-runbook.md`: error investigation, release-health monitoring, config control, escalation, rollback, dashboards, privacy incident checks. No crash SDK added; Play vitals remains the only production crash channel |
| Privacy policy accuracy | **Fixed** | Corrected location to **coarse only** (the manifest no longer requests fine); documented the absence of app-owned crash/analytics SDKs, the Google Play vitals boundary, and the automatic startup reciter-catalog fetch |
| Data-safety form accuracy | **Fixed** | `docs/store/data-safety-form-answers.md` no longer lists `ACCESS_FINE_LOCATION`; the network answer now distinguishes user-initiated downloads from the automatic startup `mp3quran.net` catalog request; added a platform-vitals note |
| Log hygiene | **Verified / guarded** | `test/log_hygiene_test.dart` fails on `print`/`debugPrint` in `lib/` and on obvious secret names in `dev.log` call windows |
| Crash reporting | **Unresolved (owner decision)** | No app-owned crash channel; adding Sentry/Firebase/etc. requires a privacy-policy and Data-safety update |
| Staged rollout / rollback execution | **Unresolved (external)** | The runbook defines the policy; no Play Console rollout was executed from this workstation |

**Files:** `docs/operations-runbook.md`, `docs/store/data-safety-form-answers.md`,
`PRIVACY.md`, `PRIVACY.en.md`, `test/log_hygiene_test.dart`.

**Privacy posture verified:** no accounts, no analytics/advertising/attribution SDK, no
app-owned server, no device identifiers in catalog/CDN requests, coarse location processed
on-device and not stored, local DB/backup plaintext documented, backup import logs only the
error type (never the user’s file content). The startup catalog request is automatic but
sends no parameters, identifiers, or user data; it necessarily exposes the user’s IP to
`mp3quran.net` as ordinary service-provider processing, which the privacy policies and the
Data-safety answer now state explicitly.

**Shipped-artifact permission check:** `aapt dump permissions` on the signed release APK shows
`INTERNET`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`,
`ACCESS_COARSE_LOCATION`, `SCHEDULE_EXACT_ALARM`, plus plugin-merged `VIBRATE`,
`POST_NOTIFICATIONS`, and `ACCESS_NETWORK_STATE`. It does **not** show `ACCESS_FINE_LOCATION`
or the advertising ID permission (`AD_ID`), matching the manifest and the privacy policy.

**Tests executed:** `test/log_hygiene_test.dart` — **1/1 passed**. The final full suite is
**877/877**; coverage is **73.15 % raw / 89.08 % hand-written** (§23).

**External prerequisites / manual verification:**

- Play Console access for Android vitals, internal/closed tracks, staged rollout, and Play App
  Signing certificate.
- An owner decision on whether a privacy-compatible crash channel is acceptable; without one,
  diagnosis is Play vitals + user reports only.
- Cloudflare Pages access for the web companion’s operational checks.
- A real-device incident drill (halt rollout, promote previous release, hotfix versionCode).

**Remaining operational risk:** a crash that Play vitals does not surface (e.g., a device-only
plugin failure) may be invisible until a user reports it. The runbook makes the investigation
privacy-preserving, but it does not create telemetry that does not exist. No claim of legal or
regulatory compliance is made.

---

**Report prepared:** 2026-10-30 · **Audit commit:** `d39c1f7` · **Security remediation applied
on top of the audit commit (see §18); functional remediation in §19; performance/accessibility
remediation in §20; architecture in §21; data integrity in §22; QA/coverage in §23; release
configuration in §24; observability/privacy in §25.**
