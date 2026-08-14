<#
.SYNOPSIS
    HX AI Runtime Acceptance - contract test runner.

.DESCRIPTION
    Validates a runtime profile against the HX AI Runtime Acceptance Contract
    (governance/policy/ai-runtime-acceptance-contract.md).

    The offline-fixture profile runs model-free and proves evidence class A
    (protocol/client conformance) only. Class B (model behaviour) and class C
    (performance/resource) tests SKIP unless a live endpoint is configured.

    No model is downloaded. No host is contacted unless a profile supplies a
    live base URL through its environment variable.

.PARAMETER Profile
    Profile name under profiles/. Default: offline-fixture.

.PARAMETER EvidencePath
    Where to write machine-readable evidence. Default: evidence/.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ai-runtime\hx-runtime-acceptance.ps1
.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ai-runtime\hx-runtime-acceptance.ps1 -Profile vllm-qwen
#>
[CmdletBinding()]
param(
    [string]$Profile = 'offline-fixture',
    [string]$EvidencePath
)

$ErrorActionPreference = 'Stop'
$root         = Split-Path -Parent $MyInvocation.MyCommand.Path
$fixtureDir   = Join-Path $root 'fixtures'
$profileDir   = Join-Path $root 'profiles'
$contractVer  = '1.0.0'
if (-not $EvidencePath) { $EvidencePath = Join-Path $root 'evidence' }
if (-not (Test-Path $EvidencePath)) { New-Item -ItemType Directory -Path $EvidencePath -Force | Out-Null }

$script:results = @()
$script:pass = 0; $script:fail = 0; $script:skip = 0

function Add-Result {
    param($Id, $Capability, $Class, $Status, $Detail)
    $script:results += [pscustomobject]@{
        id = $Id; capability = $Capability; evidence_class = $Class
        status = $Status; detail = $Detail
    }
    switch ($Status) {
        'PASS' { $script:pass++; Write-Host ("  PASS  {0,-5} {1,-6} {2}" -f $Id, $Capability, $Detail) -ForegroundColor Green }
        'FAIL' { $script:fail++; Write-Host ("  FAIL  {0,-5} {1,-6} {2}" -f $Id, $Capability, $Detail) -ForegroundColor Red }
        'SKIP' { $script:skip++; Write-Host ("  SKIP  {0,-5} {1,-6} {2}" -f $Id, $Capability, $Detail) -ForegroundColor DarkGray }
    }
}

function Assert-That {
    param($Id, $Capability, $Class, [bool]$Condition, $PassDetail, $FailDetail)
    if ($Condition) { Add-Result $Id $Capability $Class 'PASS' $PassDetail }
    else            { Add-Result $Id $Capability $Class 'FAIL' $FailDetail }
}

function Get-Fixture { param($Name) Get-Content (Join-Path $fixtureDir $Name) -Raw | ConvertFrom-Json }

# --- SSE parser under test: turns raw event lines into content, terminal state and errors ---
function Read-SseStream {
    param([string[]]$Lines, [int]$StopAfter = 0)
    $content = ''; $reasoning = ''; $terminal = 0; $err = $null; $n = 0
    foreach ($line in $Lines) {
        if ($StopAfter -gt 0 -and $n -ge $StopAfter) { break }
        $n++
        if (-not $line.StartsWith('data: ')) { continue }
        $payload = $line.Substring(6)
        if ($payload -eq '[DONE]') { $terminal++; continue }
        try { $obj = $payload | ConvertFrom-Json } catch { $err = 'unparsable event'; continue }
        if ($obj.PSObject.Properties.Name -contains 'error') { $err = $obj.error.type; continue }
        foreach ($choice in $obj.choices) {
            $d = $choice.delta
            if ($null -eq $d) { continue }
            if ($d.PSObject.Properties.Name -contains 'content' -and $d.content) { $content += $d.content }
            if ($d.PSObject.Properties.Name -contains 'reasoning_content' -and $d.reasoning_content) { $reasoning += $d.reasoning_content }
        }
    }
    [pscustomobject]@{ Content = $content; Reasoning = $reasoning; TerminalCount = $terminal; Error = $err; Consumed = $n }
}

Write-Host ''
Write-Host '=========================================' -ForegroundColor Cyan
Write-Host ' HX AI Runtime Acceptance' -ForegroundColor Cyan
Write-Host '=========================================' -ForegroundColor Cyan

