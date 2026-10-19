# Backup & Restore (user-controlled file) — Design Spec

Date: 2026-10-19 · Status: APPROVED by owner (2026-10-19) — all four decisions resolved (§8); implementation wave S3-BR briefed
Prepared by: PM session (Mode B artifact — English)

## 1. Why

All user data is device-local by design (zero accounts, zero telemetry). A device change or
factory reset silently loses bookmarks, last-read position, khatma/wird progress, prayer
logs, tasbih counts and settings. The privacy-compatible answer is a **user-controlled file
export/import**: nothing leaves the device unless the user explicitly shares/saves the file,
and nothing ever reaches a server of ours.

## 2. Scope (v1)

IN — **data-only merge**, one JSON file, share-sheet export, document-picker import.
Entity inventory **verified at source (2026-10-19, pre-implementation)** from
`lib/core/db/app_database.dart` + the feature repositories (a test pins the list so a
future table/key cannot be silently forgotten):

| Entity | Verified home | Merge rule (import into existing data) |
|---|---|---|
| Bookmarks | `bookmarks` table (`ayahId`, `createdAt`) | union by `ayahId` (dedupe; existing kept) |
| Last-read | settings key `last_read_ayah_id` (int string) | import wins when present & valid (1..6236) |
| Khatma/wird plan | `khatma_progress` single row (`ayahId`, `targetPages`, `updatedAt`) | newer `updatedAt` wins |
| Prayer log (worship tracker) | `prayer_log` table (day PK + 5 bools) | OR-merge per day (`true` wins) |
| Tasbih | settings key `tasbih_state` (JSON `{count,target}`) | `count` = max(current, imported); `target` = import wins (valid > 0) |
| Settings (whitelist) | `settings_table` keys, enumerated from the source key constants at implementation | import wins, key-by-key |

Feature-owned key names are used by backup **as string literals in one inventory file**
(production stays free of cross-feature imports — the architecture guard stays green);
a pinning test imports the real source constants and asserts equality, so a rename fails
loudly.

OUT (v1): downloaded audio/packs (re-downloadable, huge), cached CDN content, seeds,
cloud/auto backup (D9 future), encryption/password (plain JSON — user-mediated),
selective per-entity export.

## 3. File format

`quran_yahdi_backup_YYYY-MM-DD.json` — UTF-8 JSON object:

```json
{
  "app": "quran_yahdi",
  "format": 1,
  "exportedAt": "<ISO-8601>",
  "schemaVersion": <db schemaVersion int>,
  "data": { "bookmarks": [...], "lastRead": {...}, "khatma": [...],
            "prayerLog": [...], "tasbih": {...}, "settings": {...} }
}
```

Guards: decode size cap (**2 MB** — the data is tiny; anything larger is rejected before
parsing), `app`/`format` must match, unknown keys ignored, per-entry decode with
**skip + count** for corrupt entries (never crash, never partial-apply).

## 4. UX flows (Settings → «النسخ الاحتياطي والاستعادة» section)

- **Export:** «تصدير البيانات» → build JSON in one read transaction → temp file →
  `share_plus` share sheet (user picks destination: Files/Drive/chat). Success snackbar;
  failure → the house localized failure copy (never raw exception text).
- **Import:** «استيراد البيانات» → `file_picker` single-file pick (json) → decode+validate →
  **preview dialog**: per-entity summary («١٧ علامة جديدة · ٥ أيام عبادات · ...») with
  «دمج» / «إلغاء»; cancel = **zero DB writes** → on confirm: merge inside ONE drift
  transaction → if reminder-relevant keys changed, reschedule reminders through the existing
  scheduler → result snackbar. Never destructive: nothing is ever deleted by an import.
- All copy ARB-ified (additive + symmetric AR/EN, per house rule). Needed keys: section
  title, both buttons, preview dialog title/summary lines, merge/cancel, success, invalid
  file, import failure.

## 5. Privacy & data-safety

- Additive PRIVACY.md line (AR + EN, owner-reviewed wording): the backup file is created
  only on the user's action and goes only where the user sends it.
- Play Data-Safety answer is **unchanged** (the app itself transmits nothing).

## 6. Dependency

`file_picker` — the ONE new package (needs explicit owner grant). Justification: SAF
document picking on Android + `UIDocumentPickerViewController` on iOS with one API;
alternatives rejected — `receive_sharing_intent` (different UX: forces share-to-app),
manual path entry (hostile UX). `share_plus` (export) is already in the dependency set.

## 7. Testing & waves

- Unit: codec roundtrip; app/format/version guards; corrupt-entry skip+count; size cap;
  per-entity merge matrix (empty→file, file→empty, overlapping, conflicting timestamps);
  cancel-writes-nothing.
- Widget: settings entries present; preview counts correct; failure panes.
- Device leg (PM, on the Infinix): full export → import on a wiped install.
- Waves (each committed + gated, worktree protocol): **B1** codec + pinned inventory (pure,
  no UI) → **B2** export UI + share → **B3** import UI + preview + merge + reminder
  reschedule.

## 8. Owner decisions — RESOLVED 2026-10-19

1. `file_picker` — **GRANTED** (the single new dependency; latest stable at add time).
2. Settings whitelist — **INCLUDED** (§2 row).
3. Timing — **implement before the first store upload**.
4. PRIVACY.md addition — additive lines drafted in the S3-BR brief; **owner text review at
   the wave close-out** (committed as drafted; amendable by a follow-up commit).

## 9. Explicit non-goals

Cloud/auto backup · encryption · media/downloads · any server-side component ·
iOS-specific verification beyond code-readiness (Mac leg).
