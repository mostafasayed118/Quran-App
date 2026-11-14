# Typography Scale & Responsive Type — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the app's 22 ad-hoc font sizes with one 12-rung ladder plus four named component tokens, keep every UI size at or above 11, make the ayah number scale with the reader's font setting, and pin the result behind a guard and the existing responsive matrix so it cannot drift again.

**Architecture:** `lib/core/theme/app_type.dart` becomes the only place a type number exists — sizes, line heights and tracking — as an `abstract final class AppType`, mirroring the already-shipped `AppSpacing` / `AppRadius` pattern. `AppTheme` turns those numbers into the named `TextStyle`s widgets consume. A repository scan fails any new numeric `fontSize:` outside `lib/core/theme/`. Width does **not** change a type size: the measure adapts (`AppBreakpoints.readingMaxWidth`), the user's text scale is never clamped, and the ladder is read from `MediaQuery.textScalerOf` plus the reader's own `fontScale`.

**Tech Stack:** Flutter 3.47.5 / Dart 3.13.4 · Cairo (400/700 only) · HafsSmart · me_quran · `flutter_test` · no new packages.

**Spec:** §1 of this document (the measured inventory) · `docs/superpowers/plans/2026-11-06-responsive-adaptive.md` §1 ("what 100% means") · `docs/superpowers/audits/2026-11-13-ui-ux-audit.md` · `AGENTS.md` §3.

## Global Constraints

- No new dependency. No l10n value change. Generated files untouched by hand.
- **Pre-flight sign-off:** the owner sees a rendered preview of the 12-rung ladder (real fonts, light + dark) before Task 1 starts. No code is written against an unapproved visual.
- **Task 1 is pixel-identical.** Every later size change is named, measured and recorded; no silent drift.
- **No test pins a `fontSize`** (verified: 0 hits in `test/`), so no Class A pin is edited by this plan. If that changes mid-flight, STOP and report.
- Reader `fontScale` (0.8–2.0) and system `textScaler` (1.0–2.0) are **multipliers, never clamps**. Worst case is 2.0 × 2.0; layouts grow or scroll.
- Type size is **not** width-dependent. No `FittedBox` on paragraphs. Width only changes the measure.
- Gates after every task: `dart format --set-exit-if-changed lib test tools` → **0 changed**; `flutter analyze` (whole tree, not `lib`) → **No issues**; `flutter test` → exact count recorded.
- One branch `wave/type-scale` cut from `main` **before** the first edit. Explicit pathspecs. **NO PUSH** without owner GO.

## Review Focus

The five input classes most likely to break while type grows:

1. A 320 dp phone at `textScaler` 2.0 with a long Arabic label inside a `Row` → `RenderFlex` overflow.
2. The reader badge at `fontScale` 2.0 × `textScaler` 2.0 with the four action buttons open at 320 dp → the actions row cannot fit.
3. The exported share card (fixed 360 dp) once its footer or number grows → clipped PNG, not a visible layout error.
4. An English localized label at the new sizes in a block that still hard-codes RTL alignment → wrong wrap or clipped edge.
5. Countdown / tasbih digits at 2.0 in a 360 dp-tall landscape window → vertical clip, because those screens are not scrollable.

Each line has a test in the task that owns the code (Task 4 for 2, Task 6 for 1/4/5, Task 3 for 3).

---

## §1 Baseline — measured 2026-11-14 (`main` `2b6f2481`)

Scan: 362 files in `lib/` (generated excluded), 76 `TextStyle(` blocks.

| Metric | Value |
|---|---|
| `fontSize:` sites | **79** |
| distinct expressions | 26 |
| distinct numbers | **22** |
| below the 11 floor | **5 sites** (10 ×3, 10.5 ×2) |
| off the target ladder | **25 sites** across 6 values |
| parameterized / scaled | 7 (`fontSize` param ×3, `22 * fontScale` ×2, `hafsAyah.fontSize! * fontScale` ×1, `isQuran ? 18 : 16` ×1) |
| `fontFamily` | 37 uses, **all** via `QuranFonts.*` (clean) |
| `fontWeight` | `bold` 24 vs `w700` 21 (same weight, two spellings) |
| `letterSpacing` | 4 sites, all Latin (splash ×3, share-card footer) |
| `height` inside TextStyles | 18 values; 1.2/1.7/1.8/1.9/2.1 sit outside the theme's 1.15–1.6 ramp |

