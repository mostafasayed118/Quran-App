# Widget Inventory & Extraction Audit — `quran_yahdi`

> Committed by the PM (2026-10-16) as the governing reference for the UX-W1 primitives wave
> (PROMPT 10). Produced by a read-only audit session at HEAD `1079302a` — read-only proven
> (porcelain empty before/after, `flutter analyze` exit 0, 132/132 tests green at audit time).
> Only the PM-approved subset items are in scope for UX-W1; the rest are recorded here for W7.

## 0. Read-only proof & objective gates

| Check | Result |
|---|---|
| HEAD before / after | `1079302a` / `1079302a` — identical |
| `git status --porcelain` before / after | 0 dirty files both times |
| `flutter analyze` | **No issues found** (40.1s) |
| `flutter test` | **All tests passed** (+132) |

Everything below was verified by reading every screen at source; no file was modified.

**Scale:** 19 public widget classes + 24 private `_widgets` + 1 app root ≈ **44 widget classes**, across 19 `*_screen.dart` files. Notably only **one StatefulWidget** exists (`_MushafPager`) — the app is stateless-visual + cubit-owned, which makes extraction low-risk.

---

## 1. Complete widget inventory

**Public (screens/components):**

| Widget | File (class line) | Also consumed by |
|---|---|---|
| `QuranYahdiApp` | lib/app/app.dart:8 | — |
| `PlaceholderScreen` | lib/core/widgets/placeholder_screen.dart:3 | router `/settings` (hardcoded `'الإعدادات'` router.dart:177) |
| `HomeScreen` | home_screen.dart:12 | router `/home` |
| `SurahIndexScreen` | surah_index_screen.dart:11 | `/quran` |
| `ReaderScreen` | reader_screen.dart:15 | `/quran/reader` |
| `BookmarksScreen` | bookmarks_screen.dart:10 | `/bookmarks` |
| `RecitersScreen` | reciters_screen.dart:13 | `/recitation` |
| `ReciterSurahsScreen` | reciter_surahs_screen.dart:16 | `/recitation/reciter` |
| `MiniPlayerBar` | mini_player_bar.dart:9 | reader_screen.dart:88 **and** reciter_surahs_screen.dart:85 — already cross-feature shared |
| `LibraryScreen` | library_screen.dart:10 | `/library` |
| `PrayerTimesScreen` | prayer_times_screen.dart:12 | `/prayer-times` |
| `CityPickerScreen` | city_picker_screen.dart:8 | `/prayer-times/city` |
| `QiblaScreen` | qibla_screen.dart:13 | `/qibla` |
| `AzkarScreen` | azkar_screen.dart:10 | `/azkar` |
| `TasbihScreen` | tasbih_screen.dart:10 | `/tasbih` |
| `DuasScreen` | duas_screen.dart:10 | `/duas` |
| `TrackerScreen` | tracker_screen.dart:11 | `/worship` |
| `ZakatScreen` | zakat_screen.dart:9 | `/zakat` |
| `HijriScreen` | hijri_screen.dart:10 | `/hijri` |
| `AsmaScreen` | asma_screen.dart:11 | `/asma` |

**Private widgets** (extraction candidates marked ★):

| Widget | Location | Verdict |
|---|---|---|
| `_FeatureTile` | home_screen.dart:134 | ★ see 3-G |
| `_SurahRow` | surah_index_screen.dart:60 | ★ uses badge pattern |
| `_ReadyView` / `_VersesList` / `_AyahCard` / `_MushafPager`(STF) | reader_screen.dart:34/93/120/188 | stay feature-local (AyahCard is Quran-specific) |
| `_RecitersList` / `_SectionHeader` / `_ReciterRow` | reciters_screen.dart:83/110/135 | ★ `_SectionHeader` + badge |
| `_SurahDownloadRow` | reciter_surahs_screen.dart:101 | ★ uses badge + progress patterns |
| `_PlaybackStrip` / `_FailedStrip` | mini_player_bar.dart:60/151 | ★ failure strip pattern |
| `_FailureStrip` / `_PackList` / `_PackRow` | library_screen.dart:76/119/136 | ★ failure strip + progress patterns |
| `_TimesList` | prayer_times_screen.dart:44 | no-city pattern ★ |
| `_DialPainter` (CustomPainter) | qibla_screen.dart:96 | stay local |
| `_RecitingList` | azkar_screen.dart:78 | ★ text-card pattern |
| `_DuasView` / `_RuqyahView` | duas_screen.dart:67/164 | ★★ twins (§3-F) |
| `_Field` | zakat_screen.dart:123 | labeled numeric field — candidate only if more forms appear |
| `_NameSheet` | asma_screen.dart:94 | grid-tile pattern ★ |

