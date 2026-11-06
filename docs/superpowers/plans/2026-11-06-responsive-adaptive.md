# Responsive & adaptive audit — 2026-11-06

> **Verdict:** the app is **not** responsive/adaptive at 100%. It is a
> well-behaved phone-portrait app: every screen scrolls, insets and text-scale
> were handled screen by screen, and 14 screens carry a 2.0 text-scale probe.
> What it has never had is a **width strategy**: there is not one breakpoint,
> not one max content width, and the shell renders the same bottom bar from a
> 320 dp phone to a 1280 dp tablet. Reading surfaces stretch to the full
> display width, and eight RTL-only alignments stay RTL after the user picks
> English.
>
> **Scope:** Flutter app only (`lib/**`, `test/**`). `web/**` is a separate
> campaign. iOS is out of scope (rejected for v1 in the v1.1 plan).
>
> **Baseline:** `main` = `227fc2f`, 2 unpushed commits (`dba7d42`, `227fc2f`),
> full suite 1394/1394, format 0, analyze 0.
>
> **Status 2026-11-06:** waves R1–R8 are **implemented in the working tree**,
> uncommitted. Gates: format 0, analyze 0, full suite **1412/1412**
> (+18 responsive tests). Device proof captured on the API 36 emulator
> (phone portrait 1.0/2.0, 320 dp / 2.0, tablet 1024 dp landscape 1.0/2.0,
> phone landscape 914×411 dp): rail, caps and reader measure render as
> designed, no overflow banner. The share-sheet inset is pinned by a
> 320×640 + 48 dp widget test (the pre-fix emulator run showed the action
> sitting under the gesture bar). Commit/push await the owner GO.

## 1. What "100%" means here

A screen passes only if all of these hold:

| Axis | Values that must be proven |
|---|---|
| Width | 320 · 360 · 411 · 600 · 840 · 1024 · 1280 dp |
| Height / orientation | portrait · landscape 360 dp tall |
| Text scale | 1.0 · 1.3 · 2.0 |
| Locale / direction | Arabic RTL · English LTR |
| Theme | light · dark |
| Insets | 0 dp · 24 dp · 48 dp bottom; keyboard open |
| Touch | every tappable ≥ 48 × 48 dp |

Pass = no `RenderFlex` overflow, no clipped/ellipsized localized label, no
content line wider than its reading measure, no fixed-width child wider than
the viewport, and navigation reachable at every width.

## 2. Evidence — findings

Severity: **S1** breaks a class of devices · **S2** visibly wrong layout ·
**S3** polish.

| # | Sev | Finding | Evidence |
|---|---|---|---|
| R-01 | S1 | No width strategy: zero breakpoints, zero max content widths in `lib/**`. Every scroll body is full-bleed at any width. | `rg maxWidth lib` → only `qibla_screen.dart:508` (dial cap) and `licenses_screen.dart:142` (dialog). |
| R-02 | S1 | The shell is bottom-bar-only: a 1280 dp tablet still gets a phone navigation bar. | `lib/app/app_shell.dart:57-97` — `bottomNavigationBar: Column(MiniPlayerBar, NavigationBar)` with no width branch. |
| R-03 | S1 | Reader has no reading measure: ayah cards are `screen width − 24 dp`, so a tablet renders 1000 dp lines. Mushaf text is the same. | `lib/features/quran/presentation/reader/reader_screen.dart:285-290` (12 dp margin), `:551-557` (16 dp padding). |
| R-04 | S2 | Home service grid is hard-coded to 3 columns, so tiles stretch to ~330 dp on a 1024 tablet and crush to ~90 dp at 320. | `lib/features/home/presentation/home_screen.dart:469` (`const columns = 3`). |
| R-05 | S2 | Player sheet is a non-scroll-controlled `Column` in a sheet capped at 9/16 of the screen: landscape 640×360 gives ~202 dp for ~360 dp of content. | `lib/features/recitation/presentation/playback/player_sheet.dart:63-71`, content `:205-330`. |
| R-06 | S2 | Sleep-timer sheet and reader font sheet have the same fixed-`Column` shape; the font sheet has two sliders. | `player_sheet.dart:352-386`; `reader_screen.dart:684-733`. |
| R-07 | S2 | Modal sheets have no max width, so on a tablet they span the full display instead of the 640 dp M3 measure. | `verse_share_sheet.dart:28`, `player_sheet.dart:63`, `player_sheet.dart:352`, `reader_screen.dart:684`, `tracker_screen.dart:265`. |
| R-08 | S2 | Hard-coded RTL alignments survive the English switch: localized verdicts/labels stay right-aligned in LTR. | `zakat_screen.dart:160,172`; `surah_index_screen.dart:108` (localized subtitle); `duas_screen.dart:213-246`; `downloads_screen.dart:245,251`; `reciters_screen.dart:172,179`; `reciter_surahs_screen.dart:151,164`. |
| R-09 | S2 | Search field hard-codes `TextAlign.right`, so English search types against the wrong edge. | `lib/core/widgets/search_field.dart:27`. |
| R-10 | S2 | Zakat rows hard-code `TextDirection.rtl`; the whole panel is mirrored in English. | `zakat_screen.dart:199`. |
| R-11 | S3 | Licenses rows hard-code a trailing `chevron_right`; wrong affordance in RTL. | `licenses_screen.dart:127`. |
| R-12 | S3 | Duas chip strip pads with `EdgeInsets.only(left:)`; wrong side when direction flips. | `duas_screen.dart:94`. |
| R-13 | S2 | Onboarding step card puts the action label as an unconstrained `Row` child; at 320 dp / 2.0 it competes with the title column. | `onboarding_screen.dart:177-184`. |
| R-14 | S2 | Qibla dial is capped at 320 dp even inside a 720 dp column; it stays phone-sized on tablets. | `qibla_screen.dart:508`. |
| R-15 | S2 | Hijri month grid is 7 fixed columns with `childAspectRatio: 0.82` and no width cap: cells become ~140×170 on a tablet. | `hijri_screen.dart:180-187`. |
| R-16 | S2 | Landscape is unproven: exactly one landscape test exists (tasbih). No tablet test exists at all. | `test/tasbih_landscape_test.dart:37`; `rg landscape test` → 1 hit. |
| R-17 | S2 | Text-scale probes cover 14 screens/widgets; 12 production screens have none (onboarding, library, bookmarks, folder bookmarks, prayer month, quran search, reciters, reciter surahs, adhan picker, licenses, settings screen, hijri screen). | `rg textScale test` file list vs. `lib/features/**/*_screen.dart`. |
| R-18 | S3 | Toast width is already capped (`_maxWidth`) — **pass**, recorded so it is not "fixed" twice. | `app_toast.dart:76-79`. |
| R-19 | S3 | Edge-to-edge bottom inset helper and its tests are **pass**. | `core/utils/insets.dart:14-23`; `test/insets_test.dart`, `test/edge_to_edge_screens_test.dart`. |
| R-20 | S3 | `AppShell` test surface is 800×600 and pins `NavigationBar`; a rail must therefore start at the expanded class (840 dp), not medium (600 dp), or the frozen behaviour pin changes. | `test/app_shell_test.dart:76-87`. |

