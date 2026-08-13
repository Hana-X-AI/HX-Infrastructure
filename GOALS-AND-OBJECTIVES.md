# HX-Infrastructure Goals & Objectives

## Purpose

HX-Infrastructure exists to establish an authoritative understanding of the HX local server fleet and then configure each server deliberately for an assigned role.

This is an infrastructure project, not a product-development effort.

## Expected Fleet

Expected servers: 15

## Phase 1 — Discovery & Documentation

### Goal

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

### Goal

Consolidate the 2025 pre-relocation project and the current repository into one repository,
one authority and one operating model. Redefined 2026-08-13; Phase 2 previously meant role
configuration, which is now Phase 3.

### Rules

- `SERVER-REGISTRY.md` stays authoritative; `discovery.md` records stay immutable.
- Legacy material is migrated selectively, fact-transformed, and secret-scanned.
- No credential value enters the repository.
- Ansible is excluded.

## Phase 3 — Server Implementation

### Goal

Configure each server for its approved role.

### Rules

- Use the Phase 1 discovery record as the starting point.
- Preserve `discovery.md` unchanged.
- Create a separate `configuration.md`.
- Document the resulting role-specific state.
- Validate that the configured server performs its assigned role.

`discovery.md` answers: **What was this server when we found it?**

`configuration.md` answers: **What did HX configure this server to become?**

## Success

The project succeeds when the fleet is fully documented, every role is intentionally assigned from discovered capabilities, and each configured server preserves both its original discovery record and its separate configured-state record.
