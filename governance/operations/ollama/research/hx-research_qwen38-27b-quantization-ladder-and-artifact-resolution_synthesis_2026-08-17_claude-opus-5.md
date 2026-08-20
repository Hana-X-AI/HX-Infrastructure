# Qwen3.8-27B — Quantization Ladder, Artifact Resolution, and the Collapse of the Fit Argument

| | |
|---|---|
| **Document ID** | `hx-research_qwen38-27b-quantization-ladder-and-artifact-resolution_synthesis_2026-08-17_claude-opus-5` |
| **Subject** | Full quantization ladder resolved against hxs-1's aggregate budget; real vLLM artifact manifests; MTP acceptance on hybrid attention; benchmark provenance |
| **Evidence tier** | `synthesis` — third-party transcript (trigger) reconciled against **vendor primary** (HuggingFace manifest byte counts, llama.cpp issue tracker, Qwen model card) and **HX primary** |
| **Author** | Claude (Opus 5) |
| **Date** | 2026-08-17 |
| **Status** | Research record. **Not a decision, not an acceptance, not an authorization.** |
| **Corrects** | `hx-research_qwen38-27b-inference-performance_third-party_...` (H8 framing) and `hx-research_qwen38-27b-ollama-serving-and-capability-fit_synthesis_...` (F5 extrapolation, benchmark weighting). **This is the fifth and final record in the series.** |

---

## 1. Verdict

**Hypothesis H8 is resolved, and it resolves against the position the previous records were
building.** The memory-fit argument for preferring Ollama over vLLM on hxs-1 does not survive
contact with real manifest data, and is withdrawn.

I extrapolated the vLLM w4a16 artifact at **~29 GB**, using HX's own measured 9B ratio of 1.61×.
The actual best-case Ada-compatible W4A16 build of Qwen3.8-27B is **18.60 GB** — my extrapolation
was **56% too high**. Against the GGUF path at 18.04 GB (Q4_K_M plus the vision projector), the
gap is **0.57 GB, or 3.1%** — 1.42 GB and 7.8% once the separately-shipped MTP module is counted
on both sides. Either way it is far too small to carry a runtime decision.

**The runtime decision must now be made on other grounds** — silent truncation (`iss-015`),
continuous batching, authentication, the unmeasured PCIe ×4 link, and operational fit. Every one
of those was already on the table. The differentiator that appeared to favour Ollama on hard
numbers is no longer decisive on its own.

One qualification kept out of the headline because it is real: **the two paths are not charged
symmetrically.** vLLM's fixed per-process cost (CUDA graphs, NCCL buffers, activation workspace)
is higher, and F8 shows its default `gpu_memory_utilization=0.90` delivers roughly **10.8 GB** of
KV rather than the 13.6 GB the raw budget implies. The fit gap narrows from ~4.5× to under 1.5 GB;
it does not vanish, and it must be re-checked at the actual utilization setting.

Two further corrections follow. **Every benchmark figure in the series — including the Opus 4.6
Max comparison column — is vendor self-reported, and no independent reproduction of the headline
table exists.** Record 4 weighted the model card as "vendor primary — load-bearing." That was
right about the source and wrong about what it licenses. And **hxs-1's aggregate budget reaches
above the consumer quantization ladder**: Q6_K plus its projector lands at 23.82 GB, leaving
8.38 GB nominal for KV — a tier no single-card consumer machine reaches. But **Ollama's library
ships no Q6_K tag**, so reaching it means importing a GGUF rather than pulling one; and F2 shows
the per-card split leaves materially less usable KV than the aggregate figure suggests.

The transcript that triggered this record is the most numerically accurate of the three field
reports: **thirteen of thirteen file-size and percentage claims verified exact.** Its two failures
are both claims about what does *not* exist, and both are wrong.

---

## 2. The correction, stated plainly

### 2.1 What I got wrong, and why

Record 1 (hypothesis H8) correctly identified the vLLM artifact size as the cheapest
decision-relevant unknown and said to *resolve real manifest byte counts*. Record 4 then did the
opposite: it **extrapolated** from HX's measured 9B ratio instead of resolving the 27B manifests,
and presented the result as a finding.

