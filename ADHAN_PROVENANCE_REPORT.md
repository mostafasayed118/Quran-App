# Adhan Audio Provenance Report — `quran_yahdi`

> Read-only provenance audit. Repo `E:\old_flutter\Quran-App-master`, HEAD `02a01caa3b1fba332442b1dc023bda30aec7d19e`, branch `main`, full history (1,148 commits, root 2024-08-23).
> **Not legal advice.** This report collects and classifies evidence only; it never issues legal conclusions. Licence terms quoted are copied from the cited pages/repo files; anything unverified is marked UNKNOWN.
> Web pages retrieved **2026-11-16**. No secret values printed. No project file changed; `git status` at close = `?? PROJECT_AUDIT_REPORT.md` (prior task) + `?? ADHAN_PROVENANCE_REPORT.md` (this report) only; HEAD unchanged.

---

## 1. Executive summary

- **Count by status (files/tracks):** NOT-CLEARED-REMOVE **27 files = 9 tracks** (9 bundled full + 9 clips + 9 gitignored masters; clips duplicated into `res/raw`). CLEARED **1** (Freesound 820088 — CC0 but a *soundwalk*, not a usable adhan). CLEARED-WITH-ATTRIBUTION **0**. SUPPORTIVE-EVIDENCE-ONLY **1** (Islamic Network forum reply). NEEDS-OWNER-VERIFICATION **~11** (6 R1 CC0 candidates from the 2026-10-19 dossier, AlAdhan official/download pages, Freesound 639494, Islamweb, and 14 vanished audition-v3 candidates). INCOMPATIBLE **8** (5 Cambridge + Archive.org Kroos + The Wahy Project + Black Toast Music).
- **Ship / no-ship verdict:** **Current nine — DO NOT SHIP** (YouTube-sourced, no permission; owner decision confirms NOT CLEARED). **Earlier "CC0 set" — NO audio exists in git history**; it is a documented candidate shortlist only, so there is nothing historical that could be restored. **Candidates — none is usable as an adhan today**: the only CLEARED item is a 2:55 soundwalk with a distant adhan; the Makkah/Madinah source is community-evidence-only; every Cambridge/reject-list item is NC and/or ND.
- **Top owner action 1:** obtain written redistribution permission from Islamic Network for the specific Makkah/Madinah MP3s, and reconcile their forum reply ("1. Yes. 2. No. 3. No.") with the terms page that only retains copyright.
- **Top owner action 2:** re-verify (or replace) the R1 CC0 shortlist with a current source-page check, then bundle a 3–5 track cleared set; confirm Freesound `sonically_sound` directly before using sound 639494 (its page says CC0, but the uploader adds conditions and the audio is YouTube-extracted).
- **Top owner action 3:** remove all nine current recordings (full, clip, `res/raw`, and `_adhan_masters/`) from the shipping tree before any Play upload; the in-code catalog is deliberately data-only so this is a file deletion + one catalog edit.

---

## 2. Master table

`SHA` = first 12 chars of SHA-256. "In current AAB?" refers to the shipping Android artifact (assets + `res/raw`); the 128 k masters are gitignored and never bundled.