Distribution (value × occurrences): 16×11, 13×10, 14×8, 12×7, 15×6, 11×4, 10×3, 22×3, 10.5×2, 17×2, 18×2, 24×2, 28×2, 40×2, 19/20/21/26/30/34/44/56×1 each.

**The ayah number specifically:**

| Mode | Number size | Follows `fontScale`? |
|---|---|---|
| Verse cards (`reader_verses.dart:241`) | `16` literal | **no** |
| Mushaf (`reader_mushaf.dart:71` inline in the text span) | inherits `22 × fontScale` | yes |
| Share card (`verse_card.dart:111`) | `16` literal | n/a (fixed export) |

## §2 The target scales — 12 rungs + 4 component tokens

| Rung | px | Role | Replaces |
|---|---|---|---|
| `AppType.micro` | **11** | footnotes, dense labels (M3 `labelSmall`) | 11 |
| `AppType.caption` | **12** | captions, secondary labels | 10.5, 12, 13 (caption) |
| `AppType.body` | **14** | list subtitles, dense UI body | 14 |
| `AppType.bodyLarge` | **16** | paragraphs, card titles, row titles | 15, 16 |
| `AppType.title` | **18** | Quran/UI titles, reading body | 17, 18 |
| `AppType.titleLarge` | **20** | page titles, `meQuranHead` | 19, 20 |
| `AppType.headline` | **22** | `heroTitle`, app-bar titles | 21, 22 |
| `AppType.headlineLarge` | **24** | `hafsAyah`, screen heroes | 24 |
| `AppType.stat` | **28** | ayah number, `headlineMedium` | 28 |
| `AppType.timerLarge` | **40** | countdown main | 40 |
| `AppType.timerHuge` | **44** | countdown focus | 44 |
| `AppType.counter` | **56** | tasbih counter | 56 |

**Component tokens** — same pixels as today, allowed to deviate, each with one owning component:

| Token | px | Component | Why not a rung |
|---|---|---|---|
| `AppType.shareFooter` | **10** | share-card footer | the export is a fixed 360 card; its footer is tuned to it |
| `AppType.splashWordmark` | **26** | boot wordmark | brand |
| `AppType.heroValue` | **30** | home hero number | one component |
| `AppType.countdownDigit` | **34** | next-prayer countdown digit | one component |

Readable aliases (aliases are `const double` re-points, no new numbers): `AppType.quranMushaf = titleLarge` (22), `AppType.quranVerse = headlineLarge` (24), `AppType.ayahNumber = stat` (28).

Eliminated from the ladder: **10, 10.5, 13, 15, 17, 19, 21** (7 values). `10` survives only as `shareFooter`; **11 survives as a rung** because it is Material 3's `labelSmall` and the app's footnotes already use it.

Rationale: the UI half (11/12/14/16/18/20/22/24) is the Material 3 role ladder already mirrored in `_textTheme`, plus the house rule that nothing sits below 11. The display half (28/40/44/56) is what the app already renders for numbers; the three designed one-off display sizes (26/30/34) became component tokens instead of forcing a 2 px redesign.

## §3 Mapping decisions

