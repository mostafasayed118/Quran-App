# Adhan Selection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the user pick one of nine bundled adhans (global + an optional Fajr override), hear it as the prayer notification's sound, and play the full adhan on demand with a stop control.

**Architecture:** The catalog is data in `lib/core/domain/`. Two ports (`AdhanPreferences`, `AdhanPlayer`) live in `lib/core/domain/` and are implemented inside the `notifications` feature, so `settings/` depends only on core and no new feature→feature edge appears. Because the planner emits **one** prayer reminder for the *next* prayer, "is this Fajr?" is resolved at **plan** time and stamped onto `ScheduledReminder.adhanId`; the binding then posts on a per-reciter channel so a channel's frozen sound is never mutated.

**Tech Stack:** Flutter 3.47.5 / Dart 3.13.4 · flutter_bloc + freezed · drift (settings table) · flutter_local_notifications 22 · just_audio + just_audio_background · ffmpeg (build-time only, not an app dependency).

**Spec:** `docs/superpowers/specs/2026-11-04-adhan-selection-design.md` (APPROVED 2026-11-04). Read it before Task 1 — this plan argues from it.

## Global Constraints

- **No commit, no push** unless the owner has opened an explicit commit/commit-window. Every "Commit" step below is executed only inside such a window; otherwise stage nothing and report the diff. Never `git add -A`.
- **Do not edit any existing test file.** A perceived need is a STOP with `file:line`. The only sanctioned exception is an **additive Class B inventory pin** (`test/backup_inventory_pin_test.dart`) when a key is added — and the report must state the exact set delta.
- **l10n is additive and symmetric:** never change an existing ARB value. Add the AR pair, regenerate, keep AR count == EN count.
- **Boot rule:** the first frame never waits for a plugin. Anything needing the audio/notification plugin queues its request; "not yet initialized" is never surfaced as "unavailable".
- **UI shows localized copy only.** Never render an exception string; log to `dev.log(name: 'quran_yahdi/adhan')`.
- **Gates after every task:** `flutter analyze` → 0 issues; `flutter test` → all green. Report literal counts.
- Default adhan id is `abdulbasit_abdulsamad`; the unattributed track id is `khushu`.
- Audio: 64 kbit/s mono AAC, 44.1 kHz; clips are the first 25 s with a 2 s fade-out.

## Review Focus

The spec implies these five conditions but no single task's happy-path test pins them. Each gets a test in the owning task:

1. **A restored backup names an adhan this build does not know** (older/newer version, hand-edited file) → the picker and the notification must fall back to the default, never blank or crash.
2. **`adhan_fajr_id` is stored but its track was removed**, or points at an unknown id → Fajr must fall back to the global choice.
3. **Preview is tapped twice quickly, or a second row is tapped while one preview plays** → exactly one player, no overlapping audio, one media notification.
4. **The adhan is played while a surah is playing** → recitation stops first; no two streams and no orphaned media session.
5. **Play is requested before the audio plugin finished initialising** (cold boot, or the 1.5 s fail-open cap already fired) → the request is queued or fails open with a log; never an unhandled exception or a silent no-op the UI reports as "unavailable".

---

## Task 1: Adhan asset pipeline

**Files:**
- Create: `_adhan_masters/` (gitignored; the 9 original 128 k files move here)
- Modify: `.gitignore` (add `_adhan_masters/`)
- Create: `tools/build_adhan_audio.ps1`
- Create: `assets/audio/adhan/<id>.m4a` (9, generated)
- Create: `assets/audio/adhan/clips/<id>_clip.m4a` (9, generated)
- Create: `android/app/src/main/res/raw/<id>_clip.m4a` (9, generated copies)
- Modify: `pubspec.yaml` (asset declarations)

**Interfaces:**
- Produces: the 18 shipped assets and 9 raw resources that Task 2's catalog test asserts exist, addressed by the ids in the spec's §3 table.

- [ ] **Step 1: Move the masters out of `assets/` and ignore them**

```powershell
New-Item -ItemType Directory -Force _adhan_masters | Out-Null
Get-ChildItem assets -File -Filter *.m4a | Move-Item -Destination _adhan_masters
```
Add `_adhan_masters/` to `.gitignore`. Verify `git status --porcelain` no longer lists any `.m4a` and `Get-ChildItem assets -Filter *.m4a` is empty.