| ID | File name | Path (current or historical) | SHA-256 (12) | In current AAB? | Introduced (commit/date) | Removed (commit/date) | Claimed source | Claimed licence | Evidence (path:line or URL + retrieval date) | Edits needed | Attribution text | Status | Owner action |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| A1-01 | abdulbasit_abdulsamad.m4a | `assets/audio/adhan/abdulbasit_abdulsamad.m4a` | `19845a530712` | YES | `1c91b43c` 2026-11-04 | never | embedded `comment`: `youtube.com/watch?v=eZXSAsjCZXM`; `artist` ISLAMIHERE/2020 | none | ffprobe tags; `adhan_catalog.dart:56-61`; commit `1c91b43c` message | re-encode 128k→64k mono, 25 s trim + fade | none present | **NOT-CLEARED-REMOVE** | delete full+clip+raw+master |
| A1-02 | ali_ahmed_mulla.m4a | `assets/audio/adhan/ali_ahmed_mulla.m4a` | `892b12a8175c` | YES | `1c91b43c` 2026-11-04 | never | `youtube.com/watch?v=uPyc8XV2lnY`; `artist` القرآن الكريم/2015 | none | ffprobe; `adhan_catalog.dart:62-67` | same | none | **NOT-CLEARED-REMOVE** | delete full+clip+raw+master |
| A1-03 | islam_sobhy.m4a | `assets/audio/adhan/islam_sobhy.m4a` | `036bd360845a` | YES | `1c91b43c` 2026-11-04 | never | `youtube.com/watch?v=vOidRj8qB6g`; `artist` 2021 | none | ffprobe; `adhan_catalog.dart:92-97` | same | none | **NOT-CLEARED-REMOVE** | delete full+clip+raw+master |
| A1-04 | khushu.m4a | `assets/audio/adhan/khushu.m4a` | `f5c8aaef198a` | YES | `1c91b43c` 2026-11-04 | never | `youtube.com/watch?v=O3eem7f0qjk`; `artist` عبدالرحمن القضاعي/2012 | none | ffprobe; `adhan_catalog.dart:80-85`; **contradicts** `design.md:30` ("source file carries no reciter") | same | none | **NOT-CLEARED-REMOVE** | delete full+clip+raw+master; resolve tag/doc discrepancy |
| A1-05 | mohamed_qassas.m4a | `assets/audio/adhan/mohamed_qassas.m4a` | `aa3c9265399d` | YES | `1c91b43c` 2026-11-04 | never | `youtube.com/watch?v=mSyrzcHeOGc`; `artist` Awder_Slimani/2023 | none | ffprobe; `adhan_catalog.dart:74-79` | same | none | **NOT-CLEARED-REMOVE** | delete full+clip+raw+master |
| A1-06 | mohamed_tarek.m4a | `assets/audio/adhan/mohamed_tarek.m4a` | `ad4eef536251` | YES | `1c91b43c` 2026-11-04 | never | `youtube.com/watch?v=vS0zBleiJuk`; `artist` 2020 | none | ffprobe; `adhan_catalog.dart:86-91` | same | none | **NOT-CLEARED-REMOVE** | delete full+clip+raw+master |
| A1-07 | nasser_alqatami_1.m4a | `assets/audio/adhan/nasser_alqatami_1.m4a` | `381b89faf25c` | YES | `1c91b43c` 2026-11-04 | never | `youtube.com/watch?v=GN1f4LNoTUs`; `artist` مزامير الفرقان/2016 | none | ffprobe; `adhan_catalog.dart:98-103` | same | none | **NOT-CLEARED-REMOVE** | delete full+clip+raw+master |
| A1-08 | nasser_alqatami_2.m4a | `assets/audio/adhan/nasser_alqatami_2.m4a` | `b9bd7c8b9b10` | YES | `1c91b43c` 2026-11-04 | never | `youtube.com/watch?v=4vV5aV6YK14`; `artist` الفردوس الأعلى/2011 | none | ffprobe; `adhan_catalog.dart:104-109` | same | none | **NOT-CLEARED-REMOVE** | delete full+clip+raw+master |
| A1-09 | omar_hisham.m4a | `assets/audio/adhan/omar_hisham.m4a` | `b6c3a77a846a` | YES | `1c91b43c` 2026-11-04 | never | `youtube.com/watch?v=SI4CScs4D2Q`; `artist` Omar Hisham/2022 | none | ffprobe; `adhan_catalog.dart:68-73` | same | none | **NOT-CLEARED-REMOVE** | delete full+clip+raw+master |
| A2-01…09 | `<id>_clip.m4a` (9) | `assets/audio/adhan/clips/` **and** `android/app/src/main/res/raw/` | `b7d43effcdcf`, `bf9f4351d750`, `cf4b82a43db5`, `b07afec49aa1`, `4404c9ee7afa`, `200aee2f2079`, `9e42157f8ad6`, `277e9a3eae1a`, `4eea1be1dca5` | YES (both paths) | `1c91b43c` 2026-11-04 | never | same tags as A1 source file | none | `tools/build_adhan_audio.ps1:5-7,67-73`; `notifications_binding.dart:531`; `keep.xml:5,10` | 25 s trim + 2 s fade + re-encode + copy to raw | none | **NOT-CLEARED-REMOVE** | delete both paths per track |
| A3-01…09 | `<id>.m4a` masters (9) | `_adhan_masters/` (gitignored, never tracked) | `21c77388bbc4`, `2b0164178ef1`, `09df9562470b`, `1805e8d4a905`, `5a248303cc85`, `bca8cc94ca4f`, `76749254732b`, `79b78a0496df`, `1536026a4d1f` | NO | UNKNOWN (never in git; ignored by `.gitignore:58` added in `1c91b43c`) | n/a | same tags as A1 | none | `git check-ignore -v`; `tools/build_adhan_audio.ps1:1,19` | source masters for the re-encode | none | **NOT-CLEARED-REMOVE** | remove/retire with the set |
| C1 | Beautiful adhan.ogg (Adam-synagda) | never bundled; R1 dossier only | n/a | NO | doc `ac0a000a` 2026-10-19 | n/a | `https://commons.wikimedia.org/wiki/File:Beautiful_adhan.ogg` | CC0 1.0 (claimed) | `docs/superpowers/plans/2026-10-19-r1-license-dossier.md:15,67` | download + verify page + build script edits | courtesy credit recommended | **NEEDS-OWNER-VERIFICATION** | re-open URL, save page, re-hash, then bundle |
| C2 | Adhan.ogg (Aishatu98) | never bundled; R1 dossier only | n/a | NO | doc `ac0a000a` 2026-10-19 | n/a | `https://commons.wikimedia.org/wiki/File:Adhan.ogg` | CC0 1.0 (claimed) | dossier `:16,67` | same | courtesy credit recommended | **NEEDS-OWNER-VERIFICATION** | re-open URL, save page, then bundle |
| C3–C6 | Freesound 869673 / 555065 / 683120 / 863861 | never bundled; R1 dossier only | n/a | NO | doc `ac0a000a` 2026-10-19 | n/a | `https://freesound.org/people/<SignatureSoundsOrg\|AhmadAiuby\|aridtrax>/sounds/<id>/` | CC0 1.0 (claimed) | dossier `:17,72` ("'Creative Commons 0' text present on each ✓") | same | courtesy credit recommended | **NEEDS-OWNER-VERIFICATION** | re-open each page at download time; licences are uploader-controlled |
| C7–C14? | "audition v3" 14 candidates + `_normalized.mp3` | external temp dir, **gone** | UNKNOWN | NO | ledger `87aae15f` 2026-10-20 | n/a | UNKNOWN (no INDEX.txt survives) | CC0 claimed in ledger | `docs/campaign-ledger.md:758` | UNKNOWN | UNKNOWN | **NEEDS-OWNER-VERIFICATION** | filenames/hashes unrecoverable — ignore this lead |
| A0-X | silent.wav (non-adhan, context) | `web/tests/fixtures/silent.wav` | `bd88863614f9` | NO | `5e4ae677` 2026-10-18 | never | generated fixture | n/a | `web/tests/e2e/player.spec.ts:8,32,50` | none | none | **N/A** (e2e fixture, not an adhan) | leave alone |

