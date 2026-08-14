<#
.SYNOPSIS
    Workload commissioning state machine - takes a workload from NOT PRESENT to OPERATIONAL.

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
    Workload name under workloads/. Default:

.PARAMETER TargetHost
    Host the workload is being commissioned on. Default: hxs-3.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ai-runtime\hxps1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Workload,
    [string]$TargetHost,
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

# --- refuse to commission a deferred or aborted workload ------------------------------
if ($wl.status -and ($wl.status.status -match 'DEFERRED|ABORTED' -or $wl.status.commissioning -eq 'ABORTED')) {
    Write-Host ''
    Write-Host '=========================================' -ForegroundColor Cyan
    Write-Host ' Workload Commissioning State Machine' -ForegroundColor Cyan
    Write-Host '=========================================' -ForegroundColor Cyan
    Write-Host ("Workload      : {0}" -f $wl.workload)
    Write-Host ("Status        : {0}" -f $wl.status.status) -ForegroundColor Yellow
    Write-Host ("Commissioning : {0}" -f $wl.status.commissioning) -ForegroundColor Yellow
    Write-Host ("Installed     : {0}    Model present: {1}    Service active: {2}" -f `
                $wl.status.installed, $wl.status.model_present, $wl.status.service_active)
    Write-Host ("Host assignment: {0}" -f $wl.status.host_assignment)
    Write-Host ''
    Write-Host ("  Reason: {0}" -f $wl.status.reason) -ForegroundColor DarkYellow
    Write-Host ''
    Write-Host '  Commissioning is DISABLED for this workload.' -ForegroundColor Yellow
    Write-Host '  No gate is evaluated. No install, download or activation is authorized.' -ForegroundColor Yellow
    Write-Host '========================================='
    Write-Host ''
    exit 4
}

if (-not $TargetHost) { Write-Host 'A -TargetHost is required to commission an active workload.' -ForegroundColor Red; exit 2 }
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
Write-Host ' Workload Commissioning State Machine' -ForegroundColor Cyan
Write-Host '=========================================' -ForegroundColor Cyan
Write-Host ("Workload     : {0}  ({1})" -f $wl.workload, $wl.classification)
Write-Host ("Target host  : {0}" -f $TargetHost)
Write-Host ("Durable role : {0}   <- SERVER-REGISTRY.md, not changed by commissioning" -f $durableRole)
Write-Host ''

# ---- gate definitions, in required order -------------------------------------------
# Each returns: MET, or the reason it is not met.
$defs = @(
    @{ phase='1'; state='MODEL SELECTED'; test={
        $m = $wl.model_selection
        $missing = @()
        foreach ($f in 'identity','quantization','gguf_filename','supported_by_'source_provenance','expected_file_size_gb') {
            if (-not $m.$f) { $missing += $f }
        }
        if ($missing.Count -eq 0) { $null }
        else { "no exact model and quantization selected: missing $($missing -join ', ')" } } }

    @{ phase='1'; state='EXECUTION MODE SELECTED'; test={
        # The mode decision is bound to the exact artifact. If the artifact changes,
        # the recorded capacity result is stale and the decision reopens.
        $ssd = $wl.execution_modes.cuda_ssd_streaming_single_gpu
        $g   = $wl.capacity_gate_result
        $m   = $wl.model_selection
        if (-not $ssd)            { 'no execution mode recorded' }
        elseif (-not $ssd.pursue) { 'no pursuable execution mode' }
        elseif ($g.verdict_for_model -ne $m.identity -or $g.verdict_for_quantization -ne $m.quantization) {
            "capacity result is STALE: evaluated for '$($g.verdict_for_model)/$($g.verdict_for_quantization)' but the selected artifact is '$($m.identity)/$($m.quantization)' - the gate must be rerun"
        }
        else { $null } } }

    @{ phase='2'; state='STORAGE VERIFIED'; test={
        $sg = $wl.storage_gate
        if (-not $sg.measured_free_gb) {
            "hxs-3 NVMe capacity and sustained performance not yet measured; need >$($sg.requirements.minimum_free_gb) GB free on the fast NVMe hosting the GGUF. Under SSD streaming the device is in the inference path"
        } elseif ($sg.measured_free_gb -lt $sg.requirements.minimum_free_gb) {
            "measured $($sg.measured_free_gb) GB free is below the $($sg.requirements.minimum_free_gb) GB minimum"
        } else { $null } } }

    @{ phase='3'; state=' test={
        if ($wl.install_path -and $wl.revision) { $null }
        else { ' Applicable model-free vendor tests are run as part of this gate' } } }

    @{ phase='4'; state='MODEL ACQUIRED'; test={
        $a = $wl.model_acquisition
        if (-not $a.authorized)          { "acquisition not authorized: $($a.authorization_condition)" }
        elseif (-not $a.acquired)        { 'model not acquired' }
        elseif (-not $a.checksum_sha256) { 'model acquired but no checksum recorded' }
        else { $null } } }

    @{ phase='5'; state='CLI VERIFIED'; test={
        $i = $wl.execution_modes.cuda_ssd_streaming_single_gpu.initial_settings
        "one-GPU CUDA SSD-streaming CLI run required (expert cache $($i.ssd_streaming_cache_experts_gb) GB, context $($i.context)); exact flags must come from the installed revision --help" } }

    @{ phase='6'; state='CACHE SWEEP PASSED'; test={
        $sw = ($wl.execution_modes.cuda_ssd_streaming_single_gpu.cache_sweep_gb) -join ' -> '
        "expert-cache sweep not run ($sw GB); advance one step only after the previous passes" } }

    @{ phase='7'; state='CONTEXT SWEEP PASSED'; test={
        $sw = ($wl.execution_modes.cuda_ssd_streaming_single_gpu.context_sweep) -join ' -> '
        "context sweep not run ($sw); advance one step only after the previous passes" } }

    @{ phase='8'; state='BENCHMARKED'; test={
        'cold and warm benchmark not run; timing is never fabricated offline' } }

    @{ phase='9'; state='LOCAL SERVER VERIFIED'; test={
        ' loopback validation precedes any network exposure' } }

    @{ phase='10'; state='API VERIFIED'; test={
        'API, streaming and tool round-trip require a reachable local endpoint; offline protocol results are class A evidence only' } }

    @{ phase='11'; state='HX CONTRACT VERIFIED'; test={
        'HX L2 live acceptance requires a validated live endpoint' } }

    @{ phase='12'; state='MANAGED WORKLOAD'; test={
        'managed service definition requires a stable manual launch first' } }

    @{ phase='13'; state='NETWORK VERIFIED'; test={
        'HX network smoke requires local validation first and separate authorization' } }

    @{ phase='14'; state='CLIENT VERIFIED'; test={
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
Write-Host (" Installed is not operational.") -ForegroundColor DarkYellow
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
revision
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
$out = Join-Path $EvidencePath "_$stamp.json"
$ev | ConvertTo-Json -Depth 8 | Set-Content -Path $out -Encoding UTF8
Write-Host ("  evidence: {0}" -f (Resolve-Path $out).Path)
Write-Host ''

if ($operational) { exit 0 } else { exit 3 }