| | Figure | Source |
|---|---|---|
| Record 4 extrapolation | ~29.05 GB | 18 GB GGUF × 1.61 (HX's measured 9B w4a16 / GGUF ratio) |
| **Actual** | **18.60 GB** | `dbirks/Qwen3.8-27B-W4A16-AutoRound`, 18,603,379,616 bytes |
| Error | **+10.45 GB, 56% high** | |

**Why the ratio failed:** HX's 9B measurement compared a w4a16 repo shipping the full vision tower
at BF16 against a GGUF whose *resident* footprint excluded the vision encoder. On a 27B base the
same absolute vision tower (**≈0.93 GB** — see F6) is a far smaller proportional inflation, and the
quantization recipes differ. **Artifact-size ratios do not transfer across model scales.**

<small>A residual inconsistency between the companion records, inherited here: record 1 cites the
hxs-4 9B GGUF at **5.29 GB** (implying a ~2× w4a16 ratio) while record 4 cites **6.6 GB** (1.61×).
The HX workload record gives 6,594,474,236 bytes, so 6.6 GB and 1.61× are correct; record 1's
5.29 GB figure is unsourced against the HX record and should be corrected there.</small>

The repository already had the correct instruction, and I did not follow it:

> *"Always resolve the real file size in the channel you will actually deploy from."*

**Recording this rather than quietly amending it.** A research series that corrects its own load-
bearing claim is worth more than one that appears consistent.

### 2.2 What the correction changes

| Claim, records 1 & 4 | Status |
|---|---|
| "A 27B w4a16 artifact plausibly exceeds the aggregate budget" | ❌ **Refuted.** 18.60 GB against 32.20 GB usable |
| "The vLLM path is ~4.5× tighter on KV headroom" | ❌ **Refuted.** 13.59 GB vs 14.16 GB — a 4% difference |
| "This evidence materially strengthens the case that Ollama is the runtime that *fits*" | ❌ **Withdrawn.** Both fit comfortably |
| "vLLM preallocates and fails to start rather than degrading" | ✅ **Stands**, and matters more than the raw budget suggests — see F8: the default utilization setting yields ~10.8 GB, not 13.6 GB |
| "iss-015: Ollama silently truncates; vLLM errors explicitly" | ✅ **Stands, and is now the strongest remaining differentiator** |
| "The ×4 link penalises TP=2" | ✅ **Stands, and is now the decisive open question** |

---

## 3. The artifact ladder, resolved against hxs-1

hxs-1 usable: **32.20 GB decimal** (32,752 MiB aggregate less 2 × 1 GiB CUDA context). All sizes
below are **exact manifest byte counts** in decimal GB retrieved from the HuggingFace API on
2026-08-17 — **except the two Ollama rows, which are the registry's rounded display strings**;
exact Ollama blob byte counts were not retrieved and are listed as V3 below. HuggingFace file
listings publish decimal GB; Ollama's registry does too.

### 3.1 GGUF path

| Artifact | Weights | + projector (0.931 GB) | KV room |
|---|---|---|---|
| Unsloth BF16 | 54.66 | 55.59 | **−23.39 ❌ OVER** |
| bartowski Q6_K | 23.46 | 24.39 | +7.80 |
| **Unsloth Q6_K** | **22.88** | **23.82** | **+8.38** |
| ggml-org Q4_K_M | 18.97 | 19.91 | +12.29 |
| **Ollama `27b-q4_K_M`** (projector included) | **18.00** | — | **+14.20** |
| Unsloth UD-Q4_K_XL | 17.92 | 18.85 | +13.34 |
| Unsloth Q4_K_M | 17.11 | 18.04 | +14.16 |
| lmstudio-community / mradermacher Q4_K_M | 16.81 | 17.74 | +14.45 |
| Unsloth IQ4_XS | 15.71 | 16.64 | +15.56 |
| Unsloth UD-IQ3_XXS | 11.91 | 12.84 | +19.35 |
| Ollama `27b-q8_0` | 30.00 | — | +2.20 |

**Nominal quant names are not portable between publishers.** "Q4_K_M" spans **16.81 → 18.97 GB**
depending on who built it — a 2.16 GB spread on the same label. Ollama's 18 GB sits inside that
range. Any HX artifact record must name the publisher and pin the digest, not the quant label.

### 3.2 vLLM path — Ada-compatible builds only

**Accounting basis, stated because it changes the headline:** all rows **exclude** the
separately-shipped MTP module (≈0.85 GB). Including it adds ~0.85 GB to every W4A16 row and widens
the §3.3 gap to **1.42 GB (7.8%)**. This matters because record 4's F3 established that Ollama's
*default* tag is the MTP variant — so on a like-for-like basis the GGUF side ships MTP and the
vLLM side, as tabulated, does not.

| Artifact | Weights (vision incl., MTP excl.) | KV room | `--language-model-only` |
|---|---|---|---|
| **`dbirks/…-W4A16-AutoRound`** | **18.60** | **+13.59** | +14.52 |
| `philbert440/…-W4A16-AWQ` | 18.70 | +13.50 | +14.43 |
| `Vishva007/…-W4A16-AutoRound-GPTQ` | 19.19 | +13.01 | — |
| `amd/…-Quark-AWQ-INT4-W4A16` | 19.51 | +12.68 | — |
| `btbtyler09/…-GPTQ-4bit` | 20.14 | +12.06 | — |
| `cyankiwi/…-AWQ-INT4` | 21.02 | +11.18 | — |
| `Qwen/Qwen3.8-27B-FP8` | 30.39 | +1.81 | ❌ vLLM would fail to start |

**Ruled out on architecture, not size:** `amd/…-MXFP4` — vLLM's own recipe page states the MXFP4
linear method is missing on NVIDIA, so it is broken on *all* NVIDIA hardware, not just Ada.
`dsikka/…-NVFP4-FP8` — NVFP4 requires Blackwell (compute capability 10.0+); hxs-1's Ada cards are
8.9. This independently corroborates record 4's F4 disposition from a second direction.

**`RedHatAI/Qwen3.8-27B-quantized.w4a16` does not exist.** Only `RedHatAI/Qwen3-8B-quantized.w4a16`
— a different, 8-billion-parameter model. Worth recording because the naming collision is an easy
trap, and HX's own hxs-4 workload record cites a RedHatAI w4a16 repo for the 9B.

### 3.3 The two paths converge

```
GGUF  Q4_K_M + projector   18.038 GB   →  +14.16 GB KV room
vLLM  W4A16 (dbirks)       18.603 GB   →  +13.59 GB KV room
                            ──────
gap                          0.566 GB   =  3.1%   (MTP-exclusive basis)
                             1.415 GB   =  7.8%   (MTP-inclusive basis)
```

Corroborating datum, with its qualifier: `dbirks/…-W4A16-AutoRound` is the checkpoint in a public
deployment running **150K context on a single 24 GB RTX 3090** with an fp8 KV pool — **but that
deployment applies an additional int8 requantization to the embedding matrices.** The published
18.60 GB artifact did not fit 24 GB at 150K; a further-shrunk derivative did. The comparison still
favours hxs-1's 32 GB across two cards, but it is not the clean proof it first appears.

---

## 4. Findings

### F1 — Benchmark provenance: every number is vendor-run, and none has been reproduced

The transcript makes a methodological point the previous records understated:

> *"Every benchmark number came off Qwen's own model card, including the Opus column beside it.
> Qwen ran both sides of that table."*

This is verified from the vendor's own words — **the model card labels `QwenSWEBench` an
"in-house coding benchmark"**, and it sits in the comparison table scoring Qwen3.8-27B at 79.0
against Opus 4.6 Max's 63.8. A third-party analysis reaches the same conclusion: *"These are
Alibaba's own model-card numbers, not independent replications."*

**Scope the claim precisely:** no independent reproduction of the **headline benchmark table**
exists. That is not the same as no non-vendor data of any kind — community leaderboard tracking
for the family does exist. The claim is about the table, not the model.

**This is not an accusation.** Publishing self-run comparisons is standard industry practice, and
Qwen's table is unusually honest — it records four losses, including HLE at 30.8 against Opus's
40.0. The transcript's framing is right: *"the losses are what make the wins believable."*

**But it changes the evidence class.** Record 4 tabled the model card as *"vendor primary —
load-bearing."* That is correct about *what Qwen claims* and wrong about what it licenses. Under
HX's own acceptance contract these are **class B — model behaviour — and class B is not provable
offline**, still less by the vendor's own harness. The correct weighting:

| Claim type | Status |
|---|---|
| "Qwen states Qwen3.8-27B scores 61.7 on SWE-bench Pro" | **Verified fact about the model card** |
| "Qwen3.8-27B scores 61.7 on SWE-bench Pro" | **Vendor self-report, unreproduced** |
| "Qwen3.8-27B beats Opus 4.6 Max on agentic coding" | **NOT ESTABLISHED** by any independent source |

**Consequence for record 4's F1/F2.** The role-fit finding — that this model is weak on frontier
reasoning and strong on computer use — rests entirely on this table. The *direction* is
corroborated by the model card recording its own losses, and by the qualitative field reports. The
*magnitudes* are provisional. Record 4's finding should be read as **"the vendor's own evidence
points this way"**, not **"this is measured."**

**The remedy is available and cheap:** the weights are Apache 2.0. HX has hxs-15 assigned to
`Test & integration — QA, regression, integration testing, benchmarks`. **A fleet that wants an
independent number can produce one**, which is more than most organizations evaluating this model
can say.

### F2 — hxs-1 sits above the consumer quantization ladder, but Ollama's library does not reach the tier

The transcript's central structure is a VRAM ladder — 24 / 17 / 16 / 12 / 8 GB — with the 16 GB
rung as "the trap": standard Q4_K_M at 17.11 GB against a card holding 17.18 GB, fitting by
**73 MB** before the KV cache is allocated at all.

**None of that applies to hxs-1 the way it applies to a consumer machine.** Under layer split the
budget is aggregate, 32.20 GB usable — above the transcript's top rung. The consequence is that
**Q6_K becomes reachable**: 22.88 GB plus the 0.931 GB projector leaves **8.38 GB** nominal for KV.
That is the tier the transcript calls *"the best quality anyone runs at home"*.

**But the aggregate figure flatters it, and the per-card arithmetic matters.** 23.82 GB split
evenly is **11.91 GB per card** against 16.10 GB usable per card — the weights fit. Consuming the
full 8.38 GB of KV, however, puts each card at **16.10 GB, exactly 100% of usable, with zero
slack**. And real llama.cpp splits are not even: layer granularity is ~0.37 GB, and the token
embedding, output head and the 0.931 GB projector all land on one device, so **expect 1–1.5 GB of
asymmetry**. The practical KV pool at Q6_K is closer to **6.5–7 GB** than 8.38.

**But the Ollama library does not offer it.** The twelve tags catalogued in record 4 are Q4_K_M,
Q8_0, BF16, MLX, NVFP4 and MXFP8 variants — **no Q6_K, no IQ4_XS**. The library's usable range for
this host is a 4-bit tier at 18 GB or an 8-bit tier at 30 GB with 2.20 GB left over.

So the practical choice is sharper than it looked:

| Path | Quality tier available | Mechanism |
|---|---|---|
| Ollama library tag | Q4_K_M (18 GB) or Q8_0 (30 GB, impractical) | `ollama pull` |
| Ollama + imported GGUF | **Q6_K (23.82 GB, +8.38 KV)** | Modelfile `FROM ./file.gguf` |
| vLLM W4A16 | 4-bit equivalent (18.60 GB) | HF repo |

**A quality tier is available to hxs-1 that requires leaving the convenient path to reach.**
Whether the Q6_K→Q4_K_M quality delta justifies importing a GGUF is a measurement question — and
it is exactly the kind of question the fidelity data in F3 exists to answer.

### F3 — Quantization fidelity is now measurable, with published methodology

The publisher **AtomicChat** ships a token-agreement table measuring each quant against the
unquantized BF16 reference. Verified exact:

| Build | Top-1 token agreement vs BF16 |
|---|---|
| `AD-Q4_K_M` | **95.59%** |
| `AD-IQ1_M` (1-bit) | **76.34%** |

Methodology, verified and independently reproducible: reference is the original BF16 weights
converted to GGUF and run unquantized; metric is per-token KL divergence plus top-1 agreement;
evaluation on a held-out `eval_neutral` partition of 87 chunks at 4096 context, **disjoint from
the imatrix calibration corpus**; reference logits published.

**This is the only quantization-fidelity evidence in the entire series that carries a stated,
reproducible method.** It is third-party and unverified by HX, but it is *methodologically
stronger* than most of what has been available. It gives HX a template: a token-agreement harness
against a BF16 reference is a class-B test that could be run on hxs-15 without touching hxs-1.

The transcript's summary is fair: **4-bit is a rounding error; 1-bit is a different model wearing
the same name.**

### F4 — The MTP speed story carries a large asterisk on exactly hxs-1's workload

Record 4 established that Ollama's **default `qwen3.8:27b` tag is the MTP variant**. The transcript
supplies the reason it matters, and verification both confirms the numbers and corrects the framing.

**Confirmed:** llama.cpp merged MTP support in **PR #22673, 16 May 2026** (~75% acceptance with 3
draft tokens, >2× generation speedup on compatible models). **Issue #23322**, opened 19 May 2026,
measured draft acceptance on hybrid-memory models at **0.35360 and 0.36667** on long tasks —
bracketing the claimed 35–37% precisely — against a stated baseline of *"70–90% for models with
compatible attention mechanisms."* Mechanism: cache invalidation forces full prompt reprocessing,
wasting roughly two-thirds of the speculative compute.

