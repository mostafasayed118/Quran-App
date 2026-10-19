# Quran Yahdi Web — Mushaf Page Mode (وضع صفحات المصحف) — Design Spec

Date: 2026-10-19 · Status: **APPROVED — owner sign-off 2026-10-19 (as drafted; the Q1–Q3 proposed defaults stand)** · Owner: Mustafa Sayed (mostafasayed118)
Scope: the Astro site in `web/` (single repo `Quran-App`, branch `main`).
Predecessors: `docs/superpowers/specs/2026-10-17-quran-yahdi-web-design.md` (site design) · plans `2026-10-17-web-p1-foundation.md` → `2026-10-18-p4-app-links.md`.

The owner approved the feature concept (mushaf page mode in the web reader, 2026-10-19) with four pillars: **page ranges (`pagesStart`/`pagesEnd`)** · **page navigation** · **position save (resume)** · **integration** with the existing reader. This spec fixes the design for implementation.

---

## 1. Goal

Let a visitor read the web reader **page by page, like a physical mushaf** — the same ayah text laid out on its real mushaf page (1–604) — with page navigation and last-read resume, on both `/surah/{n}` and `/en/surah/{n}`. No new data pipeline: the page numbers are already committed (§3).

## 2. Evidence — the data already exists (verified 2026-10-19)

| Fact | Source |
|---|---|
| Every ayah carries `page` (1..604) | `web/src/data/ayahs/{1..114}.json` — e.g. `108.json`: `{"n":1,"juz":30,"page":602,...}` |
| Every surah carries `pagesStart` / `pagesEnd` | `web/src/data/surahs.json` — e.g. surah 1 → `"pagesStart":1,"pagesEnd":1` |
| The reader already types `page` in its import cast | `web/src/components/pages/ReaderPage.astro` (~line 13) |
| The generator keeps these in sync with the app DB | `tools/export_web_data.dart` (ayah fields `{n,juz,page,u,i,sajda}`) |
| App reference implementation (parity target) | `lib/features/quran/presentation/reader/mushaf_page_block.dart` (`groupAyahsByPage`, lines 17-33) + `test/mushaf_grouping_test.dart` |
| The existing toolbar «المصحف/الإملائي» toggle is a **script** switch (Uthmani glyphs ↔ imlaei text), NOT a layout | `web/src/lib/reader-settings.ts` (`ReaderView`) · `web/src/lib/strings.ts` (`readerViewMushaf`/`readerViewImlaei`) |

Ayah text fields (`u` PUA glyph stream + `i` plain imlaei + `sajda`) are unchanged by this feature.

## 3. Locked at concept (owner-approved)

- Mushaf page mode ships in the web reader (AR + EN routes).
- The four pillars above; parity with the app's mushaf behavior wherever the web has the same affordance.

## 4. Proposed design (for owner review)

### 4.1 Page model — surah-scoped (app parity)

Mirror the app exactly: for a surah, its pages are the **distinct `page` values of its ayahs, ascending** (`pagesStart`…`pagesEnd`); a page block shows **only the current surah's ayahs that fall on it**; pages with zero ayahs of this surah are omitted. Consequence (same as the app): for a short surah a "page" can hold just a few ayahs (e.g. surah 108 → one page block, 3 ayahs, page ٦٠٢).

**Not in v1:** cross-surah physical pages (a real mushaf page can span surahs) — a future option, needs a build-time page→(surah, ayah) index and a page-centric URL model.

### 4.2 Layout & look

- One page = a framed "mushaf page" card in the existing visual identity (paper/ink/gold tokens): the page's ayahs flow as one continuous RTL text block with inline ornate ayah-number medallions, and a page-number footer in Arabic-Indic digits («٦٠٢»).
- The basmala stays as the existing surah header — not repeated inside page cards.
- The reader toolbar gains a third control — **layout: آيات ↔ صفحات**. The existing script toggle (مصحف/إملائي) and the font-step control stay independent (every combination is valid).
- EN route renders the same mushaf pages with LTR chrome around RTL ayah text (existing pattern: `html[dir='ltr'] .reader .ayah-text { direction: rtl }`).

### 4.3 Navigation

