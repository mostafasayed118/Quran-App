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
| 3 | The mandatory update gate clips its only action at 320 dp, textScale 2.0 (Cairo: 40 px overflow, button ends at y=656) | high | B | **merged** (`23eee01e`, PR #59) |
| 4 | Countdown digit boxes are 34 dp vs 44 sp text | medium (latent) | B | **closed — not reproducible**: with Cairo at 2.0 the glyph is 26.5 px inside a 34 dp box at both 320 and 360; the 28/29 px came from the widget-test font. Reopen only if the font or the supported scale changes |
| 5 | Audio resume accepts any 206 without a validator; `total == 0` skips the only size check | high | C | **merged** (`7ef6b4a9`, PR #60): a stored validator is sent as `If-Range`; a 206 with no total, or a prefix with no validator, is dropped and refetched; a zero-byte file is not "done". Live probe: the CDN answers 206 for a matching validator and 200 with the full body for a wrong one |
| 6 | First-boot DB copy fallback is non-atomic and `exists → skip` makes a truncated DB permanent | high | C | **merged** (`7ef6b4a9`, PR #60): the fallback writes atomically, and a target whose header is not SQLite is moved to a timestamped aside and replaced; a valid DB is never touched. A truncated file that still has a valid header is **not** auto-repaired (decision) |
| 7 | Home-screen widget uses the device time zone; the app uses the selected city's | medium | E | **fixed** (Wave E PR): the background refresh formats the instant with `cityWallClock(…, city.timezone)`; the in-app path already did. A red test pins 13:30Z → ١٥:٣٠ in Africa/Cairo |
| 8 | `reminderAlarmIds()` uses `i < 2` instead of `kFajrFollowUpMinutes.length` | medium (latent) | E | **fixed** (Wave E PR, latent): both the planner and the clear set read the configured length; a test pins that every configured index is covered |
| 9 | Search index stamps `kContentVersion` even when the content refresh failed | medium (latent) | C | **merged** (`7ef6b4a9`, PR #60): two stamps — index format and **installed content** — with a one-time rebuild for installs that lack the content stamp |
| 10 | Azkar favourite tapped during the cold-start hydration is overwritten by the read | medium | D | **merged** (`fbe78581`, PR #61): the toggled ids are replayed over the read instead of overwriting it; both add and remove directions are covered |
| 11 | Overlapping qada saves revert to a snapshot older than a newer committed save | medium | D | **merged** (`fbe78581`, PR #61): writes are serialized and each computes from the last saved list; a failure reverts to it, not to a pre-mutation snapshot |
| 12 | Splash progress controller repeats for the app lifetime | medium (battery) | D | **merged** (`fbe78581`, PR #61): the looping bar is stopped when the overlay is dismissed; the probe checks that no frame is scheduled after the fade |
| 13 | Reader writes last-read + wird pointers for every ayah crossing the viewport | medium (jank) | D | **not proven**: the cubit already drops duplicate reports, so the writes are one last-read + one wird advance per **distinct leading ayah** (a fling past N cards costs N pairs), not per frame and not 150–300 per fling. No device frame measurement was possible (phone disconnected); recorded instead of changed on faith |
| 14 | Adhan selection and azkar count are not announced to TalkBack | medium (a11y) | B | **merged** (`23eee01e`, PR #59); **TalkBack verified** on the A16 emulator (row `selected=true`; card ends with «باقي ١») |
| 15 | The DST regression test is vacuous on the UTC CI host | medium (test gap) | E | **not closed**: the test only uses UTC instants and never names a local zone, but on a UTC host `DateTime(y,m,d+1)` and `+24h` are equivalent, so an in-process test cannot catch the regression; it needs a TZ-controlled runner. No code change |
| 16 | Frozen notification ids 1–4 are not pinned numerically | medium (test gap) | E | **fixed** (Wave E PR): the four id constants are pinned to 1–4 |
| 17 | Translation search normalizes every installed pack on the UI isolate | medium (jank/memory) | D | **hardened, merged** (`fbe78581`, PR #61): the UI-isolate block measured 51 ms for one pack / 120 ms for three on a **desktop host, JIT, pre-fix path** (~3 frames at 60 Hz, not device-measured); the normalization now runs through `Isolate.run`, with the runner injectable for tests |
| 18 | Tracker streak silently caps at 400 days | low | E | queued |
| 19 | Library shows pack size "٢.٠ م.ب" (double `toString`) | low | E | **fixed** (Wave E PR): `formatMegabytesValue` keeps a whole MB whole and a fraction to one decimal |
| 20 | README says 1450 tests; the suite is 1877+ | low | E | **fixed** (Wave E PR): refreshed to the current suite count |
| 21 | A folder with more than 999 bookmarks builds an `IN` list of that many SQL variables (`ayahsByIds`) | low (latent, post-audit) | — | **recorded, not fixed**: needs a power user past the engine limit; found by the Wave E sweep |
| 22 | More than 999 hadith bookmarks build the same kind of `IN` list (`hadith_store.byNumbers`) | low (latent, post-audit) | — | **recorded, not fixed**: same bound |

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

**Reproduced on the emulator (2026-11-16, A16_API36, debug build from
`85fb1b17`):** baseline **35** `RTC_WAKEUP` alarms → `am force-stop` → **0** →
re-launch → **0 after 30 s**. The process starts, the home loads, but the
restored snapshot's fingerprint still matches the plan, so `_applyPlan` returns
without scheduling. Toggling the prayer reminder off and on re-arms to 35.

**Why the phone recovered once:** the earlier 32 → 0 → 37 sequence happened
after hours, when the next-prayer window had moved, so the new plan's
fingerprint differed and `_applyPlan` re-armed. The recovery is incidental to
the fingerprint changing, not a detection of the cleared alarms.

**Diagnosis conclusion:** the same-boot snapshot trust is what suppresses the
re-arm; any external clear (force-stop, OEM freeze, a battery manager) leaves
the user with zero reminders until the plan changes or a setting is touched.
The fix needs a different signal, e.g. compare the OS's pending notification
count with the plan on `resumed` and re-apply when it is short, or read
`ApplicationExitInfo`; it is not a blind re-arm on every open.

**Fix and its verified behaviour (branch `wave/1b-alarm-probe`):**

- The binding probes two upcoming alarms through `PendingIntent.getBroadcast(
  FLAG_NO_CREATE)` with the plugin's exact identity (request code = the
  notification id, `ScheduledNotificationReceiver`, no action/data — read from
  `flutter_local_notifications` 22.3.2), and re-applies when either is gone.
  A `MissingPluginException` (a background isolate has no channel) skips the
  probe; any other probe failure re-arms.
- `ApplicationExitInfo` (10/11/13) is a helper signal read at `init`; the
  forced re-arm is consumed only by a successful apply.
- Emulator evidence (A16, debug build): 33 alarms → `am force-stop` → relaunch
  **33** (`force=true`); a normal resume leaves 33 with `alive=true` (no
  re-arm); `am kill` leaves the 33 alarms untouched — only force-stop clears
  them.
- **Inherent limit (recorded):** after a force stop the app is silent until it
  is opened once. Closing that gap needs a boot/package-replaced receiver or an
  external monitor, a separate decision that adds a permission and native code.
- **Still pending:** the same probe on the Infinix (phone disconnected at the
  time of the emulator run).

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
  and on the **Infinix X6882 (Android 14, SELinux Enforcing)** with the app's
  own UID (`run-as`): `/proc/sys/kernel/random/boot_id` is readable
  (`2724423c-af34-4233-8782-9420d9c98240` before the last reboot), while
  `/proc/uptime` returns `Permission denied`. The debug app's persisted
  `reminder_plan_v1` row carried the **actual value**
  (`"bootId":"926e43be-c180-409e-aed0-5a58f17e3d3e"`), so the binding stored a
  real id on the phone — not the null fallback. If the file were unreadable, the
  provider would return null and the binding would re-apply on every process;
  `test/reminder_plan_persistence_test.dart` covers that fallback and asserts
  one schedule per id, not duplicates.
- **Device re-arm evidence (Infinix, 2026-11-15/16):** a debug build cut after
  the fix was launched after a real `adb reboot` (boot id changed to
  `926e43be-c180-409e-aed0-5a58f17e3d3e`) with **0 alarms** on the device; it
  re-armed to **30** `RTC_WAKEUP` alarms with no user interaction. The owner's
  release build was still the pre-fix code and stayed at **0** after the same
  reboot — the defect reproduced live. Installing release **2008** (owner cert,
  `install -r`, `firstInstallTime` unchanged) and launching it took the release
  from **0 → 32** alarms. The release's own reboot leg was then measured:
  37 alarms → **0** after a second reboot (boot id `fad1f68d-7a1d-46b2-a0ad-14327d54b010`)
  → **37** after launching release 2008. The debug app was removed **after**
  reading its snapshot, as required.
- **#1b live observation (2026-11-16):** hours after the release had 32 alarms,
  the same boot showed **0** — with no reboot and no app update. Only launching
  the app re-armed them (37). That is the force-stop/OEM class the finding
  describes, observed on the owner's phone; the fix does not cover it.
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

## Wave B record

Branch `wave/b-a11y-scale`, cut from `6029d555`.

| Commit | Role | Red evidence |
|---|---|---|
| `7afe552f` | test: update gate at **320×640**, textScale 2.0, Cairo loaded | 2 failures — `RenderFlex overflowed by 40 pixels`, CTA ends at y=656 |
| `93fd40f1` | fix: pin the CTA, scroll the copy, 48 dp actions | 5/5 green |
| `24d5f6b7` | test: adhan `isSelected` + azkar count label | 2 failures — `isSelected` false; label is the dhikr text only |
| `33eb5d89` | fix: merged row semantics + count label (new AR/EN string) | targeted 13/13 green |

**Finding 4 was a false positive and no code changed for it.** The audit's
28/29 px came from the **widget-test font**, which draws every glyph at full em
width; the app ships Cairo. Measured with Cairo at textScale 2.0: the digit's
intrinsic width is **26.5 px** inside the existing 34 dp box at both 320 and
360, the row fits, and the before/after renders are pixel-identical. The
proposed box/FittedBox change was reverted rather than shipped as a fix for a
defect that does not reproduce.

**The same trap hit finding 3's numbers:** "424 px at 360" was the test font.
With Cairo the gate fits at 360 and overflows by **40 px at 320**, which is a
supported floor in this repo (the adhan picker probe uses 320). That is the
size and the number the probe now uses.

**Rule adopted:** a text-scale probe that asserts a shipped screen survives
must load the bundled font; the default test font is wider than any shipping
font and turns every screen into a false overflow. It is still useful as a
conservative stress test, but its failures are not evidence of a user-visible
defect.

**Permanent probe:** `test/update_gate_scale_probe_test.dart` (320 and 360,
Cairo, tap-after-scroll). `test/adhan_picker_semantics_test.dart` and
`test/azkar_count_semantics_test.dart` pin the announcements.

**Device TalkBack walk — done (2026-11-15, A16_API36 emulator):** on a debug
build that contains this wave, with TalkBack 15.x enabled:
- the adhan row's accessibility node is
  `content-desc="عبد الباسط عبد الصمد\nAbdul Basit Abdulsamad"`,
  `class=android.widget.Button`, and **`selected=true`**;
- the azkar card's merged `content-desc` ends with **«باقي ١»**, so the count is
  announced with its meaning rather than as a bare numeral.

The spoken audio was not captured (no audio pipeline on the headless emulator),
but the accessibility tree TalkBack reads is exactly the one above. **No
`liveRegion` is set**, so the count is read when the row is focused, not on
every tap.

**Infinix X6882 A/B (2026-11-15):** the pre-fix debug build exposed
`selected=false` on the adhan row; the post-fix build exposed **`selected=true`**,
and the azkar card's merged `content-desc` ended with **«باقي ١»** on the phone.

**Probe self-check:** `test/update_gate_scale_probe_test.dart` now measures the
app's own display style and fails if the ambient font is the test font (88.0 px)
instead of Cairo (26.5 px), so the overflow assertions can never silently
measure the wrong font.

## Wave C record

Branch `wave/c-data-integrity`, cut from `2115c882`. **Merged** as
`7ef6b4a9` (PR #60), fast-forward from `2115c882`: 14 commits, 12 files,
+797/−45; branch deleted after CI.

| Commit | Role | Red evidence |
|---|---|---|
| `b13d18b4` | test: content refresh | the index still held `'النص القديم'` |
| `e708128c` | fix: two stamps | — |
| `c4442830` | test: asset stamp pin | — |
| `7fa9647e` | fix(db): atomic fallback + non-SQLite repair | the old code kept `'not a database'` and `'garbage'` |
| `c06c97f3` | test(db): fixture header (Class A) | — |
| `c70a334c` | test: unverified resume + empty done file | one request only; `isDownloaded` true on an empty file |
| `4a0318d6` | fix: unknown total → restart; zero-byte not done | — |
| `0fa916b8` | test: If-Range | `If-Range` null; `bytes=40-` offered with no validator |
| `0780dc7d` | fix: If-Range + validator sidecar | — |

**#9 — what the audit got wrong and what landed.** The boot order is
`_ensureContentCurrentOffUiIsolate(db, dir)` then `_ensureSearchIndex(db)`
(`connection.dart:229-230`), and the refresh **swallows** its failure — so the
index builds after the *attempt*, not after success. The index now stamps the
**installed content version read from the DB** next to the format stamp, so an
index built from old content is rebuilt when the refresh later completes. An
install with only the format stamp rebuilds once; the shipped asset carries the
content stamp, and a test pins the asset's stamp to
`content_version == kContentVersion`, so a regenerated asset cannot ship a
mismatched index silently. Production passes no runner (`connection.dart:240`)
→ `Isolate.run`; the test proves the injected runner is used by the rebuild and
not by the skip.

**#6 — scope and decisions.** The primary mobile path was already atomic
(`.part` → rename). The fallback (`copyDbAssetIfAbsent`) is the path reached
when the worker reply is lost — documented in the code as observed on Android 16
— and it wrote directly with `exists → skip`. It is now atomic, and a target
whose first 16 bytes are not SQLite is moved to `<path>.corrupt-<timestamp>`
(never overwriting an earlier aside; the path is logged) and replaced. A valid
database, with user rows, is never touched. **Decision:** a truncated file that
still carries a valid header is **not** auto-repaired — an integrity check on
every boot is slow and can fail for reasons other than corruption, and the
atomic write stops new ones; reopen with a measured `quick_check` if a real
device ever reports one.

**#5 — evidence and decisions.** Live probe against `cdn.mp3quran.net` (3 files,
2 servers): `Range: bytes=0-99` → **206** with `Content-Range` and an ETag;
`If-Range` with the matching ETag → **206**; with a wrong ETag → **200** and the
whole body. The validator is stored beside the `.part`, written before the body
so a mid-body kill stays resumable, refreshed on a 200 and deleted with the
part. A prefix with no validator is discarded before the request; a 206 that
does not state the total is discarded and refetched whole; `isDownloaded`
requires a non-empty file. Class A (disclosed in the PR): two fixtures gained a
real SQLite header, two resume fixtures gained a validator, and the
unknown-total pin now asserts the owner's decision (drop + refetch) instead of
the old append.

**Gates at the final tip (`7ef6b4a9`):** format **0** · analyze **0** · suite
**1913/1913**; CI `analyze-test`, `db-drift`, `data-drift` and `gates` green.
The asset was regenerated with `tools/build_quran_db.dart` after `db-drift`
rejected the manual stamp.

**Device (Infinix X6882, 2026-11-15):** `boot_id` readable by the app UID with
SELinux enforcing (`/proc/uptime` denied). After a real `adb reboot` the
post-fix debug build re-armed from **0 → 30** alarms with no interaction, while
the pre-fix release build stayed at **0** — the defect and the fix side by side.
Installing release **2008** (owner cert, `install -r`, `firstInstallTime`
unchanged) took the release **0 → 32**; its own reboot leg is still unmeasured.

## Wave D record

Branch `wave/d-races-perf`, cut from `7548a710`. **Merged** as `fbe78581`
(PR #61), fast-forward: 9 commits, 12 files, +580/−31; branch deleted after CI.

| Commit | Role | Red evidence |
|---|---|---|
| `67c6fe82` | feat: shared `SerialQueue` + tests | — |
| `491300cc` | test: azkar favourite during hydration | added favourite lost (`Set[]`), removed one resurrected |
| `86271d85` | fix: replay touched ids over the read | 4/4 green |
| `7dcb6f28` | test: qada overlapping saves | two saves in flight; the failed day rode along in the next write |
| `269b812c` | fix: serialize writes, compute from `_confirmed` | 3/3 green |
| `6897c004` | test: splash frames after dismissal | `hasScheduledFrame` stayed true |
| `df83e712` | fix: stop the bar at dismissal | green |
| `08f2b979` | fix: translation preparation off the UI isolate | measured, not a failing test |

**#10** — the stored read is a snapshot from when it started; a toggle that
lands during it is newer. The cubit records the toggled collection ids and
replays their **final membership** over the read, so an added favourite
survives and a removed one is not resurrected; untouched favourites and
counters still come from the stored state. Opening a collection before
hydration already waits for the read (the existing test pins the untouched
counter case).

**#11** — writes go through one `SerialQueue`; every task recomputes its list
from the last **saved** list, so two saves cannot land out of order and a failed
save is not carried into the next write. A failure repaints only when it is the
newest mutation, from `_confirmed`. Tests: A fails/B succeeds → `[d2]`; A
succeeds/B fails → `[d1]`.

**#12** — `SplashScreen` wraps the whole app, so its State outlives the overlay.
The bar's `repeat()` kept a ticker alive; the probe pumps past hold+fade and
asserts `hasScheduledFrame` is false, which fails on the pre-fix code.

**#13 — not proven, no code.** `ReaderCubit.onVisibleAyah` drops duplicate
reports (`ayahId == _lastVisibleAyahId`), and `open` waits for hydration, so the
cost is one last-read write + one wird advance per **distinct leading ayah** —
a fling past N cards costs N pairs, not a write per frame and not the 150–300
the finding implied. A device frame measurement was not possible (phone
disconnected); recorded as not proven rather than changed on faith.

**#17 — measured, then fixed.** `prepareQuery` over every entry measured **51 ms
for one pack (6,236 entries) and 120 ms for three** on a desktop host — several
dropped frames on a phone. The normalization now runs through `Isolate.run`
(injectable for tests). Class A harness: the screen test injects a synchronous
runner because a real isolate future does not settle inside a `testWidgets`
body; assertions unchanged.

**Gates at the tip:** format 0 · analyze 0 · suite **1925/1925**; CI
`analyze-test` 8m42s and Cloudflare Pages green.

## Wave E record

Branch `wave/e-polish`, cut from `aefdfd98`.

| Commit | Role | Red evidence |
|---|---|---|
| `b70c30f4` | fix: Fajr follow-up bound | latent — the list has two entries, so a third is the failing case |
| `80f95a3f` | fix: whole-megabyte pack label | the row rendered `٢.٠ م.ب` |
| `ff8ee91a` | test: reserved ids pinned to 1–4 | — |
| `17f80cd1` | test: 400-day streak cap | expected 401, actual 400 |
| `503eafd7` | fix: wide lookback + range query | 7/7 |
| `e41dd9f1` | test: background widget clock | `١٣:٣٠` instead of `١٥:٣٠` |
| `c1cfe503` | fix: `cityWallClock` in the background refresh | green |

**#8** was latent by construction: `reminderAlarmIds()` iterated a hard-coded
two while `kFajrFollowUpMinutes` drives the planner. Both now read the same
length, and a test pins that every configured index is covered.

**#18's fix exposed a second defect:** `markedDaysRange` built an `IN` list with
one SQL parameter per day in the window, so widening the lookback failed every
tracker test ("too many SQL variables"). It now uses a range predicate
(`day >= start AND day <= today`); the lookback is a century-long storage bound,
not a product cap.

**#7** — the in-app card already converted with `cityWallClock`; only the
background refresh formatted the raw instant, so a widget refreshed by the
worker showed the device clock. A red test pins 13:30Z → `١٥:٣٠` in
`Africa/Cairo`.

**#15 — not closed.** The existing DST test only uses UTC instants and never
names a local zone. On a UTC host `DateTime(y, m, d + 1)` and `+24 h` are
equivalent, so no in-process test can catch the regression; it needs a
TZ-controlled runner. Recorded with no code change.

**#20** — the README count moved from 1450 to **1931**.

**Gates at the tip:** format **0** · analyze **0** · suite **1931/1931**.

**Merge:** `d07f6820` (PR #62), fast-forward from `aefdfd98`: 9 commits,
13 files, +228/−26. CI `analyze-test` 6m21s green.

**#15 — why it stays open.** The alternatives were tried on paper: `withClock`
controls `DateTime.now()` but not the process time zone, and the `timezone`
package can build `TZDateTime` values without changing what `DateTime(...)`
means locally. On a UTC host the two arithmetic forms are equivalent, so no
in-process test can catch the regression; it needs a runner started with a
TZ-controlled environment. Filed as the first item of the next wave.

**IN-list sweep (owner-requested).** The unbounded one was `markedDaysRange`
(fixed). Two more **latent** user-sized lists remain, recorded as findings 21
and 22: `ayah_repository.ayahsByIds` fed by one folder's bookmark ids, and
`hadith_store.byNumbers` fed by the hadith bookmarks. Both need >999 entries in
one lookup to hit the engine limit, so they are recorded, not fixed. The other
`isIn` uses are bounded (settings whitelist, reciter rows, ≤114 surah ids,
paged hadith numbers).

**#18 user-visible change:** a streak that was silently capped at 400 now
continues past it — intended, and worth a release-note line.

**Accounting (2026-11-16):** 17 fixed, 1 withdrawn as a false positive (#4), 2
not proven (#13, #15), 1 open (#1b), 2 latent added by the sweep (21, 22).

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

1. **#1b — diagnosis first, then a decision.** The live evidence is that 32
   alarms disappeared on the same boot with no update and no reboot; only an
   app launch re-armed them. Before any code: establish what clears them
   (force-stop, an OEM battery manager, or the app itself), because a blind
   re-arm on every start is exactly what the owner rejected. Candidate signals
   after the diagnosis: inspect the real alarms when the app opens, or re-arm
   on `resumed` when the live count is lower than the plan.
2. **#15 — first item of the next wave.** The DST test is vacuous on a UTC
   host; `withClock`/`timezone` do not change `DateTime`'s local zone, so a
   TZ-controlled runner is required. Until then it stays open by name.
3. **Latent IN lists (21, 22)** — a folder or hadith bookmark set past ~999
   entries; recorded, not fixed.
4. **Waves A–E** — merged; 13 and 15 are the only remaining not-proven items,
   and #1b is the only live defect.
