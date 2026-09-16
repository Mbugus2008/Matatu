# Where is the "debug log"? Check logcat + app-private storage + workspace logs.
param([string]$Serial = '59RWPRFE7LY5WCV8')
$ErrorActionPreference = 'Continue'

Write-Host '===== logcat: flutter / exceptions (last 4000 lines) ====='
$lc = adb -s $Serial logcat -d -t 4000 2>&1
"  logcat lines: {0}" -f $lc.Count
$lc | Where-Object { $_ -match 'flutter|Flutter|Exception|FATAL|E/|AssertionError|PopScope|trimline' } |
    Select-Object -Last 60 | ForEach-Object { "  $($_.Trim().Substring(0, [Math]::Min(260, $_.Trim().Length)))" }

Write-Host "`n===== is CityHoppa installed / recently run? ====="
adb -s $Serial shell "dumpsys package trimline.citihoppa | grep -E 'versionName|lastUpdateTime|firstInstallTime'" 2>&1 | ForEach-Object { "  $($_.Trim())" }
Write-Host '  --- external data dirs for citihoppa ---'
adb -s $Serial shell "ls -la /sdcard/Android/data/ 2>/dev/null | grep -i citihoppa" 2>&1 | ForEach-Object { "  $($_.Trim())" }

Write-Host "`n===== app-private files (needs a debuggable build) ====="
adb -s $Serial shell "run-as trimline.citihoppa ls -R /data/data/trimline.citihoppa/files 2>&1 | head -40" 2>&1 | ForEach-Object { "  $($_.Trim())" }

Write-Host "`n===== log-like files in the workspace =====\n"
Get-ChildItem 'd:\Projects2\Matatu' -Recurse -File -Include *.log -Depth 4 -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\build\\|\\\.dart_tool\\|\\android\\\.gradle\\' } |
    Sort-Object LastWriteTime -Descending | Select-Object -First 15 |
    ForEach-Object { "  {0,10}  {1}  {2}" -f $_.Length, $_.LastWriteTime.ToString('MM-dd HH:mm'), $_.FullName }
Write-Host 'DONE'
