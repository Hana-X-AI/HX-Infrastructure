# P1-02 execution spec — guard hard-lock (the safety-critical pair)

**From:** Claude · **Date:** 2026-08-15 · **Runs in:** `remediation/phase3` worktree only. No server contacted, no remote endpoint, no commit until owner approves.

## Status of P1-01

**Open.** P1-01 requires both completion of its P1-00 entry gate and resolution of its seven scan findings before it can pass. P1-00 remains pending. The seven findings (six P1-02 guard-release findings and one P1-04 hook-count finding) are now resolved, and the corrected after scan reports zero. The corrected scanner also removes two earlier false positives:

- `README.md:23` — the now-correct future-phase sentence "configure each server for its approved role". Scanner v2 drops that pattern.
- `SERVER-REGISTRY.md:27` — "READY — Phase 2 is open; consolidation may proceed" is the valid Phase-2 *consolidation* lifecycle vocabulary, read by the dashboard and asserted by `rem-008`. It stays. The staleness was the guard *acting* on it — fixed below in code, not by editing this line.

Phase 2 must not begin until every canonical gate condition is complete.

The executed set was **P1-02** (guard-behavior documentation, code, test, and lifecycle stragglers) and **P1-04** (hook count, one line, bundled here).

---

## P1-02 edits — executed in the worktree

### A. Code — `.claude/hooks/hx-phase1-guard.ps1` (the hard-lock)

**A1.** Remove the Phase-2 release. FIND:
```
if (Test-HxPhase2Open $root) {
    exit 0
}
```
REPLACE:
```
# Phase 3 (Regroup) hard-lock. Server mutation is denied regardless of the
# registry Phase 2 status; no lifecycle value releases this guard. The
# authorization record that replaces the hard lock is designed in the
# Transition Stage (P-F1), not here. (Previously released on Phase 2 = READY.)
```

**A2.** Deny reason for configuration.md. FIND:
```
        $denyReason = "Phase 2 is blocked. configuration.md must not be created or edited during Phase 1."
```
REPLACE:
```
        $denyReason = "Phase 3 (Regroup) hard-lock: configuration.md is created only in the later owner-authorized implementation phase, not now."
```

**A3.** Deny reason for commands. FIND:
```
            $denyReason = "Phase 1 is discovery/documentation only. This command appears to perform role-specific or persistent server configuration. Complete the fleet discovery and manual role-assignment gate before Phase 2."
```
REPLACE:
```
            $denyReason = "Phase 3 (Regroup) hard-lock: this command performs role-specific or persistent server configuration, which is denied until the owner authorizes the implementation phase."
```

> `.claude/hooks/hx-common.ps1` — **no change required.** `Test-HxPhase2Open` stays; `hx-session-state.ps1` still reads it for the dashboard. It is simply no longer called by the guard. (Optional: add a one-line comment above it noting it no longer governs the guard.)

### B. Test — `tests/remediation-tests-restored.ps1` (F1 block, ~line 753)

**B1.** Update the comment + state table. FIND:
```
# ---------- F1: Phase 2 unblock vocabulary ----------
# The guard releases only on the canonical SERVER-REGISTRY.md lifecycle values.

$phase2States = @(
    @{ Value = "BLOCKED";     GuardActive = $true  },
    @{ Value = "READY";       GuardActive = $false },
    @{ Value = "IN PROGRESS"; GuardActive = $false },
    @{ Value = "COMPLETE";    GuardActive = $false }
)
```
REPLACE:
```
# ---------- F1: Phase 3 hard-lock matrix ----------
# The guard denies protected mutations for EVERY registry state. No Phase 2
# status value releases it. (READY/IN PROGRESS/COMPLETE flipped from release
# to deny in the same change as the guard code.)

$phase2States = @(
    @{ Value = "BLOCKED";     GuardActive = $true },
    @{ Value = "READY";       GuardActive = $true },
    @{ Value = "IN PROGRESS"; GuardActive = $true },
    @{ Value = "COMPLETE";    GuardActive = $true },
    @{ Value = "BANANA";      GuardActive = $true },   # unknown value
    @{ Value = "";            GuardActive = $true }     # malformed / empty
)
```
(The `missing registry` case is already covered by `$noRegistryRoot` just below. A `duplicate status` case can be added the same way with a second `**Phase 2 Status:**` line — optional; the hard-lock treats it identically.)

**B2.** Replace the OPEN-gate assertion (~line 806). FIND:
```
Assert-True "F1: hook no longer gates on OPEN" (
    (Get-Content "$root\.claude\hooks\hx-common.ps1" -Raw) -match 'READY\|IN PROGRESS\|COMPLETE'
)
```
REPLACE:
```
Assert-True "F1: guard is hard-locked (Phase 2 release removed)" (
    (Get-Content "$root\.claude\hooks\hx-phase1-guard.ps1" -Raw) -notmatch 'if\s*\(\s*Test-HxPhase2Open'
)
```
Keep the "F1: OPEN is not reintroduced" assertion as-is.

