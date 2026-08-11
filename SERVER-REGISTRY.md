# HX Server Registry

Fleet-level source of truth for discovery status, manual role assignment, and Phase 2 status.

## Rules

- Add one row per discovered server.
- Hardware fields summarize `servers/<server>/discovery.md`.
- `SERVER-REGISTRY.md` is authoritative for assigned role, approved workload/model, discovery lifecycle status, and Phase 2 lifecycle status.
- Roles and workloads/models are entered only after manual review and approval.
- `configuration.md` copies approved role and workload/model values from this registry; it does not assign them.
- Agents must not assign roles automatically.
- Phase 2 remains blocked until the full fleet passes the Phase 1 gate.

## Discovery Status Values

```text
IN PROGRESS - discovery is underway or not yet accepted
COMPLETE    - discovery is accepted for fleet comparison
BLOCKED     - discovery cannot complete until a recorded blocker is resolved
```

## Phase 2 Status Values

```text
BLOCKED     - the fleet-wide Phase 1 gate is incomplete
READY       - the fleet-wide Phase 1 gate is complete
IN PROGRESS - approved role configuration has started
COMPLETE    - configuration.md is complete and the assigned role is validated
```

Phase 2 transitions from `BLOCKED` to `READY` only after the fleet-wide Phase 1 gate is complete, to `IN PROGRESS` when approved role configuration starts, and to `COMPLETE` after `configuration.md` and role validation are complete.

## Registry

| Server | FQDN | IP | CPU | RAM | GPU / VRAM | Primary Storage | Discovery | Assigned Role | Workload / Model | Phase 2 |
|---|---|---|---|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  |  |  |  | BLOCKED |

## Phase 1 Gate

```text
[ ] Every expected server is present in the registry
[ ] Every server has a complete discovery.md
[ ] Fleet hardware capabilities are documented and comparable
[ ] Fleet capabilities have been manually reviewed
[ ] Every server has a manually assigned role
[ ] Every assigned role is recorded in SERVER-REGISTRY.md
[ ] No role-specific configuration has begun
```

**Phase 1 Status:** IN PROGRESS
**Phase 2 Status:** BLOCKED
