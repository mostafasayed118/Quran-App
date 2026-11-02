# v1.0 launch decisions — 2026-11-01

> **Status:** owner-delegated decisions for the Android `1.0.0+3` launch. iOS is out of
> scope for v1.0. **Basis:** `PRODUCTION_READINESS_REPORT.md` (93 findings),
> `PRODUCTION_REMEDIATION_PLAN.md` §3.2, and a source re-check of the working tree.
>
> These decisions close the "external / owner track" questions that Phase 0 of the
> remediation plan requires before any product code is scheduled. They do **not** approve
> a Play upload, a commit, or a push.

## Decision table

| # | Question | v1.0 decision | Why | Follow-up |
|---|---|---|---|---|
| D1 | English locale | **Arabic-only at runtime.** Remove `en` from the app's supported locales and the Android locale config; keep the EN ARB + generated files as v1.1 groundwork. | `app.dart` pins `Locale('ar')`, so advertising EN to the OS is false: a user who picks English gets an Arabic app. A real switch needs a settings control, persistence, and LTR/RTL tests — a feature, not a launch fix. | v1.1: settings toggle + persisted locale + `MaterialApp.locale` from state. |
| D2 | R8 / shrinking | **Enable R8 + resource shrinking for the store build, but only after a signed build passes a real-device smoke.** Archive `mapping.txt` + native symbols. | The AAB is 68.9 MB and ships recoverable Dart symbols; Play discourages large downloads. Flipping it blind risks plugin/reflection breakage (drift, notifications, audio). | Owner approves one signed build + `tools/device_smoke.ps1`; roll back if smoke fails. |
| D3 | Play App Signing | **Enroll, then put the Play app-signing SHA-256 in `assetlinks.json` *alongside* the upload cert.** | The file pins one fingerprint (`DB:7F:…:46:85`). If Play re-signs, Android App Links stop verifying. | Play Console step; paste the SHA-256 into the JSON and the web deploy. |
| D4 | Content licensing | **Launch only with cleared packs:** the two translations (`ara-sirajtafseer`, `eng-mohammedmarmadu`) and `ara-bukhari` with its provenance note. Obtain written terms for the two bundled fonts and mp3quran before upload; remove any pack whose terms are not cleared. | Seven `OPEN-FOR-OWNER` rows remain; IP/takedown risk is a launch blocker, not a code bug. | Owner supplies written terms / signs off; catalog edit is one file. |
| D5 | Crash reporting | **Play vitals only for v1.0. No third-party crash SDK.** | Matches the tracker-free privacy posture and `docs/operations-runbook.md`; adding telemetry is a policy change, not a bug fix. | Revisit in v1.1 with an explicit privacy decision. |
| D6 | Juz navigation | **v1.1 feature, not a launch blocker.** | The `juz` column is already in the schema; the reader is complete by surah. Adding juz navigation is a focused UI wave. | v1.1: juz index + reader entry. |
| D7 | Azkar counters | **Keep counters per-session in v1.0.** | They reset on leaving the collection, which is acceptable for a dhikr session and avoids extra writes. Persisting them is a UX enhancement. | v1.1 candidate. |
| D8 | Zakat inputs | **Keep ephemeral (do not persist).** | Financial inputs are sensitive; the plan already lists persistence as an open product question. The calculator is stateless by design. | Revisit only with a privacy decision. |
| D9 | Qibla calibration | **v1.0 keeps the static fallback; v1.1 adds smoothing + a figure-8 calibration hint.** | Raw magnetometer readings vary by device; the screen already degrades when the sensor is unavailable, so this is quality, not correctness. | v1.1 sensor polish. |
| D10 | Download scope | **v1.0 keeps per-surah retry (no resume, no global queue).** | Retry works and the 64 MiB cap/atomic `.part` promote are already safe. Resume is an enhancement, not a blocker. | v1.1: HTTP Range resume + queue. |
| D11 | iOS | **Out of scope for v1.0.** | No `Podfile`, no `DEVELOPMENT_TEAM`, no macOS CI job; the shared Dart code is ready but the platform shell is not. | Separate project decision. |
| D12 | 16 KB page alignment | **Verify the signed artifact with `zipalign -c -P 16`; fix only if it fails.** | Android 15+ requires 16 KB alignment; the current AGP may already handle it, but the signed artifact must be measured, not assumed. | Run on the release APK/AAB before upload. |

**D1 scope note:** "Arabic-only" is the Flutter UI. `android/app/src/main/res/values-en/strings.xml`
still provides the English launcher label (the system locale picks it), and the generated
`AppLocalizations.supportedLocales` still lists `en` because the EN ARB is kept for v1.1. Do not
wire that generated list into `MaterialApp.supportedLocales` until the switch exists.

## Consequences for the code

- **D1 is implemented in this wave** (`app.dart`, `locales_config.xml`) because it removes a
  false claim without adding a feature.
- **D2–D4, D12 are owner/build actions**; no source change is made here.
- **D5–D11 are deferred by decision**, not forgotten. They are recorded so a later session
  does not re-litigate them.

## What this does not decide

- The Play Console track/rollout percentages and the highest versionCode.
- The final licensing sign-off (legal, not engineering).
- Whether the web site gets a custom domain.

## Amendment — 2026-11-02: D1 delivered as a runtime switch (v1.1 work)

D1 originally pinned the app to Arabic because advertising `en` without a switch would have
been a false claim. The v1.1 groundwork is now paid and the switch exists:

- **Domain/storage:** `AppLanguage` + `AppLocaleSource` (`lib/core/domain/app_locale.dart`),
  stored by `AppLocaleRepository` under the `app_locale` key (`ar` default; an unknown or
  unreadable value falls back to Arabic).
- **Runtime:** `AppLocaleController` (`lib/core/l10n/app_locale_controller.dart`) holds the
  choice and notifies the root; `MaterialApp.locale` reads it and `supportedLocales` is
  `kSupportedLocales` (`ar`, `en`), so `Directionality` follows the language (RTL/LTR).
  The controller is loaded behind the first frame from `lib/main.dart`.
- **Surface:** a language row in Settings (`lib/features/settings/presentation/settings_screen.dart`)
  offering each shipped language; the pick applies immediately and persists.
- **Platform:** `android/app/src/main/res/xml/locales_config.xml` now declares `ar` **and** `en`.
- **Backup:** `app_locale` is deliberately **device-scoped** and stays out of the backup
  whitelist (a restore onto another phone must not flip the reading language); the coverage
  pin in `test/backup_settings_coverage_test.dart` enforces that split.

Arabic remains the default for a fresh install. The EN ARB stays a full mirror of the AR
template (285 keys each, no drift), so a new string still needs both sides.
