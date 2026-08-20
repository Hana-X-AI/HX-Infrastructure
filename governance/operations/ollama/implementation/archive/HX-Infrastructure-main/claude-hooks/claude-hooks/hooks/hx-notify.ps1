$ErrorActionPreference = "SilentlyContinue"

$raw = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($raw)) {
    exit 0
}

$inputObject = $raw | ConvertFrom-Json
$title = if ($inputObject.title) { [string]$inputObject.title } else { "Claude Code" }
$message = if ($inputObject.message) { [string]$inputObject.message } else { "Claude Code needs your attention." }
$type = [string]$inputObject.notification_type

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show(
    "$message`n`nType: $type",
    $title,
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
) | Out-Null

exit 0
