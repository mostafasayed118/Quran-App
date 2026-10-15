# Quran Yahdi — Wave 4 (Azkar + Tasbih + Duas/Ruqyah + Asma) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The five offline worship features from the locked v1 set, all driven by bundled, curated, bilingual datasets — no network anywhere — plus the digital tasbih counter with persistence. Home grid already routes to all of them (W3).

**Architecture:** content = bundled JSON assets (`assets/data/`) read by fixture-injectable pure-Dart repositories (the W3 `CityRepository` pattern exactly) → one cubit per surface (freezed states) → five real screens replacing four placeholder routes (`/azkar`, `/tasbih`, `/duas`, `/asma`; duas+ruqyah live under `/duas` with an in-page section switch). Tasbih persists to the settings table only.

**Tech Stack:** W3 stack. **ZERO new packages. ZERO schema changes** (settings-table reuse only). All content transcribed from well-known public-domain compilations (prophetic adhkar / Quranic supplications) — transcribe, never paraphrase; disclose source character in the report («Hisn al-Muslim structure» is the accepted benchmark).

**Spec:** `docs/superpowers/specs/2026-10-15-quran-yahdi-rebuild-design.md`. Ledger lessons binding.

**Baseline:** main after `3feb4fd`. Gates: analyze 0, suite 71/71, porcelain empty.

## Global Constraints

