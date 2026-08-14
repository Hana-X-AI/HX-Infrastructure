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

$vq  = Get-Content (Join-Path $here 'profiles\vllm-qwen.json')     -Raw | ConvertFrom-Json
$qw  = Get-Content (Join-Path $here 'workloads\qwen35-9b-ollama.json') -Raw | ConvertFrom-Json
$reg = Get-Content (Join-Path $repoRoot 'SERVER-REGISTRY.md') -Raw
$contract = Get-Content (Join-Path $repoRoot 'governance\policy\ai-runtime-acceptance-contract.md') -Raw
# Loaded tolerantly on purpose. If this record is deleted the suite must FAIL the invariant
# that depends on it, not crash before any invariant runs - a crash reads as a broken test.
$decisionsPath = Join-Path $repoRoot 'governance\policy\runtime-acceptance-decisions.md'
$decisions = ''
if (Test-Path $decisionsPath) { $decisions = Get-Content $decisionsPath -Raw }

Test-Invariant 'vllm-qwen remains PRIMARY' {
    if ($vq.status -eq 'PRIMARY') { $true } else { "status is '$($vq.status)'" } }

Test-Invariant 'commissioning refuses to run for a deferred workload' {
    $src = Get-Content (Join-Path $here 'hx-workload-commission.ps1') -Raw
    if ($src -match "DEFERRED\|ABORTED" -and $src -match 'Commissioning is DISABLED') { $true }
    else { 'driver would still walk gates for a deferred workload' } }

Test-Invariant 'runtime contract stays engine-neutral: no host, IP or model' {
    if ($contract -match 'hxs-\d' -or $contract -match '192\.168\.') { 'contract names a host or IP' } else { $true } }

Test-Invariant 'no model weights tracked in Git' {
    Push-Location $repoRoot
    $tracked = git ls-files | Where-Object { $_ -match '\.(gguf|safetensors|bin|pt|pth)$' }
    Pop-Location
    if (-not $tracked) { $true } else { "tracked weight files: $($tracked -join ', ')" } }

Test-Invariant 'capacity gate supports PASS, FAIL and BLOCKED' {
    $src = Get-Content (Join-Path $here 'hx-capacity-gate.ps1') -Raw
    $ok = ($src -match "'PASS'") -and ($src -match "'FAIL'") -and ($src -match "'BLOCKED'")
    $exits = ($src -match 'exit 0') -and ($src -match 'exit 1') -and ($src -match 'exit 3')
    if ($ok -and $exits) { $true } else { 'gate does not implement all three verdicts with distinct exit codes' } }

Test-Invariant 'live tests SKIP when no live runtime is configured' {
    $src = Get-Content (Join-Path $here 'hx-runtime-acceptance.ps1') -Raw
    if ($src -match 'LIVE RUNTIME NOT CONFIGURED') { $true } else { 'no explicit not-configured skip reason' } }

Test-Invariant 'model identity and checksum are required before OPERATIONAL' {
    $src = Get-Content (Join-Path $here 'hx-workload-commission.ps1') -Raw
    $ok = ($src -match 'checksum_sha256') -and ($src -match 'no exact model and quantization selected')
    if ($ok) { $true } else { 'commissioning does not require model identity and checksum' } }

Test-Invariant 'capacity gate result is bound to the exact artifact' {
    $src = Get-Content (Join-Path $here 'hx-workload-commission.ps1') -Raw
    $ok = ($src -match 'verdict_for_model') -and ($src -match 'verdict_for_quantization') -and ($src -match 'STALE')
    if ($ok) { $true } else { 'a stale capacity verdict would not reopen the gate' } }

Test-Invariant 'system RAM is not conflated with CUDA device memory' {
    $src = Get-Content (Join-Path $here 'hx-capacity-gate.ps1') -Raw
    if ($src -match 'NOT a full-residency pass' -and $src -match 'NOT an automatic SSD-streaming fail') { $true }
    else { 'gate does not scope the system RAM finding' } }

