# Version-policy signing runbook

**Status:** the Force Update gate is implemented but **dormant**: no
`version.json` is deployed. A release build must now carry the Ed25519 public
key; a release build without it rejects every policy (fail-open, gate off)
instead of trusting an unsigned remote document.

## 1. Key custody

- The private seed lives **outside the repository**, e.g.
  `%USERPROFILE%\quranyahdi-keys\version-policy.seed`.
- Back it up to an encrypted USB drive and a password manager; verify the
  restore on a second machine.
- Never commit, paste, screenshot, or send the seed. `*.seed` is ignored as a
  backstop only.
- The public key is safe to commit: `tools/version-policy-public.txt`.
- Rotating the key requires a new app build (old builds do not trust the new
  key). Keep the old public key in the old builds; a new policy signed with
  the new key is ignored there (fail-open) until they update.

Generate (once, on the owner machine):

```powershell
$keyDir = "$env:USERPROFILE\quranyahdi-keys"
New-Item -ItemType Directory -Force $keyDir
icacls "$keyDir" /inheritance:r /grant:r "$($env:USERNAME):(OI)(CI)F"

dart run tools/version_policy_key.dart generate "$keyDir\version-policy.seed"
# prints the public key; copy it to tools/version-policy-public.txt
```

## 2. Release builds

```powershell
powershell -File tools\build_release.ps1 -Target appbundle
# or: -Target apk -SplitPerAbi
```

The wrapper is the **only** store lane. It reads
`QURAN_VERSION_POLICY_PUBLIC_KEY`, falls back to `tools/version-policy-public.txt`,
and **fails** if both are empty; it also sets `PUBLISH_RELEASE=true`, so a
machine without `android/key.properties` fails the build instead of emitting a
debug-signed artifact. The same public key must be present in every release
artifact that ships the update gate (APK and AAB). The private key is never
needed to build.

A direct `flutter build --release` that bypasses the wrapper still compiles,
but it is a **local-only check**: the gate stays off (no key, so unsigned
policies are rejected) and `PUBLISH_RELEASE` is unset (no signing guard).
Never use such an artifact for a store upload.

Code behavior:

- release + key configured → signed policy required, `expires_at` required;
- release + key empty → every policy rejected, gate stays off (fail-open);
- debug + key empty → legacy unsigned path for local development.

## 3. Policy document

```json
{
  "min_supported": "1.0.0",
  "latest": "1.0.0",
  "expires_at": "2027-01-31T00:00:00Z"
}
```

- `min_supported`: oldest version allowed to keep running. Keep it at or below
  the oldest build you actually support.
- `latest`: newest store version; at or above it means "current".
- `expires_at`: UTC instant, required on signed policies. Use a short window
  (30–60 days) and republish before it expires.
- `signature`: added by the signing tool; never include it in the source file.

The app also rejects an implausible `min_supported` (more than one major or two
minor versions ahead of the installed build) and a cache older than 30 days.
Those are typo/rollback guards, not a substitute for signing.

## 4. Sign and verify

```powershell
dart run tools/version_policy_key.dart sign `
  "tools\version-policy\version.json" `
  "$env:USERPROFILE\quranyahdi-keys\version-policy.seed"

$pub = (Get-Content tools\version-policy-public.txt -Raw).Trim()
dart run tools/version_policy_key.dart verify `
  "tools\version-policy\version.json" $pub
# valid
```

The signature covers the canonical JSON of the document without `signature`
(sorted keys, no whitespace), exactly as
`lib/core/utils/canonical_json.dart` produces it.

## 5. Publish order

**Do not publish `version.json` before the key-bearing build is the live
baseline.** Older builds have an empty key and accept unsigned policies; a
`min_supported` above their version would wall them.

Safe sequence:

1. Build and release the key-bearing app.
2. Confirm the release artifact is live and the key is present.
3. Sign a policy with `min_supported` = the oldest supported live version and
   `latest` = the new store version; use a 30–60 day expiry.
4. Copy the signed file to `web/public/version.json` and deploy the web app.
5. Probe `https://quranyahdi.pages.dev/version.json` (200, JSON, signature).
6. Watch the first 24 hours; keep the previous policy and a corrected one
   ready.

If the gate is intentionally off, leave `web/public/version.json` absent and
record that decision here and in `docs/operations-runbook.md`. The app stays
fail-open.

## 6. Play App Signing

Play App Signing is **not active until the first Play upload**. The current
`assetlinks.json` fingerprint is the release/upload certificate, which is
correct for sideloaded builds.

When the first Play upload enables Google Play App Signing:

1. Play Console → Test and release → Setup → App signing.
2. Copy the **App signing key certificate SHA-256** (not the upload key).
3. Add it to `web/public/.well-known/assetlinks.json` next to the existing
   fingerprint.
4. Deploy the web app.
5. Verify:
   ```powershell
   adb shell pm get-app-links com.mostafasayed.quranyahdi
   adb shell am start -a android.intent.action.VIEW `
     -d "https://quranyahdi.pages.dev/surah/2"
   ```
   The status must be `verified` and the reader must open.

## 7. Rollback

- A bad `min_supported` is a lockout. Publish a corrected signed policy with a
  lower minimum (or a `latest` at/above the affected builds) immediately.
- Online devices pick it up on the next launch; offline devices are bounded by
  `expires_at` and the 30-day cache age.
- If the key is compromised, rotate it in a new app release and publish a new
  signed policy with the new key. Old builds ignore the new policy (fail-open)
  until they update.
- Record the incident in `docs/campaign-ledger.md`.
