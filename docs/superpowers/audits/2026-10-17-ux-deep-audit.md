# UX Deep Audit — Quran Yahdi (read-only)

Date: 2026-10-17 · Auditor: PM-delegated read-only audit (PROMPT 13) · Repo: `E:\old_flutter\Quran-App-master` · Branch: `main` · HEAD audited: `f7c4869`

## §0 Read-only proof

| Gate | Value |
|---|---|
| HEAD at start | `f7c4869` (matches expected tip) |
| Branch at start / end | `main` / `main` |
| `git status --porcelain` at start | ` M .vscode/settings.json` — **pre-existing as-found** (editor cSpell dict line, diff inspected: only cSpell words added). Not produced by the audit; left untouched. |
| `git status --porcelain` at end | identical porcelain + **one** new untracked path: `docs/superpowers/audits/2026-10-17-ux-deep-audit.md` (this file) |
| `flutter analyze` at start | `No issues found!` (0) |
| `flutter analyze` at end | 0 (re-run, see close of §0) |
| Commits / code / test / dep edits | **0 / 0 / 0 / 0** |
| Build artifacts | `build/app/outputs/flutter-apk/app-release.apk` rebuilt at HEAD (66.4 MB, Gradle cache hit, 28 s). `build/` is git-ignored. |
| Device | Infinix X6882 (`13372704AR007777`) was **attached and healthy at session start** (`adb devices` → `device`), then disconnected from USB before the first capture. Owner ruling: **"Proceed without device."** |
| Device settings touched / restored | **None.** No `settings put`, no `cmd uimode`, no `font_scale` was ever applied (only `wm size`/`wm density` reads and getprops — all as-found). Table of before/after = one row: nothing changed. |
| Screenshots | None exist; `build/ux_audit/` was never created. **No visual claim in this report is screenshot-backed.** |

Method: three parallel read-only research passes covered every file in the brief (~120 Dart files): (A) router/app/theme/l10n + quran + library; (B) prayer + recitation + notifications + l10n/ARB; (C) home/settings + the nine secondary screens + DI. High-severity claims were then re-verified by hand at source (§1 cites `file:line` for every item; the ones marked ✅ verified were re-read line-by-line by the auditor). No production endpoint was probed.

---

## §1 Per-screen findings

Severity: **P1** breaks core use / crash-class on a reachable path · **P2** clear UX or consistency miss · **P3** polish. `capture:` column: `N/A — no device session` for every row this audit.

### 1.1 Home

| Sev | Finding | Evidence |
|---|---|---|
| P2 | No error branch: `HomeState` has only loading/ready; `HomeCubit.reload()` is `unawaited` and unguarded — a repository throw leaves an infinite `LoadingView` | `lib/features/home/presentation/home_state.dart:11-18`, `home_cubit.dart:30-38`, `home_screen.dart:23-24` |
| P3 | New users see neither the last-read card nor the next-prayer card and get no hint to pick a city; both banners silently absent with empty prefs | `home_cubit.dart:40-59` |
| P3 | Mixed-script subtitle built inline: `﴿N﴾ متابعة القراءة` (ornate brackets + Arabic-Indic digits hardcoded, not ARB) | `home_screen.dart:37` |
| Pass | Grid: 13/13 tiles → existing routes; all labels l10n'd; zero orphan routes; tiles ≈101×106 dp; labels wrap `maxLines:2` | `home_screen.dart:90-104`, `router.dart:69-271` |

### 1.2 Surah index (`/quran`)

| Sev | Finding | Evidence |
|---|---|---|
| P1 | `watchAll().listen(...)` has no `onError` — a DB stream error is unhandled and **the `SurahIndexError` UI branch is dead code** (cubit never emits it); user stranded on last state ✅ verified | `surah_index_cubit.dart:11-14` (grep shows `listen` with no onError), dead branch `surah_index_screen.dart:26` |
| P2 | Empty DB / no-search-hit renders a bare 0-item `ListView` — no "no results", no clear-affordance (the ready-made `EmptyState` primitive is never used anywhere in the app) | `surah_index_screen.dart:36-41`; `empty_state.dart:3-25` (grep: 0 external usages) |
| P3 | `Icons.chevron_left` hardcoded (non-adaptive); correct under pinned-AR, wrong once EN exists | `surah_index_screen.dart:76` vs `app.dart:18-19` |

### 1.3 Reader + mushaf (`/quran/reader`)

