# Quran workspace — two-pane master/detail on expanded windows

- **Date:** 2026-11-06
- **Status:** design approved in chat; spec awaiting owner review
- **Owner decision:** shape **C — nested Navigator**, masters = surah index + juz index + bookmarks
- **Repo:** `E:\old_flutter\Quran-App-master` · base `main` = `9d9bfb7`
- **Wave branch (planned):** `wave/quran-workspace` · no push without GO

## 1. Problem

The responsive wave gave every screen a width strategy, but the Quran tab still
behaves like a phone on a tablet: the surah index is one full-width list, and
opening a surah replaces it with a full-screen reader. A tablet has enough
width to keep the index, the juz starts or the bookmark list beside the text.

## 2. Goal

On an **expanded** window (≥ 840 dp), `/quran` becomes a workspace:

```
Row
├── master pane (300–340 dp)
│   ├── TabBar: سور · أجزاء · علامات
│   └── active master body (search/list · juz list · bookmark list)
├── VerticalDivider
└── detail pane (Expanded)
    └── nested Navigator
        ├── empty prompt (no selection)
        └── reader pane (AppBar + ReaderView, no mini player)
```

Below 840 dp the tab keeps today's `SurahIndexScreen` exactly as it is.

### Success criteria

- A surah, juz or bookmark can be selected on a tablet and read beside the
  list without losing the list.
- Back closes the reader pane first, then behaves as today.
- No behaviour change on compact widths.
- No new package; no schema change; phone tests untouched.

## 3. Routing

| Route | Compact (< 840) | Expanded (≥ 840) |
|---|---|---|
| `/quran` | `SurahIndexScreen` | `QuranWorkspaceScreen` |
| `/quran/juz` | `JuzIndexScreen` | `JuzIndexScreen` (unchanged) |
| `/quran/reader?surah=&ayah=` | full-screen `ReaderScreen` | full-screen `ReaderScreen` (unchanged) |
| `/bookmarks` | `BookmarksScreen` | `BookmarksScreen` (unchanged) |

- The `/quran` route keeps its `RouteCubitScope<SurahIndexCubit>` and swaps only
  the child, through a new `QuranTabScreen` that reads the width:
  `isExpanded ? QuranWorkspaceScreen(...) : SurahIndexScreen()`.
- The in-pane reader is **not** a URL. Selecting inside the workspace keeps the
  browser location at `/quran`; the full reader route stays the shareable and
  deep-linkable path. This is a stated trade-off, not an oversight.
- `/quran/juz` and `/bookmarks` stay standalone for compact and deep links; the
  workspace exposes the same content as tabs.
- `PopScope`: with a reader open, back clears the selection; with no reader it
  falls through to the normal route behaviour.

## 4. Components and contracts

### 4.1 `QuranTabScreen` (new, route level)

```dart
class QuranTabScreen extends StatelessWidget {
  const QuranTabScreen({super.key});
}
```

- Reads `AppBreakpoints.isExpanded(context)`.
- Creates the two **extra** master cubits (`JuzIndexCubit`, `BookmarksCubit` +
  `BookmarkMetaCubit`) when the workspace mounts; the `SurahIndexCubit` comes
  from the existing route scope and is reused by both presentations.
- Provides the `ReaderCubit` factory for the pane.
- Returns `QuranWorkspaceScreen(...)` on expanded, `SurahIndexScreen()` below.
- Files: `lib/features/quran/presentation/workspace/quran_tab_screen.dart`,
  `quran_workspace_screen.dart`, `reader_pane.dart`.
- Production wiring lives in `lib/app/router.dart`:
  - replace `child: const SurahIndexScreen()` with `child: const QuranTabScreen()`;
  - the `RouteCubitScope<SurahIndexCubit>` around it stays and is reused by both
    presentations.

### 4.2 `QuranWorkspaceScreen` (new, presentation only)

