<#
.SYNOPSIS
    DS4 commissioning state machine - takes a workload from NOT PRESENT to OPERATIONAL.

.DESCRIPTION
    Evaluates each commissioning gate against current repository evidence and reports the
    workload's actual state. Gates are evaluated in order and evaluation stops at the first
    unmet gate, because a later gate cannot be meaningfully assessed before an earlier one.

    Installed is not operational. A successful build is not proof of model fit, and a working
    HTTP endpoint is not proof that an agent client behaves correctly. The states are not
    collapsed.

    This script contacts no host, downloads nothing, and installs nothing. Gates requiring
    live host execution report SKIP or BLOCKED with a precise reason. Nothing is fabricated.

.PARAMETER Workload
    Workload name under workloads/. Default: ds4-deepseek.

.PARAMETER TargetHost
    Host the workload is being commissioned on. Default: hxs-3.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ai-runtime\hx-ds4-commission.ps1
#>
[CmdletBinding()]
param(
    [string]$Workload   = 'ds4-deepseek',
    [string]$TargetHost = 'hxs-3',
    [string]$EvidencePath
)

$ErrorActionPreference = 'Stop'
$here     = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $here '..\..')
$wlPath   = Join-Path $here "workloads\$Workload.json"
$registry = Join-Path $repoRoot 'SERVER-REGISTRY.md'
if (-not $EvidencePath) { $EvidencePath = Join-Path $here 'evidence' }
if (-not (Test-Path $EvidencePath)) { New-Item -ItemType Directory -Path $EvidencePath -Force | Out-Null }

if (-not (Test-Path $wlPath)) { Write-Host "Unknown workload '$Workload'." -ForegroundColor Red; exit 2 }
$wl = Get-Content $wlPath -Raw | ConvertFrom-Json

$row = Select-String -Path $registry -Pattern "^\|\s*$TargetHost\s*\|" | Select-Object -First 1
if (-not $row) { Write-Host "Host '$TargetHost' not in SERVER-REGISTRY.md." -ForegroundColor Red; exit 2 }
$cols = $row.Line -split '\|' | ForEach-Object { $_.Trim() }
$durableRole = $cols[9]

$script:gates = @()
function Add-Gate {
    param($Phase, $State, $Status, $Reason)
    $script:gates += [pscustomobject]@{ phase = $Phase; state = $State; status = $Status; reason = $Reason }
}

Write-Host ''
Write-Host '=========================================' -ForegroundColor Cyan
Write-Host ' DS4 Commissioning State Machine' -ForegroundColor Cyan
Write-Host '=========================================' -ForegroundColor Cyan
Write-Host ("Workload     : {0}  ({1})" -f $wl.workload, $wl.classification)
Write-Host ("Target host  : {0}" -f $TargetHost)
Write-Host ("Durable role : {0}   <- SERVER-REGISTRY.md, not changed by commissioning" -f $durableRole)
Write-Host ''

# ---- gate definitions, in required order -------------------------------------------
# Each returns: MET, or the reason it is not met.
$defs = @(
    @{ phase='-'; state='INSTALLED'; test={
        if ($wl.ds4_runtime.install_path -and $wl.ds4_runtime.revision) { $null }
        else { 'DS4 runtime not installed: no install_path or revision recorded, and no installation evidence exists under servers/' } } }

    @{ phase='A'; state='MODEL SELECTED'; test={
        $m = $wl.model_selection
        $missing = @()
        foreach ($f in 'identity','quantization','supported_by_ds4_revision','source_provenance','expected_file_size_gb') {
            if (-not $m.$f) { $missing += $f }
        }
        if ($missing.Count -eq 0) { $null }
        else { "no exact model and quantization selected: missing $($missing -join ', ')" } } }

    @{ phase='B'; state='CAPACITY APPROVED'; test={
        # The gate must have been RERUN against the exact selected artifact.
        $g = $wl.capacity_gate_result
        $m = $wl.model_selection
        if ($g.verdict -ne 'PASS') {
            "capacity gate verdict is '$($g.verdict)' - rerun hx-capacity-gate.ps1 against the selected artifact"
        } elseif ($g.verdict_for_model -ne $m.identity -or $g.verdict_for_quantization -ne $m.quantization) {
            "capacity gate result is STALE: it was evaluated for '$($g.verdict_for_model)/$($g.verdict_for_quantization)' but the selected artifact is '$($m.identity)/$($m.quantization)' - the gate must be rerun"
        } else { $null } } }

    @{ phase='C'; state='MODEL ACQUIRED'; test={
        $a = $wl.model_acquisition
        if (-not $a.authorized)        { 'model acquisition not authorized' }
        elseif (-not $a.acquired)      { 'model not acquired' }
        elseif (-not $a.checksum_sha256) { 'model acquired but no checksum recorded' }
        else { $null } } }

    @{ phase='D'; state='CLI VERIFIED'; test={
        'CLI inference requires a live DS4 install and the acquired model; flags must come from the installed revision --help, never hardcoded' } }

    @{ phase='E'; state='VENDOR TESTS PASSED'; test={
        'DS4 vendor regression requires a live build on the host' } }

    @{ phase='F'; state='LOCAL SERVER VERIFIED'; test={
        'localhost ds4-server commissioning requires a live DS4 install; loopback validation precedes any network exposure' } }

    @{ phase='G-H'; state='API VERIFIED'; test={
        'API, streaming and tool round-trip require a reachable local endpoint; offline protocol results are class A evidence only and do not satisfy this gate' } }

    @{ phase='I'; state='KV VERIFIED'; test={
        'KV and prefix-cache validation requires a live runtime; cold/warm timing is never fabricated offline' } }

    @{ phase='J'; state='HX CONTRACT VERIFIED'; test={
        'HX L2 live acceptance requires a validated live endpoint' } }

    @{ phase='L'; state='MANAGED WORKLOAD'; test={
        'managed service definition requires a stable manual launch first' } }

    @{ phase='K'; state='NETWORK VERIFIED'; test={
        'network smoke requires local validation first and separate authorization; not authorized in this workstream' } }

    @{ phase='M'; state='CLIENT VERIFIED'; test={
        'Claude Code smoke requires a validated network endpoint' } }
)

