# AGENTS.md — Quran Yahdi (`quran_yahdi`) — project working instructions

> Adapted for THIS repository (2026-10-18) from the owner's `INSTRUCTIONS.md`.
> `INSTRUCTIONS.md` is the owner's personal source notes and stays **untracked**; this file is the applied, repo-true version.
> Applies to every agent session in this repo. **Owner-ratified 2026-10-18.**

## 0) Operating modes — read first, never mix them

- **MODE A — PAIRING** (the owner pairs with the agent live): the Learning Contract (§1) governs.
- **MODE B — CAMPAIGN** (delegated waves via English briefs + the campaign ledger): the campaign protocol (§4) governs.
  Where the two conflict (approval waits, branching, walkthroughs), CAMPAIGN rules win for campaign sessions; §1 wins when the owner is pairing directly.

**Language:** chat with the owner = Egyptian Arabic. Delegated/committed artifacts (briefs, plans, reports, **commit messages**) = English. Commit messages are **byte-copied — NEVER translated** (standing rule).

## 1) Learning Contract — pairing mode (adapted from Section A)

For every meaningful change: 1) explain the problem, 2) explain the plan + files touched, 3) explain alternatives and the pick, 4) wait for approval when non-trivial, 5) implement, 6) offer a learning walkthrough:

- what problem did we solve and why this approach
- how data flows through the layers
- which Flutter/Dart concepts appeared and why they matter
- what each important file owns
- what was tested and why · current limitations
- 3–5 self-check questions

Style: the owner is a **senior** Flutter engineer — tradeoffs not basics; compare alternatives; stop over-engineering, warn on under-engineering; challenge code accepted without understanding. Do not silently generate code; do not hide architecture decisions. "Build passes" ≠ "learning complete". Use a Mermaid diagram only when it beats prose (keep reusable ones in `docs/`).

## 2) Project truth — verified 2026-10-18 (do not invent alternatives)

**Toolchain:** Flutter 3.47.5 stable / Dart 3.13.4 · Windows PowerShell 5.1 (no `&&`; use `;`).

**Stack (as actually shipped):**
- State: `flutter_bloc ^9.1.1` Cubits + **freezed** immutable states (`Equatable` is NOT used)
- DI: `get_it` · Routing: `go_router ^18.1.0` · DB: `drift` · HTTP: `dio` (+ `http`)
- l10n: `flutter_localizations` + ARB (`lib/l10n/app_ar.arb` is the template; EN mirrored; generated files committed)
- Domain packages: `just_audio` (+ `just_audio_background`), `flutter_local_notifications` + `timezone`, `geolocator`, `sensors_plus`, `adhan`, `hijri`, `app_links`, `share_plus`

**Layout:**
- `lib/app/` — app, bootstrap, router, deep_links
- `lib/core/` — db, di, domain, l10n, theme, utils, widgets
- `lib/features/<feature>/` — `data/` + `presentation/` (cubit + freezed state + screens) — 15 features
- `lib/l10n/` · `test/` (flutter_test only; fakes/hand-rolled harnesses — `bloc_test`/`mocktail` are NOT in the repo; adding any package needs an explicit owner grant)
- `web/` — the Astro site, a separate owner-supervised campaign (sanctioned-foreign for app waves)
- `tools/` · `docs/` (`campaign-ledger.md` = the append-only campaign record; `store/` = Play assets; `superpowers/{plans,specs,audits}`)

**Error handling:** repositories surface failures; cubits expose explicit **Loading / Ready / Failed** states; UI shows **localized copy only** (never raw exceptions — diagnostics to dev.log). A `Result<T>` layer is NOT in use (introducing one = explicit owner decision).

**NOT in this project:** Supabase · Sentry · Firebase · Provider (banned for new features) · GetX · Riverpod · Stacked.

## 3) Engineering rules (adapted from Sections C/D/E/F/G)

