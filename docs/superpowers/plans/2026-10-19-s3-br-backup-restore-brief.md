# S3-BR — Backup & Restore (user-controlled file) — Executor Brief

Date: 2026-10-19 · Owner GO with ALL FOUR decisions resolved (file_picker granted ·
settings whitelist included · before first store upload · PRIVACY draft for close-out
sign-off).
Repo: `E:\old_flutter\Quran-App-master` · Worktree (pre-created by the PM):
`E:\old_flutter\qy-wt-s3br` @ branch `wave/s3-br` · **base pin captured at dispatch**
(verify against the dispatch message).
Binding spec: `docs/superpowers/specs/2026-10-19-backup-restore-design.md` (hash pin in
the dispatch message — verify before reading; mismatch → STOP).

## Why

All user data is device-local by design. A device change loses bookmarks, last-read,
khatma/wird plan, prayer logs, tasbih, settings. The privacy-compatible answer:
user-controlled JSON file — export via the system share sheet, import via a document
picker with a preview + non-destructive merge. Nothing reaches any server of ours.

## Pinned inventory (verified at source 2026-10-19)

| Entity | Home | Merge rule |
|---|---|---|
| Bookmarks | `bookmarks` table (`ayahId`, `createdAt`) | union by `ayahId` (existing kept) |
| Last-read | settings key `last_read_ayah_id` (int string) | import wins, valid 1..6236 |
| Khatma/wird plan | `khatma_progress` single row (`ayahId`, `targetPages`, `updatedAt`) | newer `updatedAt` wins |
| Prayer log | `prayer_log` (day PK + 5 bools) | OR-merge per day (`true` wins) — match `prayer_log_repository.dart`'s day convention exactly |
| Tasbih | settings key `tasbih_state` (JSON `{count,target}`) | `count`=max; `target`=import wins (valid >0) |
| Settings whitelist | `settings_table` keys (enumerated at impl from source key constants — city, moshaf row, prayer/azkar/wird reminder enable+time, theme, font, + any similar user preference found) | import wins per key |

## Architecture rules (guard-tested — binding)

- **Production backup code imports ONLY**: its own files + `lib/core/**` + packages.
  ZERO other-feature imports (the architecture guard scans `lib/features/**`).
- Feature-owned key names are used as **string literals in ONE file**
  (`lib/features/backup/data/backup_inventory.dart`); a pinning TEST
  (`test/backup_inventory_pin_test.dart`) imports the REAL source constants (notifications
  `reminder_settings.dart` keys, tasbih `tasbih_state`, quran `last_read_ayah_id`,
  recitation `selected_moshaf_row`, prayer city key, settings theme/font keys — grep each
  at implementation) and asserts equality → a rename fails loudly. Tests may import across
  features; production may not.
- Reminder reschedule is an **injected callback** in DI (composition root wires it, reusing
  the existing boot-schedule helper — read `lib/app/bootstrap.dart` `runBootReminderSchedule`
  + `lib/core/di/injector.dart` for the pattern). No feature import, no new edge.

## Commits (3 — byte-copy, DO NOT TRANSLATE)

1. `feat(backup): versioned backup codec + pure merger + inventory pin (S3-BR)`
2. `feat(backup): backup service — gather, transactional merge-apply, reschedule hook (S3-BR)`
3. `feat(backup): settings section — export via share sheet, import via file picker with preview (S3-BR)`

### C1 — codec + merger + inventory (no UI, no deps)

Create:
- `lib/features/backup/data/backup_codec.dart` — `kBackupAppId = 'quran_yahdi'`,
  `kBackupFormat = 1`, `kBackupMaxBytes = 2 * 1024 * 1024`; `BackupDocument`
  (`exportedAt`, `schemaVersion`, typed `data`); `encode(...)` and
  `decode(String raw)` → sealed result: `BackupDecodeFailure(reason)` |
  `BackupDecodeSuccess(document, skippedEntries)`; wrapper guards (`app`, `format` — fail
  closed); **per-entry decode with skip+count** (corrupt entries never crash, never
  partial-apply). File format exactly per spec §3.
- `lib/features/backup/data/backup_merger.dart` — PURE per-entity merge functions
  returning (rows to write / changes) + summary counts, all rules per the table above.
- `lib/features/backup/data/backup_inventory.dart` — the whitelist const + key literals
  (the single cross-feature key surface — literals only, with a comment naming each owner
  file).
- Tests: `test/backup_codec_test.dart` (roundtrip; app/format/version guards ×; size cap;
  corrupt-entry skip+count; unknown keys ignored), `test/backup_merger_test.dart` (matrix
  per entity: empty↔file / overlap / timestamp conflict), `test/backup_inventory_pin_test.dart`
  (literal ≡ source-constant equality for every key).

### C2 — service + DI + tests

Create `lib/features/backup/data/backup_service.dart`:
- Constructor: `{required AppDatabase db, required Future<void> Function() reschedule}`.
- `Future<String> exportJson()` — gather all entities from the db (one read pass),
  `schemaVersion` from the db, encode.