- Prev/next page controls + a position indicator «صفحة X من Y» (absolute mushaf page number + the surah's page-block count); changing page swaps the page block client-side and scrolls to the top of the reader frame.
- Keyboard: ←/→ page navigation while the reader has focus.
- Deep links stay ayah-based and canonical: `#ayah-{m}` (existing share URLs, unchanged). In page mode the reader opens the page containing `m` and scrolls to that anchor.

### 4.4 Position save (resume)

- localStorage shape UNCHANGED: `qy:last-read = {s, a}` (`web/src/lib/reader-resume.ts`) — no migration; the already-shipped ResumeCard keeps working as-is.
- Entering a surah: page mode → open the page containing `a`; verses mode → current behavior.
- In page mode the scroll-observer flush is disabled; on page change the reader writes `{s, a = first ayah of the shown page}` (app parity: `reader_cubit.dart` page-change handler).

### 4.5 Ayah interactions (integration with existing features)

- Every ayah keeps `id="ayah-{n}"`, its anchor, and its full action set (copy / share / bookmark / listen / content panel) in page mode.
- In page mode the per-ayah action row is hidden by default; tapping an ayah selects it and reveals its actions (one selected ayah at a time; tapping elsewhere deselects). Copy stays imlaei-only (PUA law). Share keeps the canonical `#ayah-{m}` URL for the current locale.

### 4.6 Settings & pre-paint

- `qy:reader` gains an **additive** field `layout: 'verses' | 'pages'`, default `'verses'` (existing visitors see zero change; a missing field reads as the default — no version bump).
- The existing inline pre-paint script also sets `data-reader-layout` so the first paint matches the stored layout (no flash of the wrong layout).

### 4.7 Lifecycle & no-JS

- Follow the existing ClientRouter pattern: cleanup on `astro:before-swap`, re-init on `astro:after-swap` (same as ReaderPage's current scripts).
- Server HTML stays verse mode; layout applies client-side (like the current script toggle). Crawlers/SEO see the same 114 surah pages; page mode reuses the SSR ayah elements (no duplicated content).

## 5. Budget & performance

- Implementation extends the existing inline reader script — no new dependency, no framework.
- Expected net cost ≈ +1–2 KB gz; the reader budget (`check-budgets.mjs`, measured 15.17/30 KB after W3) must stay PASS. The budget number is NOT raised by this feature without an owner decision.

## 6. Files (work sketch — for the p6 implementation plan)

| File | Change |
|---|---|
| `web/src/lib/mushaf.ts` (new) | Pure `groupAyahsByPage` equivalent + page utils (unit-testable) |
| `web/src/components/pages/ReaderPage.astro` | Layout toggle, page renderer, nav, resume integration, pre-paint attribute |
| `web/src/lib/reader-settings.ts` | Additive `layout` field |
| `web/src/lib/strings.ts` | Additive AR/EN labels |
| `web/src/styles/global.css` | `[data-reader-layout]` rules + page-card styles |
| `web/tests/unit/mushaf.test.ts` (new) | Grouping + data invariants |
| `web/tests/e2e/reader.spec.ts` / `en.spec.ts` | e2e additions (inside existing tests where possible; exact count deltas reported) |

## 7. Tests & acceptance criteria

1. **Unit** — grouping mirrors the app expectations (`test/mushaf_grouping_test.dart`: pages [2,3,4] → counts [2,1,3] on the same fixture shape); data invariants over ALL 114 ayah files: every ayah `page` ∈ `[pagesStart, pagesEnd]` of its surah, and the surah's distinct pages ascending equal its range.
2. **e2e** — toggle to صفحات shows a page card with exactly that page's ayahs; prev/next changes the page and updates resume; reload with stored `layout: pages` paints page mode without flash; `#ayah-{m}` deep link opens the right page in page mode; ClientRouter round-trip (AR↔EN) keeps the layout; actions still work in page mode (copy imlaei, share URL, bookmark); no horizontal overflow at 360px and the 44px coarse-pointer target rules stay green with the third toolbar control.
3. **Gates** — all existing web gates green; no new dependency; exact suite-count deltas reported.

## 8. Out of scope (recorded)

- Cross-surah physical pages (multi-surah page content) — future option (needs a page index + page-centric URLs).
- 15-line typographic justification / true print fidelity.
- Page-level share URLs or SEO routes.
- PWA/offline mode (separately declined by the owner; needs its own spec if requested).

## 9. Questions for the owner (this review)

| # | Question | Proposed default |
|---|---|---|
| Q1 | Default layout for a first visit (no stored setting)? | **آيات (verses)** — zero change for everyone; صفحات is opt-in |
| Q2 | Toggle + footer wording | «آيات» / «صفحات» · footer «صفحة ٦٠٢ من ٤» — owner's eye welcome |
| Q3 | Short-surah partial page blocks (e.g. surah 108 → one block of 3 ayahs) acceptable as-is (app parity)? | **Yes** — parity first; cross-surah pages are a future option |

## 10. Owner sign-off checklist — SIGNED OFF 2026-10-19

- [x] §4.1 page model (surah-scoped, app parity)
- [x] §4.2 look & the new layout toggle
- [x] §4.3 navigation + deep-link behavior
- [x] §4.4 resume (shape unchanged, first-ayah-of-page write)
- [x] §4.5 tap-to-select actions in page mode
- [x] Q1–Q3 above (defaults as proposed)
