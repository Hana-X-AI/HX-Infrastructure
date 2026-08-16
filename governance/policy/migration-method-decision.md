# Migration method — accepted as standard

**Status:** ACCEPTED
**Decided:** 2026-08-14
**Governs:** `governance/policy/repository-migration-pattern.md`
**Human-facing companion:** `governance/operations/migrations/claude_20260814_0848_migrationmethodaccepted.html`

## Decision

The repository migration / legacy-distillation method — the frozen pattern in
`governance/policy/repository-migration-pattern.md`, comprising the ledger schema and invariants,
the single-source-of-record archive, capability contracts with separate-context review, provenance,
and the acceptance gates — is **accepted as proven** and becomes the repository's **standard
legacy-mining workflow**.

It is no longer a pilot. Future services run the workflow directly: no pilot framing, the same
gates.

## Evidence — validated twice, on rising difficulty

| Application | Difficulty | Outcome |
| --- | --- | --- |
| Docling (1st) | One live integration boundary; the risk was package mechanics | Accepted after a corrective pass. Method mechanics validated. |
| LangGraph (2nd) | Stateful orchestrator, six live integration boundaries; the risk was authority and state drift | Method held. The deliverable correctly **failed** — three capability reviews FAIL, one CONDITIONAL — and caught a same-day cross-workstream architectural contradiction before any infrastructure was touched. |

The contradiction is worth naming, because it is what the method exists to catch: an endpoint was
accepted loopback-only on one host, then treated as remotely consumable by a design on another
host, in the same repository on the same day. Neither workstream could see it from the inside.

The controls that caught real errors were the ones the pattern predicted — separate-context
capability review, per-row provenance counting, source-hash verification, and the refusal to
inherit a value without resolving it. The pattern needs no structural change, only the two
principles below.

## Two permanent principles

Both are folded into `repository-migration-pattern.md` and enforced as part of the pattern.

**P-A — Gate construction.** A validation gate must specify **how** it verifies, not only the
property it claims to verify. A gate that names the right property but is constructed so it cannot
fail is worse than no gate: it ships confidence.

**P-B — Acceptance scope.** An acceptance must state exactly what it authorizes and how that was
verified — never more. Where an authorization has materially different scopes, make them
**distinct acceptance states** rather than one verdict read broadly.

## What "standard workflow" means

- Future services are distilled with the frozen pattern, the resolved ledger, and the
  `legacy/2025` archive as source of record. No new pilot ceremony.
- Every run still carries the full gates: separate-context SME reviews with no author
  self-certification, per-row provenance bound to the ledger hash, no shadow tree, target-state
  rather than as-built authority, source-hash verification, and honest coverage counting.
- Gates specify construction (P-A); acceptances state scope (P-B).
- **A service's method pass is independent of its design acceptance.** The method succeeding by
  producing a failing, corrected design is a success, not a regression.

## Scope boundary — this accepts no service design

This ratifies the **method**. It does not accept `services/langgraph/service.md`, which remains
**REVISED / NOT ACCEPTED** pending four owner decisions and a re-review. It authorizes no
implementation and no deployment. Method accepted; designs and deployments are gated separately.

## Related

- `governance/policy/repository-migration-pattern.md` — the pattern this ratifies
- `governance/operations/langgraph/phase-2/claude_20260814_0848_langgraphfourdecisions.html` — the four
  owner decisions gating the LangGraph re-review
- `governance/policy/runtime-acceptance-decisions.md` — where P-B is applied to runtime acceptance
- `act-015` in `governance/logs/actions-and-issues.md`
