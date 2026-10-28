# Performance & Correctness Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the verified performance, correctness, size, and energy defects from the 2026-10-27 audit without changing any frozen test and without shipping a regression.

**Architecture:** Five gated waves on one campaign branch, executed by parallel subagents in disjoint file lanes. Each task is TDD-first, produces one scoped commit, and is re-verified by the PM at source. Wave gates are `dart format`, `flutter analyze`, and the full `flutter test` suite. No push.

**Tech Stack:** Flutter 3.47.5 / Dart 3.13.4 · cubits + freezed · drift 2.35.2 · just_audio 0.10.6 · go_router 18 · flutter_local_notifications 22.

**Spec / evidence:** this document's "Verified findings" table (audit 2026-10-27, HEAD `b626751`, all claims re-read at source by the PM). There is no separate spec file.

---

## Global Constraints

Read `AGENTS.md` first. It is binding.

- **Mode:** pairing session with delegated subagents. One campaign branch, never branch-per-task.
- **No push, no PR, no remote mutation.** Pushes happen only in an owner-GO window.
- **Frozen tests are never edited.** Every new test goes in a **new file**. The four pins listed below block four otherwise-desirable changes; those are deferred, not forced.
- **Commits:** English, small, one concern, explicit pathspecs, never `git add -A`, never `-a`. Review `git status` and `git diff` before every commit.
- **Never touch/stage** `.vscode/settings.json` or `INSTRUCTIONS.md` (expected debris).
- **No new packages.** No l10n value changes. No new user-visible strings are needed by this plan.
- **Gates:** per task, run the new test file; per wave, run `dart format --output=none --set-exit-if-changed lib test tools`, `flutter analyze` (expect 0), and the full `flutter test` (record exact counts).
- **Known baseline flake:** `test/reader_route_reentry_test.dart` failed once in the full suite (726 passed, 1 failed) and passes alone. Do not "fix" it by editing the test; rerun alone and record.
- **Estimates:** any ms/MB/energy number not measured in this plan is labelled an estimate.

## Verified findings (the spec)

| # | Sev | Finding | Primary evidence |
|---|---|---|---|
| 1 | CRITICAL | Playback never leaves `loading`; pause/progress dead for the whole track. `play()` resolves at pause/end, but the cubit awaits it before emitting `playing`. | `just_audio_playback_service.dart:59`; `playback_cubit.dart:82-115,267-285`; just_audio `AudioPlayer.java:971-994` |
| 2 | HIGH | Quran search runs two unindexed `LIKE '%…%'` scans per keystroke, no debounce, no cancellation. | `quran_search_screen.dart:32-35`; `quran_search_cubit.dart:25-48`; `quran_search_repository.dart:22-25` |
| 3 | HIGH | Universal release APK is 66.5 MB because it ships 3 ABIs; `lib/` is 95.7%. arm64-only ≈25.4 MB. | measured APK; `android/app/build.gradle`; `ci.yml:41` |
| 4 | HIGH | Library pack install is not single-flight; re-entry starts a second writer on the same `.part`. | `library_cubit.dart:57-95`; `pack_downloader.dart:92-131,145`; `pack_store.dart:49` |
| 5 | HIGH | No prayer reminder after Isha (only today's list); azkar/wird never scheduled with no city. | `reminder_planner.dart:69-80`; `reminder_scheduling.dart:23-42` |
| 6 | HIGH | Bookmark toggle is read-then-write with no unique constraint → duplicates. | `ayah_repository.dart:48-60`; `tables.dart:52-60`; `app_database.dart:48-49` |
| 7 | MEDIUM | Audio downloads write the final path, never verify length, can mark truncated files `done`. | `audio_downloader.dart:108-151` |
| 8 | MEDIUM | Plan fingerprint survives a failed `cancelAll` → later identical plans silently skipped; applies interleave. | `notifications_binding.dart:272-300` |
| 9 | MEDIUM | Search/bookmark `loadMore` retries every scroll after failure; stale query page can merge into a new query. | `quran_search_cubit.dart:58-88`; `bookmarks_cubit.dart:68-78` |
| 10 | MEDIUM | Search-index rebuild normalizes 6,236 rows on the UI isolate at first open. | `connection.dart:218-231`; `search_index.dart:24-49` |
| 11 | MEDIUM | Home cards never refresh on return; stale card can overwrite last-read on tap. | `home_cubit.dart:40-62`; `reader_cubit.dart:74-79` |
| 12 | MEDIUM | Two `AppDatabase` wrappers share one executor (drift corruption warning in debug). | `connection.dart:197,240` |
| 13 | MEDIUM | Qibla sensor stays on for `inactive/hidden`; city pick never reloads qibla. | `qibla_screen.dart:58-70,104-109` |
| 14 | LOW | 1 Hz prayer ticker for minute copy, keeps firing in background. | `prayer_times_screen.dart:84-87` |
| 15 | MEDIUM | `PackReader` can retain 24 MB of decoded packs app-lifetime. | `pack_reader.dart:41-49,175-186` |
| 16 | MEDIUM | Backup preview stranded on system-back; emits after close can throw. | `backup_section.dart:36-55`; `backup_cubit.dart:132-140` |
| 17 | LOW | City picker pops the wrong route after a late location result. | `city_picker_screen.dart:95-112` |

## Frozen-test pins (do not cross without an owner ruling)

| Desired change | Pin | Decision |
|---|---|---|
| Remove reader save-on-load | `test/reader_cubit_test.dart:148` expects `lastRead == 8` after load | **Deferred.** Fix Home refresh (Task 10) instead. |
| Prayer 1 Hz → minute timer | `test/prayer_times_ticker_test.dart:80-84` advances 1 s and expects the countdown to move | **Deferred.** Add lifecycle pause only (Task 14). |
| Bind qibla sensor only when a city exists | `test/qibla_lifecycle_test.dart:61-64` starts with no selected city and expects a binding | **Deferred.** Add inactive/hidden pause + reload (Task 13). |
| Stabilize the full-suite flake | `test/reader_route_reentry_test.dart` is frozen | **Deferred.** Rerun alone and record; owner decision to unfreeze. |

## Execution model

**Roles:** the PM (this session) writes briefs, verifies every diff at source, runs wave gates, and integrates. A fresh executor subagent per task. Executors never push, never touch `docs/`, never edit existing tests.

**Lanes (disjoint file ownership, safe to run in parallel):**

- **Lane A — Playback:** `lib/features/recitation/playback/**`, `lib/features/recitation/presentation/playback/**`.
- **Lane B — Data integrity:** `lib/features/quran/data/ayah_repository.dart`, `lib/core/db/app_database.dart`, `lib/features/library/data/pack_downloader.dart`, `lib/features/notifications/data/reminder_planner.dart`, `lib/features/notifications/data/reminder_scheduling.dart`, `lib/features/notifications/data/notifications_binding.dart`, `lib/features/recitation/data/audio_downloader.dart`.
- **Lane C — Speed/home:** `lib/features/quran/presentation/search/**`, `lib/features/quran/presentation/bookmarks/bookmarks_cubit.dart`, `lib/core/db/search_index.dart`, `lib/core/db/connection.dart`, `lib/features/home/**`, `lib/app/route_observer.dart`, `lib/app/router.dart`.
- **Lane D — Build/size:** `.github/workflows/ci.yml`, `android/app/build.gradle`, `pubspec.yaml`, `README.md`.
- **Lane E — Lifecycle guards (after integration):** `lib/features/qibla/presentation/**`, `lib/features/prayer/presentation/prayer_times/prayer_times_screen.dart`, `lib/features/library/data/pack_reader.dart`, `lib/features/backup/presentation/**`, `lib/features/prayer/presentation/city_picker/city_picker_screen.dart`, `lib/app/app.dart`.

**Start gate for every executor (verbatim):**

```powershell
git rev-parse --short HEAD
git status --porcelain
git rev-list --count origin/main..HEAD
flutter --version
```

Expected: HEAD is the wave base given in the brief; porcelain is empty except `.vscode/settings.json` / `INSTRUCTIONS.md`; toolchain 3.47.5. Any other delta = STOP and report.

**Per-task loop:** RED test → run and see it fail → minimal implementation → run targeted test → run `flutter analyze` on the touched files (or full analyzer at wave end) → commit with the exact message → report `git show --stat` and the test tail.

**Wave gate (PM-owned):**

```powershell
dart format --output=none --set-exit-if-changed lib test tools
flutter analyze
flutter test
git status --porcelain
```

Record exact pass/fail counts and the SHA of every commit. The pre-existing flake, if it appears, is rerun alone:

```powershell
flutter test test/reader_route_reentry_test.dart
```

**Branch setup (PM, before Wave 1):**

```powershell
git switch -c fix/perf-audit-2026-10-27
git status --porcelain
```

Lane worktrees (only if running lanes in parallel):

```powershell
git worktree add ..\qyh-perf-a ..\..\qyh-perf-a -b lane-a/perf-2026-10-27
# repeat for b, c, d
```

If the owner prefers a single tree, run lanes sequentially on `fix/perf-audit-2026-10-27`. Do not branch per task.

---

# Wave 1 — P0 playback (Lane A)

### Task 1: Playback start/resume must not await the long-lived play future

**Files:**
- Modify: `lib/features/recitation/playback/just_audio_playback_service.dart:36-77`
- Modify: `lib/features/recitation/playback/playback_service.dart:21-29` (contract docs)
- Modify: `lib/features/recitation/presentation/playback/playback_cubit.dart:267-285`
- Test: `test/playback_start_contract_test.dart` (new)

**Interfaces:**
- Consumes: `PlaybackService.loadAndPlay`, `PlaybackService.resume`, `PlaybackCubit`.
- Produces: the contract “load/resume completes when the request is issued, not when playback later pauses/ends”; `PlaybackLoading → PlaybackPlaying` is a legal transition.

**Root cause:** just_audio's `play()` future is completed by `pause()`, `stop()`, or `STATE_ENDED` (`just_audio-0.10.6/android/.../AudioPlayer.java:971-994,391-394`; Dart `just_audio.dart:1096,1121`). Awaiting it in `loadAndPlay` blocks `_start` before `emit(playing)`, and awaiting it in `resume()` blocks `toggle()`. A later pause completes the blocked future and emits `playing` *after* the pause.

- [ ] **Step 1: Write the failing test**

Create `test/playback_start_contract_test.dart`:

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/playback/playback_service.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_state.dart';

import 'support/test_db.dart';

/// Models the production service: `loadAndPlay` stays pending until the
/// platform reports the load is done; a `playing` event arrives first.
class _PendingLoadService implements PlaybackService {
  final playingCtrl = StreamController<bool>.broadcast();
  final positionCtrl = StreamController<Duration>.broadcast();
  final durationCtrl = StreamController<Duration?>.broadcast();
  final loadGate = Completer<void>();

  @override
  Stream<bool> playingStream() => playingCtrl.stream;

  @override
  Stream<Duration> positionStream() => positionCtrl.stream;

  @override
  Stream<Duration?> durationStream() => durationCtrl.stream;

  @override
  Future<void> loadAndPlay(PlaybackSource source) => loadGate.future;

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}
}

