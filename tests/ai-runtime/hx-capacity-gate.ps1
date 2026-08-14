<#
.SYNOPSIS
    HX workload capacity gate - backend-aware, artifact-bound, mode-aware.

.DESCRIPTION
    Evaluates a selected workload against current authoritative evidence for its fixed
    deployment host, before any model download or runtime activation. Contacts nothing.
    Downloads nothing.

    Backend awareness matters. For a CUDA runtime, host RAM is NOT a substitute for device
    memory in full-resident mode: current
    to start if model layers would spill to CPU.

    Mode awareness matters just as much. A model too large to hold resident may still run
    under SSD streaming, which exists precisely so the routed-expert portion need not stay
    resident. The gate therefore evaluates each supported execution mode separately rather
    than issuing one verdict for the workload.

    Verdicts: PASS (0), FAIL (1), BLOCKED (3).
    A decisive FAIL in one mode does not condemn another mode.

.EXAMPLE
    powershell -File .\tests\ai-runtime\hx-capacity-gate.ps1 -Workload
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
    $c = switch -Regex ($Status) { 'PASS' {'Green'} 'FAIL' {'Red'} 'CANDIDATE' {'Cyan'} default {'Yellow'} }
    Write-Host ("  {0,-11} {1,-26} {2}" -f $Status, $Dimension, $Evidence) -ForegroundColor $c
}

Write-Host ''
Write-Host '=========================================' -ForegroundColor Cyan
Write-Host ' HX Workload Capacity Gate' -ForegroundColor Cyan
Write-Host '=========================================' -ForegroundColor Cyan

if (-not (Test-Path $wlPath))   { Write-Host "Unknown workload '$Workload'." -ForegroundColor Red; exit 2 }
if (-not (Test-Path $registry)) { Write-Host 'SERVER-REGISTRY.md not found.' -ForegroundColor Red; exit 2 }
$wl = Get-Content $wlPath -Raw | ConvertFrom-Json

# --- a deferred workload is reported, not gated ---------------------------------------
if ($wl.status -and ($wl.status.status -match 'DEFERRED|ABORTED' -or $wl.status.commissioning -eq 'ABORTED')) {
    Write-Host ("Workload      : {0}" -f $wl.workload)
    Write-Host ("Status        : {0}   commissioning {1}" -f $wl.status.status, $wl.status.commissioning) -ForegroundColor Yellow
    Write-Host ''
    Write-Host '  This workload is DEFERRED. The capacity gate is not evaluated for it.' -ForegroundColor Yellow
    Write-Host '  No model download or runtime activation is authorized.' -ForegroundColor Yellow
    Write-Host ("  Reason: {0}" -f $wl.status.reason) -ForegroundColor DarkYellow
    Write-Host ''
    Write-Host '  Prior findings are retained in the workload record as reference.' -ForegroundColor DarkGray
    Write-Host '========================================='
    Write-Host ''
    exit 4
}

$row = Select-String -Path $registry -Pattern "^\|\s*$TargetHost\s*\|" | Select-Object -First 1
if (-not $row) { Write-Host "Host '$TargetHost' not in SERVER-REGISTRY.md." -ForegroundColor Red; exit 2 }
$cols = $row.Line -split '\|' | ForEach-Object { $_.Trim() }
$regRam = $cols[5]; $regGpu = $cols[6]; $regStorage = $cols[7]
$durableRole = $cols[9]; $assignedWl = $cols[10]

$sel = $wl.model_selection
$art = if ($sel.quantization) { "$($sel.identity) / $($sel.quantization)" } else { '(none selected)' }

Write-Host ("Workload          : {0}  ({1})" -f $wl.workload, $wl.classification)
Write-Host ("Deployment host   : {0}  [{1}]" -f $TargetHost, $(if ($wl.deployment_host.status) { $wl.deployment_host.status } else { 'assigned' }))
Write-Host ("Selected artifact : {0}   ~{1} GB" -f $art, $sel.expected_file_size_gb)
if ($sel.gguf_filename) { Write-Host ("  gguf            : {0}" -f $sel.gguf_filename) }
Write-Host ("Durable role      : {0}   <- SERVER-REGISTRY.md, unchanged by this gate" -f $durableRole)
Write-Host ''

# --- hardware evidence ---------------------------------------------------------------
$gpuCount = 0; $vramTotal = $null; $vramEach = $null
$xs = ([regex]::Matches($regGpu, '(\d+)\s*x\s')) | ForEach-Object { [int]$_.Groups[1].Value }
if ($xs.Count -gt 0) { $gpuCount = ($xs | Measure-Object -Sum).Sum }
if ($regGpu -match '([\d,]+)\s*MiB\s*total') { $vramTotal = [int]($Matches[1] -replace ',','') }
if ($regGpu -match '([\d,]+)\s*MiB\s*each')  { $vramEach  = [int]($Matches[1] -replace ',','') }
if ($regGpu -match 'none') { $gpuCount = 0; $vramTotal = 0 }
$ramGb = $null; if ($regRam -match '(\d+)\s*GB') { $ramGb = [int]$Matches[1] }
$sizeGb = $sel.expected_file_size_gb
$vramTotalGb = if ($vramTotal) { [math]::Round($vramTotal/1024,1) } else { 0 }
$vramEachGb  = if ($vramEach)  { [math]::Round($vramEach/1024,1)  } else { 0 }

$cudaVer = $null; $drvVer = $null
$driverFile = Join-Path $hostDir 'driver-results.md'
if (Test-Path $driverFile) {
    $d = Get-Content $driverFile -Raw
    if ($d -match 'CUDA Version:\s*([\d.]+)')   { $cudaVer = $Matches[1] }
    if ($d -match 'Driver Version:\s*([\d.]+)') { $drvVer  = $Matches[1] }
}

