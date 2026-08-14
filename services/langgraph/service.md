# LangGraph

Status: TARGET-STATE DESIGN — **REVISED / NOT ACCEPTED**
Target placement: hxs-11 — Agent runtime (resolved from `SERVER-REGISTRY.md`)
As-built status: NOT ASSERTED BY THIS DOCUMENT
Implementation: **NOT AUTHORIZED**. Deployment on hxs-11 is NO-GO until acceptance.

Acceptance path: four owner decisions (below) → update this design to reflect the rulings →
re-run all four capability reviews in separate contexts → only then ACCEPTED FOR IMPLEMENTATION.
Decision packet: `governance/operations/langgraph/claude_20260814_0848_langgraphfourdecisions.html`

Every section carries `SME REVIEW REQUIRED`. Four reviews ran on 2026-08-14 —
`langgraph` FAIL, `mem0` FAIL, `infrastructure-ops` FAIL, `testing-qa` CONDITIONAL PASS. The
corrected revision has **not** been re-reviewed, and re-reviewing before the decisions land would
regenerate the same findings, because three of the four decisions change the design under review.

---

## Open owner decisions

These are **decisions, not verification items**. Each changes the design, so all four land before
the reviews re-run. Recommendations live in the decision packet; the rulings are the owner's and
none is made here.

| # | Decision | Status | Effect |
| --- | --- | --- | --- |
| 1 | **Qwen network-consumability** — promote with an access and auth model, route remote consumption only through the traffic plane, or drop the Qwen dependency for first deployment. | **OPEN — gates everything** | Nothing in the model path is implementable until this clears. Recorded as two acceptance states in `runtime-acceptance-decisions.md`; `accepted-network-consumable` is NOT GRANTED. |
| 2 | **LiteLLM → OmniRoute reconciliation** | **APPLIED this pass** | Model gateway is now `BLOCKED / PENDING OMNIROUTE RECONCILIATION`. No gateway contract built for either name. Ownership boundary unchanged — only the named plane moved. |
| 3 | **Deployment mode** — embedded library vs packaged server. | **OPEN** | Silently decides Store enforcement, the Redis classification, and checkpointer construction, plus process lifecycle, failure isolation and networking. Needs a focused comparison against current architecture **including OmniRoute and jcode**, both of which post-date most of the 2025 material. Not a snap call; may warrant its own architecture pass. |
| 4 | **Is MCP day-one required?** | **OPEN** | The design classifies the MCP tool plane CURRENT REQUIRED, which makes an MCP-plane SME contract mandatory. That may manufacture a blocker inconsistent with HX's deliberately deferred MCP posture. Candidate downgrade to LATER / DEFERRED unless minimum-useful first-deployment orchestration genuinely depends on MCP tools. |

Authority boundary:
- Authoritative for the current *intended* LangGraph service design.
- Does NOT assert the service is installed, configured, reachable, or validated.
- `SERVER-REGISTRY.md` is authoritative for host/role placement.
- `servers/<host>/configuration.md` is the as-built authority AFTER implementation.
- Legacy 2025 sources are non-authoritative evidence and lessons only.

---

## Purpose

LangGraph is the agent orchestration layer for HX. It sequences multi-step work across the
fleet's specialist services — retrieval, memory, model inference, tools — and holds the
execution state that makes that work resumable.

The 2025 lang-server programme established the intent (`lgc-262`): a central orchestration hub
for stateful, multi-step AI workflows, replacing linear retrieve-then-generate pipelines with
conditional reasoning, iteration and tool use. That intent survives. Almost none of its
implementation detail does, and the sections below are explicit about which is which.

---

## What LangGraph owns / does NOT own

This section is the point of the document. A stateful orchestrator that persists state, calls
models, invokes tools and reaches retrieval will absorb ownership of all four unless the
boundary is written down and defended.

### LangGraph owns

| Concern | Note |
| --- | --- |
| Graph execution state | The working state of a run, as it runs. |
| Thread and checkpoint state | Per-thread resumability. Persisted; see State and checkpointing. |
| Orchestration control flow | Which node runs next, on what condition, with what handoff. |
| Interrupt and resume state | Human-in-the-loop approval points and their resumption. |
| Orchestration-owned metadata | Data about the run itself, not about the user or the domain. |
| Pre-dispatch envelope enforcement | Honouring the verified model envelope supplied by the routing plane. |

### LangGraph does NOT own

| Concern | Owner | Boundary rule |
| --- | --- | --- |
| Durable semantic / user / agent memory | Mem0 | Orchestration asks for memory; it does not keep its own. |
| Retrieved knowledge, graph building | LightRAG | Orchestration sequences retrieval; it does not index or extract. |
| Vectors, embeddings, collections | LightRAG / embedding plane | Embedding requests route through retrieval, never direct to a model host (`lgc-279` FR-012). |
| Model routing and endpoint identity | the model traffic plane | Orchestration requests a *capability*; it never binds to a named host or model. The named plane is pending OmniRoute reconciliation; the boundary is unchanged. |
| Runtime qualification of a model | `governance/policy/runtime-acceptance-decisions.md` | Orchestration consumes an accepted capability; it does not decide fitness. |
| General queue / cache infrastructure | Platform role on the state-services host | Orchestration does not own shared infrastructure. |
| MCP server registration, gateway policy | MCP plane | Orchestration is an MCP *client* only (`lgc-279` FR-017). |
| Infrastructure configuration | `infrastructure-ops` | — |
| Authority over HX specialist agents | The specialist capability contracts | The orchestration pattern is a mechanism, not a source of authority. |

**The recurring failure mode.** Each row above is a place where upstream *supports* doing the
thing LangGraph should not do. Support is not permission. Where an upstream feature would pull
the service across its own boundary, this design disables it by default and says so.

---

## Owning SME(s)

| Capability | Role here |
| --- | --- |
| `langgraph` | Owns this design. Defends the boundary above. |
| `mem0` | Owns the memory boundary; stakeholder on the Store decision. |
| `infrastructure-ops` | Host, runtime, service model, operational checks. |
| `testing-qa` | Validation requirements and whether the gates can fail. |
| `lightrag` | Consulted on the retrieval boundary and the parsing handoff. |

---

## Current placement

Resolved from `SERVER-REGISTRY.md`:

| Concern | Host | Registry role / workload |
| --- | --- | --- |
| LangGraph runtime | hxs-11 | Agent runtime — LangGraph; Mem0, separate virtualenvs |
| Checkpoint persistence | hxs-9 | State services — PostgreSQL + Redis; **LiteLLM database**; LangGraph checkpoints |
| Model traffic plane | hxs-8 | API gateway & control. The registry names LiteLLM; **OmniRoute supersedes it in target state**, so the plane is `BLOCKED / PENDING OMNIROUTE RECONCILIATION`. |
| Retrieval | hxs-3 | Agent intelligence — LightRAG graph & retrieval |
| MCP tool plane | hxs-7 | MCP services — FastMCP runtime + custom HX MCP servers |
| Parsing | hxs-12 | Ingestion — parsing — Docling (+ MCP) |
| **Vector store, embeddings** | **hxs-4** | Retrieval & AI utility — Qdrant; embedding and rerank plane. Holds **Mem0's memory collection** as well as the retrieval collections. |
| Probable caller | hxs-10 | Open WebUI; CopilotKit/AG-UI |
| Validation execution | hxs-15 | Test & integration |
| Development | hxs-14 | Prompt engineering; LangGraph and client development |

hxs-9's co-tenancy is stated explicitly because it bears on checkpoint sizing: the same host and
the same single device carry the gateway's database, Redis and platform state.

### Values requiring current resolution

The registry is authoritative for hosts and roles. It carries **no port field and no path field**,
and no port-allocation authority exists in this repository — so the rule "resolve everything from
the registry" cannot be satisfied for the two values operations most needs. They are named here
rather than left implicit.

| Value | Status |
| --- | --- |
| Listen address and port | `VERIFICATION REQUIRED` — no fleet port-allocation authority exists; route to `infrastructure-ops` |
| Served protocol and transport | `VERIFICATION REQUIRED` — the served interface is undefined; see below |
| Whether LangGraph serves an interface at all | `VERIFICATION REQUIRED` — it may be invoked in-process rather than over a socket |
| Service root path and ownership | `VERIFICATION REQUIRED` |
| Service account | `VERIFICATION REQUIRED` |
| Log path and retention bound | `VERIFICATION REQUIRED` — bounded against a single 238.5 GB root |
| Worker / concurrency count | `VERIFICATION REQUIRED` — capped by 4 cores with no SMT; see Runtime |
| Checkpoint disk budget on hxs-9 | `VERIFICATION REQUIRED` — see State and checkpointing |

Until the served interface is defined, the operational checks below are specified but **not yet
performable**. That is a gap in this design, not a deferral to implementation.

Addresses, ports and FQDNs are deliberately absent. They resolve from the registry at
configuration time. Every address in the 2025 material is stale, and the material is not even
self-consistent about them: the deployment plan (`lgc-278`) and the execution summary
(`lgc-474`) give two different addresses for the same database host. That contradiction is the
argument against translating legacy values rather than resolving current ones.

LangGraph and Mem0 are co-located on hxs-11 in **separate virtual environments**, per the
current fleet architecture. Co-location is not integration.

---

## Upstream pinning

`VERIFICATION REQUIRED — NOT YET PINNED. This is an acceptance-gate failure, recorded rather than
concealed.`

The brief requires each independently-versioned package pinned to a release with the date checked,
and the migration pattern's DESIGN gate asserts "upstream pinned to one release". This pass
verified current upstream *behaviour* — the agent-constructor shape, the checkpointer/Store split,
the persistence model — but did **not** pin releases. Every current-upstream claim below therefore
rests on documentation retrieved 2026-08-14 without a version number.

These do not move together and must be pinned separately:

| Package | Pin | Checked |
| --- | --- | --- |
| `langgraph` | `VERIFICATION REQUIRED` | — |
| `langchain-core` | `VERIFICATION REQUIRED` | — |
| the agent-constructor package (LangChain agents) | `VERIFICATION REQUIRED` | — |
| `langgraph-checkpoint` | `VERIFICATION REQUIRED` | — |
| `langgraph-checkpoint-postgres` | `VERIFICATION REQUIRED` | — |
| `psycopg` (with pool extra) | `VERIFICATION REQUIRED` | — |
| MCP client adapter | `VERIFICATION REQUIRED` | — |
| Mem0 | `VERIFICATION REQUIRED` | — |

Co-location adds a constraint the isolation rule alone does not cover: LangGraph and Mem0 sit in
separate virtual environments **each pinned to compatible LangChain-family versions**, because
Mem0 pulls LangChain-family dependencies of its own.

## Deployment mode

`OWNER DECISION REQUIRED.` Three sections of this document are conditional on it, so it is stated
here rather than left implicit.

| Mode | Consequence |
| --- | --- |
| **Embedded library in a custom process** (assumed throughout this document) | Checkpointer is constructed and configured by the caller; no store exists unless one is built; Redis is optional. |
| **Packaged Agent/LangGraph Server** | The server provisions persistence infrastructure automatically — including a base store — so the Store ruling below becomes opt-*out* rather than absent, Redis may become mandatory, and the caller-supplied connection parameters may no longer be caller-supplied. |

This document assumes the embedded-library mode, consistent with the fleet's bare-metal venv model.
**If the Server mode is chosen, the Store decision, the Redis classification and the checkpointer
configuration section must all be re-derived**, and the Store decision requires `mem0` agreement.

## Architecture

### Orchestration primitives

Current LangGraph builds a graph from nodes and edges over a typed state object, compiles it,
and executes it with a checkpointer attached. State is a schema with reducers — the message
channel appends rather than overwrites. That much is stable across the version change and is
the part of the 2025 design (`lgc-279`, `lgc-289`) that carries forward.

### State schema

The state object carries the run: message history, the classification of the work in hand, the
active step, accumulated results, and iteration count.

Three 2025 decisions are worth keeping deliberately.

**An explicit schema version field** (`lgc-279` FR-009, adopted from a review conflict recorded
in `lgc-293`), so that state written by one version of the graph can be recognised — and
rejected or migrated — by another. Checkpointed state outlives the code that wrote it. Without a
version marker, a schema change silently corrupts resumption of in-flight threads.

**Ephemeral and persistent state are separated within the schema** (`lgc-289`). Per-turn working
values and values that must survive a checkpoint are distinguished deliberately rather than
allowed to accumulate together. This is what stops a state object growing without bound and
becoming a de facto memory store — the same boundary defended elsewhere in this document,
enforced here at the schema level.

