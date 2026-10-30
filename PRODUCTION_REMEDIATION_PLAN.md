# Production Remediation Plan — Quran Yahdi (`quran_yahdi`)

> **Status:** planning only. No application source, dependency, schema, test, or configuration
> file was modified while producing this document. The only file created is this plan.
>
> **Inputs:** `PRODUCTION_READINESS_REPORT.md` (93 findings: 4 blockers, 1 conditional
> blocker, 14 High, 2 Med-High, 31 Medium, 6 Low-Medium, 35 Low), plus a fresh source
> re-check at the same commit.
>
> **Current commit:** `d39c1f7136f1e0947b4746d5d57c9c852b1a8e63`
> **Branch:** `fix/perf-audit-2026-10-27` · 0 unpushed vs `origin/main`
> **Baseline gates re-used from the audit (same HEAD, no source changes):**
> `flutter analyze` = 0 issues · `flutter test` = 828/828 passed · Flutter 3.47.5 / Dart 3.13.4.
>
> **Execution rule:** every task is a separate gated change. No task may edit an existing
> test without the owner's explicit frozen-test ruling (AGENTS.md §3). No task may push.
>
> **Execution update (2026-10-30):** SEC-01, SEC-02, SEC-03, SEC-04 and REL-02 are
> implemented; SEC-05 and SEC-06 are partially fixed (wrapper unignored but not committed;
> backup temp-file lifetime remains); REL-04, REL-05 and SEC-07 remain open. See
> `PRODUCTION_READINESS_REPORT.md` §18. The 828/828 baseline above is the pre-remediation
> audit baseline; the current suite is 850/850.
>
> **Functional update (2026-10-30):** DAT-06, FUN-02, FUN-10, DAT-09 and ARC-01 are fixed;
> FUN-04 is partially fixed (validation only); DAT-05 is blocked by the frozen
> `test/tasbih_hydration_race_test.dart` and needs an owner ruling. See report §19.
>
> **Performance/accessibility update (2026-10-30):** UX-02, UX-07, UX-08, UX-11, UX-14 and
> PERF-04 are fixed; UX-12 and UX-15 are partially fixed; UX-04 and PERF-06 are blocked by
> frozen tests; the remaining PERF items are deferred. See report §20.
>
> **Architecture/data/QA/release update (2026-10-30):** ARC-02, ARC-03 and ARC-09 are fixed;
> DAT-01, DAT-02, DAT-08 and DAT-13 are fixed; DAT-03 is partial; ARC-07 and the remaining
> DAT items are open. Release config pins SDK/FVM, adds localized launcher/locale config and
> debug identity, and a signed APK/AAB build succeeded. Observability is documented in
> `docs/operations-runbook.md` without adding telemetry; the privacy policy and the Play
> Data-safety answers were corrected for coarse-only location and the automatic first-launch
> catalog fetch. See report §21–§25. Final suite 877/877.

---

## 1. Executive summary

### 1.1 What this plan is

The audit found **93 findings** (including one external conditional blocker), but they are not
93 independent projects. They reduce to **32 remediation tasks** grouped into **six
implementation phases** (Phase 1 has two waves), plus a baseline gate and an external-decision
track. Each task has a single rollback unit, explicit files, required tests, and acceptance
criteria. Every finding is mapped to exactly one task in §2.

### 1.2 Current validity

The working tree has **not changed since the audit commit**. `git diff` contains only the
pre-existing `.vscode/settings.json` owner edit; before this plan, the only new file was the audit report. The
P0/P1 root causes were re-read at source. All code findings therefore remain valid at the same
lines. External items (Play Console, licensing, 16 KB alignment, runtime profiling) remain
**unresolved**, not disproven.

### 1.3 Recommended order

1. **Phase 0 — decisions and frozen-test rulings.** No product code. Get the owner's rulings
   on the tests that pin the defects (reminders, Arabic plurals), licensing, Play App Signing,
   versionCode, reminder architecture, download scope, zakat persistence, crash monitoring, and
   iOS scope.
2. **Phase 1A — silent data loss and corruption** (backup, downloads, packs, DB recovery,
   local-state races). This is the highest user harm that can be fixed without external access.
3. **Phase 1B — essential workflow correctness** (reminders, continue-reading, retry, playback,
   qibla, zakat).
4. **Phase 2 — release pipeline, signing, store compliance** (rebuild, CI gating, R8, App Links,
   icons, licensing, release operations).
5. **Phase 3 — security and resilience hardening** (pack redirects, permissions, location
   denial, share/deep-link robustness).
6. **Phase 4 — accessibility, localization, UX** (contrast, plurals, RTL, semantics,
   confirmations, text-scale layouts).
7. **Phase 5 — test infrastructure and CI enforcement** (integration job, coverage gate,
   deterministic tests).
8. **Phase 6 — performance and feature completeness** (post-launch; measured, not speculative).

### 1.4 What must not be done

- Do not rebuild or upload the store artifact until Phase 1A/1B code is final and licensing is
  cleared. Otherwise the artifact is stale again on the day it is uploaded.
- Do not "fix" reminders by editing the existing pinned tests first. The tests must be changed
  only after the owner rules on the behavior change.
- Do not introduce a database migration for convenience. Two findings (pack index, prayer-log
  day key) need a deliberate migration wave; they are not release blockers.
- Do not remove features or disable checks to make the gates green.
- Do not add dependencies. Every fix below uses the existing stack.

---

## 2. Verified findings

### 2.1 Verification method

- `git rev-parse HEAD` and `git status --porcelain` were captured before planning.
- The audit commit is still `d39c1f7`; no `lib/`, `test/`, `android/`, `ios/`, `assets/`,
  `pubspec*`, or workflow file changed after the audit.
- Every P0/P1 finding was re-read at source in this session. Medium/Low findings marked `U`
  retain the audit's lane evidence at the same unchanged commit; findings marked `C` were
  directly re-read.
- External claims are marked `E`; they cannot be closed from the repository.

### 2.2 Status legend

| Code | Meaning |
|---|---|
| **C** | Confirmed at HEAD by a direct re-read in this session |
| **U** | Source unchanged since the audit; cited line/behavior re-checked or lane-verified |
| **E** | External: requires Play Console, a signed build, a device, runtime profiling, or legal input |
| **P** | Partial/conditional: the code is confirmed, but the impact depends on an environment fact |

### 2.3 Finding register

Every finding from `PRODUCTION_READINESS_REPORT.md` is listed once. The **Task** column points
to the task card in §4 that carries the solution, dependencies, tests, and acceptance criteria.

#### 2.3.1 Functional completeness (`FUN`)

| ID | Sev | Status | Affected files/components | Root cause | Impact | Task | Phase |
|---|---|---|---|---|---|---|---|
| FUN-01 | Blocker | C | `reminder_planner.dart:10,70-92`; `notifications_binding.dart:324-332`; `settings_cubit.dart:92-106,121,168`; `main.dart:138-149`; `AndroidManifest.xml:83` | One fixed prayer id, loop breaks on first future prayer, no daily repeat, no boot receiver, permission prompt gated on azkar | Prayer/azkar/wird reminders silently stop; prayer-only users never see the permission prompt | REM-06 | 1B |
| FUN-02 | High | C | `reader_cubit.dart:77,157`; `reader_screen.dart:376` | Last-read saved on load and mushaf paging only | Continue-reading card never advances in verse mode | REM-07 | 1B |
| FUN-03 | High | C | `heading_service.dart:9-17,39-40`; `qibla_cubit.dart:81-104` | Raw magnetometer only; no tilt compensation/accuracy | Wrong qibla bearing when the phone is upright; no warning | REM-10 | 1B |
| FUN-04 | High | C | `zakat_screen.dart:197-232`; `zakat_calculator.dart:24-26`; `zakat_cubit.dart:7-64` | No formatters/validation/persistence; unparseable input becomes 0 | Typo can invert the zakat verdict; inputs lost on leave | REM-11 | 1B |
| FUN-05 | Med | U | `tracker_screen.dart:58-61,147-150`; `tracker_cubit.dart:223-236` | UI renders today only | No backfill/correction of a missed day | REM-32 | 6 |
| FUN-06 | Med | U | `reader_screen.dart:92-115`; `reader_state.dart:23`; `verse.dart:38-52`; `tables.dart:32,46` | Missing juz/sajda/prev-next/font-size; mode not persisted | Navigation and reading-preference gaps | REM-32 | 6 |
| FUN-07 | Med | U | `hadith_cubit.dart:24,65-78`; `hadith_screen.dart:79-165` | 10-per-page list; no search/TOC | ~7,000 hadith effectively unsearchable | REM-32 | 6 |
| FUN-08 | Med | U | `router.dart` (no downloads route); `reciter_surahs_screen.dart:139-142`; `downloads_cubit.dart:39-55` | Downloads only as a per-surah row; queue in memory | 114 taps per reciter; queue lost on kill | REM-02 | 1A |
| FUN-09 | Med | U | `backup_inventory.dart:65-72`; `reminder_settings.dart:14,93-98` | `prayer_reminder_enabled` missing from whitelist | Restore silently re-enables prayer reminders | REM-01 | 1A |
| FUN-10 | Med | U | `home_cubit.dart:83-88`; `home_screen.dart:66-104` | Next-prayer card computed once | Stale "next prayer" when Home stays open | REM-07 | 1B |
| FUN-11 | Med | U | `pack_downloader.dart:476-482`; `library_screen.dart:134-147` | Version-aware `isInstalled` has zero callers | No pack update path; stale content invisible | REM-03 | 1A |
| FUN-12 | Low | U | `azkar_cubit.dart:77-107`; `azkar_screen.dart:296-303` | Counters live only in cubit state | Session progress lost on back; search opens item 0 | REM-32 | 6 |
| FUN-13 | Low | U | `tasbih_screen.dart:79-82`; `tasbih_cubit.dart:60-73` | No dhikr text; count unbounded past target | Users must know the phrase; target semantics unclear | REM-32 | 6 |

#### 2.3.2 Release, build, and store (`REL`)

