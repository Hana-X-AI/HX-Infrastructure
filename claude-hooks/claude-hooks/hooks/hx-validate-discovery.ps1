. "$PSScriptRoot\hx-common.ps1"

$inputObject = Read-HxHookInput
$root = Get-HxProjectRoot $inputObject

$filePath = ""
if ($null -ne $inputObject.tool_input.PSObject.Properties["file_path"]) {
    $filePath = [string]$inputObject.tool_input.file_path
}

if ([string]::IsNullOrWhiteSpace($filePath)) {
    exit 0
}

$normalized = Normalize-HxPath $filePath

if ($normalized -match '/servers/[^/]+/discovery\.md$') {
    $problems = @(Get-HxDiscoveryProblems $filePath)
    if ($problems.Count -gt 0) {
        Write-HxJson @{
            decision = "block"
            reason = ("Discovery record validation found: " + ($problems -join "; ") + ". Correct the document using factual data only; do not invent missing values.")
        }
        exit 0
    }
}

if ($normalized.EndsWith("/server-registry.md")) {
    if (-not (Test-Path -LiteralPath $filePath)) {
        exit 0
    }

    $text = Get-Content -LiteralPath $filePath -Raw
    $requiredColumns = @(
        "Server",
        "FQDN",
        "IP",
        "CPU",
        "RAM",
        "GPU / VRAM",
        "Primary Storage",
        "Discovery",
        "Assigned Role",
        "Workload / Model",
        "Phase 2"
    )

    $missing = @()
    foreach ($column in $requiredColumns) {
        if ($text -notmatch [regex]::Escape($column)) {
            $missing += $column
        }
    }

    if ($missing.Count -gt 0) {
        Write-HxJson @{
            decision = "block"
            reason = ("SERVER-REGISTRY.md is missing required columns: " + ($missing -join ", ") + ". Preserve the fleet registry schema.")
        }
        exit 0
    }
}

exit 0