**Full SHA-256 ledger and per-file durations/blobs:** see Appendix and the forensics evidence in §4 below; all 19 tracked blob hashes equal the current working-tree hashes (no binary drift).

---

## 3. Candidate-sources table

| Source | URL | License shown | Commercial OK? | Redistribution in app OK? | Modification OK? | Attribution | Evidence quality (OFFICIAL / COMMUNITY / NONE) | Status |
|---|---|---|---|---|---|---|---|---|
| Islamic Network / AlAdhan — official terms | https://aladhan.com/credits-and-terms (retrieved 2026-11-16) | No grant; only "All audio files and third-party libraries used here own and retain their respective copyrights." (Terms updated 13 Nov 2026) | NOT STATED | NOT STATED | NOT STATED | none stated | **OFFICIAL** | **NEEDS-OWNER-VERIFICATION** — terms do not clear redistribution |
| Islamic Network — Download Adhans | https://aladhan.com/download-adhans (retrieved 2026-11-16) | No licence/terms on page; footer links to credits-and-terms | NOT STATED | NOT STATED | NOT STATED | none on page | **OFFICIAL** | **NEEDS-OWNER-VERIFICATION** |
| Islamic Network Community thread 255 | https://community.islamic.network/d/255-permission-to-bundle-an-adhan-audio-file-in-our-android-app-nurafiq (retrieved 2026-11-16; live fetch shows SPA error shell, quote from cached extraction) | No licence named; reply by `gokboru`: "1. Yes. 2. No. 3. No." (free app bundling yes / attribution no / restrictions no) | NOT ADDRESSED | YES per reply (free app only) | NOT ADDRESSED | "No" per reply | **COMMUNITY** | **SUPPORTIVE-EVIDENCE-ONLY** — owner must obtain written confirmation |
| Freesound 820088 — Ramallah soundwalk | https://freesound.org/people/sounds_from_palestine/sounds/820088/ (retrieved 2026-11-16) | "Creative Commons 0" linking CC0 1.0 | Yes per page | Yes per page | Yes per page | None required (page offers "Get attribution text…") | **OFFICIAL** (licence on file's own page) | **CLEARED** (licensing) — but 2:55 soundwalk with distant Isha adhan, **not fit as an adhan** |
| Freesound 639494 — الأذان (Adhan/Call to Prayer) | https://freesound.org/people/sonically_sound/sounds/639494/ (retrieved 2026-11-16) | "Creative Commons 0" linking CC0 1.0 on the sound page | CC0 text yes; uploader profile adds conditions | CC0 text yes; same caveat | CC0 text yes; same caveat | CC0 none; uploader asks credit "Enes DENİZ" and to be told where used | **OFFICIAL** for page licence + **COMMUNITY** for profile conditions (https://freesound.org/people/sonically_sound/) | **NEEDS-OWNER-VERIFICATION** — uploader says "I request that you contact me before using any of my sounds", "I have the right to change the status of my sounds", and page says "Extracted from https://www.youtube.com/watch?v=4dpqrKYI-n4 and processed" (upstream rights unverified) |
| Cambridge — City Wide Adhan, Cairo Tower (Asr) | https://www.repository.cam.ac.uk/items/444dc017-0d10-4cfb-9ed0-028cb767bcb8 (retrieved 2026-11-16) | "Attribution-NonCommercial-NoDerivs 3.0 Unported (CC BY-NC-ND 3.0)" | **No** (NC) | Non-commercial + attribution only | **No** (ND) | BY: credit creators, link licence, indicate changes | **OFFICIAL** (item "Rights and licensing") | **INCOMPATIBLE** (NC + ND) |
| Cambridge — Masgid Serri Ghatmash (Isha) | https://www.repository.cam.ac.uk/items/3cb9d4ef-6e1b-401f-9829-b20dcf8c0c33 (2026-11-16) | CC BY-NC-ND 3.0 | No | Non-commercial + attribution only | No | same | **OFFICIAL** | **INCOMPATIBLE** |
| Cambridge — Al-Azhar Park (Dhurh) | https://www.repository.cam.ac.uk/items/4f2b87ed-3174-443a-a3c4-5e8c522650da (2026-11-16) | CC BY-NC-ND 3.0 | No | Non-commercial + attribution only | No | same | **OFFICIAL** | **INCOMPATIBLE** |
| Cambridge — Masgid Sheikh Abdullah (Dhurh) | https://www.repository.cam.ac.uk/items/e0a4cac7-b6b1-41f0-b5c2-5c12e8121a92 (2026-11-16) | CC BY-NC-ND 3.0 | No | Non-commercial + attribution only | No | same | **OFFICIAL** | **INCOMPATIBLE** |
| Cambridge — Masgid Mahmoudeya, Sheikh Hamed (Fajr) | https://www.repository.cam.ac.uk/items/2d759342-ebf9-41d7-b1b2-313efeff8fa9 (2026-11-16) | CC BY-NC-ND 3.0 | No | Non-commercial + attribution only | No | same | **OFFICIAL** | **INCOMPATIBLE** |
| Archive.org — Robert Kroos, Adhān (Morocco) | https://archive.org/details/RobertKroosAdhan_Morocco (2026-11-16) | "Attribution-NonCommercial-NoDerivs 4.0 International" | No (NC) | Non-commercial + attribution only | **No** (ND) | credit Robert Kroos / Green Field Recordings | **OFFICIAL** | **INCOMPATIBLE** — reject claim CONFIRMED |
| The Wahy Project — Adhan Recordings | https://thewahyproject.com/2011/09/05/adhan-recordings/ + https://thewahyproject.com/license/ (2026-11-16) | Site-wide CC BY-NC-ND 3.0; post itself has no licence text | No (NC) | Non-commercial + credit only | **No** ("You Can NOT change the content in any way") | "The Wahy Project" | **OFFICIAL** | **INCOMPATIBLE** — reject claim corrected (site licence exists) |
| Black Toast Music — Adhan (Shia) | https://blacktoastmusic.com/catalog/tracks/adhan-shia + https://www.blacktoastmusic.com/help/faq (2026-11-16) | "Public domain composition: Yes" (composition only); sound recording is exclusively licensed; Master Use / Sync / Digital Media licences required | No without paid licence | No without licence | No without licence | per agreement | **OFFICIAL** | **INCOMPATIBLE** — commercial library; "public domain" applies to composition only |
| Islamweb — adhan listing | https://www.islamweb.net/en/index.php?page=adhan (retrieved 2026-11-16 via cached extraction; live HTTP 500) | No licence text on listing page | NOT STATED | NOT STATED | NOT STATED | none on page | **NONE** | **NEEDS-OWNER-VERIFICATION** — open page and check body/footer |
| Islamweb — copyright fatwa | https://www.islamweb.net/en/printfatwa.php?id=379009 (2026-11-16) | "The material of Islwmweb is copyrighted"; non-commercial use with source attribution; modification not addressed | No | Non-commercial + attribution | UNKNOWN | source + site attribution required | **OFFICIAL** | **NEEDS-OWNER-VERIFICATION** — modification question open |