```dart
class QuranWorkspaceScreen extends StatefulWidget {
  const QuranWorkspaceScreen({
    super.key,
    required this.createReader,
  });

  /// Builds a side-effect-free ReaderCubit for (surah, ayah). Production
  /// passes the getIt-backed factory; tests pass a fake. The pane scope calls
  /// start() in initState, exactly like RouteCubitScope does today.
  final ReaderCubit Function(int surah, int ayah) createReader;
}
```

- `Scaffold(appBar: AppBar(title: quran, actions: [search]))`.
- Body: `Row` — master width 300 dp at 840–1023, 340 dp at ≥ 1024 — divider,
  `Expanded(detail)`.
- Owns `TabController` (3 tabs, `isScrollable: true` so 2.0 text scale on a
  300 dp pane never clips) and `_selection` (`({int surah, int ayah})?`).
- Detail: a declarative `Navigator` with two pages:
  - key `empty` → `_EmptyDetail(prompt)`.
  - key `reader-$surah-$ayah` when `_selection != null` → `ReaderPane(...)`.
  - Selecting replaces the page in the second slot; `onDidRemovePage` clears
    `_selection` when the Navigator pops the reader, so the declarative page
    list and the selection never disagree. Back returns to the prompt.
- `PopScope(canPop: _selection == null)`; while a reader is open, back sets
  `_selection = null` and does not pop the route.
- Tab switch keeps the reader open; the reader's bookmarks action switches to
  the bookmarks tab instead of pushing `/bookmarks`.

### 4.3 `ReaderView` + `ReaderActions` (extracted from `ReaderScreen`)

- `ReaderView`: the existing body (basmala + verse list/mushaf pager +
  `SelectionArea`), no `Scaffold`, no `bottomSheet`.
- `ReaderActions`: the five existing AppBar actions (listen, mushaf/verses,
  bookmarks, page jump, font size). Gains
  `VoidCallback? onOpenBookmarks`; null keeps today's `context.push`.
- `ReaderScreen` keeps its `Scaffold`, `AppBar(title: surahName,
  actions: ReaderActions())`, `ReaderView`, and `bottomSheet: MiniPlayerBar()`.
- `ReaderPane` (new): `Scaffold(appBar: AppBar(primary: false, title:
  surahName, leading: back, actions: ReaderActions(onOpenBookmarks: ...)),
  body: ReaderView())`. It does **not** mount a mini player — the app shell
  already owns one.
- `ReaderRouteScope` (new, small): wraps `RouteCubitScope<ReaderCubit>` with
  identity `(surah, ayah)` and the existing `create`/`start`; the full reader
  route keeps its `BlocProvider<PlaybackCubit>` wrapper and uses
  `ReaderRouteScope` inside it, and `ReaderPane` uses the same scope (the shell
  already provides `PlaybackCubit` there).

### 4.4 Master bodies (extracted)

| Widget | Extracted from | Callback |
|---|---|---|
| `SurahIndexBody` | `SurahIndexScreen` (search + list) | `onSelect(SurahSummary)` |
| `JuzIndexBody` | `JuzIndexScreen` (list) | `onSelect(JuzSummary)` |
| `BookmarksBody` | `BookmarksScreen` (`_BookmarkList`) | `onSelect(Verse)` |

- Each takes `selectedId` for the highlight and keeps its existing cubit reads;
  the full screens keep their `Scaffold`s and pass the old navigation callback.
- `BookmarksBody(showMeta: false)` in the workspace: no folder chips, no
  note/folder editing (v1 limit, §7). The full `/bookmarks` screen keeps them.

## 5. State and lifecycle

- Master cubits:
  - `SurahIndexCubit` — created by the existing `/quran` route scope, shared by
    both presentations.
  - `JuzIndexCubit` and `BookmarksCubit` (+ `BookmarkMetaCubit`) — created by
    `QuranTabScreen` when the workspace mounts, one scope per tab, kept alive by
    an `IndexedStack`.
  - All three tabs mount together (an `IndexedStack` builds every child), so all
    master cubits start on workspace mount. They are local reads only (surah
    list, 30 rows, bookmarks page 1); no network.
