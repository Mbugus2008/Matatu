# After the DNS move: does nav.trimline.co.ke now serve everything from main?
$ErrorActionPreference = 'Continue'
$prev = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
Clear-DnsClientCache
$ErrorActionPreference = $prev

Write-Host '===== DNS ====='
foreach ($n in 'nav.trimline.co.ke', 'main.trimline.co.ke', 'services.trimline.co.ke', 'trimline.co.ke') {
    try {
        $ips = (Resolve-DnsName $n -Type A -ErrorAction Stop | Where-Object { $_.IPAddress } | ForEach-Object { $_.IPAddress }) -join ', '
        "  {0,-26} -> {1}" -f $n, $ips
    } catch { "  {0,-26} -> FAILED" -f $n }
}
Write-Host '  (public resolver check)'
try { (Resolve-DnsName 'nav.trimline.co.ke' -Type A -Server 8.8.8.8 -ErrorAction Stop | Where-Object IPAddress | ForEach-Object { "    8.8.8.8 -> $($_.IPAddress)" }) } catch { '    8.8.8.8 query failed' }

Write-Host "`n===== key TCP ports on nav.trimline.co.ke (now = main) ====="
foreach ($p in 80, 443, 4010, 4011, 4012, 4013, 4014, 4016, 1247) {
    $r = Test-NetConnection -ComputerName 'nav.trimline.co.ke' -Port $p -WarningAction SilentlyContinue
    "  :{0,-6} = {1}" -f $p, $r.TcpTestSucceeded
}

Write-Host "`n===== API via nav name (what the installed 1.0.15 phones hit) ====="
function Probe([string]$url, [string]$label) {
    $out = curl.exe -s -X POST -H "X-Client-Identifier: REMBOCLASIC" -H "X-Api-Key: gbsQcaCncEKpIIOn45tnpsynuAwW+sXvNhFl2ynk9+s=" -H "Content-Type: application/json" -d "{}" --max-time 90 $url
    try {
        $j = $out | ConvertFrom-Json
        "  {0,-34} Code={1,-3} items={2,-6} {3}" -f $label, $j.Code, @($j.Contents).Count, $j.Desc
    } catch { "  {0,-34} RAW: {1}" -f $label, ($out -replace '\s+', ' ').Substring(0, [Math]::Min(90, $out.Length)) }
}
foreach ($e in 'agents', 'vehicles', 'members', 'transtypes', 'TransactionDate') {
    Probe "http://nav.trimline.co.ke:4010/Test/api/Matatu/$e" "nav/Test/$e"
}
Write-Host '  --- root path (what the KCS app uses) ---'
foreach ($e in 'agents', 'vehicles') {
    Probe "http://nav.trimline.co.ke:4010/api/Matatu/$e" "nav/ROOT/$e"
}
Write-Host '  --- via main name, for comparison ---'
foreach ($e in 'agents') {
    Probe "http://main.trimline.co.ke:4010/Test/api/Matatu/$e" "main/Test/$e"
}

Write-Host "`n===== BC web client on nav.trimline.co.ke:443 (does it still work?) ====="
$r = curl.exe -s -o NUL -w "%{http_code}" -k --max-time 30 "https://nav.trimline.co.ke/"
"  https://nav.trimline.co.ke/  -> HTTP $r"

Write-Host "`nDONE"
