# Licensing verification — 2026-10-24

Scope: the 9 downloadable packs in `assets/data/library_catalog.json` plus the two mushaf
fonts. Method: primary-source fetch (publisher terms pages, font name tables, upstream
metadata). Quotes are verbatim evidence, not legal advice. Every RED item is a
**hold/remove or obtain written permission** decision for the owner.

## 1. Fonts (read from the font name tables with fontTools)

- **`HafsSmart_08.ttf`** (KFGQPC "KFGQPC Hafs Smart", v0.08). Embedded EULA (name ID 13):
  "Permission is hereby granted, Free of Cost, to any person obtaining a copy of this Font
  accompanying this license, the rights to Use, Copy, Distribute" subject to: "The Font
  Software cannot be Sold, Modified, Altered, Translated, Reverse Engineered, Decompiled,
  Disassembled, Reproduced". Copyright: "King Fahd Glorious Quran Printing Complex
  (KFGQPC), AlMadinah AlMunawwarah... All Rights Reserved."
  **Verdict: AMBER.** Ship the EULA text + attribution; never modify the font.
- **`me_quran.ttf`** (name ID 0): "Typeface and data © 2005, Meor Ridzuan. Free for non
  commercial use. Other use, contact meory@yahoo.com".
  **Verdict: AMBER.** Only while the app stays free and ad-free; written permission is safer.

## 2. The Clear Quran — `eng-mustafakhattabg`

Official copyright page text (rendered by the site bundle at
https://theclearquran.org/copyright): "No person, business, or entity shall reproduce, in
whole or in part, any verses or excerpts from "THE CLEAR QURAN® Series" without prior
written consent from the publisher."

**Verdict: RED.** No CC BY-NC-ND text exists on the publisher site; the all-rights-reserved
notice contradicts that claim. Hold/remove unless written consent is obtained.

## 3. Quran Foundation content — the three tafsir packs

`spa5k/tafsir_api` (MIT covers the **repo**) attributes its tafsir data to
`https://quran.com/` and `https://qul.tarteel.ai/resources/tafsir/...` (both Quran
Foundation). QF Developer Terms (https://api-docs.quran.foundation/legal/developer-terms/):
"QF Content is not sold, sublicensed, or redistributed" and "Requires a separate written
commercial license: ... content package".

**Verdict: RED** for `ar-tafsir-muyassar`, `ar-tafsir-al-jalalayn`,
`en-tafisr-ibn-kathir` until a written QF/publisher license exists or the pack is re-sourced
from a publisher that grants redistribution.

## 4. quranenc — `ara-sirajtafseer`

https://quranenc.com/en/home: "Contents of the translations can be downloaded and
re-published, with the following terms and conditions: 1. No modification, addition, or
deletion of the content. 2. Clearly referring to the publisher and the source
(QuranEnc.com). 3. Mentioning the version number when re-publishing the translation.
4. Keeping the transcript information inside the document. 5. Notifying the source
(QuranEnc.com) of any note on the translation. 6. Updating the translation according to the
latest version issued from the source. 7. Inappropriate advertisements must not be
included."

**Verdict: AMBER.** Compatible with a free, ad-free app, but the shipped file comes via
`fawazahmed0/quran-api`; prove the edition is the quranenc edition and include the
attribution + version.

## 5. Saheeh International — `eng-safiurrahmanalm`

https://tanzil.net/trans/: "The translations provided at this page are for non-commercial
purposes only. If used otherwise, you need to obtain necessary permission from the
translator or the publisher."

**Verdict: AMBER.** The app is free and ad-free today, which is a factual input supporting
a non-commercial use; store distribution is still distribution. Publisher permission is
safer.

## 6. Hadith translations — `eng-bukhari`, `eng-muslim`

Upstream `hadith-api` editions metadata lists author "Muhsin Khan" (`eng-bukhari`) and
"Abdul Hamid Siddiqui" (`eng-muslim`), with `"source": ""` — no license grant. The
hadith-api repo license (Unlicense) covers the repo, not the translations.

**Verdict: RED / UNVERIFIED.** Hold or obtain permission from the rights holders.
`ara-bukhari`: author "Unknown", source "" — the classical Arabic text is public domain,
but this digital edition's provenance is unverified; treat as LOW risk and verify the
edition before shipping.

## 7. mp3quran.net

https://www.mp3quran.net/eng/privacy: "All rights are available to everyone, and we allow
any visitor or developer to copy any material or use any link on the websites".

**Verdict: AMBER/GREEN.** Keep streaming/download with attribution; reciter-level rights
remain; do not re-encode or claim ownership.

## Minimum safe catalog for the Play upload

| Action | Packs |
|---|---|
| **Hold/remove** | `eng-mustafakhattabg`, `eng-bukhari`, `eng-muslim`, `ar-tafsir-muyassar`, `ar-tafsir-al-jalalayn`, `en-tafisr-ibn-kathir` |
| **Keep with conditions** | `ara-sirajtafseer` (QuranEnc attribution + version), `eng-mohammedmarmadu` (free/no-ads + Tanzil credit), mp3quran streaming (attribution), `HafsSmart_08.ttf` (ship EULA + attribution), `me_quran.ttf` (free/no-ads) |
| **Already clean/low** | Arabic Quran text, adhkar/duas/asma, Cairo OFL, cities, app-authored assets |

## Owner decision required

- **A. Remove/hold the six packs** from `assets/data/library_catalog.json` before the store
  build (safest; no permissions needed).
- **B. Obtain written permissions** (Clear Quran publisher, Darussalam / Muhsin Khan estate,
  Siddiqui rights holder, a QF commercial license, and the tafsir publishers) and keep them.

Either way: ship the `HafsSmart` EULA text and an attribution/licenses screen, and keep the
app free and ad-free unless the permissions cover commercial use.

## Decision executed — app catalog (2026-10-24)

The owner chose **A (hold/remove)**. `assets/data/library_catalog.json` is now
`catalogVersion: "1.2"` with **3 packs**:

- kept: `ara-sirajtafseer` (translation), `eng-mohammedmarmadu` (Pickthall, translation),
  `ara-bukhari` (hadith);
- removed: `eng-mustafakhattabg`, `eng-bukhari`, `eng-muslim`, `ar-tafsir-muyassar`,
  `ar-tafsir-al-jalalayn`, `en-tafisr-ibn-kathir`.

The shipped translation was switched from Saheeh International to Pickthall
(`eng-mohammedmarmadu`) on 2026-10-24; Pickthall carries the same Tanzil non-commercial
clause, so the free/no-ads + attribution condition still applies.

The two frozen catalog tests were updated to pin the new shape (9→3 packs, tafsirs 3→0,
translations 3→2, hadiths 3→1) — same assertions, new expected catalog.

**Web:** `web/src/lib/content-packs.ts` now ships only the two licensed translations
(`ara-sirajtafseer`, `eng-mohammedmarmadu`); the six were withdrawn there too (W-E wave
`2df27aa`, web-gates green). The HafsSmart EULA and the me_quran/Cairo terms ship in-app via
Settings → Licenses & sources (`assets/licenses/`, `lib/features/settings/presentation/licenses_screen.dart`).
