# NVIDIA CUDA and Driver Requirements for hxs-1 Model Serving

| | |
|---|---|
| **Document ID** | `hx-research_cuda-driver-runtime-requirements-hxs1_vendor_2026-08-17_claude-opus-5` |
| **Subject** | NVIDIA driver and CUDA requirements for Ollama and vLLM on hxs-1; installed-state conformance; upgrade headroom |
| **Evidence tier** | `vendor` — official NVIDIA, vLLM and Ollama documentation, checked against the hxs-1 discovery record |
| **Author** | Claude (Opus 5) |
| **Date** | 2026-08-17 |
| **Status** | Research record. **Not a decision, not an acceptance, not an authorization.** |
| **Relates to** | hxs-1 · `act-010` (driver-only directive) · `tests/ai-runtime/hx-gpu-fit.ps1` · `governance/policy/nvidia-driver-install-directive.md` |

---

## Abstract

hxs-1 currently satisfies every published NVIDIA requirement for both candidate inference
runtimes, and **neither runtime requires the CUDA Toolkit** — a finding that matters because
`act-010` explicitly prohibits installing it. Both Ollama and vLLM ship CUDA runtime libraries
inside their own distribution; the kernel-mode driver is the only NVIDIA dependency, and it is
already installed and validated on this host.

Three findings qualify that clean bill of health. The installed driver clears **CUDA 13.0 GA and
nothing beyond it** — there is no single "13.x floor"; each minor release raises it, and CUDA
13.1 already requires 590.44.01, putting hxs-1 **one minor version** from a mandatory driver
upgrade. CUDA 13.0 dropped three GPU generations, raising the effective architecture floor to
compute capability 7.5. And `hx-gpu-fit.ps1` carries pre-CUDA-13 thresholds that would return
`PASS` for a device the installed runtime can no longer execute at all.

---

## 1. Installed state on hxs-1

Source: `servers/hxs-1/discovery.md` and `servers/hxs-1/driver-results.md`. Installed under the
approved Phase 1 exception recorded in `act-010`.

| Facet | Value |
|---|---|
| Driver package | `nvidia-driver-580-server-open` + `nvidia-utils-580-server` |
| Kernel module version | **580.173.02** |
| CUDA runtime reported | **13.0** |
| Kernel module flavour | **open** (`-open` variant) |
| GPUs | 2× RTX 4070 Ti SUPER, AD103, PCI `10de:2705` |
| Architecture | **Ada Lovelace — compute capability 8.9** |
| VRAM | 16,376 MiB each, 32,752 MiB total |
| OS / kernel | Ubuntu 24.04.4 LTS noble, kernel 7.0.0-28-generic (HWE) |
| CUDA Toolkit (`nvcc`) | **not installed** — and prohibited by `act-010` |
| Container runtime | **not installed** — no Docker, containerd, or podman |

`act-010` is worth quoting because it defines the boundary this document is testing against:

> The driver-only directive "explicitly prohibits vLLM, PyTorch, CUDA Toolkit, Python
> environments, Hugging Face tooling, model files, inference services and multi-GPU workload
> configuration."

---

## 2. NVIDIA platform requirements

### 2.1 Driver floor by CUDA version

CUDA applications require a minimum kernel-mode driver. There is **no single "CUDA 13.x
floor"** — each minor release raises it. On Linux x86_64:

| CUDA Toolkit | Minimum Linux x86_64 driver | hxs-1 @ 580.173.02 |
|---|---|---|
| 13.0 GA | ≥ 580.65.06 | ✅ PASS |
| 13.1 GA | ≥ 590.44.01 | ❌ FAIL |
| 13.1 Update 1 | ≥ 590.48.01 | ❌ FAIL |
| 13.2 GA | ≥ 595.45.04 | ❌ FAIL |
| 13.2 Update 1 | ≥ 595.58.03 | ❌ FAIL |
| 13.3 GA | ≥ 610.43.02 | ❌ FAIL |
| 13.3 Update 1 | ≥ 610.43.02 | ❌ FAIL |

hxs-1 runs **580.173.02**, which clears **CUDA 13.0 GA only**. The very next minor release
already requires 590.44.01. The host is **one minor version away** from a mandatory driver
upgrade, not several.

