# Release-Readiness Audit — Quran Yahdi (`quran_yahdi`)

**Date:** 2026-11-09 · **Auditor:** agent (release engineering) · **Working-tree HEAD:** `6e0ff45` (`wave/audit-remediation`, 7 ahead of `main` @ `d78582e`) — **the tree also contains uncommitted work**: the owner's debris (`INSTRUCTIONS.md`, `.vscode/settings.json`, `assets/icons/logo_*.png`, `.opencode/`, `web/design-concepts/`), the 2026-11-09 performance-audit fixes (4 files) and docs, **and everything created in this session** (Force Update, In-App Review, docs). Nothing was committed, pushed or released.

**Environment:** Windows 11 · Flutter 3.47.5 / Dart 3.13.4 / DevTools 2.60.0 · `.fvmrc` = 3.47.5 · CI pins the same in `.github/workflows/ci.yml`. **Device:** Infinix X6882 (`13372704AR007777`, Android 14, arm64-v8a, 1080×2460 @ 90 Hz) — connected throughout; the owner's data-bearing install was updated in place twice (`-r`, data preserved both times): first by the perf audit's rebuilt release, then by **this session's rebuilt release** (verified boot, deep-link reader route, home render — see §6).

> **Corrections (2026-11-12, doc truth pass).** Two statements in the original pass were wrong and are corrected inline below:
> (1) the app's `versionCode` is **4** (`pubspec.yaml:5` → `1.0.0+4`). The `2004` reported by `aapt` on a split APK is Flutter's arm64 ABI offset over the base code (`4 + 2000`), not a drift in the store code — `docs/store/play-console-setup.md:23` already recorded it correctly. Risk R3 below is closed as a category error.
> (2) The store lane is `tools\build_release.ps1 -Target appbundle` (since 2026-11-12 the wrapper also arms `PUBLISH_RELEASE`). A bare `PUBLISH_RELEASE=true flutter build appbundle --release` yields an artifact with the update gate **off** (no version-policy key) and is not a store lane.

---

## 1. Executive Summary

Quran Yahdi is a hardened, offline-first, store-ready application. This session closed the remaining operational-readiness gaps **without adding telemetry**:

- **Force Update** is implemented, unit/widget tested, and fail-open by construction — the app cannot be locked out by a malformed, missing, slow or 404 policy file. It cannot enforce anything until the owner publishes `https://quranyahdi.pages.dev/version.json` (their Cloudflare Pages site); the mechanism is complete client-side and the publish step is a documented owner action.
- **In-App Review** is implemented behind the official Play API with a one-shot-per-install, post-onboarding eligibility policy; the dialog itself was **never observed** (Play quotas + sideloaded install) and is not claimed as verified.
- **Crash reporting** was deliberately **not** added: no Firebase/Sentry exists in the project, the privacy policy explicitly discloses its absence, and adding either is an owner decision (presented as a decision checklist, not a code landmine).
- **Release artifacts** build and verify clean: APK (3 ABIs, owner cert, `applicationId com.mostafasayed.quranyahdi`, versionName `1.0.0`, base versionCode `4`; a split APK adds its ABI offset, arm64 = `2004`) and AAB (89.2 MB, owner cert, versionCode `4`). See §6 for hashes and certificate fingerprints.
- **Privacy docs and Data Safety answers were updated in place** to disclose the two new (anonymous) data flows: the launch-time version-policy fetch and the In-App Review surface. No user data leaves the device.
- **`versionCode=2004` on the arm64 split APK is not a drift** — it is Flutter's per-ABI offset over base code `4`, the same `4` the owner's install reports. Corrected 2026-11-12: the only open question is whether code `4` is already on a Play track (see §12).

**Ready for a staged production rollout?** The app code is. Blocking items are external/owner items: publish `version.json`, confirm the versionCode to use, run the on-device smoke of this build, and — only if desired later — approve a crash-reporting SDK.

## 2. Current repository and release configuration

