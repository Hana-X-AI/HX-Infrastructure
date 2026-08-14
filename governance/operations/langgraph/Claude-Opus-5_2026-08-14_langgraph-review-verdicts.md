# LangGraph design — capability review verdicts

**Date:** 2026-08-14
**Subject:** `services/langgraph/service.md`
**Branch:** `migration/langgraph-pilot` @ `a7961a0`
**Design status:** REVISED / NOT ACCEPTED — parked pending an owner re-rule of decision 3

Five capability reviews ran in genuinely separate contexts against the revision that incorporated
all four owner decisions and the upstream pin. **All five returned FAIL.**

This record exists because review outputs previously lived only in conversation. `testing-qa` was
unable to adjudicate eight of its own prior findings for exactly that reason, and correctly refused
to reconstruct wording it could not evidence. Verdicts and their blocking findings are recorded
here so the next re-review can verify corrections against the original claims.

## Verdicts

| Capability | Verdict | Change | Blocking findings |
| --- | --- | --- | --- |
| `langgraph` | **FAIL** | was FAIL | 6 |
| `mem0` | **FAIL** | was FAIL | 7 |
| `mcp-plane` | **FAIL** | first review | 5 |
| `testing-qa` | **FAIL** | **regressed** from CONDITIONAL PASS | 9 |
| `infrastructure-ops` | **FAIL** | was FAIL | 6 |

## The decisive finding — decision 3 is not implementable as ruled

Found independently by `langgraph` and `infrastructure-ops`, from the pinned source.

Every production path for the packaged server is a **container artefact**: `langgraph build`
("Build a Docker image"), `langgraph up` ("Launch … in Docker"), a generated compose file, base
image `langchain/langgraph-server`. The only pip-installable server is the in-memory development
runtime the ruling explicitly rejects. Production additionally requires
**`LANGGRAPH_CLOUD_LICENSE_KEY`**, and upstream's own threat model places the runtime out of scope
as **closed-source** — so it cannot meet the source-verification standard this programme runs on.

Against that: the design states **"No containers"**; fleet architecture v0.3 mandates an absolute
venv interpreter in `ExecStart`; and discovery records **no container runtime on hxs-11 or hxs-9**.

No non-container, Postgres-backed production distribution is evidenced anywhere in the vendored
source drop. **This cannot be resolved by editing the document.**

## Consequences the ruling dragged in

**The served surface inverts the design's own boundaries.** `disable_mcp`, `disable_store`,
`disable_a2a` and `disable_webhooks` all default to `False` — enabled. So the packaged server
exposes `/mcp` routes making LangGraph an **MCP server**, contradicting its own "client only, does
not register servers" ownership row; and `/store` routes make durable memory network-reachable.
The store route was found independently by `mem0`, `testing-qa` and `infrastructure-ops` via three
different evidence paths.

**Redis is a hard, health-gated dependency** of that mode — `depends_on: {langgraph-redis:
{condition: service_healthy}}` — and is the run-queue substrate, not a cache. The compose
parameterises Postgres but **not** Redis, so a default deployment stands Redis up on hxs-11 while
the registry places it on hxs-9. The design still classified it INDIRECT with a "no correctness
property may depend on it" invariant attached.

**The adopted serialisation control fails silently.** `STRICT_MSGPACK` without an allowlist does not
raise on a blocked type — it returns raw data or `None`. HX's own versioned state schema and
structured interrupts are not on the safe-types list, so enabling it degrades checkpoints silently
on resume: the same failure direction as the autocommit defect the design elevated to its flagship
gate.

## Findings against the design's own method

Recorded plainly because they are the reusable lessons.

- **Prose preferred over source, three times, with the source on disk.** The row-factory claim
  (the shipped code sets it on every cursor, so that half of the flagship gate cannot fail);
  `prepare_threshold` (the library's own constructor sets it); and "present but inert" (the store
  migrations run unconditionally and filtered recency search needs no embedding). All three were
  answerable from the vendored drop the revision cited.
- **The retention mechanism was in the file already being quoted.** `checkpointer.ttl`
  (`default_ttl`, `strategy: delete | keep_latest`, `sweep_interval_minutes`, `sweep_limit`) sits in
  the same `schema.json` quoted for the store, while every retention row was marked
  `VERIFICATION REQUIRED`.
- **An enforcement block was added without removing the one it replaced**, leaving two contradictory
  database assertions, the older of which is red on a compliant system.
- **"Five capability reviews now cover this design"** was claimed while three other lines of the same
  document stated the MCP-plane contract did not exist, and the contract file was untracked.
- **The pin is not reproducible.** Floors verified correct against source, but five of ten rows are
  ranges, `langgraph-cli` — which the entire store resolution rests on — is unpinned, and the
  corroborating drop is untracked with no commit identity or file hashes, in a repository that
  recomputes 213/213 source hashes elsewhere.

## What survived review

Stated so the next pass does not redo it: the pins transcribe correctly against source; `iss-017`
is recorded honestly rather than designed around; the two registry contradictions (n8n / hxs-13,
Crawl4AI / hxs-6) are corrected; the "approved workload, not a running service" discipline holds for
MCP; provenance reconciles exactly at 19 used / 193 reviewed-not-used / 1 blocked across 213 rows,
all bound to `64eb356f…cd59`; the silent-data-loss gate now specifies a construction; and the
ownership boundary, the Docling→LightRAG handoff answer and the envelope-ownership split were all
endorsed.

## Disposition

Design **parked**, not abandoned. Blocked on an owner re-rule of decision 3. The correction list
from all five reviews is largely contingent on that ruling, so applying it now would produce work
against an architecture that may not survive.

Related: `act-015`, `act-017`, `iss-017`, `iss-018`, `iss-019`.