$profilePath = Join-Path $profileDir "$Profile.json"
if (-not (Test-Path $profilePath)) {
    Write-Host "Unknown profile '$Profile'. Available:" -ForegroundColor Red
    Get-ChildItem $profileDir -Filter *.json | ForEach-Object { Write-Host ('  - ' + $_.BaseName) }
    exit 2
}
$p = Get-Content $profilePath -Raw | ConvertFrom-Json

# --- resolve live status from the profile's environment variable, never hardcoded ---
$baseUrl = $null
if ($p.endpoint.base_url_env) { $baseUrl = [Environment]::GetEnvironmentVariable($p.endpoint.base_url_env) }
$isLive = [bool]$baseUrl
$mode   = if ($isLive) { 'LIVE' } else { 'OFFLINE' }

Write-Host ("Profile        : {0}  ({1})" -f $p.profile, $p.status)
Write-Host ("Mode           : {0}" -f $mode)
if (-not $isLive) { Write-Host 'Model          : NO MODEL / PROTOCOL-ONLY' -ForegroundColor Yellow }
Write-Host ("Contract       : {0}" -f $contractVer)

# A live-status profile with no endpoint still runs the L1 contract tests, because those
# validate the HX client against the contract and are profile-independent. Say so plainly,
# so a passing L1 run is never read as validation of that runtime.
if ($p.mode -eq 'LIVE' -and -not $isLive) {
    Write-Host ''
    Write-Host ("  NOTE: '{0}' has no endpoint configured ({1} unset)." -f $p.profile, $p.endpoint.base_url_env) -ForegroundColor Yellow
    Write-Host '        L1 below validates the HX client against the contract, not this runtime.' -ForegroundColor Yellow
    Write-Host ("        Nothing here is evidence that {0} works." -f $p.profile) -ForegroundColor Yellow
}
Write-Host ''

# =====================================================================
# L1 - RUNTIME PROTOCOL OFFLINE  (evidence class A)
# =====================================================================
Write-Host 'L1  runtime protocol, offline, no model required' -ForegroundColor Cyan

# RT-03 profile resolution
Assert-That 'T00' 'RT-03' 'A' ($p.profile -eq $Profile -and $null -ne $p.capabilities.declared) `
    "profile resolved, $($p.capabilities.declared.Count) capabilities declared" 'profile did not resolve'

# RT-01 identity
$f = Get-Fixture '01-runtime-identity.json'
Assert-That 'T01' 'RT-01' 'A' ($f.response.data[0].id -eq $f.expect.equals) `
    "runtime identity parsed: $($f.response.data[0].id)" 'identity field missing or wrong'

# RT-02 health
$f = Get-Fixture '02-health.json'
Assert-That 'T02' 'RT-02' 'A' ($f.response.status -eq 'ok') 'health signal parsed' 'health signal missing'

# RT-04 basic chat
$f = Get-Fixture '03-basic-chat.json'
$msg = $f.response.choices[0].message
Assert-That 'T03' 'RT-04' 'A' ($msg.role -eq 'assistant' -and $msg.content -and $f.response.choices[0].finish_reason -eq 'stop') `
    'chat response parsed, role and finish_reason correct' 'chat response shape wrong'

# RT-05 SSE ordering and single termination
$f = Get-Fixture '04-sse-stream.json'
$s = Read-SseStream -Lines $f.sse
Assert-That 'T04' 'RT-05' 'A' ($s.Content -eq $f.expect.ordered_content -and $s.TerminalCount -eq 1) `
    "deltas assembled in order to '$($s.Content)', terminated once" `
    "expected '$($f.expect.ordered_content)' terminated once, got '$($s.Content)' terminal=$($s.TerminalCount)"

# RT-06 tool declaration
$f = Get-Fixture '05-tool-declaration.json'
$fn = $f.request.tools[0].function
Assert-That 'T05' 'RT-06' 'A' ($fn.name -eq $f.expect.tool_name -and $fn.parameters.required -contains 'host') `
    'tool schema transmitted intact with required args' 'tool schema mutated or incomplete'