| ID | Sev | Status | Affected files/components | Root cause | Impact | Task | Phase |
|---|---|---|---|---|---|---|---|
| REL-01 | Blocker | C | `pubspec.yaml:5`; `docs/store/play-console-setup.md:15-25`; 20 commits since `76da2d7` | Verified AAB predates HEAD; versionCode 3 not bumped | Uploading old binary or Play rejection; screenshots stale | REM-12 | 2 |
| REL-02 | Blocker | C | `.github/workflows/ci.yml:31-52`; `android/app/build.gradle:90-94` | Release job not gated on tests; debug-signed; release-named | Red suite can produce a distributable-looking bundle | REM-13 | 2 |
| REL-03 | Blocker | C/E | `docs/store/licensing-matrix.md` rows 2,4,11; `play-console-setup.md:107-122` | Font/tafsir/mp3quran terms still `OPEN-FOR-OWNER` | IP/takedown risk at launch | REM-18 | 2 |
| REL-04 | Blocker (conditional) | E | `web/public/.well-known/assetlinks.json`; Play Console | Only the upload-cert fingerprint is pinned | App Links break under Play App Signing | REM-15 | 2 |
| REL-05 | High | C | `android/app/build.gradle:74-110`; `ci.yml:41-42` | No R8, shrink, ProGuard, obfuscation, or symbol archive | 68.9 MB AAB; recoverable Dart symbols | REM-14 | 2 |
| REL-06 | Med | C | `android/app/src/main/res`; `values-v31/styles.xml`; `pubspec.yaml:39-43` | No adaptive/monochrome icon; v31 splash omits background | Legacy icon; branded splash lost on Android 12+ | REM-16 | 2 |
| REL-07 | Med | U | `android/app/build.gradle:33,52-53`; no `.fvmrc` | SDK levels inherited from local Flutter | Silent SDK drift in store artifact | REM-14 | 2 |
| REL-08 | Med | U | `pubspec.yaml` (no crash SDK); `play-console-setup.md:102-104` | No crash channel, staged rollout, or rollback doc | Regressions invisible; only remedy is halt rollout | REM-17 | 2 |
| REL-09 | Med | U | `tools/device_smoke.ps1:16`; `play-console-setup.md` | Smoke installs debug APK, checks only process alive | Store binary never smoked | REM-12 | 2 |
| REL-10 | Med | C | `README.md:59-61`; `AGENTS.md:30` | Bash env syntax; split APK line omits `--release` | Runbook fails/creates debug artifacts | REM-12 | 2 |
| REL-11 | Med | C | `android/.gitignore:1,4,5`; `gradle-wrapper.properties:5` | Wrapper ignored; no checksum | Clean clone cannot run documented publish path; unverified bytes | REM-14 | 2 |
| REL-12 | Low | U | `AndroidManifest.xml:11` | Hard-coded Arabic label; no locale config | English launcher name/per-app language missing | REM-16 | 2 |
| REL-13 | Low | C | `android/app/build.gradle:47-61` | Debug and release share `applicationId` | Debug/store builds cannot coexist | REM-14 | 2 |
| REL-14 | Low | C | `assets/json/hafs_smart_v8.json` (7.4 MB); `pubspec.yaml:70-74` | Build-only input tracked in assets | Repo bloat; not shipped | REM-16 | 2 |
| REL-15 | Low | U | `settings.gradle`; `gradle.properties:8,10-12` | AGP 9 escape hatches (`newDsl`, `builtInKotlin`) | AGP 10 breakage; migration debt | REM-14 | 2 |
| REL-16 | Low | C | `reciter_repository.dart` endpoint; `library_catalog.json`; no flavors | One compile-time environment | No staging path for catalog/CDN changes | REM-14 | 2 |

#### 2.3.3 Data integrity and resilience (`DAT`)

| ID | Sev | Status | Affected files/components | Root cause | Impact | Task | Phase |
|---|---|---|---|---|---|---|---|
| DAT-01 | High | C | `audio_downloader.dart:188-231`; `downloads_cubit.dart:39-46` | No startup reconciliation; only `done` rows hydrate | Stuck `downloading` rows; orphan `.part`; re-download from zero | REM-02 | 1A |
| DAT-02 | High | C | `pack_downloader.dart:144-153,217-259` | Promote before register; catch deletes the wrong file; no per-request retry | Ghost packs; one 5xx wastes a multi-file install | REM-03 | 1A |
| DAT-03 | High | C | `backup_cubit.dart:91-99`; `backup_codec.dart:153-160`; `backup_merger.dart:28-38,72-86` | `skippedEntries` dropped; bookmark/khatma ids not clamped | Silent partial restore; undeletable bookmarks; wedged wird | REM-01 | 1A |
| DAT-04 | High | C | `connection.dart:140,199-208,217-232` | No integrity check; fixed seed temp reused; open failures swallowed | Corrupt DB bricks every screen; stale seed reverts content | REM-04 | 1A |
| DAT-05 | High | C | `tasbih_cubit.dart:36-72` | `_userMutated` set before hydration; pre-load tap persists 1 | Stored count (e.g. 500) silently lost | REM-05 | 1A |
| DAT-06 | Med | C | `khatma_repository.dart:59-67` | Read-modify-write without conditional update | Concurrent page changes move progress backward | REM-05 | 1A |
| DAT-07 | Med | C | `reciter_repository.dart:187-190,224-226`; `tables.dart:125-141` | Delete/reinsert catalog; downloads store a string id with no FK | Renumbered/dropped moshaf orphans audio and dead-ends screen | REM-02 | 1A |
| DAT-08 | Med | U | `audio_downloader.dart:195-225` | Accepts HTTP 200 with no size/sniff validation | HTML captive-portal page promoted as a finished MP3 | REM-02 | 1A |
| DAT-09 | Med | C | `settings_cubit.dart:96-105` | DB write precedes re-plan; failure only logged | UI and storage disagree on a reminder switch | REM-06 | 1B |
| DAT-10 | Med | U | `location_service.dart:31-37,42-49` | `deniedForever` opens the system location toggle | "Locate me" becomes a permanent dead end | REM-21 | 3 |
| DAT-11 | Med | C | `backup_service.dart:57-68`; `backup_cubit.dart:231-244` | Export has no size guard; delete-after-share | App can export a file its own importer rejects; lazy receiver sees a deleted path | REM-01 | 1A |
| DAT-12 | Low | C | `tables.dart:79-96` | `dateTime` primary key; day identity is a convention | A future writer can create a duplicate day row and reset a streak | REM-04 | 1A |
| DAT-13 | Low | C | `pack_downloader.dart:456-474` | File deleted before row/index | "Installed" row with missing file; empty pack surfaces | REM-03 | 1A |
| DAT-14 | Low | C | `notifications_binding.dart:302-334`; `prayer_times_cubit.dart:142-151` | Plan fingerprint is in-memory only | Re-cancel/re-schedule platform alarms on routine refresh | REM-06 | 1B |

#### 2.3.4 UX, accessibility, localization (`UX`)

| ID | Sev | Status | Affected files/components | Root cause | Impact | Task | Phase |
|---|---|---|---|---|---|---|---|
| UX-01 | High | C | `loading_and_error_views.dart:14-22`; `error_pane.dart:8`; 19 call sites | Shared failure view has no retry | Transient failure dead-ends a route; Home is unrecoverable | REM-08 | 1B |
| UX-02 | High | C | `app_theme.dart:34-37,66-67`; `tasbih_screen.dart:47`; `zakat_screen.dart:142-146`; `duas_screen.dart:212-216`; `reciter_surahs_screen.dart:89-94`; `azkar_screen.dart:292-295` | Raw gold as foreground; `Opacity 0.45` on whole card | 1.78–2.63:1 contrast; text unreadable | REM-24 | 4 |
| UX-03 | High | C | `app_ar.arb:89,143,186,361`; no ICU plural keys | Arabic uses simple interpolation, not plural categories | "٢ ذكر", "٣ سورة", "٥ يوم" | REM-25 | 4 |
| UX-04 | Med-High | C | `surah_index_screen.dart:105-109`; `hijri_screen.dart:82-110` | Manual RTL chevron choice on already-mirrored icons | Backward-pointing chevrons; reversed nav glyphs | REM-23 | 4 |
| UX-05 | Med-High | C | `azkar_screen.dart:67-90`; `asma_screen.dart:53-61`; no `PopScope` | Sub-states are not routes; system back pops the screen | Lost recitation position / card open exits feature | REM-23 | 4 |
| UX-06 | Med | C | `bookmarks_screen.dart:79-83`; `bookmarks_cubit.dart:56-58` | One-tap delete; no confirm/undo; no catch | Long-lived bookmark lost; unhandled DB error | REM-26 | 4 |
| UX-07 | Med | C | `tasbih_screen.dart:29-51,83-87` | Non-scrolling fixed-height column; no bottom inset | Landscape/split-screen overflow | REM-27 | 4 |
| UX-08 | Med | U | `hijri_screen.dart:123-135,139-173` | 9sp Gregorian line; color-only today; no semantics | Low-vision/color-blind/screen-reader failure | REM-24 | 4 |
| UX-09 | Med | C | `pubspec.yaml:85-88`; `app_theme.dart:71-101`; w500/w600 requests | Only 400/700 ship; no `textTheme`; 17 ad-hoc sizes | Flat hierarchy; inconsistent type | REM-24 | 4 |
| UX-10 | Med | U | `reciter_surahs_screen.dart:33-45`; `hadith_screen.dart:49-65` | Two-line title in fixed toolbar | Clipped at textScale 2.0 | REM-27 | 4 |
| UX-11 | Low-Med | U | `reciters_screen.dart:62-68`; `app_ar.arb:87` | Raw empty Text; action only in app bar | Instructions point to an off-screen action | REM-26 | 4 |
| UX-12 | Low-Med | U | `reciter_surahs_screen.dart:50-54` | Tooltip says "featured"; action is "set default"; current default unmarked | Wrong screen-reader label; no state feedback | REM-26 | 4 |
| UX-13 | Low | U | `arabic_numbers.dart:52-56`; `settings_screen.dart:175-190`; `player_sheet.dart:58-62`; `app_ar.arb:206-207` | Always 24h; no `h:mm:ss`; dead key uses Western digits | Picker/list mismatch; "97:20" duration | REM-25 | 4 |
| UX-14 | Low | U | `home_screen.dart:185-191,270-276`; `asma_screen.dart:153-160` | Fixed 3-column grids with fixed aspect ratio | Huge tablet tiles; ellipsized 2× labels | REM-27 | 4 |
| UX-15 | Low | U | `tasbih_screen.dart:71-90`; `azkar_screen.dart:296-303,362-379` | No live-region semantics on counters | Screen-reader users are not told the count changed | REM-24 | 4 |

#### 2.3.5 Architecture and code quality (`ARC`)

| ID | Sev | Status | Affected files/components | Root cause | Impact | Task | Phase |
|---|---|---|---|---|---|---|---|
| ARC-01 | High | C | `playback_cubit.dart:151-167`; `mini_player_bar.dart:35`; mounts at `reader_screen.dart:138`, `reciter_surahs_screen.dart:82` | Failure path does not stop the previous track; mini player is per-screen | UI says failed while audio plays; no controls on 18 routes | REM-09 | 1B |
| ARC-02 | Med | U | `router.dart:319-321,344-349`; `injector.dart:167-180` | Optional audio cubits resolved unconditionally | Degraded boot/test can crash on primary routes | REM-09 | 1B |
| ARC-03 | Med | C | `library_cubit.dart:57-75`; `pack_downloader.dart:102-111` | Progress map lives in the route cubit | 0 % until install completes after route re-entry | REM-03 | 1A |
| ARC-04 | Low | C | `bookmarks_cubit.dart:56-65`; `bookmarks_screen.dart:82` | Only mutation without typed catch | Unhandled async error; row stays | REM-08 | 1B |
| ARC-05 | Low | U | `reader_screen.dart:322` | Share future discarded | Unhandled `PlatformException` | REM-22 | 3 |
| ARC-06 | Low | C | `backup_cubit.dart:236-244` | Temp file deleted in `finally` after share | Receiver can get a missing file | REM-01 | 1A |
| ARC-07 | Low | U | `ayah_sheet_cubit.dart:26-28`; `route_cubit_scope.dart:9-14` | I/O in constructor, not `start()` | Load outside mount lifecycle | REM-22 | 3 |
| ARC-08 | Low | U | `main.dart:82-88,120-180` | Cold link resolved after plugin init; stream has no error/cancel | Late navigation overrides user; uncaught stream error | REM-22 | 3 |
| ARC-09 | Low | U | `player_sheet.dart:113-116,193-196`; `mini_player_bar.dart:124` | Zero tests; `maybePop()` on build | Double-pop risk; silent regressions | REM-28 | 5 |

#### 2.3.6 Security and platform (`SEC`)

