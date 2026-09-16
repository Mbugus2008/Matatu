# Pull the newest app log from the device and surface errors (force re-pull).
param(
    [string]$Serial = '59RWPRFE7LY5WCV8',
    [string]$Dir = '/storage/emulated/0/Documents/Mbranch'
)
$ErrorActionPreference = 'Continue'

Write-Host '===== newest log files on device ====='
$listing = adb -s $Serial shell "ls -la $Dir" 2>&1
$listing | Where-Object { $_ -match '\.log' } | ForEach-Object { "  $($_.Trim())" }

# pick newest .log by name/date
$files = ($listing | Where-Object { $_ -match '(\d{4}-\d{2}-\d{2})\.log' } |
    ForEach-Object { [regex]::Match($_, '(\d{4}-\d{2}-\d{2})\.log').Groups[1].Value } |
    Sort-Object -Unique)
if (-not $files) { Write-Host 'no log files found'; exit 1 }
$newest = ($files | Sort-Object | Select-Object -Last 1)
"newest: $newest"

$local = "$env:TEMP\chk-$newest.log"
Remove-Item $local -ErrorAction SilentlyContinue
adb -s $Serial pull "$Dir/$newest.log" $local 2>&1 | Out-Null
if (-not (Test-Path $local)) { Write-Host 'pull failed'; exit 1 }
"pulled: {0}  ({1:N0} bytes)" -f $local, (Get-Item $local).Length

$bytes = [System.IO.File]::ReadAllBytes($local)
$text = [System.Text.Encoding]::UTF8.GetString($bytes)
$text = $text -replace "`r`n", "`n" -replace "`r", "`n"
$lines = $text -split "`n"
"lines: {0:N0}" -f $lines.Count

Write-Host "`n===== keyword counts ====="
foreach ($k in 'Exception', 'ERROR', 'Error', 'error', 'FlutterError', 'assert',
               'DISPATCH', 'depot', 'depotdata', 'Unsaved', 'PopScope', 'CITYHOPPER', 'REMBOCLASIC') {
    $c = ($lines | Where-Object { $_ -like "*$k*" }).Count
    "  {0,-14} {1}" -f $k, $c
}

Write-Host "`n===== error-ish lines (last 40) ====="
$lines | Where-Object { $_ -match 'Exception|ERROR|FlutterError|assert|Failed|failed|not working' } |
    Select-Object -Last 40 | ForEach-Object { "  $($_.Trim().Substring(0, [Math]::Min(300, $_.Trim().Length)))" }

Write-Host "`n===== dispatch/depot related (last 30) ====="
$lines | Where-Object { $_ -match 'depot|dispatch|Unsaved|PopScope' } |
    Select-Object -Last 30 | ForEach-Object { "  $($_.Trim().Substring(0, [Math]::Min(300, $_.Trim().Length)))" }

Write-Host "`n===== last 15 lines ====="
$lines | Select-Object -Last 15 | ForEach-Object { "  $($_.Trim().Substring(0, [Math]::Min(300, $_.Trim().Length)))" }
Write-Host 'DONE'