- Smallest change that solves the problem; fix root causes; read the code before modifying; never break existing behavior.
- Layer boundaries: widgets render + dispatch; logic in cubits; persistence behind repositories (feature-local — there is no global `lib/data/`).
- **FROZEN TESTS:** existing tests are never edited in campaign waves. Any perceived need to touch one = STOP and report.
- **l10n is additive + symmetric:** never change existing ARB values; AR template → EN mirror; regenerate + commit generated files.
- Dependencies: justify (why now / alternatives / deferrable), latest stable, explicit owner grant per package.
- Commits: small, focused, English; **explicit pathspecs — never `git add -A`**; review `git status` + `git diff` first; never commit keystores, `android/key.properties`, secrets, `.env`, `local.properties`, generated junk.
- **NEVER commit or push without explicit owner approval.** Pushes happen only in owner-GO push windows (pre-flight → push → `git ls-remote` proof → CI check: `web-gates` + `ci`).
- Verification: after meaningful changes run `flutter analyze` (expect 0) and the full `flutter test` (record exact counts); never claim success unverified.
- Tests: deterministic; one behavior per test; a logic bugfix ships with a reproducing test. Widget tests use **bounded pumps** — `pumpAndSettle` hangs while drift loads in the background.

## 4) Campaign protocol — Mode B essentials

- Waves run on trunk `main` (+ optional git worktrees for isolation) — **never branch-per-task**.
- Executor briefs: English, self-contained, with a **verbatim start gate** (HEAD pin · expected porcelain set · unpushed count · toolchain), a STOP list, gates (`analyze` 0 + full tests with exact frozen counts), explicit-pathspec commits, and **NO PUSH**.
- The ledger `docs/campaign-ledger.md` is **append-only**; the PM writes close-outs; executors never touch `docs/`.
- Report format: start-gate output verbatim · per-commit SHA/stat · gate tails · confirmation bullets · STOPs/deviations/disclosures · final porcelain + unpushed count.
- Sanctioned-foreign during app waves: `web/**`, `.github/workflows/web.yml`, docs-only deltas, `tools/export_web_data.dart`, `docs/campaign-ledger.md`. `INSTRUCTIONS.md` and `.vscode/settings.json` are expected debris — **never touch/stage/commit**. Never `fetch/pull/rebase/merge`.
- Device legs (PM-owned, no device work inside executor waves): full adb path `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`; test device Infinix X6882 (`13372704AR007777`); screenshots = device-side `screencap` + `adb pull` (never pipe binary through PowerShell).
- Release: **W7c pending** — `android/key.properties` is gitignored; the production keystore lives OUTSIDE the repo (never lost). Until intake, release builds stay debug-signed (fails-soft by design).

## 5) Branches

- Campaign sessions: trunk only. Pairing sessions / experiments: optional short `<type>/short-description` branch.

## 6) Reading lists (filtered for this project)

### 6a) Skills
The `skills.sh` list in `INSTRUCTIONS.md` (Section H) is a Claude-Code-plugin artifact — treat it as a **manual reading list**. In opencode, use the locally installed skill catalog when a task matches it (e.g. `systematic-debugging`, `verification-before-completion`, `design-taste` / `taste-*`, `ponytail`). Most relevant topics for this repo: go_router patterns · widget tests · layout overflow · l10n/ARB · performance & app size.

### 6b) Reference repos (read-only — prior art, never dependencies)
| Repo | Use it when |
|---|---|
| felangel/bloc | Cubit patterns, testing helpers, BlocObserver |
| fluttercommunity/get_it | Lazy singleton vs factory registration |
| flutter/packages | go_router behavior + flutter_localizations/ARB structure |
| rrousselGit/freezed | States/entities, sealed unions, copyWith (in use) |
| simolus3/drift | Queries, migrations, reactive reads (in use) |
| cfug/dio | Interceptors, cancellation, FormData |
| ResoCoder/flutter-clean-architecture-tdd · brianegan/flutter_architecture_samples | Design tradeoffs & boundaries prior art |
| VeryGoodOpenSource/very_good_analysis · dart-lang/lints | Tightening `analysis_options.yaml` |
| flutter/samples · flutter/devtools | Test scaffolding examples · profiler/inspector behavior |
| leoafarias/fvm · felangel/mason · shorebirdtech/shorebird | Toolchain hygiene, scaffolding, OTA hot-fix evaluation |
| Baseflow/permission_handler · flutter_local_notifications · fluttercommunity/flutter_workmanager | Device capability additions (justify + owner grant first) |
| gskinner/flutter_animate · rive-app/rive-flutter · Baseflow/flutter_cached_network_image | UI polish candidates (only via granted scope) |

### 6c) Do not use (unchanged from Section I-11)
getx · riverpod (comparison only) · stacked · firebase/flutterfire · flutter-after-layout (use `addPostFrameCallback`) · kt.dart · bolt · flutterfire_desktop — all excluded.

---
*Last updated: 2026-10-18 — adapted for `quran_yahdi`; owner-ratified (recorded in `docs/campaign-ledger.md`).*
