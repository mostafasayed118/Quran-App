# Quran workspace (two-pane) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On expanded windows (≥ 840 dp), `/quran` shows a three-tab master pane (surah index, juz index, bookmarks) beside a nested-navigator reader pane, with the compact tab unchanged.

**Architecture:** A route-level `QuranTabScreen` chooses the presentation by width. On expanded it mounts `QuranWorkspaceScreen`, which owns a `TabController`, keeps the three master bodies alive in an `IndexedStack`, and hosts a declarative nested `Navigator` whose second page is `ReaderPane`. The existing `ReaderScreen` is split into `ReaderView` + `ReaderActions` so the pane reuses the reader without its own Scaffold or mini player. Master list bodies are extracted from their screens with an `onSelect` callback.

**Tech Stack:** Flutter 3.47.5, flutter_bloc, go_router 18, freezed states, drift, flutter_test.

**Spec:** `docs/superpowers/specs/2026-11-06-quran-workspace-design.md`

## Global Constraints

- No new packages; no schema change; no new assets.
- Workspace only at `AppBreakpoints.expanded` (840 dp); below it the compact behaviour is byte-identical.
- l10n is additive + symmetric: AR template → EN mirror; run `flutter gen-l10n` and commit the generated files.
- No Class A frozen test may be edited; a perceived need is a STOP.
- Gates after every task: `dart format --set-exit-if-changed lib test tools` = 0, `flutter analyze` = 0, the task's tests green. Full suite at the wave tip.
- Commits: English, explicit pathspecs, one per task; **no push** in this plan.
- Wave branch: `wave/quran-workspace` cut from `main` (`9d9bfb7`).
- The in-pane selection does not change the URL; `/quran/reader` remains the shareable route.

## Review Focus

1. **Back with a reader open** must clear the pane and keep the workspace, not exit the tab.
2. **Switching master tabs** must not close or reset the open reader.
3. **Re-selecting the same surah** must replace the pane, never stack duplicate pages or leak a `ReaderCubit`.
4. **Expanded → compact while a reader is open** must unmount the workspace without a cubit leak or exception.
5. **A sheet opened from the pane** (font, ayah, share) must sit above the whole app (root navigator), not be clipped to the pane.
6. **RTL** must put the master pane on the right and keep the divider/back affordances correct.

Each is pinned in the task that owns the code (Tasks 3–5).

---

### Task 1: Split the reader body and actions from `ReaderScreen`

**Files:**
- Modify: `lib/features/quran/presentation/reader/reader_screen.dart`
- Test: `test/reader_view_test.dart` (new)

**Interfaces:**
- Consumes: existing `ReaderCubit`, `ReaderReady`, `ReaderFailed`, `ReaderMode`.
- Produces:
  - `class ReaderView extends StatelessWidget { const ReaderView({super.key, required this.state}); final ReaderReady state; }`
  - `class ReaderActions extends StatelessWidget { const ReaderActions({super.key, required this.state, this.onOpenBookmarks}); final ReaderReady state; final VoidCallback? onOpenBookmarks; }`
  - `class ReaderErrorBody extends StatelessWidget { const ReaderErrorBody({super.key, required this.state}); final ReaderFailed state; }`
  - `ReaderScreen` keeps the same public constructor and widget tree semantics.

- [ ] **Step 1: Write the failing test**

Use the reader setup from `test/quran_core_quality_probe_test.dart` (test DB + seeded surah/ayahs + `FakePlaybackService`) and assert:

```dart
expect(find.byType(ReaderView), findsOneWidget);
expect(find.byType(ReaderActions), findsOneWidget);
expect(find.byTooltip('حجم الخط'), findsOneWidget);
expect(find.text('الم'), findsOneWidget);
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/reader_view_test.dart`
Expected: compile error, `ReaderView`/`ReaderActions` undefined.

- [ ] **Step 3: Extract the widgets**

