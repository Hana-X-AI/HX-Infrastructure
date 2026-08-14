# Docling MCP

Status: TARGET-STATE DESIGN
Target placement: hxs-12 (hxs-12.hx.local.arpa) — resolved from SERVER-REGISTRY.md
As-built status: NOT ASSERTED BY THIS DOCUMENT

Authority boundary:
- Authoritative for the current *intended* Docling MCP service design.
- Does NOT assert the service is installed, configured, reachable, or validated.
- SERVER-REGISTRY.md is authoritative for host/role placement.
- servers/<host>/configuration.md is the as-built authority AFTER implementation.
- Legacy 2025 sources are non-authoritative evidence and lessons only.

---

## Purpose

Docling MCP is the fleet's document-parsing service. It converts PDFs, office documents,
web pages and images into a single structured representation, and exposes that capability
to AI agents over the Model Context Protocol so that every agent parses documents the same
way instead of each one implementing its own extraction.

It is a parsing service. It is not a retrieval service, not a knowledge-graph service and
not a model-serving service. Those capabilities exist elsewhere in the fleet and Docling
hands off to them.

Provenance: lgc-064, lgc-065, lgc-066.

---

## Current placement

| Fact | Value | Source |
| --- | --- | --- |
| Host | hxs-12 | SERVER-REGISTRY.md |
| FQDN | hxs-12.hx.local.arpa | SERVER-REGISTRY.md |
| Assigned role | Ingestion — parsing | SERVER-REGISTRY.md |
| Workload | Docling (+ MCP) | SERVER-REGISTRY.md |
| Design rationale | PDF/office layout parsing; 32 GB for large-document headroom | fleet-architecture-v0.3 |

Host characteristics that constrain this design, from `servers/hxs-12/discovery.md`:

- **4 physical cores, 4 threads, no SMT** (Intel i5-7500, Kaby Lake).
- **32 GB DDR4 non-ECC**, dual channel, 2400 MT/s.
- **No GPU and no CUDA.** Integrated Intel HD Graphics 630 only, suitable for console output
  rather than compute. No NVIDIA, AMD, NPU or other accelerator present; no CUDA or libcuda
  package installed.
- **One 238.5 GB NVMe device** carrying the operating system, ext4 root, about 4.7 percent
  used. No second device, no unallocated capacity, no RAID, no LVM.
- **One 1 Gb/s network interface**, no link redundancy.
- Ubuntu 24.04.4 LTS (noble), HWE kernel, x86_64. `python3` 3.12.3 present.

The absence of a GPU is the single most shaping fact in this document. Everything below that
touches OCR, vision models or throughput follows from it.

---

## Owning SMEs

Four capability contracts exist at `.claude/agents/`, all `activation_state: active`. Four
reviews ran against this document on 2026-08-13, each in a separate context — the authoring
context did not sign its own work.

| Capability | Contract | Review | Verdict |
| --- | --- | --- | --- |
| `docling-mcp` | exists | ran | **CONDITIONAL PASS** |
| `infrastructure-ops` | exists | ran | **CONDITIONAL PASS** |
| `testing-qa` | exists | ran | **CONDITIONAL PASS** |
| `lightrag` | exists | ran | **CONDITIONAL PASS** |

All four verdicts are conditional. Their required corrections are recorded in the pilot
report; the ones affecting factual accuracy have been applied to this document, and the
remainder are tracked as open. **This document does not claim an unconditional multi-SME
pass.**

The 2025 material carries named reviewers who signed off on the original design. Those are
historical evidence and are not current sign-off.

---

## Architecture

Three layers, all settled. Conversion runs in a co-located Docling Serve instance — see
*Conversion topology* below.

**1. Protocol layer.** The package exposes its tool surface using the **MCP Python SDK v2**
(`mcp.server.mcpserver.MCPServer`), pinned `mcp[cli]>=2.0.0,<3.0.0`. It is **not** a FastMCP
server — that changed at v3.0.0 and the 2025 material predates it. Transports are `stdio`,
`sse` and `streamable-http`, with `streamable-http` the package default. Default bind is
`localhost:8000`.

This bears directly on the hxs-7 question below: hxs-7's registry workload reads "FastMCP
runtime + custom HX MCP servers", and this service is no longer a FastMCP server. Whether an
SDK-v2 server can be composed or proxied by that runtime is a harder question than simple
co-existence, and is **VERIFICATION REQUIRED**.

**2. Processing layer.** A document arrives, its format is detected, a backend is selected,
and a pipeline produces a structured document with headings, tables, lists, code blocks,
images and reading order preserved. **This pipeline runs inside Docling Serve**, a separate
process on the same host, reached over loopback. The 2025 design assumed in-process
conversion; that is not how the current package works and not how this service is built.

**3. Handoff layer.** Parsed output leaves the service. Docling does not store knowledge,
does not build graphs and does not own a vector collection.

A deliberate 2025 decision that still holds: **Docling MCP is a standalone MCP server, not a
backend HTTP API sitting behind a composition server.** Two alternatives were considered and
rejected — a backend HTTP API for a separate FastMCP host to call, and a dual-mode server
speaking both MCP and a private HTTP API. A gateway's role, if one is used, is to compose and
proxy, which is optional and does not change this service's shape.

Provenance: lgc-105 (ADR-001), lgc-107, lgc-067, lgc-068.

---

## Conversion topology