| Area | Current state (verified this session) |
|---|---|
| Repository state | Branch `wave/audit-remediation` @ `6e0ff45`, 7 ahead of `main`; uncommitted work present (see header); no commit made by this session |
| App version | `pubspec.yaml` → `version: 1.0.0+4` → versionName `1.0.0`, base versionCode `4`. A split APK reports base + its ABI offset (arm64-v8a → `2004`); the AAB carries `4` |
| applicationId | `com.mostafasayed.quranyahdi`; debug builds carry `applicationIdSuffix = ".debug"` and `versionNameSuffix = "-debug"` (they can co-install beside release) |
| SDKs | `compileSdk = 36` (pinned) · `minSdk = 24` · `targetSdk = 36` — pinning is deliberate, not inherited |
| Signing | `android/key.properties` present (owner machine, gitignored) → release builds are owner-cert signed; without it, release fails soft (loud notice) except under `PUBLISH_RELEASE=true`, which fails the build outright. CI has no keystore → CI artifacts are `debug-signed-*` by construction |
| Keystore cert | `CN=Mostafa Sayed, OU=Quran Yahdi, O=Quran Yahdi` · SHA-256 `db7ffef4…c4685` — matches the owner's installed build (both current and the 2026-11-01 store build) |
| `.fvmrc` | `3.47.5` — CI and AGENTS.md agree; the format gate is formatter-version-sensitive |
| CI | `.github/workflows/ci.yml`: pinned Flutter, `flutter gen-l10n` drift gate, `build_runner` drift gate, `flutter analyze`, `dart format --set-exit-if-changed lib test tools`, `flutter test`, then a `release-artifact` job (push-to-main only) building split APKs + AAB, uploaded as `debug-signed-*` with 14-day retention. **No Play upload, by design.** `db-drift.yml` guards the generated drift code; `web.yml` is the separate website campaign |
| Firebase / Sentry | **None.** No `google-services.json`, no Firebase plugins, no Sentry |
| Analytics | **None.** No analytics/telemetry SDK of any kind; no events |
| Environment config | No backend; constants only (`mp3quran.net`, `cdn.jsdelivr.net`). The single remotely-observable policy file lives on the owner's Cloudflare Pages site. See §7 for the flavor decision |
| Error handling | `dart:developer log` with `quran_yahdi/*` tags; `test/log_hygiene_test.dart` (no `print`/`debugPrint` in `lib/`, no secret terms in `dev.log`); every failure family surfaces a **localized** pane (Loading/Ready/Failed or variants) — checked in the 2026-10-27 audit |
| Network | `mp3quran.net` (catalog + audio), `cdn.jsdelivr.net` (pinned text packs), `quranyahdi.pages.dev` (new: `version.json`, anonymous) |
| Permissions | INTERNET · ACCESS_COARSE_LOCATION (on-device only) · SCHEDULE_EXACT_ALARM · FOREGROUND_SERVICE(_MEDIA_PLAYBACK) · WAKE_LOCK · VIBRATE · RECEIVE_BOOT_COMPLETED (plugin-manifest merge, platform plumbing) · POST_NOTIFICATIONS (plugin manifest) — verified with `aapt dump badging` on the release APK this session; **no FINE_LOCATION, no AD_ID, no INTERNET-out beyond the three pinned hosts' behavior** |
| Backup | `kBackupSettingsWhitelist` unchanged; new keys (`version_policy_cache`, `version_update_prompt_ack`, `review_requested`) are deliberately **outside** the whitelist — restores must not resurrect dismissed prompts or wrong policies |
| Documentation | `PRIVACY.md`/`PRIVACY.en.md`, `docs/store/data-safety-form-answers.md`, `docs/operations-runbook.md` all updated **in place** this session (see §11) |
| Format gate disclosure | One pre-existing test file (`test/backup_crypto_test.dart`) was committed **not** in format-clean state; the repo's format gate re-wrapped it this session (whitespace-only, no test logic touched). HEAD was not format-clean before this session — the CI format job would have failed on any push touching that path. |

## 3. Force Update — implementation and configuration

### What exists now

