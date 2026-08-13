# HX-Infrastructure Validation Review Report

**Project:** HX-Infrastructure  
**Baseline:** Architecture Candidate v0.1  
**Validation artifact:** `hxvalidationfindings.html`  
**Architecture artifact:** `hxstackalignment (2)(1).html`  
**Review date:** 2026-08-13  
**Status:** Planning / validation only — not implementation

---

## 1. Executive Summary

The validation pass is productive and, at the host-role level, it largely supports the current architecture. The six validation threads checked 31 assumptions and reported 17 validated items, 10 caveats, 4 risks, and 7 changes proposed for Candidate v0.2.

My overall assessment is:

- **The physical server mapping does not need a broad redesign.**
- **The runtime/configuration design does need several corrections before the roadmap is frozen.**
- **One model-topology decision should be reopened:** `gpt-oss-20b` on `hxs-3` does not appear to require both 16 GB GPUs.
- **One gateway/datastore assumption is a genuine blocker:** the validation findings state that LiteLLM's required datastore is PostgreSQL rather than SQLite.
- **One security pattern must become a platform rule:** networked MCP services should not be exposed directly without authentication and origin controls.
- **The hxs-3 / hxs-4 architectural pairing is strongly reinforced:** LightRAG on `hxs-3` and Qdrant + embedding/reranking utilities on `hxs-4` remains a coherent design.
- **The hxs-2 coder placement remains a question, not a conclusion.** The research identifies PCIe 3.0 tensor-parallel overhead as a likely bottleneck, but that should lead to empirical benchmarking before any host swap is made.

A small Candidate v0.2 is justified before the roadmap. v0.2 should update configuration rules and open decisions while preserving the current fleet architecture unless testing shows a reason to move a workload.

---

## 2. Baseline Architecture Reviewed

| Host | Candidate v0.1 role |
|---|---|
| `hxs-1` | Deep reasoning / synthesis model |
| `hxs-2` | Coding model |
| `hxs-3` | Agent intelligence + LightRAG |
| `hxs-4` | Retrieval + AI utility + Qdrant |
| `hxs-5` | NGINX edge / ingress |
| `hxs-6` | Crawl4AI ingestion |
| `hxs-7` | FastMCP / custom MCP services |
| `hxs-8` | LiteLLM API gateway |
| `hxs-9` | PostgreSQL + Redis |
| `hxs-10` | Open WebUI + CopilotKit / AG-UI frontends |
| `hxs-11` | LangGraph + Mem0 |
| `hxs-12` | Docling |
| `hxs-13` | n8n |
| `hxs-14` | Development |
| `hxs-15` | Test / integration |
| `hxs-cp` | Operator/control-plane designation only; no Hana-X services |

---

# 3. Validation Thread 01 — GPU Serving & Model Fit

## Summary

The general four-host GPU strategy holds. The validation reports:

- RTX 50-series / Blackwell requires a modern vLLM/PyTorch/CUDA/driver stack.
- Tensor parallelism without NVLink works, but PCIe can become the bottleneck.
- `gpt-oss-20b` reportedly fits on a single 16 GB GPU in MXFP4 form.
- Qwen2.5-Coder-32B at 4-bit needs both 16 GB GPUs and leaves limited KV-cache headroom.
- A 27B dense 4-bit reasoning model fits within a matched 32 GB dual-GPU host.
- Embeddings and reranking fit on `hxs-4`, but TEI or Infinity are preferred over vLLM.

## Feedback

### Reopen the `hxs-3` GPU topology decision

Candidate v0.1 marks `gpt-oss-20b` at `TP=2` as closed. The validation findings directly weaken that decision: if the model fits one 16 GB GPU, the second RTX 5060 Ti could remain available for experimental inference or alternate agent workloads.

**Recommended v0.2 status:** keep GPT-OSS on `hxs-3`, but change `TP=1 vs TP=2` to a benchmark decision.

### Keep `hxs-2` under review, not remapped

