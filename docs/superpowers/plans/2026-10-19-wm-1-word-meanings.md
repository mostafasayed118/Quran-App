# WM-1 — Word Meanings (معاني الكلمات) — Wave Brief (executor-ready)

**STATUS: PRE-DISPATCH — GATE G1** · Date: 2026-10-19 · Owner-ratified feature (benchmark D2-A) · Dispatch ONLY after G1 clears.

**G1 — License gate:** a written confirmation from Tafsir Center (cloud@tafsir.net) is received and recorded (email archived under `docs/` by the PM). Until G1, this wave MUST NOT run; the data source must not be bundled.

You are a fresh executor session in `E:\old_flutter\Quran-App-master` (branch `main`). Toolchain: Flutter 3.47.5 / Dart 3.13.4 · PowerShell 5.1 (no `&&`; use `;`). Single writer for YOUR files. **NO PUSH.** A parallel session may hold WIP in `lib/`/`web/` — never touch or stage foreign files; explicit-pathspec commits only.

## Feature (v1 scope)

Tap a word while reading (verses mode) → bottom sheet: the vocalized word, its **Arabic meaning**, its **root + repetition count**, and the attribution line. Fully offline (bundled data), Arabic-first; EN mirrors only the UI labels.

**Non-goals (v1):** mushaf-mode word tap · i'rab/sarf tabs · English glosses · word search · word audio.

## Source data (PM-verified at source, 2026-10-19)

- Input: `quran.db` from `tafsircenter/tafsir-mcp` (Hugging Face `tafsircenter/tafsir-mcp-data`), sha256 `10e61f615ab5e6a3440e8ecc8ba1dc2273d12cd9048752760fe53a44d191cc27`, **CC BY 4.0** (attribution: «معاني الكلمات: مركز تفسير للدراسات القرآنية (https://tafsir.net) — CC BY 4.0»).
- Tables used: `word_content_meaning` (77,432 rows: surahNo/ayahNo/wordNo/meaning) · `word_content_rasm` (bare word) · `word_statistics` (vocalized `wordText`, `root`, `repeatitionCount`, `rootRepeatitionCount`).
- The 223 MB `quran.db` is **NOT committed**; the PM supplies its path. The committed derived artifact is small (see C1).

## Alignment facts (PM-verified; the executor re-derives these at build time and fails on drift)

- Their word indexing: 77,432 words over 6,236 ayahs.
- Our `ayahs.text_imlaei` naive split: 77,491–77,492 tokens; **~60 ayah exceptions (~1%)**, each off by one — Uthmani rasm merges two imlaei tokens: «أو»+«لا/لم/لما/كلما»، «ها»+«أنتم/أولاء»، «لو»+«ما».
- Our `ayahs.text_uthmani` (what the reader displays) splits to **words + exactly ONE trailing ayah-marker token**: 6,233 of 6,236 ayahs are their-count +1; 3 ayahs need manual derivation (likely marker merged).
- Required invariant: for every ayah, `tokens(text_uthmani) − marker == tokens(text_imlaei)`, and their exception mapping covers the ~60 merges. The build tool asserts all 6,236 ayahs map 1:1 to their `(surahNo, ayahNo, wordNo)`; any new mismatch = STOP and report.

## Files & commits (each commit gated: `flutter analyze` 0 + full `flutter test` exact counts recorded before/after)

**C1 — `feat(tools): word-meanings extraction + alignment verifier`**
- Create `tools/build_word_meanings.dart` (input: path to `quran.db` via arg; reads via the `sqlite3` package already in the toolchain used by `tools/build_quran_db.dart` — mirror its idioms).
- Outputs (committed): `assets/json/word_meanings_v1.json` (compact arrays `[surah, ayah, wordNo, wordText, meaning, root|null, wordRepeats, rootRepeats]`, ~9–10 MB) + `assets/json/word_alignment_exceptions.json` (the ≤60 merge entries: `{surah, ayah, merges: [[ourTokenIndexStart, theirWordNo], …]}`).
- Pure-Dart unit tests for the alignment verifier on fixtures (no quran.db needed in CI): valid map passes; introduced mismatch fails.
- Commit pathspec: `tools/build_word_meanings.dart`, `test/word_meanings_*`, the two JSON assets.

**C2 — `feat(db): word_meanings table + content-version bump`**
- Extend `tools/build_quran_db.dart` so the regenerated `assets/db/quran.sqlite` includes table `word_meanings(surah, ayah, word_no, text, meaning, root, word_repeats, root_repeats, PK(surah,ayah,word_no))` built from the committed JSON; regenerate the asset.
- Drift: new table class in `lib/core/db/tables.dart` + generated code; new `WordMeaningRepository` (read-only lookup by surah+ayah); bump `kContentVersion` 1→2 and include `word_meanings` in the reseed path of the content-version refresh (user-owned tables stay untouched).
- If any FROZEN test fails because of the schema addition → STOP and report (do not edit frozen tests).
- Commit pathspec: `tools/build_quran_db.dart`, `assets/db/quran.sqlite`, `lib/core/db/*`, `test/*word*`/db-bootstrap tests you ADD.

**C3 — `feat(reader): tap-a-word meaning sheet (verses mode)`**
- `_AyahCard` renders `ayah.textUthmani` as `Text.rich` with one `TextSpan` per word (+ non-tappable marker span). Tap → haptic → `showModalBottomSheet` following the `LibrarySheet` call pattern in `reader_screen.dart`.
- Sheet: vocalized word (font per house style), meaning, root chip + «تكرّر N مرة», attribution footer (l10n key).
- Exception ayahs apply the merge mapping (tap on either merged token opens the same word).
- l10n: additive keys only, AR template → EN mirror, symmetric (add to both ARB + regenerate).
- Tests: mapping (pure) + widget test with bounded pumps (no `pumpAndSettle` while drift loads).
- Commit pathspec: `lib/features/quran/**` (reader files), `lib/l10n/app_ar.arb`, `lib/l10n/app_en.arb`, `lib/l10n/app_localizations*.dart`, `test/reader_word_*`.

**C4 — `docs: word-meanings attribution`**
- PRIVACY.md + README «المحتوى والمصادر»: add the Tafsir Center credit line (verbatim above).
- Commit pathspec: `PRIVACY.md`, `README.md` (+ `PRIVACY.en.md` when it references sources).

## STOP list
G1 not cleared · source db absent or sha mismatch · alignment invariant fails beyond the known exceptions · any need to edit a frozen test · any file outside your pathspec · packages beyond the grant set (none needed) · NO PUSH.