| Concern | Implementation |
|---|---|
| Pure comparison | `lib/core/domain/version_policy.dart` — `AppVersion.parse`/`compareTo` (major, minor, patch, build; never string comparison), `VersionPolicy.fromJson` (strict validation: required `min_supported` and `latest`; `latest ≥ min_supported` or the policy is rejected as malformed; https-only `store_url`; ≤500-char messages), `VersionVerdict` (`upToDate` / `updateRecommended` / `updateRequired`) |
| Network + cache | `lib/features/update/data/version_policy_service.dart` — Dio, 8s connect/receive timeout, single-flight; **fail-open everywhere**: HTTP error / timeout / 404 / malformed JSON → serve last-known-good cache, else `null` (no policy → no enforcement). Raw response cached in `settings_table` (`version_policy_cache`) |
| Gate | `lib/app/version_gate.dart` — `VersionGate extends ChangeNotifier` modeled on the existing onboarding gate; `decide(location)` returns `/update` **only** when a valid policy marks the installed build below `min_supported`; `refreshListenable: Listenable.merge([onboardingGate, versionGate])`; `settled` future lets callers serialize on the first policy read |
| Routing | `lib/app/router.dart` — `/update` root route; redirect chain onboarding → update gate (an unsupported install is forced to `/update` no matter what it asked for; a valid policy wins over every deep link) |
| Screen | `lib/features/update/presentation/update_gate_screen.dart` — mandatory mode: full-screen, `PopScope(canPop: false)`, no close, no "later"; primary button opens the Play listing (`openStoreListing`, via `in_app_review`); on a sideloaded/failing store surface a toast tells the user to update from the Play page. Recommended mode: a dismissible `/update` prompt pushed at most once per recommendation (`version_update_prompt_ack`), with a "Later" button |
| l10n | 7 new strings × AR+EN (`updateRequiredTitle/Body`, `updateRecommendedTitle/Body`, `updateNow`, `updateLater`, `updateUnavailable`) — additive only |
| DI | `lib/app/di/injector.dart` registers `VersionPolicyService` (implements `VersionPolicySource`+`VersionPolicyCache`), `DriftVersionAckStore`, `StoreListingGateway` (`InAppReviewStoreListing`), `VersionGate` (static seam on `AppRouter`, attached in `main.dart` once `PackageInfo` resolves), `ReviewService` |
| Boot | `lib/main.dart` — `unawaited(_attachVersionGate())` behind the first frame; after the first policy read settles, if (and only if) verdict is `updateRecommended` and the user has not acked that recommendation, `/update` is pushed once. A mandatory verdict never pushes — the router redirect fires by itself |

### Version policy document (hosted, owner-published)

```json
{
  "min_supported": "1.0.0",
  "latest": "1.0.1",
  "message_ar": "يرجى تحديث التطبيق",
  "message_en": "Please update",
  "store_url": "https://play.google.com/store/apps/details?id=com.mostafasayed.quranyahdi"
}
```

All fields except `min_supported`/`latest` are optional (defaults: Play listing, app-localized copy).
**This file does not exist yet.** Until the owner publishes it, the app is never blocked (fail-open), which is the designed behavior — **the mechanism is implemented but dormant until §12 is done**.

**Fallback policy (documented contract):** malformed/missing/slow/404 → serve last-known-good cache → else no enforcement. A stricter offline policy ("lock up on every failure") was considered and rejected: it would strand users behind a launch-time gate with no network and no recovery path. If an emergency compatibility/security revocation is ever needed, document it as a separate owner decision with an immediate Pages rollback plan.

### Verification status

- `test/version_policy_test.dart` (24 tests): parse/compare/strict-validation/verdicts — incl. `1.10.0 > 1.9.0`, build-number tie-break, name-dominates-build, `latest < min_supported` rejected, non-https URL dropped, oversized message dropped, null policy can never lock out.
- `test/version_gate_test.dart` (15 tests): fail-open before first read, mandatory blocks every route except `/update`, recommended does not block, ack suppresses re-prompt, cache fallback on HTTP failure, cache fallback on malformed remote, no-cache → fail-open.
- `test/version_ack_store_test.dart` (1): settings-table round-trip (pins the exact key).
- `test/version_router_test.dart` (2): the app router wires the mandatory verdict to `/update`; the router stays usable with the gate never attached.
- `test/update_gate_screen_test.dart` (2 widget tests): mandatory hides back + "Later"; recommended shows "Later".
- **Not verified:** on-device E2E of the `/update` screen against a real remote policy (no `version.json` is published yet, and a sideloaded debug build E2E was not run this session).

## 4. In-App Review — implementation and limitations

