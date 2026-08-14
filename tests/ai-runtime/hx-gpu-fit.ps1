<#
.SYNOPSIS
    Hardware-fit gate - evaluates a model artifact against an isolated GPU before any
    runtime machinery is built or any model is acquired.

.DESCRIPTION
    Hardware fit first. Runtime and model selection second. Implementation third.

    This gate runs BEFORE install, download or deployment machinery. It answers one
    question: does the selected artifact plausibly fit the isolated target device, and
    at which context lengths.

    It does arithmetic on evidence and refuses to invent the rest. Model weights are
    known from the published artifact size. CUDA context and runtime overhead are
    reserved as a stated allowance. KV cache is NOT estimated - it is measured, because
    a fabricated KV figure would turn a guess into a false PASS.

    What it can prove:  weights against VRAM, remaining headroom, and where headroom is
                        obviously exhausted.
    What it cannot:     the exact context ceiling. That needs an empirical residency test.

    Contacts nothing. Downloads nothing.

.EXAMPLE
    powershell -File .\tests\ai-runtime\hx-gpu-fit.ps1 -Workload qwen35-9b-ollama -TargetHost hxs-4
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Workload,
    [Parameter(Mandatory = $true)][string]$TargetHost,
    [double]$RuntimeOverheadGb = 1.0   # CUDA context + allocator + compute scratch, stated not hidden
)

$ErrorActionPreference = 'Stop'
$here     = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $here '..\..')
$wl       = Get-Content (Join-Path $here "workloads\$Workload.json") -Raw | ConvertFrom-Json
$registry = Join-Path $repoRoot 'SERVER-REGISTRY.md'
$hostDir  = Join-Path $repoRoot "servers\$TargetHost"

Write-Host ''
Write-Host '=========================================' -ForegroundColor Cyan
Write-Host ' HX Hardware-Fit Gate' -ForegroundColor Cyan
Write-Host ' hardware fit first, implementation last' -ForegroundColor DarkGray
Write-Host '=========================================' -ForegroundColor Cyan

$row = Select-String -Path $registry -Pattern "^\|\s*$TargetHost\s*\|" | Select-Object -First 1
if (-not $row) { Write-Host "Host '$TargetHost' not in SERVER-REGISTRY.md." -ForegroundColor Red; exit 2 }
$cols = $row.Line -split '\|' | ForEach-Object { $_.Trim() }
$durableRole = $cols[9]; $assignedWl = $cols[10]

$dev  = $wl.gpu_isolation.target_device
$excl = $wl.gpu_isolation.excluded_device
$sel  = $wl.model_selection
$vramGb = [math]::Round($dev.vram_mib / 1024, 2)
$wGb    = $sel.published_artifact_size_gb

Write-Host ("Workload      : {0}" -f $wl.workload)
Write-Host ("Target host   : {0}   durable role: {1}" -f $TargetHost, $durableRole)
Write-Host ("Artifact      : {0}   ({1})   ~{2} GB" -f $sel.identity, $sel.tag, $wGb)
Write-Host ("Target device : {0}  {1}  {2} MiB (~{3} GB)" -f $dev.name, $dev.pci_bus_id, $dev.vram_mib, $vramGb)
Write-Host ("Excluded      : {0}  {1}  {2} MiB" -f $excl.name, $excl.pci_bus_id, $excl.vram_mib)
Write-Host ''

$fail = 0; $blocked = 0
function Write-Gate { param($S,$N,$E)
    $c = switch ($S) { 'PASS' {'Green'} 'FAIL' {'Red'} 'BLOCKED' {'Yellow'} default {'Cyan'} }
    Write-Host ("  {0,-8} {1,-26} {2}" -f $S,$N,$E) -ForegroundColor $c
    if ($S -eq 'FAIL') { $script:fail++ } elseif ($S -eq 'BLOCKED') { $script:blocked++ }
}

# --- backend, from as-built evidence --------------------------------------------------
$drv = Join-Path $hostDir 'driver-results.md'
$cuda=$null; $dv=$null
if (Test-Path $drv) {
    $d = Get-Content $drv -Raw
    if ($d -match 'CUDA Version:\s*([\d.]+)')   { $cuda = $Matches[1] }
    if ($d -match 'Driver Version:\s*([\d.]+)') { $dv   = $Matches[1] }
}
if ($dv) {
    $ok = ([double]($dv -split '\.')[0]) -ge $wl.requirements.min_driver_version
    if ($ok) { Write-Gate 'PASS' 'driver version' "$dv (>= $($wl.requirements.min_driver_version) required), CUDA $cuda - as-built record" }
    else     { Write-Gate 'FAIL' 'driver version' "$dv is below the required $($wl.requirements.min_driver_version)" }
} else { Write-Gate 'BLOCKED' 'driver version' 'no as-built driver evidence for this host' }