### 2.2 Backward compatibility

The CUDA driver is backward compatible: an application compiled against an earlier CUDA
version continues to work on later driver releases. Practically, driver 580 runs binaries built
against CUDA 12.x as well as 13.0.

**This is the fact that removes most version anxiety.** vLLM's default `cu129` wheel, PyTorch
`cu128` builds, and Ollama's bundled runtime all execute correctly on driver 580 without any
toolkit installation and without matching CUDA versions exactly.

### 2.3 Architectures dropped in CUDA 13.0

> "Removed support for Maxwell, Pascal, and Volta GPUs, corresponding to compute capabilities
> earlier than Turing."

*Citation note: cite the CUDA 13.0 general "Removed Features / architecture support" section
rather than a library-specific subsection, so the reference survives audit.*

CUDA 13 therefore supports **compute capability 7.5 (Turing) and newer**. Ada at 8.9 is
unaffected. This also explains why the `-open` kernel module variant works here — open kernel
modules require Turing or newer, which Ada satisfies.

---

## 3. Runtime requirements compared

| Requirement | Ollama | vLLM | hxs-1 |
|---|---|---|---|
| Minimum compute capability | 5.0 (5.0–6.2 need driver ≥ 570) | **7.5** | **8.9** ✅ |
| Minimum driver | **550** | set by the wheel's CUDA build | **580.173.02** ✅ |
| Prebuilt CUDA targets | bundled runtime, no separate build | **cu128 · cu129 (default) · cu130** | all three run on driver 580 ✅ |
| CUDA Toolkit required? | **No** | **No** — only to build from source | not installed, not needed ✅ |
| Python required? | No — single Go binary | Yes | `python3 3.12.3` present |
| Multi-GPU selection | `CUDA_VISIBLE_DEVICES`, **UUIDs recommended over indices** | `CUDA_VISIBLE_DEVICES` / TP config | 2 devices, UUIDs **not yet captured** |

### 3.1 The Toolkit is not required — this is the operationally significant finding

Both runtimes distribute their own CUDA runtime libraries. Ollama ships them alongside its Go
binary; vLLM's prebuilt wheels carry the CUDA runtime and cuBLAS/cuDNN dependencies as Python
package data. The `nvcc` compiler and the CUDA Toolkit development headers are needed **only**
to compile CUDA C++ from source.

One nuance, stated pre-emptively because this is the document's headline claim: vLLM's
`torch.compile` path uses Triton, which does need a `ptxas`/`nvcc` binary — but that too arrives
as a **pip wheel** (`nvidia-cuda-nvcc-cu13`), not from the system CUDA Toolkit. A CUDA compiler
may therefore be present inside the Python environment. It is not the prohibited package, and it
installs nothing system-wide.

Consequence: a future implementation phase on hxs-1 can install and run either runtime
**without violating `act-010`'s Toolkit prohibition**. The prohibition is not a blocker; it
was never load-bearing for the serving path. It would only become one if HX chose to build
vLLM from source — which the vLLM documentation reserves for modifying its C++/CUDA code.

### 3.2 Ollama's UUID guidance corroborates `iss-013`

Ollama's current documentation recommends setting `CUDA_VISIBLE_DEVICES` to device **UUIDs**
(from `nvidia-smi -L`) rather than numeric indices. This is independent upstream confirmation
of what HX established the hard way in `iss-013` — *"indexes reorder across reboots"* — and it
reinforces the outstanding gap that **hxs-1's GPU UUIDs have never been captured**.

---

## 4. Findings

### F1 — The driver clears CUDA 13.0 only, and the next minor already breaks it

580.173.02 satisfies CUDA 13.0 GA (≥ 580.65.06) and nothing beyond it. **CUDA 13.1 already
requires 590.44.01**, and 13.3 requires 610.43.02. If any required wheel is built against a
13.x minor above 13.0, hxs-1 needs a driver upgrade first.

This is a materially tighter constraint than "sits on the floor" suggests — the gap is one
minor version, not a comfortable margin.

