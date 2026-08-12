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

    # Validate the actual fleet-table header row. Searching the whole document would
    # let explanatory prose satisfy the check after the table itself was damaged.
    $table = Get-HxRegistryTable $filePath
    if ($null -eq $table) {
        Write-HxJson @{
            decision = "block"
            reason = "SERVER-REGISTRY.md no longer contains a fleet table header row beginning with '| Server |'. Preserve the fleet registry schema."
        }
        exit 0
    }

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

    $missing = @($requiredColumns | Where-Object { $table.Columns -notcontains $_ })

    if ($missing.Count -gt 0) {
        Write-HxJson @{
            decision = "block"
            reason = ("SERVER-REGISTRY.md fleet table is missing required columns: " + ($missing -join ", ") + ". Preserve the fleet registry schema.")
        }
        exit 0
    }
}

exit 0
