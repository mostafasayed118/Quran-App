# Operations Runbook — Quran Yahdi

**Scope:** Android production releases of `quran_yahdi`.
**Privacy posture:** the app has no accounts, no analytics SDK, no advertising SDK, and no
crash-reporting SDK. Operational diagnosis relies on Google Play’s platform-provided vitals
and on user reports, not on app telemetry. Do not add a third-party telemetry SDK without an
owner decision and a privacy-policy update.

## 1. Production error investigation

### 1.1 First source: Play Console

1. Open **Play Console → Quality → Android vitals** for `com.mostafasayed.quranyahdi`.
2. Review **Crash rate**, **ANR rate**, and the top crash clusters for the released versionCode.
3. Use the stack trace and affected device/OS distribution to identify the feature.
4. Correlate with the release notes and the `docs/campaign-ledger.md` entry for that version.

The app does not upload its own crash reports. Play vitals is aggregated by Google under
Google’s terms; it is not an app-owned data channel.

### 1.2 Local reproduction

- Use a debug build (package id `com.mostafasayed.quranyahdi.debug`) on a test device:
  `flutter build apk --debug` then `tools/device_smoke.ps1`.
- Capture logs with the full adb path, filtering the app’s diagnostic tags:
  `adb logcat -d | Select-String "quran_yahdi/"`.
- The app uses `dart:developer log` with tags such as `quran_yahdi/boot`,
  `quran_yahdi/db`, `quran_yahdi/downloads`, `quran_yahdi/library`,
  `quran_yahdi/playback`, `quran_yahdi/reminders`.
- Do **not** ask a user for their backup JSON, database file, or downloaded audio; those can
  contain private reading/worship data. Ask for: app version, Android version, device model,
  network type, exact steps, and a screenshot (redact personal content).

### 1.3 What not to log

- Never log passwords, signing passwords, API keys, session tokens, `Authorization` headers,
  backup file contents, Quran reading history, city coordinates, or prayer logs.
- Backup import/export logs use `error.runtimeType`, not the exception message, because a
  JSON error can embed a snippet of the user’s file.
- The source-level guard `test/log_hygiene_test.dart` fails on `print`/`debugPrint` in `lib/`
  and on obvious secret terms inside `dev.log` calls.

## 2. Release health monitoring

1. Upload the signed AAB to the **internal track** first; install from Play on a real device.
2. Smoke: cold launch, open a surah, play a recitation, download one surah, prayer times,
   qibla, backup export/import, settings, one notification tap.
3. Promote to **closed testing**; watch crash/ANR for at least 24 hours.
4. Production rollout in stages: **5 % → 20 % → 50 % → 100 %**, with a 24-hour watch at each
   stage (or the shortest window the owner accepts).
5. Monitor: crash-free users, ANR rate, Play reviews mentioning crashes/data loss, and support
   email. There is no app-owned dashboard.

## 3. Configuration control

- Version comes from `pubspec.yaml` (`version: 1.0.0+N`); `versionCode` must strictly exceed
  every code previously uploaded to any track.
- SDK levels are pinned in `android/app/build.gradle` (`compileSdk 36`, `minSdk 24`,
  `targetSdk 36`); Flutter is pinned to 3.47.5 in `.fvmrc` and CI.
- The release keystore lives outside the repo; `android/key.properties` is gitignored. CI has
  no keystore, so CI artifacts are `debug-signed-*` and must never be uploaded to Play.
- Store-bound builds use `$env:PUBLISH_RELEASE="true"; flutter build appbundle --release`
  (PowerShell); a missing key fails the build by design.
- There are no remote feature flags. Content/catalog changes require a code release; endpoints
  are compile-time constants.
- Do not change `applicationId` or signing keys. A new signing key permanently breaks updates
  for existing installs.

## 4. Incident escalation

| Severity | Example | First action | Owner action |
|---|---|---|---|
| S1 | Crash on launch; data loss; signing/update failure | Halt staged rollout immediately | Hotfix or rollback; publish a store note |
| S2 | Core feature broken (reader, prayer times, audio) | Pause rollout at the current stage | Fix in next versionCode; support reply |
| S3 | Cosmetic/localized issue | Continue rollout if data-safe | Backlog for the next release |

Escalation channel: the app owner’s privacy/support email in `PRIVACY.md`. Include the
versionCode, device/OS, reproduction steps, and redacted evidence. Never include secrets or a
user’s backup/DB.

## 5. Rollback and recovery

1. **Halt the staged rollout** in Play Console (Release → Production → Halt rollout).
2. If a previous production release is still available, promote it to restore service.
3. Otherwise ship a hotfix with a **new, higher versionCode**; never reuse a versionCode.
4. For data issues, preserve the user’s local DB: do not instruct a data clear unless the
   database is proven corrupt and the user accepts the loss. The app has no server copy.
5. After recovery, record the incident and the corrective commit in `docs/campaign-ledger.md`.

## 6. External dashboards and permissions

| System | What it provides | Access needed |
|---|---|---|
| Google Play Console | Android vitals, rollout control, app signing certificate, internal/closed testing | Owner account |
| Cloudflare Pages | Web companion availability and request metadata | Owner account |
| mp3quran.net | Recitation catalog/audio availability | Public status only |
| cdn.jsdelivr.net | Pinned pack availability | Public status only |

No Sentry, Firebase Crashlytics, analytics, advertising, or attribution dashboard exists.
Adding one is an owner decision that requires a privacy-policy and Data-safety update.

## 7. Privacy incident checks

- Confirm whether the report includes personal data; if so, delete it from the support inbox
  after resolution.
- Rotate the signing key only if it is compromised; rotation changes the app identity and
  requires a Play App Signing key reset.
- If an APK/AAB with a debug signature is ever distributed, treat it as an incident: it cannot
  update a Play-installed app and must not be uploaded.
- The privacy policy must stay aligned with the manifest (currently coarse location only, no
  analytics/crash SDK). Re-check it when permissions or SDKs change.

---

**Last updated:** 2026-10-30 · **Applies to:** versionCode 3 and later