- [ ] **Step 2: Write `tools/build_adhan_audio.ps1`**

Maps each master filename to its catalog id (the mapping is the 9 rows of the spec §3), then for each id runs:

```powershell
ffmpeg -y -i $master -ac 1 -ar 44100 -c:a aac -b:a 64k -movflags +faststart "assets/audio/adhan/$id.m4a"
ffmpeg -y -i $master -t 25 -af "afade=t=out:st=23:d=2" -ac 1 -ar 44100 -c:a aac -b:a 64k -movflags +faststart "assets/audio/adhan/clips/${id}_clip.m4a"
```
then copies each clip to `android/app/src/main/res/raw/${id}_clip.m4a` (raw file names must match `[a-z0-9_]`). The script is idempotent and takes the master directory as a parameter defaulting to `_adhan_masters`.

- [ ] **Step 3: Run the pipeline and verify the output**

Run: `pwsh -File tools/build_adhan_audio.ps1`
Expected: 9 + 9 + 9 files. Verify each with ffprobe:

```powershell
Get-ChildItem assets\audio\adhan -File -Filter *.m4a | ForEach-Object {
  $j = ffprobe -v quiet -print_format json -show_streams $_.FullName | ConvertFrom-Json
  $a = $j.streams | Where-Object codec_type -eq 'audio'
  "{0} ch={1} sr={2} kbps={3}" -f $_.Name, $a.channels, $a.sample_rate, [math]::Round($a.bit_rate/1000)
}
```
Expected per file: `ch=1 sr=44100 kbps=64`. Total `assets/audio/adhan` ≈ 14–15 MB; every clip ≤ 26 s.

- [ ] **Step 4: Declare the assets in `pubspec.yaml`**

Add both directories under `flutter: assets:` — directory entries are **not** recursive, so both lines are required:

```yaml
    - assets/audio/adhan/
    - assets/audio/adhan/clips/
```

- [ ] **Step 5: Gate**

Run: `flutter analyze` → 0 issues. Run: `flutter test` → still 1157 passing (no code changed yet).
*(Commit step omitted — see Global Constraints.)*

---

## Task 2: `AdhanTrack` catalog

**Files:**
- Create: `lib/core/domain/adhan_catalog.dart`
- Test: `test/adhan_catalog_test.dart`

**Interfaces:**
- Consumes: the assets from Task 1.
- Produces:
  - `class AdhanTrack { final String id; final String nameAr; final String nameEn; final int durationSeconds; String get assetPath; String get clipPath; String get clipResource; }`
  - `const String kDefaultAdhanId = 'abdulbasit_abdulsamad';`
  - `const List<AdhanTrack> kAdhanCatalog;`
  - `AdhanTrack adhanById(String? id);` — never returns null; unknown/null → default.
  - `String adhanIdForPrayer({required PrayerName prayer, required String globalId, required String? fajrId});`
  - `String adhanChannelId(AdhanTrack track);` → `'quran_yahdi_adhan_${track.id}'`

- [ ] **Step 1: Write the failing test**

