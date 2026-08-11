. "$PSScriptRoot\hx-common.ps1"

$inputObject = Read-HxHookInput
$root = Get-HxProjectRoot $inputObject
$message = [string]$inputObject.last_assistant_message

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
