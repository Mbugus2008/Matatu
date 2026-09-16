param(
    [string]$Apk = 'C:\Users\mbugu\OneDrive\Desktop\RemboClassic-v1.0.15.apk',
    [string]$Entry = 'lib/arm64-v8a/libapp.so',
    [string]$Match = 'REMBOCLASIC|REMBOCLASSIC|REMBO CLASSIC|clientId'
)
$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$zip = [System.IO.Compression.ZipFile]::OpenRead($Apk)
$e = $zip.Entries | Where-Object { $_.FullName -eq $Entry }
if (-not $e) { Write-Host "entry not found: $Entry"; $zip.Dispose(); exit 1 }

$ms = New-Object System.IO.MemoryStream
$s = $e.Open(); $s.CopyTo($ms); $s.Close()
$bytes = $ms.ToArray(); $ms.Dispose(); $zip.Dispose()

$text = [System.Text.Encoding]::GetEncoding(28591).GetString($bytes)
$text = [regex]::Replace($text, '[^\x20-\x7E]', [string][char]10)

Write-Host "=== lines in $Entry matching '$Match' ==="
($text -split [string][char]10) |
    Where-Object { $_ -match $Match -and $_.Length -lt 200 } |
    Sort-Object -Unique | Select-Object -First 20 | ForEach-Object { "  $_" }
Write-Host 'DONE'
