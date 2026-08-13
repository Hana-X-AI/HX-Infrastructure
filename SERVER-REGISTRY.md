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

| Server | FQDN | IP  | CPU | RAM | GPU / VRAM | Primary Storage | Discovery | Assigned Role | Workload / Model | Phase 2 |
| ------ | ---- | --- | --- | --- | ---------- | --------------- | --------- | ------------- | ---------------- | ------- |
| hxs-1 | hxs-1.hx.local.arpa | 192.168.50.200 | Intel Core Ultra 9 285K, 24c/24t | 128 GB DDR5 non-ECC | 2x RTX 4070 Ti SUPER, 16376 MiB each, 32752 MiB total | 3.6 TB NVMe root; 3.6 TB NVMe + 7.3 TB SATA unallocated | COMPLETE | Deep reasoning & synthesis | Qwen 3.8 27B — unreleased, slot reserved | READY |
| hxs-2 | hxs-2.hx.local.arpa | 192.168.50.201 | Intel Core i7-5960X, 8c/16t | 66 GB non-ECC | 2x RTX 5060 Ti, 16311 MiB each, 32622 MiB total | 3.6 TB NVMe root; 2x 596.2 GB SATA HDD unallocated | COMPLETE | Coding | Qwen2.5-Coder-32B, AWQ Int4, TP=2, max-model-len 16–24K | READY |
| hxs-3 | hxs-3.hx.local.arpa | 192.168.50.202 | Intel Core i7-5960X, 8c/16t | 66 GB non-ECC | 2x RTX 5060 Ti, 16311 MiB each, 32622 MiB total | 3.6 TB NVMe root; 1.8 TB SATA SSD unallocated | COMPLETE | Agent intelligence | gpt-oss-20b TP=2; LightRAG graph & retrieval | READY |
| hxs-4 | hxs-4.hx.local.arpa | 192.168.50.203 | Intel Core i7-14700F, 20c/28t | 32 GB DDR5 non-ECC | 1x RTX 5060 Ti 16311 MiB + 1x RTX 5060 8151 MiB, 24462 MiB total | 931.5 GB NVMe root; 476.9 GB NVMe unallocated | COMPLETE | Retrieval & AI utility | Qdrant + Web-UI; Qwen2.5-3B; BGE-M3 / Nomic embeddings and BGE-Reranker-v2-m3 via TEI or Infinity | READY |
| hxs-5 | hxs-5.hx.local.arpa | 192.168.50.204 | Intel Core i5-7500, 4c/4t | 32 GB DDR4 non-ECC | none, Intel HD 630 integrated only | 238.5 GB NVMe root, sole device | COMPLETE | Edge / ingress | NGINX | READY |
| hxs-6 | hxs-6.hx.local.arpa | 192.168.50.205 | Intel Core i5-8500T, 6c/6t | 15.9 GB DDR4 non-ECC | none, Intel UHD 630 integrated only | 238.5 GB NVMe root, sole device | COMPLETE | Ingestion — crawling | Crawl4AI (+ MCP) | READY |
| hxs-7 | hxs-7.hx.local.arpa | 192.168.50.206 | Intel Core i5-8500T, 6c/6t | 15.9 GB DDR4 non-ECC, single channel | none, Intel UHD 630 integrated only | 238.5 GB NVMe root, sole device | COMPLETE | MCP services | FastMCP runtime + custom HX MCP servers | READY |
| hxs-8 | hxs-8.hx.local.arpa | 192.168.50.207 | Intel Core i5-9400T, 6c/6t | 16 GB DDR4 non-ECC, single channel | none, Intel UHD 630 integrated only | 476.9 GB NVMe root, sole device | COMPLETE | API gateway & control | LiteLLM gateway, PostgreSQL-backed on hxs-9 | READY |
| hxs-9 | hxs-9.hx.local.arpa | 192.168.50.208 | Intel Core i5-7500, 4c/4t | 32 GB DDR4 non-ECC | none, Intel HD 630 integrated only | 238.5 GB NVMe root, sole device | COMPLETE | State services | PostgreSQL + Redis; LiteLLM database; LangGraph checkpoints | READY |
| hxs-10 | hxs-10.hx.local.arpa | 192.168.50.209 | Intel Core i5-7500, 4c/4t | 32 GB DDR4 non-ECC | none, Intel HD 630 integrated only | 238.5 GB NVMe root, sole device | COMPLETE | Web application | Open WebUI; CopilotKit / AG-UI | READY |
| hxs-11 | hxs-11.hx.local.arpa | 192.168.50.210 | Intel Core i5-7500, 4c/4t | 32 GB DDR4 non-ECC | none, Intel HD 630 integrated only | 238.5 GB NVMe root, sole device, aftermarket | COMPLETE | Agent runtime | LangGraph; Mem0 — separate virtualenvs | READY |
| hxs-12 | hxs-12.hx.local.arpa | 192.168.50.211 | Intel Core i5-7500, 4c/4t | 32 GB DDR4 non-ECC | none, Intel HD 630 integrated only | 238.5 GB NVMe root, sole device | COMPLETE | Ingestion — parsing | Docling (+ MCP) | READY |
| hxs-13 | hxs-13.hx.local.arpa | 192.168.50.212 | Intel Core i5-6500, 4c/4t | 32 GB DDR4 non-ECC, 2133 MT/s | none, Intel HD 530 integrated only | 238.5 GB SATA SSD root, sole device | COMPLETE | Automation | n8n (+ MCP) | READY |
| hxs-14 | hxs-14.hx.local.arpa | 192.168.50.213 | Intel Core i5-7500, 4c/4t | 32 GB DDR4 non-ECC | none, Intel HD 630 integrated only | 238.5 GB NVMe root, sole device, aftermarket | COMPLETE | Development | Prompt engineering; LangGraph and client development | READY |
| hxs-15 | hxs-15.hx.local.arpa | 192.168.50.214 | Intel Core i5-7500, 4c/4t, no VT-x | 32 GB DDR4 non-ECC | none, Intel HD 630 integrated only | 238.5 GB NVMe root, sole device, aftermarket | COMPLETE | Test & integration | QA, regression, integration testing, benchmarks | READY |

