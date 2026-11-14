# Prayer Skin — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the app chrome follow the prayer period (6 palettes × 2 brightness) behind an
opt-in setting, while the shipped theme, the reader, the mushaf, the share card and the
splash stay exactly as they are.

**Architecture:** An immutable `PrayerPalette` (12 constants, derived containers as getters)
feeds a second `_theme(brightness, palette)` path. `palette == null` is the shipped theme.
A settings flag (`fixed` default) and a `PrayerPeriodController` decide when `forPrayer` is
used; `AnimatedTheme` fades the swap.

**Spec:** this plan · `docs/design/prayer-skin.md` (written in W3) · the integration proposal
(`app_theme_prayer_integration.md`) · the measured palette tables.

## 0) Rollback — the first item, not the last

- The setting defaults to **`fixed`**; `AppTheme.light` / `AppTheme.dark` keep calling
  `_theme(brightness)` (`palette == null`), which is the shipped look.
- Revert path A (no build): force `fixed` in the controller — one line.
- Revert path B: `git revert <W2 wiring commit>` restores the fixed behavior; the palette
  file and the theme path stay inert.
- No DB migration: the flag lives in the existing settings table and is **outside the
  backup whitelist** (a per-device display choice, like the theme mode).
- No data loss, no schema change, no reader/mushaf/share-card change at any point.

## 1) Locked decisions

| Decision | Value |
|---|---|
| Periods | 6 (fajr, sunrise, dhuhr, asr, maghrib, isha) × light/dark |
| Primary | varies per period |
| Gold | constant signature: `gold` graphics, `goldText` text |
| Default | `fixed`; `follow` is opt-in |
| Reader / mushaf / share card / splash | untouched |
| Transition | `AnimatedTheme`, 400 ms, easeInOut |
| Semantics | always icon + label |
| `onSecondary` (light) | fixed to `cardBackground` in its **own** commit after the snapshot |

## 2) Measured floor

- Text: ink/page **11.7–15.3** · ink/surface **12.9–14.8** · muted **4.9–6.8** ·
  onPrimary **5.2–9.6** · onTint ≥ 9 · goldText **5.6–8.0**.
- Graphics: gold/surface **3.89–8.0** · onGold light **4.02** (large text only) ·
  onGold dark **8.6**.
- Containers: goldText/secondaryContainer **4.78–6.25** (no small text) ·
  onErrorContainer/errorContainer **7.12–7.33** light, **5.78–6.22** dark.
- App bar: ink on the tinted bar **10.83–14.02**.
- These numbers are re-computed in the test, not trusted from this table.

## 3) Tasks

### W0 — Baseline and the `onSecondary` fix

**Task 0.1 — capture the shipped theme (pre-change commit)**

**Files:** create `test/support/theme_snapshot.dart`, `test/theme_snapshot_test.dart`

- [ ] Write a temporary printer test that dumps the roles below for `AppTheme.light` and
      `AppTheme.dark`; run it **before any change**; paste the output into the fixture.
- [ ] Roles: `primary, onPrimary, secondary, onSecondary, surface, onSurface,
      onSurfaceVariant, primaryContainer, onPrimaryContainer, secondaryContainer,
      onSecondaryContainer, surfaceContainerHighest, outline, error, errorContainer`,
      plus the AppBar background/foreground.
- [ ] Write `theme_snapshot_test` asserting each role equals the fixture; it must be green
      on the unchanged code.
- [ ] Delete the printer. Commit: `test(theme): pin the shipped theme roles`.

**Task 0.2 — the `onSecondary` light fix, alone**

**Files:** `lib/core/theme/app_theme.dart`, `test/support/theme_snapshot.dart`

- [ ] Change the light `onSecondary` from `AppColors.ink` (3.47 on gold) to
      `AppColors.cardBackground` (5.0).
- [ ] Update the fixture's `onSecondary` entry **only**, with a comment:
      `// intended delta: 3.47 -> 5.0, AA for text on a gold fill`.
- [ ] Gates. Commit: `fix(theme): white on the light gold, not ink`.

### W1 — Palette and theme integration

**Task 1.1 — the palette file + the contrast test**

**Files:** create `lib/core/theme/prayer_palette.dart`,
`test/prayer_palette_contrast_test.dart`

- [ ] Add `PrayerPalette` with `brightness` and the 17 tokens + getters:
      `secondaryContainer`, `onSecondaryContainer`, `errorContainer`,
      `onErrorContainer` (`brightness == light` → `alphaBlend(black 22%, error)` — computed
      in the getter from the `error` token, **never a copied hex**, so editing `error`
      moves the container and the label together), `appBar`
      (`alphaBlend(primary 6%, page)`).
- [x] Add the 12 constants from the reviewed table.
- [x] Write the contrast test with `Color.computeLuminance()` covering every pair in §2.
- [x] Gates. Commit: `feat(theme): the twelve prayer palettes + their contrast gate`.

**Task 1.2 — the second theme path**

**Files:** `lib/core/theme/app_theme.dart`, create `test/theme_equivalence_test.dart`,
`test/theme_seed_leak_test.dart`

- [x] Add `_theme(brightness, [palette])`, `forPrayer`, the two caches and
      `clearPrayerCache`.
- [x] Null path: no palette, no `surfaceContainer*`/`inverse*` overrides, `onSecondary`
      unchanged (the 0.2 fix already landed).
- [x] Palette path: every role in the integration map, including `surfaceTint: primary`,
      `errorContainer`, `onErrorContainer`, `inverseSurface`, the surface family.