| ID | Sev | Status | Affected files/components | Root cause | Impact | Task | Phase |
|---|---|---|---|---|---|---|---|
| SEC-01 | Low | C | `pack_downloader.dart:282-285,313-316`; contrast `audio_downloader.dart:127-159` | Dio follows redirects; only the initial scheme is checked | A redirect can fan a pack request to any host (content still sha256-pinned) | REM-19 | 3 |
| SEC-02 | Low | C | `AndroidManifest.xml:7-8`; `location_service.dart:50-55` | Declares FINE but only uses medium accuracy | Over-broad permission; weaker Data-safety case | REM-20 | 3 |
| SEC-03 | Low | C | `data_extraction_rules.xml:3-10`; `connection.dart:218-219` | DB lives in `file` domain; rules exclude only db/sharedpref | User DB rides device-to-device transfer | REM-20 | 3 |
| SEC-04 | Low | C | `.github/workflows/ci.yml:11-12,35-36,43,48` | Mutable action tags; no `permissions:` | Supply-chain/least-privilege gap | REM-13 | 2 |
| SEC-05 | Low | C | `android/.gitignore:1,4,5`; `gradle-wrapper.properties:5` | Wrapper not tracked; no checksum | Non-reproducible build; unverified bytes | REM-14 | 2 |
| SEC-06 | Low | C | `backup_service.dart:57-68`; `backup_codec.dart:225-227` | Export/import size asymmetry; plaintext | Unrestorable backup; documented plaintext | REM-01 | 1A |
| SEC-07 | Low | C | `android/app/build.gradle:47-61` | Same `applicationId` for debug/release | Artifact confusion; cannot coexist | REM-14 | 2 |

#### 2.3.7 Testing and QA (`TST`)

| ID | Sev | Status | Affected files/components | Root cause | Impact | Task | Phase |
|---|---|---|---|---|---|---|---|
| TST-01 | High | C | `.github/workflows/ci.yml:26`; `integration_test/` | CI never runs integration tests | Real boot/DI/router/plugin regressions ship green | REM-28 | 5 |
| TST-02 | Med | C | `coverage/lcov.info` (2026-10-24); `ci.yml` | No coverage run/threshold; report is stale | No quality bar; 72.05 % is unverified | REM-29 | 5 |
| TST-03 | Med | C | `quran_search_screen.dart:174`; `quran_search_screen_test.dart:68` | Test renders a row but never taps it | Wrong ayah can open with a green suite | REM-28 | 5 |
| TST-04 | Med | C | `main.dart:120-180`; mapper-only tests | Cold/warm wiring is untested | Links/notification taps can silently break | REM-28 | 5 |
| TST-05 | Med | C | `player_sheet.dart`; no test references | Newest surface has zero tests | Seek/stop/pop regressions invisible | REM-28 | 5 |
| TST-06 | Low-Med | U | `reciter_repository.dart:131`; `pack_downloader.dart:46-47`; `audio_downloader.dart:15-16` | No timeout/5xx/connection-error tests | Offline UX can land in the wrong state | REM-29 | 5 |
| TST-07 | Low-Med | C | `prayer_log_repository_test.dart:18-19`; `tracker_cubit_test.dart:46,59,70` | Real-clock reads | Midnight/DST flake | REM-29 | 5 |
| TST-08 | Low | C | `page_contract_test.dart:5,19-33`; `smoke_test.dart:37-42`; `router_test.dart:6-28` | Tests assert a fake's constants, the widget just mounted, or 14 of 20 paths | False confidence | REM-29 | 5 |
| TST-09 | Low | C | `ci.yml:22-25`; contrast `web.yml:79-124` | Codegen runs but tree cleanliness is not checked | Stale generated code passes | REM-13 | 2 |

#### 2.3.8 Performance (`PERF`)

| ID | Sev | Status | Affected files/components | Root cause | Impact | Task | Phase |
|---|---|---|---|---|---|---|---|
| PERF-01 | Med | C | `pack_reader.dart:47-49,65-66,230-245,302-326` | Whole pack decoded per surah; cache keyed per surah | Spinner and large transient tree per surah change | REM-30 | 6 |
| PERF-02 | Low-Med | U | `main.dart:82-88`; `reminder_settings.dart:25-71`; `home_cubit.dart:70-75` | ~11 serialized boot queries; 7 single-key settings reads | Latency behind cold DB open | REM-30 | 6 |
| PERF-03 | Low-Med | C | `tasbih_cubit.dart:60-73,93-100` | One transaction + full-body rebuild per tap | Flash write amplification; frame bursts | REM-30 | 6 |
| PERF-04 | Low | C | `reciter_repository.dart:129-191,202-207`; `main.dart:97-106` | No single-flight on catalog refresh | Duplicate HTTP + table rewrite at first launch | REM-02 | 1A |
| PERF-05 | Low | U | `qibla_screen.dart:57-71,109`; `heading_service.dart:39-40` | Sensor runs for route lifetime; no sampling period | Battery/CPU while compass is covered | REM-31 | 6 |
| PERF-06 | Low | C | `prayer_times_screen.dart:87-93`; `prayer_times_cubit.dart:135` | 1 Hz ticker for minute-granularity text | 3,600 wakes/hour on an open screen | REM-31 | 6 |
| PERF-07 | Low | U | `pubspec.yaml:76-89`; no `FontLoader` | Quran fonts decode on first use | First-open text flash/relayout | REM-30 | 6 |
| PERF-08 | Low | U | `bookmarks_cubit.dart:117-133,150-192` | Re-maps all loaded pages per emission; `_older` unbounded | Churn proportional to paging | REM-31 | 6 |
| PERF-09 | Low | U | `reader_screen.dart:377-398` | Full `TextSpan` list built in `itemBuilder` | Page-turn jank on low-end devices | REM-31 | 6 |
| PERF-10 | Low | U | `tracker_cubit.dart:62-88,223-236`; `prayer_log_repository.dart:89-126` | Six queries per toggle; 400 bound dates | Slow toggle feedback | REM-31 | 6 |

### 2.4 Corrections and boundaries

- No finding in the audit was disproven at this HEAD. The earlier misspelled `tasbih` filename
  in the report was corrected before this plan.
- `mergeTasbih` already validates `target > 0`; the audit did **not** claim otherwise. The
  unvalidated field is the khatma `targetPages`/`ayahId` pair in `mergeKhatma`.
- `U` is not re-labeled as direct verification. The audit's lane evidence is explicit.
- The audit is a code and configuration review. It is not proof of runtime behavior, store
  acceptance, legal clearance, or absence of vulnerabilities outside the inspected surface.

---

## 3. Prioritized remediation backlog

### 3.1 Engineering tasks (execution order)

| Rank | Task | Covers | Highest severity | Phase | Why here |
|---:|---|---|---|---|---|
| 1 | REM-01 Backup integrity | DAT-03, FUN-09, DAT-11, ARC-06, SEC-06 | High | 1A | Silent partial restore is the worst data-loss path in the app |
| 2 | REM-02 Download lifecycle | DAT-01, DAT-07, DAT-08, FUN-08, PERF-04 | High | 1A | Interrupted downloads lose data and storage; no reconciliation |
| 3 | REM-03 Pack atomicity and retry | DAT-02, DAT-13, ARC-03, FUN-11 | High | 1A | One 5xx destroys a multi-file install; ghost packs |
| 4 | REM-04 DB recovery and seed safety | DAT-04, DAT-12 | High | 1A | A corrupt file bricks every screen; stale seed reverts content |
| 5 | REM-05 Local-state races | DAT-05, DAT-06 | High | 1A | Silent loss of tasbih count; khatma regression |
| 6 | REM-06 Reminder engine and permission | FUN-01, DAT-09, DAT-14 | Blocker | 1B | Headline feature silently stops; release blocker |
| 7 | REM-07 Reader continuity and home ticker | FUN-02, FUN-10 | High | 1B | Primary re-engagement card frozen |
| 8 | REM-08 Error retry and bookmark failure | UX-01, ARC-04 | High | 1B | 18 screens dead-end on transient failure |
| 9 | REM-09 Playback failure and mini player | ARC-01, ARC-02 | High | 1B | UI says failed while audio plays; controls on 2 routes |
| 10 | REM-10 Qibla accuracy | FUN-03 | High | 1B | Religious-direction correctness |
| 11 | REM-11 Zakat validation and persistence | FUN-04 | High | 1B | A typo can invert a financial-religious verdict |
| 12 | REM-12 Signed artifact and runbook | REL-01, REL-09, REL-10 | Blocker | 2 | Rebuild only after Phase 1 code is final |
| 13 | REM-13 CI gates and supply chain | REL-02, SEC-04, TST-09 | Blocker | 2 | Prevent a red/debug-signed artifact |
| 14 | REM-14 Build hardening and reproducibility | REL-05, REL-07, REL-11, REL-13, REL-15, REL-16, SEC-05, SEC-07 | High | 2 | R8/shrink/obfuscate, SDK pin, wrapper, debug suffix |
| 15 | REM-15 App Links and Play signing | REL-04 | Blocker (cond.) | 2 | Must be verified against the Play cert |
| 16 | REM-16 Store assets and platform polish | REL-06, REL-12, REL-14 | Med | 2 | Icon/splash/label/dead input |
| 17 | REM-17 Release operations | REL-08 | Med | 2 | No crash/rollback/staged rollout plan |
| 18 | REM-18 Licensing closure | REL-03 | Blocker | 2 | Legal gate; external |
| 19 | REM-19 Pack redirect validation | SEC-01 | Low | 3 | Redirect hardening is cheap and testable |
| 20 | REM-20 Permission and backup scope | SEC-02, SEC-03 | Low | 3 | Remove unused FINE; exclude file domain |
| 21 | REM-21 Location denial path | DAT-10 | Med | 3 | Permanent dead end after "don't ask again" |
| 22 | REM-22 Share/deep-link/AyahSheet robustness | ARC-05, ARC-07, ARC-08 | Low | 3 | Unhandled async errors and late routing |
| 23 | REM-23 RTL and system back | UX-04, UX-05 | Med-High | 4 | Every Arabic user sees the chevrons |
| 24 | REM-24 Contrast, semantics, typography | UX-02, UX-08, UX-09, UX-15 | High | 4 | WCAG failures + screen-reader gaps |
| 25 | REM-25 Arabic plurals and formatting | UX-03, UX-13 | High | 4 | Most visible Arabic copy reads machine-translated |
| 26 | REM-26 Confirmations, empty states, labels | UX-06, UX-11, UX-12 | Med | 4 | Prevent accidental data loss and dead-end copy |
| 27 | REM-27 Text-scale and landscape layouts | UX-07, UX-10, UX-14 | Med | 4 | Overflow and truncation on real devices |
| 28 | REM-28 Integration test coverage in CI | TST-01, TST-03, TST-04, TST-05, ARC-09 | High | 5 | The only tests that boot the app are not run |
| 29 | REM-29 Coverage and test quality | TST-02, TST-06, TST-07, TST-08 | Med | 5 | Stale coverage, weak tests, flaky clocks |
| 30 | REM-30 Pack/boot/tasbih/font performance | PERF-01, PERF-02, PERF-03, PERF-07 | Med | 6 | Post-launch, measured improvements |
| 31 | REM-31 Sensor/list/tracker performance | PERF-05, PERF-06, PERF-08, PERF-09, PERF-10 | Low | 6 | Post-launch, measured improvements |
| 32 | REM-32 Feature completeness | FUN-05, FUN-06, FUN-07, FUN-12, FUN-13 | Med | 6 | Product-scope features; not release blockers |

### 3.2 External / owner track (not code-only)

| Item | Related findings | Decision/evidence needed | Blocks |
|---|---|---|---|
| Content licensing | REL-03 | Written font terms; quranenc confirmation; mp3quran listing terms | REM-12 upload |
| Play App Signing | REL-04 | Console state + app-signing SHA-256 | App Links verification |
| Highest versionCode | REL-01 | Play Console tracks | Version bump choice |
| Reminder architecture | FUN-01 | Boot receiver/WorkManager vs. "open daily"; exact vs. inexact alarms | REM-06 |
| Download scope | FUN-08 | Global queue + download-all, or reconciliation only | REM-02 |
| Zakat persistence | FUN-04 | Persist inputs (privacy/retention) or leave ephemeral | REM-11 |
| Crash monitoring | REL-08 | Privacy-first channel vs. Play vitals only | REM-17 |
| English locale | UX-03 (tests), app locale | Activate EN or keep AR-only | REM-25 scope |
| iOS | — | In scope or separate project | Backlog |
| 16 KB alignment | REL-05/REL-09 | Build inspection `zipalign -c -P 16` | REM-12 |

