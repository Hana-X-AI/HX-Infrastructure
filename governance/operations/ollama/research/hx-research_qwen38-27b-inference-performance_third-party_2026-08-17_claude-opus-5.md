# Qwen3.8-27B Local Inference Performance — Third-Party Field Report and HX Fit Analysis

| | |
|---|---|
| **Document ID** | `hx-research_qwen38-27b-inference-performance_third-party_2026-08-17_claude-opus-5` |
| **Subject** | Qwen3.8-27B local inference — throughput, memory footprint, concurrency, agentic behaviour |
| **Evidence tier** | `third-party` — single external operator, unverified, non-HX hardware |
| **Author** | Claude (Opus 5) |
| **Date** | 2026-08-17 |
| **Status** | Research record. **Not a decision, not an acceptance, not an authorization.** |
| **Relates to** | hxs-1 (`Deep reasoning & synthesis`, `Qwen 3.8 27B`) · `governance/fleet-architecture-v0.3.html` · `tests/ai-runtime/` |

---

## Abstract

A public field report by a single independent operator provides the first quantitative
performance data on Qwen3.8-27B under local inference that is available to this project.
The operator ran a 4-bit Unsloth quantization on a **single NVIDIA RTX 4090 (24 GB)** and
reported prefill and decode throughput across a 8K–120K context ladder, prefix-cache
behaviour, a 32-way concurrency ladder, resident memory at 131K context, and qualitative
results on three agentic build tasks.

The headline number for this project is **~23.5 GiB resident at 131K context**. That single
figure resolves the largest open unknown in the hxs-1 slot: it establishes that Qwen3.8-27B
at 4-bit **plausibly fits hxs-1's 32,752 MiB aggregate budget with roughly 6.5 GiB of
headroom**, and simultaneously establishes that it **cannot fit on either card alone**. The
model must span both GPUs, which makes the unresolved PCIe ×4 link width on hxs-1's second
card a mandatory question rather than an optional one.

Scaled to hxs-1's hardware by memory-bandwidth and compute ratio, the derived expectation is
**~40–53 tok/s single-stream decode** and **~135 s cold time-to-first-token at 120K context**,
falling to **~3 s on a prefix-cache hit**. Prefix caching is therefore not an optimization on
this host; it is the difference between an interactive system and an unusable one.

This document records the external claims, states their limitations plainly, derives the
hxs-1 implications, and converts them into falsifiable hypotheses for a future commissioning
run. It asserts no acceptance and requests no ruling.

---

## 1. Provenance and evidence tier

### 1.1 What this source is

A transcript of a publicly published video review of Qwen3.8-27B, produced by an independent
enthusiast operator. The transcript was supplied by the project owner on 2026-08-17.

### 1.2 Classification against the HX evidence model

`governance/policy/ai-runtime-acceptance-contract.md` defines three evidence classes: **A**
protocol/client conformance (offline-provable), **B** model behaviour, **C** performance and
VRAM. Neither B nor C is provable offline.

This source makes **class C claims** (throughput, VRAM) and **class B claims** (task quality,
reasoning behaviour) about hardware that is not HX hardware, using a toolchain HX has not
installed, with no published methodology, no raw logs, and no reproduction path.

> Under the project's own standard — *"A skip is never a pass"* and *"Never use `PASS` for a
> property the test could not actually disprove"* — **nothing in this document constitutes
> evidence for an HX acceptance decision.** It is prior art. It narrows the hypothesis space
> for a commissioning run. It does not substitute for one.

### 1.3 Known limitations of the source