- Binding rules (all waves): analyze 0 issues; TDD red→green where stated; explicit-pathspec commits with these exact messages; NO push; ticks committed at close-out; one writer on `main`; start gate verbatim first.
- **No frozen-test edits granted.** `router_test.dart` hazard applies IF placeholder builders break a pin — read it first, STOP-or-grant otherwise. Judge: last wave it held (paths-only); expect the same.
- **Content discipline (the wave's core risk):** Arabic religious text must be transcribed carefully and consistently (uthmani-style orthography for Quranic snippets, standard orthography for adhkar). No diacritic-lightening shortcuts that alter meaning. Each dataset has a minimum-count + wellformedness probe (T2–T5) so truncation/aspiration fails the gate.
- `lib/features/{azkar,tasbih,duas,asma}/data/**` stay pure Dart (dart + dart:convert only). Repos take `Future<List<Map<String, dynamic>>> Function()` loaders like `CityRepository` (bootstrap owns rootBundle — D9-welfare wiring at call sites is the accepted class, mirror W3 `defaultCitiesLoader` with e.g. `defaultAzkarLoader` — disclose).
- Settings-table reuse only (`required String key` text-PK self-wrap). Tasbih key = `tasbih_state` JSON `{count, target, mode}`. NO new drift tables/columns (any temptation = STOP).
- Teardown-safe standing rules: memory-DB + tearDown close, isClosed-guarded emits, hand-rolled fakes, pumpHost only, no busy-waits (HomeCubit/home_screen W3 tests are the closest pattern reference).
- Arabic-Indic numerals at call sites via the W3 util family; l10n strictly additive + symmetric.
- Quran-text instances needed by ruqyah (e.g., Ayat al-Kursi) MUST be loaded from the DB (`AyahRepository`, the bundled uthmani text) — never re-typed into JSON (single source of truth for Quran). Ruqyah JSON therefore carries REFERENCES (surah/ayah ranges) + non-Quranic adhkar text only.

---

### Task 1: Start gate

- [x] **Step 1: Record verbatim**

```powershell
git rev-parse --short=7 HEAD; git status --porcelain; git branch --show-current; flutter --version
```

Expected: HEAD `3feb4fd` or later with intervening commits touching ONLY `docs/`; porcelain empty; branch `main`. Else STOP.

---

### Task 2: Azkar — dataset + repository + cubit + screens

**Files:**
- Create: `assets/data/azkar.json`, pubspec asset entry
- Create: `lib/features/azkar/data/azkar_repository.dart`
- Create: `lib/features/azkar/presentation/{azkar_cubit,azkar_state,azkar_screen}.dart` (collections list + collection items in one screen, cubit state: no-selection → collection list, selection → items with per-item counter)
- Modify: `lib/app/router.dart` (`/azkar` placeholder → real; router hazard rule)
- Modify: ARBs + regenerated; `lib/core/di/injector.dart` (lazy repo+cubit registrations; loader wiring `defaultAzkarLoader` in `lib/app/bootstrap.dart` + main — mirror W3 #5)
- Create: `test/azkar_repository_test.dart`, `test/azkar_screen_test.dart`

**Asset contract:**
```json
{"collections":[{"id":"morning","nameAr":"أذكار الصباح","nameEn":"Morning remembrance",
  "items":[{"text":"...","count":3,"virtue":"...","reference":"..."}]}]}
```
Minimum: **6 collections, ≥60 items total** (morning/evening/post-prayer/sleep/waking/general). Fields: text (required), count (int, default 1), virtue/reference (optional strings).

- [x] **Step 1 (red):** repository tests (fixture loader): parse + field validation; collection lookup by id; count-default coercion. WELLFORMEDNESS probe on the real asset via `File('assets/data/azkar.json')` (W3 cities precedent, same justification): ≥6 collections, ≥60 items, zero empty `text`, all counts int ≥1, bilingual collection names non-empty.
- [x] **Step 2 (green):** repository + cubit + screens. `AzkarScreen`: collection cards (name + item count) → in-page items view: text (readable type, D6 tokens), per-item count chip decrementing on tap (tap decrements; reach 0 → row turns dimmed & moves on visually), virtue/reference footnote row. Arabic text direction OK by default; use `textAlign` right for AR via `Directionality`-aware layout (existing screens pattern).
- [x] **Step 3: l10n (additive):** `azkarItemsCount` {count} ذكر/{count} items (String placeholder) · `azkarDone` تم بحمد الله/Done · `azkarBack` العودة للأقسام/Back to sections (if AppBar back semantics need it — prefer system back; only if a visible button is required).
- [x] **Step 4: Gates + commit**

```powershell
flutter gen-l10n
flutter analyze
flutter test test/azkar_repository_test.dart test/azkar_screen_test.dart test/router_test.dart
git add assets/data/azkar.json pubspec.yaml pubspec.lock lib/features/azkar lib/app/router.dart lib/app/bootstrap.dart lib/main.dart lib/l10n lib/core/di/injector.dart test/azkar_repository_test.dart test/azkar_screen_test.dart
git commit -m "feat(w4): azkar dataset + collections screen (bundled, in-page counters)"
```

---

### Task 3: Tasbih — counter + persistence

**Files:**
- Create: `lib/features/tasbih/data/tasbih_repository.dart` (settings JSON key `tasbih_state`)
- Create: `lib/features/tasbih/presentation/{tasbih_cubit,tasbih_state,tasbih_screen}.dart`
- Modify: router (`/tasbih`), injector, bootstrap (no asset this time)
- Modify: ARBs (+regenerated)
- Create: `test/tasbih_repository_test.dart`, `test/tasbih_cubit_test.dart`, `test/tasbih_screen_test.dart`

**Interfaces:** `TasbihRepository(db)` → `Future<TasbihSnapshot?> load()` / `Future<void> save(int count, int target)`; `TasbihCubit(repo)`: states holding `{count, target}` from fixed target list `[33, 99, 100, 500]` + custom? NO custom input v1 (scope wall); `increment()` (+1; reaching target emits a done pulse flag in state, one-shot), `reset()` (count→0), `selectTarget(n)` (count→0). Persistence: save on every mutation (fire-and-forget await with isClosed guard), load on open.

- [x] **Step 1 (red):** repo test: save→load roundtrip in memory DB; missing → null. Cubit tests: increment ×3 → 3; second life loads persisted count (fake repo with in-memory map is fine here — planner encourages real repo actually; use BOTH: real repo for lifecycle, pure logic asserts); reset; selectTarget resets count; reaching target sets the one-shot `reachedTarget` flag that clears on next read.
- [x] **Step 2 (green):** `TasbihScreen`: big tappable dial (count on top, target below, HapticFeedback.selectionClick on tap — flutter's own, no dep), play again/reset row, target selector chips (33/99/100/500, Arabic-Indic labels). Done pulse: brief checkmark overlay/scale — keep it a plain AnimatedScale, one-shot, no animation package (flutter-design-eng principles: interruptible, subtle).
- [x] **Step 3: l10n (additive):** `tasbihReset` تصفير/Reset · `tasbihTarget` الهدف/Target · (titles: existing `tasbih` key).
- [x] **Step 4: Gates + commit**

```powershell
flutter gen-l10n
flutter analyze
flutter test test/tasbih_repository_test.dart test/tasbih_cubit_test.dart test/tasbih_screen_test.dart
git add lib/features/tasbih lib/app/router.dart lib/core/di/injector.dart lib/l10n test/tasbih_repository_test.dart test/tasbih_cubit_test.dart test/tasbih_screen_test.dart
git commit -m "feat(w4): tasbih counter (persistent, one-shot done pulse, targets)"
```

---

### Task 4: Duas + Ruqyah — shared collection pattern

**Files:**
- Create: `assets/data/duas.json`, `assets/data/ruqyah.json`, pubspec entries
- Create: `lib/features/duas/data/{dua_repository,ruqyah_repository}.dart`
- Create: `lib/features/duas/presentation/{duas_cubit,duas_state,duas_screen}.dart` (top switcher: أدعية/رقية — two datasets, one screen shell)
- Modify: router (`/duas`), injector, bootstrap loaders
- Modify: ARBs (+regenerated)
- Create: `test/dua_repository_test.dart`, `test/ruqyah_repository_test.dart`, `test/duas_screen_test.dart`

**Asset contracts:**
- `duas.json`: `[{"id":"...","categoryAr":"...","categoryEn":"...","text":"...","reference":"..."}]` — minimum **40 duas** across ≥6 categories (morning/evening/enter-exit home/mosque/travel/food/wear/forgiveness…).
- `ruqyah.json`: `[{"id":"...","kind":"quran|dhikr","surahId":int?,"fromAyah":int?,"toAyah":int?,"text":str?,"count":int?,"reference":str?}]` — Quranic entries carry REFERENCE ranges only (Ayat al-Kursi 2:255; last-two surahs 113–114 complete; fatihah 1:1-7; [2:285-286] optional) — text resolved at runtime from `AyahRepository.ayahsForRange` (additive mirror query if absent — W3 mirror class). Non-Quranic ruqyah adhkar carry plain text. Complete canonical set, minimum 8 entries.
- [x] **Step 1 (red):** dua repo tests (fixture): category grouping + filter; ruqyah repo tests (fixture + memory DB): quran-kind resolves ranges via AyahRepository (fixture ayah rows), text-kind passes through; wellformedness probes on real assets (duas ≥40/≥6 categories; ruqyah ≥8 entries with every quran-kind carrying non-null surah/from/to).
- [x] **Step 2 (green):** `DuasScreen`: segmented switch (existing l10n keys `duasAndRuqyah` exists — add `duasTab` الأدعية/Duas + `ruqyahTab` الرقية/Ruqyah); duas tab = category chips + filtered list; ruqyah tab = ordered items, Quranic ones rendered from the repo-resolved uthmani text + citation row (surah name via SurahRepository — reuse `surahById`).
- [x] **Step 3: Gates + commit**

```powershell
flutter gen-l10n
flutter analyze
flutter test test/dua_repository_test.dart test/ruqyah_repository_test.dart test/duas_screen_test.dart
git add assets/data/duas.json assets/data/ruqyah.json pubspec.yaml lib/features/duas lib/app/router.dart lib/app/bootstrap.dart lib/core/di/injector.dart lib/l10n test/dua_repository_test.dart test/ruqyah_repository_test.dart test/duas_screen_test.dart
git commit -m "feat(w4): duas + ruqyah (bundled categories, DB-resolved quran refs)"
```

---

### Task 5: Asma ul Husna — 99 names

**Files:**
- Create: `assets/data/asma.json`, pubspec entry
- Create: `lib/features/asma/data/asma_repository.dart`
- Create: `lib/features/asma/presentation/{asma_cubit,asma_state,asma_screen}.dart`
- Modify: router (`/asma`), injector, bootstrap
- Modify: ARBs (+regenerated)
- Create: `test/asma_repository_test.dart`, `test/asma_screen_test.dart`

**Asset contract:** array of exactly **99** entries `[{"n":1,"nameAr":"الرحمن","nameEn":"Ar-Rahman","meaningAr":"...","meaningEn":"..."}]` with strict `n` 1..99 unique.

- [x] **Step 1 (red):** repo tests: fixture parse; REAL-asset wellformedness = **exactly 99**, unique n 1..99, all four text fields non-empty (this one is a hard count — no fabrication latitude).
- [x] **Step 2 (green):** `AsmaScreen`: grid of 99 cards (name en big serif D6 style, meaning under it, n badge Arabic-Indic), tap → detail bottom-sheet/card flip with both meanings (one screen, no new route).
- [x] **Step 3: l10n (additive):** `namePosition` الاسم {n} من 99/Name {n} of 99 (String placeholder).
- [x] **Step 4: Gates + commit**

```powershell
flutter gen-l10n
flutter analyze
flutter test test/asma_repository_test.dart test/asma_screen_test.dart
git add assets/data/asma.json pubspec.yaml lib/features/asma lib/app/router.dart lib/app/bootstrap.dart lib/core/di/injector.dart lib/l10n test/asma_repository_test.dart test/asma_screen_test.dart
git commit -m "feat(w4): asma ul husna (99 names grid + meanings sheet)"
```

---

### Task 6: Close-out

- [x] **Step 1: Full gates ONCE, in order, all recorded**

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

Expected: analyze 0; suite baseline 71 + 4 (azkar repo) + ~3 (azkar screen) + 4 (tasbih repo 2 + cubit 2) + 1-2 (tasbih screen) + 6 (dua/ruqyah repos + screen) + 4 (asma) = **≈92; MEASURE, record exact per-file**; debug exit 0 + size (ballpark — determinism retired, ledger W3); release exit 0 + bytes (byte-exact expected); outdated current; porcelain empty. `--delete-conflicting-outputs` flag removal warning is known (W2b D2 class — fine).
- [x] **Step 2: Tick this plan** — **targeted line edits ONLY** (the header PROSE contains a literal `- [ ]` token; W2b/W3 standing lesson), .NET `UTF8Encoding($false)` writes, then numstat + non-checkbox-line filter check committed in the report:

```powershell
git add docs/superpowers/plans/2026-10-15-w4-worship-content.md
git commit -m "docs(w4): mark plan checkboxes complete"
```

- [x] **Step 3:** Final report — §1–§10 skeleton (start-gate verbatim · commit table · content-provenance paragraph for each dataset · mandatory checkpoints like frezzed state signatures post build_runner · gates table with measured numbers + per-file counts · itemized disclosures · STOPs · incidents self-caught · unpushed · state · NO PUSH).

## Explicit non-goals (this wave)

- Prayer-time notifications / azkar notifications (flutter_local_notifications + scheduling) — W7 polish.
- Custom tasbih targets/counters beyond the fixed list; subhah history/stats.
- Audio of adhkar; tafsir linkage for ruqyah verses (visual Quran badges only).
- Azkar/duas search across datasets (nice-to-have W7 if wanted).
- Any network fetch of datasets (locked: offline bundle).

## Self-Review (PM, pre-dispatch)

- Zero new deps, zero schema change → frozen-suite risk ≈ router placeholders only (same read-first + STOP-or-grant rule; two days running it held).
- Content risk fenced by wellformedness probes with hard minimums + the Quran-text single-source-of-truth rule (ruqyah ranges resolve from the DB, never re-typed).
- Pattern reuse is maximal: CityRepository loader-injection (W3), settings-JSON persistence (W3 selected_city), segmented/switching screen style (W3 duas tab), pumpHost harnesses (W2b–W3), mirrors via additive methods only.
- Test-count discipline: baseline 71; every new test listed per file; executor MEASURES (≈92), never extrapolates.
- Arabic content direction/typography reuses the existing W1b/W3 patterns (no new text plumbing); Arabic-Indic numerals at call sites only.
- Home grid already routes `/azkar` `/tasbih` `/duas` `/asma` — no home change required this wave (verify only).