## 4. Implementation phases and task cards

Each task is one rollback unit. The required shape is: **failing test → minimal fix → full
gates → explicit-pathspec commit** (no push). Files listed are the expected touch set; the
executor must re-read them before editing.

### Phase 0 — Baseline, decisions, and frozen-test rulings (no product code)

**Purpose:** prevent implementing a fix that cannot land (frozen tests) or cannot ship
(licensing/signing). **Entry:** this plan approved. **Exit:** decision log + baseline proof +
approved test-edit list.

- Re-run `flutter analyze` and `flutter test`; record HEAD, porcelain, exact counts.
- Record the pinned tests listed in §6.4. Obtain an owner ruling per file:
  *new test only* vs *approved edit* vs *stop*.
- Obtain the external decisions in §3.2.
- Open a `docs/superpowers/plans/` ledger entry (not a source change) recording the rulings.
- No product behavior changes. **DoD:** baseline green, rulings recorded, no source edits.

### Phase 1A — Silent data loss, corruption, and integrity (REM-01 … REM-05)

#### REM-01 — Backup integrity and truthful restore

- **Covers:** DAT-03, FUN-09, DAT-11, ARC-06, SEC-06 · **Phase:** 1A · **Effort:** M
- **Affected:** `lib/features/backup/presentation/backup_cubit.dart`, `backup_state.dart`,
  `backup_section.dart`; `lib/features/backup/data/backup_codec.dart`,
  `backup_merger.dart`, `backup_inventory.dart`, `backup_service.dart`; `test/backup_*`.
- **Root cause:** `skippedEntries` is counted by the codec and thrown away by the cubit;
  bookmarks and khatma rows are not clamped; export does not measure itself against
  `kBackupMaxBytes`; the shared temp file is deleted immediately after `SharePlus`.
- **Impact:** a slightly malformed backup restores "successfully" with data missing; a crafted
  or future-schema file can create an invisible, undeletable bookmark and a wedged wird card.
- **Solution:**
  1. Add `skippedEntries` (and a `hasWarnings` flag) to `BackupState.preview` /
     `BackupState.imported`; render a localized warning line in `backup_section.dart`.
  2. Fail closed when skipped > 5 % (or a named constant), with a distinct invalid-file state.
  3. Clamp `BookmarkMerge` ids to `1..kBackupMaxAyahId`; skip and count out-of-range rows.
  4. Validate khatma `ayahId` 1..6236 and `targetPages > 0`; keep the existing plan otherwise.
  5. Add `prayer_reminder_enabled` to `kBackupSettingsWhitelist` and
     `kBackupReminderRelevantKeys`.
  6. Compare encoded export size to `kBackupMaxBytes`; refuse/warn before sharing.
  7. Keep the export temp file for the session (or hand over `XFile.fromData`) and clean it on
     next launch; do not delete immediately after the share future resolves.
- **Dependencies:** none. No schema change. **Frozen risk:** low; add new tests, do not rewrite
  `backup_codec_test.dart` / `backup_write_path_parity_test.dart` except for additive cases.
- **Required tests:** corrupt-entry preview shows N skipped; > threshold fails closed;
  bookmark 999999/0 skipped and counted; khatma `targetPages <= 0` keeps the existing plan;
  `prayer_reminder_enabled` round-trips; export > cap warns; shared file still exists after the
  share seam resolves.
- **Acceptance:** no silent partial restore; every skipped entry is visible or blocks; invalid
  ids never reach the DB; restore remains transactional; existing 828 suite stays green.

#### REM-02 — Audio download lifecycle, integrity, and queue

- **Covers:** DAT-01, DAT-07, DAT-08, FUN-08, PERF-04 · **Phase:** 1A · **Effort:** L
- **Affected:** `lib/features/recitation/data/audio_downloader.dart`,
  `lib/features/recitation/presentation/downloads/downloads_cubit.dart` + state,
  `lib/features/recitation/data/reciter_repository.dart`,
  `lib/features/recitation/presentation/reciter_surahs/*`,
  `lib/features/recitation/presentation/downloads/*`, `lib/app/router.dart`,
  `lib/core/utils/app_routes.dart`, tests.
- **Root cause:** startup hydrates only `done` rows; no orphan `.part` cleanup; a 200 HTML
  page passes; a catalog refresh drops rows without correlating downloads; no single-flight;
  no global queue surface.
- **Impact:** killed downloads stay `downloading` forever, waste the full download again, and
  leak `.part` files; a captive portal can create a green "downloaded" file that never plays;
  a reciter renumber orphans audio with no way to delete it.
- **Solution:**
  1. `AudioDownloader.reconcileOnStart()`: mark `downloading`/`queued` rows failed, delete
     orphan `.part` files under the audio root, and promote a `downloading` row whose target
     exists at the recorded size.
  2. Reject non-audio 200s: require a minimum plausible size and sniff `ID3`/MPEG frame bytes
     or reject `text/html`; treat a `done` row that fails the sniff as failed.
  3. Add a retry/backoff wrapper (2–3 attempts) for one-surah downloads; preserve the existing
     `.part` cleanup on final failure.
  4. Add single-flight to `refreshFromApi` / `ensureCatalog` (share the in-flight future).
  5. Add a `/downloads` route listing done + failed + in-progress rows, total bytes, delete and
     retry actions; add "download all" only if the owner approves the product scope.
  6. After a catalog refresh, surface orphaned downloads (or keep a tombstone) so the user can
     delete them.
- **Dependencies:** owner decision on the downloads surface scope (FUN-08). **Frozen risk:**
  low; existing download tests should remain, add new ones.
- **Required tests:** new downloader instance reconciles a `downloading` row; orphan `.part`
  removed; HTML/zero-length body rejected; retry succeeds after one 5xx; concurrent
  `ensureCatalog` makes one HTTP call; `/downloads` shows total/retry/delete.
- **Acceptance:** no `downloading` row survives a restart without a valid file; no orphan
  `.part`; a failed file is never marked done; downloads are visible and removable from one
  screen; existing download/playback semantics unchanged.

#### REM-03 — Pack install/uninstall atomicity, retry, and progress

- **Covers:** DAT-02, DAT-13, ARC-03, FUN-11 · **Phase:** 1A · **Effort:** L
- **Affected:** `lib/features/library/data/pack_downloader.dart`, `pack_store.dart`,
  `lib/features/library/presentation/library_cubit.dart`, `library_screen.dart`, tests.
- **Root cause:** promote then register; failure handler deletes the already-renamed part;
  uninstall deletes the file first; the multi-request loop has no retry; progress lives in the
  route cubit; the version-aware check is unused.
- **Impact:** one 5xx discards a 114-file install; a DB failure leaves a ghost pack or an
  "installed" row with no file; progress resets to 0 % after leaving the route.
- **Solution:**
  1. Track `promoted`; on a post-promote failure delete the promoted file (or register first
     and roll back the row). Prefer one transaction for row + promote where the filesystem
     allows it; otherwise make both operations idempotent.
  2. Uninstall order: delete index → row → file; treat "row without file" as not installed.
  3. Retry each surah body 2–3 times with jittered backoff; persist per-surah completion or
     write per-surah temp files so an interrupted install can resume.
  4. Move progress to `PackDownloader` (broadcast stream / `ValueListenable` per pack) and have
     `LibraryCubit` mirror it.
  5. Wire `isInstalled(pack.id, pack.version)` into `LibraryCubit` and show an "update"
     affordance for a stale version.
- **Dependencies:** none; REM-02 shares the retry/backoff helper. **Frozen risk:** low.
- **Required tests:** injected DB failure after promote leaves no file/row; uninstall failure
  leaves a deletable row; one 503 then success completes; progress survives route re-entry;
  stale version shows update; install remains single-flight.
- **Acceptance:** no ghost pack or installed row without a file; retry resumes without
  refetching completed surahs; progress survives navigation; store upgrade is visible.

#### REM-04 — Database corruption recovery and seed safety

- **Covers:** DAT-04, DAT-12 · **Phase:** 1A · **Effort:** M
- **Affected:** `lib/core/db/connection.dart`, `app_database.dart`, `content_version.dart`,
  `search_index.dart`, `lib/core/db/tables.dart`, tests.
- **Root cause:** no integrity check; `writeAssetOffUiIsolate` returns when the fixed seed temp
  exists; seed row counts are not validated; open failures are swallowed and the broken
  executor is handed on.
- **Impact:** a damaged SQLite file bricks every screen until app data is cleared; a kill during
  a content seed can revert corrected Quran text and stamp it as current.
- **Solution:**
  1. Run `PRAGMA quick_check` at open; on failure move the file aside
     (`quran_yahdi.sqlite.corrupt-<timestamp>`), re-copy the asset, and surface a one-time
     localized notice.
  2. Use a unique seed temp name or delete any pre-existing seed path before writing.
  3. Validate 114 surahs / 6,236 ayahs (and the search-index stamp) before writing
     `content_version`.
  4. Keep the existing best-effort boot contract: a failed recovery logs and degrades, never
     crashes the first frame.
  5. DAT-12: normalize `prayer_log.day` on write and add a duplicate-day repair/test. Do **not**
     change the primary key in this release; schedule the schema migration as a separate wave.
- **Dependencies:** none for recovery; the `day` schema change needs an owner-approved migration.
- **Required tests:** corrupt file is quarantined and re-copied; stale seed temp is discarded;
  invalid row count does not stamp the new version; normal open path unchanged; duplicate-day
  writer is normalized.
- **Acceptance:** a corrupt DB recovers on next launch with a notice; a stale seed cannot
  revert content; a valid install is byte-for-byte unaffected.

#### REM-05 — Local-state races (tasbih and khatma)

- **Covers:** DAT-05, DAT-06 · **Phase:** 1A · **Effort:** S
- **Affected:** `lib/features/tasbih/presentation/tasbih_cubit.dart`,
  `lib/features/tracker/data/khatma_repository.dart`, tests.
- **Root cause:** `_userMutated = true` before the load completes; khatma uses read-modify-write.
- **Impact:** a fast tap loses a 500-count; overlapping mushaf page changes can move the wird
  pointer backward.
- **Solution:** gate `increment` on a loaded snapshot or merge `stored + tapsSinceOpen`; replace
  the khatma update with `UPDATE ... WHERE ayah_id < ?` and treat 0 affected rows as a no-op.
- **Dependencies:** none. **Frozen risk:** existing tasbih tests await `loaded`; they should stay
  green. `khatma_repository_test` covers sequential max-wins; keep it green.
- **Required tests:** tap-before-hydration preserves the stored count; concurrent `advanceTo`
  calls never decrease the pointer; zero-row update is a no-op.
- **Acceptance:** no count regression on fast open+tap; no backward khatma pointer under
  concurrent writers; existing tests unchanged.

### Phase 1B — Essential workflow correctness (REM-06 … REM-11)

#### REM-06 — Reminder engine, permission, and schedule consistency

- **Covers:** FUN-01, DAT-09, DAT-14 · **Phase:** 1B · **Effort:** L
- **Affected:** `lib/features/notifications/data/reminder_planner.dart`,
  `notifications_binding.dart`, `reminder_settings.dart`, `reminder_scheduling.dart`,
  `lib/features/settings/presentation/settings_cubit.dart`, `lib/main.dart`, `lib/app/app.dart`,
  `android/app/src/main/AndroidManifest.xml`, tests.
- **Root cause:** one fixed prayer id; loop breaks at the first future prayer; no
  `matchDateTimeComponents`; no boot receiver; permission prompt is gated on `azkarEnabled`;
  settings write before re-plan; plan fingerprint is memory-only.