| Current | Target | Δ | Where | Reason |
|---|---|---|---|---|
| 10 ×3 | **10 token** / **11** | 0 / +1 | `verse_card` footer ×2 → `shareFooter`; `tracker_cards` → `micro` | the footer belongs to the fixed export; the tracker label joins the smallest rung |
| 10.5 ×2 | **11** / **12** | +0.5 / +1.5 | `qibla_dial` → `micro`; `splash` label → `caption` | a half-step is noise |
| 11 ×4 | 11 | 0 | `mutedFootnote`, `labelSmall`, splash, hijri | now a rung (M3 `labelSmall`) — **no pixel change** |
| 12 ×7 | 12 | 0 | tracker, library, hadith, azkar, duas | exact |
| 13 ×10 | 12 / 14 | ±1 | `caption` → 12; `sectionLabel` → 14; duas, verse_card, reciter_surahs, tasbih | 13 is a 1 px step next to 12 and 14 — no hierarchy, only noise |
| 14 ×8 | 14 | 0 | — | exact |
| 15 ×6 | 16 | +1 | `bodyText`, hijri ×2, library_sheet, hadith, prayer_times | body floor |
| 16 ×11 | 16 | 0 | — | exact |
| 17 ×2 | 18 | +1 | `azkar_recite`, `duas` | reading surfaces get the larger step |
| 18 ×2 | 18 | 0 | asma, `meQuranTitle` | exact |
| 19 ×1 | 20 | +1 | `azkar_browse` category title | titles are one rung above body |
| 20 ×1 | 20 | 0 | `meQuranHead` | exact |
| 21 ×1 | 22 | +1 | `heroTitle` | one rung |
| 22 ×3 | 22 | 0 | titleLarge, asma, reader_actions | exact |
| 24 ×2 | 24 | 0 | `hafsAyah`, `headlineSmall` | exact |
| 26 ×1 | **26 token** | 0 | splash wordmark → `splashWordmark` | brand value kept |
| 28 ×2 | 28 | 0 | `headlineMedium`, zakat | exact |
| 30 ×1 | **30 token** | 0 | `heroValue` → `heroValue` | component value kept |
| 34 ×1 | **34 token** | 0 | countdown digit → `countdownDigit` | component value kept |
| 40 ×2 | 40 | 0 | asma, countdown | exact |
| 44 ×1 | 44 | 0 | countdown focus | exact |
| 56 ×1 | 56 | 0 | tasbih counter | exact |
| `bold` ×24 | `w700` | 0 | everywhere | same numeric weight, two spellings |
| `letterSpacing` ×4 | keep | 0 | splash, share-card footer | Latin only; **never** on Arabic |

## §4 Typography policy (the rules the guard enforces)

1. **Size** comes from `AppType` only. A widget may compose `AppTheme.<style>.copyWith(...)` but may not type a number.
2. **Floor:** no UI size below **11**. 11 is reserved for captions/footnotes (Material 3 `labelSmall`); 12 is the secondary-label rung. Nothing else may drop below 12.
3. **Line height:** UI body ≥ 1.5; caption (≤12) ≥ 1.4; Arabic reading (azkar/duas/hadith) 1.7–2.1; Quran 2.0 (verse) and the user's `lineHeight` (mushaf); display 1.15–1.3.
4. **Weights:** Cairo ships 400/700 only — `w400` and `w700` are the only allowed values (`bold` is `w700` and is normalised to it).
5. **Tracking:** Latin only. A style that sets `QuranFonts.quran` or `QuranFonts.meQuran` never sets `letterSpacing`.
6. **Families:** `QuranFonts.*` only; no string literals.
7. **Scaling:** `fontScale` and `textScaler` multiply; nothing clamps. The verse badge is `AppType.stat * fontScale`; the mushaf number keeps inheriting the reader line so it stays part of the continuous text.

---

## Task 1: `AppType` + the pixel-identical migration

**Files:**
- Create: `lib/core/theme/app_type.dart`, `test/typography_tokens_test.dart`, `test/typography_guard_test.dart`
- Modify: `lib/core/theme/app_theme.dart`, plus the 20 widget files listed in Step 5

**Interfaces:**
- Produces: `AppType.micro|caption|body|bodyLarge|title|titleLarge|headline|headlineLarge|stat|timerLarge|timerHuge|counter` (`double`), the component tokens `AppType.shareFooter|splashWordmark|heroValue|countdownDigit`, the aliases `AppType.quranMushaf|quranVerse|ayahNumber`, `AppType.bodyHeight|captionHeight|readingHeight|displayHeight|quranHeight` (`double`), `AppType.ladder` (`Set<double>`), `AppType.componentSizes` (`Set<double>`), `AppType.weights` (`Set<FontWeight>`).

- [ ] **Step 1: Write the failing token test**

```dart
// test/typography_tokens_test.dart
expect(AppType.ladder, {11, 12, 14, 16, 18, 20, 22, 24, 28, 40, 44, 56});
expect(AppType.ladder.length, 12);
expect(AppType.componentSizes, {10, 26, 30, 34});
expect(AppTheme.hafsAyah.fontSize, AppType.quranVerse);
expect(AppTheme.rowTitle.fontSize, AppType.bodyLarge);
expect(AppType.ayahNumber, 28);
expect(AppType.micro, 11);
```