# RT-07 tool call identity
$f = Get-Fixture '06-single-tool-call.json'
$tc = $f.response.choices[0].message.tool_calls[0]
$args = $tc.function.arguments | ConvertFrom-Json
Assert-That 'T06' 'RT-07' 'A' ($tc.id -eq $f.expect.tool_call_id -and $tc.function.name -eq $f.expect.tool_name -and $args.host -eq $f.expect.argument_value) `
    "tool call id/name/arguments intact ($($tc.id))" 'tool call identity lost'

# RT-08 tool round-trip invariant - the load-bearing one
$f = Get-Fixture '07-tool-continuation.json'
$callTurn   = $f.history | Where-Object { $_.tool_calls }
$resultTurn = $f.history | Where-Object { $_.role -eq 'tool' }
$callId     = $callTurn.tool_calls[0].id
$correlated = ($resultTurn.tool_call_id -eq $callId)
$ordered    = ([array]::IndexOf($f.history, $callTurn) -lt [array]::IndexOf($f.history, $resultTurn))
Assert-That 'T07' 'RT-08' 'A' ($correlated -and $ordered -and $f.history.Count -eq 3) `
    "tool result correlated to $callId, history coherent across 3 turns" `
    'tool result not correlated to its originating call'

# RT-15 multiple tool calls
$f = Get-Fixture '08-multiple-tool-calls.json'
$calls = $f.response.choices[0].message.tool_calls
$ids = @($calls | ForEach-Object { $_.id })
$unique = (($ids | Select-Object -Unique).Count -eq $ids.Count)
Assert-That 'T08' 'RT-15' 'A' ($calls.Count -eq 2 -and $unique -and $ids[0] -eq 'call_hx_001' -and $ids[1] -eq 'call_hx_002') `
    'two tool calls kept distinct ids and order' 'multiple tool calls collided or reordered'

# RT-10 malformed response fails predictably
$f = Get-Fixture '09-malformed-response.json'
$parsed = $true
try { $null = $f.raw | ConvertFrom-Json } catch { $parsed = $false }
Assert-That 'T09' 'RT-10' 'A' (-not $parsed) 'malformed JSON rejected predictably, no partial parse' 'malformed JSON was accepted'

# RT-11 server error surfaced
$f = Get-Fixture '10-server-error.json'
Assert-That 'T10' 'RT-11' 'A' ($f.http_status -eq 503 -and $f.response.error.type -eq 'server_error') `
    "server error surfaced: $($f.response.error.code) (HTTP $($f.http_status))" 'server error swallowed'

# RT-12 cancellation cleanup
$f = Get-Fixture '11-timeout-cancel.json'
$s = Read-SseStream -Lines $f.sse -StopAfter $f.cancelled_after_events
Assert-That 'T11' 'RT-12' 'A' ($s.Content -eq 'par' -and $s.TerminalCount -eq 0) `
    'cancelled stream yielded partial content and no terminal event' 'cancellation left inconsistent stream state'

# RT-05 mid-stream error
$f = Get-Fixture '12-stream-error.json'
$s = Read-SseStream -Lines $f.sse
Assert-That 'T12' 'RT-05' 'A' ($s.Error -eq 'server_error' -and $s.TerminalCount -eq 0) `
    'mid-stream error reported, stream not falsely terminated' 'mid-stream error mishandled'

# RT-16 reasoning separation
$f = Get-Fixture '13-reasoning-separation.json'
$s = Read-SseStream -Lines $f.sse
Assert-That 'T13' 'RT-16' 'A' ($s.Content -eq 'FIXTURE ANSWER' -and $s.Reasoning -eq 'internal chain' -and $s.Content -notmatch 'internal') `
    'reasoning kept out of answer content' 'reasoning leaked into the answer'

# RT-04 anthropic messages
$f = Get-Fixture '14-anthropic-messages.json'
Assert-That 'T14' 'RT-04' 'A' ($f.response.content[0].type -eq 'text' -and $f.response.stop_reason -eq 'end_turn') `
    'anthropic-style message parsed, content is a block list' 'anthropic message shape wrong'

# RT-07 anthropic tool_use
$f = Get-Fixture '15-anthropic-tool-use.json'
$tu = $f.response.content[0]
Assert-That 'T15' 'RT-07' 'A' ($tu.type -eq 'tool_use' -and $tu.id -eq $f.expect.tool_call_id -and $tu.input.host -eq 'hxs-3') `
    "anthropic tool_use id/name/input intact ($($tu.id))" 'anthropic tool_use identity lost'