---

## 2. Duplication findings with severity (evidence: file:line)

### A. Repeated visual idioms (highest value extractions)

**A1 — "Arabic coin" leading badge** — 3× byte-similar (`Container w38 h38`, `primary.withValues(alpha:0.12)`, `BorderRadius.circular(11)`, bold primary text):
- reciters_screen.dart:152-168 (`_ReciterRow` initial)
- surah_index_screen.dart:74-86 (`_SurahRow` id)
- reciter_surahs_screen.dart:150-165 (`_SurahDownloadRow` surah number)

**A2 — Search TextField** — 2× identical + 1× inconsistent variant:
- reciters_screen.dart:50-68 and surah_index_screen.dart:26-44 (filled, `secondary@0.08`, `OutlineInputBorder radius 12` no side, search prefix, `onChanged` wiring)
- city_picker_screen.dart:18-27 — **third instance missing the filled/radius styling** → live UI inconsistency already present

**A3 — "Download progress trailing"** — 2× near-identical (`SizedBox(width:…)` → Column(text, gap, `LinearProgressIndicator`)):
- library_screen.dart:155-170 (w 132, gap 6)
- reciter_surahs_screen.dart:198-213 (w 96, gap 4)

**A4 — Error strip** — 3× structurally same (`Material(color: errorContainer)` + `SafeArea(top:false)` + dismiss):
- library_screen.dart:88-115 (`_FailureStrip` w/ retry)
- mini_player_bar.dart:160-189 (`_FailedStrip` w/ close)
- reciters_screen.dart:37-49 (inline `dataError` ListTile, `wifi_off`)

**A5 — No-city empty state** — 2× identical (`Text(noCity)` + 12 gap + `FilledButton(push('/prayer-times/city'))`):
- prayer_times_screen.dart:24-36, qibla_screen.dart:29-43

**A6 — Quran-text inline styles** — `TextStyle(fontFamily: QuranFonts.meQuran/quran, fontSize ∵, height ∵)` hand-copied **15+ times** (home:33, surah_index:89, reader:152/246, duas:116/198, azkar:52/112, hijri:33/95, qibla:51/82, prayer_times:71, reciter_surahs:126/137). `AppTheme` (app_theme.dart:32) carries no Arabic `TextTheme` entries, so every instance invents its own size/height. Also `TextStyle(fontSize:11, color:onSurfaceVariant)` repeated ~10× (muted-footnote idiom).

**A7 — Loading/Error switch branches** — `XLoading() => const Center(child: CircularProgressIndicator())` + `XError => Center(child: Text(message))` hand-inlined in **14 screens** (home:23, prayer_times:22, surah_index:21, reciters:31, reciter_surahs:58, duas:53, azkar:41, library:32, tracker:21, zakat (cast), tasbih (cast), hijri:20, asma:21, city_picker:32, bookmarks:17-22, reader:21-27).

**A8 — RTL text boilerplate** — `textAlign: TextAlign.right + textDirection: TextDirection.rtl` duplicated in ~20 places; under the app's `ar` locale Material already resolves RTL, so most are redundant defensive copies (e.g. reciters:176-177, duas:115-116, reader:158). **PM: removal deferred to W7 — redundant-under-ar is NOT redundant-under-en (alignment flips).**

### B. Widget twins

**B1 — `_DuasView` vs `_RuqyahView`** (duas_screen.dart:67-238): same Card + padded Column + main Arabic text + count `×n` + reference footer; only font logic differs (`isQuran ? QuranFonts.quran : meQuran`). **2 widgets → 1 param'd widget.**

**B2 — Prayer-name label switch** duplicated: home_screen.dart:85-95 `_prayerLabel(PrayerName)` vs prayer_times_screen.dart:53-60 `label(PrayerName)` — identical 6-case switch.

### C. Risks surfaced during read (adjacent to the UX findings, worth one line each):
- Unsafe casts: zakat_screen.dart:19 `state as ZakatReady`, tasbih_screen.dart:20 `state as TasbihReady` → crash if a Loading state is ever emitted; every other screen uses exhaustive `switch`.
- Hardcoded strings bypassing l10n: reciter_surahs_screen.dart:76 & 94, router.dart:177, reciters_screen.dart:146 (`'؟'`).

## 3. Proposed shared structure

