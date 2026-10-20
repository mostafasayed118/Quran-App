# A2 — عمل اليوم والليلة + بحث الأذكار — Wave Brief (executor-ready)

**STATUS: READY TO DISPATCH** · Owner-ratified (benchmark roadmap A2) · Date: 2026-10-19.

You are a fresh executor session in `E:\old_flutter\Quran-App-master` (branch `main`). Flutter 3.47.5 / Dart 3.13.4 · PowerShell 5.1 (no `&&`; use `;`). Single writer for YOUR files. **NO PUSH.** Parallel sessions may hold WIP — never touch or stage foreign files; explicit-pathspec commits only.

## Scope (v1)

1. **بحث الأذكار** — a local search field inside the Azkar screen that searches every collection and item, with proper Arabic normalization (tashkeel/tatweel-insensitive, alef/hamza/ya/taa-marbuta-folded), results list, and jump-to-item.
2. **عمل اليوم والليلة** — new occasion-based collection(s) in the existing azkar data (out-of-home/in-home, mosque, food & drink, clothing, travel, market…), texts cited from **حصن المسلم** (سعيد بن علي بن وهف القحطاني — public-domain compilation) with a `reference` field per item.

**Non-goals:** counters math changes (the reciting mode already handles `count`), audio, new screens/routes.

## Current state (verified at source 2026-10-19)

- Feature: `lib/features/azkar/` — `azkar_repository.dart` (`AzkarItem`/`AzkarCollection`/`AzkarRepository`), cubit with `AzkarBrowsing`/`AzkarReciting` states, `azkar_screen.dart`.
- Data: `assets/data/azkar.json` — `{"collections":[{id,nameAr,nameEn,items:[{text,count,(virtue|reference)}]}]}`; current ids: morning, evening, post-prayer, sleep, waking, general.
- Search-pattern prior art: the surah-index search (`lib/features/quran/presentation/index/`) — mirror its field/UX idioms.
- l10n: ARB additive+symmetric; generated files committed.

## Commits (each gated: `flutter analyze` 0 + full `flutter test` exact counts recorded before/after + `dart format --set-exit-if-changed lib test tools` stays green)

**C1 — `feat(core): Arabic search normalizer`**
- `lib/core/utils/arabic_search.dart` (or the closest existing utils home): pure `normalizeArabic(String)` + `matchesQuery(text, query)` — strip tashkeel (U+064B–U+0652, U+0670), tatweel; fold أإآٱ→ا, ى→ي, ة→ه, ؤئ→ء; collapse whitespace. Pure + unit tests with tricky fixtures (الرَّحْمَٰن → الرحمن matches «الرحمن»).
- Pathspec: the new lib file + its test.

**C2 — `feat(azkar): search across collections`**
- Cubit/state: an additive browsing-substate or field carrying `query` + `results` (collection id + item index); empty query restores the normal list. Repository: `search(query)` returning bounded results (cap ~50 with a hasMore flag or equivalent).
- Screen: search field at the top of the browsing view (mirror the surah-index field), results list showing collection name + item snippet, tap → opens that item in its collection (reuse the existing navigation into the reciting view).
- l10n: additive keys only (e.g. `azkarSearchPlaceholder`, `azkarSearchResultsFor`, `azkarSearchNoResults`) AR template → EN mirror.
- Tests: cubit search behavior + widget test with bounded pumps.
- Pathspec: `lib/features/azkar/**`, `lib/l10n/*` (ARB + generated), `test/azkar_search_*`.

**C3 — `feat(azkar): عمل اليوم والليلة occasions`**
- Add new collections to `assets/data/azkar.json` (ids like `daily-home`, `daily-out`, `daily-mosque`, `daily-food`, `daily-clothing`, `daily-travel` — executor's final naming): standard حصن المسلم entries per occasion, each with `count` and `reference` (book + chapter title, e.g. `"حصن المسلم — دعاء الخروج من المنزل"`). No invented texts; only the well-known published compilation wording.
- Data test: every item has text+count (non-empty), every collection has id/nameAr/nameEn, ids unique, JSON parses.
- **If any FROZEN test pins the azkar collection set/count → STOP and report** (do not edit frozen tests; PM will rule).
- Pathspec: `assets/data/azkar.json` + the new data test.
- **Owner text-review gate:** before the push window, the PM presents the C3 text diff to the owner for verbatim review (religious content).

## Gates / constraints
`flutter analyze` 0 · full `flutter test` exact counts (record before/after) · format gate green · explicit-pathspec commits · no new packages · frozen tests untouched (add new only) · NO PUSH.

## STOP list
Frozen azkar-data/test pinning conflicts · any file outside `lib/features/azkar/**`, `lib/core/utils/**`, `lib/l10n/**`, `assets/data/azkar.json`, and the new test files · invented or paraphrased religious texts (only published compilation wording) · NO PUSH.
