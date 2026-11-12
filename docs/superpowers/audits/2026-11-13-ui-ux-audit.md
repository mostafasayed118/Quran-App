# UI/UX Audit — Quran Yahdi — 2026-11-13

**Mode:** read-only. Nothing edited or committed by this pass.
**HEAD:** `40bd4201` (`main`) · **Toolchain:** Flutter 3.47.5.
**Capture set:** Android 16 / API 36 emulator, 1080×2160 @ 420 dpi, release build from `388b50d`.
16 screens captured in **light** and **dark**, plus a **textScale 2.0** probe on home + settings.
Every finding below cites the capture it came from and, where opened, the source line.

---

## What is working

The app has a real identity, not a Material default: cream/green surfaces, gold as the single
accent, Cairo throughout, sectioned home grid, and a consistent card language across 16 screens.
Dark mode is a genuine remap, not an inversion — surfaces go near-black with a green tint and
the gold survives. Nothing on this list is "replace the design system"; the findings are
**density, scale and one blocked interaction**.

---

## P0 — Blocking

None observed in the capture set.

---

## P1 — Seriously undermines quality

### 1. The reader spends ~40% of its height on per-ayah action chrome

- **Evidence:** `light/03-reader`, `dark` reader. Every ayah card carries four always-visible
  icon buttons plus the ayah-number badge. With four ayahs on screen, roughly 250 px of a
  2160 px column is buttons.
- **Source:** `lib/features/quran/presentation/reader/reader_verses.dart:182` renders
  `_AyahActions` unconditionally; the row itself is `:207-248`.
- **Why it matters:** the reader is the product. Reading density is the thing users came for,
  and the chrome competes with the text on every verse.
- **Fix:** reveal the row on tap of the ayah (one selected row at a time) instead of on all of
  them.
- **IMPLEMENTED 2026-11-13 — owner ruling: unfreeze.** The ayah number stays visible (it is
  part of reading); only the four buttons collapse, 180 ms, disabled under reduced motion.
  Five ayahs now fit where four did.
  **Test deltas (Class A, owner-approved):** `reader_ayah_copy_test` (×2), `reader_screen_test`,
  `reader_bookmark_toast_test`, `quran_core_quality_probe_test` and `ayah_sheet_test` gained a
  "tap the verse first" step; `reader_share_affordance_test` now asserts closed-by-default and
  exactly one open row. **No assertion was weakened** — the clipboard payload, the bookmark row,
  the sheet content and the share affordance are all still checked. A new test pins
  closed-by-default and tap-to-close.

### 2. textScale 2.0 — CORRECTED 2026-11-13: no defect found

- **Original claim (from a thumbnail):** "home breaks down at 2.0 — tiles clip, labels wrap unevenly,
  the bottom navigation is pushed off".
- **Measured at full resolution on the device:** the tiles **grow** with the text, the labels wrap
  cleanly, nothing overflows, and the section rhythm survives. The reader shows three ayahs at
  2.0 with full text; settings rows grow without clipping; the duas chip row is a
  `SingleChildScrollView` (`duas_screen.dart:95`) so its edge cut is a scroll, not an overflow.
- **Verdict:** the original finding was wrong and is withdrawn. No code change.

---

## P2 — Polish

### 3. The prayer countdown's digits sit tight — ACCEPTED AS-IS 2026-11-13

- **Evidence:** `light/01-home`, `scale2-home`. Arabic-Indic pairs (`٢٢`, `٣٣`, `٤٠`) read as
  single shapes at 30 px and worse at 2.0.
- **Verified as a font property:** the same string renders identically in Chrome with the app's
  own `Cairo-Bold.ttf`, so Flutter is faithful.
- **Tracking is a dead end — tested, not assumed:** `letterSpacing` 2.5 and 5 change nothing,
  in Chrome or in Flutter, because spacing is not applied inside an Arabic script run.
- **A font swap is a dead end too — tested:** `me_quran`, the only other bundled family,
  renders Arabic-Indic digits as boxed glyphs (screenshot in the session log), unusable for UI
  numerals.
- **The only remaining option** is composing the countdown from one `Text` per digit with
  explicit gaps. That would break `home_dashboard_visual_test:116` (`find.text('٠٠:٠٠:٠٠')`)
  and `:118-123` (exactly one `Text` matching the clock) — a frozen Class A pin — for a
  cosmetic delta on text that is already legible.
- **Verdict: accepted.** Revisit only if the countdown ever carries a decision (e.g. a
  full-screen prayer view), where a purpose-built numeral layout earns its cost.

