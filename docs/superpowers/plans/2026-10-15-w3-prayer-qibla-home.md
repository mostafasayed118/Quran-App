# Quran Yahdi — Wave 3 (Prayer Times + Qibla + Home) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Offline-first prayer times (local astronomical calculation for the user's selected city), a qibla-direction screen (bearing + static-oriented arrow; live compass = W7), and the real home screen (next-prayer card, continue-reading card, features grid) replacing the three W0 placeholder routes.

**Architecture:** `PrayerTimeService` (pure Dart wrapper over `adhan`) + `QiblaService` (pure Dart bearing) + `CityRepository` (bundled cities asset + settings-table selection) → `PrayerTimesCubit` / `QiblaCubit` / `CityPickerCubit` / `HomeCubit` → three real screens + one picker screen. NO schema change (settings key `selected_city` holds `{nameAr,nameEn,lat,lng}` JSON) → **zero frozen-test grants expected**.

**Tech Stack:** W2b stack + exactly ONE new package: `adhan` (latest stable; pure-Dart Dart port of Batoul Apps Adhan — prayers + qibla, VM-testable). PM decision (locked): **egyptian** calculation method as v1 default (Egyptian General Authority of Survey, Shafi madhab); method switching deferred to W7 settings. **geolocator/sensors_plus are OUT of this wave** (runtime permissions + native plugins + device QA → W7); location comes from city selection only.

**Spec:** `docs/superpowers/specs/2026-10-15-quran-yahdi-rebuild-design.md`. Ledger lessons binding.

**Baseline:** main after `400551b`. Gates: analyze 0, suite 48/48, porcelain empty.

## Global Constraints

- Binding rules (all waves): analyze 0 issues; TDD red→green where stated; explicit-pathspec commits with these exact messages; NO push; ticks committed at close-out; one writer on `main`; start gate verbatim first.
- **No schema changes this wave** — `SettingsTable` reuse only. Any drift table/new column = STOP.
- **No frozen-test edits granted.** `test/router_test.dart` is the hazard: it may pin placeholder builders for `/home`, `/prayer-times`, `/qibla`. READ ITS ASSERTIONS BEFORE touching `router.dart`. If upgrading a builder breaks it → STOP with evidence (PM will grant the minimal line); if it only pins paths/count → proceed, router_test must stay green UNEDITED.
- **New-dep admission (W1a/W2b lesson):** after `flutter pub add adhan`, disclose the resolved version + the full transitive set; confirm `adhan` pulls NO flutter binding (it must be VM-importable); `flutter pub outdated` at close must show direct deps current.
- **Package-companion checkpoint (W1b lesson generalized):** after adding `adhan`, OPEN the package's `lib/adhan.dart` exports in the pub cache BEFORE writing service code — confirm class names (`Coordinates`, `PrayerTimes`, `CalculationMethod*`, and whether `Qibla` is exported). Never assume API names from memory; disclose exact versions of API shapes used.
- Pure-Dart budget (S7 lesson): `lib/features/prayer/data/**` and `lib/features/qibla/data/**` must import NO flutter (dart + adhan + dart:convert only). Cubits stay flutter-free too (flutter_bloc only).        
- Time formatting: reuse `ArabicIndicInt.toArabicIndic` at call sites (AR locale emits western digits via gen-l10n — W1a lesson). Format H:mm by manual `padLeft(2,'0')` + Arabic-Indic transform — NO new intl/dependency.
- Teardown-safe tests (standing): real repositories on `NativeDatabase.memory()` + `tearDown(db.close)`; fakes for services; `isClosed` guards on every emit; pumpHost widget tests only; no busy-waits.
- Prayer-time tests are **property-based, never fabricated goldens**: ordering properties + generous sanity bands + qibla bearing band. Do NOT hard-code exact minutes for any city (timezone/device variance kills goldens).
- l10n additive-only, symmetric ARBs, `flutter gen-l10n` honored.

---

### Task 1: Start gate

- [x] **Step 1: Record verbatim**

```powershell
git rev-parse --short=7 HEAD; git status --porcelain; git branch --show-current; flutter --version
```