The PCIe 3.0 platform may limit a large TP=2 coder model. That is a legitimate concern, but it should not yet trigger a host swap. Benchmark the intended context and throughput first. Performance matters here, but it is not the top design objective.

### Prefer a specialized embedding/rerank server

TEI or Infinity is a sensible runtime direction for BGE/Nomic/reranker workloads on `hxs-4`.

**Verdict:** Architecture confirmed; configuration needs revision.

---

# 4. Validation Thread 02 — LightRAG + Qdrant

## Summary

The findings support the `hxs-3` / `hxs-4` split:

- Qdrant is reported as a supported LightRAG vector backend.
- LightRAG can use OpenAI-compatible LLM/embedding endpoints.
- Remote Qdrant over the LAN is a normal client/server pattern.
- NetworkX is acceptable for the expected dev/test graph size.
- Embedding/backend choices must be fixed before ingestion.

## Feedback

### The hxs-3 / hxs-4 architecture is reinforced

`hxs-3` becomes the graph/agent-intelligence side; `hxs-4` becomes the vector/retrieval/utility side. This is one of the strongest decisions in the current map.

### Make first ingest a formal gate

Before bulk ingestion, freeze:

- embedding model,
- embedding dimension,
- LightRAG storage backend,
- Qdrant collection design,
- one end-to-end ingest/retrieve/rerank round-trip.

### Standardize the name

Use **LightRAG** consistently in v0.2.

**Verdict:** Strongly confirmed; first-ingest configuration is the main risk.

---

# 5. Validation Thread 03 — LiteLLM Routing & Datastore

## Summary

The routing model is validated, but the datastore assumption is not.

The validation reports:

- Multi-backend routing/load balancing/fallbacks are supported.
- Open WebUI and LangGraph can use one LiteLLM OpenAI-compatible endpoint.
- Embedding and reranking requests can also route through LiteLLM.
- One LiteLLM node is acceptable for this environment.
- SQLite is not viable for the intended LiteLLM database-backed features; PostgreSQL is required.

## Feedback

### This is the clearest blocker

Candidate v0.1 says `LiteLLM (+ SQLite)`. v0.2 should change that to:

- `hxs-8` remains the LiteLLM host.
- `hxs-9` remains PostgreSQL + Redis.
- LiteLLM gets its own dedicated PostgreSQL database on `hxs-9`.

No host-role change is needed.

Separate LiteLLM virtual keys for Open WebUI, LangGraph, and other clients are also useful for attribution.

**Verdict:** Architecture confirmed; datastore configuration must be corrected before build sequencing depends on it.

---

# 6. Validation Thread 04 — Bare-Metal Virtualenv Isolation

## Summary

The no-Docker design is supported:

- virtualenvs isolate Python dependency trees,
- the NVIDIA kernel driver remains host-shared,
- systemd is suitable for service supervision,
- Qdrant and n8n have native installation paths,
- Open WebUI can run natively,
- Playwright/Crawl4AI still needs host-level browser libraries.

## Feedback

### The operating model holds

A platform standard of **bare metal + separate service environment + systemd** is reasonable for this dev/test environment.

### Virtualenvs do not isolate host resources

They do not isolate GPU VRAM, RAM, CPU, disk I/O, ports, or system libraries. This matters on shared hosts such as `hxs-3`, `hxs-4`, and `hxs-11`.

### Resolve one internal inconsistency

The validation report later suggests one pinned venv for Mem0 + LangGraph, while Candidate v0.1 says each Python service gets its own virtualenv.

Keep the cleaner rule: **separate LangGraph and Mem0 virtualenvs even on the same physical host.**

**Verdict:** Confirmed; formalize the service-isolation standard.

---

# 7. Validation Thread 05 — Mem0 + LangGraph Persistence

## Summary

The validation reports:

- Mem0 can use Qdrant but should have its own collection.
- Mem0 OSS history remains SQLite-based in the behavior described by the agent.
- Self-hosted Mem0 graph memory is not available in the current OSS path described.
- LangGraph can use PostgreSQL and Redis for persistence/checkpointing.
- LangGraph and Mem0 can co-locate on `hxs-11`.
- Model/embedding calls can route through LiteLLM.

