param(
  [ValidateSet("appbundle", "apk")]
  [string]$Target = "appbundle",
  [switch]$SplitPerAbi
)

$ErrorActionPreference = "Stop"

$key = $env:QURAN_VERSION_POLICY_PUBLIC_KEY
if ([string]::IsNullOrWhiteSpace($key)) {
  $keyFile = Join-Path $PSScriptRoot "version-policy-public.txt"
  if (Test-Path $keyFile) {
    $key = (Get-Content $keyFile -Raw).Trim()
  }
}
if ([string]::IsNullOrWhiteSpace($key)) {
  throw "QURAN_VERSION_POLICY_PUBLIC_KEY is empty; refusing a release build"
}

try {
  $keyBytes = [Convert]::FromBase64String($key)
  if ($keyBytes.Length -ne 32) {
    throw "the public key must decode to 32 bytes"
  }
} catch {
  throw "QURAN_VERSION_POLICY_PUBLIC_KEY must be a base64-encoded 32-byte Ed25519 public key: $($_.Exception.Message)"
}

# The wrapper is the store/release lane, so it arms the fail-closed signing
# guard: without android/key.properties the Gradle build must fail instead of
# producing a debug-signed artifact. A plain `flutter build apk --release`
# that bypasses the wrapper stays the local-only check and keeps its
# debug-signed fail-soft (android/app/build.gradle, publishRelease).
$env:PUBLISH_RELEASE = "true"
Write-Host "store lane: PUBLISH_RELEASE=true; version-policy public key injected"

$buildArgs = @(
  "build",
  $Target,
  "--release",
  "--dart-define=QURAN_VERSION_POLICY_PUBLIC_KEY=$key"
)
if ($Target -eq "apk" -and $SplitPerAbi) {
  $buildArgs += "--split-per-abi"
}

& flutter @buildArgs
exit $LASTEXITCODE
