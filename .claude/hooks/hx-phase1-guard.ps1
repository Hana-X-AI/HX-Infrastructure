. "$PSScriptRoot\hx-common.ps1"

$inputObject = Read-HxHookInput
$root = Get-HxProjectRoot $inputObject

if (Test-HxPhase2Open $root) {
    exit 0
}

$tool = [string]$inputObject.tool_name
$denyReason = $null

if ($tool -eq "Write" -or $tool -eq "Edit") {
    $filePath = ""
    if ($null -ne $inputObject.tool_input.PSObject.Properties["file_path"]) {
        $filePath = Normalize-HxPath ([string]$inputObject.tool_input.file_path)
    }

    if ($filePath -match '(?:^|/)servers/[^/]+/configuration\.md$') {
        $denyReason = "Phase 2 is blocked. configuration.md must not be created or edited during Phase 1."
    }
}
elseif ($tool -eq "Bash" -or $tool -eq "PowerShell") {
    $command = [string]$inputObject.tool_input.command

    $blockedPatterns = @(
        '(?i)\bapt(-get)?\s+(-\S+\s+)*(install|upgrade|full-upgrade|dist-upgrade|remove|purge|autoremove)\b',
        '(?i)\bsystemctl\s+(enable|disable|mask|unmask|start|stop|restart|reload)\b',
        '(?i)\bnetplan\s+(apply|try|set)\b',
        '(?i)\b(ufw)\s+(enable|disable|reset|allow|deny|delete)\b',
        '(?i)\b(ubuntu-drivers)\s+install\b',
        '(?i)\b(mkfs(\.\w+)?|wipefs|fdisk|cfdisk|sfdisk|parted|sgdisk|pvcreate|vgcreate|lvcreate)\b',
        '(?i)\bmdadm\b.*\b(--create|--assemble|--add|--remove|--fail)\b',
        '(?i)\bhostnamectl\s+set-hostname\b',
        '(?i)\b(hf|huggingface-cli)\s+download\b',
        '(?i)\b(ollama)\s+(pull|run|serve|create|rm|cp)\b',
        '(?i)\b(vllm)\s+serve\b',
        '(?i)\b(pip|pip3|uv\s+pip)\s+install\b.*\bvllm\b',
        '(?i)(?:^|[^a-z0-9_])servers[/\\][^/\\\s"'']+[/\\]configuration\.md'
    )

    foreach ($pattern in $blockedPatterns) {
        if ($command -match $pattern) {
            $denyReason = "Phase 1 is discovery/documentation only. This command appears to perform role-specific or persistent server configuration. Complete the fleet discovery and manual role-assignment gate before Phase 2."
            break
        }
    }
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
