<#
=====================================================================
 P1-01 / P1-02 SCAN v2 (PowerShell) - lifecycle + guard-release worklist
 Runs ONLY in the remediation worktree. Read-only. No server contacted.

 v2 changes vs v1:
  - Removed the 'configure each server for its approved role' pattern: it now
    matches the CORRECT future-phase sentence (a false positive).
  - Excludes SERVER-REGISTRY.md:27 Phase-2 Status VALUE definitions: that is
    valid consolidation vocabulary (dashboard-read, rem-008-asserted), not stale.
  - Tags each hit by gate: P1-01 (lifecycle) / P1-02 (guard release) / P1-04 (count).

 Usage:
  powershell -ExecutionPolicy Bypass -File .\p101scanv2.ps1 -WorktreeRoot "C:\Users\JarvisRichardson\Desktop\hx-remediation" -Tag after
=====================================================================
#>
param(
  [string]$WorktreeRoot = ".",
  [ValidateSet('before','after')][string]$Tag = 'after'
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
if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: cannot determine the current branch: $WorktreeRoot"; exit 1 }
if ($branch -eq 'HEAD') { Write-Host "STOP: detached HEAD is not allowed; use branch 'remediation/phase3'."; exit 1 }
if ($branch -ne 'remediation/phase3') {
  Write-Host ("STOP: expected branch 'remediation/phase3'; current branch is '{0}'." -f $branch)
  exit 1
}

$allow = @(
  "AGENTS.md","CLAUDE.md","README.md",".claude/AGENTS.md",
  ".claude/hooks/hx-phase1-guard.ps1",
  "claude-hooks/claude-hooks/hooks/hx-phase1-guard.ps1",
  "servers/AGENTS.md","servers/README.md","claude-hooks/README.md",
  "start-up/session-resume.md","SERVER-REGISTRY.md"
)
$allow += (Get-ChildItem -Recurse -File -LiteralPath "servers/_templates" -ErrorAction SilentlyContinue | ForEach-Object { Resolve-Path -Relative $_.FullName })

# Gate-tagged patterns
$gates = [ordered]@{
  'P1-01' = @(
    'Phase 2:?\s*Role Configuration',
    'configuration\.md is created only in Phase 2',
    'When Phase 2 begins',
    'server implementation is Phase 3'
  )
  'P1-02' = @(
    '\bTest-HxPhase2Open\b',
    'considers Phase 2 open',
    'Phase 2 is open',
    'command guard is released',
    'released when the registry reaches',
    'Phase 2 release state',
    'while Phase 2 is blocked'
  )
  'P1-04' = @(
    'five approved (project )?hooks'
  )
}

# Valid vocabulary to NEVER flag (SERVER-REGISTRY.md Phase-2 Status VALUE block)
$excludeExact = @('READY       - Phase 2 is open; consolidation may proceed')

$outFile = "p1-01-scan-$Tag.txt"
$total = 0
"-" * 72 | Tee-Object -FilePath $outFile
("P1-01/02 scan v2 ({0}) - branch {1}" -f $Tag, $branch) | Tee-Object -FilePath $outFile -Append
"-" * 72 | Tee-Object -FilePath $outFile -Append
foreach ($gate in $gates.Keys) {
  $rx = ($gates[$gate] -join '|')
  $gcount = 0
  foreach ($f in ($allow | Select-Object -Unique)) {
    if (Test-Path -LiteralPath $f) {
      foreach ($line in (Select-String -LiteralPath $f -Pattern $rx -AllMatches)) {
        if ($excludeExact -contains $line.Line.Trim()) { continue }
        ("[{0}] {1}:{2}: {3}" -f $gate, $f, $line.LineNumber, $line.Line.Trim()) | Tee-Object -FilePath $outFile -Append
        $gcount++; $total++
      }
    }
  }
  ("  {0} subtotal: {1}" -f $gate, $gcount) | Tee-Object -FilePath $outFile -Append
}
"-" * 72 | Tee-Object -FilePath $outFile -Append
("TOTAL STALE HITS: {0}   (0 = green gate for P1-01+P1-02+P1-04)" -f $total) | Tee-Object -FilePath $outFile -Append
if ($total -gt 0) { exit 1 }
