# Authorize the HX fleet public key on one server, then verify it works.
#
# Human-preparation step, run BEFORE handing a server to Claude Code.
# Only the public key is sent. The private key never leaves this workstation.
#
# Usage:   .\hx-authorize-key.ps1 192.168.50.201
#
# You will be prompted for the account password once. That is the last password
# this server should require.

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Ip,

    [string]$User = 'hxsa',

    [string]$KeyPath = "$env:USERPROFILE\.ssh\hx_fleet_ed25519"
)

$ErrorActionPreference = 'Stop'
$pub = "$KeyPath.pub"

if (-not (Test-Path -LiteralPath $pub)) {
    Write-Host "FAIL  public key not found: $pub" -ForegroundColor Red
    exit 1
}

$keyText = (Get-Content -LiteralPath $pub -Raw).Trim()
if ($keyText -notmatch '^(ssh-|ecdsa-|sk-)') {
    Write-Host "FAIL  $pub does not contain a public key" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "target      : $User@$Ip"
Write-Host "fingerprint : $((& ssh-keygen -lf $pub) -join '')"
Write-Host ""

# Append the key, strip any path-string line left by the PowerShell quoting trap,
# de-duplicate, and fix permissions. Safe to run more than once.
$remote = @(
    'mkdir -p -m 700 ~/.ssh'
    'cat >> ~/.ssh/authorized_keys'
    "grep -v 'hx_fleet_ed25519\.pub`$' ~/.ssh/authorized_keys | sort -u > ~/.ssh/ak.tmp"
    'mv ~/.ssh/ak.tmp ~/.ssh/authorized_keys'
    'chmod 600 ~/.ssh/authorized_keys'
    'echo REMOTE-OK'
) -join ' && '

Write-Host "Enter the account password when prompted." -ForegroundColor Yellow
Get-Content -LiteralPath $pub | & ssh "$User@$Ip" $remote
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAIL  could not write authorized_keys (exit $LASTEXITCODE)" -ForegroundColor Red
    exit 1
}

# BatchMode fails rather than prompting, so success here proves key auth really worked
# instead of quietly falling back to a password.
Write-Host ""
Write-Host "verifying key authentication..."
$check = & ssh -i $KeyPath -o BatchMode=yes -o PreferredAuthentications=publickey `
              -o IdentitiesOnly=yes -o ConnectTimeout=10 "$User@$Ip" `
              "hostname; sudo -n true && echo SUDO_NOPASSWD=yes || echo SUDO_NOPASSWD=no" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "FAIL  key authentication still refused" -ForegroundColor Red
    Write-Host "      $($check | Select-Object -First 1)"
    exit 1
}

$hostname = ($check | Select-Object -First 1).Trim()
$sudoLine = ($check | Where-Object { $_ -match 'SUDO_NOPASSWD' } | Select-Object -First 1)

Write-Host "PASS  key authentication works" -ForegroundColor Green
Write-Host "      hostname : $hostname"
Write-Host "      $sudoLine"

if ($sudoLine -match 'no') {
    Write-Host ""
    Write-Host "WARN  passwordless sudo is not configured on this host." -ForegroundColor Yellow
    Write-Host "      Discovery will still run, but firmware, DIMM, VRAM, firewall and"
    Write-Host "      SSH facts will be recorded as REQUIRES ROOT."
    Write-Host "      Apply checklist section 3 before handoff."
    exit 2
}

Write-Host ""
Write-Host "$hostname is ready for unattended discovery." -ForegroundColor Green
exit 0
