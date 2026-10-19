# A1 — ورد الختمة (daily wird + khatma plan) — Wave Brief (executor-ready)

**STATUS: READY TO DISPATCH** (owner-ratified in the Almosaly benchmark, `docs/superpowers/plans/2026-10-19-almosaly-benchmark-decision.md`) · Date: 2026-10-19.

You are a fresh executor session in `E:\old_flutter\Quran-App-master` (branch `main`). Toolchain: Flutter 3.47.5 / Dart 3.13.4 · PowerShell 5.1 (no `&&`; use `;`). Single writer for YOUR files. **NO PUSH.** A parallel session may hold WIP — never touch or stage foreign files; explicit-pathspec commits only.

## Feature (v1 scope)

A quiet, fully-offline **ختمة/ورد** plan on the existing worship tracker: choose a khatma length, see today's portion, open the reader at your bookmark position, progress is recorded as you read, and an optional daily reminder. No gamification (no points/rankings — house rule).

**Non-goals (v1):** prayer-time-anchored reminder (follow-up wave) · multiple concurrent plans · behind-schedule notifications · group/social khatma · automatic page-pace adjustment.

## Current state (PM-verified at source, 2026-10-19)

- `KhatmaProgress` table exists in `lib/core/db/tables.dart` (`id`, `ayahId`, `targetPages`, `updatedAt`) — **no code uses it yet**. v1 uses it as-is (no schema change): one active plan row; `ayahId` = read-up-to pointer (global ayah id 1..6236), `targetPages` = chosen length in mushaf pages (604 full مصحف; offer 604/302/201/151 ≈ 30/60/90/120 days… executor proposes, owner sees final labels).
- Tracker: `TrackerScreen`/`TrackerCubit`/`PrayerLogRepository` (prayer log + streak). Wird card slots under the streak chip.
- Reader: mushaf mode = `PageView` + `onMushafPageChanged` in the cubit; ayah rows carry `page` + global `id`; deep-link routing pattern already exists (`deep_links.dart`; payload→route mapping used by `'prayer'`/`'azkar'`) — follow it for `'wird'`.
- Reminders: `reminder_planner.dart` (pure, ids 1/2: prayer + azkar; settings keys `azkar_reminder_enabled/time`). **Owner supersedes the earlier "two keys" ruling:** A1 adds a third kind.
- l10n: ARB AR template → EN mirror, additive+symmetric.

## Commits (each gated: `flutter analyze` 0 + full `flutter test` exact counts recorded before/after)

**C1 — `feat(tracker): khatma repository + plan model`**
- `KhatmaRepository` over `KhatmaProgress`: start plan (targetPages), current plan, advanceTo(ayahId) (max-wins), pagesFromAyah(ayahId) via `ayahs.page`, reset/complete.
- Pure progress model (pages done / total, %, remaining days at current pace) + unit tests.

**C2 — `feat(tracker): wird card (setup · today's portion · progress)`**
- Tracker screen card: no plan → setup bottom sheet (length choice); active → progress bar, «اليوم: من صفحة X إلى Y» (derived: pointer page + daily pages), CTA «افتح الورد» → reader at pointer (reuse the existing reader-route + initial-ayah mechanism), CTA «أنهيت ورد اليوم» (manual advance by one day's portion → first ayah of the next page; completion state at the last page).
- l10n additive keys (wird/setup/progress/today-range/completion) AR→EN.
- Widget tests with bounded pumps (no `pumpAndSettle` with drift).

**C3 — `feat(reader): record wird progress while paging`**
- While a plan is active, mushaf page changes advance the pointer to the greater of current pointer / first ayah of the visible page (never backward).
- Tests: cubit-level with a fake repository + one widget-level bounded test.

**C4 — `feat(notifications): wird reminder (id 3)`**
- Planner: `wirdReminderId = 3`, settings keys `wird_reminder_enabled` + `wird_reminder_time` (HH:mm, default e.g. 20:00 — executor picks, owner may adjust), today-or-tomorrow rule identical to azkar; payload `'wird'`.
- ReminderTexts gains wird title/body inputs (keep the class constructor backward-compatible so existing frozen planner tests stay valid — if any frozen test must change → STOP and report).
- Tap routing: extend the existing payload routing so `'wird'` opens the tracker screen; routing test like the existing ones.
- Commit pathspec: notifications files + `lib/l10n/*` + `test/*wird*`/planner tests you ADD.

## STOP list
Need to edit a frozen test (esp. reminder-planner tests — add new ones instead) · any schema migration beyond nothing (v1 needs none) · files outside pathspec · packages beyond grants (none needed) · NO PUSH.
