# Quran Yahdi — Wave 6 (Library: Tafsir + Translations + Hadith) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The last content wave: an in-app library that installs offline tafsir, translation, and hadith packs from the PM-verified public CDNs (pinned URLs), manages them via the ALREADY-EXISTING schema-v1 `InstalledPacks` table (zero migration), and surfaces tafsir/translation per-ayah inside the reader. Supabase stays a thin seam only.

**Architecture:** bundled `assets/data/library_catalog.json` (curated, version-pinned) → `CatalogRepository` (fixture-injected loader, CityRepository pattern) behind a `CatalogSource` interface (the Supabase thin-layer seam: bundled catalog IS the v1 default source; a remote Supabase manifest impl is wired only when the owner's project exists — client stub documented, non-blocking). `PackDownloader` (dio stream → app-private `library/<packId>.json`, `InstalledPacks` upsert with version+size, JSON-parse integrity sniff — AudioDownloader pattern). `LibraryScreen` (catalog tabs: tafsir/translation/hadith; install progress; installed management + delete). Reader ayah card gains a tafsir/translation affordance → bottom sheet reading INSTALLED packs for that ayah. Minimal hadith browse for installed hadith packs (numbered list, paged).

**Tech Stack:** W5 stack. **ZERO new packages. ZERO schema changes.** Content endpoints (PM-verified live 2026-10-15): fawazahmed0/quran-api (translation editions), spa5k/tafsir_api (tafsirs — pin exact tags), fawazahmed0/hadith-api (hadith books). Supabase is catalog-seam only in this wave — NO supabase_flutter dependency yet, NO networking beyond the pack downloads.

**Spec:** `docs/superpowers/specs/2026-10-15-quran-yahdi-rebuild-design.md`. Locked: audio NEVER on Supabase (egress); FREE offline-first. Ledger lessons binding.

**Baseline:** main after `0eef9f1`. Gates: analyze 0, suite 113/113, porcelain empty.

## Global Constraints

- Binding rules (all waves): analyze 0; TDD red→green for repos/downloader/cubits; explicit-pathspec commits with these exact messages; NO push; ticks at close-out; one writer on `main`; start gate verbatim first.
- **No schema changes** — `InstalledPacks` exists: `packId` text-PK, `kind` (translation|tafsir|hadith), `language`, `title`, `sizeMb` real, `version` text, `installedAt` default now. **Companion checkpoint MANDATORY**: quote `InstalledPacksCompanion.insert` from `app_database.g.dart` after build_runner before any usage (text-PK precedent expects `required String packId`, others Value-able — VERIFY, not assume).
- **Catalog integrity is the wave's spine:**
  1. Catalog entries: `{id, kind, language, titleAr, titleEn, sourceUrl, approxSizeMb, version}`. Curate EXACTLY 9 packs — tafsirs: ar-muyassar, ar-jalalayn, en-ibnkathir (spa5k, pinned tag); translations: ar (a mukhtasar or Cleary-standard — pick ONE ar edition), en-sahih (fawazahmed0, pinned @1 file path); hadith: ar-bukhari, en-bukhari, en-muslim (fawazahmed0 hadith-api, pinned). Use EXACT edition slugs from the live API listing pages — never guessed paths.
  2. Every `sourceUrl` MUST be probed (GET, status 200 + Content-Length quoted) during curation; the report quotes the three (kind × first entry) probe results. CDN root: `https://cdn.jsdelivr.net/...` pinned by tag — NEVER `/latest/`.
  3. The remote API JSON SHAPES must be documented by ADAPTERS in the repositories, not assumed: download each kind's first entry ONCE, inspect the tree, copy a ≤40 KB EXCERPT fixture to `test/fixtures/` (license-attributed in the fixture header comment — sources are open content), and write adapters against the REAL shape with fixture tests. Corrupted/mismatched shapes at runtime → pack invalid → failed status + delete partial (downloader semantics).
- **Downloads:** INTERNET permission already present. Downloader follows the AudioDownloader pattern (dio `ResponseType.stream`, file to app-support via injected `libraryRootResolver` closure, partial-file delete on failure); register positions reviewed against `ensureLibraryBindings()` in bootstrap mirroring `ensureAudioBindings()`. Status lives in InstalledPacks implicitly (row present = installed) — NO drift columns added; in-flight progress is cubit-state only (transient by design).
- Pure-Dart budgets (`lib/features/library/data/**` no flutter), teardown-safe standing rules, `pumpHost` widget tests, hand-rolled fakes/local `HttpServer` for network tests (real CDN never probed inside tests — fixtures only), Arabic-Indic numerals at call sites, l10n additive + symmetric.
- Reader integration must NOT edit frozen reader_test expectations: the affordance is an ADDITIONAL icon on ayah cards; existing assertions on card internals must remain green unedited. If the pinned widget structure blocks the icon, STOP (never pre-emptively edit a frozen test).
- The ayah sheet reads installed packs ONLY (sheet copy: empty-state routes to /library). No streaming-to-skip-by-reading shortcuts.

---

### Task 1: Start gate

- [x] **Step 1: Record verbatim**

```powershell
git rev-parse --short=7 HEAD; git status --porcelain; git branch --show-current; flutter --version
```

Expected: HEAD `0eef9f1` or later with intervening commits touching ONLY `docs/`; porcelain empty; branch `main`. Else STOP.

---

### Task 2: Catalog + CatalogRepository (the Supabase seam)

**Files:**
- Create: `assets/data/library_catalog.json` (9 curated packs, version-pinned URLs)
- Create: `lib/features/library/data/library_catalog.dart` (`CatalogSource` interface + `BundledCatalogSource` — the seam: future Supabase manifest implements the same contract; document the intended Supabase shape in a doc comment on the interface, ONE file)
- Create: `lib/features/library/data/catalog_repository.dart` (list + byId + kind filter)
- Modify: `lib/core/di/injector.dart`, `lib/app/bootstrap.dart` (loader + bindings seam naming `ensureLibraryBindings()` for the downloader resolution — T3 completes it), `lib/main.dart` if the loader wiring needs it (mirror W3 citiesLoader)
- Modify: pubspec NOT needed (assets/data/ folder-registered since W3 — verify and DISCLOSE if otherwise)
- Create: `test/catalog_repository_test.dart` (+ `test/fixtures/` excerpts if already fetched — may land in T3 instead)

**Interfaces:** `LibraryPackInfo({id, kind, language, titleAr, titleEn, sourceUrl, approxSizeMb, version})`; `CatalogSource.all()` / `byId(id)`; kind enum values exactly `translation|tafsir|hadith` (schema constraint discipline).

- [x] **Step 1 (red):** catalog repository tests with fixture loader: kind filtering, byId, malformed-entry rejection. Wellformedness probe on the REAL bundled catalog: exactly 9 entries, 3 per kind, every field non-empty, `sourceUrl` starts `https://cdn.jsdelivr.net/` AND contains a pinned tag NOT `/latest/`, id unique.
- [x] **Step 2 (green + URL probing):** curate the 9 packs by reading the live listing/documentation pages of the three APIs; probe each curated `sourceUrl` (curl/Invoke-WebRequest, GET) and quote status+bytes in the report; assemble the asset; implement repository to green.
- [x] **Step 3: Gates + commit**

```powershell
flutter analyze
flutter test test/catalog_repository_test.dart
git add assets/data/library_catalog.json lib/features/library/data lib/core/di/injector.dart lib/app/bootstrap.dart lib/main.dart test/catalog_repository_test.dart
git commit -m "feat(w6): curated library catalog (pinned CDN URLs) + Supabase seam"
```

---

### Task 3: PackDownloader + InstalledPacks registry

**Files:**
- Create: `lib/features/library/data/pack_downloader.dart`
- Modify: `lib/features/library/data/catalog_repository.dart` (installed projections join), `lib/core/di/injector.dart`, `lib/app/bootstrap.dart` (`ensureLibraryBindings()` mirroring `ensureAudioBindings()`; `main.dart` passes the resolver)
- Modify: ARBs if needed (defer all strings to T4/T5 — this task is headless)
- Create: `test/fixtures/` (first-entry excerpts per kind, ≤40 KB, header-comment attribution) + `test/pack_downloader_test.dart`

**Interfaces:** `PackDownloader(db, {Dio? dio, Future<Directory> Function()? libraryRootResolver})` — mirror AudioDownloader exactly: `Future<File> install(LibraryPackInfo pack, {void Function(int, int)? onProgress})` → stream URL → `library/<packId>.json` (write-then-promote: write `.part`, parse-validates JSON non-empty, rename over final, upsert InstalledPacks row with version+measured sizeMb, delete `.part` on any failure); `Future<void> uninstall(String packId)` (delete file + row); `Future<bool> isInstalled(packId, version)`; `Future<List<InstalledPack>> installedPacks()`.
- Per-kind ADAPTERS live here too: `translationFor(packId, surah, ayah) → String?`, `tafsirFor(packId, surah, ayah) → String?`, `hadithPage(packId, int offset, int limit) → (List<(int, String)>, bool hasMore)` — implemented against the REAL fixture shapes copied in T2; shape mismatch = null/empty (never throw upward).
- [x] **Step 1 (red):** downloader tests with a local `HttpServer` (audio test pattern): happy path writes file + row with parsed sizeMb; 404 → no row, no partial left; corrupt JSON body → failed, partial deleted; uninstall removes both; `translationFor` reads the REAL fixture translation for a known ayah (e.g., 1:1) → non-null; `hadithPage` slices + hasMore flips at the fixture's end.
- [x] **Step 2 (green):** implement (injectable, pure-Dart headless); `ensureLibraryBindings()` + main wiring.
- [x] **Step 3: Gates + commit**

```powershell
flutter analyze
flutter test test/pack_downloader_test.dart test/injector_test.dart
git add lib/features/library/data lib/app/bootstrap.dart lib/main.dart lib/core/di/injector.dart test/fixtures test/pack_downloader_test.dart
git commit -m "feat(w6): pack downloader (install-or-fail integrity) + kind adapters"
```

---

### Task 4: Library screen (browse/install/manage)

**Files:**
- Create: `lib/features/library/presentation/{library_cubit,library_state,library_screen}.dart`
- Modify: router (`/library` placeholder → real; the FOURTH+1 router read-first hazard), injector
- Modify: ARBs (+regenerated)
- Create: `test/library_screen_test.dart`

**Screen:** app bar title `library` (existing key); segmented tabs tafsir/translation/hadith (`tafsirTab`/`translationsTab`/`hadithTab`); pack rows (bilingual title + `approxSizeMb` + version; per-row state: `libraryInstall` button with progress bar from cubit stream, or `libraryDelete` when installed (confirm dialog protective of content); `libraryInstalled` badge). Install failures surface a dismissible error strip (W2a error-banner pattern).
- [x] **Step 1 (red):** cubit tests (fake downloader + fake catalog source): filtering per tab; install flow → progress → installed; failure → error state with retry; delete removes row. Screen tests (fixture packs + local HttpServer for a REAL streaming row): install button starts download, progress visible, completion flips badge (pumpHost).
- [x] **Step 2 (green):** implement.
- [x] **Step 3: l10n (additive):** `tafsirTab` التفسير/Tafsir · `translationsTab` الترجمات/Translations · `hadithTab` الأحاديث/Hadith · `libraryInstall` تنزيل/Install · `libraryDelete` حذف/Delete · `libraryInstalled` مثبّت/Installed · `libraryFailed` تعذّر التنزيل/Download failed · `libraryRetry` أعِد المحاولة/Retry · `storageNote` (approxSizeMb title row already numeric — no extra key).
- [x] **Step 4: Gates + commit**

```powershell
flutter gen-l10n
flutter analyze
flutter test test/library_screen_test.dart test/router_test.dart
git add lib/features/library/presentation lib/app/router.dart lib/core/di/injector.dart lib/l10n test/library_screen_test.dart
git commit -m "feat(w6): library screen (tabs, install progress, manage)"
```

---

### Task 5: Reader ayah sheet (tafsir/translation of the INSTALLED packs)

**Files:**
- Modify: `lib/features/quran/presentation/reader/reader_screen.dart` (ayah card affordance icon → `showModalBottomSheet` with a `LibrarySheet` widget; existing assertions must stay green unedited — hazard rule)
- Create: `lib/features/library/presentation/ayah_sheet/{ayah_sheet_cubit,ayah_sheet_state}.dart` (loads installed tafsir + translation for (surah, ayah); tabbed two-panes; empty → `libraryEmptyHint` + button routing `/library`)
- Modify: router (provide/lookup locations — sheet can read via getIt directly inside the sheet widget to avoid touching the reader route providers; PREFER getIt direct to keep the reader route untouched), injector
- Modify: ARBs (+regenerated)
- Create: `test/ayah_sheet_test.dart`, add ONE focused test into a NEW file — reader_screen stays frozen; the affordance presence is asserted via the sheet tests + a pump of the reader in the sheet file's harness if needed WITHOUT editing reader_screen_test.

- [x] **Step 1 (red-first — cubit):** with fixture-installed packs → tafsir text for (1,1) + translation text; no packs → empty state; uninstalled-but-cataloged → treated as absent.
- [x] **Step 2 (green):** sheet UI: title row (ayah coordinates via `surahName(1)`-style + number), tabs, scrollable text (uthmani reading comfort sizing), `libraryEmptyHint` يوجد لا تفسير مثبّت — نزّل من المكتبة/No tafsir installed — get one from the Library + routing button.
- [x] **Step 3: l10n (additive):** `ayahSheetTafsir` تفسير/Tafsir · `ayahSheetTranslation` ترجمة/Translation · `libraryEmptyHint` (above) .
- [x] **Step 4: Gates + commit**

```powershell
flutter gen-l10n
flutter analyze
flutter test test/ayah_sheet_test.dart test/reader_screen_test.dart test/reader_cubit_test.dart
git add lib/features/library/presentation/ayah_sheet lib/features/quran/presentation/reader/reader_screen.dart lib/core/di/injector.dart lib/l10n test/ayah_sheet_test.dart
git commit -m "feat(w6): reader ayah sheet (installed tafsir/translation, library link)"
```

---

### Task 6: Hadith browse (minimal, paged)

**Files:**
- Create: `lib/features/library/presentation/hadith_browse/{hadith_cubit,hadith_state,hadith_screen.dart}`
- Modify: router (a `/library/hadith?pack=` sub-route), injector
- Modify: ARBs (+regenerated)
- Create: `test/hadith_screen_test.dart`

- [x] **Step 1 (red):** cubit page-window tests over the bukhari fixture (offset arithmetic + hasMore); screen test renders a page from the fixture-installed pack.
- [x] **Step 2 (green):** numbered list rows (Arabic-Indic hadith numbers, `hadithNext/Prev` pagination buttons at the bottom, pack title + language badge in the app bar).
- [x] **Step 3: l10n (additive):** `hadithNext` التالي/Next · `hadithPrev` السابق/Previous.
- [x] **Step 4: Gates + commit**

```powershell
flutter gen-l10n
flutter analyze
flutter test test/hadith_screen_test.dart test/router_test.dart
git add lib/features/library/presentation/hadith_browse lib/app/router.dart lib/core/di/injector.dart lib/l10n test/hadith_screen_test.dart
git commit -m "feat(w6): hadith browse (paged numbered list, installed packs)"
```

---

### Task 7: Close-out

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

Expected: analyze 0; suite baseline 113 + ~16 (catalog 3 + wellformedness, downloader 5, library 4, ayah sheet 3, hadith 2; MEASURE per-file exact, ≈129 predicted — never trusted); debug exit 0 ballpark; release exit 0 + bytes (byte-exact expected); outdated: NO new packages this wave (assert in report); porcelain empty.
- [x] **Step 2: Tick this plan** — targeted line edits ONLY (header PROSE contains a literal `- [ ]`), .NET `UTF8Encoding($false)`, numstat + non-checkbox filter recorded:

```powershell
git add docs/superpowers/plans/2026-10-15-w6-library-packs.md
git commit -m "docs(w6): mark plan checkboxes complete"
```

- [x] **Step 3:** Final report — §1–§10 skeleton (start-gate verbatim · commit table · the three CDN probe quotes (status+bytes) · InstalledPacks companion-checkpoint quote · adapter-shape documentation (one quoted tree fragment per kind fixture) · gates table + per-file counts · itemized disclosures · STOPs · incidents self-caught · unpushed · state · NO PUSH).

## Explicit non-goals (this wave)

- supabase_flutter dependency, remote manifest fetch — blocked on the owner's Supabase project creation (pending owner item); the seam (CatalogSource) is the deliverable.
- Concurrent/queue installs (one-at-a-time v1; sequential queue = W7 if wanted), background downloads, resume.
- Full hadith chapter/section navigation, search within packs, multiple simultaneous tafsir compare view, ayah-by-ayah continuous tafsir reading mode.
- Supabase hosting of pack CONTENT (locked: manifest-only; content stays on the pinned CDNs; audio never on Supabase).
- Arabic pack discovery beyond the curated 9 (catalog is curated static — additions via plan errata only).

## Self-Review (PM, pre-dispatch)

- Zero new deps, zero schema change — InstalledPacks pre-exists (verified tables.dart). All network flows reuse the AudioDownloader discipline (stream, partial-delete, resolver closure); tests never touch the real CDN (fixture honesty).
- The wave's real risk is EXTERNAL-SHAPE assumption → fenced twice: live-probed pinned URLs at curation (probes quoted in report) + committed excerpt fixtures driving the adapters (no fabricated shapes).
- Frozen surface: router placeholder swap (`/library`) + one reader icon under the never-edit rule; everything else additive.
- Restart of Supabase reality check: the seam keeps the locked thin-layer architecture honest without blocking on the owner's project.
- Per-file test budget explicit; MEASURE rule standing (113 baseline; ≈129 predicted).

---

## PM RULING ON STOP W6-6 (Option A adopted + AR edition decision, 2026-10-15)

PM independently re-probed the STOP evidence at source: tafsir/ar-tafsir-muyassar/1.json pinned at v1.2.2 answered 200 with 5249 B, and ara-sirajtafseer.min.json answered 200 with 2,096,723 B — the executor's probes reproduce byte-exactly. The single-URL single-file assumption in T3 is a PLAN DEFECT for the tafsir kind. STOP ENDORSED; resume granted under the amended contract below.

### Amend T2 (catalog): tafsir entries gain two fields
- Optional urlTemplate (example pattern: the tafsir CDN base path with a placeholder for the surah number n in 1..114, files are plain n.json — probed, NOT zero-padded) and fileCount 114 for real packs (fixtures may use small fileCounts). sourceUrl stays for single-file kinds; tafsir entries carry urlTemplate instead.
- Wellformedness test updated: each of the 3 tafsir entries HAS urlTemplate + fileCount; translations and hadith entries HAVE sourceUrl.

### Amend T3 (downloader): kind-aware install
- Single-file kinds (translation/hadith): UNCHANGED — stream one URL into the dot-part file, parse-sniff, promote, install row.
- tafsir kind (STOP option A): sequential GET loop over the urlTemplate (n = 1..fileCount), accumulating the real per-surah arrays whose objects carry text/ayah/surah fields, then ONE documented wrapper of the shape pack=<id> plus a flattened tafsirs list (surah, ayah, text) written through the SAME discipline: streamed into the single dot-part, parsed-validated at the end, promoted, InstalledPacks row installed with measured size; ANY GET failure at any step means delete the dot-part and install NO row (one-shot integrity — generator semantics, not streaming).
- tafsirFor adapter reads the WRAPPER convention; wrapper and per-surah inner shapes are BOTH fixture-locked (excerpt fixture = the probed surah-1 array, 5249 B — well under the 40 KB cap; wrapper fixture constructed around it).
- Tests stay hermetic: the local HttpServer serves per-N files with a small fixture fileCount (production stays 114); the real CDN is never touched inside tests.

### Catalog decision (the disputed AR "translation")
- AR pick = ara-sirajtafseer (Mukhtasar at-Tafsir, quranenc source, 2,096,723 B probed) as the Arabic meaning-of-the-Quran entry in the translations tab.
- EN pick = eng-safiurrahmanalm (Saheeh International, 1,083,013 B probed).
- Third translations-tab entry: executor discretion — ONE more edition whose slug passes the same probe discipline (report the GET probe; the ara-quransimple/kingfahad debate is closed — pick any well-formed single-file edition to keep the 3-per-kind symmetry).
- Hadith trio unchanged (probes green: 9,409,647 / 4,821,289 / 3,940,216 B).
