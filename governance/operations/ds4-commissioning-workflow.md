# DS4 commissioning workflow — ABORTED

**Status:** ABORTED / DEFERRED — retained as a record, not an operational procedure
**DS4 status:** DEFERRED / RESEARCH · installed NO · model present NO · service active NO ·
host assignment NONE
**Rolled back:** 2026-08-14

## Why this was aborted

Hardware and runtime fit were discovered **late in commissioning rather than before
implementation**. DS4 is a poor fit for the immediate HX local-model objective, so
operationalization was abandoned before it became operational.

Nothing was installed, downloaded, activated or configured. hxs-3 was never modified and
retains its durable registry role.

**This document is preserved deliberately.** The capacity and commissioning work is what
exposed the mismatch, and erasing it would erase the lesson. The commissioning driver now
refuses to walk any gate for this workload.

## The rule this produced

```
Hardware fit first.
Runtime and model selection second.
Implementation third.
```

The sequence here ran the other way: machinery was built, then a model was selected, then the
hardware was found not to fit. The gate did its job and caught it — but later than it should
have been asked.

---

## Original workflow, retained for reference

Everything below documents what was designed. It is **not** an active procedure.

## Deployment host and execution mode

**hxs-3 was the intended deployment host. That assignment is withdrawn.** Host selection is not part of this decision. When an
execution mode fails, the response is to evaluate the other supported modes on hxs-3 — not to
look for a different machine.

Two CUDA execution modes were evaluated against the selected artifact:

| Mode | Result | Why |
| --- | --- | --- |
| Full residency / CUDA tensor-parallel | **FAIL** | ~81 GB artifact against 32622 MiB aggregate. Upstream states two cards do not have enough memory for these Flash models, and CUDA refuses to start if layers would spill to CPU |
| **CUDA SSD streaming / single GPU** | **COMMISSIONING CANDIDATE — live validation required** | Streaming exists so the routed-expert portion need not stay resident. Mainline supports it on CUDA and QA covers it |

**Single GPU is a hard runtime constraint, not a preference.** The runtime enforces it:

```
ds4: --ssd-streaming is not compatible with multi-GPU placement
```

So GPU 0 runs DS4 and GPU 1 stays reserved during commissioning. The open multi-GPU
SSD-streaming PR is **excluded** — it adds functionality absent from mainline and carries
significant multi-tier changes, and does not belong underneath an initial operational baseline.
If approved later it gets its own branch, test plan and acceptance decision.

### The 66 GB RAM finding is scoped, not fatal

`66 GB` is **not** a full-residency pass, and **not** an automatic SSD-streaming fail. The
96/128 GB figure describes the preferred environment for full-resident Q2. Streaming exists
precisely so the model need not be cached whole in RAM.

The gate now says:

```
FULL-RESIDENT MODE        FAIL
CUDA SSD-STREAMING MODE   TEST REQUIRED
```

rather than collapsing both into `66 < 96 therefore FAIL`.

### Storage moves into the inference path

Under SSD streaming the NVMe device serves decode traffic; it is not cold storage. Capacity
**and** sustained performance both matter, and the storage gate now **gates the model
download**:

```
model file            ~81 GB
download headroom
DS4 build/runtime
KV/cache/state
logs/evidence
free reserve
                      -> well over 100 GB free on the fast NVMe hosting the GGUF
```

---

## State machine

```
1  MODEL SELECTED             ds4f-q2 exact GGUF                      PASS
2  EXECUTION MODE SELECTED    CUDA SSD streaming, single GPU          PASS
3  STORAGE VERIFIED           hxs-3 NVMe capacity + performance       <- next gate
4  DS4 INSTALLED              build current mainline CUDA
5  MODEL ACQUIRED             download ds4f-q2
6  CLI VERIFIED               one-GPU SSD streaming, cache 8 GB, ctx 4096
7  CACHE SWEEP PASSED         8 -> 10 -> 11 GB
8  CONTEXT SWEEP PASSED       4096 -> 8192 -> 16384 -> 32768
9  BENCHMARKED                cold / warm
10 LOCAL SERVER VERIFIED      ds4-server on localhost
11 API VERIFIED               API / streaming / tool round-trip
12 HX CONTRACT VERIFIED       HX L2 live acceptance
13 MANAGED WORKLOAD           managed service definition
14 NETWORK VERIFIED           HX network smoke
15 CLIENT VERIFIED            Claude Code smoke
   -> OPERATIONAL
```

