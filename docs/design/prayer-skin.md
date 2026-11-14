# Prayer skin — palettes, rules, rollback

The chrome can follow the current prayer period: six palettes, each in a light
and a dark variant. It is **opt-in** (`fixed` is the default) and it changes
**colours only** — no layout, no behaviour, no reader.

## Palettes

| Period | Light primary / page | Dark primary / page |
|---|---|---|
| fajr | `#6D4C7D` / `#F3EFF5` | `#C9A7E0` / `#151021` |
| sunrise | `#9E4A58` / `#FBF0EA` | `#D96A7E` / `#1E1513` |
| dhuhr | `#3E6B58` / `#EFE9DA` | `#8CC7A8` / `#101410` |
| asr | `#566F45` / `#EDF1E7` | `#A8C08A` / `#131A13` |
| maghrib | `#9E4B29` / `#F8ECE4` | `#E58A5E` / `#1F1410` |
| isha | `#3F4E8C` / `#EDEEF5` | `#8FA0D8` / `#0E1222` |

`dhuhr` light is deliberately the shipped emerald/paper look: a user who
switches to `follow` at midday sees no change.

Derived roles (getters on `PrayerPalette`, never copied hex):

- `secondaryContainer` = gold 14% over surface; `onSecondaryContainer` = `goldText`.
- `errorContainer` = error 12% over surface; `onErrorContainer` light = black 22%
  over `error` (so retuning `error` moves the container and label together).
- `appBar` = primary 6% over page.
- `sheetSurface` = tile 60% over surface (the device pass measured the 40%
  blend at 1.047:1 on isha dark, under the pre-declared 1.06 bar; 60% clears
  1.06 on all twelve, worst 1.073:1).

## Rules

- **Gold is the signature and graphics-only.** Text and small icons use
  `goldText`. A gold fill never carries normal text (white on `#B06F18` is
  4.02:1).
- **Semantic states always carry an icon and a label.** Under deuteranopia
  several of the semantic/surface pairs collapse.
- **The reader, the mushaf and the sheets they open stay neutral.** The reader
  route is wrapped in `NeutralReadingTheme`, which swaps the palette for the
  shipped `AppTheme.light/dark` at the same brightness. Dialogs and sheets
  opened from the reader capture that theme (`InheritedTheme.capture`).
- **A toast carries the theme that raised it** (`AppToast.show` captures
  `Theme.of(caller)`): a toast raised in the reader is neutral, a toast raised
  by the chrome takes the palette. **The same toast looking different on two
  screens is intended, not a bug** — the screen that raised it owns the colours.
  The post-await `showOn` form keeps the messenger's (chrome) theme, which is
  what it always used.
- **Surface roles:** `surfaceContainerHigh` (dialogs) = tile;
  `surfaceContainer` and `surfaceContainerLow` (sheets, navigation bars) =
  `sheetSurface`. At `surface` a modal sheet was the exact fill of the card it
  covered.
- **One theme animation, 400 ms easeInOut**, owned by
  `MaterialApp.themeAnimationDuration/Curve`. A second `AnimatedTheme` in the
  builder chains two lerps (measured: target at ~900 ms). The appearance switch
  (light/dark) therefore also fades over 400 ms.
- **`fixed` is the identity rollback:** `chromeTheme` returns the shipped
  `ThemeData` instance unchanged, and the period controller is stopped, so no
  boundary timer runs.
- **Device-scoped:** `prayer_skin_mode` is outside the backup whitelist.

## Verification

- `test/prayer_palette_contrast_test.dart` — 48 tests: every measured WCAG pair
  per palette (text 4.5, graphics 3.0) plus the sheet/card separation (> 1.03).
- `test/theme_seed_leak_test.dart` — per palette, each read role equals its
  token, the containers equal their blend, and the chrome surfaces match.
- `test/theme_equivalence_test.dart` — the null path equals the 0.1 fixture;
  building all twelve does not leak into the shipped themes.
- `test/prayer_skin_app_root_test.dart` — the real app root repaints when the
  period lands (follow) and restores the shipped roles (fixed).
- Device (Infinix X6882, layer presented at 90 Hz during interaction):
  a real maghrib→isha swap on the city-picker long list and fixed baseline both
  showed **0 missed vsync** (max 11.63 ms vs an 11.11 ms budget); the
  timer-fired boundary at 18:24 also showed no long interval.

## Known limitations

- The six-period screenshot sweep needs a clock change; the shell cannot set
  the time on this device (`date: Operation not permitted`) and `auto_time` is
  off. On-device screenshots cover the periods reachable at the session's wall
  clock (maghrib, isha).
- The chrome sheet was verified on the **`Test_Android` AVD**, not on the phone
  panel (the phone's wird sheet needs a no-plan state, i.e. wiping its data).
  The AVD and the Infinix can differ in brightness and colour profile.
- The sheet/card separation is **1.0726:1 at worst** — a mathematical floor, not
  a visual judgement. The modal scrim and the elevation shadow do more of the
  separation than the fill. On a dim panel it may still read as close; the rule
  then is to **raise the 1.06 threshold** (and the tile alpha with it) in a
  separate commit, never to tune the alpha by eye.
- The phone-panel pass still owes: the sheet (light + dark) and the four
  periods that were never captured on real hardware (fajr, sunrise, dhuhr, asr).
