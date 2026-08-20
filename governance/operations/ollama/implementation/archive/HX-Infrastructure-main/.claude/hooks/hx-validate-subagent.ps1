. "$PSScriptRoot\hx-common.ps1"

$inputObject = Read-HxHookInput
$root = Get-HxProjectRoot $inputObject

# Defense in depth. The SubagentStop matcher is honored by Claude Code, but this
# validator must not depend on settings.json alone to stay off unrelated subagents.
$agentType = [string](Get-HxInputProperty $inputObject "agent_type")
if (-not [string]::IsNullOrWhiteSpace($agentType) -and $agentType -ne "server-discovery") {
    exit 0
}

# A missing final-message field must not become a silent pass. Without it there is
# nothing to verify, so the discovery subagent is held rather than released.
$messageProperty = Get-HxInputProperty $inputObject "last_assistant_message"
if ($null -eq $messageProperty) {
    Write-HxJson @{
        decision = "block"
        reason = "Discovery cannot finish yet: the final message was not available to the validator, so the discovery record could not be verified. State the discovery record path as servers/<server>/discovery.md in the final response."
    }
    exit 0
}

$message = [string]$messageProperty

$match = [regex]::Match(
    $message,
    'servers[\\/](?<server>[^\\/\s`]+)[\\/]discovery\.md',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
)

if (-not $match.Success) {
    Write-HxJson @{
        decision = "block"
        reason = "Before completing server discovery, create the server discovery record and state its path as servers/<server>/discovery.md in the final response."
    }
    exit 0
}

$server = $match.Groups["server"].Value
$filePath = Join-Path $root ("servers\" + $server + "\discovery.md")

$problems = @(Get-HxDiscoveryProblems $filePath)

if (Test-Path -LiteralPath $filePath) {
    $text = Get-Content -LiteralPath $filePath -Raw
    if ($text -notmatch '(?im)^\s*\*\*Discovery Status:\*\*\s*COMPLETE\s*$') {
        $problems += "Discovery Status is not COMPLETE"
    }
}

if ($problems.Count -gt 0) {
    Write-HxJson @{
        decision = "block"
        reason = ("Discovery cannot finish yet: " + ($problems -join "; ") + ". Complete the factual record, explicitly mark unavailable facts as unavailable, set Discovery Status to COMPLETE, and then return.")
    }
    exit 0
}

exit 0
