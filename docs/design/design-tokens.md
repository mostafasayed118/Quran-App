# Design tokens — the residual-literal pass

> Branch `wave/token-residuals`, cut from `58dd3f95`. Seven commits, no push.
> The wave changes **no painted pixel**: every token copies the literal it
> replaced, and `test/design_token_values_test.dart` pins it.

## Why

The app was already tokenized in the areas the earlier waves touched
(`AppColors`, `AppType`, `AppSpacing`, `AppRadius`, `AppBreakpoints`), but a
census of `lib/**/*.dart` at `58dd3f95` still found **76 residual literals in
66 file/kind/value buckets**:

| kind | hits | examples |
|---|---:|---|
| `hex` | 7 | the boot splash's five brand ARGB values |
| `alpha` | 22 | `withValues(alpha: .18)`, `alpha: dark ? .42 : .55` |
| `lineHeight` | 9 | scripture `1.7 / 1.8 / 1.9 / 2.1`, timer `1.1` |
| `tracking` | 4 | splash `-.2 / 4.2 / .3`, share footer `0.4` |
| `iconSize` | 27 | `13 / 14 / 16 / 18 / 20 / 22 / 40 / 48 / 72 / 84` |
| `radius` | 6 | `10 / 11 / 14 / 28` |
| `stroke` | 7 | `1.4 / 1.5 / 1.6 / 3` |

The census is now **0 hits in 0 buckets**.

## The ratchet

`tools/design_token_scan.dart` walks paren-balanced `TextStyle`, `StrutStyle`,
`.copyWith`, `Icon(`, `BorderSide`/`Border.all`, `withValues(alpha:)` and
`opacity:` blocks (including ternary alpha/opacity expressions).
`tools/design_token_census.dart` prints the map.

`test/design_token_guard_test.dart` compares the tree to
`test/fixtures/design_token_baseline.dart` with exact map equality, so a new
literal and a stale baseline entry both fail. The baseline was recorded before
the first edit and shrank to empty; the guard now fails on any new hit.

`test/design_token_scan_test.dart` proves each detector form, including the
`copyWith` case, fires on a synthetic source and that token references and a
transparent gradient stop pass.

### Call-site proof

The value test proves `token == shipped literal`; it does not prove the call
site received the right token. `tools/design_token_diff_audit.dart [base]` pairs
every removed literal with the token added at the same site, by role (alpha,
opacity, line height, tracking, icon, radius, stroke, hex), resolves the token
from `lib/core/theme/`, and fails on a mismatch or an unpaired change.

At the wave tip: **89 pairs, 0 failed, 0 unresolved**. A negative control that
swapped `metaInk` for `dividerOnTint` at two sites produced two FAIL lines
(`0.7 -> dividerOnTint = 0.12`), so the check is not vacuous. The audit also
found six splash alpha values assigned to locals (`glowAlpha`, `ringAlpha1`,
`ringAlpha2`) that the file census never listed.

The repository has **no golden tests** (`matchesGoldenFile` has zero matches),
so this diff audit plus the value pins are the pixel-equivalence evidence.

### What the guard does not catch

It is a textual ratchet, not an AST proof. Computed literals such as
`height: 1.8 + x`, `size: 18 * scale` or `Color.fromARGB(...)` are not
matched. The `lib/core/theme/` directory is the explicit exception (it is the
token source), and `test/`/`tools/` are out of scope.

The opacity rule is broader than the constructor that exposed the gap: it
reads **any** `opacity:` expression, so `Opacity`, `AnimatedOpacity` and
`FadeTransition` with a numeric literal are covered. What remains outside is
anything the text cannot see: a value held in a local
(`final fade = 0.4; … opacity: fade`), a `ColorFiltered` colour whose alpha is
not a `Color(0x…)` or a `withValues` call, and any new opacity mechanism that
does not spell `opacity:`. Extend the scanner when such a site appears; do not
widen the regex blindly.

## Tokens added