`test/adhan_catalog_test.dart` — assertions:
```dart
test('ids are unique, lowercase and raw-resource safe', () {
  final ids = kAdhanCatalog.map((t) => t.id).toList();
  expect(ids.toSet().length, ids.length);
  for (final id in ids) {
    expect(RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id), isTrue, reason: id);
  }
});

test('every track ships both a full file and a clip', () {
  for (final t in kAdhanCatalog) {
    expect(File(t.assetPath).existsSync(), isTrue, reason: t.assetPath);
    expect(File(t.clipPath).existsSync(), isTrue, reason: t.clipPath);
  }
});

test('every track has both display names', () {
  for (final t in kAdhanCatalog) {
    expect(t.nameAr.trim(), isNotEmpty);
    expect(t.nameEn.trim(), isNotEmpty);
  }
});

test('an unknown or null id resolves to the default', () {
  expect(adhanById(null).id, kDefaultAdhanId);
  expect(adhanById('does_not_exist').id, kDefaultAdhanId);
});

test('fajr takes the override, others take the global', () {
  expect(adhanIdForPrayer(prayer: PrayerName.fajr, globalId: 'a', fajrId: 'b'), 'b');
  expect(adhanIdForPrayer(prayer: PrayerName.fajr, globalId: 'a', fajrId: null), 'a');
  expect(adhanIdForPrayer(prayer: PrayerName.isha, globalId: 'a', fajrId: 'b'), 'a');
});

test('every track gets a distinct channel id', () {
  final ids = kAdhanCatalog.map(adhanChannelId).toSet();
  expect(ids.length, kAdhanCatalog.length);
});
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `flutter test test/adhan_catalog_test.dart`
Expected: FAIL — `adhan_catalog.dart` does not exist.

- [ ] **Step 3: Implement `lib/core/domain/adhan_catalog.dart`**

Nine `const AdhanTrack` entries in the spec's §3 order (default first), the getters as listed in Interfaces, and the three free functions. Document on `adhanById` that it is the forward-compatibility seam: a backup written by a newer build must not blank the UI.

- [ ] **Step 4: Run the test**

Run: `flutter test test/adhan_catalog_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 5: Gate**

`flutter analyze` → 0. `flutter test` → 1157 + 6 = 1163.
*(Commit step omitted.)*

---

## Task 3: `AdhanPreferences` port, implementation, and backup keys

**Files:**
- Create: `lib/core/domain/adhan_preferences.dart`
- Create: `lib/core/domain/adhan_player.dart` (the **port + state only**; the implementation lands in Task 6)
- Create: `lib/features/notifications/data/adhan_preferences_impl.dart`
- Modify: `lib/app/di/injector.dart` (register the impl)
- Modify: `lib/features/backup/data/backup_inventory.dart` (2 literal keys)
- Modify: `test/backup_inventory_pin_test.dart` (Class B, additive only)
- Test: `test/adhan_preferences_test.dart`, `test/backup_adhan_roundtrip_test.dart`

**Interfaces:**
- Consumes: `AdhanTrack`/`adhanById` from Task 2; the existing settings-table idiom.
- Produces:
  - `abstract interface class AdhanPreferences { Future<String> adhanId(); Future<String?> fajrAdhanId(); Future<void> setAdhanId(String id); Future<void> setFajrAdhanId(String? id); }`
  - `const String adhanIdKey = 'adhan_id'; const String adhanFajrIdKey = 'adhan_fajr_id';`
  - `class AdhanPreferencesImpl implements AdhanPreferences { AdhanPreferencesImpl(this._db); }`
  - `abstract interface class AdhanPlayer { Future<void> play(String trackId); Future<void> preview(String trackId); Future<void> stop(); Stream<AdhanPlaybackState> get state; }`
  - `enum AdhanPlaybackStatus { idle, playing, paused }`
  - `class AdhanPlaybackState { const AdhanPlaybackState({required this.status, this.trackId}); final AdhanPlaybackStatus status; final String? trackId; }`

  The `AdhanPlayer` **port** is declared here so Task 4's picker cubit can take a fake; Task 6 ships `JustAudioAdhanPlayer` against it. Do **not** create the implementation in this task.

- [ ] **Step 1: Write the failing test**

`test/adhan_preferences_test.dart` using the existing `newTestDb()` harness from `test/support/test_db.dart`:
```dart
test('adhanId defaults to the default track when unset', () async {
  expect(await prefs.adhanId(), kDefaultAdhanId);
});
test('setAdhanId persists and round-trips', () async { ... expect(..., 'omar_hisham'); });
test('fajrAdhanId is null until set, and can be cleared back to null', () async { ... });
test('an unknown stored adhan id resolves to the default', () async {
  await prefs.setAdhanId('removed_in_a_future_build');
  expect(await prefs.adhanId(), kDefaultAdhanId);
});
```
The 4th test is Review Focus #1 at the storage layer.

- [ ] **Step 2: Run it and confirm it fails**

Run: `flutter test test/adhan_preferences_test.dart` → FAIL (file missing).

- [ ] **Step 3: Implement the preferences port and the implementation**

