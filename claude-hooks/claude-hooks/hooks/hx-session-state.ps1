. "$PSScriptRoot\hx-common.ps1"

$inputObject = Read-HxHookInput
$root = Get-HxProjectRoot $inputObject
$registry = Join-Path $root "SERVER-REGISTRY.md"

$phase1 = "UNKNOWN"
$phase2 = "UNKNOWN"
$serverCount = 0
$discoveryComplete = 0
$rolesAssigned = 0

if (Test-Path -LiteralPath $registry) {
    $text = Get-Content -LiteralPath $registry -Raw

    if ($text -match '(?im)^\s*\*\*Phase 1 Status:\*\*\s*(.+?)\s*$') {
        $phase1 = $matches[1].Trim()
    }
    if ($text -match '(?im)^\s*\*\*Phase 2 Status:\*\*\s*(.+?)\s*$') {
        $phase2 = $matches[1].Trim()
    }

    $lines = Get-Content -LiteralPath $registry
    $headerIndex = -1
    $headers = @()

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\|\s*Server\s*\|') {
            $headerIndex = $i
            $headers = @($lines[$i].Trim('|').Split('|') | ForEach-Object { $_.Trim() })
            break
        }
    }

    if ($headerIndex -ge 0) {
        $serverCol = [array]::IndexOf($headers, "Server")
        $discoveryCol = [array]::IndexOf($headers, "Discovery")
        $roleCol = [array]::IndexOf($headers, "Assigned Role")

        for ($i = $headerIndex + 2; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            if ($line -notmatch '^\|') { break }

            $cells = @($line.Trim('|').Split('|') | ForEach-Object { $_.Trim() })
            if ($serverCol -lt 0 -or $serverCol -ge $cells.Count) { continue }

            $server = $cells[$serverCol]
            if ([string]::IsNullOrWhiteSpace($server) -or $server -eq "Server") { continue }

            $serverCount++

            if ($discoveryCol -ge 0 -and $discoveryCol -lt $cells.Count) {
                if ($cells[$discoveryCol] -match '(?i)\bcomplete\b') {
                    $discoveryComplete++
                }
            }

            if ($roleCol -ge 0 -and $roleCol -lt $cells.Count) {
                $role = $cells[$roleCol]
                if (-not [string]::IsNullOrWhiteSpace($role) -and
                    $role -notmatch '(?i)^(unassigned|tbd|none|-)$') {
                    $rolesAssigned++
                }
            }
        }
    }
}

$context = @"
HX-Infrastructure dynamic state:
- phase 1: $phase1
- phase 2: $phase2
- servers in registry: $serverCount
- discovery complete: $discoveryComplete
- roles assigned: $rolesAssigned
Phase 1 is discovery/documentation only. Role assignment is manual. Do not begin role-specific configuration while phase 2 is blocked.
"@.Trim()

Write-HxJson @{
    hookSpecificOutput = @{
        hookEventName = "SessionStart"
        additionalContext = $context
    }
}
