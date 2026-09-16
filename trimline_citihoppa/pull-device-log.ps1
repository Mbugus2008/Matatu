# Pull today's app log from the device and surface dispatch/save failures.
param(
    [string]$Date = (Get-Date).ToString('yyyy-MM-dd'),
    [string]$Serial = '59RWPRFE7LY5WCV8'
)
$ErrorActionPreference = 'Continue'
$remote = "/storage/emulated/0/Documents/Mbranch/$Date.log"
$local  = "$env:TEMP\$Date.log"

if (-not (Test-Path $local) -or ((Get-Item $local -ErrorAction SilentlyContinue).Length -eq 0)) {
    adb -s $Serial pull $remote $local 2>&1 | Out-String | Write-Host
}
if (-not (Test-Path $local)) { Write-Host "log not found locally"; exit 1 }
"pulled: {0}  ({1:N0} bytes)" -f $local, (Get-Item $local).Length

Write-Host "`n===== lines mentioning dispatch / depot save ====="
Select-String -Path $local -Pattern 'DISPATCH|setdepotdata|Failed to update|Server error|batch sending|batch failed' -ErrorAction SilentlyContinue |
    Select-Object -Last 40 | ForEach-Object { "  $($_.LineNumber): $($_.Line.Trim())" }

Write-Host "`n===== last 25 error-ish lines ====="
Select-String -Path $local -Pattern 'ERROR|Error|error|Exception|Exception' -ErrorAction SilentlyContinue |
    Select-Object -Last 25 | ForEach-Object { "  $($_.LineNumber): $($_.Line.Trim())" }
Write-Host 'DONE'
