# UI/UX inspiration study — Muslim Companion → Quran Yahdi

> Session date: 2026-10-30 · Repo: `E:\old_flutter\Quran-App-master` · HEAD at start: `d39c1f7`
> Reference: <https://muslimcompanion.app/> (marketing site + the app screenshots it ships)
> Scope: visual/UX improvement only. No feature removed, no navigation contract changed,
> no dependency added, nothing committed or pushed.

---

## 1. What was actually inspected

The reference is a **marketing website** that publishes real in-app screenshots. I separated the
two, because copying a marketing page into a mobile app is exactly the failure mode this brief
warns about.

### 1.1 Pages / sections browsed

| # | Section | What it contains |
|---|---|---|
| 1 | Header (sticky) | Logo + wordmark + tagline pill, language pill, Blog, two store badges |
| 2 | Hero | Eyebrow label, 52 px headline with an accent-coloured fragment, body copy, store CTAs, 6-phone mockup |
| 3 | Highlights strip | 4 stat cells: Free / 20+ features / 6 languages / Privacy |
| 4 | Support and privacy | Inline email, two outline buttons |
| 5 | Testimonials | 7 quotes, prev/next arrows, 7 dot indicators, tab list |
| 6 | "Inside the app" | Horizontal screenshot carousel, 6 screens, arrow buttons |
| 7 | "What the app includes" | 23 feature cells in a 4×6 grid |
| 8 | "Explore features" | 1 large + 2 small + 3 medium cards with imagery |
| 9 | Insights / blog | 3 article cards + "Browse all articles" |
| 10 | FAQ | 3 accordion rows (opened all three) |
| 11 | QR / "Get the app" | Store buttons + QR code |
| 12 | Footer | 5 links, disclaimer line |

### 1.2 Real product surfaces inspected (not marketing)

Downloaded and viewed at native resolution (682×1024):

- `screen-home.png` — location card, 4 quick actions, prayer panel with toggles
- `screen-ai-hub.png` — grouped "Guidance & Learning" panel, 2-up "Advanced AI" grid, trending chips
- `screen-ai-detail.png` — assistant input + category chips
- `promo-prayer-times.png` — next-prayer countdown card + prayer list
- `promo-quran.png` — reader with ayah-end ornaments + floating transport bar
- `promo-azkar.png` — action chips, search, inspiration card, grouped dhikr rows
- `promo-qibla.png`, `promo-fatwa.png`, `promo-dreams.png`, `promo-image-studio.png`
- `showcase-phones.png` — 6-up hero mockup

