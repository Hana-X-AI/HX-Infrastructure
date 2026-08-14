# DS4 commissioning workflow

**Status:** TARGET-STATE workflow
**Current state:** `NOT PRESENT` — DS4 is not installed, and no model is installed anywhere in
the fleet
**As-built status:** NOT ASSERTED BY THIS DOCUMENT

Installed is not operational. A successful build is not proof of model fit, and a working HTTP
endpoint is not proof that an agent client behaves correctly. These states are deliberately not
collapsed.

---

## State machine

```
NOT PRESENT
  -> INSTALLED                DS4 runtime installed
  -> MODEL SELECTED           exact model + quantization selected
  -> CAPACITY APPROVED        capacity gate RERUN with that exact artifact -> PASS
  -> MODEL ACQUIRED           model acquisition, provenance + checksum recorded
  -> CLI VERIFIED             CLI inference
  -> VENDOR TESTS PASSED      DS4 vendor tests
  -> LOCAL SERVER VERIFIED    localhost ds4-server
  -> API VERIFIED             API / streaming / tool round-trip
  -> KV VERIFIED              KV-prefix validation
  -> HX CONTRACT VERIFIED     HX L2 live acceptance
  -> MANAGED WORKLOAD         managed service definition
  -> NETWORK VERIFIED         network smoke
  -> CLIENT VERIFIED          Claude Code smoke
  -> OPERATIONAL
```

### The capacity gate is bound to the artifact, and the binding is enforced

`CAPACITY APPROVED` is not "the gate passed once". The recorded verdict carries the model
identity and quantization it was evaluated against. If either changes, the prior result is
**stale** and the gate reopens automatically:

```
selected artifact : ds4f / q2
recorded verdict  : PASS, evaluated for ds4f / q4
result            : BLOCKED - capacity gate result is STALE, the gate must be rerun
```

A PASS for one quantization is not a PASS for another. This is enforced in
`hx-ds4-commission.ps1`, not left to discipline.

Evaluate with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ai-runtime\hx-ds4-commission.ps1
```

The driver stops at the first unmet gate — a later gate cannot be assessed before an earlier
one. It contacts no host, downloads nothing, installs nothing, and reports BLOCKED or SKIP with
a reason rather than inventing a result.

Until every gate passes, the reported state is `NOT PRESENT`, `COMMISSIONING` or `BLOCKED`.

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

## Phase A — model selection

DS4 does not become useful because the runtime is installed. A supported model artifact is
still required, and **arbitrary GGUF support is not assumed** — the source states plainly that
arbitrary GGUFs are unsupported.

Required before the capacity gate can compute residency: exact model identity, exact
quantization, confirmation the installed DS4 revision supports it, source provenance, and
expected file size. All five live in `model_selection` in
`tests/ai-runtime/workloads/ds4-deepseek.json` and are currently `null`.

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
