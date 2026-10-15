# Quran Yahdi — Wave 5 (Worship Tracker + Zakat + Hijri) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The remaining three v1 features: a 5-prayer daily tracker backed by the ALREADY-EXISTING schema-v1 `PrayerLog` table (no migration!), a nisab-driven zakat calculator (pure math, stateless v1), and a Hijri calendar screen.

**Architecture:** `PrayerLogRepository` (pure Dart, drift upsert-per-day) → `TrackerCubit` + tracker screen (today's 5 toggles + 7-day strip + streak). `ZakatCalculator` (pure Dart, deterministic goldens ALLOWED here — arithmetic, not astronomy) + zakat screen. `HijriService` (ONE new package, see below) + hijri screen (today header + navigable month grid).

**Tech Stack:** W4 stack + exactly ONE new package for Hijri. **Admission order:** (1) `flutter pub add hijri` — inspect the pub-cache source: must be importable from pure Dart (no flutter import) and expose the standard conversion (`Hijri.from(DateTime)`, `.hY/.hM/.hD`, `toFormat`, month lengths). (2) If unsatisfactory → `hijri_date` same checks. (3) If BOTH fail the purity/utility bar → STOP with evidence (PM will rule) — do NOT hand-roll a calendar. Package absence is the only acceptable third option and it needs a PM ruling. Disclose resolved version + transitives like always.

**Spec:** `docs/superpowers/plans/`... none — this plan + `docs/superpowers/specs/2026-10-15-quran-yahdi-rebuild-design.md`. Ledger lessons binding.

**Baseline:** main after `89a3946`. Gates: analyze 0, suite 92/92, porcelain empty.

## Global Constraints

- Binding rules (all waves): analyze 0 issues; TDD red→green for repos/cubits (W4 preference: cubits get red-first when stateful logic is non-trivial — tracker cubit qualifies); explicit-pathspec commits with these exact messages; NO push; ticks at close-out; one writer on `main`; start gate verbatim first.
- **No schema changes.** `PrayerLog` exists (v1): `day` dateTime TEXT-style single PK + `fajr/dhuhr/asr/maghrib/isha` booleans with false defaults. **Companion-checkpoint MANDATORY** (W1b/W2b law): after build_runner, open `app_database.g.dart` and quote the `PrayerLog` data-class + `PrayerLogCompanion.insert` signature (dateTime PK wrapping is UNVERIFIED — verify `required DateTime day` vs `Value(...)`, and whether `day` needs any precision normalization; the classic drift trap here is DateTime day-equality — see interface ruling below).
- **Day-key ruling (PM, binding):** `day` is stored as drift DateTime; day-equality must be normalized — repository always writes/queries with `DateTime(y,m,d)` (midnight, local) constructed via a `dateOnly(DateTime)` helper in the repository file; NEVER compare raw `DateTime.now()`.
- Frozen tests: NO edits granted. `/worship`, `/zakat`, `/hijri` placeholder builders are router surgery — same read-first + STOP-or-grant rule as W3/W4 (three consecutive waves it held paths-only).
- `lib/features/{tracker,zakat,hijri}/**` pure-Dart budgets as always (data/ layer zero flutter; cubits flutter_bloc only); screens follow the D6 token + existing screen idioms.
- Teardown-safe standing rules; haptics via flutter's `HapticFeedback` only; Arabic-Indic numerals at call sites; l10n additive + symmetric; currency inputs are plain TextFields (decimal parse, locale-tolerant: accept both `,` and `.` separators via a normalize helper — test it).
- Zakat rates (locked PM decision, cite in screen footnote): nisab = 87.48 g gold OR 612.36 g silver (choose threshold by toggle, silver is the safer default for cash-based wealth per common fiqh practice); zakat rate 2.5% on `cash + (gold_g × gold_price) + (silver_g × silver_price) − debts`; due only when zakatable ≥ chosen nisab value. Currency = whatever the user's numbers imply (no currency symbol machinery v1).

---

### Task 1: Start gate

- [x] **Step 1: Record verbatim**

```powershell
git rev-parse --short=7 HEAD; git status --porcelain; git branch --show-current; flutter --version
```

Expected: HEAD `89a3946` or later with intervening commits touching ONLY `docs/`; porcelain empty; branch `main`. Else STOP.

---

### Task 2: Prayer tracker (repository + cubit + screen)

**Files:**
- Create: `lib/features/tracker/data/prayer_log_repository.dart`
- Create: `lib/features/tracker/presentation/{tracker_cubit,tracker_state,tracker_screen}.dart`
- Modify: router (`/worship` → real; hazard rule), injector
- Modify: ARBs (+regenerated)
- Create: `test/prayer_log_repository_test.dart`, `test/tracker_cubit_test.dart`, `test/tracker_screen_test.dart`

**Interfaces:**
- `dateOnly(DateTime d)` helper (repository file, pure).
- `PrayerLogRepository(db)`: `Future<bool> getForDay(DateTime day)` → whether any prayer marked; `Future<void> togglePrayer(DateTime day, PrayerSlot slot)` (upsert row, flip bool, write normalized day); `Stream<PrayerLogCompanion-free day projection> watchToday()` — preferred shape: `Stream<bool Function(PrayerSlot)>` is NOT a stream type; instead emit `Stream<TrackerDay>` where `TrackerDay` = simple class with the five bools + `bool get anyMarked`; `Future<List<DateTime>> markedDaysRange(DateTime fromInclusive, int daysBack)` (for the strip + streak — return normalized days with ≥1 marked).
- `TrackerCubit(repo)`: `TrackerReady(toggle day flags, streakDays int, last7 List<bool>)` + initial/loading; loads today + streak on create; `toggle(slot)` → optimistic-ish recompute from repo truth; `streak` = consecutive marked days ending today-or-yesterday (PM ruling recorded here; test it explicitly for both anchors).

- [x] **Step 1 (red-first — repos AND cubit):** repository tests (memory DB): toggle-on persists and re-reads; toggle-all-off keeps the row with `anyMarked=false` (upsert semantics — assert rows count stays 1 per day); day normalization: repo called with `DateTime.now()` must match a row written with `dateOnly(now)` (the classic PK trap). Cubit tests: fresh state all-false; toggling fajr flips + streak 1; seeded previous 3 days → streak 4; seeded gap → streak resets (test today-anchored and yesterday-anchored cases per ruling).
- [x] **Step 2 (green):** implement. `TrackerScreen`: today date header (Gregorian + Arabic-Indic; Hijri arrives in T4 — do NOT couple), five toggle rows using existing `fajr…isha` l10n keys with check affordances (D6 primary when on), 7-day dot strip (marked = filled), streak badge `streak {days}` label.
- [x] **Step 3: l10n (additive):** `streak` سلسلة {days} يوم/{days}-day streak (String placeholder) · `trackerToday` علِمت اليوم/Today's prayers (fresh key, do not collide with existing `worshipTracker` title) · `last7Days` آخر ٧ أيام/Last 7 days (western 7 literal in source; render Arabic-Indic at call site or plain — String placeholder justified).
- [x] **Step 4: Gates + commit**

```powershell
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test test/prayer_log_repository_test.dart test/tracker_cubit_test.dart test/tracker_screen_test.dart test/router_test.dart
git add lib/features/tracker lib/app/router.dart lib/core/di/injector.dart lib/l10n test/prayer_log_repository_test.dart test/tracker_cubit_test.dart test/tracker_screen_test.dart
git commit -m "feat(w5): prayer tracker (PrayerLog upsert, week strip, streak)"
```

---

### Task 3: Zakat calculator (pure math + screen)

**Files:**
- Create: `lib/features/zakat/data/zakat_calculator.dart`
- Create: `lib/features/zakat/presentation/{zakat_cubit,zakat_state,zakat_screen}.dart`
- Modify: router (`/zakat`), injector
- Modify: ARBs (+regenerated)
- Create: `test/zakat_calculator_test.dart`, `test/zakat_screen_test.dart`

**Interface:** `ZakatInput({double goldGrams, double silverGrams, double cash, double debts, bool nisabBySilver})` (all default 0/false); `ZakatResult compute(ZakatInput, {required double goldPricePerGram, required double silverPricePerGram})` → `ZakatResult({double zakatable, double nisabValue, bool due, double amount})`; constants `goldNisabGrams = 87.48`, `silverNisabGrams = 612.36`, `zakatRate = 0.025` (const, cited).
- [x] **Step 1 (red-first — REAL goldens allowed, deterministic arithmetic):** 1) below silver nisab → due=false, amount=0; 2) above gold nisab with silver toggle → nisabValue = 87.48×goldPrice; 3) below-gold/above-silver boundary with silver default → due=true, amount = 2.5% of zakatable; 4) debts subtract; 5) comma-decimal parse normalization (`"1,000.50"` and `"1000,50"` → 1000.5 — helper test).
- [x] **Step 2 (green):** calculator; `ZakatScreen`: numeric fields (gold grams, silver grams, gold price/g, silver price/g, cash, debts) + nisab toggle + results card (zakatable, nisab value, `zakatDue`/`zakatNotDue`, amount highlighted, footnote citing the constants + "شرعاً — تحقق من أهلك" clarity line via `zakatFootnote` key). Input changes recompute live (cubit state, no submit button).
- [x] **Step 3: l10n (additive):** `goldGrams` ذهب (جرام)/Gold (grams) · `silverGrams` فضة (جرام)/Silver (grams) · `goldPrice` سعر جرام الذهب/Gold price per gram · `silverPrice` سعر جرام الفضة/Silver price per gram · `cash` النقد المعروض/On-hand cash · `debts` الديون/Debts · `nisabByGold` العتبة: الذهب/Threshold: gold · `nisabBySilver` العتبة: الفضة/Threshold: silver · `zakatDue` الزكاة الواجبة/Zakat due · `zakatNotDue` لا زكاة عليك/No zakat due · `zakatFootnote` النسب ثابتة 2.5% والعتبار على العتبة — راجع أهل العلم في تقديرك/The rate is fixed at 2.5% and the threshold applies — consult scholars for your estimate.
- [x] **Step 4: Gates + commit**