void main() {
  late AppDatabase db;
  late Directory tempRoot;
  late _PendingLoadService service;
  late PlaybackCubit cubit;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_playback_contract');
    service = _PendingLoadService();
    cubit = PlaybackCubit(
      service: service,
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
    );
  });

  tearDown(() async {
    await cubit.close();
    await service.playingCtrl.close();
    await service.positionCtrl.close();
    await service.durationCtrl.close();
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  test('a playing event moves the mini player out of loading before load returns',
      () async {
    await db.into(db.reciters).insert(
          RecitersCompanion.insert(
            id: '51-53',
            reciterName: 'عبدالباسط عبدالصمد',
            moshafName: 'حفص مرتل',
            server: 'https://server.example/mp3',
            surahList: '1',
            surahTotal: 114,
          ),
        );
    final row = (await ReciterRepository(db).byId('51-53'))!;

    final pending = cubit.playSurah(row, 1);
    // Wait until the cubit has bound the streams (the DB lookup runs first).
    for (var i = 0; i < 100 && !service.playingCtrl.hasListener; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(service.playingCtrl.hasListener, isTrue);
    expect(cubit.state, isA<PlaybackLoading>());

    service.playingCtrl.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<PlaybackPlaying>());

    service.loadGate.complete();
    await pending;
    expect(cubit.state, isA<PlaybackPlaying>());
  });

  test('a pause before load settles is not undone by the late load', () async {
    await db.into(db.reciters).insert(
          RecitersCompanion.insert(
            id: '51-53',
            reciterName: 'عبدالباسط عبدالصمد',
            moshafName: 'حفص مرتل',
            server: 'https://server.example/mp3',
            surahList: '1',
            surahTotal: 114,
          ),
        );
    final row = (await ReciterRepository(db).byId('51-53'))!;

    final pending = cubit.playSurah(row, 1);
    for (var i = 0; i < 100 && !service.playingCtrl.hasListener; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    service.playingCtrl.add(true);
    await Future<void>.delayed(Duration.zero);

    await cubit.toggle(); // pause
    expect(cubit.state, isA<PlaybackPaused>());

    service.loadGate.complete();
    await pending;
    expect(cubit.state, isA<PlaybackPaused>(),
        reason: 'the late load completion must not emit playing after a pause');
  });
}
```

- [ ] **Step 2: Run it and confirm RED**

```powershell
flutter test test/playback_start_contract_test.dart
```

Expected: the first test fails at `expect(cubit.state, isA<PlaybackPlaying>())` (state is `PlaybackLoading`).

- [ ] **Step 3: Implement the service contract**

In `just_audio_playback_service.dart`, add `import 'dart:developer' as dev;`. Replace `await _player.play();` at the end of `loadAndPlay` with:

```dart
    // just_audio's play() future resolves on pause/stop/completion, not when
    // playback starts. Awaiting it here would block the cubit's loading state
    // for the whole track and let a later pause emit "playing".
    unawaited(_player.play().catchError((Object error, StackTrace stackTrace) {
      dev.log('playback play request failed',
          name: 'quran_yahdi/playback',
          error: error,
          stackTrace: stackTrace);
    }));
```

And `resume`:

```dart
  @override
  Future<void> resume() async {
    unawaited(_player.play().catchError((Object error, StackTrace stackTrace) {
      dev.log('playback resume request failed',
          name: 'quran_yahdi/playback',
          error: error,
          stackTrace: stackTrace);
    }));
  }
```

`unawaited` is already available via `dart:async`.

In `playback_service.dart`, extend the `loadAndPlay`/`resume` docs:

```dart
  /// Issues the load and the play request.
  ///
  /// The returned future completes when the request has been issued; it must
  /// NOT wait for playback to pause, stop, or finish.
  Future<void> loadAndPlay(PlaybackSource source);
  ...
  /// Issues the resume request; completes when issued, not when playback ends.
  Future<void> resume();
```

- [ ] **Step 4: Implement the cubit guard**

Also guard the post-load emit in `_start` so a user pause during a slow load is not undone:

```dart
      await _service.loadAndPlay(source);
      if (isClosed || episode != _episode) return;
      if (state is! PlaybackLoading) return;
      emit(PlaybackState.playing(
        reciterName: _reciterName,
        surahNumber: surahNumber,
      ));
```

In `playback_cubit.dart`, `_onPlayingChanged`:

```dart
  void _onPlayingChanged(bool playing) {
    if (isClosed) return;
    final state = this.state;
    if (playing && state is PlaybackLoading && state.reciterName != null) {
      emit(PlaybackState.playing(
        reciterName: state.reciterName!,
        surahNumber: state.surahNumber,
      ));
    } else if (playing && state is PlaybackPaused) {
      emit(PlaybackState.playing(
        reciterName: state.reciterName,
        surahNumber: state.surahNumber,
        position: state.position,
        duration: state.duration,
      ));
    } else if (!playing && state is PlaybackPlaying) {
      emit(PlaybackState.paused(
        reciterName: state.reciterName,
        surahNumber: state.surahNumber,
        position: state.position,
        duration: state.duration,
      ));
    }
  }
```

- [ ] **Step 5: Run the new test and the existing playback tests**

```powershell
flutter test test/playback_start_contract_test.dart test/playback_cubit_test.dart test/playback_completion_test.dart test/playback_races_test.dart test/playback_download_lookup_test.dart
```

Expected: all pass.

- [ ] **Step 6: Commit**

```powershell
git add lib/features/recitation/playback/just_audio_playback_service.dart lib/features/recitation/playback/playback_service.dart lib/features/recitation/presentation/playback/playback_cubit.dart test/playback_start_contract_test.dart
git commit -m "fix(playback): stop awaiting long-lived play futures"
```

**Device verification (PM, after wave integration):** install the release APK, play a surah, confirm within 2 s that the mini player shows pause (not a spinner), position advances, pause works, resume works, and pause again does not flip the UI back to playing.

---

### Task 2: Throttle playback position to 1 Hz

**Files:**
- Modify: `lib/features/recitation/playback/just_audio_playback_service.dart:24-25`
- Modify: `lib/features/recitation/presentation/playback/playback_cubit.dart:287-305`
- Test: `test/playback_position_throttle_test.dart` (new)

**Interfaces:** `PlaybackCubit` emits at most one position update per second.

- [ ] **Step 1: Write the failing test**

Create `test/playback_position_throttle_test.dart` using the same fake service/DB setup as Task 1, then:

```dart
  test('sub-second position ticks do not rebuild the progress row', () async {
    // ... seed reciter `51-53` exactly as in Task 1 ...
    final pending = cubit.playSurah(row, 1);
    service.playingCtrl.add(true);
    await Future<void>.delayed(Duration.zero);

    service.positionCtrl.add(const Duration(milliseconds: 200));
    service.positionCtrl.add(const Duration(milliseconds: 400));
    service.positionCtrl.add(const Duration(milliseconds: 800));
    await Future<void>.delayed(Duration.zero);

    expect((cubit.state as PlaybackPlaying).position, Duration.zero);

    service.positionCtrl.add(const Duration(seconds: 1));
    await Future<void>.delayed(Duration.zero);
    expect((cubit.state as PlaybackPlaying).position,
        const Duration(seconds: 1));

    service.loadGate.complete();
    await pending;
  });
```

- [ ] **Step 2: Run RED**

```powershell
flutter test test/playback_position_throttle_test.dart
```

Expected: fails because the 200 ms tick is already emitted.

- [ ] **Step 3: Implement**

`just_audio_playback_service.dart`:

```dart
  @override
  Stream<Duration> positionStream() => _player.createPositionStream(
        minPeriod: const Duration(seconds: 1),
        maxPeriod: const Duration(seconds: 1),
      );
```

`playback_cubit.dart` `_onPositionChanged`, before building the new state:

```dart
  void _onPositionChanged(Duration position) {
    if (isClosed) return;
    final state = this.state;
    final current = switch (state) {
      PlaybackPlaying(position: final p) => p,
      PlaybackPaused(position: final p) => p,
      _ => null,
    };
    // The plugin stream is already capped at 1 Hz; this dedupe also protects
    // the UI from a replayed tick at the same wall-clock second.
    if (current != null && current.inSeconds == position.inSeconds) return;
    ...
  }
```

- [ ] **Step 4: Run the playback suite** (same command as Task 1 Step 5 plus the new file). Expected: all pass.

- [ ] **Step 5: Commit**

```powershell
git add lib/features/recitation/playback/just_audio_playback_service.dart lib/features/recitation/presentation/playback/playback_cubit.dart test/playback_position_throttle_test.dart
git commit -m "perf(playback): throttle position updates to 1 Hz"
```

---

# Wave 2 — P1 data integrity (Lane B)

### Task 3: One bookmark per ayah

**Files:**
- Modify: `lib/core/db/app_database.dart:48-49`
- Modify: `lib/features/quran/data/ayah_repository.dart:47-60`
- Test: `test/bookmark_uniqueness_test.dart` (new)

**Interfaces:** `AyahSource.toggleBookmark(int)` becomes atomic; the schema rejects a duplicate `ayah_id`.

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';

import 'support/test_db.dart';

void main() {
  test('the schema rejects a duplicate bookmark for the same ayah', () async {
    final db = newTestDb();
    addTearDown(db.close);

    await db.into(db.bookmarks).insert(BookmarksCompanion.insert(ayahId: 8));
    await expectLater(
      db.into(db.bookmarks).insert(BookmarksCompanion.insert(ayahId: 8)),
      throwsA(anything),
    );
  });

  test('concurrent toggles never leave two rows for one ayah', () async {
    final db = newTestDb();
    addTearDown(db.close);
    final repo = AyahRepository(db);

    await Future.wait([repo.toggleBookmark(8), repo.toggleBookmark(8)]);

    final rows = await db.select(db.bookmarks).get();
    expect(rows.length, lessThanOrEqualTo(1));
  });
}
```

- [ ] **Step 2: Run RED**

```powershell
flutter test test/bookmark_uniqueness_test.dart
```

Expected: the first test fails because the duplicate insert succeeds.

- [ ] **Step 3: Implement the schema repair**

Replace the `idx_bookmarks_ayah` statement in `beforeOpen` with:

```dart
          // One bookmark per ayah is a user-visible invariant. Repair any
          // duplicates left by the old read-then-write toggle before the
          // unique index is created (a failed CREATE would abort every open).
          await customStatement(
              'DELETE FROM bookmarks WHERE id NOT IN '
              '(SELECT MIN(id) FROM bookmarks GROUP BY ayah_id)');
          await customStatement(
              'DROP INDEX IF EXISTS idx_bookmarks_ayah');
          await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_bookmarks_ayah '
              'ON bookmarks(ayah_id)');
```

- [ ] **Step 4: Implement the atomic toggle**

```dart
  @override
  Future<void> toggleBookmark(int ayahId) {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.bookmarks)
            ..where((b) => b.ayahId.equals(ayahId)))
          .getSingleOrNull();
      if (existing == null) {
        await _db.into(_db.bookmarks).insert(
              BookmarksCompanion.insert(ayahId: ayahId),
              mode: InsertMode.insertOrIgnore,
            );
      } else {
        await (_db.delete(_db.bookmarks)
              ..where((b) => b.ayahId.equals(ayahId)))
            .go();
      }
    });
  }
```

- [ ] **Step 5: Run the bookmark suite**

```powershell
flutter test test/bookmark_uniqueness_test.dart test/bookmarks_paging_test.dart test/bookmarks_screen_test.dart test/bookmarks_delete_test.dart test/reader_cubit_test.dart
```

- [ ] **Step 6: Commit**

```powershell
git add lib/core/db/app_database.dart lib/features/quran/data/ayah_repository.dart test/bookmark_uniqueness_test.dart
git commit -m "fix(bookmarks): enforce one bookmark per ayah"
```

---

### Task 4: Single-flight library installs

**Files:**
- Modify: `lib/features/library/data/pack_downloader.dart:38-132`
- Test: `test/pack_install_single_flight_test.dart` (new)

**Interfaces:** `PackDownloader.install` returns the shared in-flight future for the same pack id; every caller receives the same `File`.

- [ ] **Step 1: Write the failing test**

Model it on `test/pack_downloader_test.dart` (real `HttpServer` + `Dio`). The response is gated so two calls overlap:

```dart
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/library/data/library_catalog.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';

import 'support/test_db.dart';

void main() {
  test('two concurrent installs of one pack share one request', () async {
    final db = newTestDb();
    addTearDown(db.close);
    final tempRoot = await Directory.systemTemp.createTemp('qy_pack_single');
    addTearDown(() => tempRoot.delete(recursive: true));

    var requests = 0;
    final gate = Completer<void>();
    final server = await HttpServer.bind('127.0.0.1', 0);
    addTearDown(() => server.close(force: true));
    server.listen((req) async {
      requests++;
      await gate.future;
      req.response.write('{"quran":[{"chapter":1,"verse":1,"text":"ب"}]}');
      await req.response.close();
    });

    final downloader = PackDownloader(
      db,
      dio: Dio(),
      libraryRootResolver: () async => tempRoot,
    );
    final pack = LibraryPackInfo(
      id: 'tp1',
      kind: LibraryPackKind.translation,
      language: 'ar',
      titleAr: 'حزمة',
      titleEn: 'Pack',
      sourceUrl: 'http://127.0.0.1:${server.port}/translation/tp1.min.json',
      approxSizeMb: 0.001,
      version: '1',
    );

    final first = downloader.install(pack);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final second = downloader.install(pack);
    gate.complete();

    final files = await Future.wait([first, second]);
    expect(requests, 1);
    expect(files[0].path, files[1].path);
    expect(File('${files[0].path}.part').existsSync(), isFalse);
  });
}
```

- [ ] **Step 2: Run RED**

```powershell
flutter test test/pack_install_single_flight_test.dart
```

Expected: `requests` is 2, or one install fails with a truncated/invalid pack.

- [ ] **Step 3: Implement**

Rename the existing body to `_installOnce` and add the gate:

```dart
  final Map<String, Future<File>> _installs = {};

  /// Installs a pack at most once at a time. Concurrent callers share the
  /// in-flight future; the second caller gets the same promoted file and does
  /// not open a second writer on the same `.part`. Progress callbacks belong
  /// to the caller that started the install.
  Future<File> install(
    LibraryPackInfo pack, {
    void Function(int received, int total)? onProgress,
  }) {
    final inFlight = _installs[pack.id];
    if (inFlight != null) return inFlight;
    final future = _installOnce(pack, onProgress: onProgress);
    _installs[pack.id] = future;
    future
        .whenComplete(() {
          if (identical(_installs[pack.id], future)) {
            _installs.remove(pack.id);
          }
        })
        .ignore();
    return future;
  }

  Future<File> _installOnce(
    LibraryPackInfo pack, {
    void Function(int received, int total)? onProgress,
  }) async {
    // ... the previous install() body verbatim ...
  }
```

- [ ] **Step 4: Run the library/notification-adjacent tests**

```powershell
flutter test test/pack_install_single_flight_test.dart test/pack_downloader_test.dart test/library_cubit_test.dart test/library_screen_test.dart test/library_uninstall_failure_test.dart
```

- [ ] **Step 5: Commit**

```powershell
git add lib/features/library/data/pack_downloader.dart test/pack_install_single_flight_test.dart
git commit -m "fix(library): make pack installs single-flight"
```

---

### Task 5: Schedule tomorrow's Fajr and city-free azkar/wird

**Files:**
- Modify: `lib/features/notifications/data/reminder_planner.dart:58-104`
- Modify: `lib/features/notifications/data/reminder_scheduling.dart:15-46`
- Test: `test/reminder_gap_test.dart` (new)

**Interfaces:** `planReminders` gains `PrayerChoice? nextPrayer` (optional, default null). `scheduleReminders` composes azkar/wird outside the city gate and passes `prayer.nextPrayer(...)` when a city exists.

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_scheduling.dart';

class _NoCity implements CitySource {
  @override
  Future<City?> selectedCity() async => null;
  @override
  Future<void> select(City city) async {}
}

class _Prayer implements PrayerTimesPort {
  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) =>
      const <PrayerChoice>[];
  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) =>
      PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 16, 4, 45));
}

