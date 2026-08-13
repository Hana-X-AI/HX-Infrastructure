# GPU Capability Input for Servers 1 through 4

**Author:** Claude Opus 5 (Claude Code)
**Reported at:** 2026-08-11 22:05:00 -05:00
**Purpose:** Provide the factual capability basis, and the decisions required, for the project owner to manually assign roles to the four GPU-bearing servers.
**Status of this document:** Decision input. It assigns no role, selects no workload, and selects no model.

---

## Boundary

`GOALS-AND-OBJECTIVES.md` permits agents to report and compare factual capabilities, and prohibits assigning roles, selecting workloads, or selecting models. This report stays on the permitted side of that line: it states what the hardware is, what the software stack requires, what the gaps are, and what has to be decided. The decisions themselves are yours.

`governance/policy/tooling-first-rule.md` permits vendor specification and external documentation to **interpret** discovered hardware, provided they never replace direct server evidence in the as-found record. This report uses that permission. Every figure below is labelled either **discovered** or **vendor specification**. Nothing marked vendor specification will be written into `servers/hxs-1/discovery.md`.

---

## 1. The headline problem

**As found, `hxs-1` cannot currently run CUDA-dependent NVIDIA inference workloads such as vLLM — and VRAM is not the reason.**

The discovered evidence proves that `nouveau` is bound, that CUDA is absent, and that the proprietary NVIDIA stack is not installed. It does not prove that every possible form of model serving is impossible on this host.

Both NVIDIA GPUs are bound to the open-source `nouveau` driver:

```text
02:00.0 VGA compatible controller: NVIDIA Corporation AD103 [GeForce RTX 4070 Ti SUPER]
        Kernel driver in use: nouveau
81:00.0 VGA compatible controller: NVIDIA Corporation AD103 [GeForce RTX 4070 Ti SUPER]
        Kernel driver in use: nouveau
```

`nouveau` does not provide CUDA. vLLM requires CUDA. No `nvidia-smi`, no CUDA runtime, and no NVIDIA packages are installed — `dpkg` returned nothing matching `nvidia`, `cuda`, or `libcuda`.

This matters more than the VRAM question, because it is upstream of it:

- it is why VRAM cannot be read — `nvidia-smi` is the normal source and it does not exist;
- it is why the cards cannot run CUDA-dependent inference today, whatever their VRAM turns out to be;
- and resolving it resolves both problems at once.

The moment the proprietary driver is installed, `nvidia-smi --query-gpu=memory.total` reports VRAM authoritatively, and the capability question answers itself.

**That install is a Phase 2 activity or an explicit Phase 1 exception.** `governance/policy/tooling-first-rule.md` is unambiguous: *"During Phase 1, installing a missing diagnostic utility or vendor driver requires an explicit project decision and must not be done automatically."* I have not done it and will not without your instruction.

---

## 2. What is actually discovered, and what is not

### Discovered on hxs-1 (direct server evidence)

| Fact | Value | Source |
| --- | --- | --- |
| GPU count | 2 discrete NVIDIA, plus 1 integrated Intel | `lspci -nnk` |
| GPU model | NVIDIA AD103 [GeForce RTX 4070 Ti SUPER] ×2 | `lspci -nnk` |
| GPU PCI IDs | `10de:2705` at `02:00.0` and `81:00.0` | `lspci -nn` |
| GPU driver in use | `nouveau` (both) | `lspci -nnk` |
| NVIDIA/CUDA packages | none installed | `dpkg-query` |
| Additional accelerator | Intel Arrow Lake NPU `8086:ad1d`, driver `intel_vpu` | `lspci -nnk` |
| Additional accelerator | Hailo-8 AI processor `1e60:2864`, **no driver bound** | `lspci -nnk` |
| CPU | Intel Core Ultra 9 285K, 24 cores / 24 threads, 1 socket, 1 NUMA node | `lscpu` |
| RAM | 128 GB online | `lsmem`, `numactl` |
| Python | 3.12.3 | `dpkg-query` |
| OS / kernel | Ubuntu 24.04.4 LTS, 7.0.0-28-generic | `/etc/os-release`, `uname -a` |
| Chassis | desktop; MSI MS-7E34 board; firmware 1.A80 (2025-01-07) | `hostnamectl` |

### Not yet available

| Fact | Status | Why |
| --- | --- | --- |
| **VRAM per GPU** | **unavailable from current as-found OS/driver state** | no CUDA driver; `nvidia-smi` absent; no sysfs VRAM attribute under `nouveau` |
| PCIe link width per GPU | not yet collected | probe prepared, not yet run |
| Serial, BIOS detail, DIMM layout | unavailable | `dmidecode` needs root; `sudo -n` refused |
| **Servers 2, 3, 4 — everything** | **not discovered** | discovery has not been run against them |

**Servers 2 through 4 have produced no data whatsoever.** Nothing in this report should be read as describing them. If they are identical units, the analysis below transfers; if they are not, it does not. That is precisely what discovery is for.

---

## 3. vLLM requirements, from current documentation