- `Future<BackupSummary> preview(BackupDocument doc)` — computes counts (new bookmarks,
  merged days, plan replaced?, tasbih delta, settings keys applied) WITHOUT writing.
- `Future<BackupOutcome> apply(BackupDocument doc)` — merge + write in **ONE drift
  transaction**; invoke `reschedule()` ONLY when any reminder-relevant key changed
  (also only after a successful apply). Never deletes user data.
Modify `lib/core/di/injector.dart` — register `BackupService` (db + reschedule closure
mirroring the existing boot-schedule wiring; read the file first).
Tests: `test/backup_service_test.dart` — in-memory db: export→(fresh db)→apply→state
equality; merge-into-nonempty per entity; reschedule called iff reminder keys changed
(counter callback); apply failure path leaves db unchanged (inject a failing write if
cheap — else disclose why untested).

### C3 — UI + file_picker + l10n + PRIVACY

- `pubspec.yaml`: `flutter pub add file_picker` — latest stable (record the version; lock
  delta MUST be additions-only — report the full delta list).
- Create `lib/features/backup/presentation/backup_state.dart` (freezed) +
  `backup_cubit.dart` + `backup_section.dart`:
  - Section: title + «تصدير البيانات» row + «استيراد البيانات» row; busy/disabled states;
    localized failure copy (house ErrorStrip/errorPane idioms — never raw exceptions).
  - Export: write JSON to a temp file (path_provider, existing dep) → `share_plus`
    (check the CURRENT share API at source — see the reader share affordance for the
    house pattern) → success/failure feedback.
  - Import: `file_picker` single `.json` file → read bytes → size cap → decode → **preview
    dialog** (per-entity counts + «دمج»/«إلغاء»; cancel = ZERO writes) → apply → summary
    snackbar; invalid file → localized error.
- Modify `lib/features/settings/presentation/settings_screen.dart`: minimal insertion of
  the section (read the screen first; keep the existing structure intact).
- l10n: additive + symmetric ARB keys (AR template → EN mirror) + `flutter gen-l10n`
  (committed generated files). Enumerate: section title, export row, import row, preview
  title, merge, cancel, success (export/import), failure (export/import), invalid file.
  Placeholders ONLY if the generated-l10n precedent supports them (check existing ARB);
  else compose static labels + Arabic numerals via the existing helper.
- PRIVACY additive lines (EXACT drafts — owner text sign-off pending at close-out, commit
  as drafted, do not touch other lines):
  - `PRIVACY.md` (AR) — append as a new bullet in «البيانات المحفوظة على جهازك»:
    `- يمكنك تصدير بياناتك يدويًا إلى ملف من الإعدادات، ويُشارك الملف إلى الوجهة التي تختارها أنت فقط؛ ولا يُرسل أي شيء إلى أي خادم أثناء ذلك.`
  - `PRIVACY.en.md` (EN) — mirrored bullet:
    `- You can manually export your data to a file from Settings; the file goes only to the destination you choose — nothing is sent to any server in the process.`
- Tests: `test/backup_section_test.dart` (rows render; export failure → failure copy;
  preview dialog shows counts + cancel = zero-write spy) + cubit coverage as needed.

## Frozen tests

- `test/settings_screen_test.dart` is **FROZEN — zero grants**: the settings-screen
  insertion must not break it. If it reds → **STOP + report verbatim**; do not edit it.
- No other existing test file may change.

## Gates

- Start: HEAD pin, porcelain EMPTY, `flutter pub get`, baseline `flutter analyze` (0) +
  `flutter test` (record exact count).
- After EACH commit: analyze **0**; full test = baseline + that commit's new tests (report
  exact counts; C3 also proves the settings suite is unchanged). Expected new tests
  (ranges, exact = yours): C1 ≥ 12, C2 ≥ 6, C3 ≥ 3.
- Flake under load → one re-run, report both.

## STOP list

- Frozen-test red (`settings_screen_test`) or any need to edit an existing test.
- Architecture-guard red (any new production cross-feature edge — the design forbids it).
- `file_picker` lock delta beyond additions; analyze ≠ 0; anything outside scope;
  plan/spec hash mismatch; worktree not empty.

## Report format

1. Start gate verbatim + pub get + baseline (analyze + exact count).
2. Per-commit: full SHA, `git show --stat`, byte-copied subject.
3. Gate tails per commit (analyze line + test-count line + exits) + the final count math.
4. Confirmations: staged-set ×3 (exact lists), frozen compliance, guard test green
   (the architecture guard ran inside the suite), zero production cross-feature imports,
   worktree-only, zero pushes.
5. `file_picker` version + full lock-delta list (additions-only proof).
6. PRIVACY drafts committed — flagged for owner sign-off; exact lines quoted.
7. STOPs/deviations/disclosures (or "none").
8. Final state: porcelain, HEAD, "unpushed = 3 on wave/s3-br — NO PUSH", worktree retained.

## Non-goals

Cloud/auto backup · encryption · media/downloads · iOS verification beyond code-readiness ·
selective export · any server component.