class _Settings implements ReminderSettingsPort {
  @override
  Future<bool> azkarEnabled() async => true;
  @override
  Future<String?> azkarTimeHm() async => '06:30';
  @override
  Future<bool> wirdEnabled() async => true;
  @override
  Future<String?> wirdTimeHm() async => '20:00';
  @override
  Future<void> setAzkarEnabled(bool enabled) async {}
  @override
  Future<void> setAzkarTime(String hm) async {}
  @override
  Future<void> setWirdEnabled(bool enabled) async {}
  @override
  Future<void> setWirdTime(String hm) async {}
  @override
  Future<void> reschedule({
    required CitySource city,
    required PrayerTimesPort prayer,
    required ReminderSchedulerPort scheduler,
  }) async {}
}

class _Scheduler implements ReminderSchedulerPort {
  List<ScheduledReminder>? plan;
  @override
  Future<bool> ensurePermissions() async => true;
  @override
  Future<void> scheduleAll(List<ScheduledReminder> reminders) async {
    plan = List<ScheduledReminder>.of(reminders);
  }
}

ReminderTexts _texts() => ReminderTexts(
      prayerTitle: (name) => 'prayer ${name.name}',
      azkarTitle: 'azkar',
      wirdTitle: 'wird',
    );

void main() {
  test('after Isha the plan uses the supplied next prayer (tomorrow Fajr)',
      () {
    final plan = planReminders(
      now: DateTime(2026, 3, 15, 21, 0),
      todayPrayers: [
        PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 15, 4, 45)),
        PrayerChoice(PrayerName.isha, DateTime(2026, 3, 15, 19, 30)),
      ],
      nextPrayer: PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 16, 4, 45)),
      azkarEnabled: false,
      azkarTimeHm: null,
      texts: _texts(),
    );

    expect(plan, hasLength(1));
    expect(plan.single.id, prayerReminderId);
    expect(plan.single.fireAt, DateTime(2026, 3, 16, 4, 45));
  });

  test('no city still schedules azkar and wird', () async {
    final scheduler = _Scheduler();
    await scheduleReminders(
      city: _NoCity(),
      prayer: _Prayer(),
      settings: _Settings(),
      scheduler: scheduler,
      now: DateTime(2026, 3, 15, 5, 0),
    );

    final ids = scheduler.plan!.map((r) => r.id).toSet();
    expect(ids, containsAll({azkarReminderId, wirdReminderId}));
    expect(ids, isNot(contains(prayerReminderId)));
  });
}
```

- [ ] **Step 2: Run RED**

```powershell
flutter test test/reminder_gap_test.dart
```

Expected: the first test has no prayer reminder; the second receives an empty plan.

- [ ] **Step 3: Implement the planner**

Add the parameter and fallback:

```dart
List<ScheduledReminder> planReminders({
  required DateTime now,
  required List<PrayerChoice> todayPrayers,
  PrayerChoice? nextPrayer,
  required bool azkarEnabled,
  ...
}) {
  final byId = <int, ScheduledReminder>{};

  var prayerPlanned = false;
  for (final choice in todayPrayers) {
    if (choice.name == PrayerName.sunrise) continue;
    if (!choice.time.isAfter(now)) continue;
    byId[prayerReminderId] = ScheduledReminder(
      id: prayerReminderId,
      fireAt: choice.time,
      title: texts.prayerTitle(choice.name),
      payload: prayerReminderPayload,
    );
    prayerPlanned = true;
    break;
  }
  if (!prayerPlanned &&
      nextPrayer != null &&
      nextPrayer.time.isAfter(now)) {
    byId[prayerReminderId] = ScheduledReminder(
      id: prayerReminderId,
      fireAt: nextPrayer.time,
      title: texts.prayerTitle(nextPrayer.name),
      payload: prayerReminderPayload,
    );
  }
  // ... azkar and wird blocks unchanged ...
}
```

- [ ] **Step 4: Implement the scheduling path**

Replace `scheduleReminders`'s body with a city-independent composition:

```dart
    final selected = await city.selectedCity();
    final nowLocal = now ?? DateTime.now();
    final loc = lookupAppLocalizations(const Locale('ar'));
    final plan = planReminders(
      now: nowLocal,
      todayPrayers: selected == null
          ? const <PrayerChoice>[]
          : prayer.today(selected.coordinates, nowLocal),
      nextPrayer:
          selected == null ? null : prayer.nextPrayer(selected.coordinates, nowLocal),
      azkarEnabled: await settings.azkarEnabled(),
      azkarTimeHm: await settings.azkarTimeHm(),
      wirdEnabled: await settings.wirdEnabled(),
      wirdTimeHm: await settings.wirdTimeHm(),
      texts: ReminderTexts(
        prayerTitle: (name) => loc.reminderNextPrayer(name.label(loc)),
        azkarTitle: loc.reminderAzkar,
        wirdTitle: loc.reminderWird,
      ),
    );
    await scheduler.scheduleAll(plan);
