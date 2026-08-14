# Runtime Acceptance Decisions

Durable record of what each AI runtime workload is **accepted for** and, just as importantly,
what it is **not accepted for**.

A workload is never simply "accepted". It is accepted for a stated use, on stated evidence,
with stated limits. A verdict recorded here without its evidence is not a verdict.

## Acceptance states

Per principle **P-B** (`governance/policy/migration-method-decision.md`): an acceptance states
exactly what it authorizes and how that was verified, never more. Where an authorization has
materially different scopes, those scopes are **distinct states** — not one verdict left to be
read broadly.

| State | Authorizes | Requires |
| --- | --- | --- |
| `accepted-local-runtime` | Use on the host itself, over loopback, for commissioning and local utility work. | Measurement on that host. |
| `accepted-network-consumable` | Consumption by a client on a **different host**. | A verified access path and an access model, measured as configured. Never inherited from a local-runtime acceptance. |

**A local-runtime acceptance never implies network consumability.** The two were conflated once
already, across two workstreams on the same day, and that conflation is what earned P-B.

Governed by `governance/policy/ai-runtime-acceptance-contract.md`. Machine-enforced by
`tests/ai-runtime/hx-runtime-invariants.tests.ps1`, which fails if a decision below is widened
without new measurement.

---

## qwen35-9b-ollama — hxs-4

| | |
| --- | --- |
| Model | Qwen3.5-9B, Q4_K_M, digest `6488c96fa5fa` |
| Runtime | Ollama 0.32.9 |
| Device | RTX 5060 8151 MiB, `GPU-cc758e31-d23b-3c53-bee6-dae3299a6f11`, isolated by UUID |
| Decided | 2026-08-14, on measurement taken on the host |
| Record | `tests/ai-runtime/workloads/qwen35-9b-ollama.json` |

### `accepted-local-runtime` — GRANTED

Accepted for local inference, API validation and tool-driven work **on hxs-4 itself, over
loopback**, where the calling client controls its own prompt size.

### `accepted-network-consumable` — NOT GRANTED / OPEN

**Not granted.** No client on another host may consume this endpoint under the current
acceptance. The measurement behind the grant above was taken against a loopback-bound service
with no authentication; it does not carry to a networked configuration and must not be read as
if it did.

This is the live blocker for LangGraph, which is placed on hxs-11 and routes through a gateway on
hxs-8 — neither can reach a loopback socket on hxs-4 (`iss-017`).

**Open pending owner decision 1**, per
`governance/operations/langgraph/claude_20260814_0848_langgraphfourdecisions.html`. The candidate
paths are recorded there — promote with an access and auth model, route remote consumption
exclusively through the traffic plane, or drop the dependency for first deployment. **No path is
chosen here.** Whichever is ruled, granting this state requires its own verification: the access
path measured as configured, not inherited from the local grant.

### Scope of the grant below

Everything in the evidence and conditions that follow supports `accepted-local-runtime` only.

Evidence:

- 100% GPU residency to a 16,384-token context; 6,794 MiB of 8,151 MiB.
- Usable to 65,536 with a CPU/GPU split, ~28 tok/s under real generation.
- Structured output 5/5 valid against a strict JSON schema; tool selection 4/4 correct from
  three candidates; full `tool_use` → `tool_result` round-trip.
- Correct retrieval of a fact buried mid-document in a 22,846-token prompt.
- Vision works and costs 12 MiB without breaking full-GPU residency.

Conditions of acceptance:

- **Bound prompts below 65,536 tokens.** See the refusal below for why this is not advisory.
- Disable thinking (`"think": false`, or `"thinking": {"type": "disabled"}` on the Anthropic
  surface). It draws from the same budget as the reply, so a small `max_tokens` returns an
  empty response.
- Service stays on `127.0.0.1:11434`. Ollama has no authentication; reaching it from a
  workstation is an SSH port-forward, not a network binding.
- GPU isolation requires `OLLAMA_VULKAN=0` alongside `CUDA_VISIBLE_DEVICES`. CUDA-only
  isolation does not hold on this host (`iss-013`).

### NOT ACCEPTED — Claude Code backend

**Do not wire Claude Code to this endpoint.** The protocol works, which is precisely what makes
this worth writing down: it will appear to function, and then be wrong.

Evidence:

- Claude Code's baseline system prompt measured **28,440 tokens** before any user request. With
  a normal workstation profile a trivial request reached **69,386**, and a stripped profile
  still reached **73,351** — both past the 65,536 window.
- Claude Code reports `contextWindow: 200000` and has **no mechanism to discover the real
  limit**, so it will keep exceeding it.
- On overflow this runtime does not clamp and does not error. It **silently collapses the
  prompt to 32,770 tokens** and answers confidently from what remains (`iss-015`). A fact
  placed at the start of an 85,000-token prompt was destroyed and the model reported it absent.
- Where the prompt did fit, accuracy was still poor: a four-line file was reported as six lines.

The failure mode is a wrong answer indistinguishable from a right one. That is worse than a
refusal, because nothing signals that the result is unsound.

This also settles the context question for this client: 16,384 is not a slower-but-workable
setting for Claude Code, it is **impossible** — the system prompt alone is nearly twice it.

### What would change the refusal

Both conditions, not either:

1. A context window with genuine headroom above the ~28,440-token baseline. The reserved
   16 GB RTX 5060 Ti in the same host could supply it; the 8 GB card cannot.
2. Prompt overflow that raises an error instead of truncating silently. vLLM does this, and it
   is a good reason to prefer it.

Until both hold, widening this decision requires new measurement, not a judgement call.

### Not applicable

**Docling** does not use this endpoint. Core document conversion is not served by a language
model — it runs computer-vision and parsing models inside the processing library on CPU-only
torch. Only optional picture-description enrichment involves a vision model, and that is a
separate pipeline.

---

## Recording a new decision

State the workload, the device, the date, and the record it derives from. Then state what it is
accepted for **and** what it is refused for, each with the measurements that support it. If a
refusal has no stated evidence, it will be argued away later; if an acceptance has no stated
limits, it will be exceeded.