Expected: HEAD `400551b` or later with intervening commits touching ONLY `docs/`; porcelain empty; branch `main`; Flutter 3.47.5 / Dart 3.13.4. Else STOP.

---

### Task 2: `adhan` + PrayerTimeService + QiblaService (pure Dart)

**Files:**
- Modify: `pubspec.yaml` / `pubspec.lock` (add adhan)
- Create: `lib/features/prayer/data/prayer_time_service.dart`, `lib/features/qibla/data/qibla_service.dart`
- Create: `test/prayer_time_service_test.dart`, `test/qibla_service_test.dart`

**Interfaces:**
- `CityCoordinates` (shared record-like class, lives in prayer/data): `final double latitude; final double longitude; const CityCoordinates(this.latitude, this.longitude);`
- `PrayerTimeService.nextPrayer(CityCoordinates c, DateTime whenLocal)` → returns a `PrayerChoice` record (name enum + DateTime): enum over the SIX anchored points `fajr, sunrise, dhuhr, asr, maghrib, isha` (sunrise informational, never "next"). Semantics: the first of the day's five prayers with time strictly after `whenLocal`; if all passed → tomorrow's fajr.
- `PrayerTimeService.today(CityCoordinates c, DateTime dayLocal)` → ordered list of the 6 `(PrayerName, DateTime)`.
- `QiblaService.bearingDeg(CityCoordinates c)` → degrees clockwise from true north.

- [x] **Step 1:** `flutter pub add adhan` — disclose resolved version + transitives. MANDATORY: open the package exports in the pub cache; quote the exact symbol names you found (`Coordinates(c1, c2)`, prayer fields, method enum, Qibla symbol or its absence) in the report BEFORE writing usage code. If `Qibla` is NOT exported, implement the bearing inline in `qibla_service.dart`:

```dart
  double bearingDeg(CityCoordinates c) {
    const kaabaLat = 21.4225, kaabaLng = 39.8262; // public constants (disclosed step)
    final dLng = (kaabaLng - c.longitude) * 3.1415926535897932 / 180.0;
    final phi1 = c.latitude * 3.1415926535897932 / 180.0;
    final phi2 = kaabaLat * 3.1415926535897932 / 180.0;
    final y = _sin(dLng); final x = _cos(phi2) * _sin(phi1) - _sin(phi2) * _cos(phi1) * _cos(dLng);
    final deg = (dart_math.atan2(y, x) * 180.0 / 3.1415926535897932 + 360.0) % 360.0;
    return deg;
  }
```

(rectify trig helpers though the real code imports `dart:math` normally — the sketch shows intent, write idiomatic code).

- [x] **Step 2 (TDD red):** write the two test files FIRST against the interfaces above.

`prayer_time_service_test.dart` (property-based, plain `test()`):
1. `ordering: fajr < sunrise < dhuhr < asr < maghrib < isha for Cairo on a sample day` (`CityCoordinates(30.0444, 31.2357)`, fixed local DateTime like `DateTime(2026, 3, 15)`).
2. `allsanity: sunrise-fajr between 60 and 160 minutes; isha-maghrib between 60 and 130 minutes (egyptian method)`.
3. `nextPrayer picks strictly-after first anchor; after isha wraps to tomorrow fajr` (call with `whenLocal` = a time between dhuhr & asr → expects asr; call with 23:50 → next-day fajr and verify the returned date is +1).
4. `egyptian method is the fixed v1 default` (assert the service exposes/uses it — via behavior: egyptian isha-maghrib ~90min band above already asserts it; plus assert the service class exposes a `method label` const `egyptian` if trivial — else skip this assertion, keep 3 tests).

`qibla_service_test.dart`:
1. `Cairo bearing lands in the 130–145° band` (public-geography sanity; do not tighten).
2. `makkah itself returns a value in [340, 360)∪[0,20)` (degenerate-zone band, generous).

- [x] **Step 3 (green):** implement both services to green. `flutter test test/prayer_time_service_test.dart test/qibla_service_test.dart`.

- [x] **Step 4: Gates + commit**

```powershell
flutter analyze
flutter test test/prayer_time_service_test.dart test/qibla_service_test.dart
git add pubspec.yaml pubspec.lock lib/features/prayer/data lib/features/qibla/data test/prayer_time_service_test.dart test/qibla_service_test.dart
git commit -m "feat(w3): prayer + qibla services (adhan, egyptian method, pure dart)"
```