- [ ] **Step 2: Run it and watch it fail** — `flutter test test/typography_tokens_test.dart` → `AppType` undefined.

- [ ] **Step 3: Create `app_type.dart`** with the §2 numbers and §4 heights. No `ThemeExtension`: the scale does not vary by brightness, matching `AppSpacing`/`AppRadius`.

- [ ] **Step 4: Point `app_theme.dart` at the tokens**, keeping the numbers it renders today. `hafsAyah` stays 24, `meQuranHead` 20, `meQuranTitle` 18, `rowTitle` 16, `heroValue` 30 stays (component token), `heroTitle` 21→**hold**, `sectionLabel` 13→**hold**, `caption` 13→**hold**, `bodyText` 15→**hold**. Task 1 must not move a pixel.

- [ ] **Step 5: Migrate the exact-ladder sites** (value already equals the token):
  `asma_screen.dart:30,35` · `azkar_browse.dart:161,202` · `library_screen.dart:290` · `hadith_screen.dart:251` · `duas_screen.dart:250` · `library_sheet.dart:247` · `reader_verses.dart:241` · `verse_card.dart:85,111` · `player_sheet.dart:216` · `reciters_screen.dart:169` · `reader_actions.dart:34` · `zakat_screen.dart:18,26` · `licenses_screen.dart:106,128` · `tracker_screen.dart:25` · `asma_screen.dart:25` · `next_prayer_countdown_screen.dart:86,176` · `tasbih_screen.dart:138` · `splash_screen.dart:284` · `hijri_screen.dart:243` (both 11 → `micro`) · `splash_screen.dart:253` (26 → `splashWordmark`) · `app_theme.dart:39` (30 → `heroValue`) · `next_prayer_countdown_screen.dart:165` (34 → `countdownDigit`).
  Computed sites in the same task (no pixel change): `reader_mushaf.dart:91,96` (`22 * fontScale` → `AppType.quranMushaf * fontScale`) · `verse_card.dart:39` (`18.0 : 22.0` → `AppType.title : AppType.titleLarge`) · `duas_screen.dart:176` (`18 : 16` → `AppType.title : AppType.bodyLarge`).

- [ ] **Step 6: Write the guard test with two shrinking lists.**

```dart
// test/typography_guard_test.dart
// 1. A numeric fontSize in a file outside lib/core/theme/ and outside
//    _exemptFiles -> fail.  Match ONLY a bare literal, so computed sizes
//    (22 * fontScale, AppType.x * scale) are not flagged:
//      RegExp(r'fontSize:\s*(\d+(?:\.\d+)?)\s*[,)]')
// 2. A value not in AppType.ladder and not in AppType.componentSizes
//    -> fail unless listed in _offLadderAllowed (the 23 sites left
//    after Task 1's migrations).
// 3. FontWeight.w500|w600|w800|w900 anywhere -> fail.
// 4. letterSpacing inside a TextStyle that also names
//    QuranFonts.quran|QuranFonts.meQuran -> fail.
const _exemptFiles = <String>{ /* files still carrying any literal */ };
const _offLadderAllowed = <String>{ /* file:line for the 23 sites */ };
```

- [ ] **Step 7: Gates + commit** — format 0, analyze 0, suite `1632 + 2`. Commit: `refactor(theme): one type ladder, AppType, and the first zero-pixel migration`.

## Task 2: The 11 px floor

**Files:** `tracker_cards.dart:134` · `qibla_dial.dart:89` · `splash_screen.dart:264` · `test/typography_guard_test.dart`

- [ ] **Step 1: Delete the three remaining sub-11 entries** (10 at `tracker_cards`, 10.5 at `qibla_dial`, 10.5 at `splash_screen` — the two share-card 10s already point at `shareFooter` after Task 1). Run → 3 unresolved sites.
- [ ] **Step 2: Migrate** the tracker label and the qibla degree label to `AppType.micro` (11), and the splash label to `AppType.caption` (12).
- [ ] **Step 3: Verify the share card is untouched** — it stays at 10 through `shareFooter`; the 320 dp × 2.0 export probe must still pass.
- [ ] **Step 4: Gates + commit** — `fix(type): fold the last sub-12 values into micro and caption`.

## Task 3: The five 1 px-adjacent values

