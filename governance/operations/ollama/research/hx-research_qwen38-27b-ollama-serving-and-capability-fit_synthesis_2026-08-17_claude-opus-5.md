# Qwen3.8-27B — Ollama Serving, Capability Profile, and hxs-1 Role Fit

| | |
|---|---|
| **Document ID** | `hx-research_qwen38-27b-ollama-serving-and-capability-fit_synthesis_2026-08-17_claude-opus-5` |
| **Subject** | Second third-party field report on Qwen3.8-27B, verified against the official model card and the Ollama registry; artifact register; capability profile; hxs-1 role fit |
| **Evidence tier** | `synthesis` — third-party transcript (trigger) reconciled against **vendor primary** (Qwen model card, Ollama registry manifest) and **HX primary** (registry, discovery, workload records) |
| **Author** | Claude (Opus 5) |
| **Date** | 2026-08-17 |
| **Status** | Research record. **Not a decision, not an acceptance, not an authorization.** |
| **Supersedes** | Nothing. **Companion to** `codex_20260817_1524_hx-qwen38-27b-ollama-deployment-deep-dive.html` (deployment runbook) and `hx-research_qwen38-27b-inference-performance_third-party_2026-08-17_claude-opus-5` (inference performance). Deliberately does not duplicate either. |

---

## 1. Verdict

**The model is real, the benchmarks check out, and it is available in the official Ollama
library today. But the single most consequential finding is not about serving — it is that
Qwen3.8-27B's strongest capability has no home in the HX architecture, and the role it has been
assigned is the one capability where it is weakest.**

hxs-1's registry role is **`Deep reasoning & synthesis`**. Verified against the official model
card, Qwen3.8-27B is **not a frontier reasoner** — HLE 30.8 against Opus 4.6 Max's 40.0,
GPQA-Diamond 89.2 against 91.3, Terminal-Bench 73.0 against 78.2. What it *is*, decisively, is
the best **computer-use / GUI-agent** model in its own comparison table: OSWorld-Verified **84.3
against Opus's 72.7**, AndroidWorld 81.9 against 62.0, SWE-MM 38.6 against 27.1. A full repo
search establishes that **HX has no computer-use, GUI-automation, or browser-control plane
anywhere** — not in the registry's fifteen roles, not in the fleet architecture, not in the
Phase 3 tech stack.

Three qualifications keep this from being an argument to change anything today. First, **the only
*recorded justification* for the placement is hardware-based** — VRAM, PCIe generation, matched
card pairs — and across every HX document available to this search, no record defines a reasoning
bar the occupant must clear. The model is not failing a test that exists. Second, the role's own
founding document describes "multi-agent synthesis (Flow B)", which is closer to long-horizon
agentic work than to frontier reasoning. Third, role assignment is explicitly an owner decision
that agents may not make.

The honest framing is therefore not *"the wrong model is in the slot."* It is: **HX is about to
commission a best-in-class agentic/computer-use model into a slot named for reasoning, with no
recorded definition of what that slot requires, and no plane to consume the thing the model is
actually exceptional at.** That is a decision worth making deliberately rather than by default.

On serving, the practical findings are smaller but sharp: **the default `qwen3.8:27b` tag is the
MTP variant, not plain Q4_K_M**, and they are genuinely different artifacts; **`27b-nvfp4` and
`27b-mlx` resolve to the same artifact**, so at least one of the two format names is wrong; and
**no HX record anywhere specifies sampler settings for any model**, while this model ships two
distinct official sampler regimes that materially affect output quality.

---

## 2. Provenance and evidence discipline

### 2.1 The trigger source

A transcript of a second publicly published video review of Qwen3.8-27B by an independent
operator, supplied by the project owner on 2026-08-17. It is a different author from the field
report in the companion inference-performance record.

**Unlike that first source, this one is largely a conduit for vendor-published material.** Its
benchmark section restates the official model card; its serving section restates the Ollama
library page. That makes it *verifiable*, and I have verified essentially all of it — which
means the load-bearing evidence in this document is **vendor primary**, not third-party. The
transcript's value is as a pointer and as a source of operator judgement, not as data.

### 2.2 Excluded material

**Minutes 1:38–3:45 of the transcript are a paid advertising segment** for a third-party
testing product, structured as a narrative about agent feedback loops. It is unrelated to
Qwen3.8-27B, it is commercial content, and **none of it is carried into this document** — not
the product, not the claims, not the anecdote. It is noted here only so that a future reader
comparing this record against the source knows the omission is deliberate.

### 2.3 Evidence classes used

| Class | Sources | Weight |
|---|---|---|
| **Vendor primary** | Qwen3.8-27B official model card (benchmarks, samplers, thinking controls, architecture); Ollama library registry (tags, sizes, digests); Ollama context-length docs; llama.cpp server docs | Load-bearing |
| **HX primary** | `SERVER-REGISTRY.md`, `servers/hxs-1/discovery.md`, `tests/ai-runtime/workloads/qwen35-9b-ollama.json` (measured hxs-4 as-built) | Authoritative for HX state |
| **HX design / in-flight** | `codex_20260817_1524_...deployment-deep-dive.html`, `governance/fleet-architecture-v0.3.html`, `hx-stack-alignment-v0.1-frozen.html` | Proposals, not authority |
| **Third-party** | The transcript | Pointer and judgement only |
| **Derived** | Memory arithmetic in §5 (F5 and F6) | Explicitly labelled |

### 2.4 Authority note

`SERVER-REGISTRY.md` is authoritative for assigned role and approved workload/model. Neither
this document, the Codex runbook, nor any other agent output changes it. Per the registry's own
rule: *"Agents must not assign roles automatically."*

---

## 3. Benchmark verification

Every figure the transcript stated was checked against the official model card. **The transcript
is accurate — of twenty-two checkable numbers, twenty-two match.**