**Termination is explicit, not implicit** (`lgc-289`). A run carries both a termination flag and
a stated reason, alongside a bounded iteration count. "Stopped because the iteration cap was
reached" and "stopped because the work is complete" are different outcomes, and a graph that
cannot distinguish them cannot be operated.

Interrupts are likewise structured rather than boolean (`lgc-289`): an interrupt names its kind
— approval, edit, input, review — and carries a timeout and a default action. An
interrupt without a default is a run that blocks forever on an absent human.

`VERIFICATION REQUIRED` — the exact state-schema construction and reducer API against the
pinned release.

---

## Orchestration topology

`VERIFICATION REQUIRED — this is the open design decision, not a settled one.`

The 2025 design specified a supervisor-and-workers arrangement built on a dedicated supervisor
package (`lgc-279` FR-001/FR-002, `lgc-289`). **That package is not the current recommended
path.** Current upstream guidance builds agents with an agent constructor and composes them by
wrapping subagents as tools, with the outer agent delegating through tool calls. The
constructor lives in the LangChain agents package and produces a LangGraph graph internally —
so the packaging boundary itself has moved, not just the API.

Candidate shapes, to be decided on evidence rather than inherited:

| Shape | When it fits | Consequence |
| --- | --- | --- |
| Custom `StateGraph` | Control flow is the product; explicit conditional routing | Most control, most code |
| Agent constructor + tool-wrapped subagents | Delegation to specialists by capability | Current upstream default; subagent persistence must be chosen explicitly |
| Router / handoff | Classification then single-owner execution | Simple; weak for iteration |
| Orchestrator-worker fan-out | Parallel independent subtasks | Strongest for breadth; hardest to make resumable |

Subagent persistence is a real decision inside the tool-wrapped shape, not a detail. Per-invocation
persistence — the upstream default — starts each subagent call fresh while still inheriting the
parent's checkpointer for interrupts within that call. Per-thread persistence gives a subagent
its own durable thread and changes what "resume" means. Choosing the second without intending
it creates durable state nobody owns.

**HX constraint on all four shapes.** The specialists are governed capabilities with their own
contracts. Whichever topology is chosen, it is a mechanism for sequencing them. It does not
become a new authority over them, and a subagent is not a substitute for a capability contract.

---

## Specialist execution

HX specialists remain governed capabilities. Orchestration invokes them; it does not redefine
them, extend their scope, or acquire the right to speak for them. Where a specialist has a
contract under `.claude/agents/`, that contract is authoritative for what the specialist may
decide — and an orchestration node wrapping that specialist inherits none of that authority.

---

## State and checkpointing

Checkpoints persist to PostgreSQL on the state-services host. This is the most concrete
inheritance from 2025, because the database work was actually executed and its state captured
(`lgc-276`, `lgc-277`, `lgc-474`).

### Durable shape

| Element | Value | Source |
| --- | --- | --- |
| Dedicated database | one, owned by the service | `lgc-276` |
| Dedicated schema | `langgraph`, with the role's `search_path` set to it | `lgc-276`, `lgc-277` |
| Checkpoint tables | `checkpoints`, `checkpoint_blobs`, `checkpoint_writes`, `checkpoint_migrations` | `lgc-277` |
| Table creation | by the checkpointer's own setup step, not by hand | `lgc-277` |
| Role privileges | no superuser, no createdb, no replication, no RLS bypass | `lgc-277` |
| Connection limits | bounded per role and per database | `lgc-276` |
| Authentication | SCRAM-SHA-256 | `lgc-298` |

The schema was deliberately empty before the checkpointer initialised it (`lgc-276`). That is
the correct order: the library owns its own tables, so its migrations remain valid. The four
table names above are **2025-observed library output**, recorded as what to expect and confirm at
the pinned release — not as a shape this design specifies.

Serialisation: the current fleet architecture specifies strict message-pack serialisation for
LangGraph checkpoints on this host. Adopted here. `VERIFICATION REQUIRED` — that it remains
applicable at the pinned checkpointer release. It bounds what can be written into a checkpoint,
which matters directly to the memory boundary below.

### Lifecycle, growth and recovery

Specifying tables and stopping is not a persistence design. Checkpoint state is the only durable
state this service owns, and it accumulates.

| Concern | Requirement |
| --- | --- |
| Growth | Expected rows and blob volume per run must be estimated before deployment. |
| Retention | A pruning rule for completed threads, and a separate one for abandoned threads. |
| Interrupt reaping | Structured interrupts carry a timeout and a default action, so approval-blocked threads are long-lived **by design**. They must be reaped, or they accumulate indefinitely. |
| Disk budget | A stated budget on hxs-9, chosen against a single 238.5 GB device shared with the gateway database, Redis and platform state. |
| Backup and restore | A named backup target and a **tested restore**. Without one, recovery objectives cannot be answered at all. |

`VERIFICATION REQUIRED` on every row. The backup target is not LangGraph's to define; it is a
dependency on the state-services host owner, recorded here so it is not silently assumed.

**Invariant:** LangGraph holds **no durable state on hxs-11's local disk**. Everything durable
lives on hxs-9. That is what keeps hxs-11 rebuildable without data loss, which is what makes a
single non-redundant device acceptable for the runtime host.

### The connection parameters that cause silent data loss

The single most valuable operational finding in the 2025 corpus (`lgc-298`) — with one addition
the 2025 material missed. The Postgres checkpointer's connection recipe carries **three** settings,
not two:

- **autocommit enabled.** Without it, checkpoint writes are never committed. The service appears
  healthy and loses all thread execution state on restart. It fails silently, in the direction of
  data loss.
- **dict-style row factory.** The checkpointer addresses columns by name. Without it, checkpoint
  save and load raise key errors.
- **prepared-statement threshold disabled.** Absent from the 2025 material entirely, and it is the
  one that connects to the next section: it turns off psycopg's automatic prepared statements,
  which is precisely the mechanism a transaction-mode pooler breaks.

The autocommit failure mode is accurately described above and is the dangerous one, because it is
silent. Whether each parameter is still **caller-supplied** is a different question and is open:
recent checkpointer versions may set the row factory on the cursor rather than requiring it on the
connection, and the convenience constructor may supply all three. No claim is made here that these
survive the version change unexamined.

