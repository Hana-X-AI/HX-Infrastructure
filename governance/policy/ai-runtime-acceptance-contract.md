# HX AI Runtime Acceptance Contract

**Status:** TARGET-STATE CONTRACT
**Engine-neutral:** yes — this contract names no runtime, host or model
**As-built status:** NOT ASSERTED BY THIS DOCUMENT

This defines what a local AI runtime must provide for HX, so that HX tests runtimes against a
stated contract rather than defining the platform as "whatever the current runtime happens to
do".

Host placement, model identity and endpoint come from the selected **profile**, never from
this contract.

---

## Why this exists

HX has governance, hooks, skills and specialist agents, and no local model installed. Most of
that is testable today. This contract draws the line between what can be proven without
inference and what genuinely requires a live model, so that neither gets claimed on the
other's evidence.

Design source: the reviewed DwarfStar snapshot, mined for its treatment of an AI runtime
as a protocol, state, tooling and QA surface. See *Provenance* below.

---

## Evidence classes — never substitute one for another

| Class | Proves | Provable offline |
| --- | --- | --- |
| **A · protocol/client conformance** | Wire shape, parsing, framing, correlation, error and cancellation handling | **Yes** |
| **B · model behavioural quality** | Reasoning, instruction-following, tool choice, skill adherence, context recall | **No** |
| **C · runtime performance/resource** | Latency, throughput, VRAM, cache behaviour | **No** |

An offline fixture result is class A only. It is never evidence for B or C. A harness that
emits a plausible-looking answer from a fixture and counts it as model behaviour is producing
exactly the false confidence this contract exists to prevent.

---

## Capability matrix

`REQUIRED` — the primary HX local-agent runtime must provide it.
`OPTIONAL` — desirable, not disqualifying.
`PROFILE-SPECIFIC` — required only where the profile declares the capability.

| ID | Capability | Level | Class | Offline testable |
| --- | --- | --- | --- | --- |
| `RT-01` | Runtime/model identity and discovery | REQUIRED | A | yes (fixture) |
| `RT-02` | Health/readiness signal | REQUIRED | A | yes (fixture) |
| `RT-03` | Base URL / endpoint configuration | REQUIRED | A | yes |
| `RT-04` | Basic chat request/response | REQUIRED | A | yes |
| `RT-05` | Streaming (SSE) event sequencing | REQUIRED | A | yes |
| `RT-06` | Structured tool declaration | REQUIRED | A | yes |
| `RT-07` | Tool call: ID, name, arguments | REQUIRED | A | yes |
| `RT-08` | Tool result correlation and continuation | REQUIRED | A | yes |
| `RT-09` | Multi-turn history coherence | REQUIRED | A | yes |
| `RT-10` | Malformed response handling | REQUIRED | A | yes |
| `RT-11` | Server error handling | REQUIRED | A | yes |
| `RT-12` | Timeout and cancellation cleanup | REQUIRED | A | yes |
| `RT-13` | Recovery — a valid call succeeds after an error or cancel | REQUIRED | A | yes |
| `RT-14` | Long system/context payload serialization | REQUIRED | A | serialization only |
| `RT-15` | Multiple tool calls in one turn | OPTIONAL | A | yes |
| `RT-16` | Reasoning/answer field separation | PROFILE-SPECIFIC | A | yes |
| `RT-17` | Usage/telemetry reporting | OPTIONAL | A | yes (shape only) |
| `RT-18` | Runtime version/commit evidence | OPTIONAL | A | yes (shape only) |
| `RT-19` | Long-context behaviour at configured size | REQUIRED | B | **no** |
| `RT-20` | Instruction and skill adherence | REQUIRED | B | **no** |
| `RT-21` | Correct tool selection | REQUIRED | B | **no** |
| `RT-22` | Context recall across turns | REQUIRED | B | **no** |
| `RT-23` | Cold/warm/resume prefix behaviour | OPTIONAL | C | **no** |
| `RT-24` | Time to first token | OPTIONAL | C | **no** |
| `RT-25` | Prefill and decode throughput, measured separately | OPTIONAL | C | **no** |
| `RT-26` | GPU/VRAM residency evidence | OPTIONAL | C | **no** |