---

### Task 3: City catalog (bundled asset) + selection persistence

**Files:**
- Create: `assets/data/cities.json` (curated static list)
- Modify: `pubspec.yaml` (asset entry under `flutter: assets:` — additive line)
- Create: `lib/features/prayer/data/city_repository.dart`
- Modify: `lib/core/di/injector.dart` (register CityRepository; register PrayerTimeService + QiblaService lazy)
- Create: `test/city_repository_test.dart`

**Asset contract (executor curates using public knowledge only):**
```json
[{"id":"cairo","nameAr":"القاهرة","nameEn":"Cairo","lat":30.0444,"lng":31.2357}, ...]
```
Curate ~150 entries: ALL 27 Egyptian governorate capitals (correct Arabic names), major Arab capitals/cities (~40), world capitals (~80) — plain public facts; NO fabricated coordinates beyond common precision (2–4 decimals). This dataset is static reference data — commit as-is; do not over-engineer generation tooling.

**Interfaces:** `CityRepository(loaded from the bundled asset via a rootBundle-free injection: constructor takes `Future<List<Map<String, dynamic>>> Function()` loader so VM tests inject a fixture loader — bootstrap.dart keeps rootBundle wiring (bundle ownership, W0 pattern)). `Future<List<City>> search(String query)` (client-side filter over nameAr/nameEn substring); `Future<String?> selectedCityJson()` / `Future<void> select(City c)` via the settings table key `selected_city` (companion check: settings text-PK `required String key` — W1b lesson, `insertOnConflictUpdate`). `City` freezed-style simple class: id/nameAr/nameEn/lat/lng (+`CityCoordinates` accessor).

- [x] **Step 1 (red):** `city_repository_test.dart` — fixture loader with 5 fake cities; tests: search matches both locales + whitespace-insensitive trim; select persists + round-trips (memory DB); empty/missing selection returns null. Asset-wellformedness test: load the REAL `assets/data/cities.json` via `File('assets/data/cities.json')` and assert ≥150 entries + every entry has all 5 fields + lat in [-90,90], lng in [-180,180] (guards typos in curated data — this is the ONE place File-based asset reading in tests is justified; if the working dir resolves differently in CI, SKIP with disclosure rather than contort).
- [x] **Step 2 (green):** implement; add asset + pubspec entry; DI registrations (lazy; services need no resolver closure — pure).
- [x] **Step 3: Gates + commit**

```powershell
flutter analyze
flutter test test/city_repository_test.dart test/injector_test.dart
git add assets/data/cities.json pubspec.yaml pubspec.lock lib/features/prayer/data/city_repository.dart lib/core/di/injector.dart test/city_repository_test.dart
git commit -m "feat(w3): bundled city catalog + selection persistence (settings reuse)"
```

---

### Task 4: Prayer times + city picker screens

**Files:**
- Create: `lib/features/prayer/presentation/prayer_times/{prayer_times_cubit,prayer_times_state,prayer_times_screen}.dart`, `lib/features/prayer/presentation/city_picker/{city_picker_cubit,city_picker_state,city_picker_screen}.dart`
- Modify: `lib/app/router.dart` (upgrade `/prayer-times` from placeholder to the real screen with its cubits; add `/prayer-times/city` route) — READ router_test first (constraint above)
- Modify: `lib/l10n/app_ar.arb`, `lib/l10n/app_en.arb` + regenerated
- Create: `test/prayer_times_screen_test.dart`, `test/prayer_times_cubit_test.dart`, `test/city_picker_screen_test.dart`

**l10n (additive, symmetric):** `fajr` فجر/Fajr · `sunrise` شروق/Sunrise · `dhuhr` الظهر/Dhuhr · `asr` العصر/Asr · `maghrib` المغرب/Maghrib · `isha` العشاء/Isha · `sunriseAltNote` ملاحظة؟ NO — sunrise row gets its own visual weight only. `remaining` متبقٍ {duration}/{duration} remaining (String placeholder) · `selectCity` اختر مدينتك/Select your city · `searchCity` ابحث عن مدينة…/Search a city… · `noCity` لم تُحدَّد مدينة بعد/No city selected yet · `qiblaDirection` اتجاه القبلة/Qibla direction · `degreesFromNorth` {degrees}° عن الشمال/{degrees}° from north · `surahBadge` exists (W2b); Time strings pass through `toArabicIndic` at call sites.

- [x] **Step 1 (red):** cubit test — `PrayerTimesCubit(prayer: service, city: repo)`: no selection → `ready(cityState: none, entries: [])`; with selection → entries sorted with times + `next` anchor flagged (fake `PrayerTimeService` — hand-rolled, deterministic); after `select(city)` → reloads with new city. Screens: seeds via memory DB.
- [x] **Step 2 (green):** cubit + `PrayerTimesScreen`: header city row → picker; 6 rows (5 prayers + sunrise dimmed); next-prayer row highlighted (D6 primary) + `remaining` text (H:mm) computed from the service; Arabic-Indic H:mm per row. `CityPickerScreen`: search field + live list (existing live-filter pattern from W1a index) + tap → `select` → pop.
- [x] **Step 3: Router** — `/prayer-times` builder provides `PrayerTimesCubit` + nothing else; `/prayer-times/city` provides `CityPickerCubit`; grid/placeholder removals limited to those two builders. If router_test breaks → STOP (constraint).
- [x] **Step 4: Gates + commit** (record per-file counts)

```powershell
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test test/prayer_times_cubit_test.dart test/prayer_times_screen_test.dart test/city_picker_screen_test.dart test/router_test.dart
git add lib/features/prayer/presentation lib/app/router.dart lib/l10n test/prayer_times_cubit_test.dart test/prayer_times_screen_test.dart test/city_picker_screen_test.dart
git commit -m "feat(w3): prayer times + city picker screens (l10n, next-prayer highlight)"
```

---

### Task 5: Qibla screen

**Files:**
- Create: `lib/features/qibla/presentation/{qibla_cubit,qibla_state,qibla_screen}.dart`
- Modify: `lib/app/router.dart` (`/qibla` placeholder → real screen; router_test hazard rule applies)
- Modify: ARBs + regenerated
- Create: `test/qibla_screen_test.dart`

- [x] **Step 1 (red):** `QiblaCubit(prayer's cityRepository, qibla service)`: none → `ready(cityState: none, bearing: null)`; selection → bearing double. Screen test: with seeded city → degrees text visible + arrow `Transform.rotate(angle present)`; without → `noCity` prompt + button routes to picker.
- [x] **Step 2 (green):** Screen shows: city row, big circular dial (CustomPaint acceptable; keep it one-file simple), vector arrow `Transform.rotate(angle: bearing rad)` pointing up at bearing 0, `degreesFromNorth` text with Arabic-Indic. A "live compass" note is NOT rendered (W7 owns it silently).
- [x] **Step 3: Gates + commit**

```powershell
flutter gen-l10n
flutter analyze
flutter test test/qibla_screen_test.dart
git add lib/features/qibla/presentation lib/app/router.dart lib/l10n test/qibla_screen_test.dart
git commit -m "feat(w3): qibla screen (bearing dial, city-scoped, compass W7)"
```

---

### Task 6: Home screen (real, replaces placeholder)

**Files:**
- Create: `lib/features/home/presentation/{home_cubit,home_state,home_screen}.dart` (new `lib/features/home/` feature folder)
- Modify: `lib/app/router.dart` (`/home` placeholder → `HomeScreen` + HomeCubit; router_test hazard rule applies)
- Modify: ARBs + regenerated
- Create: `test/home_cubit_test.dart`, `test/home_screen_test.dart`

**Interface:** `HomeCubit(lastRead: LastReadRepository, ayahs: AyahRepository, prayer: PrayerTimeService, city: CityRepository)` → freezed `HomeState.ready(lastRead: ({int surahId, String surahName, int ayahNumber})?, nextPrayer: ({String label, String timeText})?, greeting is UI-only)`; reload() after nav returns (screen calls on push-return via `.then` or simply on init — v1: load-once on create + manual refresh on tap; no stream subscriptions beyond repos).
- [x] **Step 1 (red):** cubit tests (memory DB): no last-read & no city → both cards null; seeded last-read → surahName+ayah populated (seed settings row like W1b tests do); seeded city → nextPrayer label/time from fake service.
- [x] **Step 2 (green):** `HomeScreen`: app bar with appName; "continue reading" card (existing `continueReading` key + surahName + ayah via Arabic-Indic → pushes `/quran/reader?surah=..&ayah=..`, hidden when null); next-prayer card (existing `nextPrayer` key + name + H:mm → pushes `/prayer-times`, hidden when null); D6 features grid (3 columns, existing l10n keys ONLY: quran/azkar/tasbih/duasAndRuqyah/worshipTracker/zakat/hijriCalendar/asmaUlHusna/library/recitations/prayerTimes/qibla/settings — each pushes its existing route; unimplemented features keep their placeholder routes, that is by design). NO new l10n keys needed here (reuse) — if the executor finds one unavoidable, additive grant implicit but disclose.
- [x] **Step 3: Gates + commit**

```powershell
flutter gen-l10n
flutter analyze
flutter test test/home_cubit_test.dart test/home_screen_test.dart test/router_test.dart
git add lib/features/home lib/app/router.dart lib/l10n test/home_cubit_test.dart test/home_screen_test.dart
git commit -m "feat(w3): home screen (continue reading, next prayer, features grid)"
```

---

### Task 7: Close-out

- [x] **Step 1: Full gates ONCE, in order, all recorded**

```powershell
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter analyze
flutter test
flutter pub outdated
flutter build apk --debug
flutter build apk --release
git status --porcelain
git rev-list --count origin/main..HEAD
```

Expected: analyze 0; suite baseline 48 + 7 (prayer/qibla services) + 3 (city repo) + ~6 (prayer cubit/screens/picker) + 2 (qibla) + ~4 (home) = **≈70; MEASURE, record exact per-file**; APK debug exit 0 + bytes; `--release` exit 0 (first release build gate — file size + exit code only, no keystore signing beyond debug defaults; if release fails on a signing step, disclose the error text verbatim — signing/keystore is W7 anyway, a debug-signed release success is the target). Porcelain empty.

- [x] **Step 2: Tick this plan** (`- [ ]` → `- [x]`; .NET `UTF8Encoding($false)` write; NEVER blanket replaceAll — W2b lesson: the plan header PROSE contains a literal `- [ ]` token, target lines only), commit:

```powershell
git add docs/superpowers/plans/2026-10-15-w3-prayer-qibla-home.md
git commit -m "docs(w3): mark plan checkboxes complete"
```

- [x] **Step 3:** Final report — same §1–§10 skeleton as W2a/W2b (start-gate verbatim · commit table · package-companion checkpoint quotes for adhan · gates table with measured numbers + per-file counts · itemized disclosures · STOPs · incidents self-caught · unpushed count measured · state at close · NO PUSH).

## Explicit non-goals (this wave)

- GPS/geolocation, location permissions, `geolocator` — W7 with device QA; city selection is the only location source.
- Live device compass / sensor rotation / `sensors_plus` — W7.
- Hijri date rendering — W5 (hijri calendar feature) owns it.
- Prayer-method settings UI, notification scheduling (`flutter_local_notifications` or similar), adhan sounds.
- Release signing/keystore — W7 release wave.

## Self-Review (PM, pre-dispatch)

- One new dep only (`adhan`), pure-Dart, VM-testable; zero schema change → frozen tests should not move at all this wave; the only plausible frozen conflict is `router_test` pins, explicitly routed through read-first + STOP-or-grant.
- No geolocation/compass scope creep: W3 works fully offline with curated cities — consistent with the FREE/offline-first locked identity.
- Property-based temporal tests avoid golden time data (timezone/host variance), matching the no-fabrication discipline of prior waves.
- Teardown/fake pattern carried (FakePlaybackService precedent → fakes here: `FakePrayerTimeService`), `isClosed` discipline, pumpHost only.
- Arabic-Indic rendering at call sites via the existing utility; l10n strictly additive and symmetric.
- Home reuses existing l10n keys and existing routes — no new route count (router retains 14); placeholder text removals in the three upgraded builders are the only router surgery.