**Two corrections to the transcript's framing:**

1. **The issue is closed, not open.** It is presented as live.
2. **It measured Qwen3.6-27B-MTP (SWA + hybrid recurrent memory), not Qwen3.8-27B.** Qwen3.8's
   stack is Gated DeltaNet + Gated Attention — related in kind, not the same. **The 35–37% figure
   is suggestive by analogy, not a Qwen3.8 measurement.**

**Why this matters more for hxs-1 than for a consumer machine.** The degradation is
specifically on *long* tasks — and hxs-1's whole proposition is long context, with 131K supported
under every branch of record 4's analysis. If the effect transfers, **the MTP default that doubles
throughput on a short prompt may contribute close to nothing at the context length hxs-1 actually
works at.** Combined with record 1's independent finding that MTP had to be *disabled* to reach
high concurrency, the case for treating the non-MTP tag as the baseline strengthens further.

**One qualification on my own citation, in the spirit of the correction above.** Issue #23322
reports four data points, not two: 0.36667 and 0.35360 on long tasks, but also **0.83333 on a
short task and ~55% cumulative across 1,446 drafts**. Quoting only the two lowest makes the
degradation look uniform when the issue's own aggregate is 55%. **The 35–37% band is the long-task
tail, not the mean.** The recommendation — measure at working context, not headline context —
survives intact; the magnitude should not be overstated.