| # | Limitation | Effect on usability |
|---|---|---|
| L1 | **Different GPU class.** Single RTX 4090, 24 GB, 1008 GB/s, AD102. hxs-1 is 2× RTX 4070 Ti SUPER, 16 GB each, 672 GB/s, AD103. | All throughput figures require scaling. Single-card vs dual-card is an architectural difference, not a scaling factor. |
| L2 | **Quantization tier partly ambiguous.** Most tests stated as "4-bit from Unsloth"; a 3-bit tier is also discussed. The 23.5 GiB figure is stated adjacent to the 3-bit discussion and its tier is not unambiguous. | The single most important number carries a tier ambiguity. See §4.1. |
| L3 | **Unsloth dynamic quants are not plain Q4_K_M.** Unsloth applies per-layer mixed precision. Byte sizes and quality do not transfer to a generic "4-bit" label. | Any HX artifact must be sized in the exact channel it will deploy from. |
| L4 | **No stated inference engine, version, or flags** beyond references to MTP and prefix caching. | Behaviour is engine-specific. Findings cannot be attributed to Ollama, llama.cpp, or vLLM. |
| L5 | **No methodology, no error bars, no repetition count.** Several figures given as ranges or approximations ("about", "I believe"). | Treat every number as ±. |
| L6 | **One internal arithmetic inconsistency** — see §3.4. | Reduces confidence in the concurrency block specifically. |
| L7 | **Two comparative claims are explicitly hearsay** — see §5.3. | Not propagated into any HX record. |
| L8 | **Concurrency context depth unstated.** Aggregate throughput at 32 agents is meaningless without knowing per-agent context. | Concurrency figures cannot be converted to an HX capacity plan. |

---

## 2. Reported test configuration

| Parameter | Value | Confidence |
|---|---|---|
| Model | Qwen3.8-27B | stated |
| Predecessor referenced | Qwen3.6-27B, ~4–5 months earlier | stated |
| GPU | 1× NVIDIA RTX 4090, 24 GB GDDR6X | stated |
| Quantization | 4-bit, Unsloth; 3-bit also sampled | stated |
| Speculative decoding | MTP (multi-token prediction) enabled by default, "out of the box" | stated |
| Prefix caching | Available; on/off both measured | stated |
| Reasoning effort | Maximum, for the build tasks | stated |
| Inference engine | **not stated** | — |
| Engine version / flags | **not stated** | — |

---

## 3. Reported quantitative findings

All figures in this section are **the source's claims**, restated. None are HX measurements.

### 3.1 Prefill (context ingestion)

| Context | Prefill throughput | Cold TTFT |
|---|---|---|
| 8,192 | **2,359 tok/s** (peak) | — |
| ~120,000 | slightly degraded from peak | **~72 s** |

The peak sits at 8K and degrades only "slightly" out to 120K — a notably flat curve. The
practical consequence is stated directly: ingesting 120K cold costs the user a **72-second
wait before the first token appears**.

### 3.2 Decode (generation)

| Condition | Throughput |
|---|---|
| Sustained, 32K–48K context | **60–80 tok/s** |
| Context ladder measured | 8K, 32K, 64K, 120K — throughput declines as context fills |

Per-rung decode figures for the 8K/32K/64K/120K ladder were shown on-screen in the source but
not spoken; only the aggregate characterization survives in the transcript.

### 3.3 Prefix caching

| Condition | TTFT at ~120K |
|---|---|
| Cold | ~72 s |
| Cache hit | **~1.5 s** |

**A ~48× reduction.** This is the largest single effect reported anywhere in the source.

### 3.4 Concurrency

| Concurrent agents | Aggregate decode | Per-agent | MTP |
|---|---|---|---|
| 8 | **202 tok/s** | ~25 tok/s (derived) | not stated |
| 16 / 20 / 24 | ladder run, values not stated | — | disabled |
| 32 | **330 tok/s** | ~10.3 tok/s (derived) / **11.4 stated** | disabled |

Two observations:

1. **MTP had to be disabled to reach high concurrency.** This is the expected trade — speculative
   decoding spends spare compute to cut single-stream latency, and batching wants that compute
   back. It is a real operational finding and it generalizes across engines.
2. **The per-agent figure is internally inconsistent.** 32 × 11.4 = 365 tok/s, not the stated
   330 aggregate; 330 ÷ 32 = 10.3. The discrepancy is ~10%. Either the aggregate or the
   per-agent figure is approximate. *(L6)*

The operator states the ceiling was **not reached** at 32 agents.

### 3.5 Resident memory

> "I was pretty much almost at the limit. I believe 23 gigs, 23 and a half gigs at 131K context."

**~23.5 GiB resident at 131,072-token context**, against a 24 GiB card. Quantization tier
ambiguous *(L2)*. This is the most consequential number in the source for this project.

---

## 4. HX fit analysis — hxs-1

