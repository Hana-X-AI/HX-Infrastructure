---
name: sync-registry
description: Synchronize factual server discovery summaries into HX `SERVER-REGISTRY.md`. Use when one or more server discovery records have been created or corrected and the fleet registry needs to reflect current discovery facts without changing manual role or workload assignments.
---

# Sync Registry

## Objective

Keep `SERVER-REGISTRY.md` aligned with accepted discovery records.

## Workflow

1. Read `SERVER-REGISTRY.md` and the relevant server discovery records.
2. Add missing server rows or update factual discovery columns.
3. Normalize concise values for:
   - server;
   - FQDN;
   - IP;
   - CPU;
   - RAM;
   - GPU / VRAM;
   - primary storage;
   - discovery status.
4. Preserve manual decision fields exactly as they are:
   - `Assigned Role`;
   - `Workload / Model`;
   - any Phase 2 approval/configuration status already set manually.
5. Never infer a role from hardware.
6. Never select a model or workload.

If a registry value conflicts with the discovery record, treat the discovery record as the Phase 1 factual source and report the discrepancy while correcting only factual discovery columns.

## Output

Report which rows were added or updated and any unresolved conflict. Keep the report concise.
