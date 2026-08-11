param(
    [string]$ProjectRoot = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
$packageRoot = Join-Path $PSScriptRoot "claude-hooks"
$sourceHooks = Join-Path $packageRoot "hooks"
$fragmentPath = Join-Path $packageRoot "settings.fragment.json"

if (-not (Test-Path -LiteralPath $fragmentPath)) {
    throw "Missing settings fragment: $fragmentPath"
}

$claudeDir = Join-Path $ProjectRoot ".claude"
$targetHooks = Join-Path $claudeDir "hooks"
$settingsPath = Join-Path $claudeDir "settings.json"

New-Item -ItemType Directory -Force -Path $targetHooks | Out-Null

Get-ChildItem -LiteralPath $sourceHooks -Filter "*.ps1" | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $targetHooks $_.Name) -Force
}

if (Test-Path -LiteralPath $settingsPath) {
    Copy-Item -LiteralPath $settingsPath -Destination "$settingsPath.bak" -Force
    $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
} else {
    $settings = [pscustomobject]@{}
}

$fragment = Get-Content -LiteralPath $fragmentPath -Raw | ConvertFrom-Json

if ($null -eq $settings.PSObject.Properties["hooks"]) {
    $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue ([pscustomobject]@{})
}

$ourPattern = 'hx-(session-state|phase1-guard|validate-discovery|validate-subagent|notify)\.ps1'

foreach ($eventProperty in $fragment.hooks.PSObject.Properties) {
    $eventName = $eventProperty.Name
    $newGroups = @($eventProperty.Value)

    $existingProperty = $settings.hooks.PSObject.Properties[$eventName]
    $existingGroups = @()

    if ($null -ne $existingProperty) {
        $existingGroups = @($existingProperty.Value) | Where-Object {
            (($_ | ConvertTo-Json -Depth 20) -notmatch $ourPattern)
        }
        $settings.hooks.PSObject.Properties.Remove($eventName)
    }

    $combined = @($existingGroups) + @($newGroups)
    $settings.hooks | Add-Member -NotePropertyName $eventName -NotePropertyValue $combined
}

$settingsJson = $settings | ConvertTo-Json -Depth 30
Set-Content -LiteralPath $settingsPath -Value $settingsJson -Encoding UTF8

Write-Host ""
Write-Host "HX Claude Code hooks installed." -ForegroundColor Green
Write-Host "Project: $ProjectRoot"
Write-Host "Settings: $settingsPath"
Write-Host "Hooks: $targetHooks"
if (Test-Path -LiteralPath "$settingsPath.bak") {
    Write-Host "Backup: $settingsPath.bak"
}
Write-Host ""
Write-Host "In Claude Code, run /hooks to verify:"
Write-Host "  SessionStart"
Write-Host "  PreToolUse"
Write-Host "  PostToolUse"
Write-Host "  SubagentStop"
Write-Host "  Notification"