## Phase 1 Gate

```text
[x] Every expected server is present in the registry
[x] Every server has a complete discovery.md
[x] Fleet hardware capabilities are documented and comparable
[x] Fleet capabilities have been manually reviewed
[x] Every server has a manually assigned role
[x] Every assigned role is recorded in SERVER-REGISTRY.md
[x] No role-specific configuration has begun
```

Verified 2026-08-13: expected fleet 15, registry rows 15, `discovery.md` records with
`Discovery Status: COMPLETE` 15, assigned roles 15, `configuration.md` files 0.

Comparability was completed on 2026-08-13 and verified as follows: all 15 records carry the
same 10 template sections; no record contains an unresolved template placeholder; every
factual registry column is populated for all 15 rows; and all 15 records pass the
`hx-validate-discovery` hook. Cross-host claims written while the fleet was only partly
discovered were found to be stale or wrong once all 15 records existed; 27 corrections
across 13 records were applied — firmware-recency and smallest-memory superlatives, Secure
Boot and serial-number uniqueness claims, batch-membership counts that predated later
members, and the "no NVIDIA packages installed" statement on the four GPU hosts, which the
approved driver install had since made false. Two records were also missing the root
filesystem usage figure the other nine carried; both were recovered from retained collector
output rather than by re-contacting the hosts.

**Roles were assigned by the project owner on 2026-08-13**, ratifying the mapping in
`governance/fleet-architecture-v0.3.html`. This registry records that decision; it did not
make it. `hxs-cp` is the control plane, deliberately outside the fifteen-server fleet, and
holds no row here.

All seven conditions are complete and `act-012` is closed. **Phase 2 is open.** The Phase 1
command guard is released as a direct consequence: package installation, service management,
network, storage and driver commands are no longer denied fleet-wide. Phase 2 work is bounded
by the approved role for each server rather than by the guard, and `configuration.md` copies
the role and workload values from this table without reinterpreting them.

**Phase 1 Status:** COMPLETE
**Phase 2 Status:** READY
