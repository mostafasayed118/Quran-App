# Top-5 remediation plan — 2026-10-30

> Campaign plan for the five verified issues in
> `docs/superpowers/audits/2026-10-30-code-quality-audit.md`.
> One commit per wave. No push. Executors do not touch `docs/`.
>
> **Status at publication (2026-10-30 01:38).** A concurrent session is landing
> the audit's maintainability findings. HEAD moved `c76063a` → `418d0d0`, and
> W2's code change (single write path) landed in `e9d72f0` **without** the
> parity test. Re-check `git log` and re-pin the start gate before dispatching;
> skip any wave whose fix is already an ancestor of the dispatch tip.

## Baseline (pin verbatim)

| Item | Expected |
|---|---|
| `git rev-parse HEAD` | `c76063a4eaf24f5174cd0ab500dcb1d86128dde1` (audit snapshot — re-pin to the live dispatch tip; it was `418d0d0` at publication) |
| `git status --porcelain` | `.vscode/settings.json` (M), `INSTRUCTIONS.md` (??), `assets/icons/logo_1.png` (??), `assets/icons/logo_2.png` (??), `web/design-concepts/` (??) — **owner debris, never stage** |
| `git rev-list --count origin/main..HEAD` | `0` |
| `flutter --version` | Flutter 3.47.5 / Dart 3.13.4 |
| `dart format --output=none --set-exit-if-changed lib test tools` | 462 files, **0 changed** |
| `flutter analyze` | **0 issues** |
| `flutter test` | **815 / 815** |

Any mismatch = **STOP** and report; do not "fix" the baseline.

## Global constraints

- `AGENTS.md` is binding. FROZEN TESTS: existing tests are never edited. A perceived need = STOP.
- New tests go in **new files**; no new packages; no new `// ignore:` suppressions.
- UI copy stays localized; no raw exception strings reach the UI.
- Commits: English, one concern, explicit pathspecs, `git add` never `-A`.
- Never touch/stage `.vscode/settings.json`, `INSTRUCTIONS.md`, `assets/icons/logo_*.png`, `web/design-concepts/`, `android/key.properties`.
- **No push, no PR, no rebase/merge/fetch.** The PM commits; an executor may commit only if the brief says so.

## Waves

| # | Wave | Issue | Commit message |
|---|---|---|---|
| 1 | W1 | **LANDED `7d3983c`** — first-open search-index rebuild blocked the DB executor | `perf(db): ship the Quran search index prebuilt` |
| 2 | W2 | **LANDED `e9d72f0` + `3099912`** — backup restore had two parallel write paths | `test(backup): parity test for both write paths` |
| 3 | W3 | **LANDED `e712e64`** — settings mutations could emit invented values after a failed load | `fix(settings): never emit invented values from a failed load` |
| 4 | W4 | **LANDED `7045a96`** — router resolved optionally-registered repositories | `fix(di): optional features degrade instead of throwing` |
| 5 | W5 | **LANDED `b90ea1a`** — audio redirect was not re-validated | `fix(recitation): revalidate every audio redirect hop` |

Order is deliberate: W1 is boot-path and asset-touching; W2/W3 are state-integrity; W4 is DI; W5 is security and independent.

---

### W1 — Ship the Quran search index prebuilt

**Problem.** `lib/core/db/connection.dart:229-231` awaits `_ensureSearchIndex(db)` before returning the executor. `lib/core/db/search_index.dart:27-29` rebuilds when the `search_index_version` stamp is missing or stale, and `tools/build_quran_db.dart` neither creates `ayah_search` nor writes the stamp. On every fresh install (and every content bump) the first query waits on 6,236 normalization+inserts.

**Files owned.** `tools/build_quran_db.dart`, `assets/db/quran.sqlite`, `lib/core/db/search_index.dart` (stamp constants only if needed), `test/search_index_asset_stamp_test.dart` (new).

**Required change (preferred, A).**
1. In the generator: create `ayah_search(ayah_id INTEGER PRIMARY KEY, text_norm TEXT NOT NULL)`, insert the same rows `rebuildQuranSearchIndex` would produce (reuse `normalizeSearchEntries`/`normalizeArabic`, do not fork the normalization), and write `settings_table('search_index_version', '<kContentVersion>')`.
2. Regenerate `assets/db/quran.sqlite` with the existing tool; the runtime path is unchanged and should now short-circuit at `search_index.dart:28`.
3. Add one test that opens a copy of the shipped asset in a temp dir and asserts (a) `search_index_version == kContentVersion`, (b) `SELECT COUNT(*) FROM ayah_search` is 6,236, (c) the first normalized row is non-empty.
4. Record the asset size delta in the commit body.

