# Independent review: Phase 3 remediation plan v2

- **Reviewer:** GitHub Copilot
- **Date:** 2026-08-15
- **Plan reviewed:** `governance/Phase -3-Regroup/remediation/claude_20260815_0150_phase3remediationplandeepv2.html`
- **Plan SHA-256:** `ed860d3fb9b352f52458b0eef7d117cf36d315bfd7981cfa4c0c0aed64e39078`
- **Artifact status:** Immutable reviewed artifact at the recorded hash; not modified by any subsequent correction.
- **Verdict:** **REVISE BEFORE EXECUTION**

## Scope and method

This review checked the plan against the current authoritative checkout and exercised only
local, non-mutating fixtures. It did not contact a server, invoke a remote endpoint, begin
remediation, or change an infrastructure control. Review artifacts were treated as claims
until corroborated by repository evidence.

Evidence baseline:

- branch `main`, commit `efb1a3a26a662c282b3822c0fec5e1e66285467b`;
- dirty worktree with 16 porcelain entries at review time;
- current joint brief SHA-256
  `f58b1a4a8852a5593dd39c5ed9420243e391861fa9ffe734b9980b7ac745f307`;
- superseded v1 plan SHA-256
  `2bb4ff1b43f38d80c7f4d3c0262562184ed184326d3ef091d1d1d1492ab57a92`;
- prior ChatGPT review SHA-256
  `b187036c96069c418481c14622299d60f81b6188da6351d4e98cbf0433b852ed`.

## Findings

### B1 - P1-00 provenance gate cannot pass from this checkout

The plan requires three hashes to be recomputed before Wave 0 passes. The checkout does not
contain the required evidence set:

- the file currently named `claudecodex_20260815_0051_jointreconciliationbrief.html` hashes
  to `f58b1a4a...f307`, not the recorded corrected-final hash `a788e800...31a8`;
- no artifact carrying the recorded corrected-final hash or superseded-draft hash
  `38f403e4...f9c9d` is present;
- the archive hash `db09e94f...f7919` is corroborated as metadata in review artifacts, but
  the source archive whose bytes could be recomputed is not present.

This does not prove the recorded lineage false. It means P1-00 is not reproducible from the
current checkout and therefore cannot satisfy its own gate.

**Required revision:** preserve immutable, uniquely named copies of every artifact whose hash
must be recomputed, or revise the gate to distinguish repository evidence from externally held
evidence. Record the current joint brief as a new version rather than assigning an unavailable
hash to the file now present.

### B2 - P1-00 has no executable clean/protected-branch path

P1-00 says Git cleanliness is observational, but its gate requires a clean remediation branch.
The authoritative checkout is already dirty with owner and regroup work. The plan does not say
how those changes become the baseline without stashing, discarding, or silently excluding them.

The word `protected` is also unresolved. A local Git branch has no native branch-protection
control. Configuring or verifying GitHub branch protection uses a remote endpoint, while the
plan's hard boundary prohibits every task from invoking one.

**Required revision:** define the exact baseline-preservation workflow, such as an owner-approved
baseline commit followed by a dedicated worktree. Define whether `protected` means a local
workflow rule or remote GitHub protection. If remote protection is required, make it an explicit
owner/workstation prerequisite outside the no-remote remediation run.

### H1 - P1-01's authority scan is incomplete

The lifecycle repair is necessary, and `GOALS-AND-OBJECTIVES.md` already carries the final
Phase 3 ruling. The proposed scan does not cover every current authority and control surface.
Verified stale text also exists in:

- root `AGENTS.md`;
- `.claude/AGENTS.md`;
- `servers/README.md`;
- `claude-hooks/README.md`.

These are in addition to the root README, root CLAUDE instructions, server contract, startup
record, template, and registry surfaces named by the plan. In particular, the hook README and
`.claude/AGENTS.md` still describe Phase 2 lifecycle values as releasing the mutation guard.