**RESOLVED by owner decision, 2026-08-13: remote mode, with Docling Serve co-located on
hxs-12.** Recorded in
`governance/reports/claude-code/Claude-Opus-5_2026-08-13_docling-topology-decision-packet.html`.

Two services on one host:

```
hxs-12
├─ docling-serve        parses. Owns native libraries, model weights, parser cache.
│                       Listens on loopback.
└─ docling-mcp          MCP surface. conversion_mode=remote, service_url -> loopback.
                        Holds no model weights.
```

Verified against pinned upstream on 2026-08-13:

| Package | Version | Identity |
| --- | --- | --- |
| `docling-mcp` | v3.0.0 | tag commit `7b51926920550c4a2c6e888977b8e38a08bafdbd`, released 2026-07-31 |
| `docling-serve` | v1.30.0 | released 2026-08-07 |

Both declare `requires-python >=3.10`; the host carries 3.12.3.

### What this ruling buys

- **Lifecycle separation on one box.** A parser upgrade restarts Serve, not the MCP surface.
  This is the phase-4 parsing / phase-5 MCP split expressed as two units rather than two hosts.
- **The upstream default path.** `conversion_mode` defaults to `remote`; this is the
  configuration the package is built around, not a variant.
- **A CPU-only dependency path that actually exists.** Serve ships a `cpu` extra
  (`docling-serve[cpu]`) resolved against a CPU-only torch index. `docling-mcp[local]` has no
  equivalent, so the local topology would have pulled the CUDA runtime onto a GPU-less host
  unless torch were pinned by hand. **This ruling removes that hazard rather than managing it.**
- **Relocation stays cheap.** Moving Serve to another host later is a `service_url` change and
  a registry update, not a redesign.
- **The registry stays accurate.** hxs-12 still parses, so its assigned role — "Ingestion —
  parsing" — remains correct. No role change is required or made.

### What it costs

- Two systemd units instead of one, and a loopback HTTP hop per conversion.
- The parsing footprint — native libraries, model weights, parser cache — still lands on
  hxs-12's single 238.5 GB disk. Co-location moves the ownership, not the bytes.
- `service_timeout` (default 300.0) and `service_max_retries` (default 3) are declared in
  `docling-mcp` settings but **not consumed** by its remote client at v3.0.0, so a conversion
  cannot currently be bounded through that configuration. Over loopback to a local process the
  exposure is materially smaller than it would be across the network, but it is not zero and
  it is not configurable.

### Settings this fixes

| Setting | Value |
| --- | --- |
| `DOCLING_MCP_CONVERSION_MODE` | `remote` |
| `DOCLING_MCP_SERVICE_URL` | Serve on loopback — port **VERIFICATION REQUIRED**, Serve's uvicorn default is 5001 |
| `DOCLING_MCP_FALLBACK_TO_LOCAL` | `false` — no local converter is installed, so a fallback would fail rather than degrade |
| Serve bind address | Loopback. Serve's uvicorn default is `0.0.0.0`, which must be overridden: nothing outside the host needs to reach the parser directly |
| Serve install | `docling-serve[cpu]`, resolved against the CPU-only torch index |

## MCP tool surface

**This is the part of the inherited design least safe to copy forward.** The 2025 material
contains three mutually incompatible tool inventories:

| Source | Count | Example names |
| --- | --- | --- |
| Node README (lgc-064) | 21 | `convert_pdf`, `generate_title`, `export_markdown` |
| Upstream `docling-mcp` package (lgc-067) | 19 | `convert_document_into_docling_document`, `add_title_to_docling_document` |
| HX specification (lgc-124) | 19 | `convert_document`, `batch_convert`, `annotate_document` |

The upstream inventory is the only one established by reading the package itself — the
research recorded it as high confidence, counted from the tool decorators in the source. The
other two are aspirational naming that was never reconciled. The 2025 functional test suite
was written against the README naming, so the tests did not test the tools the package
actually ships.

**None of the three is current.** All three predate the package's remote/local split. The
2025 counts are historical evidence and are not carried forward as the current surface.

**Current surface, verified from v3.0.0 source on 2026-08-13.** The package organises tools
into selectable groups rather than a fixed list:

| Group | Loaded by default | HX position |
| --- | --- | --- |
| `conversion` | Yes | Enabled |
| `generation` | Yes | Enabled |
| `manipulation` | Yes | Enabled |
| `llama-index-rag` | No | **Disabled by HX default** |
| `llama-stack-rag` | No | **Disabled by HX default** |
| `llama-stack-ie` | No | **Disabled by HX default** |

**The optional retrieval, RAG and information-extraction groups stay disabled unless the owner
explicitly enables one.** This follows directly from the HX boundary: Docling parses; it does
not own retrieval, graph building, embedding generation or vector collections. **Two of the
three optional groups write to a vector store of their own** — `llama-index-rag` ships
document export and search against a vector database, and `llama-stack-rag` ships insertion
into one. Enabling either puts Docling back in exactly the position the 2025 project had to
correct.

**MCP prompts load unconditionally.** The package registers its prompt modules outside every
toolgroup branch, so disabling a toolgroup does not disable its prompts.

The exact tool names within each group are **VERIFICATION REQUIRED** — they must be read from
the pinned package version at implementation time, not copied from this document or from 2025
material. Whatever is chosen, one name per tool exists in exactly one place, and the tests are
written against that place.

Provenance: lgc-064, lgc-067, lgc-124, lgc-070.

