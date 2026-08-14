# hxs-3 workload placement

**Status:** TARGET-STATE placement semantics
**As-built status:** NOT ASSERTED BY THIS DOCUMENT
**Authority:** `SERVER-REGISTRY.md` owns durable host identity and role. This document owns
workload eligibility only.

---

## The rule

```
THE SERVER OWNS CAPACITY.
THE MODEL AND RUNTIME ARE A WORKLOAD.
```

hxs-3 is not a DS4 server. DS4 is one workload that may be selected to run there when it is
chosen and the capacity gate passes.

## hxs-3 durable identity — unchanged

| Field | Value | Source |
| --- | --- | --- |
| Durable role | **Agent intelligence** | `SERVER-REGISTRY.md` |
| Assigned workload | gpt-oss-20b TP=2; LightRAG graph & retrieval | `SERVER-REGISTRY.md` |

**No registry change was made and none is required.** The registry does not assign DS4 to
hxs-3, so there is no incorrect role to correct. The role stays "Agent intelligence".

This document deliberately does **not** restyle hxs-3 as a "flexible development-model compute
host" or an "experimental AI runtime node". Replacing an authoritative durable role with either
phrase is exactly the mistake the placement correction exists to prevent — it would swap one
permanent mislabel for another.

**The EXPERIMENTAL classification belongs to the `ds4-deepseek` workload and profile. It never
attaches to the server.**

## Conceptual model

```
hxs-3                          durable role: Agent intelligence  (registry-owned)
└── GPU capacity
    ├── assigned workload : gpt-oss-20b TP=2; LightRAG graph & retrieval
    ├── candidate workload: ds4-deepseek            EXPERIMENTAL, gate-required
    └── candidate workload: a further approved model/runtime
```

Only a selected workload is active. **Installation presence is not activation.** The host
identity does not change when the workload changes.

## Reconciliation with the approved placement documents

Three points where the current repository disagrees with the placement plan's examples. The
registry wins.

| Placement-plan wording | Current repository | Resolution |
| --- | --- | --- |
| hxs-3 durable intent is "flexible development-model compute host" | Registry role is **Agent intelligence** | Role unchanged. The orchestration guidance forbids replacing an authoritative durable role with that phrase |
| "Qwen Coder" is the alternate hxs-3 workload | Registry assigns **Qwen2.5-Coder-32B AWQ Int4 TP=2 to hxs-2** | No `qwen-coder` workload is defined for hxs-3. Asserting one would contradict the registry. The architecture admits an alternate workload without naming that one |
| hxs-3 has spare GPU capacity for DS4 | Registry already assigns gpt-oss-20b TP=2 **and** LightRAG graph & retrieval to hxs-3 | Coexistence is never assumed. The gate treats the assigned workload as occupying the host |

## Runtime isolation

A workload must be removable without making hxs-3 unusable for another.

- DS4 configuration never overwrites or mutates vLLM/Qwen configuration.
- Environment variables scoped to the runtime profile, never global.
- Model files separated by model identity and quantization.
- Start, stop and status procedures name the selected workload explicitly.
- Ports configurable and documented, never assumed globally.
- Only the selected runtime binds its endpoint, unless concurrent operation has been
  capacity-tested — it has not been.
- Switching workloads must not require rebuilding the host.
- A shared CUDA or toolchain change is validated against every affected workload before it is
  made.

## Filesystem placement — PROPOSED, not current state

No canonical model-runtime storage root exists in HX today. `/srv/hx/` is the **control-plane**
layout and its own design document excludes application workloads and role-specific fleet
services, so it is not the model root.

Proposed shape, to be confirmed against hxs-3 storage design during Phase 3:

```
[HX AI runtime root - PROPOSED]
├── runtimes/     vllm/ , ds4/
├── models/       separated by model identity and quantization
├── profiles/
└── state-or-logs/
```

The evidence-backed candidate location is hxs-3's **1.8 TB SATA SSD, currently unallocated**
(`SERVER-REGISTRY.md`, `servers/hxs-3/discovery.md`) — the root NVMe carries the OS. This is a
proposal. No path is created, and none is asserted as current state.

**Model weights never enter Git.**

## Capacity gate

Every workload passes the gate before any model download or runtime activation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ai-runtime\hx-capacity-gate.ps1 `
    -Workload ds4-deepseek -TargetHost hxs-3
```

It evaluates GPU and VRAM, backend, system RAM, storage, model residency, context and KV
allowance, runtime overhead, and coexistence. It returns PASS, FAIL, or **BLOCKED**, and exits
0, 1 or 3.

"hxs-3 has a large GPU" is not a capacity result.

### Current result for `ds4-deepseek` on hxs-3 — BLOCKED

Run 2026-08-13 against current repository evidence:

| Dimension | Result | Evidence |
| --- | --- | --- |
| GPU / VRAM | PASS | 2× RTX 5060 Ti, 16311 MiB each, **32622 MiB** aggregate |
| Backend | PASS | CUDA 13.0, driver 580.173.02 — as-built, `driver-results.md` |
| **System RAM** | **FAIL** | host has **66 GB**; DS4's documented reference target `ds4f-q2` is **96 GB** |
| Storage | BLOCKED | cannot size without a selected model and quantization |
| Model residency | BLOCKED | no exact model or quantization selected |
| Context / KV | BLOCKED | no target context size, concurrency or KV allowance recorded |
| Runtime overhead | BLOCKED | no measured overhead for this runtime on this host |
| Coexistence | BLOCKED | host already carries an assigned workload; combined residency must be measured |

**Verdict: BLOCKED — insufficient current hardware evidence. No model download or runtime
activation is authorized.**

The System RAM row is the substantive finding: the smallest DS4 model variant documented in
the reviewed snapshot targets 96/128 GB RAM machines, and hxs-3 has 66 GB. That is not a
blocker to be waived — it is evidence that this workload, as documented, does not fit this
host. A smaller supported variant, or a different host, would have to be selected and
re-gated.

Note the as-found/as-built distinction the gate preserves: `discovery.md` records hxs-3 with
nouveau and **no CUDA**, which was true when discovered. `driver-results.md` records the later
authorized driver installation. The gate reads the as-built record and says which one it used.

## Operator sequence

1. Decide which workload should be active on hxs-3.
2. Select the workload profile.
3. Run the capacity gate.
4. **Stop if the gate does not PASS.**
5. Verify runtime prerequisites.
6. Download the model only if approved and the gate passed.
7. Start the selected runtime through its isolated service definition.
8. Run the HX AI Runtime Acceptance contract against that profile.
9. Record evidence.
10. Deactivate before changing workloads, then re-gate.

Switching workloads never requires editing test source.

## Non-goals

No permanent DS4 role for hxs-3. No permanent "experimental AI runtime" role. No block on
hxs-3 hosting another approved model. No DS4 in the registry as host identity. No mixing of
DS4 and vLLM/Qwen configuration trees. No assumption of simultaneous residency. No model
weights downloaded by this document. No replacement of the engine-neutral acceptance contract
with runtime-specific tests.

## Related

- `governance/policy/ai-runtime-acceptance-contract.md` — engine-neutral contract
- `tests/ai-runtime/workloads/` — workload definitions
- `tests/ai-runtime/README.md` — running the gate and the contract tests
- `SERVER-REGISTRY.md` — authoritative durable host identity and role
