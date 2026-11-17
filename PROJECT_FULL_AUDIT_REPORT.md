# Project Full Audit — Quran Yahdi (`quran_yahdi`)

> **Read-only audit** of `E:\old_flutter\Quran-App-master` at **HEAD `3109dda1711df6f4e07477dd55a802562c04420b`** (branch `main`, tree clean except untracked `PROJECT_AUDIT_REPORT.md`), 2026-11-17.
> Method: gates re-measured from source → 8 parallel read-only dimension agents → orchestrator re-verification of every load-bearing claim at source (file:line or verbatim command output).
> No files created/modified except this report. No secret value printed anywhere. No builds, installs, device/emulator runs, coverage runs, commits, pushes, or network calls to external services. This is a NEW full-project review; closed PRs #58–#68 are not re-litigated, only their current state verified.

---

## 1. Pre-checks + environment

| Item | Measured output |
|---|---|
| `git rev-parse HEAD` | `3109dda1711df6f4e07477dd55a802562c04420b` |
| `git branch --show-current` | `main` |
| `git ls-remote --heads origin main` | `3109dda1711df6f4e07477dd55a802562c04420b refs/heads/main` ✅ local = origin |
| `git status --porcelain=v1` | `?? PROJECT_AUDIT_REPORT.md` only |
| `flutter --version` | Flutter 3.47.5 • channel stable • Framework revision `6a19cca564` (2026-09-17) • **Dart 3.13.4** • DevTools 2.60.0 |

All pre-checks passed. No mismatch → audit proceeded.

---

## 2. Gates (measured)

| Gate | Command | Result |
|---|---|---|
| analyze | `flutter analyze` | **No issues found! (ran in 136.0s)** → 0 issues |
| format | `dart format --output=none --set-exit-if-changed lib test tools` | **Formatted 918 files (0 changed) in 1.19 seconds**, exit 0 |
| full test | `flutter test` | **+1949: All tests passed!** (15:24) → 1949 passed, 0 failed, 0 skipped; duration ~15 min wall (2nd attempt, see Not proven) |
| pub outdated | `dart pub outdated --no-dev-dependencies` | 3 direct outdated: `file_picker 13.3.3→13.4.0`, `flutter_local_notifications 22.3.2→22.3.3` (resolvable 23.0.2), `geolocator 14.0.1→14.1.2`; pinned FLN deliberately (see F-8 below) |
| existing debug APK | `Get-ChildItem build\app\outputs\flutter-apk\app-debug.apk` | **223.2 MB**, LastWriteTime 2026-11-17 16:06 (pre-existing — not built for this audit) |
| coverage | `coverage/lcov.info` exists | **LF 9,790 / LH 7,161 = 73.1%**, dated 2026-10-30 (~18 days / 10 commits stale) — **not re-run** per brief |

**Doc-vs-measured number mismatches (every number claimed in README/docs re-checked):**

| Claim | Source | Measured truth | Severity |
|---|---|---|---|
| "البوابة الكاملة: 1931 اختبار" | `README.md:58` | **1949** tests | Low |
| "485 test files / 1,943 passing tests" | `PROJECT_AUDIT_REPORT.md:3,14` | **487** `*_test.dart` files / **1949** passing | Low (stale untracked report) |
| "No license file in the repo … fonts only Cairo-OFL.txt" | `docs/store/licensing-matrix.md:17` | `assets/licenses/HafsSmart-EULA.txt`, `me_quran-terms.txt`, `adhan-attribution.txt` all exist and ship in-app | Medium |
| "That backup file is an unencrypted JSON file" | `PRIVACY.en.md:37` | AES-256-GCM encrypted export exists (`backup_section.dart:123-131`, `backup_cubit.dart:111`) | Low |
| `// TODO: Specify your own unique Application ID` | `android/app/build.gradle:50` | applicationId already `com.mostafasayed.quranyahdi` (:51) | Low |
| `linux/macos/windows` platforms declared | `.metadata:24-33` | none of the three dirs exist on disk | Low |
| `db-drift.yml` comment "4,173,824 B" | `.github/workflows/db-drift.yml:10` | `assets/db/quran.sqlite` = **5,574,656 B** | Low |

---

## 3. Findings table (ordered Critical → Info)

