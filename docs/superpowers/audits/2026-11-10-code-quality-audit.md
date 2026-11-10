# Code Quality Audit — Quran Yahdi (`quran_yahdi`) — 2026-11-10

> **Remediation landed (2026-11-10).** This report is the snapshot taken at
> `6e0ff45` with a dirty working tree. The wave it produced is merged on `main`
> as `7635a29` (PR #26) — see the close-out in `docs/campaign-ledger.md`. Every
> High finding and every Medium except the deferred list at the bottom of that
> entry is closed; the deferred items are: the `update/` cubit question, FTS5
> `content=''`, `directives_ordering`, `_postShellRoutes`/`player_sheet` splits,
> and the folder-bookmarks N+1 (port widening). Scores and counts below are the
> pre-fix baseline and are kept unchanged on purpose.

**Mode:** read-only. **No file inside the repository was created, edited or deleted.**
**Scope:** `lib/`, `test/`, `android/`, `ios/`, `web/public/`, `tools/`, governance docs.

| | |
|---|---|
| HEAD at audit time | `6e0ff453ba8c93d6d7953b5c1ad3bc1cd0ce6364` — branch `wave/audit-remediation` (7 ahead of `origin/main`, 1 behind `main`) |
| Working tree | **dirty** — uncommitted WIP: a new `update` feature, the version-gate/review wave, and a 14-file `lib/` diff |
| Toolchain | Flutter 3.47.5 stable / Dart 3.13.4 · Windows PowerShell 5.1 |
| Scale | **346** `lib/*.dart` (307 hand-written) · **60,693** LOC · **413** `test/*.dart` · **44,697** test LOC · **19** features |

---

## Baseline (run by the integrator, not delegated)

| Gate | Result |
|---|---|
| `flutter analyze` | **0 issues** (89.0 s) |
| `dart format --output=none --set-exit-if-changed lib test tools` | **763 files, 0 changed** (exit 0) |
| `flutter test` | **1498 / 1498 passed** (7 m 10 s), exit 0 |
| ARB parity | **422 AR message keys = 422 EN**, diff **0** (the 3-key delta is `@`-metadata, which legitimately lives only in the AR template) |
| Cross-feature edges | **2** live (`quran->library`, `quran->recitation`) — matches `allowedFeatureEdges` exactly |

---

## Scorecard

Weights: security 25% · maintainability 20% · architecture 20% · code quality 20% · performance 15%.

| Dimension | Score | Weight | Contribution | Authored by |
|---|---:|---:|---:|---|
| Security | **7.5** | 25% | 1.875 | subagent, integrator-verified |
| Maintainability | **7.0** | 20% | 1.400 | subagent, integrator-verified |
| Clean architecture | **7.0** | 20% | 1.400 | subagent, integrator-verified |
| Code quality | **7.4** | 20% | 1.480 | subagent, integrator-verified |
| Performance | **7.5** | 15% | 1.125 | subagent, **adjusted down** 8.0 → 7.5 (see below) |
| **Overall weighted** | **7.28 / 10** | 100% | **7.280** | |

```
7.5 × 0.25 = 1.875   (security)
7.0 × 0.20 = 1.400   (maintainability)
7.0 × 0.20 = 1.400   (clean architecture)
7.4 × 0.20 = 1.480   (code quality)
7.5 × 0.15 = 1.125   (performance)
                        ------
                        7.280  →  7.28 / 10
```

**Performance score adjustment (disclosed).** The performance lane scored **8.0** but explicitly did
not examine the backup export/import path ("only `backup_crypto.dart`'s PBKDF2 cost was read at
source") and did not read the reader's per-build allocation. The integrator independently verified
**three further Medium performance findings in exactly those two areas** (the pure-Dart PBKDF2 and
a double 2 MiB decode on the UI isolate; `stripAyahEndMarker` per rebuild). Adding them to the
lane's own set (1 High + 1 Medium + 4 Low/Info) pulls the score to **7.5**.

**Verdict.** Strong engineering discipline in the layers that existed before 2026-11-09, with
genuinely excellent enforcement (a two-way-pinned architecture guard, a hash-enforced CSP,
parameter-bound SQL, per-hop redirect re-validation). The score is held down by the **newest
wave** — the update/version-policy feature and the backup passphrase crypto — plus the FTS5 search
migration, which traded correctness for speed and silently broke short-token Arabic search. **One
finding is a live, user-facing defect shipped in `a13033c`** (the search regression); the rest are
in code that is either unshipped, owner-gated, or a prior-audit item that was never closed. No
Critical finding; the highest *forward-looking* risk is a **remote, unrecoverable availability
lockout**.

### Trend

| Audit | Scale | Tests | Weighted |
|---|---|---:|---:|
| 2026-10-30 | 211 files · 34,018 LOC | 815 | **7.80** |
| **2026-11-10 (this)** | 346 files · 60,693 LOC | 1498 | **7.28** |

The surface grew **78%** and the suite **84%** while every gate stayed green and class-level
doc coverage went **46% → 96.6%**. The weighted score nevertheless fell 0.52. The rubrics are
not identical, but the honest reading is: **growth outpaced discipline in the newest wave.**
The new code is where the findings cluster — 9 of the 12 Medium/High findings are in the
uncommitted `update`/version-gate wave or in the 2026-11-09 backup-crypto and FTS5 commits — and
the **campaign ledger has been silent since 2026-11-07**, so none of those three waves has a
recorded rationale.

---

## 1) Security — 7.5 / 10

No Critical. The pre-existing surface is unusually tight; the deductions are entirely in new code.

**Verified controls (not merely claimed).** `allowBackup="false"` + `fullBackupContent="false"` +
`data_extraction_rules.xml` excluding `database`/`sharedpref`/`file` for cloud-backup **and**
device-transfer (`android/app/src/main/res/xml/data_extraction_rules.xml:3-14` — the prior audit's
Low is **CLOSED**). `android:usesCleartextTraffic="false"`, no `network_security_config.xml`, no
iOS ATS exceptions. Every exported component is permission-guarded; the deep-link filter is
`autoVerify` + host-scoped + path-scoped. Every `customSelect` binds a parameter and the FTS5
`MATCH` expression is a quoted, bound variable (`lib/features/quran/data/quran_search_repository.dart:51-52,64-67`).
No archive extraction → no zip-slip. Download redirects are followed manually with
`followRedirects:false` and **every hop re-validated** against a host allowlist. Pack bodies are
sha256-verified before promotion. The web CSP has `script-src 'self'` + 7 exact `sha256-` pins,
no `unsafe-inline`/`unsafe-eval`, `object-src 'none'`, `frame-ancestors 'none'`, HSTS — and the
hash list is **enforced by a gate** (`web/scripts/check-budgets.mjs`). Secrets sweeps for
`AIza`/`sk-`/`ghp_`/JWT/`-----BEGIN`/credentialed URLs across `lib/`, `android/`, `ios/`, `web/`,
`tools/`, `docs/` return **0 hits**; `android/key.properties` and `.env` are proven ignored via
`git check-ignore -v`. Deep links are clamped (`deep_links.dart:24,32,51`).

**What does not exist:** no authentication surface at all (no accounts, login, tokens, session or
local PIN/biometric) — so nothing to steal and no authorization to bypass; no WebView, no
`evaluateJavascript`, no `addJavascriptInterface`; no dynamic code loading, no
`REQUEST_INSTALL_PACKAGES`, no APK auto-install.

### [Medium] The version policy is an unsigned remote kill-switch with no in-app recovery
`lib/app/version_policy_service.dart:17-18,62-71,83-91` · `lib/core/domain/version_policy.dart:116-129,149-157`
· `lib/app/version_gate.dart:91-102,119-123` · `lib/app/router.dart:147-151,260-276`
· `lib/features/update/presentation/update_gate_screen.dart:56-57,89-100`
**OWASP M8 Security Misconfiguration / M4 Insufficient Validation; A08:2021 Software and Data Integrity Failures.**

`https://quranyahdi.pages.dev/version.json` is fetched over HTTPS but the document is **never
signed, MAC'd or integrity-checked** — `VersionPolicy.fromJson` validates *shape only*. There is
**no upper bound** on `min_supported` and **no `expires_at`**. `{"min_supported":"99.0.0","latest":"99.0.0"}`
parses cleanly → `updateRequired` → `VersionGate.decide` rewrites **every** location to `/update`
→ the mandatory screen is a full-screen lock (`PopScope(canPop: !mandatory)` blocks back,
`automaticallyImplyLeading: !mandatory` removes the arrow, the only control is "Update now").
There is **no "continue anyway", no grace period, no client-side kill-switch** — the only off
switch is the compile-time `--dart-define=QURAN_VERSION_POLICY_URL=off`, unreachable for an
installed app. Worse, the policy is **persisted into drift** (`version_policy_service.dart:78`,
key `version_policy_cache`) and re-served on any later fetch failure (`:69-76,83-91`), so a device
that fetched a bad policy **stays walled while offline, even after the owner republishes a good file**.

*Material mitigating facts (verified):* the remote `store_url` is **never opened** — the button
always calls `InAppReview.instance.openStoreListing(appStoreId: kPlayStoreId)`
(`lib/app/version_ack_store.dart:45-56`), so **no phishing/open-redirect**; the remote
`message_ar`/`message_en` are parsed but never rendered (the screen uses ARB strings), so **no
remote text injection**. The policy controls **availability only**. And it is **dormant today**:
no `version.json` exists in `web/public/`, matching `docs/release-readiness-audit.md:72`.

*Fix:* (a) sign the document (Ed25519 detached signature, public key embedded in the app) and
reject an unsigned one; (b) add `expires_at` + a `max_age` on the cached copy and drop it when stale;
(c) reject a `min_supported` more than N minor versions above the installed build (a typo like
`9.9.9` bricks everyone); (d) cap the response body size before `jsonDecode` and require `https`
in `versionPolicyUrl()`; (e) offer a bounded escape hatch (defer enforcement by N hours) or an
owner-signed "revoke enforcement" file that clears the gate without a new release.

### [Medium] Attacker-chosen `kdf.iterations` (1 … 10,000,000) runs on the UI isolate
`lib/features/backup/data/backup_crypto.dart:118-126,144-151` · `lib/features/backup/data/backup_io.dart:106-119`
· `lib/features/backup/presentation/backup_cubit.dart:145-176` — **OWASP M4 / M8.**

`decryptBackupJson` reads the iteration count **from the untrusted file**, clamps it only to
`(1, 10000000)`, and runs it. The whole derivation executes **on the calling (UI) isolate** —
the module header says so (`backup_crypto.dart:20`) and `backup_io.dart:113` calls it inline
(only the *plaintext* decode is isolated, `:124`). A structurally valid hostile envelope carrying
`"iterations": 10000000` makes the victim perform 10M pure-Dart PBKDF2 rounds **on the UI thread**
before the GCM tag check fails → minutes of frozen UI / ANR, with no cancel. The same field
accepts `"iterations": 1`, silently weakening any file it lands on.

*Fix:* clamp to a narrow documented band (reject anything outside 100,000–1,000,000); bound the
total derivation cost; run the KDF in `Isolate.run` — the same treatment the plaintext path
already gets at `backup_io.dart:124-129`.

### [Medium] The KDF is 6× below the project's **own ratified floor**, and the envelope header is unauthenticated
`lib/features/backup/data/backup_crypto.dart:39,44-47,62-79,115-126,144-156`
vs `docs/superpowers/specs/2026-10-24-backup-encryption-decision.md:52-55,70` — **OWASP M10 Insufficient Cryptography; MASVS-CRYPTO.**

The repo's own ratified decision specifies:

> **Cipher:** AES-256-GCM, a fresh random 96-bit nonce per file, **header as AAD**.
> **KDF:** **Argon2id** `m=19 MiB, t=2, p=1` (OWASP minimum); fall back to
> **PBKDF2-HMAC-SHA256 with 600,000 iterations** only if Argon2id is unavailable.

The shipped code uses `kEncryptedBackupKdfIterations = 100000` — **6× weaker than the project's
own floor** — and never uses Argon2id, although the fallback was never needed: `Argon2id` ships in
`cryptography` 2.9.0 (`algorithms.dart:502`). The `aad` parameter exists on `AesGcm.encrypt`
(`algorithms.dart:2134,2145-2148`) and is **used nowhere** (`rg aad` in `backup_crypto.dart` → 0),
so the envelope's `app`/`format`/`kdf` header is **unauthenticated** and `kdf.name` is decorative.
`SecretKey.destroy()` exists (`secret_key.dart:59,202`) and is never called; the plaintext
`Uint8List` is never wiped. The envelope also drops the spec's magic `QYBAK` + version byte.

*Correct and not reported:* AES-256-GCM, a fresh random 12-byte nonce and 16-byte salt per
encryption (`Random.secure()`), GCM authentication verified before plaintext is released, and
wrong-passphrase indistinguishable from tampering.

*Fix:* raise to 600,000 (or move to Argon2id `m=19 MiB, t=2, p=1` as specified); bind the header
as AAD; `destroy()` the derived key and zero the plaintext buffer; add the magic + version byte.
Note the decision doc's own trigger ("only if a concrete need appears") was arguably never met —
either **re-ratify the parameters** in the decision doc or bring the code up to them.

### [Medium] `assetlinks.json` pins only the release/upload cert — App Links break at first Play upload
`web/public/.well-known/assetlinks.json:1-12` · `android/app/src/main/AndroidManifest.xml:46-56` — **OWASP M8.**

The file carries one fingerprint, `DB:7F:FE:F4:35:E1:…:99:9C:46:85`, which the ledger confirms is
the **genuine current release cert** (not a placeholder). But `docs/decisions/2026-11-01-v1-launch-decisions.md:17`
(D3) requires the **Play app-signing** SHA-256 **alongside** the upload cert, and the ledger still
lists it as open owner-gated work. Once Play App Signing is enrolled, `android:autoVerify="true"`
silently stops verifying and `https://quranyahdi.pages.dev/surah/...` opens in the browser.
*Fix:* after Play enrollment, add the Play app-signing fingerprint alongside the upload cert and
re-run the web gates. **Owner-gated — no repo-side code change.**

### [Low] No `kReleaseMode` gate — 160 `dev.log` sites ship in release, contradicting the privacy policy
`PRIVACY.md:14` · `lib/**` — **OWASP M9 / M6.**

`PRIVACY.md:14` states "السجلات المحلية تُستخدم أثناء التطوير فقط" (*local logs are used during
development only*). There is **not one** `kReleaseMode`/`kDebugMode`/`kProfileMode` guard in `lib/`
(**0 hits**), so nothing enforces it. Measured: **160** `dev.log(` sites — **119** pass the full
exception object (whose message can embed a file path, a SQL fragment or imported user content),
**33** pass only `error.runtimeType`, **8** pass no error. The sink is logcat, so exposure is
owner/ADB/sysdiagnose-level rather than cross-app. The repo already has the right pattern at
`lib/features/backup/presentation/backup_cubit.dart:100-102` ("The error MESSAGE is never logged:
a jsonDecode failure embeds a snippet of the imported file, and the imported file is user content").
*Fix:* route all logging through one helper that is a no-op unless `kDebugMode`, and standardise on
`error.runtimeType`.

---

## 2) Clean architecture — 7.0 / 10

The **enforcement** is the strongest thing in this repo and I verified it independently.

**Measured import graph** (own resolver, mirroring the guard's semantics, over 307 hand-written files):

| Measurement | Count |
|---|---:|
| `lib/core/**` → `lib/features/**` | **0** |
| `lib/features/**` → `lib/app/**` | **0** |
| `lib/features/*/presentation/**` → another feature's `data/` | **0** |
| `lib/features/*/presentation/**` importing `dio`/`drift`/`sqlite3`/`http`/`just_audio`/`geolocator`/`app_links`/… | **0** |
| `lib/features/*/presentation/**` importing `dart:io` | **0** |
| live cross-feature edges | **2** (`quran->library`, `quran->recitation`) — **exactly** the allowlist |
| `getIt.register*` calls outside the composition root | **0** (all 83 in `lib/app/di/injector.dart`) |
| route-scoped cubits wrongly registered as singletons | **0** |
| `lib/core/di/injector.dart` | **pure re-export** (1 export line + 8 comment lines) |

`test/architecture_guard_test.dart` pins `allowedFeatureEdges` **exactly in both directions** — it
fails on any unpinned live edge *and* on any dead permission — so the set cannot silently grow to
match the tree. Both edges are presentation→presentation, neither reaches a foreign `data/`.

### [High] The new `update` feature breaks the documented feature shape; its persistence lives in `lib/app/`
`lib/features/update/presentation/update_gate_screen.dart` (the whole feature = 1 file, 127 lines)
· `lib/app/version_policy_service.dart:35-41,112-125` · `lib/app/version_ack_store.dart:12-33,52-61`
· `lib/app/review_service.dart:69-83,130-144` · `lib/app/version_gate.dart:13-16,29`

AGENTS.md §2 declares the uniform feature shape as `data/` + `presentation/` (cubit + freezed state +
screens) with three documented exceptions. `update/` is the **only** feature with a screen and
**0 cubits, 0 states**. Its behaviour — the policy fetch, the last-known-good cache, the ack
marker, the Play gateway, the whole verdict state machine — is not in the feature at all: three
network/DB adapters sit in `lib/app/`, the layer AGENTS.md reserves for app/boot/router/DI, and
`VersionAckStore`/`StoreListingGateway` are **ports declared in the app layer** while every other
port (22 of them) lives in `lib/core/domain/`. 38 of the 40 feature files that import
`core/db/app_database.dart` are under `data/`; the only two exceptions are the frozen-test shims.
*Fix:* move `VersionPolicyService` + `DriftVersionAckStore` into `lib/features/update/data/`, move
the two ports into `lib/core/domain/version_policy_source.dart`, give the feature a real
freezed cubit/state, and keep `update_gate_screen.dart` exactly as it is — it is already a clean
leaf widget with plain callbacks.

### [Medium] Three blind spots in the architecture guard
`test/architecture_guard_test.dart:239` · `lib/features/quran/presentation/reader/mushaf_page_block_rows.dart:1`
· `lib/features/recitation/presentation/playback/playback_row_entry.dart:1`
· `lib/features/notifications/data/reminder_diagnostics_channel.dart:1`
· `lib/features/quran/data/uthmani_text_source.dart:4` · `lib/features/notifications/data/notifications_binding.dart:3`

1. **No rule against `presentation/` → `core/db/`.** Two files do it, and — verified by
   `rg` over `lib/` and `test/` — **both are called only from `test/`**:
   `groupAyahsByPage` only at `test/mushaf_grouping_test.dart:70`; `playSurah(row, …)` only from
   `test/mini_player_bar_test.dart`, `mini_player_failure_copy_test.dart`, `mini_player_inset_test.dart`,
   `mini_player_stop_test.dart`, `playback_cubit_test.dart`. They exist in production **solely to
   satisfy frozen tests**, and they re-export drift row types into the production API surface
   (`playback_cubit.dart:17`, `mushaf_page_block.dart:3`).
2. **The data-layer Flutter rule is narrower than it claims** — it bans exactly
   `package:flutter/material.dart`, so **3 live violations are invisible**: `flutter/services.dart`
   in `reminder_diagnostics_channel.dart:1` and `uthmani_text_source.dart:4`, `flutter/foundation.dart`
   in `notifications_binding.dart:3`.
3. **No rule about what may live in `lib/app/`** — which is exactly where the new adapters went.

*Fix:* pin the current two `presentation → core/db` files in an allowlist so a third is a failure;
widen `:239` to reject any `package:flutter/` and `dart:ui` in `data/`; add a planted-violation test
beside the existing one at `:219-231`. The frozen tests import `…/presentation/reader/mushaf_page_block.dart`
and `…/presentation/playback/playback_cubit.dart`, so moving the *implementation* file down into
`data/` while keeping the re-export at the same path satisfies them without touching a frozen test.

### [Medium] Service-locator resolution inside presentation widgets (2 sites; 1 new since the prior audit)
`lib/features/settings/presentation/settings_screen.dart:266-274` · `lib/features/library/presentation/ayah_sheet/library_sheet.dart:53`

`settings_screen.dart` calls `GetIt.I.isRegistered<ReminderDiagnostics>()` / `GetIt.I<ReminderDiagnostics>()`
and the same for `ReminderApplyHealth` **inside a `build()`**. The prior audit flagged only
`library_sheet.dart:53` (`GetIt.instance<PackDownloader>()`), which is **still open**; the settings
screen added a second instance.
*Fix:* the seam already exists — `SettingsScreen` accepts optional `reminderDiagnostics` / `reminderApplyHealth`
params; the router builds it at `lib/app/router.dart:519-523` **without** passing them. Resolve in
the router and delete the fallback; the frozen test that builds `const SettingsScreen()` still compiles.

### [Medium] The composition root registers two objects it does not own and cannot reset
`lib/app/di/injector.dart:391,405-407,433-435` · `lib/app/router.dart:135,139`

`registerLazySingleton<VersionGate>(() => AppRouter.versionGate)` and the same for `OnboardingGate`
make the DI registration a **facade** over the router's statics. `resetDependenciesForTest()`
cannot reset them, so tests reach past the container (`test/version_router_test.dart:45,60`,
`test/onboarding_gate_test.dart:128,139`) — a `getIt.reset()` leaves the previous test's
`_source`/`_installed`/`_verdict` on the gate.
*Fix:* create the gates in the injector, have `AppRouter` read them from the container, and extend
`resetDependenciesForTest()` to call `reset()` on both.

### [Medium] AGENTS.md §2 mis-describes the layering it mandates
`AGENTS.md:42`

The line says "**18 features**" and lists 18 (no `update`), and names only `quran`/`ramadan`/`recitation`
as `domain/` exceptions. Measured: **19** features exist and **11** have a `domain/` layer
(`asma, azkar, backup, duas, library, prayer, quran, ramadan, recitation, tracker, zakat`) —
the 2026-11-09 `c2aa253` hoist landed *after* the doc-truth commit `4ac4dc6` that rewrote this line.
A reader who believes "`domain/` is a rare exception" will put presentation-facing DTOs back into
`data/` and undo `c2aa253`.
*Fix:* amend `AGENTS.md:42` — 19 features, `domain/` in 11, `notifications/` data-only,
`home/` no `data/`, `update/` presentation-only pending a cubit.

---

## 3) Code quality — 7.4 / 10

Base hygiene is **exemplary** and I re-measured every headline number: **0** `print`/`debugPrint`
in `lib/`, **0** empty catch blocks, **0** `catch (_)`, **220** catches of which 156 are typed,
**0** raw exception strings reaching the UI, **0** `Future.delayed` inside a `build()`, **0** dead
private members, **24** `late` fields all assigned on every path, **19** `setState` sites with
post-await ones mounted-guarded. `analysis_options.yaml` (78 lines, read in full) is strict on
types, async and hygiene, and excludes `**/*.g.dart` + `**/*.freezed.dart` (the prior audit's ask —
**closed**).

### [High] Four defects introduced by the uncommitted wave
- `lib/app/di/injector.dart:165-166` — `_configured = true;` **twice**, back to back (diff-visible).
- `lib/main.dart:246` + `:279-282` — the wave inserted `_attachVersionGate()` **between the two halves
  of `_listenForDeepLinks`'s doc comment**; `:246` now reads "Warm deep links: …" directly above the
  new function, and `:279` begins mid-sentence with "/// the pure [deepLinkRouteFor] and navigates."
- `lib/app/review_service.dart:55-63` — `ReviewEligibility` is documented as "Pure policy for the
  review prompt… tests pin it fully", but production never reads it: `maybeRequestAfterOnboarding()`
  (`:92-112`) re-implements the predicate inline. A test-only policy class that the shipped code
  diverges from.
- `lib/core/domain/version_policy.dart:101-105` + `lib/app/version_gate.dart:42,45` + `:161-167` —
  **four dead public API members**: `messageAr`, `messageEn`, `storeUrl`, `evaluateVersion()`,
  `gate.installed`, `gate.isLoading` — all have **0 production consumers** (verified by `rg` over
  `lib/`), yet the model validates and length-caps them and `test/version_policy_test.dart` pins them.

### [Medium] Persistence moved into the composition root, and the cubit re-couples to the data layer
`lib/app/review_service.dart`, `lib/app/version_ack_store.dart`, `lib/app/version_policy_service.dart`
are the only files in `lib/app/` that touch drift. `lib/features/backup/presentation/backup_cubit.dart:6,125,127`
calls `encryptBackupJson` / `exceedsBackupLimit` directly, re-coupling presentation to the data
layer that the 2026-11-05 technical-debt close-out had deliberately separated ("the cubit keeps
state + validation only"). The wave also adds **three more copies** of the settings-store skeleton
(8 copies repo-wide) even though `lib/features/settings/data/app_theme_repository.dart:6-7` documents
the exact rule for when a generic is warranted ("a generic is only worth it when a third preference
appears").

### [Medium] Five new silent swallow points
`lib/app/version_policy_service.dart:79` · `lib/app/onboarding_gate.dart:76` (in the *same method*
whose other catch logs at `:67-70`) · `lib/app/version_gate.dart:85` · `lib/app/version_ack_store.dart:58`
· `lib/app/review_service.dart:33` — none logs, rethrows, or converts to a typed failure. Every
pre-existing catch in `lib/` does one of those three.

### [Medium] Near-duplicate test files and an unused shared harness
**17 pairs ≥ 0.60** normalized Jaccard across 413 test files (e.g. `reader_bookmark_toast_test.dart`
vs `reader_page_jump_invalid_test.dart` **0.828**; `asma_screen_test.dart` vs `azkar_system_back_test.dart`
**0.795**; `zakat_nisab_prompt_test.dart` vs `zakat_screen_test.dart` **0.795**). The MaterialApp
harness is copy-pasted (**79** files inline their own `MaterialApp(`; only **61** import
`test/support/host.dart`). The 2026-11-05 cleanup of the 12 `_FakePlaybackService` copies **did not
hold**: the class name now exists **5 times** — 3 independent `implements PlaybackService` bodies
(`test/support/fake_playback_service.dart:7`, `test/playback_cubit_test.dart:15`,
`test/mini_player_bar_test.dart:18`) and 2 that extend the shared base. `FakePrayerTimeService` is
defined in 2 files with different bodies and reached by **30** suites through relative
`import '…_test.dart'` — so a fixture change ripples across 30 suites with no compile error.
Relative cross-test imports grew from the prior audit's **34 → 48**.
*Fix:* `test/support/app_harness.dart` with `pumpLocalizedApp(tester, child)`; move the doubles into
`test/support/` (one canonical base + thin subclasses); convert the 48 relative imports.

### [Low] Findings worth recording but not acting on first
- `lib/core/widgets/empty_state.dart:21-49` vs `lib/core/widgets/loading_and_error_views.dart:35-65`
  — the same widget twice (0.471 similarity); only the optional icon vs optional action differ.
- Import order regressed in the wave's files (`lib/main.dart:8,17-18`; `lib/app/di/injector.dart:14`;
  `lib/app/router.dart:122-123`) and **`directives_ordering` is not enabled** in `analysis_options.yaml`,
  so the repo's own import-order pass (`8e3dc6d`) is unenforced.
- `lib/app/router.dart:258-667` — `_postShellRoutes()` is a **410-line** method holding all 28
  post-shell routes; `32fbede` already extracted "router route builders" but produced two methods,
  not per-feature ones.
- `lib/features/quran/presentation/reader/reader_screen.dart` — 807 lines, 15 top-level units,
  genuinely cohesive (12 widget classes) but the workspace pane's shared contract lives inside it.
- `lib/features/recitation/presentation/playback/player_sheet.dart:153` — a **189-line `build()`**,
  the largest in `lib/` (next: `backup_section.dart` at 134). The prior audit filed the 99-/102-line
  versions as Med "Extract named sub-widgets" and it is **not** marked closed; both grew since.
- `lib/features/recitation/presentation/playback/playback_cubit.dart` — **7** sites
  (147, 340, 440, 460, 554, 565, 576) hand-rebuild `PlaybackState.playing/paused(...)` spelling out
  all 8 fields. The prior audit's Low is still open: `PlaybackState` is a sealed union, so freezed
  generates `copyWith` **per variant**, never union-level.
- `lib/features/backup/data/backup_crypto.dart:35` — `kEncryptedBackupApp = 'quran_yahdi'` re-declares
  the literal `lib/features/backup/data/backup_codec.dart:10` already names as `kBackupAppId`, in the
  same feature; its doc says "mirrors `kBackupAppId`" but it does not import it.
- `lib/core/domain/version_policy.dart:5-6` — points at `docs/release-readiness-audit.md`, which is
  **untracked** (`git ls-files` → 0), so the reference dangles for anyone who clones.
- `lib/features/quran/presentation/workspace/quran_workspace_screen.dart:80` —
  `width >= 1024 ? 340.0 : 300.0` invents a threshold and two widths, while
  `lib/core/layout/app_breakpoints.dart` already names `medium = 600`, `expanded = 840`.

---

## 4) Maintainability — 7.0 / 10

Documentation is the strongest dimension and I verified the headline number independently:
**143 / 148 = 96.6%** of public types in `lib/core/domain/` + feature `data|domain` carry a doc
comment (prior audit: 46%). Where docs exist they explain **why**, not what —
`lib/core/domain/ayah_lookup.dart:4-12`, `lib/features/notifications/data/notifications_binding.dart:14-45`,
`lib/features/quran/domain/verse.dart:1-17`.

Real gaps: **3 genuinely public undocumented types** — `lib/features/library/data/pack_downloader_types.dart:3`
(`PackFailure`), `lib/features/quran/data/verse_mapping.dart:34` (`SurahRowMapping`),
`lib/features/quran/domain/verse.dart:33` (`Verse`, the app's central entity — its file's header
doc is attached to a free function instead). Public **method** coverage in the three named layers
is **74%**, worst in `lib/features/backup/data/backup_merger.dart` (15 undocumented public members),
`lib/features/notifications/data/reminder_settings.dart` (11), `notifications_binding.dart` (7).

Naming and conventions are consistent: 422/422 ARB keys camelCase, l10n parity exact, feature
layout uniform (with the exceptions noted above), **0** TODO/FIXME/HACK in `lib/` (the apparent "6"
is `toDouble`/`roundToDouble` matching case-insensitively — the same false positive the prior
audit corrected), **0** `// ignore:`, **0** commented-out code.

Where it hurts: 13 files > 400 LOC (prior audit: 2). File length is not the same as a god class —
`reader_screen.dart` (807) holds **12 distinct widget classes** and is cohesive — so the issue is
file organisation, not design. `lib/app/router.dart` (681) + `lib/app/di/injector.dart` (435) +
`lib/main.dart` (288) = 1,404 lines that a newcomer must hold in their head, with the route table
and its DI registration living in **two different files** kept in sync by hand.

Also: the l10n **prefix taxonomy** is inconsistent (`settingsPrayerReminder` / `azkarReminder` /
`settingsWirdReminder` are three sibling rows of the same list; `settingsTheme` vs `themeSystem` /
`themeLight` / `themeDark`), and the quran feature splits vocabulary — 331 "ayah" vs 74 "verse" for
the same object, whose entity class is `Verse`.

---

## 5) Performance — 7.5 / 10

**Verified strengths.** The 4.1 MB DB asset is loaded on a **worker isolate**
(`lib/core/db/connection.dart:92-102`) and copied **only when absent** (`:25`) — the prior audit's
#1 finding is **CLOSED**. The Quran search is **FTS5 trigram** with a quoted, parameter-bound
`MATCH` (`quran_search_repository.dart:51-52,64-67`) and a **memoized** `COUNT(*)` (`:93`) — the
prior audit's LIKE-scan Low is **CLOSED**. Reader mushaf pages are **derived at the view boundary**
(`reader_state.dart:49` is a getter, not a stored field). Per-row `BlocSelector` in azkar (`:332`),
`buildWhen` ignoring position while dragging (`player_sheet.dart:28-32`), cached azkar
normalization, batched reciter lookups, bounded pack concurrency with `Future.wait`, a 2 MiB backup
cap, lazy lists throughout (the app's **only** `shrinkWrap` is a 42-cell hijri grid), **0**
`AnimationController`/`ScrollController`, and **all 4** `Timer`s cancelled on close
(`translation_search_cubit.dart:82,152` · `quran_search_cubit.dart:29,127` · `home_cubit.dart:72,146,161`
· `playback_cubit.dart:245,478,534`) — no timer leaks.

### [High] The FTS5 trigram tokenizer silently drops every token shorter than 3 characters
`lib/features/quran/domain/quran_search_source.dart:35,44-55` ·
`lib/features/quran/data/quran_search_repository.dart:26-29,47-52,63-68` ·
`lib/core/db/search_index.dart:17-18` · `lib/features/quran/presentation/search/quran_search_screen.dart:76-80`

**This is a live, user-facing correctness regression introduced by the FTS5 migration (`a13033c`) —
a performance change that traded correctness for speed.** The gate admits a 2-character query
(`kQuranSearchMinChars = 2`) and checks the **joined** length, not each token
(`quranSearchQueryUsable` → `tokens.join().length >= 2`), but the FTS5 **trigram tokenizer cannot
represent a token shorter than 3 characters** — such a token matches nothing and is *erased* from
the query.

**Reproduced by the integrator independently against the shipped asset** (`assets/db/quran.sqlite`,
5,484,544 B, 6,236 ayahs), comparing the app's `MATCH` path against a folded-substring ground truth:

| tokens | app path (`MATCH`) | true AND | verdict |
|---|---:|---:|---|
| `لا` | **0** | **3,093** | silent false negative |
| `ال` | **0** | **5,155** | silent false negative |
| `يا` | **0** | **1,352** | silent false negative |
| `لا` + `يا` | **0** | **817** | silent false negative |
| `يا` + `الصلاه` | **61** | **17** | **false positive — the 2-char token is dropped, so AND degrades to the long token alone** |
| `الصلاه` · `الرحمن` · `الرحيم` · `محمد` | 61 · 48 · 34 · 4 | identical | ok (≥ 3 chars work) |

The mixed case is the nastier one: `quran_search_repository.dart:47-52` promises *"every token
must appear (AND)"*, but a short token is not merely unmatched — it is **erased**, so the result
set is a **superset** (61 vs 17) that looks perfectly plausible. The user's only signal in the
false-negative case is the screen's "no results" empty state. The comment at
`quran_search_repository.dart:26-29` — that `MATCH` *"preserves the legacy substring/contains
semantics (LIKE '%token%')"* — is **false as written**.

*Fix:* make the gate match the tokenizer — reject any token `< 3` normalized chars
(per token, not on the joined string), or keep a `LIKE '%token%'` fallback for short tokens. Either
way the comment at `:26-29` must change. Add a regression test that asserts a 2-char Arabic query
returns the same count as the legacy substring semantics.

### [Medium] Every reminder re-plan cancels 88 alarm ids and re-schedules ~74 — one await each, serialized
`lib/features/notifications/data/notifications_binding.dart:519-521,526-541` ·
`lib/features/notifications/data/reminder_planner.dart:27,85-97` ·
`lib/app/reminder_background_task.dart:34,134`

Each apply is **O(universe)** sequential platform-channel round-trips on the main isolate —
**88 `cancel` + ~74 `zonedSchedule` ≈ 162 awaited calls**, strictly one at a time (no batching, no
`Future.wait`). The fingerprint dedupe means it fires only when the plan actually changed (day
rollover, city/config change, exact-alarm grant change), so it is bounded and infrequent — but each
firing is a long serialized tail on the platform channel, and it runs from the background worker's
isolate too. (The 88-id universe itself is a **ratified** design decision — the finding is the
serialization, not the id scheme.)
*Fix:* the binding already tracks the previous ids (`_appliedPlanIds`, `:522-525`) — clear only
`previous − new` when that set is populated, reserving the full clear for the first apply after
process start; schedule the new set with chunked bounded concurrency instead of 74 sequential awaits.

### [Medium] The encrypted-backup path inverts the file's own isolate-hop rationale
`lib/features/backup/data/backup_io.dart:110,113,115,124,137` ·
`lib/features/backup/presentation/backup_cubit.dart:125` · `lib/features/backup/data/backup_crypto.dart:20-22`

The plaintext path is deliberately isolate-hopped — the doc at `:100-101` says the isolate exists
because "decoding it on the UI isolate blocks the frame for the whole JSON parse". But the
**encrypted** path (added later) does the opposite:
- `:110` `utf8.decode(bytes, allowMalformed: true)` decodes the whole 2 MiB document **on the calling
  (UI) isolate**, then `:124` hands the *bytes* to the isolate, which **decodes the same bytes again**
  at `:137` — a literal double decode.
- `:113` `decryptBackupJson` runs the pure-Dart PBKDF2 (100k rounds) + AES-GCM **on the UI isolate** —
  the module header admits it ("The work runs on the calling isolate… If profiling ever flags it,
  move the call sites behind `Isolate.run` like [exportJson] does"), and `exportJson` at
  `backup_service.dart:67` *already does* exactly that.
- `:115` `decode(unlocked)` parses the decrypted JSON **inline**, so the encrypted import is slower
  on the UI isolate than the plaintext one — the opposite of the file's intent.
`cryptography` 2.9.0's `DartPbkdf2` yields to the event loop every 2,000 iterations
(`pub cache lib/src/dart/pbkdf2.dart:38-40,95-100`), so this is jank and a long freeze rather than
a hard ANR — but the plain 100k-round PBKDF2 is still seconds of UI-isolate CPU.
*Fix:* sniff the envelope from a short prefix, keep the full decode in the worker, and run the KDF
in `Isolate.run` (both `encryptBackupJson` and `decryptBackupJson`).

### [Medium] `stripAyahEndMarker` still runs per build — a prior-audit Medium that was never closed
`lib/features/quran/presentation/reader/verse_card.dart:41` (inside `build()`) ·
`lib/features/quran/presentation/reader/reader_screen.dart:381` and `:611` ·
`lib/features/quran/domain/verse.dart:18-28`

The prior audit (2026-10-30) filed this as Medium — "Precompute once in `Verse`" — and it is
**still open**, and it has **grown from 2 call sites to 3**. Each call does
`text.trimRight().runes.toList()` (a `List<int>` of every rune) + `String.fromCharCodes(runes)`
(a second full copy): **two allocations and two copies of the full ayah text per visible ayah per
rebuild**. During a reader scroll that is ~10 visible cards re-allocating on every frame.
The `Verse` entity was created by the 2026-11-09 `c2aa253` hoist — this was the moment to move the
strip into it, and the refactor missed it.
*Fix:* compute the stripped text once in `AyahRowMapping.toVerse()` (`lib/features/quran/data/verse_mapping.dart:14-23`)
or as a `late final` on `Verse`.

### [Low] Other measured items
- **N+1 in the folder-bookmarks load** — `lib/features/quran/presentation/bookmarks/folder_bookmarks_cubit.dart:35-36`
  + `lib/features/quran/data/ayah_repository.dart:31-33`: one serial `await _ayahs.ayahById(id)` per
  bookmark, and `ayahById` is a real drift query. N is user-data-bounded, so this is a low-impact
  N+1 rather than a scaling cliff. The fix is a **port widening** (`AyahLookup.ayahsByIds(List<int>)`),
  which is an owner-grade change because frozen doubles implement the interface.
- **No index on `ayahs(juz)`** — `lib/features/quran/data/juz_repository.dart:17-27`; the shipped asset
  has only `idx_ayahs_surah` and `idx_ayahs_page`. Measured on the asset: `SCAN ayahs` at
  **1.61 ms/iter** → with `CREATE INDEX idx_ayahs_juz ON ayahs(juz, id)` it becomes
  `SEARCH ayahs USING INDEX idx_ayahs_juz` at **0.08 ms/iter** (≈20×). One line in
  `_ensureDerivedSchema`, same idempotent pattern as the existing indexes.
- **The FTS5 table is contentful** — `lib/core/db/search_index.dart:17-18` confirms
  `CREATE VIRTUAL TABLE ayah_search USING fts5(text_norm, tokenize='trigram')` (no `content=''`),
  so the corpus is shadow-copied inside the 5.48 MB asset (measured contentful 2,121,728 B vs
  contentless 1,306,624 B → ~815 KB, ~15% of the shipped asset). Switching to `content=''` requires
  changing the rebuild at `search_index.dart:98` to `INSERT INTO ayah_search(ayah_search) VALUES('delete-all')`
  — the two edits go together (SQLite rejects `DELETE FROM` on a contentless table and `delete-all`
  on a contentful one).
- **Per-keystroke Arabic re-normalization** — `lib/features/quran/presentation/index/surah_index_cubit.dart:60-68`
  + `lib/features/quran/presentation/index/surah_index_body.dart:54` (no debounce) and
  `lib/features/prayer/data/city_repository.dart:37-48`: the repo ships `prepareQuery` ("Search loops
  call this ONCE and reuse it for every item") but the loop uses `matchesQuery`, re-normalizing the
  same query once per item — 114 surahs × 2 = 228 query normalizations per keystroke.
- **The search-index build blocks the first DB *query*, not the first frame** —
  `lib/core/db/connection.dart:217-231`: `openAppDatabase()` awaits `_ensureSearchIndex(db)` at `:230`
  before handing the executor to drift's `LazyDatabase`. The first frame is unaffected (the DB is
  lazy; `runApp` is at `lib/main.dart:74`), but the first screen that queries the DB waits for a
  6,236-row rebuild on a stale-content install.
- **The DB asset size comment is 31% stale** — `lib/core/db/connection.dart:94,215` say "~4.0 MiB
  (4,173,824 B)"; the shipped asset is now **5,484,544 B** (it grew at `a13033c`).
- **`hadith_store._backfillNorm` rewrites every row of a pack**, not just the pending ones
  (`lib/features/library/data/hadith_store.dart:137-163` — the UPDATE has no `norm = ''` predicate);
  the import path already writes `norm` (`:263`), so it is a one-time legacy path.

---

## Top 5 critical issues, ranked

| # | Severity | Dimension | Issue | Where |
|---|---|---|---|---|
| 1 | **High** | Correctness ← perf | **The FTS5 trigram tokenizer silently drops every token shorter than 3 characters** — the gate admits 2 (`kQuranSearchMinChars = 2`, checked on the *joined* length) but trigram cannot represent < 3. Reproduced by the integrator against the shipped asset: `لا` → **0** rows vs **3,093** true, `ال` → **0** vs **5,155**, `يا` → **0** vs **1,352**; and in a mixed query the short token is **erased** so AND degrades to a superset (`يا`+`الصلاه` → **61** vs **17** true). The most common Arabic particles silently return "no results". Introduced by the FTS5 migration `a13033c` — a perf change that traded correctness for speed. | `quran_search_source.dart:35,44-55` · `quran_search_repository.dart:26-29,47-52` · `search_index.dart:17-18` · `quran_search_screen.dart:76-80` |
| 2 | **High** | Security / availability | **Unsigned remote policy can permanently wall every installed app, and the poisoned policy is cached so the owner's fix never reaches offline devices.** No ceiling on `min_supported`, no `expires_at`, no in-app bypass, no client-side kill-switch. Dormant today only because `version.json` does not exist yet. | `version_policy_service.dart:17-18,62-91` · `version_policy.dart:116-129` · `version_gate.dart:119-123` · `update_gate_screen.dart:56-57` |
| 3 | **High** | Security / crypto | **The backup KDF is 6× below the repo's own ratified floor (PBKDF2-100k vs Argon2id / PBKDF2-600k) and the envelope header is unauthenticated (no AAD).** Argon2id and `aad` were both available and unused; `SecretKey.destroy()` exists and is never called. | `backup_crypto.dart:39,44-47,75-79,144-156` vs `docs/superpowers/specs/2026-10-24-backup-encryption-decision.md:52-55,70` |
| 4 | **High** | Security → performance | **Attacker-chosen `kdf.iterations` (1 … 10,000,000) from an untrusted file runs on the UI isolate** → minutes-long freeze/ANR on import, and `iterations: 1` silently downgrades any file it lands on. | `backup_crypto.dart:118-126,144-151` · `backup_io.dart:113` |
| 5 | **Medium** | Architecture | **The architecture guard has three blind spots and the constitution is stale.** No `presentation → core/db` rule (2 live files that exist *only* for frozen tests), the data-layer Flutter rule bans only `material.dart` (3 live violations), no rule for `lib/app/` (where the new adapters went) — and `AGENTS.md:42` says 18 features / 3 `domain/` layers when the truth is 19 / 11, while the new `update` feature has no `data/`, no `domain/`, no cubit and puts persistence in `lib/app/`. | `architecture_guard_test.dart:239` · `mushaf_page_block_rows.dart:1` · `playback_row_entry.dart:1` · `reminder_diagnostics_channel.dart:1` · `uthmani_text_source.dart:4` · `notifications_binding.dart:3` · `AGENTS.md:42` |

**Runner-up 1 — performance.** **`stripAyahEndMarker` still allocates and copies the whole ayah text
per visible card per rebuild** (3 call sites; the 2026-10-30 Medium was never closed and the
2026-11-09 `Verse` hoist missed it) — and the encrypted-backup path runs the pure-Dart PBKDF2
**and** a double 2 MiB decode on the UI isolate, inverting the plaintext path's own isolate-hop
rationale. → `verse_card.dart:41` · `reader_screen.dart:381,611` · `verse.dart:18-28` ·
`backup_io.dart:110,113,115,124,137` · `backup_cubit.dart:125`

**Runner-up 2 — performance.** **Every reminder re-plan makes ~162 serialized platform-channel calls**
(88 `cancel` + ~74 `zonedSchedule`), one await each, on the main isolate.
→ `notifications_binding.dart:519-541` · `reminder_planner.dart:85-97`

**Runner-up 3 — governance (integrator-discovered).** The campaign ledger has been **silent since
2026-11-07** (last modified at `474d75d`, 2026-11-08) while **12 commits landed on 2026-11-09**
— including the new backup crypto, the FTS5 search migration, the layer-reshaping `c2aa253` refactor
and the "remove raw theme colors" pass — plus the entire uncommitted `update`/version-gate/review
wave. Verified with a control (`version` → 30 hits, `backup` → 46 hits in the same file). AGENTS.md §4
calls the ledger "the append-only campaign record" and every wave closes out in it; the repo's
memory of *why* has a three-day hole covering exactly the riskiest changes. The crypto wave in
particular landed with **no ledger entry and no amendment to its ratified decision doc** — and the
FTS5 migration landed with no entry either, which is why its token-length regression went unnoticed.

---

## Methods, corrections and limitations

**Method.** Start gate (HEAD / branch / porcelain / worktrees) → governance read (AGENTS.md, the
campaign ledger tail, the frozen-test policy, the 2026-10-30 prior audit, the backup-encryption
decision) → STEP-0 measurements run by the integrator (analyze, format, tests, l10n parity) →
five parallel read-only dimension lanes → integrator re-verification of every load-bearing
citation at source → weighted score with shown arithmetic. The performance lane arrived late; its
findings were re-verified independently, and the three findings it did not examine were added
first-party.

**Authored-by split.** Security, maintainability, clean architecture and code quality are
**subagent-authored**; every cited claim in those four lanes was re-opened at source by the
integrator and confirmed (spot-check ledger below). Performance is **subagent-authored and
integrator-augmented**, with the score adjusted 8.0 → 7.5 as disclosed above. The governance
runner-up and the FTS5 reproduction are **integrator-discovered**.

**Files opened directly by the integrator** (~75): `AGENTS.md`, `analysis_options.yaml`,
`docs/campaign-ledger.md`, `docs/superpowers/audits/2026-10-30-code-quality-audit.md`,
`docs/superpowers/plans/2026-10-28-post-audit-remediation-ledger.md`,
`docs/superpowers/specs/2026-10-24-backup-encryption-decision.md`,
`docs/release-readiness-audit.md`, `test/architecture_guard_test.dart`, `lib/core/di/injector.dart`,
`lib/app/{router,version_gate,version_policy_service,version_ack_store,review_service,onboarding_gate,main}.dart`,
`lib/core/domain/{version_policy,version_policy_source,ayah_lookup}.dart`,
`lib/core/db/{connection,app_database}.dart`, `lib/core/layout/app_breakpoints.dart`,
`lib/core/utils/deep_links.dart`,
`lib/features/update/presentation/update_gate_screen.dart`,
`lib/features/backup/{data/{backup_crypto,backup_io,backup_codec},presentation/backup_cubit}.dart`,
`lib/features/quran/{domain/{verse,quran_search_source},data/{verse_mapping,ayah_repository,quran_search_repository},presentation/{reader/{verse_card,mushaf_page_block_rows,reader_cubit,reader_state},bookmarks/{bookmarks_cubit,folder_bookmarks_cubit},search/quran_search_screen}}.dart`,
`lib/features/recitation/presentation/playback/{playback_row_entry,playback_cubit}.dart`,
`lib/features/settings/presentation/settings_screen.dart`,
`lib/features/library/presentation/ayah_sheet/library_sheet.dart`,
`android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/xml/data_extraction_rules.xml`,
`web/public/_headers`, `web/public/.well-known/assetlinks.json`,
`pubspec.yaml`/`pubspec.lock`, `assets/db/quran.sqlite` (read-only copy), and the `cryptography`
2.9.0 sources in the pub cache.

**Corrections made to lane claims.** (1) A lane reported 24 lib-level near-duplicate pairs at
token-overlap ≥ 0.30; my line-level normalized diff showed the top pairs collapse to ≤ 0.47 and
most to < 0.10 — the token metric was inflated by Dart boilerplate, so "no code clones in `lib/`"
is the accurate statement and the real duplication is confined to test doubles. (2) The lane
reported `prayer_config_screen.dart` as a 140-line `build()`; my brace-matched measurement gives
19 — that sub-claim is dropped as unreproduced. (3) `assetlinks.json` was initially framed as
carrying a placeholder; it in fact carries the **genuine current release cert** — the finding is
the missing Play App Signing fingerprint, not a placeholder. (4) My own first pass reported the
four `Timer`s as uncancelled; a regex artifact (it missed `?.cancel()`) — reading the code showed
all four **are** cancelled, and no timer leak exists. (5) A lane's `player_sheet.dart` `build()`
length of 189 and `router.dart` `_postShellRoutes()` of 410 were independently reproduced exactly.
(6) The ARB key count differs by method (integrator 422 message keys; lane 481/478 including
`@`-metadata) — reconciled: **422 = 422, diff 0**; the 3-key delta is `@`-metadata that legitimately
exists only in the AR template. (7) The performance lane scored **8.0** while explicitly not
examining the backup export/import path or the reader's per-build allocation; the integrator
verified three further Medium findings in exactly those two areas, so the dimension score was
**adjusted down to 7.5** and the adjustment is disclosed above. (8) The lane's FTS5 short-token
finding — the audit's highest-impact defect — was **independently reproduced by the integrator**
against the shipped asset with an independent ground truth (folded substring over all 6,236 ayahs);
the counts agree (`لا` 0 vs 3,093 · `ال` 0 vs 5,155 · `يا` 0 vs 1,352 · mixed 61 vs 17), and the
integrator additionally measured the juz-index win (1.61 ms → 0.08 ms) and confirmed the FTS5
table is contentful.

**Not checked / limitations.** No runtime profiling, no flame graphs, no frame timings, no memory
measurement, no device or emulator test, no APK/AAB or merged-manifest inspection, no live
network probe (the live content of `version.json`, `mp3quran.net` and `cdn.jsdelivr.net` was
**not** fetched), no CVE/advisory database, no iOS build or entitlements review (no
`Runner.entitlements` file exists in the tree at all), no `web/src` line-by-line review of the
reader/player TypeScript, and no audit of `assets/` provenance. The working tree was **dirty** —
the audit reflects the current working-tree state, including the uncommitted WIP, not HEAD alone.
Every latency figure in this report is a **structural / query-plan count**, explicitly **not
runtime-measured** — no cold-start, PSS, frame-time, jank, GC or memory-growth claim is made. The
SQLite probes ran against a `mode=ro` copy in a temp directory; the shipped asset was not modified.

**No file inside the repository was created, edited or deleted.**