Related, and **both also closed** (the same status error this finding corrects in the transcript,
so stated carefully): **#23658**, acceptance collapsing at KV-slot boundaries from ~70% to ~16%
across a 256-token context shift — substantively the stronger citation of the two — and **#23184**,
a feature request for pipelined draft strategies, closed as not planned.

### F5 — Dense architecture removes every escape hatch

Verified: Qwen3.8-27B is **dense**, and llama.cpp's `--n-cpu-moe` matches only tensors named
`\.ffn_(up|down|gate|gate_up)_(ch|)exps` — routed expert tensors. A dense model has none, so the
flag has nothing to match and no effect. The same applies to `-ot` expert-offload regexes.

The consequences compound:

- **Every one of the 27B parameters is read for every token.** There is no sparse activation to
  exploit.
- **The CPU-offload recipes circulating for MoE models do not apply.** They are the single most
  commonly pasted "make it fit" advice and they are inert here.
- **Disk paging is not a fallback.** The transcript's arithmetic: ~17 GB read per token against a
  Gen4 NVMe sustaining ~5 GB/s gives **~0.3 tok/s as a ceiling**. It is presented as a bound
  rather than a measurement, correctly — no published measurement of a dense 27B paging from disk
  exists. A laptop CPU running entirely from system RAM with no paging was clocked at 0.94 tok/s.

