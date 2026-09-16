# Does main's :4010 answer regardless of the hostname?  (simulates repointing nav DNS -> main)
$ErrorActionPreference = 'Continue'
$hdr = @{
    'Content-Type'        = 'application/json'
    'X-Client-Identifier' = 'REMBOCLASIC'
    'X-Api-Key'           = 'gbsQcaCncEKpIIOn45tnpsynuAwW+sXvNhFl2ynk9+s='
}

function Try-Probe([string]$uri, [string]$label) {
    try {
        $r = Invoke-WebRequest -Uri $uri -Method Post -Body '{}' -Headers $hdr -UseBasicParsing -TimeoutSec 60
        $j = $r.Content | ConvertFrom-Json
        "  {0,-40} HTTP {1}  Code={2,-3} items={3,-5} {4}" -f $label, $r.StatusCode, $j.Code, @($j.Contents).Count, $j.Desc
    } catch { "  {0,-40} FAIL {1}" -f $label, $_.Exception.Message }
}

Write-Host '===== by main IP (no Host header) ====='
Try-Probe 'http://51.89.234.110:4010/Test/api/Matatu/agents' 'main-IP  /Test/agents  (Rembo)'
Try-Probe 'http://51.89.234.110:4010/api/Matatu/agents'      'main-IP  ROOT /agents (KCS path)'

Write-Host "`n===== explicit Host: nav.trimline.co.ke (what a DNS repoint would send) ====="
$hc = New-Object System.Net.Http.HttpClient
$hc.Timeout = [TimeSpan]::FromSeconds(60)
foreach ($path in '/Test/api/Matatu/agents', '/api/Matatu/agents') {
    $req = New-Object System.Net.Http.HttpRequestMessage('POST', "http://51.89.234.110:4010$path")
    $req.Headers.Add('Host', 'nav.trimline.co.ke')
    $req.Headers.Add('X-Client-Identifier', 'REMBOCLASIC')
    $req.Headers.Add('X-Api-Key', 'gbsQcaCncEKpIIOn45tnpsynuAwW+sXvNhFl2ynk9+s=')
    $req.Content = New-Object System.Net.Http.StringContent('{}', [System.Text.Encoding]::UTF8, 'application/json')
    try {
        $resp = $hc.SendAsync($req).GetAwaiter().GetResult()
        $body = $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json
        "  Host=nav {0,-26} HTTP {1} Code={2,-3} items={3,-5} {4}" -f $path, [int]$resp.StatusCode, $body.Code, @($body.Contents).Count, $body.Desc
    } catch { "  Host=nav $path FAIL: $($_.Exception.Message)" }
}

Write-Host "`n===== what nav serves today (baseline) ====="
Try-Probe 'http://nav.trimline.co.ke:4010/Test/api/Matatu/agents' 'nav /Test/agents'
Try-Probe 'http://nav.trimline.co.ke:4010/api/Matatu/agents'      'nav ROOT /agents (KCS path)'

Write-Host "`n===== main's /Test web.config + which build serves the ROOT =====`n"
Write-Host 'DONE'