*Correction, recorded rather than quietly fixed: a first pass of this document declared two of
the transcript's benchmark claims unverifiable, having retrieved only part of the model card's
text table. Both are in the model card and both are exact. The error is instructive — it is an
absence-of-evidence inference drawn from an incomplete retrieval, which is the same failure mode
this document cautions against in F1. The two rows are restored below.*

### 3.1 Text and agentic

| Benchmark | **Qwen3.8-27B** | Qwen3.6-27B | Qwen3.7-Plus | Muse Glimmer-30B | Opus 4.6 Max | Verdict |
|---|---|---|---|---|---|---|
| SWE-bench Pro | **61.7** | 53.5 | 57.6 | 51.2 | 53.4 | ✅ beats Opus |
| Terminal-Bench 2.1 | 73.0 | 63.4 | 64.0 | 51.7 | **78.2** | ❌ behind Opus |
| CoWorkBench | **70.7** | 61.0 | 65.1 | — | 68.2 | ✅ beats Opus |
| IFBench (instruction following) | **79.5** | 69.1 | 79.1 | 77.0 | 62.5 | ✅ beats Opus |
| LiveCodeBench v6 | **90.3** | 83.9 | 89.6 | — | 88.8 | ✅ top of table |
| QwenSWEBench | **79.0** | 49.3 | 59.2 | — | 63.8 | ✅ beats Opus |
| DeepSWE 1.1 | **42.2** | 13.3 | 14.2 | — | — | ✅ top of table |
| NL2Repo-Bench | 42.3 | — | — | — | **47.6** | ❌ behind Opus |
| GPQA-Diamond | 89.2 | 87.8 | 90.3 | 83.5 | **91.3** | ❌ behind Opus |
| **HLE** | 30.8 | 24.0 | 34.7 | 22.0 | **40.0** | ❌ **well behind Opus, and behind Qwen3.7-Plus** |

**DeepSWE 1.1 deserves note: 13.3 → 42.2 is a 3.2× generation-over-generation jump** on an
agentic software-engineering benchmark. It is the largest single improvement in the table and it
reinforces F2's reading of where this model's strength actually lies.

### 3.2 Vision and computer use — **computer-use subset**

**Scope warning.** The model card's vision-language table has **17 rows**; the five below are the
computer-use and GUI-agent rows. On the remaining rows Qwen3.8-27B is *not* the leader —
**Qwen3.7-Plus leads on at least six**, including ClawEval-MM Average (60.1 vs 56.9), MathVision
(90.3 vs 90.0), CharXiv RQ (85.8 vs 83.7), OmniDocBench 1.5 (91.4 vs 91.1), RealWorldQA (86.9 vs
85.9) and ERQA (69.8 vs 65.5). **This model is the computer-use leader, not the general
vision-language leader**, and any HX claim must be scoped that way.

| Benchmark | **Qwen3.8-27B** | Qwen3.6-27B | Qwen3.7-Plus | Muse Glimmer-30B | Opus 4.6 Max |
|---|---|---|---|---|---|
| **OSWorld-Verified** (desktop computer use) | **84.3** | 63.9 | 73.3 | 65.9 | 72.7 |
| WebArena-Verified (browser) | **64.8** | 48.8 | 55.3 | — | — |
| AndroidWorld (mobile) | **81.9** | 70.3 | 81.0 | — | 62.0 |
| Vision2Web | **62.9** | 45.0 | 42.1 | — | — |
| SWE-MM (multimodal SWE) | **38.6** | 25.7 | 30.0 | — | 27.1 |

### 3.3 A resolved loose end

**"Muse Glimmer" is real and is in the official comparison table** as Muse Glimmer-30B. The
first field report referred to it in passing and this record could not corroborate it at the
time. It is now corroborated as a vendor-named comparison model — though HX has no reason to
care about it beyond that.

---

## 4. The Ollama artifact register

Retrieved from the official Ollama library, 2026-08-17. **Twelve tags**, matching the
transcript's count.

| Tag | Size | Short digest | Notes |
|---|---|---|---|
| `qwen3.8:latest` | 18 GB | `22130167c4c2` | ⚠️ **= the MTP variant** |
| `qwen3.8:27b` | 18 GB | `22130167c4c2` | ⚠️ **= the MTP variant** |
| `qwen3.8:27b-mtp-q4_K_M` | 18 GB | `22130167c4c2` | MTP speculative decoding |
| `qwen3.8:27b-q4_K_M` | 18 GB | `25b843619e94` | **Non-MTP. Different artifact.** |
| `qwen3.8:27b-mtp-q8_0` | 30 GB | `8a1582877303` | |
| `qwen3.8:27b-q8_0` | 30 GB | `8f5fb6b71ea0` | |
| `qwen3.8:27b-mlx` | 18 GB | `5642e97495e1` | Apple Silicon |
| `qwen3.8:27b-nvfp4` | 18 GB | `5642e97495e1` | ⚠️ **same digest as `-mlx`** |
| `qwen3.8:27b-mxfp8` | 32 GB | `464021588235` | |
| `qwen3.8:27b-bf16` | 56 GB | `1aa85dae8b2d` | |
| `qwen3.8:27b-mtp-bf16` | 56 GB | `197257101a8c` | |
| `qwen3.8:27b-mlx-bf16` | 56 GB | `65e5e1c72d2d` | |

All tags advertise a **256K context window** with **text and image** capability.

---

## 5. Findings, ordered by impact

### F1 — Role–capability mismatch, with no capability bar to fail

`SERVER-REGISTRY.md` assigns hxs-1: **Assigned Role `Deep reasoning & synthesis`**, **Workload
`Qwen 3.8 27B — unreleased, slot reserved`**.

