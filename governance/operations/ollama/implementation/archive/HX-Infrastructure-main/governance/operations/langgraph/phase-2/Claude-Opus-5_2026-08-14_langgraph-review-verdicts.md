# LangGraph design — capability review verdicts

**Date:** 2026-08-14
**Subject:** `services/langgraph/service.md`
**Branch:** `migration/langgraph-pilot` @ `a7961a0`
**Design status:** REVISED / NOT ACCEPTED — PARKED. Pilot complete.
**Decision 3:** FINAL — PACKAGED SERVER (owner ruling, not to be re-litigated)

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

## Decision 3 — FINAL: packaged server

Two reviewers (`langgraph`, `infrastructure-ops`) independently established from pinned source what
the packaged-server mode entails. **The owner ruling stands.** Those findings are therefore recorded
as accepted deployment prerequisites, not as objections:

- **Container runtime required.** Every evidenced production path is a container artefact —
  `langgraph build` produces a Docker image, `langgraph up` launches in Docker, base image
  `langchain/langgraph-server`, generated compose file. The only pip-installable server is the
  in-memory development runtime. Neither hxs-11 nor hxs-9 has a container runtime installed, so
  provisioning one is part of the deployment.
- **`LANGGRAPH_CLOUD_LICENSE_KEY` required** for production use, per the CLI's own output.
  Referenced by mechanism only.
- **Closed-source runtime.** Upstream's threat model places the server runtime out of scope as
  closed-source, so it cannot be source-verified to the standard applied elsewhere in this
  programme. Accepted as a property of the chosen mode.

## Conditions the mode carries

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

**Source verification correction — the adopted serialisation control is observable but may change
blocked values.** In the reviewed LangGraph 1.2.11 source, `LANGGRAPH_STRICT_MSGPACK=true` selects
the built-in safe-type list. An unregistered constructor emits a `msgpack_blocked` event and a
warning, then returns its decoded argument payload instead of reconstructing the type; `None` is
returned only when the guarded decode or construction path catches an exception. The safe list
explicitly includes `langgraph.types.Interrupt` and `langgraph.types.StateSnapshot`. The earlier
claim that this behavior is silent and that structured interrupts are absent from the safe list was
incorrect. Any HX-specific custom state type still requires an explicit identity check and a
round-trip test before deployment.

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

**Pilot complete. Design parked, not abandoned.**

The pilot's purpose was to validate the migration method against a harder subject than Docling — a
stateful orchestrator with six live integration boundaries. It did, under real adversarial pressure:
five independent reviewers, unanimous FAIL, every one of them finding something the authoring
context could not see. That is the method working, and it is the second validation.

The design not reaching acceptance is a separate outcome from the method being proven. Decision 3 is
final. The findings above become the **implementation-correction backlog** (`iss-019`), to be worked
when LangGraph implementation is scheduled. They are not re-derived and not re-reviewed now.

Related: `act-015`, `act-017`, `iss-017`, `iss-018`, `iss-019`.