---

## 4. Duplicate / near-duplicate findings

1. **Exact duplicates by design:** all nine `assets/audio/adhan/clips/<id>_clip.m4a` are byte-identical to `android/app/src/main/res/raw/<id>_clip.m4a` (same SHA-256 pairs in §2). Cause: `tools/build_adhan_audio.ps1:73` `Copy-Item … -Force`; `docs/campaign-ledger.md:1293` corroborates (`res/2u.m4a` = `nasser_alqatami_2_clip.m4a`, 206,355 B).
2. **Near-duplicates (re-encode lineage):** each shipped full file is a 64 kbps mono re-encode of its 128 kbps stereo master — different SHA and ~half the size, but identical `title`/`artist`/`date`/`comment` tags and durations within ≤0.001 s.
3. **Old CC0 shortlist vs the nine — zero overlap:** different extensions (`.ogg`/`.webm` vs `.m4a`), different claimed sources (Wikimedia/Freesound vs YouTube URLs in tags), no shared blob/SHA. No undisclosed CC0 re-upload among the nine.
4. **No "earlier CC0 set" exists in git:** `git rev-list --objects --all` over audio extensions returns only 18 adhan paths + `silent.wav`; `git log --all --diff-filter=D` over audio extensions is empty (no audio ever deleted/renamed); `git fsck --no-reflogs --unreachable` → 365 unreachable blobs, 202 >50 KB checked, **0 with audio magic**. The "CC0 set" is prose in `docs/superpowers/plans/2026-10-19-r1-license-dossier.md` (commit `ac0a000a`, 2026-10-19), never bundled. A second lead, "audition v3" (`docs/campaign-ledger.md:758`, commit `87aae15f`, 2026-10-20), produced 14 CC0 candidates + loudnorm copies in an external temp dir that no longer exists → unrecoverable.
5. **Provenance discrepancy:** `2026-11-04-adhan-selection-design.md:30` says `khushu` "source file carries no reciter", but ffprobe finds `artist="عبدالرحمن القضاعي"` and `comment=youtube.com/watch?v=O3eem7f0qjk`. The repo's own documentation is wrong about this file's provenance.
6. **No licence evidence for the nine:** all nine have `encoder=Lavf62.12.102`, no `copyright`/`license` tag; the nine YouTube URLs exist only inside binary metadata (`git grep` over tracked text → zero hits). `docs/store/licensing-matrix.md` has **no adhan row**; the Licenses & Sources screen cites only recitation audio (`licenses_screen.dart:54` → `app_ar.arb:568` "mp3quran.net").