`VERIFICATION REQUIRED` — the checkpointer package name and import path at the pinned release, and
which of the three parameters remain the caller's responsibility.

All three belong in a validation test, not a runbook — see Validation.

### Connection pooling

`VERIFICATION REQUIRED` — 2025 left this explicitly open (`lgc-293`): whether a transaction-mode
connection pooler is compatible with the checkpointer. It is a real risk, not a formality, and it
is **the same mechanism as the third connection parameter above**: transaction-mode poolers break
prepared statements and session state. That is why the threshold is disabled in the recommended
recipe, and why the two questions are one question. Role-level `search_path` is also not reliably
applied through a transaction-mode pooler, which would break the dedicated-schema arrangement.
Resolve before introducing a pooler, not after.

---

## LangGraph Store vs Mem0 — explicit boundary

**Decision: the LangGraph `Store` is not used in HX.**

Stated as a runtime fact rather than as a default, because "default" is the wrong frame and is
factually wrong on one of the two paths:

- No `BaseStore` is constructed, and none is passed at graph compilation.
- No store key appears anywhere in runtime configuration.
- **HX does not run the LangGraph Server / Platform runtime.** On the library path a store is
  opt-*in*; on the Server path a base store is provisioned automatically and would be opt-*out*.
  Saying "disabled by default" would be untrue there. HX runs a custom process in a virtual
  environment under systemd — not the packaged API server — and that is what makes the statement
  above true rather than aspirational.

Current LangGraph provides two persistence systems, and the distinction matters:

| System | Scope | Purpose |
| --- | --- | --- |
| Checkpointer | one thread | Thread execution state; resumability, time travel, fault tolerance |
| Store | across threads | Durable application data: user preferences, accumulated facts, shared knowledge |

"Short-term" is deliberately not used for the checkpointer. Upstream pairs "short-term memory"
with "long-term memory", and adopting half of that vocabulary concedes the very thing this
section denies — that checkpoints are memory, only shorter. They are not memory at all. They are
thread execution state, and as recorded below they currently have **no retention policy**, so
nothing about them is short.

The Store is cross-thread durable memory with semantic search over it. That is Mem0's job
description. If both existed, HX would have two durable memory authorities with no rule for
which one holds the truth — and the second one would have arrived by default rather than by
decision.

The available options were (A) Store unused, (B) Store confined to orchestration-owned
application metadata, (C) a deliberately non-overlapping role. **HX takes A.** Orchestration-owned
metadata that genuinely needs to outlive a thread is rare enough to be handled explicitly when a
case appears, and option B's boundary — "only metadata" — is the kind that erodes quietly.

Consequences, stated so they are not discovered later:

- Adopting the Store later is a design change requiring the `mem0` capability's agreement. It is
  not reachable by editing configuration, and it is not reachable by choosing an orchestration
  topology that happens to require the Server runtime — that choice reopens this decision and
  carries the same agreement gate. See verification items 1 and 2.
- Cross-thread durable data goes to Mem0 through its interface.
- Checkpoint state is **not** memory. It is thread execution state with a different lifetime and
  a different owner, and it must not be mined as a memory substitute — including as a fallback
  when memory is unavailable. See Failure handling.
- Adopting the Store would also introduce **a second embedding client and a second vector index**
  outside the frozen Qdrant collection design. That breaches this document's own rule that
  embedding requests route through retrieval, and collides with the first-ingest freeze recorded
  under Memory. The Store is not merely redundant with Mem0; it is incompatible with the
  embedding boundary.
- Store-backed *tools* are covered by this ruling too. A memory tool that reaches a store through
  the tool surface bypasses graph compilation entirely, so the MCP tool surface excludes durable
  memory tools other than Mem0's.

### Enforcement

A ruling with no mechanism is a preference. This one is enforced in three places, and each is
falsifiable:

| Where | Assertion |
| --- | --- |
| Startup | The service **refuses to start** if a store is configured or injected. |
| Database | No `store`, `store_vectors` or `store_migrations` table exists in the `langgraph` schema. |
| Tool surface | No store-backed memory tool is admitted. |

The database assertion matters more than it looks. This document elsewhere instructs that the
checkpoint library creates its own tables via its setup step — and the store's setup step is the
identical idiom against the same schema. Without an explicit negative assertion, someone runs it,
the boundary is crossed, and every other check in this document still passes.

---

## Memory

`SME REVIEW REQUIRED` — this section and the Store boundary above await a recorded `mem0` review.

Mem0 is co-located on hxs-11 in a separate virtual environment. Its storage boundaries are set
by the current fleet architecture, not by this document:

- Its own **Qdrant** collection on **hxs-4**, distinct from the retrieval collections.
- History kept in **SQLite on a durable path**.
- Graph intelligence belongs to the retrieval capability — but see the caveat below.

Co-location is not proximity of storage: Mem0's durable store is cross-host and lives on the same
Qdrant instance as retrieval's, which is exactly why the collection boundary is the thing that
separates them.

### First-ingest freeze gate — a precondition on the first memory write

The current architecture makes embedding model, embedding dimension and **Qdrant collection
design immutable after first ingest**, and warns that a dimension mismatch corrupts the store.
The final embedding model and dimension are recorded as still open.

Therefore: **no memory may be written until those are frozen and round-trip validated.** A design
in which orchestration submits memories is a design that triggers first ingest into a
frozen-forever collection. This precondition is not optional and does not belong to LangGraph to
waive.

### Write authority — Mem0 decides what becomes a memory

LangGraph's relationship to Mem0 is that of a caller, and the direction of authority on the write
path matters as much as on the read path:

- Orchestration submits **raw material** — turns, observations, outcomes.
- **Mem0 decides** what becomes a memory, what updates an existing one, what is redundant and
  what expires.
- Orchestration does **not** pre-form, deduplicate, consolidate or expire memory records.

If orchestration submitted finished records, Mem0 would degrade to a passive store and the memory
lifecycle would migrate into graph code — absorption by the shape of the write path rather than
by the Store. That is the same boundary failure in a less obvious place.

### Memory must not accumulate in checkpoints

"Not cached in graph state beyond the run" is too weak to be enforceable, because checkpoints
outlive the run by design and the message channel appends rather than overwrites. Retrieved
memory placed into a checkpointed channel becomes a durable second copy of memory with no owner,
no update path and no expiry, addressable by thread.

