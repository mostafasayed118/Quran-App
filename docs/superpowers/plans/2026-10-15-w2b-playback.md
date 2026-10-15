# Quran Yahdi — Wave 2b (Foreground Playback) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Play a (reciter, surah) pair — from the local file when it is downloaded, otherwise streamed straight from the mp3quran server — with a thin playback facade over `just_audio`, a foreground-only `PlaybackCubit` singleton, a persistent mini player, and play affordances in the reciter's surah screen and the reader.

**Architecture:** `PlaybackService` (pure interface owning our own source/tick types, so just_audio types never leak past one file) → `JustAudioPlaybackService` (the ONLY file importing just_audio) → `PlaybackCubit` (singleton: source resolution + state machine + stream merging) → `MiniPlayerBar` (in the `bottomSheet` slot of the two playback screens) → play affordances. NO background audio / audio_service / media notification — W7 owns those with device QA.

**Tech Stack:** W2a stack + exactly ONE new package: `just_audio` (latest stable; disclose resolved version + pub admission like W1a required). No rxdart (stream merging happens in the cubit with `Stream` basics). No `audio_session` (default attributes accepted v1 — disclosed).

**Spec:** `docs/superpowers/specs/2026-10-15-quran-yahdi-rebuild-design.md`. Ledger lessons binding (esp. W1a S8 plain-fakes, W1b teardown-safe, W2a isClosed guards).

**Baseline:** main after `0d84a15` (ledger W2a close-out). Gates: analyze 0, tests 41/41, porcelain empty.

## Global Constraints

- Binding rules (all waves): analyze ends 0 issues; TDD red→green where stated; explicit-pathspec commits with these exact messages; NO push; checkbox ticks committed at close-out; one writer on `main`; start gate verbatim before ANY edit.
- **No frozen-test edits granted this wave.** There is NO schema change; `test/db_migration_test.dart`, `test/router_test.dart` and all W0–W2a test files are FROZEN (may only be touched if a play affordance refactor forces an existing widget test to need the new provider — in that case STOP first, never pre-emptively edit).
- **NEVER construct `AudioPlayer` inside a test.** `just_audio` is platform-channel backed and will hang or throw on the host VM. Every cubit/widget test uses a hand-rolled `FakePlaybackService` + the real `ReciterRepository` on `NativeDatabase.memory()` (W1a-S8 lesson: plain fakes beat helper packages).
- Teardown-safe discipline (W2a class): every `emit` behind `if (isClosed) return;`; every cubit dependency injectable so tests close DBs in `tearDown`; no `Future.delayed` busy-waits; widget tests use the W1a `pumpHost` pattern ONLY.
- Source resolution MUST reuse `surahAudioUrl()` from `lib/features/recitation/data/reciter_repository.dart` and `AudioDownloader.downloadedPath()` — no duplicated URL logic.
- `PlaybackCubit`, `PlaybackService`, `JustAudioPlaybackService` live under `lib/features/recitation/playback/` (new folder). `playback_service.dart` imports ONLY dart:async/dart:io. `just_audio_playback_service.dart` imports dart + just_audio ONLY (no flutter/widgets — it is a headless adapter).
- l10n additive-only, both ARBs symmetric, `flutter gen-l10n` honored.
- If `audio_downloader.dart` needs any change beyond imports, STOP (downloader is W2a-closed).

---

### Task 1: Start gate

- [x] **Step 1: Record verbatim**

```powershell
git rev-parse --short=7 HEAD; git status --porcelain; git branch --show-current; flutter --version
```

Expected: HEAD `0d84a15` or later with intervening commits touching ONLY `docs/` (the PM commits the plan right after the ledger); porcelain empty; branch `main`; Flutter 3.47.5 / Dart 3.13.4. Else STOP — report and wait.

---

### Task 2: Dependency + facade + PlaybackCubit (the engine)

**Files:**
- Modify: `pubspec.yaml` / `pubspec.lock` (add just_audio)
- Create: `lib/features/recitation/playback/playback_service.dart`, `lib/features/recitation/playback/just_audio_playback_service.dart`, `lib/features/recitation/presentation/playback/playback_state.dart`, `lib/features/recitation/presentation/playback/playback_cubit.dart`
- Generated: `playback_state.freezed.dart` (build_runner)
- Create: `test/playback_cubit_test.dart`