---

## 5. Technical-fit table

Current measurements from `ffprobe` and `Get-ChildItem`; per-track channel handling from source.

| Track (current) | Full duration | Full size | Clip (25 s) size | Format | Notification-channel handling |
|---|---|---|---|---|---|
| abdulbasit_abdulsamad | 223.6 s | 1,839,923 B | 207,604 B | AAC-LC mono 44.1 kHz ~64 kbps / M4A | `quran_yahdi_adhan_abdulbasit_abdulsamad` |
| ali_ahmed_mulla | 205.1 s | 1,659,885 B | 194,790 B | same | `…_ali_ahmed_mulla` |
| islam_sobhy | 171.8 s | 1,399,898 B | 203,663 B | same | `…_islam_sobhy` |
| khushu | 210.8 s | 1,719,140 B | 207,101 B | same | `…_khushu` |
| mohamed_qassas | 226.6 s | 1,868,516 B | 207,571 B | same | `…_mohamed_qassas` |
| mohamed_tarek | 171.5 s | 1,415,861 B | 209,455 B | same | `…_mohamed_tarek` |
| nasser_alqatami_1 | 127.5 s | 1,050,182 B | 207,510 B | same | `…_nasser_alqatami_1` |
| nasser_alqatami_2 | 135.2 s | 1,072,971 B | 206,355 B | same | `…_nasser_alqatami_2` |
| omar_hisham | 180.0 s | 1,465,238 B | 199,569 B | same | `…_omar_hisham` |