hxs-1 (`192.168.50.200`): Intel Core Ultra 9 285K 24c/24t · 128 GB DDR5 · **2× RTX 4070 Ti
SUPER, 16,376 MiB each, 32,752 MiB total** · driver 580.173.02 / CUDA 13.0 · Ubuntu 24.04.4 ·
3.6 TB NVMe root at 1% used, ~11 TB unallocated. Source: `servers/hxs-1/discovery.md`.

### 4.1 Memory budget

Applying `hx-gpu-fit.ps1`'s own stated convention — 1.0 GiB runtime overhead per device for
CUDA context, allocator, and compute scratch:

```
hxs-1 aggregate            32,752 MiB  =  31.98 GiB
  less 2 × 1.0 GiB CUDA context        =  -2.00 GiB
usable                                 =  29.98 GiB

observed footprint @131K ctx           =  23.50 GiB
headroom                               =   6.48 GiB      utilization 78.4%

single card usable (15.99 − 1.0)       =  14.99 GiB
observed footprint                     =  23.50 GiB   →  DOES NOT FIT
```

Two conclusions, and the second matters more than the first:

**PASS on aggregate.** 6.48 GiB headroom clears `hx-gpu-fit.ps1`'s thresholds (`FAIL` if ≤ 0,
`BLOCKED` if < 1.0 GiB) with margin. At 78% utilization there is room for the CUDA context to
run heavier than assumed and still hold.

**Multi-GPU is mandatory, not optional.** 23.5 GiB exceeds a single card by ~8.5 GiB. There is
no single-card configuration of this model at this context on this host. Every deployment
option therefore inherits the inter-GPU question — which is the unresolved item below.

### 4.2 The PCIe ×4 link becomes a blocking question

`servers/hxs-1/discovery.md` records GPU0 at `2.5 GT/s ×16` and **GPU1 at `2.5 GT/s ×4`
against an ×16-capable device**, noting the two GPUs "do not have equal host bandwidth" and
that this "has not been confirmed under load."

The 2.5 GT/s reading is very likely idle link-state downtraining (ASPM / dynamic link speed)
and will recover under load. **Link width, by contrast, is negotiated at link training and is
not reduced by idle power management on NVIDIA GeForce parts.** A ×4 reading therefore reflects
the physical slot wiring, board bifurcation settings, riser or cable lane loss, or a lane that
failed to train — none of which recover under load. And §4.1 has just established that the
model *must* span both cards.

The consequence differs sharply by parallelism strategy:

| Strategy | Inter-GPU traffic | Sensitivity to ×4 |
|---|---|---|
| **Layer split** (llama.cpp / Ollama) | One activation tensor per split boundary — a few MB per token | **Low.** Latency-bound, not bandwidth-bound. ×4 Gen4 (~8 GB/s) is ample. |
| **Tensor parallel, TP=2** (vLLM) | All-reduce **every layer**, 64 layers per forward pass | **High.** The slow card paces both. This is where a ×4 link becomes a throughput collapse. |

**This single unmeasured fact discriminates between the two candidate runtimes.** It should be
resolved before any runtime decision is packaged, and it costs one command.

### 4.3 Derived throughput expectations

Scaling from the 4090 baseline. Decode is memory-bandwidth-bound; prefill is compute-bound:

| Ratio | 4090 | 4070 Ti SUPER | Ratio |
|---|---|---|---|
| Memory bandwidth | 1008 GB/s | 672 GB/s | **0.667** |
| Compute (AI TOPS) | 1321 | 706 | **0.534** |
| Compute (FP32 TFLOPS) | 82.6 | 44.1 | 0.534 |

**A note on why two cards do not double the rate.** Under layer split, the forward pass runs
GPU0's layers, then GPU1's — sequentially. Each card reads only its own weights from its own
VRAM. With two cards of *equal* bandwidth, total time is governed by one card's bandwidth
rather than the sum — so for a single stream, two cards buy capacity, not speed. Under TP=2
the compute genuinely parallelizes, but only if the interconnect keeps up — which returns to
§4.2.