### Critical (0)
None. No data loss, crash-on-launch, secret leak, or wrong religious content found. Adhan is a single licensed voice with matching attribution (verified: `adhan_catalog.dart:54-64`, `assets/licenses/adhan-attribution.txt`, byte-identical clip hash); Quran DB integrity and Bismillah convention were verified in the prior audit and not contradicted here; permissions hardened (no plaintext, `allowBackup=false`).

### High (0 — one Medium-latent candidate upgraded for visibility)

| ID | Sev | File:line | Evidence | Recommended fix |
|---|---|---|---|---|
| H-1 | **FIXED (was High, latent) — PR #69, main `69188695`** | `lib/features/home/presentation/home_cubit.dart:119`; `lib/features/prayer/presentation/prayer_times/prayer_times_cubit.dart:101`; `lib/features/notifications/data/reminder_scheduling.dart:34`; `lib/app/reminder_background_task.dart:146` | **Corrected mechanism (decisive probe, 2026-11-17):** the prayer INSTANT is correct and TZ-independent — the same adhan calculation for Cairo 2026-11-17 under device TZ EET-2EEST/GMT0/EST5EDT gave the identical Fajr epoch `1794883920000`; `toLocal()` only relabels the wall clock, it does not change the instant. The original report's claim ("instants are host-relative") was wrong. The REAL defect was the calendar DAY: the four schedule callers passed device-local `DateTime.now()` into the prayer port, so near midnight the "today" used for the schedule came from the device date instead of the selected city's date (device UTC 23:30 day D vs Cairo 01:30 day D+1 → first reminder off by 24 h; Fajr epoch for D+1 `1794970320000` vs D `1794883920000`). | **Fixed** by passing `cityWallClock(now, city.timezone)` at all four sites — it preserves the real instant (so `isAfter`/`difference` and reminder `.toUtc()` stay correct) while supplying the city's year/month/day. No `utcOffset` was added to adhan (measured to introduce a +2 h error). Red test `test/prayer_city_date_test.dart` (`8e79aec9`) fails `Expected 18 / Actual 17` before the fix, passes after (`69188695`); merged in PR #69. |

> Not classed Critical because the displayed times are correct when device TZ == city TZ (the normal single-user case) and the phone verification confirmed that path; it becomes wrong only on travel/city mismatch, which is reachable but not the default.

### Medium