The enforceable rule: **retrieved memory is used in the model call and is not persisted into any
checkpointed append-only channel.** Where a channel must carry it, it is ephemeral by
construction. This is also why the checkpoint retention policy above is a memory concern and not
only a disk concern.

### Verification

- `VERIFICATION REQUIRED` — the Mem0 interface LangGraph consumes, on both the **read and write**
  paths, and whether retrieval happens in a dedicated node or inside the model-call step.
- `VERIFICATION REQUIRED` — **graph memory.** The architecture states Mem0 does not use graph
  memory because it was removed from the open-source line. Current upstream indicates the external
  graph store was removed and *replaced* by built-in entity linking that writes a parallel
  entities collection. If that holds at the pinned release, then "no Mem0 graph memory" is not
  achievable by omitting configuration, Mem0's footprint is two collections rather than one, and
  Mem0 performs entity extraction — which this document's own ownership table assigns exclusively
  to retrieval. That overlap is unresolved. Owner: `mem0`, with `lightrag` as stakeholder.
- `VERIFICATION REQUIRED` — which Mem0 distribution HX runs, embedded library or self-hosted
  server. It changes the interface and the storage footprint.
- `VERIFICATION REQUIRED` — where Mem0's own extraction and embedding calls are routed. hxs-11 has
  **no accelerator**, so every memory write costs a remote model call plus an embedding. Those
  must route through the gateway and the embedding plane like any other, not bind directly.

The 2025 material contains no Mem0 topology — Mem0 was not part of that design. Its value here
is negative evidence: an orchestrator was specified that persisted conversation state and session
cache without ever naming a durable-memory owner (`lgc-291`). That gap is what the boundary above
closes.

The 2025 material contains no Mem0 topology — Mem0 was not part of that design. Its value here
is negative evidence: an orchestrator was specified that persisted conversation state and session
cache without ever naming a durable-memory owner. That gap is what the boundary above closes.

---

## Integration contracts

Classified before any contract is written. Only CURRENT REQUIRED integrations get one.

| Integration | Classification | Basis |
| --- | --- | --- |
| Model traffic plane (hxs-8) | **BLOCKED / PENDING OMNIROUTE RECONCILIATION** | An orchestrator must call models, so the *boundary* is required. The named component is not settled: the registry records LiteLLM, OmniRoute supersedes it in target state. No contract is built for either — see owner decision 2. |
| PostgreSQL checkpointer (hxs-9) | **CURRENT REQUIRED** | Orchestration state persistence; registry assigns LangGraph checkpoints to hxs-9. |
| Mem0 (hxs-11) | **CURRENT REQUIRED (domain)** | Durable memory owner; co-located; own SME. |
| LightRAG (hxs-3) | **CURRENT PIPELINE REQUIRED — contract not established** | Retrieval is reached through the pipeline; no direct service contract is asserted here. |
| MCP tool plane (hxs-7) | **CLASSIFICATION UNDER REVIEW — owner decision 4** | The registry assigns an MCP runtime to hxs-7; that is an approved workload, not a running service. Classified CURRENT REQUIRED in the first revision, which makes an MCP-plane SME contract mandatory — possibly a manufactured blocker against HX's deferred MCP posture. Candidate downgrade to LATER / DEFERRED. Shape remains `VERIFICATION REQUIRED` either way. |
| Redis (hxs-9) | **INDIRECT — VERIFICATION REQUIRED** | See below. |
| n8n (hxs-13) | **NO ORCHESTRATION CONTRACT** | n8n *is* a current registry assignment — hxs-13, Automation. What is retired is the 2025 arrangement in which LangGraph exposed endpoints and webhooks for it (`lgc-262`). No contract in either direction is asserted here. |
| Crawl4AI (hxs-6) | **NO ORCHESTRATION CONTRACT** | Also a current assignment — hxs-6, Ingestion — crawling. If it is reached at all it is as a tool on the MCP plane, not as a LangGraph integration (`lgc-262`). |
| Direct model hosts | **RETIRED as a LangGraph concern** | Superseded by the gateway boundary. |

### Model gateway

LangGraph requests a **capability**, not a host and not a model name. Routing, endpoint identity,
capability metadata and fallback policy belong to the gateway.

The division of responsibility:

```
The model-routing plane OWNS:
  endpoint identity · model capability metadata · the VERIFIED context envelope ·
  routing and fallback policy · ideally fail-closed overflow enforcement

LangGraph OWNS:
  computing the request it is about to send · honouring the verified envelope the routing
  plane supplies · refusing, compacting or splitting work before it exceeds that envelope ·
  treating a missing or unverified limit as UNSAFE, never as "probably large"
```

**Why this is a hard rule and not a preference.** HX has a measured case of an inference endpoint
that does not fail safely when a prompt exceeds its window: it silently discards the excess and
answers confidently from what remains, producing a wrong answer indistinguishable from a right
one. The governing record is `governance/policy/runtime-acceptance-decisions.md`. An orchestrator
that trusts a provider-advertised context length will eventually send an over-budget request into
exactly that behaviour.

Accepted inference capability, cited from the governed policy rather than from a commissioning
report:

```
Qwen3.5-9B / hxs-4
  Authority : governance/policy/runtime-acceptance-decisions.md
  Status    : ACCEPTED for bounded local utility inference
  Intended client : LangGraph
  Constraints : client bounds prompt below the verified 65,536 envelope · thinking
    disabled unless deliberately required · endpoint loopback-only · OLLAMA_VULKAN=0 kept
  Exclusion : NOT ACCEPTED as a Claude Code backend
```

LangGraph consumes that acceptance. It does not make it, extend it, or re-derive the envelope.
Per-endpoint limits live in the routing/capability contract, never hardcoded in graph logic.
`VERIFICATION REQUIRED` — the gateway's capability-metadata contract, and whether it can enforce
overflow fail-closed on LangGraph's behalf or only advertise the limit.

**BLOCKED — that acceptance is not network-consumable, and this design does not work around it.**

Recorded formally under principle P-B. `runtime-acceptance-decisions.md` now carries two distinct
acceptance states, and Qwen3.5-9B / hxs-4 holds only the first:

| State | Qwen3.5-9B / hxs-4 |
| --- | --- |
| `accepted-local-runtime` | **GRANTED** — loopback on hxs-4, local commissioning and utility use |
| `accepted-network-consumable` | **NOT GRANTED / OPEN** — pending owner decision 1 |