| Metric | 4090 observed | **hxs-1 derived** | Basis |
|---|---|---|---|
| Decode, single stream | 60–80 tok/s | **40–53 tok/s** | × 0.667 (bandwidth) |
| Prefill @ 8K | 2,359 tok/s | **~1,260 tok/s** | × 0.534 (compute) |
| Cold TTFT @ 120K | 72 s | **~135 s** (2.2 min) | ÷ 0.534 (compute) |
| Cached TTFT @ 120K | 1.5 s | **~2–3 s** | weakly scaled — see note |
| Aggregate decode, 8 agents | 202 tok/s | ~108–135 tok/s | × 0.534–0.667 |
| Aggregate decode, 32 agents | 330 tok/s | ~176–220 tok/s (~5.5–6.9/agent) | × 0.534–0.667 |

**Two scaling caveats, stated rather than hidden:**

- **The concurrency rows carry a range, not a point.** Single-stream decode is
  memory-bandwidth-bound, so × 0.667 is right. Under batching, weight reads amortize across
  the batch and decode shifts toward compute- and attention-bound — pulling the honest ratio
  toward 0.534. The upper end of each range is therefore an optimistic bound, not an estimate.
  A related caveat applies to the layer-split argument above: it is a *single-stream* result.
  Under concurrency the two GPU stages can in principle be pipelined so both cards work on
  different requests at once, recovering throughput toward 2× — vLLM's pipeline-parallel does
  this; llama.cpp largely does not.
- **Cached TTFT is only weakly scalable.** A prefix-cache hit skips prefill entirely, so the
  1.5 s is KV load plus first-token decode plus host overhead — none of it compute-bound
  prefill. No clean ratio applies. ~2–3 s is an order-of-magnitude expectation, not a
  derivation.

> These are **derived estimates from an unverified third-party baseline**, not predictions and
> certainly not commitments. They exist to size expectations and to give a commissioning run
> something specific to falsify. Real-world divergence of ±30% would not be surprising.

### 4.4 Prefix caching is load-bearing on this host

A 135-second cold TTFT at 120K context is not usable interactively. The same request on a
cache hit lands at ~3 s. On the 4090 the cold path was merely annoying; **on hxs-1 it is the
difference between a working system and an abandoned one.**

This has an architectural consequence worth stating plainly: any serving design for hxs-1
must treat prefix-cache retention as a first-class requirement — sized deliberately, measured,
and protected — rather than as an engine default nobody looked at. It also argues against
frequent model unload/reload cycles on this host, which discard the cache.

### 4.5 Reasoning verbosity is a capacity lever, not a preference

The source is emphatic that Qwen3.8-27B over-reasons — that it "thinks a lot," can "talk
itself out of solutions," and that turning reasoning effort down to medium or off makes it
"feel a lot snappier" without materially hurting the observed results.

At hxs-1's derived ~0.667× decode rate, this stops being a stylistic note:

| Task (source) | 4090 wall-clock | hxs-1 derived | Token budget consumed |
|---|---|---|---|
| Kanban board | ~5 min | **~7.5 min** | ~60,000 |
| Options dashboard (MCP + skills) | ~7–8 min | **~11 min** | ~120,000 |

Both were single-prompt runs at **maximum** reasoning effort. Reasoning effort therefore acts
as a direct multiplier on wall-clock, on context consumption, and on how quickly a session
approaches the context ceiling. On a host running at two-thirds the reference speed, the
default reasoning level is a capacity decision.

*(Derivation note: the token figures are total consumed, not tokens generated. 5 minutes at
60–80 tok/s implies ~18–24K generated tokens of the ~60K total. Wall-clock scaling uses the
bandwidth ratio; the token figures are reported as-is.)*

### 4.6 Runtime implications — what this evidence does and does not settle

`tests/ai-runtime/profiles/vllm-qwen.json` marks vLLM `PRIMARY`, and CI invariant #1 enforces
it. `craig-ollama-specialist.md` limits Ollama to a narrow GGUF-utility role. Owner direction
of 2026-08-14: *"the fleet goes forward on vLLM with HuggingFace models rather than Ollama
with library tags."*

That direction was set against a 9B model on hxs-4. This evidence is the first data bearing on
a 27B on hxs-1, and it cuts in a specific direction:

| Factor | Favours | Why |
|---|---|---|
| 23.5 GiB footprint vs 29.98 GiB usable | **Ollama / llama.cpp** | HX's own hxs-4 measurement: a w4a16 vLLM artifact was **10.65 GB** against a **5.29 GB** GGUF for the same 9B, "because that format keeps activations at 16-bit and ships the vision tower." At ~2× ratio a 27B w4a16 artifact plausibly exceeds the aggregate budget. |
| Must span both GPUs | **Ollama / llama.cpp** | Layer split is insensitive to the ×4 link; TP=2 is not. |
| Over-budget failure mode | **Ollama / llama.cpp** | HX record: vLLM "preallocates a KV block pool… does NOT offload layers to CPU… **vLLM fails to start.**" Ollama degrades to a CPU/GPU split. |
| Context-overflow correctness | **vLLM** | `iss-015` remains open: Ollama silently truncates. Root-caused in source — the Anthropic adapter never sets `Truncate` and the handler defaults it true. Present at v0.32.13. |
| Concurrency / multi-agent serving | **vLLM** | Continuous batching and paged KV are vLLM's purpose. The source's 32-agent numbers came from an unstated engine. |
| Authentication | **vLLM** | HX record: "Ollama has **no authentication of any kind**." |

**The honest reading:** this evidence materially strengthens the case that Ollama is the
runtime that *fits* on hxs-1, while leaving every reason Ollama was demoted — silent
truncation, no auth, no batching story — completely intact. Those are orthogonal problems, and
a fit argument does not answer a correctness argument.

It is not grounds to break a CI-enforced invariant. It is grounds to put a properly evidenced
question in front of the owner: *does the vLLM-primary direction survive contact with a 27B
model on a 32 GiB aggregate budget behind an unequal PCIe link?* The correct next step is a
measurement, not a preference.

---

## 5. Reported qualitative findings

### 5.1 Agentic task performance

| Task | Result |
|---|---|
| Flappy Bird, React + Vite | One-shot success. Score tracking, sound, working physics described as "okay." |
| Kanban to-do board | Complete in ~5 min / ~60K tokens. Drag-reorder, priority editing, persistence all functional. |
| Options debit-spread dashboard | Single prompt, ~120K tokens, 7–8 min. Chained tool use, skills, and a live MCP connection to a brokerage account; produced positions view and a profit heatmap. **Minor rendering defects observed** — some elements did not appear. |

The third task is the most informative for HX purposes: it exercised **multi-step tool use,
skill invocation, and MCP integration under a long reasoning chain from a short prompt** —
which is much closer to the `Deep reasoning & synthesis` role assigned to hxs-1 than a
one-shot code generation is.

### 5.2 Behavioural characterization

- **Over-reasons.** The central qualitative complaint. Described as a double-edged sword: the
  reasoning solves genuine edge cases, but can also reason its way past a correct answer.
- **Operator recommendation:** medium or disabled reasoning for most work.
- **Quality holds at 3-bit** in limited sampling, with lower memory use — untested at depth.
- **MTP available by default,** and worth disabling under concurrency.

### 5.3 Comparative claims — recorded, not propagated

Two comparative claims appear in the source. Both are flagged here and **deliberately not
carried into any HX record**:

1. *"As good, if not better on some benchmarks than Opus 4.6."* The operator explicitly
   qualifies this as half-remembered — "I think I saw a benchmark screenshot somewhere." No
   benchmark, harness, or figure is named. **This is the weakest claim in the source.**
2. Favourable comparison against a similarly-sized model referred to as "Muse Glimmer."
   Subjective, single-operator, no methodology.

Neither meets any HX evidence bar. They are recorded solely so that a future reader who
encounters the same source knows they were seen and rejected, rather than missed.

---

## 6. Derived hypotheses for hxs-1 commissioning

Falsifiable, each mapped to the measurement that would settle it. This is the section a future
commissioning run should consume.

