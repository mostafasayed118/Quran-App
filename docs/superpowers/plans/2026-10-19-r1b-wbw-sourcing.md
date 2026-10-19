# R1b — Word-by-Word Sourcing Pass (Target B resolution attempt)

Date: 2026-10-19 · Follow-up to `2026-10-19-r1-license-dossier.md` (R1)
Result: **No clean PUBLIC license exists for an English word-gloss layer · a CLEAN Arabic word-meaning path was found (CC BY 4.0) · decision pending**
Method: PM deep-probe of QUL without an account + a research subagent across Hugging Face / GitHub / Kaggle / Zenodo / open Arabic-NLP projects + **PM re-verification of every load-bearing claim at source**. Zero material discrepancies (two nuances recorded in the appendix).

---

## Decisive findings

1. **The root of the English WBW gloss chain (the real blocker).** Every dataset containing per-word **English** glosses traces to one compilation: **Dr. Shehnaz Shaikh & Ms. Kausar Khatri (emuslim.com)** — credited verbatim on quranwbw.com/about (PM-verified: *"Dr. Shehnaz Shaikh and Ms. Kausar Khatri … for their English word by word compilation"*; and Tafsir Center *"granting us special permission to use their word by word audio files"*). No public license; permission-based only. That chain feeds quranwbw.com, QUL resource 92, and the wider ecosystem.

2. **QUL license state (practically a dead end for now).** QUL's FAQ says (PM-verified verbatim): *"Yes, you can use QUL data in commercial projects. However, please review the licensing terms for each resource. Some data may have restrictions or require attribution…"* — but the resource pages display **no licensing terms at all** (PM-verified: 8 QUL pages incl. docs/resources/translations → **0 "license" mentions**; resource page variants → no license text). License-clarification issues remain **open with zero comments** (PM-verified via GitHub API):
   - #765 — "License for English word-by-word transliteration (resource 71)" — opened 2026-09-24
   - #812 — "License clarification needed for French word-by-word translation (resource #95)" — 2026-10-08
   - #891 — "Licenses for commercial use of specific QUL resources" — 2026-10-15
   The account-side export check is therefore **very unlikely** to yield a citable license.

3. **Clean alternative found — Arabic word meanings under CC BY 4.0.** `tafsircenter/tafsir-mcp` `quran.db` (Tafsir Center for Quranic Studies, مركز تفسير للدراسات القرآنية):
   - License: **CC BY 4.0** — PM-verified on two surfaces: repo `LICENSE-DATA` + Hugging Face card `license:cc-by-4.0` (machine-readable).
   - Required attribution: *"Tafsir Center for Quranic Studies (https://tafsir.net)"*.
   - Contents: 77,432 words / 6,236 ayahs; per-word fields: `word_content_rasm` (Uthmani), `word_content_meaning` (**Arabic** meaning), `word_content_irab`, `word_content_sarf`, roots/stats; SQLite 214 MB, HF-hosted, SHA-256 pinned.
   - Caveat (PM-verified): the repo's "Acceptable Use" says *"Commercial redistribution of tafsir texts requires permission from rights holders"* — recommendation: **one confirmation email to `cloud@tafsir.net`** and ship **word-level fields only** (meaning/i'rab/sarf/root), not tafsir texts. A 100%-free app is non-commercial, but written confirmation removes the ambiguity.
   - This satisfies the D2 rule's spirit **for Arabic meanings**: explicit license, citable, redistributable, attribution clarity.

4. **Near-miss with perfect shape, zero license.** `Buraaq/quran-md-words` (HF) — 77,429 rows, fields `word_ar` / `word_en` / `word_tr` + audio, full coverage. PM-verified: **no license tag, no LICENSE file** (HF API + file tree), derived from unlicensed quranwbw chain. **REJECT as-is** (watchlist only).

5. **Adjacent clean assets (audio, not gloss).** `quranhive/quran_word_by_word_audio_mapping` + GitHub repo — **CC BY 4.0** (PM-verified on both), word-level audio mapping, useful later for a memorization companion. `dev-ahmedhany/quran-wbw-audio` — CC0 declared (CAUTION: uploader CC0 over mirrored reciter audio). Not glosses; recorded for the roadmap.

6. **Everything else swept and rejected with reasons** (each fetched at source): Kaggle `alizahraja/quran-nlp` (corpus-like provenance → GPL regime), `hosein7hosein/Quran_Full_Database_Word_By_Word` (repo Apache-2.0 only; data provenance undocumented; bundles third-party tafsirs), `uthumany`/`ibnuh`/`AhyaanTech`/`SakinaDevGroup` (provenance-void data), `SadaqaWorks` data re-audit (still undocumented), Zenodo (nothing), KFGQPC (nothing openly licensed).

---

## Bottom line vs the D2 rule

- **English gloss: does NOT satisfy "freely redistributable with a publicly citable license."** Realistic paths: (a) written permission from emuslim / Shaikh–Khatri (a permission-track email — long shot), (b) monitor QUL issues #765/#891 (unreliable timing), (c) drop.
- **Arabic word meanings: CLEAN PATH FOUND** — CC BY 4.0 (Tafsir Center) + one confirmation email + attribution. This satisfies D2 **if the email confirms** and we ship word-level fields with the required credit.

## Recommended decision set (owner)

- **D2-A (recommended, if the feature stays):** ship **word meanings in Arabic** from `tafsir-mcp` word fields (CC BY 4.0, attribution "Tafsir Center … https://tafsir.net", confirmation email sent). English gloss deferred to the permission track.
- **D2-B:** send the written-permission request to emuslim (English gloss); no blocking, revisit if a reply lands.
- **D2-C:** drop the word-by-word feature entirely.

---

## Verification appendix (PM re-fetches, 2026-10-19)

Verified verbatim by the PM in this session: tafsir `LICENSE-DATA` (+ HF `cardData.license=cc-by-4.0`) · `DATA_SOURCES.md` commercial clause · quranhive HF + GitHub · Buraaq license absence + file tree (`data/`, README, no LICENSE) · QUL issues #765/#812/#891 (open, 0 comments, titles + dates) · QUL FAQ quote · quranwbw.com/about credits (Shaikh/Khatri/emuslim/Tafsir-Center permission) · hosein repo `Apache-2.0` · dev-ahmedhany HF `cc0-1.0` · QUL 8-page zero-license scan.

Nuances (honest):
1. Kaggle `mojahidabdoo/quran-words-meaning` CC0 claim could **not** be re-verified by PM fetch (Kaggle API returned HTML) — treat as UNVERIFIED, fallback-only, Arabic-only, coverage unstated.
2. One LICENSE-DATA regex hiccup (script artifact); the license is confirmed via the HF machine-readable field and the file snippet.
3. Not re-verified: dataset row counts/sizes (from dataset cards), and `quran-md-words` provenance details beyond its two upstream citations.
