<#
.SYNOPSIS
    HX workload capacity gate.

.DESCRIPTION
    Evaluates a selected workload against current authoritative evidence for a host
    before any model download or runtime activation.

    Reads SERVER-REGISTRY.md for durable role and assigned workload, and
    servers/<host>/ for discovered and as-built hardware evidence. Contacts nothing.
    Downloads nothing.

    Returns PASS, FAIL, or BLOCKED. BLOCKED is the correct answer when the evidence
    needed to decide is absent - notably when no exact model and quantization has
    been selected. "The host has a big GPU" is not a capacity result.

    This gate never assumes two heavy models are simultaneously resident.

.PARAMETER Workload
    Workload name under workloads/.

.PARAMETER TargetHost
    Host to evaluate, e.g. hxs-3. Must exist in SERVER-REGISTRY.md.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ai-runtime\hx-capacity-gate.ps1 -Workload ds4-deepseek -TargetHost hxs-3
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Workload,
    [Parameter(Mandatory = $true)][string]$TargetHost
)

$ErrorActionPreference = 'Stop'
$here     = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $here '..\..')
$wlPath   = Join-Path $here "workloads\$Workload.json"
$registry = Join-Path $repoRoot 'SERVER-REGISTRY.md'
$hostDir  = Join-Path $repoRoot "servers\$TargetHost"

$findings = @()
function Add-Finding {
    param($Dimension, $Status, $Evidence)
    $script:findings += [pscustomobject]@{ dimension = $Dimension; status = $Status; evidence = $Evidence }
    $c = switch ($Status) { 'PASS' {'Green'} 'FAIL' {'Red'} 'BLOCKED' {'Yellow'} default {'Gray'} }
    Write-Host ("  {0,-7} {1,-22} {2}" -f $Status, $Dimension, $Evidence) -ForegroundColor $c
}

Write-Host ''
Write-Host '=========================================' -ForegroundColor Cyan
Write-Host ' HX Workload Capacity Gate' -ForegroundColor Cyan
Write-Host '=========================================' -ForegroundColor Cyan

if (-not (Test-Path $wlPath))    { Write-Host "Unknown workload '$Workload'." -ForegroundColor Red; exit 2 }
if (-not (Test-Path $registry))  { Write-Host 'SERVER-REGISTRY.md not found.' -ForegroundColor Red; exit 2 }
$wl = Get-Content $wlPath -Raw | ConvertFrom-Json

# --- durable identity from the registry, which is authoritative -------------------
$row = Select-String -Path $registry -Pattern "^\|\s*$TargetHost\s*\|" | Select-Object -First 1
if (-not $row) { Write-Host "Host '$TargetHost' not present in SERVER-REGISTRY.md." -ForegroundColor Red; exit 2 }
$cols = $row.Line -split '\|' | ForEach-Object { $_.Trim() }
# columns: 1 host 2 fqdn 3 ip 4 cpu 5 ram 6 gpu 7 storage 8 discovery 9 role 10 workload 11 phase2
$regRam      = $cols[5]
$regGpu      = $cols[6]
$regStorage  = $cols[7]
$durableRole = $cols[9]
$assignedWl  = $cols[10]

Write-Host ("Workload       : {0}  ({1})" -f $wl.workload, $wl.classification)
Write-Host ("Target host    : {0}" -f $TargetHost)
Write-Host ("Durable role   : {0}   <- SERVER-REGISTRY.md, unchanged by this gate" -f $durableRole)
Write-Host ("Assigned load  : {0}" -f $assignedWl)
Write-Host ''
Write-Host 'Dimensions:'

# --- GPU ---------------------------------------------------------------------------
$vramTotal = $null
if ($regGpu -match '([\d,]+)\s*MiB\s*total') { $vramTotal = [int]($Matches[1] -replace ',', '') }
if ($vramTotal) { Add-Finding 'GPU / VRAM' 'PASS' "$regGpu -> $vramTotal MiB aggregate" }
else            { Add-Finding 'GPU / VRAM' 'BLOCKED' "aggregate VRAM not parseable from registry: '$regGpu'" }

