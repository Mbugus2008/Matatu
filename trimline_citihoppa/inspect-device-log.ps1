# Inspect the pulled device log format and search it robustly.
param([string]$Path = "$env:TEMP\2026-09-15.log")
$ErrorActionPreference = 'Continue'

$bytes = [System.IO.File]::ReadAllBytes($Path)
"bytes: {0:N0}" -f $bytes.Length
"first 16 bytes (hex): {0}" -f (($bytes[0..15] | ForEach-Object { $_.ToString('X2') }) -join ' ')

# Try UTF8 then Latin1
$utf8 = [System.Text.Encoding]::UTF8.GetString($bytes)
$lat1 = [System.Text.Encoding]::GetEncoding(28591).GetString($bytes)
$text = if (($utf8.ToCharArray() | Where-Object { $_ -eq [char]0xFFFD }).Count -gt 50) { $lat1 } else { $utf8 }

$norm = $text -replace "`r`n", "`n" -replace "`r", "`n"
$lines = $norm -split "`n"
"lines: {0:N0}" -f $lines.Count

Write-Host "`n===== first 12 lines ====="
$lines | Select-Object -First 12 | ForEach-Object { "  $($_.Trim())" }

Write-Host "`n===== last 12 lines ====="
$lines | Select-Object -Last 12 | ForEach-Object { "  $($_.Trim())" }

Write-Host "`n===== keyword counts ====="
foreach ($k in 'DISPATCH', 'setdepot', 'depot', 'dispatch', 'Failed', 'error', 'Error', 'Exception') {
    $c = ($lines | Where-Object { $_ -like "*$k*" }).Count
    "  {0,-12} {1}" -f $k, $c
}

Write-Host "`n===== any line mentioning depot/dispatch/save ====="
$lines | Where-Object { $_ -match 'depot|dispatch|save|Save' } | Select-Object -Last 30 | ForEach-Object { "  $($_.Trim())" }
Write-Host 'DONE'
