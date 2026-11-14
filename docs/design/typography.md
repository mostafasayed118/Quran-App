# Typography

The app has **one scale** and **four named exceptions**. Every size is read
from `lib/core/theme/app_type.dart`; no widget types a number, and
`test/typography_guard_test.dart` fails the build if one appears.

## The ladder — 12 rungs

| Token | px | Role |
|---|---|---|
| `AppType.micro` | 11 | footnotes, dense labels (Material 3 `labelSmall`) |
| `AppType.caption` | 12 | captions, secondary labels |
| `AppType.body` | 14 | list subtitles, dense UI body |
| `AppType.bodyLarge` | 16 | paragraphs, card titles, row titles |
| `AppType.title` | 18 | Quran/UI titles, reading body |
| `AppType.titleLarge` | 20 | page titles, `meQuranHead` |
| `AppType.headline` | 22 | `heroTitle`, app-bar titles |
| `AppType.headlineLarge` | 24 | `hafsAyah`, screen heroes |
| `AppType.stat` | 28 | the ayah number, `headlineMedium` |
| `AppType.timerLarge` | 40 | countdown main |
| `AppType.timerHuge` | 44 | countdown focus |
| `AppType.counter` | 56 | tasbih counter |

Quran aliases: `quranMushaf` = 22, `quranVerse` = 24, `ayahNumber` = 28. They
are re-points, not new numbers.

## The component tokens — 4 exceptions

| Token | px | Owner | Why not a rung |
|---|---|---|---|
| `shareFooter` | 10 | share card footer | the export is a fixed 360 dp card |
| `splashWordmark` | 26 | boot wordmark | brand |
| `heroValue` | 30 | home hero number | one component |
| `countdownDigit` | 34 | next-prayer countdown | one component |

## The rules

1. **Size** comes from `AppType`. A widget may compose
   `AppTheme.<style>.copyWith(...)`; it may not type a number.
2. **Floor:** nothing below 11. 11 is captions/footnotes only; 12 is the
   secondary-label rung; nothing else goes under 12.
3. **Line height:** UI body ≥ 1.5; ≤ 12 px roles ≥ 1.4; Arabic reading
   (azkar/duas/hadith) 1.7–2.1; Quran 2.0 (verse) and the reader's own
   `lineHeight` (mushaf); display 1.15–1.35.
4. **Weights:** Cairo ships 400/700 only — `w400` and `w700`, nothing else.
5. **Tracking:** Latin only. A style that names `QuranFonts.quran` or
   `QuranFonts.meQuran` never sets `letterSpacing`.
6. **Families:** `QuranFonts.*` only.

## Scaling

- `textScaler` (the OS setting) and the reader's `fontScale` **multiply**.
  Nothing clamps them; the surfaces scroll or grow.
- Width does **not** change a size. It changes the measure
  (`AppBreakpoints.readingMaxWidth` = 760, `contentMaxWidth` = 720).
- The tested envelope is **2.0 text scale × 2.0 reader scale at 320 dp**. Above
  it the layout degrades gracefully but is not pinned by a test.

## How to add a size

1. Ask whether a component token can point at an existing rung. It usually can.
2. If a new rung is genuinely needed, add it to `AppType` **with its role**,
   add it to `ladder`, and extend `typography_tokens_test`.
3. Run `typography_matrix_test` at 320/360/411 × 1.0/1.3/2.0 and the export
   test if the surface is captured to an image.
4. Update this file.

A guard failure is a request for a decision, not an obstacle to route around.
Never add a literal to silence it.

## Why this shape

Measured before the wave: 79 `fontSize:` sites, 22 distinct sizes, 9 below 12,
32 off the ladder. After: 12 rungs + 4 tokens = 16 sizes, one source, and a
guard that keeps it that way. The mapping and the pixel deltas are in
`docs/superpowers/plans/2026-11-14-typography-scale.md`.

Two measured decisions worth keeping:

- **No `AdaptiveListRow`.** The reciter-shaped row was probed at 320 dp × 2.0:
  `ListTile` grows and the title is not truncated (`didExceedMaxLines` false),
  so no shared row was extracted. The probe stays as the regression gate.
- **The share card is not responsive by design.** It is a fixed 360 dp export;
  its footer keeps 10 px and is verified by an exported-PNG test, not a layout
  probe.
