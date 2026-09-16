# Extract the error block(s) from the Flutter debug console log.
param(
    [string]$Path = 'C:\tmp\debug-console-logs\flutter_debug.log',
    [int]$Blocks = 3,
    [int]$ContextLines = 30
)
$ErrorActionPreference = 'Continue'
if (-not (Test-Path $Path)) { Write-Host "not found: $Path"; exit 1 }

$lines = Get-Content $Path -ErrorAction SilentlyContinue
"file: $Path"
"lines: {0:N0}" -f $lines.Count

$patterns = 'EXCEPTION CAUGHT|Unhandled Exception|Exception:|Failed assertion|AssertionError|Another exception was thrown|The following .* was thrown|ERROR:flutter|FlutterError'
$hits = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match $patterns) { $hits += $i }
}
"error markers: {0}" -f $hits.Count

if ($hits.Count -eq 0) {
    Write-Host "`n===== last 60 lines ====="
    $lines | Select-Object -Last 60 | ForEach-Object { "  $_" }
    exit 0
}

$shown = $hits | Select-Object -Last $Blocks
foreach ($h in $shown) {
    Write-Host "`n==================== line $($h + 1) ===================="
    $end = [Math]::Min($h + $ContextLines, $lines.Count - 1)
    $lines[$h..$end] | ForEach-Object { "  $_" }
}

Write-Host "`n===== last 25 lines of the log ====="
$lines | Select-Object -Last 25 | ForEach-Object { "  $_" }
Write-Host 'DONE'