**For hxs-1 this closes a door that was never really open.** The model fits in VRAM at 4-bit and
6-bit, so paging is moot — but it is worth recording that *if* a future artifact did not fit,
there is no graceful degradation path. It fits or it does not.

### F6 — `--language-model-only` saves about a gigabyte, not the three a first draft claimed

The vision tower is **≈0.93 GB at BF16** — `vision_config` gives hidden_size 1152, depth 27,
≈460M parameters — and this is confirmed by every `mmproj-*BF16.gguf` in the ecosystem landing
within 600 bytes of **931,146,432**. vLLM's `--language-model-only` drops it cleanly.

*A first draft of this finding asserted 2.7 GB, which is wrong by ~2.9×. The likely source is
conflating `visual.*` with the other BF16-retained tensors — `lm_head` at ≈1.55 GB and the
linear-attention projections — which that flag does **not** drop.* The corrected claim: the flag
saves ~0.93 GB, **less than the 2.42 GB spread between the cheapest and dearest 4-bit checkpoint
in §3.2**, and comparable to the GGUF projector it mirrors. Useful, not decisive.

The GGUF path has the same property by default: the projector is a **separate 931 MB file**, and
omitting it yields a text-only model. Two consequences worth stating:

- **This confirms record 4's derivation — as a consistency check, not independent corroboration.**
  Record 4 computed 461M params × 2 bytes = **0.922 GB**; the actual file is **931,146,432 bytes =
  0.931 GB**. But these are not two methods: they are a parameter count of a tensor blob and the
  on-disk size of that same blob, so agreement within 1% is guaranteed by construction — the delta
  is GGUF header and metadata. It confirms the manifest reading was correct, nothing more. Record 4
  drew exactly this distinction about its own "three methods" claim; it applies here too.
