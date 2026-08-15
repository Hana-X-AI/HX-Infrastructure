# HX-Infrastructure

Local HX infrastructure project.

## Project Flow

```text
Phase 1: Discovery & Documentation
  -> discover every server
  -> create discovery.md
  -> maintain SERVER-REGISTRY.md
  -> manually review hardware
  -> manually assign every server role

PHASE 1 GATE

Phase 2: Repository Consolidation & Alignment  (COMPLETE)

Phase 3: Regroup & Reconciliation  (current)
  -> reconcile authority, controls, lessons, and architecture decisions

Future Server Implementation Phase  (number TBD, owner-authorized)
  -> configure each server for its approved role
  -> create configuration.md
  -> preserve discovery.md unchanged
```

## Source of Truth

- `SERVER-REGISTRY.md` is the fleet registry.
- `servers/<server>/discovery.md` records the server as found.
- Roles are assigned manually after fleet review.
- Agents may summarize capabilities but may not assign roles.
- `servers/<server>/configuration.md` is created only in the future server implementation phase.

## Project Tracking

Use `actions-and-issues.md` as the single project log for both action items and issues. The `Type` column distinguishes `action` from `issue`.