| Concern | Implementation |
|---|---|
| Timing | **Not at launch, never during religious/reading/prayer/adhkar flows.** The only trigger is the onboarding completion seam (`OnboardingGate.complete()` — finish **or** skip), which fires **1.5 s after** the flow completes, once per install, and never again |
| Eligibility | `ReviewEligibility` (pure): `onboardingCompleted && !alreadyRequested`. No counters of user activity exist — nothing about reading, adhkar, tasbeeh, prayer or search is inspected or counted |
| Persistence | One-shot marker `review_requested` written **before** the platform call (an install whose marker write succeeded can never re-prompt; a fresh install is re-eligible) |
| Failure handling | Gateway failures and Play being unavailable (sideloaded builds) are swallowed; the feature can never affect app stability or block navigation |
| Dialog realism | The Play In-App Review API decides whether a dialog appears (quota/install-source). This build has **never** been Play-installed in that sense — no claim that a dialog was seen is made anywhere |

**Known limitation (honest):** eligibility logic is unit-tested (`test/review_service_test.dart`, 10 tests); the actual Play dialog is verifiable only via Play internal testing on a store-installed build. `in_app_review 2.0.12` implements `requestReview()` over the Play API only on Play-installed builds; elsewhere `isAvailable()` returns false.

## 5. Crash reporting — provider status and decision

**Status: not implemented — deliberate.** The last known state (and current state) is: no crash SDK, privacy policy discloses its absence, and Play Console vitals is the sanctioned channel. Adding Crashlytics or Sentry **is a new data-collection posture** and this session does not grant that. Doing it silently would violate the project's privacy contract.

**Decision checklist for the owner (all required, none done):**

1. Pick provider. Criteria: no Firebase exists in the repo, so **Sentry** (single SDK, no Google services dependency) is the marginally better fit than Crashlytics; either requires new credentials and a new privacy posture.
2. Update `PRIVACY.md` + `PRIVACY.en.md` (disclose collection scope, retention, controls) — owner reviews wording.
3. Update `docs/store/data-safety-form-answers.md` and the Play Data Safety form (crash/ANR data type declaration; Play vitals is already declared as a platform source and remains unaffected).
4. Configure minimal capture: `FlutterError.onError`, `PlatformDispatcher.instance.onError`, background isolate errors (where technically supported), and keep `quran_yahdi/*` tags; **never** attach user content, search queries, city, reading position, or any religious-activity metadata.
5. Sample non-fatal errors (Crashlytics: default sampling; Sentry: `tracesSampleRate: 0`, errors only) — no performance tracing initially.
6. Verify on the closed testing track with a crash-forcing build before production.

Until all six are done and the owner signs off, crash investigation is **Play vitals + user reports** (`docs/operations-runbook.md` §1–2). The runbook has been updated to note the two new settings keys and the update gate; the crash section is unchanged because the posture is unchanged.

## 6. Release-mode verification (artifacts + device)

### Artifacts (built from this working tree, owner signing)

| Artifact | Size | Signer | applicationId | versionName | versionCode | Permissions (aapt) |
|---|---|---|---|---|---|---|
| `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` | 44.7 MB | `CN=Mostafa Sayed` SHA-256 `db7ffef4…c4685` | `com.mostafasayed.quranyahdi` | `1.0.0` | **2004** (split: base 4 + ABI offset) | INTERNET · WAKE_LOCK · FOREGROUND_SERVICE(+MEDIA_PLAYBACK) · ACCESS_COARSE_LOCATION · SCHEDULE_EXACT_ALARM · RECEIVE_BOOT_COMPLETED · VIBRATE · POST_NOTIFICATIONS |
| `…/app-armeabi-v7a-release.apk` | 42.7 MB | same cert | same | same | base `4` + its own ABI offset | same set (aapt on arm64; armeabi-v7a structurally identical) |
| `…/app-x86_64-release.apk` | 46.2 MB | same cert | same | same | base `4` + its own ABI offset | n/a checked (x86_64 = emulator dev lane only) |
| `build/app/outputs/bundle/release/app-release.aab` | 89.2 MB | `CN=Mostafa Sayed` (same serial, `keytool -printcert -jarfile` verified) | same | same | `4` | n/a (AAB verified by jar/keytool cert + Play inspection) |