Write-Host 'Host evidence:'
Add-Finding 'GPU topology' 'PASS' "$gpuCount x GPU, $vramEach MiB each (~$vramEachGb GB), $vramTotal MiB aggregate"
if ($cudaVer) { Add-Finding 'Backend' 'PASS' "CUDA $cudaVer, driver $drvVer (as-built)" }
else          { Add-Finding 'Backend' 'BLOCKED' 'no as-built CUDA evidence' }

# --- MODE 1: full-resident CUDA tensor-parallel ---------------------------------------
Write-Host ''
Write-Host 'MODE 1  full residency / CUDA tensor-parallel' -ForegroundColor Cyan
if (-not $sel.quantization) {
    Add-Finding 'cuda_model_residency' 'BLOCKED' 'no exact artifact selected'
    $mode1 = 'BLOCKED'
} else {
    Add-Finding 'cuda_model_residency' 'FAIL' `
        "artifact ~$sizeGb GB vs $vramTotal MiB (~$vramTotalGb GB) aggregate across $gpuCount GPU(s); upstream states two cards do not have enough memory for these Flash models and CUDA refuses to start if layers would spill to CPU"
    $mode1 = 'FAIL'
}

# --- MODE 2: CUDA SSD streaming, single GPU -------------------------------------------
Write-Host ''
Write-Host 'MODE 2  CUDA SSD streaming / single GPU' -ForegroundColor Cyan
$ssd = $wl.execution_modes.cuda_ssd_streaming_single_gpu
if ($gpuCount -lt 1) {
    Add-Finding 'gpu for ssd-streaming' 'FAIL' 'no discrete GPU present'
    $mode2 = 'FAIL'
} else {
    Add-Finding 'gpu for ssd-streaming' 'PASS' `
        "single GPU required; host provides $gpuCount x ~$vramEachGb GB - PASS for initial SSD-streaming trial (mainline rejects multi-GPU SSD streaming)"
    Add-Finding 'initial cache / context' 'PASS' `
        "conservative commissioning values recorded: expert cache $($ssd.initial_settings.ssd_streaming_cache_experts_gb) GB, context $($ssd.initial_settings.context)"
    Add-Finding 'ssd_streaming residency' 'CANDIDATE' `
        'routed-expert portion need not stay resident; non-streamed tensors + KV + graph scratch must still fit one GPU - LIVE VALIDATION REQUIRED'
    $mode2 = 'CANDIDATE'
}

# --- system RAM: scoped, never conflated ----------------------------------------------
Write-Host ''
Write-Host 'Shared dimensions:' -ForegroundColor Cyan
$refRam = $wl.requirements.documented_reference_target.system_ram_gb
Add-Finding 'System RAM' 'SCOPED' `
    "$ramGb GB - NOT a full-residency pass (reference target $refRam GB); NOT an automatic SSD-streaming fail: streaming exists so the model need not be cached whole in RAM"

# --- storage gate: gates the download --------------------------------------------------
$sg = $wl.storage_gate
if ($sg.measured_free_gb) {
    if ($sg.measured_free_gb -ge $sg.requirements.minimum_free_gb) {
        Add-Finding 'NVMe storage gate' 'PASS' "$($sg.measured_free_gb) GB free on $($sg.target_filesystem)"
        $storage = 'PASS'
    } else {
        Add-Finding 'NVMe storage gate' 'FAIL' "$($sg.measured_free_gb) GB free is below the $($sg.requirements.minimum_free_gb) GB minimum"
        $storage = 'FAIL'
    }
} else {
    Add-Finding 'NVMe storage gate' 'MUST VERIFY' `
        "artifact ~$sizeGb GB + build + KV/state + logs + reserve; need >$($sg.requirements.minimum_free_gb) GB free on the fast NVMe hosting the GGUF. Registry: $regStorage. Under streaming the device is in the inference path, not cold storage"
    $storage = 'MUST VERIFY'
}

if ($wl.concurrency.assume_coexistence -eq $false -and $assignedWl) {
    Add-Finding 'Coexistence' 'BLOCKED' "host already carries an assigned workload ('$assignedWl'); combined residency measured, never assumed"
}

# --- summary ---------------------------------------------------------------------------
Write-Host ''
Write-Host '-----------------------------------------'
Write-Host '  RESULT BY EXECUTION MODE' -ForegroundColor Cyan
Write-Host ("    full residency / CUDA TP      : {0}" -f $mode1) -ForegroundColor $(if($mode1 -eq 'FAIL'){'Red'}else{'Yellow'})
Write-Host ("    CUDA SSD streaming / 1 GPU    : {0}" -f $mode2) -ForegroundColor $(if($mode2 -eq 'CANDIDATE'){'Cyan'}else{'Red'})
Write-Host ''
Write-Host ("  MODEL DOWNLOAD : {0}" -f $(if ($storage -eq 'PASS') { 'AUTHORIZED - storage gate passed' } else { "NOT AUTHORIZED - NVMe storage gate $storage" })) -ForegroundColor $(if($storage -eq 'PASS'){'Green'}else{'Yellow'})
Write-Host ("  Deployment host is fixed: {0}. Host selection is not part of this decision." -f $TargetHost) -ForegroundColor DarkGray
Write-Host ("  Durable role unchanged  : {0}" -f $durableRole) -ForegroundColor DarkGray
Write-Host '========================================='
Write-Host ''

if ($mode2 -eq 'CANDIDATE' -and $storage -eq 'PASS') { exit 0 }
elseif ($mode2 -eq 'FAIL')                          { exit 1 }
else                                                { exit 3 }