Advance one step only after the previous step passes. Do not start by maximising the expert
cache or the context — start conservatively and measure.

If step 6 fails because the non-streamed resident footprint plus KV and graph scratch cannot
fit one 16 GB card, that is the true hxs-3 boundary, learned experimentally. Reduce cache or
context. The host does not change.

### The mode decision is bound to the artifact

Change the model or the quantization and the recorded capacity result goes stale, reopening the
decision:

```
selected artifact : DeepSeek V4 Flash / ds4f-q2
recorded verdict  : evaluated for DeepSeek V4 Flash / ds4f-q4
result            : BLOCKED - capacity result is STALE, the gate must be rerun
```

Evaluate with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .	estsi-runtime\hx-ds4-commission.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .	estsi-runtime\hx-capacity-gate.ps1 -Workload ds4-deepseek -TargetHost hxs-3
```

---

## Phase status in this workstream

| Phase | Work | Implemented now | Requires live host |
| --- | --- | --- | --- |
| A | Model selection record | schema in the workload file | selection decision |
| B | Capacity gate | `hx-capacity-gate.ps1` | — |
| C | Acquisition record | schema + rules | the download itself |
| D | CLI smoke | gate defined | yes |
| E | Vendor regression | gate defined | yes |
| F | Local server profile | config schema | yes |
| G–H | API, streaming, tool round-trip | contract + fixtures exist; live tests SKIP | yes |
| I | KV / prefix validation | gate defined | yes |
| J | HX L2 live acceptance | contract exists; SKIP | yes |
| K | Network exposure | gate defined | yes, plus separate authorization |
| L | Managed workload | unit template below | yes |
| M | Claude Code launcher | documented below | yes |

---

## Selected artifact

```
model         DeepSeek V4 Flash
target        ds4f-q2
gguf          DeepSeek-V4-Flash-IQ2XXS-w2Q2K-AProjQ8-SExpQ8-OutQ8-chat-v2-imatrix-0731.gguf
quantization  Q2 / imatrix 0731; routed expert gate/up IQ2_XXS, down Q2_K; attn/shared/out Q8
size          ~81 GB
source        antirez/deepseek-v4-gguf
runtime       DS4 / DwarfStar
workload      ds4-deepseek   EXPERIMENTAL
```

Arbitrary GGUF support is **not** assumed — the source states plainly that arbitrary GGUFs are
unsupported. This exact GGUF is named in the reviewed snapshot's own release smoke-test
instructions.

`model_download_allowed` stays **false** until the storage gate passes.

## Phase B — capacity gate

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ai-runtime\hx-capacity-gate.ps1 `
    -Workload ds4-deepseek -TargetHost hxs-3
```

Current verdict: **BLOCKED**, with **System RAM already FAIL** — hxs-3 has 66 GB and DS4's
smallest documented variant `ds4f-q2` targets 96/128 GB machines. That is not a gate to waive.

## Phase C — model acquisition

Only after the gate returns PASS **and** acquisition is separately authorized. Record filename,
actual size, SHA-256, source URL, identity, quantization and acquisition date. Weights live
outside Git, in the host model-storage location. **No canonical HX model-storage root exists
yet** — see `hxs3-workload-placement.md`; the candidate is hxs-3's unallocated 1.8 TB SATA SSD.
Do not download multiple large quantizations speculatively.

## Phase D — CLI smoke

Derive the command from the **installed revision's own `--help`**. Do not hardcode flags from
documentation — the flags in any plan may not match the installed build. Prove: model opens,
backend initializes, prompt path works, prefill completes, generation completes, process exits
cleanly, and runtime and model identity are captured.

## Phase E — vendor regression

Run DS4's own applicable tests before blaming HX for a runtime failure. Capture the DS4
revision or commit, the exact command, and PASS/FAIL/SKIP. **Do not copy the DS4 test tree into
HX.**

## Phase F — local server, loopback first

```
127.0.0.1  ->  runtime/API validation  ->  HX contract validation  ->  network exposure
```

The server profile owns working directory, model path, context target, GPU and backend
selection, KV cache path and quota, listen address, port and logs. It defaults to
`127.0.0.1` and `network_exposed: false`.

**The service definition represents the DS4 workload. It never encodes hxs-3's durable role.**

## Phases G–J — API, tool fidelity, KV, HX acceptance

Four distinct states, deliberately not collapsed: **API VERIFIED** (chat, streaming, tool
round-trip), then **KV VERIFIED** (prefix cache), then **HX CONTRACT VERIFIED** (L2 live
acceptance). A working endpoint is not a passing contract.

Reuse the engine-neutral contract; no DS4-specific test language is introduced. Order: identity,
non-stream chat, streaming, Anthropic-compatible messages, the OpenAI surface HX requires,
structured tool call, tool result continuation, error handling, cancellation and recovery.

Tool fidelity is the invariant already in the contract — id, name and arguments survive, the
result correlates to the same call, the next turn stays coherent, and a failed or cancelled
call does not corrupt the next request.

KV and prefix cache: cold, warm same-prefix, same-session continuation, restart/resume, disk
persistence, and invalidation after a model or runtime change. Record TTFT, prefill throughput,
generation throughput, cache-hit evidence and memory only **if actually measured**. Offline mode
never fabricates timing.

The existing OFFLINE / NO MODEL results stay class A protocol evidence. They are not
reinterpreted as live success.

## Phase K — network exposure

Only after loopback validation. Bind the interface resolved from `SERVER-REGISTRY.md` — **do
not create a second host or IP inventory**. Re-run a minimal remote L2 smoke from the approved
client location. Not authorized in this workstream; the gate is defined and pending.

Do not widen this into firewall or hardening work.

## Phase L — managed workload

Follow the existing HX convention: **systemd per unit, absolute venv interpreter in
`ExecStart`**. Template shape — values come from the workload profile, not from this document:

```ini
[Unit]
Description=DS4 DeepSeek runtime (HX workload: ds4-deepseek)
# no hard Requires= on remote units; the workload checks dependencies itself and retries

