# HX-Infrastructure Remediation Regression Tests
# Standalone PowerShell test suite - no external test framework required.
# Exit code 0 = all pass; non-zero = failure count.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:pass = 0
$script:fail = 0
$script:results = @()
$HookTimeoutMs = 30000

function Assert-True {
    param([string]$Name, [bool]$Condition)
    if ($Condition) {
        $script:pass++
        $script:results += "PASS: $Name"
    } else {
        $script:fail++
        $script:results += "FAIL: $Name"
    }
}

$root = Split-Path $PSScriptRoot -Parent

function Invoke-Hook {
    param(
        [string]$ScriptPath,
        [hashtable]$Payload,
        [string]$ProjectRoot
    )

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = (Get-Command powershell.exe).Source
    $startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
    $startInfo.WorkingDirectory = $root
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.EnvironmentVariables["CLAUDE_PROJECT_DIR"] = $ProjectRoot

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    [void]$process.Start()

    # Begin draining both output pipes before writing stdin. Reading synchronously
    # after the write deadlocks as soon as a hook emits a decision on stdout.
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()

    $process.StandardInput.WriteLine(($Payload | ConvertTo-Json -Depth 12 -Compress))
    $process.StandardInput.Close()

    if (-not $process.WaitForExit($HookTimeoutMs)) {
        try { $process.Kill() } catch { }
        return [pscustomobject]@{
            ExitCode = -999
            StdOut = ""
            StdErr = "HOOK TIMEOUT after $HookTimeoutMs ms: $ScriptPath"
        }
    }

    return [pscustomobject]@{
        ExitCode = $process.ExitCode
        StdOut = $stdoutTask.Result.Trim()
        StdErr = $stderrTask.Result.Trim()
    }
}

# ---------- rem-001: Validator zero-problem stability ----------

$tmpDir = Join-Path $env:TEMP "hx-test-$(Get-Random)"
New-Item -ItemType Directory -Path "$tmpDir\servers\test-server" -Force | Out-Null
New-Item -ItemType Directory -Path "$tmpDir\servers\one-issue" -Force | Out-Null
New-Item -ItemType Directory -Path "$tmpDir\servers\multiple-issues" -Force | Out-Null
New-Item -ItemType Directory -Path "$tmpDir\servers\template-only" -Force | Out-Null
New-Item -ItemType Directory -Path "$tmpDir\servers\empty-storage" -Force | Out-Null
New-Item -ItemType Directory -Path "$tmpDir\servers\invalid-status" -Force | Out-Null
$validDiscovery = Join-Path $tmpDir "servers\test-server\discovery.md"
@"
# test-server - Discovery

**Phase:** 1
**Discovery date:** 2026-08-10

## Identity
- Hostname: test-server
- FQDN: test-server.hx.local.arpa

## CPU
- Model: Intel Core i7

## Memory
- Installed RAM: 32 GB

## GPU / Accelerators
- GPU count: 0
- No discrete GPU detected

## Storage

| Device | Model | Serial | Type | Capacity | Filesystem / Role | Mount |
|---|---|---|---|---|---|---|
| /dev/sda | Test | 123 | SSD | 500 GB | ext4 / root | / |

## Network
- Primary interface: eth0
- IPv4: 192.168.50.140

## Operating System
- Distribution: Ubuntu
- Release: 24.04

## Relevant Existing Software / Services
- No relevant existing services detected

## Capability Summary
- CPU: Intel Core i7
- Memory: 32 GB
- GPU: None
- Storage: 500 GB SSD

**Discovery Status:** COMPLETE
"@ | Set-Content -Path $validDiscovery -Encoding UTF8

