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

### `accepted-network-consumable` — NOT GRANTED. Path ruled; grant still pending.

**Not granted.** No client on another host may consume this endpoint today.

**Owner ruling, 2026-08-14 — decision 1, option B.** The endpoint is **not promoted**. Qwen3.5-9B
stays loopback-bound on hxs-4, and **remote consumption is authorized only through the OmniRoute
traffic plane**. This preserves the loopback safety the commissioning deliberately chose — Ollama
has no authentication, so publishing it on the LAN would expose an unauthenticated model *and
tool* endpoint — while routing remote use through the plane that will own model traffic anyway.

Consequences of the ruling:

- **Direct network consumption is refused permanently**, not merely deferred. A client that reaches
  this endpoint by any path other than OmniRoute is out of policy regardless of how it gets there.
- The grant of `accepted-network-consumable` is **conditional on OmniRoute existing** and on its
  own measurement. It is not granted by this ruling; the ruling fixes *which* path may be measured.
- Widening beyond OmniRoute would re-open the acceptance and require new measurement.

**Open mechanism question — not a challenge to the ruling.** OmniRoute is placed on hxs-8, and a
process on hxs-8 cannot reach a loopback socket on hxs-4 any more than LangGraph can. So the ruling
settles the *policy* — only OmniRoute may consume remotely — while the *mechanism* by which
OmniRoute fronts a loopback-bound endpoint on a different host remains to be defined and measured.
Candidates include co-locating a plane component on hxs-4 or an explicit forwarding path. That
definition, and its measurement, are prerequisites to granting this state.

Until then this remains the live blocker for LangGraph (`iss-017`), which is placed on hxs-11.

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
