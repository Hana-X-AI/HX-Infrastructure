---
name: phase1-gate
description: Evaluate the HX-Infrastructure Phase 1 completion gate. Use when asked whether discovery is complete, whether Phase 2 can start, or for fleet discovery status. Read the registry and server discovery records, verify all servers are documented and all roles were manually assigned, and report the gate without assigning roles or changing server configuration.
---

# Phase 1 Gate

## Objective

Determine whether Phase 2 is allowed to begin.

Read:

1. `GOALS-AND-OBJECTIVES.md`
2. `SERVER-REGISTRY.md`
3. every `servers/*/discovery.md`

## Gate Conditions

Phase 1 passes only when all are true:

```text
[ ] Every expected server is present in the registry
[ ] Every server has a complete discovery.md
[ ] Fleet hardware capabilities are documented and comparable
[ ] Fleet capabilities have been manually reviewed
[ ] Every server has a manually assigned role
[ ] Every assigned role is recorded in SERVER-REGISTRY.md
[ ] No role-specific configuration has begun
```

Do not satisfy a missing role yourself. A blank role keeps the gate closed.

Do not create `configuration.md` files as part of this check.

## Expected Fleet

The expected fleet baseline is defined in `GOALS-AND-OBJECTIVES.md`. Compare:

```text
expected fleet count
vs
registry count
vs
completed discovery count
```

## Output

Return a compact gate report:

```text
phase 1 gate
servers expected: <n>
servers registered: <n>
discovery complete: <n>
discovery incomplete: <n>
roles assigned: <n>
roles unassigned: <n>

phase 1: complete | not complete
phase 2: ready | blocked
```

Then list only the blockers, if any.