```

- [ ] **Step 5: Run the reminder suite**

```powershell
flutter test test/reminder_gap_test.dart test/reminder_planner_test.dart test/wird_reminder_planner_test.dart test/wird_reminder_routing_test.dart test/reminder_notification_copy_test.dart test/prayer_times_cubit_test.dart
```

- [ ] **Step 6: Commit**

```powershell
git add lib/features/notifications/data/reminder_planner.dart lib/features/notifications/data/reminder_scheduling.dart test/reminder_gap_test.dart
git commit -m "fix(notifications): schedule tomorrow Fajr and city-free azkar/wird"
```

---

### Task 6: Invalidate the plan fingerprint when alarms are cleared

**Files:**
- Modify: `lib/features/notifications/data/notifications_binding.dart:249-300`
- Test: `test/notification_schedule_failure_test.dart` (new)

**Interfaces:** `scheduleAll` serializes applies; a failed apply leaves `_appliedPlan == null` because `cancelAll` already ran.

- [ ] **Step 1: Write the failing test**

Copy the MethodChannel harness from `test/notifications_binding_scheduling_test.dart` into a new file. Then:

```dart
  test('a failed plan does not block re-applying the previous plan', () async {
    final binding = NotificationsBinding();
    await binding.init();

    final planA = [_reminder(id: 1, title: 'Azkar')];
    await binding.scheduleAll(planA);
    final afterA = calls.where((c) => c.method == 'zonedSchedule').length;
    expect(afterA, 1);

    throwOn = 'zonedSchedule';
    await binding.scheduleAll([_reminder(id: 2, title: 'Wird')]);
    throwOn = null;

    await binding.scheduleAll(planA);
    final afterRetry = calls.where((c) => c.method == 'zonedSchedule').length;
    expect(afterRetry, greaterThanOrEqualTo(2),
        reason: 'cancelAll cleared the alarms, so plan A must be re-scheduled');
  });
