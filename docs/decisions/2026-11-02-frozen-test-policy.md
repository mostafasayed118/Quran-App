# Frozen-test policy — two classes, and the inventory allowance

> **Status:** owner-requested (2026-11-02): «قرار تجميد التيست ده هيوقفنا كل شويه عايزين نحله».
> **Scope:** `quran_yahdi` campaign waves (Mode B). Replaces the blanket
> "existing tests are never edited in campaign waves" rule with a two-class rule.
> **Owner ratification:** pending — this doc is the proposal the next wave runs under;
> until the owner ratifies it, Class B edits still need an explicit per-wave grant.

## The problem

The campaign rule "FROZEN TESTS: existing tests are never edited in campaign waves — any
perceived need to touch one = STOP and report" was written for **behaviour** tests, where an
edit is how a regression gets laundered into green.

But the repo also has a class of tests that assert a **complete set** of something that is
*designed to grow*: the backup settings whitelist, the fixed notification ids, the route map,
the l10n key surface, the pinned backup inventory literals. Adding a legitimate new member
(prayer calculation keys, a new route) makes those tests fail **by construction**, and the
blanket rule turns every such addition into a STOP + owner round-trip. That friction was paid
in the Wave A window (`test/backup_inventory_pin_test.dart`, twice) and it will be paid again
on every future settings/route/l10n addition.

## Decision

Two classes. The rule differs per class.

### Class A — behaviour pins (FROZEN)

A test that asserts **what a user sees or what the app does**: a widget renders, a cubit emits,
a repository writes, a reminder fires at a time, a screen degrades to an error.

- Never edited in a campaign wave.
- A product change that alters one is a **STOP**: report and wait for an owner ruling.
- The ruling is recorded in `docs/campaign-ledger.md` with the file and the exact assertion.

### Class B — inventory pins (editable under conditions)

A test whose job is to notice that a **declared set drifted from the code**: the whitelist
equals the owner constants, the planner owns exactly these ids, the router exposes these paths,
every ARB key has a getter. Its value is the *drift alarm*, not the exact membership.

A wave may update a Class B test when **all** of these hold:

1. **Additive, or a deliberate rename.** Removing a member to make a test pass is not allowed.
2. **Intent preserved.** Every existing assertion keeps its purpose. An `isNot(contains(...))`
   or an exclusion pin may only change when the excluded thing genuinely became exportable, and
   the wave says why.
3. **No behaviour assertion touched.** If the file also contains Class A assertions, only the
   inventory literal/set lines may change.
4. **Recorded.** The wave report lists the file and the exact set delta, and the ledger entry
   records it under "Class B inventory update".
5. **One edit per addition.** The new member is added to the inventory in `lib/` **and** to the
   test's expected set in the same commit, so the alarm stays honest.

## Design rule that keeps Class B cheap

Prefer a **single source of truth in `lib/`** (`kBackupSettingsWhitelist`,
`AppRoutes`, `preAdhanReminderId`, …) plus one test that pins it against the owner constants.
Then adding a member is one `lib/` edit and one test line — never a rewrite of the pin's
philosophy.

## Registry — the Class B files as of this decision

| File | What it pins |
|---|---|
| `test/backup_inventory_pin_test.dart` | backup string literals vs owner constants; the whitelist and reminder-relevant sets |
| `test/backup_settings_coverage_test.dart` | every user-preference settings key is exportable |
| `test/router_test.dart` | the approved route map (`containsAll`, so additions pass) |
| `test/notifications_binding_scheduling_test.dart` | the fixed planner ids in the cancel sequence |
| `test/notification_targeted_cancel_test.dart` | the targeted cancel trio |
| `test/backup_merge_validation_test.dart` | the accepted/rejected id bounds |
| `test/theme_typography_test.dart` | the Cairo weight census |
| `test/security_platform_config_test.dart` | the manifest/SDK pins |

Anything not in this table is Class A by default. Adding a file to this table is itself a
Class B edit (append-only, no removal): a pin only graduates to Class B when it asserts a set
that grows, never to excuse a behaviour change.

## What this does not allow

- Deleting, skipping, or weakening a behaviour assertion.
- Changing a pinned value (a reminder time, a page number, a copy string) to match new output.
- Editing a test to hide a bug: if the new behaviour is wrong, the test is right.
- Any edit at all without the wave reporting it.

## Consequences

- Wave A's backup widening (2026-11-02) becomes the first Class B update: eight preference keys
  added to the whitelist, five to the reminder-relevant set, with the delta in the ledger.
- Future settings/routes/l10n additions cost one `lib/` line plus one inventory line, no STOP.
- The owner keeps the real veto: a Class A edit, or a Class B edit that fails conditions 1–3,
  is still a STOP.
