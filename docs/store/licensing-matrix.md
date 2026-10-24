# Content Licenses & Attribution Matrix (v1.0.0)

> Rule of this document: **EVIDENCE OR FLAG**. A license is stated only where it can be
> quoted (bundled file or fetched upstream document, date-pinned). Anything not quotable
> goes to `## OPEN-FOR-OWNER` at the bottom — never an invented license.
> Two classes matter: **BUNDLED** assets ship inside the store artifact;
> **DOWNLOAD-PACKS** are fetched on demand from pinned CDNs at runtime (not in the APK).
> Owner decision needed wherever the table says `FLAG → OPEN-FOR-OWNER <n>`.

Last updated: 2026-10-17 (verification-freshness date)

## The matrix

| # | Asset | Class | Source | License | Verification method | Risk |
|---|---|---|---|---|---|---|
| 1 | Quran text, Uthmani + Imlaei (114 surahs / 6,236 ayahs) — `assets/db/quran.sqlite` | BUNDLED | Legacy repo bundle, rebuilt in W1a via `tools/build_quran_db.dart` from repo-tracked `assets/json/hafs_smart_v8.json` (campaign ledger W1a) | Classical religious scripture text — public domain by its nature; this document does not assert any digitization copyright claim | Ledger W1a independent sqlite probe (114/6236) | Font licenses are SEPARATE (see 2) — flagged there |
| 2 | Mushaf typefaces `HafsSmart_08.ttf`, `me_quran.ttf` | BUNDLED | Quran typography publishers (upgrade source not tracked in-repo) | **No license file in the repo** — PRIVACY.md l.42/91 states free-redistribution terms with documentation "to be completed before final store submission" | `assets/fonts/` contains only `Cairo-OFL.txt`; no OFL/readme for these two files | **FLAG → OPEN-FOR-OWNER 1** |
| 3 | Cairo Regular/Bold | BUNDLED | Cairo Project — `assets/fonts/Cairo-OFL.txt:1`: "Copyright 2009 The Cairo Project Authors (https://github.com/Gue3bara/Cairo)" ; `:3`: "licensed under the SIL Open Font License, Version 1.1" | SIL OFL 1.1 — full text bundled as an app asset (required by the license) | OFL file in-repo + UX-FIX 2 ledger (Statics derived from upstream variable font via the OFL-sanctioned `fontTools.varLib.instancer` path) | None |
| 4 | Translation `ara-sirajtafseer` — المختصر في التفسير | DOWNLOAD-PACK | fawazahmed0/quran-api pinned `@1`; editions entry: `"author": "Siraj Tafseer", "source": "https://quranenc.com"` | quran-api REPO is Unlicense ("This is free and unencumbered software released into the public domain.", LICENSE fetched 2026-10-17); the TEXT's own terms live on quranenc.com — not re-quotable here | editions.json (branch `1`) fetched 2026-10-17; fixture note `test/fixtures/ATTRIBUTION.md:16` ("source quranenc.com — open content") | **FLAG → OPEN-FOR-OWNER 2** (confirm quranenc text terms) |
| 5 | Translation `eng-safiurrahmanalm` — Saheeh International | DOWNLOAD-PACK | editions entry: `"author": "Safi Ur Rahman Al Mubarakpuri", "source": "http://tanzil.net"` | Not quotable from the listing (no license field); the translation historically carries publisher usage restrictions | editions.json fetched 2026-10-17 | **FLAG → OPEN-FOR-OWNER 3** (verify publisher terms; PD fallback listed) |
| 6 | Translation `eng-mustafakhattabg` — The Clear Quran | DOWNLOAD-PACK | editions entry: `"author": "Mustafa Khattab God Edition", "source": ""` (**empty**) | **No license evidence obtainable from the listing**; the edition is widely documented as CC BY-NC-ND 4.0 — attribution required, **no derivatives, NON-COMMERCIAL** — but that claim is not quotable from the upstream listing and is NOT asserted here as verified | editions.json fetched 2026-10-17 (empty `source`) | **FLAG → OPEN-FOR-OWNER 4** (highest-risk row: NC/ND terms would be incompatible with a paid/ads-integrated store distribution; PD fallback listed) |
| 7 | Hadith packs `ara-bukhari`, `eng-bukhari`, `eng-muslim` | DOWNLOAD-PACK | fawazahmed0/hadith-api pinned `@1` (catalog `library_catalog.json`); References.md (branch `1`, fetched 2026-10-17) cites `https://sunnah.com/` and `http://forhuman.free.fr/hadith/muslim/`; `test/fixtures/ATTRIBUTION.md:20-22`: "Sahih Muslim, English, Abdul Hamid Siddiqui translation — public domain per sunnah.com sources" | hadith-api repo Unlicense (GitHub API: `license=Unlicense`, branch `1`); classical hadith compilations public domain; the eng-muslim translation documented as public domain (fixture-cited) | References.md + GitHub API + ATTRIBUTION.md, all fetched 2026-10-17 | Bukhari EN translator license not traced per-edition → **FLAG → OPEN-FOR-OWNER 5** (light) |
| 8 | Tafsir packs `ar-tafsir-muyassar`, `ar-tafsir-al-jalalayn`, `en-tafisr-ibn-kathir` | DOWNLOAD-PACK | spa5k/tafsir_api pinned `@v1.2.2` (catalog URLTemplates, 114 files each); README sources the DATA to quran.com / qul.tarteel.ai via its source table | spa5k/tafsir_api REPO is MIT ("MIT License / Copyright (c) 2023 Spark / Permission is hereby granted, free of charge…" — LICENSE fetched 2026-10-17); the DATA's redistribution terms come from the upstream sources, not the MIT repo | GitHub LICENSE + README fetched 2026-10-17 | **FLAG → OPEN-FOR-OWNER 6** (MIT covers the API repo; original publishers' policies — e.g. the King Fahd Complex for al-Muyassar — not quotable here) |
| 9 | Adhkar, duas, ruqyah, 99-names datasets — `assets/data/*.json` | BUNDLED | Classical compilations (Tirmidhi-ordering 99 names per ledger W4) | Classical public-domain religious texts compiled in-repo | PRIVACY.md l.40/89: "compilations gathered from classical public collections, bundled offline" (wording already owner-ratified in REL-1) | None |
| 10 | `assets/data/cities.json` (156 cities) | BUNDLED | In-repo authored dataset (W3) | App-owned content | Ledger W3 probe (156/0-bad) | None |
| 11 | Recitation audio | CDN ONLY — nothing bundled | mp3quran.net free service (endpoint `lib/features/recitation/data/reciter_repository.dart:57`) | Rights to recitations belong to the reciters/their owners (PRIVACY.md l.41/90) | Upstream attribution noted in PRIVACY.md; app streams/downloads only | **FLAG → OPEN-FOR-OWNER 7** (confirm mp3quran terms for listing) |
| 12 | App icon & branding (`assets/icons/`), code | BUNDLED | In-repo authored (owner) | App-owned | n/a | None |
| 13 | Surah metadata cache `tools/chapters_cache.json` (quran.com v4) | REPO-ONLY (build tooling input; NOT in APK) | quran.com v4 API, fetched 2026-10-15 (W1a) | Factual metadata (names/counts); used once to build the shipped sqlite | Ledger W1a | None (not distributed in the artifact) |