**Interfaces:**
- `PlaybackSource` — `const PlaybackSource.file(String path)` / `const PlaybackSource.url(Uri uri)`.
- `PlaybackService` — `Stream<bool> playingStream(); Stream<Duration> positionStream(); Stream<Duration?> durationStream(); Future<void> loadAndPlay(PlaybackSource source); Future<void> pause(); Future<void> resume(); Future<void> stop();`
- `JustAudioPlaybackService` maps these 1:1 onto `_player.playerStateStream.map((s) => s.playing)`, `positionStream`, `durationStream`, `setAudioSource(...)`+`play()`, `pause()`, `play()`, `stop()`.
- `PlaybackState` (freezed, sealed): `PlaybackInitial` | `PlaybackLoading(reciterName, surahNumber)` | `PlaybackPlaying(reciterName, surahNumber, position, duration)` | `PlaybackPaused(reciterName, surahNumber, position, duration)` | `PlaybackFailed(FailureKind kind)` where `enum PlaybackFailureKind { network, noReciters }` (UI maps kinds to l10n — never raw message strings).

- [x] **Step 1: Add the dependency**

```powershell
flutter pub add just_audio
```

Disclose the resolved version in the report. MANDATORY ADMISSION (W1a lesson): run `flutter pub outdated` right after and disclose anything new this pulls in; `just_audio` brings `just_audio_platform_interface` (+ Android plugin). If gradle sync complains about minSdk, STOP with the exact error (default `flutter.minSdkVersion` 21+ is known-compatible with just_audio ≥ 0.10 — expect no issue).

- [x] **Step 2:** Create `playback_service.dart` with the interface + source/tick types exactly as specced above (pure Dart — dart:async + dart:io imports only).

- [x] **Step 3:** Create `just_audio_playback_service.dart`. UTC constructor accepts an optional `AudioPlayer` (default `AudioPlayer()`). `loadAndPlay`:

```dart
  @override
  Future<void> loadAndPlay(PlaybackSource source) async {
    switch (source.kind) {
      case PlaybackSourceKind.file:
        final file = File(source.path!);
        await _player.setFilePath(file.path);
      case PlaybackSourceKind.url:
        await _player.setUrl(source.uri!.toString());
    }
    await _player.play();
  }
```

(If this switch pattern needs adjustment for the analyzer, disclose — S6-class mechanical.)

- [x] **Step 4:** Create `playback_state.dart` freezed sealed classes (fields above; `PlaybackPlaying`/`Paused` carry `Duration position, Duration duration` with sensible DateTime-zero defaults) and run `dart run build_runner build --delete-conflicting-outputs`. THEN — MANDATORY COMPANION CHECKPOINT (W1b lesson) — open the generated `PlaybackState` factory signatures and confirm which params are required; adjust usages before compiling, disclose any drift.

- [x] **Step 5:** Create `playback_cubit.dart`:

```dart
class PlaybackCubit extends Cubit<PlaybackState> {
  PlaybackCubit({
    required PlaybackService service,
    required ReciterRepository reciters,
    required AudioDownloader downloader,
  })  : _service = service,
        _reciters = reciters,
        _downloader = downloader,
        super(const PlaybackState.initial());

  String? _rowId; int? _surah; String _reciterName = '';

  Future<void> playSurah(ReciterRow row, int surahNumber) async { ... }
  Future<void> playDefaultForSurah(int surahNumber) async { ... }
  Future<void> toggle(); Future<void> stopAndReset();
}
```

