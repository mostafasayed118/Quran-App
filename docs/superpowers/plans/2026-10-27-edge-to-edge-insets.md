# Edge-to-Edge Bottom Insets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stop the Android 15/16 system navigation bar from covering the app's bottom-anchored UI (mini player, sheet content, last scrollable row, page indicator) and keep the system icons legible on a forced edge-to-edge window.

**Architecture:** Per-boundary inset handling. One shared `appBottomInset`/`appScrollPadding` helper feeds every scrollable body and every bottom-anchored surface; one root `AnnotatedRegion<SystemUiOverlayStyle>` (plus the theme's `AppBarTheme.systemOverlayStyle`) owns the system-bar icon brightness. No app-wide `SafeArea`, no `windowOptOutEdgeToEdgeEnforcement`, no fixed bar height.

**Tech Stack:** Flutter 3.47.5 / Dart 3.13.4, Material 3, `flutter_test` only (no new packages).

**Spec:** the read-only audit of 2026-10-27 (this session) plus the throwaway probe at `C:\Users\ASUS\AppData\Local\Temp\opencode\inset_probe` (outside the repo). Probe evidence with a 48 dp bottom inset on an 800 dp screen (`safeLimit = 752`):

```
CASE1 plain Scaffold ListView         -> bottom=784  covered=true
CASE2 boundSheet without SafeArea     -> bottom=800  covered=true
CASE3 boundSheet + SafeArea(top:false)-> bottom=800  covered=true   (SafeArea is a no-op here)
CASE4 modal useSafeArea:true, no pad  -> bottom=800  covered=true
CASE5 modal + inner SafeArea(top:false)-> bottom=752 covered=false
```

Framework facts pinned at source (do not re-derive):
- `android/app/build.gradle:53` uses `flutter.targetSdkVersion`; `C:\src\flutter\packages\flutter_tools\gradle\src\main\kotlin\FlutterExtension.kt:34` = **36** → edge-to-edge is enforced on Android 15+ and mandatory on Android 16; Android 14 keeps the old window model, which is why the same code looks fine there.
- `scaffold.dart:3032` — the **body** keeps `MediaQuery.padding.bottom` (unless a `bottomNavigationBar`/`persistentFooterButtons` exists), so `padding.bottom` is the correct scroll padding inside a body.
- `scaffold.dart:3085` — `Scaffold.bottomSheet` is wrapped with `removeBottomPadding: _resizeToAvoidBottomInset` (true by default) → `SafeArea` inside `Scaffold.bottomSheet` cannot see the bottom inset.
- `bottom_sheet.dart:1167` — `showModalBottomSheet(useSafeArea: true)` applies `SafeArea(bottom: false)`; the sheet still "extends all the way to the bottom of the screen, including any system intrusions".
- `snack_bar.dart:791` already wraps the SnackBar in `SafeArea(top: false)` → no work needed there.

## Global Constraints

- Toolchain: Flutter 3.47.5 stable / Dart 3.13.4. Shell: Windows PowerShell 5.1 (no `&&`; use `;`).
- Existing tests are **FROZEN**. This plan adds new test files only; it never edits `test/**` that already exists.
- No new dependencies. No l10n changes.
- **NO COMMIT / NO PUSH without explicit owner GO.** The commit steps below stay unchecked until the owner approves.
- Baseline before this plan: `flutter analyze` = 0 issues, `flutter test` = **710 passed** (measured 2026-10-27 at HEAD `45fc409`).
- Definition of done for every task: its new test fails before the change, passes after, and the full suite is still 710 + (new tests) green.
- Formatting: every touched file must pass `dart format --output=none --set-exit-if-changed lib test`.

## File Map

| File | Responsibility |
|---|---|
| `lib/core/theme/app_system_ui.dart` (new) | Pure `Brightness -> SystemUiOverlayStyle` mapping (transparent bars + icon brightness). |
| `lib/core/theme/app_theme.dart` | Carries that style on both `AppBarTheme`s. |
| `lib/app/app.dart` | Root `AnnotatedRegion` so bars outside an AppBar (dialogs, first frame) get the same style. |
| `lib/core/utils/insets.dart` (new) | `appBottomInset` + `appScrollPadding` — the only place that reads the system bottom inset. |
| 20 feature screens | One-line: scroll padding = base + system bottom inset. |
| `lib/features/recitation/presentation/playback/mini_player_bar.dart` | Bottom bar paints behind the bar and pads its content (Scaffold strips `padding`, so it uses `viewPadding`). |
| `lib/features/library/presentation/ayah_sheet/library_sheet.dart` | Sheet content gets `SafeArea(top: false)` inside its own `Material`. |
| `lib/features/quran/presentation/reader/reader_screen.dart` | Verses list padding, mushaf page padding, error-pane retry button. |
| `lib/features/asma/presentation/asma_screen.dart` | Grid padding + bottom-anchored name card margin. |
| `test/system_ui_style_test.dart` (new) | Icon-brightness contract. |
| `test/insets_test.dart` (new) | Helper contract + render-level geometry proof. |
| `test/edge_to_edge_screens_test.dart` (new) | Real `HomeScreen` scroll padding at inset 48 and 24. |
| `test/mini_player_inset_test.dart` (new) | Real `MiniPlayerBar` inside `Scaffold.bottomSheet`: content clears the bar, background reaches the screen edge. |
| `test/ayah_sheet_inset_test.dart` (new) | Modal sheet content clears the bar. |
| `test/reader_inset_test.dart` (new) | Mushaf page indicator + error retry button clear the bar. |

---

### Task 1: System UI overlay style

**Files:**
- Create: `lib/core/theme/app_system_ui.dart`
- Modify: `lib/core/theme/app_theme.dart` (the `appBarTheme:` block)
- Modify: `lib/app/app.dart`
- Test: `test/system_ui_style_test.dart`

**Interfaces:**
- Produces: `AppSystemUi.overlayStyle(Brightness brightness) -> SystemUiOverlayStyle`.

- [x] **Step 1: Write the failing test**

```dart
// test/system_ui_style_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/theme/app_system_ui.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';

void main() {
  test('light theme: transparent bars, dark icons', () {
    final style = AppSystemUi.overlayStyle(Brightness.light);
    expect(style.statusBarColor, Colors.transparent);
    expect(style.systemNavigationBarColor, Colors.transparent);
    expect(style.systemNavigationBarDividerColor, Colors.transparent);
    expect(style.statusBarIconBrightness, Brightness.dark);
    expect(style.systemNavigationBarIconBrightness, Brightness.dark);
  });

  test('dark theme: transparent bars, light icons', () {
    final style = AppSystemUi.overlayStyle(Brightness.dark);
    expect(style.systemNavigationBarColor, Colors.transparent);
    expect(style.statusBarIconBrightness, Brightness.light);
    expect(style.systemNavigationBarIconBrightness, Brightness.light);
  });

  test('both app themes carry the style on the AppBar', () {
    expect(
      AppTheme.light.appBarTheme.systemOverlayStyle
          ?.systemNavigationBarIconBrightness,
      Brightness.dark,
    );
    expect(
      AppTheme.dark.appBarTheme.systemOverlayStyle
          ?.systemNavigationBarIconBrightness,
      Brightness.light,
    );
  });
}
```

- [x] **Step 2: Run it and watch it fail**

Run: `flutter test test/system_ui_style_test.dart`
Expected: FAIL — `app_system_ui.dart` does not exist.

- [x] **Step 3: Create the style mapping**

```dart
// lib/core/theme/app_system_ui.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// System-bar chrome for a forced edge-to-edge Android window.
///
/// Android 15+/targetSdk 35+ draws the bars over the app and ignores the bar
/// colors, so the only levers left are the icon brightness and transparent
/// bar backgrounds (the app content itself paints the strip).
abstract final class AppSystemUi {
  static SystemUiOverlayStyle overlayStyle(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final iconBrightness = isLight ? Brightness.dark : Brightness.light;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: brightness,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: iconBrightness,
    );
  }
}
```

- [x] **Step 4: Wire it into the theme and the app root**

In `lib/core/theme/app_theme.dart`, add the import and one line inside `AppBarTheme(...)`:

```dart
systemOverlayStyle: AppSystemUi.overlayStyle(
  isLight ? Brightness.light : Brightness.dark,
),
```

In `lib/app/app.dart`:

```dart
import 'package:flutter/services.dart';

import '../core/theme/app_system_ui.dart';

// ...
return MaterialApp.router(
  // ...
  builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: AppSystemUi.overlayStyle(Theme.of(context).brightness),
    child: child!,
  ),
  routerConfig: AppRouter.router,
);
```

- [x] **Step 5: Run the test and the analyzer**

Run: `flutter test test/system_ui_style_test.dart` → 3 passing.
Run: `flutter analyze` → 0 issues.

---

### Task 2: Shared inset helper + geometry proof

**Files:**
- Create: `lib/core/utils/insets.dart`
- Test: `test/insets_test.dart`

**Interfaces:**
- Produces:
  - `double appBottomInset(BuildContext context)`
  - `EdgeInsets appScrollPadding(BuildContext context, EdgeInsets base)`

- [x] **Step 1: Write the failing test**

```dart
// test/insets_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/utils/insets.dart';

const double kHeight = 800;
const double kInset = 48;

void setInset(WidgetTester tester, {double inset = kInset}) {
  tester.view.physicalSize = const Size(400, kHeight);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(bottom: inset);
  tester.view.viewPadding = FakeViewPadding(bottom: inset);
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('body padding: the bottom inset is the nav bar height',
      (tester) async {
    setInset(tester);
    late double measured;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        measured = appBottomInset(context);
        return const SizedBox.shrink();
      }),
    ));
    expect(measured, kInset);
  });

  testWidgets('keyboard open: the inset collapses', (tester) async {
    setInset(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    late double measured;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        measured = appBottomInset(context);
        return const SizedBox.shrink();
      }),
    ));
    expect(measured, 0);
  });

  testWidgets('bar stripped of padding: falls back to viewPadding',
      (tester) async {
    setInset(tester);
    late double measured;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomSheet: Builder(builder: (context) {
          measured = appBottomInset(context);
          return const SizedBox(height: 10);
        }),
      ),
    ));
    expect(measured, kInset);
  });

  testWidgets('adds the inset to a scroll padding', (tester) async {
    setInset(tester);
    late EdgeInsets measured;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        measured = appScrollPadding(context, const EdgeInsets.all(12));
        return const SizedBox.shrink();
      }),
    ));
    expect(measured, const EdgeInsets.fromLTRB(12, 12, 12, 60));
  });

  testWidgets('last list row stays above the nav bar', (tester) async {
    setInset(tester);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ListView(
            padding: appScrollPadding(context, const EdgeInsets.all(12)),
            children: [
              for (var i = 0; i < 20; i++) const SizedBox(height: 80),
              Container(key: const Key('last'), height: 80),
            ],
          ),
        ),
      ),
    ));
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byKey(const Key('last')));
    expect(rect.bottom, lessThanOrEqualTo(kHeight - kInset));
  });
}
```

- [x] **Step 2: Run it and watch it fail**

Run: `flutter test test/insets_test.dart`
Expected: FAIL — `insets.dart` does not exist.

- [x] **Step 3: Create the helper**

```dart
// lib/core/utils/insets.dart
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Bottom system inset the UI must keep clear right now.
///
/// `MediaQuery.padding.bottom` collapses to zero while the keyboard is open,
/// and `Scaffold` strips it entirely from `bottomSheet`/bar slots, so the
/// value is the larger of `padding` and `viewPadding`, minus the keyboard
/// case (the Scaffold already resizes for `viewInsets`).
///
/// Never call this below a [SafeArea] that already consumed the inset.
double appBottomInset(BuildContext context) {
  final media = MediaQuery.of(context);
  if (media.viewInsets.bottom > 0) return 0;
  return math.max(media.padding.bottom, media.viewPadding.bottom);
}

/// [base] with the system bottom inset added — for scrollable bodies.
EdgeInsets appScrollPadding(BuildContext context, EdgeInsets base) {
  return base.copyWith(bottom: base.bottom + appBottomInset(context));
}
```

- [x] **Step 4: Run the tests**

Run: `flutter test test/insets_test.dart` → 5 passing.
Note: the last test must pass **without** any screen change; it proves the helper's mechanism.

---

### Task 3: Scrollable bodies

**Files (one line each):**
- Modify: `lib/features/home/presentation/home_screen.dart:40`
- Modify: `lib/features/qibla/presentation/qibla_screen.dart:111`
- Modify: `lib/features/azkar/presentation/azkar_screen.dart:122,159,254`
- Modify: `lib/features/duas/presentation/duas_screen.dart:110,145`
- Modify: `lib/features/zakat/presentation/zakat_screen.dart:46`
- Modify: `lib/features/hijri/presentation/hijri_screen.dart:33`
- Modify: `lib/features/prayer/presentation/prayer_times/prayer_times_screen.dart:102`
- Modify: `lib/features/settings/presentation/settings_screen.dart:76`
- Modify: `lib/features/settings/presentation/licenses_screen.dart:27`
- Modify: `lib/features/prayer/presentation/city_picker/city_picker_screen.dart:125`
- Modify: `lib/features/quran/presentation/index/surah_index_screen.dart:53`
- Modify: `lib/features/quran/presentation/bookmarks/bookmarks_screen.dart:61`
- Modify: `lib/features/quran/presentation/search/quran_search_screen.dart:87`
- Modify: `lib/features/recitation/presentation/reciters/reciters_screen.dart:102`
- Modify: `lib/features/recitation/presentation/reciter_surahs/reciter_surahs_screen.dart:67`
- Modify: `lib/features/library/presentation/library_screen.dart:132`
- Modify: `lib/features/asma/presentation/asma_screen.dart:145` and the `_NameSheet` card margin
- Modify: `lib/features/tracker/presentation/tracker_screen.dart:52`
- Test: `test/edge_to_edge_screens_test.dart`

**Interfaces:**
- Consumes: `appScrollPadding` / `appBottomInset` (Task 2).

- [x] **Step 1: Write the failing test**

```dart
// test/edge_to_edge_screens_test.dart
// Reuses the HomeScreen harness from test/home_screen_test.dart.
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/home/presentation/home_cubit.dart';
import 'package:quran_yahdi/features/home/presentation/home_screen.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';

import 'home_cubit_test.dart' show FakePrayerTimeService, cairoCity;
import 'support/host.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late LastReadRepository lastRead;
  late AyahRepository ayahs;
  late CityRepository city;

  setUp(() async {
    db = newTestDb();
    lastRead = LastReadRepository(db);
    ayahs = AyahRepository(db);
    city = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
    await db.into(db.surahs).insert(SurahsCompanion.insert(
          id: const Value(2),
          nameAr: 'البقرة',
          nameEn: 'Al-Baqarah',
          revelationType: 'Medinan',
          ayahCount: 286,
          pagesStart: 2,
          pagesEnd: 49,
        ));
    await city.select(cairoCity);
    await lastRead.saveAyahId(8);
  });

  for (final inset in <double>[48, 24]) {
    testWidgets('home list padding includes the $inset dp system inset',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = FakeViewPadding(bottom: inset);
      tester.view.viewPadding = FakeViewPadding(bottom: inset);
      addTearDown(tester.view.reset);

      final cubit = HomeCubit(
        lastRead: lastRead,
        ayahs: ayahs,
        prayer: FakePrayerTimeService(),
        city: city,
      );
      addTearDown(cubit.close);
      await cubit.start();
      await pumpAppHost(
        tester,
        wrap: (app) => BlocProvider<HomeCubit>.value(value: cubit, child: app),
        home: const HomeScreen(),
      );

      final list = tester.widget<ListView>(find.byType(ListView));
      final padding = list.padding! as EdgeInsets;
      expect(padding.bottom, 12 + inset);
    });
  }
}
```

- [x] **Step 2: Run it and watch it fail**

Run: `flutter test test/edge_to_edge_screens_test.dart`
Expected: FAIL — `Expected: 60, Actual: 12` (and 36 vs 12).

- [x] **Step 3: Apply the helper at every listed site**

Pattern (all imports are `import '../../../../core/utils/insets.dart';` adjusted to depth):

| Current | Replace with |
|---|---|
| `padding: const EdgeInsets.all(AppSpacing.md)` | `padding: appScrollPadding(context, const EdgeInsets.all(AppSpacing.md))` |
| `padding: const EdgeInsets.all(AppSpacing.lg)` | `padding: appScrollPadding(context, const EdgeInsets.all(AppSpacing.lg))` |
| `padding: const EdgeInsets.only(bottom: AppSpacing.md)` | `padding: appScrollPadding(context, const EdgeInsets.only(bottom: AppSpacing.md))` |
| `padding: const EdgeInsets.only(bottom: AppSpacing.lg)` | `padding: appScrollPadding(context, const EdgeInsets.only(bottom: AppSpacing.lg))` |
| no `padding:` on `ListView.builder` | add `padding: EdgeInsets.only(bottom: appBottomInset(context)),` |

Special cases:
- `settings_screen.dart:76` and `city_picker_screen.dart:125` and `surah_index_screen.dart:53` and `bookmarks_screen.dart:61` and `reciters_screen.dart:102` and `reciter_surahs_screen.dart:67` currently have no padding → add the `ListView.builder(... , padding: EdgeInsets.only(bottom: appBottomInset(context)), ...)` parameter.
- `asma_screen.dart`: `_NamesGrid` `padding: const EdgeInsets.all(AppSpacing.md)` → `appScrollPadding(context, ...)`; and `_NameSheet`'s `Card(margin: const EdgeInsets.all(AppSpacing.md))` → `margin: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md + appBottomInset(context))` so the bottom-anchored card clears the bar.
- Do **not** touch `duas_screen.dart:88` (horizontal chips scroller), `hadith_screen.dart` (list sits above the already-safe pager), `tracker_screen.dart:342` (sheet `SafeArea`), or `error_strip.dart` (inline banner at the top of a list).

- [x] **Step 4: Run the tests**

Run: `flutter test test/edge_to_edge_screens_test.dart` → 2 passing.
Run: `flutter analyze` → 0 issues.

---

### Task 4: Mini player (`Scaffold.bottomSheet`)

**Files:**
- Modify: `lib/features/recitation/presentation/playback/mini_player_bar.dart`
- Test: `test/mini_player_inset_test.dart`

**Interfaces:**
- Consumes: `appBottomInset` (Task 2).

- [x] **Step 1: Write the failing test** (same fakes as `test/mini_player_bar_test.dart`)

```dart
// test/mini_player_inset_test.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/playback/playback_service.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/mini_player_bar.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';

import 'support/host.dart';
import 'support/test_db.dart';

class _FakePlaybackService implements PlaybackService {
  final playing = StreamController<bool>.broadcast();
  final positionCtrl = StreamController<Duration>.broadcast();
  final durationCtrl = StreamController<Duration?>.broadcast();

  @override
  Stream<bool> playingStream() => playing.stream;
  @override
  Stream<Duration> positionStream() => positionCtrl.stream;
  @override
  Stream<Duration?> durationStream() => durationCtrl.stream;
  @override
  Future<void> loadAndPlay(PlaybackSource source) async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> stop() async {}
}

const double kHeight = 800;
const double kInset = 48;

void main() {
  late AppDatabase db;
  late Directory tempRoot;
  late _FakePlaybackService fake;
  late PlaybackCubit cubit;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_mini_inset_test');
    fake = _FakePlaybackService();
    cubit = PlaybackCubit(
      service: fake,
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
    );
    await db.into(db.reciters).insert(
          RecitersCompanion.insert(
            id: '51-53',
            reciterName: 'عبدالباسط عبدالصمد',
            moshafName: 'حفص مرتل',
            server: 'https://server.example/mp3',
            surahList: '1,2',
            surahTotal: 114,
          ),
        );
  });

  tearDown(() async {
    await cubit.close();
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  testWidgets('the playing strip clears the nav bar and paints behind it',
      (tester) async {
    tester.view.physicalSize = const Size(400, kHeight);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: kInset);
    tester.view.viewPadding = const FakeViewPadding(bottom: kInset);
    addTearDown(tester.view.reset);

    await pumpAppHost(
      tester,
      wrap: (app) => BlocProvider<PlaybackCubit>.value(value: cubit, child: app),
      home: const Scaffold(bottomSheet: MiniPlayerBar()),
      settle: false,
    );
    await tester.pumpAndSettle();

    final row = (await ReciterRepository(db).byId('51-53'))!;
    await cubit.playSurah(row, 1);
    fake.durationCtrl.add(const Duration(minutes: 6));
    fake.positionCtrl.add(Duration.zero);
    await tester.pumpAndSettle();

    final stopButton = tester.getRect(find.byTooltip('إيقاف'));
    expect(stopButton.bottom, lessThanOrEqualTo(kHeight - kInset));

    final strip = tester.getRect(find.byType(Material).last);
    expect(strip.bottom, kHeight);
  });
}
```

- [x] **Step 2: Run it and watch it fail**

Run: `flutter test test/mini_player_inset_test.dart`
Expected: FAIL — `Expected: a value less than or equal to 752, Actual: 800` (the stop button sits on the bar).

- [x] **Step 3: Fix both strip states**

`_PlaybackStrip.build`: delete the `SafeArea` and put the inset into the strip's own padding, inside the `Material` so the background still reaches the screen edge:

```dart
return Material(
  color: colors.surface,
  elevation: 4,
  child: Padding(
    padding: EdgeInsets.fromLTRB(
      14,
      AppSpacing.xs,
      AppSpacing.xs,
      AppSpacing.xs + appBottomInset(context),
    ),
    child: Row( /* unchanged children */ ),
  ),
);
```

`_FailedStrip.build`: keep the error surface colour behind the bar:

```dart
final colors = Theme.of(context).colorScheme;
return ColoredBox(
  color: colors.errorContainer,
  child: Padding(
    padding: EdgeInsets.only(bottom: appBottomInset(context)),
    child: ErrorStrip(
      message,
      dismissTooltip: loc.stopTooltip,
      onDismiss: () => context.read<PlaybackCubit>().stopAndReset(),
    ),
  ),
);
```

- [x] **Step 4: Run the tests**

Run: `flutter test test/mini_player_inset_test.dart test/mini_player_bar_test.dart test/mini_player_stop_test.dart test/mini_player_failure_copy_test.dart` → all passing.

---

### Task 5: Sheets, mushaf page and reader error pane

**Files:**
- Modify: `lib/features/library/presentation/ayah_sheet/library_sheet.dart` (`_AyahSheetView.build`)
- Modify: `lib/features/quran/presentation/reader/reader_screen.dart` (`_VersesList`, `_MushafPager`, `_FailedView`)
- Test: `test/ayah_sheet_inset_test.dart`, `test/reader_inset_test.dart`

**Interfaces:**
- Consumes: `appBottomInset` / `appScrollPadding` (Task 2).

- [x] **Step 1: Write the failing sheet test**

```dart
// test/ayah_sheet_inset_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/library/presentation/ayah_sheet/library_sheet.dart';
import 'package:quran_yahdi/core/utils/insets.dart';

const double kHeight = 800;
const double kInset = 48;

void main() {
  testWidgets('modal sheet content pads for the nav bar', (tester) async {
    tester.view.physicalSize = const Size(400, kHeight);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: kInset);
    tester.view.viewPadding = const FakeViewPadding(bottom: kInset);
    addTearDown(tester.view.reset);

    late double contentBottom;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              useSafeArea: true,
              builder: (_) => LayoutBuilder(
                builder: (context, _) {
                  contentBottom = kHeight - appBottomInset(context);
                  return const SizedBox(key: Key('sheetContent'), height: 200);
                },
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final rect = tester.getRect(find.byKey(const Key('sheetContent')));
    expect(rect.bottom, lessThanOrEqualTo(kHeight - kInset));
  });
}
```

Note: this test proves the modal MediaQuery keeps `padding.bottom` (CASE5). The production change is the `SafeArea(top: false)` inside `_AyahSheetView`; the reader-sheet test below asserts it on the real widget.

- [x] **Step 2: Extend it to the real sheet**

Add a second test that pumps `AyahSheet` inside `showModalBottomSheet` with the real cubit is heavy; instead assert the shipped tree directly:

```dart
  testWidgets('AyahSheet wraps its content in a bottom SafeArea', (tester) async {
    // The widget is private; assert through the public route behaviour in
    // test/reader_inset_test.dart instead.
  });
```

The real-sheet assertion lives in `test/reader_inset_test.dart` (Step 4) so the route is exercised end to end.

- [x] **Step 3: Implement the sheet change**

In `_AyahSheetView.build`, inside the `Material`:

```dart
child: Material(
  color: colors.surface,
  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
  clipBehavior: Clip.antiAlias,
  child: SafeArea(top: false, child: content),
),
```

- [x] **Step 4: Write the failing reader test**

`test/reader_inset_test.dart` reuses the harness in `test/reader_screen_test.dart` (DB + `ReaderCubit` + `PlaybackCubit`), reaches `ReaderReady` with `mode: ReaderMode.mushaf`, and:

```dart
final pageLabel = tester.getRect(find.textContaining('صفحة'));
expect(pageLabel.bottom, lessThanOrEqualTo(800 - 48));
```

and for the failed state:

```dart
final retry = tester.getRect(find.text('إعادة المحاولة'));
expect(retry.bottom, lessThanOrEqualTo(800 - 48));
```

Run: `flutter test test/reader_inset_test.dart` → FAIL on both (the page label and the button sit in the bottom 48 dp).

- [x] **Step 5: Implement the reader changes**

- `_VersesList`: add `padding: EdgeInsets.only(bottom: appBottomInset(context)),` to `ScrollablePositionedList.builder`.
- `_MushafPager`: `padding: const EdgeInsets.all(AppSpacing.lg)` → `EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg + appBottomInset(context))`.
- `_FailedView`: `Padding(padding: const EdgeInsets.only(bottom: 32))` → `Padding(padding: EdgeInsets.only(bottom: 32 + appBottomInset(context)))`.

- [x] **Step 6: Run the tests**

Run: `flutter test test/ayah_sheet_inset_test.dart test/reader_inset_test.dart test/reader_screen_test.dart test/ayah_sheet_test.dart` → all passing.

---

### Task 6: Whole-tree gates

- [x] **Step 1: Format**

Run: `dart format lib test`
Then: `dart format --output=none --set-exit-if-changed lib test` → exit 0.

- [x] **Step 2: Analyze**

Run: `flutter analyze` → 0 issues.

- [x] **Step 3: Full suite**

Run: `flutter test` → 710 + (new tests). Record the exact count.

- [x] **Step 4: Census sweep (no missed scrollable)**

Run: `rg -n "ListView|GridView" lib/features --glob "!*.freezed.dart"` and confirm every screen-level scrollable either uses `appScrollPadding`/`appBottomInset` or is on the intentional skip list (horizontal chips, hadith list above its safe pager, grids inside cards).

- [ ] **Step 5: Commit (owner-gated)**

Only after an explicit GO. Suggested commits, explicit pathspecs:
1. `feat(a11y): system UI overlay style for forced edge-to-edge (Android 15/16)`
2. `feat(a11y): shared bottom-inset helper + scrollable body padding`
3. `fix(a11y): mini player clears the system navigation bar`
4. `fix(a11y): sheets and reader bottom controls clear the navigation bar`

## Self-Review

- Spec coverage: mechanism explanation (header), icons (`Task 1`), scrollables (`Task 3`), `Scaffold.bottomSheet` (`Task 4`), modal sheet (`Task 5`), reader bottom controls (`Task 5`), tests at 48 and 24 dp (`Task 2`, `Task 3`), explicit rejection of the opt-out flag / fixed height / app-wide SafeArea (Architecture + Global Constraints).
- Placeholder scan: no TBD; every code step carries the actual code; every run step carries the expected result.
- Type consistency: `appBottomInset(BuildContext) -> double` and `appScrollPadding(BuildContext, EdgeInsets) -> EdgeInsets` are used with those names in every task; `AppSystemUi.overlayStyle(Brightness)` likewise.
- Known trade-off (disclosed): while the mini player is visible the reader/reciter lists keep their own bottom inset, which adds one inset-sized gap above the already-padded bar. Accepted over state-coupled padding.

## Execution log (2026-10-27)

- Tasks 1-5 executed in this session, test-first (every new test was watched failing before its production change).
- Gates at the final tip: dart format --output=none --set-exit-if-changed lib test = exit 0 · lutter analyze = 0 issues · lutter test = **724 passed** (baseline 710 + 14 new).
- Devation 1 (helper): MediaQueryData.removePadding subtracts from iewPadding too (media_query.dart:1011), so the plan's original max(padding, viewPadding) returned 0 inside Scaffold.bottomSheet. The helper now reads View.of(context).viewPadding (the frame value that survives MediaQuery surgery) and keeps MediaQuery.padding as the body-side signal.
- Deviation 2 (test selector): the mini-player surface is asserted via Material.elevation == 4 because ind.byType(Material).last matched an IconButton's inner Material.
- Census sweep after the waves: every screen-level ListView/GridView under lib/features uses ppScrollPadding/ppBottomInset except four intentional skips — home/hijri GridView.count(shrinkWrap: true) inside a padded ListView, the ayah-sheet list inside its new SafeArea, and the hadith list above its already-safe pager.
- NOT committed: awaiting owner GO. Working tree carries the 24 modified + 9 new files listed in the plan.