Searching the full repo for the rationale behind that role returns a split answer. **The only
*recorded justification* is hardware-based; the role *naming* is capability-framed, and nothing
connects the two.** `fleet-architecture-v0.3.html` justifies it as
`TP = 2, 4-bit, ~14 GB weights + KV → fits`. `hx-stack-alignment-v0.1-frozen.html` calls hxs-1
"the **reasoning flagship**" and pairs the role with "Deep reasoning, multi-agent synthesis
(Flow B)". `hx-validation-findings.html` debates the placement purely on PCIe generation: *"If
either big model should sit on the one PCIe-4 host, it's the coder, not the reasoning model."*

Note the tension inside that evidence: "reasoning flagship" and "multi-agent synthesis (Flow B)"
are *capability* language, sitting inside a pipeline taxonomy — but every justification offered
for the placement is about VRAM, PCIe generation and matched card pairs.

**Across every HX document available to this search, no record defines a reasoning-capability
requirement, benchmark threshold, or acceptance criterion for the hxs-1 role.** The name appears
to derive from the model already earmarked for the slot, not from a specification the occupant
must satisfy. This is an absence-of-evidence conclusion, and it is safe only because
`SERVER-REGISTRY.md` is *stated* to be authoritative for role assignment — so silence there is
meaningful rather than merely incomplete.

That cuts both ways, and both matter:

- **It softens the mismatch.** The model is not failing a bar, because no bar was ever written.
  And "multi-agent synthesis" is arguably a better description of what this model excels at
  than "deep reasoning" is.
- **It sharpens the gap.** HX is about to commission a model into a role whose meaning is
  undefined. The Codex runbook independently reached the same place, listing as an unresolved
  owner decision: *"Primary workload and success measures: coding, agentic tool use, research,
  vision/document analysis, or a weighted mix."* Two independent workstreams arriving at the
  same unanswered question is a signal.

**Defining what `Deep reasoning & synthesis` requires is the prerequisite decision.** Without
it, no acceptance test for hxs-1 can be written that means anything — which is exactly the
failure mode the evidence-class model exists to prevent.

### F2 — The model's best capability has nowhere to go

OSWorld-Verified 84.3 makes Qwen3.8-27B the strongest computer-use model in its comparison
table, ahead of Opus 4.6 Max. AndroidWorld 81.9, WebArena-Verified 64.8, Vision2Web 62.9 all
point the same direction.

A full search of the registry's fifteen roles, `fleet-architecture-v0.3.html`, and
`governance/Phase -3-Regroup/tech-stack/` establishes: **HX has no computer-use, GUI-agent, or
browser-control plane.** The three adjacent things are all explicitly scoped away from it:

- **Crawl4AI on hxs-6** is web *scraping*, characterised as "web scraping & cleaning;
  I/O-bound" — not browser control.
- **Granite Docling** is fenced off by explicit ruling: *"It remains inside the Docling service
  boundary and is **not a general-purpose vision endpoint**."*
- The only vision capability HX has measured is incidental — a red-rectangle recognition test on
  hxs-4 recorded in `qwen35-9b-ollama.json` at a **12 MiB** VRAM cost.

**This is informational, not a blocker.** Nothing obliges HX to use every capability a model
has. But an 84.3 OSWorld score is the single most differentiated thing about this model, and
commissioning it without noticing that the fleet cannot consume that capability would be a
missed observation, not a neutral one.

### F3 — The default tag is the MTP variant, and MTP is not free

`qwen3.8:latest`, `qwen3.8:27b`, and `qwen3.8:27b-mtp-q4_K_M` **all resolve to digest
`22130167c4c2`**. The plain `qwen3.8:27b-q4_K_M` is a **different artifact**, digest
`25b843619e94`.

So the transcript's instruction — *"you just run `ollama pull qwen3.8:27b` and that's it"* —
pulls the **multi-token-prediction speculative-decoding build**, not plain Q4_K_M. Both are
18 GB, so size gives no warning.

This matters because of a measurement already in the HX evidence set. The companion
inference-performance record captured, from an independent operator on a 4090: **MTP had to be
disabled to reach high concurrency**, and the 32-agent aggregate figure was obtained with MTP
off. That is the expected trade — speculative decoding spends spare compute to cut
single-stream latency, and batching wants that compute back.

The in-flight Codex runbook independently reached the correct handling: recommend
**`qwen3.8:27b-q4_K_M` (non-MTP) as the baseline**, with the MTP default as *"the first
optimization A/B"*. This record corroborates that from the registry side and adds the reason:
**the two tags are not interchangeable, and the default is the less conservative choice.**

### F4 — `27b-nvfp4` resolves to the MLX artifact — an NVIDIA-named tag pointing at an Apple build

`qwen3.8:27b-mlx` and `qwen3.8:27b-nvfp4` **share digest `5642e97495e1`**, verified on a second
retrieval specifically to rule out a misreading.

NVFP4 is NVIDIA's 4-bit floating-point format for Blackwell-class tensor cores. MLX is Apple's
Silicon framework. **These should not be the same artifact.** Either the registry has a
packaging error, or one tag is an alias placed in error.

For hxs-1 this is a concrete trap: an operator on an NVIDIA host reaching for `27b-nvfp4`
expecting a native FP4 build would get the MLX artifact. And separately — **NVFP4 requires
Blackwell (compute capability 10.0+); hxs-1's Ada cards are 8.9**, so an NVFP4 build would not
be the right target for this host regardless.

**Disposition: do not pull `27b-nvfp4` on hxs-1.** Not because of the digest anomaly alone, but
because neither of the two things it might be is correct for an Ada host. This finding does not
appear in the Codex runbook.

### F5 — Hypothesis H8 is **not** resolved — the registry answers the GGUF channel, not the vLLM channel

This finding was originally written as "H8 is resolved." That was wrong, and the correction
matters more than the original claim did.