**Files:** the §3 rows for 13/15/17/19/21 · `app_theme.dart` · `test/typography_guard_test.dart`

- [ ] **Step 1: Delete the remaining `_offLadderAllowed` entries** (the 13/15/17/19/21 sites); run → 20 failures, one per remaining off-ladder site.
- [ ] **Step 2: Labels + captions** — `sectionLabel` 13→14, `caption` 13→12, and the five widget 13s → 12. Gate: format/analyze/test.
- [ ] **Step 3: Body + reading + titles** — `bodyText` 15→16, hijri/library/hadith/prayer_times 15→16, azkar/duas 17→18, azkar_browse 19→20, `heroTitle` 21→22. Gate.
- [ ] **Step 4: Before/after evidence** — capture Home, Azkar, Duas, Reader, Countdown, Tasbih at 1.0 and 2.0 on the device (or 320 dp probe where a device leg is not run); paste the numbers into the ledger entry. **Pause here for owner review of the set before Task 4.** The splash wordmark, home hero and countdown digit must be **unchanged** — that is the proof the component tokens work.
- [ ] **Step 5: Commit** — `refactor(type): fold the five 1 px-adjacent values into the ladder` (one commit; the tasks inside share the same allowlist edit).

## Task 4: The ayah number

**Files:** `lib/features/quran/presentation/reader/reader_verses.dart` (`_AyahActions`, `_AyahCard`) · `lib/core/theme/app_theme.dart` · `test/ayah_number_size_test.dart`

**Interfaces:**
- `_AyahActions` gains `required double fontScale`.
- `AppTheme.ayahNumber` → `TextStyle(fontFamily: meQuran, fontSize: AppType.stat)`; colour stays at the call site (`AppTheme.goldText(context)`).

- [ ] **Step 1: Write the failing test** — pump the reader (existing harness) at `fontScale` 1.0 and 2.0; find the number `Text`; assert `style.fontSize` is `28` and `56`; assert `takeException()` is null at 320 dp with the actions open.
- [ ] **Step 2: Run it** → today it reports `16` at both scales.
- [ ] **Step 3: Implement** — pass `fontScale` into `_AyahActions`, use `AppType.stat * fontScale`, `maxLines: 1`, and replace the `Row` + `Spacer` with a `Wrap` (`alignment: WrapAlignment.spaceBetween`) so the four buttons drop to a second line when the badge and the buttons cannot share one. The card grows; the badge never shrinks.
- [ ] **Step 4: Re-run** → 28 / 56 and no overflow.
- [ ] **Step 5: Commit** — `feat(reader): the ayah number follows the reader's font size at 28 dp`.

## Task 5: Line heights

**Files:** `app_theme.dart` (TextTheme roles + named styles) · `test/type_line_height_test.dart`

- [ ] **Step 1: Write the failing policy test** — every role with `fontSize <= 12` has `height >= 1.4`; every body role `>= 1.5`; every display role `>= 1.15`; `hafsAyah.height == 2.0`.
- [ ] **Step 2: Run** → `labelSmall` 1.35 and `bodyMedium` 1.45 fail.
- [ ] **Step 3: Set `labelSmall` 1.4 and `bodyMedium` 1.5**; leave the reading surfaces and the display heights alone (they already pass).
- [ ] **Step 4: Gates + commit** — `fix(type): give the smallest and body roles the house line height`.

## Task 6: The responsive/adaptive matrix + the hard guard

**Files:** create `test/support/type_probe.dart`, `test/typography_matrix_test.dart`; extend `asma_quality_probe_test.dart`, `azkar_textscale_probe_test.dart`, `hijri_screen_test.dart`, `home_quality_probe_test.dart`, `prayer_city_textscale_test.dart`, `qibla_quality_probe_test.dart`, `quran_core_quality_probe_test.dart`, `recitation_textscale_test.dart`, `app_shell_adaptive_test.dart`; `test/typography_guard_test.dart` (allowlist empty).

**Interfaces:**
- `pumpTypeProbe(tester, {required Widget child, required double width, double textScale = 1.0, Locale locale = const Locale('ar')})` sets `tester.view.physicalSize`, `devicePixelRatio = 3`, restores in teardown, pumps through `appShell`.

