. "$PSScriptRoot\hx-common.ps1"

# Authority edit guard.
#
# Makes changes to the files that govern HX behaviour intentional and reviewable.
# The coordinating session is asked to confirm; a specialist subagent is denied,
# because a narrow reviewer has no mandate to rewrite the rules it reviews under.
#
# The protected set below was discovered from this repository, not assumed. Paths
# that do not exist here are deliberately absent - guarding a path that does not
# exist protects nothing and hides the fact that the real authority lives
# elsewhere.

$inputObject = Read-HxHookInput

$tool = [string](Get-HxInputProperty $inputObject "tool_name")
$toolInput = Get-HxInputProperty $inputObject "tool_input"
$rawPath = [string](Get-HxInputProperty $toolInput "file_path")

# Malformed input fails closed. This hook is registered only on the matcher
# Write|Edit, so a payload that does not name one of those tools, or whose
# file_path cannot be read, is a write the guard was unable to classify. It
# cannot be shown to miss the protected set, so it is escalated to the owner
# rather than allowed silently. Escalating is 'ask', not 'deny': the write may
# be entirely ordinary, and only the confirmation step is being preserved.
if (($tool -ne "Write" -and $tool -ne "Edit") -or [string]::IsNullOrWhiteSpace($rawPath)) {
    Write-HxJson @{
        hookSpecificOutput = @{
            hookEventName = "PreToolUse"
            permissionDecision = "ask"
            permissionDecisionReason = "The authority-edit guard could not read a tool name and file path from this payload, so it cannot establish that the target is outside the protected authority set. Confirm the write is intended."
        }
    }
    exit 0
}

$filePath = Normalize-HxPath $rawPath

# Protected classes. Matched against the normalised (forward-slash, lowercase) path.
$protected = @(
    @{ Pattern = '(?:^|/)goals-and-objectives\.md$';        Class = "project constitution" },
    @{ Pattern = '(?:^|/)infrastructure-contract\.md$';     Class = "infrastructure contract" },
    @{ Pattern = '(?:^|/)claude\.md$';                      Class = "agent instruction authority" },
    @{ Pattern = '(?:^|/)agents\.md$';                      Class = "agent instruction authority" },
    @{ Pattern = '(?:^|/)server-registry\.md$';             Class = "fleet registry (host/role authority)" },
    @{ Pattern = '(?:^|/)\.claude/settings\.json$';         Class = "automation control" },
    @{ Pattern = '(?:^|/)\.claude/hooks/.+\.ps1$';          Class = "hook enforcement layer" },
    @{ Pattern = '(?:^|/)claude-hooks/.+\.ps1$';            Class = "packaged hook enforcement layer" },
    @{ Pattern = '(?:^|/)governance/policy/.+\.md$';        Class = "governance policy" }
)

$matchedClass = $null
foreach ($rule in $protected) {
    if ($filePath -match $rule.Pattern) {
        $matchedClass = $rule.Class
        break
    }
}

if ($null -eq $matchedClass) {
    exit 0
}

# A specialist subagent is denied outright. Capability contracts in this repository
# define read-only reviewers; none is chartered to edit authority documents.
$agentType = [string](Get-HxInputProperty $inputObject "agent_type")
$isSubagent = -not [string]::IsNullOrWhiteSpace($agentType)

if ($isSubagent) {
    Write-HxJson @{
        hookSpecificOutput = @{
            hookEventName = "PreToolUse"
            permissionDecision = "deny"
            permissionDecisionReason = "Subagent '$agentType' may not edit $matchedClass files. Return the required change as a finding; the coordinating session applies it."
        }
    }
    exit 0
}

Write-HxJson @{
    hookSpecificOutput = @{
        hookEventName = "PreToolUse"
        permissionDecision = "ask"
        permissionDecisionReason = "This edits a $matchedClass file, which governs how HX and its agents behave. Confirm the change is intended and that it does not contradict a standing decision."
    }
}
exit 0