# --- device identity ------------------------------------------------------------------
if ($dev.uuid) { Write-Gate 'PASS' 'device identity' "UUID $($dev.uuid)" }
else { Write-Gate 'BLOCKED' 'device identity' "UUID not in repository evidence - $($dev.uuid_status)" }

# --- weights against VRAM: the hard arithmetic ----------------------------------------
$headroom = [math]::Round($vramGb - $wGb - $RuntimeOverheadGb, 2)
if ($wGb -ge $vramGb) {
    Write-Gate 'FAIL' 'weights vs VRAM' "artifact ~$wGb GB exceeds ~$vramGb GB device memory"
} else {
    Write-Gate 'PASS' 'weights vs VRAM' "~$wGb GB weights fit within ~$vramGb GB"
}

$hc = 'PASS'
if ($headroom -le 0)        { $hc = 'FAIL' }
elseif ($headroom -lt 1.0)  { $hc = 'BLOCKED' }
Write-Gate $hc 'headroom after overhead' "~$headroom GB left for KV after reserving $RuntimeOverheadGb GB runtime overhead"

# --- context ladder: state what is knowable, measure the rest --------------------------
Write-Host ''
Write-Host '  context ladder - KV is measured, never estimated:' -ForegroundColor Cyan
$ladder = $wl.requirements.context_ladder
$rec    = $wl.requirements.claude_code_recommended_context
foreach ($ctx in $ladder) {
    $rel = [math]::Round($ctx / $ladder[0], 0)
    if ($headroom -le 0) {
        Write-Host ("    {0,6}  FAIL      no headroom remains for any KV allocation" -f $ctx) -ForegroundColor Red
    } elseif ($ctx -eq $ladder[0]) {
        Write-Host ("    {0,6}  MEASURE   ~{1} GB headroom; plausible but unproven - empirical residency test required" -f $ctx, $headroom) -ForegroundColor Cyan
    } else {
        Write-Host ("    {0,6}  MEASURE   KV scales ~{1}x the 4K allocation; must fit the same ~{2} GB headroom" -f $ctx, $rel, $headroom) -ForegroundColor DarkCyan
    }
}
Write-Host ("    Claude Code guidance recommends >= {0}. That is {1}x the 4K KV footprint against unchanged headroom." -f $rec, [math]::Round($rec/$ladder[0],0)) -ForegroundColor DarkYellow

# --- isolation ------------------------------------------------------------------------
Write-Host ''
if ($wl.gpu_isolation.required) {
    Write-Gate 'BLOCKED' 'GPU isolation' "mandatory and unproven: $($wl.gpu_isolation.reason)"
}

# --- coexistence ----------------------------------------------------------------------
    Write-Gate 'BLOCKED' 'coexistence' "host already carries assigned workloads ('$assignedWl'); combined residency measured, never assumed"

# --- authorization --------------------------------------------------------------------
if (-not $wl.activation.host_mutation_authorized) {
    Write-Gate 'BLOCKED' 'host mutation' 'not authorized: Ollama install, model pull and systemd configuration are Phase 3 server implementation'
}

# --- verdict ---------------------------------------------------------------------------
Write-Host ''
Write-Host '-----------------------------------------'
if ($fail -gt 0) {
    Write-Host '  HARDWARE FIT: FAIL' -ForegroundColor Red
    $verdict = 1
} elseif ($blocked -gt 0) {
    Write-Host '  HARDWARE FIT: PLAUSIBLE AT 4K - EMPIRICAL TEST REQUIRED' -ForegroundColor Cyan
    Write-Host '  Weights fit the isolated device. The context ceiling is unproven.' -ForegroundColor DarkGray
    Write-Host '  BLOCKED on: device UUID, GPU isolation proof, host mutation authorization.' -ForegroundColor Yellow
    $verdict = 3
} else {
    Write-Host '  HARDWARE FIT: PASS' -ForegroundColor Green
    $verdict = 0
}
Write-Host ("  Durable role of {0} unchanged: {1}" -f $TargetHost, $durableRole) -ForegroundColor DarkGray
Write-Host '========================================='
Write-Host ''
exit $verdict
