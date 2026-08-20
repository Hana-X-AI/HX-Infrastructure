# Research — Ollama & Local Model Serving

Research records supporting the Ollama / local-model-serving thread. This directory holds
**research**: structured records of evidence gathered from outside a commissioning run.

Research is not a decision, an acceptance, or an authorization. It narrows the hypothesis
space before a measurement; it never substitutes for one.

---

## File naming standard

Every document in this directory uses:

```
hx-research_<subject-slug>_<evidence-tier>_<YYYY-MM-DD>_<author-slug>.<ext>
```

**Example**

```
hx-research_qwen38-27b-inference-performance_third-party_2026-08-17_claude-opus-5.md
hx-research_qwen38-27b-inference-performance_third-party_2026-08-17_claude-opus-5.html
```

### Fields

| Field | Rule |
|---|---|
| `hx-research` | Fixed prefix. Groups all research records and distinguishes them from reports, plans, decisions, and prompts. |
| `<subject-slug>` | Kebab-case. Technology plus focus, specific enough to read alone: `qwen38-27b-inference-performance`, not `qwen-notes`. No version dots — write `qwen38`, not `qwen3.8`. |
| `<evidence-tier>` | One of the four values below. **Mandatory** — the tier is part of the filename so provenance is visible before the file is opened. |
| `<YYYY-MM-DD>` | Date the record was authored. ISO order so the field sorts. |
| `<author-slug>` | Kebab-case author or model identity: `claude-opus-5`, `gpt-5-6-sol`, `codex`, `owner`. |
| `<ext>` | `.md` and `.html` are published as a **pair** with identical stems — Markdown is the editable source, HTML is the reviewable render. |

### Evidence tiers

Aligned to the evidence classes in `governance/policy/ai-runtime-acceptance-contract.md`.

| Tier | Meaning | Can support an acceptance decision? |
|---|---|---|
| `primary` | Measured by HX, on HX hardware, with retained evidence | **Yes** |
| `vendor` | Official upstream documentation, model cards, release notes, source code | For facts about the artifact only |
| `third-party` | External operator reports, community benchmarks, published reviews — unverified, non-HX hardware | **No** |
| `synthesis` | Derived from two or more of the above; states its inputs | Only as strong as its weakest input |

### Rules

1. **The tier is a claim about provenance, not quality.** A careful third-party benchmark is
   still `third-party`. Never promote a tier because the source seems trustworthy.
2. **Every derived figure states its basis.** A number scaled from another platform is labelled
   as derived, with the ratio shown.
3. **Limitations go in the document, near the front.** A research record that does not state
   what it cannot support is not finished.
4. **No decisions.** Research records may propose hypotheses and identify the measurement that
   would settle them. Decisions live in `governance/policy/`; actions and issues live in
   `governance/logs/actions-and-issues.md`.
5. **No spaces in filenames** — per `governance/policy/documentation-standards.md`.
6. **Publish the pair.** Edit the `.md`; regenerate the `.html`. They must not diverge.

### Why this shape

Sorting by filename groups all research together, then by subject, then by tier, then
chronologically — so a reader scanning the directory sees at a glance which subjects have
`primary` evidence behind them and which are still resting on `third-party` reports. That
distinction is the one this project cares most about, so it is encoded where it cannot be
missed.

---

## Start here if you are executing

**`MVP1-CONSTRAINTS.md`** — the operational distillation of all five records: every constraint
that changes what an operator or agent types, with the evidence stripped out. One page.
Read that before touching HXS-1; read the records below only when you need to know *why*.

The records themselves are deliberately **not** rewritten as execution plans. A research record
that becomes a plan stops being checkable, and the corrections register below is only meaningful
because the records still say what they originally claimed.

---

## Contents

The five records below form one series on the hxs-1 / Qwen3.8-27B question, written 2026-08-17.
**Read record 5 first if you read only one** — it corrects load-bearing claims in records 1 and 4
and closes the series. Corrections are recorded in the documents rather than silently applied.

