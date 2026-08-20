# HXS-1 MVP-1 — Constraint Sheet

**Purpose:** the five research records in this directory are *evidence*. This page is the
*execution* distillation — every constraint they establish that changes what an operator or agent
types, with everything else stripped out.

**Scope:** HXS-1 only. OS to first message sent and answered. Dev/test environment — no hardening.
**Done means:** a prompt sent to the endpoint returns a coherent response. Nothing else.

---

## Do this

| # | Action | Why |
|---|---|---|
| 1 | Pull **`qwen3.8:27b-q4_K_M`**, digest `25b843619e94` | Bare `qwen3.8:27b` is digest `22130167c4c2` — the **MTP variant**, a different artifact at the same 18 GB |
| 2 | Capture GPU UUIDs before anything else | Never recorded for this host; the fit gate blocks without them |
| 3 | Pin GPUs by **UUID, never index** | Indexes reorder across reboots (`iss-013`) |
| 4 | Resolve the model-store disk by **serial `250816800905`** | NVMe enumeration already changed once on this host; root moved `nvme1n1` → `nvme0n1` |
| 5 | Mount by **UUID** in fstab, with `nofail` | No BMC on this host — a failed data disk must not block boot |
| 6 | Set `OLLAMA_HOST=127.0.0.1:11434` | Ollama has **no authentication of any kind** |
| 7 | Set `OLLAMA_CONTEXT_LENGTH` explicitly; verify with `ollama ps` | Default is VRAM-tiered and this host sits on a tier boundary |
| 8 | Set `OLLAMA_FLASH_ATTENTION=1` if using `OLLAMA_KV_CACHE_TYPE` | KV quantization is **gated on flash attention**; without it the setting silently does nothing |
| 9 | Set samplers explicitly — thinking `1.0 / 0.95 / 20 / 0.0 / 0.0`, instruct `0.7 / 0.80 / 20 / 0.0 / 1.5` | No HX record has ever specified samplers; defaults make this model measurably worse |
| 10 | Set reasoning effort deliberately | Defaults to **`xhigh`**, the most expensive setting |
| 11 | `systemctl daemon-reload` + restart after the drop-in | A drop-in has no effect until reloaded |

## Do not do this

| Action | Why |
|---|---|
| Pull `27b-nvfp4` | Shares a digest with the MLX build, and NVFP4 requires Blackwell — our cards are Ada 8.9 |
| Pull Q8_0 (30 GB) or BF16 (56 GB) | Q8_0 leaves 2.2 GB for KV; BF16 does not fit at all |
| Plan for single-card operation | 18 GB does not fit 16.10 GB usable per card — **both GPUs mandatory** |
| Write anything to `/dev/sda` | ST8000DM004 is **SMR** — sustained writes collapse after cache exhaustion |
| Install CUDA Toolkit, Python, or PyTorch | Ollama needs **none of them** — Go binary, CUDA compiled in, driver is the only dependency |
| Touch the NVIDIA driver | 580.173.02 / CUDA 13.0 is installed and validated. It clears CUDA 13.0 **only** — 13.1 would need 590.44.01 |
| Partition by device name | See #4 — the highest-consequence hazard on this host |
| Provision 2× space for downloads | Both Ollama and HF download **in place** with same-filesystem atomic promotion |
| Try to fix `iss-015` | Silent prompt truncation is open and upstream. Set a sane context and move on |

---

## Two read-only checks that gate MVP-1

```bash
# 1. GPU identity — never captured for this host
nvidia-smi --query-gpu=index,uuid,name,memory.total,pci.bus_id,driver_version --format=csv
nvidia-smi -L

# 2. PCIe link width on GPU1 — discovery recorded x4 against an x16-capable slot.
#    Width does not recover under load. Use lspci, NOT nvidia-smi's pcie.link.width.max,
#    which reports device capability rather than slot width.
for BDF in $(nvidia-smi --query-gpu=pci.bus_id --format=csv,noheader | sed 's/^0000\{0,1\}://I'); do
  echo "== $BDF =="; sudo lspci -vvs "$BDF" | grep -E 'LnkCap:|LnkSta:'
done
```

The link-width result does not block MVP-1 under Ollama — layer split tolerates ×4. It is captured
now because it is free at this point and it decides the MVP-2 runtime question.

---

## Budget, for sanity checking only

hxs-1 usable: **32.20 GB** decimal (32,752 MiB less 2 × 1 GiB CUDA context).
Chosen artifact 18 GB → **+14.20 GB** for KV. Comfortable. Not a constraint at MVP-1.

---

## Deferred — do not let these into MVP-1

LM Studio / Bionic (**ruled out**) · hardening of any kind · fine-tuning and its Python/PyTorch
dependency chain · SMART monitoring · backup and redundancy · NFS export · the HXS-1→HXS-4
repeatable pattern · vision/multimodal testing · MTP A/B · quantization comparison · context-ladder
measurement · benchmarking · repository migration · acceptance suite beyond one smoke test.

---

*Distilled 2026-08-17 from the five research records in this directory. Those records remain the
evidence and are unchanged — they are deliberately not rewritten as plans, because a research
record that becomes a plan stops being checkable. This page is the bridge.*