```powershell
flutter gen-l10n
flutter analyze
flutter test test/zakat_calculator_test.dart test/zakat_screen_test.dart test/router_test.dart
git add lib/features/zakat lib/app/router.dart lib/core/di/injector.dart lib/l10n test/zakat_calculator_test.dart test/zakat_screen_test.dart
git commit -m "feat(w5): zakat calculator (nisab gold/silver, live inputs)"
```

---

### Task 4: Hijri calendar (service + screen)

**Files:**
- Create: `lib/features/hijri/data/hijri_service.dart`
- Create: `lib/features/hijri/presentation/{hijri_cubit,hijri_state,hijri_screen}.dart`
- Modify: router (`/hijri`), injector
- Modify: ARBs (+regenerated)
- Create: `test/hijri_service_test.dart`, `test/hijri_screen_test.dart`

- [x] **Step 1: dependency admission** — per Tech Stack order; quote the pub-cache class surface you found BEFORE usage; disclose version + transitives + purity check.
- [x] **Step 2 (red-first, PROPERTY tests — no cross-calendar goldens):** 1) today roundtrip: gregorian(t) → hijri → gregorian == t (package must be exact — if the chosen package is only ±1 day, STOP, that fails the bar); 2) sanity band: hijri year for 2026-10-15 ∈ {1447, 1448} (single loose band, justified); 3) month-length validity: every reported month length ∈ {29, 30}; 4) known-span ordering: 1 Muh 1447 < 1 Muh 1448 in gregorian time.
- [x] **Step 3 (green):** `HijriService` wrapper + `HijriCubit` (current month state `month/year/offsets/grid` — build with `dateOnly` semantics) + `HijriScreen`: header `hijriLabel` + today's `hijriDate` line (formatted Arabic-Indic), month grid (weekday-aligned, gregorian day number rendered subtly under hijri number — same-cell dual label), prev/next month arrows + `jumpToToday` action.
- [x] **Step 4: l10n (additive):** `hijriDate` الشهر {month} سنة {year}/{month} {year} AH (two String placeholders) · `gregorianEquivalent` يوافق {date}/= {date} (String placeholder) · `jumpToToday` اليوم/Today · `hijriMonths` are CONTENT — render hijri month names from the value (Umm al-Qura naming arrives with the package locale OR map 12 canonical names in a constant inside the cubit file with AR/EN pairs — content like asma precedent, cite source character).
- [x] **Step 5: Gates + commit**