In `reader_screen.dart`:
- `ReaderView` = the current `_ReadyView` body `Builder` (basmala + `_VersesList`/`_MushafPager` + `SelectionArea`).
- `ReaderActions` = the five current `AppBar` actions; the bookmarks action becomes `onOpenBookmarks ?? () => context.push(AppRoutes.bookmarks)`; the rest keep their existing helpers.
- `ReaderErrorBody` = the current `_ReaderErrorView` body column.
- `_ReadyView` = `Scaffold(appBar: AppBar(title: state.surahName, actions: ReaderActions(state)), body: ReaderView(state), bottomSheet: const MiniPlayerBar())`.
- `_ReaderErrorView` = `Scaffold(appBar: AppBar(title: loc.quran), body: ReaderErrorBody(state))`.

- [ ] **Step 4: Run the new test and the reader suites**

Run: `flutter test test/reader_view_test.dart test/reader_inset_test.dart test/quran_core_quality_probe_test.dart test/verse_share_sheet_test.dart`
Expected: PASS.

The commit for Tasks 1–3 lands at the end of Task 3, so this task ends at the green test run.

---

### Task 2: Extract the three master list bodies

**Files:**
- Create: `lib/features/quran/presentation/index/surah_index_body.dart`
- Create: `lib/features/quran/presentation/index/juz_index_body.dart`
- Create: `lib/features/quran/presentation/bookmarks/bookmarks_body.dart`
- Modify: `lib/features/quran/presentation/index/surah_index_screen.dart`
- Modify: `lib/features/quran/presentation/index/juz_index_screen.dart`
- Modify: `lib/features/quran/presentation/bookmarks/bookmarks_screen.dart`
- Test: `test/quran_master_bodies_test.dart` (new)

**Interfaces:**
- Consumes: existing `SurahIndexCubit`, `JuzIndexCubit`, `BookmarksCubit`.
- Produces:
  - `class SurahIndexBody extends StatelessWidget { const SurahIndexBody({super.key, required this.onSelect, this.selectedSurahId}); final ValueChanged<SurahSummary> onSelect; final int? selectedSurahId; }`
  - `class JuzIndexBody extends StatelessWidget { const JuzIndexBody({super.key, required this.onSelect, this.selectedJuz}); final ValueChanged<JuzSummary> onSelect; final int? selectedJuz; }`
  - `class BookmarksBody extends StatelessWidget { const BookmarksBody({super.key, required this.onSelect, this.selectedAyahId, this.showMeta = false}); final ValueChanged<Verse> onSelect; final int? selectedAyahId; final bool showMeta; }`
  - The three screens keep their constructors; they pass `onSelect` that pushes the reader (surah/juz) or the existing list tap.

- [ ] **Step 1: Write the failing tests**

For each body, pump it with its cubit and an `onSelect` spy, tap the first row, and assert the spy received the right domain object and no route was pushed:

```dart
expect(selectedSurah?.id, 1);
expect(selectedJuz?.juz, 1);
expect(selectedVerse?.numberInSurah, 1);
```

Use the seeding patterns from `test/surah_index_screen_test.dart`, `test/juz_index_screen_test.dart` and `test/bookmarks_screen_test.dart`.

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/quran_master_bodies_test.dart`
Expected: compile errors for the three bodies.

- [ ] **Step 3: Extract the bodies**

Move the list/search UI out of each screen into the new widget. The screens become `Scaffold` + `AppContentFrame` + the body, and their `onSelect` keeps the current navigation:
- surah: `context.push(quranReaderPath(surah: summary.id))`
- juz: `context.push(quranReaderPath(surah: entry.surahId, ayah: entry.numberInSurah))`
- bookmarks: the current row tap (reader at the verse).

`BookmarksBody` owns the `_BookmarkList` rendering (and the meta chips only when `showMeta` is true); the workspace passes `showMeta: false`.

- [ ] **Step 4: Run the new test and the three existing screen suites**

Run: `flutter test test/quran_master_bodies_test.dart test/surah_index_screen_test.dart test/juz_index_screen_test.dart test/bookmarks_screen_test.dart test/bookmarks_meta_screen_test.dart`
Expected: PASS.

The commit for Tasks 1–3 lands at the end of Task 3.

---

### Task 3: Share the reader route scope

**Files:**
- Create: `lib/features/quran/presentation/reader/reader_route_scope.dart`
- Modify: `lib/app/router.dart`
- Test: `test/reader_route_scope_test.dart` (new)

**Interfaces:**
- Produces:

```dart
class ReaderRouteScope extends StatelessWidget {
  const ReaderRouteScope({
    super.key,
    required this.surah,
    required this.ayah,
    required this.create,
    required this.child,
  });
  final int surah;
  final int ayah;
  final ReaderCubit Function() create;
  final Widget child;
}
```

It wraps `RouteCubitScope<ReaderCubit>` with `identity: (surah, ayah)`, `create: create`, `start: (c) => c.start()`.

- [ ] **Step 1: Write the failing test**

Pump `ReaderRouteScope` with a counting factory and a `ValueKey` that changes `surah`; assert the factory ran once per identity, `start` ran once per cubit, and the old cubit was closed.

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/reader_route_scope_test.dart`
Expected: undefined `ReaderRouteScope`.

