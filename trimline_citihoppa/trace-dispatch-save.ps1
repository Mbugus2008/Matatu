# Trace the dispatch save in the Flutter debug console log.
param(
    [string]$Path = 'C:\tmp\debug-console-logs\flutter_debug.log',
    [int]$ErrorLine = 3132
)
$ErrorActionPreference = 'Continue'
$lines = Get-Content $Path

Write-Host '===== API calls mentioning depot (last 30) ====='
$hits = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match 'depot') { $hits += $i }
}
"  matches: {0}" -f $hits.Count
$hits | Select-Object -Last 30 | ForEach-Object { "  [{0}] {1}" -f ($_ + 1), $lines[$_].Trim().Substring(0, [Math]::Min(230, $lines[$_].Trim().Length)) }

Write-Host "`n===== 60 lines before the 'No Overlay' exception (line $ErrorLine) ====="
$start = [Math]::Max(0, $ErrorLine - 62)
$lines[$start..($ErrorLine - 1)] | ForEach-Object { "  $($_.Trim().Substring(0, [Math]::Min(230, $_.Trim().Length)))" }

Write-Host "`n===== any 'setdepot' / 'Saved' / 'Nothing to save' lines ====="
$lines | Where-Object { $_ -match 'setdepot|Saved|Nothing to save|Check these vehicles|setdepotdatabatch' } |
    Select-Object -Last 20 | ForEach-Object { "  $($_.Trim().Substring(0, [Math]::Min(250, $_.Trim().Length)))" }
Write-Host 'DONE'
