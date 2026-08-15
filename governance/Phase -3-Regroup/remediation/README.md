# Phase 3 — Regroup · Living Index

**Status:** ACTIVE · Phase 3 (Regroup) is the current phase — planning, decision, and tightening-only control work. No server implementation is authorized.

**Owner:** Jarvis Richardson, Hana-X AI · **Last updated:** 2026-08-15

This index records the reconnaissance-and-remediation artifacts for the Phase 3 regroup and their status. It is the single place to see which plan version is current, which reviews have run, and what each artifact's verified hash is.

---

## Current governing artifacts

| Artifact | Version / status | SHA-256 | Notes |
| --- | --- | --- | --- |
| `claude_20260815_0234_phase3remediationplandeepv3.html` | **v3 — CURRENT** | `6317299dfd591e0eabfd1b9184110a5d8c52ba9578b3492879758f55cd998e45` | Incorporates the GitHub Copilot review. P1-00 is incomplete pending its provenance gate. |
| Joint Reconnaissance & Reconciliation Brief (on disk) | governing brief · CURRENT | `f58b1a4a8852a5593dd39c5ed9420243e391861fa9ffe734b9980b7ac745f307` | Reconciled in P1-00 against the corrected-final comparison copy. The content delta is the canonical phase-model update. |

## Plan version history

| Version | File | SHA-256 | Status |
| --- | --- | --- | --- |
| v1 | `claude_20260815_0130_phase3remediationplandeep.html` | `2bb4ff1b43f38d80c7f4d3c0262562184ed184326d3ef091d1d1d1492ab57a92` | superseded by v2 |
| v2 | `claude_20260815_0150_phase3remediationplandeepv2.html` | `ed860d3fb9b352f52458b0eef7d117cf36d315bfd7981cfa4c0c0aed64e39078` | superseded by v3 (reviewed by Copilot) |
| v2.1 | `claude_20260815_0150_phase3remediationplandeepv2.1.html` | `a5fc390f1aaa73846884f2c34e5b04a0e3ac66e8f0a09a9b67929a925c43ceac` | Markup-only derivative of v2 (P1-06 closing tag); Copilot-review hash `a5fc390f` |
| **v3** | `claude_20260815_0234_phase3remediationplandeepv3.html` | `6317299dfd591e0eabfd1b9184110a5d8c52ba9578b3492879758f55cd998e45` | **current** |

## Review chain

| Review | Reviewer | SHA-256 | Verdict |
| --- | --- | --- | --- |
| Joint brief consolidation | Claude + ChatGPT/Codex | corrected-final `a788e80067553604ad0009bb4979f076b88bcb05cff990839b4db31fe69531a8` (externally held) | accepted with correction |
| v1 → v2 review | ChatGPT / Codex (GPT-5.6) | `2bb4ff1b…a57a92` (plan reviewed) | conditional accept (B+) |
| v2 → v3 review | GitHub Copilot | `11d4b863db4e713d7b211c3fcdc97e587fb79a0a249592f86bc0df611e587d1a` | REVISE BEFORE EXECUTION |

## Provenance — four evidence classes

| Class | Artifact | SHA-256 |
| --- | --- | --- |
| Reproducible (in checkout) | current joint brief | `f58b1a4a…f307` |
| Reproducible (in checkout) | Copilot review | `11d4b863…587d1a` (re-verified: match) |
| Reproducible (in checkout) | remediation plan v2 | `ed860d3f…e39078` |
| Externally held | corrected-final joint brief | `a788e800…31a8` |
| Unavailable | pre-correction joint-brief draft | `38f403e4…f9c9d` |
| Metadata-corroborated | source repository archive | `db09e94f…f7919` |

## Lifecycle model (v3)

1. **Phase 3 — Regroup (current):** planning, decisions, control-correction that only tightens (guard hard-locks). Closes at **C-02** after **Gate A**.
2. **Transition Stage (owner-authorized, after Phase 3):** opened by **Gate B**. Executable authorization parser (P-F1) built and validated; hard lock deliberately replaced; OmniRoute topology selected and measured; implementation planned.
3. **Server Implementation Phase (number TBD):** actual server changes. Requires its own separate, explicit owner authorization.

## Open owner rulings (from v3)

- `P-D0` — name the future implementation phase (roadmap dependency; does not gate P1-01).
- `P1-05` — what owns hxs-4 (approved role vs observed exception).
- `P2-01` — expired-risk disposition (`risk-001`, `risk-002`).
- `P2-02` — `act-015` / `iss-016` status.
- `P2-03` — OmniRoute charter scope (topology deferred).
- `P2-04` — hxs-4 as-built record type (prefer accepted-runtime evidence; a new file requires amending the server-record contract first).
- `P3-03` — repository maturity / licence posture.
- `C-02` — approve reconciled baseline + roadmap (closes Phase 3).

> Placement note: the v3 SHA-256 (`ce206cb2…a6886`) is recorded in the tables above. It includes the verified correction from four reproducible evidence rows to three.

## Reconciliation notes

### Hook registration count

The joint reconciliation brief plan item 4 refers to "all eight hooks."
The actual registered hook-command count is **seven**, as verified from
`.claude/settings.json`. The eighth file, `hx-common.ps1`, is a dot-sourced
shared helper loaded by other hooks — it is not a registered hook command.
Plan item 4's "eight hooks" is superseded by the verified count of seven
registered commands.

### F-07 severity

The joint brief governs F-07 at **MEDIUM**, not HIGH. The affected decisions
cover bootstrap credential strength and local credential-file permissions whose
review triggers expired; there is no evidence in F-07 of a live credential
disclosure or a tracked secret value. The owner disposition remains open under
`P2-01` and still requires an explicit ruling in the risk register.