## Feedback

### `hxs-11` still makes sense

Nothing here requires moving either service.

### Separate memory from enterprise retrieval

Mem0 should use its own Qdrant collection, distinct from LightRAG/RAG collections.

### Do not depend on Mem0 graph memory

That actually simplifies the design: graph intelligence remains with LightRAG on `hxs-3`.

### Preserve separate service environments

LangGraph and Mem0 should remain separate virtualenvs/services on `hxs-11`.

**Verdict:** Confirmed with storage and isolation clarifications.

---

# 8. Validation Thread 06 — MCP Exposure

## Summary

The validation confirms that the MCP integration path is viable:

- Streamable HTTP is the preferred cross-host transport where supported.
- FastMCP supports HTTP deployment.
- LangGraph can consume MCP tools.
- MCP support maturity varies by product.
- Some networked MCP servers may expose themselves without authentication when deployed with defaults.

## Feedback

The concerns raised in this thread are valid, but they are **not a blocker for the current planning goal**.

The immediate priority is to stand up the Hana-X dev/test platform, validate the end-to-end architecture, and prove the core workflows. Detailed MCP exposure controls, authentication patterns, origin validation, mTLS/bearer-token standards, and compatibility hardening can easily become a separate security-design workstream.

For the initial platform build, MCP services should be deployed conservatively on the private environment and only to the extent needed to validate the intended workflows.

The following items are therefore explicitly **deferred until post-platform hardening**:

- standardized MCP authentication,
- reverse-proxy policy for every MCP service,
- Origin allow-listing,
- mTLS/bearer-token standardization,
- full MCP compatibility/version matrix,
- broader exposure and security policy.

These items should remain visible in the architecture backlog so they are not forgotten, but they should **not delay the core platform roadmap**.

**Verdict:** Architecture confirmed; detailed MCP security and exposure hardening deferred to a later post-platform workstream.

---

# 9. Review of the Seven Proposed v0.2 Changes

| # | Proposed change | Review |
|---|---|---|
| 1 | LiteLLM → PostgreSQL, not SQLite | **Accept — blocker/high priority** |
| 2 | Revisit GPT-OSS TP=2 | **Accept — reopen decision** |
| 3 | Reconsider coder on PCIe-3 host | **Keep open — benchmark before remap** |
| 4 | TEI/Infinity for embeddings/reranker | **Accept as preferred runtime direction** |
| 5 | Freeze LightRAG backend + embedding model/dimension before ingest | **Accept — formal roadmap gate** |
| 6 | Mem0 OSS specifics / no graph-memory dependency | **Accept — clarify boundaries** |
| 7 | MCP authentication / exposure hardening | **Accept, but defer — post-platform hardening; not a roadmap blocker** |

---

# 10. Architecture Impact Classification

## Confirmed

- Four-host GPU tier.
- `hxs-3` as Agent Intelligence + LightRAG.
- `hxs-4` as Retrieval + AI Utility + Qdrant.
- Single-node Qdrant.
- LiteLLM as unified API/model gateway.
- `hxs-9` as PostgreSQL + Redis.
- `hxs-11` as LangGraph + Mem0.
- Bare-metal deployment with service isolation.
- Cross-host MCP tool use through LangGraph.
- `hxs-cp` running no Hana-X services.

## Needs adjustment

- LiteLLM SQLite → PostgreSQL.
- GPT-OSS TP=2 should no longer be closed.
- Embedding/reranking serving stack.
- LightRAG naming and first-ingest controls.
- Mem0 collection/history specifics.
- MCP security exposure standard is deferred to post-platform hardening.
- Separate LangGraph/Mem0 virtualenvs.

## Still open

- Whether Qwen2.5-Coder-32B stays on `hxs-2` after benchmarking.
- GPT-OSS `TP=1` vs `TP=2` on `hxs-3`.
- Exact context windows.
- Exact quantization/runtime flags.
- Final embedding model and dimension.
- Exact MCP implementations/versions where maturity varies.