- **Impact:** at most one prayer alarm per cold start; azkar/wird fire once per plan; prayer-only
  users never see the Android 13+ prompt; a failed re-plan leaves UI and storage disagreeing.
- **Solution:**
  1. Schedule every remaining prayer of the day with ids `prayerReminderId + slotIndex` (or a
     stable per-prayer id map), preserving the existing prayer/azkar/wird tap payloads.
  2. Add daily repetition (`DateTimeComponents.time`) for azkar/wird, or re-plan after each
     fire; choose one with the owner.
  3. Re-plan on `AppLifecycleState.resumed`; add a boot receiver or WorkManager path only if the
     owner accepts the Play/battery trade-off.
  4. Call `ensurePermissions()` when **any** reminder toggle is enabled, including prayer; show
     a denied state for the prayer switch.
  5. On a re-plan failure, emit the confirmed setting and log, or roll back the write; never
     leave the switch disagreeing with the DB.
  6. Persist the applied plan fingerprint (settings row) or recompute it from the stored plan.
- **Dependencies:** **frozen-test ruling** for `reminder_planner_test.dart`,
  `notifications_binding_scheduling_test.dart`, `notification_targeted_cancel_test.dart`,
  `reminder_gap_test.dart`, `reminder_notification_copy_test.dart`,
  `prayer_reminder_toggle_test.dart`, `wird_reminder_routing_test.dart`; owner decision on
  boot receiver/exact alarms.
- **Required tests:** planner returns all remaining prayers with unique ids; azkar/wird repeat;
  prayer-only toggle requests permission; denied permission is visible; lifecycle resume
  re-plans; failed re-plan does not desync; device day-boundary test.
- **Acceptance:** 5 prayers can fire across a day without reopening; a prayer-only user is
  prompted; azkar/wird are not one-shot; no `cancelAll`; playback notification survives; the
  targeted-cancel test still proves exactly the planner ids are cancelled.

#### REM-07 — Reader continuity and Home prayer ticker

- **Covers:** FUN-02, FUN-10 · **Phase:** 1B · **Effort:** M
- **Affected:** `lib/features/quran/presentation/reader/reader_cubit.dart`,
  `reader_screen.dart`, `lib/features/home/presentation/home_cubit.dart`, `home_screen.dart`,
  tests.
- **Root cause:** verse list has no visibility observer; Home computes the next prayer once.
- **Impact:** continue-reading never advances in the default mode; Home advertises a passed
  prayer as "next".
- **Solution:** track the first visible ayah in the verse list (throttled) and call the existing
  `saveAyahId`; add a minute ticker or a one-shot timer to `HomeCubit` that re-plans when the
  shown prayer passes.
- **Dependencies:** none. **Frozen risk:** low.
- **Required tests:** scrolling to ayah N persists N; reopening starts there; Home card changes
  after a simulated time jump; no timer after dispose.
- **Acceptance:** continue-reading advances in both modes; Home updates at the boundary;
  no extra DB writes on every scroll pixel.

#### REM-08 — Shared error recovery and bookmark failure

- **Covers:** UX-01, ARC-04 · **Phase:** 1B · **Effort:** M
- **Affected:** `lib/core/widgets/loading_and_error_views.dart`, `error_pane.dart`,
  the 19 `errorPane` call sites, `bookmarks_cubit.dart`, `bookmarks_screen.dart`, tests.
- **Root cause:** shared `ErrorView` has no action; `BookmarksCubit.remove` has no typed catch.
- **Impact:** transient failures dead-end a route (Home unrecoverable); a delete failure becomes
  an unhandled async error.
- **Solution:** add optional `onRetry`/`retryLabel` to `ErrorView` and `errorPane`; wire each
  cubit's existing reload; wrap `remove` in the standard typed catch + `dev.log` and restore/
  mark the row on failure.
- **Dependencies:** none. **Frozen risk:** low; existing error-text tests should stay green.
- **Required tests:** ErrorView renders retry and calls it once; Home recovers after a failed
  load; bookmark delete failure leaves the row and reports/logs.
- **Acceptance:** every non-terminal failed state offers a retry; no unhandled bookmark error;
  no change to successful paths.

#### REM-09 — Playback failure stop and app-wide mini player

- **Covers:** ARC-01, ARC-02 · **Phase:** 1B · **Effort:** M
- **Affected:** `lib/features/recitation/presentation/playback/playback_cubit.dart`,
  `mini_player_bar.dart`, `lib/app/app.dart` or a shell wrapper, `lib/app/router.dart`,
  `lib/app/di/injector.dart`, tests.
- **Root cause:** failure path emits without stopping the service; mini player is mounted on
  two screens; optional audio cubits are resolved unconditionally.
- **Impact:** failed state while old audio plays; no in-app controls on 18 routes; degraded
  boot can crash a primary route.
- **Solution:** stop (or preserve the prior playing state) before emitting `failed`; host one
  mini player in `MaterialApp.builder`/the app shell above system insets; register the audio
  cubits with a null-safe seam or guard `/reader`/`/reciter` like `/library`.
- **Dependencies:** none. **Frozen risk:** low; `mini_player_bar_test` should stay green.
- **Required tests:** failed lookup stops the service; mini player appears on Home/Settings;
  no duplicate player; degraded boot navigates instead of throwing.
- **Acceptance:** UI and audio never disagree; controls are reachable on every route; insets and
  bottom sheets are respected; no double player.

#### REM-10 — Qibla heading accuracy

- **Covers:** FUN-03 · **Phase:** 1B · **Effort:** M
- **Affected:** `lib/features/qibla/data/heading_service.dart`, `qibla_cubit.dart`,
  `qibla_screen.dart`, tests.
- **Root cause:** `atan2(-x, y)` on raw magnetometer samples; no tilt compensation or accuracy.
- **Impact:** the needle is wrong when the phone is held upright; no warning.
- **Solution:** use a fused rotation-vector/orientation stream available in `sensors_plus`
  (no new dependency); keep the raw magnetometer as fallback; expose an accuracy/calibration
  hint; animate the shortest signed delta.
- **Dependencies:** device sensor verification. **Frozen risk:** low.
- **Required tests:** pure heading math with tilted samples; no-sensor fallback; shortest-delta
  animation; calibration state.
- **Acceptance:** dial is correct in flat and upright postures within an agreed tolerance;
  unavailable/denied sensor is honest; no infinite rebind loop.

#### REM-11 — Zakat validation, persistence, and formatting

- **Covers:** FUN-04 · **Phase:** 1B · **Effort:** M
- **Affected:** `lib/features/zakat/presentation/zakat_screen.dart`, `zakat_cubit.dart`,
  `zakat_state.dart`, `lib/features/zakat/data/zakat_calculator.dart`, settings persistence,
  tests.
- **Root cause:** no input formatters, inline errors, or persistence; `parseDecimal` collapses
  invalid text to 0.
- **Impact:** a typo can show "no zakat due"; inputs are lost on navigation.
- **Solution:** `FilteringTextInputFormatter` for Arabic/Western digits and separators; inline
  `errorText` when non-empty input parses to 0; persist the input snapshot under a settings key
  (owner decision); format amounts with grouping/currency and Arabic-Indic consistency; add a
  reset action.
- **Dependencies:** owner decision on persistence/retention. **Frozen risk:** existing zakat
  tests may pin text; add new cases, do not rewrite.
- **Required tests:** letters/invalid separators show an error and do not produce a verdict;
  negative values rejected; decimal + Arabic digits parse; persistence round-trip; reset clears.
- **Acceptance:** no silent zero for invalid input; user can recover; the verdict is visibly
  tied to valid fields; existing math tests stay green.

### Phase 2 — Release pipeline, signing, and store compliance (REM-12 … REM-18)

#### REM-12 — Signed artifact, version bump, and runbook

- **Covers:** REL-01, REL-09, REL-10 · **Phase:** 2 · **Effort:** M
- **Affected:** `pubspec.yaml`, `docs/store/play-console-setup.md`, `README.md`,
  `tools/device_smoke.ps1`, release checklist.
- **Root cause:** verified AAB predates HEAD; versionCode 3; runbook uses bash syntax and a
  debug split-APK command; smoke only installs debug.
- **Impact:** stale/incorrect binary or Play rejection; screenshots mismatch.
- **Solution:** after Phase 1 code is final, bump to `1.0.0+4` (or the next code from the
  console), rebuild with `PUBLISH_RELEASE=true`, record SHA-256/apksigner/jarsigner/version,
  run `zipalign -c -P 16`, smoke the **release-signed** APK, re-shoot changed screens, update
  the runbook to PowerShell and `--release`.
- **Dependencies:** Phase 1A/1B; licensing (REM-18); console highest versionCode.
- **Required tests/evidence:** build log, signature output, versionCode, 16 KB check, install/
  boot on device, screenshot diff.
- **Acceptance:** the recorded artifact is built from the final HEAD and is the one smoked;
  runbook commands work verbatim in PowerShell 5.1.

#### REM-13 — CI gates, action pinning, and generated-code drift

- **Covers:** REL-02, SEC-04, TST-09 · **Phase:** 2 · **Effort:** M
- **Affected:** `.github/workflows/ci.yml`, `android/app/build.gradle`.
- **Root cause:** release job has no `needs`; no `PUBLISH_RELEASE`; debug-signed artifacts named
  `app-release-*`; mutable action tags; no permissions; codegen drift unchecked.
- **Impact:** red suite can upload a publishable-looking bundle; supply-chain exposure; stale
  generated code.
- **Solution:** `needs: [analyze-test]`; either inject a keystore + `PUBLISH_RELEASE=true` or
  rename to `debug-signed-*` and drop the AAB upload; SHA-pin actions; `permissions: contents:
  read`; `git diff --exit-code` after codegen; add `integration_test` to the format gate.
- **Dependencies:** REM-14 signing decision. **Frozen risk:** none.
- **Required tests:** workflow dry run; a red analyze/test must block the artifact job; artifact
  names/contents inspected.
- **Acceptance:** no artifact is uploaded when tests fail; no store-sounding debug artifact; CI
  tree is clean after codegen.

#### REM-14 — Build hardening, reproducibility, and environment pinning

- **Covers:** REL-05, REL-07, REL-11, REL-13, REL-15, REL-16, SEC-05, SEC-07 · **Phase:** 2 ·
  **Effort:** L
- **Affected:** `android/app/build.gradle`, `android/build.gradle`, `android/gradle.properties`,
  `android/gradle/wrapper/*`, `android/.gitignore`, `.fvmrc`, `settings.gradle`, tests.
- **Root cause:** no R8/shrink/ProGuard/obfuscation; SDK inherited; wrapper ignored; debug shares
  app id; AGP 9 escape hatches; one compile-time environment.
- **Impact:** large artifact, recoverable symbols, SDK drift, irreproducible clean clone,
  debug/store coexistence.
- **Solution:** enable `minifyEnabled`/`shrinkResources`/ProGuard with plugin keep rules; add
  `--obfuscate --split-debug-info` and archive symbols; pin `compileSdk/targetSdk/minSdk` and
  add `.fvmrc`; commit the wrapper + `distributionSha256Sum`; add `.debug` suffix and update the
  smoke script; document the AGP 10 migration; add a `--dart-define` endpoint seam only if the
  owner wants staging.
- **Dependencies:** REM-13; device smoke for R8/plugins. **Frozen risk:** none.
- **Required tests:** release build with R8; plugin smoke (audio, notifications, picker, share);
  size before/after; `apksigner`; debug variant installs beside release.
- **Acceptance:** store build is minified/obfuscated with archived symbols; SDK levels are
  explicit; clean clone builds; debug and release coexist.

#### REM-15 — App Links certificate under Play Signing (external)