## 3. Fix plan — waves

Each wave is a separate commit (no push), gated by
`dart format --set-exit-if-changed lib test tools` = 0,
`flutter analyze` = 0, full `flutter test`.

### R1 — Foundation (tokens + frame)
Files: `lib/core/layout/app_breakpoints.dart` (new),
`lib/core/widgets/app_content_frame.dart` (new),
`lib/core/widgets/app_sheet.dart` (new).
- Breakpoints: medium 600, expanded 840.
- Measures: reading 760, content 720, form 640, grid 1000, sheet 640.
- `AppContentFrame`: caps and centres a body above its measure; no-op below.
- `showAppSheet`: one entry point that sets max width, drag handle, safe area
  and (optionally) scroll control for every modal sheet.

### R2 — Adaptive shell
`app_shell.dart`: at ≥ 840 dp render `Row(NavigationRail, content column)`,
rail on the direction's start edge, mini player at the bottom of the content
column. Below 840 the existing bottom bar is byte-identical.
New test: rail at 1024×768, bottom bar at 800×600 (existing test unchanged).

### R3 — Apply the measure to every screen
Wrap each screen body in `AppContentFrame` with the class from §4. Reading
surfaces use 760; forms 640; grids 1000; everything else 720. No visual change
below 720 dp, so phone tests stay green.

### R4 — Reading surfaces
Reader verses and mushaf pages get the 760 dp measure centred. Qibla dial
grows to `min(available, 420)`. Hijri grid capped at 720. Home grid switches
to 2 columns below 340 dp (LayoutBuilder, not MediaQuery, because it sits
inside the frame).

### R5 — Sheets & dialogs
Route all five sheet call sites through `showAppSheet`; make the player,
sleep-timer and font sheets scroll-controlled and scrollable; verify at
640×360 / textScale 2.0. Dialog widths stay Material-managed.

### R6 — Direction correctness
`TextAlign.start` for localized copy, keep right+RTL only for Arabic-only
content; remove hard-coded `TextDirection.rtl` from zakat lines; direction-aware
chevron in licenses; `EdgeInsetsDirectional` for the duas chip strip; onboarding
action becomes a `Wrap`/secondary row.

### R7 — Small-width + text-scale hardening
Add a responsive matrix probe (`test/responsive_probe_test.dart`) that pumps
the shell, home, reader, player sheet, onboarding, qibla, tasbih, settings,
hijri and zakat at 320/360/600/840/1024 × 1.0/2.0 and asserts
`takeException() == null`. Fix whatever it finds.

