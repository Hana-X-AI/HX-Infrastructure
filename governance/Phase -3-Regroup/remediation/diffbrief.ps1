<#
=====================================================================
 DIFF JOINT BRIEF (PowerShell) - line-by-line
 Compare the EXTERNAL corrected-final copy against the ON-DISK file.
 Read-only. No server contacted.

 Usage (adjust paths to where the two files sit):
   powershell -ExecutionPolicy Bypass -File .\diff-brief.ps1 `
     -External ".\joint-brief-external-a788e800.html" `
     -OnDisk   "C:\Users\JarvisRichardson\Desktop\HX-Infrastructure\governance\Phase -3-Regroup\repo review\claudecodex_20260815_0051_jointreconciliationbrief.html"
=====================================================================
#>
param(
  [Parameter(Mandatory=$true)][string]$External,
  [Parameter(Mandatory=$true)][string]$OnDisk
)

foreach ($p in @($External,$OnDisk)) {
  if (-not (Test-Path -LiteralPath $p)) { Write-Host "FAIL: not found: $p"; exit 1 }
}

function Info($label,$path){
  $b = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $path).Path)
  $sha = ([System.Security.Cryptography.SHA256]::Create().ComputeHash($b) | % { $_.ToString('x2') }) -join ''
  Write-Host ("{0}: {1} bytes  sha256 {2}" -f $label, $b.Length, $sha)
}

"-" * 72
Info "EXTERNAL" $External
Info "ON-DISK " $OnDisk
"-" * 72

$a = Get-Content -LiteralPath $External
$b = Get-Content -LiteralPath $OnDisk
Write-Host ("EXTERNAL lines: {0}   ON-DISK lines: {1}" -f $a.Count, $b.Count)
"-" * 72
Write-Host "LINE DIFF   ( => only on-disk / added,   <= only external / removed )"
$diff = Compare-Object -ReferenceObject $a -DifferenceObject $b -SyncWindow 200
if (-not $diff) {
  Write-Host "  (no line differences - content is line-identical)"
} else {
  $diff | ForEach-Object {
    $mark = if ($_.SideIndicator -eq '=>') { 'ADD' } else { 'DEL' }
    Write-Host ("  [{0}] {1}" -f $mark, $_.InputObject)
  }
  $add = ($diff | ? { $_.SideIndicator -eq '=>' }).Count
  $del = ($diff | ? { $_.SideIndicator -eq '<=' }).Count
  "-" * 72
  Write-Host ("Summary: {0} line(s) added on-disk, {1} line(s) removed vs external." -f $add, $del)
}
"-" * 72