`playSurah` semantics (write tests FIRST — red→green):
1. `emit(Loading(row.reciterName, surahNumber))` (guarded `isClosed`).
2. `final downloaded = await _downloader.downloadedPath(row.id, surahNumber);`
3. `source = downloaded != null ? PlaybackSource.file(downloaded) : PlaybackSource.url(Uri.parse(surahAudioUrl(row.server, surahNumber)));`
4. track `_rowId/_surah/_reciterName`, subscribe the service streams ONCE (idempotent bind — if already subscribed, reuse), then `await _service.loadAndPlay(source)`; on success emit `Playing(...)`, on `Object` catch emit `Failed(network)`. Every emit behind `if (isClosed) return;`.
`playDefaultForSurah`: inspect `loadSelectedMoshaf()` → `byId`; fallback = first row of `sortReciters(await _reciters.watchAll().first)`; if the catalog is empty → `Failed(noReciters)` WITHOUT touching the service.
`toggle`: `Playing → _service.pause() → emit Paused`; `Paused → _service.resume() → emit Playing`; others = no-op.
`stopAndReset`: `_service.stop()`, cancel subscriptions, `emit(PlaybackInitial)` (guarded).

- [x] **Step 6:** `test/playback_cubit_test.dart` — `FakePlaybackService implements PlaybackService` with `StreamController` fields + a `List<PlaybackSource> loaded` recorder. Tests (all plain `test()`, real `ReciterRepository` on `NativeDatabase.memory()`, seeded rows use `Value(...)`-wrapped companions — read `app_database.g.dart` for `RecitersCompanion.insert` if headers drifted):
  1. `playSurah uses the downloaded file when the downloads row is done` (seed a `downloads` row via the real DB then `downloadedPath` picks it — or simpler: seed `downloads` with status `done` + path pointing to a temp file).
  2. `playSurah streams the server URL when nothing is downloaded` (expect `loaded.single.kind == url` and the URL uses `surahAudioUrl`).
  3. `service failure lands in Failed(network) and keeps state resettable` (make the fake `loadAndPlay` throw; then `stopAndReset` → initial).
  4. `playDefaultForSurah falls back to the first featured row when no selection exists` (seed rows for ids `55-55` and `51-53`; expect the `51-53` row name in state).
  5. `toggle pauses and resumes` (fake-driven).

- [x] **Step 7: Gates + commit**

```powershell
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test test/playback_cubit_test.dart
git add pubspec.yaml pubspec.lock lib/features/recitation/playback lib/features/recitation/presentation/playback test/playback_cubit_test.dart
git commit -m "feat(w2b): playback facade + just_audio service + playback cubit (source resolution)"
```

---

### Task 3: DI + MiniPlayerBar + reciter-surahs play affordance

**Files:**
- Modify: `lib/core/di/injector.dart` (register service + cubit lazily)
- Create: `lib/features/recitation/presentation/playback/mini_player_bar.dart`
- Modify: `lib/features/recitation/presentation/reciter_surahs/reciter_surahs_screen.dart` (play affordance + `bottomSheet:` slot + provide the singleton cubit via the route)
- Modify: `lib/app/router.dart` (add `BlocProvider<PlaybackCubit>.value(value: getIt<PlaybackCubit>())` into the `/recitation/reciter` MultiBlocProvider)
- Modify: `lib/l10n/app_ar.arb`, `lib/l10n/app_en.arb` + regenerated files
- Create: `test/mini_player_bar_test.dart`, modify `test/reciter_surahs_screen_test.dart` ONLY if the existing harness needs the new provider (STOP first if so)

**l10n (additive, symmetric):** `nowPlaying` `يُشغَّل الآن: {name}` / `Now playing: {name}` (String placeholder) · `playTooltip` `تشغيل`/`Play` · `pauseTooltip` `إيقاف مؤقت`/`Pause` · `stopTooltip` `إيقاف`/`Stop` · `listenTooltip` `استمع للسورة`/`Listen to surah` · `surahBadge` `سورة {number}`/`Surah {number}` (String placeholder through `ArabicIndicInt.toArabicIndic` at the call site — western-digit gen-l10n caveat from the ledger).

- [x] **Step 1: DI**

```dart
import '../../features/recitation/playback/just_audio_playback_service.dart';
import '../../features/recitation/playback/playback_service.dart';
import '../../features/recitation/presentation/playback/playback_cubit.dart';
...
getIt.registerLazySingleton<PlaybackService>(() => JustAudioPlaybackService());
getIt.registerLazySingleton<PlaybackCubit>(() => PlaybackCubit(
      service: getIt<PlaybackService>(),
      reciters: getIt<ReciterRepository>(),
      downloader: getIt<AudioDownloader>(),
    ));
```