---

## Dependencies

### Runtime

- **Python** — v3.0.0 declares `requires-python = ">=3.10"` and carries classifiers through
  **3.14**. The host carries 3.12.3, comfortably inside that range.
- **Virtual environment — already decided, not open.** The frozen stack alignment names
  Docling explicitly: every Python service runs bare-metal in its own dedicated virtualenv,
  with an absolute venv interpreter in the unit's `ExecStart`. This document does not reopen
  it.
- **Base dependencies at v3.0.0**, verbatim from package metadata:
  `docling-slim[service-client]~=2.92`, `docling-core>=2.51.0`, `mcp[cli]>=2.0.0,<3.0.0`,
  `pydantic~=2.10`, `pydantic-settings~=2.4`. Note `docling-core` is present under **every**
  topology, so document-model types and thumbnail support exist even under B.
- **`docling-mcp[local]` is NOT installed.** The base package is sufficient in remote mode.
  This is what keeps the CUDA wheel chain off the host.
- **Docling Serve is installed separately** as `docling-serve[cpu]`, resolved against the
  CPU-only torch index (`torch>=2.7.1`, `torchvision>=0.22.1`, with a torchvision exclusion
  for linux x86_64). Serve v1.30.0 declares `requires-python >=3.10`.

### Native libraries — Docling Serve owns these

The imaging and OCR stack needs shared libraries present on the host. Under this topology they
are **Docling Serve's** prerequisites, not `docling-mcp`'s — but Serve runs on hxs-12, so they
still land here.

In 2025 a missing OpenGL shared library stopped the service starting at all, and the fix was
complicated by a package rename: **the name used before Ubuntu 24.04 no longer exists on
24.04**, so an installation instruction carried forward verbatim fails. hxs-12 runs 24.04.4, so
this applies directly.

Native prerequisites are declared explicitly against the 24.04 package set and verified on the
host. Exact package names are **VERIFICATION REQUIRED** — confirmed on hxs-12, not inherited
from a 2025 document.

### Model artefacts — Docling Serve owns these

Serve downloads model weights for layout analysis, table structure and OCR on first use. They
land in Serve's cache directory on hxs-12's single disk.

`docling-mcp` downloads **no** model weights under this topology. That separation is the point
of the ruling: one service owns the parsing footprint, and the MCP surface stays light.

Pre-fetching those weights at install time rather than on the first production conversion is
**VERIFICATION REQUIRED** — otherwise the first document to arrive also triggers the first
download, and a network or storage failure surfaces as a conversion failure.

## Integration contracts

Every integration is classified before any contract is written. A 2025 integration does not
survive into 2026 by default.

**None of these partner services is built.** Every host below carries an *approved role
assignment* in `SERVER-REGISTRY.md`, not a running service. No `servers/<host>/configuration.md`
exists for any of them; server implementation is Phase 3 and has not started. The same
authority boundary this document applies to itself applies to its partners: role assignment is
asserted, as-built state is not. Neither side of the LightRAG handoff exists yet.

| Integration | Current host | Classification | Basis |
| --- | --- | --- | --- |
| LightRAG | hxs-3 | **CURRENT PIPELINE REQUIRED** | Grouped with Docling in roadmap phase 4, "Retrieval & ingestion" — a bring-up grouping, not a role grouping. Parsed text must reach graph building. Direct service contract **NOT ESTABLISHED** |
| Qdrant | hxs-4 | **INDIRECT** | Reached through LightRAG, which owns the **RAG** collections. Backend not yet frozen |
| Embeddings / reranker | hxs-4 | **INDIRECT** | hxs-4's assigned capability, not Docling's work. Governed by the first-ingest freeze gate |
| LiteLLM gateway | hxs-8 | **LEGACY CANDIDATE** | The reason Docling called it moved to hxs-3 |
| Redis | hxs-9 | **LEGACY CANDIDATE**, conditional | Upstream has no Redis integration; its cache is in-process. **But hxs-9 is the fleet's assigned queue host, so the queue handoff pattern would reclassify it** |
| PostgreSQL | hxs-9 | **LEGACY CANDIDATE** | Metadata storage never became part of the parsing role |
| FastMCP runtime | hxs-7 | **VERIFICATION REQUIRED** | Sharpened by the SDK v2 change — this is no longer a FastMCP server |
| LangGraph | hxs-11 | **CONTINGENT** | Not an integration today. Becomes one only if the orchestrated handoff pattern is chosen |

### LightRAG

```
classification:           CURRENT PIPELINE REQUIRED
direct_service_contract:  NOT ESTABLISHED
handoff_owner:            VERIFICATION REQUIRED
```

The pipeline relationship is required; a direct service contract between Docling and LightRAG
is **not** established, and nothing here creates one. This wording is deliberate: treating a
pipeline dependency as a direct contract is how the 2025 project ended up with Docling owning
the whole ingestion stack.

Docling parses; LightRAG builds the graph. The fleet architecture's **roadmap phase 4**
brings up Qdrant, the embedding/reranker services, LightRAG, Docling and Crawl4AI together
under "Retrieval & ingestion" — a bring-up sequence, not a role grouping (the registry roles
are distinct: hxs-3 "Agent intelligence", hxs-12 "Ingestion — parsing"). Either way the
boundary between parsing and graph building is real and must be crossed somehow.