# --- backend / driver: as-built evidence, distinct from as-found -------------------
$driverFile = Join-Path $hostDir 'driver-results.md'
$discFile   = Join-Path $hostDir 'discovery.md'
$cudaVer = $null; $drvVer = $null
if (Test-Path $driverFile) {
    $d = Get-Content $driverFile -Raw
    if ($d -match 'CUDA Version:\s*([\d.]+)')    { $cudaVer = $Matches[1] }
    if ($d -match 'Driver Version:\s*([\d.]+)')  { $drvVer  = $Matches[1] }
}
if ($cudaVer) {
    $ok = $wl.requirements.backend -contains 'cuda'
    if ($ok) { Add-Finding 'Backend' 'PASS' "CUDA $cudaVer, driver $drvVer (as-built, driver-results.md)" }
    else     { Add-Finding 'Backend' 'FAIL' "host provides CUDA $cudaVer; workload requires one of: $($wl.requirements.backend -join ', ')" }
} elseif (Test-Path $discFile -and (Get-Content $discFile -Raw) -match 'CUDA availability:\s*none') {
    Add-Finding 'Backend' 'FAIL' 'as-found discovery reports no CUDA and no as-built driver record exists'
} else {
    Add-Finding 'Backend' 'BLOCKED' 'no accelerator backend evidence found for this host'
}

# --- system RAM --------------------------------------------------------------------
$ramGb = $null
if ($regRam -match '(\d+)\s*GB') { $ramGb = [int]$Matches[1] }
$refRam = $wl.requirements.documented_reference_target.system_ram_gb
if (-not $ramGb) {
    Add-Finding 'System RAM' 'BLOCKED' "RAM not parseable from registry: '$regRam'"
} elseif ($refRam -and $ramGb -lt $refRam) {
    Add-Finding 'System RAM' 'FAIL' ("host has $ramGb GB; the workload's documented reference target ($($wl.requirements.documented_reference_target.model)) is $refRam GB")
} else {
    Add-Finding 'System RAM' 'PASS' "$ramGb GB present"
}

# --- storage -----------------------------------------------------------------------
if ($regStorage) { Add-Finding 'Storage' 'BLOCKED' "host storage: $regStorage - cannot size without a selected model and quantization" }
else             { Add-Finding 'Storage' 'BLOCKED' 'no storage evidence in registry' }

# --- model residency: the dimension that decides most gates ------------------------
if ($wl.model.selection_required -and (-not $wl.model.identity)) {
    Add-Finding 'Model residency' 'BLOCKED' 'no exact model and quantization selected - residency cannot be computed'
} else {
    Add-Finding 'Model residency' 'BLOCKED' 'model selected but no measured residency evidence recorded'
}

# --- context / KV ------------------------------------------------------------------
Add-Finding 'Context / KV' 'BLOCKED' 'no target context size, concurrency or KV allowance recorded for this workload'

# --- runtime overhead --------------------------------------------------------------
Add-Finding 'Runtime overhead' 'BLOCKED' 'no measured runtime overhead evidence for this runtime on this host'

# --- coexistence -------------------------------------------------------------------
if ($wl.concurrency.assume_coexistence -eq $false -and $assignedWl) {
    Add-Finding 'Coexistence' 'BLOCKED' ("host already carries an assigned workload ('$assignedWl'); combined residency must be measured, never assumed")
} else {
    Add-Finding 'Coexistence' 'BLOCKED' 'coexistence not evaluated'
}

# --- verdict -----------------------------------------------------------------------
$fails   = @($findings | Where-Object { $_.status -eq 'FAIL' })
$blocked = @($findings | Where-Object { $_.status -eq 'BLOCKED' })
if ($fails.Count -gt 0 -and $blocked.Count -eq 0) { $verdict = 'FAIL' }
elseif ($blocked.Count -gt 0)                     { $verdict = 'BLOCKED' }
else                                              { $verdict = 'PASS' }

Write-Host ''
Write-Host '-----------------------------------------'
$vc = switch ($verdict) { 'PASS' {'Green'} 'FAIL' {'Red'} default {'Yellow'} }
Write-Host ("  VERDICT: $verdict") -ForegroundColor $vc
if ($verdict -eq 'BLOCKED') {
    Write-Host '  BLOCKED - INSUFFICIENT CURRENT HARDWARE EVIDENCE' -ForegroundColor Yellow
    Write-Host '  No model download or runtime activation is authorized.' -ForegroundColor Yellow
}
if ($fails.Count -gt 0) {
    Write-Host ("  {0} dimension(s) already fail on the evidence available:" -f $fails.Count) -ForegroundColor Red
    $fails | ForEach-Object { Write-Host ("    - {0}: {1}" -f $_.dimension, $_.evidence) -ForegroundColor Red }
}
Write-Host ("  Durable role of {0} is unchanged: {1}" -f $TargetHost, $durableRole)
Write-Host '========================================='
Write-Host ''

switch ($verdict) { 'PASS' { exit 0 } 'FAIL' { exit 1 } default { exit 3 } }