- [ ] **Step 1: Write the matrix test** — the 2026-11-06 axes, type subset: widths **320 / 360 / 411 / 600 / 840 / 1024**, `textScaler` **1.0 / 1.3 / 2.0**, `ar` + `en`; assert no exception, every tappable ≥ 48, and no ellipsized *localized* label outside the designed single-line labels.
- [ ] **Step 2: Run** → record every failure; fix each at the widget that overflows — `Wrap`, `Expanded`, or the ≥ 1.5 **stacked row** from §7 — never by shrinking type.
- [ ] **Step 3: Reader worst case** — 320 dp, `fontScale` 2.0, `textScaler` 2.0, actions open: no exception.
- [ ] **Step 4: Adaptive shell** — 840 / 1024 / 1280 at 2.0: rail present, labels intact.
- [ ] **Step 5: Empty the guard allowlist and commit** — `test(type): pin the ladder and probe it across the responsive matrix`.

## Task 7: Docs, device proof, ledger

**Files:** create `docs/design/typography.md`; append `docs/campaign-ledger.md`.

- [ ] **Step 1: Document the scales** — the 12 rungs, the 4 component tokens, the four rules, the mapping table, and the "how to add a size" procedure (add the token first, never a literal).
- [ ] **Step 2: Device proof** — debug build on the Infinix; screenshots at 1.0 and 2.0 of Home, Reader (verse + mushaf), Azkar, Countdown, Tasbih; confirm `topResumedActivity`.
- [ ] **Step 3: Full gates at the tip** — format 0, analyze 0, suite with the exact count.
- [ ] **Step 4: Ledger + push window** — close-out entry, then wait for owner GO.

---

## §6 Acceptance (definition of done)

| Check | Target |
|---|---|
| Numeric `fontSize:` outside `lib/core/theme/` | **0** |
| Ladder rungs | **12**, plus **4** named component tokens |
| Distinct sizes | **16** (down from 22) |
| UI sizes below 11 | **0**; 11 appears only on caption roles |
| `11` on anything but captions/footnotes | **0** |
| `bold` spellings left | **0** (all `w700`) |
| `letterSpacing` on an Arabic family | **0** |
| Overflow at 320 dp × 2.0 (all probed screens) | **0** |
| Tap targets | ≥ 48 × 48 |
| Ayah number | 28 at `fontScale` 1.0, 56 at 2.0 |
| Suite | baseline 1632 + new tests, exact count recorded |
| Device | 1.0 and 2.0 screenshots of the six screens |

## §7 Risks — mechanism, not just detection

The rule for all three: **never solve an overflow by shrinking type, clamping the scale, or `FittedBox`-ing a paragraph.** Change the shape of the row and let the surface grow (every affected surface scrolls).

| Risk | Mechanism | Proof |
|---|---|---|
| **Reader actions row.** At 320 dp the card's inner width is **272** (320 − 2×12 margin − 2×12 padding). At `fontScale` 2.0 × `textScaler` 2.0 the badge is **112** (28 × 4) and the four `IconButton`s are **192** (4 × 48): 304 > 272, a 32 dp overflow. | Replace `Row(badge, Spacer, actions)` with a **`Wrap`** (`alignment: spaceBetween`, `crossAxisAlignment: center`). At 1.0 everything stays on one line; when it cannot fit, the actions drop to a second line and the card grows inside the reader's scroll list. The badge never shrinks. | Task 4 test: 320 dp, `fontScale` 2.0, `textScaler` 2.0, actions open → `takeException()` null, four buttons present, badge `fontSize` 56. |
| **Tight metadata rows.** 19 rows carry a `trailing:`. Fifteen are **fixed-size** (icon, check, `IconButton`, status chip) and can never overflow — they need no work. Four carry **text** that grows: the reciter count, the reminder time, the azkar item count, and the prayer-config summary. A 320 dp reciter row gives the title ~152 dp at 1.0 and ~98 dp at 2.0. | **Classify first, then stack only the text ones.** Fixed-size trailing stays untouched. For a text trailing: at `textScaler.scale(16) / 16 >= AppType.stackAt` (1.5, one token) render `Row(leading, Expanded(Column(title, subtitle, metadata)))` instead of `ListTile(trailing: …)`. Where the metadata is truly secondary (reciter count), moving it into the subtitle permanently is the stronger option and removes the branch. Title always `Expanded`; `minHeight: 48`, never a fixed height. Extract `AdaptiveListRow` in Task 6 — four rows already share the shape. | Task 6: primary label `RenderParagraph.didExceedMaxLines == false`, no exception, every tappable ≥ 48, at 320/360/411 × 1.0/1.3/2.0. |
| **Fixed 360 share card.** Its PNG is captured at 2×; if the footer or number grows, the card gets taller, and a long host could ellipsize. | The card keeps **fixed export sizes from the ladder**, independent of the reader's `fontScale`; the host already carries `overflow: ellipsis`; the height is intrinsic (no fixed box). | Tasks 2–3: worst-case export test — 400+ char ayah, long surah name, long host → `toImage(pixelRatio: 2)` is **720 px wide**, height recorded, ayah `didExceedMaxLines == false`. |

