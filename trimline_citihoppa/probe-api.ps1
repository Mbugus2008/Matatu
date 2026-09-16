# Probe the Matatu API across candidate hosts.
param(
    [string]$Base = 'http://services.trimline.co.ke:8092/api/Matatu/',
    [string[]]$Endpoint = @('agents'),
    [string]$Client = 'CITYHOPPER'
)

$headers = @{
    'Content-Type'        = 'application/json'
    'X-Client-Identifier' = $Client
    'X-Api-Key'           = 'gbsQcaCncEKpIIOn45tnpsynuAwW+sXvNhFl2ynk9+s='
}

if (-not $Base.EndsWith('/')) { $Base += '/' }

foreach ($e in $Endpoint) {
    $uri = "$Base$e"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $r = Invoke-WebRequest -Uri $uri -Method Post -Body '{}' -Headers $headers `
            -UseBasicParsing -TimeoutSec 40
        $sw.Stop()
        $body = ($r.Content -replace '\s+', ' ')
        $code = '?'; $count = '?'
        try {
            $j = $r.Content | ConvertFrom-Json
            $code = $j.Code
            if ($null -ne $j.Contents) {
                $count = @($j.Contents).Count
            }
        } catch { }
        $preview = if ($body.Length -gt 180) { $body.Substring(0, 180) + '...' } else { $body }
        "{0,-16} HTTP {1}  Code={2,-3} items={3,-6} {4,6}ms  {5}" -f $e, $r.StatusCode, $code, $count, $sw.ElapsedMilliseconds, $preview
    } catch {
        $sw.Stop()
        $sc = $_.Exception.Response.StatusCode.value__
        $msg = ''
        if ($_.ErrorDetails) {
            $msg = ($_.ErrorDetails.Message -replace '\s+', ' ')
            if ($msg.Length -gt 180) { $msg = $msg.Substring(0, 180) + '...' }
        }
        if (-not $msg) { $msg = $_.Exception.Message }
        "{0,-16} HTTP {1,-4} {2,6}ms  {3}" -f $e, $sc, $sw.ElapsedMilliseconds, $msg
    }
}