SHA-256 (final artifacts, built from the fully tested tree): arm64-v8a APK `18A9EB38…F4F7828A` · AAB `DF2E3E0C…D7525686`. Built this session **twice**: first after the release-readiness implementation (hashes superseded), then rebuilt after the architecture-guard fix so the published hashes match the tree that passed `flutter analyze` (0 issues) and the full suite.

**Device-tested (this build, owner-approved install via `-r` — data preserved; the on-device `firstInstallTime=2026-11-01` confirms the owner's data survived):** force-stopped cold start ×3 → 701 / 645 / 881 ms; home renders with the owner's content intact (last-read Al-Baqarah ﴿٥﴾, next prayer فجر); deep link `surah/2` routes into the reader; total PSS after deep-link nav ≈ 217 MB. A later UI probe was interrupted by the owner's live phone call; **no further device interaction was attempted** and none is needed — the release smoke per `docs/release-checklist.md` §I remains for a calm sitting. The on-device screen-verification of `/update` and the review seam was also not done (first requires a published policy; second already fired on the owner's install or never will by design).

### Build-mode rules that remain in force

- Never build a store artifact on a machine without the keystore; the fail-closed guard stays.
- `tools\build_release.ps1 -Target appbundle` is the store-bound lane — since 2026-11-12 the wrapper arms `PUBLISH_RELEASE` itself. A bare `flutter build appbundle --release` is a local-only check with the update gate **off**. `.github` CI must never have the keystore.

## 7. Environments — flavor decision (honest evaluation)

**Evaluated:** Android product flavors (dev/staging/prod). **Conclusion: not justified for this app today**, and rejected deliberately:

- The app has **no backend**: nothing to point at another environment except the one policy file, which is already overridable per build: `--dart-define=QURAN_VERSION_POLICY_URL=<url>` (or `off` for a policy-free developer build).
- Three flavors would triplicate applicationIds, add signing and Play-console bookkeeping, and — with no staging backend — produce a "staging" that cannot exercise anything a local debug run doesn't already exercise. That's fake infrastructure, not separation.
- What the project *does* have is deliberate: `release` (minified+shrunk, owner keystore) vs `debug` (`applicationIdSuffix=.debug`, co-installable), plus the `publish` lane for store-bound artifacts. The documented normal lanes remain: `flutter run` (debug), `flutter build apk --release` (local release check), `tools\build_release.ps1 -Target appbundle` (store lane: policy key + signing guard).
- **Staging**: explicitly **not implemented** — there is no staging page, no staging policy file, and inventing one would be exactly the fake infrastructure this audit rejects. If the owner later wants a staging surface, the one knob is a second `version.json` (e.g., `…/pages.dev/staging-version.json`) and the same `--dart-define`.

Dev-vs-prod separation that actually exists today: debug applicationId (`.debug`), verbose `quran_yahdi/*` logs only in debug (release strips `print`; `dev.log` remains but is silent by platform policy), and the release-only R8/shrinking path.

## 8. Analytics — privacy-safe strategy (ready, not activated)

**Status: not active, no SDK shipped, nothing transmitted.** The privacy gate stands. What *would* be safe and *would* be useful, if the owner ever approves it — a small operational taxonomy (never the worship loops):

| Event | Why it exists | Parameters |
|---|---|---|
| `onboarding_completed` | Conversion/health of the 2-step first-run flow | `method` (finish\|skip) |
| `update_required_shown` | Emergency-lockout visibility | `installed_version` (name only) |
| `update_optional_shown` | Is the prompt useful or noise? | `installed_version` |
| `reciter_catalog_fetch_failed` | Is the catalog endpoint unhealthy? | none |
| `download_failed` | Recitation downloads are the one bytes-heavy flow | `reason` (network\|http\|disk) — **never** file names, never surah references |

Never instrumented: Quran reading history, specific surahs/ayahs, search queries, adhkar/tasbeeh counts, prayer times/activity, Qibla/location, backups, any PII. Architecture if approved: a `CoreAnalytics` port in `core/domain` with a no-op default, a thin provider adapter, events typed as `const` enums, UI code never imports the SDK, opt-in only, honors any future consent flag. Effort: ~1 sitting. **Decision owner: Mustafa.**

## 9. Release checklist

