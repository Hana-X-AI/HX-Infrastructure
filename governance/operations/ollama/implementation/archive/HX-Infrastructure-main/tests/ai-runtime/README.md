# HX AI Runtime Acceptance — usage

Validates a runtime profile against
`governance/policy/ai-runtime-acceptance-contract.md`.

**No model is required to run this.** No model is downloaded, and no host is contacted unless
a profile is given a live endpoint through its environment variable.

## Run it

```powershell
# offline, model-free - the default
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ai-runtime\hx-runtime-acceptance.ps1

# against a named profile
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ai-runtime\hx-runtime-acceptance.ps1 -Profile vllm-qwen
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ai-runtime\hx-runtime-acceptance.ps1 -Profile
```

Exit code is the failure count, so it fails a pipeline correctly.

## What PASS, FAIL and SKIP mean here

| Result | Meaning |
| --- | --- |
| **PASS** | The asserted contract behaviour held. Offline, this is **evidence class A only** |
| **FAIL** | The behaviour did not hold. Exit code is non-zero |
| **SKIP** | The test needs something not present — almost always a live runtime. **A skip is never a pass** |

The runner reports `SKIP — LIVE RUNTIME NOT CONFIGURED` rather than inventing a result.

## What offline mode proves, and what it does not

**Proves — class A, protocol and client conformance:** request serialization, response parsing,
SSE ordering and termination, tool declaration, tool call identity, tool result correlation,
multi-turn coherence, malformed-response handling, server-error surfacing, cancellation
cleanup, recovery after an error, large-payload serialization, profile resolution.

**Does not prove — class B, model behaviour:** reasoning, instruction-following, tool choice,
skill adherence, context recall.

**Does not prove — class C, performance and resource:** latency, throughput, VRAM, cache
behaviour.

The fixtures deliberately return text like `FIXTURE RESPONSE - NOT MODEL OUTPUT`. If a fixture
ever returns something that reads like a plausible model answer, and a test then counts that as
success, the harness has started lying. Don't do that.

## Enabling live tests later

A profile becomes live when its endpoint environment variable is set:

| Profile | Variable | Status |
| --- | --- | --- |
| `offline-fixture` | none | always offline |
| `vllm-qwen` | `HX_VLLM_BASE_URL` | **PRIMARY** — also requires `HX_VLLM_MODEL` |

Model identity comes from `HX_VLLM_MODEL`. Nothing is hardcoded, and no
credential belongs in a profile.

Running a live-status profile with no endpoint still executes the L1 contract tests, because
those validate the HX client rather than the runtime. The runner prints an explicit notice so
a passing L1 run is never mistaken for validation of that runtime.

## Adding a profile

Drop a JSON file in `profiles/`. Required keys: `profile`, `status`, `mode`, `endpoint`,
`api_styles`, `capabilities.declared`, `live`. Adding a profile must not require editing the
contract or the runner.

## Layout

```
tests/ai-runtime/
├── hx-runtime-acceptance.ps1   the runner
├── hx-capacity-gate.ps1        workload capacity gate (see below)
├── profiles/                   offline-fixture, vllm-qwen
├── fixtures/                   17 recorded protocol cases
├── workloads/                  workload placement definitions
└── evidence/                   run output, git-ignored
```

## Evidence

Each run writes `evidence/runtime-acceptance_<profile>_<timestamp>.json` recording mode,
profile, contract version, per-test result with its capability and evidence class, and totals.
Offline runs are labelled `NO MODEL / PROTOCOL-ONLY`, and `metrics` stays empty because nothing
was measured. Evidence is git-ignored — it is run output, not source.

## Capacity gate

Before any model download or runtime activation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ai-runtime\hx-capacity-gate.ps1 -Workload
```

It returns PASS, FAIL, or **BLOCKED** when evidence is insufficient. It reads current
authoritative evidence from `SERVER-REGISTRY.md` and `servers/<host>/`. It never assumes that
two heavy models fit concurrently.

## Provenance

Design inspiration from a reviewed third-party inference-runtime snapshot, MIT licensed.
**No source code from that snapshot was copied into HX.** The adopted ideas —
evidence-class separation, the tool-call fidelity invariant, cold/warm cache distinctions, and
separating fast protocol regression from model-backed quality testing — were independently
implemented here in PowerShell. See the contract's *Provenance* section, which carries the
snapshot's SHA-256 and the licence position in full.
