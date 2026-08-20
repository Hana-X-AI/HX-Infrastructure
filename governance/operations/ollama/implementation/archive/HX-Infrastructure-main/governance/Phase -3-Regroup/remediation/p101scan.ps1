<#
=====================================================================
 P1-01 SCAN (PowerShell) - lifecycle authority worklist (red gate)
 Runs ONLY in the remediation worktree. Read-only. No server contacted.

 Finds stale lifecycle text on the current authority surfaces:
   - Phase 2 described as server configuration
   - Phase 3 described as server implementation
   - Phase-2-status described as releasing the mutation guard
 Historical reports and lessons are intentionally NOT scanned.

 Usage (run from inside the worktree, or pass its path):
   powershell -ExecutionPolicy Bypass -File .\p1-01-scan.ps1
  powershell -ExecutionPolicy Bypass -File .\p1-01-scan.ps1 -WorktreeRoot "C:\path\to\hx-remediation" -Tag before
=====================================================================
#>
param(
  [string]$WorktreeRoot = ".",
  [ValidateSet('before','after')][string]$Tag = 'before'
)

try {
  Set-Location -LiteralPath $WorktreeRoot -ErrorAction Stop
} catch {
  Write-Host "FAIL: worktree path is not accessible: $WorktreeRoot"
  exit 1
}
git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: not a git repository: $WorktreeRoot"; exit 1 }

$branch = (git rev-parse --abbrev-ref HEAD)
if ($LASTEXITCODE -ne 0 -or $branch -ne 'remediation/phase3') {
  Write-Host ("STOP: P1-01 requires branch 'remediation/phase3'. Current branch = {0}." -f $branch)
  exit 1
}
Write-Host ("Branch: {0}" -f $branch)

# Current-authority allowlist (H1). Historical/lessons excluded by omission.
$allow = @(
  "AGENTS.md",
  "CLAUDE.md",
  "README.md",
  ".claude/AGENTS.md",
  "servers/AGENTS.md",
  "servers/README.md",
  "claude-hooks/README.md",
  "start-up/session-resume.md",
  "SERVER-REGISTRY.md"
)
# active server templates (whatever exists)
$allow += (Get-ChildItem -Recurse -File -LiteralPath "servers/_templates" -ErrorAction SilentlyContinue | ForEach-Object { Resolve-Path -Relative $_.FullName })

# Stale-lifecycle patterns (case-insensitive)
$patterns = @(
  'Phase 2:?\s*Role Configuration',
  'configuration\.md is created only in Phase 2',
  'When Phase 2 begins',
  'Phase 3\b.{0,30}(implement|Server Implementation)',
  'Phase 2 is open',
  'considers Phase 2 open',
  'released when the registry reaches',
  'Phase 2 release state',
  'while Phase 2 is blocked',
  'lifecycle value is\s*`?READY',
  'five approved (project )?hooks'
)
$rx = ($patterns -join '|')
$excludeExact = @('READY       - Phase 2 is open; consolidation may proceed')

$outFile = "p1-01-scan-v1-$Tag.txt"
$hits = New-Object System.Collections.Generic.List[string]
"-" * 72 | Tee-Object -FilePath $outFile
("P1-01 lifecycle scan ({0}) - branch {1}" -f $Tag, $branch) | Tee-Object -FilePath $outFile -Append
"-" * 72 | Tee-Object -FilePath $outFile -Append
foreach ($f in ($allow | Select-Object -Unique)) {
  if (Test-Path -LiteralPath $f) {
    $m = Select-String -LiteralPath $f -Pattern $rx -AllMatches
    foreach ($line in $m) {
      if ($excludeExact -contains $line.Line.Trim()) { continue }
      $rec = ("{0}:{1}: {2}" -f $f, $line.LineNumber, $line.Line.Trim())
      $hits.Add($rec); $rec | Tee-Object -FilePath $outFile -Append
    }
  }
}
"-" * 72 | Tee-Object -FilePath $outFile -Append
("STALE HITS: {0}   (0 = green gate)" -f $hits.Count) | Tee-Object -FilePath $outFile -Append
Write-Host ("Written: {0}" -f (Resolve-Path -LiteralPath $outFile).Path)
if ($hits.Count -gt 0) { exit 1 }