```powershell
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test test/hijri_service_test.dart test/hijri_screen_test.dart
git add pubspec.yaml pubspec.lock lib/features/hijri lib/app/router.dart lib/core/di/injector.dart lib/l10n test/hijri_service_test.dart test/hijri_screen_test.dart
git commit -m "feat(w5): hijri calendar (month grid, property-tested service)"
```

---

### Task 5: Close-out

- [x] **Step 1: Full gates ONCE, all recorded**

```powershell
dart run build_runner build --delete-conflicting-outputs 2>&1 | Select-Object -Last 1
flutter gen-l10n
flutter analyze
flutter test
flutter pub outdated
flutter build apk --debug
flutter build apk --release
git status --porcelain
git rev-list --count origin/main..HEAD
```

Expected: analyze 0; suite baseline 92 + ~11 (tracker: 4 repo + 4 cubit + 2-3 screen) + ~6 (zakat: 5 calc + 1 screen) + ~6 (hijri: 4 service + 1-2 screen) = **≈115; MEASURE, per-file exact**; debug exit 0 ballpark; release exit 0 + bytes (byte-exact expected); pub outdated with the ONE hijri admission disclosed; porcelain empty.
- [x] **Step 2: Tick this plan** — targeted line edits ONLY (header PROSE contains a literal `- [ ]`), .NET UTF8-no-BOM, numstat + non-checkbox filter recorded.