**The same phase carries a first-ingest freeze gate**, and it constrains this handoff
directly: embedding model, embedding dimension, LightRAG storage backend and Qdrant collection
design must be frozen and round-trip validated before any bulk ingest. A handoff design that
assumes any of those four is settled is premature.

What is settled: Docling produces a structured document and can export it as Markdown, JSON
or plain text. LightRAG consumes text and produces entities and relationships.

Candidate handoff patterns, none chosen — the handoff owner is **VERIFICATION REQUIRED**:

| Pattern | Shape |
| --- | --- |
| Docling pushes | Docling calls LightRAG when a conversion completes. What 2025 did (lgc-151) |
| LightRAG pulls | LightRAG requests parsed output when it is ready to ingest |
| Queue or store handoff | Neither calls the other; parsed output lands somewhere both agree on. The fleet's assigned queue substrate is Redis on hxs-9 — choosing this reclassifies Redis |
| Orchestrated | A third component sequences both — the pattern LangGraph on hxs-11 would imply. Choosing this makes hxs-11 a pipeline participant |

What is not settled and must be decided before a contract is written: **which side initiates**.
In 2025 Docling held an HTTP client and called the LightRAG service (lgc-151). That was a consequence of
Docling once owning the whole pipeline. With LightRAG now a service in its own right on hxs-3,
with its own co-located model, the call could reasonably run the other way, or through a
queue. This is **VERIFICATION REQUIRED** and is the most important open question in this
document.

Transport, payload format and whether parsed output is passed by value or by reference are all
**VERIFICATION REQUIRED**.

### Qdrant — INDIRECT

Do not author a direct Docling-to-Qdrant contract. The evidence against it is specific and
came from the 2025 project's own correction cycle:

- The specification gap analysis (lgc-127) recorded a **critical** conflict: Docling was
  initially designed to install LightRAG locally, and that was reversed in favour of
  integrating with the separate LightRAG service. **This is the decision that moved graph
  building out of Docling.**
- The same analysis recorded a **collection-ownership conflict**, fixed (lgc-117) by renaming
  Docling's collections. That was a naming deconfliction, not a ruling against direct access —
  it left Docling still holding collections of its own.

The load-bearing evidence is what the 2025 task breakdown then built anyway: **entity
insertion with deduplication (lgc-158), bidirectional relationship insertion (lgc-159), and
vector search with graph traversal (lgc-161)**. Those are graph building — the exact work the
local-LightRAG reversal had already moved to the separate service. A direct client (lgc-156),
collection initialisation (lgc-157) and payload indexes (lgc-160) are ambiguous on their own;
these three are not.

**That is the specific failure this classification exists to prevent.** Note the sequence is
inferred from the task breakdown's own structure, not from dated evidence — the ledger records
no timestamps, so "the design decided one thing and the build did another" is the defensible
claim, not a proven chronology.

Scope note: LightRAG owns the **RAG** collections. It does not own every collection on hxs-4 —
Mem0 on hxs-11 is assigned a separate Qdrant collection, distinct from RAG. And the LightRAG
storage backend itself is a first-ingest freeze item: validated as feasible, not yet frozen.

If a current requirement genuinely calls for Docling to touch the vector store directly, that
is a new decision requiring a current architecture ruling — not an inheritance.

### Embeddings and reranking — INDIRECT

hxs-4 is assigned BGE-M3 / Nomic embeddings and a BGE reranker behind a serving layer. The
2025 plan had Docling configuring its own embedding generation. That is superseded: embedding
generation is hxs-4's assigned capability. **Docling does not embed.**

This is not merely an inherited invariant. The current fleet architecture places a
**first-ingest freeze gate** ahead of any bulk ingestion: the embedding model, the embedding
dimension, the LightRAG storage backend and the Qdrant collection design must all be frozen
and round-trip validated before ingest begins. Embedding choice is therefore a fleet-level
decision governed by that gate, not something a parsing service settles.

### LiteLLM gateway — LEGACY CANDIDATE

In 2025 Docling called the model gateway because Docling ran the entity-extraction step
itself. That step now belongs to hxs-3, which has a model co-located with it. Docling's
current role is parsing, and parsing needs no language model.

The 2025 material records a **critical, still-open** defect against this integration
(lgc-080): a gateway authentication failure that blocked the health check. Following the
brief's ruling on that defect, it is treated as evidence that an authentication concern
existed, not as a current credential problem. `legacy-secret-002` is inspect-only provenance. It is not a
current credential, not a rotation target, and does not appear in any active configuration
described here.

If a future Docling workflow does need a language model — picture description or formula
enrichment through a vision model are the realistic cases — it routes through the current
model gateway and gets classified then. It does not get a contract now.

Two design details are worth keeping if that day comes: model fallback was handled by the
gateway's router rather than by Docling, and retries used **one shared budget across all
error types** rather than a separate allowance per error (lgc-125, lgc-126, lgc-163,
lgc-164).

### Redis — LEGACY CANDIDATE

The upstream package caches converted documents in an in-process dictionary keyed by a hash
of the source and the conversion settings. That cache is lost on restart and is not shared
between processes. Upstream has no Redis integration at all; the 2025 session management and
shared cache were an HX addition on top.

Whether the current design wants a shared cache is a real question with a real cost, and it is
not answered by the fact that 2025 wired one up. **VERIFICATION REQUIRED.**

### PostgreSQL — LEGACY CANDIDATE

2025 configured a metadata database. Nothing in the current parsing role requires one.