LangGraph runs on hxs-11; its model path runs through the traffic plane on hxs-8. Neither can reach
a loopback socket on hxs-4. So the only inference capability HX has formally accepted is not
consumable by the client it names as intended, and **LangGraph currently has no reachable accepted
model capability.** This is the top downstream blocker; nothing else in the model path is
implementable until it clears.

Recorded, not resolved. The candidate paths are set out in the owner decision packet and **none is
chosen here**. Granting the second state will require its own verification — the access path
measured as configured — because the existing grant was measured against a loopback-bound service
with no authentication and does not carry.

A design that quietly assumed reachability would have failed at first contact and been diagnosed as
a network fault. See `iss-017`.

The 2025 design anticipated this in primitive form: it required validating that a model's context
size met a minimum before use (`lgc-279` FR-013, `lgc-392`). The instinct was right; what was
missing was a verified source for the number and a defined behaviour when the budget is exceeded.

### PostgreSQL

Covered under State and checkpointing. The database is reached as a service on hxs-9; the DSN is
composed from configuration, never written into code or committed. Credentials are referenced by
mechanism, never by value.

### LightRAG

Retrieval is LightRAG's. LangGraph sequences its use — deciding when to retrieve, whether the
result is sufficient, and whether to iterate — and consumes the result.

Two 2025 decisions are durable and worth restating, both from `lgc-393` and `lgc-281`:

- **Retrieval is consumed over its service interface, not embedded.** The rationale then was to
  avoid duplicating storage backends and to leave one owner for the vector store. That rationale
  is stronger now, not weaker.
- **Embedding requests route through retrieval**, never direct to a model host (`lgc-279` FR-012).
  This is the boundary that stops an orchestrator quietly acquiring an embedding plane.

Adaptive retrieval — iterating when the first result is insufficient — is orchestration's
contribution and remains in scope. Query-mode selection is retrieval's vocabulary; LangGraph
passes intent rather than tuning modes on retrieval's behalf.

No direct service contract is asserted. Establishing one is `lightrag`'s call with `langgraph` as
stakeholder.

### MCP tool plane

LangGraph is an MCP **client**. It does not register servers, does not own gateway policy, and
does not become a second control plane (`lgc-279` FR-017, `lgc-285`).

`VERIFICATION REQUIRED` on all of: the current client adapter package and release; transport;
tool discovery; the allowed tool surface; namespace handling for tools reached through a gateway;
and failure semantics when a tool or the gateway is unavailable.

Two cautions carry from the Docling pass and from 2025. First, the client must not depend on
server-implementation specifics of whatever framework backs the gateway — the 2025 design bound
itself to a named gateway framework, and framework identity has already moved once in this
repository. Second, 2025 built protocol version detection with fallback (`lgc-279` FR-020a);
that instinct is sound, but the specific versions it negotiated are long superseded and must not
be carried forward as current.

### Redis

The registry places Redis on hxs-9 alongside PostgreSQL, serving state services including the
gateway's own needs. The 2025 design used it for session cache, model-response cache and rate
limiting (`lgc-291`).

**Those three uses have moved.** Response caching and rate limiting are model-routing concerns
and belong to the gateway. What remains for orchestration is ephemeral coordination, and whether
LangGraph needs any is unproven — orchestration state is durable and belongs in checkpoints.

The 2025 design went further than caching, and this is the part not to repeat. Alongside caches
and TTLs it placed a **checkpoint write lock** in the same ephemeral store, keyed per thread with
a short expiry (`lgc-291`). That makes checkpoint serialisation — a correctness property —
dependent on a cache that is allowed to evict, expire and be flushed. If the lock expires early,
two writers proceed; if the store is cleared, the guarantee vanishes silently. Checkpoint
concurrency is the checkpointer's problem and belongs in the database that holds the checkpoints.

`VERIFICATION REQUIRED` — whether LangGraph requires Redis at all. Until answered, it is INDIRECT.
Two invariants do not need verification: **durable graph state never lives in Redis**, and **no
correctness property may depend on it**. If a cache is introduced, it is ephemeral by
construction, and losing it costs latency, never correctness.

### The Docling → LightRAG handoff

An open question from the Docling pass asked whether orchestration should own the handoff from
parsing to retrieval. Investigated here, not assumed.

**Finding: LangGraph is a legitimate candidate to *sequence* that handoff, and is not a candidate
to *own* it.** Sequencing — deciding that a parsed document should now be indexed, and invoking
that — is orchestration. The contract itself — what is passed, in what shape, which side
initiates, who owns failure — is a matter between the parsing and retrieval capabilities.

If orchestration owned that contract, the handoff would silently acquire a dependency on the
orchestrator being running and healthy for ingestion to work at all. That is a worse coupling
than the one it would solve. Returned to the Docling open item as a bounded answer rather than a
decision: orchestration can drive it; the contract stays with `docling-mcp` and `lightrag`.

---

## Runtime and service model

- Bare-metal Python virtual environment under systemd. No containers. Consistent with the fleet
  philosophy and with 2025 (`lgc-262`, `lgc-296`).
- One virtual environment per service even when co-located — LangGraph and Mem0 do not share one.
- The service unit represents the LangGraph workload, never the host's role.
- Removable without host rebuild.

`VERIFICATION REQUIRED` — Python version floor at the pinned release; process model and worker
count; resource envelope on the actual host. The 2025 figures (`lgc-296`) were sized for a
different machine, a different model backend and a different orchestration library, and are not
carried forward.

---

## Configuration model

- No hardcoded endpoints, addresses, ports or paths. Every current fact resolves from
  `SERVER-REGISTRY.md` and current infra contracts at configuration time.
- No credential values in the repository, in configuration examples, or in this document.
  Credentials are referenced by mechanism only. The 2025 credential-management mechanism is
  retired and is not reintroduced.
- Model selection is expressed as a capability requirement, never as a model name bound in code.
- Context limits come from the routing plane's capability metadata, never from a constant.
- Configuration is validated at startup; the service refuses to start on an incoherent
  configuration rather than failing later under load.

---

## Validation requirements

