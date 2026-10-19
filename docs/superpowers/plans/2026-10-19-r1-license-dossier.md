# R1 — License Clearance Dossier (Adhan audio + Word-by-Word gloss)

Date: 2026-10-19 · Owner-approved roadmap item R1 (doc-only, no code)
Result: **Target A — CLEARED (verified candidates ready for the audio wave) · Target B — BLOCKED (license-first rule not yet satisfied)**
Method: a research subagent surveyed candidates at source; the PM then re-fetched **every load-bearing license fact** independently (see Verification appendix — zero discrepancies). Item metadata (durations, sizes, formats) from the research pass was **not** independently re-measured.

---

## Target A — Adhan recordings (D1: 2–3 recordings, license-first)

### Verified shortlist (all licenses PM-re-verified)

| # | Candidate | Source URL | License | Role |
|---|---|---|---|---|
| A1 | `Beautiful adhan.ogg` (Adam-synagda) | `https://commons.wikimedia.org/wiki/File:Beautiful_adhan.ogg` | **CC0 1.0** | **Default candidate** — full-length adhan (~2:34 per research pass) |
| A2 | `Adhan.ogg` (Aishatu98) | `https://commons.wikimedia.org/wiki/File:Adhan.ogg` | **CC0 1.0** | Short alert cue (~42 s) |
| A3 | Freesound CC0 set — `869673` (Fes pack, SignatureSoundsOrg) · `555065` + `683120` (AhmadAiuby) · `863861` (aridtrax) | `https://freesound.org/people/<user>/sounds/<id>/` | **CC0 1.0** | Extra voices; **field recordings with ambience — audition required** |
| A4 (optional) | `Adhan, Great Mosque of Mecca - Jan 21, 2013.webm` (Seyfula Islam) | `https://commons.wikimedia.org/wiki/File:Adhan,_Great_Mosque_of_Mecca_-_Jan_21,_2013.webm` | **CC BY 3.0** | "Iconic Makkah" flavor; attribution string required; audio extraction = adaptation (allowed; note changes) |

CC0 requires **no attribution** (courtesy credit recommended); CC BY requires its exact attribution string in the app's credits/licenses note.

### Rejected candidates (bundle-blocking reasons)

- archive.org `athan_dzd` — "Public Domain Mark" is an assertion label on an effectively empty item (14.1 KB, unverifiable provenance). **REJECT.**
- archive.org `11.14.2021-jb-tarwater-…` — genuinely CC0 but is Christian missionary content, not an adhan. **REJECT (wrong content).**
- Commons `Call to prayer by Sabah Fakhry.mp3` — PD-Old claim cannot hold for a 1985 YouTube-sourced recording by a 20th-century performer; performer rights unaddressed. **REJECT.**
- GitHub `abodehq/Athan-MP3`, `Kiwifu/adhan-mp3` (+ similar repos) — no license at all. **REJECT.**
- archive.org aporee Fes — CC BY-NC-SA 3.0. **FALLBACK only** (NC breaks any future monetization; SA complicates edits).

### Integration requirements (for the future audio wave — A4-audio/A5)

1. Owner auditions the shortlist (sound quality cannot be judged from metadata).
2. Store the proof next to the assets in-repo: item URL + uploader + verbatim license + (for CC BY) the attribution string.
3. Prefer bundling **unmodified** files where practical (esp. any CC BY-SA fallback).

---

## Target B — Word-by-word gloss layer (D2: source data under a verified clean license first)

### Outcomes per candidate

| # | Source | License status | Verdict |
|---|---|---|---|
| B1 | QUL "English Word by Word Translation" res. 92 + colored 564 | **not publicly displayed**; downloads sign-in gated (PM-verified: 4 `sign_in` hits, **0** "license" mentions on the pages); QF Developer Terms prohibit redistribution of QF Content without a signed commercial license (PM-verified verbatim) | **CAUTION — NOT CLEARED** |
| B2 | QUL morphology 75/76/77/78 | grammar layer (corpus-derived risk), same visibility problem | CAUTION — not a gloss layer |
| B3 | Quranic Arabic Corpus `corpus.quran.com` | **GNU GPL v3** (PM-verified) | **REJECT** for an all-rights-reserved offline app |
| B4 | Quran.com / Quran Foundation API word-by-word | "not sold, sublicensed, or redistributed" (PM-verified) | **REJECT** for bundling |
| B5/B6 | `marwan/quranwbw`, `qazasaz/quranwbw` | GitHub license = NONE (PM-verified) | **REJECT** |
| B7/B8 | `SadaqaWorks` / `emonm` Word-By-Word-Quran-Android | repo MIT, but data provenance/license undocumented (grammar analysis suggests corpus-derived) | CAUTION — data unusable without provenance audit |
| B9 | `risan/quran-json` | CC BY-SA 4.0 — verse-level text+translations only | Not a match (no per-word gloss) |
| B10 | `fawazahmed0/quran-api` | Unlicense — translations only | Not a match (no WBW layer) |
| B11 | Tanzil | text license, no modification | Not a match (no WBW layer) |
| B12 | KFGQPC | no openly downloadable license-documented WBW dataset found | Not established |

### Blocker resolution options (owner pick — pending)

1. **Account-side check (fastest):** create a free QUL account → download res. 92 export → read the per-resource license/attribution metadata → if it explicitly permits redistribution in apps, re-evaluate; if silent or QF-Content-derived, skip.
2. **Alternative-sourcing pass:** targeted research for community WBW datasets with explicit open licenses (CC BY / CC0 / Unlicense) — new short research wave.
3. **Drop the feature** per D2 ("no clean source → skip").

---

## Verification appendix (PM re-fetch, 2026-10-19)

All re-derived at source by the PM in the same session, **zero discrepancies** vs the research report:

- Commons API extmetadata ×5: Beautiful_adhan.ogg=CC0 · Adhan.ogg=CC0 · Azan.ogg=CC BY-SA 4.0 · Mecca webm=CC BY 3.0 · Hassan II wav=CC BY-SA 4.0 ✓
- `corpus.quran.com/license.jsp`: GPLv3 markers present ✓
- `api-docs.quran.foundation/legal/developer-terms/`: "not sold, sublicensed, or redistributed" + "signed commercial license" both present ✓
- QUL res. 92/564 pages: sign-in-gated downloads; zero "license" mentions ✓
- GitHub API ×7: `marwan/quranwbw`=NONE · `qazasaz/quranwbw`=NONE · `risan/quran-json`=CC-BY-SA-4.0 · `fawazahmed0/quran-api`=Unlicense · `SadaqaWorks/…`=MIT · `abodehq/Athan-MP3`=NONE · `Kiwifu/adhan-mp3`=NONE ✓
- Freesound ×4 (869673, 555065, 683120, 863861): HTTP 200, CC0 link + "Creative Commons 0" text present on each ✓

Not independently re-verified (non-load-bearing): durations/sizes/format details, Freesound filter counts ("26 of 45 CC0"), and the detailed PD-Old analysis of the rejected Sabah Fakhry file (rejection direction is unaffected).

## Status

- **Target A: CLEARED** — the adhan-recording item of D1 is unblocked; candidates are ready for the future audio wave (subject to owner audition).
- **Target B: BLOCKED by the D2 rule** — no source yet satisfies "freely redistributable with a publicly citable license"; word-by-word stays out of any wave until option 1 or 2 resolves it.
