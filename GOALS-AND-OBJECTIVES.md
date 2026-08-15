# HX-Infrastructure Goals & Objectives

## Purpose

HX-Infrastructure exists to establish an authoritative understanding of the HX local server fleet and then configure each server deliberately for an assigned role.

This is an infrastructure project, not a product-development effort.

## Core Principles

These govern every phase. Merged from the 2025 project constitution on 2026-08-13 (`lgc-046`),
carrying forward only what current documents do not already cover.

### 1. Document before you change

Every change starts with documentation. Record what a thing is before altering it, and record
what it became afterwards.

This is why `discovery.md` is written before configuration and never rewritten to reflect it,
and why `configuration.md` is a separate record rather than an edit to the first.

### 2. Validation gates completion

A server is not finished when it is configured. It is finished when its assigned role is
demonstrated to work.

Configuration without a passing check is an assertion, not a result. A check that cannot fail
is not a check.

### 3. Spec before build

Work follows a stated order: what and why, then how, then the steps, then the proof.

Skipping straight to steps produces undocumented outcomes that nobody can audit later. This
applies to design documents as much as to servers — a target-state design is the "what and
why" for work that has not started.

### 4. Quality over speed

Accuracy and completeness outrank velocity. There is no deadline that justifies an
undocumented change or an unverified claim.

Infrastructure mistakes compound. A wrong fact recorded once is repeated by everything that
reads it afterwards.

### Already covered elsewhere

These principles are in force but live in their proper documents, not here:

| Principle | Where it lives |
| --- | --- |
| One server, one assigned role | `SERVER-REGISTRY.md` and the Phase 1 objectives below |
| Operational status is unambiguous | The phase model below, and the registry's phase column |
| Defects are tracked transparently in one place | `CLAUDE.md`, which routes all routine tracking to `governance/logs/actions-and-issues.md` |
| Documentation must be usable by agents | `governance/policy/documentation-standards.md` and the `AGENTS.md` files |

## Expected Fleet

Expected servers: 15

## Phase 1 — Discovery & Documentation

### Phase 1 Goal

Discover and document the actual state and capabilities of every server before role-specific configuration begins.

### Objectives

- Discover every server.
- Create one authoritative `discovery.md` per server.
- Maintain `SERVER-REGISTRY.md`.
- Make fleet hardware capabilities easy to compare.
- Review server capabilities manually.
- Assign every server role manually.
- Record each approved role in the registry.
- Perform no role-specific configuration during Phase 1.

### Role Assignment

Role assignment is a manual project decision.

Agents may report and compare factual capabilities, but may not:

- assign roles;
- select workloads;
- select models;
- start role-specific configuration without approval.

Examples include manually deciding which server will run a Hugging Face/vLLM workload such as an Alibaba Qwen model.

## Phase 1 Gate — historical

Retired as a control on 2026-08-13, kept as a record. All seven conditions were met:
fifteen servers discovered, documented, reviewed, and each assigned a role recorded in
`SERVER-REGISTRY.md`. Phase 1 closed COMPLETE. The gate is no longer evaluated; it stands as
evidence that discovery finished properly before any configuration began.

### Conditions as met

```text
[ ] Every expected server is present in the registry
[ ] Every server has a complete discovery.md
[ ] Fleet hardware capabilities are documented and comparable
[ ] Fleet capabilities have been manually reviewed
[ ] Every server has a manually assigned role
[ ] Every assigned role is recorded in SERVER-REGISTRY.md
[ ] No role-specific configuration has begun
```

Phase 2 is blocked until every item is complete.

## Phase 2 — Repository Consolidation & Alignment

**Status:** COMPLETE — closed by owner ruling on 2026-08-15.

### Phase 2 Goal

Consolidate the 2025 pre-relocation project and the current repository into one repository,
one authority and one operating model. Redefined 2026-08-13; Phase 2 previously meant role
configuration, which is now deferred to a later owner-authorized phase.

### Phase 2 Rules

- `SERVER-REGISTRY.md` stays authoritative; `discovery.md` records stay immutable.
- Legacy material is migrated selectively, fact-transformed, and secret-scanned.
- No credential value enters the repository.
- Ansible is excluded.

## Phase 3 — Regroup & Reconciliation

**Status:** CURRENT — opened by owner ruling on 2026-08-15.

### Authority and Scope

The project owner defines Phase 3 as the regroup: reconciliation, lessons learned,
foundational architecture decisions, and true-north planning. This is the canonical lifecycle
decision. It governs project intent but does not assert that any server is installed,
configured, reachable, or validated.

### Phase 3 Goal

Reconcile project truth and controls, review the completed work, make the foundational
decisions required for the next phase, and define the gate for later server implementation.

### Entry Conditions

- Phase 1 discovery and documentation is complete.
- Phase 2 repository consolidation and alignment is closed by owner ruling.
- The owner has opened the regroup and recorded its scope in this canonical document.

### Phase 3 Rules

- Planning, review, documentation, decisions, and control correction are authorized.
- Server installation, service startup, and network, storage, or role-specific mutation are
  not authorized by Phase 3.
- Review findings remain claims until verified against current authoritative sources.
- Decisions are recorded in the canonical document that owns the affected subject.

### Exit Gate

- The completed phase has been reviewed candidly.
- Action, issue, risk, and lessons-learned records reflect current evidence and owner rulings.
- Foundational architecture decisions and the project's true north are recorded.
- The scope, sequence, entry criteria, and validation expectations for server implementation
  are approved.
- The owner explicitly authorizes the implementation phase.

## Later Phase — Server Implementation

**Status:** DEFERRED — not authorized by Phase 3.

### Implementation Goal

Configure each server for its approved role.

### Implementation Rules

- Use the Phase 1 discovery record as the starting point.
- Preserve `discovery.md` unchanged.
- Create a separate `configuration.md`.
- Document the resulting role-specific state.
- Validate that the configured server performs its assigned role.

`discovery.md` answers: **What was this server when we found it?**

`configuration.md` answers: **What did HX configure this server to become?**

## Success

The project succeeds when the fleet is fully documented, every role is intentionally assigned from discovered capabilities, and each configured server preserves both its original discovery record and its separate configured-state record.
