. "$PSScriptRoot\hx-common.ps1"

# Permanent policy guard.
#
# Enforces prohibitions that hold in EVERY phase. This hook must never consult
# Phase 2 state: a permanent prohibition that lapses when a phase opens is not
# permanent. It is deliberately narrow - it is not a shell allowlist, and it does
# not duplicate the destructive-storage rules already owned by permissions.deny
# or the phase-scoped rules owned by hx-phase1-guard.ps1.

$inputObject = Read-HxHookInput

# Malformed input fails closed. This hook is registered only on the matcher
# Bash|PowerShell, so a payload that does not name one of those tools, or whose
# command cannot be read, is a shell call the guard was unable to screen.
# Allowing it is the fail-open path .claude/AGENTS.md forbids.

$denyReason = $null

$tool = [string](Get-HxInputProperty $inputObject "tool_name")
$toolInput = Get-HxInputProperty $inputObject "tool_input"
$command = [string](Get-HxInputProperty $toolInput "command")

if ($tool -ne "Bash" -and $tool -ne "PowerShell") {
    $denyReason = "This guard is registered only for Bash and PowerShell, and the payload did not identify either. An unclassifiable shell call is denied rather than allowed."
}
elseif ([string]::IsNullOrWhiteSpace($command)) {
    $denyReason = "The $tool payload carries no readable command, so the permanent-policy guard could not screen it. An uninspectable shell call is denied rather than allowed."
}

# Ansible is permanently outside the HX execution model. The validated native
# Bash/SSH fan-out pattern remains the authoritative fleet-control baseline.
# Ruled out by the owner 2026-08-13; see governance/logs/actions-and-issues.md.
# Match only in COMMAND position - start of line, or after a shell separator -
# with an optional sudo/env prefix. Matching the bare word anywhere would deny
# 'grep -r ansible .', which is exactly the work of removing Ansible references.
$ansiblePattern = '(?im)(?:^|[;&|]|&&|\|\|)\s*(?:sudo\s+)?(?:env\s+\S+=\S+\s+)*(?:ansible|ansible-playbook|ansible-galaxy|ansible-vault|ansible-config|ansible-inventory|ansible-doc)\b'

if ($null -eq $denyReason -and $command -match $ansiblePattern) {
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