- **Covers:** REL-04 · **Phase:** 2 · **Effort:** S · **Owner:** Play Console access
- **Affected:** `web/public/.well-known/assetlinks.json`, `AndroidManifest.xml`.
- **Root cause:** only the upload-cert fingerprint is pinned.
- **Impact:** App Links fail on Play-installed builds.
- **Solution:** after the first upload, add the Play app-signing SHA-256 alongside the upload
  cert; redeploy; verify with `adb shell pm get-app-links` and a cold link.
- **Dependencies:** REM-12 upload; Play Console access.
- **Required tests:** both fingerprints are present in `assetlinks.json`; `adb shell pm
  get-app-links` reports `verified`; a cold `https://quranyahdi.pages.dev/...` link opens the
  app on a Play-signed install.
- **Acceptance:** both certs present; `autoVerify` passes; `https://quranyahdi.pages.dev/...`
  opens the app on a Play-signed install.

#### REM-16 — Store assets, label, and dead input

- **Covers:** REL-06, REL-12, REL-14 · **Phase:** 2 · **Effort:** M
- **Affected:** `android/app/src/main/res/*`, `values-v31/styles.xml`, `pubspec.yaml`,
  `AndroidManifest.xml`, `assets/json/hafs_smart_v8.json`.
- **Root cause:** no adaptive/monochrome icon; v31 splash background missing; hard-coded Arabic
  label; 7.4 MB build-only JSON tracked under assets.
- **Impact:** legacy icon/splash; English launcher name; repo bloat.
- **Solution:** adaptive foreground/background + monochrome; `windowSplashScreenBackground`;
  `@string/app_name` + `values-en` + `locales_config.xml`; move the JSON under `tools/` or
  delete it after confirming the DB generator source.
- **Dependencies:** visual review. **Required tests/evidence:** `aapt dump badging`, icon
  previews, splash on API 31+, locale switch.
- **Acceptance:** adaptive icon renders on all OEMs; branded splash on Android 12+; launcher
  label localizes; no shipped-asset regression.

#### REM-17 — Release operations: monitoring, rollback, staged rollout

- **Covers:** REL-08 · **Phase:** 2 · **Effort:** S · **Owner decision**
- **Affected:** `docs/store/play-console-setup.md`, `tools/device_smoke.ps1`.
- **Root cause:** no crash channel/rollback/staged rollout.
- **Impact:** a regression is invisible until reviews/vitals; only remedy is halting rollout.
- **Solution:** choose privacy-first Play vitals only or a crash channel; write a one-page
  rollback/staged-rollout policy (e.g. 5→20→50→100 %), an internal-track checklist, and a
  post-release watch window.
- **Dependencies:** owner monitoring/privacy decision.
- **Required tests:** a dry-run rollback on the internal track; a staged-rollout checklist with
  named halt criteria; a crash-signal review after 24 h.
- **Acceptance:** runbook covers monitoring, rollback, and rollout; owner signs off.

#### REM-18 — Licensing closure (external)

- **Covers:** REL-03 · **Phase:** 2 · **Effort:** external
- **Affected:** `docs/store/licensing-matrix.md`, `docs/store/play-console-setup.md`,
  `PRIVACY*.md`, `assets/fonts/*`, `assets/data/library_catalog.json`.
- **Root cause:** font/tafsir/mp3quran terms remain `OPEN-FOR-OWNER`.
- **Impact:** takedown/IP risk.
- **Solution:** obtain written redistribution terms for the fonts; confirm quranenc text terms;
  confirm mp3quran listing terms; otherwise swap/withdraw the asset.
- **Dependencies:** external legal/publisher input.
- **Required tests:** a licensing-matrix review against the actual shipped catalog; a written
  source for each GREEN item; a signed owner decision for every remaining FLAG.
- **Acceptance:** every shipped item is GREEN with a recorded source; legal sign-off; matrix
  matches the shipped catalog.

### Phase 3 — Security and resilience hardening (REM-19 … REM-22)

#### REM-19 — Pack redirect validation

- **Covers:** SEC-01 · **Phase:** 3 · **Effort:** S
- **Affected:** `lib/features/library/data/pack_downloader.dart`; tests.
- **Root cause:** Dio follows redirects; only the initial scheme is checked.
- **Impact:** a redirect can fan a pack request to any host; sha256 still protects content.
- **Solution:** `followRedirects: false` + manual hop chain with per-hop `https` and
  `cdn.jsdelivr.net` allowlist; reuse the audio downloader helper; cap hops.
- **Dependencies:** REM-03 (shared pack download path).
- **Required tests:** 301/302 to a foreign host/http rejected; 3-hop allowed host succeeds; no
  `Location` fails closed.
- **Acceptance:** no pack byte is read from an unvalidated hop; existing pack install passes.

#### REM-20 — Permission and data-extraction scope

- **Covers:** SEC-02, SEC-03 · **Phase:** 3 · **Effort:** S
- **Affected:** `AndroidManifest.xml`, `res/xml/data_extraction_rules.xml`.
- **Root cause:** unused FINE; DB in `file` domain not excluded.
- **Impact:** over-broad permission; user DB rides D2D transfer.
- **Solution:** drop `ACCESS_FINE_LOCATION`; add `<exclude domain="file" path="."/>` (and
  `root`/`external` if used); add `usesCleartextTraffic="false"` explicitly for clarity.
- **Dependencies:** none.
- **Required tests:** merged manifest contains no FINE location; the data-extraction rule
  excludes the `file` domain; cleartext is explicitly false.
- **Evidence:** merged manifest + data-extraction rule inspection.
- **Acceptance:** only coarse location is requested; the DB is excluded from D2D; no cleartext
  allowance.

#### REM-21 — Location permission denial path

- **Covers:** DAT-10 · **Phase:** 3 · **Effort:** S
- **Affected:** `lib/features/prayer/data/location_service.dart`,
  `city_picker_cubit.dart`/screen.
- **Root cause:** `deniedForever` is treated like `denied` and opens the system toggle.
- **Impact:** "Locate me" is a permanent dead end.
- **Solution:** return a tri-state; call `Geolocator.openAppSettings()` for `deniedForever` and
  `openLocationSettings()` only for services-off; keep the manual city picker as fallback.
- **Dependencies:** none.
- **Required tests:** denied vs deniedForever; services-off; grant after settings.
- **Acceptance:** each denial state has a working recovery; manual city selection always works.

#### REM-22 — Share, deep-link, and AyahSheet robustness

- **Covers:** ARC-05, ARC-07, ARC-08 · **Phase:** 3 · **Effort:** S-M
- **Affected:** `reader_screen.dart`, `ayah_sheet_cubit.dart`,
  `route_cubit_scope.dart`/sheet state, `main.dart`.
- **Root cause:** share future discarded; I/O in constructor; cold link resolved after plugin
  init; no stream error/cancel.
- **Impact:** unhandled `PlatformException`; load outside mount lifecycle; late navigation
  overrides the user; uncaught stream error.
- **Solution:** `unawaited(... .catchError(log))`; move sheet load to `start()`; resolve
  `getInitialLink()` before `runApp` and use it as `initialLocation`; add `onError` and cancel
  the subscription on app dispose.
- **Dependencies:** none.
- **Required tests:** share failure is logged; sheet load starts once; cold link lands before
  Home; invalid link no-ops; stream error is logged.
- **Acceptance:** no unhandled async error; no late route override; listener is bounded.

### Phase 4 — Accessibility, localization, and UX (REM-23 … REM-27)

#### REM-23 — RTL chevrons and system back

- **Covers:** UX-04, UX-05 · **Phase:** 4 · **Effort:** S
- **Affected:** `surah_index_screen.dart`, `hijri_screen.dart`, `azkar_screen.dart`,
  `asma_screen.dart`, tests.
- **Root cause:** manual RTL icon choice on already-mirrored icons; sub-states are not routes.
- **Impact:** backward chevrons; back exits the feature.
- **Solution:** always use `chevron_right` and let `Directionality` mirror; fix Hijri button
  order; add `PopScope` for reciting and the Asma overlay.
- **Dependencies:** none.
- **Required tests:** RTL golden/geometry; back at reciting stays in azkar; back with sheet
  closes it.
- **Acceptance:** chevrons point forward in AR/EN; system back never loses the feature state.

#### REM-24 — Contrast, semantics, and typography tokens

- **Covers:** UX-02, UX-08, UX-09, UX-15 · **Phase:** 4 · **Effort:** M-L
- **Affected:** `app_theme.dart`, `app_colors.dart`, `tasbih_screen.dart`,
  `zakat_screen.dart`, `duas_screen.dart`, `reciter_surahs_screen.dart`, `azkar_screen.dart`,
  `hijri_screen.dart`, `pubspec.yaml`, tests.
- **Root cause:** raw gold as text; whole-card opacity; missing 500/600 font weights; no
  `textTheme`; no live-region semantics.
- **Impact:** unreadable states; flat hierarchy; screen-reader silence.
- **Solution:** use `AppTheme.goldText` for text and primary/onPrimary for SnackBars; dim only
  the surface/check; add Cairo SemiBold or map w500/w600→700; define an M3 textTheme; add
  `Semantics(value:, liveRegion:)` to tasbih/azkar counters; raise Hijri Gregorian text.
- **Dependencies:** visual review of the resulting palette/type scale.
- **Required tests:** contrast ratios; textScale 2.0; semantics labels; golden/theme.
- **Acceptance:** no text below 4.5:1 (or 3:1 large); counters announce; type scale is tokenized.

#### REM-25 — Arabic plurals and time formatting

- **Covers:** UX-03, UX-13 · **Phase:** 4 · **Effort:** M
- **Affected:** `lib/l10n/app_ar.arb`, `app_en.arb`, generated l10n,
  `arabic_numbers.dart`, `settings_screen.dart`, `player_sheet.dart`, tests.
- **Root cause:** simple interpolation for counts; always 24h; `m:ss` for long audio; dead key.
- **Impact:** "٢ ذكر", "٣ سورة", "٥ يوم"; picker/list mismatch; "97:20".
- **Solution:** convert count keys to ICU `plural` with zero/one/two/few/many/other; mirror EN;
  honor `alwaysUse24HourFormat`; use `h:mm:ss` when hours > 0; delete dead keys; add a rate
  string using one digit system.
- **Dependencies:** **frozen-test ruling** for `azkar_screen_test.dart:51`,
  `azkar_textscale_probe_test.dart:62`, `backup_section_test.dart:157`,
  `tracker_quality_probe_test.dart:95`, `tracker_screen_test.dart:46`,
  `wird_card_test.dart:197`.
- **Required tests:** plural categories 0/1/2/3/11/100; EN parity; 12/24h; duration > 1h.
- **Acceptance:** grammatical Arabic for all counts; AR/EN key parity preserved; no test edits
  beyond the approved list.

#### REM-26 — Confirmations, empty states, and labels

- **Covers:** UX-06, UX-11, UX-12 · **Phase:** 4 · **Effort:** S-M
- **Affected:** `bookmarks_screen.dart`/cubit, `reciters_screen.dart`,
  `reciter_surahs_screen.dart`, `azkar_cubit`/screen (target reset), `tracker_screen.dart`,
  ARB, tests.
- **Root cause:** one-tap delete; raw empty text; wrong tooltip/default state; silent target
  reset.
- **Impact:** accidental data loss; instructions point nowhere; TalkBack hears the wrong action.
- **Solution:** SnackBar undo for bookmark delete; `EmptyState` with refresh action; new ARB
  key for "set as default"; filled/outlined star + `Semantics(toggled:)`; confirm target change
  when count > 0; confirm "new khatma".
- **Dependencies:** none.
- **Required tests:** undo restores; empty action calls refresh; toggled semantics; confirm path.
- **Acceptance:** destructive actions are reversible or confirmed; every empty state has an
  on-screen action; labels match actions.