### FastMCP runtime on hxs-7 — classification VERIFICATION REQUIRED

hxs-7 currently runs a FastMCP runtime and custom HX MCP servers. Docling also runs its own
MCP server on hxs-12. The standalone-server decision says a gateway may compose and proxy, and
that this is optional.

Whether hxs-7 fronts Docling's tools, whether agents connect to hxs-12 directly, or both, is
not recorded in any current authority. This is a current architecture decision, not a legacy
one, so none of the four legacy classifications fit. It needs a ruling before the transport
and bind address can be fixed.

Provenance: lgc-105, lgc-117, lgc-118, lgc-123, lgc-125, lgc-126, lgc-127, lgc-080,
lgc-151, lgc-156..lgc-161, lgc-162..lgc-164.

---

## Docling and model serving — the boundary

Core document conversion is not served by a language model and must not be described as
though it were. Layout analysis, table structure recognition, reading order and OCR are
computer-vision and parsing models that run inside the processing library on the host.

**hxs-12 has no GPU, and Docling Serve runs on it.** Therefore:

- Serve's accelerator setting resolves to CPU. There is no CUDA device to select, which is why
  it is installed from the `cpu` extra rather than a CUDA-indexed build.
- OCR runs on CPU. The 2025 measurements put OCR-enabled throughput roughly five to ten times
  below OCR-disabled throughput, and those numbers were not taken on this hardware.
- Vision-model pipelines — picture description, picture classification, and the vision-model
  document pipeline — are available in the library but would run on four CPU cores. They are
  **not enabled by default** in this design. Enabling any of them is a decision that must be
  made against measured cost on this host.
- GPU toolchain concerns, driver pinning and model-serving runtimes belong to the fleet's
  GPU-bearing hosts. None of them are Docling requirements and none appear here.

Provenance: lgc-066, lgc-069, `servers/hxs-12/discovery.md`.

---

## Runtime and service model

- **Bare metal, systemd, no containers.** This matches both the inherited decision and the
  current fleet's practice. The host has no container runtime installed.
- **Two units, one host.** `docling-serve` parses; `docling-mcp` presents the MCP surface and
  calls it over loopback. Each is a single process; the document cache is per-process, so a
  second instance of either would not share it. Horizontal scaling is not part of this design.
- **Unit ordering.** `docling-mcp` is ordered *after* `docling-serve`, but must not hard-require
  it — see the next point. Serve restarting is a degraded window, not a reason for the MCP
  surface to exit.
- **No hard systemd dependency on remote services.** The 2025 architecture review specifically
  required removing a `Requires=` directive on remote units, replacing it with
  application-level dependency checking and retry. A parsing service must start and stay
  running when a downstream service is briefly unavailable; it must not be held down by
  systemd because another host is restarting.
- **Pre-start validation inline**, not delegated to a separate script.
- **No post-stop cleanup hook.** The 2025 review removed one and it was not reinstated.
- **Service account** owns the installation, the cache and the working directories. The
  account name must not contain characters that break shell tooling — a 2025 defect traced
  directly to an `@` in a directory-integrated account name producing a home path that broke
  scripts. Whether the current service account is local or directory-integrated is
  **VERIFICATION REQUIRED**.

### Logging

- Structured logging through the standard logging facility. Never `print()` — a 2025 defect
  was raised for exactly that.
- **Never overwrite the global journald configuration.** A 2025 task overwrote
  `journald.conf` wholesale and destroyed the existing configuration. Logging preferences are
  service-scoped; a systemd drop-in is used only when a deliberate system-wide change is
  actually required, and then as a drop-in rather than a replacement file.
- Log rotation must be defined, with retention bounded against a single 238 GB disk.

Provenance: lgc-083 (journald), lgc-094 (path/account), lgc-078 (logging), lgc-108, lgc-109,
lgc-110, lgc-180, lgc-181, lgc-182, lgc-183.

---

## Configuration model

- **No hardcoded endpoints anywhere** — not in code, not in tests, not in documentation. This
  is the strongest lesson in the whole 2025 record: the gap analysis (lgc-127) found **245
  wrong address literals across 38 files**, enough that the service could not have worked as
  specified. Every endpoint resolves from the registry or from configuration at deploy time.
- **No absolute paths embedded in examples.** Paths derive from a defined service root.
- Configuration loads from environment, then a file, then defaults — in that precedence.
- Settings are validated at startup through a typed settings model, and startup fails loudly
  on a missing required value rather than starting half-configured.
- One authoritative place per value. A 2025 defect was raised because a port number appeared
  inconsistently across many documents; the fix is that a value has one home and everything
  else refers to it.

### Values requiring current resolution

| Setting | Status |
| --- | --- |
| MCP listen port | **VERIFICATION REQUIRED** — package default 8000 |
| Serve listen port | **VERIFICATION REQUIRED** — Serve's uvicorn default is 5001, loopback only |
| `conversion_mode` | **Settled** — `remote` |
| `service_url` | **Settled in shape** — Serve on loopback; port per above |
| `fallback_to_local` | **Settled** — `false`; no local converter is installed |
| Bind address | **Settled** — the standing fleet rule is to bind the LAN interface, not `0.0.0.0` |
| Transport | **Settled** — the fleet standardises on Streamable HTTP |
| Service root path | **VERIFICATION REQUIRED** |
| Cache path | **VERIFICATION REQUIRED** — see below |
| Max document size | **VERIFICATION REQUIRED** — 2025 used 100 MB |
| Concurrency and worker counts | **VERIFICATION REQUIRED** — see *Validation requirements* |
| Enabled tool groups | **VERIFICATION REQUIRED** |
| OCR on or off by default | **VERIFICATION REQUIRED** — material cost on a CPU-only host |

