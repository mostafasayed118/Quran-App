# F-D1 — fail-open boot (boot inits behind bounded timeouts) — Wave Brief (executor-ready)

**STATUS: READY TO DISPATCH** · Owner-GO 2026-10-20 · Source finding: F-D1 (device-leg ledger `986aedb`). · Date: 2026-10-20.

You are a fresh executor session in `E:\old_flutter\Quran-App-master` (branch `main`). Flutter 3.47.5 / Dart 3.13.4 · PowerShell 5.1 (no `&&`; use `;`). Single writer for YOUR files. **NO PUSH.** Parallel sessions may hold WIP — never touch or stage foreign files; explicit-pathspec commits only.

## Why (evidence — read the ledger entry `986aedb` for the full chain)

The DEBUG standalone boot reproducibly stalls at the splash on the Infinix X6882 (3 standalone launches + 1 clean uninstall/reinstall; Flutter engine warm, main isolate idle via VM-service, **zero logcat errors**). The SAME debug build boots fine under the integration-test harness (3/3), and the RELEASE build boots normally (<18s). Impact: dev-standalone launches only — but the fix is a user-side robustness win too. Hypothesis (unproven): one awaited plugin init never resolves on that path and nothing bounds it.

## Current boot (read first)

`lib/main.dart:19-54` — awaited: `configureDependencies(...)`, then `Future.wait([BackgroundInitGuard.attempt(JustAudioBackground.init…), getIt<NotificationsBinding>().init(...)])`. Everything after is already `unawaited` best-effort with try/catch (`_requestBootNotificationGrace`, `_openReminderLaunchTarget`, `_openDeepLinkLaunchTarget`, `runBootReminderSchedule`). `lib/app/bootstrap.dart` — asset loaders + `runBootReminderSchedule` (guarded, never throws).

## Scope (max 2 commits)

**C1 — `feat(core): fail-open boot init helper`**
- NEW `lib/core/utils/boot_fail_open.dart`:
  `Future<T?> failOpenBootInit<T>(String label, Future<T> Function() init, {required Duration timeout})`
  — races `init()` vs the timeout; on timeout OR any error: `dev.log(...)` under `quran_yahdi/boot` + return **null**; NEVER throws, never leaves an unhandled late-completion error. Pure/injectable.
- Unit tests: success returns the value; sync throw → null; async hang → null after a short real timeout; late completion after timeout is discarded cleanly (no unhandled error).
- Pathspec: the new file + its test under `test/`.

**C2 — `feat(app): bound the awaited boot inits`**
- `main.dart`: wrap the two `Future.wait` legs with `failOpenBootInit` (audio background init · notifications init) with generous const timeouts (start at 8s each; keep them consts with a comment). `configureDependencies` stays awaited and UNCHANGED (DI must be complete for `runApp`). **If evidence in-session shows `configureDependencies` itself hanging → STOP and report** (PM decides; do not improvise).
- Assess-first degradation check (read, then confirm in the report): after a timed-out notifications init, the later callers (`NotificationsBinding.launchPayload`, `requestBootPermission`, the tap callbacks) are all reached only through guarded call sites — verify no unguarded direct plugin access exists outside `notifications_binding.dart` (headless law).
- Tests: keep every existing test green (especially `smoke_test` boot); ADD tests only. Do NOT edit frozen tests. If the helper change needs a new smoke-path test, add a new file.
- Pathspec: `lib/main.dart` (+ the C1 import), the new test files.

## Gates (each commit)

`flutter analyze` 0 + full `flutter test` exact counts (record before/after) + `dart format --set-exit-if-changed lib test tools` stays green (CI gate is live). Explicit-pathspec commits ONLY.

## Post-merge (PM-owned — NOT executor scope)

Device proof on the Infinix X6882: reinstall the DEBUG APK standalone → 3 cold launches must reach HOME (or the fail-open path logs its bound and the app proceeds) — closes F-D1.

## STOP list

`configureDependencies` semantic change · any frozen-test edit · any file outside the pathspec · new packages · turning any guarded best-effort call into an awaited one · NO PUSH.