**H8 asks specifically about the vLLM channel:** *"A vLLM-compatible 4-bit artifact does **not**
fit the 29.98 GiB budget… Resolve actual **w4a16 / AWQ / GPTQ** manifest byte counts before
download."* The Ollama registry supplies **GGUF Q4_K_M** sizes. Those are different channels, and
the companion record itself supplies the reason they are not interchangeable — HX's own measured
9B artifacts: **GGUF Q4_K_M 6.6 GB against w4a16 10.65 GB, a ratio of 1.61×.**

Extrapolating that measured ratio to the verified 18 GB GGUF artifact:

| Channel | 27B artifact | Headroom against 32.20 GB usable |
|---|---|---|
| GGUF Q4_K_M (**verified**) | 18 GB | **+14.20 GB** for KV |
| vLLM w4a16 (**extrapolated, 1.61×**) | ~29.05 GB | **+3.15 GB** for a preallocated KV pool |

**The vLLM path is roughly 4.5× tighter on KV headroom**, and vLLM preallocates its KV block pool
rather than growing into free memory. **H8 remains open, and this evidence points toward its
stated hypothesis being true.** That materially strengthens — not weakens — the companion
record's runtime caution. Only real w4a16/AWQ/GPTQ manifest byte counts settle it.

#### What the registry *does* resolve: the GGUF sizing