- **Current bundled total:** 13,491,614 B full + 1,843,618 B clips + 1,843,618 B `res/raw` duplicates = **17,178,850 B ≈ 16.38 MiB** (~34% of the ~47 MiB reference APK; dominant size contributor after the Quran DB and Hafs JSON).
- **3-track replacement estimate:** ~3 × 1.4 MB full + 3 × 0.2 MB clip + 3 × 0.2 MB raw ≈ **5.4–6.0 MiB**, saving **~10–11 MiB** from the AAB.
- **Channel immutability — handled:** `adhanChannelId(track) => 'quran_yahdi_adhan_${track.id}'` (`lib/core/domain/adhan_catalog.dart:151`) and `_detailsFor` (`notifications_binding.dart:517-549`) create one channel per track; source comments at `adhan_catalog.dart:145-150` and `notifications_binding.dart:508-513` explicitly state Android freezes a channel's sound, so a new track id gets a new channel and no channel is mutated. **Implication when replacing:** use **new ids** (or accept stale channels on existing installs); a removed id's channel remains on device but is harmless, and `adhanById` (`:117-123`) resolves unknown persisted ids to the default so no crash/blank picker. Do **not** reuse an old id with a different sound — existing users would keep the old sound.
- **Notification sound mechanics:** `RawResourceAndroidNotificationSound(track.clipResource)` (`notifications_binding.dart:531`) requires the clip in `res/raw` (`adhan_catalog.dart:43-48`); the build script produces full + 25 s fade clip + raw copy (`tools/build_adhan_audio.ps1:61-73`), and `res/raw/keep.xml:5,10` prevents R8/shrinkResources from stripping the clips (fix commit `e3a879dd`, 2026-11-05).
- **Modification requirement:** every candidate must permit re-encoding to 64 kbps mono, 25 s trim + 2 s fade-out, and copying the clip to `res/raw` (script lines above). This is why ND licences are incompatible.
- **Loudness:** no normalisation step in the shipped script (it only re-encodes/trims); the audition-v3 `_normalized.mp3` files referenced in `docs/campaign-ledger.md:758` were an offline listening aid, not shipped.
- **Fit caveat:** Freesound 820088 is 2:55 stereo FLAC (33.7 MB source) soundwalk with traffic, children and a siren; the adhan is distant — technically CC0-cleared but **not a usable prayer notification**.

---

## 6. Recommended shipping set / remove list

**Ship today (CLEARED or CLEARED-WITH-ATTRIBUTION, usable as an adhan): NONE.**
The only CLEARED candidate (Freesound 820088) is a soundwalk, not a standalone adhan. Until written confirmation arrives, the honest options are (a) keep the system default notification sound for prayer reminders, or (b) delay the adhan-selection feature. Do not substitute a NOT-CLEARED file.