Retrieved via Context7 from the vLLM stable documentation, per `CLAUDE.md`'s instruction to use it for version-sensitive guidance.

| Requirement | Value | hxs-1 status |
| --- | --- | --- |
| OS | Linux | Ubuntu 24.04.4 — satisfied |
| Python | 3.10 – 3.13 | 3.12.3 — satisfied |
| NVIDIA compute capability | **≥ 7.5** | AD103 is 8.9 *(vendor specification)* — satisfied |
| CUDA | required | **not present — blocking** |
| Multi-GPU | `tensor_parallel_size=N` splits one model across N GPUs | 2 GPUs available |
| Memory control | `--gpu-memory-utilization`, default **0.92**; or `--kv-cache-memory-bytes` | n/a until driver present |

So the hardware is eligible and the OS and Python are already correct. The single blocking item is the driver.

### Your instinct on vLLM is technically sound

For serving Hugging Face models on NVIDIA hardware, vLLM is a reasonable default: it loads Hugging Face model repositories directly, supports 200+ architectures, and its PagedAttention KV-cache management is the main reason it outperforms naive `transformers` serving on limited VRAM. Nothing in the discovered hardware argues against it.

I am deliberately not making that selection for you — workload and model selection are manual project decisions. But you asked whether the guess was sensible, and on the evidence it is.

---

## 4. Capacity arithmetic — planning only

**Every figure in this section is vendor specification, not discovered fact.** It exists to let you plan; it must not enter `discovery.md`, and it must be replaced by measured values once the driver question is settled.

RTX 4070 Ti SUPER (AD103) carries **16 GB GDDR6X** per card *(vendor specification)*. Two cards is **32 GB aggregate** *(vendor specification)* — but aggregate is not the same as usable for one model, which is the point most planning gets wrong.

Rough weight sizing, before KV cache and activation overhead:

| Precision | Bytes/param | 7B | 14B | 32B | 70B |
| --- | --- | --- | --- | --- | --- |
| FP16 / BF16 | 2 | ~14 GB | ~28 GB | ~64 GB | ~140 GB |
| INT8 | 1 | ~7 GB | ~14 GB | ~32 GB | ~70 GB |
| INT4 (AWQ/GPTQ) | ~0.5 | ~3.5 GB | ~7 GB | ~16 GB | ~35 GB |

Read against a 16 GB card at vLLM's default 0.92 utilisation — roughly 14.7 GB usable, and KV cache must fit in what remains after weights:

- **7B FP16 on one card:** weights alone ~14 GB. Fits only barely, leaving almost nothing for KV cache. Impractical without lowering utilisation or shortening context.
- **7B INT8 or INT4 on one card:** comfortable, with real KV cache headroom.
- **14B FP16:** exceeds one card. Needs `tensor_parallel_size=2`, or quantisation.
- **32B INT4:** ~16 GB of weights — needs both cards even quantised.
- **70B in any precision:** beyond two cards. Not a candidate on this hardware.

### The constraint that will bite you

These are **consumer Ada cards, which have no NVLink.** Tensor parallelism across them runs over PCIe, and every token generated requires cross-GPU collective operations. Splitting a model across two cards to fit it is very different, in throughput terms, from running two independent copies — one per card — and load-balancing between them.

Which is why PCIe link width per card matters, and why I put it in the probe. On a consumer desktop board the second x16 slot is frequently wired x4, or both drop to x8 when populated. The two GPUs here sit on different root complexes (`02:00.0` versus `81:00.0`), so this needs measuring, not assuming.

If a model fits on one card, prefer one model per card. Reach for tensor parallelism only when the model genuinely does not fit.

---

## 5. Hardware-class observations

Stated as fact, with no judgement about suitability — that is your call.

- **Desktop workstation, not a rack server.** MSI consumer board, desktop chassis, Wi-Fi 7 radio, consumer CPU. No BMC or IPMI was observed, so there is no out-of-band management path; recovery requires physical or in-band access.
- **Consumer memory.** No ECC on this platform *(vendor specification for the 285K/Z890 class)*. DIMM detail still needs the root pass to confirm.
- **~11 TB of storage installed and idle.** `sda` (Seagate 8 TB, serial `ZR1682F1`) and `nvme1n1` (WD SN850X 4 TB, serial `250816800905`) have no partition table, no filesystem, and no mount. Everything runs from `nvme0n1`. Model weights are large and read-heavy; that idle NVMe is directly relevant to any serving role.
- **Two accelerators beyond the GPUs.** The Intel NPU has a driver bound; the **Hailo-8 has no driver bound at all** and is unusable as it stands. Neither is a vLLM target.
- **Image leftovers.** `open-vm-tools`, `vgauth` and `cloud-init` are enabled on bare metal. Harmless, but they indicate this was deployed from a VM-oriented image.
- **34 pending updates, 1 security.** Relevant because a proprietary NVIDIA driver builds against the running kernel; this host runs the HWE kernel (7.0.0-28), so kernel updates and DKMS rebuild behaviour interact.

---

## 6. Decisions required from you

