# Phase 1 Discovery Report — hxs-1 through hxs-4

**Author:** Claude Opus 5 (Claude Code)
**Reported at:** 2026-08-12
**Scope:** The four GPU-bearing servers. Servers 5 through 15 are owner-confirmed as having no discrete GPU and are not covered here.
**Status:** All four discovered, audited, and synchronized to the registry. Phase 2 remains `BLOCKED`. No role assigned.

---

## Headline

All four GPU servers are discovered and documented. **The fleet's GPU capacity is materially worse than the hardware inventory suggests.**

Seven GPUs are installed across the four hosts. Five are enumerated by their operating systems. Three hosts report measurable VRAM. **Two hosts carry open hardware faults that make four of the seven GPUs unusable today.**

Both faults are on the same two machines, and they are the only two machines in the fleet running 2016-era firmware. That correlation is the most useful lead in this report, and it is recorded as a hypothesis to be tested, not as a conclusion.

---

## 1. Fleet position

| Host | IP | CPU | RAM | GPUs installed | GPUs enumerated | Measurable VRAM |
| --- | --- | --- | --- | --- | --- | --- |
| hxs-1 | .200 | Core Ultra 9 285K, 24c/24t | 128 GB | 2 | 2 | **32752 MiB** |
| hxs-2 | .201 | i7-5960X, 8c/16t | 66 GB | 2 | 2 | **none** |
| hxs-3 | .202 | i7-5960X, 8c/16t | 66 GB | 2 | **1** | **16311 MiB** |
| hxs-4 | .203 | i7-14700F, 20c/28t | 32 GB | 2 | 2 | **24462 MiB** |

```text
GPUs installed        7
GPUs enumerated       5
GPUs usable today     5 enumerated, of which 5 report VRAM on 3 hosts
Total measured VRAM   73525 MiB across hxs-1, hxs-3, hxs-4
Unusable capacity     hxs-2 entirely, plus one card on hxs-3
```

---

## 2. Per-server summary

### hxs-1 — 192.168.50.200

MSI PRO Z890-P WIFI, firmware 1.A80 dated 2025-01-07. Core Ultra 9 285K, 24 cores, no SMT. 128 GB DDR5 non-ECC, all four slots populated.

**GPUs:** 2 × NVIDIA AD103, PCI `10de:2705`, **16376 MiB each, 32752 MiB total**, measured from kernel reporting. Both bound to `nouveau`.

**Notable:** the second GPU negotiates **x4** against a device maximum of x16, so the two cards do not have equal host bandwidth. Also carries an Intel NPU with its driver bound, and a **Hailo-8 AI accelerator with no driver bound** at x2 of a maximum x4. Roughly 11 TB of storage installed and entirely unallocated.

### hxs-2 — 192.168.50.201

Gigabyte X99-UD5 WIFI-CF, firmware F22 dated **2016-06-13**. i7-5960X, 8 cores / 16 threads. 66 GB non-ECC at 2133 MT/s across 8 slots.

**GPUs:** 2 × NVIDIA **GB206**, PCI `10de:2d04`. **VRAM unavailable.**

**Fault — `iss-008`:** `nouveau` identifies both chips correctly, then aborts on each with `drm: Device allocation failed: -22`, leaving no driver bound. The same GB206 initializes normally on hxs-3 under an identical kernel, so the failure is specific to this host or these cards rather than to the chip or the kernel.

This host contributes **no GPU capacity at all** in its as-found state.

### hxs-3 — 192.168.50.202

Identical platform to hxs-2: Gigabyte X99-UD5 WIFI-CF, firmware F22 dated 2016-06-13, i7-5960X, 66 GB.

**GPU:** 1 × NVIDIA GB206, PCI `10de:2d04`, **16311 MiB**, measured. Bound to `nouveau` and working.

**Fault — `iss-007`:** two GPUs are physically installed. The operating system enumerates one. The missing card produces **no kernel message whatsoever** — not a failed probe, nothing. It is not appearing on the PCI bus at all. Candidate causes are seating, slot power, a slot disabled in firmware, or a failed card.

This host runs at **half its installed GPU capacity**.

### hxs-4 — 192.168.50.203

iBUYPOWER system on ASUS PRIME B760M-A AX6 II, firmware 1820 dated 2025-05-15. i7-14700F, 20 cores / 28 threads hybrid. **32 GB DDR5**, 2 of 4 slots populated. The only host with programmed system and baseboard serial numbers.

**GPUs:** 2 × NVIDIA GB206, both bound and initialized, but **not a matched pair**:

| PCI | Device ID | VRAM | PCIe negotiated | Device maximum |
| --- | --- | --- | --- | --- |
| `01:00.0` | `10de:2d04` | 16311 MiB | x8 | x16 |
| `07:00.0` | `10de:2d05` | **8151 MiB** | **x4** | x16 |

**24462 MiB combined, asymmetric.** Any workload assuming matched GPUs is constrained by the 8 GB card.

**Notable:** 32 GB of system RAM is **less than the 24462 MiB of combined VRAM**, leaving little headroom for staging weights in host memory. Total installed storage is roughly 1.4 TB, the smallest in the fleet.

---

## 3. The critical finding

### Four of seven GPUs are unusable, and both faults sit on the two oldest boards