---

# 11. Source-Alignment Issues Before v0.2

### 11.1 `hxs-3` topology is both closed and reopened

Candidate v0.1 says TP=2 is decided. The validation report says single-GPU operation is viable and the decision should be revisited. v0.2 should remove the "closed" wording.

### 11.2 LiteLLM still says "+ SQLite"

Candidate v0.1 must be updated consistently in the server table, crosswalk, and notes.

### 11.3 Observability is not an unresolved 15-server mapping problem

The validation artifact notes no dedicated monitoring node inside the current 15-server mapping. Current planning reserves a separate spare server for observability outside this mapping, so Candidate v0.2 should record observability as external to the 15-server role map rather than missing.

---

# 12. Recommended Candidate v0.2 Changes

Keep v0.2 intentionally small:

1. Replace LiteLLM SQLite with a dedicated LiteLLM PostgreSQL database on `hxs-9`.
2. Reopen GPT-OSS `TP=1` vs `TP=2` on `hxs-3`.
3. Mark `hxs-2` coder placement as benchmark-sensitive.
4. Specify TEI or Infinity as the preferred embedding/reranking serving layer, pending build-time validation.
5. Standardize on `LightRAG`.
6. Add a first-ingest configuration freeze for embedding model/dimension and LightRAG/Qdrant configuration.
7. Define separate Mem0 and RAG Qdrant collections.
8. Preserve separate LangGraph and Mem0 virtualenvs on `hxs-11`.
9. Record MCP network/security hardening as a deferred post-platform workstream rather than a prerequisite for initial platform bring-up.
10. Record observability as external to the current 15-server map.

---

# 13. Roadmap Implications

Once v0.2 is frozen, the findings support this planning sequence:

## Phase 1 — Fleet foundation
OS/service conventions, users, storage mounts, DNS, time, systemd, Python/runtime baseline, NVIDIA runtime baseline.

## Phase 2 — Shared state and edge
PostgreSQL, Redis, NGINX, LiteLLM and service identities.

## Phase 3 — GPU inference foundation
Bring up and benchmark the GPU hosts; resolve `hxs-3` TP and `hxs-2` coder topology questions.

## Phase 4 — Retrieval and ingestion
Qdrant, embedding/reranking service, LightRAG, Docling and Crawl4AI.

A formal **first-ingest gate** belongs here.

## Phase 5 — Agent runtime and MCP
LangGraph, Mem0, FastMCP, n8n MCP, Docling MCP and Crawl4AI MCP, focused on getting the agent/tool workflows operational. Detailed MCP security hardening is intentionally deferred.

## Phase 6 — Application/front-end layer
Open WebUI, CopilotKit and AG-UI clients routed through NGINX/LiteLLM.

## Phase 7 — Dev/test/demo workflow
Development and integration workflows, automated validation, repeatable demo scenarios.

## Phase 8 — Hardening and operational readiness
Observability integration, backup/snapshot procedures, recovery exercises, documentation, performance tuning where it materially improves the environment, and the deferred MCP security/exposure workstream (authentication, proxy policy, origin controls, transport hardening, and compatibility standardization).

---

# 14. Final Assessment

The validation effort did what it was supposed to do: challenge the frozen candidate without needlessly redesigning it.

The important result is not that every assumption was correct. The important result is that the research separated:

- architecture decisions that are holding,
- configuration assumptions that need correction,
- runtime choices that require benchmarking,
- security rules missing from the first candidate.

The `hxs-3` and `hxs-4` role design is stronger after validation.

The next planning artifact should be **Architecture Candidate v0.2** incorporating these corrections. Once that is frozen, the project is ready for the phased roadmap.

---

## Source Notes

This report reviews the two supplied artifacts:

1. `hxvalidationfindings.html` — Research & Validation Findings against Architecture Candidate v0.1.
2. `hxstackalignment (2)(1).html` — Frozen Architecture Candidate v0.1.

Statements about library/runtime behavior are summaries of the validation artifact's findings and were not independently re-researched for this report.