That is not a small operation on this host. `INFRASTRUCTURE-CONTRACT.md` §14 lists "kernel or
driver changes" as a high-impact change requiring inspection, backup, validation, and rollback
planning. And the discovery record notes hxs-1 has **no baseboard management controller or
out-of-band management interface**, so a driver change that breaks the graphics stack requires
physical access to recover.

**Implication:** treat driver version as a pinned dependency with a stated upgrade path, not as
something to bump opportunistically. Prefer wheels targeting cu128/cu129/cu130 while on 580.

### F2 — once it can run, `hx-gpu-fit.ps1` carries pre-CUDA-13 floors and can return a false PASS

Two sequential conditions, kept distinct. **Today** the gate cannot run at all on hxs-1: it needs
the GPU UUID input, which is absent (see the conformance table), so the floor defect is latent.
**After** the UUIDs are captured and the gate runs, the floor defect below becomes live: it may
return `PASS` for a device that cannot actually execute.

The gate enforces:

```
min_driver_version       = 531
min_compute_capability   = 5.0
```

Both predate CUDA 13.0. On a host whose installed runtime is CUDA 13.0, a device at compute
capability 5.0–7.0 **cannot execute at all**, yet the gate would return `PASS` for it. Driver
531 likewise cannot run any CUDA 13 application.

This does not affect hxs-1 — 8.9 and 580 clear every threshold — but it is a false-`PASS` path
in a harness whose stated purpose is to refuse false passes:

> "Never use `PASS` for a property the test could not actually disprove."

**Suggested correction:** raise to `min_compute_capability = 7.5` and `min_driver_version = 580`,
with a comment naming CUDA 13.0's architecture removal as the reason, and ideally deriving the
floor from the host's detected CUDA runtime rather than hardcoding it. Filing this as an issue
is a Phase 3 action; it requires no host access.

### F3 — The v0.3 build pin does not apply to hxs-1

`governance/fleet-architecture-v0.3.html` records a build-time pin: *"vLLM 0.11.x / PyTorch
cu128 / CUDA 12.8 / driver ≥575, FlashAttention-2 (FA3 unsupported on Blackwell)."*

That pin was written for the **Blackwell** hosts — hxs-2, hxs-3 and hxs-4, which carry RTX 5060
Ti / 5060 cards. hxs-1 is **Ada**, a generation with longer-established kernel support and
without the Blackwell FlashAttention-3 caveat. Applying the Blackwell pin to hxs-1 would be a
category error; the document should be read as host-class-specific, and the distinction stated
explicitly when v0.3 is next reissued.

### F4 — Residual observations

- **Package variant.** `nvidia-driver-580-server-open` is the server/datacenter branch with
  open kernel modules. It is functioning correctly on consumer Ada silicon — both GPUs bound to
  `nvidia`, `nvidia-smi` reporting VRAM — per `driver-results.md`. Recorded as verified-working,
  not raised as a concern.
- **No container runtime.** Neither Ollama nor vLLM requires one for a bare-metal install. If a
  containerised deployment is ever chosen, the NVIDIA Container Toolkit becomes an additional
  dependency — and it is a separate package from the CUDA Toolkit, so `act-010`'s prohibition
  would need re-reading against that specific case rather than assumed to cover it.
- **Secure Boot is disabled** on hxs-1, so kernel module signing is not a constraint on driver
  changes. Worth noting because it removes a failure mode that commonly complicates NVIDIA
  driver upgrades on Ubuntu.

---

## 5. Conformance summary

| Check | Requirement | hxs-1 | Verdict |
|---|---|---|---|
| Compute capability, Ollama | ≥ 5.0 | 8.9 | ✅ PASS |
| Compute capability, vLLM | ≥ 7.5 | 8.9 | ✅ PASS |
| Compute capability, CUDA 13 runtime | ≥ 7.5 | 8.9 | ✅ PASS |
| Driver, Ollama | ≥ 550 | 580.173.02 | ✅ PASS |
| Driver, CUDA 13.0 GA | ≥ 580.65.06 | 580.173.02 | ✅ PASS |
| Driver, CUDA 13.1 GA and every later minor | ≥ 590.44.01, rising to 610.43.02 at 13.3 | 580.173.02 | ❌ **would fail — upgrade needed at the very next minor** |
| CUDA Toolkit | not required by either runtime | not installed | ✅ compliant with `act-010` |
| Open kernel modules | Turing or newer | Ada 8.9 | ✅ PASS |
| GPU UUIDs recorded | required by `hx-gpu-fit.ps1` | **absent** | ❌ **gate cannot run** |

