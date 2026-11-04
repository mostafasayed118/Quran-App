# Builds the shipped adhan audio from the 128k source masters.
#
# For every <id>.m4a in the master directory this writes three files:
#   assets/audio/adhan/<id>.m4a             full adhan, 64 kbit/s mono AAC
#   assets/audio/adhan/clips/<id>_clip.m4a  first 25 s + 2 s fade, same encoding
#   android/app/src/main/res/raw/<id>_clip.m4a  copy of the clip for the
#                                               notification channel sound
#
# Mono at 64k is the spec's ruling (D1): the sources are 128k stereo, and a
# constant bitrate can only shrink by re-encoding, so 64k mono is ~half the
# size with better quality per bit for a single voice.
#
# Idempotent: re-running overwrites the generated files. Requires ffmpeg on
# PATH (verified by the script before it does anything).
#
# Usage:  pwsh -File tools/build_adhan_audio.ps1 [-MasterDir <dir>]

param(
    [string]$MasterDir = "_adhan_masters"
)

$ErrorActionPreference = "Stop"

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpeg) {
    throw "ffmpeg not found on PATH; install it before building the adhan audio."
}

if (-not (Test-Path $MasterDir)) {
    throw "Master directory '$MasterDir' not found. It holds the 128k originals named <id>.m4a."
}

$roots = @(
    "assets/audio/adhan",
    "assets/audio/adhan/clips",
    "android/app/src/main/res/raw"
)
foreach ($root in $roots) {
    New-Item -ItemType Directory -Force -Path $root | Out-Null
}

$masterFiles = Get-ChildItem -Path $MasterDir -File -Filter "*.m4a" | Sort-Object Name
if ($masterFiles.Count -eq 0) {
    throw "No <id>.m4a masters found in '$MasterDir'."
}

$built = 0
foreach ($file in $masterFiles) {
    $id = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)

    # Android raw resource names must be lowercase [a-z0-9_]; the catalog ids
    # already are, so a bad name is a hard error rather than a silent skip.
    if ($id -notmatch '^[a-z][a-z0-9_]*$') {
        throw "Master '$($file.Name)' does not resolve to a valid id (got '$id')."
    }

    $full = "assets/audio/adhan/$id.m4a"
    $clip = "assets/audio/adhan/clips/${id}_clip.m4a"
    $raw = "android/app/src/main/res/raw/${id}_clip.m4a"

    & $ffmpeg.Source -y -nostdin -hide_banner -loglevel error `
        -i $file.FullName `
        -ac 1 -ar 44100 -c:a aac -b:a 64k -movflags +faststart `
        $full
    if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed for the full file of '$id'." }

    & $ffmpeg.Source -y -nostdin -hide_banner -loglevel error `
        -i $file.FullName -t 25 -af "afade=t=out:st=23:d=2" `
        -ac 1 -ar 44100 -c:a aac -b:a 64k -movflags +faststart `
        $clip
    if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed for the clip of '$id'." }

    Copy-Item -LiteralPath $clip -Destination $raw -Force

    $mb = [math]::Round((Get-Item $full).Length / 1MB, 2)
    Write-Output ("  {0,-24} full={1,6} MB" -f $id, $mb)
    $built = $built + 1
}

Write-Output ""
Write-Output "Built $built adhan(s): $built full + $built clip + $built raw resource."
