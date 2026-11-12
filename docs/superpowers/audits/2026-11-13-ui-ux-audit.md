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

### 2. Home breaks down at textScale 2.0

- **Evidence:** `scale2-home`. The grid tiles keep their square aspect, so the labels wrap to
  two lines and clip; the second row is cut mid-card and the bottom navigation is pushed off
  the visible column.
- **Not a crash** — no overflow stripes — but a reader who raises the system font size to 2.0
  sees a home screen that cannot be scanned.
- **Fix:** let the tile grow with the text (intrinsic height or a `mainAxisExtent` derived from
  the text scale) and clamp the label to two lines with an ellipsis only after that.

---

## P2 — Polish

### 3. The prayer countdown's digits collide

- **Evidence:** `light/01-home`, the `_LiveCountdown` value. The Arabic-Indic `٢`/`٣` pairs
  visually merge.
- **Verified as a font property, not a rendering bug:** the same string renders identically in
  Chrome with the app's own `Cairo-Bold.ttf`, so Flutter is faithful. It is a legibility risk
  at store-screenshot size.
- **Fix options:** a small `letterSpacing` **on the numerals only** (2–3 px) or a numeral-first
  font for this one widget. The first is a one-line change; the second is a design decision.

### 4. Settings inverts its own hierarchy on the time rows

- **Evidence:** `light/16-settings`, `scale2-settings`. Rows like *وقت التذكير* / *وقت تذكير
  الورد* render the label at title size and the value (٠٦:٣٠ / ٢٠:٠٠) at caption size in a
  muted tone — the value a user opens the screen to change is the least prominent element.
- **Fix:** same size step as the other rows (label + trailing value at body size), or make the
  value a tappable chip.

### 5. Azkar and Duas tab strips are cramped

- **Evidence:** `light/11-duas`, `light/05-azkar`. Three to four long Arabic labels in a
  segmented strip that already fills the width at scale 1.0.
- **Not measured at 2.0** — this is the screen most likely to break there, which is why UI-2
  should probe it first.
- **Fix:** scrollable tabs, or shorten the labels to one word each.

---

## P3 — Preference

### 6. Home's "المزيد" section begins mid-row

- **Evidence:** `light/01-home`. The last grid row of «العبادة اليومية» is clipped by the
  section boundary, which reads as an accident rather than a scroll affordance.
- **Fix:** give the section a fixed row count, or fade the cut row.

---

## Verdict

The design argument is clear: a calm, cream-and-green reading app where gold means "the sacred
text". The single change that would improve the product most is **#1** — getting the reader's
buttons out of the way — and it is exactly the change that needs your ruling because a frozen
test pins the current interaction.

---

## Proposed waves

| Wave | Scope | Size | Blocker |
|---|---|---|---|
| **UI-1** | Reader: reveal actions on tap; unfreeze `reader_ayah_copy_test` | M | Owner ruling on the frozen test |
| **UI-2** | textScale 2.0: home tiles grow, then re-probe every screen at 2.0 | M | — |
| **UI-3** | Settings hierarchy + Azkar/Duas tab strips | S | — |
| **UI-4** | Countdown numerals + section-cut polish | S | Font decision |
| **UI-5** | Dark-mode contrast sweep with measured pairs on every surface | M | — |