No credential value appears in this document or in the configuration it describes. Where the
inherited configuration referenced secrets, those references are recorded by identifier only.
The 2025 vault mechanism is retired along with the tool that provided it.

Provenance: lgc-071, lgc-072, lgc-073, lgc-106, lgc-117, lgc-127, defect evidence lgc-074,
lgc-075, lgc-076, lgc-077, lgc-082, lgc-088.

---

## Data and cache paths

The host has exactly one NVMe device of 238.5 GB carrying a 232.64 GB ext4 root, about 4.7
percent used — roughly 222 GB free — with no second device, no spare capacity and no
redundancy. Four kinds of data compete for it:

1. **Model artefacts** — layout, table-structure and OCR weights, downloaded on first use.
   **Owned by Docling Serve**, on this host.
2. **Converted document cache** — `docling-mcp`'s own on-disk exports of parsed documents,
   separate from Serve's model cache.
3. **Working files** — whatever a conversion needs mid-flight.
4. **Swap** — the host uses a swapfile on this same and only device.

**A second cache exists and it is not the model cache.** The package reads a bare, unprefixed
`CACHE_DIR` environment variable — outside the typed settings model, so it is *not* covered by
the startup validation rule below. Left unset it creates a `_cache` directory **inside the
installed package tree**, and the document-save and page-thumbnail tools write there. This
applies regardless of where conversion runs, so it is `docling-mcp`'s to pin explicitly to
the service root — separately from Serve's model cache.

Requirements:

- Every path sits under a defined service root owned by the service account. **Nothing lives
  under a home directory.**
- The model cache path is pinned explicitly rather than left to a default that resolves into a
  home directory.
- **Unit sandboxing must be consistent with the cache location.** A 2025 defect had the model
  cache fail with permission denied because the systemd unit's home-protection setting hid the
  very directory the default cache path pointed at. The fix is not to loosen the sandbox — it
  is to put the cache where the service account owns it and the sandbox permits it, and to
  keep those two decisions aligned.
- Cache growth is **bounded**, with the bound chosen against remaining disk rather than
  inherited. Root is currently about 4.7 percent used, so roughly 222 GB is free, and that
  same space carries the operating system.

Provenance: lgc-084 (cache permissions), lgc-094 (home paths), `servers/hxs-12/discovery.md`.

---

## Validation requirements

The 2025 suite is not carried forward. Its shape is.

**Five test groups**, which map cleanly onto what a parsing service needs to prove:
deployment, functionality, integration, health, and multimodal input handling.

**Coverage discipline, re-baselined.** The 2025 numbers — a 100 percent mandate, line coverage
at or above 95 percent, branch coverage at or above 90 percent — are recorded as the previous
intent, not adopted as current targets. Current thresholds are **VERIFICATION REQUIRED**.

**A quality gate must be able to fail, and must prove it.** The 2025 quality review's first
finding was false-positive quality gates: gates that reported success without validating
anything. The requirement here is not the principle but the evidence — **a gate is accepted
only when a recorded failing run of that gate is retained alongside it.** A gate with no
captured failing run is not accepted. The gate inventory itself is **VERIFICATION REQUIRED**;
until it exists, "any gate defined for this service" is vacuously satisfied by defining none.

**A claimed result counts only when its output is captured.** A test result reported in
conversation is not evidence. Command, branch, working-tree state, counts and timestamp are
recorded together or the claim does not stand.

**Mandatory coverage, carried forward as discipline rather than as old test counts:**

- **Deliberately malformed input fixtures.** The 2025 malformed-PDF fixtures were themselves
  invalid — too small to contain what they claimed — so the tests that depended on them proved
  nothing. This defect was still open at handover. Malformed fixtures must be verified to be
  malformed in the intended way.
- **Explicit coverage for every supported input format**, plus format detection from file
  content, `file://` prefix handling, and case-insensitive extension matching. Detection is
  layered — content signature, then MIME type, then extension, then heuristics — and each
  layer needs its own test.
- **Coverage-gap tracking as a practice.** The 2025 work found whole areas with no tests at
  all: document validation, document creation, provenance, and edge cases generally. Tracking
  the gaps is the habit worth keeping.
- **Error-path tests, named rather than gestured at.** Each of these is a defect this project
  already paid for once, so each gets its own test: retry delay clamped at zero including the
  negative-jitter case; redaction asserted against every credential form it claims to cover,
  failing closed; semantic version comparison; structured-output parse failure degrading to
  the defined fallback; and each conversion status handled distinctly, with **partial success
  asserted as its own state** rather than collapsed into failure.
- **Malformed-input tests must assert the specific failure mode**, not merely that an error
  occurred. A fixture too small to be a valid document is rejected for the wrong reason and
  proves nothing — which is exactly the 2025 defect.
- **Format detection must be tested from file content**, not from a filename-derived MIME
  lookup, or the lesson is defeated while appearing satisfied.
- **Coverage gaps are tracked in `governance/logs/actions-and-issues.md`**, the project's only
  routine tracker. A discipline with no home does not survive implementation.
- **Export coverage across every item type.** A 2025 defect had Markdown export silently
  incomplete for several item types.