**Fallback (B) — only if A cannot be made deterministic.** Return the executor first and expose a `Future<void> searchIndexReady` that `QuranSearchRepository` awaits; the DB open must not await it. A "preparing search" state must be visible, not a silent empty result. Do not do both.

**Acceptance.** App boots with no `rebuildQuranSearchIndex` call when the asset is current (test-pinned); generator rerun twice produces an identical `sha256`; DB delta < 2.5 MB.

**Commit.** `perf(db): ship the Quran search index prebuilt` — explicit pathspecs for the tool, the asset, search-index code, and the new test.

**STOP.** Generator needs source data that is not in the repo; two runs differ byte-wise; delta ≥ 2.5 MB; a frozen test pins the old build-at-boot behavior.

---

### W2 — Parity test for the landed single write path

**Status: LANDED** — code `e9d72f0`, parity test `3099912`. `_writePlan` builds one companion list and delegates the khatma write to `_writeKhatma`, and the new test forces both branches via the `batchThreshold` seam and compares all four tables.

**Problem (historical, for context).** The old `_writePlan` duplicated the khatma insert/update block between a sequential branch and a `db.batch` branch; a fix on one path could miss the other on restore.

**Files owned.** `test/backup_write_path_parity_test.dart` (new). `lib/features/backup/data/backup_service.dart` only if a test seam is unavoidable.

**Required change.**
1. If needed for the test, add an optional `@visibleForTesting int? batchThreshold` (default `_batchThreshold`, `backup_service.dart:45`) — no behavior change in production.
2. Parity test: apply the same plan to two fresh in-memory DBs, one forced below and one above the threshold, then dump and compare `bookmarks`, `prayer_log`, `settings_table`, `khatma_progress` row sets.

**Acceptance.** Both branches produce identical table dumps; existing backup tests unchanged and green.

**Commit.** `test(backup): parity test for both write paths`.

**STOP.** The landed refactor cannot be exercised through a seam without changing production behavior — report instead.

---

### W3 — Settings never emit invented values

**Problem.** `lib/features/settings/presentation/settings_cubit.dart`: six `SettingsState.ready(...)` emits rebuild all seven fields from `_xOf(state)` helpers; after `SettingsFailed`, `_prayerEnabledOf` returns `true` (:250-254), so a mutation emits a "ready" state with fabricated settings.

**Files owned.** `lib/features/settings/presentation/settings_cubit.dart`, `test/settings_failed_state_guard_test.dart` (new).

**Required change.**
1. At the top of every mutator (`setPrayerEnabled`, `setAzkarEnabled`, `setTime`, `toggleWird`, `changeWirdTime` — re-verify the set in the file): if `state is! SettingsReady`, return without writing or emitting.
2. Replace each `SettingsState.ready(...)` with `current.copyWith(field: value)` (freezed `SettingsReady` already generates it — `settings_state.dart:13-21`).
3. Delete the `_xOf` helpers that become dead.
4. Test: a cubit in `SettingsFailed`, call each mutator, assert no repository write and no `SettingsReady` emit; a ready cubit still emits exactly one `copyWith` state per mutation.

**Acceptance.** No fabricated defaults remain; ready-state emits are field-local; existing settings tests green.

**Commit.** `fix(settings): never emit invented values from a failed load`.

**STOP.** A frozen test pins the fabricated behavior, or the UI requires mutations while failed (report instead of guessing).

---

### W4 — Optional features degrade, not throw

**Problem.** `lib/app/di/injector.dart:138-169` registers `AzkarRepository`, `DuaRepository`, `RuqyahRepository`, `AsmaRepository`, `CatalogRepository`, `PackDownloader` only when the matching loader/resolver is passed; `lib/app/router.dart:205` (and `:225-226`, `:240`, `:265`) resolves them unconditionally. `injector.dart:70-73` promises an empty-state degradation that does not exist.

