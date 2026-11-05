# Simulation-risk remediation plan — 2026-11-02

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** close the two real product gaps the MiroFish prediction surfaced — reminder
reliability on aggressive Android OEMs and storage transparency — and publish the trust
policy that keeps the app's "free, no ads, no account, local data" promise auditable.

> **Status — 2026-11-05: Task 1, Task 2 and Task 3 all landed; the boxes below are
> ticked for that reason.** Evidence: `reminder_health_test` + the settings diagnostics
> card (Task 1), `DownloadsSummary`/`summary()`/`removeAll()` + `downloads_summary_test`
> and `downloads_screen_header_test` (Task 2), `principles_screen_test` (Task 3). Task 4
> stays a decision gate with no code. Section 9 (duplicate Gradle files) is resolved: no
> `*.gradle.kts` exists or is tracked.

**Architecture:** every change is additive and stays inside the existing feature split
(`lib/features/notifications`, `lib/features/recitation/presentation/downloads`,
`lib/features/settings`). The only native surface is one small `MethodChannel` in
`MainActivity.kt`; no package is added.

**Tech Stack:** Flutter 3.47.5 / Dart 3.13.4 · flutter_bloc 9 · drift · go_router 18 ·
flutter_local_notifications 22.3.2 · ARB l10n (AR template → EN mirror).

**Source evidence:** prediction report at
`E:\foolmark_workspace\mobile_workspace\mirofish\backend\uploads\reports\report_2e78a6a6271f\full_report.md`
(4 sections, 12 agents, 6 rounds). Quotes below are from that report.

---

## 0. What the report is — and is not