**Measured outcome (2026-11-14):** the reciter-shaped row probe at 320 dp × 2.0
shows `ListTile` grows and the title is **not** truncated
(`didExceedMaxLines == false`), so no `AdaptiveListRow` was extracted — the
plan's threshold was three rows needing it and zero do. The probe stays as the
regression gate.

**The three helpers every probe uses** (in `test/support/type_probe.dart`, Task 6):
```dart
void expectNoOverflow(WidgetTester tester) =>
    expect(tester.takeException(), isNull);

void expectNotTruncated(WidgetTester tester, Finder text) =>
    expect(tester.renderObject<RenderParagraph>(text).didExceedMaxLines, isFalse);

void expectTapTargets(WidgetTester tester, Finder targets) {
  for (final element in targets.evaluate()) {
    final size = tester.getSize(find.byWidget(element.widget));
    expect(size.shortestSide, greaterThanOrEqualTo(48));
  }
}
```

Task 4 owns the `Wrap` and its test, Task 6 owns the stacked-row rule and the matrix, Tasks 2–3 own the export test.

## §9 Future growth — what still holds, and what does not

| Future change | Holds? | Why / what it costs |
|---|---|---|
| Base rungs move (body 14→15) | ✅ | every consumer reads `AppType`; the layout rules are scale-relative, not pixel-relative |
| A new size is needed | ⚠️ **by design** | the guard refuses a literal; adding a rung means naming its role and probing it — that friction is the feature |
| `textScaler` 3.0 | ⚠️ extend the matrix | the reader still fits (192 dp of buttons < 272 dp); stacked rows still hold. 3.0 is simply outside today's tested envelope, and the plan says 2.0 |
| Tablets / desktop | ✅ | type is width-independent; only the measure moves (`readingMaxWidth`) |
| A new row with text trailing | ⚠️ | the type guard cannot see layout; the rule is in `docs/design/typography.md` + `AdaptiveListRow` |
| Font family swap (Cairo → another Arabic face) | ⚠️ | the px ladder is tuned to Cairo's metrics; the display rungs would need re-measuring, the ladder shape survives |
| Non-linear system scaling (Android 14+) | ⚠️ | `scale(16)/16` is a ratio approximation; monotonic, but the stack threshold is approximate by nature |
| A sub-11 size | ❌ **by design** | needs a documented rung below 11 and its own probe; the floor is not negotiable silently |
| Fluid type by width | ❌ **rejected** | it adds a second axis to every probe and a new overflow class; it would be its own plan |

The honest boundary: **2.0 text scale × 2.0 reader scale at 320 dp is the tested envelope.** Everything above degrades gracefully (scroll, wrap, grow) but is not guaranteed by a test — and the plan does not pretend otherwise.

## §8 References

- Material 3 type scale and Flutter's `TextTheme` role table (57/45/36/32/28/24/22/16/14/16/14/12/14/12/11).
- WCAG 2.2 **1.4.4 Resize Text** (200% without loss of content) and **1.4.12 Text Spacing**.
- Flutter `MediaQuery.textScaler` / `TextScaler` (system scaling can be non-linear; read it, never assume 1.0).
- House typography rules: UI scale 12/13/14/16/20/24, Arabic body 1.6–1.8, no `letterSpacing` on Arabic, small type pairs with ≥ 1.4.
- `docs/superpowers/plans/2026-11-06-responsive-adaptive.md` — the width/scale/locale/inset matrix this plan reuses.