Keep feature-first organization; extraction goes to the **already-existing** `lib/core/widgets/` (not a new `lib/shared/widgets/` — would fragment the codebase). Theme extensions go to `lib/core/theme/`:

```
lib/core/widgets/
  ar_badge.dart            ArabicBadge(label, size, radius, textStyle)
  search_field.dart        SearchField(hint, onChanged, controller?)
  download_progress.dart   DownloadProgressLabel(received, total, formatFn, width)
  error_strip.dart         ErrorStrip(message, {retriable, onRetry, onDismiss})
  empty_state.dart         EmptyState(message, {actionLabel, onAction})
  async_view.dart          LoadingView /. ErrorView(message)   (terminal branches only)
  section_header.dart      SectionHeader(title)                (+ _SectionHeader migration)
lib/core/theme/app_theme.dart
  + textTheme: meQuranHead/Body, hafsAyah, mutedFootnote styles  (kills A6/A7 duplication at source)
lib/core/l10n/prayer_names.dart
  extension PrayerNameLabel on PrayerName   (kills B2)
```

**Do NOT extract** (would be premature abstraction): `_AyahCard`, `_MushafPager`, `_DialPainter`, `_PackRow`, `_ReciterRow`, `_SurahRow`, `_FeatureTile` bodies — each is feature-specific; they merely reuse the primitives above.

**Standardization guidance:** house constructor pattern (`const`, `super.key`, requireds explicit); required params = data the widget can't infer, optional style params with defaults (`size = 38`, `width = 132`); theme resolved inside (never passed); `ValueChanged<String>` for onChanged, `VoidCallback`/`VoidCallback?` for taps/dismiss; 100% stateless; drop `_` prefixes, PascalCase domain names (`ArabicBadge`, mirroring `MiniPlayerBar` precedent); colors only via `colorScheme` — `app_colors.dart` imported nowhere outside `app_theme.dart` (keep that invariant).

## 4. Prioritized refactoring plan (impact × effort)

| # | Refactor | Files touched | Effort | Impact | Est. |
|---|---|---|---|---|---|
| 1 | `ArabicBadge` extract + reuse (3 sites) | reciters, surah_index, reciter_surahs + new widget | **Low** | High | 1h |
| 2 | `SearchField` unify incl. fixing city_picker styling drift | reciters, surah_index, city_picker | **Low** | High | 1h |
| 3 | `EmptyState` extract | prayer_times, qibla | **Low** | Med | 0.5h |
| 4 | `TextTheme` Arabic styles + `mutedFootnote`; swap ~25 inline styles | app_theme ~25 call sites | **Low-Med** | High | 2h |
| 5 | Replace zakat:19 / tasbih:20 unsafe casts with exhaustive switch | zakat, tasbih | **Low** | High (robustness) | 0.5h |
| 6 | `DownloadProgressLabel` extract | library, reciter_surahs | **Low** | Med | 1h |
| 7 | `ErrorStrip` extract w/ named action slots | library, mini_player, reciters | **Med** | Med-High | 2-3h |
| 8 | `LoadingView`/`ErrorView` + `SectionHeader` extraction; de-RTL boilerplate cleanup | ~16 screens | **Med-High** | Med | 1 day |
| 9 | `PrayerNameLabel` extension | home, prayer_times (+ new core file) | **Low** | Low-Med | 0.5h |
| 10 | `_DuasView`+`_RuqyahView` → one `DuaCard(name, fontFamily, …)` | duas_screen | **Med** | Med | 2h |
| 11 | Move 4 hardcoded strings into `arb`/l10n | reciter_surahs×2, router, reciters | **Low** | Med | 1h |
| 12 | `SurfaceTile` for home/asma grids | home, asma | **Low** | Low (optional; defer unless visual drift appears) | 1h |

**Expected outcomes:** UI consistency (badges/search/error/empty states can no longer diverge), testability (each primitive is trivially widget-testable), maintainability (one place per idiom; new features inherit standardized async/empty/error handling), typography solved exactly once. Net −350-400 LOC.

**Limitations:** read-only session — no runtime/device profiling, no golden tests exist to byte-pin visuals, and the two variants (light/dark) were verified only via theme code, not screenshots.

## PM scope ruling (2026-10-15, for UX-W1)

IN: items 1-7, 9, 10, 11 (+T6 entry-point grant as UX-W1 commit 9). OUT/DEFERRED: item 8's RTL-boilerplate cleanup (EN-locale alignment behavior — not mechanical), item 12 (audit's own defer), golden infra.
