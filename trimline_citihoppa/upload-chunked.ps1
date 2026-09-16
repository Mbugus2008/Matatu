# upload-chunked.ps1 - uploads a large file to a remote Windows host in parallel
# chunks, reassembles it there and verifies the SHA256.
#
# Why: Copy-Item -ToSession streams through WinRM, which is slow for big files
# (~0.5 MB/s measured on a 159 MB APK). Splitting the file and pushing the
# chunks over several WinRM sessions at once - with larger envelopes - is much
# faster, and a failed chunk only costs one chunk rather than the whole file.
#
# Usage:
#   pwsh -File .\upload-chunked.ps1 -LocalPath .\build\app-release.apk `
#        -RemoteDirectory 'C:\Services\Matatu\Updates'
#
#   pwsh -File .\upload-chunked.ps1 -LocalPath <file> -RemoteDirectory <dir> `
#        -ChunkMB 8 -Parallel 4
#
#   # fastest where SMB/445 is reachable: copy straight to the admin share
#   pwsh -File .\upload-chunked.ps1 -LocalPath <file> -RemoteDirectory <dir> -UseSmb
#
# Requires PowerShell 7 (pwsh) for the parallel runspaces.

param(
    [Parameter(Mandatory = $true)][string]$LocalPath,
    [Parameter(Mandatory = $true)][string]$RemoteDirectory,
    [string]$RemoteName = '',
    [int]$ChunkMB = 8,
    [int]$Parallel = 4,
    [string]$User = 'Administrator',
    [string]$Pass = 'Touran2018',
    [string]$HostName = 'main.trimline.co.ke',
    [switch]$UseSmb
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $LocalPath)) { throw "File not found: $LocalPath" }
$LocalPath = (Resolve-Path $LocalPath).Path
if ([string]::IsNullOrWhiteSpace($RemoteName)) { $RemoteName = Split-Path $LocalPath -Leaf }

$fileSize = (Get-Item $LocalPath).Length
$fileMb = [math]::Round($fileSize / 1MB, 1)
$localHash = (Get-FileHash $LocalPath -Algorithm SHA256).Hash

Write-Host "file       : $RemoteName ($fileMb MB)" -ForegroundColor Cyan
Write-Host "sha256     : $localHash" -ForegroundColor DarkGray
Write-Host "destination: ${HostName}:$RemoteDirectory" -ForegroundColor Cyan

