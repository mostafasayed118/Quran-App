# S3-IT — On-device Integration Tests (3 offline journeys) — Executor Brief

Date: 2026-10-19 · Dispatched by the PM (owner GO 2026-10-19) · 2 commits · NO PUSH
Repo: `E:\old_flutter\Quran-App-master` · Worktree (pre-created): `E:\old_flutter\qy-wt-s3it`
@ branch `wave/s3-it` · base pin `6fd6243` · porcelain EMPTY at handoff.

## Why this wave exists

The repo's end-to-end confidence currently rests on widget tests + PM-run manual device legs.
This wave adds a small, offline-only `integration_test/` suite so the three critical journeys
can be re-proven on a real device in minutes (`flutter test integration_test -d <device>`).
Machine has **no device attached right now** — the on-device execution is the PM's device leg
(when the Infinix is reconnected); the executor's job is the code, compile-clean, analyze-0.

## Scope (binding)

Exactly these files, nothing else:
- `pubspec.yaml` — add to `dev_dependencies`:
  ```yaml
    integration_test:
      sdk: flutter
  ```
  (`pubspec.lock` gains the corresponding sdk entry — expected, disclose; nothing else may drift.)
- NEW `integration_test/app_harness.dart` — shared helpers:
  - `Future<void> bootApp(WidgetTester tester)` → `await app.main();` (import
    `package:quran_yahdi/main.dart` as app) + initial bounded wait for the home feature grid.
  - `Future<void> waitFor(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 15), Duration step = const Duration(milliseconds: 200)})`
    → pump loop until found; `fail('timed out waiting for $finder')` otherwise. **No bare
    `pumpAndSettle` without timeout** — bounded pumps are the house rule (drift streams keep
    the scheduler busy).
- NEW `integration_test/reader_journey_test.dart`, `integration_test/prayer_city_journey_test.dart`,
  `integration_test/azkar_journey_test.dart` — ONE `testWidgets` per file (so `app.main()`
  runs once per process; `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` in each
  file's `main()` before boot).

## The three journeys (offline only — no downloads, no network screens)

Finders MUST come from the existing UI read at source (visible Arabic labels, tooltips,
icons — e.g. read `lib/features/home/presentation/home_screen.dart` for the feature-tile
labels, `lib/features/quran/presentation/reader/reader_screen.dart` for the bookmark
affordance/icons, `lib/features/prayer/presentation/...` for the city affordance,
`lib/features/azkar/presentation/azkar_screen.dart` for the counter tap target). **No
`lib/` edits are allowed in this wave** — if a target is genuinely unfindable from the
existing UI surface, STOP and report with evidence.

1. **reader_journey_test.dart** — boot → home → tap the Quran feature tile → surah index →
   tap «الفاتحة» → reader visible → tap the bookmark toggle on the first ayah → assert the
   icon flipped → back to the index → reopen «الفاتحة» → assert the bookmark state persisted
   (a real DB write+read round-trip through the device).
2. **prayer_city_journey_test.dart** — boot → tap the prayer-times tile → times screen
   (assert a prayer label, e.g. «الفجر») → open the city picker → search «الإسكندرية» →
   select the result → assert the times screen now shows «الإسكندرية» (bundled cities,
   fully offline).
3. **azkar_journey_test.dart** — boot → tap the azkar tile → categories → open «أذكار الصباح»
   → tap the first counter target → assert the counter display incremented (Arabic-numeral
   format as rendered by the screen).

## Rules (binding)

- Worktree-only writes; explicit `git add <paths>`; `git add -A` banned; no amend; no
  fetch/pull/rebase/merge; **NO PUSH**; never touch `lib/`, `test/`, `docs/`, `.vscode/`,
  `INSTRUCTIONS.md`, or anything outside the scope list.
- Do NOT attempt `flutter test integration_test ...` (no device attached — it must not run;
  see STOP list).
- Deterministic: bounded waits only; no fixed long sleeps where `waitFor` fits; tests stay
  read-mostly (the reader journey writes one bookmark — acceptable, disclosed).

## Commits (byte-copy — DO NOT TRANSLATE)

1. `test(it): integration harness + reader journey (S3)` — pubspec + harness + reader file.
2. `test(it): prayer/city + azkar journeys (S3)` — the two remaining journey files.

## Gates

- Start: HEAD `6fd6243`, porcelain EMPTY, `flutter pub get`, **baseline** `flutter analyze`
  (0) + `flutter test` (record exact count — the unit suite; expect unchanged thereafter).
- After EACH commit: `flutter analyze` → 0; full `flutter test` → **count identical to
  baseline** (this also empirically proves `integration_test/` is not auto-collected); the
  pubspec.lock delta = the single sdk entry (verify + disclose).
- Staged-set check before every commit (`git status --porcelain` + `git diff --cached
  --name-status` = the intended list exactly).

## STOP list

- Any ask to touch `lib/`/`test/`/anything outside scope; any unfindable UI target.
- `flutter test` count changing (integration files got collected or a test broke).
- pubspec.lock drifting beyond the single sdk entry; analyze ≠ 0; unexpected reds.
- Attempting device runs (impossible here — report as "deferred to PM device leg").

## Report format (final message)

1. Start gate verbatim + pub get + baseline gates (analyze + exact count).
2. Per-commit: full SHA, `git show --stat`, byte-copied subject; published lock-delta line.
3. Gate tails after each commit (analyze line + test-count line; exits).
4. Confirmations: staged-set ×2; zero `lib/`/`test/` touches; worktree-only; no pushes;
   no device runs attempted.
5. Files delivered list + the exact future device command
   (`flutter test integration_test -d 13372704AR007777` — device disconnected today).
6. STOPs/deviations/disclosures (or "none").
7. Final state: porcelain, HEAD, "unpushed = 2 on wave/s3-it — NO PUSH", worktree retained.