Read: `lib/features/notifications/data/reminder_settings.dart:34-65` for the exact idiom. Use:
```dart
final row = await (_db.select(_db.settingsTable)
      ..where((s) => s.key.equals(adhanIdKey)))
    .getSingleOrNull();
```
and `_db.into(_db.settingsTable).insertOnConflictUpdate(SettingsTableCompanion.insert(key: ..., value: ...))`.
`setFajrAdhanId(null)` writes the empty string `''`, and the getter maps `''` back to `null` (the table has no nullable value).
`adhanId()` returns `adhanById(row?.value).id` — normalising an unknown stored id to the default at the boundary.

Also create `lib/core/domain/adhan_player.dart` containing **only** the `AdhanPlayer` interface, `AdhanPlaybackStatus` enum and `AdhanPlaybackState` value type (declarations from the Interfaces block). No implementation, no imports beyond what the type needs — the concrete player is Task 6.

- [ ] **Step 4: Register in the composition root**

In `lib/app/di/injector.dart`, next to the other notification registrations: `getIt.registerLazySingleton<AdhanPreferences>(() => AdhanPreferencesImpl(getIt<AppDatabase>()));`

- [ ] **Step 5: Add the backup keys and update the pin**

In `backup_inventory.dart`, under a `/// adhan_preferences.dart.` comment, add:
```dart
const String backupKeyAdhanId = 'adhan_id';
const String backupKeyAdhanFajrId = 'adhan_fajr_id';
```
and add both to the exported/imported key lists in that file. Then extend `test/backup_inventory_pin_test.dart` with two `expect(literal, ownerConstant)` rows only. **Disclose the +2 key delta in the report.**

- [ ] **Step 6: Write the backup round-trip test**

`test/backup_adhan_roundtrip_test.dart` (new file — do not modify the existing `backup_service_test.dart` / `backup_codec_test.dart` / `backup_merger_test.dart`):
```dart
test('export carries both adhan keys', ...);              // adhan_id and adhan_fajr_id present
test('import restores a selected adhan and a fajr override', ...);
test('import of an unknown adhan id does not fail the restore', ...); // Review Focus #1
test('import of an empty fajr value restores "same as default"', ...); // '' -> null
```
Reuse the harness already used by `backup_service_test.dart` (`writeSetting` / `settingValue` helpers, `doc(settings: {...})`).

- [ ] **Step 7: Run the tests**

Run: `flutter test test/adhan_preferences_test.dart test/backup_inventory_pin_test.dart test/backup_adhan_roundtrip_test.dart test/backup_service_test.dart`
Expected: PASS.

- [ ] **Step 8: Gate**

`flutter analyze` → 0. `flutter test` → report the new total.
*(Commit step omitted.)*

---

## Task 4: Picker cubit, screen, route, and l10n

**Files:**
- Create: `lib/features/settings/presentation/adhan_picker_state.dart` (freezed)
- Create: `lib/features/settings/presentation/adhan_picker_cubit.dart`
- Create: `lib/features/settings/presentation/adhan_picker_screen.dart`
- Modify: `lib/core/utils/app_routes.dart` (add `static const adhanPicker = '/settings/adhan';`)
- Modify: `lib/app/router.dart` (GoRoute + `RouteCubitScope<AdhanPickerCubit>`)
- Modify: `lib/features/settings/presentation/settings_screen.dart` (one navigation row)
- Modify: `lib/l10n/app_ar.arb`, `lib/l10n/app_en.arb` (+ regenerated files)
- Test: `test/adhan_picker_test.dart`

**Interfaces:**
- Consumes: `AdhanPreferences`, `AdhanPlayer` (Task 3 port; Task 6 provides the implementation — the cubit must accept a fake in tests), `ReminderSettingsPort`, `CitySource`, `PrayerTimesPort`, `ReminderSchedulerPort`.
- Produces:
  - `class AdhanPickerCubit extends Cubit<AdhanPickerState>` with
    `AdhanPickerCubit({required AdhanPreferences prefs, required AdhanPlayer player, required ReminderSettingsPort settings, required CitySource city, required PrayerTimesPort prayer, required ReminderSchedulerPort scheduler})`,
    `Future<void> start()`, `Future<void> select(String id)`, `Future<void> selectFajr(String? id)`, `Future<void> preview(String id)`, `Future<void> stopPreview()`, `Future<void> close()`.
  - `AdhanPickerState.ready({required String adhanId, required String? fajrAdhanId, required String? previewingId})`.