It is a **structured scenario**, not user research: 12 LLM personas, 6 simulated rounds,
one seed document. Treat its *categories* as useful and its *numbers* as invented. Three
of its four risks map onto code that already exists here; the fourth ("reciter discovery
packs") describes a feature that does not exist yet.

| Report risk | Reality in this repo (verified) | Verdict |
|---|---|---|
| App size from audio downloads | Streaming playback exists (`setUrl`, `just_audio_playback_service.dart:92`); downloads are per-surah with a byte cap (`audio_downloader.dart:61`); no bulk download; per-row size shown (`format_bytes` in `downloads_screen.dart`) | **Partial gap** — no total, no "delete all", no pre-download size |
| Notification reliability on Infinix/Tecno/Xiaomi | Permission + exact-alarm requests exist (`notifications_binding.dart:252-253`), `canScheduleExactNotifications()` fallback to `inexactAllowWhileIdle` (`:363-366`); **no battery-optimization status or guidance anywhere** | **Real gap** |
| Trust / monetization / "no ads" | No ads SDK, no auth, no telemetry (pubspec + `AGENTS.md`), local-first storage | **Policy gap** — true, but never stated in-product |
| Curated packs + shareable cards | Do not exist. Reader shares verse text only (`reader_screen.dart:433`); reciter catalog comes from an API (`reciter_source.dart:9`) | **Not applicable yet** — gate before building |
| Backup loses settings | Whitelist now covers prayer config, font scale and azkar keys (`backup_inventory.dart:82-97`) and a pin test guards it (`test/backup_inventory_pin_test.dart`) | **Closed** — no work |

The report's own honesty note is worth keeping: agent interviews in the earlier pilot
timed out, so its conclusions were inferred from public interactions. It never saw real
users.

## 1. Decisions locked before coding

1. **No new packages.** Battery-optimization state is read through a hand-written
   `MethodChannel` (≈40 lines of Kotlin). `permission_handler`, `android_intent_plus`
   and `url_launcher` are explicitly rejected for this scope.
2. **No telemetry.** Diagnostics are local-only and never leave the device.
3. **Free / no ads / no account stays a hard constraint**, not a marketing line.
4. **Nothing ships for "curated packs"** until Task 4's gate is answered.
5. Android-first; iOS gets the same UI with the battery row hidden (`null` capability).

## 2. Global constraints (from `AGENTS.md`)

- Frozen tests: existing tests are never edited. New tests go in new files.
- l10n additive and symmetric: AR template (`lib/l10n/app_ar.arb`) → EN mirror, regenerate.
- DI: register in `lib/app/di/injector.dart` only. A route-scoped cubit is never a singleton.
- Gates: `flutter analyze` = 0 · `flutter test` = full suite green · `dart format` clean.
- Commits: English, one concern, explicit pathspecs, never `git add -A`.
- No raw exception text reaches the UI; diagnostics go to `dev.log`.

## 3. Review Focus (failure modes no task's happy-path test covers)

1. **Android 13+ without notification permission** — the diagnostics card must show
   "off" and offer the system prompt, not silently claim everything is fine.
2. **Exact alarms revoked mid-life by the OS** (Android 14 `SCHEDULE_EXACT_ALARM` can be
   revoked) — the card must re-read on resume, not cache a boot-time value.
3. **A device where `isIgnoringBatteryOptimizations` throws** (OEM ROM without the API) —
   the third row must degrade to "unknown + instructions" instead of crashing the screen.
4. **Downloads deleted outside the app** (user clears storage) — the total must reconcile
   on open (`_ensureReconciled`), not show a stale number.
5. **RTL + textScaler 2.0** on the new settings section — the longest Arabic label
   ("تحسين استهلاك البطارية") must not overflow at 2×.

---

## 4. Task 1 — Reminder reliability diagnostics (P0)

**Why:** the report's second risk, and the only one that silently damages a core promise
(prayer reminders). On Infinix/Tecno/Xiaomi the OS kills background alarms; the app today
has no way to tell the user, and no way for the user to fix it.

**Files:**
- Modify: `android/app/src/main/kotlin/com/mostafasayed/quranyahdi/MainActivity.kt`
  (confirm the active package first — see §7)
- Create: `lib/features/notifications/data/reminder_diagnostics.dart`
- Create: `lib/features/notifications/data/reminder_diagnostics_channel.dart`
- Modify: `lib/app/di/injector.dart`
- Modify: `lib/features/settings/presentation/settings_screen.dart`
- Modify: `lib/l10n/app_ar.arb`, `lib/l10n/app_en.arb`
- Test: `test/reminder_health_test.dart`, `test/reminder_diagnostics_card_test.dart`

**Interfaces:**
- `abstract class ReminderDiagnostics` with `Future<bool> notificationsEnabled()`,
  `Future<bool> exactAlarmsAllowed()`, `Future<bool?> batteryOptimizationIgnored()`
  (`null` = platform cannot report), `Future<bool> openBatteryOptimizationSettings()`
  and `Future<bool> openExactAlarmSettings()`.
- `List<ReminderIssue> diagnoseReminders({required bool notificationsEnabled, required bool exactAlarmsAllowed, required bool? batteryOptimizationIgnored})`
  returning `ReminderIssue.notificationsOff`, `.exactAlarmsOff`, `.batteryRestricted`.

- [x] **Step 1: Write the failing unit test** for `diagnoseReminders` — four cases: all
  healthy → empty; notifications off; exact alarms off; `batteryOptimizationIgnored == false`
  → `batteryRestricted`; `batteryOptimizationIgnored == null` → no battery issue.
- [x] **Step 2: Run it** — `flutter test test/reminder_health_test.dart` → fails
  (`diagnoseReminders` not defined).
- [x] **Step 3: Implement `reminder_diagnostics.dart`** — the enum, the pure function, the
  abstract class. No Flutter imports.
- [x] **Step 4: Re-run** → passes.
- [x] **Step 5: Write the failing channel test** with a fake `MethodChannel`
  (`TestDefaultBinaryMessengerBinding`) asserting the three reads map to the Kotlin names
  `notificationsEnabled`, `exactAlarmsAllowed`, `batteryOptimizationIgnored`, and that a
  `PlatformException` maps to `null` rather than throwing.
- [x] **Step 6: Implement `reminder_diagnostics_channel.dart`** — `MethodChannel('quran_yahdi/reminder_diagnostics')`,
  wrap every call in `try/catch (PlatformException) => null`.
- [x] **Step 7: Implement the Kotlin side** in `MainActivity.configureFlutterEngine`:
  `areNotificationsEnabled()` via `NotificationManagerCompat`; exact alarms via
  `AlarmManager.canScheduleExactAlarms()` (guarded by `Build.VERSION >= S`);
  battery via `PowerManager.isIgnoringBatteryOptimizations(packageName)`; two open
  methods firing `ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS` and
  `ACTION_REQUEST_SCHEDULE_EXACT_ALARM`. Return `null` from the battery read when the
  OEM API throws.
- [x] **Step 8: Write the failing widget test** — pump the settings section with a fake
  `ReminderDiagnostics` in three states (healthy → no rows; one issue → that row + fix
  button; battery unknown → instruction row, no button). Assert the card also builds at
  `textScaler: TextScaler.linear(2.0)` without overflow. Use bounded pumps, no
  `pumpAndSettle`.
- [x] **Step 9: Add the UI** — a `_ReminderReliabilitySection` in `settings_screen.dart`
  that reads diagnostics in `initState`, re-reads on `WidgetsBindingObserver.didChangeAppLifecycleState == resumed`,
  and renders one `ListTile` per issue with a "إصلاح" trailing action. Add l10n keys
  `reminderReliabilityTitle`, `reminderReliabilityIntro`, `reminderIssueNotifications`,
  `reminderIssueExactAlarms`, `reminderIssueBattery`, `reminderIssueBatteryUnknown`,
  `reminderFixAction`.
- [x] **Step 10: Register the implementation** in `lib/app/di/injector.dart` as a lazy singleton.
- [x] **Step 11: Gates** — `dart format`, `flutter analyze` (0), `flutter test` (full suite),
  then manual device check on the Infinix X6882: deny notifications → row appears → tap
  fix → grant → row clears after resume.
- [x] **Step 12: Commit** — `feat(settings): surface reminder permissions and OEM battery restrictions`.

## 5. Task 2 — Storage transparency (P0)

**Why:** the report's most repeated conditional-churn trigger is "became heavy on a
mid-range phone". The app already streams and caps downloads, but a user cannot see how
much space the app holds, and cannot free it in one action.

**Files:**
- Modify: `lib/features/recitation/presentation/downloads/downloads_cubit.dart`
- Modify: `lib/features/recitation/presentation/downloads/downloads_screen.dart`
- Modify: `lib/l10n/app_ar.arb`, `lib/l10n/app_en.arb`
- Test: `test/downloads_summary_test.dart`, `test/downloads_screen_header_test.dart`

**Interfaces:**
- `class DownloadsSummary { final int count; final int bytes; }`
- `Future<DownloadsSummary> DownloadsCubit.summary()` — sums `InstalledDownload.bytes`
  after `_ensureReconciled()`.
- `Future<void> DownloadsCubit.removeAll()` — iterates `installed()` and calls the
  existing `removeDone(rowId, surahNumber)`; stops at the first failure and rethrows so
  the screen can show the error pane.

- [x] **Step 1: Write the failing cubit test** — fake repository with three installed rows
  (1 MB, 2 MB, 3 MB) → `summary()` returns `count: 3, bytes: 6 MB`; empty → zeroes.
- [x] **Step 2: Run it** → fails.
- [x] **Step 3: Implement `DownloadsSummary` + `summary()`**.
- [x] **Step 4: Re-run** → passes.
- [x] **Step 5: Write the failing `removeAll` test** — three rows → all removed, one repo
  failure → earlier removals kept, error propagates.
- [x] **Step 6: Implement `removeAll()`**.
- [x] **Step 7: Write the failing widget test** — header shows `loc.downloadsTotal`
  formatted with `format_bytes` and the row count; empty state shows no header.
- [x] **Step 8: Add the header + "حذف الكل"** — a `ListTile`-free summary card above the
  list, trailing `TextButton` guarded by the existing `confirm_delete_dialog`; add l10n
  keys `downloadsTotal`, `downloadsCount`, `downloadsDeleteAll`, `downloadsDeleteAllBody`.
- [x] **Step 9: Gates** — format, analyze, full test suite.
- [x] **Step 10: Commit** — `feat(downloads): show total storage use and allow deleting all downloads`.

## 6. Task 3 — Principles page (P1, no risk)

**Why:** the report's strongest signal is that trust is the product. The app never states
in-product what it does with data, why it is free, and how recitations are attributed.
This is a static page; it creates no new behaviour.

**Files:**
- Create: `lib/features/settings/presentation/principles_screen.dart`
- Modify: `lib/core/utils/app_routes.dart`, `lib/app/router.dart`,
  `lib/features/settings/presentation/settings_screen.dart`
- Modify: `lib/l10n/app_ar.arb`, `lib/l10n/app_en.arb`
- Test: `test/principles_screen_test.dart`

**Content (owner-approved copy, four blocks):**
1. مجاني بلا إعلانات — ولا نيّة لإدخال إعلانات.
2. بلا حساب — كل شيء يبقى على جهازك، والنسخ الاحتياطي بيدك أنت.
3. التلاوات منسوبة لأصحابها — أي قائمة مستقبلية تُراجع بشريًا قبل النشر.
4. إن أضفنا يومًا ميزة مدفوعة، تبقى كل الميزات الحالية مجانية.

- [x] **Step 1: Write the failing widget test** — route `/settings/principles` renders the
  four headings; textScale 2.0 renders without overflow.
- [x] **Step 2: Run it** → fails (route missing).
- [x] **Step 3: Add route + screen + settings entry** (`ListTile` under the licenses row).
- [x] **Step 4: Add l10n keys** `principlesTitle` + `principlesFree`, `principlesNoAccount`,
  `principlesAttribution`, `principlesFuturePaid`.
- [x] **Step 5: Gates** — format, analyze, full suite, plus a device render at textScale 2.0.
- [x] **Step 6: Commit** — `feat(settings): add the principles page`.

## 7. Task 4 — Curated packs: decision gate, no code (P1, blocked)

Do **not** build packs, playlists or shareable cards until these four answers exist in
`docs/decisions/`:

1. **Selection authority** — who signs off a reciter (a named reviewer), and what happens
   when a recording's attribution is challenged.
2. **Criteria** — published, non-commercial: tajweed accuracy and authenticated recitation
   before popularity.
3. **Pack weight** — hard cap per pack with on-demand streaming as the default; a pack must
   never bundle audio into the APK/IPA.
4. **Card attribution** — every shared card carries reciter + surah + ayah + source, and the
   share sheet says "مشاركة ≠ تزكية".

If the answers do not exist, the feature is postponed, not improvised.

## 8. Manual verification protocol (no code)

Run on the owner's Infinix X6882 (Android) and one Xiaomi if available:

1. Fresh install → open settings → diagnostics card state.
2. Deny notifications → card shows the issue → fix → grant → resume → clears.
3. Toggle exact alarms off in system settings → resume → issue appears.
4. Play a surah by streaming with mobile data only → confirm it does not write a file.
5. Download three surahs → downloads header total matches the system storage screen (±2 MB).
6. Delete all → total returns to zero and files are gone from app storage.
7. Set system font to largest + Arabic → principles page and settings card render fully.

Record results in `docs/audit/2026-11-02-device-verification.md` (new file, one table).

## 9. Open verification item — duplicate Gradle build files

`android/app/` currently holds **both** `build.gradle` (tracked; namespace
`com.mostafasayed.quranyahdi`, minSdk 24, targetSdk 36) and an **untracked, uncommitted**
`build.gradle.kts` (namespace `com.mostafasayed.quran_yahdi`, `flutter.*` defaults), plus an
untracked `.../quran_yahdi/MainActivity.kt`. This looks like an in-progress Kotlin-DSL
migration from another session.

Gradle resolves `build.gradle.kts` first when both exist, so the active applicationId may
have changed. That would install as a **second app** and break upgrades.

Verify before any release work — do not edit either file until the owning session is asked:

```powershell
cd android; .\gradlew.bat :app:properties -q | Select-String "applicationId|namespace"
```

Expected: one applicationId, equal to `com.mostafasayed.quranyahdi`. Anything else is a
release blocker, not a cleanup task.

## 10. Sequencing

Task 1 → Task 2 → Task 3 are independent and can land in any order; each is one commit.
Task 4 is blocked on owner decisions. Section 9 is a verify-only item that gates release,
not development.