```

- [ ] **Step 2: Run RED**

```powershell
flutter test test/notification_schedule_failure_test.dart
```

Expected: `afterRetry == 1` (the second apply was skipped).

- [ ] **Step 3: Implement**

In `_applyPlan`, immediately before `cancelAll`:

```dart
      // The alarms are about to be cleared. From this point the old
      // fingerprint is a lie even if a later zonedSchedule throws.
      _appliedPlan = null;
      await _plugin.cancelAll();
```

Serialize applies in `scheduleAll`:

```dart
  Future<void>? _applyQueue;

  @override
  Future<void> scheduleAll(List<ScheduledReminder> reminders) async {
    if (!_ready || _details == null) {
      if (_initFailed) return;
      _pendingPlan = List<ScheduledReminder>.of(reminders);
      return;
    }
    final previous = _applyQueue;
    final run = () async {
      if (previous != null) {
        try {
          await previous;
        } on Object {
          // _applyPlan swallows its own failures; keep the chain alive.
        }
      }
      await _applyPlan(reminders);
    }();
    _applyQueue = run;
    await run;
  }
```

- [ ] **Step 4: Run the notification suite**

```powershell
flutter test test/notification_schedule_failure_test.dart test/notifications_binding_scheduling_test.dart test/notification_payload_routing_test.dart test/boot_notification_grace_test.dart
```

- [ ] **Step 5: Commit**

```powershell
git add lib/features/notifications/data/notifications_binding.dart test/notification_schedule_failure_test.dart
git commit -m "fix(notifications): invalidate plan fingerprint after cancelAll"
```

---

### Task 7: Stage audio downloads and reject truncated bodies

**Files:**
- Modify: `lib/features/recitation/data/audio_downloader.dart:101-153`
- Test: `test/audio_download_truncation_test.dart` (new)

**Interfaces:** `downloadSurah` writes `<name>.mp3.part`, verifies `received == total` when `total > 0`, then promotes. Failure deletes both files. The `IOSink` is opened only after the null-body check.

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';

import 'support/test_db.dart';

class _ShortAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    return ResponseBody(
      Stream.fromIterable([Uint8List.fromList(List<int>.filled(10, 7))]),
      200,
      headers: {
        Headers.contentLengthHeader: ['1000'],
        Headers.contentTypeHeader: ['audio/mpeg'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('a body shorter than content-length is failed and leaves no file',
      () async {
    final db = newTestDb();
    addTearDown(db.close);
    final root = await Directory.systemTemp.createTemp('qy_audio_short');
    addTearDown(() => root.delete(recursive: true));
    await db.into(db.reciters).insert(RecitersCompanion.insert(
          id: '51-53',
          reciterName: 'عبدالباسط عبدالصمد',
          moshafName: 'حفص مرتل',
          server: 'https://server.example/mp3',
          surahList: '1',
          surahTotal: 114,
        ));
    final reciter = await (db.select(db.reciters)).getSingle();
    final downloader = AudioDownloader(
      db,
      dio: Dio()..httpClientAdapter = _ShortAdapter(),
      audioRootResolver: () async => root,
    );

    await expectLater(
      downloader.downloadSurah(reciter: reciter, surahNumber: 1),
      throwsA(isA<DownloadFailure>()),
    );

    final row = await (db.select(db.downloads)).getSingle();
    expect(row.status, 'failed');
    expect(File(row.path!).existsSync(), isFalse);
    expect(File('${row.path!}.part').existsSync(), isFalse);
  });
}
```

- [ ] **Step 2: Run RED**

```powershell
flutter test test/audio_download_truncation_test.dart
```

Expected: no throw; the row is marked `done`.

- [ ] **Step 3: Implement**

In `downloadSurah`:

```dart
    final target = await _targetFile(reciter.id, surahNumber);
    final part = File('${target.path}.part');
    ...
      final body = res.data;
      if (body == null) throw DownloadFailure('empty audio response');
      final sink = part.openWrite();
      try {
        await for (final chunk in body.stream) {
          received += chunk.length;
          if (received > maxAcceptedBytes(total)) {
            throw DownloadFailure('audio stream exceeded its declared size');
          }
          sink.add(chunk);
          if (throttle.shouldReport(received, total)) {
            onProgress?.call(received, total);
          }
        }
        if (total > 0 && received != total) {
          throw DownloadFailure('audio body ended before its declared size');
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      if (await target.exists()) await target.delete();
      final promoted = await part.rename(target.path);
      final size = await promoted.length();
      await _markStatus(
          reciter.id, surahNumber, DownloadStatus.done, size, promoted.path);
      return promoted;
    } on Object {
      await _markStatus(
          reciter.id, surahNumber, DownloadStatus.failed, 0, target.path);
      if (await part.exists()) await part.delete();
      if (await target.exists()) await target.delete();
      rethrow;
    }
```

- [ ] **Step 4: Run the download suite**

```powershell
flutter test test/audio_download_truncation_test.dart test/audio_downloader_test.dart test/downloads_cancel_test.dart test/downloads_cubit_test.dart test/downloads_queue_dedupe_test.dart
```

- [ ] **Step 5: Commit**

```powershell
git add lib/features/recitation/data/audio_downloader.dart test/audio_download_truncation_test.dart
git commit -m "fix(downloads): stage audio files and reject truncated bodies"
```

---

# Wave 3 — P1 speed and home (Lane C)

### Task 8: Debounce search and guard paging

**Files:**
- Modify: `lib/features/quran/presentation/search/quran_search_cubit.dart`
- Modify: `lib/features/quran/presentation/search/quran_search_screen.dart:32-36`
- Modify: `lib/features/quran/presentation/bookmarks/bookmarks_cubit.dart:68-78`
- Test: `test/search_debounce_and_guards_test.dart` (new)

**Interfaces:** `search()` stays immediate (frozen tests call it). New `onQueryChanged()` is the debounced UI entry point. `loadMore()` captures the query and refuses to merge a stale page. Both paging guards include `moreFailed`.

- [ ] **Step 1: Write the failing tests**

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/quran/data/quran_search_source.dart';
import 'package:quran_yahdi/features/quran/presentation/search/quran_search_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/search/quran_search_state.dart';

QuranSearchHit _hit(int id) => QuranSearchHit(
      ayahId: id,
      surahId: 1,
      numberInSurah: id,
      surahNameAr: 'الفاتحة',
      textImlaei: 'نص $id',
    );

QuranSearchPage _page(List<int> ids, {required bool hasMore}) =>
    QuranSearchPage(
      hits: [for (final id in ids) _hit(id)],
      total: ids.length,
      hasMore: hasMore,
    );

