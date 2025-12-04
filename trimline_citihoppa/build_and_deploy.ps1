# Build and Deploy Script for CityHoppa
# This script builds the release APK, uploads it to the server, and updates update.json

param(
    [string]$SftpHost = "trimline.co.ke",
    [string]$SftpUser = "Administrator",
    [string]$RemotePath = "D:/apps/CityHoppa/",
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

# Get version from pubspec.yaml
$pubspecPath = "pubspec.yaml"
$pubspecContent = Get-Content $pubspecPath -Raw
$versionMatch = [regex]::Match($pubspecContent, 'version:\s*(\d+\.\d+\.\d+)\+(\d+)')

if (-not $versionMatch.Success) {
    Write-Error "Could not find version in pubspec.yaml"
    exit 1
}

$versionName = $versionMatch.Groups[1].Value
$versionCode = $versionMatch.Groups[2].Value
$apkFileName = "CityHoppa-v$versionName.apk"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CityHoppa Build & Deploy" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Version: $versionName ($versionCode)" -ForegroundColor Yellow

# Step 1: Build Release APK
if (-not $SkipBuild) {
    Write-Host "`n[1/4] Building release APK..." -ForegroundColor Green
    flutter build apk --release
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed!"
        exit 1
    }
    Write-Host "Build successful!" -ForegroundColor Green
} else {
    Write-Host "`n[1/4] Skipping build (using existing APK)" -ForegroundColor Yellow
}

$apkSource = "build\app\outputs\flutter-apk\app-release.apk"

if (-not (Test-Path $apkSource)) {
    Write-Error "APK not found at: $apkSource"
    exit 1
}

# Step 2: Create update.json
Write-Host "`n[2/4] Creating update.json..." -ForegroundColor Green

# Release notes for this version
$releaseNotes = @"
Version $versionName
- Fixed Settings menu layout
- Fixed Check for Updates functionality
- Added Change Password feature
- Improved update notifications
"@

$updateJson = @{
    version = $versionName
    version_code = [int]$versionCode
    apk_url = "https://trimline.co.ke/apps/CityHoppa/$apkFileName"
    release_notes = $releaseNotes
    release_date = (Get-Date -Format "yyyy-MM-dd")
} | ConvertTo-Json -Depth 2

$updateJsonPath = "build\update.json"
$updateJson | Out-File -FilePath $updateJsonPath -Encoding UTF8
Write-Host "update.json created:" -ForegroundColor Green
Write-Host $updateJson

# Step 3: Copy APK with version name
Write-Host "`n[3/4] Preparing APK for upload..." -ForegroundColor Green
$apkDest = "build\$apkFileName"
Copy-Item $apkSource $apkDest -Force
Write-Host "APK copied to: $apkDest" -ForegroundColor Green

# Step 4: Upload files
Write-Host "`n[4/4] Uploading files to server..." -ForegroundColor Green

try {
    # Upload APK
    Write-Host "Uploading $apkFileName..." -ForegroundColor Yellow
    & scp "$apkDest" "Administrator@trimline.co.ke:D:/apps/CityHoppa/$apkFileName"
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to upload APK"
    }
    
    # Upload update.json
    Write-Host "Uploading update.json..." -ForegroundColor Yellow
    & scp "$updateJsonPath" "Administrator@trimline.co.ke:D:/apps/CityHoppa/update.json"
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to upload update.json"
    }
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "SUCCESS! Deployed version $versionName" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "APK URL: https://trimline.co.ke/apps/CityHoppa/$apkFileName" -ForegroundColor White
    Write-Host "Update URL: https://trimline.co.ke/apps/CityHoppa/update.json" -ForegroundColor White
    
} catch {
    Write-Host "`nUpload failed: $_" -ForegroundColor Red
    Write-Host "`nManual upload instructions:" -ForegroundColor Yellow
    Write-Host "  scp `"$apkDest`" Administrator@trimline.co.ke:D:/apps/CityHoppa/" -ForegroundColor White
    Write-Host "  scp `"$updateJsonPath`" Administrator@trimline.co.ke:D:/apps/CityHoppa/" -ForegroundColor White
}

Write-Host "`nDone! Version $versionName deployment complete." -ForegroundColor Green