- [ ] **Step 1: Write the failing test**

`test/adhan_picker_test.dart` with a hand-rolled `_FakeAdhanPlayer` (records calls) and a `_FakeAdhanPreferences`:
```dart
testWidgets('renders one row per catalog entry plus the fajr fallback row', ...);
testWidgets('the current global selection is checked', ...);
testWidgets('tapping a row writes the preference and re-plans', ...);  // assert fake prefs + fake scheduler
testWidgets('selecting fajr "same as default" writes null', ...);
testWidgets('preview plays the clip once and stops on a second tap', ...); // Review Focus #3
testWidgets('rapid double taps on two rows leave exactly one preview', ...); // Review Focus #3
testWidgets('disposing the screen stops an active preview', ...);
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `flutter test test/adhan_picker_test.dart` → FAIL (files missing).

- [ ] **Step 3: Implement the cubit and state**

Mirror `SettingsCubit`'s idioms exactly: a `_mutations` future chain with `_serialized`, a `_readyState()` guard that returns null when closed/loading/failed, and `copyWith` emits. After a successful write call the same reschedule path (`settings.reschedule(city: _city, prayer: _prayer, scheduler: _scheduler)`), wrapped best-effort with `dev.log(name: 'quran_yahdi/adhan')`. `preview(id)` first calls `stopPreview()` so a second tap can never stack a second stream.

- [ ] **Step 4: Implement the screen**

`AdhanPickerScreen` reads the cubit via `context.read` inside `RouteCubitScope` (never `context.watch` on the whole screen). Two sections per spec §7: global list, then Fajr with a "مثل الافتراضي" row first. Each row: leading preview/stop `IconButton` (48×48 minimum), `RadioListTile`-style selection, `nameAr` as title and `nameEn` as subtitle. All static copy from `AppLocalizations`.

- [ ] **Step 5: Add the route, the router entry, and the settings row**

`AppRoutes.adhanPicker = '/settings/adhan'`. Router entry follows `router.dart:141-155`:
```dart
GoRoute(
  path: AppRoutes.adhanPicker,
  builder: (_, __) => RouteCubitScope<AdhanPickerCubit>(
    create: () => AdhanPickerCubit(
      prefs: getIt<AdhanPreferences>(),
      player: getIt<AdhanPlayer>(),
      settings: getIt<ReminderSettingsPort>(),
      city: getIt<CitySource>(),
      prayer: getIt<PrayerTimesPort>(),
      scheduler: getIt<ReminderSchedulerPort>(),
    ),
    identity: AppRoutes.adhanPicker,
    start: (cubit) => cubit.start(),
    child: const AdhanPickerScreen(),
  ),
),
```
`settings_screen.dart` gains one row above the reliability section: title `loc.adhanTitle`, subtitle = `adhanById(currentId).nameAr`, trailing chevron, `onTap: () => context.push(AppRoutes.adhanPicker)`. The current id comes from `AdhanPreferences` via the settings screen's existing injection style — **read it, do not add a write path to `SettingsCubit`.**

- [ ] **Step 6: Add the l10n pairs and regenerate**

Add to `app_ar.arb` and `app_en.arb`, both, with identical keys:
`adhanTitle`, `adhanDefaultSection`, `adhanFajrSection`, `adhanSameAsDefault`, `adhanPreview`, `adhanStopPreview`, `adhanPlayAction`.
Run `flutter gen-l10n` (or the project's generation command) and keep the generated files. AR key count must equal EN key count.

- [ ] **Step 7: Run the tests**

Run: `flutter test test/adhan_picker_test.dart` → PASS.
Then `flutter test` → report the literal total. If a l10n parity test pins a key count, bump it (additive, Class B) and disclose the delta.

- [ ] **Step 8: Gate**

`flutter analyze` → 0. `flutter test` → all green.
*(Commit step omitted.)*

---

## Task 5: Per-reciter notification channels with Fajr resolution

**Files:**
- Modify: `lib/core/domain/reminders.dart` (`ScheduledReminder` gains `String? adhanId`)
- Modify: `lib/features/notifications/data/reminder_planner.dart` (`planReminders` stamps the resolved id)
- Modify: `lib/features/notifications/data/reminder_scheduling.dart` (read the preference, pass it through)
- Modify: `lib/features/notifications/data/reminder_settings.dart` (optional `AdhanPreferences` ctor param)
- Modify: `lib/features/notifications/data/notifications_binding.dart` (per-reminder `NotificationDetails`)
- Modify: `lib/app/di/injector.dart` (pass the preference into `ReminderSettings`)
- Test: `test/adhan_notification_channel_test.dart`

**Interfaces:**
- Consumes: `adhanById`, `adhanIdForPrayer`, `adhanChannelId` (Task 2); `AdhanPreferences` (Task 3).
- Produces:
  - `ScheduledReminder({..., String? adhanId})` — `final String? adhanId;`
  - `planReminders({..., String? adhanId, String? fajrAdhanId})`
  - `scheduleReminders({..., AdhanPreferences? adhanPrefs})`
  - `ReminderSettings(this._db, {PrayerConfigSource? prayerConfig, PreAdhanCanceller? preAdhanCanceller, AdhanPreferences? adhanPrefs})`

- [ ] **Step 1: Write the failing test**

`test/adhan_notification_channel_test.dart`:
```dart
test('the prayer reminder carries the resolved adhan id', ...);      // isha -> global
test('a fajr reminder carries the fajr override', ...);              // fajr + override
test('fajr falls back to the global when the override is absent', ...);
test('fajr falls back to the global when the override names an unknown track', ...); // Review Focus #2
test('azkar, wird and pre-adhan reminders carry no adhan id', ...);
test('every catalog entry produces a distinct channel id, none equal to the legacy channel', ...);
```
Assert on the **plan** (`planReminders` output) for the first five — it is pure and needs no plugin.

- [ ] **Step 2: Run it and confirm it fails**

Run: `flutter test test/adhan_notification_channel_test.dart` → FAIL.

- [ ] **Step 3: Stamp the plan**

Add the optional field to `ScheduledReminder` with a doc comment explaining it is resolved at plan time because the planner emits a single "next prayer" reminder (`reminder_planner.dart:97-103`). In `planReminders`, set it **only** on the `prayerReminderId` entry:
```dart
adhanId: adhanIdForPrayer(
  prayer: chosen.name,
  globalId: adhanId ?? kDefaultAdhanId,
  fajrId: fajrAdhanId,
),
```
Leave the pre-adhan, azkar and wird entries without it.

- [ ] **Step 4: Thread the preference through**

`ReminderSettings` gains the optional `adhanPrefs` param (optional so existing constructions and test fakes keep compiling — same precedent as `PrayerReminderSettingsPort` per `reminders.dart:73-75`). `scheduleReminders` gains `AdhanPreferences? adhanPrefs`, reads `await adhanPrefs?.adhanId()` and `await adhanPrefs?.fajrAdhanId()` **inside** its existing `try`, and passes both into `planReminders`. Wire it in `injector.dart`.

- [ ] **Step 5: Post on the right channel**

In `notifications_binding.dart`, replace the single `_details` reuse inside `_applyPlan` (line ~355) with a per-reminder builder:
```dart
NotificationDetails _detailsFor(ScheduledReminder reminder) {
  final track = reminder.adhanId == null ? null : adhanById(reminder.adhanId);
  if (track == null) return _details!;                       // azkar/wird/pre-adhan keep today's channel
  return NotificationDetails(
    android: AndroidNotificationDetails(
      adhanChannelId(track),
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(track.clipResource),
    ),
  );
}
```
Cache `_channelName` / `_channelDescription` in `init()` from the same `loc` strings already used at line 134-141. Add a comment stating the channel is created implicitly on first post and that one channel per track is deliberate — a shared channel would freeze the first sound forever for existing users.

- [ ] **Step 6: Run the tests**

Run: `flutter test test/adhan_notification_channel_test.dart` → PASS.
Then `flutter test` → all green. Watch `notification_*_test.dart` and `reminder_*_test.dart` specifically; a `ScheduledReminder` with `adhanId == null` must behave byte-identically to today.

- [ ] **Step 7: Gate**

`flutter analyze` → 0. `flutter test` → report the literal total.
*(Commit step omitted.)*

---

## Task 6: Full playback and the notification action

**Files:**
- Create: `lib/core/domain/media_playback_control.dart`
- Create: `lib/features/notifications/data/just_audio_adhan_player.dart`
- Modify: `lib/features/recitation/playback/just_audio_playback_service.dart` (implement the new interface)
- Modify: `lib/features/notifications/data/notifications_binding.dart` (action + tap routing)
- Modify: `lib/app/router.dart` (handle the adhan payload)
- Modify: `lib/app/di/injector.dart` (register `AdhanPlayer`, `MediaPlaybackControl`)
- Test: `test/adhan_player_test.dart`

**Interfaces:**
- Consumes: `AdhanTrack`, the `AdhanPlayer`/`AdhanPlaybackState` **port declared in Task 3**, `just_audio`, `AudioService`, `MediaPlaybackControl`.
- Produces:
  - `abstract interface class MediaPlaybackControl { Future<void> stopForAdhan(); }`
  - `class JustAudioAdhanPlayer implements AdhanPlayer { JustAudioAdhanPlayer({required MediaPlaybackControl? recitation, required Future<bool> Function() ready}); }`

- [ ] **Step 1: Write the failing test**

`test/adhan_player_test.dart` with fake `MediaPlaybackControl` and a fake asset loader. Assertions:
```dart
test('play stops recitation before it starts the adhan', ...);        // Review Focus #4
test('preview plays the clip path, not the full asset', ...);
test('a second preview replaces the first instead of stacking', ...); // Review Focus #3
test('play before the plugin is ready is queued, not dropped', ...);  // Review Focus #5
test('a missing asset fails open: logs, leaves the player idle, never throws', ...);
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `flutter test test/adhan_player_test.dart` → FAIL.