#### REM-27 — Text-scale and landscape layouts

- **Covers:** UX-07, UX-10, UX-14 · **Phase:** 4 · **Effort:** M
- **Affected:** `tasbih_screen.dart`, `reciter_surahs_screen.dart`, `hadith_screen.dart`,
  `home_screen.dart`, `asma_screen.dart`, tests.
- **Root cause:** fixed-height column/dial; two-line appbar; fixed 3-column grids.
- **Impact:** overflow in landscape/split-screen; clipped titles; ellipsized labels.
- **Solution:** scrollable/LayoutBuilder dial with bottom inset; single-line title/subtitle in
  body; `SliverGridDelegateWithMaxCrossAxisExtent`; allow 3 lines.
- **Dependencies:** none.
- **Required tests:** 320×640, 360×800, landscape, textScale 2.0.
- **Acceptance:** no overflow banner; all labels readable; dial remains usable.

### Phase 5 — Test infrastructure and CI enforcement (REM-28 … REM-29)

#### REM-28 — Integration and wiring tests in CI

- **Covers:** TST-01, TST-03, TST-04, TST-05, ARC-09 · **Phase:** 5 · **Effort:** L
- **Affected:** `integration_test/*`, `.github/workflows/ci.yml`, test helpers.
- **Root cause:** CI runs `test/` only; search tap, deep link, notification tap, player sheet
  are untested.
- **Impact:** the only tests that boot the real app are decorative.
- **Solution:** add journeys: search→tap→reader exact ayah; deep link cold/warm; notification
  tap cold/warm; player sheet seek/stop/pop; backup round-trip; download kill/restart. Add an
  emulator job (`android-emulator-runner`) and a signed-release smoke job.
- **Dependencies:** Phase 1 code stable; emulator CI decision.
- **Required tests:** the journeys themselves; CI must fail on a deliberately broken route.
- **Acceptance:** integration job green on a clean run and red on a planted wiring break.

#### REM-29 — Coverage baseline and test quality

- **Covers:** TST-02, TST-06, TST-07, TST-08 · **Phase:** 5 · **Effort:** M
- **Affected:** `ci.yml`, `coverage/` generation, `test/*`.
- **Root cause:** stale coverage; no threshold; real-clock tests; weak tests.
- **Impact:** no quality bar; flaky CI; false confidence.
- **Solution:** `flutter test --coverage` at HEAD, record the number, add a ratchet threshold;
  inject fixed clocks; replace `page_contract_test` with a real paged source; strengthen
  `smoke_test` to assert Home; expand `router_test` to all 20 routes.
- **Dependencies:** **frozen-test ruling** to modify `page_contract_test`, `smoke_test`,
  `router_test`, `prayer_log_repository_test`, `tracker_cubit_test`.
- **Required tests:** coverage report; deterministic clock; router/tile assertions.
- **Acceptance:** coverage is measured and gated; no time-bound flake; weak tests replaced with
  behavior-bearing ones.

### Phase 6 — Performance and feature completeness (REM-30 … REM-32)

#### REM-30 — Pack/boot/tasbih/font performance

- **Covers:** PERF-01, PERF-02, PERF-03, PERF-07 · **Phase:** 6 · **Effort:** L
- **Affected:** `pack_reader.dart`, `pack_downloader.dart`, `connection.dart`,
  `home_cubit.dart`, `tasbih_cubit.dart`, `main.dart`/`app_theme.dart`, tests.
- **Root cause:** whole-pack parse per surah; serialized boot queries; per-tap write; no font
  warm-up.
- **Impact:** spinner per surah; cold-start latency; flash-write amplification.
- **Solution:** per-surah index at install (new table, migration) or full-pack byte-budgeted
  cache; settings snapshot query; debounce tasbih writes + flush on pause; warm Quran fonts
  behind the first frame.
- **Dependencies:** schema migration approval; post-launch measurement.
- **Required tests:** parse count per surah; boot query count; write count per 100 taps;
  font-load timing.
- **Acceptance:** measured reduction with no behavior change; migration tested.

#### REM-31 — Sensor, ticker, and list performance

- **Covers:** PERF-05, PERF-06, PERF-08, PERF-09, PERF-10 · **Phase:** 6 · **Effort:** M
- **Affected:** `qibla_screen/cubit`, `prayer_times_screen/cubit`, `bookmarks_cubit`,
  `reader_screen`, `tracker_cubit`, `prayer_log_repository`, tests.
- **Root cause:** sensor for route lifetime; 1 Hz ticker; page re-mapping; full span rebuild;
  six queries per toggle.
- **Impact:** battery drain; jank; slow toggles.
- **Solution:** RouteAware sensor pause/resume + sampling period; minute-boundary timer; cache
  `Verse` objects; memoize spans; local toggle + narrower query.
- **Dependencies:** none (post-launch; profiler evidence).
- **Required tests:** pause on push, resume on pop; emission count per minute; frame/profiling
  evidence.
- **Acceptance:** measured improvement; no missed ticks; no stale state.

#### REM-32 — Feature completeness (post-launch scope)

- **Covers:** FUN-05, FUN-06, FUN-07, FUN-12, FUN-13 · **Phase:** 6 · **Effort:** L
- **Affected:** reader, hadith, tracker, azkar, tasbih, library; tests.
- **Root cause:** product scope gaps, not defects.
- **Impact:** missing juz/sajda/prev-next/font size; unsearchable hadith; today-only tracker;
  ephemeral azkar counters; no dhikr text.
- **Solution:** add juz index, sajda badge, prev/next, persisted font scale/mode; hadith
  search/TOC; tracker day navigation; persisted azkar counters + reset; tasbih phrase list and
  target clamp.
- **Dependencies:** owner product approval per feature.
- **Required tests:** each feature's acceptance path; no regression in existing
  reader/hadith/tracker.
- **Acceptance:** each feature is explicitly accepted by the owner; no release blocker is
  re-opened by these additions.

### Phase 7 — External decisions and deferred migration

No code is scheduled here until the owner decides. It contains:
- licensing (REM-18), Play signing (REM-15), crash monitoring (REM-17), iOS scope, English
  locale activation, downloads scope, zakat persistence, reminder architecture, pack-index
  migration, and the prayer-log date-key migration.
- **DoD:** decisions recorded in the campaign ledger; no open question blocks Phase 1/2.

---

## 5. Dependency map

| Task | Depends on | Why | Unblocks |
|---|---|---|---|
| REM-01 | Phase 0 decisions | Export retention/size policy needs an owner ruling | REM-12 |
| REM-02 | Phase 0 download-scope decision | Global queue vs reconciliation-only changes the UI work | REM-12 |
| REM-03 | REM-02 helper | Shares retry/backoff and downloader seam | REM-12 |
| REM-04 | Phase 0 migration decision for DAT-12 | Avoid a schema change in the recovery release | REM-12 |
| REM-05 | none | Pure local-state fixes | REM-12 |
| REM-06 | Phase 0 frozen-test ruling; reminder architecture decision | Existing tests pin one alarm/three cancels | REM-12 |
| REM-07 | none | Reader/Home only | REM-12 |
| REM-08 | none | Shared widget + one cubit | REM-12 |
| REM-09 | none | Playback + shell | REM-12 |
| REM-10 | Device sensor check | Fused orientation availability | REM-12 |
| REM-11 | Zakat persistence decision | Adds a settings key | REM-12 |
| REM-12 | REM-01…REM-11, REL-03, console versionCode | Artifact must include final code and be legally shippable | REM-15, store upload |
| REM-13 | REM-12 signing decision | Keystore-in-CI vs debug artifact rename | REM-14 |
| REM-14 | REM-13; device smoke | R8/plugins and CI must exist first | REM-12 |
| REM-15 | REM-12 first upload; Play Console | Needs the Play signing cert | Live App Links |
| REM-16 | visual review | Icon/splash/label assets | REM-12 store listing |
| REM-17 | owner monitoring decision | Privacy-first choice | Release operations |
| REM-18 | external legal input | Cannot be coded | REM-12 |
| REM-19 | REM-03 | Reuses the pack download path | Security sign-off |
| REM-20 | none | Manifest/rules only | Security sign-off |
| REM-21 | none | Location path | Security sign-off |
| REM-22 | none | Share/link/sheet | Security sign-off |
| REM-23 | none | RTL/back | Phase 4 gate |
| REM-24 | visual review | Theme/semantics | Phase 4 gate |
| REM-25 | Phase 0 frozen-test ruling; ARB parity | String-pinned tests | Phase 4 gate |
| REM-26 | none | Confirmations/labels | Phase 4 gate |
| REM-27 | none | Layouts | Phase 4 gate |
| REM-28 | REM-01…REM-11 stable | Journeys need stable flows | REM-12 final smoke |
| REM-29 | Phase 0 test-edit ruling | Weak tests must be replaced | REM-28 |
| REM-30 | REM-03; migration approval | Pack format/index change | Post-launch |
| REM-31 | none | Performance only | Post-launch |
| REM-32 | owner product approval | Feature scope | Post-launch |

**Critical path:** Phase 0 → REM-01/02/03/04/05 → REM-06 → REM-12 → REM-13/14 → REM-15 →
upload. REM-18 runs in parallel from day 1.

---

## 6. Required tests

### 6.1 Unit tests (new or extended)

| Area | Required cases |
|---|---|
| Reminders | All remaining prayers get unique ids; sunrise skipped; tomorrow fallback; daily repeat; plan fingerprint persisted; permission policy for prayer; disabled toggles; unknown payload |
| Backup | `skippedEntries` surfaced; threshold fail-closed; bookmark 0/6237 skipped; khatma `targetPages <= 0`/`ayahId` out of range; whitelist includes `prayer_reminder_enabled`; export size; temp file lifetime |
| Downloads | Reconcile `downloading`; orphan `.part`; HTML/zero-length/truncated body; retry after 5xx; single-flight catalog; catalog refresh orphan |
| Packs | Promote→register failure; uninstall failure; 503 then success; progress survives route; version update |
| DB | `quick_check` failure recovery; stale seed temp; invalid row count; duplicate prayer day |
| Tasbih/Khatma | Tap before hydrate; concurrent `advanceTo`; zero-row update |
| Qibla | Tilted heading; no sensor; shortest delta |
| Zakat | Invalid chars; negative; Arabic digits; decimal; persistence; reset |

### 6.2 Widget tests

- `ErrorView` retry fires once; Home recovers.
- Mini player visible on Home/Settings; no duplicate; stop resets.
- RTL chevron geometry; system back at reciting/sheet.
- Arabic plural strings for 0/1/2/3/11/100; EN parity.
- Contrast tokens; textScale 2.0; 320/360-wide; landscape.
- Zakat inline errors; downloads screen states.
- Semantics labels for tasbih/azkar/Hijri.

### 6.3 Integration / device tests

| Journey | Evidence |
|---|---|
| Search → tap result → reader exact ayah | Emulator/device; route params |
| Deep link cold + warm | `adb shell am start -a android.intent.action.VIEW ...` |
| Notification tap cold + warm | Real notification, route check |
| Player sheet seek/stop/pop | Widget + device |
| Backup export → share → import → restart | Device file picker/share |
| Download kill/restart | Force-stop mid-download; reopen |
| 5 prayers across a day boundary | Device clock/emulator; logcat notifications |
| Prayer-only permission prompt | Fresh install, enable prayer only |
| Qibla upright/flat | Device sensor |
| Signed release install | `adb install` on internal track |

### 6.4 Frozen tests requiring owner ruling before any edit

