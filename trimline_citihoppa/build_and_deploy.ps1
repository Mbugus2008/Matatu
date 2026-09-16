# build_and_deploy.ps1 - bump, build and publish a CityHoppa release to the
# app's self-update feed.
#
# Feed: https://main.trimline.co.ke:4016/  (IIS site "CityHoppaUpdates",
#       folder C:\Services\Matatu\Updates, Let's Encrypt certificate)
#
# The app compares the published 'version' with its own and only offers an
# update when the published one is strictly newer, so bump before deploying.
#
# Usage:
#   pwsh -File .\build_and_deploy.ps1 -Bump -ReleaseNotes "Fixed drawer layout"
#   pwsh -File .\build_and_deploy.ps1                    # redeploy current version
#   pwsh -File .\build_and_deploy.ps1 -SkipBuild         # upload the existing APK
#   pwsh -File .\build_and_deploy.ps1 -Abi armeabi-v7a   # publish the 32-bit build
#
# Notes:
#  - --split-per-abi keeps the payload ~20 MB instead of ~57 MB. Stay with one
#    style: split APKs get derived version codes (arm64 = 2000 + build number).
#  - Change PublicBaseUrl only if the feed host changes - it is baked into the
#    app, so existing installs keep polling the old URL until they update.

param(
    [switch]$Bump,
    [string]$Version = '',
    [int]$VersionCode = 0,
    [string]$ReleaseNotes = '',
    [string]$ReleaseNotesFile = '',
    [ValidateSet('arm64-v8a', 'armeabi-v7a', 'x86_64')][string]$Abi = 'arm64-v8a',
    [string]$PublicBaseUrl = 'https://main.trimline.co.ke:4016/',
    [string]$RemoteDirectory = 'C:\Services\Matatu\Updates',
    [string]$HostName = 'main.trimline.co.ke',
    [string]$User = 'Administrator',
    [string]$Pass = 'Touran2018',
    [switch]$SkipBuild,
    [switch]$SkipUpload
)

$ErrorActionPreference = 'Stop'

Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' CityHoppa build & deploy' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan

# ---------------------------------------------------------------- version ---
$pubspecPath = 'pubspec.yaml'
$pubspec = Get-Content $pubspecPath -Raw
$m = [regex]::Match($pubspec, 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)')
if (-not $m.Success) { throw "Could not find 'version: x.y.z+n' in $pubspecPath" }

$major = [int]$m.Groups[1].Value
$minor = [int]$m.Groups[2].Value
$patch = [int]$m.Groups[3].Value
$build = [int]$m.Groups[4].Value