### 4. Settings hierarchy — WITHDRAWN 2026-11-13

- **Original claim:** the time rows render the value at caption size so the thing users open the
  screen to change is the least prominent element.
- **Measured:** at 1.0 and at 2.0 the trailing value sits a full step below the label in every
  row, and the time rows match the shape of *اللغة / العربية* and *المظهر / حسب النظام*. The
  claim was read from a thumbnail and does not survive the full-resolution capture.
- **No code change.**

### 5. Azkar/Duas tab strips — WITHDRAWN 2026-11-13

- **Original claim:** the strips are cramped and would break at 2.0.
- **Measured at 2.0:** the two main tabs fit; the category chips live in a
  `SingleChildScrollView` (`duas_screen.dart:95`), so the cut at the edge is a scroll, not an
  overflow. No clipping, no stripes.
- **No code change.**

---

## Contrast measurements — measured, not eyeballed

WCAG 2.2, computed from the theme tokens (`lib/core/theme/app_colors.dart`).

| Pair | Ratio | Need | Verdict |
|---|---|---|---|
| LIGHT ink / page | 11.74 | 4.5 | pass |
| LIGHT ink / card | 13.97 | 4.5 | pass |
| LIGHT `goldText` / card | 5.81 | 4.5 | pass |
| LIGHT `onEmeraldTint` / tint | 9.79 | 4.5 | pass |
| LIGHT `primaryBeige` / emerald (filled button) | 5.07 | 4.5 | pass |
| **LIGHT `gold` / card** | **2.12** | **3.0** | **fail** |
| LIGHT `gold` / page | 1.78 | 3.0 | fail |
| LIGHT `gold` / tile | 1.67 | 3.0 | fail |
| DARK onSurface / surface | 12.92 | 4.5 | pass |
| DARK onSurface / background | 14.38 | 4.5 | pass |
| DARK `gold` (the dark `secondary`) / surface | 7.73 | 3.0 | pass |
| DARK mushaf ink / card top | 11.85 | 4.5 | pass |
| DARK mushaf muted / card top | 8.51 | 4.5 | pass |

**The failure is real and systemic:** `secondary` is gold in the light scheme, and all sixteen
uses of `colors.secondary` are *meaningful* — favourite, done, aligned, bookmarked, the qibla
ring and needle. Excluding decoration does not rescue it; the state colour itself is below the
3:1 floor on every cream surface.

**Fix applied (UI-5):** a new `AppColors.goldStrong` (`#B06F18`) becomes the light `secondary`.
Measured: **4.02 on the card, 3.38 on the page, 3.15 on the tiles** — all above 3:1, hue intact.
Dark keeps `gold` (7.73). `goldText` (the light text role) is unchanged.

---

## P3 — Preference

### 6. Home's "المزيد" section begins mid-row

- **Evidence:** `light/01-home`. The last grid row of «العبادة اليومية» is clipped by the
  section boundary, which reads as an accident rather than a scroll affordance.
- **Fix:** give the section a fixed row count, or fade the cut row.

---

## Verdict

The design argument is clear: a calm, cream-and-green reading app where gold means "the sacred
text". The single change that improved the product most was **#1** — getting the reader's
buttons out of the way — and it landed in UI-1 after the owner unfroze the test that pinned the
old interaction.

**Pass result:** one behavioural improvement (the reader), one measurable accessibility fix
(the light gold accent), and three findings withdrawn after full-resolution inspection. The
app was in better shape than the first read suggested; that is worth saying plainly rather than
manufacturing fixes to fill a list.

---

## Proposed waves

| Wave | Scope | Size | Status |
|---|---|---|---|
| **UI-1** | Reader: reveal actions on tap | M | **DONE** (owner ruling on the frozen test) |
| **UI-2** | textScale 2.0 re-probe | S | **DONE — nothing to fix**; finding withdrawn |
| **UI-3** | Settings hierarchy + tab strips | S | **DONE — nothing to fix**; both withdrawn |
| **UI-4** | Countdown numerals | S | **CLOSED — accepted as-is**: tracking and font-swap both tested and dead; per-digit layout costs a frozen test for a cosmetic delta |
| **UI-5** | Dark-mode contrast sweep with measured pairs | M | **DONE** — light `secondary` failed 3:1 on every cream surface; `goldStrong` fixes it. Dark passed everywhere |

**Lesson recorded:** four of the five findings were judged from a contact sheet. Three did not
survive full-resolution inspection. The capture set is the evidence; the thumbnail is not.