Screenshots captured for this study (outside the repo, under
`%LOCALAPPDATA%\Temp\opencode\mc-recon\`):

```
desktop-hero.png  desktop-full.png        desktop-sec00..09.png
tablet-full.png   mobile-hero.png         mobile-full.png
mobile-footer.png desktop-faq-open.png    mobile-faq-open.png
desktop-carousel-scrolled.png             desktop-lang-menu.png
desktop-review-tab.png                    desktop-scrolled-header.png
assets/screen-home.png  assets/screen-ai-hub.png  assets/promo-*.png
before/home-light.png  before/home.png    before/prayer-light.png
before/qibla-light.png before/azkar-light.png      before/reader-light.png
after/*.png  (captured from the Infinix X6882, see §10)
```

They are referenced by path rather than embedded: they are large binaries and are deliberately not
committed. The website pass used Playwright driving the installed Chrome at three viewports, with
`networkidle` plus a full lazy-load scroll before capturing, and `getComputedStyle` for the token
table; the device pass used `adb shell screencap` + `adb pull` (never piping binary through the
shell).

### 1.3 Responsive behaviour measured

Captured at 1440×900, 834×1112, 390×844 (DPR 2). Measured document widths:

| Viewport | Document height | Horizontal overflow |
|---|---|---|
| Desktop 1440 | 5 842 px | none |
| Mobile 390 | 10 228 px | none (`scrollWidth == innerWidth == 390`) |

Mobile behaviour: the header does **not** collapse into a burger menu (there are only two nav
items). It stacks logo → language/Blog pills → store badges, consuming ~330 px before the hero.
The phone mockup is dropped on mobile; the hero becomes pure type. Feature grids collapse from
4 columns to 1. The carousel stays horizontal with 44 px arrow buttons.

Tablet (834) sits between the two: the hero stacks copy over the 6-phone mockup, the stats strip
stays 4-up, and the feature grid goes 3-up.

### 1.4 Interactions exercised

- FAQ: clicked all three questions; all open inline (accordion, no modal).
- Screenshot carousel: two right-arrow presses advanced the row (scroll-snap behaviour).
- Language menu: opened; 6 items with country codes and native names, active row filled emerald.
- Testimonials: switched to Review 3 of 7 (dot indicator widens into a pill for the active item).
- Sticky header while scrolling 3 000 px: header stays, gains a translucent surface.

No forms submitted, no accounts created, no purchases.

---

## 2. Observed visual identity (marketing + in-app)

Measured with `getComputedStyle` on the live page, not guessed.

| Token | Value | Where it appears |
|---|---|---|
| Page background | `#050A12` → `#0A1628` gradient | page, hero |
| Raised surface | `rgba(255,255,255,.05–.06)` + 1 px `rgba(255,255,255,.10–.15)` border | cards, pills |
| Primary text | `#F1F5F9` / `#E5E7EB` | headlines, body |
| Muted text | `#94A3B8` / `#64748B` | captions, meta |
| Accent (brand) | `#10B981` → `#34D399` → `#6EE7B7`, plus teal `#2DD4BF` | CTAs, active states, eyebrow labels |
| Secondary accent | `#8B5CF6` (violet) | AI section gradients only |
| Attention | `#FBBF24` | star ratings |
| Display face | Outfit 600/700 | headings |
| Text face | DM Sans 400/500/600 | body, UI |
| Type ramp | 52/52 · 30/36 · 20/28 · 16/24 · 14/20 · 12/16 | measured |
| Radii | 12 (buttons/inputs) · 16 (cards) · 24 (panels) · 9999 (pills) | measured |
| Spacing | 4 px scale (Tailwind steps: 4/8/12/16/24/32) | measured |
| Elevation | inset 1 px white 4–7 %, plus large soft black shadow, plus emerald glow `rgba(15,163,113,.7) 0 22px 60px -30px` | cards, mockups |
| Decoration | star-field radial gradients, mosque silhouettes, crescent, arch shapes | hero, promo images |

In-app specifics (from the real screenshots):

- **Dark glass** cards on a near-black field, 16–20 px radius, hairline white border at ~10 %.
- **One accent** (emerald) doing the structural work: active tab, primary button, highlighted
  prayer row, "next prayer" ring. Gold appears only for the next-prayer clock badge.
- **Bottom navigation, 5 labelled destinations**, active item wrapped in a filled pill.
- Bottom sheets, chips and inline action rows (`Reflect` / `Explain` / share) attached to a
  content card rather than hidden in menus.

---

## 3. Observed UX patterns

1. **The changing number is the hero.** The prayer screens put the countdown — not the prayer
   name — at 30–40 px inside a ring, with the target time underneath. The one value that moves
   is the one the eye lands on first.
2. **Location + date as context, not as a setting.** A single card states city and Hijri date;
   editing is secondary.
3. **Grouping beats enumeration.** 23 features are grouped into 6 sections with a heading per
   group ("Guidance & Learning", "Advanced AI", "Trending Questions"). A flat list of 23 would
   be unreadable.
4. **Progressive disclosure through rows.** A group card holds 2–3 rows of
   `badge + title + one-line subtitle + chevron`; the subtitles do the explaining so the titles
   can stay short.
5. **Active state is unmistakable.** Bottom-nav active tab = filled pill + coloured icon + label;
   current testimonial = widened pill; highlighted prayer row = tint + badge.
6. **Icon badges create rhythm.** Every icon sits in a tinted circle or rounded square, so a grid
   of repeated items reads as a system instead of a pile of glyphs.
7. **State communication is explicit.** "Compass live" vs "compass static", "next prayer in
   hh:mm:ss", toggles per prayer, download/installed states.
8. **Marketing-only patterns** (deliberately *not* copied): star-field gradients, mosque
   silhouettes, 52 px display headlines, store badges, testimonial carousels, QR block.

---

## 4. Best ideas, and whether they fit Quran Yahdi

| # | Observed | Why it works | Where it applies here | Adaptation (not a copy) | Expected gain |
|---|---|---|---|---|---|
| 1 | Countdown-first next-prayer card with a ring | The most time-sensitive fact becomes the first thing read; the ring encodes progress without a chart | Home hero, prayer times | Warm emerald tint card, `me_quran`/Cairo type, HH:mm:ss Arabic-Indic digits, ring replaced by a single accent bar (no fake progress data) | Users answer "how long until prayer?" in one glance instead of reading a tile |
| 2 | Location + Hijri date card | Removes "where am I praying?" ambiguity | Home (had no location at all when a city *was* selected) | City name travels in the next-prayer record; shown as a quiet footer row with a pin | Context without a second card |
| 3 | Grouped feature sections with a heading | 14 equal tiles carry no hierarchy; groups give the eye three chunks | Home service grid | Three groups — القرآن والاستماع / العبادة اليومية / المزيد — with a start-aligned label and a 3 px accent bar | Faster target finding; the eye stops scanning 14 items |
| 4 | Icon inside a tinted badge | Gives repeated tiles a rhythm and a consistent optical size | Home tiles, prayer rows, section headers | 44 dp circle at 10 % primary; one accent only | A grid that looks designed rather than generated |
| 5 | One panel, hairline-separated rows | Seven separate elevated cards read as seven unrelated facts and overflow the fold | Prayer times list | Single `Card` + `Divider(indent 14)` + one highlighted row with a leading accent bar | All six times visible at once; hierarchy is explicit |
| 6 | "Not a prayer" is visually distinct (sunrise muted, no toggle) | Prevents a category error: sunrise is a marker | Prayer times | Sunrise muted + sun glyph; the misleading radio-button dot removed | Correct mental model, and no fake control |
| 7 | Compass with cardinal marks and a target marker | Without north, a rotating arrow is unreadable | Qibla | Painter draws ش/ق/ج/غ at true bearings + a gold qibla dot on the rim | The dial answers "which way is north?" as well as "which way is the qibla?" |
| 8 | Explicit state copy ("Compass live", "aligned") | The user never has to infer whether the sensor is working | Qibla | "أنت تواجه القبلة" pill when within ±5°, otherwise "turn 12° right/left" | Removes the "is it broken?" doubt; adds a success state |
| 9 | Bottom navigation with a filled active pill | 5 destinations always reachable, 1 tap | Home | **Not implemented** — see §12 (requires a shell route; documented, not risked) | Would be the single largest nav gain |
| 10 | Inline action chips on content cards (Reflect/Explain) | Keeps the action next to the thing it acts on | Reader / azkar | Not implemented this wave (needs content actions, not styling) | Deferred |
| 11 | Star-field / gradient / silhouette art | Sells an app on a landing page | — | **Rejected**: would erase the ivory-and-ink identity and lower text contrast | — |

---

## 5. Quran Yahdi before this wave

Captured on the Infinix X6882 (`13372704AR007777`), 1080×2460, both themes.

**What was already good (kept):**

- A coherent identity: warm ivory page, off-white cards, forest-emerald ink, gold reserved for
  sacred/attention. Light and dark are both real themes, not an inverted afterthought.
- Arabic-first RTL throughout, `me_quran` for surah/city display, HafsSmart for the mushaf,
  Arabic-Indic digits at the call sites.
- Reader is genuinely good: per-ayah cards, ornamented ayah numbers, basmala in gold,
  per-ayah actions, mini player.
- Cubit/freezed state, explicit Loading/Failed/Ready arms, localized copy only.
- Edge-to-edge inset handling exists (`appBottomInset`, `appScrollPadding`).

**What was weak (measured defects):**

| # | Defect | Evidence |
|---|---|---|
| 1 | Home had no location, no date, and no countdown — just a `ListTile` with a clock time | `home_screen.dart` pre-change, `before/home-light.png` |
| 2 | 14 identical tiles, no grouping, no badge, `fontSize: 12` + fixed `childAspectRatio` → label clipped at 2.0 | `before/home-light.png`, `home_quality_probe_test` only asserted "no exception" |
| 3 | Tile ink was painted under a 50 % fill (`InkWell > DecoratedBox`) → the ripple was invisible | pre-change `home_screen.dart:254-262` |
| 4 | The "next prayer" highlight used the seed-generated `primaryContainer`, a saturated mint that read as a different app on the ivory page | `before/prayer-light.png` |
| 5 | Seven separate elevated cards for six times + city | same |
| 6 | `Icons.radio_button_unchecked` on every non-next prayer: TalkBack announced "radio button" in a non-radio list; sunrise looked like a prayer | `prayer_times_screen.dart:156` |
| 7 | Every failure state was `Center(Text)` with no icon and no retry — a dead end | `loading_and_error_views.dart`, `error_pane.dart` |
| 8 | Qibla dial: tick ring with no N/E/S/W, no target marker, no aligned state, fixed 260 dp, no Semantics on the dial | `before/qibla-light.png` |
| 9 | Qibla's "turn" information was absent: only `137° عن الشمال` (a static bearing) | same |
| 10 | Five different radii (10/11/12/14/16/28) and three body insets (0/12/16) across sibling screens | audit table in §5.1 |

### 5.1 Concrete file-level audit (read-only subagent sweep)

Screens inspected: home, prayer times, city picker, qibla, reader, recitation + player sheet,
library, hadith, bookmarks, search, azkar, tasbih, duas, zakat, settings.

Confirmed defects not fixed this wave (documented, see §12): player sheet ignores the bottom
system inset; library has no empty state for a missing catalog; bookmark delete has no
confirm/undo; mini player appears on only 2 of 8 screens; mushaf text is not selectable and has
no per-ayah affordance; hadith shows a raw `AR` language tag.

---

## 6. Design direction chosen

**Design read:** Arabic mobile ritual companion — warm ivory paper in light, deep forest in dark,
**one** structural accent (emerald) plus gold for sacred/attention; hierarchy comes from type
scale, grouping and surface tone, never from new colours or decoration.

Deliberately **not** adopted from the reference: dark-only glassmorphism, star fields, violet
secondary accent, neon glows, and a 6-item bottom bar bolted onto a flat `GoRoute` table.

### 6.1 Tokens

```
radius      sm 8 · md 12 · lg 16 · xl 24 · pill 999        (lib/core/theme/app_radius.dart)
spacing     xs 4 · sm 8 · md 12 · lg 16 · xl 24            (existing AppSpacing)
type        heroValue 30/1.15 · heroTitle 21/1.25 · cardTitle 16/1.35
            sectionLabel 13/1.4 · caption 13/1.5 · rowTitle 16 bold
            + meQuranHead 20 (surah/city) · hafsAyah 24/2.0 (mushaf)
colour      primary emerald 3E6B58 / E4EEE9 (dark)
            highlight primaryContainer DCE8E1 · 1E2F27 (dark)
            grouping surfaceContainerHighest E6E2D4 · 1A251F (dark)
            gold E3A53E · goldText 8A5A14 (AA on ivory)
            hairline D9D2BF · 2A362F (dark)
elevation   flat; 1 px hairline border; depth from tone, not shadow
```

The `primaryContainer` / `surfaceContainerHighest` overrides are the highest-leverage colour
change: they were the two seed-generated roles that produced the off-brand mint and the cold grey
tiles across prayer, tasbih, azkar, hijri and asma.

### 6.2 Component rules

- **Cards** — one surface, `AppRadius.lg`, hairline border, no elevation, `margin: 0` at the call
  site so spacing is owned by the layout.
- **Service tile** — `Material` + `InkWell` (visible ripple), 44 dp tinted icon circle, caption
  label with **no** `maxLines`, intrinsic height ≥ 104 dp. Grows with `textScaler`.
- **Section header** — 3 px accent bar + 13 px bold label, start-aligned (was end-aligned, i.e.
  left in RTL — a bug).
- **Highlight row** — tinted surface + 3 px `BorderDirectional(start:)` accent + one distinctive
  glyph; never colour alone.
- **States** — failure = icon + localized message + retry (when the screen can reload); empty =
  optional icon + message + optional action; both scrollable so 2.0 text cannot overflow.

---

## 7. Implemented changes

### 7.1 Home — from a flat index to a dashboard

Before → after:

| Before | After |
|---|---|
| App bar + two `ListTile` cards + 14 flat tiles | App bar + next-prayer hero + continue-reading card + 3 labelled groups of tiles |
| Time only (`١٨:٤٨`), no countdown | Context block (label · prayer · time · city) on one side, live HH:mm:ss countdown on the other |
| No location when a city was set | City name inside the hero context block |
| Tile ripple invisible | `Material` + `InkWell` |
| Fixed tile height, 12 px label, 2-line ellipsis | Per-row equal height (`IntrinsicHeight`), no label clamp, 44 dp badge |
| Ragged tile bottoms when one label wrapped | Each row shares one height; a missing slot keeps its column width |
| 14 ungrouped destinations | 3 groups: القرآن والاستماع (3) · العبادة اليومية (6) · المزيد (5) |

The hero is deliberately two-column: the context block (label, prayer name, target time, city)
sits at the reading start, and the countdown sits at the opposite edge, so the eye finds the
moving number without scanning the whole card. Under a 2.0 text scale the countdown is allowed to
scale down inside its column rather than push the row apart.

All 14 destinations are preserved, same routes, same callbacks. Grouping and order are the only
behavioural change.

### 7.2 Prayer times — one panel, one differentiated row

Before → after:

| Before | After |
|---|---|
| 7 separate `Card`s | City header + **one** panel card with hairline dividers |
| Mint `primaryContainer` row | Warm emerald tint + 3 px start accent + schedule glyph |
| `radio_button_unchecked` on 5 rows | No glyph on prayers; sunrise muted with a sun glyph |
| Sunrise indistinguishable | Sunrise muted, no countdown, no highlight |
| Failure = text, no retry | Failure = icon + text + "أعِد المحاولة" |
| Empty = text + button | Empty with `location_off` icon + button |

### 7.3 Qibla — the dial now answers a question

- Cardinal **words** شمال / شرق / جنوب / غرب painted at their true bearings (they rotate with the
  live heading). Initials were rejected: شمال and شرق share the same first letter.
- Gold **qibla marker** on the rim at the qibla bearing, coincident with the arrow's angle.
- **Aligned state**: within ±5° the ring and arrow turn gold, and a gold pill reads
  "أنت تواجه القبلة"; otherwise "أدر الهاتف ٣٠° يمينًا / يسارًا" from the *shortest* signed turn.
- One haptic tick on entering alignment (not per sample).
- Responsive dial: `min(available width, 320 dp)` instead of a fixed 260 dp.
- The dial announces the actionable state (aligned / turn N° / bearing) through `Semantics`
  instead of repeating the visible bearing line; the city row is a quiet info row, not a fake
  list tile.
- Failure state gains retry.

### 7.4 Shared system

- New `AppRadius` scale; `CardTheme`/`FilledButtonTheme`/`DividerTheme` aligned to it.
- `ColorScheme` container roles re-tinted to brand (fixes 6 screens at once).
- `ErrorView` gained `icon`, `onRetry`, `retryLabel`; `errorPane(loc, onRetry:)`.
- `EmptyState` gained `icon`, and both state views are scroll-safe.
- `SectionHeader` is now start-aligned with an accent bar and an optional trailing slot.
- New `ServiceTile` (shared, reusable by any future grid).
- New `formatDurationHms` (clamped at zero, Arabic-Indic).
- 6 new localization keys in AR + EN, generated files regenerated.

---

## 8. Files modified

Created:

```
lib/core/theme/app_radius.dart
lib/core/widgets/service_tile.dart
test/home_dashboard_visual_test.dart
test/prayer_panel_test.dart
test/qibla_compass_test.dart
test/state_views_test.dart
docs/ui-ux-inspiration-muslimcompanion.md   (this file)
```

Modified:

```
lib/core/theme/app_theme.dart                  radius + type steps + container roles
lib/core/theme/app_colors.dart                 highlight / grouping / dark tints
lib/core/widgets/loading_and_error_views.dart  retry + icon + scroll-safe
lib/core/widgets/error_pane.dart               optional retry
lib/core/widgets/empty_state.dart              icon + scroll-safe
lib/core/widgets/section_header.dart           start-aligned + accent bar + trailing
lib/core/utils/arabic_numbers.dart             formatDurationHms
lib/features/home/presentation/home_screen.dart
lib/features/home/presentation/home_state.dart  next-prayer record carries cityName
lib/features/home/presentation/home_cubit.dart  supplies cityName (no logic change)
lib/features/prayer/presentation/prayer_times/prayer_times_screen.dart
lib/features/qibla/presentation/qibla_screen.dart
lib/l10n/app_ar.arb · app_en.arb               +6 keys
lib/l10n/app_localizations*.dart               generated
```

No generated freezed file needed regenerating: `NextPrayerCard` is a record typedef, not a
freezed class, so adding a field changes neither the union nor its `copyWith`.

---

## 9. Deliberately unchanged

- All routing (`lib/app/router.dart`) and every route string.
- Bottom navigation — **not** added; see §12.
- The reader, the player sheet, library, hadith, azkar, tasbih, duas, zakat, settings screens:
  their internal layout was not redrawn. They inherit the container-role colour correction.
- Business logic: the home cubit gained one field in an existing record; no rule, calculation or
  persistence changed.
- The mushaf font sizes, page model and audio pipeline.
- Dependencies: none added.

---

## 10. Verification

### 10.1 Static gates

| Gate | Command | Result |
|---|---|---|
| Format | `dart format --output=none --set-exit-if-changed` on every touched path | clean (0 would change) |
| Analyze | `flutter analyze` | **No issues found!** |
| Build | `flutter build apk --debug` | built `app-debug.apk` (warning: Kotlin Gradle Plugin migration notice, pre-existing) |

### 10.2 Tests

Targeted run first (the screens this wave touched), then the whole suite.

```
flutter test test/home_dashboard_visual_test.dart \
             test/prayer_panel_test.dart \
             test/qibla_compass_test.dart \
             test/state_views_test.dart \
             test/home_screen_test.dart test/home_quality_probe_test.dart \
             test/home_cubit_test.dart test/home_city_hint_test.dart \
             test/home_continue_reading_test.dart \
             test/prayer_times_screen_test.dart test/prayer_city_textscale_test.dart \
             test/prayer_times_ticker_test.dart test/prayer_ticker_lifecycle_test.dart \
             test/qibla_screen_test.dart test/qibla_quality_probe_test.dart \
             test/edge_to_edge_screens_test.dart
→ 29 tests passed
```

Full suite: see §10.5.

New coverage added (all additive; no existing test was edited):

| Test file | Pins |
|---|---|
| `test/home_dashboard_visual_test.dart` | 3 named groups · all 14 destinations · hero shows city/time/countdown · tiles ≥ 48 dp · 2.0 scale grows tiles instead of clipping |
| `test/prayer_panel_test.dart` | one panel (2 cards total) · exactly one `Icons.schedule` · sunrise is a marker, not a radio button · failed load offers retry |
| `test/qibla_compass_test.dart` | shortest signed turn (20° not 340°) · aligned confirmation · left vs right instruction |
| `test/state_views_test.dart` | `ErrorView` retry wiring · `EmptyState` icon + action |

### 10.3 What the tests actually caught

The new tests found two real defects during the wave, both fixed before the final
build: the hero rendered the "next prayer" label twice after the layout was restructured, and a
future-dated prayer made a `pumpAndSettle`-based test chase the cubit's one-shot reload timer
(the test now uses the frozen fake's past time; liveness is proven on-device instead — §10.4).

### 10.4 On-device verification (Infinix X6882, `13372704AR007777`)

Installed `com.mostafasayed.quranyahdi.debug` (debug suffix, so the release install and its data
were untouched) and inspected the rendered screens in both themes.

| Check | Evidence |
|---|---|
| Home, light | `after/v3-home.png` (hero + continue-reading + 3 groups) |
| Home groups, scrolled | `after/v2-home-groups.png`, `after/pre-tap.png` — tile bottoms align per row |
| Home, dark | `after/dark-home.png` — forest surfaces, ivory type, gold clock badge |
| Prayer panel, light | `after/final-prayer.png` — one card, hairline dividers, sunrise muted + sun glyph, no radio dots |
| Prayer panel, dark | `after/dark-prayer.png` |
| Qibla | `after/final-qibla.png` — شمال/شرق/جنوب/غرب labels, gold qibla marker on the rim, "أدر الهاتف ٣٦° يمينًا", "١٣١° عن الشمال" |
| Countdown is live | Two captures 6 s apart: the countdown crop hashes differ, and the rendered value moved `٠٠:١٩:٣٠ → ٠٠:١٧:٠٧` while the target stayed fixed |
| Countdown correctness | At 19:36 device time, after Isha (18:48), the hero shows the **next day's Fajr ٠٤:٤٠** with `٠٩:٠٣:٤٠` remaining — the rollover is correct |

**Not verified on-device** (and therefore not claimed): the highlighted "next prayer" row inside
the panel (every capture ran after Isha, when no row is next — the widget test covers it), the
first-run "no city" hero, and the failure/retry panes. §12 lists these as the next device pass.

Screenshots live outside the repo under
`%LOCALAPPDATA%\Temp\opencode\mc-recon\{before,after}\` and are intentionally not committed.

### 10.5 Full suite

```
flutter test
→ 892 tests passed, 0 failed
```

`flutter analyze` was re-run on the final tree after the last edit: **No issues found!**
The APK was rebuilt from the final tree as well.

One caveat, stated precisely: the on-device screenshots come from the build immediately before a
one-line revert of a `DividerTheme.space` value. That value is not used by any redesigned screen
(home, prayer panel and qibla all pass an explicit divider height), and its removal only restores
the Material default spacing in the untouched Settings/Licenses lists. The final tree was
re-analyzed and re-tested; the device dropped off adb before a final reinstall.


---

## 11. Remaining UX issues (found, not fixed in this wave)

Ordered by user impact. Each one is a real defect in the current tree, not a wish.

| # | Issue | Where | Why it was not fixed here |
|---|---|---|---|
| 1 | No bottom navigation. 14 features sit behind one screen; 2 taps minimum to reach anything, and no way back to a section | `lib/app/router.dart` (flat `GoRoute` table) | **Fixed in wave 2 (§13.1)** — 4-tab bar over a `ShellRoute`; detail routes stay full-screen |
| 2 | Mini player only exists on the reader and the reciter's surah list. Audio keeps playing with no pause/stop surface on 6 other screens | `mini_player_bar.dart`, used at `reader_screen.dart:140`, `reciter_surahs_screen.dart:82` | Still open: the bar lives per-screen. The shell now exists, so the next step is moving the mini player into it |
| 3 | Player sheet ignores the bottom system inset (`useSafeArea:true` ⇒ `SafeArea(bottom:false)`) so transport controls sit in the gesture strip | `player_sheet.dart:36-44, 124-130` | **Fixed in wave 2 (§13.2)** |
| 4 | Library shows three blank tabs when the catalog is empty | `library_screen.dart:54-59, 146, 156-172` | **Fixed in wave 2 (§13.3)** |
| 5 | Bookmark delete is instant, with no confirm/undo (library and recitation do confirm) | `bookmarks_screen.dart:79-83` | **Fixed in wave 2 (§13.4)** — one pinned test updated, see §13.4 |
| 6 | Mushaf text is not selectable and has no per-ayah affordance in page mode | `reader_screen.dart:445-455` | Selection **fixed in wave 2 (§13.5)**; per-ayah affordance in page mode is still open |
| 7 | Azkar rows show an English subtitle inside an Arabic-only UI | `azkar_screen.dart` row builder | Content decision: remove the field or localize it |
| 8 | Hadith language chip shows a raw code (`AR`) | `hadith_screen.dart:55-62` | Needs a localized language-name map |
| 9 | `SearchField` hardcodes `textAlign: TextAlign.right`; the app pins `locale: ar` while advertising `en` | `search_field.dart:27`, `app.dart:51` | Localization policy change |
| 10 | Radii/insets are still inconsistent in untouched screens (10/11/12/14/28) | azkar, asma, hadith, library | Scale exists now; migration is mechanical follow-up |
| 11 | No global `TextTheme`; each untouched screen still carries inline `TextStyle` | app-wide | A global text theme changes every screen at once and cannot be visually verified in one wave |
| 12 | Qibla dial still reports a static bearing ("١٣٧° عن الشمال") rather than a live deviation in the footer | `qibla_screen.dart` | Deliberate: the live turn instruction now covers this; the footer keeps the fixed qibla bearing for context |
| 13 | After Isha the prayer panel highlights **nothing** (its state carries today only) while Home advertises tomorrow's Fajr — the two screens disagree | `prayer_times_cubit.dart`, `prayer_times_state.dart` | **Fixed in wave 2 (§13.6)** — the panel now names tomorrow's Fajr |
| 14 | The prayer panel leaves a large empty area on tall phones once the six rows end | `prayer_times_screen.dart` | Partly addressed by the §13.6 footer; the hijri-date half is still open |

---

## 12. Recommended next wave

> Written before wave 2 (§13). Items 1, 2 (inset only), 3 (library/bookmarks) and 5 (selection)
> were delivered there; what is still open is listed below the original list, in §12.1.

1. **App shell + bottom navigation** (`Home · Quran · Prayer · Azkar · More`) with
   `StatefulShellRoute.indexedStack`, keeping the existing route strings, and moving the mini
   player into the shell so audio is controllable everywhere. Biggest single UX gain left.
2. **Player sheet inset fix + a downloads screen** (the download UI currently only exists as a
   per-row trailing slot).
3. **Library / bookmarks / hadith state pass**: empty states, confirm-before-delete, localized
   language names, share/copy actions.
4. **Token migration** of the remaining screens onto `AppRadius` + a real `TextTheme`, with
   per-screen screenshots as the acceptance gate.
5. **Reader wave**: selectable text, per-ayah action sheet in page mode, font-size control.
6. **Arabic copy pass**: remove or translate the English subtitles in azkar; align the app's
   locale policy with the ARB files it ships.

### 12.1 Still open after wave 2

> Wave 3 (§14) closed 1, 2 and 3, invalidated the selection half of 5, and deferred 4.

1. **Mini player in the shell** — **done in §14.2**.
2. **A downloads screen** — **done in §14.4**.
3. **Hadith pass** — **done in §14.3**.
4. **Token migration + global `TextTheme`** — **done in §15.1** (the ramp + guard test); the
   remaining per-screen inline sizes are the migration backlog listed there.
5. **Reader, part two** — per-ayah action sheet in mushaf page mode and font-size control are still
   open; "selection across lazily-unbuilt ayahs" is **invalidated** by §14.1 (the text is a
   private-use glyph encoding, so selection cannot be valid until the Unicode dataset lands).
6. **Arabic copy pass** — the English subtitles in azkar, and the `ar`-only locale policy.



---

## 13. Wave 2 — the six follow-ups (2026-10-31)

The owner picked six items from §11 and asked for them in one pass. Each subsection states the
before, the after, the files, and how it was verified.

### 13.1 Bottom navigation (§11 #1)

**Before:** every feature lived behind one screen; reaching prayer times or the Quran was
Home → tile, and there was no way back to a section from a detail screen.
**After:** a persistent four-destination bar — الرئيسية · القرآن الكريم · مواقيت الصلاة · الأذكار.

- Implemented as one `ShellRoute` in `lib/app/router.dart` plus `lib/app/app_shell.dart`. The four
  `GoRoute` blocks moved **verbatim** into the shell, so their `RouteCubitScope` wiring, identities
  and `start` hooks are unchanged.
- **Why four and not five:** Home is still the complete service directory (its 14 destinations are
  pinned by frozen tests), so a fifth "More" tab would have duplicated it. A new hub screen was
  rejected as duplication, not as risk.
- **Detail routes stay full-screen:** reader, recitation, library, qibla, city picker, settings …
  are declared outside the shell, so the bar disappears there (verified on device, §13.7).
- Bar styling: `surface` background, `primaryContainer` pill indicator, `AppRadius.pillAll`.
- `test/router_test.dart` now walks nested `ShellRoute` children; the pinned 14-path map is
  unchanged — only its traversal moved.
- New `test/app_shell_test.dart`: four destinations, tapping the prayer destination updates
  `selectedIndex`, and a detail route renders without a bar.
- **Known trade-off:** switching tabs recreates the route-scoped cubit (fresh data, scroll position
  not preserved). `StatefulShellRoute.indexedStack` would preserve state but changes the
  `ModalRoute` contract Home's `RouteAware` reload depends on.

### 13.2 Player sheet bottom inset (§11 #3)

`showModalBottomSheet(useSafeArea: true)` protects the top and sides but not the bottom, so the
transport row sat inside the gesture strip on an edge-to-edge build. The sheet's padding bottom is
now `AppSpacing.lg + appBottomInset(context)` (`player_sheet.dart`). Covered by the existing
`player_sheet_test.dart` (still green).

### 13.3 Library empty state (§11 #4)

- Whole catalog empty → **one** `EmptyState` (`libraryEmpty`, `inventory_2_outlined`) instead of a
  TabBar over three blank pages.
- A visible tab whose list is empty → the same empty state instead of a blank list.
- `visibleLibraryKinds()` is untouched (its 3-tab fallback is pinned by `library_tabs_test.dart`);
  the whole-empty decision is made in the widget.
- New `test/library_empty_state_test.dart` (empty catalog shows one state and no TabBar; a catalog
  with a pack restores both).

### 13.4 Bookmark delete confirmation (§11 #5)

- `bookmarks_screen.dart` now calls the shared `confirmDeleteDialog` with
  `bookmarkRemove` / `bookmarkRemoveBody` and only deletes on confirmation. The cubit is resolved
  before the `await`, and `context.mounted` is checked after it.
- **One pinned test had to change:** `test/bookmarks_screen_test.dart` tapped delete and asserted
  the row was gone in the same frame — the exact behaviour the owner asked to remove. The test now
  taps the dialog's حذف as well. This is a behaviour change requested by the owner, not a test
  weakened to fit the code.
- New `test/bookmark_delete_confirm_test.dart`: cancelling keeps the row, confirming removes it.

### 13.5 Selectable Quran text (§11 #6) — **superseded, see §14.1**

- **Before:** the ayah text was plain `Text`; nothing could be selected or copied.
- **After:** one `SelectionArea` wraps the reading surface (basmala + both modes).
- **Why `SelectionArea`, not `SelectableText`:** `SelectableText` renders through `EditableText`
  and would change the HafsSmart/me_quran line metrics and the shaped page paragraph.
  `SelectionArea` adds no render object, so fonts, spacing and the ornamented page stay identical,
  and it gives cross-ayah selection plus the native handles/toolbar.
- **Gesture safety:** the region is an *ancestor* of the two scrollables, so their drag recognizers
  still win the arena — vertical scrolling and the mushaf page swipe keep working, and only a
  long-press starts a selection (verified on device: handles + نسخ/مشاركة/اختيار الكل toolbar).
- Limitation, accepted and documented: selection spans the ayahs currently built by the lazy list,
  not all 286 of a surah.
- New `test/reader_selection_test.dart` (selection present in both modes; the ayah is still a plain
  `Text` with the same data/font; vertical drag still scrolls; horizontal fling still turns pages).

> **Correction (2026-10-31):** this shipped a broken copy path. The reader renders the
> **PUA-glyph-encoded** `text_uthmani` column (codepoints such as `U+E8DB` that only the bundled
> Hafs face can draw), so a selection copied `   …` into WhatsApp. The selection region was
> removed and replaced by a per-ayah copy action that takes `text_imlaei` (real Arabic). Full
> analysis, evidence, and the enabler for bringing selection back are in §14.1.

### 13.6 After Isha — the panel now names tomorrow (§11 #13)

- **Before:** after Isha no row is next, so the panel highlighted nothing and said nothing while
  Home advertised tomorrow's Fajr.
- **After:** the state carries `nextTomorrowName`, `nextTomorrowTime` and `nextTomorrowRemaining`,
  and the panel renders a quiet footer card — "غدًا فجر ٠٤:٤٠" with "متبقٍ ٠٨:٤٥".
- **Contract kept:** `remaining` still goes null once no row is next (the frozen ticker test pins
  exactly that), so the footer has its own countdown field instead of overloading `remaining`.
- The list stays today's six times; tomorrow is never appended as a seventh row (which would have
  duplicated the `فجر` label the frozen screen test finds exactly once).
- New `test/prayer_tomorrow_note_test.dart` (footer text + countdown after Isha; no footer while a
  prayer is ahead).

### 13.7 Verification

| Gate | Result |
|---|---|
| `flutter analyze` | **No issues found!** |
| `dart format --output=none --set-exit-if-changed` on touched paths | clean |
| `flutter test` (full suite) | **905 passed, 0 failed** |
| `flutter build apk --debug` | built and installed (`…quranyahdi.debug`) |

On-device (Infinix X6882), screenshots under
`%LOCALAPPDATA%\Temp\opencode\mc-recon\wave2\`:

| Check | Evidence |
|---|---|
| Bar on Home, Home selected | `w2-home.png` |
| Bar follows the tab; prayer row highlighted with countdown | `w2-prayer-tab.png` |
| Quran tab | `w2-quran-tab.png` |
| Detail route has no bar | `w2-reader-select.png` (reader, full screen) |
| Quran text selectable | `w2-select2.png` — handles + native toolbar (نسخ / مشاركة / اختيار الكل) |

**Not visually verified** (test-only, and stated as such): the library empty state (the device has
a catalog), the after-Isha footer (the capture ran before Isha; the device clock was also being
changed externally), and the player-sheet inset (needs an active track). Each is pinned by a
widget test listed above.

### 13.8 Disclosure — a `build_runner` hazard hit during this wave

`dart run build_runner build --build-filter=<one output>` **deletes every generated output outside
the filter**. It removed 24 committed `.freezed.dart` files (the whole feature set). They were
restored byte-exact from `HEAD` and `flutter analyze` then returned to zero. Anyone regenerating
codegen in this repo should run an unfiltered build, or restore the deleted outputs and check
`git status` immediately.

---

## 14. Wave 3 — the share-copy bug and the follow-ups (2026-10-31)

### 14.1 Bug: copying a verse produced glyph codes

**Report:** selecting an ayah and sharing it to WhatsApp produced `‏ ‏‏ ‏‏‏‏ …` — boxes
instead of Arabic.

**Root cause (evidence, not a guess).** The reader renders `ayahs.text_uthmani`, and that column is
a **private-use glyph encoding**, not text:

```
text_uthmani = '\u200F\ue8db \u200f\ue338\u200f\ue48e …'   (U+E8DB, U+E338 … = PUA)
text_imlaei  = 'بسم الله الرحمن الرحيم'                      (real Unicode Arabic)
```

Checked directly in `assets/db/quran.sqlite`, ayah 1. The bundled `HafsSmart_08.ttf` maps those
PUA codepoints to the Uthmani glyphs, so the screen is correct — but any selection is a PUA
string, which every other app renders as tofu. The web bundle (`web/src/data/ayahs/1.json`) uses
the same PUA `u` field, so there was no Unicode Uthmani source to switch to.

**Why the share button was fine:** `_ShareAyahButton` already shares `ayah.textImlaei`. Only the
selection I added in §13.5 leaked the glyph string.

**Fix shipped:**
- Removed the `SelectionArea` from the reader. Partial selection of glyph-coded text can never be
  valid, and expanding it (the §12.1 "selection across unbuilt ayahs" item) would have spread the
  bug, so that item is **invalidated**, not deferred.
- Added a per-ayah **copy** action (`Icons.copy_outlined`, tooltip "نسخ الآية") that writes
  `ayah.textImlaei` to the clipboard and confirms with a "تم نسخ الآية" snackbar. It sits beside
  the existing share button, which keeps sharing `text_imlaei` too.
- New keys `copyAyah` / `ayahCopied` (AR + EN).
- `test/reader_ayah_copy_test.dart` replaces `reader_selection_test.dart`; the fixture stores a
  deliberately PUA `textUthmani` and real `textImlaei`, and the test asserts the clipboard payload
  equals the Arabic text and contains **no** codepoint in `U+E000–U+F8FF`. It also keeps the
  scroll and page-swipe regressions.

**The enabler for real selection (next wave, scoped):** bundle a Unicode Uthmani dataset
(e.g. Tanzil Uthmani, ~1.5 MB) plus a Unicode Quran face (e.g. KFGQPC HAFS Uthmanic), keep
`text_imlaei` for search/copy, and only then re-introduce `SelectionArea`. That is a data +
licensing + visual-regression job, not a widget tweak, which is why it is not bundled here.

### 14.2 Mini player moved into the shell (§12.1 #1)

- `PlaybackCubit` is an app-level GetIt singleton, so the `ShellRoute` builder now provides it and
  `AppShell` mounts `MiniPlayerBar` **inside the bottom navigation area**
  (`bottomNavigationBar: Column(min, [MiniPlayerBar, NavigationBar])`).
- That slot is excluded from the body's height by `Scaffold`, so the playing strip pushes the page
  up instead of covering its last row; it is zero-height while idle, so nothing moves.
- Result: the player is now reachable on Home, Quran, Prayer and Azkar. The reader and the
  reciter's surah list keep their own instance (they are detail routes outside the shell).
- `test/app_shell_test.dart` asserts the shell mounts the bar.

**On-device evidence:** playing a surah in the reader and returning to Home showed the strip with
"يُشغّل الآن: عبدالباسط عبدالصمد / الفاتحة", a progress bar, pause and stop, sitting above the four
destinations (`wave3/mp2.png`, `wave3/mp-home.png`). Those captures were taken with the first
version of the shell slot (`bottomSheet`); the strip was then moved into the nav column so the body
shrinks instead of being overlaid. The final layout is covered by the shell test and the framework
contract, but was not re-photographed after the move.

**Side effect to know:** diagnosing this required a clean reinstall on the debug package, which
cleared the debug app's local data (last-read position, selected city). The release install and
its data were not touched.

### 14.3 Hadith screen pass (§12.1 #3)

`lib/features/library/presentation/hadith/hadith_screen.dart`:

- **Loading** now uses the shared `LoadingView` instead of a bare spinner.
- **Empty** renders `EmptyState(icon: Icons.menu_book_outlined, hadithEmpty)` and no pager
  (previously a blank list under a pager).
- **Language chip** maps the code to a localized name (`ar` → "العربية", `en` → "الإنجليزية"),
  falling back to the raw code. It printed `AR` before.
- **Number badge** is a fixed 28 dp box with `FittedBox(scaleDown)`, which lets the numeral grow at
  textScaler 2.0 instead of being frozen by `CircleAvatar`'s internal no-scaling wrapper.
- New keys `hadithEmpty`, `languageArabic`, `languageEnglish`; new
  `test/hadith_state_views_test.dart` (5 tests: empty, loading, localized chip, code fallback,
  2.0 scale).

Honest note from that pass: the old `CircleAvatar` did **not** actually overflow at 2.0 (it wraps
its child in `MediaQuery.withNoTextScaling`). The change was kept because it improves the numeral
at large scales, and the test now pins the 28 dp box rather than claiming a fixed bug.

### 14.4 Downloads screen (§12.1 #2)

**Before:** the only download UI was the trailing slot of each row inside the reciter's surah
list; there was no place to see what is actually on the device. `DownloadsCubit` existed but no
screen used it.

**After:** `/downloads` — a list of installed surahs (reciter, surah, size), per-row delete behind
the shared confirmation, `EmptyState` when nothing is installed, `LoadingView` and `errorPane` for
the other arms. Entry point: an icon in the reciters AppBar.

- The cubit gained one **read-only** method, `Future<List<InstalledDownload>> installed()`, which
  joins `AudioDownloader.listDone()` with `ReciterRepository.surahNamesFor([...])`. It deliberately
  does not add a freezed state field (no codegen, no `build_runner`).
- `SurahSource` has no by-id lookup (only `watchAll` / `watchSummaries`), so the join uses the
  reciter repository's existing `surahNamesFor` query on the same `surahs` table — one indexed
  `WHERE id IN (…)`, no catalog load per build.
- The route provides the **existing** singleton via `BlocProvider.value(getIt<DownloadsCubit>())`,
  not `create:`: a second instance would re-run `reconcileOnStart()` under an active transfer and
  leave stale "done" badges on the reciter rows after a delete here.
- Size reuses the existing `libraryPackSize` template with Arabic-Indic digits; three new keys:
  `downloadsTitle`, `downloadsEmpty`, `downloadsDeleteBody`.
- New `test/downloads_screen_test.dart` (empty, one installed row, confirm/cancel delete), plus all
  67 existing `audio_* / downloads_* / recitation_* / reciter_*` tests re-run green.

**Not verified:** the screen's failure arm, its refresh-after-delete, and its 2.0 text scale are
not covered by tests, and the device pass did not reach this screen.

### 14.5 The global `TextTheme` — deferred here, delivered in §15.1

This was left out of wave 3 and completed immediately afterwards; see §15.1 for the ramp, the
weight contract, and the migration boundary.

### 14.6 Verification

| Gate | Result |
|---|---|
| `flutter analyze` | **No issues found!** |
| `dart format` on touched paths | clean |
| Targeted tests | reader copy/scroll/paging, hadith (20), downloads (3 + 67 recitation), app shell — green |
| Full suite | **913 passed, 0 failed** |
| `flutter build apk --debug` | built and installed on the debug package |

On-device evidence for the copy fix (`%LOCALAPPDATA%\Temp\opencode\mc-recon\wave3\`):
`copy-tap.png` shows the copy action firing with its "تم نسخ الآية" confirmation, and
`r2.png` shows the new copy icon in the ayah action row.

---

## 15. Typography system + the selection decision (2026-10-31, continued)

### 15.1 `TextTheme` — delivered (closes §14.5)

The app now ships a real type ramp instead of relying on Material defaults plus scattered
`TextStyle(fontSize: …)` literals.

- `AppTheme._textTheme` builds every role from Cairo, in the **same metrics Material 3 uses**
  (size/height), so adopting it does not reflow an existing screen.
- **Only 400 and 700** are used, because that is what the bundled Cairo has. The old ramp asked
  M3 for 500 in six roles; those rendered as 400 while reading as "medium" in source. Three real
  sites were lying about their weight and are fixed: the Hijri day cell, the library pack title
  (both now 700), and the reciter variant row (now explicitly 400).
- **AppBar titles stay regular on purpose** (`titleLarge` → 400). Bolding all sixteen headers
  would be a restyle, not a consistency fix.
- Emphasis that Material components already expect is now real: dialog titles (`headlineSmall`)
  and tab labels (`titleSmall`) are 700.
- `AppTheme.bodyText` (15/1.6) replaces the duplicated literal in `EmptyState` and `ErrorView`.
- **Guard test** `test/theme_typography_test.dart`: every text role must be Cairo at w400/w700,
  and a source scan fails the build if any file asks for `FontWeight.w500/w600`.

**Scope boundary, stated honestly:** ~40 inline sizes remain in feature screens (azkar 6,
reader 5, asma 4, reciters 4, zakat/tasbih/licenses/hijri/duas 3 each, and a long tail). They were
not mass-migrated in this pass because most use one-off sizes (11/12/13/15/18/20/22) whose nearest
role changes pixels; each needs its own screenshot check. The ramp is now the single place to
migrate them into, one screen per commit — that is the remaining work, not a missing system.

Device check: Home renders unchanged after the swap (`wave4/t-home.png`), and the targeted screens
plus the full suite stay green — `flutter test` → **916 passed, 0 failed**, `flutter analyze` →
**No issues found!**

### 15.2 Long-press copy — the safe half of "selectable text"

Long-pressing a verse now copies it (real Arabic, `text_imlaei`) and confirms with the same
snackbar as the copy button, through one shared `copyAyahText`. New test:
`test/reader_ayah_copy_test.dart` covers both the button and the long-press, asserting the
clipboard contains no codepoint in `U+E000–U+F8FF`.

This is a mitigation, not selection: the reader still renders a private-use glyph encoding (see
§14.1), so partial selection cannot produce valid text no matter which widget hosts it.

### 15.3 The decision selection is actually blocked on

| Option | What it means | Cost / risk |
|---|---|---|
| **A. Keep the current mushaf** | HafsSmart + the PUA Uthmani column, no text selection; copy/share/long-press carry the copy path | zero data risk; selection stays unavailable |
| **B. Switch to Unicode Uthmani** | New Unicode column (Tanzil/QPC edition) + a Unicode Quran face + attribution, then `SelectionArea` becomes valid | ~1.5 MB data, a licensed font asset, an asset rebuild, and a full visual re-QA of every mushaf page; the rendering *will* look different from today's glyph-perfect Madani page |

Option B is the only way to get real selection (and, later, in-text search highlighting). It is a
scripture-rendering decision, so it is left to the owner rather than taken silently; the code is
ready to accept it the moment the column exists.

> **Decided:** the owner chose **B**. It is implemented in §16 — and it turned out to need no new
> font at all: the bundled HafsSmart already renders Unicode text identically to the glyph column,
> so the mushaf looks the same and the text became real.

---

## 16. Unicode Uthmani — decision B executed (2026-11-01)

§15.3 offered two options for real text selection. The owner chose **B**: ship Unicode Uthmani
text and a Unicode Quran face so selection/copy/search act on real Arabic.

### 16.1 Data provenance and validation

| | |
|---|---|
| Source | `https://api.alquran.cloud/v1/quran/quran-uthmani` (Tanzil-derived Uthmani edition), fetched once |
| Shape | 114 surahs → 6,236 ayahs, written as one UTF-8 JSON per surah (`{"<ayah>":"<text>"}`) under `assets/quran/uthmani/` |
| Size | 1,362 KB total |

The fetch script refuses to write anything unless every gate passes, and it was run until all of
them did:

- **6,236 / 6,236** ayahs, keys reconciled 1:1 against `assets/db/quran.sqlite` (no unknown,
  missing or duplicate `(surah, ayah)`).
- **No private-use codepoints**, no Latin letters, no blank verses.
- **No leading combining mark/space** on any verse (the first run exposed two surah openings that
  kept a stray kasra after cutting a glued basmala; the cutter now skips marks and whitespace).
- **Basmala de-duplication:** the API glues the basmala onto each surah's first ayah. It is
  stripped from **112 openings** (all except Al-Fatiha, where 1:1 *is* the basmala, and At-Tawbah,
  which has none) so the reader's basmala header is not painted twice. An-Naml 27:30 keeps its
  mid-verse basmala.
- **Orthographic cross-check** against the shipped `text_imlaei`: 83 outliers were reduced to 11
  after the basmala fix, and all 11 were reviewed by key — they are genuine Uthmani variants
  (`جِمَٰلَت` vs `جمالة`, dagger-alef spellings, `ءَايَٰت` vs `آيات`), not misalignments.
- **Font coverage:** every one of the 68 distinct codepoints in the corpus exists in the bundled
  face (0 missing), so no verse can fall back to tofu.

A real bug was caught here before shipping: the first writer serialised the **raw API payload**
instead of the cleaned text, which would have duplicated the basmala in 112 surahs. The asset test
(`2:1` must not contain "بسم") is what surfaced it.

### 16.2 Font — no new font needed (and why Amiri was rejected)

The expected cost of option B was "a licensed Unicode Quran face and a different look". Both turned
out to be unnecessary:

- **Amiri Quran (OFL) was downloaded, tried, and rejected on evidence.** It contains every one of
  the 68 codepoints, but Chrome/Windows renders its Quranic marks *detached* from the letters — the
  harakat float above the word instead of attaching (`quran-unicode/compare.png`). A text face that
  cannot position marks is unusable for a mushaf.
- **The already-bundled `HafsSmart` is Unicode-capable.** Rendering the new Unicode assets with
  HafsSmart at the app's real sizes (24 px/2.0 and 22 px/2.2) is visually **identical** to today's
  private-use column (`quran-unicode/sizes.png`): same face, same ligatures, same mark positions.

So the switch changes the *data* and not a single pixel of the mushaf. The Amiri files were removed
again; `pubspec.yaml` gained only the asset directory.

| | |
|---|---|
| Face | `HafsSmart_08.ttf` (already shipped) |
| Glyph coverage | 68/68 codepoints used by the corpus are present |

### 16.3 Architecture — no database migration

- `Verse` gained `textUnicode` (nullable) and `copyText` (`textUnicode ?? textImlaei`, never the
  glyph column).
- `UthmaniTextSource` / `AssetUthmaniTextSource` loads and caches one surah's JSON. It is injected
  into `ReaderCubit` as an **optional** dependency, so every existing construction site and frozen
  test keeps compiling and simply gets the fallback.
- The reader renders `textUnicode` with `AmiriQuran` and falls back to `stripAyahEndMarker(textUthmani)`
  with HafsSmart.
- **Selection is enabled only when every verse of the surah has Unicode text** (`state.ayahs.every`),
  so a missing asset degrades to the previous behaviour instead of exposing glyph garbage.
- Copy, share and the long-press all prefer the Unicode text; the imlaei column remains the
  fallback. The database, bookmarks, last-read and the PUA column are untouched — zero user-data
  risk, reversible by deleting the asset folder.

### 16.4 Verification

| Gate | Result |
|---|---|
| Data | 6,236 ayahs / 114 files, all gates above |
| Font coverage | 68/68 codepoints present |
| `flutter analyze` | **No issues found!** |
| `test/uthmani_assets_test.dart` | every surah parses, no PUA/Latin, 6,236 total, 1:1 and Ayat al-Kursi read correctly, 2:1 has no basmala |
| `test/reader_ayah_copy_test.dart` | Unicode mode: selection area present + Hafs face + copy takes the Unicode text; long-press starts selection (not copy); fallback mode: no selection + long-press copies imlaei; scroll and page-swipe regressions |
| Full suite | **920 passed, 0 failed** |
| Device | reader renders the Unicode text identically; long-press selects a word with the native toolbar (§16.6) |

**Device pass:** the phone dropped off adb mid-wave and was in use for a while, so the font/text
pair was first proven at the app's real sizes in the browser (`sizes.png`). It was later installed
and exercised for real: the reader renders the Unicode text identically and long-press selection
works (§16.6).

### 16.5 Long-press: the second real bug this change surfaced

Enabling selection exposed a conflict with the copy-on-long-press shortcut added in §15.2: the
`GestureDetector` inside the card **won the long-press**, so `SelectionArea` never started a
selection. On the device that looked like "selection still doesn't work" even though the widget
was present.

Fix: the gesture is attached **only for the glyph fallback**. With Unicode text the verse is a
plain `Text`, so the long-press belongs to the selection region (verified on device: word selected,
handles + نسخ/مشاركة/اختيار الكل toolbar). Tests pin both arms.

### 16.6 On-device evidence

`wave5/u-reader-v2.png` — Al-Fatiha in the new build: HafsSmart, marks attached, identical
composition to the previous glyph rendering.
`wave5/u-select3.png` — long-press selects "ٱلرَّحْمَٰنِ" with handles and the native selection
toolbar, i.e. the copy/selection path now carries real Arabic.

Environment note for future device runs: this repo's `android/key.properties` now exists, and
`build.gradle` signs **debug** variants with the release key when it does. `adb install -r` over an
older debug-key install therefore fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`; uninstall the
debug package once, then install. (A silent `-r` failure is what made an earlier pass test a stale
build.)

### 16.7 Remaining after this change

- The web bundle (`web/src/data/ayahs/*.json`) still ships the PUA column; switching it is a
  separate campaign.
- Search still runs on `text_imlaei`; with Unicode present, in-text highlight could now be added.
- The PUA `text_uthmani` column stays in the DB as the documented fallback.


