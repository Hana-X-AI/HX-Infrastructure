# HX-AI-Platform Agent Library Reconnaissance

**Prepared by:** Codex  
**Date:** 2026-08-17 16:41 EDT  
**Disposition:** **ADOPT — NARROW ROLE**  
**Confidence:** High for repository placement and boundaries; medium for the final technology seed list until the proposed stack is ratified.

## Executive verdict

Create a root-level `library/` directory in `HX-AI-Platform`, as a sibling of `.claude/`, `.specify/`, `governance/`, `knowledge/`, `platform/`, and `evidence/`.

The library should mirror the **technology coverage** of the current `governance/operations` area, but it should not copy that directory byte-for-byte. The archive shows that `governance/operations` currently combines five different artifact lifecycles: ignored upstream source drops, tracked reconnaissance and decision reports, implementation prompts, executable agent definitions, and stale work/session material. Reproducing that mixture would create a second governance plane and make agent knowledge difficult to validate.

The correct boundary is:

> **`library/` is local, advisory, source-provenanced knowledge consulted by agents. `governance/` contains HX decisions that govern agents.**

`library/` must never override owner rulings, the constitution, canonical registries/contracts, or current measured host evidence.

## Evidence inspected

- Supplied archive: `HX-Infrastructure-main (4).zip`
- SHA-256: `5dd124e1b5a391fc102ab553fb9bc05eece57e73190283dbfe5e060736d26779`
- Static inventory: 403 archive entries, 316 files, 8,148,119 uncompressed bytes
- Safety result: no absolute paths, parent traversal, or other unsafe ZIP members detected
- Material reviewed: repository authority files, `.gitignore`, `SERVER-REGISTRY.md`, `.claude/agents`, all filenames under `governance/operations`, and the proposed technology-stack report
- Archive identity limitation: the ZIP name says `main`, but the archive contains no immutable Git commit identity. Treat its hash as the supplied-source identity.

## What the archive actually contains

`governance/operations` contains 18 named subdirectories and one root workload-placement file. There are 43 tracked files beneath it. Most are HTML reconnaissance, decisions, prompts, and review outputs—not reusable upstream knowledge.

The repository `.gitignore` explicitly excludes paths such as `governance/operations/*/*-main/`, `*-master/`, and `*-release-*`. This means upstream source trees used by agents are local-only and absent from both a clean clone and this ZIP. The present structure therefore cannot be reproduced from Git alone.

Three agent definitions are also located inside operations content (`Craig`, `Atlas`, and `Ariadne`), while other agents are in `.claude/agents/`. `governance/operations/sessions/session-resume.md` contains historical work state. These are strong signs that the directory has become a catch-all rather than a single-purpose knowledge plane.

The archive also lacks the planned `knowledge/instructions.md`, so there is currently no canonical routing index that tells agents how governance, local source knowledge, and live evidence relate.

## Recommended target structure

```text
HX-AI-Platform/
├── .claude/
│   └── agents/                     # executable agent definitions
├── .specify/
│   └── memory/constitution.md      # highest repository principles
├── governance/                     # decisions, policies, registries, reviews
├── knowledge/
│   └── instructions.md             # agent retrieval and authority router
├── library/                        # local agent knowledge plane
│   ├── README.md                   # purpose, boundary, contribution rules
│   ├── catalog.yaml                # every technology and lifecycle status
│   ├── _schemas/
│   │   └── technology-library.schema.json
│   ├── _shared/                    # cross-technology reference knowledge
│   │   ├── bash-ssh/
│   │   ├── nvidia-cuda/
│   │   ├── systemd/
│   │   └── ubuntu-server/
│   └── technologies/
│       ├── ollama/
│       ├── qwen/
│       ├── vllm/
│       └── ... one stable slug per technology
├── platform/                       # executable scripts/config/runbooks
└── evidence/                       # generated probes, tests, benchmarks
```

Use stable technology paths. Do not encode `core`, `candidate`, or `roadmap` in the directory path: status changes would then require disruptive renames. Put lifecycle status in the catalogue and each technology manifest instead.