[Service]
Type=simple
User=<service account>
WorkingDirectory=<workload working_directory>
Environment=DS4_MODEL_PATH=<model path>
Environment=DS4_CONTEXT=<context target>
ExecStart=<absolute venv interpreter> <ds4 server entrypoint> --host 127.0.0.1 --port <port>
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

The unit is named and documented as a **DS4 workload service**, never as an hxs-3 role. It must
stop cleanly so the host can later run another approved model.

## Phase M — Claude Code integration

Last, and only after API and tool behaviour are known good.

**Do not overwrite the operator's normal Claude Code configuration.** Use an explicit launcher:

```
normal Claude Code        ->  existing provider configuration, untouched
explicit DS4 launcher     ->  hxs-3 DS4 Anthropic-compatible /v1/messages endpoint
```

Commission progressively, recording each result: simple smoke, read-only repository navigation,
safe tool call, tool result continuation, skill activation, specialist scenario, deliberate
deterministic hook denial, recovery from denial, then a bounded real coding task.

The hook-denial step matters most: the pass condition is not "the model never attempts the
forbidden action". It is that the deterministic hook denies it, the model recognises the denial,
recovers using the approved path, and does not fight the hook repeatedly.

---

## Operational acceptance gate

`OPERATIONAL` requires **all** of: exact model and quantization selected; capacity gate PASS;
provenance and checksum recorded; CLI inference PASS; applicable vendor tests PASS; local server
PASS; model and API identity PASS; streaming PASS; structured tool use PASS; tool result
continuation PASS; error and cancel recovery PASS; KV behaviour validated or explicitly deferred
with a reason; HX L2 PASS; managed workload PASS; remote endpoint PASS; explicit Claude Code
smoke PASS; and evidence recorded.

Anything less is `INSTALLED`, `COMMISSIONING` or `BLOCKED`.

---

## Workload switch and rollback

No durable role change is required to switch workloads.

1. Stop the DS4 workload service.
2. Verify the endpoint is inactive — absence of a listener, not merely a stopped unit.
3. Preserve or archive DS4 state as intended; **do not delete another runtime's configuration**.
4. Select the next workload profile.
5. Run the capacity gate for that workload.
6. Activate the next runtime and model.
7. Run the HX acceptance contract against the new profile.

`hxs-3` keeps its durable role — **Agent intelligence** — throughout. Only the selected workload
changes.

---

## Evidence

Each commissioning run writes JSON under `tests/ai-runtime/evidence/` recording host identity,
durable role and its source, DS4 revision, model identity, quantization, checksum, backend and
GPU mapping, context, cache configuration, endpoint, contract version, per-gate PASS/FAIL/SKIP,
performance **only if measured**, and the current commissioning state.

## Related

- `governance/policy/ai-runtime-acceptance-contract.md`
- `governance/operations/hxs3-workload-placement.md`
- `tests/ai-runtime/README.md`
- `SERVER-REGISTRY.md` — authoritative durable host identity and role
