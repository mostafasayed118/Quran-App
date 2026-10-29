# Post-audit remediation — 2026-10-28

> Campaign plan. Executed by subagents in disjoint lanes; one commit per task; gates per
> wave (`dart format`, `flutter analyze`, full `flutter test`). **No push.**

**Baseline:** branch `fix/perf-audit-2026-10-27`, HEAD `3de50ec`, 30 commits ahead of
`origin/main`, working tree clean except `.vscode/settings.json` (owner debris) and
`INSTRUCTIONS.md` (untracked owner notes). Gates at baseline: analyze **0**, format
**0 changed**, tests **765/765**.

**Source:** the read-only audit of 2026-10-28 (7 parallel dimension agents). Only
source-verified findings are listed here.

## Global constraints

- `AGENTS.md` is binding. Frozen tests are never edited; new tests go in new files.
- Commits: English, one concern, explicit pathspecs, `git add` never `-A`.
- Never touch/stage `.vscode/settings.json`, `INSTRUCTIONS.md`, `android/key.properties`.
- No new packages. l10n changes are additive + symmetric + regenerated.
- Executors do not commit and do not run the full suite; the PM commits and runs wave gates.
- Owner-gated, NOT executed here: screenshots, Play Console, CI push, `ara-bukhari`
  licensing decision, iOS.

## Tasks

| # | Wave | Task | Lane |
|---|---|---|---|
| 1 | 1 | Ayah sheet hides tabs that can never have content | library UI |
| 2 | 1 | Prayer reminder becomes genuinely optional | settings/notifications |
| 3 | 1 | Reminder apply cancels its own ids, not `cancelAll` | notifications |
| 4 | 2 | Downloads get a unique `(reciter, surah)` index + legacy repair | data |
| 5 | 2 | Bookmark paging keeps rows that fall off the first page | quran data/UI |
| 6 | 2 | Playback play-issuer seam so the P0 fix is testable | recitation |
| 7 | 3 | Cache the two `ThemeData` objects | theme |
| 8 | 3 | Search-index rebuild gets an isolate seam + test | core db |
| 9 | 3 | Architecture guard pins core→feature and layer-level edges | test |
| 10 | 3 | Library/reciter screens stop rebuilding the list on every progress tick | UI perf |
| 11 | 4 | Version + store docs truth pass | docs |
| 12 | 4 | README/AGENTS truth pass + campaign ledger close-out | docs |

Deferred with rulings (see
`2026-10-28-post-audit-remediation-ledger.md`): tafsir
reclassification to `kind: tafsir` (needs single-file tafsir install support), language
switch, `pumpAndSettle` migration, screenshots, push/CI, iOS.

## Gates

Per wave, from the repo root:

```powershell
dart format --output=none --set-exit-if-changed lib test tools
flutter analyze
flutter test
git status --porcelain
```

Record exact counts. A wave is not closed until all three are green.
