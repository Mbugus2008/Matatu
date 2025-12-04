@echo off
setlocal enabledelayedexpansion

echo ========================================
echo CityHoppa Build and Deploy
echo ========================================

REM Get version from pubspec.yaml
for /f "tokens=2 delims=: " %%a in ('findstr /r "^version:" pubspec.yaml') do set VERSION_FULL=%%a
for /f "tokens=1 delims=+" %%a in ("%VERSION_FULL%") do set VERSION=%%a

echo Version: %VERSION%

REM Build release APK
echo.
echo [1/3] Building release APK...
call flutter build apk --release
if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

REM Create update.json
echo.
echo [2/3] Creating update.json...
set APK_NAME=CityHoppa-v%VERSION%.apk

(
echo {
echo   "version": "%VERSION%",
echo   "apk_url": "https://trimline.co.ke/apps/CityHoppa/%APK_NAME%",
echo   "release_notes": "Version %VERSION%",
echo   "release_date": "%date:~10,4%-%date:~4,2%-%date:~7,2%"
echo }
) > build\update.json

echo update.json created

REM Copy APK with version name
echo.
echo [3/3] Preparing files...
copy /Y "build\app\outputs\flutter-apk\app-release.apk" "build\%APK_NAME%"

echo.
echo ========================================
echo Files ready for upload:
echo   build\%APK_NAME%
echo   build\update.json
echo.
echo Upload to: https://trimline.co.ke/apps/CityHoppa/
echo ========================================

pause