```powershell
git add docs/superpowers/plans/2026-10-15-w5-tracker-zakat-hijri.md
git commit -m "docs(w5): mark plan checkboxes complete"
```

- [x] **Step 3:** Final report — §1–§10 skeleton (start-gate verbatim · commit table · hijri package-checkpoint quotes + admission verdict · PrayerLog companion-checkpoint quotes · gates table · itemized disclosures · STOPs · incidents self-caught · unpushed · state · NO PUSH).

## Explicit non-goals (this wave)

- Tracker beyond daily 5-prayer booleans: qada flags, prayer-time window validation, Quran-page/khatma tracking UI (KhatmaProgress table awaits its future wave or W7 decision), stats charts.
- Zakat: zakat-al-fitr, livestock/trade-goods modes, persistence of inputs (stateless v1), currency selection — W7 backlog.
- Hijri: events/anniversaries, prayer-times screen integration (W3 screen shows Gregorian-only today header — cross-link vs change is a W7 polish), moon-sighting disclaimers beyond the standard footnotes.
- Notifications/scheduling — W7 line unchanged.

## Self-Review (PM, pre-dispatch)

- Zero schema change (PrayerLog pre-exists — verified at source tables.dart:43-52); ONE new dep for hijri with ordered fallbacks and a hard STOP bar (roundtrip-exact or PM ruling).
- The two real data-integrity traps are fenced explicitly: DateTime day-PK normalization (dateOnly rule + test mandated) and Hijri roundtrip-exactness (property test mandated, STOP if not).
- Zakat is deterministic arithmetic → real goldens allowed (contrast with the temporal/spatial property rule — both documented in the ledger, opposite sides of the same law).
- Router placeholder surgery ×3 with the three-times-proven read-first + STOP-or-grant rule; home untouched; no frozen edits granted.
- Red-first mandated for repository and cubit layers across all three tasks; screens may go green-first as established.

---

## PM Errata & Adjudications (post-wave, committed by PM 2026-10-15)
- All 7 disclosures ACCEPTED. Zero STOPs — router_test unedited FOURTH consecutive wave (diff-verified). Package intake gate worked as designed: HijriCalendar (not the plan-sketch name) accepted because the checkpoint verification — not assumption — drove it; purity scan re-confirmed PM-side (zero flutter imports in the package lib).
- D3 streak cap 400 days (bounded markedDaysRange query, stats unbounded = W7) — accepted, rational bound.
- D5 ZakatCalculator registered-but-inline-computed — harmless slop; W7 either wires it or removes the registration.
- D4 setLocal('ar') package-global — v1 default-AR fine; locale-aware switch = W7 line.
- Companion checkpoint PM-reproduced: PrayerLogCompanion.insert required DateTime day (g.dart:1611-1619) — the report's quote was accurate to the line.
- Gates PM-reproduced: analyze 0; suite 113/113; debug rebuild exit 0 @ 206,245,214 B (delta 173 B, retired-determinism ballpark); release rebuilt exit 0 @ 65,014,586 B byte-EXACT (FOURTH consecutive); hijri 3.0.1 sole dep; ticks 17/17 targeted; self-caught logic bug (hijri gregorian/hijri ctor swap) never reached green-claim — exemplary.