- **Rollback validated before deployment**, not assumed.
- **Defect handling wired into test execution** rather than run alongside it.

**Throughput expectations must be measured on this host, not inherited.** Every 2025
performance figure was taken on different hardware, and this host has four cores and no GPU.
Concurrency, worker counts and any timeout defaults are **VERIFICATION REQUIRED** and should
be set from measurement.

Provenance: lgc-113 (quality review), lgc-128 (testing review), lgc-208 (test plan), lgc-211
(suite index), lgc-212..lgc-225 (deployment cases), lgc-245..lgc-248 (health cases),
lgc-249..lgc-253 (integration cases), lgc-254..lgc-259 (multimodal cases); defect evidence
lgc-092, lgc-093, lgc-098, lgc-099.

---

## Failure handling

- **Bounded, tested backoff.** Retry delay is clamped so it can never go negative — a 2025
  defect produced negative sleep values from unclamped jitter.
- **No regex-patched control flow.** A 2025 task applied retry behaviour by pattern-matching
  and rewriting source text. Retry is composed explicitly in code.
- **Semantic version comparison** wherever a version constraint is evaluated. String
  comparison was a real defect, and it fails in the ordinary case where a two-digit component
  sorts below a one-digit one. Dependency constraints declare upper bounds as well as lower.
- **Library-based authentication parsing and redaction.** A 2025 redaction pattern for bearer
  tokens had no capture group for the bearer form, so the substitution failed and **the token
  was not redacted at all**. Any redaction must be tested against every credential form it
  claims to cover, and must fail closed.
- **Structured-output parse failures degrade to a defined fallback** rather than crashing.
- **Conversion status is explicit.** The processing library reports success, partial success,
  failure, skipped and pending as distinct outcomes, with per-element confidence available.
  Partial success is a real state and must be handled as one, not collapsed into failure.
- **Application-level dependency checks with retry**, since systemd carries no hard
  requirement on remote units.

Two decisions were explicitly deferred in 2025 and remain open, carried forward as design
decisions to confirm rather than as defects: the **circuit-breaker criterion**, whose
acceptance condition was ambiguous, and **schema versioning** for the document representation.

Provenance: lgc-079, lgc-085, lgc-086, lgc-090, lgc-091, lgc-095, lgc-096, lgc-097,
lgc-164, lgc-066.

---

## Operational checks

**Health behaviour is topology-dependent, and the 2025 assumption does not survive either
way.** The 2025 design asserted a health endpoint on a dedicated port and wrote health tests
against it.

Under the chosen topology, health is **two questions**: is the MCP surface up, and is Docling
Serve reachable on loopback. The second is a check against Serve, not against `docling-mcp`.
Whether a Serve failure should make the MCP surface report unhealthy — rather than report
healthy-but-degraded — is **VERIFICATION REQUIRED**.

`docling-mcp` itself still exposes no health endpoint, so whatever probes these two questions
is HX-authored.

The remaining upstream capability boundaries stand regardless of topology: no authentication,
no multi-tenancy, no request metrics, no distributed cache.

Minimum operational checks for a parsing service:

- The MCP endpoint answers a tool-discovery request.
- **Docling Serve answers on loopback.** This is a distinct check with a distinct failure mode:
  the MCP surface can be perfectly healthy while conversion is unavailable.
- The enabled tool groups are the ones intended.
- Serve's model artefacts are present and readable by its service account.
- Disk headroom on the single device is above a defined floor.
- A known-good sample document converts end to end.

Whether these are exposed as an endpoint, a systemd health check, or an external probe is
**VERIFICATION REQUIRED**.

Provenance: lgc-067, lgc-070 (upstream has no health endpoint), lgc-245..lgc-248 (2025 health
cases), lgc-187, lgc-191.

---

## Known gotchas and legacy lessons

Short list, each one traceable, each one a thing that actually went wrong:

| Lesson | Origin |
| --- | --- |
| A missing native imaging library stops the service starting, and the pre-24.04 package name no longer exists on 24.04 | lgc-081 |
| The model cache fails with permission denied when unit sandboxing hides the default cache location | lgc-084 |
| Overwriting global journald configuration destroys existing settings | lgc-083 |
| Address literals spread through documentation — 245 across 38 files — and none of them worked | lgc-127 |
| A port number duplicated across documents drifts out of step | lgc-082 |
| An `@` in a service account name produces paths that break shell tooling | lgc-094 |
| Unclamped retry jitter produces negative sleep values | lgc-090 |
| A bearer-token redaction pattern with no capture group silently redacts nothing | lgc-097 |
| String version comparison gives wrong answers on ordinary version numbers | lgc-096 |
| Quality gates that cannot fail report success forever | lgc-113 |
| Malformed-input fixtures that are not actually malformed test nothing | lgc-099 |
| An ownership command without a guard fails when the account does not exist | lgc-076 |
| Implementation drifted back to direct vector-store access after the design ruled it out | lgc-127 vs lgc-156..lgc-161 |

---

## Current verification required

Consolidated and renumbered. Nothing below may be treated as decided.

**Settled — recorded so they are not reopened**

Conversion topology (remote, Serve co-located on hxs-12, owner ruling 2026-08-13);
`conversion_mode=remote`; `fallback_to_local=false`; virtualenv per service with an absolute
interpreter in `ExecStart`; Streamable HTTP as the fleet transport standard; the standing
bind-to-LAN-interface rule, which for Serve means loopback only.