| # | Document | Tier | Subject |
|---|---|---|---|
| 1 | `hx-research_qwen38-27b-inference-performance_third-party_2026-08-17_claude-opus-5` | `third-party` | Throughput, memory footprint, concurrency and agentic behaviour from an external RTX 4090 field report, with derived hxs-1 fit analysis. |
| 2 | `hx-research_cuda-driver-runtime-requirements-hxs1_vendor_2026-08-17_claude-opus-5` | `vendor` | NVIDIA driver and CUDA requirements; neither runtime needs the CUDA Toolkit; the per-minor CUDA 13.x driver floor; a false-`PASS` path in `hx-gpu-fit.ps1`. |
| 3 | `hx-research_hxs1-model-storage-architecture_synthesis_2026-08-17_claude-opus-5` | `synthesis` | Storage reconnaissance and model-store design: the SATA drive is SMR; device names are unsafe on this host; downloads are in-place. |
| 4 | `hx-research_qwen38-27b-ollama-serving-and-capability-fit_synthesis_2026-08-17_claude-opus-5` | `synthesis` | Benchmarks verified against the model card; the twelve-tag Ollama artifact register; official sampler regimes; the hxs-1 role/capability question. |
| **5** | `hx-research_qwen38-27b-quantization-ladder-and-artifact-resolution_synthesis_2026-08-17_claude-opus-5` | `synthesis` | **Series close.** Full quantization ladder against hxs-1's aggregate; real vLLM manifests resolve H8 and **withdraw the memory-fit argument**; MTP acceptance on hybrid attention; benchmark provenance reweighted. |

### Series corrections register

| Correction | Origin | Corrected in |
|---|---|---|
| H8 framing — resolved vs. still open | record 1 → 4 | record 5 |
| vLLM w4a16 extrapolation, 56% too high | record 4 | record 5 |
| Benchmark evidence weighting — vendor self-reported, unreproduced | record 4 | record 5 |
| `noatime` rationale; PCIe link-width claim | record 3 | at verification |
| KV functional form; dropped L2 limitation | record 4 | at verification |

Every one of these was found by an **adversarial verification pass**, not by the drafting pass.
That is the process finding worth carrying forward more than any individual number.

### Full listing

| Document | Tier | Subject |
|---|---|---|
| `hx-research_qwen38-27b-inference-performance_third-party_2026-08-17_claude-opus-5` | `third-party` | Qwen3.8-27B throughput, memory footprint, concurrency and agentic behaviour, from an external single-operator RTX 4090 field report; with derived fit analysis for hxs-1. |
| `hx-research_cuda-driver-runtime-requirements-hxs1_vendor_2026-08-17_claude-opus-5` | `vendor` | NVIDIA driver and CUDA requirements for Ollama and vLLM on hxs-1; installed-state conformance; the per-minor CUDA 13.x driver floor and hxs-1's one-version headroom; a false-`PASS` path in `hx-gpu-fit.ps1`. |
| `hx-research_hxs1-model-storage-architecture_synthesis_2026-08-17_claude-opus-5` | `synthesis` | hxs-1 storage reconnaissance and model-store design: device selection (the SATA drive is SMR), partition/filesystem/mount plan, directory layout and env wiring, and how artifacts are stored during download and at runtime. |
| `hx-research_qwen38-27b-ollama-serving-and-capability-fit_synthesis_2026-08-17_claude-opus-5` | `synthesis` | Benchmarks verified against the official model card; the twelve-tag Ollama artifact register (the default tag is the MTP variant; `27b-nvfp4` and `27b-mlx` share a digest); official sampler regimes, of which HX has no prior art; and the hxs-1 role/capability question — the model's strongest capability is computer use, for which HX has no plane. |
| `hx-research_qwen38-27b-quantization-ladder-and-artifact-resolution_synthesis_2026-08-17_claude-opus-5` | `synthesis` | Series close. The full GGUF and vLLM quantization ladder resolved against hxs-1's aggregate budget from exact manifest bytes; H8 resolved and the memory-fit argument withdrawn; MTP draft-acceptance degradation on hybrid attention; benchmark provenance reweighted to vendor-self-reported. |

---

*Standard established 2026-08-17. Proposed for adoption across HX research records; not yet
ratified by owner ruling.*
