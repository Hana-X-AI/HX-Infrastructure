<#
=====================================================================
 P1-00 RUNBOOK (PowerShell) - Phase 3 Remediation Plan v3  [rev]
 Establish reproducible evidence, the baseline commit, and the working branch.

 Runs on the AUTHORITATIVE checkout (your machine). PowerShell + git only.
 No server is contacted. No remote endpoint is called.

 CHANGES IN THIS REV:
  - Phase B count is owner-confirmed via -ConfirmDirty <N>, not a hard-coded 16.
    (The tree legitimately grew to 19 as regroup artifacts were added.)
  - The follow-up command prints this script's ACTUAL filename at runtime.

 Usage:
   powershell -ExecutionPolicy Bypass -File .\<thisfile>.ps1 -RepoRoot "C:\Users\JarvisRichardson\Desktop\HX-Infrastructure"
   # after reviewing the entry list, confirm the count you saw:
   powershell -ExecutionPolicy Bypass -File .\<thisfile>.ps1 -RepoRoot "C:\Users\JarvisRichardson\Desktop\HX-Infrastructure" -Commit -ConfirmDirty 19
=====================================================================
#>
param(
  [string]$RepoRoot = ".",
  [switch]$Commit,
  [int]$ConfirmDirty = 0     # Phase B: the entry count YOU reviewed in Phase A
)

$ErrorActionPreference = "Continue"
$SelfName = if ($PSCommandPath) { Split-Path -Leaf $PSCommandPath } else { "this-script.ps1" }

$ExpectHead  = "efb1a3a26a662c282b3822c0fec5e1e66285467b"
$BaselineMsg = "baseline: preserve owner + regroup work (Phase 3 remediation P1-00)"
$Branch      = "remediation/phase3"
$WorktreeDir = "../hx-remediation"

$ExpectHash = @{
  "governance/Phase -3-Regroup/remediation/claude_20260815_0150_phase3remediationplandeepv2.html" = "ed860d3fb9b352f52458b0eef7d117cf36d315bfd7981cfa4c0c0aed64e39078"
  "governance/Phase -3-Regroup/remediation/claude_20260815_0234_phase3remediationplandeepv3.html" = "81d9ac470d67225dcc19492bf975c313a9f82ffb7337832001793e138033d3da"
  "governance/Phase -3-Regroup/repo review/GitHub-Copilot_2026-08-15_phase3-remediation-plan-v2-review.md" = "48c48e5457320eecb6b8ce72ee82fa80f169bcdc360ee03044749d8142d32894"
}
$JointBrief        = "governance/Phase -3-Regroup/repo review/claudecodex_20260815_0051_jointreconciliationbrief.html"
$JointOnDiskExpect = "f58b1a4a8852a5593dd39c5ed9420243e391861fa9ffe734b9980b7ac745f307"
$JointExternal     = "a788e80067553604ad0009bb4979f076b88bcb05cff990839b4db31fe69531a8"

function Line { "-" * 70 }
function Sha256($p) {
  if (Test-Path -LiteralPath $p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLower() } else { $null }
}

if (-not (Test-Path -LiteralPath $RepoRoot)) { Write-Host "FAIL: path not found: $RepoRoot"; exit 1 }
Set-Location -LiteralPath $RepoRoot
git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: not a git repository: $RepoRoot"; exit 1 }