- [x] Equivalence test: `_theme(brightness, null)` equals the 0.1 fixture.
- [x] Seed-leak test: for each palette, each read role equals its token **and**
      `surfaceTint == primary`.
- [x] Gates. Commit: `feat(theme): a palette path that leaves the shipped theme alone`.

### W2 — Behavior

**Task 2.1 — the setting**

**Files:** create `lib/core/domain/prayer_skin.dart`, the source + settings impl,
`test/prayer_skin_source_test.dart`

- [x] `PrayerSkinMode { fixed, follow }` (persisted codes), default `fixed`.
- [x] Source + settings-backed impl; a failed read keeps `fixed`.
- [x] Confirm the key is **not** in the backup whitelist (the pin test stays green).
- [x] Gates. Commit: `feat(settings): an opt-in prayer skin flag, fixed by default`.

**Task 2.2 — the period controller**

**Files:** create `lib/core/domain/prayer_period.dart`,
`lib/core/presentation/prayer_period_controller.dart` (or the app layer),
`test/prayer_period_test.dart`

- [x] `PrayerPeriod` window function: six explicit markers, absolute `DateTime`s, the isha
      window using the **next day's fajr**, no-sunrise → fajr extends to dhuhr, and the
      last-known-isha hold just after midnight.
- [x] Controller: a timer to the next boundary; after each firing recompute the next
      boundary `> now`; recompute on `resumed`, on `timeZoneOffset` change and on plan
      change.
- [x] Tests: normal day, isha→fajr midnight crossing, DST jump, timezone change,
      high-latitude rule, no-sunrise, a **plan/city change mid-transition** (two rapid
      changes must settle on the last plan), and a **resume after hours** (the device slept
      across several boundaries — jump straight to the correct period, never walk each).
- [x] Gates. Commit: `feat(theme): derive the prayer period from the plan, safely`.

**Task 2.3 — wiring + the toggle**

**Files:** `lib/app/app.dart`, `lib/features/settings/presentation/...`, `lib/l10n/*.arb`
(+ generated), `test/prayer_skin_widget_test.dart`

- [x] `app.dart`: pick `forPrayer(period, brightness)` only when the flag is `follow` and
      the brightness is resolved; otherwise the shipped getters.
- [x] `builder: (context, child) => AnimatedTheme(data: Theme.of(context),
      duration: 400 ms, curve: easeInOut, child: child!)`.
- [x] Settings toggle "المظهر: ثابت / يتبع الصلاة" with additive AR/EN keys.
- [x] Tests: `fixed` after `follow` returns the exact shipped theme; a period change swaps
      the theme; the reader route keeps the neutral palette.
- [x] Gates. Commit: `feat(settings): let the chrome follow the prayer`.

### W3 — Verification and close-out

**Task 3.1 — device leg**

- [ ] `flutter run --profile` on the Infinix (state the panel's refresh rate; the budget
      is `1000/refresh` ms — 16 ms at 60 Hz).
- [ ] Timeline: no frame over the budget during the 400 ms transition **and in the 1 s
      after it settles**, measured on a **long-list screen** (the reader index or azkar),
      not only the home.
- [x] **Sheet separation (closed in W2.4):** `surfaceContainerLow` — the role a modal
      sheet actually reads — equals `surface`, i.e. the exact fill of the card it
      covers. It now carries `alphaBlend(tile 40%, surface)` (and so does
      `surfaceContainer`); `surfaceContainerHigh` (dialogs) stays `tile`. Pinned by the
      palette contrast test (ratio > 1.03) and a widget test that opens a real sheet in
      a light and a dark period. The device screenshot remains the visual gate.
- [ ] Toggle copy check (AR + EN): "ثابت" must read as the current theme; "يتبع الصلاة"
      must say that **only the colours** change.
- [ ] Screenshots: home over the six periods; reader/mushaf/share card unchanged.
- [ ] Record the results in the ledger entry.

**Task 3.2 — docs, ledger, CI**

- [ ] `docs/design/prayer-skin.md`: the palettes, the rules, the rollback. Include the
      reader rule (the wrapper + the toast following its caller's theme, so a reader
      toast is neutral and a chrome toast takes the palette).
- [ ] Ledger close-out (append-only), full gates at the tip, CI on the PR.
- [ ] **No push without owner GO.**

## 4) Acceptance

| Check | Target |
|---|---|
| Null path | equals the 0.1 fixture role by role |
| 12 palettes | contrast test green (every pair in §2) |
| Seed leak | every read role equals its token, `surfaceTint` included |
| Boundary | 6 cases green, including no-sunrise and the midnight crossing |
| Device | no frame over the budget during the 400 ms **and no jank in the 1 s after it** (profile build, long list screen) |
| Reader / share card | byte-identical screenshots |
| Rollback | `fixed` reproduces the fixture theme **after W0.2** (the onSecondary 3.47 → 5.0 fix is the one intended delta, recorded in the fixture) |

## 5) Risks

| Risk | Mitigation |
|---|---|
| A role the widgets read slips back to the seed | the seed-leak test |
| `surfaceContainer == surface` makes sheets blend into cards | `surfaceContainerLow` carries a 40% tile blend; contrast test (ratio > 1.03) + a real-sheet widget test; device screenshot |
| gold text on a gold container (4.78 margin) | never for small text; the rule is in `docs/design/prayer-skin.md` |
| The 400 ms lerp on a low-end device | profile timeline, budget stated per refresh rate |
| Period edge cases (midnight, no sunrise, DST) | the six boundary tests |
| The feature feels heavy (the WeMuslim complaint) | opt-in, default fixed, tint-layer only |