### Per-technology contract

```text
library/technologies/<technology>/
├── README.md              # scope, exclusions, agent consumers
├── library.yaml           # lifecycle, owners, authorities, freshness rules
├── source-lock.yaml       # URL, tag/commit, hash, license, acquisition date
├── sources/               # local upstream snapshots; ignored by Git
├── references/            # small, licensed, curated reference material
├── distilled/             # tracked agent-ready knowledge with provenance
└── indexes/               # tracked source/file/symbol maps
```

The directory must not be considered ready merely because it exists. `library.yaml` should declare at least `technology`, `canonical_slug`, `plane`, `lifecycle`, `agent_consumers`, `source_required`, `materialization_state`, `verified_at`, `freshness_window`, `authoritative_links`, and `exclusions`.

## Technology catalogue seed

The proposed stack is broader than the existing operations folders. Seed a manifest-backed directory for every ratified technology, while using lifecycle metadata so presence does not imply adoption.

| Plane | Initial technology slugs |
|---|---|
| Governance/development | `sdd-core`, `claude-code`, `github`, `jcode` |
| Systems | `ubuntu-server`, `systemd`, `python`, `bash-ssh`, `chrony`, `dns`, `nvidia-cuda` |
| Edge/traffic | `nginx`, `omniroute` |
| Inference/models | `ollama`, `vllm`, `hugging-face`, `qwen`, `gpt-oss` |
| Retrieval/knowledge | `qdrant`, `lightrag`, `docling`, `granite-docling`, `crawl4ai`, `tei`, `infinity`, `bge`, `nomic`, `code-graph-rag` |
| Agents/MCP/memory | `langgraph`, `fastmcp`, `mem0` |
| Data/state | `postgresql`, `redis`, `sqlite` |
| Experience/automation | `open-webui`, `copilotkit`, `ag-ui`, `n8n` |
| Observability | `prometheus`, `grafana`, `loki`, `node-exporter`, `dcgm-exporter` |
| Exploratory/reference | `loopx`, `code-review-graph`, `gitdiagram`, `diagram-design`, `skill-expert` |

The exploratory entries should carry `lifecycle: candidate`, `roadmap`, `reference-only`, or `retired`. A local directory is evidence availability, not an architecture decision.

Normalize current inconsistent names through catalogue aliases rather than retaining path drift: `OmniRoute` → `omniroute`, `Qwen` → `qwen`, and `code-rag-graph` → `code-graph-rag` if that is the owner-ratified product name.

## Migration map from `governance/operations`

| Current artifact | New destination | Reason |
|---|---|---|
| Upstream checkouts such as `ollama-main` | `library/technologies/ollama/sources/<version-or-commit>/` | Local source knowledge; reproducible and hash-locked |
| Curated technical notes derived from source | `library/technologies/<tech>/distilled/` | Agent-ready advisory knowledge with provenance |
| Source indexes/maps | `library/technologies/<tech>/indexes/` | Deterministic retrieval without copying governance |
| Architecture decisions and reconnaissance reports | `governance/reports/<technology>/` | Decision evidence and human review history |
| Owner-ratified decisions | canonical governance decision location | Must remain authoritative, not advisory |
| Implementation prompts/handoffs | dedicated work/handoff area | Temporary execution input, not durable technical truth |
| Craig, Atlas, Ariadne agent definitions | `.claude/agents/` | Executable agent catalogue has one home |
| Operational scripts/config/runbooks | `platform/<technology>/` | Executable platform material must be tested and governed |
| Probe, test, benchmark output | `evidence/<technology>/` | Generated evidence has a different retention lifecycle |
| `session-resume.md` | work-state/archive policy, or retire | Session narrative is not reusable technology knowledge |
| Cross-cutting lessons | `governance/logs/` with links from the catalogue | Lessons can change operating rules and need governance review |

## Source storage and synchronization recommendation