**Files owned.** `lib/app/di/injector.dart`, `lib/app/router.dart`, `test/optional_features_degrade_test.dart` (new).

**Required change.**
1. Mirror `_emptyCitiesLoader` (`injector.dart:52-56`) with an empty loader per type and register the content repositories unconditionally: azkar, duas, ruqyah, asma, catalog.
2. Keep `PackDownloader` conditional (it needs a writable root), but add a `redirect` on `/library` and `/library/hadith` back to `/` when `!getIt.isRegistered<PackDownloader>()`. No loop: `/` is home.
3. Test: `configureDependencies` with only `audioRootResolver` + `citiesLoader`, pump `/azkar`, `/duas`, `/asma`, `/library`; assert empty/localized states and **no** `unregistered type` throw.

**Acceptance.** No `getIt<T>()` on a route can throw for a missing optional loader; production registrations unchanged.

**Commit.** `fix(di): optional features degrade instead of throwing`.

**STOP.** Making a repository unconditional requires a loader signature change that ripples beyond the two files; the redirect approach conflicts with a frozen navigation test.

---

### W5 — Revalidate every audio redirect hop

**Problem.** `lib/features/recitation/data/audio_downloader.dart:124-128` calls Dio with default redirects; `isTrustedAudioServer` (`reciter_repository.dart:86-92`) validates only the initial URL, and audio has no sha256 pin, so a compromised CDN can redirect to `http://` or a foreign host.

**Files owned.** `lib/features/recitation/data/audio_downloader.dart`, `test/audio_redirect_guard_test.dart` (new).

**Required change.**
1. Request with `followRedirects: false`.
2. Follow at most 3 hops manually: resolve `Location` against the current URL, require `https` + `isTrustedAudioServer`, then re-request.
3. Any non-trusted hop, a non-http(s) scheme, a missing `Location`, or >3 hops → delete the `.part` file and throw the existing `DownloadFailure` (localized at the UI boundary).
4. Test with a fake `HttpClientAdapter`: trusted→trusted succeeds; trusted→`http://` fails; trusted→foreign host fails; 4-hop chain fails; no `.part` survives a failure.

**Acceptance.** No byte is written to the final path unless every hop is on the allowlist.

**Commit.** `fix(recitation): revalidate every audio redirect hop`.

**STOP.** Dio's adapter API in 5.11 does not allow a deterministic fake without a new package (report; do not add one).

---

## Gates (per wave, from the repo root)

```powershell
dart format --output=none --set-exit-if-changed lib test tools
flutter analyze
flutter test
git status --porcelain
```

A wave is not closed until format = 0 changed, analyze = 0, tests = **previous count + the wave's new tests, 0 failures**, and porcelain = owner debris only.

## Final report format

Start-gate output verbatim · per-wave commit SHA + `--stat` · gate tails with exact counts · confirmation bullets · STOPs/deviations/disclosures · final porcelain + unpushed count. **No push.**

## Close-out (2026-10-30)

| Wave | Commit | Result |
|---|---|---|
| W1 | `7d3983c` | asset `4,173,824 B` (+901,120 B); 6,236 index rows + `search_index_version` stamp; generator deterministic (two identical sha256) |
| W2b | `3099912` | `batchThreshold` test seam; khatma insert + update parity across forced per-row/batch branches; all four tables compared |
| W3 | `e712e64` | every mutator guards on `SettingsReady` and emits `copyWith`; fabricated defaults deleted; 3 new tests |
| W4 | `7045a96` | azkar/duas/ruqyah/asma/catalog register with empty fallbacks; `/library` + `/library/hadith` redirect home without `PackDownloader`; 1 new test |
| W5 | `b90ea1a` | 3-hop manual redirect chain, every hop re-validated against the mp3quran allowlist; 6 new tests |

Combined gate on the committed content: format **0 changed** · analyze **0** ·
tests **826/826** (11 new). No push.

**Disclosure:** the four waves were developed in parallel on one tree with
disjoint file ownership and gated together; the per-commit tips were not
independently re-gated in isolation.

## Deferred (not in this plan)

W1 fallback B if A lands; the remaining Low findings in the audit (test-fixture consolidation, `freezed`/lint exclusions, `beforeOpen` versioning, D2D extraction rules, CI action pinning, Gradle verification metadata, `en` locale decision). Each is its own wave with its own ruling.