class _Fake implements QuranSearchSource {
  _Fake(this.onSearch);
  final Future<QuranSearchPage> Function(String q, int? after) onSearch;
  final queries = <String>[];

  @override
  Future<QuranSearchPage> search(String query,
      {int? afterAyahId, int limit = kQuranSearchPageSize}) {
    queries.add('$query|$afterAyahId');
    return onSearch(query, afterAyahId);
  }
}

void main() {
  test('rapid keystrokes collapse into one query', () async {
    final source = _Fake((q, _) async => _page([1], hasMore: false));
    final cubit =
        QuranSearchCubit(source, debounce: const Duration(milliseconds: 40));
    addTearDown(cubit.close);

    cubit.onQueryChanged('الص');
    cubit.onQueryChanged('الصلا');
    cubit.onQueryChanged('الصلاة');
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(source.queries, ['الصلاة|null']);
  });

  test('a failed next page is not retried by every scroll notification',
      () async {
    final source = _Fake((q, after) async {
      if (after == null) return _page([1, 2], hasMore: true);
      throw StateError('page failed');
    });
    final cubit = QuranSearchCubit(source, debounce: Duration.zero);
    addTearDown(cubit.close);

    await cubit.search('الصلاة');
    await cubit.loadMore();
    await cubit.loadMore();
    await cubit.loadMore();

    final calls = source.queries.where((q) => q.endsWith('|2')).length;
    expect(calls, 1, reason: 'only the explicit Retry may reissue the page');
  });

  test('a page from the old query cannot merge into the new query', () async {
    final oldPage = Completer<QuranSearchPage>();
    final newPage = Completer<QuranSearchPage>();
    final source = _Fake((q, after) {
      if (q == 'قديم' && after == null) {
        return Future.value(_page([1, 2], hasMore: true));
      }
      if (q == 'قديم') return oldPage.future;
      return newPage.future;
    });
    final cubit = QuranSearchCubit(source, debounce: Duration.zero);
    addTearDown(cubit.close);

    await cubit.search('قديم');
    final more = cubit.loadMore();
    final fresh = cubit.search('جديد');
    newPage.complete(_page([9], hasMore: false));
    await fresh;
    oldPage.complete(_page([3], hasMore: false));
    await more;

    final state = cubit.state as QuranSearchReady;
    expect(state.query, 'جديد');
    expect(state.hits.map((h) => h.ayahId), [9]);
  });
}
```

- [ ] **Step 2: Run RED**

```powershell
flutter test test/search_debounce_and_guards_test.dart
```

Expected: `onQueryChanged` does not exist (compile error); after adding only the method, the retry and stale-query tests fail.

- [ ] **Step 3: Implement the cubit**

```dart
  QuranSearchCubit(
    this._source, {
    Duration debounce = const Duration(milliseconds: 300),
  })  : _debounceDuration = debounce,
        super(const QuranSearchState.ready(
            query: '', hits: [], total: 0, hasMore: false));

  final Duration _debounceDuration;
  Timer? _debounce;

  /// UI entry point: coalesces typing bursts. [search] remains the immediate
  /// path used by tests and by a restored query.
  void onQueryChanged(String rawQuery) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () => search(rawQuery));
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
```

In `loadMore`, add `current.moreFailed` to the guard, capture `final query = current.query;`, and after the generation check:

```dart
      final latest = state;
      if (latest is! QuranSearchReady || latest.query != query) return;
```

Screen:

```dart
              onChanged: context.read<QuranSearchCubit>().onQueryChanged,
```

Bookmarks guard:

```dart
    if (pager == null ||
        current is! BookmarksReady ||
        !current.hasMore ||
        current.loadingMore ||
        current.moreFailed ||
        current.lastBookmarkId <= 0) {
      return;
    }
```

- [ ] **Step 4: Run the search/bookmark suite**

```powershell
flutter test test/search_debounce_and_guards_test.dart test/quran_search_cubit_test.dart test/quran_search_screen_test.dart test/quran_search_repository_test.dart test/bookmarks_paging_test.dart test/bookmarks_screen_test.dart
```

- [ ] **Step 5: Commit**

```powershell
git add lib/features/quran/presentation/search/quran_search_cubit.dart lib/features/quran/presentation/search/quran_search_screen.dart lib/features/quran/presentation/bookmarks/bookmarks_cubit.dart test/search_debounce_and_guards_test.dart
git commit -m "perf(search): debounce queries and guard paging"
```

---

### Task 9: Build the search index off the UI isolate

**Files:**
- Modify: `lib/core/db/search_index.dart:1-49`
- Test: existing `test/search_index_build_test.dart` is the proof (frozen, unchanged).

**Interfaces:** `ensureQuranSearchIndex(AppDatabase)` signature unchanged. Rows are projected to plain `(int, String)` records on the UI isolate, then normalized in a worker isolate.

- [ ] **Step 1: Baseline the existing test**

```powershell
flutter test test/search_index_build_test.dart
```

Expected: pass (3-4 tests).

- [ ] **Step 2: Implement**

```dart
import 'dart:isolate';

/// Pure projection used by the worker isolate.
List<(int, String)> normalizeSearchEntries(List<(int, String)> input) => [
      for (final (id, text) in input)
        (id, normalizeArabic(text).toLowerCase()),
    ];

Future<void> rebuildQuranSearchIndex(AppDatabase db) async {
  final rows =
      await db.customSelect('SELECT id, text_imlaei FROM ayahs').get();
  // Only plain records cross the isolate boundary: drift QueryRows are not a
  // stable transfer type.
  final input = [
    for (final row in rows)
      (row.read<int>('id'), row.read<String>('text_imlaei')),
  ];
  final entries = await Isolate.run(() => normalizeSearchEntries(input));
  // ... the existing transaction/batch unchanged ...
}
```

- [ ] **Step 3: Verify**

```powershell
flutter test test/search_index_build_test.dart test/quran_search_asset_test.dart test/quran_search_schema_test.dart
```

Expected: all pass; no test hangs.

- [ ] **Step 4: Commit**

```powershell
git add lib/core/db/search_index.dart
git commit -m "perf(db): build the search index off the UI isolate"
```

---

### Task 10: Refresh Home when it becomes visible again

**Files:**
- Create: `lib/app/route_observer.dart`
- Modify: `lib/app/router.dart:79-91` (add `observers`)
- Modify: `lib/features/home/presentation/home_cubit.dart:40-62` (sequence guard)
- Modify: `lib/features/home/presentation/home_screen.dart` (Stateful + RouteAware + lifecycle)
- Test: `test/home_refresh_on_return_test.dart` (new)

**Interfaces:** `appRouteObserver` is the single `RouteObserver<PageRoute<dynamic>>` shared by the router and Home. `HomeCubit.reload()` ignores a stale response.

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/app/route_observer.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/home/presentation/home_cubit.dart';
import 'package:quran_yahdi/features/home/presentation/home_screen.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'home_cubit_test.dart' show FakePrayerTimeService, cairoCity;
import 'support/test_db.dart';

Future<void> _pumpRounds(WidgetTester tester, {int rounds = 8}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)));
  }
}

void main() {
  testWidgets('returning to Home reloads the continue-reading card',
      (tester) async {
    final db = newTestDb();
    addTearDown(db.close);
    final lastRead = LastReadRepository(db);
    final ayahs = AyahRepository(db);
    final city =
        CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
    await db.into(db.surahs).insert(SurahsCompanion.insert(
          id: const Value(2),
          nameAr: 'البقرة',
          nameEn: 'Al-Baqarah',
          revelationType: 'Medinan',
          ayahCount: 286,
          pagesStart: 2,
          pagesEnd: 49,
        ));
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: const Value(8),
          surahId: 2,
          numberInSurah: 5,
          juz: 1,
          page: 2,
          textUthmani: 'ذلك الكتاب',
          textImlaei: 'ذلك الكتاب',
        ));
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: const Value(20),
          surahId: 2,
          numberInSurah: 6,
          juz: 1,
          page: 2,
          textUthmani: 'هدى للمتقين',
          textImlaei: 'هدى للمتقين',
        ));
    await city.select(cairoCity);
    await lastRead.saveAyahId(8);

    final cubit = HomeCubit(
      lastRead: lastRead,
      ayahs: ayahs,
      prayer: FakePrayerTimeService(),
      city: city,
    );
    addTearDown(cubit.close);
    await cubit.start();

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [appRouteObserver],
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      home: BlocProvider<HomeCubit>.value(
          value: cubit, child: const HomeScreen()),
    ));
    await _pumpRounds(tester);
    expect(find.text('﴿٥﴾ متابعة القراءة'), findsOneWidget);

    await lastRead.saveAyahId(20);
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(nav.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('reader')))));
    await _pumpRounds(tester);
    nav.pop();
    await _pumpRounds(tester);

    expect(find.text('﴿٦﴾ متابعة القراءة'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run RED**

```powershell
flutter test test/home_refresh_on_return_test.dart
```

Expected: after pop, the card still shows `﴿٥﴾` (or `appRouteObserver` is undefined).

- [ ] **Step 3: Implement**

Create `lib/app/route_observer.dart`:

```dart
import 'package:flutter/material.dart';

