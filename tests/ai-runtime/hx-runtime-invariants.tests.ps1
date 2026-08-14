<#
.SYNOPSIS
    Repository-side invariants for the AI runtime workstream.

.DESCRIPTION
    Proves the guarantees the workstream depends on, with no model and no host.
    These are the checks that stop the architecture drifting back into the mistakes
    it was built to avoid.

    Exit code is the failure count.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$here     = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $here '..\..')
$pass = 0; $fail = 0

function Test-Invariant {
    param([string]$Name, [scriptblock]$Body)
    try {
        $r = & $Body
        if ($r -eq $true) { $script:pass++; Write-Host ("  PASS  {0}" -f $Name) -ForegroundColor Green }
        else { $script:fail++; Write-Host ("  FAIL  {0}" -f $Name) -ForegroundColor Red
               if ($r -is [string]) { Write-Host ("        {0}" -f $r) -ForegroundColor DarkRed } }
    } catch {
        $script:fail++; Write-Host ("  FAIL  {0}" -f $Name) -ForegroundColor Red
        Write-Host ("        {0}" -f $_.Exception.Message) -ForegroundColor DarkRed
    }
}

Write-Host ''
Write-Host '=========================================' -ForegroundColor Cyan
Write-Host ' AI Runtime Workstream Invariants' -ForegroundColor Cyan
Write-Host '=========================================' -ForegroundColor Cyan

$wl  = Get-Content (Join-Path $here 'workloads\ds4-deepseek.json') -Raw | ConvertFrom-Json
$pr  = Get-Content (Join-Path $here 'profiles\ds4-deepseek.json')  -Raw | ConvertFrom-Json
$vq  = Get-Content (Join-Path $here 'profiles\vllm-qwen.json')     -Raw | ConvertFrom-Json
$reg = Get-Content (Join-Path $repoRoot 'SERVER-REGISTRY.md') -Raw
$contract = Get-Content (Join-Path $repoRoot 'governance\policy\ai-runtime-acceptance-contract.md') -Raw

Test-Invariant 'ds4-deepseek workload remains EXPERIMENTAL' {
    if ($wl.classification -eq 'EXPERIMENTAL') { $true } else { "classification is '$($wl.classification)'" } }

Test-Invariant 'ds4-deepseek profile remains EXPERIMENTAL' {
    if ($pr.status -eq 'EXPERIMENTAL') { $true } else { "status is '$($pr.status)'" } }

Test-Invariant 'vllm-qwen remains PRIMARY' {
    if ($vq.status -eq 'PRIMARY') { $true } else { "status is '$($vq.status)'" } }

Test-Invariant 'EXPERIMENTAL is scoped to the workload, not a server' {
    if ($wl.classification_scope -match 'not to any physical server') { $true }
    else { 'classification_scope does not exclude the server' } }

Test-Invariant 'hxs-3 durable role comes from SERVER-REGISTRY.md' {
    $row = ($reg -split "`n") | Where-Object { $_ -match '^\|\s*hxs-3\s*\|' } | Select-Object -First 1
    if (-not $row) { return 'hxs-3 not in registry' }
    $role = ($row -split '\|')[9].Trim()
    if ($role -and $role -notmatch 'DS4|DeepSeek|experimental') { $true }
    else { "registry role for hxs-3 is '$role'" } }

Test-Invariant 'no DS4 or workload profile redefines a host role' {
    $bad = @()
    Get-ChildItem (Join-Path $here 'workloads') -Filter *.json | ForEach-Object {
        $j = Get-Content $_.FullName -Raw | ConvertFrom-Json
        if ($j.PSObject.Properties.Name -contains 'durable_role') { $bad += $_.Name }
        if ($j.PSObject.Properties.Name -contains 'host_role')    { $bad += $_.Name }
    }
    if ($bad.Count -eq 0) { $true } else { "workload files assert a host role: $($bad -join ', ')" } }

Test-Invariant 'runtime contract stays engine-neutral: no host, IP or model' {
    if ($contract -match 'hxs-\d' -or $contract -match '192\.168\.') { 'contract names a host or IP' } else { $true } }

Test-Invariant 'no model weights tracked in Git' {
    Push-Location $repoRoot
    $tracked = git ls-files | Where-Object { $_ -match '\.(gguf|safetensors|bin|pt|pth)$' }
    Pop-Location
    if (-not $tracked) { $true } else { "tracked weight files: $($tracked -join ', ')" } }

Test-Invariant 'model acquisition records weights are not in Git' {
    if ($wl.model_acquisition.weights_in_git -eq $false) { $true } else { 'weights_in_git is not false' } }

Test-Invariant 'capacity gate supports PASS, FAIL and BLOCKED' {
    $src = Get-Content (Join-Path $here 'hx-capacity-gate.ps1') -Raw
    $ok = ($src -match "'PASS'") -and ($src -match "'FAIL'") -and ($src -match "'BLOCKED'")
    $exits = ($src -match 'exit 0') -and ($src -match 'exit 1') -and ($src -match 'exit 3')
    if ($ok -and $exits) { $true } else { 'gate does not implement all three verdicts with distinct exit codes' } }

