. "$PSScriptRoot\hx-common.ps1"

# Permanent policy guard.
#
# Enforces prohibitions that hold in EVERY phase. This hook must never consult
# Phase 2 state: a permanent prohibition that lapses when a phase opens is not
# permanent. It is deliberately narrow - it is not a shell allowlist, and it does
# not duplicate the destructive-storage rules already owned by permissions.deny
# or the phase-scoped rules owned by hx-phase1-guard.ps1.

$inputObject = Read-HxHookInput

$tool = [string](Get-HxInputProperty $inputObject "tool_name")
if ($tool -ne "Bash" -and $tool -ne "PowerShell") {
    exit 0
}

$toolInput = Get-HxInputProperty $inputObject "tool_input"
$command = ""
if ($null -ne $toolInput -and $null -ne $toolInput.PSObject.Properties["command"]) {
    $command = [string]$toolInput.command
}
if ([string]::IsNullOrWhiteSpace($command)) {
    exit 0
}

$denyReason = $null

# Ansible is permanently outside the HX execution model. The validated native
# Bash/SSH fan-out pattern remains the authoritative fleet-control baseline.
# Ruled out by the owner 2026-08-13; see governance/logs/actions-and-issues.md.
# Match only in COMMAND position - start of line, or after a shell separator -
# with an optional sudo/env prefix. Matching the bare word anywhere would deny
# 'grep -r ansible .', which is exactly the work of removing Ansible references.
$ansiblePattern = '(?im)(?:^|[;&|]|&&|\|\|)\s*(?:sudo\s+)?(?:env\s+\S+=\S+\s+)*(?:ansible|ansible-playbook|ansible-galaxy|ansible-vault|ansible-config|ansible-inventory|ansible-doc)\b'

if ($command -match $ansiblePattern) {
    $denyReason = "Ansible is permanently out of scope for HX in every phase, not deferred. The authoritative fleet-control baseline is native Bash/SSH fan-out. Use that instead; do not reintroduce Ansible in scripts, plans, examples or recommendations."
}

if ($null -ne $denyReason) {
    Write-HxJson @{
        hookSpecificOutput = @{
            hookEventName = "PreToolUse"
            permissionDecision = "deny"
            permissionDecisionReason = $denyReason
        }
    }
    exit 0
}

exit 0