| file | tokens |
|---|---|
| `lib/core/theme/app_colors.dart` | `splashCard`, `splashGlowMint`, `splashGlowGold`, `splashShadowWarm`, `splashShadowCool`; splash alpha roles (footer, corner, glow, rings, accent, card border) |
| `lib/core/theme/app_alphas.dart` | `chipTint .10`, `dividerOnTint .12`, `outlineFaint .18`, `secondaryTile .14`, `errorTint .35`, `accentRule .35`, `accentRuleSoft .25`, `metaInk .70`, `secondaryInk .75`, `iconMuted .60`, `completedFade .80` |
| `lib/core/theme/app_type.dart` | `dhikrHeight 2.1`, `scriptureHeight 1.8`, `scriptureLooseHeight 1.9`, `scriptureTightHeight 1.7`, `timerHeight 1.1`, `splashWordmarkHeight 1.2`, and four tracking roles |
| `lib/core/theme/app_icon_size.dart` | `inline 13`, `dot 14`, `sm 16`, `md 18`, `lg 20`, `xl 22`, `state 40`, `hero 48`, `dial 72`, `gate 84` |
| `lib/core/theme/app_strokes.dart` | `emphasis 1.4`, `selection 1.5`, `ring 1.6`, `accent 3` |
| `lib/core/theme/app_radius.dart` | `panel 14`, `dayCell 10`, `selection 11`, `sheet 28` (documented W2 candidates) |

The alpha split is deliberate: 0.10 and 0.12 stay separate tokens, and 0.70
and 0.75 stay separate, because merging two shipped values is a visual change,
not a rename.

## Domain contract

`lib/core/domain/ayah_key.dart` replaces the private `PackReader` helper and
the inline `~/ 1000` decode in the search cubit. The helpers are total (ayah 0
and surah 0 round-trip) so the pack boundary keeps its behavior.

`kFajrFollowUpMinutes = [5, 10]` now drives the planner loop and the
`fajrFollowUpAlarmId` bound; the test asserts the produced offsets equal the
list, not merely that two reminders exist.

## Left literal on purpose

- `lib/core/theme/prayer_palette.dart` — the palette **is** the token source.
- Adhan reciter names and city names — content, not interface copy.
- `kPlayStoreId`, the notification channel id, the backup format and the
  content/search version keys — platform or storage contracts.
- `AppBreakpoints` — responsive measures already live in their token file.
- Test expectations — a test that pins a value should contain the value.
- Motion durations — 35 sites, mostly named constants in their owner file;
  a global motion scale is structure without a current need. Revisit only if a
  screen needs a shared duration.

## W2 candidates (each needs a decision, not a rename)

1. **Spacing rhythm.** 39 `SizedBox` gaps and 14 `EdgeInsets` use values off
   the 4 dp scale (`2 / 6 / 10 / 14 / 18 / 20 / 22 / 26`). Snapping them is a
   ≤2 dp change in ~30 places; do it screen by screen with screenshots.
2. **Scripture line height.** `1.7` (asma), `1.8` (duas, azkar, hadith),
   `1.9` (ayah sheet), `2.1` (azkar recite). This is a **reading** decision:
   Arabic diacritics change with the line box. Capture before/after on the
   four screens; do not approve it from a table.
3. **Radii.** `panel 14`, `dayCell 10`, `selection 11` are shipped component
   values; fold them into `md 12` / `lg 16` by role. `sheet 28` stays.
4. **Muted ink.** `metaInk 0.70` and `secondaryInk 0.75` play the same
   apparent role on tinted cards. Unify only with screenshots.

## W2 decision criteria (written before the screenshots)

**Scripture line height.** A screen keeps its shipped value if, at 1.0 and 2.0
text scale on a 360 dp surface, any of these is true:

- (a) a diacritic is clipped at the top or bottom of its line box;
- (b) marks from two consecutive lines touch or overlap;
- (c) the paragraph touches the adjacent rule or card edge;
- (d) the baseline gap reads visibly tighter than the shipped screenshot at the
  same width.

The unified rung is accepted only if **none** of the four screens (`asma`,
`duas`, `azkar`, `hadith`) fails (a)–(d). The verdict is written per screen
**before** the "after" shot is opened, so the bar cannot move with the
impression.