Do not commit full upstream repositories into `HX-AI-Platform` by default. The existing `.gitignore` already recognizes the size, line-ending, and licensing problems, but its path convention makes missing source invisible.

Replace that implicit behavior with an explicit materialization contract:

1. Track `source-lock.yaml`, licenses/attributions, indexes, and distilled HX notes.
2. Ignore only `library/technologies/**/sources/**` with a narrowly scoped rule.
3. Provide one idempotent native Bash command to `sync`, `verify`, and `status` every locked source. No Ansible.
4. Fail the Agent Knowledge Base Review when a required source is absent, has the wrong commit/hash, or is stale.
5. Keep the working library on the `hxs-cp` checkout. HXS-1 through HXS-4 should receive only approved scripts/configuration through the existing SSH/SCP control plane, not copies of the whole knowledge base.

Avoid Git submodules in the first implementation. A lock-manifest-driven sync is simpler for heterogeneous upstreams and makes license, archive hash, and acquisition method explicit. Revisit submodules only if a real update/traceability problem appears.

## Proposed authority precedence

This needs owner ratification, but the safe default is:

1. Owner rulings and the project constitution
2. Canonical governance policies, contracts, registries, and accepted specifications
3. Current measured evidence for runtime and host facts
4. `library/` upstream source, indexes, and distilled knowledge
5. Historical reports, handoffs, session notes, and chat transcripts

An agent must surface conflicts instead of silently choosing the library. `knowledge/instructions.md` should encode this routing and require citations to the exact source lock, file, and revision used.

## Critical risks and controls

| Risk | Control |
|---|---|
| Library becomes a shadow governance system | Explicitly mark it advisory; link to authorities rather than copying decisions |
| Empty directories imply unsupported technology is adopted | Mandatory lifecycle status in `catalog.yaml` and `library.yaml` |
| Clean clone silently lacks source | `materialization_state`, `sync`, `verify`, and fail-closed preflight |
| Upstream updates invalidate distilled knowledge | Revision-bound provenance and freshness checks |
| Vendor source bloats or contaminates the repo | Ignore snapshots; track locks, licenses, hashes, and HX-authored derivatives |
| Multiple agents create incompatible layouts | One schema, one catalogue, stable lowercase slugs, one validator |
| Historical prompts become current truth | Keep prompts/session state outside the library and label historical material |
| Knowledge copied to model servers drifts | Centralize on `hxs-cp`; deploy only approved runtime artifacts |

## Implementation sequence after approval

1. Ratify the library/governance boundary and authority precedence.
2. Ratify the initial technology catalogue and canonical slugs.
3. Add the root scaffold, schema, catalogue, ignore rule, and `knowledge/instructions.md` routing contract.
4. Implement native Bash `library sync|verify|status` behavior and tests.
5. Pilot migration with `ubuntu-server`, `nvidia-cuda`, `ollama`, and `qwen` because they directly support the HXS-1 commissioning workflow.
6. Run the Agent Knowledge Base Review and correct the contract before migrating the remaining technologies.
7. Move governance reports and agent definitions to their proper homes; do not bulk-copy historical operations content.

## Owner rulings requested

1. **Authority:** Approve that `library/` is advisory and cannot override governance, canonical registries/contracts, or current measured evidence. **Recommended: approve.**
2. **Source policy:** Keep full upstream source snapshots local and Git-ignored, with tracked lock manifests, hashes, licenses, and a deterministic Bash sync/verify command. **Recommended: approve.**
3. **Distribution:** Keep the complete library in the `hxs-cp` working copy and deploy only approved runtime artifacts to HXS-1 through HXS-4. **Recommended: approve.**

## Final recommendation

Adopt the root-level library now as a first-class design requirement, but treat it as a **knowledge supply chain**, not a document dump. The current operations tree provides valuable technology coverage and migration evidence; it should be decomposed by artifact role. The first implementation should prove the contract on the exact four knowledge domains needed for HXS-1—Ubuntu Server, NVIDIA/CUDA, Ollama, and Qwen—before expanding across the full platform catalogue.
