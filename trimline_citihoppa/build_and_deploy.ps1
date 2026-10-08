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
#   pwsh -File .\build_and_deploy.ps1 -SkipBuild         # upload the existing APKs
#   pwsh -File .\build_and_deploy.ps1 -No32Bit -NoX64    # publish only the arm64 APK
#
# Notes:
#  - --split-per-abi keeps each payload ~20 MB instead of ~57 MB for one fat
#    APK. Split APKs get derived version codes (arm32 = 1000 + build,
#    arm64 = 2000 + build, x64 = 4000 + build) and every release publishes
#    all three: arm64 as the main apk_url, armeabi-v7a as apk_url_32 and
#    x86_64 as apk_url_x64. The app stays in the family it was installed
#    with (UpdateController.apkFor), so never publish a split build under a
#    plain version code - devices on one style can never install the other.
#  - Change PublicBaseUrl only if the feed host changes - it is baked into the
#    app, so existing installs keep polling the old URL until they update.

param(
    [switch]$Bump,
    [string]$Version = '',
    [int]$VersionCode = 0,
    [string]$ReleaseNotes = '',
    [string]$ReleaseNotesFile = '',
    [switch]$No32Bit,
    [switch]$NoX64,
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
$apk32FileName = "CityHoppa-v$versionName-32bit.apk"
$apkX64FileName = "CityHoppa-v$versionName-x64.apk"

Write-Host "publishing : $versionName (build $build) for arm64$(if (-not $No32Bit) { ' + arm32' })$(if (-not $NoX64) { ' + x64' })"
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
$apkPath = 'build\app\outputs\flutter-apk\app-arm64-v8a-release.apk'
$apk32Path = 'build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk'
$apkX64Path = 'build\app\outputs\flutter-apk\app-x86_64-release.apk'
if (-not $SkipBuild) {
    Write-Host "`n[1/3] building release APK (split per ABI)..." -ForegroundColor Green
    flutter build apk --release --split-per-abi
    if ($LASTEXITCODE -ne 0) { throw 'build failed' }
} else {
    Write-Host "`n[1/3] skipping build" -ForegroundColor Yellow
}
if (-not (Test-Path $apkPath)) { throw "APK not found: $apkPath" }
# Hashes go into update.json so the app can verify a downloaded copy before
# offering it to the installer (an interrupted download must never install).
$apkHash = (Get-FileHash -Path $apkPath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "      $apkFileName ($([math]::Round((Get-Item $apkPath).Length / 1MB, 1)) MB)" -ForegroundColor Green

$apk32Hash = ''
if (-not $No32Bit) {
    if (-not (Test-Path $apk32Path)) { throw "APK not found: $apk32Path" }
    $apk32Hash = (Get-FileHash -Path $apk32Path -Algorithm SHA256).Hash.ToLowerInvariant()
    Write-Host "      $apk32FileName ($([math]::Round((Get-Item $apk32Path).Length / 1MB, 1)) MB)" -ForegroundColor Green
}

$apkX64Hash = ''
if (-not $NoX64) {
    if (-not (Test-Path $apkX64Path)) { throw "APK not found: $apkX64Path" }
    $apkX64Hash = (Get-FileHash -Path $apkX64Path -Algorithm SHA256).Hash.ToLowerInvariant()
    Write-Host "      $apkX64FileName ($([math]::Round((Get-Item $apkX64Path).Length / 1MB, 1)) MB)" -ForegroundColor Green
}

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
$feed = [ordered]@{
    version      = $versionName
    version_code = $build
    apk_url      = "${PublicBaseUrl}$apkFileName"
    sha256       = $apkHash
}
if (-not $No32Bit) {
    $feed['apk_url_32'] = "${PublicBaseUrl}$apk32FileName"
    $feed['sha256_32'] = $apk32Hash
}
if (-not $NoX64) {
    $feed['apk_url_x64'] = "${PublicBaseUrl}$apkX64FileName"
    $feed['sha256_x64'] = $apkX64Hash
}
$feed['release_notes'] = $ReleaseNotes
$feed['release_date'] = (Get-Date -Format 'yyyy-MM-dd')
$updateJson = $feed | ConvertTo-Json -Depth 2

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

if (-not $No32Bit) {
    pwsh -NoProfile -File (Join-Path $PSScriptRoot 'upload-chunked.ps1') `
        -LocalPath $apk32Path `
        -RemoteDirectory $RemoteDirectory `
        -RemoteName $apk32FileName `
        -HostName $HostName -User $User -Pass $Pass -ChunkMB 8 -Parallel 3
    if ($LASTEXITCODE -ne 0) { throw '32-bit APK upload failed' }
}

if (-not $NoX64) {
    pwsh -NoProfile -File (Join-Path $PSScriptRoot 'upload-chunked.ps1') `
        -LocalPath $apkX64Path `
        -RemoteDirectory $RemoteDirectory `
        -RemoteName $apkX64FileName `
        -HostName $HostName -User $User -Pass $Pass -ChunkMB 8 -Parallel 3
    if ($LASTEXITCODE -ne 0) { throw 'x64 APK upload failed' }
}

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
if (-not $No32Bit) {
    $head32 = Invoke-WebRequest -Uri "${PublicBaseUrl}$apk32FileName" -Method Head -UseBasicParsing -TimeoutSec 40
    $len32 = [int]($head32.Headers['Content-Length'] | Select-Object -First 1)
    Write-Host ("apk 32-bit -> HTTP {0}, {1:n1} MB" -f $head32.StatusCode, ($len32 / 1MB)) -ForegroundColor Green
}
if (-not $NoX64) {
    $headX64 = Invoke-WebRequest -Uri "${PublicBaseUrl}$apkX64FileName" -Method Head -UseBasicParsing -TimeoutSec 40
    $lenX64 = [int]($headX64.Headers['Content-Length'] | Select-Object -First 1)
    Write-Host ("apk x64 -> HTTP {0}, {1:n1} MB" -f $headX64.StatusCode, ($lenX64 / 1MB)) -ForegroundColor Green
}

Write-Host "`nDone - $versionName is live." -ForegroundColor Cyan
if (-not $No32Bit) { Write-Host "32-bit APK: ${PublicBaseUrl}$apk32FileName" -ForegroundColor Cyan }
Write-Host "Devices on an older release will be offered it on their next check." -ForegroundColor Cyan
Write-Host "Remember: installs older than 1.0.18 are signed with a different key and need one reinstall." -ForegroundColor DarkYellow