/// Shared by the GoRouter and by screens that need a "was covered, now
/// visible again" callback (Home's last-read and next-prayer cards).
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
```

In `router.dart`, add to the `GoRouter(...)` constructor:

```dart
    observers: [appRouteObserver],
```

In `home_cubit.dart`, add a sequence guard:

```dart
  int _reloadSeq = 0;

  Future<void> reload() async {
    final seq = ++_reloadSeq;
    try {
      final results = await Future.wait<Object?>([
        _loadLastReadCard(),
        _loadNextPrayerCard(),
      ]);
      if (isClosed || seq != _reloadSeq) return;
      emit(HomeState.ready(
        lastRead: results[0] as LastReadCard?,
        nextPrayer: results[1] as NextPrayerCard?,
      ));
    } on Object catch (error, stackTrace) {
      ...
      if (isClosed || seq != _reloadSeq) return;
      emit(const HomeState.failed());
    }
  }
```

In `home_screen.dart`, convert to a StatefulWidget and keep the existing static picker helper accessible:

```dart
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static Future<void> _openCityPicker(BuildContext context) async { ... }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with RouteAware, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (!mounted) return;
    unawaited(context.read<HomeCubit>().reload());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(context.read<HomeCubit>().reload());
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... previous build body unchanged; references to the picker use
    // HomeScreen._openCityPicker(context) or the inlined method.
  }
}
```

Add `import 'dart:async';` and `import '../../../app/route_observer.dart';` (adjust depth).

- [ ] **Step 4: Run the Home suite**

```powershell
flutter test test/home_refresh_on_return_test.dart test/home_cubit_test.dart test/home_continue_reading_test.dart test/home_screen_test.dart test/home_city_hint_test.dart test/home_load_parallelism_test.dart
```

- [ ] **Step 5: Commit**

```powershell
git add lib/app/route_observer.dart lib/app/router.dart lib/features/home/presentation/home_cubit.dart lib/features/home/presentation/home_screen.dart test/home_refresh_on_return_test.dart
git commit -m "fix(home): refresh cards when the route resumes"
```

---

### Task 11: One `AppDatabase` per executor

**Files:**
- Modify: `lib/core/db/connection.dart:193-245`
- Test: existing `test/search_index_build_test.dart` + a run of `test/reader_route_reentry_test.dart` (log check).

**Interfaces:** `_ensureContentCurrentOffUiIsolate(AppDatabase, Directory)` and `_ensureSearchIndex(AppDatabase)` take the already-created database.

- [ ] **Step 1: Confirm the warning**

```powershell
flutter test test/reader_route_reentry_test.dart 2>&1 | Select-String "created the database class AppDatabase multiple times"
```

Expected: two warnings today.

- [ ] **Step 2: Implement**

```dart
Future<QueryExecutor> openAppDatabase() async {
  ...
  final executor = NativeDatabase.createInBackground(...);
  final db = AppDatabase(executor);
  await _ensureContentCurrentOffUiIsolate(db, dir);
  await _ensureSearchIndex(db);
  return executor;
}

Future<void> _ensureContentCurrentOffUiIsolate(
  AppDatabase db,
  Directory tempDir,
) async {
  final installed = await db.installedContentVersion();
  ...
}

Future<void> _ensureSearchIndex(AppDatabase db) async {
  try {
    await ensureQuranSearchIndex(db);
  } ...
}
```

- [ ] **Step 3: Verify no warning**

```powershell
flutter test test/reader_route_reentry_test.dart 2>&1 | Select-String "created the database class AppDatabase multiple times"
flutter test test/search_index_build_test.dart test/quran_search_asset_test.dart
```

Expected: no matches; tests pass.

- [ ] **Step 4: Commit**

```powershell
git add lib/core/db/connection.dart
git commit -m "chore(db): use one AppDatabase per executor"
```

---

# Wave 4 — P1 app size (Lane D)

### Task 12: Split the sideload APK and shrink the upload bundle

**Files:**
- Modify: `.github/workflows/ci.yml:41-52`
- Modify: `android/app/build.gradle` (inside `defaultConfig`)
- Modify: `pubspec.yaml:71` (remove the runtime declaration of the build-only icon)
- Modify: `README.md` release section if it states a single universal APK
- Test: build gates (no unit test)

**Owner approval:** changing CI and the release artifact shape is a build-contract change. Ask the owner before this task; default is to land it, because the measured 42 MB saving is the largest single win.

- [ ] **Step 1: CI**

```yaml
      - run: flutter build apk --release --split-per-abi
      - run: flutter build appbundle --release
      - uses: actions/upload-artifact@v4
        with:
          name: app-release-apk
          path: build/app/outputs/flutter-apk/app-*-release.apk
          retention-days: 14
```

Keep the AAB step and artifact unchanged.

- [ ] **Step 2: Native symbols**

Inside `defaultConfig` in `android/app/build.gradle`:

```groovy
        ndk {
            // Upload-only native symbols: keep function names for crash
            // symbolication without the FULL per-ABI DWARF payload.
            debugSymbolLevel 'SYMBOL_TABLE'
        }
```

- [ ] **Step 3: Drop the build-only icon from the bundle**

`assets/icons/app_icon_2.png` is read from disk by `flutter_launcher_icons` and `flutter_native_splash`, never by `rootBundle`. Remove `- assets/icons/` from the `flutter.assets` list. Do not delete the file and do not touch the tool configs.

- [ ] **Step 4: Build and measure**

```powershell
flutter build apk --release --split-per-abi
flutter build appbundle --release
Get-ChildItem build\app\outputs\flutter-apk\app-*-release.apk |
  Select-Object Name, @{n='MB';e={[math]::Round($_.Length/1MB,2)}}
Get-Item build\app\outputs\bundle\release\app-release.aab |
  Select-Object Name, @{n='MB';e={[math]::Round($_.Length/1MB,2)}}
```

Expected: `app-arm64-v8a-release.apk` ≈ 25 MB (was 66.5 MB universal); AAB smaller than 65.4 MB; no `assets/flutter_assets/assets/icons/` entry in the APK.

- [ ] **Step 5: Commit**

```powershell
git add .github/workflows/ci.yml android/app/build.gradle pubspec.yaml README.md
git commit -m "build(android): ship split APKs and smaller upload symbols"
```

If `README.md` needed no change, omit it from the pathspec.

---

# Wave 5 — P2 lifecycle guards (Lane E, after Wave 1-4 integration)

### Task 13: Qibla pause on inactive/hidden and reload after city selection

**Files:**
- Modify: `lib/features/qibla/presentation/qibla_screen.dart:58-70,104-109`
- Test: `test/qibla_inactive_pause_test.dart` (new)

- [ ] **Step 1: Write the failing test**

Model it on `test/qibla_lifecycle_test.dart`: a `HeadingService(streamFactory: ...)`, a selected city, `cubit.start()`, pump `QiblaScreen`, send `AppLifecycleState.inactive`, expect the controller has no listener. Before the fix it still has one.

- [ ] **Step 2: Implement**

```dart
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        cubit.pause();
      case AppLifecycleState.resumed:
        cubit.resume();
      case AppLifecycleState.detached:
        break;