# ---------------------------------------------------------- direct SMB path ---
if ($UseSmb) {
    $unc = "\\$HostName\" + ($RemoteDirectory -replace ':', '$')
    $target = Join-Path $unc $RemoteName
    Write-Host "`n[smb] copying to $target" -ForegroundColor Yellow
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $mapping = $null
    try {
        $mapping = New-SmbMapping -RemotePath $unc -UserName "$HostName\$User" -Password $Pass -ErrorAction Stop
        Copy-Item $LocalPath $target -Force
    } finally {
        if ($mapping) { Remove-SmbMapping -RemotePath $unc -Force -ErrorAction SilentlyContinue }
    }
    $sw.Stop()
    Write-Host ("[smb] done in {0:n0}s ({1:n1} MB/s)" -f `
            $sw.Elapsed.TotalSeconds, ($fileMb / [math]::Max($sw.Elapsed.TotalSeconds, 0.001))) -ForegroundColor Green
    return
}

# ------------------------------------------------------------------ chunks ----
$chunkBytes = $ChunkMB * 1MB
$partCount = [int][math]::Ceiling($fileSize / $chunkBytes)
if ($partCount -gt 12) {
    # keep the number of WinRM sessions sane on very large files
    $partCount = 12
    $chunkBytes = [int][math]::Ceiling($fileSize / $partCount)
}
$work = Join-Path $env:TEMP ("chunkupload-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $work -Force | Out-Null

Write-Host "`n[1/3] splitting into $partCount chunk(s) of $([math]::Round($chunkBytes / 1MB, 1)) MB..." -ForegroundColor Green
$sw = [Diagnostics.Stopwatch]::StartNew()
$parts = @()
$in = [IO.File]::OpenRead($LocalPath)
try {
    $buffer = New-Object byte[] (1MB)
    for ($i = 1; $i -le $partCount; $i++) {
        $partName = "{0}.part{1:d3}" -f $RemoteName, $i
        $partPath = Join-Path $work $partName
        $remaining = $chunkBytes
        $out = [IO.File]::Create($partPath)
        try {
            while ($remaining -gt 0) {
                $toRead = [int][math]::Min($buffer.Length, $remaining)
                $read = $in.Read($buffer, 0, $toRead)
                if ($read -le 0) { break }
                $out.Write($buffer, 0, $read)
                $remaining -= $read
            }
        } finally { $out.Close() }
        $parts += $partName
    }
} finally { $in.Close() }
$sw.Stop()
Write-Host ("      split in {0:n0}s" -f $sw.Elapsed.TotalSeconds) -ForegroundColor DarkGray

# ------------------------------------------------- parallel chunk transfer ----
$cred = New-Object PSCredential($User, (ConvertTo-SecureString $Pass -AsPlainText -Force))
# Larger envelopes mean far fewer WinRM round trips for bulk copy. This knob
# only exists on the WSMan session option object.
try {
    $opts = New-WSManSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck -MaxEnvelopeSizekb 8192
} catch {
    Write-Host "      (falling back to default WinRM envelope size)" -ForegroundColor DarkYellow
    $opts = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
}
$streams = [math]::Min($Parallel, $parts.Count)

Write-Host "[2/3] uploading $($parts.Count) chunk(s) over $streams parallel session(s)..." -ForegroundColor Green
$sessions = @(1..$streams | ForEach-Object {
        New-PSSession -ComputerName $HostName -Credential $cred -UseSSL -SessionOption $opts
    })
Write-Host "      connected to $HostName" -ForegroundColor DarkGray

# spread the chunks over the sessions, one session per worker
$tasks = @()
for ($s = 0; $s -lt $streams; $s++) {
    $mine = @()
    for ($i = $s; $i -lt $parts.Count; $i += $streams) { $mine += $parts[$i] }
    $tasks += [pscustomobject]@{ Id = $s; Session = $sessions[$s]; Parts = $mine }
}

$sw = [Diagnostics.Stopwatch]::StartNew()
try {
    $tasks | ForEach-Object -Parallel {
        $t = $_
        foreach ($p in $t.Parts) {
            Copy-Item -Path (Join-Path $using:work $p) `
                -Destination "$using:RemoteDirectory\$p" -ToSession $t.Session -Force
        }
        "stream $($t.Id): $($t.Parts.Count) chunk(s) done"
    } -ThrottleLimit $streams | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
} finally {
    $sw.Stop()
}
$mbps = $fileMb / [math]::Max($sw.Elapsed.TotalSeconds, 0.001)
Write-Host ("      uploaded in {0:n0}s ({1:n1} MB/s)" -f $sw.Elapsed.TotalSeconds, $mbps) -ForegroundColor Green

# ------------------------------------------------------------- reassemble -----
Write-Host "[3/3] reassembling and verifying on the server..." -ForegroundColor Green
try {
    Invoke-Command -Session $sessions[0] -ScriptBlock {
        param($RemoteDirectory, $RemoteName)
        $dest = Join-Path $RemoteDirectory $RemoteName
        if (Test-Path $dest) { Remove-Item $dest -Force }
        # copy /b concatenates the parts in sorted order (part001, part002, ...)
        $parts = Get-ChildItem "$RemoteDirectory\$RemoteName.part*" | Sort-Object Name
        if (-not $parts) { throw "no chunks found in $RemoteDirectory" }
        $list = ($parts | ForEach-Object { '"' + $_.FullName + '"' }) -join '+'
        cmd /c "copy /b $list `"$dest`"" | Out-Null
        $parts | Remove-Item -Force
    } -ArgumentList $RemoteDirectory, $RemoteName

    $remote = Invoke-Command -Session $sessions[0] -ScriptBlock {
        param($RemoteDirectory, $RemoteName)
        $dest = Join-Path $RemoteDirectory $RemoteName
        [pscustomobject]@{
            Length = (Get-Item $dest).Length
            Hash   = (Get-FileHash $dest -Algorithm SHA256).Hash
        }
    } -ArgumentList $RemoteDirectory, $RemoteName
} finally {
    $sessions | Remove-PSSession -ErrorAction SilentlyContinue
    Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
}

$remoteMb = [math]::Round($remote.Length / 1MB, 1)
if ($remote.Hash -eq $localHash) {
    Write-Host "`nOK - $RemoteName ($remoteMb MB) uploaded and verified (sha256 matches)" -ForegroundColor Green
} else {
    Write-Host "`nMISMATCH - local $localHash / remote $($remote.Hash)" -ForegroundColor Red
    exit 1
}