**If nothing fails, the default is to keep the shipped values.** Passing
(a)–(d) is permission to change, not a reason. The roles stay
`scriptureTightHeight` (asma), `scriptureHeight` (duas/azkar/hadith),
`scriptureLooseHeight` (ayah sheet) and `dhikrHeight` (the long recitation
prose). Folding all of them onto one `1.8` is accepted only if the worst-case
captures show a **clear reading gain** that the shipped value does not have —
not merely that no screen broke.

**Worst-case capture, not the first screen.** For each of the four screens,
open the **longest text** in that category (longest dua, longest hadith,
longest dhikr, the longest asma explanation), set the app's font/reader size
and the system text scale to the **largest allowed** value (2.0), and capture
at 360 dp width on the phone. The **same entry, scale and width** are used for
the before and after pair; record them with the shots.

## W2 worst-case entries (chosen before the session)

Selected by programmatic maximum text length from the shipped data on
2026-11-15, before any screenshot. The entries are fixed; if one is not
reachable, record why and take the next entry **by the same maximum-length
rule**, chosen before the shot — not by appearance.

| screen | entry | length | note |
|---|---|---|---|
| duas | `d26` — دعاء الهم والحزن (`الهم والكرب`) | 409 chars | longest `text` in `assets/data/duas.json` |
| azkar | `collections[id=evening].items[0]` — «أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ…» | 454 chars | the **recite** surface (`dhikrHeight`), not the collection list |
| asma | `n=76` — الْبَاطِنُ / «العالم بالخفايا الذي لا يبلغه إدراك» | 35 chars | longest `meaningAr`; the grid card's text |
| hadith | `ara-bukhari` #2731 | 14,114 chars | longest `text` in the pinned pack edition (`df57907…`) |

- The hadith pack is `ara-bukhari` (catalog v1.2, edition `df57907…`, 9.4 MB).
  Install it **before** the before shot; it is app data, not a new build.
- Installing the pack is **additive**: it writes one file under the app's
  support directory and one registry row; it does not clear app data, the
  reader/bookmarks, or other packs. Reinstalling the same id replaces only that
  pack's file. Removal after the session: Library → the pack's trash icon →
  confirm (this calls `uninstall(packId)` and removes only this pack). Record
  the pack id and whether it was removed.
- Text scale 2.0 and 360 dp width apply to every entry; the same entry is used
  for before and after.

## Shipped build identity (before shots)

The before shots must come from the installed **release 2006**. The matching
local artifact is `build/app/outputs/flutter-apk/app-release.apk`:

- package `com.mostafasayed.quranyahdi`, versionCode **2006**;
- size 49,660,720 bytes, built 2026-11-14 18:04;
- SHA-256 `28e4cc65e8853e2da1aaa7dd1827faf3055332375b2e68fcae274552873e8ce6`.

The APK does not embed the source SHA. Record the installed version and this
artifact hash at capture; if the source SHA is not recoverable from the
artifact, say so — do not substitute the current `main` SHA as if it were the
build's source.

## Device session order (W2 + deferred periods)

1. On the shipped `fixed` build: capture the W2 **before** shots on the
   physical phone **before any new build**. Record the date, the installed
   version (`2006`), the source SHA if the artifact exposes it (otherwise say
   it is not recoverable — do not substitute the current `main` SHA), the
   chosen entry, the text scale and the width.
2. Build W2 and capture **after** with the same entry, scale, width and theme.
3. Switch to `follow` and capture the four periods two minutes after each
   adhan (card + dialog + bottom sheet).
4. Restore `fixed` after isha and record it in the ledger.

`fixed` is not swapped between sessions, so the before/after pair and the
period pass do not contaminate each other. W2 is not opened as a branch until
this session is scheduled; no half-done W2 branch.

## Capture conditions (same for before and after)

- **Brightness:** disable auto-brightness and set one fixed level; record it
  and restore the previous setting after the session.
- **Orientation:** portrait.
- **Theme:** the same light/dark mode on both sides. Dark and light change how
  diacritics read, so capture **both themes** if time allows; if only one is
  captured, record which one and why.
- **Period:** on `fixed` the prayer period does not change the theme, but
  record it in the package anyway.

## Device note

The wave touched the splash and colour roles but changed no value, so the
deferred phone pass for the four uncaptured prayer periods is unaffected: it
still waits on a natural day on `follow`.
