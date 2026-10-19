# A1b — Wird reminder toggle (Settings → reminders section) — Wave Brief (executor-ready)

**STATUS: READY TO DISPATCH** · Owner-ratified 2026-10-19 (toggle placement decision; recorded in the A1 ledger entry). · Date: 2026-10-19.

You are a fresh executor session in `E:\old_flutter\Quran-App-master` (branch `main`). Toolchain: Flutter 3.47.5 / Dart 3.13.4 · PowerShell 5.1 (no `&&`; use `;`). Single writer for YOUR files. **NO PUSH.** A parallel session may hold WIP — never touch or stage foreign files; explicit-pathspec commits only.

## Why (state at dispatch — verified at source 2026-10-19)

A1 landed the wird reminder **read-path already wired**: `ReminderSettings.wirdEnabled()` / `wirdTimeHm()` getters exist (keys `wird_reminder_enabled` / `wird_reminder_time`, default `defaultWirdTimeHm = '20:00'` in `reminder_planner.dart`); `scheduleReminders` already reads both and passes them to the planner with `loc.reminderWird`; the planner branch + tests are green. **Missing (this wave = the entire write-path):** setters + settings state/cubit/screen controls. The engine is dormant until this lands.

## Scope — mirror the azkar reminder flow EXACTLY (read it first)

Files (read the azkar equivalents before writing anything):
- `lib/features/notifications/data/reminder_settings.dart` (azkar setters as the template)
- `lib/features/settings/presentation/settings_cubit.dart` + `settings_state.dart` (+ freezed regen)
- `lib/features/settings/presentation/settings_screen.dart`
- `lib/l10n/app_ar.arb` (template) → `app_en.arb` mirror (+ regenerate; generated files committed)

**C1 — `feat(settings): wird reminder persistence + cubit wiring`**
- `ReminderSettings`: add `setWirdEnabled(bool)` + `setWirdTime(String)` — same 'true'/'false' + 'HH:mm' conventions as azkar, same insertOnConflictUpdate pattern.
- `SettingsState.ready`: add `wirdEnabled` (bool, default false) + `wirdTimeHm` (String, default `defaultWirdTimeHm`).
- `SettingsCubit`: hydrate both from settings; add `toggleWird(enabled)` + `changeWirdTime(hm)` following the azkar flow verbatim (persist → the shared permission-request path → `scheduleReminders` re-plan; denied permission keeps the same `permissionDenied` hint semantics).
- Tests (add new): enable persists + re-plans; time change persists + re-plans; denial shares the hint path.

**C2 — `feat(settings): wird reminder rows in the reminders section`**
- `SettingsScreen`: in the reminders section add the wird toggle row + time tile mirroring the azkar widgets (same styling/48 dp/haptics; time tile opens material picker once enabled; Arabic-Indic display via the existing helpers).
- l10n: additive keys only (AR template → EN mirror, symmetric) — toggle label + time row; naming follows the existing `settings*`/`reminder*` conventions (e.g. `settingsWirdReminder*`).
- Tests (add new): widget tests with bounded pumps — default render, toggle delegates to cubit, time tile opens only when enabled. Do NOT touch frozen settings tests.

## Gates (each commit)
`flutter analyze` 0 + full `flutter test` exact counts (record before/after) + `dart format --set-exit-if-changed lib test tools` stays green (CI gate is live — a format miss fails CI). Explicit-pathspec commits ONLY.

## STOP list
Any frozen test needing edits (add new instead) · any file outside `lib/features/settings/**`, `lib/features/notifications/data/reminder_settings.dart`, `lib/l10n/**`, and the new test files · any planner/scheduler change (already wired — if something feels missing, STOP and report) · new packages · NO PUSH.
