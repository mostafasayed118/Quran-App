<#
Device smoke gate for quran_yahdi (W7a Task 1).

Contract (docs/superpowers/plans/2026-10-16-w7a-device-media.md):
  1) locate adb (%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe or ANDROID_SDK_ROOT env) else FAIL 2
  2) adb install -r <apk> -> must print Success (else FAIL 3)
  3) adb shell am start -n com.mostafasayed.quranyahdi/.MainActivity
  4) poll pidof up to 10s (2s interval) -> alive required (else FAIL 4)
  5) adb logcat -d scan for "FATAL EXCEPTION" (fresh buffer: -c before start) -> none required (else FAIL 5)
  6) print DEVICE-SMOKE: PASS and exit 0; any failure prints DEVICE-SMOKE: FAIL <n> and exits nonzero

ASCII-only output (PS 5.1). Default -ApkPath resolves against the repo root.
#>
[CmdletBinding()]
param(
    [string]$ApkPath = "build\app\outputs\flutter-apk\app-debug.apk",
    [string]$PackageId = "com.mostafasayed.quranyahdi.debug"
)

$ErrorActionPreference = "Stop"

# The debug build carries the `.debug` applicationId suffix (REL-13). Pass
# -PackageId com.mostafasayed.quranyahdi when smoking the signed release APK.
$packageId = $PackageId
$component = "$PackageId/.MainActivity"

function Fail-Smoke {
    param([int]$Code, [string]$Message)
    Write-Output ("DEVICE-SMOKE: FAIL {0} ({1})" -f $Code, $Message)
    exit $Code
}

# 1) locate adb
$adb = $null
$sdkRoot = $env:ANDROID_SDK_ROOT
if (-not $sdkRoot) { $sdkRoot = $env:ANDROID_HOME }
if ($sdkRoot) {
    $fromSdk = Join-Path $sdkRoot "platform-tools\adb.exe"
    if (Test-Path -LiteralPath $fromSdk) { $adb = $fromSdk }
}
if (-not $adb) {
    $fromLocal = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
    if (Test-Path -LiteralPath $fromLocal) { $adb = $fromLocal }
}
if (-not $adb) { Fail-Smoke -Code 2 -Message "adb not found (ANDROID_SDK_ROOT/ANDROID_HOME/LOCALAPPDATA)" }
Write-Output ("adb: {0}" -f $adb)

# resolve apk path (relative paths resolve against the repo root = script parent's parent)
if (-not [System.IO.Path]::IsPathRooted($ApkPath)) {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $ApkPath = Join-Path $repoRoot $ApkPath
}
$apkExists = Test-Path -LiteralPath $ApkPath

# device must be attached (distinct message; install cannot proceed without it)
$deviceLines = @(& $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "\sdevice\s*$" })
if ($deviceLines.Count -eq 0) {
    Fail-Smoke -Code 3 -Message "no device attached (adb devices shows none in 'device' state)"
}
Write-Output ("device: {0}" -f ($deviceLines[0].Trim()))

if (-not $apkExists) { Fail-Smoke -Code 3 -Message ("apk not found: {0}" -f $ApkPath) }
$apkSize = (Get-Item -LiteralPath $ApkPath).Length
Write-Output ("apk: {0} ({1} bytes)" -f $ApkPath, $apkSize)

# 2) install
Write-Output "installing..."
$installOutput = @(& $adb install -r $ApkPath 2>&1)
$installText = ($installOutput | Out-String)
if (-not ($installText -match "Success")) {
    $trimmed = ($installText.Trim())
    Fail-Smoke -Code 3 -Message ("install did not print Success: {0}" -f $trimmed)
}
Write-Output "install: Success"

# 3) fresh logcat buffer, then launch
& $adb logcat -c | Out-Null
$startOutput = @(& $adb shell am start -n $component 2>&1)
$startText = ($startOutput | Out-String)
Write-Output ("launch: {0}" -f ($startText.Trim() -replace "\r?\n", " | "))

# 4) poll pidof up to 10s, 2s interval
$alive = $false
$pidText = ""
for ($i = 0; $i -lt 6; $i++) {
    $pidRaw = @(& $adb shell pidof $packageId 2>&1)
    $pidText = (($pidRaw | Out-String).Trim())
    if ($pidText -match "^\d+") { $alive = $true; break }
    if ($i -lt 5) { Start-Sleep -Seconds 2 }
}
if (-not $alive) {
    Fail-Smoke -Code 4 -Message ("process not alive within 10s (pidof output: '{0}'; am start: {1})" -f $pidText, ($startText.Trim() -replace "\r?\n", " | "))
}
Write-Output ("process: alive pid {0}" -f $pidText)

# 5) FATAL scan on the fresh buffer
$logcat = @(& $adb logcat -d 2>&1)
$fatal = @($logcat | Select-String -Pattern "FATAL EXCEPTION" -SimpleMatch)
if ($fatal.Count -gt 0) {
    $first = $fatal[0].Line.Trim()
    Fail-Smoke -Code 5 -Message ("FATAL EXCEPTION in fresh logcat: {0}" -f $first)
}

# 6) pass
Write-Output "DEVICE-SMOKE: PASS"
exit 0
