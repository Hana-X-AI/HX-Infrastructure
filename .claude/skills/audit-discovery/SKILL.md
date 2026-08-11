---
name: audit-discovery
description: Audit an HX Phase 1 server discovery record for completeness, consistency, and comparability without changing the server. Use when asked to review, validate, check, or complete a server discovery record before Phase 1 acceptance.
---

# Audit Discovery

## Objective

Determine whether one server discovery record is complete enough for fleet comparison and manual role assignment.

Read:

1. `GOALS-AND-OBJECTIVES.md`
2. `servers/_templates/discovery.md`
3. the target server discovery record
4. the matching row in `SERVER-REGISTRY.md`

## Audit Rules

Check that the record contains factual values or an explicit reason a value could not be obtained for:

- identity, manufacturer/model/serial, BIOS/UEFI;
- CPU model, sockets, cores, threads, architecture, NUMA;
- installed RAM and useful DIMM/type/speed data;
- discrete GPU presence/absence, model, count, VRAM, driver and UUID where available;
- storage device model, serial, type, capacity, filesystem/mount information;
- primary network interface, MAC, IP, gateway, DNS and link speed where available;
- Ubuntu release, kernel, architecture, timezone, update/reboot state;
- relevant existing software/services;
- concise capability summary.

A section with only unchanged template placeholders is not complete.

Acceptable explicit absence examples:

```text
No discrete GPU detected
Not available from firmware
Not reported by current hardware/tooling
```

Cross-check internally for contradictions such as GPU count versus listed GPUs, RAM totals versus DIMMs, IP versus registry, or storage totals that do not match listed devices.

Do not connect to or modify the server unless the user explicitly asks to retrieve missing facts. This skill is primarily a document audit.

## Discovery Status

The record must use one canonical status field:

```text
**Discovery Status:** IN PROGRESS | COMPLETE | BLOCKED
```

Return `discovery complete` only when every required section contains factual data or an explicit unavailable/not-detected statement and `Discovery Status` is `COMPLETE`. `IN PROGRESS` and `BLOCKED` records remain incomplete.

## Result

Return exactly one status:

- `discovery complete`
- `discovery incomplete`

For incomplete records, list only the missing or contradictory facts that block acceptance.

Do not recommend or assign a server role.
