# Full endpoint sweep for RemboClassic via the (moved) nav name.
# Read-only endpoints only - never POST to mutating ones with dummy bodies.
param(
    [string]$Base = 'http://nav.trimline.co.ke:4010/Test/api/Matatu/',
    [string]$Client = 'REMBOCLASIC'
)
$ErrorActionPreference = 'Continue'
if (-not $Base.EndsWith('/')) { $Base += '/' }

$hdr = @{
    'Content-Type'        = 'application/json'
    'X-Client-Identifier' = $Client
    'X-Api-Key'           = 'gbsQcaCncEKpIIOn45tnpsynuAwW+sXvNhFl2ynk9+s='
}
$today = (Get-Date).ToString('yyyy-MM-dd')

# endpoint -> body   (read-only)
$tests = [ordered]@{
    'TransactionDate'     = '""'
    'agents'              = '{}'
    'members'             = '{}'
    'vehicles'            = '{}'
    'transtypes'          = '{}'
    'transtypesamounts'   = '{}'
    'expenses'            = '{}'
    'Hires'               = '{}'
    'GetReversals'        = '{}'
    'vehiclecrew'         = '{}'
    'NRODefects'          = '{}'
    'routes'              = '{}'
    'waybills'            = ('{"date":"' + $today + '"}')
    'getdepotdata'        = ('{"date":"' + $today + '"}')
    'gettodayvehicletrans' = ('{"date":"' + $today + '"}')
    'getvehicletrans'     = ('{"date":"' + $today + '"}')
    'Dailytrans'          = ('{"date":"' + $today + '"}')
    'transheader'         = ('{"date":"' + $today + '"}')
    'transactions'        = ('{"date":"' + $today + '"}')
    'disFuelSummary'      = ('{"date":"' + $today + '"}')
}

Write-Host "===== $Base  (X-Client-Identifier: $Client) ====="
$ok = 0; $bad = 0
foreach ($e in $tests.Keys) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $r = Invoke-WebRequest -Uri "$Base$e" -Method Post -Body $tests[$e] -Headers $hdr -UseBasicParsing -TimeoutSec 120
        $sw.Stop()
        $j = $r.Content | ConvertFrom-Json
        $n = if ($null -ne $j.Contents) { @($j.Contents).Count } else { 0 }
        if ($j.Code -eq 0) { $ok++; $mark = 'OK  ' } else { $bad++; $mark = 'FAIL' }
        "  {0} {1,-22} Code={2,-3} items={3,-6} {4,6}ms  {5}" -f $mark, $e, $j.Code, $n, $sw.ElapsedMilliseconds, $j.Desc
    } catch {
        $sw.Stop(); $bad++
        "  FAIL {0,-22} {1,6}ms  {2}" -f $e, $sw.ElapsedMilliseconds, $_.Exception.Message
    }
}
Write-Host "`n  => $ok OK, $bad failed"
Write-Host 'DONE'
