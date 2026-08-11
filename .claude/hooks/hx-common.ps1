Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-HxHookInput {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return [pscustomobject]@{}
    }
    return ($raw | ConvertFrom-Json)
}

function Get-HxProjectRoot {
    param($InputObject)

    if (-not [string]::IsNullOrWhiteSpace($env:CLAUDE_PROJECT_DIR)) {
        return [System.IO.Path]::GetFullPath($env:CLAUDE_PROJECT_DIR)
    }

    if ($null -ne $InputObject -and
        $null -ne $InputObject.PSObject.Properties["cwd"] -and
        -not [string]::IsNullOrWhiteSpace([string]$InputObject.cwd)) {
        return [System.IO.Path]::GetFullPath([string]$InputObject.cwd)
    }

    return [System.IO.Path]::GetFullPath((Get-Location).Path)
}

function Normalize-HxPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return ""
    }
    return (($Path -replace "\\", "/").ToLowerInvariant())
}

function Test-HxPhase2Open {
    param([string]$ProjectRoot)

    $registry = Join-Path $ProjectRoot "SERVER-REGISTRY.md"
    if (-not (Test-Path -LiteralPath $registry)) {
        return $false
    }

    $text = Get-Content -LiteralPath $registry -Raw
    return ($text -match '(?im)^\s*\*\*Phase 2 Status:\*\*\s*OPEN\s*$')
}

function Write-HxJson {
    param($Object)
    $Object | ConvertTo-Json -Depth 12 -Compress
}

function Test-HxDiscoverySectionContent {
    param([string]$Body)

    foreach ($rawLine in ($Body -split '\r?\n')) {
        $line = $rawLine.Trim()
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        if ($line.StartsWith("|")) {
            if ($line -match '^\|\s*Device\s*\|' -or
                $line -match '^\|\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|$') {
                continue
            }

            $cells = @($line.Trim([char]'|').Split([char]'|') | ForEach-Object { $_.Trim() })
            $dataCells = @($cells | Where-Object {
                -not [string]::IsNullOrWhiteSpace($_) -and $_ -notmatch '^<[^>]+>$'
            })
            if ($dataCells.Count -gt 0) {
                return $true
            }
            continue
        }

        $value = $line -replace '^[-*]\s*', ''
        if ($value -match '^[^:]+:\s*(?<fieldValue>.*)$') {
            $value = $matches["fieldValue"].Trim()
        }

        if (-not [string]::IsNullOrWhiteSpace($value) -and $value -notmatch '^<[^>]+>$') {
            return $true
        }
    }

    return $false
}

function Get-HxDiscoveryProblems {
    param([string]$FilePath)

    $problems = New-Object System.Collections.Generic.List[string]

    if (-not (Test-Path -LiteralPath $FilePath)) {
        $problems.Add("discovery record does not exist: $FilePath")
        return $problems
    }

    $text = Get-Content -LiteralPath $FilePath -Raw

    $required = @(
        "## Identity",
        "## CPU",
        "## Memory",
        "## GPU / Accelerators",
        "## Storage",
        "## Network",
        "## Operating System",
        "## Relevant Existing Software / Services",
        "## Capability Summary"
    )

    foreach ($heading in $required) {
        $escapedHeading = [regex]::Escape($heading)
        $sectionMatch = [regex]::Match(
            $text,
            "(?ms)^\s*$escapedHeading\s*\r?\n(?<body>.*?)(?=^\s*##\s+|\z)"
        )
        if (-not $sectionMatch.Success) {
            $problems.Add("missing required section: $heading")
            continue
        }

        if (-not (Test-HxDiscoverySectionContent $sectionMatch.Groups["body"].Value)) {
            $problems.Add("section has no substantive content: $heading")
        }
    }

    $placeholders = @([regex]::Matches($text, '<[^<>\r\n]+>') | ForEach-Object { $_.Value } | Select-Object -Unique)
    foreach ($placeholder in $placeholders) {
        $problems.Add("template placeholder is still present: $placeholder")
    }

    $legacyStatusCount = [regex]::Matches($text, '(?im)^\s*\*\*Status:\*\*').Count
    if ($legacyStatusCount -gt 0) {
        $problems.Add("legacy Status field is not allowed; use Discovery Status")
    }

    $statusMatches = [regex]::Matches(
        $text,
        '(?im)^\s*\*\*Discovery Status:\*\*\s*(?<value>[^\r\n]+?)\s*$'
    )
    if ($statusMatches.Count -eq 0) {
        $problems.Add("Discovery Status is missing")
    }
    elseif ($statusMatches.Count -gt 1) {
        $problems.Add("Discovery Status must appear exactly once")
    }
    else {
        $status = $statusMatches[0].Groups["value"].Value.Trim().ToUpperInvariant()
        if (@("IN PROGRESS", "COMPLETE", "BLOCKED") -notcontains $status) {
            $problems.Add("Discovery Status must be IN PROGRESS, COMPLETE, or BLOCKED")
        }
    }

    return $problems
}