Lazy ONLY (`AudioPlayer` must not be constructed at boot — smoke test boots `/home`). Verify `injector_test` still passes; `ensureAudioBindings()` ordering unaffected.

- [x] **Step 2:** `MiniPlayerBar` — stateless, `BlocBuilder<PlaybackCubit, PlaybackState>`: `Initial/Failed` → `SizedBox.shrink()`; else a `Material` surface strip (D6 tokens): reciter name (`nowPlaying`), `surahBadge` with Arabic-Indic number, a thin `LinearProgressIndicator(position/duration)` (guard divide-by-zero), IconButton play/pause via `toggle()`, IconButton `Icons.close` tooltip `stopTooltip` via `stopAndReset()`. `Failed(kind)` surfaces a dismissible error strip mapping `network → playbackFailed` (new key `playbackFailed`: `تعذّر تشغيل التلاوة`/`Could not play the recitation`), `noReciters → noReciters` (existing W2a key — reuse, do NOT duplicate).

- [x] **Step 3: Wire the screen** — in `ReciterSurahsScreen`: `bottomSheet:` gets `const MiniPlayerBar()` BUT `bottomSheet` with a shrink-sized widget is harmless when idle. Provide the cubit: it arrives scoped through the route (Step 4). Add to each `ReciterSurahsReady` surah row a leading IconButton `Icons.play_arrow` tooltip `playTooltip`, visible only when `row.surahList` contains the number (`parseSurahList(row.surahList).contains(n)`) — absent rows keep the row as-is (download affordance unchanged, W2a-frozen test A asserts must keep passing WITHOUT edit). On tap: `context.read<PlaybackCubit>().playSurah(row, surahNumber)`.

- [x] **Step 4: Router** — add `BlocProvider<PlaybackCubit>.value(value: getIt<PlaybackCubit>())` to the existing `/recitation/reciter` MultiBlocProvider. `router_test` MUST stay green unedited — this route is not pinned by it (verify).

- [x] **Step 5: Gates + tests + commit**

```powershell
flutter gen-l10n; dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test test/mini_player_bar_test.dart test/reciter_surahs_screen_test.dart test/injector_test.dart test/router_test.dart
git add lib/core/di/injector.dart lib/features/recitation/presentation/playback/mini_player_bar.dart lib/features/recitation/presentation/reciter_surahs lib/app/router.dart lib/l10n test/mini_player_bar_test.dart
git commit -m "feat(w2b): mini player + DI + reciter-surahs play affordance (l10n)"
```

`mini_player_bar_test.dart` (2 tests, pumpHost pattern, `MultiBlocProvider` with `PlaybackCubit` on `FakePlaybackService` + memory DB; `tearDown` closes DB and cubit):
1. `idle state renders nothing` (finds no `LinearProgressIndicator`).
2. `playing state shows names, progress, and pause→resume flips the icon` (drive the fake: emit stream value / call playSurah with a seeded row; assert `nowPlaying` text + surah badge + tooltip flip).

---

### Task 4: Reader listen hook

**Files:**
- Modify: `lib/features/quran/presentation/reader/reader_screen.dart` (AppBar action IconButton `Icons.headphones` tooltip `listenTooltip` → `context.read<PlaybackCubit>().playDefaultForSurah(surahId)`; `bottomSheet: const MiniPlayerBar()`)
- Modify: `lib/app/router.dart` (add `BlocProvider<PlaybackCubit>.value(...)` to the `/quran/reader` bloc-only route — wrap in MultiBlocProvider)
- Modify: `test/reader_screen_test.dart` ONLY if its harness must gain the provider — FROZEN otherwise; if any existing reader assertion breaks, STOP (per constraints) instead of editing.

