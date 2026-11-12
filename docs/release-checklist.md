# Release Checklist — Quran Yahdi

Reusable, practical, grouped by stage. Run it **every** production release; tick and date each item. If a box can't be ticked, the release doesn't ship. The app has **no accounts, no analytics, no crash SDK** — never add one without an owner decision and a privacy update.

Legend: 🖥️ host step · 📱 on-device step · 🔁 repeatable · ⚠️ owner decision / external account.

---

## A. Versioning

- [ ] Version comes from `pubspec.yaml` (`version: NAME+CODE`). `versionCode` strictly exceeds every versionCode ever uploaded to any track, including bundling ASIC channels.
- [ ] `versionName` bumped by semver intent (patch = fix, minor = feature); never reused.
- [ ] Release notes written (`docs/store/release-notes-1.0.0.ar.md`/`.en.md` pattern, latest = list of user-visible changes, honest, no marketing).
- [ ] `.fvmrc` and CI pin Flutter 3.47.5; `AGENTS.md` and CI agree.
- [ ] Min SDK 24 / target 36 / compile 36 unchanged or deliberately bumped with the pinning rules in `android/app/build.gradle` (see CONTRIBUTING decisions in `docs/decisions/`).
- [ ] Version-policy JSON (`https://quranyahdi.pages.dev/version.json`) checked if this release changes compatibility requirements: set `min_supported` ≥ the new floor, `latest` to the new version (see §D).
- [ ] Changelog references the `docs/campaign-ledger.md` entries that produce this release.

## B. Build configuration

- [ ] `android/app/build.gradle` `namespace`/`applicationId` unchanged (`com.mostafasayed.quranyahdi`); debug keeps `applicationIdSuffix = ".debug"` and `versionNameSuffix = "-debug"`.
- [ ] Pinning confirmed: `compileSdk = 36`, `minSdk = 24`, `targetSdk = 36` (not inherited from flutter.*).
- [ ] `minifyEnabled`/`shrinkResources` = true on `release`; `proguard-rules.pro` kept for the name-resolved plugins (Gson notification payloads). Do **not** disable R8 to ship faster.
- [ ] No development endpoints, no `--dart-define` leak of staging values; the only build-time switches are `QURAN_VERSION_POLICY_URL` (optional override) and `PUBLISH_RELEASE` (publish lane only).
- [ ] Generated sources are current (`flutter gen-l10n` + `build_runner` clean; CI gate proves this).
- [ ] `flutter pub outdated` reviewed; **no new package without an owner grant** and an entry in `docs/campaign-ledger.md`.

## C. Signing

- [ ] `android/key.properties` exists on the release machine (gitignored; never in the repo, never in CI, never printed).
- [ ] Release builds signed with the owner keystore — verified with `apksigner verify --print-certs` on the built APK (issuer `CN=Mostafa Sayed`).
- [ ] For the store-bound lane: `tools\build_release.ps1 -Target appbundle` — the **only** store lane. It injects the version-policy public key **and** arms `PUBLISH_RELEASE`, so a missing keystore fails the build instead of producing a debug-signed artifact. A debug-signed artifact must never reach Play.
- [ ] Play App Signing (managed by Google) noted: the Play console serves the app-signing key; keep the upload key safe — rotating it invalidates updates.
- [ ] No secrets in the repo: `git status --porcelain` clean except owner debris (`INSTRUCTIONS.md`, `.vscode/settings.json`, …); `.gitignore` covers `android/key.properties`.

## D. Update policy (Force Update)

The app checks a remote policy at launch: `min_supported` / `latest`. Older than `min_supported` → blocking `/update` screen (only way past it is updating from Play). Supported-but-behind-`latest` → once-per-install optional prompt (dismissible; re-prompts only when `latest` increases).

- [ ] `https://quranyahdi.pages.dev/version.json` exists and is current for this release (owner action — the app fails open without it; never blocks users).
  - Content: `{"min_supported": "x.y.z", "latest": "x.y.z", "message_ar": "…", "message_en": "…", "store_url": "https://..."}` (messages optional; `store_url` must be https; `latest` ≥ `min_supported` or the policy is ignored as malformed).
  - Publish it as a **new file** (Pages serves immutable deploys); do not cache-bust by hand — bump the JSON on every release.
- [ ] The app never enforces on a malformed/missing/404 policy (fail-open is the documented guarantee; see `docs/release-readiness-audit.md` §3).
- [ ] `QURAN_VERSION_POLICY_URL=off` documented for offline developer builds.
- [ ] **First user-visible Force Update** (a release where you *intend* to lock out users) needs an owner sign-off and a Privacy/Runbook note — it's a product decision, not a build task.

## E. Permissions and privacy