Re-baselined. The 2025 suite counted 78 cases across deployment, functionality, integration,
end-to-end and health-check categories (`lgc-395`, `lgc-394`, `lgc-288`). **No count is carried
forward** — the old total measured a different design. What carries is the coverage *intent*,
and it is worth carrying because the categories were well chosen.

Required coverage, by what must be proven rather than by how many tests prove it:

| Area | Must prove |
| --- | --- |
| Checkpoint durability | State survives a **SIGKILL** mid-run, recovered by a new process. A graceful restart is explicitly **not** sufficient: a clean context-manager exit can commit the very transaction whose absence the test exists to prove, so the gate would pass on a service that loses everything on crash. The connection lifecycle under test must be named. |
| Checkpoint connection settings | See the construction below. Naming the requirement is not enough — the two obvious constructions both pass while the system is broken. |
| State schema versioning | A state written under one schema version is detected, not silently misread. |
| Control flow | Routing, handoff, and iteration limits behave as specified. |
| Interrupt and resume | A run pauses for approval and resumes correctly. |
| Envelope enforcement | An over-budget request is refused, compacted or split **before** dispatch — never sent. |
| Missing envelope | An unverified or absent context limit is treated as unsafe, not as permissive. |
| Boundary enforcement | The Store is not in use; durable memory calls go to Mem0. |
| Embedding boundary | Embedding requests reach retrieval, never a model host directly. |
| Integration liveness | Each CURRENT REQUIRED integration: connect, round-trip, and degrade. |
| Failure behaviour | Retry, circuit-breaking and graceful degradation act as designed. |
| Health surface | Health, readiness and dependency status distinguish "up" from "usable". |

Every gate must be failable, and proven so at least once. A test that cannot fail is not a gate.

### The silent-data-loss gate, specified

This is the flagship gate and it is the easiest one in the document to build wrong. Both
constructions an implementer reaches for first **pass while the system is broken**:

- *Config echo* — asserting the connection object reports autocommit enabled. That asserts the
  line of code that set it. It cannot see a pool, a second code path, or a caller that builds its
  own connection.
- *Same-session round-trip* — writing a checkpoint and reading it back on the same connection.
  With autocommit off, the session reads its own uncommitted rows. Green test, doomed data.

Required construction:

1. Build the checkpointer through the **same factory the service uses**.
2. Run work that produces rows in both the checkpoint and pending-write tables — an interrupted or
   multi-node run, not a single node.
3. Read back over an **independent connection opened by the test process**, and again through a
   freshly constructed checkpointer. Same-session read-back is prohibited.
4. Prove failability by **fault injection**: rebuild the checkpointer with autocommit disabled,
   re-run, and assert the gate goes **red**. That red run is the retained artefact.

The 2025 corpus already contained the right method and this design initially missed it: an
integration case (`lgc-456`) read back through an independent database session rather than the
writing one. The defect was cited from `lgc-298`; the method should have been cited from `lgc-456`.

Apply step 4 to the row factory **only if** the pinned release still requires it from the caller.
If the library sets it internally, that half of the gate cannot be made to fail and must be
deleted rather than kept as a permanent green tick.

**Acceptance standard for every gate** — the frozen sibling design's rule, adopted here: a gate is
accepted only when a **recorded failing run** of it is retained alongside it, with command,
branch, working-tree state, counts and timestamp. Fail-first-on-absence is not a substitute: a
test that goes red only because the service does not exist yet does not discriminate a behaviour
assertion from a liveness check.

**The 2025 discipline worth reinstating** (`lgc-395`): tests are written *before*
deployment, and are required to **fail first** — against a service that does not yet exist —
before the deployment is performed and they are required to pass. That ordering is what proves
a test is wired to the thing it claims to measure. It is the same principle the migration
pattern states as "a gate that cannot fail is not a gate", arrived at independently, and it is
the strongest single practice in the historical corpus.

Note what 2025 put out of scope: production load testing, on the grounds of a development
environment, and security *penetration* testing. Neither exclusion is inherited; scope is set by
current authority, not by a 2025 phase boundary.

**And note what the inherited structure is worth.** At the archive commit, all 78 cases are marked
manual and **not run** — 0 executed, 0 passed, 0 failed. The category structure is therefore
borrowed shape, never proven practice, and the 2025 quality sign-off that praised it (`lgc-288`)
is historical evidence rather than current approval. Reusing the shape is reasonable; treating it
as validated would not be.

---

## Failure handling

- Retry with backoff on transient dependency failures; circuit-breaking to stop a failing
  dependency cascading (`lgc-279`).
- Graceful degradation with a stated order: which capabilities are shed first, and which failures
  are fatal to a run rather than degradable.
- In-flight work is checkpointed, so a restart resumes rather than restarts.
- Human-in-the-loop interrupts are a first-class path, not an error path.
- **Refusal is a valid outcome.** An over-budget or unverifiable request is refused before
  dispatch. Sending it and hoping is the failure mode the model-routing boundary exists to
  prevent.

`VERIFICATION REQUIRED` — recovery objectives against the current host and dependencies. The 2025
targets (`lgc-279`) were set for a different topology.

---

## Operational checks

- Service liveness and readiness, distinguished: running is not the same as able to serve.
- Dependency status for each CURRENT REQUIRED integration, reported individually.
- Checkpoint write/read verification against the live database.
- Confirmation that checkpoint tables exist in the dedicated schema and were created by the
  library's own setup.
- Structured logging with rotation; log location owned by `infrastructure-ops`.
- Graceful shutdown that completes or checkpoints in-flight runs.

---

## Known gotchas and legacy lessons

Mined from the 2025 tasks and tests (`lgc-298`–`lgc-473`), reduced to what is still true.

1. **The checkpointer's two connection parameters cause silent data loss when wrong** (`lgc-298`).
   Nothing errors; state simply never persists. Assert them in a test.
2. **Let the checkpoint library create its own tables** (`lgc-277`). Hand-built tables diverge
   from the library's migrations.
3. **Give the orchestrator its own database, schema and least-privileged role** (`lgc-276`,
   `lgc-277`). Bound connection limits per role and per database.
4. **A named orchestration package is not the pattern.** The 2025 design bound itself to a
   supervisor package that is now superseded (`lgc-289`). Bind to the shape, keep the package
   replaceable.
5. **State schema versioning is not optional** (`lgc-279`, `lgc-293`). Checkpointed state outlives
   the code that wrote it.
