# Pull embedded strings (URLs) out of an APK's Dart AOT snapshot.
param(
    [string]$Apk = 'C:\Users\mbugu\OneDrive\Desktop\RemboClassic-v1.0.15.apk',
    [string[]]$Patterns = @('http://', 'https://')
)
$ErrorActionPreference = 'Continue'

if (-not (Test-Path $Apk)) { Write-Host "NOT FOUND: $Apk"; exit 1 }
"APK : $Apk"
"Size: {0:N0} bytes" -f (Get-Item $Apk).Length

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($Apk)

Write-Host "`n===== entries of interest ====="
$entries = $zip.Entries | Where-Object { $_.FullName -match 'libapp\.so|flutter_assets/(AssetManifest|kernel_blob|NOTICES)|\.json$' }
$entries | ForEach-Object { "  {0,-52} {1,12:N0}" -f $_.FullName, $_.Length }

function Get-StringsFromEntry($entry) {
    $ms = New-Object System.IO.MemoryStream
    $s = $entry.Open()
    $s.CopyTo($ms)
    $s.Close()
    $bytes = $ms.ToArray()
    $ms.Dispose()
    # Latin1 keeps a 1:1 byte->char mapping so ASCII runs survive
    $text = [System.Text.Encoding]::GetEncoding(28591).GetString($bytes)
    $text = [regex]::Replace($text, '[^\x20-\x7E]', "`n")
    return $text -split "`n"
}

foreach ($e in $entries) {
    if ($e.Length -gt 200MB) { continue }
    Write-Host "`n===== scanning $($e.FullName) ====="
    $lines = Get-StringsFromEntry $e
    $hits = $lines | Where-Object {
        $l = $_
        if ($l.Length -lt 8 -or $l.Length -gt 300) { return $false }
        $found = $false
        foreach ($p in $Patterns) { if ($l.Contains($p)) { $found = $true; break } }
        $found
    }
    if (-not $hits) { Write-Host '  (no URL strings)' ; continue }
    $hits | Sort-Object -Unique | ForEach-Object { "  $_" }
}

$zip.Dispose()
Write-Host "`nDONE"