- **The transcript's warning stands:** the main GGUF "has no eyes at all." Pull it without the
  projector and you have a text-only model, silently.

### F7 — Two transcript claims refuted, both about what does not exist

The transcript is otherwise the most accurate source in this series — **13 of 13 numeric claims
verified exact**, with correct GB/GiB handling throughout. Both failures are negative claims:

| Claim | Verdict |
|---|---|
| *"Four of those five do not go below 2-bit at all"* | ❌ **It is five of five.** No IQ1_S, IQ1_M or TQ1_0 exists in any of the five repos, including mradermacher's imatrix repo |
| *"There is no AWQ build and no GPTQ build"* | ❌ **Flatly wrong.** ~29 AWQ and ~24 GPTQ repos exist — and **this is the finding that resolved H8** |

The second is instructive beyond its own correction. **The transcript's single largest error is
the one that mattered most to HX** — and it happens to be an error in the same direction as my
own: both of us concluded the vLLM channel was unavailable or unviable without resolving it.

*(Publisher floors, all verified exact: Unsloth 9.010 GB · bartowski 9.393 · mradermacher 10.865 ·
lmstudio-community 16.811 · ggml-org 18.974. AtomicChat undercuts all of them at 8.498 GB.)*

### F8 — An operational detail that changes TP=2 planning

`gpu_memory_utilization` in vLLM is a **per-GPU fraction, not an aggregate**. With TP=2 and ~9.3 GB
of weights per card, the default 0.90 yields roughly 5.4 GB of KV per card — **10.8 GB total, not
the 13.59 GB the budget allows**. Reaching the full pool requires 0.94–0.95.

Small, but it is the kind of detail that produces a "why is my context so short" investigation
three days into a commissioning run. Pairs with `--kv-cache-dtype fp8` to roughly double token
capacity — the same lever the 24 GB single-card deployment uses to reach 150K context.

---

## 5. What now decides the runtime question

With the fit argument withdrawn, the decision rests on five factors. **None is settled by this
record**, and that is the honest position.

| Factor | Favours | Strength |
|---|---|---|
| `iss-015` — silent truncation vs explicit error | **vLLM** | **Strongest remaining.** Root-caused in source; open |
| Continuous batching / paged KV for fleet serving | **vLLM** | Strong — hxs-1 serves a fleet, not one user |
| Authentication | **vLLM** | Strong — Ollama has none |
| PCIe ×4 link penalising TP=2 all-reduce | **Ollama** | **Unmeasured.** Could be decisive either way |
| Operational simplicity, no Python environment | **Ollama** | Real but not architectural |
| Memory fit | **neither** | **Withdrawn — 3.1% gap** |

**The ×4 link is now the single highest-leverage unmeasured fact in the entire workstream.** It
was already flagged in three prior records. With memory fit removed from the equation, it is the
only remaining factor that could favour Ollama on hard evidence — and it is settled by one
command.

This also means the `vllm-qwen remains PRIMARY` invariant now faces **one fewer counter-argument**.
That is not the same as new support for it — nothing in this record is positive evidence for vLLM,
and the ×4 link, on which TP=2 and therefore every vLLM advantage depends, remains unmeasured and
capable of undermining it. What is gone is the case for revisiting the invariant *on fit grounds*.

---

## 6. Recommendations

### R1 — Measure the PCIe link width before anything else

**Do:** `sudo lspci -vvs <bdf>`, comparing `LnkCap` against `LnkSta` for both GPUs, deriving the
bus IDs rather than hardcoding them.
**Why:** it is now the only unmeasured fact that could change the runtime decision.
**Resolves:** whether TP=2 is viable, and therefore whether vLLM's advantages are reachable.
**Does not resolve:** anything about correctness or batching, which stand regardless.
**Cost:** one command, read-only. **Highest leverage item in the series.**

### R2 — Record the artifact register, and pin by publisher + full digest