| ID | Sev | File:line | Evidence | Recommended fix |
|---|---|---|---|---|
| M-1 | Medium | `docs/store/licensing-matrix.md:17` | Asserts "No license file in the repo … `assets/fonts/` contains only Cairo-OFL.txt"; actually `HafsSmart-EULA.txt`, `me_quran-terms.txt`, `adhan-attribution.txt` exist and are surfaced by `licenses_screen.dart:20-25`. | Correct the row; reflect the EULA/terms/attribution in the `OPEN-FOR-OWNER` status. |
| M-2 | Medium | `PROJECT_AUDIT_REPORT.md:3,14,135,297` | Stale/untracked report pinned to `02a01caa` (10 commits behind): F-01 adhan "BLOCKER" already closed by `1782c882` (single licensed voice); undercounts 485 files/1,943 tests vs 487/1949. | Re-pin to HEAD and re-run the finding register before circulating (note: owner's artifact, left untouched here). |
| M-3 | Medium | `AGENTS.md §2` vs tree | Doc lists `prayer/presentation/{city_picker,prayer_config,prayer_month,prayer_times}` and `library/presentation/{ayah_sheet,hadith}`, but tree also has `prayer/presentation/countdown/` (routed `router.dart:66`) and `library/presentation/search/` (`router.dart:58-59`). | Add `countdown` and `search` to the AGENTS.md nested-presentation list. |
| M-4 | Medium (edge case, structural) | `lib/features/library/data/hadith_store.dart:98-108,131-139` | `WHERE pack_id=? AND norm LIKE ?` and `number IN (...)`; PK `(pack_id,ordinal)`, no index on `norm` or `number`. Leading-wildcard `LIKE` can't use a B-tree index anyway; real pack sizes not measured → impact not proven. | If packs grow, add FTS5 on `norm` and a `(pack_id,number)` index. |

### Low

| ID | Sev | File:line | Evidence | Recommended fix |
|---|---|---|---|---|
| L-1 | Low | `README.md:58` | "1931 اختبار" vs measured 1949. | Update to 1949. |
| L-2 | Low | `PRIVACY.en.md:37`; `docs/store/licensing-matrix.md:17` | Privacy doc omits encrypted export; licensing matrix stale (see M-1). | Clarify AES-GCM export option; fix licensing row. |
| L-3 | Low | `pubspec.yaml:8` vs `pubspec.lock:1541-1542` | `sdk: ^3.5.0` declared but lock requires `dart >=3.13.0 <4.0.0`, `flutter >=3.47.0` — declared min not resolvable. | Raise constraint to `^3.13.0`. |
| L-4 | Low | `settings_store.dart:29-34`; `reciter_repository.dart:302,316` | `readAll(keys)` and `isIn(surahIds)` unbatched; current callers ≤~12 keys / ≤114 surahs so safe by construction, but no in-store cap. | Reuse `sqlBatches` defensively or document the ≤999 contract. |
| L-5 | Low | `lib/features/recitation/presentation/downloads/downloads_screen.dart:23,32-40` | `late Future<_DownloadsView> _data` fetched imperatively via `setState`, unlike the Cubit-state pattern elsewhere. | Consume a `BlocBuilder` stream or document as intentional exception. |
| L-6 | Low | `notifications_binding.dart:582` | Probe samples only `upcoming.take(2)` of ~74 alarms; a partial OEM clear of later slots with the first two intact is skipped on fingerprint match. | Sample first and last horizon alarms (or all ids). |
| L-7 | Low | `tasbih_repository.dart:37-39`, `hadith_bookmark_repository.dart:53-55`, `city_clock.dart:24-26`, `backup_io.dart:45-49` | `on Object { return null/empty; }` silent fail-open, no `appLog` in read paths. | Add `appLog(...)` in these decode/parse fallbacks. |
| L-8 | Low | `app_log.dart:14-16,22-31` | 171 `error: error` vs 43 `error: error.runtimeType`; release is silent so no release leak, but content-bearing call sites could surface paths in debug. | Switch file-import/restore call sites to `.runtimeType`. |
| L-9 | Low | `coverage/lcov.info` (2026-10-30) | 73.1% coverage artifact is 18 days / 10 commits stale. | Regenerate on HEAD before citing. |
| L-10 | Low | `rg "\.arb" test` → only a comment | No automated ARB↔EN key-parity test (440 keys currently identical by discipline only). | Add a Class B ARB key-parity pin. |
| L-11 | Low | `rg -l "Semantics\(" lib/features` → 9 files | ~10/19 features have no `Semantics(` widget; no goldens. | Extend semantics pass to reader/bookmarks/settings/zakat/duas. |
| L-12 | Low | `build.gradle:50`, `.metadata:24-33` | Stale Gradle TODO; phantom linux/macos/windows platforms. | Remove TODO and desktop entries. |
| L-13 | Low | `assets/icons/logo_master.png` 1,507,942 B | Only image >500 KB; build-time launcher source, not bundled — repo bloat only. | Downscale or move to `tools/brand/`. |
| L-14 | Low | `.github/workflows/db-drift.yml:10` | Comment "4,173,824 B" vs actual 5,574,656 B. | Update comment. |
| L-15 | Low | `git rev-list --left-right main...wave-b-old` → `66 8` | Local branch `wave-b-old` has 8 unmerged fix commits; intent unproven. | Owner confirm abandoned vs recover, then delete/merge (no action taken). |
| L-16 | Low | `git status --porcelain=v1` | Untracked `PROJECT_AUDIT_REPORT.md` in repo root. | Commit/archive/delete explicitly; never stage accidentally. |
| L-17 | Low | `assets/licenses/me_quran-terms.txt` | Font carries non-commercial restriction. | Confirm distribution intent; obtain license or substitute if commercial. |

### Info

| ID | Sev | File:line | Evidence | Fix |
|---|---|---|---|---|
| I-1 | Info | `test/architecture_guard_test.dart` | Strong guard: exact allowlist `{quran→library, quran→recitation}`, core↛feature, feature↛app, presentation↛other-feature-data, 18-file `lib/app/` set. | Keep. |
| I-2 | Info | `reader_screen.dart:24-26` | Only live cross-feature edges are presentation→presentation, matching allowlist. | None. |
| I-3 | Info | `notifications_binding.dart` (722 lines), `playback_cubit.dart` (623) | >500-line hand-written files, justified by allowlisted roles. | Optional split. |
| I-4 | Info | `adhan_catalog.dart:54-64`, `assets/licenses/adhan-attribution.txt` | Single licensed voice, attribution covers shipped asset, clip byte-identical to `res/raw`. | None. |
| I-5 | Info | `prayer_palette.dart:88-99` | 6 periods × 2 brightness = 12 palettes; sunrise has palette but no reminder (intentional). | None. |
| I-6 | Info | `docs/audit/2026-11-15-defect-audit.md:121-123` | "silent until first open" documented and code matches (`app.dart:123-127`, `bootId` check `:276`). | None. |
| I-7 | Info | `licenses_screen.dart:20-25`, `test/fixtures/ATTRIBUTION.md` | All third-party content has attribution. | None. |
| I-8 | Info | `gh run list --branch main` | 5/5 workflows green; latest CI `44098152451` success @ HEAD. | None. |
| I-9 | Info | `.gitignore` + `git check-ignore` | build/, .dart_tool/, coverage/, `*.jks`, `*.keystore`, `key.properties`, `local.properties` ignored; no secret file tracked. | None. |
| I-10 | Info | `app_log.dart:28` + `test/log_hygiene_app_log_test.dart` | appLog silent in release (`if (kReleaseMode) return;`), enforced by test; 191 call sites all routed through helper. | None. |
| I-11 | Info | `reciter_repository.dart:87-93`, `audio_downloader.dart:116-129`, `pack_redirect_guard.dart:34-42`, `version_policy_service.dart:28-30,60-203` | Network hardened: HTTPS-only allowlists, ≤3 redirect hops, Ed25519-signed size-capped version doc. | None. |
| I-12 | Info | `backup_service.dart:138-175`, `backup_inventory.dart:22-41` | Backup exports user data only, GPS stripped, atomic write transaction, fail-closed corrupt handling; no token/secret in backup. | None. |
| I-13 | Info | `test/plugin_version_pin_test.dart:27-30` | FLN 22.3.2 hard-pinned by test (PendingIntent identity); any bump fails suite by design. | None. |
| I-14 | Info | `app_locale_controller.dart:13,26,45` | Arabic default + fail-open; AR/EN 440-key ARB parity holds. | None. |
| I-15 | Info | `docs/decisions/2026-11-02-frozen-test-policy.md` + `docs/audit/...:162-178,309,370` | Class A edits disclosed; 8 registered Class B files. | None. |
| I-16 | Info | `material_color_utilities 0.13.0` etc. | `pub outdated` shows most transitive valid-on-major; 3 direct outdated (see gates). | None. |
| I-17 | Info | `version_policy_service.dart` + `ci.yml:56` | Store builds must pass `--dart-define=QURAN_VERSION_POLICY_PUBLIC_KEY=…` locally; omission intentionally fails closed. | Owner build check-list. |
| I-18 | Info | `just_audio_background 0.0.1-beta.17` | Pre-release dependency in core playback path; no stable line available. | Track upstream; deliberate pin. |
| I-19 | Info | `reader_state.dart:57-65`, `core/di/injector.dart:1` | Compat shims / legacy aliases intentionally retained for frozen suite. | None. |
| I-20 | Info | `// ignore:` sites | 100% in generated files; zero hand-written ignores. | None. |
| I-21 | Info | `pubspec.yaml:2` "offline-first" vs 3 HTTPS destinations | App is offline-first but not offline-only (catalog fetch, pack/audio downloads, update check) — all fail-open/hardened. | Align privacy/listing wording (also L-2). |
| I-22 | Info | `apd` — no `print(`/`withOpacity(`/hardcoded `Text()` strings in `lib/` | House hygiene clean; `appLog` sole logging entrypoint. | None. |

---

## 4. Counts

**Findings by severity** (unique IDs): Critical 0 · High 1 (**H-1 — FIXED in PR #69 @ main `69188695`**, mechanism corrected above) · Medium 4 · Low 17 · Info 22 · **total 44**. H-1's entry was corrected 2026-11-17 after the decisive probe disproved the original "toLocal changes the instant" mechanism.

**Tests by area** (487 `*_test.dart` + 11 support/fixture = 498 `.dart` files; prefix grouping, best effort): prayer 31 · reader 22 · backup 19 · azkar 17 · quran 16 · reminder/playback/settings/qibla 14 each · home 13 · pack/city/tasbih/downloads 11 each · zakat 10 · tracker/hadith/audio/app 9 each · reciter/ayah 8 each · adhan/hijri/bookmarks/db/library/search 7 each · theme/bookmark/asma 6 each · notification/surah/duas/onboarding 5 each · architecture/translation/ruqyah/mini/juz/qada/recitation/version 4 each · long tail 99.

**Docs checked:** README.md, AGENTS.md, PRIVACY.en.md, docs/store/licensing-matrix.md, docs/campaign-ledger.md, docs/audit/2026-11-15-defect-audit.md, docs/decisions/2026-11-02-frozen-test-policy.md, PROJECT_AUDIT_REPORT.md, .metadata, android/app/build.gradle, .github/workflows/{ci,db-drift,web}.yml — 12 docs + 3 workflows.

**Non-vacuity sample:** `quran_search_token_cap_test.dart` (1500-token QueryInterceptor, fails without cap), `zakat_calculator_test.dart` (hard numbers), `backup_inventory_pin_test.dart` (inventory drift), `prayer_time_service_dst_test.dart` (TZ runner, non-vacuity proven by revert) — all non-vacuous.

---

## 5. Not proven (could not verify; what would verify it)

- **H-1 device re-verification** — the fix (city-date selection) is proven by `test/prayer_city_date_test.dart` on the clock seam, but NOT yet re-run on a physical device with device TZ ≠ city TZ near midnight. The earlier Cairo check (device TZ == city TZ) still holds by construction. The decisive probe (plain Dart, three POSIX TZs) proved the instant is TZ-independent and the day-source was the defect.
- **Full-suite result on first attempt** — an earlier gate run was killed mid-suite at ~+132 tests under 384 MB free RAM (memory pressure, no test failure); the recorded 1949/1949 is from a clean retry. All test files passed individually in the retry; no `[E]` failure was ever observed.
- **Existing coverage number is current** — `lcov.info` 73.1% is stale (2026-10-30); a fresh `flutter test --coverage` would verify current coverage (not run per brief).
- **Adhan audio actual duration** = `durationSeconds: 149` — no ffprobe/playback (no device/build).
- **Shipped `quran.sqlite` PRAGMA user_version / migration from legacy v1/v2** — binary asset not opened; source-only conclusion.
- **F3 hadith pack real sizes / search latency** — not measured read-only.
- **Production store builds pass `--dart-define=QURAN_VERSION_POLICY_PUBLIC_KEY=…`** — local build step outside repo.
- **EN-mode correctness of hardcoded `TextDirection.rtl`** in `asma_screen.dart`, `downloads_screen.dart`, `hijri_screen.dart` — needs an EN-locale device run.
- **Orphan-test absence / exhaustive production-area test gaps** — name-level inspection only, no full AST mapping.
- **"20th audit finding gap (19 of 20)"** — not identifiable from `PROJECT_AUDIT_REPORT.md` (it enumerates F-01…F-25); no 19-of-20 statement found repo-wide. Not guessed.
- **`wave-b-old` 8 unmerged commits intentionally abandoned vs. lost work** — owner knowledge required.
- **Circular imports / duplicated logic** — best-effort grep, not AST-level analysis.
- **Secrets in untracked/ignored local files** (e.g. `android/key.properties` contents) — deliberately not read; no value reported.
- **iOS signing entitlements / App Store state** — state-only review.

---

## 6. Three most important next steps (in order)

1. **H-1 — DONE (PR #69, main `69188695`).** The day-source defect was fixed by passing `cityWallClock(now, city.timezone)` at the four schedule sites; red test `8e79aec9` → fix `69188695`. Remaining: a device re-run with device TZ ≠ city TZ near midnight (owner, no device work done in that wave). Note the fix is the DAY choice, NOT a utcOffset on adhan (the instant was already correct).
2. **Refresh the two stale owner-facing artifacts** — `README.md:58` test count (1931→1949) and `PROJECT_AUDIT_REPORT.md` (re-pin to HEAD, close F-01 adhan, correct counts); plus M-1 licensing matrix correction. These are trust/legal-facing and currently mislead.
3. **Raise the declared SDK floor** (`pubspec.yaml:8` `^3.5.0` → `^3.13.0`) and add the ARB key-parity Class B pin + `sqlBatches` defensively in `settings_store.readAll`/`isIn(surahIds)` — small hygiene items that keep future contributors and future inputs safe.
