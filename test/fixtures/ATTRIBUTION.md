# Test fixtures attribution (W6)

All fixtures are byte-preserved or shape-locked excerpts of probed real CDN
files, pinned exactly as the installed packs are pinned. They exist for
hermetic tests only — tests never touch the real CDN.

- `tafsir_muyassar_surah_1.json` (5,249 B, byte-identical) —
  spa5k/tafsir_api pinned `@v1.2.2`, file `tafsir/ar-tafsir-muyassar/1.json`.
  Open content sourced from quran.com data; excerpt = Surah 1 (7 ayahs).
- `tafsir_wrapper_sample.json` — app-defined install wrapper built AROUND the
  real surah-1 array above (wrapper shape is fixture-locked; the inner array
  is the untouched real excerpt). Attribution embedded in the wrapper
  (`attribution` key) because the wrapper shape is app-owned.
- `translation_ara_sirajtafseer_excerpt.json` (12,875 B, shape-locked) —
  fawazahmed0/quran-api pinned `@1`, edition `ara-sirajtafseer`
  (المختصر في التفسير، source quranenc.com — open content). Excerpt = first
  40 ayah objects of the original minified file (JSON cannot carry a header
  comment, so attribution lives here).
- `hadith_eng_muslim_excerpt.json` (10,314 B, shape-locked) —
  fawazahmed0/hadith-api pinned `@1`, edition `eng-muslim`
  (Sahih Muslim, English, Abdul Hamid Siddiqui translation — public domain
  per sunnah.com sources). Excerpt = full `metadata` + first 12 hadiths.
