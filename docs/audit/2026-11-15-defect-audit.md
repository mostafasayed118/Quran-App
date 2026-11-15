# Defect audit — 2026-11-15

Read-only audit of `quran_yahdi` at `8bb87a81` (main, clean). Five parallel
reviewers; every finding below was re-checked at source. Gates at the base:
`flutter analyze` 0, `flutter test` 1877/1877.

Load assumed: one user on a mid-range Android phone, offline. The web
subproject and iOS were not audited.

## Findings and wave plan

| # | Finding | Severity | Wave | Status |
|---|---|---|---|---|
| 1 | A reboot clears every alarm, and the persisted plan fingerprint suppresses the re-arm | critical | A | **merged** (`991da562`, PR #58) |
| 1b | Force-stop clears the alarms without changing the boot id; the plan is still trusted | high | open | **open — first follow-up** |
| 2 | Backup merge replaces whole document settings (notes, folders, hadith bookmarks, qada, favourites) | critical | A | **merged** (`991da562`, PR #58) |
| 3 | Mandatory update gate overflows at textScale 2.0; the update button is clipped (probe: 424 px) | high | B | queued |
| 4 | Countdown digit boxes are 34 dp vs 44 sp text; digits overlap at 2.0 (probe: 28/29 px) | high | B | queued |
| 5 | Audio resume accepts any 206 without a validator; `total == 0` skips the only size check | high | C | queued |
| 6 | First-boot DB copy fallback is non-atomic and `exists → skip` makes a truncated DB permanent | high | C | queued |
| 7 | Home-screen widget uses the device time zone; the app uses the selected city's | medium | E | queued |
| 8 | `reminderAlarmIds()` uses `i < 2` instead of `kFajrFollowUpMinutes.length` | medium (latent) | E | queued |
| 9 | Search index stamps `kContentVersion` even when the content refresh failed | medium (latent) | C | queued |
| 10 | Azkar favourite tapped during the cold-start hydration is overwritten by the read | medium | D | queued |
| 11 | Overlapping qada saves revert to a snapshot older than a newer committed save | medium | D | queued |
| 12 | Splash progress controller repeats for the app lifetime | medium (battery) | D | queued |
| 13 | Reader writes last-read + wird pointers for every ayah crossing the viewport | medium (jank) | D | queued |
| 14 | Adhan selection and azkar count are not announced to TalkBack | medium (a11y) | B | queued |
| 15 | The DST regression test is vacuous on the UTC CI host | medium (test gap) | E | queued |
| 16 | Frozen notification ids 1–4 are not pinned numerically | medium (test gap) | E | queued |
| 17 | Translation search normalizes every installed pack on the UI isolate | medium (jank/memory) | D | queued |
| 18 | Tracker streak silently caps at 400 days | low | E | queued |
| 19 | Library shows pack size "٢.٠ م.ب" (double `toString`) | low | E | queued |
| 20 | README says 1450 tests; the suite is 1877+ | low | E | queued |

## Open finding 1b — force-stop vs. the boot id

**What happens:** Android "Force stop" (and some OEM battery managers) cancels
every `AlarmManager` alarm but does **not** change
`/proc/sys/kernel/random/boot_id`. The persisted plan snapshot is therefore
still considered valid, and `init()` restores its fingerprint; `_applyPlan`
returns before scheduling. The user gets no reminders until the plan itself
changes (midnight roll or a settings edit).

**Why it is not in Wave A:** the owner approved a boot-count/boot-id fix for
the reboot case and explicitly did not want blind re-scheduling on every open.
Detecting force-stop needs a different signal (`ActivityManager`
`ApplicationExitInfo`, a foreground force-apply policy, or a platform channel),
which is a separate decision.

**Current mitigation:** none automatic. Toggling a reminder setting or
changing the plan re-arms the alarms. Reinstalling the app also clears the
snapshot (not recommended).

**Candidate fixes (next wave):**
1. A small Android method channel returning
   `ApplicationExitInfo.getHistoricalProcessExitReasons()` and forcing one
   apply when the last exit was `REASON_USER_REQUESTED`/`REASON_OTHER` and the
   alarms are expected to be gone.
2. Re-arm once on every **foreground** app start (not the 15-minute background
   worker). This covers force-stop but re-schedules on every open; the owner
   rejected blind re-scheduling without a decision.

## Verification notes

- **Boot id readability:** verified on the `A16_API36` emulator (Android 16)
  with the debug app's UID: `/proc/sys/kernel/random/boot_id` is readable;
  `/proc/uptime` returns `Permission denied`. The Infinix X6882 (Android 14)
  check is **pending** — the phone was not connected during the session. If the
  file is unreadable on a device, the provider returns null and the binding
  re-applies on every process; `test/reminder_plan_persistence_test.dart`
  covers that fallback and asserts one schedule per id, not duplicates.
- **Class A edit 1** — `test/reminder_plan_persistence_test.dart` (behaviour
  pin): two setup lines changed, assertions untouched.
  - before: `NotificationsBinding(store: store)`
  - after: `NotificationsBinding(store: store, bootId: () => 'boot-A')`

  The injection is required because the binding now asks for the boot id. The
  assertions are unchanged (same-boot new process must not rewrite the alarms);
  the reboot and null-boot-id cases are new tests.
- **Class A edit 2** — `test/backup_prayer_config_apply_test.dart` (behaviour
  pin): one assertion group updated because the accepted decision changed the
  behaviour it pins (daily azkar progress is now export-only).
  - before: `expect(outcome.summary.settingsKeysApplied, 2);`
  - after: `expect(outcome.summary.settingsKeysApplied, 1, reason: ...);` plus
    `expect(progress, isNull)` proving the daily document is not written.

  The font-scale half of the test is unchanged. Without the export-only
  decision this pin would have kept an unsafe import alive.
- **Backup merge semantics:** an entry that exists on both sides keeps the
  local value; the import never overwrites existing entries. `azkar_progress_v1`
  is one day's counters, not a date-keyed document, so it is **export-only**.
  An invalid imported document is skipped, the local value stays, and the
  preview reports the skipped count.

## Wave A record

Branch `wave/a-data-safety`, four commits ahead of `8bb87a81`; test-first
ordering is preserved so the red state is recoverable:

| Commit | Role | Red evidence |
|---|---|---|
| `6ac5bfd1` | test: reboot + null boot id | 2 failures (`reminder_plan_persistence_test`) |
| `acab1e28` | fix: trust a persisted plan only within the same boot | 7/7 green |
| `70488167` | test: document replacement + daily-progress import | 9 failures |
| `26649d14` | fix: merge document settings per entry | 23/23 green targeted |

Gates on the Wave A tip: `flutter analyze` 0 issues, `dart format` clean,
`flutter test` **1893/1893**. The Infinix X6882 device check for the boot-id
read is still pending (phone was not connected); the null fallback is covered
by a test, so an unreadable file degrades to one re-apply per process, not to
lost reminders.

## Wave plan (owner-ordered)

| Wave | Items |
|---|---|
| A | 1, 2 |
| B | 3, 4, 14 |
| C | 6, 5, 9 |
| D | 10, 11, 12, 13, 17 |
| E | 8, 16, 15, 19, 20, 7, 18 |

Each wave follows the same discipline: a test that fails first, the fix, full
gates, and a draft PR. No merge without owner review.

## Follow-ups (in order)

1. **#1b force-stop** — same defect from the other side: the user gets no
   reminders and no signal. Needs a decision on the signal (ApplicationExitInfo
   vs one foreground re-arm).
2. **Infinix X6882 boot-id check** — pending; the emulator is not the phone.
   If the file is unreadable there, the fix degrades to one re-apply per
   process (safe, not the goal).
3. **Wave B** — 3, 4, 14 (text-scale overflow and TalkBack), with a permanent
   probe at 360×640, scale 2.0 so they cannot come back.
4. **Wave C** — 6, 5, 9.
5. **Wave D** — 10, 11, 12, 13, 17.
6. **Wave E** — 8, 16, 15, 19, 20, 7, 18.