**Required revision:** make the current-authority allowlist explicit and include the complete
AGENTS chain, active READMEs for governed controls, templates, registry vocabulary, and startup
state. Keep the historical/lessons exclusion, then retain red and green scan outputs.

### H2 - P-F1 is both outside Phase 3 and sequenced inside it

P-F1 is headed "carried out of Phase 3," but Wave 4 places it before C-02 closes Phase 3 and
Gate B requires both P-F1 and C-02. Its gate also tests a real parser, which is more than a design
description. The lifecycle position is therefore contradictory.

**Required revision:** choose one model. Either classify P-F1 as Phase 3 control-design work and
keep it before C-02, or close Phase 3 first and put P-F1 plus its executable parser gate in a
separate, owner-authorized transition stage. Gate B must reflect the selected order.

### M1 - P-D0 does not enable P1-01

P1-01 explicitly works with `Future Server Implementation Phase (number TBD, owner-authorized)`,
and P-D0 permits retaining `number TBD`. P-D0 is also not sequenced before Wave 1. It therefore
does not enable P1-01.

**Required revision:** make P-D0 a roadmap or Gate B dependency only. P1-01 should remain
executable using the already ruled unnumbered label.

### M2 - P2-04 can create an ungoverned server-record type

The recommended `servers/hxs-4/runtime-experiment-record.md` is not in the fixed server record
file set owned by `governance/policy/documentation-standards.md`, `servers/AGENTS.md`, and
`servers/README.md`. Avoiding `configuration.md` preserves one invariant but does not by itself
authorize a new per-server record type.

**Required revision:** if the owner selects the new-file option, require an explicit amendment to
the server record contract, file-set standard, and index before creating it. Otherwise use the
plan's alternative of adding an exception section to the accepted-runtime evidence.

### M3 - The minimum guard gate conflates two lifecycle controls

Minimum gate 3 combines Phase 3 hard-lock inputs with duplicate and unrecognized states that are
also part of P-F1's future authorization parser. This blurs the key invariant: no input may
release protected mutations during Phase 3, while exactly one valid scoped authorization may
release them only in a later owner-authorized stage.

**Required revision:** retain two named matrices. The Phase 3 matrix must deny for every registry
status, including `READY`, `IN PROGRESS`, `COMPLETE`, missing, malformed, duplicate, and unknown.
The future matrix must separately test the authorization record and may have one valid release
case only after the hard lock is deliberately replaced.

## Non-blocking corrections

- P1-06's gate opens a `div` and closes it with `</dd>`; correct the closing tag.
  **Implemented** in the markup-only corrected derivative:
  `governance/Phase -3-Regroup/remediation/claude_20260815_0150_phase3remediationplandeepv2.1.html`
  (SHA-256: `a5fc390f1aaa73846884f2c34e5b04a0e3ac66e8f0a09a9b67929a925c43ceac`).
  The original v2 plan remains unmodified at its recorded hash.
- P1-06 should assert that commission code derives the target dynamically and prove it with at
  least two fixture targets. Checking only that `hxs-3` does not appear in output is weaker than
  proving the source has no hard-coded host.

## Claims that survived verification

- The plan's SHA-256 matches the supplied value exactly.
- The planning-only boundary is explicit and no plan task requires live server commissioning.
- P1-02 correctly replaces Phase 2 status-based release with a Phase 3 hard lock and a
  default-deny fixture matrix.
- P1-04 correctly counts seven registered hook commands. An isolated two-run installer fixture
  changed the settings on the second run and produced nine registrations, confirming the defect.
- P1-03's semantic recovery gate matches visible corruption in the runtime contract.
- P1-06 and P2-03 correctly separate static planning work from operational commission,
  topology selection, and measurement.
- Dynamic tracker-ID parity, baseline-object preservation, atomic fix-forward, and the split
  truth/readiness gates are sound improvements over v1.

## Acceptance condition

Do not begin Wave 0 from this document. A revised plan is execution-ready when B1 and B2 have
failable, reproducible gates; H1 and H2 have unambiguous scope and ordering; and the medium
findings are incorporated without weakening the no-server-mutation boundary.