```

Empty-state action:

```dart
              onAction: () async {
                final selected =
                    await context.push<bool>(AppRoutes.cityPicker);
                if (selected == true && context.mounted) {
                  await context.read<QiblaCubit>().reload();
                }
              },
```

- [ ] **Step 3: Run** `flutter test test/qibla_inactive_pause_test.dart test/qibla_lifecycle_test.dart test/qibla_screen_test.dart` → all pass. Commit `fix(qibla): pause on inactive and reload after city selection`.

---

### Task 14: Stop the prayer countdown ticker in the background

**Files:**
- Modify: `lib/features/prayer/presentation/prayer_times/prayer_times_screen.dart:77-94`
- Test: `test/prayer_ticker_lifecycle_test.dart` (new)

- [ ] **Step 1: Failing test** — pump the screen, send `paused`, advance the injected clock by one minute, pump 1 s, expect the text **not** to change; send `resumed`, pump 1 s, expect it to change. Before the fix the paused tick still fires.
- [ ] **Step 2: Implement** `_TimesListState with WidgetsBindingObserver`; extract `_startTicker()`/`_stopTicker()`; start in `initState`, stop on `inactive/paused/hidden`, restart on `resumed`, cancel in `dispose`. Keep the 1 s cadence (frozen test pin); only the lifecycle gate is new.
- [ ] **Step 3: Run** `flutter test test/prayer_ticker_lifecycle_test.dart test/prayer_times_ticker_test.dart test/prayer_times_screen_test.dart`. Commit `perf(prayer): stop the countdown ticker in the background`.

---

### Task 15: Trim the decoded pack cache on background

**Files:**
- Modify: `lib/features/library/data/pack_reader.dart` (add `trim()` + `cachedBytes`)
- Modify: `lib/features/library/data/pack_downloader.dart` (add `trimReadCache()`)
- Modify: `lib/app/app.dart` (stateful lifecycle observer)
- Test: `test/pack_reader_trim_test.dart` (new)

- [ ] **Step 1: Failing test**

```dart
test('trim drops the primed cache', () {
  final reader = PackReader();
  reader.primeAyahIndex('p', {1: 'x'});
  expect(reader.cachedBytes, greaterThan(0));
  reader.trim();
  expect(reader.cachedBytes, 0);
});
```

- [ ] **Step 2: Implement**

```dart
  /// Estimated retained bytes of the decoded projections (test/diagnostic).
  int get cachedBytes => _cacheBytes;

  /// Drops every decoded projection. Called when the app is backgrounded;
  /// the next read re-decodes from disk.
  void trim() {
    _cache.clear();
    _cacheBytes = 0;
  }
```

`PackDownloader.trimReadCache() => _reader.trim();`

`QuranYahdiApp` becomes stateful, observes lifecycle, and on `paused` calls `getIt<PackDownloader>().trimReadCache()` when registered.

- [ ] **Step 3: Run** `flutter test test/pack_reader_trim_test.dart test/pack_reader_scheduling_test.dart test/pack_reader_index_isolate_test.dart`. Commit `perf(library): trim the decoded pack cache on background`.

---

### Task 16: Backup dismissal and closed-emit guards

**Files:**
- Modify: `lib/features/backup/presentation/backup_section.dart:36-45,153-168`
- Modify: `lib/features/backup/presentation/backup_cubit.dart:132-140` (and the entry points flagged by `rg "emit\\(" backup_cubit.dart`)
- Test: `test/backup_closed_guard_test.dart` (new)

- [ ] **Step 1: Failing test** — construct `BackupCubit`, `await cubit.close()`, then call `cancelPreview()` and `acknowledge()`; before the fix both throw `StateError: Cannot emit new states after calling close`.
- [ ] **Step 2: Implement** `if (isClosed) return;` at the top of `cancelPreview`, `acknowledge`, `export`, `importFromFile`, `confirmImport`; await the preview dialog and cancel on a null result (`system back`). Change the dialog buttons to `Navigator.pop(context, false/true)` and let the caller invoke cancel/merge exactly once.
- [ ] **Step 3: Run** `flutter test test/backup_closed_guard_test.dart test/backup_section_test.dart test/backup_retry_after_failure_test.dart`. Commit `fix(backup): cancel a dismissed preview and guard closed emits`.

---

### Task 17: City picker mounted guard

**Files:**
- Modify: `lib/features/prayer/presentation/city_picker/city_picker_screen.dart:95-112`
- Test: `test/city_picker_late_location_test.dart` (new; reuse the fakes pattern from `test/city_picker_locate_test.dart`)

- [ ] **Step 1: Failing test** — open the picker, start `_useMyLocation` with a gated locator, pop the picker, complete the locator, assert the underlying route was not popped and no snackbar was shown on it.
- [ ] **Step 2: Implement** `if (!context.mounted) return;` immediately after `await cubit.locateNearest()`.
- [ ] **Step 3: Run** `flutter test test/city_picker_late_location_test.dart test/city_picker_locate_test.dart test/city_picker_screen_test.dart`. Commit `fix(city): ignore a late location result after leaving the picker`.

---

## Deferred — requires an owner ruling (do not implement in this plan)

| Item | Why deferred | Options |
|---|---|---|
| Prayer ticker 1 Hz → minute-aligned one-shot | `test/prayer_times_ticker_test.dart:80-84` advances 1 s and expects an update; a minute timer breaks it under FakeAsync | (a) keep 1 Hz + lifecycle pause (Task 14); (b) owner unfreezes the test for a minute-aligned timer. Energy gain is <0.1 %/h, so (a) is rational. |
| Qibla sensor not bound with no city | `test/qibla_lifecycle_test.dart:61-64` expects a binding with no selected city | (a) accept the low-power waste; (b) owner authorizes a one-line test change. |
| Reader resets last-read to the route's initial ayah | `test/reader_cubit_test.dart:148` pins save-on-load | (a) Home refresh (Task 10) fixes the stale-card symptom; (b) owner authorizes a reader save-policy test change. |
| Full-suite flake on `reader_route_reentry_test` | Frozen test; passes alone | Owner authorizes a test-robustness wave (bounded pumps / serial run for that file). |
| Prayer-log day keys shift on timezone change | Requires a schema migration and data conversion | Separate migration plan: add `day_key TEXT`, backfill from local dates, switch the PK, keep a dual-read window. |
| Downloads progress copies the whole map at 1 % steps | UI refactor to per-row selector/notifier; medium benefit | Follow-up perf task if download lists grow. |
| Orphan `.part` sweep for pre-fix installs | New installs are safe after Task 7; legacy files are bounded | Boot sweep in a later library wave. |
| `assets/json/hafs_smart_v8.json` (7.4 MB) | Verified **not shipped**; build-tool only | No action. Optionally move to LFS for repo weight. |

## PM verification checklist (per wave)

- [ ] `git status --porcelain` contains only the expected files; no `.vscode/settings.json` / `INSTRUCTIONS.md`.
- [ ] Every commit has the exact English message and only the planned paths (`git show --stat`).
- [ ] New test was RED before the implementation (executor pastes the failing tail).
- [ ] Targeted suite green; full wave gate green with exact counts.
- [ ] The frozen-test pin table was not crossed.
- [ ] No dependency, l10n, or generated-file changes.
- [ ] `git diff --stat <wave-base>..HEAD -- lib test` is explainable line-by-line.

## Self-review

- **Coverage:** findings 1→Tasks 1-2; 2→8; 3→12; 4→4; 5→5; 6→3; 7→7; 8→6; 9→8; 10→9; 11→10 (symptom) + deferred (root); 12→11; 13→13; 14→14; 15→15; 16→16; 17→17. Every ranked finding has a task or an explicit owner-gated deferral.
- **No placeholders:** every code step names files, symbols, and commands; no “handle errors” hand-waves.
- **Type consistency:** `planReminders` adds only an optional `PrayerChoice? nextPrayer` (existing callers unchanged); `QuranSearchCubit` adds only an optional `Duration debounce`; `PackDownloader.install` keeps its signature; `cachedBytes`/`trim` are new and used only by the new test/app hook.
- **Frozen pins:** all four are called out before any task; no task edits an existing test file.
- **Risk order:** the P0 playback bug and the data-loss races land before perf/size polish; size is last in Phase 1 because it needs a long build.