- Reader: `ReaderRouteScope` per `(surah, ayah)`; changing the selection closes
  the previous cubit through `RouteCubitScope` and starts the new one.
- The reader's last-read save and bookmark state work as today.
- Mini player: owned by the shell's bottom bar; the pane never mounts another.
- `showAppSheet` gains `useRootNavigator: true`, so a pane sheet (font, ayah,
  share) opens over the whole app instead of being confined to the pane.

## 6. Responsive, RTL and accessibility

- Workspace only at ≥ 840; master 300/340 dp; detail fills the rest and keeps
  the reader measure (760) centred on very wide windows.
- Arabic RTL: the master pane is on the right (the `Row` follows
  `Directionality`); in English it is on the left.
- Tab labels are existing strings (`quran`, `juzIndexTitle`, `bookmarks`);
  `TabBar.isScrollable` keeps them readable at text scale 2.0.
- The selected master row is highlighted and announced as selected.
- Empty prompt is one new ARB key (AR + EN, additive, generated files
  committed):
  `quranWorkspacePrompt` — «اختر سورة أو جزءًا أو علامة للقراءة» /
  "Pick a surah, juz or bookmark to read".

## 7. Out of scope (v1)

- URL sync for the in-pane selection (the full reader route remains shareable).
- Folder chips, note editing and folder screens inside the pane.
- Resizable divider, three-column layout, compact two-pane.
- Changing `/quran/juz` or `/bookmarks` routes into the workspace.
- Reader state restoration across app restarts.

## 8. Failure and empty states

- A failing master cubit renders the existing `errorPane` inside its tab.
- Empty bookmarks renders the existing `noBookmarks` state; the empty detail
  renders `quranWorkspacePrompt`.
- A failing reader keeps the existing `_ReaderErrorView` inside the pane, with
  retry.
- No selection after a width change to compact: the workspace unmounts and the
  plain index mounts; the reader pane closes (accepted).

## 9. Testing

New `test/quran_workspace_test.dart`:

1. 1024×768 with providers: three tabs, master + prompt, no `SurahIndexScreen`.
2. 800×600: `SurahIndexScreen`, no workspace.
3. Tap a surah: reader pane shows the surah; the router URI stays `/quran`
   (pump the real `MaterialApp.router` with DI, as
   `app_shell_adaptive_test` does, and assert `AppRouter.router.state.uri.path`).
4. Back arrow: prompt returns, workspace stays.
5. Tap a juz: reader opens at that juz's first surah/ayah.
6. Tap a bookmark: reader opens at the bookmarked ayah.
7. Tab switch keeps the search query and the open reader.
8. 1024 at text scale 2.0: no overflow, tabs scrollable.
9. English LTR: master on the left.

Existing suites to keep green: `surah_index_screen_test`, `juz_index_screen_test`,
`bookmarks_screen_test`, `quran_core_quality_probe_test`, `reader_inset_test`,
`app_shell_adaptive_test`, `player_sheet_test`, `verse_share_sheet_test`.

Gates: `dart format --set-exit-if-changed lib test tools` = 0 ·
`flutter analyze` = 0 · full `flutter test` (exact count reported).

## 10. Risks

| Risk | Mitigation |
|---|---|
| Reader extraction breaks the full route | `ReaderScreen` keeps its exact widget tree around `ReaderView`; existing reader tests are the pin |
| Three master cubits on mount cost | local reads only; measure first frame at 1024 in the widget test |
| Nested Navigator + root sheets | `showAppSheet(useRootNavigator: true)`; font/ayah/share tests re-run |
| Master pane too narrow at 2.0 | 300 dp floor + scrollable tabs + 320-wide probe |
| Route-level width swap loses selection | accepted; workspace unmounts on compact |

## 11. Delivery shape

1. `refactor(reader): extract ReaderView/ReaderActions` (no behaviour change).
2. `feat(quran): add the expanded two-pane workspace` (tab screen, bodies,
   navigator, l10n, tests).
3. Docs/ledger close-out after gates.

No push without the owner's GO.
