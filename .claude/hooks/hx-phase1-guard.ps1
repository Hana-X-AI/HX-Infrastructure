. "$PSScriptRoot\hx-common.ps1"

$inputObject = Read-HxHookInput
$root = Get-HxProjectRoot $inputObject

# Phase 3 (Regroup) hard-lock. Server mutation is denied regardless of the
# registry Phase 2 status; no lifecycle value releases this guard. The
# authorization record that replaces the hard lock is designed in the
# Transition Stage (P-F1), not here. (Previously released on Phase 2 = READY.)

# Malformed input fails closed. Two separate defects were confirmed here:
#
# 1. Every payload field is read through Get-HxInputProperty. Under
#    Set-StrictMode -Version Latest a direct property read on an absent field
#    throws, the hook dies before it can emit a deny decision, and the protected
#    tool call proceeds.
# 2. A guarded read alone is not enough. Reading an absent field as "" and then
#    finding no pattern match still allows the call, which is the same fail-open
#    outcome by a quieter route.
#
# .claude/AGENTS.md forbids both: "missing or malformed hook input must not
# silently create a fail-open path for a protected operation". This hook is
# registered only on the matcher Bash|PowerShell|Write|Edit, so every payload
# reaching it is a protected call by construction; one it cannot classify or
# inspect is denied, not allowed. The tool name is re-checked here rather than
# trusted from the matcher, the same posture hx-validate-subagent.ps1 adopted.

$tool = [string](Get-HxInputProperty $inputObject "tool_name")
$toolInput = Get-HxInputProperty $inputObject "tool_input"
$denyReason = $null

if ($tool -eq "Write" -or $tool -eq "Edit") {
    $rawPath = [string](Get-HxInputProperty $toolInput "file_path")

    if ([string]::IsNullOrWhiteSpace($rawPath)) {
        $denyReason = "Phase 3 (Regroup) hard-lock: the $tool payload carries no readable file_path, so the guard cannot establish that the target is not servers/<host>/configuration.md. An uninspectable protected call is denied."
    }
    elseif ((Normalize-HxPath $rawPath) -match '(?:^|/)servers/[^/]+/configuration\.md$') {
        $denyReason = "Phase 3 (Regroup) hard-lock: configuration.md is created only in the later owner-authorized implementation phase, not now."
    }
}
elseif ($tool -eq "Bash" -or $tool -eq "PowerShell") {
    $command = [string](Get-HxInputProperty $toolInput "command")

    $blockedPatterns = @(
        '(?i)\bapt(-get)?\s+(-\S+\s+)*(install|upgrade|full-upgrade|dist-upgrade|remove|purge|autoremove)\b',
        '(?i)\bsystemctl\s+(enable|disable|mask|unmask|start|stop|restart|reload)\b',
        '(?i)\bnetplan\s+(apply|try|set)\b',
        '(?i)\b(ufw)\s+(enable|disable|reset|allow|deny|delete)\b',
        '(?i)\b(ubuntu-drivers)\s+install\b',
        '(?i)\b(mkfs(\.\w+)?|wipefs|cfdisk|sgdisk|pvcreate|vgcreate|lvcreate)\b',
        # fdisk, sfdisk and parted are blocked except for their read-only listing form,
        # which is legitimate Phase 1 discovery. sgdisk is excluded above because its
        # -l switch is --load-backup, not a listing operation.
        '(?i)\b(fdisk|sfdisk|parted)\b(?!\s+(-l|--list)\b)',
        # The flag alternation is anchored on whitespace, not \b: there is no word
        # boundary between a space and a leading '-', so \b(--create) never matched.
        '(?i)\bmdadm\b.*(?:^|\s)(--create|--assemble|--add|--remove|--fail)\b',
        '(?i)\bhostnamectl\s+set-hostname\b',
        '(?i)\b(hf|huggingface-cli)\s+download\b',
        '(?i)\b(ollama)\s+(pull|run|serve|create|rm|cp)\b',
        '(?i)\b(vllm)\s+serve\b',
        '(?i)\b(pip|pip3|uv\s+pip)\s+install\b.*\bvllm\b',
        '(?i)(?:^|[^a-z0-9_])servers[/\\][^/\\\s"'']+[/\\]configuration\.md'
    )

    if ([string]::IsNullOrWhiteSpace($command)) {
        $denyReason = "Phase 3 (Regroup) hard-lock: the $tool payload carries no readable command, so the guard cannot screen it against the blocked mutation patterns. An uninspectable protected call is denied."
    }
    else {
        foreach ($pattern in $blockedPatterns) {
            if ($command -match $pattern) {
                $denyReason = "Phase 3 (Regroup) hard-lock: this command performs role-specific or persistent server configuration, which is denied until the owner authorizes the implementation phase."
                break
            }
        }
    }
}
else {
    $denyReason = "Phase 3 (Regroup) hard-lock: this guard is registered only for Bash, PowerShell, Write and Edit, and the payload did not identify one of them. An unclassifiable protected call is denied."
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
