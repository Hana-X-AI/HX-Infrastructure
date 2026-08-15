# Phase 3 — Regroup · Living Index

**Status:** ACTIVE · Phase 3 (Regroup) is the current phase — planning, decision, and tightening-only control work. No server implementation is authorized.

**Owner:** Jarvis Richardson, Hana-X AI · **Last updated:** 2026-08-15

This index records the reconnaissance-and-remediation artifacts for the Phase 3 regroup and their status. It is the single place to see which plan version is current, which reviews have run, and what each artifact's verified hash is.

---

## Current governing artifacts

| Artifact | Version / status | SHA-256 | Notes |
| --- | --- | --- | --- |
| `remediation/claude_20260815_0234_phase3remediationplandeepv3.html` | **v3 — CURRENT · awaiting owner accept** | `81d9ac470d67225dcc19492bf975c313a9f82ffb7337832001793e138033d3da` | Incorporates the GitHub Copilot review. Not execution-ready until the owner accepts it on an authoritative checkout. |
| Joint Reconnaissance & Reconciliation Brief (on disk) | governing brief · CURRENT | `f58b1a4a8852a5593dd39c5ed9420243e391861fa9ffe734b9980b7ac745f307` | On-disk copy present in the checkout. Reconcile against the externally-held corrected-final (below) in P1-00. |

## Plan version history

| Version | File | SHA-256 | Status |
| --- | --- | --- | --- |
| v1 | `claude_20260815_0130_phase3remediationplandeep.html` | `2bb4ff1b43f38d80c7f4d3c0262562184ed184326d3ef091d1d1d1492ab57a92` | superseded by v2 |
| v2 | `remediation/claude_20260815_0150_phase3remediationplandeepv2.html` | `ed860d3fb9b352f52458b0eef7d117cf36d315bfd7981cfa4c0c0aed64e39078` | superseded by v3 (reviewed by Copilot) |
| **v3** | `remediation/claude_20260815_0234_phase3remediationplandeepv3.html` | `81d9ac470d67225dcc19492bf975c313a9f82ffb7337832001793e138033d3da` | **current — awaiting owner accept** |

## Review chain

| Review | Reviewer | SHA-256 | Verdict |
| --- | --- | --- | --- |
| Joint brief consolidation | Claude + ChatGPT/Codex | corrected-final `a788e80067553604ad0009bb4979f076b88bcb05cff990839b4db31fe69531a8` (externally held) | accepted with correction |
| v1 → v2 review | ChatGPT / Codex (GPT-5.6) | `2bb4ff1b…a57a92` (plan reviewed) | conditional accept (B+) |
| v2 → v3 review | GitHub Copilot | `48c48e5457320eecb6b8ce72ee82fa80f169bcdc360ee03044749d8142d32894` | REVISE BEFORE EXECUTION |

## Provenance — four evidence classes

| Class | Artifact | SHA-256 |
| --- | --- | --- |
| Reproducible (in checkout) | current joint brief | `f58b1a4a…f307` |
| Reproducible (in checkout) | Copilot review | `48c48e54…d32894` (re-verified: match) |
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

> Placement note: the v3 SHA-256 (`81d9ac47…33d3da`) is recorded in the tables above; re-verify it once v3 is committed to the checkout. v3 was produced with no remediation performed and no canonical project state edited.