- [ ] **Step 3: Implement the scope and use it in the reader route**

In `router.dart`, replace the inline `RouteCubitScope<ReaderCubit>` with `ReaderRouteScope(surah: ..., ayah: ..., create: () => ReaderCubit(...), child: const ReaderScreen())`. Keep the `BlocProvider<PlaybackCubit>` wrapper.

- [ ] **Step 4: Run the test and the app boot/reader suites**

Run: `flutter test test/reader_route_scope_test.dart test/app_shell_adaptive_test.dart test/quran_core_quality_probe_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit the refactor slice (Tasks 1–3)**

```bash
git add lib/features/quran/presentation/reader/reader_screen.dart lib/features/quran/presentation/reader/reader_route_scope.dart lib/features/quran/presentation/index/surah_index_body.dart lib/features/quran/presentation/index/juz_index_body.dart lib/features/quran/presentation/bookmarks/bookmarks_body.dart lib/features/quran/presentation/index/surah_index_screen.dart lib/features/quran/presentation/index/juz_index_screen.dart lib/features/quran/presentation/bookmarks/bookmarks_screen.dart lib/app/router.dart test/reader_view_test.dart test/quran_master_bodies_test.dart test/reader_route_scope_test.dart
git commit -m "refactor(quran): split the reader and extract selectable master bodies"
```

---

### Task 4: Build the workspace and the reader pane

**Files:**
- Create: `lib/features/quran/presentation/workspace/quran_workspace_screen.dart`
- Create: `lib/features/quran/presentation/reader/reader_pane.dart`
- Modify: `lib/l10n/app_ar.arb`, `lib/l10n/app_en.arb` (+ generated files)
- Test: `test/quran_workspace_test.dart` (new)

**Interfaces:**
- Consumes from context: `SurahIndexCubit`, `JuzIndexCubit`, `BookmarksCubit`
  and `PlaybackCubit` (the route/shell provides them); `SurahIndexBody`,
  `JuzIndexBody`, `BookmarksBody` (Task 2); `ReaderView`, `ReaderActions`
  (Task 1); `ReaderRouteScope` (Task 3); `AppBreakpoints`; `showAppSheet`.
- Produces:

```dart
class QuranWorkspaceScreen extends StatefulWidget {
  const QuranWorkspaceScreen({
    super.key,
    required this.createReader,
  });
  final ReaderCubit Function(int surah, int ayah) createReader;
}
```

and

```dart
class ReaderPane extends StatelessWidget {
  const ReaderPane({
    super.key,
    required this.surah,
    required this.ayah,
    required this.createReader,
    this.onOpenBookmarks,
  });
  final int surah;
  final int ayah;
  final ReaderCubit Function(int surah, int ayah) createReader;
  final VoidCallback? onOpenBookmarks;
}
```

- [ ] **Step 1: Add the one new string**

AR: `"quranWorkspacePrompt": "اختر سورة أو جزءًا أو علامة للقراءة"` ·
EN: `"quranWorkspacePrompt": "Pick a surah, juz or bookmark to read"`.
Run `flutter gen-l10n`; the generated `app_localizations*.dart` ride with the
feature commit at the end of Task 5.

- [ ] **Step 2: Write the failing workspace tests**

Pump `QuranWorkspaceScreen` with three fake master cubits, a `PlaybackCubit` (existing `FakePlaybackService`) and a `createReader` that returns a `ReaderCubit` over the test DB. Cover:

```dart
// 1) 1024x768: tabs + prompt, no surah list-only screen
expect(find.text('سور'), findsOneWidget);
expect(find.text('أجزاء'), findsOneWidget);
expect(find.text('علامات'), findsOneWidget);
expect(find.text('اختر سورة أو جزءًا أو علامة للقراءة'), findsOneWidget);