**Architecture and boundaries**
1. Direction, initiator and transport of the Docling↔LightRAG handoff.
2. Relationship with the runtime on hxs-7, sharpened by the SDK v2 change — that host's
   assigned workload is a FastMCP runtime and this is no longer a FastMCP server.
3. Whether any shared cache or session store is wanted, given the package cache is in-process.
4. Whether any optional RAG or information-extraction toolgroup is ever enabled — all are
   disabled by HX default.

**Interface**
5. The authoritative tool names within the enabled groups, read from the pinned version.
6. Which tool groups are enabled.

**Configuration**
7. MCP listen port, and Serve's loopback port.
8. Service roots and cache paths for **both** units, kept distinct.
9. The mechanism that enforces the cache size bound, and the disk-headroom floor value.
10. Maximum document size, bound together with item 12 as one memory budget.
11. OCR enabled or disabled by default, decided against measured CPU cost.
12. Concurrency and worker count for both units, set from measurement on hxs-12.

**Runtime**
13. Dependency versions at both pinned releases, with upper bounds declared.
14. Exact native library package names on Ubuntu 24.04, confirmed on the host.
15. Service account identity for each unit, and whether local or directory-integrated.
16. Measured model-artefact footprint for Serve — the cache bound cannot be computed without it.
17. Model pre-fetch at install time, so the first conversion is not also the first download.
18. Restart policy and start rate limiting for both units; pre-start validation scoped to local
    preconditions only, so the removed hard dependency is not reintroduced through `ExecStartPre`.
19. How a conversion is bounded, given `service_timeout` and `service_max_retries` are declared
    but unconsumed at v3.0.0.

**Validation and operations**
20. Coverage thresholds.
21. The gate inventory, and a recorded failing run for each gate.
22. The supported input-format inventory, without which per-format coverage is unmeasurable.
23. Health probe mechanism and frequency, covering both the MCP surface and Serve.
24. Whether a Serve outage makes the MCP surface report unhealthy or healthy-but-degraded.
25. Log destination — journal or file — before its retention bound can be set.
26. Circuit-breaker acceptance criterion (deferred in 2025).
27. Schema versioning approach (deferred in 2025).

## Provenance

This document was distilled from the 2025 Docling files under
`nodes/hx-docling-mcp-server/`, ledger rows `lgc-064` to `lgc-261`:

```
195 content-eligible files reviewed
115 contributed distilled content
 80 reviewed-not-used
  3 blocked / never opened
```

**Correction to an earlier figure.** The first pass reported 120 contributed / 75
reviewed-not-used. That 120 was inflated by five rows — `lgc-210` and `lgc-226` through
`lgc-229` — which a loose pattern in the generator swept in without their ever being cited.
The recount above is derived per row from the provenance index and is the accurate one. The
195 / 3 figures are unchanged.

The three blocked rows are `lgc-134`, `lgc-260` and `lgc-261`, referenced by identifier only.

**Source of record.** `Hana-X-AI/HX-Infrastructure`, ref `legacy/2025`, commit
`a98846d6930f7b0097e7ac237c93b60280f99e44` — a protected, read-only archive ref. Every row
binds to a per-file SHA-256 verified against that commit. Ledger identity:
`manifest_base_sha256` `2d6faadc…6b31a`, `manifest_resolved_sha256` `8983c5d6…bea7d`.

| Section | Ledger rows |
| --- | --- |
| Purpose | lgc-064, lgc-065, lgc-066 |
| Current placement | SERVER-REGISTRY.md, fleet-architecture-v0.3, servers/hxs-12/discovery.md |
| Architecture | lgc-105, lgc-107, lgc-067, lgc-068 |
| MCP tool surface | lgc-064, lgc-067, lgc-070, lgc-124 |
| Dependencies | lgc-067, lgc-079, lgc-081, lgc-135, lgc-136, lgc-137 |
| Integration contracts | lgc-080, lgc-105, lgc-117, lgc-118, lgc-123, lgc-125, lgc-126, lgc-127, lgc-151, lgc-156..161, lgc-162..164 |
| Model-serving boundary | lgc-066, lgc-069, servers/hxs-12/discovery.md |
| Runtime and service model | lgc-078, lgc-083, lgc-094, lgc-108, lgc-109, lgc-110, lgc-180..183 |
| Configuration model | lgc-071, lgc-072, lgc-073, lgc-106, lgc-117, lgc-127, lgc-074..077, lgc-082, lgc-088 |
| Data and cache paths | lgc-084, lgc-094 |
| Validation requirements | lgc-113, lgc-128, lgc-208, lgc-211, lgc-212..225, lgc-245..259, lgc-092, lgc-093, lgc-098, lgc-099 |
| Failure handling | lgc-066, lgc-079, lgc-085, lgc-086, lgc-090, lgc-091, lgc-095, lgc-096, lgc-097, lgc-164 |
| Operational checks | lgc-067, lgc-070, lgc-187, lgc-191, lgc-245..248 |
| Gotchas | lgc-074..lgc-100 (defect family), lgc-127, lgc-113 |

Credential references appear by identifier only. `legacy-secret-001` is a historical exposure
tracked outside this document and is not referenced by this design. `legacy-secret-002` is
inspect-only provenance and does not appear in any configuration described here.

Historical files remain in their original lineage. Nothing from 2025 has been copied into this
repository.