### Decision 1 — how VRAM gets established (blocking)

| Option | What happens | Consequence |
| --- | --- | --- |
| **A. Record unavailable, proceed** | `discovery.md` records `unavailable from current as-found OS/driver state`, preserving model and PCI ID | Fully compliant with Phase 1. Roles get assigned on model identity rather than measured VRAM. |
| **B. Authorise the NVIDIA driver as a Phase 1 exception** | Install proprietary driver on all four GPU servers; `nvidia-smi` then reports VRAM authoritatively | Gives measured VRAM and proves CUDA works. But it mutates hosts during discovery, which Phase 1 exists to prevent, and `discovery.md` would no longer be a pure as-found record. |
| **C. Defer to Phase 2** *(recommended)* | Assign roles using discovered model identity plus vendor specification; if `hxs-1` is later manually assigned a CUDA/vLLM role, the approved NVIDIA driver will be installed during Phase 2, and VRAM measured then | Keeps Phase 1 clean. No role has been assigned yet, so this commits the project to nothing. |

C is the option I would put forward, for one reason: **installing the driver would be role configuration, not diagnostic work.** Installing CUDA on a machine is most of what makes it a CUDA inference server. Doing it during discovery does not just bend the Phase 1 boundary, it performs Phase 2 work and then documents the result as if it were found that way.

The counter-argument is real and you may prefer it: you are assigning roles partly *on* GPU capability, and option C means assigning them on `lspci` model strings plus a specification sheet rather than on measured memory. If two of the four servers turn out to hold different AD103 variants, option C would not reveal that until Phase 2.

For the specific card in question that risk is low — the RTX 4070 Ti SUPER ships in a single 16 GB configuration *(vendor specification)*. It is not a model with 8 GB and 16 GB variants. But I cannot verify from the server that both cards are that exact SKU beyond the shared PCI ID `10de:2705`, which is itself strong evidence.

### Decision 2 — discover servers 2 through 4

Nothing here generalises until they are discovered. Same read-only collector, same method. This is ordinary Phase 1 work and needs no exception — only your time at the keyboard for authentication.

### Decision 3 — servers 5 through 15

Owner-confirmed: these 11 servers have no discrete GPU. That is recorded as fleet input in section 6a and is not re-litigated here. Their individual Phase 1 discoveries must still record the hardware actually observed on each host; the owner statement sets expectation, not evidence.

**Note on fleet access:** the shared fleet SSH identity is already decided as a Phase 2 baseline activity. It is therefore out of scope for Phase 1, and no key will be installed during discovery. Interactive authentication per host remains the Phase 1 method, keeping `discovery.md` free of HX-introduced persistent changes.

---

## 6a. Fleet capability conclusion — owner-confirmed

```text
gpu-bearing servers: 4
confirmed servers without discrete gpu: 11
additional discrete-gpu inference capacity among servers 5-15: none expected
```

The four GPU-bearing servers are therefore the fleet's discrete-GPU inference-capacity pool, unless later direct discovery contradicts this owner-confirmed fact.

This statement is fleet input for planning. It is **not** a substitute for hardware discovery on those 11 servers, and their eventual `discovery.md` records must still reflect direct server evidence collected from each host.

---

## 7. What I need to complete the capability picture

Two probes are prepared and not yet run, both read-only:

1. **Supplementary root pass** — serial, BIOS, DIMM layout, LVM, `ufw` state, `sshd -T`, Secure Boot, pending updates.
2. **VRAM probe, rewritten** to follow `governance/reports/owner_2026-08-11_gpu-vram-discovery-prompt.md` exactly — kernel messages and sysfs only, with PCI BAR sizes explicitly excluded as VRAM evidence. It also captures PCIe link width per GPU, which section 4 shows is a first-order constraint.

Expected outcome of probe 2, stated in advance so the result is not a surprise: `nouveau` on Ada frequently fails to fully initialise because of signed-firmware requirements, and `mem_info_vram_total` is an `amdgpu` attribute that almost certainly will not exist here. **`unavailable` is the likely and correct result**, which routes back to Decision 1.

---

## 8. What I will not do

- assign a role to any server;
- select a workload or a model;
- install a driver, CUDA, vLLM, or any package, on any host, without an explicit project decision;
- write vendor-specification VRAM figures into `discovery.md` as though discovered;
- infer VRAM from PCI BAR size, marketing name, or any other proxy.

---

## 9. Summary

The four GPU servers cannot be evaluated on measured VRAM in their as-found state, because they have no CUDA driver — and that same absence means they cannot currently run CUDA-dependent inference workloads such as vLLM. The gap is one decision wide, not a series of technical problems.

The hardware is eligible for vLLM on every requirement that can be checked without the driver: compute capability, OS, and Python all pass. The practical ceiling is roughly a 14B model in FP16 across both cards, or a 32B at INT4 *(vendor specification)*, with one-model-per-card likely to outperform tensor parallelism given the absence of NVLink.

The most consequential unknown is not VRAM. It is servers 2, 3 and 4, about which nothing at all is known.
