# Run the HX Phase 1 read-only collector against one server and save the output.
#
# Requires key authentication to already work. Nothing is installed or changed
# on the target; the collector reads existing system state only.
#
# Usage:   .\hx-collect.ps1 192.168.50.201
#          .\hx-collect.ps1 192.168.50.201 -OutFile C:\path\to\out.txt
#
# Output is written as UTF-8. PowerShell's Tee-Object and default redirection
# write UTF-16, which downstream text tools cannot read.

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Ip,

    [string]$User = 'hxsa',

    [string]$KeyPath = "$env:USERPROFILE\.ssh\hx_fleet_ed25519",

    [string]$OutFile
)

$ErrorActionPreference = 'Stop'

$collector = Join-Path $PSScriptRoot 'collect-server-facts.sh'
if (-not (Test-Path -LiteralPath $collector)) {
    Write-Host "FAIL  collector not found: $collector" -ForegroundColor Red
    exit 1
}

# A CR byte makes bash fail with "$'\r': command not found" on the target.
$bytes = [System.IO.File]::ReadAllBytes($collector)
$crCount = @($bytes | Where-Object { $_ -eq 13 }).Count
if ($crCount -gt 0) {
    Write-Host "FAIL  collector contains $crCount CR bytes and would not run on Linux" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "target    : $User@$Ip"
Write-Host "collector : $collector ($($bytes.Length) bytes, LF)"

# Confirm key auth before spending time on the collection.
$who = & ssh -i $KeyPath -o BatchMode=yes -o PreferredAuthentications=publickey `
            -o IdentitiesOnly=yes -o ConnectTimeout=10 "$User@$Ip" "hostname" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAIL  key authentication refused. Run hx-authorize-key.ps1 $Ip first." -ForegroundColor Red
    Write-Host "      $($who | Select-Object -First 1)"
    exit 1
}
$hostname = ($who | Select-Object -First 1).Trim()
Write-Host "hostname  : $hostname"

if (-not $OutFile) {
    # Include the last address octet. Naming by hostname alone silently overwrites
    # a previous collection when two hosts report the same name, which has happened.
    $octet = ($Ip -split '\.')[-1]
    $OutFile = Join-Path $env:USERPROFILE "$hostname-$octet-facts.txt"
}

if (Test-Path -LiteralPath $OutFile) {
    Write-Host "note      : overwriting existing $OutFile" -ForegroundColor Yellow
}

# base64 keeps the script byte-exact in transit and leaves stdin free.
$b64 = [Convert]::ToBase64String($bytes)

Write-Host "collecting..."
$out = & ssh -i $KeyPath -o BatchMode=yes -o IdentitiesOnly=yes `
            "$User@$Ip" "echo '$b64' | base64 -d | bash" 2>&1
$sshExit = $LASTEXITCODE

$text = ($out | Out-String) -replace "`r`n", "`n"
[System.IO.File]::WriteAllText($OutFile, $text, (New-Object System.Text.UTF8Encoding($false)))

$lines = ($text -split "`n").Count
$priv  = ($text -split "`n" | Where-Object { $_ -match 'privilege mode' } | Select-Object -First 1)
$done  = $text -match 'collection complete'

Write-Host ""
Write-Host "output    : $OutFile"
Write-Host "lines     : $lines"
Write-Host "$(($priv -replace '\s+', ' ').Trim())"

if (-not $done) {
    Write-Host "FAIL  collector did not reach its completion marker (ssh exit $sshExit)" -ForegroundColor Red
    exit 1
}

$notInstalled = @($text -split "`n" | Where-Object { $_ -match 'TOOL NOT INSTALLED' }).Count
$needsRoot    = @($text -split "`n" | Where-Object { $_ -match 'REQUIRES ROOT' }).Count
Write-Host "absent tools        : $notInstalled"
Write-Host "facts needing root  : $needsRoot"

if ($needsRoot -gt 0) {
    Write-Host ""
    Write-Host "WARN  $needsRoot facts could not be collected without root." -ForegroundColor Yellow
    Write-Host "      Apply checklist section 3 (NOPASSWD sudo) and rerun for a complete record."
}

Write-Host ""
Write-Host "collection complete for $hostname" -ForegroundColor Green
exit 0