- [ ] Manifest census re-checked (see `docs/store/data-safety-form-answers.md`): no new permissions; `INTERNET`, coarse `LOCATION` only, exact-alarm, foreground service — nothing else. Release APK `aapt dump permissions` matches.
- [ ] No `ACCESS_FINE_LOCATION`, no `AD_ID` anywhere in the resolved manifests.
- [ ] `PRIVACY.md` / `PRIVACY.en.md` still describe reality (no analytics, no crash SDK, or, if ever added, disclosure + this task's owner decision recorded).
- [ ] Data Safety form answers consistent with the last privacy update (`docs/store/data-safety-form-answers.md`).
- [ ] Log hygiene: no PII in `dev.log`; `test/log_hygiene_test.dart` passes; backup/DB contents never logged.
- [ ] Backup whitelist (`kBackupSettingsWhitelist`) deliberately unchanged for new transient keys (version-policy cache, review marker, update ack) — all are install-local by intent; restores must not resurrect dismissed prompts or wrong-version policies.

## F. Application quality

- [ ] `dart format --output=none --set-exit-if-changed lib test tools` clean.
- [ ] `flutter analyze` — **0 issues**.
- [ ] `flutter test` — full suite green; note exact count in the release ledger entry.
- [ ] Release-mode smoke on a real device (A-block). No debug builds for sign-off.
- [ ] Cold start < 2 s warm-cache on a modest device (see `docs/performance-audit.md`).
- [ ] 90 Hz reading scroll on Al-Baqarah holds ≤ 16.67 ms/frame — no jank (see audit §3).
- [ ] Offline: airplane mode boot → reader, adhkar, quran all usable; catalog/download failures show **localized** errors, never raw exceptions.
- [ ] Deep links: `https://quranyahdi.pages.dev/surah/N` opens the reader; back exits (documented v1 behavior).
- [ ] Audio: reciter catalog fetches once (fail-open offline); playback starts, pauses, resumes; the media notification is correct; closing the app doesn't duplicate the player (one `JustAudioPlaybackService`).
- [ ] Arabic RTL and EN LTR both render; textScale 2.0 leaves the reader, prayer times and settings legible.

## G. Release artifacts

- [ ] `flutter build apk --release --split-per-abi` → 3 ABIs built.
- [ ] `tools\build_release.ps1 -Target appbundle` → signed, policy-key-bearing AAB. A bare `flutter build appbundle --release` is a local-only check: no policy key (update gate off) and no signing guard, so it must never be uploaded.
- [ ] `apksigner verify --print-certs` — owner cert; `aapt dump badging` — correct applicationId, versionName 1.0.0(+N).
- [ ] AAB size sanity (arm64 ≈ 45 MB; flag regressions > 10% vs previous).
- [ ] Artifacts hashed (SHA-256) into the ledger entry; **never** uploaded/pushed outside the owner-approved lane.

## H. Store readiness

- [ ] Listing (`docs/store/listing-ar.md` / `.en.md`) current; screenshots re-shot if UI changed (`docs/store/screenshots/`).
- [ ] App icon (512 px), feature graphic, categories unchanged unless this release changes them.
- [ ] Privacy policy URLs live and current: `https://quranyahdi.pages.dev/privacy/` (AR) and `https://quranyahdi.pages.dev/en/privacy/` (EN) — owner-verified 2026-10-30 per `docs/store/play-console-setup.md`; re-verify if this release changes data flows.
- [ ] Data Safety + target SDK declarations consistent with §E; Play SDK declarations (none) unchanged.
- [ ] Internal testing track first; promote after the soak (§J), not straight to production.

## I. On-device release smoke (owner's phone)

📱 Launch → home renders; surah index opens; reader opens at last-read; Al-Baqarah scroll; search finds a surah; audio catalog lists reciters (needs network); download one reciter pack (optional); prayer times shows times or "اختر مدينتك"; adhkar counter works; tasbih counts; bookmark a verse (it stays a bookmark after restart); first-run onboarding on a *clean* install (debug build) both bypasses and completes correctly; update screen blocks when a locally-served policy demands it (see `docs/release-readiness-audit.md` §4).

## J. Post-release operations

- [ ] Staged rollout as `docs/operations-runbook.md` §2 (5 → 20 → 50 → 100 %, 24 h per stage, watch vitals).
- [ ] Internal track smoke within 24 h; closed track ≥ 24 h before production.
- [ ] Play vitals watched for 7 days (crash-free users, ANR, top clusters vs this versionCode).
- [ ] Emergency path rehearsed: halt rollout → promote prior version → hotfix with a new higher versionCode; record in `docs/campaign-ledger.md`.
- [ ] The version policy file (§D) is bumped **before** any emergency lock-out; the app never enforces remotely without a published policy.
- [ ] Crash reporting remains Play-vitals-only unless/until the owner approves an SDK (see `docs/release-readiness-audit.md` §5) — do not change it here.

## Ledger

After the release: append the checklist outcome (date, versionCode, artifact hashes, vitals verdict) to `docs/campaign-ledger.md`. Never delete prior entries.