if ($Bump) {
    $patch++
    $build++
    $newLine = "version: $major.$minor.$patch+$build"
    $pubspec = [regex]::Replace($pubspec, 'version:\s*\d+\.\d+\.\d+\+\d+', $newLine, 1)
    [IO.File]::WriteAllText((Resolve-Path $pubspecPath), $pubspec, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "bumped pubspec.yaml -> $newLine" -ForegroundColor Yellow
} elseif (-not [string]::IsNullOrWhiteSpace($Version)) {
    $patch = ($Version -split '\.')[-1]
    $major = ($Version -split '\.')[0]
    $minor = ($Version -split '\.')[1]
}

$versionName = "$major.$minor.$patch"
if ($VersionCode -gt 0) { $build = $VersionCode }
$apkFileName = "CityHoppa-v$versionName.apk"

Write-Host "publishing : $versionName (build $build) for $Abi"
Write-Host "feed       : $PublicBaseUrl"

# ------------------------------------------------------------- guard rails ---
try {
    $live = Invoke-RestMethod -Uri "${PublicBaseUrl}update.json" -TimeoutSec 20
    if ($live.version) {
        Write-Host "published  : $($live.version)" -ForegroundColor Yellow
        $liveParts = ($live.version -split '[^0-9]+' | Where-Object { $_ -ne '' }) -as [int[]]
        $newParts = ($versionName -split '[^0-9]+' | Where-Object { $_ -ne '' }) -as [int[]]
        $newer = $false
        for ($i = 0; $i -lt [Math]::Max($liveParts.Count, $newParts.Count); $i++) {
            $l = if ($i -lt $liveParts.Count) { $liveParts[$i] } else { 0 }
            $n = if ($i -lt $newParts.Count) { $newParts[$i] } else { 0 }
            if ($n -ne $l) { $newer = $n -gt $l; break }
        }
        if (-not $newer) {
            Write-Warning "$versionName is NOT newer than $($live.version) - installed apps will not be offered this release."
        }
    }
} catch {
    Write-Host "could not read the published update.json (skipping version check)" -ForegroundColor DarkYellow
}

# ------------------------------------------------------------------ build ---
$apkPath = "build\app\outputs\flutter-apk\app-$Abi-release.apk"
if (-not $SkipBuild) {
    Write-Host "`n[1/3] building release APK (split per ABI)..." -ForegroundColor Green
    flutter build apk --release --split-per-abi
    if ($LASTEXITCODE -ne 0) { throw 'build failed' }
} else {
    Write-Host "`n[1/3] skipping build" -ForegroundColor Yellow
}
if (-not (Test-Path $apkPath)) { throw "APK not found: $apkPath" }
$apkMb = [math]::Round((Get-Item $apkPath).Length / 1MB, 1)
Write-Host "      $apkFileName ($apkMb MB)" -ForegroundColor Green

# ------------------------------------------------------------ update.json ---
if ([string]::IsNullOrWhiteSpace($ReleaseNotes)) {
    if (-not [string]::IsNullOrWhiteSpace($ReleaseNotesFile) -and (Test-Path $ReleaseNotesFile)) {
        $ReleaseNotes = (Get-Content $ReleaseNotesFile -Raw).Trim()
    } elseif (Test-Path 'release_notes.md') {
        $ReleaseNotes = (Get-Content 'release_notes.md' -Raw).Trim()
    } else {
        $ReleaseNotes = "Version $versionName"
    }
}

Write-Host "`n[2/3] writing update.json..." -ForegroundColor Green
$updateJson = [ordered]@{
    version       = $versionName
    version_code  = $build
    apk_url       = "${PublicBaseUrl}$apkFileName"
    release_notes = $ReleaseNotes
    release_date  = (Get-Date -Format 'yyyy-MM-dd')
} | ConvertTo-Json -Depth 2

$updateJsonPath = 'build\update.json'
[IO.File]::WriteAllText((Join-Path (Get-Location) $updateJsonPath), $updateJson,
    (New-Object System.Text.UTF8Encoding($false)))
Write-Host $updateJson -ForegroundColor DarkGray

# ----------------------------------------------------------------- upload ---
if ($SkipUpload) {
    Write-Host "`n[3/3] skipping upload (files are in build\)" -ForegroundColor Yellow
    return
}

Write-Host "`n[3/3] uploading to ${HostName}:$RemoteDirectory" -ForegroundColor Green

# the APK is the big file - chunk it
pwsh -NoProfile -File (Join-Path $PSScriptRoot 'upload-chunked.ps1') `
    -LocalPath $apkPath `
    -RemoteDirectory $RemoteDirectory `
    -RemoteName $apkFileName `
    -HostName $HostName -User $User -Pass $Pass -ChunkMB 8 -Parallel 3
if ($LASTEXITCODE -ne 0) { throw 'APK upload failed' }

# update.json is tiny - a plain session copy is enough
$cred = New-Object PSCredential($User, (ConvertTo-SecureString $Pass -AsPlainText -Force))
$opts = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
$sess = New-PSSession -ComputerName $HostName -Credential $cred -UseSSL -SessionOption $opts
try {
    Copy-Item -Path $updateJsonPath -Destination "$RemoteDirectory\update.json" -ToSession $sess -Force
} finally {
    Remove-PSSession $sess
}
Write-Host 'update.json uploaded' -ForegroundColor Green

# ----------------------------------------------------------------- verify ---
Write-Host "`n=== verifying $PublicBaseUrl ===" -ForegroundColor Cyan
$pub = Invoke-WebRequest -Uri "${PublicBaseUrl}update.json" -UseBasicParsing -TimeoutSec 25
Write-Host "update.json -> HTTP $($pub.StatusCode)"
Write-Host $pub.Content -ForegroundColor DarkGray
$head = Invoke-WebRequest -Uri "${PublicBaseUrl}$apkFileName" -Method Head -UseBasicParsing -TimeoutSec 40
$len = [int]($head.Headers['Content-Length'] | Select-Object -First 1)
Write-Host ("apk -> HTTP {0}, {1:n1} MB" -f $head.StatusCode, ($len / 1MB)) -ForegroundColor Green

Write-Host "`nDone - $versionName is live." -ForegroundColor Cyan
Write-Host "Devices on an older release will be offered it on their next check." -ForegroundColor Cyan
Write-Host "Remember: installs older than 1.0.18 are signed with a different key and need one reinstall." -ForegroundColor DarkYellow