`docs/release-checklist.md` was created and is reusable as-is (all release stages A→J, store readiness, staged rollout, rollback, post-release vitals). The checklist enforces what this audit verified manually once (artifacts, signing, permissions, on-device smoke, staged rollout) and what it cannot (fresh `version.json` **before** any lock-out, versionCode confirmation, release-notes honesty). Summary in the file's A–J sections; not duplicated here.

## 10. CI/CD — implementation and remaining setup

**What CI does today** (verified by reading `.github/workflows/ci.yml`, this session): pinned Flutter 3.47.5; `flutter gen-l10n` drift check; `dart run build_runner build --delete-conflicting-outputs` + drift check; `flutter analyze`; `dart format --set-exit-if-changed lib test tools`; `flutter test`; on pushes to main a second job builds split release APKs + the AAB and uploads them as `debug-signed-*` artifacts (14-day retention — never Play-bound). The toolchain matches `.fvmrc` and AGENTS.md — the format gate is the same formatter as the dev box, which is load-bearing for this repo.

**What was deliberately not added:** a store-upload job. CI has no keystore (by design) and must never gain one silently. A `publish` job would only duplicate the documented manual lane (`tools\build_release.ps1 -Target appbundle` on the owner's machine) with new failure modes. If the owner later wants it, the required secrets (`KEYSTORE_B64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` — documented by name, never values) go to GitHub environment `production` with manual approval, plus a `wrangler`-style review gate; not in this task's scope.

**Remaining external setup for CI/CD:** none to make today's green-main loop work — it already runs. For release automation later: Play Console service account + internal-track lane in a new `publish.yml` with required reviewers; Play App Signing already managed by Google — verify `Upload key` retention. This is an owner call, not a default.

## 11. Privacy-policy and Data-Safety changes required — done (not deferred)

| Document | What changed | Why |
|---|---|---|
| `PRIVACY.md` (AR) | Internet row now names the three pinned endpoints including `quranyahdi.pages.dev/version.json` (anonymous, once per launch, fail-open); new short section "التقييم على Google Play" disclosed (once per install, only post-onboarding, never at launch, no data collected) | Honest disclosure of the only new network call and the review surface |
| `PRIVACY.en.md` (EN) | Same two changes in English | Mirror |
| `docs/store/data-safety-form-answers.md` | v1.0.0/+3 note updated; the full data-type matrix gains the `version.json` row (anonymous, no identifiers/parameters); the dependency-set paragraph now names `package_info_plus` (reads platform, transmits nothing) and `in_app_review` (official Play API; data handled by Play, never by the app); `RECEIVE_BOOT_COMPLETED` added to the census as plugin-manifest merge plumbing | The form stays consistent with the shipped artifact |
| `docs/operations-runbook.md` | §3 gains the version-policy control surface, the fail-open contract, the Pages publish path, the unblock-without-a-release procedure (flip `min_supported` back up/down), and the two new settings keys; smoke list includes the `/update` check on a side-loaded build; scope note "versionCode 4+" | Ops can actually run an emergency |

**Not changed (correctly):** location section (still coarse-only, on-device), advertising/analytics statements (still truthful — none), backup-whitelist claims (unchanged), Play vitals platform-note (still the crash channel), permissions table rows (only the Internet row grew), Data Safety form top-level answer (still **NO** to collection; no user data is transmitted).

**Review needed from owner:** the Arabic/English wording of the two new disclosures (lawyer-grade review if the store ever complains), and whether "no start-up review prompt" is a claim to keep in public copy (it is accurate — eligibility starts only after onboarding completes, which happens on the first session, but **immediately after onboarding, 1.5 s later**, which is a completion moment, not a launch moment — the wording in the privacy docs states this precisely).

## 12. External prerequisites (owner-side; nothing in the repo can do these)

1. **Publish** `https://quranyahdi.pages.dev/version.json` (owner repo `web/`): `min_supported`/`latest`/messages/store URL — without it the gate is inert (fail-open, safe). Include a `message_ar` and a `message_en`.
2. **Confirm the versionCode for the next Play upload**: the base code is `4` (`pubspec.yaml`) and the AAB carries `4`. Check in Play Console whether code `4` is already on a track; if it is, bump `pubspec.yaml` to `1.0.0+5` before building — Play rejects a reused code.
3. **Decide crash reporting** (§5) or reaffirm the Play-vitals-only posture.
4. **Decide analytics** (§8) if desired; otherwise the taxonomy stays a plan.
5. **Closed-testing soak** with this build (internal track → 24 h → closed → production staged 5→20→50→100 %), watching vitals per the runbook.
6. **Re-install this build on the device** when the owner wants the new paths smoke-verified (the phone currently runs the 2026-11-09 perf-audit build).
7. **Owner-side pages deploys** stay manual: the force-update file and privacy pages are published from the website repo, not from this one.
8. **No release, no push** from this session: HEAD is unchanged, artifacts are local, `debug-signed-*` never leaves CI, Play is untouched.

## 13. Remaining risks

| # | Risk | Severity | Mitigation in place |
|---|---|---|---|
| R1 | Force Update locks out users if `min_supported` is raised carelessly | **P1** (owner-action) | Fail-open covers everything *except* a valid-but-wrong policy — a single static file decides this. Mitigation: policy file publish is the owner's explicit step, store listing always reachable, unblock = flip the file (§R in runbook), rollback is instant |
| R2 | `version.json` is a single point of failure (site content, cache headers) | P2 | Cloudflare Pages redundancy; file could be served with `Cache-Control: max-age=300`; app-side fail-open bounds the blast radius; no lock-out ever happens from the app's own behavior |
| R3 | ~~versionCode `2004` vs store's `4`~~ — **CLOSED 2026-11-12: category error.** `2004` is the arm64 split-APK ABI offset over base code `4`; nothing drifts. The real question is whether code `4` is already on a track (§12) | — (was P1) | Correction note at the top; `docs/store/play-console-setup.md:23` had it right all along |
| R4 | In-App Review dialog never shown (Play quota) — owner may think it's broken | P2 | Documented as API-quota reality; one-shot marker means no repeated nagging either way; verify only via internal-track install |
| R5 | `in_app_review` adds a KGP plugin; Flutter will warn again at next major | P3 | Pinned version; watch the runbook review note; consider alternatives at Flutter 4 migration |
| R6 | No crash SDK → an S1 (launch crash) is a Play-vitals estimate, not an instrumented count | P2 | Play vitals + user reports; §5 decision pending owner |
| R7 | The review seam is a single point of behavioral change on every install (it asks *once*) | P3 | Unit tested; one-shot marker; fail-silent; user can always ignore |
| R8 | New network call increases dependency surface (one more host the owner must keep up) | P2 | Same Pages host that serves the privacy policy; anonymous request; failure costs nothing |
| R9 | Only a partial on-device smoke ran (boot, home, deep-link reader route) — tapped UI flows remain for a calm sitting; an earlier tap probe was interrupted by the owner's live call, so interaction testing has a small unverified residue | P3 | Checklist §I documents the full pass; nothing in the touched code paths changed the release-tested behavior |
| R10 | Data Safety reviewer notes `in_app_review`'s Play delivery as a "network call" → possible rejection wording | P3 | Disclosure is explicit in the docs; Play's Data Safety asks about *data collection by the app*, which is unchanged (NO). Rejection risk is low but nonzero |

## 14. Recommended next steps

1. **Now (owner):** confirm R3 (versionCode) and R1 (want Force Update active at all? Publish `version.json` only when comfortable; inert is a valid steady state).
2. **Before next release:** re-install this build on the Infinix; walk the §I smoke checklist with the gates green (analyze 0; full suite passed — see header).
3. **Before production lane:** internal track soak ≥ 24 h; vitals decision (R6 persists until §5 is resolved).
4. **After production:** add the `publish` lane to CI only when the owner wants automated internal-track upload (with environment protections), never a straight production deploy.
5. **When Flutter next majors:** revisit `in_app_review` (KGP warnings), the versionCode derivation, and Play's Data Safety wording.

---

*This document is the single source of truth for the 2026-11-09 release-readiness pass. Evidence: git HEAD `6e0ff45`, artifact SHA-256s above (rebuilt from the final tested tree), `flutter analyze` (0 issues), full test suite (**+1498, 0 failed**, of which 48 are the release-readiness tests incl. architecture-guard), the device measurements in `docs/performance-audit.md` §3 (2026-11-09 rev 2), and the verified certificate/permission prints in §6. Nothing in this document asserts anything that was not observed.*