**Net:** the platform requirements are met. The blocking item is not CUDA — it is the missing
device identity, which is a read-only five-minute capture.

---

## 6. Recommended actions

Ordered so that nothing requires authorization it does not have. Items 1–3 are read-only or
documentation-only and sit fully within Phase 3.

1. **Capture GPU device identity on hxs-1.** Read-only; unblocks `hx-gpu-fit.ps1`. Append to
   `driver-results.md` rather than editing the immutable `discovery.md`.

   ```bash
   nvidia-smi --query-gpu=index,uuid,name,memory.total,pci.bus_id,driver_version \
              --format=csv
   nvidia-smi -L
   ```

   While there, settle the ×4 link question with the authoritative source — `nvidia-smi`'s
   `pcie.link.width.max` often reports the *device's* capability rather than the slot's:

   ```bash
   # Derive the bus IDs rather than hardcoding them, and use sudo —
   # unprivileged `lspci -vv` prints "Capabilities: <access denied>" and the
   # LnkCap/LnkSta lines are never emitted, so the grep silently returns nothing.
   # nvidia-smi emits an eight-digit domain (e.g. 00000000:01:00.0); lspci wants
   # the short form, so strip the four leading domain zeros before calling it.
   for BDF in $(nvidia-smi --query-gpu=pci.bus_id --format=csv,noheader \
                | sed 's/^0000//I'); do
     echo "== $BDF =="
     OUT=$(sudo lspci -vvs "$BDF" | grep -E 'LnkCap:|LnkSta:')
     if [ -z "$OUT" ]; then
       echo "FATAL: no LnkCap/LnkSta output for $BDF — check sudo and the bus ID" >&2
     else
       printf '%s\n' "$OUT"
     fi
   done
   ```

2. **File the `hx-gpu-fit.ps1` floor defect** (F2) in `governance/logs/actions-and-issues.md`.
   Repository-side change, no host access.

3. **Record the driver-version pin** (F1) as a stated constraint: hxs-1 remains on 580.x, and
   runtime artifacts must target cu128/cu129/cu130. Re-evaluate only if a required wheel raises
   the floor, and treat that as a §14 high-impact change.

4. **When implementation is authorized,** install neither the CUDA Toolkit nor a container
   runtime unless a specific requirement emerges. The serving path needs the driver only.

---

## 7. Citation

**Vendor sources, retrieved 2026-08-17**

- NVIDIA CUDA Toolkit Release Notes — driver version table, architecture removals
  <https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html>
- NVIDIA CUDA Compatibility — minor version compatibility and backward compatibility rules
  <https://docs.nvidia.com/deploy/cuda-compatibility/minor-version-compatibility.html>
- NVIDIA Ada GPU Architecture Compatibility Guide
  <https://docs.nvidia.com/cuda/ada-compatibility-guide/>
- vLLM — GPU installation requirements, prebuilt wheel CUDA targets
  <https://docs.vllm.ai/en/stable/getting_started/installation/gpu/>
- Ollama — hardware support, compute capability and driver minimums, `CUDA_VISIBLE_DEVICES`
  <https://docs.ollama.com/gpu>

**HX records referenced:** `servers/hxs-1/discovery.md` · `servers/hxs-1/driver-results.md` ·
`governance/policy/nvidia-driver-install-directive.md` · `governance/logs/actions-and-issues.md`
(`act-010`, `iss-013`) · `governance/fleet-architecture-v0.3.html` ·
`INFRASTRUCTURE-CONTRACT.md` §14 · `tests/ai-runtime/hx-gpu-fit.ps1`

---

*Prepared by Claude (Opus 5), 2026-08-17. Research record — no authority asserted, no decision
made, no acceptance granted. Per repository convention, a proposal is not a ruling.*