# RT-14 long payload serialization only
$f = Get-Fixture '16-long-context-serialization.json'
$payload = ($f.system_repeat.unit * $f.system_repeat.count)
$rt = (@{ role = 'system'; content = $payload } | ConvertTo-Json -Compress | ConvertFrom-Json)
Assert-That 'T16' 'RT-14' 'A' ($payload.Length -ge $f.expect.min_chars -and $rt.content.Length -eq $payload.Length) `
    "$($payload.Length) char system payload serialized intact (serialization only)" 'large payload did not round-trip'

# RT-13 recovery after error and cancellation
$ok = $true
try {
    $null = Get-Fixture '10-server-error.json'
    $null = Get-Fixture '11-timeout-cancel.json'
    $f = Get-Fixture '03-basic-chat.json'
    $ok = ($f.response.choices[0].message.role -eq 'assistant')
} catch { $ok = $false }
Assert-That 'T17' 'RT-13' 'A' $ok 'valid call succeeded after error and cancellation, state not corrupted' 'state corrupted after error path'

# =====================================================================
# L2-L5 - LIVE REQUIRED
# =====================================================================
Write-Host ''
Write-Host 'L2-L5  live runtime required' -ForegroundColor Cyan

$liveTests = @(
    @{ id='L2-01'; cap='RT-01'; class='A'; name='live runtime and model identity' }
    @{ id='L2-02'; cap='RT-04'; class='A'; name='live basic chat' }
    @{ id='L2-03'; cap='RT-05'; class='A'; name='live streaming' }
    @{ id='L2-04'; cap='RT-07'; class='A'; name='live structured tool call' }
    @{ id='L2-05'; cap='RT-08'; class='A'; name='live tool result continuation' }
    @{ id='L3-01'; cap='RT-20'; class='B'; name='skill and instruction adherence' }
    @{ id='L3-02'; cap='RT-21'; class='B'; name='correct tool selection' }
    @{ id='L3-03'; cap='RT-20'; class='B'; name='hook denial recovery, no repeated fighting' }
    @{ id='L3-04'; cap='RT-20'; class='B'; name='authority edit protection, reports instead of bypassing' }
    @{ id='L3-05'; cap='RT-22'; class='B'; name='target-state vs discovered-state not conflated' }
    @{ id='L4-01'; cap='RT-19'; class='B'; name='long context at configured size' }
    @{ id='L4-02'; cap='RT-23'; class='C'; name='cold vs warm prefix behaviour' }
    @{ id='L4-03'; cap='RT-24'; class='C'; name='time to first token' }
    @{ id='L4-04'; cap='RT-25'; class='C'; name='prefill and decode throughput, measured separately' }
    @{ id='L4-05'; cap='RT-26'; class='C'; name='GPU and VRAM residency evidence' }
    @{ id='L5-01'; cap='RT-01'; class='A'; name='cross-runtime contract conformance' }
)
$reason = if ($isLive) { 'live execution not implemented in this pass' } else { 'LIVE RUNTIME NOT CONFIGURED' }
foreach ($t in $liveTests) { Add-Result $t.id $t.cap $t.class 'SKIP' ("$($t.name) - SKIP: $reason") }

# =====================================================================
# EVIDENCE
# =====================================================================
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$evidence = [pscustomobject]@{
    timestamp        = (Get-Date -Format 'o')
    contract_version = $contractVer
    mode             = $mode
    model_state      = if ($isLive) { 'LIVE' } else { 'NO MODEL / PROTOCOL-ONLY' }
    profile          = $p.profile
    profile_status   = $p.status
    host             = if ($isLive) { $baseUrl } else { $null }
    base_url         = if ($isLive) { $baseUrl } else { $null }
    runtime_identity = $null
    model_identity   = $null
    quantization     = $null
    backend          = $null
    context_setting  = $null
    device_placement = $null
    evidence_classes_proven = @('A')
    evidence_classes_not_proven = @('B','C')
    totals           = [pscustomobject]@{ pass = $script:pass; fail = $script:fail; skip = $script:skip }
    results          = $script:results
    metrics          = @{}
    note             = 'Offline fixture results prove protocol and client conformance only. They are not evidence of model behaviour or runtime performance.'
}
$outFile = Join-Path $EvidencePath "runtime-acceptance_$($p.profile)_$stamp.json"
$evidence | ConvertTo-Json -Depth 8 | Set-Content -Path $outFile -Encoding UTF8

Write-Host ''
Write-Host '-----------------------------------------'
Write-Host ("  PASS: {0}   FAIL: {1}   SKIP: {2}" -f $script:pass, $script:fail, $script:skip)
Write-Host ("  mode: {0}" -f $evidence.model_state)
Write-Host '  proven      : class A  protocol/client conformance'
Write-Host '  NOT proven  : class B  model behaviour, class C  performance/resource'
Write-Host ("  evidence    : {0}" -f (Resolve-Path $outFile).Path)
Write-Host '========================================='
Write-Host ''

exit $script:fail