> Note: `rem-008` (Phase 2 Status Values assertions) needs **no change** — the registry vocabulary is unchanged.

### C. Docs — guard behavior

**C1.** `.claude/AGENTS.md:35`. FIND:
```
- Phase 2 release state must follow the lifecycle vocabulary defined by `SERVER-REGISTRY.md`.
```
REPLACE:
```
- The mutation guard is hard-locked in Phase 3 (Regroup); no `SERVER-REGISTRY.md` Phase 2 status value releases it. The registry vocabulary is retained for the session dashboard only.
```

**C2.** `claude-hooks/README.md:8`. FIND:
```
2. `PreToolUse` — blocks obvious role-specific or persistent configuration while Phase 2 is blocked.
```
REPLACE:
```
2. `PreToolUse` — hard-locks obvious role-specific or persistent server configuration during Phase 3 (Regroup); no registry status releases it.
```

**C3.** `claude-hooks/README.md` — the whole `## Phase Gate` section (lines ~57–67). FIND:
```
## Phase Gate

`PreToolUse` considers Phase 2 open only when the authoritative `SERVER-REGISTRY.md` lifecycle value is `READY`, `IN PROGRESS`, or `COMPLETE`:

```text
**Phase 2 Status:** READY
```

`BLOCKED` keeps the guard active, as does a missing registry file. `READY` is set only after the fleet-wide Phase 1 gate is complete.

Until then, the guard blocks obvious package installation/upgrades, service mutations, Netplan apply/try, firewall mutation, storage formatting/partitioning, NVIDIA driver installation, model downloads, vLLM serving/install commands, Ollama mutations, and creation/editing of per-server `configuration.md`.
```
REPLACE:
```
## Phase Gate — Phase 3 hard-lock

During Phase 3 (Regroup) the `PreToolUse` guard denies protected mutations matched by its bounded `Write`, `Edit`, `Bash`, and `PowerShell` rules for **every** registry state. No `Phase 2 Status` value — `READY`, `IN PROGRESS`, `COMPLETE`, `BLOCKED`, missing, or unrecognized — releases it. The registry `Phase 2 Status` column is retained for the session dashboard, but it no longer gates the guard.

Those bounded rules cover obvious package installation/upgrades, service mutations, Netplan apply/try, firewall mutation, storage formatting/partitioning, NVIDIA driver installation, model downloads, vLLM serving/install commands, Ollama mutations, and creation/editing of per-server `configuration.md`.

The authorization record that replaces this hard lock — allowing scoped, owner-authorized mutation in the later implementation phase — is designed in the Transition Stage (P-F1), not here.
```

**C4.** `claude-hooks/README.md:75`. FIND:
```
These rules are deliberately phase-independent. Unlike the hook, they are not released when the registry reaches `READY`, because the contract prohibits those operations without approval in Phase 2 as well.
```
REPLACE:
```
These rules are deliberately phase-independent. Like the Phase 3 hard-locked hook, they are never released by a registry status value, because the contract prohibits those operations without explicit approval in any phase.
```

### D. Lifecycle straggler — `SERVER-REGISTRY.md:86`

FIND: `server implementation is Phase 3.`
REPLACE: `server implementation is a later owner-authorized phase (Phase 3 is Regroup & Reconciliation).`
(Surgical clause edit; the historical gate note is otherwise untouched.)

### E. P1-04 (bundled) — hook count

`claude-hooks/README.md:3`. FIND: `installs the five approved project hooks`
REPLACE: `installs the seven approved project hook commands`

Full P1-04 (adding `hx-permanent-policy-guard` and `hx-authority-edit-guard` to the hook list at lines 5–11, and the installer-idempotency fix) remains its own task; this only corrects the count line the scan flags.

---

## Green gate

Executed **`p101scanv2.ps1 -Tag after`** in the worktree. Result: **`TOTAL STALE HITS: 0`** (P1-01, P1-02, and P1-04 subtotals all 0). The regression suite passed 160 checks with 0 failures, including the flipped F1 hard-lock matrix. The green scan is retained in the worktree; `git diff --check` remains part of final validation.

---

## Cold-verifier notes

1. **Current review digest.** The current Copilot review digest is `11d4b863…587d1a`, consistent with the remediation index, P100 helpers, validation record, and package summary. `48c48e54…d32894` is historical external provenance only; there is no current mismatch claim.
2. **Final cold-verifier review** not yet run — an independent pass before any commit. Owner's call to schedule.