**Do:** record §3.1 and §3.2 in the hxs-1 workload definition. Pin the chosen artifact by
**publisher, repo, and full blob SHA-256** — never by quant label.
**Why:** F7 — "Q4_K_M" spans 16.81–18.97 GB across publishers, a 2.16 GB spread on one name.
**Resolves:** the artifact ambiguity that record 4's F3 (MTP default) and F4 (nvfp4/mlx digest
collision) both exposed.
**Prerequisite:** none. Repository-side.

### R3 — Reweight the benchmark evidence in record 4

**Do:** annotate record 4's §3 tables as **vendor self-reported, unreproduced**, and soften its
F1/F2 conclusions from "measured" to "the vendor's own evidence points this way."
**Why:** F1 — no independent reproduction exists, and one benchmark in the comparison is the
vendor's in-house harness.
**Resolves:** prevents a provisional magnitude hardening into a project fact.
**Does not resolve:** the direction of the finding, which survives.

### R4 — Consider an independent benchmark run on hxs-15

**Do:** evaluate whether HX wants its own number on one or two benchmarks, using the Apache-2.0
weights. AtomicChat's published methodology (F3) is a usable template for a token-agreement
fidelity test.
**Why:** hxs-15's assigned role is literally `Test & integration — QA, regression, integration
testing, benchmarks`, and F1 establishes nobody has reproduced these scores.
**Resolves:** converts the series' weakest evidence class into HX-primary evidence.
**Does not resolve:** anything on the critical path — this is optional and later.
**Reversal criteria:** drop it if independent leaderboard results appear first.

### R5 — Treat the non-MTP tag as baseline and measure acceptance at working context

**Do:** baseline on the non-MTP artifact; if MTP is A/B'd, measure draft acceptance at **131K, not
at 4K**.
**Why:** F4 — the degradation is specifically on long tasks, which is hxs-1's entire proposition.
Corroborated by record 1's independent finding that MTP had to be disabled under concurrency.
**Resolves:** prevents a headline throughput number that does not survive the real workload.
**Consistent with** the Codex runbook, which already recommends non-MTP first.

---

## 7. Explicitly not recommended

- **Do not revisit `vllm-qwen remains PRIMARY` on fit grounds.** That argument is withdrawn.
- **Do not pull `27b-nvfp4`, `amd/…-MXFP4`, or `dsikka/…-NVFP4-FP8`** — all Blackwell-dependent or
  broken on NVIDIA; hxs-1 is Ada 8.9.
- **Do not plan any CPU-offload or disk-paging fallback.** F5 — dense architecture, ~0.3 tok/s
  ceiling, MoE flags inert. It fits or it does not.
- **Do not quote any benchmark figure from this series as measured.** F1.
- **Do not treat Q6_K as a recommendation.** It is an *available option* that the Ollama library
  does not reach; whether the quality delta justifies the inconvenience is unmeasured.

---

## 8. Series close — the five records and what each settled

| # | Record | Settled | Left open |
|---|---|---|---|
| 1 | `…inference-performance_third-party` | 23.5 GiB at 131K *plausibly* fits hxs-1's aggregate but not one card; prefix caching is load-bearing | H8; the ×4 link; the L2 quantization-tier ambiguity on the 23.5 GiB figure itself |
| 2 | `…cuda-driver-runtime-requirements_vendor` | Neither runtime needs the CUDA Toolkit; driver clears CUDA 13.0 **only** | `hx-gpu-fit.ps1` floor defect |
| 3 | `…hxs1-model-storage-architecture_synthesis` | The SATA drive is SMR; device names unsafe; downloads are in-place | Mount path (`/srv/hx-ai` vs `/srv/hx`) |
| 4 | `…ollama-serving-and-capability-fit_synthesis` | Default tag is MTP; no sampler prior art; role/capability gap | Benchmark weighting *(corrected here)*; H8 *(resolved here)* |
| **5** | **this record** | **H8 resolved; fit argument withdrawn; artifact ladder resolved** | **The ×4 link — one command** |

**Corrections issued across the series:** H8 framing (record 1 → record 4 → here), the w4a16
extrapolation (record 4 → here), benchmark evidence weighting (record 4 → here), the `noatime`
rationale and PCIe width claim (record 3, at verification), the KV functional form and L2
limitation (record 4, at verification).

**Every one of these was found by adversarial verification, not by the drafting pass.** That is
the process finding worth carrying forward more than any individual number.

---

## 9. Remaining verification and owner decisions

| # | Item | Type |
|---|---|---|
| V1 | **PCIe `LnkCap` vs `LnkSta` on both GPUs** | Verification — **the critical path** |
| V2 | Does the OpenAI `/v1` path share `iss-015`? Read vendored source | Verification |
| V3 | Full blob SHA-256 for whichever artifact is chosen | Verification, at pull time |
| V4 | MTP draft acceptance at 131K on Qwen3.8 specifically | Measurement, at commissioning |
| V5 | Whether Ollama's VRAM context tiering reads aggregate or per-device | Verification, at commissioning |
| D1 | What does `Deep reasoning & synthesis` require? | **Owner decision** — record 4 |
| D2 | `/srv/hx-ai` or `/srv/hx`, and which partition plan? | **Owner decision** — record 3 |
| D3 | Runtime selection, now on correctness/batching grounds only | **Owner decision** |
| D4 | Implementation-phase authorization for hxs-1 | **Owner decision** — gates everything |

---

## 10. Provenance

**Vendor primary — retrieved 2026-08-17.** Exact manifest byte counts via the HuggingFace API
(`?blobs=true`), not rounded UI strings:
`unsloth/Qwen3.8-27B-GGUF` · `bartowski/Qwen3.8-27B-GGUF` · `ggml-org/Qwen3.8-27B-GGUF` ·
`lmstudio-community/Qwen3.8-27B-GGUF` · `mradermacher/Qwen3.8-27B-GGUF` (+ `-i1-GGUF`) ·
`AtomicChat/Qwen3.8-27B-GGUF` (+ `-metrics`) · `dbirks/Qwen3.8-27B-W4A16-AutoRound` ·
`philbert440/Qwen3.8-27B-W4A16-AWQ` · `Vishva007/Qwen3.8-27B-W4A16-AutoRound-GPTQ` ·
`amd/Qwen3.8-27B-Quark-AWQ-INT4-W4A16` · `amd/Qwen3.8-27B-Quark-AWQ-MXFP4` ·
`btbtyler09/Qwen3.8-27B-GPTQ-4bit` · `cyankiwi/Qwen3.8-27B-AWQ-INT4` ·
`dsikka/Qwen3.8-27B-NVFP4-FP8-GPTQ-AWQ` · `Qwen/Qwen3.8-27B` · `Qwen/Qwen3.8-27B-FP8`

llama.cpp — [PR #22673](https://github.com/ggml-org/llama.cpp/pull/22673) (MTP merge, 16 May 2026) ·
[issue #23322](https://github.com/ggml-org/llama.cpp/issues/23322) (hybrid-attention acceptance,
**closed**) · issues #23658, #23184 · `docs/speculative.md`

[vLLM recipes — Qwen3.8-27B](https://recipes.vllm.ai/Qwen/Qwen3.8-27B) ·
[Red Hat AI quantization support matrix](https://docs.redhat.com/en/documentation/red_hat_ai/3/html/supported_product_and_hardware_configurations/rhaiis-gpu-quantization-support_supported-configurations)
(NVFP4 Blackwell-only) · [TensorRT-RTX 1.4 support matrix](https://docs.nvidia.com/deeplearning/tensorrt-rtx/1.4/getting-started/support-matrix-1/1.4.html)

**HX primary:** `SERVER-REGISTRY.md` · `servers/hxs-1/discovery.md` ·
`tests/ai-runtime/workloads/qwen35-9b-ollama.json` · `governance/logs/actions-and-issues.md`
(`iss-013`, `iss-014`, `iss-015`, `iss-016`)

**HX design / in-flight:** `governance/operations/ollama/codex_20260817_1524_hx-qwen38-27b-ollama-deployment-deep-dive.html`
and the four companion records in this directory.

**Third-party trigger source:** independent operator video review, transcript supplied by project
owner 2026-08-17. Thirteen of thirteen numeric claims verified exact; two negative claims refuted
(F7); one framing error on issue status and model identity (F4).

**Derived:** all headroom arithmetic in §3, from exact manifest bytes against
32,752 MiB less 2 × 1 GiB. **Derived, not measured on hxs-1.** No figure here is an HX measurement.

---

*Prepared by Claude (Opus 5), 2026-08-17. Research record — no authority asserted, no decision
made, no acceptance granted. Per repository convention, a proposal is not a ruling.*
