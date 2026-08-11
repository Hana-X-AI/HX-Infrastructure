# HX-Infrastructure Remediation Regression Tests
# Standalone PowerShell test suite - no external test framework required.
# Exit code 0 = all pass; non-zero = failure count.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:pass = 0
$script:fail = 0
$script:results = @()

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
    $process.StandardInput.WriteLine(($Payload | ConvertTo-Json -Depth 12 -Compress))
    $process.StandardInput.Close()
    $stdout = $process.StandardOutput.ReadToEnd().Trim()
    $stderr = $process.StandardError.ReadToEnd().Trim()
    $process.WaitForExit()

    return [pscustomobject]@{
        ExitCode = $process.ExitCode
        StdOut = $stdout
        StdErr = $stderr
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

$actionLog = Get-Content "$root\governance\actions-and-issues.md" -Raw
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
Assert-True "rem-008: Phase 2 transitions are defined" (
    $regText -match 'BLOCKED.*READY.*only after the fleet-wide Phase 1 gate is complete' -and
    $regText -match 'IN PROGRESS.*approved role configuration starts' -and
    $regText -match 'COMPLETE.*configuration\.md.*role validation.*complete'
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