**Ship after owner gets written confirmation (SUPPORTIVE-EVIDENCE-ONLY → promote to CLEARED first):**
1. **Makkah-style + Madinah-style pair** from Islamic Network / AlAdhan (e.g. Alafasy Makkah and Aḥmad al-Nafīs Madinah, both on https://aladhan.com/download-adhans) — requires the written confirmation drafted in §7, plus confirmation that Islamic Network controls the reciter-level rights.
2. **Freesound 639494** (`sonically_sound`, Turkish-style, 4:51.853) — only after direct uploader confirmation and verification of the upstream YouTube video's rights; its profile conditions conflict with a bare CC0 reading.

**Remove list (NOT-CLEARED-REMOVE):**
- All 9 `assets/audio/adhan/<id>.m4a`
- All 9 `assets/audio/adhan/clips/<id>_clip.m4a`
- All 9 `android/app/src/main/res/raw/<id>_clip.m4a` (plus `keep.xml` rule can stay; it matches by wildcard)
- All 9 `_adhan_masters/<id>.m4a` (untracked/ignored)
- Then reduce `kAdhanCatalog` in `lib/core/domain/adhan_catalog.dart:55-110` to the cleared ids and bump `kDefaultAdhanId` (`:52`) if the old default is removed. No other code changes are needed by design.

**Do not use:** all five Cambridge items, Archive.org Kroos, The Wahy Project, Black Toast Music (INCOMPATIBLE); Islamweb until modification rights are confirmed; the vanished audition-v3 candidates (unrecoverable).

---

## 7. Draft written-confirmation requests (EN)

**A. Islamic Network / AlAdhan — request (send to an official contact, not a forum reply)**

> Subject: Written permission to bundle AlAdhan adhan MP3s in a free Android app
>
> We develop "Quran Yahdi", a free, ad-free, no-IAP, no-analytics offline Quran app (Google Play package `com.mostafasayed.quranyahdi`). We would like to bundle, for offline playback and prayer notifications, the following MP3 files from https://aladhan.com/download-adhans: [list exact filenames/URLs]. We trim each to a 25-second notification clip, re-encode to 64 kbps mono AAC, and may normalise loudness.
>
> Please confirm in writing: (1) we may redistribute these recordings inside our free app; (2) whether "free / no ads / no IAP" is a binding condition; (3) whether trimming, transcoding, sample-rate change and loudness normalisation are permitted; (4) the exact credit line, if any, to show in the app's Licenses screen; (5) whether you control the recording rights for each credited reciter, or whether reciter-level clearance is also required. Please also reconcile this with https://aladhan.com/credits-and-terms, which states that audio files retain their copyrights, and with the community reply at https://community.islamic.network/d/255-… ("1. Yes. 2. No. 3. No.").

**B. Freesound `sonically_sound` (Enes DENİZ) — request**

> Subject: Permission to use sound 639494 (الأذان) in a free Android app
>
> We would like to use your Freesound sound 639494 (https://freesound.org/people/sonically_sound/sounds/639494/) in "Quran Yahdi", a free, ad-free app. The page shows Creative Commons 0, but your profile asks users to contact you first and states you may change a sound's status. Please confirm in writing that we may (a) bundle the file offline, (b) trim to 25 s, re-encode to 64 kbps mono AAC and normalise loudness, (c) redistribute it in our free app, and (d) confirm that the upstream YouTube source (https://www.youtube.com/watch?v=4dpqrKYI-n4) does not carry rights that prevent this. Please give the exact credit text you want, if any.

**Evidence to save for each confirmation:** the signed/stamped email or message with sender address and full date; a screenshot or PDF of any web page stating the terms; the exact URL and retrieval date; the exact file name/URL covered; and a copy of any attribution string. Store these next to the asset (e.g. `assets/licenses/`) so the next audit can cite them.

---

## 8. Appendix

### Exact commands run (read-only)
- Git: `rev-parse HEAD`, `branch --show-current`, `status --porcelain`, `log --all --name-status --diff-filter=ADRM -- '*.mp3' '*.m4a' '*.ogg' '*.wav' '*.aac' '*.opus'`, `log --all --diff-filter=D --name-only`, `rev-list --objects --all`, `fsck --no-reflogs --unreachable`, `ls-tree`, `cat-file -s`, `cat-file blob <sha>` (streamed to temp outside repo), `check-ignore -v`, `grep -n -I`, `show <sha>:<path>`.
- Hashing: `Get-FileHash -Algorithm SHA256`; historical blobs streamed via .NET `Process.StandardOutput.BaseStream.CopyTo` to `C:\Users\ASUS\AppData\Local\Temp\opencode\adhan_audit\<name>`, hashed, then deleted.
- Metadata: `ffprobe -v error -print_format json -show_format -show_streams <file>` on all bundled files and masters.
- Sizes: `Get-ChildItem -Recurse -File | Measure-Object Length -Sum`; `git cat-file -s <blob>`.
- Web: built-in `webfetch` on the URLs in §3 (2026-11-16); full outputs saved by the harness to `C:\Users\ASUS\.local\share\opencode\tool-output\`; decisive quotes re-read from those saved outputs with `Select-String`.
- No builds, installs, commits, branch operations, or history rewrites.

### Tools / versions
`git.exe`, `ffprobe.exe`/`ffmpeg.exe` (WinGet links, `Lavf62.12.102`), `Get-FileHash` (SHA-256), PowerShell 5.1, `webfetch` (markdown), Exa MCP (used by research subagents only to locate URLs / read JS-blocked pages). **Not available:** exiftool, Python `mutagen` — M4A metadata therefore read from MP4 atoms via ffprobe, not ID3v2.

### Full SHA-256 ledger — tracked blobs (19; first 12 shown in §2)
```
assets/audio/adhan/abdulbasit_abdulsamad.m4a  19845a5307127dd87b647dc70741f052966863002f66407e8f0f297605d7c833
assets/audio/adhan/ali_ahmed_mulla.m4a        892b12a8175c156010ff8cfd43b9c9510f97bb3cea375840a7d9378efea89e90
assets/audio/adhan/islam_sobhy.m4a            036bd360845a81873aefd150d60beeb91582831fde5c608d273cbf139b5e8ecd
assets/audio/adhan/khushu.m4a                 f5c8aaef198a155e125f803fee485c2a0ade75ebc4b89a6b1243b4f637a53ca2
assets/audio/adhan/mohamed_qassas.m4a         aa3c9265399da866f1fb77ea059dcc82c3b67c84c27dfc8a7c253c0881ec5f48
assets/audio/adhan/mohamed_tarek.m4a          ad4eef5362514750498acc924bcd083e88d057745360ea465f52d50b4e9048a4
assets/audio/adhan/nasser_alqatami_1.m4a      381b89faf25c32030a092b6c42f19cc232d888812438a322e5ae50ff6d6f2e07
assets/audio/adhan/nasser_alqatami_2.m4a      b9bd7c8b9b102f46d87654162b3fe3e5e22f635a652adc4c91e2efe8b30ccd38
assets/audio/adhan/omar_hisham.m4a            b6c3a77a846ac642bb2979d5325e8971b5aaf66b87679f4654b34f477d6fe9f9
<clip blob> abdulbasit_abdulsamad               b7d43effcdcf4fac5308a572102fbb8ebcc9c2c257fb6835061ca606f4ab3681
<clip blob> ali_ahmed_mulla                    bf9f4351d750db0d79119b6fe0eed5e7510f56af37d66fd3a1518e53a0b31f97
<clip blob> islam_sobhy                        cf4b82a43db530f60fdd7f23f6cde1613868e0d4435cb6f2277ae2e6657772b7
<clip blob> khushu                             b07afec49aa12c048576cd3713163e4d1d41fe257e7533aaa26adcbb0aefe495
<clip blob> mohamed_qassas                     4404c9ee7afa43824db757d50e9abadfb945c45392b9e32ecc8674cd297bab8a
<clip blob> mohamed_tarek                      200aee2f2079a6fdaa8d08b9f4ba9f2bbed3d1090ea56c76af90a3bfeb1c84b4
<clip blob> nasser_alqatami_1                  9e42157f8ad6ea2d197dd362495b0f8c0e6318a2a339367b4ce901ba009f33e7
<clip blob> nasser_alqatami_2                  277e9a3eae1a66f1f292e1815b722f7b8af6978f8b6da3134c7c2170226f98df
<clip blob> omar_hisham                        4eea1be1dca523a7a3ce52363afbfdc201140c95a967a122890ba6aa67032697
web/tests/fixtures/silent.wav                  bd88863614f9f117591c3c4d8d2aacbaf7c88502c05e2e010a27f0159948eca0
```
Untracked masters (9) — first 12 in §2; full values in the forensics ledger quoted above. All 19 tracked blob hashes equal current working-tree hashes.

### Files not examined / why
- `web/node_modules/**`, `build/**`, `.dart_tool/**` — generated/dependencies, not audio provenance.
- `PRODUCTION_READINESS_REPORT.md` and the prior `PROJECT_AUDIT_REPORT.md` — prior-task artifacts; not relied on for this report.
- Cambridge bitstream "accession form" PDFs — not opened; the item pages carry a hedging "Except where otherwise noted…" phrase, so per-item PDF terms remain **UNKNOWN**.
- The 5 remaining Cambridge items (collection says 10 locations; only 5 item pages located) — **UNKNOWN**; open each item's "Rights and licensing" before assuming CC BY-NC-ND 3.0.

### All UNKNOWN items
1. Real rights/identity of the nine recordings beyond embedded tags (URLs and artist names are claims inside the files, not independently verified).
2. Origin/acquisition of the nine masters before `_adhan_masters/` — never tracked; no commit records it.
3. The 14 audition-v3 candidates (filenames, hashes, licences, URLs) — temp dir gone; never committed.
4. Present-day licence state of the R1 CC0 candidates (Wikimedia/Freesound) — dossier records a 2026-10-19 verification; pages not archived in-repo and not re-fetched here.
5. Islamic Network's official position: forum reply is community-only, official terms grant nothing; written confirmation outstanding.
6. Islamweb modification rights; Islamweb listing page licence text (live HTTP 500; cached extraction only).
7. Cambridge accession-form PDF terms and the other 5 collection items.
8. Exact upload time of the embedded YouTube comments (only `date` year tags), and whether any earlier lossless source existed (masters are themselves `Lavf` AAC).