### R8 — Device proof
Boot `A16_API36`, install the debug APK, and capture:
- phone portrait (411 dp), text scale 1.0 and 2.0;
- phone landscape (411×~190 dp after bars);
- tablet window (`wm size 2560x1600` at density 320 → 800×500 dp) and
  `wm size 2560x1600` density 240 → 1024 dp.
Screenshot home, reader, player sheet, settings and qibla. Any overflow banner
in a screenshot fails the wave.

## 4. Per-screen measure map

| Screen | Class | Cap |
|---|---|---|
| home | content | 720 |
| quran index · juz index | content | 720 |
| prayer times | form | 640 |
| azkar | content | 720 |
| duas | content | 720 |
| asma | grid | 1000 |
| hijri | content | 720 |
| settings | content | 720 |
| library | content | 720 |
| hadith | reading | 760 |
| translation search · quran search | content | 720 |
| reader (verses + mushaf) | reading | 760 |
| qibla | form | 560 (dial ≤ 420) |
| tasbih | form | 560 |
| bookmarks · folder bookmarks | content | 720 |
| prayer month | content | 720 |
| prayer config · city picker | form | 640 |
| ramadan · qada | form | 640 |
| tracker | form | 640 |
| zakat | form | 640 |
| reciters · packs · downloads · surahs | content | 720 |
| onboarding | form | 560 |
| licenses · principles | content | 720 |
| adhan picker | form | 640 |

## 5. Out of scope (explicit)

- iOS v1 (rejected for this program).
- Desktop/web chrome, hover states, keyboard shortcuts.
- Two-pane master/detail (surah list + reader side by side). It is a feature,
  not a responsiveness fix; recorded as a follow-up.
- `web/**` layout (separate campaign).
- RTL mirroring of illustrations (none shipped).

## 6. Acceptance checklist

- [x] `rg "const columns = 3"` no longer exists without a width branch.
- [x] `NavigationRail` renders at ≥ 840 dp; `NavigationBar` below it.
- [x] Every screen body above has an `AppContentFrame` (33/33 screens).
- [x] Reader line length ≤ 760 dp at 1280 dp width (760 at 1024 tested).
- [x] No `TextAlign.right` on a localized string (Arabic-only content allowed).
- [x] `rg "showModalBottomSheet"` finds only `core/widgets/app_sheet.dart`.
- [x] Responsive probes: 320/1024 home, 320 onboarding, 640×360 player sheet,
      1024 reader/settings/shell, rail at 2.0.
- [x] Full suite green **1412/1412**, format 0, analyze 0.
- [x] Emulator screenshots for portrait, portrait 2.0, 320 dp / 2.0,
      tablet 1.0/2.0 and phone landscape.

## 7. Delivered as built (2026-11-06)

- `lib/core/layout/app_breakpoints.dart` — medium 600, expanded 840, measures
  reading 760 / content 720 / form 640 / grid 1000 / sheet 640.
- `lib/core/widgets/app_content_frame.dart` — four const constructors
  (`AppContentFrame`, `.reading`, `.form`, `.grid`); below the measure it
  returns the child untouched, so phone geometry is byte-identical.
- `lib/core/widgets/app_sheet.dart` — the only `showModalBottomSheet` call
  site; caps sheets at 640 dp.
- `AppShell` — rail at ≥ 840 dp, rail on the direction's start edge, mini
  player in the `bottomNavigationBar` slot in both modes.
- Home grid — `LayoutBuilder`, 2 columns below 340 dp, 3 above.
- Reader — `AppContentFrame.reading` on both the verse list and the mushaf
  pager; error and loading states included.
- Qibla — dial 420 dp only in the expanded class, 320 below it (keeps the
  hints above the fold on phones and the quality probe intact).
- Sheets — player, sleep timer, reader font, tracker setup, ayah sheet and
  verse share all route through `showAppSheet`; the short ones scroll.
- Direction — `SearchField` and localized summary rows use `start`; zakat
  rows drop the forced RTL; juz and licenses chevrons follow `Directionality`;
  the duas chip strip uses `EdgeInsetsDirectional`; onboarding's action label
  is `Flexible` so it wraps at 320 dp / 2.0.
- Insets — the verse-share sheet and the sleep-timer sheet add
  `appBottomInset`, so their last action clears the gesture bar at 320 dp / 2.0
  (found on the emulator, pinned by a 320×640 + 48 dp inset test).
- Tests added: `responsive_foundation_test.dart`, `app_shell_adaptive_test.dart`,
  plus home 320/1024, reader 1024, player 640×360, onboarding 320, settings
  1024, zakat LTR and search-field direction cases.

## 8. Device evidence (temp, not committed)

`C:\Users\ASUS\AppData\Local\Temp\opencode\responsive_shots\`:
`home_phone.png` (411 dp), `home_phone_2x.png`, `home_tablet.png`
(1024×640 dp, rail), `surah_tablet.png`, `reader_tablet.png`,
`home_tablet_2x.png`, `home_landscape.png` (914×411 dp, rail) and
`home_320_2x.png` (320 dp, 2 columns).