| # | Hypothesis | Test | Falsified if |
|---|---|---|---|
| H1 | Qwen3.8-27B at 4-bit is resident in < 26 GiB at 128K context across both GPUs | Measured context ladder — 8K, 32K, 64K, 128K — recording `nvidia-smi` per card at each rung | Footprint exceeds 26 GiB at 128K (hard failure at 29.98 GiB, or if CPU offload engages) |
| H2 | Single-stream decode lands in 40–53 tok/s | Generation benchmark at 8K and 32K context | Sustained rate falls below 30 tok/s |
| H3 | GPU1's ×4 is a reporting artifact, not the negotiated slot width | **`sudo lspci -vvs <bdf>`, comparing `LnkCap` width against `LnkSta` width** — `nvidia-smi --query-gpu=pcie.link.width.max` often reports the *device's* capability (16) rather than the slot's, and can leave this unfalsifiable | `LnkSta` width reads x4 while `LnkCap` reads x16 |
| H4 | Layer split is insensitive to the ×4 link; TP=2 is not | Same decode benchmark under both strategies | TP=2 within 10% of layer split (H4 false, ×4 is a non-issue) |
| H5 | Prefix caching reduces long-context TTFT by more than 20× | TTFT at 120K, cold vs warm | Reduction under 10× |
| H6 | KV growth is sub-linear in context, per the Gated DeltaNet hybrid pattern measured on Qwen3.5-9B | Per-rung KV delta from the H1 ladder | KV scales linearly with context |
| H7 | Reduced reasoning effort cuts wall-clock >30% without materially degrading task success | Same task at max / medium / off | Success rate drops materially at medium |
| H8 | A vLLM-compatible 4-bit artifact does **not** fit the 29.98 GiB budget | Resolve actual w4a16/AWQ/GPTQ manifest byte counts before download | An artifact fits with >1 GiB headroom |

**H8 is the cheapest and the most decision-relevant.** It requires no host access at all —
only resolving real manifest sizes in both channels. Per the project's own recorded lesson:
*"Always resolve the real file size in the channel you will actually deploy from."*

---

## 7. Conclusions

1. **A 27B-class model at 4-bit plausibly fits hxs-1.** ~23.5 GiB against 29.98 GiB usable is
   a 78% utilization with 6.48 GiB of headroom. The reserved slot is viable on capacity
   grounds. This was previously unknown.
2. **It cannot fit on one card.** Multi-GPU is mandatory, which promotes the PCIe ×4 link
   from a footnote to a blocking question.
3. **The ×4 link discriminates between the two candidate runtimes** — layer split tolerates
   it, TP=2 does not — and it is unmeasured. One command settles it.
4. **Prefix caching is load-bearing on this host,** not an optimization. ~135 s cold versus
   ~3 s warm at 120K context.
5. **Reasoning effort is a capacity lever.** At two-thirds the reference decode rate, default
   maximum reasoning multiplies wall-clock and context burn on every request.
6. **The fit evidence favours Ollama; the correctness evidence still favours vLLM.** Both are
   true simultaneously. This is a question to put to the owner with measurements attached, not
   a conclusion to act on.
7. **This document changes no project state.** It is prior art that narrows the hypothesis
   space and supplies eight falsifiable tests for a commissioning run that has not been
   authorized.

---

## 8. Citation

```
Third-party field report, Qwen3.8-27B local inference performance.
Independent operator, published video review; transcript supplied by project owner 2026-08-17.
Hardware: 1× NVIDIA RTX 4090 24 GB. Quantization: 4-bit (Unsloth), 3-bit sampled.
Engine, version and flags: not stated.
Evidence tier: third-party — unverified, non-HX hardware, no published methodology.
```

**HX records referenced:** `servers/hxs-1/discovery.md` · `SERVER-REGISTRY.md` ·
`governance/fleet-architecture-v0.3.html` · `governance/policy/ai-runtime-acceptance-contract.md` ·
`governance/logs/actions-and-issues.md` (`iss-015`, `act-014`) ·
`governance/operations/ollama/craig-ollama-specialist.md` ·
`tests/ai-runtime/hx-gpu-fit.ps1` · `tests/ai-runtime/profiles/vllm-qwen.json` ·
`tests/ai-runtime/workloads/qwen35-9b-ollama.json`

**GPU specifications** are vendor-published figures for the RTX 4090 and RTX 4070 Ti SUPER
(memory bandwidth, AI TOPS, FP32 throughput), used only to compute scaling ratios.

---

*Prepared by Claude (Opus 5), 2026-08-17. Research record — no authority asserted, no decision
made, no acceptance granted. Per repository convention, a proposal is not a ruling.*