Test-Invariant 'runtime acceptance layer is preserved' {
    $keep = @('hx-runtime-acceptance.ps1','hx-capacity-gate.ps1','hx-workload-commission.ps1','README.md')
    $missing = $keep | Where-Object { -not (Test-Path (Join-Path $here $_)) }
    if (-not $missing) { $true } else { "missing: $($missing -join ', ')" } }

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
    if ($qw.isolation.config_separate_from -contains 'vllm' -and
        $qw.isolation.removable_without_host_rebuild -eq $true) { $true }
    else { 'workload does not guarantee isolated, removable configuration' } }

Test-Invariant 'network exposure is gated behind local validation' {
    if ($qw.network_exposure.state -match 'LOOPBACK' -and $qw.network_exposure.listener -match '^127\.0\.0\.1') { $true }
    else { 'workload does not default to loopback with exposure gated' } }

# Superseded by consolidation. This began as a BRANCH-ISOLATION guard: while the
# runtime-acceptance work lived on its own branch, any Docling or LangGraph path in
# its diff meant the workstreams had bled together. On a consolidated main that test
# is obsolete by construction - main legitimately carries all three workstreams - so
# it is replaced by the property the guard actually existed to protect: the runtime
# acceptance layer stays engine- and service-neutral, and does not couple itself to
# any one service design.
Test-Invariant 'AI runtime layer stays neutral: no service-design coupling' {
    # Scope: the CONTRACT and the GATES must stay neutral. Workload and profile records
    # are excluded by design - naming the intended client is exactly what they are for.
    $hits = Get-ChildItem $here -Recurse -File -Include *.ps1 |
            Where-Object { $_.Name -ne 'hx-runtime-invariants.tests.ps1' } |
            Select-String -Pattern 'docling|langgraph|lightrag|mem0' -CaseSensitive:$false |
            Where-Object { $_.Line -notmatch 'never|not |no |prohibit|out of scope|neutral' }
    $contractHits = $contract -split "`n" | Where-Object {
        $_ -match '(?i)docling|langgraph|lightrag|mem0' -and $_ -notmatch '(?i)never|not |no |prohibit|out of scope|neutral' }
    if (-not $hits -and -not $contractHits) { $true }
    elseif ($hits) { "a gate references a service design: $($hits[0].Path):$($hits[0].LineNumber)" }
    else { "the contract references a service design: $($contractHits[0])" } }

Test-Invariant 'Qwen3.5-9B IS accepted for local utility inference' {
    $a = $qw.acceptance_states.A_qwen_local_runtime_operational
    $b = $qw.acceptance_states.B_hx_validation_operational
    if ($a -match 'REACHED' -and $b -match 'REACHED') { $true }
    else { 'the accepted-for states were weakened; re-measure before narrowing them' } }

Test-Invariant 'Qwen3.5-9B is NOT accepted as a Claude Code backend' {
    $c = $qw.acceptance_states.C_claude_code_qualified
    $v = $qw.claude_code_qualification.verdict
    if ($c -match 'NOT REACHED' -and $v -eq 'NOT QUALIFIED') { $true }
    else { "Claude Code acceptance was widened to '$v'. That requires NEW measured evidence: a window with real headroom above the ~28,440-token baseline, and overflow that errors instead of truncating. See iss-016." } }

Test-Invariant 'the evidence for refusing Claude Code is preserved' {
    if ($qw.claude_code_qualification.blocking_reasons.Count -ge 3 -and
        $qw.context_overflow_behavior.behavior_on_overflow -match 'SILENT') { $true }
    else { 'the blocking reasons or the silent-truncation finding were removed - the verdict cannot be audited without them' } }

Test-Invariant 'the acceptance decision is recorded in durable governance' {
    if ($decisions -match 'NOT ACCEPTED' -and $decisions -match 'Claude Code' -and
        $decisions -match 'qwen35-9b-ollama') { $true }
    else { 'governance/policy/runtime-acceptance-decisions.md no longer records the Qwen verdict' } }

Write-Host ''
Write-Host '-----------------------------------------'
Write-Host ("  PASS: {0}   FAIL: {1}" -f $pass, $fail)
Write-Host '========================================='
Write-Host ''
exit $fail