function Phase-A {
  Write-Host "### P1-00 PHASE A - read-only evidence (nothing is changed)"; Line
  Write-Host ("Repo:   {0}" -f (Get-Location).Path)
  $head = (git rev-parse HEAD)
  Write-Host ("Branch: {0}" -f (git rev-parse --abbrev-ref HEAD))
  Write-Host ("HEAD:   {0}" -f $head)
  if ($head -eq $ExpectHead) { Write-Host "  HEAD matches expected efb1a3a2" }
  else { Write-Host "  NOTE: HEAD differs from the reviewed efb1a3a2 - record the new value." }
  Line
  Write-Host "Dirty worktree entries (review EVERY line - these become the baseline commit):"
  $entries = @(git status --porcelain)
  $entries | ForEach-Object { Write-Host "  $_" }
  Write-Host ("  count = {0}" -f $entries.Count)
  Write-Host "  (Copilot reviewed 16; new regroup artifacts - v3 plan, living index, review, runbook - explain a higher count.)"
  Line
  Write-Host "Reproducible-artifact hashes (recompute only what is present):"
  foreach ($f in $ExpectHash.Keys) {
    $h = Sha256 $f
    if ($null -eq $h)               { Write-Host "  ABSENT $f" }
    elseif ($h -eq $ExpectHash[$f]) { Write-Host "  MATCH  $f" }
    else { Write-Host "  DIFF   $f"; Write-Host "         got $h  (record on-disk value)" }
  }
  Line
  Write-Host "Joint brief reconciliation (B1):"
  $h = Sha256 $JointBrief
  if ($null -eq $h) { Write-Host "  ABSENT - locate the current joint brief; record its path + hash." }
  else {
    Write-Host ("  on-disk  = {0}" -f $h)
    $tag = if ($h -eq $JointOnDiskExpect) { "(match - same bytes Copilot measured)" } else { "(DIFF - record new value)" }
    Write-Host ("  expected = {0} {1}" -f $JointOnDiskExpect, $tag)
    Write-Host ("  external = {0} (corrected-final; externally held)" -f $JointExternal)
    Write-Host "  ACTION: owner attests this on-disk file IS the intended governing brief."
  }
  Line
  Write-Host "PHASE A done. Review the entry list above, then run Phase B with the count you saw:"
  Write-Host ("  powershell -ExecutionPolicy Bypass -File .\{0} -RepoRoot `"{1}`" -Commit -ConfirmDirty {2}" -f $SelfName, $RepoRoot, $entries.Count)
}

function Phase-B {
  Write-Host "### P1-00 PHASE B - baseline commit + worktree (mutating, local only)"; Line
  $entries = @(git status --porcelain)
  if ($ConfirmDirty -le 0) {
    Write-Host ("STOP: pass -ConfirmDirty <N> with the entry count you reviewed in Phase A (now {0})." -f $entries.Count); exit 1
  }
  if ($entries.Count -ne $ConfirmDirty) {
    Write-Host ("STOP: tree has {0} entries but you confirmed {1}. State changed since you reviewed - re-run Phase A." -f $entries.Count, $ConfirmDirty); exit 1
  }
  Write-Host ("Committing all {0} owner-confirmed entries as the baseline (nothing discarded)..." -f $entries.Count)
  git add -A
  git commit -m $BaselineMsg
  if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: commit"; exit 1 }
  $base = (git rev-parse HEAD)
  Write-Host ("  baseline commit = {0}" -f $base)
  Line
  Write-Host "Creating the remediation worktree (protected = local rule: work never on main)..."
  git worktree add -b $Branch $WorktreeDir $base
  if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: worktree add"; exit 1 }
  Line
  Write-Host "EXIT-GATE checks:"
  Push-Location -LiteralPath $WorktreeDir
  $wtClean = if (@(git status --porcelain).Count -eq 0) { "yes" } else { "NO" }
  Write-Host ("  worktree branch = {0}  (must NOT be main)" -f (git rev-parse --abbrev-ref HEAD))
  Write-Host ("  worktree clean  = {0}" -f $wtClean)
  Write-Host ("  baseline in log = {0}" -f (git log --oneline -1))
  Pop-Location
  Line
  Write-Host ("PHASE B done. Baseline preserves the {0} entries; worktree clean; branch != main." -f $entries.Count)
  Write-Host ("Do all remediation work inside: {0}" -f $WorktreeDir)
  Write-Host "No remote endpoint was contacted."
}

if ($Commit) { Phase-B } else { Phase-A }