// 2) tap the first surah -> ReaderPane, URL not involved
expect(find.byType(ReaderPane), findsOneWidget);
expect(find.text('الفاتحة'), findsWidgets);

// 3) back -> prompt, workspace still there
expect(find.text('اختر سورة أو جزءًا أو علامة للقراءة'), findsOneWidget);

// 4) tapping a juz opens the reader at that juz's first ayah

// 5) tapping a bookmark opens the reader at the bookmarked ayah

// 6) switching tabs keeps the surah search text and the open reader

// 7) re-selecting the same surah keeps exactly one ReaderPane and does not
//    create a second ReaderCubit (factory call count stays 1)

// 8) 1024 at textScale 2.0: no exception, TabBar scrollable

// 9) English: the master pane is on the left of the divider
```

Capture the reader's surah/ayah through the `createReader` spy (record `(surah, ayah)`).

- [ ] **Step 3: Run to verify they fail**

Run: `flutter test test/quran_workspace_test.dart`
Expected: compile errors for `QuranWorkspaceScreen` / `ReaderPane`.

- [ ] **Step 4: Implement `ReaderPane`**

`ReaderRouteScope` → `BlocBuilder<ReaderCubit, ReaderState>`:
- Ready → `Scaffold(appBar: AppBar(primary: false, title: Text(state.surahName), actions: ReaderActions(state, onOpenBookmarks: onOpenBookmarks)), body: ReaderView(state))`.
- Loading → `Scaffold(appBar: AppBar(primary: false, title: Text(loc.quran), leading: const BackButton()), body: const LoadingView())`.
- Failed → the same shell with `ReaderErrorBody(state)`.
No `bottomSheet`, no mini player.

- [ ] **Step 5: Implement `QuranWorkspaceScreen`**

- `TabController(length: 3, vsync: this)`, `_selection`, `_detailKey`; add a
  controller listener that `setState`s so the `IndexedStack` index follows the
  selected tab.
- `Scaffold(appBar: AppBar(title: Text(loc.quran), actions: [search icon → context.push(AppRoutes.quranSearch)]))`.
- `Row`: `SizedBox(width: width >= 1024 ? 340 : 300, child: Column(TabBar(isScrollable: true), Expanded(IndexedStack(children: [SurahIndexBody, JuzIndexBody, BookmarksBody]))))`, `VerticalDivider`, `Expanded(Navigator(...))`.
- Selection handlers: surah → `(surah: id, ayah: 0)`, juz → `(surahId, numberInSurah)`, bookmark → `(verse.surahId, verse.numberInSurah)`.
- Declarative `Navigator` pages: empty prompt + `ReaderPane` with `ValueKey('reader-$surah-$ayah')`; `onDidRemovePage` clears `_selection`.
- `PopScope(canPop: _selection == null)`: back clears the selection.
- `onOpenBookmarks` sets the tab index to 2.
- `selectedSurahId` / `selectedJuz` / `selectedAyahId` come from `_selection`.

- [ ] **Step 6: Run the workspace tests**

Run: `flutter test test/quran_workspace_test.dart`
Expected: PASS (all nine).

The commit for Tasks 4–5 lands at the end of Task 5.

---

### Task 5: Wire the tab, the router and the root sheets

**Files:**
- Create: `lib/features/quran/presentation/workspace/quran_tab_screen.dart`
- Modify: `lib/app/router.dart`
- Modify: `lib/core/widgets/app_sheet.dart`
- Test: `test/quran_workspace_route_test.dart` (new)

**Interfaces:**
- Produces: `class QuranTabScreen extends StatelessWidget { const QuranTabScreen({super.key}); }` — returns `QuranWorkspaceScreen` at ≥ 840 and `SurahIndexScreen` below.
- `showAppSheet` gains `useRootNavigator: true`.

- [ ] **Step 1: Write the failing route test**

Use the real app boot from `test/app_shell_adaptive_test.dart` (`configureDependencies`, temp path provider, `MaterialApp.router`):

```dart
// 800x600
AppRouter.router.go(AppRoutes.quran);
expect(find.byType(SurahIndexScreen), findsOneWidget);
expect(find.byType(QuranWorkspaceScreen), findsNothing);