Test-Invariant 'live tests SKIP when no live runtime is configured' {
    $src = Get-Content (Join-Path $here 'hx-runtime-acceptance.ps1') -Raw
    if ($src -match 'LIVE RUNTIME NOT CONFIGURED') { $true } else { 'no explicit not-configured skip reason' } }

Test-Invariant 'model identity and checksum are required before OPERATIONAL' {
    $src = Get-Content (Join-Path $here 'hx-ds4-commission.ps1') -Raw
    $ok = ($src -match 'checksum_sha256') -and ($src -match 'no exact model and quantization selected')
    if ($ok) { $true } else { 'commissioning does not require model identity and checksum' } }

Test-Invariant 'commissioning states are not collapsed' {
    $src = Get-Content (Join-Path $here 'hx-ds4-commission.ps1') -Raw
    $states = 'INSTALLED','MODEL SELECTED','CAPACITY APPROVED','MODEL ACQUIRED','CLI VERIFIED',
              'VENDOR TESTS PASSED','LOCAL SERVER VERIFIED','API VERIFIED','KV VERIFIED',
              'HX CONTRACT VERIFIED','MANAGED WORKLOAD','NETWORK VERIFIED','CLIENT VERIFIED'
    $missing = $states | Where-Object { $src -notmatch [regex]::Escape($_) }
    if (-not $missing) { $true } else { "missing states: $($missing -join ', ')" } }

Test-Invariant 'capacity gate result is bound to the exact artifact' {
    $src = Get-Content (Join-Path $here 'hx-ds4-commission.ps1') -Raw
    $ok = ($src -match 'verdict_for_model') -and ($src -match 'verdict_for_quantization') -and ($src -match 'STALE')
    if ($ok) { $true } else { 'a stale capacity verdict would not reopen the gate' } }

Test-Invariant 'tool fidelity tests stay engine-neutral' {
    $f = Get-Content (Join-Path $here 'fixtures\07-tool-continuation.json') -Raw
    if ($f -match 'DSML') { 'fixture encodes a DS4-specific format' } else { $true } }

Test-Invariant 'no Ansible anywhere in the workstream' {
    # exclude this file: it names the tool in order to forbid it
    $self = $MyInvocation.ScriptName
    $hits = Get-ChildItem $here -Recurse -File -Include *.ps1,*.json,*.md |
            Where-Object { $_.FullName -ne $self -and $_.Name -ne 'hx-runtime-invariants.tests.ps1' } |
            Select-String -Pattern 'ansible' -SimpleMatch -CaseSensitive:$false |
            Where-Object { $_.Line -notmatch 'never|not |no ansible|prohibit|out of scope' }
    if (-not $hits) { $true } else { "ansible referenced: $($hits[0].Path):$($hits[0].LineNumber)" } }

Test-Invariant 'no second host or IP inventory created' {
    $hits = Get-ChildItem $here -Recurse -File -Include *.ps1,*.json |
            Select-String -Pattern '192\.168\.\d+\.\d+'
    if (-not $hits) { $true } else { "hardcoded IP in $($hits[0].Path)" } }

Test-Invariant 'no credentials or secrets in profiles, workloads or fixtures' {
    $hits = Get-ChildItem $here -Recurse -File -Include *.json |
            Select-String -Pattern '(api[_-]?key|password|secret|token)\s*[:=]\s*"[A-Za-z0-9]{8,}"'
    if (-not $hits) { $true } else { "possible secret in $($hits[0].Path)" } }

Test-Invariant 'endpoints resolve from environment, never hardcoded' {
    $ok = $true
    Get-ChildItem (Join-Path $here 'profiles') -Filter *.json | ForEach-Object {
        $j = Get-Content $_.FullName -Raw | ConvertFrom-Json
        if ($j.endpoint.base_url) { $ok = "profile $($j.profile) hardcodes a base_url" }
    }
    $ok }

Test-Invariant 'workload switch preserves other runtime configuration' {
    if ($wl.isolation.config_separate_from -contains 'vllm' -and
        $wl.isolation.removable_without_host_rebuild -eq $true) { $true }
    else { 'workload does not guarantee isolated, removable configuration' } }

Test-Invariant 'network exposure is gated behind local validation' {
    if ($wl.server.network_exposed -eq $false -and $wl.server.listen_address -eq '127.0.0.1') { $true }
    else { 'workload does not default to loopback with exposure gated' } }

Test-Invariant 'no Docling or LangGraph work on this branch' {
    Push-Location $repoRoot
    $diff = git diff --name-only bb629f4 HEAD 2>$null
    Pop-Location
    $bad = $diff | Where-Object { $_ -match 'docling|langgraph|manifestv3|provenance-index' }
    if (-not $bad) { $true } else { "contaminating paths: $($bad -join ', ')" } }

Test-Invariant 'DS4 upstream source is not vendored' {
    Push-Location $repoRoot
    $tracked = git ls-files | Where-Object { $_ -match 'ds4-main/' }
    Pop-Location
    if (-not $tracked) { $true } else { "$($tracked.Count) DS4 source files are tracked" } }

Write-Host ''
Write-Host '-----------------------------------------'
Write-Host ("  PASS: {0}   FAIL: {1}" -f $pass, $fail)
Write-Host '========================================='
Write-Host ''
exit $fail