```text
hxs-1   Z890, firmware 2025-01-07, 2 GPUs   both work
hxs-4   B760, firmware 2025-05-15, 2 GPUs   both work
hxs-2   X99,  firmware 2016-06-13, 2 GPUs   both fail with -22
hxs-3   X99,  firmware 2016-06-13, 2 GPUs   only 1 enumerates
```

### Working hypothesis, recorded as `act-007`

Both faults may share a single cause: **insufficient 64-bit PCI address space, because Above 4G Decoding is disabled in the 2016-era X99 firmware.**

Supporting reasoning:

- `-22` is `EINVAL`, which is what BAR allocation returns when MMIO space is exhausted
- 16 GB-class GPUs require large 64-bit BARs that a 2016 BIOS will not map without Above 4G Decoding enabled
- it explains both symptoms from one cause: on hxs-2 two large cards exhaust the window and both fail; on hxs-3 the available space accommodates one card and the second never enumerates
- the two hosts that work are precisely the two on modern firmware

**This is a hypothesis, not a diagnosis.** No BAR evidence has been collected. The discovery collector could not have found it: its kernel-log filter targets GPU memory strings and does not match PCI subsystem messages. The absence of BAR errors in the discovery output is an artefact of that filter, not evidence that none occurred. This is recorded as `ll-016`.

### Confirming test — ready to run

`.claude/skills/discover-server/scripts/hx-gpu-diagnose.sh` collects the deciding evidence, read-only:

- PCI enumeration and BAR assignment errors from `dmesg`, unfiltered by GPU-specific terms
- each GPU's BAR assignments, with an explicit above-4G or below-4G marker per BAR
- bridge topology via `lspci -tv`
- 64-bit MMIO windows from `/proc/iomem`
- firmware version and baseboard identity
- nouveau firmware availability

If the hypothesis holds, the remedy is a firmware setting change — **a human-performed action outside Phase 1 scope**, and one that must not be attempted by automation.

If it does not hold, hxs-3's silent card points at seating, slot power or a dead device, and hxs-2 needs a different line of investigation.

---

## 4. Common characteristics across all four

Every host shares these as-found conditions:

- Ubuntu 24.04.4 LTS, kernel 7.0.0-28-generic, UTC, NTP synchronized, zero failed units
- **No NVIDIA proprietary driver, no CUDA, no vLLM, no Ollama, no container runtime.** No host can run CUDA-dependent inference in its as-found state
- **Non-ECC memory** on all four
- **No baseboard management controller** observed on any host, so no out-of-band recovery path
- **Secure Boot disabled** on all four
- **ufw inactive** on all four, so no host is firewalled
- **SSH permits password authentication** on all four
- Significant unallocated storage on every host
- No FQDN configured; `act-001` remains open and blocked nothing

---

## 5. What this means for role assignment

Stated as constraints only. Role assignment is a manual project decision and none is made here.

**hxs-2 and hxs-3 cannot be assessed for GPU roles yet.** Their true capability is unknown until `act-007` completes. Assigning a role to either on current evidence would be assigning it on incomplete information — hxs-2 might have 32 GB of VRAM or none, depending on the outcome.

**hxs-1 and hxs-4 have measured, usable GPU capacity**, at 32752 MiB and 24462 MiB respectively. Both are constrained by consumer-platform characteristics: no ECC, no out-of-band management, and PCIe links below device maximum. hxs-4 is additionally constrained by 32 GB of system RAM against 24462 MiB of VRAM.

**No host can serve models today.** All four need the proprietary NVIDIA driver installed before any CUDA-dependent stack runs, and that is Phase 2 role configuration, conditional on a role being assigned.

---

## 6. Phase 1 gate

```text
phase 1 gate
servers expected:     15
servers registered:    4
discovery complete:    4
discovery incomplete:  0
roles assigned:        0
roles unassigned:      4

phase 1: not complete
phase 2: blocked
```

Blockers: 11 servers undiscovered, no roles assigned. Both expected.

Regression suite: 161 pass, 0 fail.

---

## 7. Open items from this batch

| Item | Priority | Summary |
| --- | --- | --- |
| `act-007` | **critical** | Diagnose hxs-2 and hxs-3 GPU faults before either is considered for a role |
| `iss-007` | critical | hxs-3 second GPU not enumerated by the operating system |
| `iss-008` | critical | hxs-2 both GPUs abort nouveau initialization with `-22` |
| `act-001` | open | Persistent router-side DNS. Did not block any discovery |
| `act-005` | open | No off-machine copy of this repository |

---

## 8. Process outcome

The workflow reached the intended state during this batch. hxs-1 took four failed authentication attempts and two collection passes. hxs-2, hxs-3 and hxs-4 each took **one unattended command and zero prompts**, after the human preparation checklist gained passwordless sudo and fleet key authorization.

Two process defects were found and corrected mid-batch, both recorded in `lessons-learned.md`:

- pre-work records were not being read before collection, which is how hxs-3's GPU discrepancy reached a written record before being caught by the owner rather than by the process. The `discover-server` skill now makes reading and cross-checking pre-work step 0, and the handoff now carries declared hardware counts
- a narrow extraction filter discarded facts the collector had correctly captured, including the GB206 chip identity and the `-22` initialization failure

The declared-hardware cross-check worked as designed on hxs-4: two declared, two enumerated, agreement recorded.