- [ ] **Step 3: Implement the ports and the player**

One `AudioPlayer` inside the implementation. **Every source must carry a `MediaItem` tag** — `JustAudioBackground.init` runs in `main.dart:74` and throws on untagged sources. Mirror `just_audio_playback_service.dart:84-95,106-115` for the tag shape. `play` awaits `recitation?.stopForAdhan()` first, then `setAsset(track.assetPath)`; `preview` uses `track.clipPath`. Both guard on a `ready` callback and queue through a single `_pending` future (the same queue idiom `notifications_binding.dart:101` uses) so a cold-boot request is never dropped.

- [ ] **Step 4: Let recitation be stopped from the port**

Add `implements MediaPlaybackControl` to `JustAudioPlaybackService` and implement `stopForAdhan()` by stopping the player. Do **not** add the method to `PlaybackService` — that interface is implemented by 12 test fakes and changing it would force test edits.

- [ ] **Step 5: Add the notification action**

On the prayer notification (`AndroidNotificationDetails.actions`), add one action with a stable id (e.g. `adhan_play`) whose payload carries the track id. Handle it in the existing tap path (`notifications_binding.dart:181-201`) and route it in `router.dart` to `AdhanPlayer.play(trackId)`. A tap with an unknown track id must be ignored with a log, never a crash.

- [ ] **Step 6: Run the tests**

Run: `flutter test test/adhan_player_test.dart` → PASS. Then `flutter test` → all green (the 12 existing `PlaybackService` fakes must be untouched and still compile).

- [ ] **Step 7: Final gate**

`flutter analyze` → 0 issues.
`dart format --output=none --set-exit-if-changed lib test tools` → 0 changed.
`flutter test` → report the literal total.
*(Commit step omitted.)*

---

## Deferred (not in this plan)

- Autoplay at prayer time from a background wake (Doze, exact alarms, foreground-service policy).
- Per-prayer selection for all five prayers.
- User-imported adhan files.
- iOS notification sound wiring (`≤30 s`, `.caf`/`.aiff`/`.wav`).
- Rights clearance for the nine recordings (owner track, REL-03) — blocks store submission, not these tasks.