// 1024x768
expect(find.byType(QuranWorkspaceScreen), findsOneWidget);
await tester.tap(find.text('الفاتحة'));
await tester.pumpAndSettle();
expect(find.byType(ReaderPane), findsOneWidget);
expect(AppRouter.router.state.uri.path, AppRoutes.quran); // no route push
```

Also cover: back returns to the prompt; the juz tab opens the reader; a font
sheet opened from the pane is found once (root navigator, not clipped); and
resizing 1024 → 800 with a reader open unmounts the workspace without an
exception and shows `SurahIndexScreen`.

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/quran_workspace_route_test.dart`
Expected: `QuranWorkspaceScreen` never appears (route still builds `SurahIndexScreen`).

- [ ] **Step 3: Implement `QuranTabScreen`**

- `AppBreakpoints.isExpanded(context)` chooses.
- On expanded, create the extra scopes (`JuzIndexCubit`, `BookmarksCubit` + `BookmarkMetaCubit`) with the same `getIt` sources used by the standalone routes, and pass a `createReader` built from the `ReaderCubit` dependencies in `router.dart` (extract that factory to a private helper in the tab screen so the route builder stays small).
- The `SurahIndexCubit` stays in the route scope.

- [ ] **Step 4: Wire the router and the sheet root navigator**

- `/quran` child becomes `const QuranTabScreen()`.
- `showAppSheet` passes `useRootNavigator: true`.
- Re-run the sheet tests to prove no regression.

- [ ] **Step 5: Run the route test, sheet tests and the reader suite**

Run: `flutter test test/quran_workspace_route_test.dart test/verse_share_sheet_test.dart test/player_sheet_test.dart test/quran_core_quality_probe_test.dart test/app_shell_adaptive_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit the feature slice (Tasks 4–5)**

```bash
git add lib/features/quran/presentation/workspace/quran_workspace_screen.dart lib/features/quran/presentation/workspace/quran_tab_screen.dart lib/features/quran/presentation/reader/reader_pane.dart lib/app/router.dart lib/core/widgets/app_sheet.dart lib/l10n/app_ar.arb lib/l10n/app_en.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_ar.dart lib/l10n/app_localizations_en.dart test/quran_workspace_test.dart test/quran_workspace_route_test.dart
git commit -m "feat(quran): add the expanded two-pane workspace"
```

---

### Task 6: Wave gates, ledger and close-out

**Files:**
- Modify: `docs/campaign-ledger.md`
- Test: full suite

- [ ] **Step 1: Run the full gates at the branch tip**

```bash
dart format --set-exit-if-changed lib test tools
flutter analyze
flutter test
```

Expected: format 0 · analyze 0 · all tests pass; record the exact count.

- [ ] **Step 2: Device leg (required before merge)**

Build `flutter build apk --debug`, install on `A16_API36`, open `/quran` at 1024×640 dp, select a surah, check the pane + back, switch all three tabs, 2.0 text scale. Screenshot into `C:\Users\ASUS\AppData\Local\Temp\opencode\quran_workspace\`. If no emulator/device is available, record it as a STOP and do not claim the merge is ready.

- [ ] **Step 3: Append the ledger close-out**

Record the commits, gates, device evidence, the URL trade-off and the v1 limits. Append only; never edit earlier entries.

- [ ] **Step 4: Commit the docs-only close-out**

```bash
git add docs/campaign-ledger.md docs/superpowers/specs/2026-11-06-quran-workspace-design.md docs/superpowers/plans/2026-11-06-quran-workspace.md
git commit -m "docs: close out the quran workspace wave"
```

No push. The owner reviews the branch and opens the push window separately.