| Test | Why it blocks |
|---|---|
| `test/notifications_binding_scheduling_test.dart` | Pins exactly 3 cancels + one schedule; per-prayer ids change the count |
| `test/notification_targeted_cancel_test.dart` | Pins the exact 3-id cancel set |
| `test/reminder_planner_test.dart` | `plan.single` assumes one prayer |
| `test/reminder_gap_test.dart` | `plan.single`/`prayerReminderId` |
| `test/reminder_notification_copy_test.dart` | `singleWhere(prayerReminderId)` |
| `test/prayer_reminder_toggle_test.dart` | `prayerReminderId` |
| `test/wird_reminder_routing_test.dart` | Exact id set |
| `test/azkar_screen_test.dart` | Pins `'٢ ذكر'` |
| `test/azkar_textscale_probe_test.dart` | Pins `'٢ ذكر'` |
| `test/backup_section_test.dart` | Pins `'٢ يوم عبادات'` |
| `test/tracker_quality_probe_test.dart` | Pins `'سلسلة ١ يوم'` |
| `test/tracker_screen_test.dart` | Pins `'سلسلة ١ يوم'` |
| `test/wird_card_test.dart` | Pins `'باقي نحو ١٢١ يوم'` |
| `test/page_contract_test.dart`, `test/smoke_test.dart`, `test/router_test.dart`, `test/prayer_log_repository_test.dart`, `test/tracker_cubit_test.dart` | Test-quality/clock edits |

**Rule:** add new test files for new behavior. Do not rewrite a pinned test until the owner
approves that exact file. If a fix cannot satisfy a pin without an edit, STOP and report.

---

## 7. Acceptance criteria

### 7.1 Global gates (every task)

| Gate | Requirement |
|---|---|
| G1 | `flutter analyze` = 0 issues |
| G2 | `flutter test` = all tests pass; record exact count; baseline is 828 + new tests |
| G3 | `dart format --output=none --set-exit-if-changed lib test tools` = 0 changed |
| G4 | No existing test edited without the approved frozen-test list |
| G5 | No new dependency; no schema change without an approved migration |
| G6 | No secret, keystore, `.env`, or `key.properties` in the diff |
| G7 | Explicit-pathspec commit; `git status` shows only intended files |
| G8 | `docs/campaign-ledger.md` close-out appended after the task (PM) |
| G9 | No regression in the 828 baseline; behavior changes are covered by new tests |
| G10 | No push; push is a separate owner-GO window |

### 7.2 Phase-level acceptance

- **1A:** no silent restore loss; no stuck download; no ghost pack; corrupt DB recovers; tasbih/
  khatma races closed; all new tests pass; device kill/restart evidence.
- **1B:** 5 prayers fire across a day; permission prompt for prayer-only; continue-reading
  advances; every failed screen retries; playback failure stops; qibla correct flat/upright;
  zakat refuses invalid input.
- **2:** signed AAB from final HEAD; versionCode bumped; CI gates artifacts; R8/obfuscation;
  App Links verified; licensing GREEN; store checklist complete.
- **3:** pack redirects rejected; only coarse location; DB excluded from D2D; denial recovery;
  no unhandled share/link errors.
- **4:** contrast ≥4.5:1 (or 3:1 large); Arabic plurals grammatical; RTL correct; system back
  preserves state; textScale 2.0/landscape no overflow.
- **5:** integration job green; coverage baseline + threshold; deterministic clocks; weak tests
  replaced.
- **6:** measured improvements with before/after evidence; feature acceptance by owner.

---

## 8. Unresolved questions

| # | Question | Owner | Blocks | Default if unanswered |
|---:|---|---|---|---|
| 1 | Do we have written redistribution terms for HafsSmart/me_quran, quranenc Siraj, and mp3quran listing? | Owner/legal | REM-12 upload, REM-18 | Do not upload; keep internal |
| 2 | Is Play App Signing enabled, and what is the app-signing SHA-256? | Owner/console | REM-15 | Keep only the upload cert; App Links unverified |
| 3 | What is the highest versionCode uploaded on any track? | Owner/console | REM-12 | Use `+4`; verify before upload |
| 4 | Approve the frozen-test edits in §6.4? | Owner | REM-06, REM-25, REM-29 | Stop those tasks; do not edit |
| 5 | Reminder architecture: boot receiver/WorkManager vs. resume re-plan; exact vs. inexact alarms? | Owner/engineering | REM-06 | Resume re-plan + existing exact/inexact fallback |
| 6 | Downloads: full queue + download-all, or reconciliation + a simple list? | Owner/product | REM-02 | Reconciliation + a done/failed list (no download-all) |
| 7 | Persist zakat inputs? | Owner/product/privacy | REM-11 | Persist locally under a settings key; no sync |
| 8 | Crash monitoring: Play vitals only or a privacy-first crash channel? | Owner | REM-17 | Play vitals + rollback doc |
| 9 | Activate English locale, or keep Arabic-only? | Owner/product | REM-25 scope | Keep `ar` only; do not delete EN ARB |
| 10 | Is iOS in scope for this release? | Owner | Phase 7 | No; separate project |
| 11 | Do we accept a pack per-surah index migration? | Owner/engineering | REM-30 | Full-pack cache first; migration later |
| 12 | Do we add juz/sajda/font size/hadith search/tracker backfill? | Owner/product | REM-32 | Post-launch backlog; not release blockers |
| 13 | Do we add a `--dart-define` staging endpoint? | Owner/engineering | REM-14 | Keep one production config; document it |
| 14 | Does the device support fused orientation, and what is the qibla tolerance? | Engineering/device | REM-10 | Use fused if available; fallback to raw + warning |

---

## 9. Risks and limitations

### 9.1 Execution risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Frozen-test rule blocks reminder/plural fixes | High | High | Phase 0 ruling; new test files; stop if refused |
| Reminder changes clear the playback notification | Med | High | Keep targeted cancels; never `cancelAll`; assert in test |
| Download reconciliation deletes a valid file | Med | High | Only delete `.part`/status rows; verify target size first |
| DB recovery quarantines a good DB | Low | High | `quick_check` only; move aside, never delete; one-time notice |
| Pack index migration corrupts installs | Med | High | Separate migration wave; schema dump; rollback to file cache |
| R8 breaks a plugin | Med | High | Keep rules; device smoke; disable per-plugin if needed |
| ARB plural changes break pinned strings | High | Med | Approved test edits; parity test; staged commit |
| App Links cert change misses a build variant | Med | Med | Add both certs; verify Play-signed install |
| CI keystore injection leaks a secret | Low | High | GitHub secrets; `permissions`; no logs; owner review |
| Debug suffix breaks the smoke script | High | Low | Update `tools/device_smoke.ps1` in the same task |
| Scope creep from feature gaps | Med | Med | REM-32 is post-launch and owner-approved |

### 9.2 Planning limitations

- No build, device, store console, CVE scan, or runtime profile was available in this session.
  Every release/device acceptance item remains external.
- The plan assumes the same Flutter 3.47.5 / Dart 3.13.4 toolchain. A toolchain bump is a
  separate change and must update AGENTS.md and CI together.
- The plan assumes no backend; if a backend is added later, the security/data-integrity sections
  need a new audit.
- The report's line numbers are at `d39c1f7`. The executor must re-read each file; a moved line
  is not a moved defect.
- The plan does not estimate calendar time; effort labels are relative (S/M/L), not promises.

### 9.3 Out of scope

iOS implementation, a web app rewrite, new dependencies, payments/subscriptions, accounts,
analytics, and a backend are out of scope. The existing architecture is not redesigned.

---

## 10. Definition of Done per phase

### Phase 0 — Baseline and decisions
- [ ] HEAD/porcelain/baseline gates recorded.
- [ ] All §8 decisions answered or explicitly deferred with a named owner.
- [ ] Frozen-test list approved or tasks blocked.
- [ ] No source file changed.

### Phase 1A — Data integrity
- [ ] REM-01…REM-05 merged individually with gates.
- [ ] Corrupt backup, killed download, failed pack register, corrupt DB, tasbih race,
      khatma race each have a reproducing test that fails before the fix and passes after.
- [ ] Device kill/restart evidence for download and backup.
- [ ] `flutter analyze` 0; full suite green; exact count recorded.
- [ ] No schema migration without an approved plan.

### Phase 1B — Workflow correctness
- [ ] REM-06…REM-11 merged.
- [ ] 5 prayers across a day, including a reboot or resume path; prayer-only permission prompt.
- [ ] Continue-reading advances; Home ticks; every failed screen retries.
- [ ] Playback failure stops audio; mini player on all routes.
- [ ] Qibla flat/upright tolerance agreed; zakat invalid input rejected.
- [ ] Frozen-test edits only from the approved list.

### Phase 2 — Release readiness
- [ ] Signed AAB built from final HEAD; versionCode > every uploaded code.
- [ ] `apksigner`/`jarsigner`/`zipalign -c -P 16` evidence recorded.
- [ ] CI blocks artifacts on red; no debug-signed store-named artifact.
- [ ] R8/shrink/obfuscation + symbol archive; SDK pinned; wrapper reproducible.
- [ ] App Links verified with the Play cert; licensing GREEN.
- [ ] Store checklist, screenshots, data-safety, privacy policy match the binary.
- [ ] Internal-track install + smoke.

### Phase 3 — Security/resilience
- [ ] Pack redirects rejected per hop; only coarse location; DB excluded from D2D.
- [ ] Location denial recovery works; share/deep-link/sheet have no unhandled errors.
- [ ] Merged manifest inspected; no new permission.
- [ ] Security tests green; no high/medium finding re-opened.

### Phase 4 — Accessibility/localization/UX
- [ ] Contrast tests meet AA; no raw gold as text.
- [ ] Arabic plural cases correct; AR/EN parity preserved.
- [ ] RTL chevrons/back behavior verified.
- [ ] TextScale 2.0, 320/360-wide, landscape tests pass.
- [ ] Screen-reader labels verified on device.

### Phase 5 — Tests/CI
- [ ] Integration job runs on emulator and fails on a planted wiring break.
- [ ] Coverage measured at HEAD and threshold enforced.
- [ ] Time-based tests use injected clocks.
- [ ] Weak tests replaced only with owner approval.

### Phase 6 — Performance/features
- [ ] Before/after measurements recorded (cold start, pack open, tasbih writes, frame times).
- [ ] No behavior regression; feature acceptance recorded.
- [ ] Migrations tested and reversible.

---

## 11. Recommended first implementation phase

**Start with Phase 1A — silent data loss and corruption (REM-01 … REM-05).**

Why this first:

1. **It is the highest harm that can be fixed immediately.** Silent backup loss, stuck
   downloads, ghost packs, and a corrupt DB that bricks every screen do not need the Play
   Console, licensing, or a device decision. They can start on day one.
2. **It is independent of the frozen-test wall.** These fixes add new tests and do not require
   rewriting the reminder/plural pins. They can land while Phase 0 decisions are pending.
3. **It protects the release artifact.** Every day the app is used, the backup/download/pack
   paths can lose user data. Fixing them before the rebuild avoids shipping a build that
   creates new loss during the testing window.
4. **It creates the regression net for everything else.** The new reconciliation/atomicity
   tests become the guardrails for the release smoke and for later performance work.
5. **The reminder blocker follows immediately.** REM-06 is the first task of Phase 1B; its
   frozen-test ruling should be requested in Phase 0 so the data-integrity wave and the
   reminder decision proceed in parallel.

**First task:** REM-01 (backup integrity), because it is the only path where a user can believe
their data is restored while it is silently missing — and because it is the cheapest to prove
with a deterministic corrupt-file test.

**Do not start with:** R8/obfuscation or store polish (they depend on final code), the
performance pack index (needs a migration decision), or feature gaps (product scope).

---

**Plan prepared:** 2026-10-30 · **Commit:** `d39c1f7` · **Only file created:**
`PRODUCTION_REMEDIATION_PLAN.md` · **Application source modified: none.**