| Sev | Finding | Evidence |
|---|---|---|
| P1 | **Mushaf content is misleading**: pages are surah-scoped quarter-pages ("v1" per the model's own docstring) while the footer claims `صفحة N` — columns of other surahs sharing the physical page are silently missing | `mushaf_page_block.dart:3-5,13-26`; rendering `reader_screen.dart:249-251`; label `:270-276` |
| P2 | Invalid params (`?surah=999`) never error: router `int.tryParse` fallback + cubit emits `ready` with empty ayahs → fully blank screen, no "not found" | `router.dart:220-222`; `reader_cubit.dart:45-53` |
| P2 | Error state is a dead end: `ErrorView(message)` has no retry, error `AppBar()` untitled; mushaf-empty path is a silent `SizedBox.shrink()` | `reader_screen.dart:25-28,240-242`; primitive `async_view.dart:12-21` |
| P3 | Two different Hafs metrics: theme `hafsAyah` (24 px / lh 2.0) vs inline mushaf style (22 px / lh 2.2) — numbers never reconciled | `app_theme.dart:15-16` vs `reader_screen.dart:260-264` |
| P3 | Basmala planted above content in **both** modes → can double with page-1 data in mushaf mode; swipe-only page turns (no tap zones); bookmark toggle gives no feedback (no snackbar/anim) | `reader_screen.dart:71-83,243-247,186-193` |
| Pass (font) | Uthmani body = bundled HafsSmart + me_quran; no `Cairo` substitution on Quran text; RTL is explicit and correct on ayah rows | `pubspec.yaml:70-76`; `reader_screen.dart:152,158,161` |

### 1.4 Ayah/tafsir sheet

| Sev | Finding | Evidence |
|---|---|---|
| P1 | `AyahSheetCubit._load` has no try/catch and the state has **no error variant** — any throw from `installedPacks()`/`tafsirFor()` leaves the sheet on an eternal inline spinner (dismiss only by scrapping the sheet; no message) | `ayah_sheet_cubit.dart:28-52`; `ayah_sheet_state.dart:9-15`; `library_sheet.dart:56-58` |
| P3 | Inline spinner + hand-rolled empty pane reinvent `LoadingView`/`EmptyState`; no drag handle; header hardcodes ornate brackets `﴿N﴾` | `library_sheet.dart:56-58,128-148,75-83` |

### 1.5 Bookmarks (`/bookmarks`)

| Sev | Finding | Evidence |
|---|---|---|
| P2 | Delete `IconButton` has **no tooltip** (of 22 IconButtons app-wide, 7 lack labels — this is the worst, an irreversible action); hand-rolled empty text reinvents `EmptyState` (which supports a CTA straight into the reader) | `bookmarks_screen.dart:47-51,27-30` |
| P3 | Snippet hard-cut at 60 chars + literal `…` can split an Arabic combining mark mid-shaping (should be `maxLines`/ellipsis) | `bookmarks_screen.dart:35-37` |
| P3 | Reference `N:M` mixes Arabic-Indic digits with Latin colon inside an RTL row without explicit `textDirection` (bidi-order risk) | `bookmarks_screen.dart:39-42` |

### 1.6 Prayer times (`/prayer-times`)

| Sev | Finding | Evidence |
|---|---|---|
| P2 | **No PullToRefresh and no AppBar action** (`ListView.builder`, empty appbar) — the only in-place refresh is the (W7a-fixed) city-picker return path; drift >1 h has no recovery short of re-picking a city | `prayer_times_screen.dart:16-24,30,63`; contrast `reciters_screen.dart:28-33` |
| P2 | Countdown computed once per `reload()` — no ticker; "متبقٍ ١٢:٣٤" goes stale while the screen sits open ✅ verified structurally | `prayer_times_cubit.dart:38-58,23 (unawaited reload)` |
| P3 | After Isha passes, `isNext` still highlights today's already-passed Fajr (next is tomorrow's Fajr but matched by today's name) | `prayer_times_cubit.dart:44-46`; `prayer_time_service.dart:50-53` |
| Pass | Refresh-in-place via awaited picker return confirmed in code (W7a regression check ✓); loading/empty-no-city states present and localized; Arabic-Indic times via central `toArabicIndicDigits` | `prayer_times_screen.dart:33-46,104,114`; `arabic_numbers.dart:39-49` |

### 1.7 City picker (`/prayer-times/city`)

| Sev | Finding | Evidence |
|---|---|---|
| P2 | **No selected-city indicator** — no check/highlight/pre-scroll to the persisted city; re-tapping the current city re-saves and pops as if new | `city_picker_screen.dart:49-67` (nothing reads `selectedCityJson`) |
| P2 | Zero search hits = blank list (no empty state); `search()` uncached/undekeybounced, no hamza/alef normalization | `city_picker_screen.dart:49-67`; `city_picker_cubit.dart:20-24`; `city_repository.dart:64-65` |
| P3 | Trailing city id renders western digits inside AR UI; locate-failure falls back to generic snackbar (no settings deep link) | `city_picker_screen.dart:56,84-89` |

### 1.8 Reciters (`/recitation`)

| Sev | Finding | Evidence |
|---|---|---|
| P2 | Raw exception text leaks to users: soft-fail banner shows `$e` (e.g. `StateError: mp3quran HTTP 502`) ᢒ in an AR-first app | `reciters_cubit.dart:36` → `reciters_screen.dart:41-47` |
| Pass | Loading/error/ready all exist; offline banner uses shared `ErrorStrip` (dismissible, tooltip); refresh tooltip'd; search-empty localized; Arabic-Indic surah counts | `reciters_screen.dart:36-62,28-33,56-58,131-134` |

### 1.9 Reciter surahs (`/recitation/reciter`)

| Sev | Finding | Evidence |
|---|---|---|
| P2 | **Downloads have no cancel path** (`DownloadsCubit` has no cancel API; trailing widget is a non-interactive label) and **no delete UI** (`AudioDownloader.removeDownload` has zero UI callers) — storage fills invisibly | `downloads_cubit.dart:24-87`; `reciter_surahs_screen.dart:179-187`; `audio_downloader.dart:131-141` (unreferenced) |
| P2 | Errors surface English snippets: hardcoded `'reciter row not found'` state + raw `$e` in `ErrorView` | `reciter_surahs_cubit.dart:30,45-47` → `reciter_surahs_screen.dart:60` |
| P3 | Progress label is raw byte math `received/total` (no MB format, no Arabic digits; `total==0` → `12345/0` + indeterminate bar); queued items render nothing until active; default-download IconButton & retry tooltip unbranded (borrowed framework string) | `download_progress.dart:29-37`; `reciter_surahs_screen.dart:179-200,189-195` |
| Pass | Per-surah play respects the reciter's own surah list; failure → file deleted + red retry icon; default-reciter snackbar localized ✅ | `reciter_surahs_screen.dart:147-159,91-96` |

### 1.10 Mini player

| Sev | Finding | Evidence |
|---|---|---|
| P2 | Player bar is mounted **only** on `/quran/reader` and `/recitation/reciter` — navigating up to reciters/home leaves playback running with **no stop/control affordance anywhere on screen** (single-audio app, the strip is the only stop) | `reciter_surahs_screen.dart:84`; `reader_screen.dart:89` (no other mount points) |
| P3 | During buffering the 44 px busy slot replaces the stop button — a hung load cannot be stopped until it fails; `Icons.close` used as "stop" glyph; dual stop wording `إيقاف` (tooltip) vs `وقف` (dismiss) | `mini_player_bar.dart:119-130,138-139,162` |
| P3 | Reader-triggered playback failure shows the reciters-index empty copy ("حمّل فهرس القرّاء…") instead of playback wording | `playback_cubit.dart:71-75` → `mini_player_bar.dart:159-161` |
| Verified | **W7b stop-wording debt is closed in code** ✅: stop tooltip = `loc.stopTooltip` (`إيقاف`), failed-strip dismiss = W7b key `loc.stopAction` (`وقف`) | `mini_player_bar.dart:138,162`; ARB keys `app_localizations_ar.dart:137,372` |

### 1.11 Background audio (system surface)

| Sev | Finding | Evidence |
|---|---|---|
| P2 | If `just_audio_background` init fails at boot, it silently degrades to foreground-only audio and the later failure is mislabeled `network` ("تعذّر تشغيل التلاوة") — user gets no truthful signal that background audio is gone | `background_init_guard.dart:14-18,28-37`; `playback_cubit.dart:59-62` (mapped to `PlaybackFailureKind.network`) |
| P3 | `stop()` never clears the foreground media session — ongoing notification can linger ("paused") after the mini player is dismissed | `just_audio_playback_service.dart:58`; `playback_cubit.dart:105-110`; `main.dart:29` |
| Pass | Init is guarded at boot (can't crash startup); streams rebound `??=` per episode and unbound on stop; downloaded file preferred over network (offline playback works) | `main.dart:24-31`; `playback_cubit.dart:38-50,112-145` |

### 1.12 Library (`/library`) + Hadith (`/library/hadith`)

| Sev | Finding | Evidence |
|---|---|---|
| P1 | **Hadith screen can hang forever**: `HadithState` has only loading/ready and `_load` is unguarded — a missing/corrupt/deleted pack = eternal spinner; an unknown `pack` param lands on a silent blank page with no CTA back to `/library` | `hadith_cubit.dart:22-37,24-26 (row==null silent)`; `hadith_state.dart:9-18`; `hadith_screen.dart:44-46` |
| P2 | `LibraryState` has **no error variant at all** (catalog parse failures are silently swallowed) and empty tabs render bare lists with no install hint | `library_state.dart:8-18`; `library_catalog.dart:132-139`; `library_screen.dart:97-103` |
| P3 | Trailing `Row` (label + read + delete `IconButton`s at 8 px gap) can overflow the `ListTile.trailing` width on narrow screens (unbounded `mainAxisSize.min`, no `Flexible`) | `library_screen.dart:150-167` |
| P3 | `' MB'` units hardcoded with Arabic-Indic digits in the same string — bidi flips possible (`MB 12 / 43` visually) | `library_screen.dart:128-129`; `download_progress.dart:29-32` |
| Pass | Delete confirmation dialog present; install-fail strip = shared `ErrorStrip` with localized title + retry; bilingual hadith rows branch `textDirection` on pack language (only legit LTR branching in the app) | `library_screen.dart:70-81,177-199`; `hadith_screen.dart:55,64-65,83-84` |

### 1.13 Azkar (`/azkar`)

| Sev | Finding | Evidence |
|---|---|---|
| P2 | `AzkarCubit.load()` unguarded → infinite spinner on a loader crash; empty collections render a blank body (no empty branch) | `azkar_cubit.dart:16-20`; `azkar_screen.dart:43-71` |
| P3 | Custom `leading` back icon = `Icons.arrow_back` with **no tooltip** and no auto-mirroring guarantee; no haptics on tap/complete (tracker/tasbih have them); stray one-line `onTap:` collapse at `:101` | `azkar_screen.dart:28-37,99-101` |
| Pass | Reciting list: whole-card tap target, done-state dim + count badge def clamp, appbar title/state swap pattern is clean | `azkar_screen.dart:95-124`; `azkar_cubit.dart:32-44` |

### 1.14 Tasbih (`/tasbih`)

| Sev | Finding | Evidence |
|---|---|---|
| P2 | Overshoot confusion: tapping *past* the target flips the check icon back to `touch_app` and un-pulses while the count keeps climbing — no lock/snap at target | `tasbih_cubit.dart:35-48`; `tasbih_screen.dart:33-36,51-56` |
| P3 | Target `ChoiceChip`s ≈32 dp tall (sub-48); picking a target silently resets the count; "done" copy reuses the azkar key `azkarDone`; dial has tap haptics but no press-down feedback | `tasbih_screen.dart:81-92,101-105`; `tasbih_cubit.dart:58-62` |
| Pass | 220×220 dp counter — best touch target in the app; `HapticFeedback.selectionClick` wired | `tasbih_screen.dart:27-39` |

### 1.15 Worship tracker (`/worship`)

| Sev | Finding | Evidence |
|---|---|---|
| P2 | No error state (`TrackerCubit.reload` unguarded) — same systemic class | `tracker_state.dart:7-16`; `tracker_cubit.dart:27-42` |
| P3 | Last-7 dots are 14 px decorative icons with **no semantics** (screen-reader users can't interpret) ; no way to correct a missed yesterday; date hand-formatted `y/m/d` | `tracker_screen.dart:86-93,33` |
| Pass | Five slots full-width ListTiles + haptic on toggle; persists-then-reloads is acceptable on this cadence | `tracker_screen.dart:53-70` |

### 1.16 Zakat (`/zakat`)

| Sev | Finding | Evidence |
|---|---|---|
| P1 | **Wrong religious verdict by default** ✅ verified line-by-line: `nisabBySilver` defaults `true` while silver price defaults empty → `nisab == 0` → `due = zakatable > 0 && zakatable >= nisab` is *true for any positive input* → first-run user enters any cash amount and immediately gets "الزكاة واجبة" + a computed amount | `zakat_state.dart:10` (`@Default(true)`), `zakat_calculator.dart:3-19 (parseDecimal('')==0),68-71`, surfaced `zakat_screen.dart:63-84` |
| P2 | Inputs have no `inputFormatters`/`errorText` — Arabic-Indic digits (٠-٩) typed on an AR keyboard are silently parsed to 0 | `zakat_screen.dart:138-143`; `zakat_calculator.dart:18` |
| P3 | Due amount carries **no currency label**; single-variant state cast (no loading/error) | `zakat_screen.dart:74-84,20-22; zakat_state.dart:8-25` |

### 1.17 Qibla (`/qibla`)

| Sev | Finding | Evidence |
|---|---|---|
| P2 | Dead/absent magnetometer is completely silent: heading-stream errors are double-swallowed (service + cubit) and static mode shows no hint — only a "live" footnote that renders when `heading != null` | `heading_service.dart:30-36`; `qibla_cubit.dart:44-47`; `qibla_screen.dart:81-89` |
| P3 | No calibration/inaccuracy hint at all (raw magnetometer, no accuracy events) | `heading_service.dart:7-12` |
| Pass | Missing city/bearing empty state is exemplary (`noCity` + CTA into city picker); dial animation 180 ms; bearing in Arabic-Indic | `qibla_screen.dart:31-45,60-99` |

### 1.18 Hijri (`/hijri`)

| Sev | Finding | Evidence |
|---|---|---|
| P2 | No error state; `show()` recomputes cells synchronously per navigation, unguarded | `hijri_cubit.dart:18-47`; `hijri_state.dart:17-29` |
| P3 | **No weekday header row** over the Saturday-first grid (users infer alignment); Gregorian sub-digit at 9 px; chevrons non-adaptive | `hijri_screen.dart:68-111` (no header build), `:44,63` |
| Pass | The only tooltip'd month-nav IconButtons in the audited set (`today` at `:57-58`); grid non-lazy but ≤30 cells — fine | `hijri_screen.dart:40-67` |

### 1.19 Asma ul-Husna (`/asma`)

| Sev | Finding | Evidence |
|---|---|---|
| P2 | Detail surface is a `Stack` overlay, **not dismissible** — no scrim, no gesture; tapping behind swaps selection instead of closing (feels broken); clear-selection IconButton unlabeled | `asma_screen.dart:83,124-127` |
| P3 | `nameEn` hard-ellipsized to one line; 7 inline `TextStyle`s (worst file in the app) | `asma_screen.dart:66-74,51-166` |
| Pass | 99 items in lazy `GridView.builder` (~104×113 dp targets) | `asma_screen.dart:25-33` |

### 1.20 Duas / Ruqyah (`/duas`)

| Sev | Finding | Evidence |
|---|---|---|
| P2 | No empty/filtered-out state (unmatched category = blank list); category chips ≈32 dp sub-48 | `duas_screen.dart:101-117,86-97` |
| P3 | Ruqyah range resolves N+1 DB queries on **every** tab switch; hardcoded `×` repetition marker | `duas_cubit.dart:36-84`; `duas_screen.dart:207` |
| Pass | Loading state present; flat two-tab navigation is good depth-wise | `duas_screen.dart:27-48,55` |

### 1.21 Settings (`/settings`)

| Sev | Finding | Evidence |
|---|---|---|
| P2 | Reminder-note mismatch: the screen says "الوضع الليلي واللغة من إعدادات جهازك" — dark mode does follow the system, **but language is pinned to Arabic in code, so the note is factually false today** (EN ARB is dead: 111/111 keys unreachable) ✅ verified | `settings_screen.dart:62-68` + ARB `settingsMinimalNote`; `app.dart:17-19` |
| P2 | Permission-denied hint is a static colored `Text` — not tappable, no `openAppSettings`, no re-request affordance | `settings_screen.dart:51-60`; `settings_cubit.dart:42-47` |
| P2 | Zero save/error feedback: no SnackBar anywhere in settings; scheduling failure silent (no error variant in `SettingsState`) | `settings_cubit.dart:57-73`; `settings_state.dart:8-15`; grep: SnackBar only in `reciter_surahs_screen.dart:91` and `city_picker_screen.dart:83` |
| P3 | Time picker is the platform dialog (western digits) while the row displays Arabic-Indic; reminder-time row disables with no inline reason | `settings_screen.dart:40-41,76-89,36-49` |
| Verified | **T6 default-reciter snackbar debt is closed in code** ✅ — `defaultReciterSet` ARB key consumed; original debt trail = campaign ledger deviation 8 | `reciter_surahs_screen.dart:91-96`; `docs/campaign-ledger.md:32` |

### 1.22 Notifications (system surface)

| Sev | Finding | Evidence |
|---|---|---|
| P2 | **Tap-to-open is unimplemented**: `initialize(...)` carries no `onDidReceiveNotificationResponse`/payload routing (grep: 0 hits repo-wide) — every tap cold-launches to `/home` with no target context ✅ verified | `notifications_binding.dart:49-53`; `router.dart:66-67` |
| P2 | **Android 13 permission is never requested at boot** — `POST_NOTIFICATIONS` is requested only when the user toggles the *azkar* reminder; prayer reminders (independent of that toggle) can be silently dropped on a fresh install | `main.dart:32-33` (boot: `init`+schedule only); request lives at `settings_cubit.dart:44-47`; channel `defaultIcon = '@mipmap/ic_launcher'` (colored mip, not monochrome — grey blob on status bar) `notifications_binding.dart:36-37` |
| P3 | Both reminder types set `body: title` (shade shows the sentence twice); channel description hardcodes `أذكار الصباح` for the shared prayer+azkar channel; exact-alarm denial invisible (capability check exists, flag respected — good) | `reminder_planner.dart:52-53`; `notifications_binding.dart:54-61,89-94,106-108` |
| Pass | Scheduling model is coherent: next-prayer-only today (sunrise skipped), azkar daily at settings time with roll-to-tomorrow; replans on toggle/time/city/screen-load/boot ✅ regressed-verified in code | `reminder_planner.dart:44-70`; `settings_cubit.dart:42-73`; `prayer_times_cubit.dart:59-74`; `bootstrap.dart:62-70` |

### 1.23 Global surfaces (router / theme / l10n / a11y)

| Sev | Finding | Evidence |
|---|---|---|
| P1 | **Systemic missing-error-state class**: 10 screens (home, settings, azkar, tasbih, zakat, qibla, hijri, asma, duas, library) have no error branch and unguarded `unawaited` cubit loads; ayah-sheet + hadith additionally have no error *variant* at all → any data-layer throw = infinite spinner (this is the monster under the bed; each instance can strand a screen behind the spinner) | §6.1 table of the research pass; spot-verified: `surah_index_cubit.dart:11`, `ayah_sheet_state.dart:9-15`, `hadith_state.dart:9-18` |
| P2 | **`Cairo` is set as the global UI font but is not bundled** — `QuranFonts.ui = 'Cairo'` drives `fontFamily` app-wide while pubspec ships only HafsSmart + me_quran → every non-Quran label silently renders in the platform fallback (Roboto/Noto); the intended brand typeface never loads ✅ verified | `app_theme.dart:8,43`; `pubspec.yaml:69-76` |
| P2 | **Gold `#E3A53E` as text on light surfaces ≈ 2:1** (fails WCAG AA even large-text): basmala, ayah-number glyphs, mushaf page indicator, "installed" 12 px label, hadith lang chip (~1.8:1 on beige appbar). Dark mode is fine (~6:1) — light mode is the outlier | `app_colors.dart:9`; `reader_screen.dart:79,163-170,270-276`; `library_screen.dart:154-157`; `hadith_screen.dart:30-35` |
| P2 | No `errorBuilder`/404 in `GoRouter` — unknown route renders Flutter's default **English** "Page Not Found" in a pinned-Arabic app; `placeholder_screen.dart` is dead code wired to nothing | `router.dart:66-273`; `placeholder_screen.dart:3-19` (grep: 0 external usages) |
| P2 | `ErrorView` primitive has no retry slot → its 5 call sites (reader/bookmarks/index/reciters/reciter-surahs) are all dead-ends; `EmptyState` primitive entirely unused while 3 screens hand-roll worse ones | `async_view.dart:12-21`; `empty_state.dart:3-25`; straggler list in §2 |
| P2 | A11y labeling: `semanticsLabel` count in `lib/` = **0** (grep); **7 unlabeled IconButtons**: bookmarks-delete `bookmarks_screen.dart:47-51`, hijri prev/next `hijri_screen.dart:43-46,62-65`, asma clear `asma_screen.dart:124-127`, azkar back `azkar_screen.dart:28-37`, prayer edit-city `prayer_times_screen.dart:78-81`, reciter download `reciter_surahs_screen.dart:197-200` | grep-verified |
| P3 | l10n parity is perfect (111 keys / 111 — scripted key-diff AR↔EN identical), so the drift risk is one-way: raw strings *outside* ARBs — 14 entries catalogued in §2 idiom 3 (channel/media-notification app names, ` MB` units, decorative `﴿N﴾` family, basmala constant) | `app_localizations_ar/en.dart` line-diff |
| P3 | 36 inline pixel `TextStyle`s across 11 screens bypass `textTheme` (asma 7, azkar/tracker/zakat 4 each …) — type-scale changes require 30+ edits | per-file counts in research pass C §6.4 |
| P3 | `mutedFootnote` = 11 px `onSurfaceVariant` ≈ 3.7:1 on beige (below AA small-text) used on mini-player subtitle, asma subtitle, downloader label; `SearchField` fill = 8 % alpha, borderless — reads as floating text; `ArabicBadge` 12 % fill faint in light mode | `app_theme.dart:18-21`; `search_field.dart:21-31`; `ar_badge.dart:24-28` |
| P3 | Sub-48 dp touch targets: tasbih target chips `tasbih_screen.dart:84-90`, duas category chips `duas_screen.dart:86-97` — **everything else in the app passes** (home 101 dp tiles, 220 dp counter, 48 dp default IconButtons, full-width ListTiles) | grep/line-verified |
| P3 | Router constructs fresh cubits for 7 features that *are* registered in DI (dead registrations — harmless today, drifting bisection tomorrow) | `injector.dart:75-136` vs `router.dart:151-202` |
| P3 | Hidden features: `/bookmarks` reachable only from inside the reader appbar; no deep-link scheme in manifest (VIEW intent absent) | `reader_screen.dart:65`; `AndroidManifest.xml` (MAIN/LAUNCHER + audio-service intents only) |
| Pass (RTL) | RTL is in good shape: `TextDirection.ltr` appears exactly twice, both conditional for non-Arabic hadith packs; no `OverflowBox`/`overflow:` misuse; chevrons correct under pinned-AR (only brittle if EN ships) | hadith `:65,84`; grep 0 others |

### 1.24 Regression sweep (W0→W7b, code-trace level)

| Claim from the campaign | Verdict (static trace) |
|---|---|
| Prayer refresh-in-place (W7a) | ✅ intact — awaited picker return → `cubit.reload()` `prayer_times_screen.dart:16-24,78-81` |
| Offline-first reciters with soft-fail banner | ✅ intact (banner leaks raw `$e` — new P2 polish issue above) |
| Mini-player stop wording (W7b debt) | ✅ closed in code (`loc.stopTooltip`/`loc.stopAction`); residual dual-wording `إيقاف`/`وقف` |
| T6 default-reciter snackbar i18n debt | ✅ closed (`defaultReciterSet`) |
| Background audio survives HOME; `just_audio_background` init can't crash boot | ✅ logically intact (`BackgroundInitGuard`), but silent-degradation path exists (P2 above) |
| Downloads: enqueue → progress → retry, file preferred when offline | ✅ intact; cancel/delete never shipped (P2 above) |
| Empty/error/loading states on *every* async surface | ❌ **regression-shaped gap**: holds only for reciters/reciter-surahs/library-strip/bookmarks/index*; the other 10 surfaces never grew error states (P1 systemic) |
| Notification reminder chain toggle→plan→schedule | ✅ intact; runtime permission + tap-routing absent (P2 above) |
| l10n key parity + Arabic-Indic digit discipline | ✅ parity 111/111; discipline mostly held (exceptions: download bytes, city id, time picker widget) |

---

## §2 Cross-screen idioms (ranked by count × severity)

1. **Missing/unreachable error states** — 12 surfaces (10 screens + 2 sheets) · P1 systemic. One shared fix: an `AsyncGuard`/`runCatching` cubit mixin + error variants; `ErrorView(onRetry)`.
2. **Dead-end primitives** — `EmptyState` 0 usages; `ErrorView` no retry; 5 screens, plus a11y-unlabeled destructive delete · P2.
3. **Raw-string / wording drift** — 14 catalogued entries: media-notification (`قرآن يَهدي`), `'reciter row not found'`, `$e` banners (×3), ` MB` (×2), decorative `﴿N﴾` (×5), basmala constant, `أذكار الصباح` channel desc; plus إيقاف-vs-وقف stop split · P2/P3 mixed.
4. **Contrast & typography discipline** — gold-on-light 2:1 (5 surfaces), 11 px footnotes 3.7:1, 8–12 % alpha containers, 36 inline text styles, **Cairo declared but never bundled** · P2/P3.
5. **Truncated flows** — no cancel/delete on downloads, no tap-to-open notifications, mini player stranded off two screens, permission hint non-tappable · P2.
6. **A11y labeling** — 0 `semanticsLabel`; 7 unlabeled IconButtons; decorative tracker dots/chips without semantics; verse-number glyphs unannounced · P2/P3.
7. **Input/format consistency** — Arabic-Indic vs western split across download label, city id, time-picker dialog; no inputFormatters in zakat; hard-cut bookmark snippet · P3.
8. **Touch targets** — only ChoiceChips (2 screens) violate 48 dp; app otherwise passes · P3.

---

## §3 Flows walked (static code trace — device was lost before capture; every step is a code-level pass)

| # | Flow | Step outcomes | Verdict |
|---|---|---|---|
| 1 | index→reader→tafsir sheet | `/quran` lists surahs (stream ✓) → tap opens `/quran/reader?surah` (router ✓) → sheet sheet opens with tabs ✓ → **sheet `_load` unguarded: a DB throw = eternal spinner** ✖; bookmark toggle silent (no feedback) ✖ | Fail-with-caveats |
| 2 | index→reader→bookmark→mushaf mode | Bookmark persists via stream (✓ reload reflects); mushaf renders surah-scoped pages labeled `صفحة N` with other-surah columns missing ✖; swipe-only turns, repeat-basmala risk | Fail-with-caveats |
| 3 | reciters→surahs→download (cached)→mini player→HOME | List guarded by ErrorStrip ✓ → drain queue serial ✓ → progress label raw bytes (~ok) → playback with downloaded file preferred ✓ → **HOME: player controls vanish; no stop affordance** ✖; media notification continues (feature ✓ actually) but notification icon = launcher mip ✖ | Fail-at-last-step |
| 4 | prayer→city (+location) | CTA + edit affordances exist ✓ → picker search/re-list ✓ → locate failure → generic snackbar (usable) ✓ → return → refresh-in-place ✓; **no selected-city indicator** ✖ | Pass-with-caveats |
| 5 | settings→azkar reminder fires | toggle → `ensurePermissions` ✓ → schedule today/tomorrow ✓ → replans on change ✓ → **if user never opens Settings, prayer reminders ship with no Android-13 permission prompt ever** ✖ | Conditional-pass |
| 6 | notifications tap-opens-app | fire ✓ (zonedSchedule, AR payloads) → tap: **no callback, no payload routing — lands cold on `/home`** ✖ (documented W7b non-goal; still the most-missed v1 flow) | Fail (known) |
| 7 | settings→dark mode / language | themeMode.system ✓ genuine; language switch **does not exist** and the there-note claims it follows the device ✖ (pinned AR) | Fail (copy) |
| 8 | zakat wizard empty-skills first-run | any cash > 0 → "due" with nisab 0 ✖ | Fail (P1) |

---

## §4 Top-10 prioritized fixes (impact × effort, 3 candidate waves)

| # | Fix | Impact | Effort | Wave |
|---|---|---|---|---|
| 1 | Zakat nisab guard: when `nisab == 0` (prices blank) render a "أدخل أسعار الذهب/الفضة" prompt instead of `due`; add gold/silver is default off | Very high (wrong religious verdict) | XS | **A** |
| 2 | Systemic error-state wave: `runCatching` cubit guard + error variants for ayah-sheet/hadith/library + `onError` on `surah_index` stream + `ErrorView(onRetry)` slot | Very high (10 screens unrusted under failure) | M | **A** |
| 3 | Bundle Cairo (or drop the `Cairo` declaration) — one `pubspec` entry or one `app_theme` line decides which | High (brand typeface / whole-UI look) | XS | **A** |
| 4 | Request notification permission at boot (once, gentle), monochrome status-bar icon, tap-to-open payload→route map (prayer→`/prayer-times`, azkar→`/azkar`) | High (silent reminder drop; dead-intent UX) | M | **B** |
| 5 | Mini player persistence: bottomSheet at router-shell level (or on `/recitation`+`/quran` too) so controls (incl. stop) are always reachable | High (background playback unusable one level up) | M | **B** |
| 6 | Gold-on-light contrast pass: darken `AppColors.gold` for text on light (dark keeps it), bump `mutedFootnote` to 12 px | High (most-read elements fail AA) | XS | **B** |
| 7 | Downloads: cancel affordance + "delete reciter" wired to existing `removeDownload`; progress label `MB` + Arabic-Indic | Med-high (storage + trust) | S/M | **B** |
| 8 | Settings honesty + affordance: correct the language note (or wire `Locale.system`), tappable open-settings hint, one save-Snackbar | Med (trust; 2-line copy fix otherwise) | XS/S | **C** |
| 9 | EmptyState adoption + city-picker selected indicator + 0-result search message; label the 7 IconButtons (delete first) | Med | S | **C** |
| 10 | Wording drift clean-up: raw exceptions→localized copy, unify إيقاف/وقف, ARB-ify ` MB`, media-notification titles | Medium (polish) | S | **C** |

Wave A ≈ 3 PRs ("failure-safety sprint"), Wave B ≈ integrations, Wave C ≈ polish sweep.

---

## §5 Limitations

1. **No device evidence this session.** The audit device (Infinix X6882 / `13372704AR007777`) was confirmed attached at start but disconnected before the first capture; the owner ruled "proceed without device". Consequently: **zero screenshots**, no `build/ux_audit/` artifacts, and no visual claim anywhere in this report is screenshot-backed. Every finding above is *code-traced*; reproduction effort is narrow because all are `file:line`-cited.
2. **Tofu/font rendering, true mushaf darkness, status-bar icon look, notification shade wording, tap-target feel, TalkBack behavior, transition smoothness — all unverified visually.** The mushaf/Hafs findings are font-asset/declaration-level (`pubspec.yaml:70-76`), not measured rendering.
3. Contrast numbers are **computed** from hex pairs, not measured on the panel.
4. English runtime could not be audited even in principle on-device: locale is pinned in code (`app.dart:18`) — flipping it *is itself* the P2 finding; a `--dart-define` language switch would require a code change, which this read-only audit couldn't make.
5. Flows were walked as a static trace; timing-dependent behaviors (countdown staleness, background-audio survival across actual HOME presses, notification fire timing) are verified structurally in code but not on a live device.
6. `build/` was rebuilt (release APK at HEAD) for future device passes — repo-cleanliness unaffected (`build/` git-ignored); no device setting was ever altered.

---

READ-ONLY COMPLETE — zero commits — awaiting PM triage.

---

## PM TRIAGE (2026-10-17) — every headline P1 re-verified at source before acceptance
- **REFUTED**: P1 zakat first-run due. zakat_state.dart default is due:false and zakat_calculator guards due = zakatable > 0 AND >= nisabValue (verified lines). No code change needed; the audit's line cites were right but the read of the guard was wrong.
- **CONFIRMED**: ayah_sheet_cubit + hadith_cubit load paths have ZERO try/catch → uncaught future errors, state never leaves loading (grep + line reads). This is the sharpest true P1.
- **CONFIRMED**: surah_index_cubit.listen has no onError — the error variant is dead code (line 11).
- **REGRADED P1→P2**: mushaf surah-scoped pages labeled as global page indicator (reader_screen.dart:271). Misleading semantics, not a failure; fix = label with the real mushaf page column of the block's first ayah, guarded against frozen-test pin changes (STOP-or-grant rule).
- Systemic 10-screens-no-error-state: regraded to a per-screen triage in Wave B/C (a screen without a real failure source does not need a decorative error state — blanket sweeps rejected).
- WAVE GROUPING RATIFIED with corrections: Wave A (failure-safety) = the three confirmed items only. Wave B = integrations (notification boot permission + tap-to-open, Cairo font decision, download cancel/delete, language-note truth fix). Wave C = polish (contrast, semantics labels, EmptyState wiring, 404, mini-player coverage).
- LESSON RECORDED: audit findings are DIRECTIONAL, not numerically authoritative — every accepted fix wave item re-verified at source first (this triage refuted 1 of 6 headline P1s).
---

## PM TRIAGE B (2026-10-17) — pre-Wave-C source re-verification
- Line-based grep CANNOT count IconButton tooltips (params are multi-line; 23 sites showed 0 line-attached tooltips which is a MEASUREMENT artifact). Wave C item 2 mandates a multi-line-aware census BEFORE migration, and the real number is recorded in the report.
- 404/unknown-route handling: confirmed ABSENT (no errorBuilder/onException in router.dart) — blank/untranslated default error ships today.
- Gold-as-text contrast: gold is the scheme secondary (app_theme.dart:33); fix = a compliant TEXT tone per-mode (v1 ruling: light mode gets a darkened gold text tone at >=4.5:1; dark mode keeps the existing lighter gold if >=4.5:1 there — ratios COMPUTED and printed in the report, pure-Dart WCAG helper + test).
- OUT of Wave C (unchanged): RTL boilerplate (device-gated), global mini player (shell decision W7c), zakat (refuted), mushaf (closed).