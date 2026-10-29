# SDD ledger — plan: docs/superpowers/plans/2026-10-28-post-audit-remediation.md

Branch: fix/perf-audit-2026-10-27
Base HEAD at start: 3de50ec061f2ec8fc751e43000228eae81902f39
Unpushed at start: 30

## Pre-flight rulings

- Ruling: treat "نفذ الخطة كلها بالترتيب" as approval to COMMIT each task (the plan is commit-per-task) and NOT to push. Pushing stays an owner-GO window per AGENTS.md. — Cost if wrong: commits are local and revertable; the owner still owns the push gate.
- Ruling: run the campaign on the existing branch, not on main. AGENTS.md says waves run on trunk or a campaign branch; this branch is the campaign branch and is 30 commits ahead. — Cost if wrong: a later merge is needed (already required anyway).
- Ruling: Task 1 is implemented as "hide empty ayah-sheet tabs" rather than reclassifying Siraj to kind=tafsir. Reclassifying needs single-file tafsir install support (the tafsir install path is a per-surah wrapper: urlTemplate+fileCount, reader key `tafsirs`), which is an install-pipeline wave. The user-visible defect is the dead tab + false "no tafsir installed" copy. — Cost if wrong: the Siraj tafsir is still filed under the Translations tab; deferred as Task 13 candidate.
- Ruling: language switch (audit item 12) is deferred to a dedicated wave; the docs task removes any bilingual-UI claim instead. A locale toggle needs a persisted setting, a controller above MaterialApp, and settings UI. — Cost if wrong: 212 EN strings stay unreachable in v1.
- Ruling: screenshots, Play Console/CI push, `ara-bukhari` licensing, and iOS are owner-gated and are NOT executed here. — Cost if wrong: launch steps remain manual.
- Ruling: `pumpAndSettle` mass migration (161 sites) is deferred to a dedicated test-robustness wave; touching the shared harness mid-campaign would invalidate every wave gate. — Cost if wrong: the known flake risk stays.

## Task log

- Task 1: complete (87524cc) — `fix(library): hide ayah-sheet tabs with no installed pack`.
  4 new tests, green. Wave-1 lane.
- Task 3: complete (1a00fb2) — `fix(notifications): cancel only the planner's reminder ids`.
  3 new tests + 13 existing notification tests green.
  Ruling: the fix required updating five method-sequence expectations in the frozen
  `test/notifications_binding_scheduling_test.dart` that pinned the removed `cancelAll`
  call. Updated only the pinned method names (cancelAll → 3×cancel, 2→6 occurrences); no
  behavioural assertion changed. — Cost if wrong: the owner can revert that one commit; the
  alternative is dropping the media-notification fix entirely.
- Task 2: complete (ba145a9) — `feat(settings): make the prayer reminder optional`.
  17 files (incl. regenerated freezed + l10n). 4 new tests; 56 reminder/settings/boot
  tests green. Deviation accepted: boot + backup reschedule now go through the single
  flag-aware seam.
- Wave 1 gate: format FAILED on `test/notifications_binding_scheduling_test.dart` (my edit
  was not formatted); analyze 0; full suite **776/776**. Fixed by `86010b5` (style) and
  re-verified: format 0.
- Task 4: complete (f0bbf54) — `fix(downloads): enforce one row per reciter and surah`.
  4 new tests. Deviation accepted: drift's `insertOrIgnore` reports the surviving rowid, so
  the pair-scoped update runs unconditionally after the insert branch.
- Task 5: complete (2ee452b) — `fix(bookmarks): keep rows a shifted first page pushes out`.
  7 new tests. The implementer found a second live bug (stuck `loadingMore`); fixed in the
  same commit with its own RED test.
- Task 6: complete (0b30f16) — `test(playback): pin the fire-and-forget play contract`.
  3 new tests incl. a source guard; mutation-proven (reverting a call site fails the guard).
- Wave 2 gate: format 0 · analyze 0 · **790/790**.
- Task 11: complete (9ca0f3a) — store/version docs truth pass, version 1.0.0+3.
- Task 12: complete (34da466) — README/AGENTS truth pass + RECOVERY_PLAN archived.
  Follow-up fixes by the PM inside the same commit: licensing-matrix web-mirror claim,
  stale `reciter_repository.dart:57`, `PRIVACY` "font size"/"dark mode" claim, AGENTS §2
  header amended date.
- Task 7: complete (504792d) — `perf(theme): build each ThemeData once`. 4 new tests.
- Task 8: complete (d709076) — `test(db): pin the off-isolate search-index build`.
  3 new tests; mutation-proven. The job closure must stay in its own scope or it captures
  the unsendable drift handle.
- Task 9: complete (e2ce2ca) — `test(arch): pin core-to-feature and layer-level edges`.
  Live edges are exactly `quran->library`, `quran->recitation`; allowlist pruned 11 → 2.
- Task 10: complete (ecaf647) — `perf(ui): rebuild one row per download tick`.
- Task 13 (plans committed): 739db0f.
- Final gate: format **0 changed** · analyze **0** · tests **801/801** (exit 0).
- Ledger close-out: b2dc1cb. Final state: 45 commits ahead of `origin/main`, 0 behind,
  no push; porcelain = `.vscode/settings.json` (M) + `INSTRUCTIONS.md` (??) only.

## Follow-up window (owner: screenshots → docs → push)

- Owner rulings: bukhari **stays with the provenance note** (already at `PRIVACY*.md:63`,
  the in-app licenses tile, and the pinned jsDelivr commit + sha256); screenshots on the
  **Pixel 9 Pro emulator**; push only **after** screenshots + docs.
- Screenshots: built the signed `1.0.0+3` x86_64 APK (`PUBLISH_RELEASE=true`,
  apksigner-verified `DB:7F:FE…`, versionCode 3), installed on `emulator-5554`, set the
  emulator to 1080×2160 (2:1, Play-valid), seeded Cairo + the Siraj pack + two prayers,
  and captured all 11 screens via `adb screencap` + `pull`. Each was reviewed visually.
- Commit 2ccdd1b: 11 PNGs replaced + listing/play-console copy updated (no more "recapture
  before upload", REL-1 status now 2026-10-28, emulator source disclosed).
- Commit f8c7aa5: ledger addendum for both rulings.
- Gate transfer: `git diff b2dc1cb..HEAD -- lib test tools assets pubspec* android ios
  .github` is EMPTY; format 0 at the tip. The gated suite (801/801) therefore applies.
- Push: `git push origin f8c7aa5347500c8a0018871f0996734ba1c0d5aa:refs/heads/main` →
  `b626751..f8c7aa5`; ls-remote == HEAD; unpushed 0. CI `ci` 40724502574 +
  `web-gates` 40724502381 triggered on the SHA.