$currentState = 'NOT PRESENT'
$blockedAt    = $null

foreach ($d in $defs) {
    if ($blockedAt) {
        Add-Gate $d.phase $d.state 'SKIP' 'not evaluated - an earlier gate is unmet'
        Write-Host ("  SKIP     {0,-22} [{1}]  not evaluated - earlier gate unmet" -f $d.state, $d.phase) -ForegroundColor DarkGray
        continue
    }
    $reason = & $d.test
    if (-not $reason) {
        Add-Gate $d.phase $d.state 'PASS' 'gate met'
        $currentState = $d.state
        Write-Host ("  PASS     {0,-22} [{1}]" -f $d.state, $d.phase) -ForegroundColor Green
    } else {
        $status = if ($d.state -eq 'CAPACITY APPROVED') { 'BLOCKED' } else { 'BLOCKED' }
        Add-Gate $d.phase $d.state $status $reason
        $blockedAt = $d.state
        Write-Host ("  BLOCKED  {0,-22} [{1}]" -f $d.state, $d.phase) -ForegroundColor Yellow
        Write-Host ("           {0}" -f $reason) -ForegroundColor DarkYellow
    }
}

# ---- verdict -----------------------------------------------------------------------
$operational = ($currentState -eq 'CLIENT VERIFIED' -and -not $blockedAt)
$reported    = if ($operational) { 'OPERATIONAL' } elseif ($currentState -eq 'NOT PRESENT') { 'NOT PRESENT' } else { 'COMMISSIONING' }

Write-Host ''
Write-Host '-----------------------------------------'
Write-Host ("  CURRENT STATE : {0}" -f $reported) -ForegroundColor $(if ($operational) {'Green'} else {'Yellow'})
Write-Host ("  reached       : {0}" -f $currentState)
if ($blockedAt) { Write-Host ("  next gate     : {0}" -f $blockedAt) }
Write-Host ("  DS4 is NOT operational. Installed is not operational.") -ForegroundColor DarkYellow
Write-Host ("  Durable role of {0} unchanged: {1}" -f $TargetHost, $durableRole)
Write-Host '========================================='
Write-Host ''

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$ev = [pscustomobject]@{
    timestamp             = (Get-Date -Format 'o')
    workload              = $wl.workload
    classification        = $wl.classification
    target_host           = $TargetHost
    durable_role          = $durableRole
    durable_role_source   = 'SERVER-REGISTRY.md'
    reported_state        = $reported
    highest_state_reached = $currentState
    next_gate             = $blockedAt
    ds4_revision          = $wl.ds4_runtime.revision
    model_identity        = $wl.model_selection.identity
    quantization          = $wl.model_selection.quantization
    checksum_sha256       = $wl.model_acquisition.checksum_sha256
    endpoint              = $null
    backend_gpu_mapping   = $null
    context_setting       = $wl.server.context_target
    cache_config          = $wl.server.kv_cache_path
    performance           = @{}
    gates                 = $script:gates
    note                  = 'No host was contacted, nothing was downloaded, nothing was installed. Gates requiring live execution report BLOCKED or SKIP with a reason.'
}
$out = Join-Path $EvidencePath "ds4-commission_$($TargetHost)_$stamp.json"
$ev | ConvertTo-Json -Depth 8 | Set-Content -Path $out -Encoding UTF8
Write-Host ("  evidence: {0}" -f (Resolve-Path $out).Path)
Write-Host ''

if ($operational) { exit 0 } else { exit 3 }