- [x] **Step 1:** Reader AppBar trailing action (before any existing actions): `IconButton(Icons.headphones, tooltip: loc.listenTooltip, onPressed: () => context.read<PlaybackCubit>().playDefaultForSurah(state.surahId))` — wire against the ReaderCubit state that carries the surah id (read the current state shape first; guard for non-ready states).
- [x] **Step 2:** Router — convert the `/quran/reader` builder to a `MultiBlocProvider(ReaderCubit..., PlaybackCubit.value...)`, `bottomSheet: const MiniPlayerBar()` in the reader Scaffold.
- [x] **Step 3: Gates + commit**

```powershell
flutter gen-l10n
flutter analyze
flutter test test/reader_screen_test.dart test/reader_cubit_test.dart
git add lib/features/quran/presentation/reader/reader_screen.dart lib/app/router.dart
git commit -m "feat(w2b): reader listen hook + mini player (l10n)"
```

(If the pinned reader tests need the new provider and would otherwise be EDITED, do NOT amend them silently — STOP with evidence; the PM will grant the minimal import/provider-line edit.)

---

### Task 5: Close-out

- [x] **Step 1: Full gates ONCE, in this order, all recorded**

```powershell
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter analyze
flutter test
flutter pub outdated
flutter build apk --debug
git status --porcelain
git rev-list --count origin/main..HEAD
```

Expected: analyze 0; full suite baseline 41 + 5 (cubit) + 2 (mini player) = **≈48, MEASURE — do not trust, record exact per-file counts**; APK exit 0 + byte size; `just_audio` disclosed in outdated; porcelain empty.
- [x] **Step 2: Tick this plan** (`- [x]` → `- [x]`, workflow-safe edit — PowerShell: .NET `UTF8Encoding($false)` write, NEVER `-Encoding ascii`), commit:

```powershell
git add docs/superpowers/plans/2026-10-15-w2b-playback.md
git commit -m "docs(w2b): mark plan checkboxes complete"
```

- [x] **Step 3:** Produce the §8-style final report (same section skeleton as the W2a report: start-gate verbatim, commit table, companion checkpoint quotes, gates table with measured numbers, itemized disclosures, STOPs, unpushed count, state). NO PUSH.

## Explicit non-goals (this wave)

- Background playback, `audio_service`, media notification/notification actions, lock-screen controls — W7 with real-device QA.
- Sequential surah autoplay / playlist / khatma audio — deferred by owner decision.
- Seek bar in the mini player; audio interruption/focus policy beyond just_audio defaults (accepted v1, disclosed).
- iOS/AVPlayer verification — Android-first per locked D-decisions.

## Self-Review (PM, pre-dispatch)

- Zero deps beyond `just_audio` (no rxdart — streams merged manually in the cubit; no audio_session v1).
- No DB schema change → no companion risk beyond the generated freezed state classes (checkpoint in T2 enforces verification).
- The ONLY constructible-in-test hazard is `AudioPlayer` — fenced by constraints (lazy DI + fake service + never-in-tests rule).
- Frozen-test surface: `db_migration`, `router`, `reciters_screen` untouched by design; `reciter_surahs_screen`/`reader_screen` may need a provider line only, and both cases route through STOP-or-grant, never silent edits.
- Teardown safety: singleton cubit with `isClosed` guards; tests own their DB/fixtures; no busy-waits.
- l10n is additive + symmetric; Arabic-Indic numerals rendered at call sites (gen-l10n caveat respected).

---

## PM Errata & Adjudications (post-wave, committed by PM 2026-10-15)
- All 8 disclosures ACCEPTED. Notable rulings: D3 (plan-sketch private tracking fields dropped in favor of freezed-state identity — correct for the 0-issue gate); D5 (plan Step-2 self-contradiction "shrink vs strip" resolved toward the error-strip intent — correct reading); D6 (leading slot: number badge KEPT for non-playable surahs, play button replaces it only for playable rows — verified at source, better than plan-literal).
- In-session grant RATIFIED post-hoc with full diff audit (b1fa075..3930a94): the two frozen harnesses received ONLY imports + _FakePlaybackService + one BlocProvider.value line + ddTearDown each — ZERO assertion edits. Bug-fix class accepted.
- v1 playback semantics now locked: streaming happens at play time for undownloaded surahs; offline listening requires a prior download (reciter-surahs affordance). Background audio / audio_session focus / media notification remain W7 line.