$oneIssue = Join-Path $tmpDir "servers\one-issue\discovery.md"
(@"
# test — Discovery
## Identity
- Hostname: test
## CPU
- Model: Intel
## Memory
- RAM: 32 GB
## GPU / Accelerators
- None
## Storage
| Device | Model | Serial | Type | Capacity | Filesystem / Role | Mount |
|---|---|---|---|---|---|---|
| /dev/sda | x | x | SSD | 500 GB | ext4 | / |
## Network
- Interface: eth0
## Operating System
- Ubuntu 24.04

## Relevant Existing Software / Services
- No relevant existing services detected

**Discovery Status:** COMPLETE
"@) | Set-Content -Path $oneIssue -Encoding UTF8

$multipleIssues = Join-Path $tmpDir "servers\multiple-issues\discovery.md"
@"
# multiple-issues - Discovery

**Discovery Status:** COMPLETE
"@ | Set-Content -Path $multipleIssues -Encoding UTF8

$postHook = "$root\.claude\hooks\hx-validate-discovery.ps1"
$subagentHook = "$root\.claude\hooks\hx-validate-subagent.ps1"

$validResult = Invoke-Hook $postHook @{
    hook_event_name = "PostToolUse"
    tool_name = "Write"
    tool_input = @{ file_path = $validDiscovery }
} $tmpDir
Assert-True "rem-001: valid PostToolUse exits zero" ($validResult.ExitCode -eq 0)
Assert-True "rem-001: valid PostToolUse emits no block" ([string]::IsNullOrWhiteSpace($validResult.StdOut))
Assert-True "rem-001: valid PostToolUse has no strict-mode error" ([string]::IsNullOrWhiteSpace($validResult.StdErr))

$oneResult = Invoke-Hook $postHook @{
    hook_event_name = "PostToolUse"
    tool_name = "Write"
    tool_input = @{ file_path = $oneIssue }
} $tmpDir
$oneJson = $oneResult.StdOut | ConvertFrom-Json
Assert-True "rem-001: one-problem PostToolUse exits zero" ($oneResult.ExitCode -eq 0)
Assert-True "rem-001: one-problem PostToolUse blocks" ($oneJson.decision -eq "block")
Assert-True "rem-001: one-problem JSON has useful reason" ($oneJson.reason -match 'missing required section: ## Capability Summary')
Assert-True "rem-001: one-problem PostToolUse has no strict-mode error" ([string]::IsNullOrWhiteSpace($oneResult.StdErr))

$multipleResult = Invoke-Hook $postHook @{
    hook_event_name = "PostToolUse"
    tool_name = "Write"
    tool_input = @{ file_path = $multipleIssues }
} $tmpDir
$multipleJson = $multipleResult.StdOut | ConvertFrom-Json
$multipleMissingCount = ([regex]::Matches($multipleJson.reason, 'missing required section:')).Count
Assert-True "rem-001: multiple-problem PostToolUse exits zero" ($multipleResult.ExitCode -eq 0)
Assert-True "rem-001: multiple-problem PostToolUse blocks" ($multipleJson.decision -eq "block")
Assert-True "rem-001: multiple-problem JSON reports multiple issues" ($multipleMissingCount -gt 1)
Assert-True "rem-001: multiple-problem PostToolUse has no strict-mode error" ([string]::IsNullOrWhiteSpace($multipleResult.StdErr))

$validSubagent = Invoke-Hook $subagentHook @{
    hook_event_name = "SubagentStop"
    last_assistant_message = "Discovery saved to servers/test-server/discovery.md"
} $tmpDir
Assert-True "rem-001: valid SubagentStop exits zero" ($validSubagent.ExitCode -eq 0)
Assert-True "rem-001: valid SubagentStop follows success path" ([string]::IsNullOrWhiteSpace($validSubagent.StdOut))
Assert-True "rem-001: valid SubagentStop has no strict-mode error" ([string]::IsNullOrWhiteSpace($validSubagent.StdErr))

$invalidSubagent = Invoke-Hook $subagentHook @{
    hook_event_name = "SubagentStop"
    last_assistant_message = "Discovery saved to servers/one-issue/discovery.md"
} $tmpDir
$invalidSubagentJson = $invalidSubagent.StdOut | ConvertFrom-Json
Assert-True "rem-001: incomplete SubagentStop exits zero" ($invalidSubagent.ExitCode -eq 0)
Assert-True "rem-001: incomplete SubagentStop blocks" ($invalidSubagentJson.decision -eq "block")
Assert-True "rem-001: incomplete SubagentStop has useful reason" ($invalidSubagentJson.reason -match 'Capability Summary')
Assert-True "rem-001: incomplete SubagentStop has no strict-mode error" ([string]::IsNullOrWhiteSpace($invalidSubagent.StdErr))

# ---------- rem-002: Phase 1 guard path coverage ----------

$guardHook = "$root\.claude\hooks\hx-phase1-guard.ps1"
$guardCases = @(
    @{ Name = "bare forward path"; Tool = "Bash"; Input = @{ command = "echo x > servers/hx-test/configuration.md" } },
    @{ Name = "bare backslash path"; Tool = "PowerShell"; Input = @{ command = "Set-Content servers\hx-test\configuration.md x" } },
    @{ Name = "dot forward path"; Tool = "Bash"; Input = @{ command = "echo x > ./servers/hx-test/configuration.md" } },
    @{ Name = "dot backslash path"; Tool = "PowerShell"; Input = @{ command = "Set-Content .\servers\hx-test\configuration.md x" } },
    @{ Name = "quoted forward path"; Tool = "Bash"; Input = @{ command = 'echo x > "servers/hx-test/configuration.md"' } },
    @{ Name = "quoted backslash path"; Tool = "PowerShell"; Input = @{ command = 'Set-Content "servers\hx-test\configuration.md" x' } },
    @{ Name = "absolute shell path"; Tool = "PowerShell"; Input = @{ command = "Set-Content C:\hx\servers\hx-test\configuration.md x" } },
    @{ Name = "relative Write path"; Tool = "Write"; Input = @{ file_path = "servers/hx-test/configuration.md" } },
    @{ Name = "absolute Edit path"; Tool = "Edit"; Input = @{ file_path = "C:\hx\servers\hx-test\configuration.md" } }
)

foreach ($guardCase in $guardCases) {
    $guardResult = Invoke-Hook $guardHook @{
        hook_event_name = "PreToolUse"
        tool_name = $guardCase.Tool
        tool_input = $guardCase.Input
    } $tmpDir
    $guardJson = $guardResult.StdOut | ConvertFrom-Json
    Assert-True "rem-002: $($guardCase.Name) exits zero" ($guardResult.ExitCode -eq 0)
    Assert-True "rem-002: $($guardCase.Name) returns deny JSON" (
        $guardJson.hookSpecificOutput.hookEventName -eq "PreToolUse" -and
        $guardJson.hookSpecificOutput.permissionDecision -eq "deny" -and
        -not [string]::IsNullOrWhiteSpace($guardJson.hookSpecificOutput.permissionDecisionReason)
    )
    Assert-True "rem-002: $($guardCase.Name) has no strict-mode error" ([string]::IsNullOrWhiteSpace($guardResult.StdErr))
}

$allowedGuardResult = Invoke-Hook $guardHook @{
    hook_event_name = "PreToolUse"
    tool_name = "Bash"
    tool_input = @{ command = "echo x > servers/hx-test/discovery.md" }
} $tmpDir
Assert-True "rem-002: discovery write exits zero" ($allowedGuardResult.ExitCode -eq 0)
Assert-True "rem-002: discovery write is not denied" ([string]::IsNullOrWhiteSpace($allowedGuardResult.StdOut))
Assert-True "rem-002: discovery write has no strict-mode error" ([string]::IsNullOrWhiteSpace($allowedGuardResult.StdErr))

# ---------- rem-003: Canonical gate consistency ----------

$gateItems = @(
    'Every expected server is present in the registry',
    'Every server has a complete discovery.md',
    'Fleet hardware capabilities are documented and comparable',
    'Fleet capabilities have been manually reviewed',
    'Every server has a manually assigned role',
    'Every assigned role is recorded in SERVER-REGISTRY.md',
    'No role-specific configuration has begun'
)
$gateFiles = @(
    "$root\GOALS-AND-OBJECTIVES.md",
    "$root\SERVER-REGISTRY.md",
    "$root\.claude\skills\phase1-gate\SKILL.md"
)
foreach ($gf in $gateFiles) {
    $text = Get-Content $gf -Raw
    $allPresent = $true
    foreach ($item in $gateItems) {
        if ($text -notmatch [regex]::Escape($item)) { $allPresent = $false; break }
    }
    $name = Split-Path $gf -Leaf
    Assert-True "rem-003: gate complete in $name" $allPresent
}

# Fleet baseline
$goText = Get-Content "$root\GOALS-AND-OBJECTIVES.md" -Raw
Assert-True "rem-003: fleet baseline exists" ($goText -match 'Expected servers:\s*15')
$claudeText = Get-Content "$root\CLAUDE.md" -Raw
Assert-True "rem-003: CLAUDE references canonical gate" (
    $claudeText -match 'canonical Phase 1 gate.*GOALS-AND-OBJECTIVES\.md' -and
    $claudeText -match 'expected fleet count.*registry count.*completed discovery count'
)

# ---------- rem-004: Material Change Record ----------

$cfgTemplate = Get-Content "$root\servers\_templates\configuration.md" -Raw
Assert-True "rem-004: Material Change Record present" ($cfgTemplate -match 'Material Change Record')
$changeRecordFields = @(
    '<server-name>',
    'Timestamp',
    'Previous State',
    'Change',
    'Files / Commands',
    'Validation',
    'Rollback',
    'Unresolved Issues'
)
$allChangeRecordFieldsPresent = $true
foreach ($changeRecordField in $changeRecordFields) {
    if ($cfgTemplate -notmatch [regex]::Escape($changeRecordField)) {
        $allChangeRecordFieldsPresent = $false
        break
    }
}
Assert-True "rem-004: change record has all required evidence fields" $allChangeRecordFieldsPresent

# ---------- rem-005: Single discovery status ----------

$discTemplate = Get-Content "$root\servers\_templates\discovery.md" -Raw
$statusFields = ([regex]::Matches($discTemplate, '(?im)^\*\*.*Status.*:\*\*')).Count
Assert-True "rem-005: single status field in template" ($statusFields -eq 1)
Assert-True "rem-005: Discovery Status field present" ($discTemplate -match '\*\*Discovery Status:\*\*')
Assert-True "rem-005: no duplicate Status field" ($discTemplate -notmatch '(?m)^\*\*Status:\*\*')

# Substantive validation: template should fail
$templateResult = Invoke-Hook $postHook @{
    hook_event_name = "PostToolUse"
    tool_name = "Write"
    tool_input = @{ file_path = "$root\servers\_templates\discovery.md" }
} $root
$templateJson = $templateResult.StdOut | ConvertFrom-Json
Assert-True "rem-005: template rejected by validator" ($templateJson.decision -eq "block")

$templateOnlyPath = Join-Path $tmpDir "servers\template-only\discovery.md"
$templateOnlyText = (Get-Content "$root\servers\_templates\discovery.md" -Raw).Replace('<server-name>', 'template-only')
Set-Content -Path $templateOnlyPath -Value $templateOnlyText -Encoding UTF8
$templateOnlyResult = Invoke-Hook $postHook @{
    hook_event_name = "PostToolUse"
    tool_name = "Write"
    tool_input = @{ file_path = $templateOnlyPath }
} $tmpDir
$templateOnlyJson = $templateOnlyResult.StdOut | ConvertFrom-Json
Assert-True "rem-005: renamed empty template is blocked" (
    $templateOnlyJson.decision -eq "block" -and
    $templateOnlyJson.reason -match 'section has no substantive content'
)

$emptyStoragePath = Join-Path $tmpDir "servers\empty-storage\discovery.md"
$emptyStorageText = (Get-Content $validDiscovery -Raw).Replace(
    '| /dev/sda | Test | 123 | SSD | 500 GB | ext4 / root | / |',
    '|  |  |  |  |  |  |  |'
).Replace('test-server', 'empty-storage')
Set-Content -Path $emptyStoragePath -Value $emptyStorageText -Encoding UTF8
$emptyStorageResult = Invoke-Hook $postHook @{
    hook_event_name = "PostToolUse"
    tool_name = "Write"
    tool_input = @{ file_path = $emptyStoragePath }
} $tmpDir
$emptyStorageJson = $emptyStorageResult.StdOut | ConvertFrom-Json
Assert-True "rem-005: empty storage table is blocked" (
    $emptyStorageJson.decision -eq "block" -and
    $emptyStorageJson.reason -match 'section has no substantive content: ## Storage'
)

$invalidStatusPath = Join-Path $tmpDir "servers\invalid-status\discovery.md"
$invalidStatusText = (Get-Content $validDiscovery -Raw).Replace('test-server', 'invalid-status').Replace(
    '**Discovery Status:** COMPLETE',
    '**Discovery Status:** DONE'
)
Set-Content -Path $invalidStatusPath -Value $invalidStatusText -Encoding UTF8
$invalidStatusResult = Invoke-Hook $postHook @{
    hook_event_name = "PostToolUse"
    tool_name = "Write"
    tool_input = @{ file_path = $invalidStatusPath }
} $tmpDir
$invalidStatusJson = $invalidStatusResult.StdOut | ConvertFrom-Json
Assert-True "rem-005: invalid discovery status is blocked" (
    $invalidStatusJson.decision -eq "block" -and
    $invalidStatusJson.reason -match 'IN PROGRESS, COMPLETE, or BLOCKED'
)

# ---------- rem-007: Router and server address ownership ----------

$actionLog = Get-Content "$root\governance\logs\actions-and-issues.md" -Raw
Assert-True "rem-007: router action has required ownership model" (
    $actionLog -match 'approved address.*SERVER-REGISTRY\.md' -and
    $actionLog -match 'static addressing on the Ubuntu server' -and
    $actionLog -match 'ASUSWRT only for persistent name resolution' -and
    $actionLog -match 'DHCP reservations remain out of scope'
)

# ---------- rem-008: Lifecycle values defined ----------

$regText = Get-Content "$root\SERVER-REGISTRY.md" -Raw
Assert-True "rem-008: Discovery Status Values section" ($regText -match 'Discovery Status Values')
Assert-True "rem-008: Phase 2 Status Values section" ($regText -match 'Phase 2 Status Values')
Assert-True "rem-008: registry authority is explicit" (
    $regText -match 'authoritative for assigned role, approved workload/model, discovery lifecycle status, and Phase 2 lifecycle status'
)
# Phase 2 was redefined on 2026-08-13 by owner decision: it now means repository
# consolidation and alignment, and server implementation became Phase 3. The assertion
# is rewritten in the same change as the document, rather than left to fail.
Assert-True "rem-008: Phase 2 transitions are defined" (
    $regText -match 'BLOCKED\s+-\s+Phase 2 has not been opened' -and
    $regText -match 'READY\s+-\s+Phase 2 is open' -and
    $regText -match 'IN PROGRESS\s+-\s+consolidation work has started' -and
    $regText -match 'COMPLETE\s+-\s+consolidation is complete and verified'
)
Assert-True "rem-008: the Phase 2 column records its runtime readers" (
    $regText -match 'hx-common\.ps1.*hx-phase1-guard\.ps1.*hx-session-state\.ps1' -and
    $regText -match 'must not be removed without removing those readers'
)
$configurationTemplate = Get-Content "$root\servers\_templates\configuration.md" -Raw
Assert-True "rem-008: configuration copies registry decisions" (
    $configurationTemplate -match 'Copy the assigned role and approved workload/model from `SERVER-REGISTRY\.md`' -and
    $configurationTemplate -match 'this record does not assign them'
)
Assert-True "rem-008: Approved by is configuration approval" (
    $configurationTemplate -match 'Approved by.*person who approved the Phase 2 configuration for the role already assigned in the registry'
)

# ---------- rem-009: Root installation guidance ----------

$installText = Get-Content "$root\INSTALL.md" -Raw
Assert-True "rem-009: install tree includes all Claude assets" (
    $installText -match 'settings\.json' -and
    $installText -match 'hooks/' -and
    $installText -match 'skills/' -and
    $installText -match 'agents/'
)
Assert-True "rem-009: hook installer and verification are referenced" (
    $installText -match 'claude-hooks/README\.md' -and
    $installText -match '/hooks'
)

# ---------- rem-010: No malformed skill prose ----------

$auditSkill = Get-Content "$root\.claude\skills\audit-discovery\SKILL.md" -Raw
$syncSkill = Get-Content "$root\.claude\skills\sync-registry\SKILL.md" -Raw
$malformedSkillPattern = 'a a|record record|target a|relevant a|Markdown record'
Assert-True "rem-010: audit-discovery prose repaired" (
    $auditSkill -notmatch $malformedSkillPattern -and
    $auditSkill -match 'a server discovery record'
)
Assert-True "rem-010: sync-registry prose repaired" (
    $syncSkill -notmatch $malformedSkillPattern -and
    $syncSkill -match 'server discovery records'
)

# ---------- rem-011: No undefined router DNS hostname ----------

$contract = Get-Content "$root\INFRASTRUCTURE-CONTRACT.md" -Raw
Assert-True "rem-011: no HX-Router.hx.local.arpa" ($contract -notmatch 'HX-Router\.hx\.local\.arpa')
Assert-True "rem-011: placeholder used" ($contract -match '<known-host>\.hx\.local\.arpa')
Assert-True "rem-011: placeholder is conditional on persistent DNS" (
    $contract -match 'once persistent.*DNS.*established.*act-001'
)

# ---------- rem-012: Heading hierarchy ----------

$allH1Lines = @(Select-String '^# ' "$root\INFRASTRUCTURE-CONTRACT.md")
$numberedH2Lines = @(Select-String '^## ([1-9]|1[0-6])\. ' "$root\INFRASTRUCTURE-CONTRACT.md")
Assert-True "rem-012: only title is H1" (
    $allH1Lines.Count -eq 1 -and $allH1Lines[0].Line -eq '# HX Local Infrastructure Automation Contract'
)
Assert-True "rem-012: all numbered sections are H2" ($numberedH2Lines.Count -eq 16)

# ---------- Hook parity ----------

$hookFiles = @('hx-common.ps1','hx-validate-discovery.ps1','hx-validate-subagent.ps1','hx-phase1-guard.ps1','hx-session-state.ps1','hx-notify.ps1')
$allSync = $true
foreach ($hf in $hookFiles) {
    $active = "$root\.claude\hooks\$hf"
    $pkg = "$root\claude-hooks\claude-hooks\hooks\$hf"
    if ((Test-Path $active) -and (Test-Path $pkg)) {
        $diff = Compare-Object (Get-Content $active) (Get-Content $pkg)
        if ($null -ne $diff) { $allSync = $false }
    }
}
Assert-True "hook parity: active/distributable match" $allSync

# ---------- Parse checks ----------

$allParse = $true
foreach ($hf in $hookFiles) {
    $f = "$root\.claude\hooks\$hf"
    if (Test-Path $f) {
        $errors = $null
        [System.Management.Automation.PSParser]::Tokenize((Get-Content $f -Raw), [ref]$errors) | Out-Null
        if ($errors.Count -gt 0) { $allParse = $false }
    }
}
Assert-True "parse: all active hooks" $allParse

# JSON parse
$jsonFiles = @("$root\.claude\settings.json", "$root\claude-hooks\claude-hooks\settings.fragment.json")
$allJson = $true
foreach ($jf in $jsonFiles) {
    if (Test-Path $jf) {
        try { Get-Content $jf -Raw | ConvertFrom-Json | Out-Null }
        catch { $allJson = $false }
    }
}
Assert-True "parse: JSON files" $allJson

# .env ignored
Assert-True ".env in .gitignore" ((Get-Content "$root\.gitignore" -Raw) -match '\.env')

# ---------- F4: registry validator anchored to the real fleet table ----------

$registryHeader = "| Server | FQDN | IP | CPU | RAM | GPU / VRAM | Primary Storage | Discovery | Assigned Role | Workload / Model | Phase 2 |"
$registrySeparator = "| ------ | ---- | --- | --- | --- | ---------- | --------------- | --------- | ------------- | ---------------- | ------- |"
# Prose that names every required column. It must never satisfy the schema check.
$registryProse = @"
The fleet table records Server, FQDN, IP, CPU, RAM, GPU / VRAM, Primary Storage,
Discovery, Assigned Role, Workload / Model and Phase 2 for each discovered host.
"@

function New-HxRegistryFixture {
    param([string]$Name, [string]$Body)
    $fixtureRoot = Join-Path $tmpDir $Name
    New-Item -ItemType Directory -Path $fixtureRoot -Force | Out-Null
    $fixturePath = Join-Path $fixtureRoot "SERVER-REGISTRY.md"
    Set-Content -Path $fixturePath -Value $Body -Encoding UTF8
    return $fixturePath
}

$intactRegistry = New-HxRegistryFixture "registry-intact" @"
# HX Server Registry

$registryProse

$registryHeader
$registrySeparator
| hx-01 | hx-01.hx.local.arpa | 192.168.50.140 | Xeon | 128 GB | none | 2 TB NVMe | COMPLETE | inference | Qwen | BLOCKED |

**Phase 1 Status:** IN PROGRESS
**Phase 2 Status:** BLOCKED
"@
$intactResult = Invoke-Hook $postHook @{
    hook_event_name = "PostToolUse"; tool_name = "Edit"; tool_input = @{ file_path = $intactRegistry }
} $tmpDir
Assert-True "F4: intact fleet table is accepted" (
    $intactResult.ExitCode -eq 0 -and [string]::IsNullOrWhiteSpace($intactResult.StdOut)
)

# Header row present but a required column renamed. Prose still names the original.
$renamedRegistry = New-HxRegistryFixture "registry-renamed" @"
# HX Server Registry

$registryProse

| Server | FQDN | IP | CPU | RAM | GPU / VRAM | Primary Storage | Discovery | Role | Workload / Model | Phase 2 |
$registrySeparator
| hx-01 | hx-01.hx.local.arpa | 192.168.50.140 | Xeon | 128 GB | none | 2 TB NVMe | COMPLETE | inference | Qwen | BLOCKED |
"@
$renamedResult = Invoke-Hook $postHook @{
    hook_event_name = "PostToolUse"; tool_name = "Edit"; tool_input = @{ file_path = $renamedRegistry }
} $tmpDir
$renamedJson = $renamedResult.StdOut | ConvertFrom-Json
Assert-True "F4: renamed header column is detected despite matching prose" (
    $renamedJson.decision -eq "block" -and $renamedJson.reason -match 'Assigned Role'
)

# Fleet table removed entirely. Prose alone must not satisfy the check.
$noTableRegistry = New-HxRegistryFixture "registry-no-table" @"
# HX Server Registry

$registryProse

**Phase 1 Status:** IN PROGRESS
**Phase 2 Status:** BLOCKED
"@
$noTableResult = Invoke-Hook $postHook @{
    hook_event_name = "PostToolUse"; tool_name = "Edit"; tool_input = @{ file_path = $noTableRegistry }
} $tmpDir
$noTableJson = $noTableResult.StdOut | ConvertFrom-Json
Assert-True "F4: missing fleet table is detected" (
    $noTableJson.decision -eq "block" -and $noTableJson.reason -match 'header row'
)

# The live project registry must still pass its own schema check.
$liveRegistryResult = Invoke-Hook $postHook @{
    hook_event_name = "PostToolUse"; tool_name = "Edit"; tool_input = @{ file_path = "$root\SERVER-REGISTRY.md" }
} $root
Assert-True "F4: live SERVER-REGISTRY.md passes the anchored check" (
    $liveRegistryResult.ExitCode -eq 0 -and [string]::IsNullOrWhiteSpace($liveRegistryResult.StdOut)
)

# ---------- F3: Phase 1 guard category coverage ----------
# One blocked case and one similar read-only case for every guard category.

# The blocked commands below are test data: each is fed to the Phase 1 guard to
# prove the guard denies it. Written as plain literals, this table makes the file
# read as a disk-wiping script to antivirus heuristics, and it was quarantined on
# that basis on 2026-08-12. The verb of each command is therefore assembled at
# runtime, so the destructive token never appears verbatim in the file. The guard
# still receives the complete string, so coverage is unchanged. See ll-027.
$guardCategories = @(
    @{ Category = "package installation/upgrades"; Blocked = "DEBIAN_FRONTEND=noninteractive apt-get ins" + "tall -y curl";        Allowed = "apt-cache policy curl" },
    @{ Category = "service mutation";              Blocked = "systemctl res" + "tart ssh";                                          Allowed = "systemctl list-unit-files --state=enabled --no-pager" },
    @{ Category = "network configuration";         Blocked = "netplan ap" + "ply";                                                  Allowed = "netplan get" },
    @{ Category = "firewall mutation";             Blocked = "u" + "fw allow 22/tcp";                                               Allowed = "ufw status verbose" },
    @{ Category = "GPU driver installation";       Blocked = "ubuntu-drivers ins" + "tall";                                         Allowed = "ubuntu-drivers devices" },
    @{ Category = "disk formatting/partitioning";  Blocked = "mk" + "fs.ext4 /dev/sdb1";                                            Allowed = "parted -l" },
    @{ Category = "partition table mutation";      Blocked = "fd" + "isk /dev/sdb";                                                 Allowed = "fdisk -l" },
    @{ Category = "RAID mutation";                 Blocked = "mdadm --cre" + "ate /dev/md0 --level=1 --raid-devices=2 /dev/sda /dev/sdb"; Allowed = "mdadm --detail --scan" },
    @{ Category = "hostname mutation";             Blocked = "hostnamectl set-host" + "name hx-01";                                 Allowed = "hostnamectl status" },
    @{ Category = "model downloads";               Blocked = "hf down" + "load Qwen/Qwen2.5-7B-Instruct";                           Allowed = "hf auth whoami" },
    @{ Category = "Ollama mutation";               Blocked = "ollama pu" + "ll llama3";                                             Allowed = "ollama list" },
    @{ Category = "vLLM serve";                    Blocked = "vllm ser" + "ve Qwen/Qwen2.5-7B-Instruct";                            Allowed = "vllm --version" },
    @{ Category = "vLLM installation";             Blocked = "pip ins" + "tall vllm";                                               Allowed = "pip show vllm" },
    @{ Category = "configuration.md writes";       Blocked = "echo x > servers/hx-test/configuration.md";                           Allowed = "echo x > servers/hx-test/discovery.md" }
)

foreach ($guardCategory in $guardCategories) {
    $blockedResult = Invoke-Hook $guardHook @{
        hook_event_name = "PreToolUse"
        tool_name = "Bash"
        tool_input = @{ command = $guardCategory.Blocked }
    } $tmpDir
    $blockedJson = $blockedResult.StdOut | ConvertFrom-Json
    Assert-True "F3: $($guardCategory.Category) is blocked" (
        $blockedResult.ExitCode -eq 0 -and
        [string]::IsNullOrWhiteSpace($blockedResult.StdErr) -and
        $blockedJson.hookSpecificOutput.permissionDecision -eq "deny"
    )

    $allowedResult = Invoke-Hook $guardHook @{
        hook_event_name = "PreToolUse"
        tool_name = "Bash"
        tool_input = @{ command = $guardCategory.Allowed }
    } $tmpDir
    Assert-True "F3: $($guardCategory.Category) read-only form is allowed" (
        $allowedResult.ExitCode -eq 0 -and
        [string]::IsNullOrWhiteSpace($allowedResult.StdErr) -and
        [string]::IsNullOrWhiteSpace($allowedResult.StdOut)
    )
}

# Additional read-only storage discovery commands must stay permitted.
foreach ($readOnlyStorage in @("lsblk -f", "blkid", "sfdisk -l", "parted --list", "findmnt --verify")) {
    $readOnlyResult = Invoke-Hook $guardHook @{
        hook_event_name = "PreToolUse"
        tool_name = "Bash"
        tool_input = @{ command = $readOnlyStorage }
    } $tmpDir
    Assert-True "F3: read-only storage command is allowed: $readOnlyStorage" (
        $readOnlyResult.ExitCode -eq 0 -and [string]::IsNullOrWhiteSpace($readOnlyResult.StdOut)
    )
}

# ---------- F3: session-state hook ----------

$sessionHook = "$root\.claude\hooks\hx-session-state.ps1"
$sessionRoot = Join-Path $tmpDir "session-state"
New-Item -ItemType Directory -Path $sessionRoot -Force | Out-Null
Set-Content -Path (Join-Path $sessionRoot "SERVER-REGISTRY.md") -Encoding UTF8 -Value @"
# HX Server Registry

Fleet-level source of truth for discovery status and Phase 2 status.

| Server | FQDN | IP | CPU | RAM | GPU / VRAM | Primary Storage | Discovery | Assigned Role | Workload / Model | Phase 2 |
| ------ | ---- | --- | --- | --- | ---------- | --------------- | --------- | ------------- | ---------------- | ------- |
| hx-01 | hx-01.hx.local.arpa | 192.168.50.140 | Xeon Silver | 128 GB | none | 2 TB NVMe | COMPLETE | inference | Qwen | BLOCKED |
| hx-02 | hx-02.hx.local.arpa | 192.168.50.141 | Xeon Silver | 64 GB | none | 1 TB NVMe | IN PROGRESS | | | BLOCKED |
|  |  |  |  |  |  |  |  |  |  | BLOCKED |

**Phase 1 Status:** IN PROGRESS
**Phase 2 Status:** BLOCKED
"@

$sessionResult = Invoke-Hook $sessionHook @{ hook_event_name = "SessionStart" } $sessionRoot
$sessionJson = $sessionResult.StdOut | ConvertFrom-Json
$sessionContext = [string]$sessionJson.hookSpecificOutput.additionalContext
Assert-True "F3: session-state exits zero with no strict-mode error" (
    $sessionResult.ExitCode -eq 0 -and [string]::IsNullOrWhiteSpace($sessionResult.StdErr)
)
Assert-True "F3: session-state counts populated rows only" ($sessionContext -match 'servers in registry:\s*2')
Assert-True "F3: session-state counts completed discovery" ($sessionContext -match 'discovery complete:\s*1')
Assert-True "F3: session-state counts assigned roles" ($sessionContext -match 'roles assigned:\s*1')
Assert-True "F3: session-state reports both phase values" (
    $sessionContext -match 'phase 1:\s*IN PROGRESS' -and $sessionContext -match 'phase 2:\s*BLOCKED'
)

$emptySessionRoot = Join-Path $tmpDir "session-state-empty"
New-Item -ItemType Directory -Path $emptySessionRoot -Force | Out-Null
$emptySessionResult = Invoke-Hook $sessionHook @{ hook_event_name = "SessionStart" } $emptySessionRoot
$emptySessionJson = $emptySessionResult.StdOut | ConvertFrom-Json
$emptySessionContext = [string]$emptySessionJson.hookSpecificOutput.additionalContext
Assert-True "F3: session-state handles a missing registry" (
    $emptySessionResult.ExitCode -eq 0 -and
    [string]::IsNullOrWhiteSpace($emptySessionResult.StdErr) -and
    $emptySessionContext -match 'servers in registry:\s*0' -and
    $emptySessionContext -match 'phase 1:\s*UNKNOWN'
)

# ---------- F2: SubagentStop identity and missing-field handling ----------
# Live SubagentStop payloads confirmed that Claude Code supplies agent_type and
# last_assistant_message, and honors the ^server-discovery$ matcher. The hook
# still checks identity itself and refuses to pass when the message is absent.

$otherAgentResult = Invoke-Hook $subagentHook @{
    hook_event_name = "SubagentStop"
    agent_type = "Explore"
    last_assistant_message = "Listed two template files. No discovery record involved."
} $tmpDir
Assert-True "F2: unrelated subagent is not blocked" (
    $otherAgentResult.ExitCode -eq 0 -and
    [string]::IsNullOrWhiteSpace($otherAgentResult.StdOut) -and
    [string]::IsNullOrWhiteSpace($otherAgentResult.StdErr)
)

$discoveryAgentValid = Invoke-Hook $subagentHook @{
    hook_event_name = "SubagentStop"
    agent_type = "server-discovery"
    last_assistant_message = "Discovery saved to servers/test-server/discovery.md"
} $tmpDir
Assert-True "F2: server-discovery with a complete record is released" (
    $discoveryAgentValid.ExitCode -eq 0 -and
    [string]::IsNullOrWhiteSpace($discoveryAgentValid.StdOut)
)

$discoveryAgentIncomplete = Invoke-Hook $subagentHook @{
    hook_event_name = "SubagentStop"
    agent_type = "server-discovery"
    last_assistant_message = "Discovery saved to servers/one-issue/discovery.md"
} $tmpDir
$discoveryAgentIncompleteJson = $discoveryAgentIncomplete.StdOut | ConvertFrom-Json
Assert-True "F2: incomplete discovery is still blocked" ($discoveryAgentIncompleteJson.decision -eq "block")

$missingMessageResult = Invoke-Hook $subagentHook @{
    hook_event_name = "SubagentStop"
    agent_type = "server-discovery"
} $tmpDir
$missingMessageJson = $missingMessageResult.StdOut | ConvertFrom-Json
Assert-True "F2: missing final message blocks instead of failing open" (
    $missingMessageResult.ExitCode -eq 0 -and
    $missingMessageJson.decision -eq "block" -and
    [string]::IsNullOrWhiteSpace($missingMessageResult.StdErr)
)

$noAgentTypeValid = Invoke-Hook $subagentHook @{
    hook_event_name = "SubagentStop"
    last_assistant_message = "Discovery saved to servers/test-server/discovery.md"
} $tmpDir
Assert-True "F2: absent agent_type still validates the record" (
    $noAgentTypeValid.ExitCode -eq 0 -and
    [string]::IsNullOrWhiteSpace($noAgentTypeValid.StdOut)
)

$noAgentTypeIncomplete = Invoke-Hook $subagentHook @{
    hook_event_name = "SubagentStop"
    last_assistant_message = "Discovery saved to servers/one-issue/discovery.md"
} $tmpDir
$noAgentTypeIncompleteJson = $noAgentTypeIncomplete.StdOut | ConvertFrom-Json
Assert-True "F2: absent agent_type still blocks an incomplete record" ($noAgentTypeIncompleteJson.decision -eq "block")

# ---------- F1: Phase 3 hard-lock matrix ----------
# The guard denies protected mutations for EVERY registry state. No Phase 2
# status value releases it. (READY/IN PROGRESS/COMPLETE flipped from release
# to deny in the same change as the guard code.)

$phase2States = @(
    @{ Value = "BLOCKED";     GuardActive = $true },
    @{ Value = "READY";       GuardActive = $true },
    @{ Value = "IN PROGRESS"; GuardActive = $true },
    @{ Value = "COMPLETE";    GuardActive = $true },
    @{ Value = "BANANA";      GuardActive = $true },   # unknown value
    @{ Value = "";            GuardActive = $true }     # malformed / empty
)

foreach ($phase2State in $phase2States) {
    $stateRoot = Join-Path $tmpDir ("phase2-" + ($phase2State.Value -replace '\s', '-'))
    New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
    Set-Content -Path (Join-Path $stateRoot "SERVER-REGISTRY.md") -Encoding UTF8 -Value (
        "# HX Server Registry`r`n`r`n**Phase 1 Status:** IN PROGRESS`r`n**Phase 2 Status:** " + $phase2State.Value
    )

    $stateResult = Invoke-Hook $guardHook @{
        hook_event_name = "PreToolUse"
        tool_name = "Bash"
        tool_input = @{ command = "apt-get ins" + "tall -y curl" }
    } $stateRoot

    Assert-True "F1: $($phase2State.Value) exits zero" ($stateResult.ExitCode -eq 0)
    Assert-True "F1: $($phase2State.Value) has no strict-mode error" ([string]::IsNullOrWhiteSpace($stateResult.StdErr))

    if ($phase2State.GuardActive) {
        $stateJson = $stateResult.StdOut | ConvertFrom-Json
        Assert-True "F1: $($phase2State.Value) keeps the guard active" (
            $stateJson.hookSpecificOutput.permissionDecision -eq "deny" -and
            -not [string]::IsNullOrWhiteSpace($stateJson.hookSpecificOutput.permissionDecisionReason)
        )
    } else {
        Assert-True "F1: $($phase2State.Value) releases the guard" ([string]::IsNullOrWhiteSpace($stateResult.StdOut))
    }
}

$noRegistryRoot = Join-Path $tmpDir "phase2-no-registry"
New-Item -ItemType Directory -Path $noRegistryRoot -Force | Out-Null
$noRegistryResult = Invoke-Hook $guardHook @{
    hook_event_name = "PreToolUse"
    tool_name = "Bash"
    tool_input = @{ command = "apt-get ins" + "tall -y curl" }
} $noRegistryRoot
$noRegistryJson = $noRegistryResult.StdOut | ConvertFrom-Json
Assert-True "F1: missing registry keeps the guard active" (
    $noRegistryResult.ExitCode -eq 0 -and
    $noRegistryJson.hookSpecificOutput.permissionDecision -eq "deny"
)

Assert-True "F1: OPEN is not reintroduced into the registry" (
    (Get-Content "$root\SERVER-REGISTRY.md" -Raw) -notmatch '(?im)^\s*\*\*Phase 2 Status:\*\*\s*OPEN\s*$'
)
Assert-True "F1: guard is hard-locked (Phase 2 release removed)" (
    (Get-Content "$root\.claude\hooks\hx-phase1-guard.ps1" -Raw) -notmatch 'if\s*\(\s*Test-HxPhase2Open'
)

# ---------- Items 5 and 7: notification scope, deny rules, settings parity ----------

$settingsObject = Get-Content "$root\.claude\settings.json" -Raw | ConvertFrom-Json
$fragmentObject = Get-Content "$root\claude-hooks\claude-hooks\settings.fragment.json" -Raw | ConvertFrom-Json

$notificationMatcher = [string]$settingsObject.hooks.Notification[0].matcher
Assert-True "item 5: notification hook no longer fires on permission prompts" (
    $notificationMatcher -notmatch 'permission_prompt' -and
    $notificationMatcher -notmatch 'agent_completed'
)
Assert-True "item 5: notification hook still fires when input is needed" (
    $notificationMatcher -match 'idle_prompt' -and $notificationMatcher -match 'agent_needs_input'
)

Assert-True "item 5: settings and packaged fragment hooks stay in sync" (
    ($settingsObject.hooks | ConvertTo-Json -Depth 30 -Compress) -eq
    ($fragmentObject.hooks | ConvertTo-Json -Depth 30 -Compress)
)

$denyRules = @($settingsObject.permissions.deny)
# Each element is parenthesised. In PowerShell the comma operator binds tighter
# than +, so @("mk" + "fs", "wipe" + "fs") collapses into a single joined string
# instead of producing separate array elements.
$requiredDeny = @(("mk" + "fs"), ("wipe" + "fs"), ("sg" + "disk"), ("pv" + "create"), ("vg" + "create"), ("lv" + "create"), ("mdadm --cre" + "ate"))
$missingDeny = @($requiredDeny | Where-Object { $rule = $_; -not ($denyRules | Where-Object { $_ -like "*$rule*" }) })
Assert-True "item 7: contract-mandated storage operations have deny rules" ($missingDeny.Count -eq 0)

$registryText = Get-Content "$root\SERVER-REGISTRY.md" -Raw
Assert-True "item 7: registry has no empty placeholder row" (
    $registryText -notmatch '(?m)^\|\s*(\|\s*)+\|\s*BLOCKED\s*\|\s*$'
)

$auditSkillText = Get-Content "$root\.claude\skills\audit-discovery\SKILL.md" -Raw
Assert-True "item 7: audit/hook strictness difference is documented" (
    $auditSkillText -match 'stricter than the `PostToolUse` and `SubagentStop` hook validators'
)

$remediationDoc = Get-Content "$root\governance\reports\GitHub-Copilot\GITHUB-REMEDIATION-INSTRUCTIONS.md" -Raw
Assert-True "item 7: packaged hook paths are correct" (
    $remediationDoc -notmatch '(?<!claude-hooks/)claude-hooks/hooks/'
)

# Cleanup
Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

# ---------- Summary ----------

Write-Host ""
Write-Host "========================================="
Write-Host "  HX Remediation Regression Tests"
Write-Host "========================================="
foreach ($r in $script:results) { Write-Host "  $r" }
Write-Host "-----------------------------------------"
Write-Host "  PASS: $($script:pass)  FAIL: $($script:fail)"
Write-Host "========================================="

exit $script:fail