The 18 GB Q4_K_M artifact includes a **461M-parameter BF16 vision projector** (per the Codex
runbook's reading of the manifest) ≈ **0.92 GB**, implying text-only weights ≈ **17.1 GB**.

**This is a consistency check, not three independent confirmations** — a first draft of this
section claimed the latter and it was circular. The 4090 field measurement of 23.5 GiB does not
corroborate the 18 GB weight figure: this document *assumes* weights = 18 GB in order to derive
KV by subtraction, so the same datum cannot both confirm the weights and be the residual computed
from them. And the earlier paper's 16–17 GB was a *text-weights* estimate while 18 GB is the
*full artifact*; 17.08 sits just outside that band. The honest statement is that **the manifest is
consistent with the earlier estimate and does not overturn it.**

<small>All sizes in this section are **decimal GB** — Ollama's registry publishes decimal, and the
MiB/GiB host figures are converted to match. Re-deriving in GiB gives materially different
headroom numbers.</small>

Against hxs-1's **32.20 GB usable** (32,752 MiB aggregate less 2 × 1 GiB CUDA context):

| Tag | Size | Weights-only headroom | Disposition |
|---|---|---|---|
| `27b-q4_K_M` (non-MTP)<sup>†</sup> | 18 GB | **+14.20 GB** | ✅ the viable baseline |
| `27b-q8_0` | 30 GB | +2.20 GB | ⚠️ fits, but almost nothing left for KV |
| `27b-mxfp8` | 32 GB | +0.20 GB | ❌ not viable in practice |
| `27b-bf16` | 56 GB | −23.80 GB | ❌ cannot reside in VRAM |

<small><sup>†</sup> The MTP default tag is the same 18 GB but a **distinct artifact** — see F3.
Listing them on one row would reproduce exactly the conflation F3 exists to prevent.</small>

This corroborates the Codex runbook's independent conclusion: *"Do not begin with Q8 or BF16.
Q8 is 30 GB and BF16 is 56 GB."*

**And 18 GB still does not fit one card** — single-card usable is 16.10 GB. Multi-GPU remains
mandatory, so the unresolved PCIe ×4 link width remains a blocking question.

### F6 — Full native 262K context is plausibly reachable — a possibility no current HX proposal considers

**The functional form matters, and the model card supplies it.** The architecture is
`16 × (3 × (Gated DeltaNet → FFN) → 1 × (Gated Attention → FFN))` — a **3:1 linear-to-full ratio
with 16 full-attention layers**. Only the Gated Attention layers grow with context; the DeltaNet
recurrent state is constant. KV is therefore **affine**, `KV(C) = aC + b`, not a power law. Fitting
HX's measured 9B datum (KV × 12 across a × 16 context increase) to the affine form gives
`b = (4/11)aC`, so **doubling context multiplies KV by 26/15 = 1.733** — not the 1.861 a power-law
fit would give. *(A first draft used the power law; it overestimates KV by 7.4%, which is
conservative in direction but wrong in form.)*

Deriving from the 4090 field measurement — 23.5 GiB total at 131K context, implying **~7.23 GB of
KV** if the weights were 18 GB:

| Context | KV (fp16) | Total | Headroom | KV @ `q8_0` | Total | Headroom |
|---|---|---|---|---|---|---|
| 131,072 | 7.23 GB | 25.23 GB | **+6.96 GB** | 3.84 GB | 21.84 GB | +10.35 GB |
| **262,144** (native) | 12.54 GB | 30.54 GB | **+1.66 GB** | 6.66 GB | **24.66 GB** | **+7.54 GB** |

<small>`q8_0` KV is taken at **0.53125×** fp16, not 0.5× — llama.cpp's q8_0 block is 32 int8 values
plus one fp16 scale, 34 bytes per 32. Ollama's own documentation describes q8_0 as "approximately
1/2 the memory of f16", so this is a refinement, not a disagreement. The constant DeltaNet state
may not be quantized at all, which would make even 0.53125× optimistic.</small>

#### The dominant uncertainty is not the arithmetic — it is the source datum

The companion record flags limitation **L2** on exactly the number this entire derivation rests
on: *"The 23.5 GiB figure is stated adjacent to the 3-bit discussion and its tier is not
unambiguous. The single most important number carries a tier ambiguity."* **A first draft of this
section hedged generically without naming that error term. That was the same stale-claim failure
this document criticises in C2**, so it is named here explicitly.

| If the 23.5 GiB run was… | implied weights | KV @ 131K | 262K fp16 | 262K @ `q8_0` |
|---|---|---|---|---|
| **4-bit** (assumed above) | 18 GB | 7.23 GB | 30.54 GB — **+1.66** | 24.66 GB — **+7.54** |
| **3-bit** (L2 branch) | ~14.1 GB | **11.15 GB** | 33.42 GB — **−1.22 OVER** | 24.37 GB — **+7.83** |

**The two branches disagree on the headline conclusion.** Under the 4-bit reading, 262K fp16 is
marginal and `q8_0` is comfortable. Under the 3-bit reading, **262K fp16 does not fit at all** and
even `q8_0` is tight. 131K fits under both.

**Conclusion, appropriately hedged:** 131K context is well-supported under every branch. Anything
beyond it is **NOT ESTABLISHED** and depends on a source figure whose quantization tier is
unresolved. This is a hypothesis for the commissioning ladder, not a result — **KV must be
measured, never estimated**, and the fit gate is right to refuse.

**A prerequisite neither the transcript nor a first draft of this section stated:** Ollama's
documentation makes KV quantization conditional — *"The K/V context cache can be quantized… **when
Flash Attention is enabled**."* Setting `OLLAMA_KV_CACHE_TYPE=q8_0` without `OLLAMA_FLASH_ATTENTION=1`
means the entire `q8_0` column above silently does not happen. The Codex runbook sets both; any
HX configuration must.

This matters because both current proposals aim far lower. The Codex runbook proposes
**`OLLAMA_CONTEXT_LENGTH=32768`** with 64K as the next target. The transcript urges the
opposite — *"push it as high as your memory will allow… if you run it in a tiny window you have
essentially bought a sports car and left it in first gear."*

**The derivation suggests both current proposals are conservative** — 131K is supported under
every branch above, against the 32K they target — while stopping well short of endorsing the
transcript's "as high as your memory will allow." The right posture is a measured ladder that
does not stop at 64K, with `OLLAMA_FLASH_ATTENTION=1` and `OLLAMA_KV_CACHE_TYPE=q8_0` treated as
paired variables rather than fallbacks.

### F7 — Ollama's default context on hxs-1 is 32K, not 4K — the transcript's headline warning is miscalibrated for this host

The transcript's most emphatic operational warning is that Ollama silently uses a small default
context. Ollama's documentation gives the actual behaviour as VRAM-tiered:

| VRAM | Default context |
|---|---|
| < 24 GiB | **4K** |
| 24–48 GiB | **32K** |
| 48+ GiB | **256K** |

hxs-1 has **31.98 GiB aggregate**, landing it in the 32K band. HX's own workload record captured
the low tier — *"systems under 24 GiB VRAM default to 4K"* — which is why hxs-4's 8 GB card
behaved as it did.

Two consequences. The 4K catastrophe the transcript warns about **does not apply to hxs-1**. And
the Codex runbook's proposed `OLLAMA_CONTEXT_LENGTH=32768` is **not a tightening — it is pinning
the value the host would default to anyway**, which is good practice (explicit beats implicit)
but should be understood as a floor rather than a considered ceiling.

**Caveat, flagged rather than assumed:** whether the tier is evaluated against *aggregate* VRAM
across both cards or *per-device* is not stated in the documentation. If per-device, each 15.99
GiB card falls in the < 24 GiB band and the default would be **4K after all**. This is cheap to
settle at commissioning with `ollama ps`, and it should be settled rather than assumed.

### F8 — No HX record anywhere specifies sampler settings, and this model ships two regimes

An exhaustive search of `tests/ai-runtime/` (including all 17 fixtures, the acceptance suite,
both profiles, and the hxs-4 workload record), all of `governance/`, and the registry for
`temperature`, `top_p`, `top_k`, `min_p`, `presence_penalty`, `repetition_penalty`, and `seed`
returns: **no HX record specifies sampler settings for any model, on any host, at any point.**
The acceptance harness sends no generation options at all. The Codex deployment runbook contains
none either.

The official model card specifies two distinct regimes:

| Parameter | **Thinking mode** | **Non-thinking / instruct** |
|---|---|---|
| `temperature` | 1.0 | 0.7 |
| `top_p` | 0.95 | 0.80 |
| `top_k` | 20 | 20 |
| `min_p` | 0.0 | 0.0 |
| `presence_penalty` | 0.0 | **1.5** |
| `repetition_penalty` | 1.0 | 1.0 |

The transcript's judgement on this is worth quoting because it is the one place its operator
experience adds something the vendor docs do not: *"please do set them, because the default
sampler settings will make this model look noticeably worse than it actually is, and then you'll
blame the model."*

**This is the cheapest quality intervention available and nobody currently has it.** It costs
one configuration block. Left unset, any future HX evaluation of this model risks measuring the
sampler rather than the model — which would corrupt exactly the class-B evidence the acceptance
contract exists to produce.

**The reasoning-effort default is the more consequential omission.** The model card records three
levels — **`xhigh` (default)**, `medium`, `low` — and the default is *the most expensive one*. On a
host with single-digit GB of KV headroom and a fleet-serving role, silently defaulting to maximum
reasoning effort multiplies latency and context burn on every request. The companion
inference-performance record measured exactly this: a single-prompt task consuming ~120,000 tokens
over 7–8 minutes at maximum effort. **This belongs in the workload definition explicitly, not left
to a vendor default.**

One further note: the model card records a **`preserve_thinking` flag, default `True`**, which
retains reasoning context across conversation turns. For multi-step agentic work — which is
what this model is good at — that is likely load-bearing and should be explicit in any
configuration rather than left to a default that could change.

### F9 — The transcript's own scoping caveat argues *against* its recommendation for HX

The transcript reverses its author's prior advice, moving from vLLM to Ollama/LM Studio. Read
carelessly, that is support for Ollama on hxs-1. Read carefully, **it is the opposite**, because
the author scopes the reversal explicitly:

> *"vLLM is great if you have a proper multi-GPU box and you're serving a team. But if you're
> one person on one machine trying to run an agent, vLLM is a lot of setup…"*

and closes:

> *"If you're serving a team off a multi-GPU box, sure, go do that. But for one person on one
> machine, it's just extra work for the same result."*

**hxs-1 is a two-GPU server intended to serve a fifteen-server fleet.** It is not the
single-user, single-machine case the reversal is scoped to.

The defensible conclusion — and no more than this — is that **this transcript does not support
Ollama for HX's deployment shape and must not be cited as if it did.** A first draft went
further and said it "points to vLLM"; that overshoots. The author's "sure, go do that" is
permissive, not a positive indication, and two premises are shaky in any case: a fleet of
*servers* is not obviously the author's "serving a team" of humans, and two consumer cards behind
a ×4 link may not be the "proper multi-GPU box" they have in mind.

That does **not** settle the runtime question — the companion record's countervailing evidence
stands unchanged: the ×4 link penalises TP=2, vLLM w4a16 artifacts run larger than GGUF, and
vLLM fails to start rather than degrading. But it does remove this transcript from the column of
evidence supporting Ollama for HX, where a casual reading would have placed it.

**This is a case where the source's headline and the source's applicability to HX point in
opposite directions.** Recording it because the naive citation would have been wrong.

### F10 — The `--jinja` claim is outdated

The transcript states that running llama.cpp directly requires *"the `--jinja` flag on
llama-server for tool calling to work at all."*

Current llama.cpp server documentation lists: `--jinja, --no-jinja | whether to use jinja
template engine for chat (**default: enabled**)`. The flag was historically required when the
Jinja path defaulted off; **it no longer is.**

Low impact — HX would not run llama.cpp directly — but it is a claim that would have propagated
into a runbook as a required flag, and it is wrong. Recorded for that reason.

### F11 — `iss-015`'s scope against the OpenAI-compatible endpoint is unestablished, and it matters

`iss-015` (open) records that Ollama silently truncates prompts exceeding the context window,
collapsing to 32,770 tokens rather than erroring. The companion record captured the root cause
found in source: **the Anthropic adapter constructs an `api.ChatRequest` that never sets
`Truncate`, and the chat handler defaults it true.**

The transcript's entire integration story runs over the **OpenAI-compatible endpoint** at
`:11434/v1`. Whether that path shares the defect, or whether it was specific to the Anthropic
adapter, **is NOT ESTABLISHED** by any evidence in this document or in the HX record.

This is materially important in both directions. If the OpenAI path does not truncate silently,
one of the strongest arguments for vLLM over Ollama weakens considerably. If it does, then the
defect is systemic and `iss-015` should be restated in engine-general terms rather than
adapter-specific ones.

**Settling this is cheap** — it requires reading the OpenAI handler in the already-vendored
`ollama-main` source tree, with no host access and no network. It may be the highest
value-per-effort open item in the whole Qwen3.8 workstream.

---

## 6. Contradictions and conflicts discovered

### C1 — Two same-day proposals assign different storage paths

| Document | Proposed model store |
|---|---|
| `codex_20260817_1524_...deployment-deep-dive.html` | **`/srv/hx-ai/models/ollama`** |
| `hx-research_hxs1-model-storage-architecture_synthesis_2026-08-17_claude-opus-5` | **`/srv/hx/models/ollama`** |

Both are dated 2026-08-17, both are unratified proposals, and both are mine to disclose — the
second is my own. **Neither is authority, and they must not both be implemented.**

**The conflict is deeper than the path string, in two ways a first draft understated.**

1. **The partition plans are contradictory, not merely different.** Codex proposes capacity
   partitioning — 1 TB for inference, 2 TB if adaptation is pursued. The storage record specifies
   *"GPT label, **single partition spanning the device**"*. These are mutually exclusive layouts,
   not one plan plus an addition.
2. **The mount point propagates.** `/srv/hx/models` in the storage record is not a bare path — it
   is a mount point with dependents: two fstab UUID entries, `/srv/hx/archive` for the SMR drive,
   `RequiresMountsFor=` in the systemd drop-in, the `chattr +i` bare-mountpoint procedure,
   `OLLAMA_MODELS`, and `HF_HOME`/`HF_HUB_CACHE`. Changing it touches all of them.

**Recommendation: adopt the Codex `/srv/hx-ai` path and its partition plan** unless the owner
prefers otherwise — because it is embedded in a fuller deployment plan with agent ownership
assigned, and because the naming distinguishes the AI platform from generic HX data. *(Both were
authored the same day, so precedence carries no weight here.)*

What survives the choice: the storage record's *device-level* findings — the SMR disqualification,
serial-based device resolution, the `nofail` second-order hazard, `-m 0 -T largefile`, and the
in-place download behaviour — are genuinely path-independent. Its *mount architecture* is not.

### C2 — hxs-4 vision testing: the record contradicts itself

`governance/logs/actions-and-issues.md` `act-014` states *"vision was **not** tested and would
add unmeasured VRAM"*, and the commissioning report's footer agrees. But
`tests/ai-runtime/workloads/qwen35-9b-ollama.json` carries a `vision_as_built` block:
`"status": "TESTED AND WORKING"`, `"vram_cost_mib": 12`, concluding *"Vision does NOT break
full-GPU residency."*

The workload JSON is the later record and explicitly flags itself as superseding. **The log and
the commissioning report are stale on this point** and should be corrected — it is a small
correction, but `ll-030` in the lessons register is precisely about stale claims propagating
into everything that reads them afterwards.

This is directly relevant here: Qwen3.8-27B is a native VL model with a 461M vision projector,
and the question "does vision cost meaningful VRAM" is one HX has already answered once.

### C4 — The fleet architecture's fit premise rests on a figure now known to be 29% low

`fleet-architecture-v0.3.html` justifies the hxs-1 placement with the cell
**`TP = 2, 4-bit, ~14 GB weights + KV` → `fits`**. §4 establishes the actual Q4_K_M artifact is
**18 GB** — **29% larger** than the number that "fits" verdict was computed against.

The outcome does not change: 18 GB still fits 32.20 GB usable, with 14.20 GB left for KV. **The
margin does.** And under the repository's own `ll-030` — *"comparative claims rot as records are
added"* — a stale load-bearing figure should be corrected rather than re-quoted, which is what
F1 above does when it cites the same cell as evidence of hardware-driven reasoning.

*Disclosure: this document quoted that cell twice before noticing its own §4 had invalidated it.*

### C3 — HX's practised digest standard is weaker than its own invariant requires

`hx-runtime-invariants.tests.ps1` asserts that *"model identity and checksum are required before
OPERATIONAL"*, and `hx-workload-commission.ps1` fails with `'model acquired but no checksum
recorded'` when `checksum_sha256` is absent. Yet `qwen35-9b-ollama.json` — the only workload
record that exists — **has no `checksum_sha256` field at all.** The invariant passes because it
greps the driver *source* for the string rather than checking the data exists.

HX's practised standard is therefore **short display digest + upstream byte count**, not a
cryptographic artifact lock. The Codex runbook independently flags this: *"The website's
`25b843619e94` is a short display ID, **not sufficient as the only immutable lock**."*

Given F3 and F4 — where tag-to-artifact mapping is genuinely surprising in two separate ways —
**recording full blob SHA-256 identities for whatever is pulled onto hxs-1 is the correct
standard**, and the existing invariant already claims to require it.

---

## 7. Recommendations

Six, ordered. Each states what it resolves and what it deliberately does not.

**Scope note:** R2 and R5 are Ollama-specific and assume an Ollama evaluation track is
authorized. They do **not** presuppose that Ollama wins the runtime question — §8 preserves the
`vllm-qwen remains PRIMARY` invariant, and F5 now points toward the vLLM channel being tighter
than assumed rather than looser. Read them as "if and when an Ollama track is authorized".

### R1 — Define what `Deep reasoning & synthesis` requires, before commissioning anything

**Do:** record, in `SERVER-REGISTRY.md` or a policy document, what capability the hxs-1 role
demands and how it will be demonstrated.
**Why:** F1 establishes no such definition exists. Both this record and the Codex runbook
arrived independently at the same unanswered question.
**Resolves:** makes an hxs-1 acceptance test meaningful; converts an implicit assumption into a
recorded owner decision.
**Does not resolve:** whether Qwen3.8-27B is the right occupant — that follows from the
definition, not the other way round.
**Owner decision. Not delegable** — the registry forbids agents assigning roles or selecting
workloads.
**Reversal criteria:** revisit if the fleet gains a computer-use plane, which would change what
this model is best used for.

### R2 — Pin the artifact by full digest, and pull the non-MTP tag

**Do:** baseline on **`qwen3.8:27b-q4_K_M`** (digest `25b843619e94`), never bare `qwen3.8:27b`.
Record the complete local manifest and all blob SHA-256 identities, not the short display ID.
Treat the MTP default as a later A/B.
**Why:** F3 — the default is a different artifact; F4 — tag naming is demonstrably unreliable in
this repository; C3 — HX's invariant already claims to require a checksum it has never had.
**Resolves:** artifact ambiguity and the MTP-under-concurrency question becoming a confound.
**Does not resolve:** whether MTP is beneficial for HX's traffic shape — that needs the A/B.
**Corroborates** the Codex runbook rather than competing with it.

### R3 — Establish sampler settings as a recorded configuration artifact

**Do:** record both official regimes (§F8) in the hxs-1 workload definition, and set them
explicitly at serving time. Include `preserve_thinking` and the reasoning-effort level.
**Why:** F8 — zero prior art anywhere in HX, and default samplers will make the model measure
worse than it is.
**Resolves:** prevents future class-B evidence from measuring the sampler instead of the model.
**Does not resolve:** which reasoning-effort level suits which workload — that is a measurement.
**Prerequisite:** none. Repository-side, no host access. **Cheapest item on this list.**

### R4 — Settle `iss-015`'s scope by reading the vendored source

**Do:** read the OpenAI-compatible handler in `governance/operations/ollama/ollama-main` and
determine whether the `Truncate` defect is adapter-specific or engine-wide.
**Why:** F11 — it is unestablished, it is cheap, and it materially moves the runtime argument.
**Resolves:** either weakens a principal argument for vLLM, or promotes `iss-015` from an
adapter defect to an engine property.
**Does not resolve:** the runtime decision itself, which also turns on the ×4 link and artifact
sizing.
**Prerequisite:** none — the source is already in the repository. No host, no network.

### R5 — Carry the context question into the commissioning ladder rather than settling it on paper


**Do:** extend the planned context ladder past 64K, and test `OLLAMA_FLASH_ATTENTION=1` +
`OLLAMA_KV_CACHE_TYPE=q8_0` together (Ollama gates KV quantization on flash attention) as a
first-class variable rather than a fallback. Confirm at commissioning whether Ollama's VRAM
tiering reads aggregate or per-device.
**Why:** F6 suggests the full 262K native context may be reachable with quantized KV — well
beyond the 32K/64K both current proposals target. F7 shows the default-context hazard is
miscalibrated for this host in one direction and possibly understated in the other.
**Resolves:** whether hxs-1 can actually exploit the model's headline capability.
**Does not resolve:** anything on paper. **KV must be measured, never estimated** — the fit gate
is right to refuse, and §F6's arithmetic is a hypothesis for it to test, not a result.

### R6 — Choose one model-store mount architecture

**Do:** pick `/srv/hx-ai` (Codex) or `/srv/hx` (storage record), and with it one partition plan —
capacity-split or single-partition. Record the choice before any partitioning.
**Why:** C1 — two same-day unratified proposals specify mutually exclusive layouts.
**Resolves:** prevents two runbooks diverging at implementation time.
**Does not resolve:** the device-level storage findings, which hold either way.
**Owner decision**, but a cheap one. **Must precede** any storage mutation.

---

## 8. Explicitly not recommended

- **Do not treat this record as grounds to break the `vllm-qwen remains PRIMARY` invariant.**
  F9 shows this source cannot be cited in support of Ollama for HX's deployment shape, and F5
  now shows the vLLM artifact question is *more* open than previously recorded, not less.
- **Do not pull `qwen3.8:27b-nvfp4` on hxs-1** — F4. Neither of the two things it might be is
  correct for Ada.
- **Do not begin on Q8 or BF16** — F5, corroborating the Codex runbook.
- **Do not reopen the storage design** — C1 needs a path choice, not a redesign. The technical
  findings are path-independent.
- **Do not treat the OSWorld result as a reason to build a computer-use plane.** F2 is an
  observation about capability going unused, not an argument for new architecture.

---

## 9. Remaining verification and owner decisions

| # | Item | Type | Cost |
|---|---|---|---|
| V1 | Does the OpenAI `/v1` path share `iss-015`'s truncation defect? | Verification | Read vendored source — free |
| V2 | Is Ollama's VRAM context tiering aggregate or per-device? | Verification | One `ollama ps` at commissioning |
| V3 | Full blob SHA-256 for the chosen artifact | Verification | At pull time |
| V4 | Is GPU1's ×4 physical or a reporting artifact? | Verification | `sudo lspci -vvs`, carried from prior records |
| V5 | The `27b-nvfp4` / `27b-mlx` shared digest — which name is the mislabel? | Verification | Upstream to fix, but HX must not pull the tag either way |
| V6 | Real w4a16 / AWQ / GPTQ manifest byte counts for the 27B — **H8, still open** | Verification | No host access; the single cheapest decision-relevant test |
| D1 | What does `Deep reasoning & synthesis` require? | **Owner decision** | Not delegable |
| D2 | `/srv/hx-ai` or `/srv/hx`, and which partition plan? | **Owner decision** | Mechanical, but propagates into fstab, the systemd unit, and the Ollama/HF environment — decide before partitioning, not after |
| D3 | Is a computer-use / GUI-agent plane wanted at all? | **Owner decision** | Architectural |
| D4 | Implementation-phase authorization for hxs-1 | **Owner decision** | Gates everything |

Two stale records to correct as Phase 3 documentation work: **C2** (hxs-4 vision testing) and
the `hx-gpu-fit.ps1` compute-capability floor recorded in the companion CUDA record.

---

## 10. Provenance

**Vendor primary — retrieved 2026-08-17**
- Qwen3.8-27B official model card — benchmark tables, sampler regimes, reasoning-effort levels,
  `enable_thinking` / `preserve_thinking`, architecture, context.
  <https://huggingface.co/Qwen/Qwen3.8-27B>
- Ollama library, Qwen3.8 tags — twelve tags with sizes and short digests; retrieved twice, the
  second time specifically to confirm the `-mlx` / `-nvfp4` digest collision.
  <https://ollama.com/library/qwen3.8/tags>
- Ollama context-length documentation — VRAM-tiered defaults.
  <https://docs.ollama.com/context-length>
- llama.cpp server documentation — `--jinja` default state.
  <https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md>

**HX primary**
`SERVER-REGISTRY.md` · `servers/hxs-1/discovery.md` ·
`tests/ai-runtime/workloads/qwen35-9b-ollama.json` ·
`tests/ai-runtime/hx-runtime-invariants.tests.ps1` · `tests/ai-runtime/hx-workload-commission.ps1` ·
`governance/logs/actions-and-issues.md` (`act-014`, `iss-013`, `iss-014`, `iss-015`, `iss-016`)

**HX design / in-flight**
`governance/operations/ollama/codex_20260817_1524_hx-qwen38-27b-ollama-deployment-deep-dive.html` ·
`governance/fleet-architecture-v0.3.html` · `governance/hx-stack-alignment-v0.1-frozen.html` ·
`governance/hx-validation-findings.html` · `governance/hx-recommendations.html` (R8) ·
`governance/operations/ollama/craig-ollama-specialist.md` ·
`governance/operations/docling/hx-granite-docling-reconnaissance-report_chatgpt-gpt-5-6_20260815_0305.html`

**Companion research records** (same directory)
`hx-research_qwen38-27b-inference-performance_third-party_2026-08-17_claude-opus-5` ·
`hx-research_cuda-driver-runtime-requirements-hxs1_vendor_2026-08-17_claude-opus-5` ·
`hx-research_hxs1-model-storage-architecture_synthesis_2026-08-17_claude-opus-5`

**Third-party trigger source**
Independent operator video review, transcript supplied by project owner 2026-08-17.
**Advertising segment at 1:38–3:45 excluded in full.** Two benchmark claims from this source
("Qwen's WebBench", "DeepSWE 1.1") were initially flagged unverifiable; per the §3 correction both
are verified exact model-card values and are included in the conclusions.

**Derived**
Memory arithmetic in §F5 and §F6 is derived from vendor manifest sizes, the 461M BF16 vision
projector figure, the 4090 field measurement, and HX's own measured hybrid-attention KV
scaling. It is **derived, not measured on hxs-1**, and no figure in it should be quoted as an
HX measurement.

---

*Prepared by Claude (Opus 5), 2026-08-17. Research record — no authority asserted, no decision
made, no acceptance granted, no role assigned. Per repository convention, a proposal is not a
ruling.*
