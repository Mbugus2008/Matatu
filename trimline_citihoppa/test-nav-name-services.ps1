# Post-DNS-move: TTL/propagation + the non-API services that nav.trimline.co.ke used to serve.
$ErrorActionPreference = 'Continue'

Write-Host '===== DNS record + TTL ====='
Resolve-DnsName 'nav.trimline.co.ke' -Type A -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress } | ForEach-Object { "  answer: $($_.IPAddress)  TTL=$($_.TTL)s" }
Write-Host '  --- what public resolvers see ---'
foreach ($srv in '8.8.8.8', '1.1.1.1') {
    try {
        $a = (Resolve-DnsName 'nav.trimline.co.ke' -Type A -Server $srv -ErrorAction Stop | Where-Object IPAddress | ForEach-Object { $_.IPAddress }) -join ', '
        "  {0,-9} -> {1}" -f $srv, $a
    } catch { "  {0,-9} -> query failed" -f $srv }
}

Write-Host "`n===== BC web client paths on https://nav.trimline.co.ke (main now answers) ====="
foreach ($p in '/', '/BC140/', '/BC240/', '/kirigiti/') {
    $code = curl.exe -s -o NUL -w "%{http_code}" -k -L --max-time 30 "https://nav.trimline.co.ke$p"
    "  {0,-12} -> HTTP {1}" -f $p, $code
}

Write-Host "`n===== other nav services (ports) ====="
foreach ($p in 4011, 4012, 4013, 4014) {
    $code = curl.exe -s -o NUL -w "%{http_code}" --max-time 20 "http://nav.trimline.co.ke:$p/"
    "  http://nav.trimline.co.ke:{0} -> HTTP {1}" -f $p, $code
}

Write-Host "`n===== every wrapper app clientId (to test each client's path) ====="
Get-ChildItem 'd:\Projects2\Matatu' -Directory -Filter 'trimline_*' | ForEach-Object {
    $m = Join-Path $_.FullName 'lib\main.dart'
    if (Test-Path $m) {
        $id = (Select-String -Path $m -Pattern 'clientId:' | Select-Object -First 1).Line
        $url = (Select-String -Path $m -Pattern 'apiBaseUrl:' | Select-Object -First 1).Line
        "  {0,-24} {1,-28} {2}" -f $_.Name, ($id -replace '\s+', ' ').Trim(), ($url -replace '\s+', ' ').Trim()
    }
}

Write-Host "`n===== sweep each client id against nav:4010 (root and /Test) ====="
foreach ($cid in 'REMBOCLASIC', 'KC-SHUTTLE', 'KMOS_SACCO', 'LOPHA_SACCO', 'CITYHOPPER') {
    foreach ($base in 'http://nav.trimline.co.ke:4010/Test/api/Matatu/', 'http://nav.trimline.co.ke:4010/api/Matatu/') {
        $out = curl.exe -s -X POST -H "X-Client-Identifier: $cid" -H "X-Api-Key: gbsQcaCncEKpIIOn45tnpsynuAwW+sXvNhFl2ynk9+s=" -H "Content-Type: application/json" -d "{}" --max-time 90 "${base}agents"
        try { $j = $out | ConvertFrom-Json; "  {0,-14} {1,-46} Code={2,-3} items={3,-5} {4}" -f $cid, ($base -replace 'http://nav.trimline.co.ke:4010', ''), $j.Code, @($j.Contents).Count, $j.Desc }
        catch { "  {0,-14} {1,-46} RAW: {2}" -f $cid, ($base -replace 'http://nav.trimline.co.ke:4010', ''), ($out -replace '\s+', ' ') }
    }
}
Write-Host "`nDONE"