`RT-14` splits deliberately: offline proves the client serializes a large payload correctly;
only a live runtime proves the runtime accepts and uses it.

---

## Test levels

| Level | Model required | Scope |
| --- | --- | --- |
| **L0** repository static | no | Hooks, skills, agent definitions, reference integrity, authority routing. Already covered by the existing suite; not duplicated here |
| **L1** runtime protocol offline | no | This layer. Serialization, parsing, SSE, tool round trip, errors, cancellation, profile resolution, evidence |
| **L2** live runtime smoke | yes | Identity, chat, stream, one tool call, continuation |
| **L3** agent behavioural | yes | Skill selection, tool choice, hook-denial recovery, authority compliance, truth-state separation |
| **L4** quality and performance | yes | Long context, cold/warm prefix, TTFT, throughput, GPU evidence |
| **L5** cross-runtime conformance | two live runtimes | Same contract against two profiles; compare capability and behaviour, never byte-identical text |

L2–L5 are defined now and **SKIP** until a profile declares a live endpoint. A skip is not a
failure and must never be reported as a pass.

---

## The tool round-trip invariant

Mined from
exact sampled representation, using canonical re-rendering only as a fallback, because
re-serializing a tool call can differ from what the model actually emitted and break
continuation and cache identity.

HX states the runtime-neutral invariant:

```
tool call generated
  -> tool id retained
  -> tool name retained
  -> arguments semantically retained
  -> result correlated to the same call id
  -> next turn receives coherent history
```

---

## Profiles

A profile supplies everything this contract deliberately omits: endpoint, model, host, API
style, capability declarations, timeouts, live/offline status.

| Profile | Status | Purpose |
| --- | --- | --- |
| `offline-fixture` | executable now | Model-free deterministic protocol validation |
| `vllm-qwen` | PRIMARY — configuration now, live later | The intended primary HX local model runtime |
| ` live later | Anthropic-compatible and OpenAI-compatible cross-runtime testing, tool fidelity, cache experiments |

**The experimental classification applies to the ` not to any
server.** Adding a further profile must not require editing this contract.

No credentials, no secrets and no live host are hardcoded anywhere in this contract or in the
profiles.

---

## Evidence model

Every run records:

```
timestamp · contract version · mode (OFFLINE|LIVE) · profile
host · base URL (only when safe) · runtime identity/version
model identity · quantization · backend · context setting · device placement
per-test: id, capability, evidence class, PASS|FAIL|SKIP, detail
metrics: present only when actually measured
```

Offline runs are labelled `OFFLINE / NO MODEL` and every class B and C test is `SKIP`. Live
runs record observed values only — a missing telemetry field is recorded as absent, never
inferred.

Machine-readable JSON plus a human-readable summary.

---

## What this contract does not do

- It does not name a host. Placement comes from the selected profile and from
  `SERVER-REGISTRY.md`.
- It does not make performance a universal pass/fail condition.
- It does not treat a runtime-specific optional capability as a failure unless the contract
  marks it REQUIRED.
- It does not replace the primary vLLM/Qwen runtime decision.
- It does not adopt `

---

## Provenance

Design inspiration only — the reviewedzip`, SHA-256
`e4e5a5ad5124436f13f6bb6b0ef91d496c6c2e5cd954e20fef709510a7f43bac`, upstream
`github.com/antirez/ MIT licensed, copyrightc authors and the ggml authors.

**No** The patterns adopted — evidence-class separation,
the tool-call fidelity invariant, cold/warm cache distinctions, and separating fast protocol
regression from model-backed quality testing — were independently implemented in the existing
HX test language. No MIT notice obligation is triggered by idea reuse; had source been copied,
the notice and source path would be recorded here.

Facts asserted about
inference engine targeting not a general GGUF runner; it exposes
`/v1/models`, `/v1/chat/completions`, `/v1/responses`, `/v1/completions` and an
Anthropic-compatible `/v1/messages`; it supports Metal, CUDA and ROCm; the snapshot contained
1,166 files and zero model weights.