6. **Consume retrieval over its interface; do not embed it** (`lgc-393`). Embedding it duplicates
   storage backends and splits vector ownership.
7. **Route embeddings through retrieval** (`lgc-279` FR-012). The shortcut to a model host is how
   an orchestrator acquires an embedding plane by accident.
8. **Be an MCP client, not a server** (`lgc-279` FR-017, `lgc-285`), and do not depend on the
   gateway framework's server-side specifics.
9. **Version negotiation ages badly** (`lgc-279` FR-020a). The mechanism is sound; the versions
   are not. Never carry a negotiated version forward as current.
10. **The 2025 material contradicts itself on facts that look authoritative.** Two documents give
    different addresses for the same database host (`lgc-278` vs `lgc-474`); two give different
    library versions (`lgc-279` vs `lgc-278`). Resolve from current authority; never translate.
11. **Four questions were left open in 2025 and were never closed** (`lgc-293`): library version,
    model context sizes, protocol version compatibility, and pooler compatibility. Three are
    overtaken by current authority. The pooler question is still open and is carried forward
    above rather than quietly dropped.
12. **A cache that holds correctness is not a cache.** 2025 put session state, response cache and
    rate limiting in one ephemeral store (`lgc-291`). Only latency may depend on it.

---

## Current verification required

Consolidated. Each must be resolved against current authority or current upstream before
implementation; none may be filled in from 2025 values.

| # | Item |
| --- | --- |
| 1 | Orchestration topology — which of the four shapes, on what evidence |
| 2 | Subagent persistence mode, if a tool-wrapped shape is chosen |
| 3 | Pinned release for each independently-versioned package, with date checked |
| 4 | State-schema construction and reducer API at the pinned release |
| 5 | Checkpointer package name, import path, and whether connection parameters are still caller-supplied |
| 6 | Connection-pooler compatibility with the checkpointer — open since 2025 |
| 7 | Mem0 interface consumed, and where memory retrieval occurs in the graph |
| 8 | Gateway capability-metadata contract, and whether it enforces overflow fail-closed |
| 9 | Per-endpoint verified context envelopes |
| 10 | MCP client adapter package, transport, discovery, allowed tool surface, namespace and failure semantics |
| 11 | Whether LangGraph requires Redis at all |
| 12 | Python version floor, process model, and resource envelope on hxs-11 |
| 13 | Recovery objectives against the current topology |
| 14 | Whether a direct LightRAG service contract should be established |

---

## Provenance

Distilled from 213 ledger rows, `lgc-262`–`lgc-474`, `owner_capability: langgraph`, against
`manifest_resolved_sha256` `64eb356f…cd59`, read from `legacy/2025` at commit `a98846d6`.

| Section | Ledger IDs |
| --- | --- |
| Purpose | `lgc-262` |
| Owns / does not own | `lgc-262`, `lgc-279`, `lgc-289` |
| Current placement | `lgc-278`, `lgc-474` (as contradiction evidence) |
| Architecture | `lgc-279`, `lgc-289`, `lgc-293` |
| Orchestration topology | `lgc-279`, `lgc-289` |
| State and checkpointing | `lgc-276`, `lgc-277`, `lgc-298`, `lgc-474`, `lgc-293` |
| Store vs Mem0 | `lgc-279`, `lgc-291` (negative evidence) |
| Memory | `lgc-291` (negative evidence) |
| Model gateway | `lgc-279`, `lgc-287`, `lgc-392` |
| LightRAG | `lgc-279`, `lgc-281`, `lgc-393` |
| MCP tool plane | `lgc-279`, `lgc-285` |
| Redis | `lgc-291` |
| Runtime and service model | `lgc-262`, `lgc-296` |
| Validation requirements | `lgc-288`, `lgc-394`, `lgc-395` |
| Failure handling | `lgc-279` |
| Known gotchas | `lgc-276`–`lgc-279`, `lgc-285`, `lgc-289`, `lgc-291`, `lgc-293`, `lgc-298`, `lgc-393` |

Excluded from content review: `lgc-302`, retired mechanism, referenced by ID only and never
opened.

### Coverage

212 content-eligible rows reviewed; **19 contributed distilled content**; **193 reviewed-not-used**;
**1 blocked**. Total 213. Counted per row from the provenance index, not by pattern.

The ratio is worth stating plainly rather than dressing up. 19 of 212 is a hard filter, and it is
the honest outcome for a corpus that is 96 task files and 80 test files describing the execution of
a design that has since been superseded in its orchestration library, its model backend, its host,
its addresses and its credential mechanism. What survived is invariant knowledge — the checkpointer's
connection requirements, the persistence boundaries, the retrieval and embedding rules, the
validation discipline. The `tasks/` and `tests/` families contributed **structurally** — the work
breakdown and the coverage categories — without any individual file's content reaching the
deliverable, which is why they are recorded as reviewed-not-used rather than used.

Per-row disposition is recorded in `governance/reports/claude/provenance-index.jsonl`, 213 records
bound to `manifest_resolved_sha256` `64eb356f…cd59`, all carrying `migration_status: pending`.

### Review status

Four capability reviews ran against this document in separate contexts on 2026-08-14:
`langgraph` **FAIL**, `mem0` **FAIL**, `infrastructure-ops` **FAIL**, `testing-qa`
**CONDITIONAL PASS**. Their findings are recorded in the pilot report.

This revision incorporates the blocking corrections but has **not been re-reviewed**. Every section
therefore carries `SME REVIEW REQUIRED` until a subsequent review records a passing verdict —
including the sections whose `reviewed_by` entries in the provenance index name a capability, since
those entries record that a review *ran*, not that it passed.

Two integration SME requirements were raised by the first review round. Both are **withdrawn or
deferred** by owner decisions 2 and 4 rather than satisfied:

- **Model traffic plane** — the `litellm` contract requirement is **withdrawn**. LiteLLM is
  superseded by OmniRoute in target state, so building it would formalise a dead component. No
  gateway contract is built for either name. The dependency is OmniRoute reconciliation, not a
  missing contract.
- **MCP tool plane** — the contract requirement is **held** pending owner decision 4, which
  challenges the CURRENT REQUIRED classification against HX's deferred MCP posture. If downgraded
  to LATER / DEFERRED, the requirement lapses.

Neither blocker is now satisfied by construction, so the SME gate is gated on the decisions rather
than on contract-writing.
