# Wave B scope — read-only gap scan and wave split

> **Status:** proposed, not started. **Basis:** a read-only scan of `main` @ `d48ca00` (2026-11-02)
> plus the standing decisions in `docs/decisions/2026-11-01-v1-launch-decisions.md` and the open
> findings in `docs/superpowers/audits/2026-10-30-code-quality-audit.md`.
> **This document does not approve any wave**: each one starts on its own owner GO.

## 1. Closed since the previous plans (do not redo)

| Item | Where it landed |
|---|---|
| Prayer calculation method + Asr madhab | `c0d853f` |
| Compass smoothing + calibration hint (D9) | `c5ea73e` |
| Per-prayer alerts, pre-adhan reminder, monthly timetable | `26eaa09` |
| Juz index, page jump, reader font size (D6) | `f8c91e1` |
| Azkar counters persisted per day + favourites (D7) | `7cffbcf` `16e9e98` |
| Backup: prayer/reader/azkar preferences exported + restore reload | `0c1cfef` |
| Onboarding setup flow, now the first-run gate | `fae8529` `d4c6a67` |
| Frozen-test policy split (Class A / Class B) | `e054f4c` |

## 2. What is actually missing

### 2a. Product features

| Gap | Evidence | Size | Owner input |
|---|---|---|---|
| **English language switch** (D1 v1.1) | `lib/app/app.dart:51` pins `Locale('ar')` and `:55` advertises Arabic only; the EN layer is complete — **285 AR keys / 285 EN keys, 0 drift** | M | None (groundwork paid) |
| **Download resume + queue** (D10 v1.1) | `lib/features/recitation/data/audio_downloader.dart` has only atomic `.part` promote (`:183`, `:250`); no HTTP `Range`, no global queue | M | None; must prove Range on the pinned hosts |
| **Adhan sound choice** | No sound configuration anywhere; `notifications_binding.dart:129` passes `requestSoundPermission: false` | S–M | **Yes** — needs licensed adhan audio assets |
| **Tafsir in-app** | The pipeline exists (catalog kind `tafsir`, per-surah `urlTemplate`, downloader loop) but `assets/data/library_catalog.json` ships **0 tafsir packs** (2 translations + 1 hadith) | S (catalog) | **Yes** — licensing |
| **Word-by-word meanings** | Plan exists (`2026-10-19-wm-1-word-meanings.md`); no data source is cleared | L | **Yes** — sourcing/licensing |
| **iOS app shell** (D11) | `ios/` contains only `.gitignore`; no `Podfile`, no `DEVELOPMENT_TEAM` | L | **Yes** — separate project |
| Zakat input persistence (D8) | decided **no** (sensitive financial input) | — | Revisit only with a privacy decision |
| Crash reporting (D5) | decided **Play vitals only**, no third-party SDK | — | Policy, not code |

### 2b. Performance / quality residuals (audit 2026-10-30, still open on this tree)

| Sev | Evidence | Fix |
|---|---|---|
| Med | `lib/features/azkar/presentation/azkar_screen.dart:299` — one `BlocBuilder<AzkarCubit, AzkarState>` wraps the reciting `ListView`, so **every counter tap rebuilds all visible cards**; sharper now that each tap also persists | per-row `BlocSelector<…, int>` on `remaining[i]` |
| Low | `lib/features/recitation/presentation/playback/player_sheet.dart:111` — plain `BlocBuilder` with no `buildWhen`, so the whole sheet rebuilds on the 1 Hz position tick, including mid-drag | `buildWhen` that ignores position while dragging |
| Low | `lib/features/quran/data/quran_search_repository.dart:24,40-42` — a second full `COUNT(*) … LIKE %token%` scan on **every** page | count on page 1 only, or derive `hasMore` from the row probe |
| Med | `lib/core/db/app_database.dart:37-87` — `beforeOpen` runs duplicate-repair `DELETE`s and index `DROP/CREATE` on **every** launch; `onUpgrade` only handles `from < 2`, `schemaVersion = 2` | move the repairs into a versioned `onUpgrade` step; `drift_dev ^2.35.1` is already a dev dependency, so a schema dump is available |
| Med | `lib/features/backup/presentation/backup_section.dart:22` (99-line `build`), `player_sheet.dart:104` (102-line `build`) | extract named sub-widgets |
| Low | test fixtures re-declared per suite | one shared fixture module (Class B: new files only) |

### 2c. Launch / store (owner-led, not app code)

| Item | State | Owner action |
|---|---|---|
| Licensing sign-off (D4) | two translations + `ara-bukhari` with a provenance note; fonts and mp3quran terms pending | written terms |
| R8 + resource shrinking (D2) | off | one signed build + `tools/device_smoke.ps1` |
| Play App Signing + `assetlinks.json` (D3) | upload cert pinned only | Play Console enrollment, paste the app-signing SHA-256 |
| 16 KB page alignment (D12) | unmeasured | `zipalign -c -P 16` on the signed artifact |
| Store asset refresh + upload | screenshots from the `1.0.0+3` build | re-shoot + upload |

## 3. Proposed Wave B split

Each wave is independently shippable, gated by `dart format` 0 / `flutter analyze` 0 / full
`flutter test` with an exact count, and follows the two-class frozen-test policy.

| Wave | Scope | Commits | Risk | Ruling needed |
|---|---|---|---|---|
| **B1 — Perf residuals** | azkar per-row selector · player-sheet `buildWhen` · search count paging | 3 | low | none |
| **B2 — English switch** | persisted `app_locale`, settings row, `MaterialApp.locale` from state, `supportedLocales` = ar+en, Android locale config, LTR/RTL + persistence tests | 3–4 | medium (RTL layout, 285 strings) | none |
| **B3 — Downloads resume + queue** | HTTP `Range` resume onto the existing `.part`, global queue with backoff, per-host capability probe, tests against a local range-capable server | 4 | medium–high (host behaviour, partial-file safety) | none, but the host list is a STOP if Range is unsupported |
| **B4 — DB versioned migrations** | schemaVersion 2 → 3, move duplicate repair + index maintenance into `onUpgrade`, drift schema dump + stepwise migration tests (v1→v2→v3, v2→v3) | 2–3 | medium (data loss if wrong) | **Yes** — touching the DB open path and the migration contract |
| **B5 — Store readiness** | Gradle R8/shrink flags behind `PUBLISH_RELEASE`, signed build + device smoke, `zipalign -P 16` probe, assetlinks update, store copy refresh | 1 code + owner steps | high (signed artifact) | **Yes** — keystore + Play console |
| **B6 — Content** | tafsir pack in the catalog (code already supports it), adhan audio, word-by-word | 1 vs L/L | — | **Yes** — licensing |

## 4. Recommended order

1. **B1** — three small, provably safe wins; no rulings; immediate feel improvement in azkar and playback.
2. **B2** — the last big unfinished v1.1 promise, and the groundwork is already paid (285/285 parity).
3. **B4** — do it before the DB grows more settings; needs the owner's ruling because it changes the migration contract.
4. **B3** — highest risk of the list; must be piloted against the real CDN before it lands.
5. **B5** — owner-paced, parallel to any wave.
6. **B6** — only once licensing moves.

## 5. Explicitly out of scope for Wave B

- iOS shipping (needs a machine, a team id and a store account).
- Crash-reporting SDKs (D5 stands).
- Zakat persistence (D8 stands).
- Any `web/` work (separate campaign).
- Re-litigating the launch decisions D1–D12 without a written owner change.
