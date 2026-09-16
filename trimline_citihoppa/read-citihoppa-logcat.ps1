# CityHoppa debug build: read its logcat output and private storage.
param([string]$Serial = '59RWPRFE7LY5WCV8', [string]$Pkg = 'trimline.citihoppa')
$ErrorActionPreference = 'Continue'

Write-Host '===== is it running? ====='
$pid_ = (adb -s $Serial shell "pidof $Pkg" 2>&1) -join ''
"  pidof: '$($pid_.Trim())'"

Write-Host "`n===== logcat for the app (whole buffer, this pid) ====="
if ($pid_.Trim()) {
    $out = adb -s $Serial logcat -d --pid=$($pid_.Trim()) 2>&1
    "  lines: {0}" -f $out.Count
    Write-Host '  --- exception / error lines ---'
    $out | Where-Object { $_ -match 'EXCEPTION|Exception|Unhandled|Error|error|assert|Failed|═|╞' } |
        Select-Object -Last 80 | ForEach-Object { "  $($_.Trim().Substring(0, [Math]::Min(300, $_.Trim().Length)))" }
    Write-Host '  --- last 30 raw lines ---'
    $out | Select-Object -Last 30 | ForEach-Object { "  $($_.Trim().Substring(0, [Math]::Min(300, $_.Trim().Length)))" }
} else {
    Write-Host '  app not running - nothing in the pid buffer'
}

Write-Host "`n===== flutter-tagged logcat (whole buffer) ====="
$fl = adb -s $Serial logcat -d -s flutter 2>&1
"  lines: {0}" -f $fl.Count
$fl | Select-Object -Last 60 | ForEach-Object { "  $($_.Trim().Substring(0, [Math]::Min(300, $_.Trim().Length)))" }

Write-Host "`n===== private storage tree ====="
foreach ($d in '/data/data/trimline.citihoppa/files', '/data/data/trimline.citihoppa/databases', '/data/data/trimline.citihoppa/cache') {
    "  --- $d ---"
    adb -s $Serial shell "run-as $Pkg ls -la $d 2>&1" 2>&1 | ForEach-Object { "    $($_.Trim())" }
}
Write-Host 'DONE'