## Ceiling verification quotes (for quick store review)

- `assets/fonts/Cairo-OFL.txt:3` — "This Font Software is licensed under the SIL Open
  Font License, Version 1.1." (full OFL text ships with the app asset).
- fawazahmed0/quran-api `LICENSE` (fetched 2026-10-17) — "This is free and unencumbered
  software released into the public domain."
- spa5k/tafsir_api `LICENSE` (fetched 2026-10-17) — "MIT License", "Copyright (c) 2023
  Spark".
- fawazahmed0/quran-api `References.md` (branch `1`, fetched 2026-10-17) —
  "- https://quranenc.com/en/home#transes" (translation-content provenance).

## OPEN-FOR-OWNER

> **Verified 2026-10-24:** primary-source quotes and a per-pack verdict are in
> `docs/store/licensing-verification-2026-10-24.md`. Six shipped packs are RED/UNVERIFIED
> (`eng-mustafakhattabg`, `eng-bukhari`, `eng-muslim`, `ar-tafsir-muyassar`,
> `ar-tafsir-al-jalalayn`, `en-tafisr-ibn-kathir`); the two fonts have embedded terms that
> must ship with the app. The decision remains OPEN-FOR-OWNER.

1. **HafsSmart + me_quran font licenses** — bundle a written license/redistribution
   statement for both TTFs before store submission (PRIVACY.md l.91 already promises this
   documentation). Nothing else in-repo can stand in for it.
2. **quranenc text terms (ara-sirajtafseer)** — confirm the quranenc.com (مركز تفسير)
   terms for redistribution inside an app download-pack; attribution is expected.
3. **Saheeh International (eng-safiurrahmanalm)** — verify the publisher's usage terms.
   If restrictive, suggested freely-licensed alternatives available in the SAME editions
   listing (source `http://tanzil.net`, public-domain works): `eng-mohammedmarmadu`
   (Pickthall), `eng-abdullahyusufal` (Abdullah Yusuf Ali).
4. **The Clear Quran (eng-mustafakhattabg)** — the editions listing carries an EMPTY
   `source` field; verify the license at the publisher before keeping the pack
   (CC BY-NC-ND 4.0 is the widely-documented claim and would forbid derivatives and
   commercial use). Same PD alternatives as 3 apply.
5. **Bukhari EN translator** — trace the per-edition translator license for
   `eng-bukhari` (the repo/tooling is Unlicense; per-translation terms untraced).
6. **Tafsir data provenance** — MIT covers the spa5k repo only; confirm the original
   publisher policies (e.g. King Fahd Complex for al-Muyassar) for runtime redistribution.
7. **mp3quran audio** — confirm mp3quran.net's terms for streaming/downloading recitation
   audio inside a store-listed app; recitation rights remain the reciters'.
8. **`eng-muslim` translation (Abdul Hamid Siddiqui)** — shipped but absent from the
   original list; upstream metadata has no license/source. Verify or hold.
