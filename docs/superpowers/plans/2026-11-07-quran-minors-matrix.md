# Quran workspace — deferred minors + responsive matrix

- **Date:** 2026-11-07
- **Branch:** `wave/quran-minors-matrix` from `main` = `0f22a36`
- **Owner GO:** «5 minors + matrix», minors first.
- **No push** until a separate owner GO.

## Part 1 — the five deferred minors

| # | Minor | Fix | Pin |
|---|---|---|---|
| M1 | Page jump from the pane pushes the full reader; its dialog is pane-modal | `ReaderActions` gains `onOpenAyah(surah, ayah)`; the pane resolves the anchor in place; `showDialog(useRootNavigator: true)` | workspace test: page jump opens surah 2 inside the same pane, factory called with (2,2) |
| M2 | Bookmark delete confirmation is pane-modal | `confirmDeleteDialog(useRootNavigator: true)` | existing delete tests stay green |
| M3 | `createBookmarkMeta` is dead wiring | drop the factory, provider and router argument | analyze + workspace/route tests |
| M4 | IME focus stays on a hidden tab | unfocus the primary focus in the `TabController` listener | workspace test: search focused → juz tab → focus false |
| M5 | Third tab label clipped at 340 dp | short workspace labels (AR/EN additive), tab bar still scrollable at 2.0 | workspace test: all three labels fit inside the master rect at 1024 |

## Part 2 — responsive matrix probes

Add 320×640 / textScale 2.0 and 1024×768 / 1.0 probes to the screens without
one: library, bookmarks, folder bookmarks, prayer month, quran search,
reciters, reciter surahs, adhan picker, licenses, settings (2.0), hijri (2.0).
Onboarding already has 320/2.0. Each probe asserts `takeException() == null`
and the screen's primary content is still present.

## Gates

`dart format --set-exit-if-changed lib test tools` = 0 · `flutter analyze` = 0 ·
full `flutter test` (exact count). Device smoke at 1024 dp for M1/M5 after the
code fixes. Commit shape: minors commit, matrix commit, docs close-out.
