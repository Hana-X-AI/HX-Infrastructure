# Phase 1 Discovery Report — hxs-5 through hxs-15

**Author:** Claude Opus 5 (Claude Code)
**Reported at:** 2026-08-13
**Scope:** The eleven non-GPU servers. The four GPU-bearing hosts are covered in `Claude-Opus-5_2026-08-12_hxs-1-to-4-discovery-report.md`.
**Status:** All eleven discovered, validated, and synchronized to the registry. **Fleet discovery is complete at 15 of 15.** Phase 2 remains `BLOCKED`. No role assigned.

---

## Headline

All eleven remaining servers are discovered and documented. The owner's statement that servers 5 through 15 carry no discrete GPU is **confirmed on every host by direct evidence**.

**The finding that matters is structural, not a fault.** These eleven machines are small form factor desktop-mini units. Between them they hold zero discrete GPUs, 50 physical cores with no SMT anywhere, 304 GB of RAM, and roughly 2.9 TB of storage — **every byte of which is boot media**. There is not one spare drive, not one free drive bay, and not one PCIe slot across the entire batch. Their capability is fixed at what was found.

Three hosts deviate from the batch in ways that constrain them further, and one carries a firmware condition unique in the fleet.

---

## 1. Fleet position

| Host | IP | Model | CPU | Cores/Threads | RAM | Storage | Firmware date | Secure Boot |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| hxs-5 | .204 | HP EliteDesk 800 G3 DM 65W | i5-7500 | 4 / 4 | 32 GB | 238.5 GB NVMe, KIOXIA | 2018-01-31 | disabled |
| hxs-6 | .205 | HP EliteDesk 800 G4 DM 35W | i5-8500T | 6 / 6 | **15.9 GB** | 238.5 GB NVMe, Toshiba | 2026-02-03 | **enabled** |
| hxs-7 | .206 | HP ProDesk 400 G4 DM | i5-8500T | 6 / 6 | **15.9 GB** | 238.5 GB NVMe, Intel | 2025-07-08 | **enabled** |
| hxs-8 | .207 | **Lenovo** 10T8SMWP00 | i5-9400T | 6 / 6 | **16 GB** | **476.9 GB** NVMe, WD | **2026-03-12** | disabled |
| hxs-9 | .208 | HP EliteDesk 800 G3 DM 65W | i5-7500 | 4 / 4 | 32 GB | 238.5 GB NVMe, WD | 2018-01-31 | disabled |
| hxs-10 | .209 | HP EliteDesk 800 G3 DM 65W | i5-7500 | 4 / 4 | 32 GB | 238.5 GB NVMe, KIOXIA | 2018-01-31 | disabled |
| hxs-11 | .210 | HP EliteDesk 800 G3 DM 65W | i5-7500 | 4 / 4 | 32 GB | 238.5 GB NVMe, **iDsonix** | 2018-01-31 | disabled |
| hxs-12 | .211 | HP EliteDesk 800 G3 DM 65W | i5-7500 | 4 / 4 | 32 GB | 238.5 GB NVMe, KIOXIA | 2018-01-31 | disabled |
| hxs-13 | .212 | HP EliteDesk 800 G3 DM 65W | **i5-6500** | 4 / 4 | 32 GB | 238.5 GB **SATA**, SK hynix | 2020-10-19 | disabled |
| hxs-14 | .213 | HP EliteDesk 800 G3 DM 65W | i5-7500 | 4 / 4 | 32 GB | 238.5 GB NVMe, **iDsonix** | 2024-07-14 | disabled |
| hxs-15 | .214 | HP EliteDesk 800 G3 DM 65W | i5-7500 | 4 / 4 | 32 GB | 238.5 GB NVMe, **iDsonix** | 2018-01-31 | disabled |

```text
Discrete GPUs                 0
VRAM                          0 MiB
Physical cores               50, across 11 sockets
Threads                      50  (no SMT on any host)
Installed RAM               303.8 GB
Raw storage                   2.9 TB, all of it boot media
Free space                    2.5 TB, none on a dedicated data volume
Spare drives / free bays      0
PCIe expansion slots          0
Network interfaces           11 × 1 Gb/s copper, one per host
```

---

## 2. Per-server summary

### hxs-5 — 192.168.50.204

HP EliteDesk 800 G3 DM 65W, firmware P21 02.15 dated 2018-01-31. i5-7500, 4 cores, no SMT. 32 GB DDR4-2400 dual channel. Single 238.5 GB KIOXIA NVMe, 210 GB free.

**Notable:** the first non-GPU host discovered, and the reference configuration for the six-unit `8CG8170Sxx` batch. **32 packages pending**, not upgraded during preparation.

### hxs-6 — 192.168.50.205

HP EliteDesk 800 G4 DM **35 W**, firmware Q21 02.33.00 dated 2026-02-03 — the second newest in the fleet. i5-8500T, 6 cores, no SMT. **15.9 GB DDR4-2667**, 2 × 8 GB. Single 238.5 GB Toshiba NVMe, 214 GB free.

**Notable:** **Secure Boot is enabled**, one of only two hosts in the fleet. Loading an unsigned or DKMS-built kernel module here would require signing and key enrolment, or disabling Secure Boot. Tied for the smallest memory in the fleet. A 35 W envelope, the most thermally constrained chassis in the batch. **32 packages pending.**

### hxs-7 — 192.168.50.206

HP ProDesk 400 G4 DM, firmware Q23 02.31.00 dated 2025-07-08. i5-8500T, 6 cores, no SMT. **15.9 GB in a single 16 GB module — single channel**, with a second slot empty. Single 238.5 GB Intel NVMe, 214 GB free.

**Notable:** **Secure Boot is enabled**, the only other host besides hxs-6. **Memory runs single channel**, halving available bandwidth against the dual-channel hosts, and one slot is free. Carries a **wireless interface, currently DOWN**. 0 packages pending.

### hxs-8 — 192.168.50.207

**Lenovo 10T8SMWP00** — the only non-HP small form factor host in the fleet. Firmware M1UKT79A dated **2026-03-12, the newest platform firmware in the fleet**. i5-9400T, 6 cores, no SMT. **16 GB in a single module — single channel**, second slot empty.

**Notable:** **476.9 GB of storage, double every other host in the batch, with 437 GB free — the largest free capacity of any non-GPU host by a wide margin.** Also single-channel memory with a spare slot, and a **wireless interface, currently DOWN**. 0 packages pending.

### hxs-9 — 192.168.50.208

HP EliteDesk 800 G3 DM 65W, firmware 02.15. i5-7500, 32 GB dual channel. Single 238.5 GB Western Digital SN740 NVMe, 210 GB free. 0 packages pending.

**Notable:** the genuine `hxs-9`, serial `8CG8170SW8`. Its identity had to be established by serial and machine ID after a second machine on the network also reported the name `hxs-9` — see `iss-009`.

### hxs-10 — 192.168.50.209

HP EliteDesk 800 G3 DM 65W, firmware 02.15. i5-7500, 32 GB dual channel. Single 238.5 GB KIOXIA NVMe, 210 GB free. 0 packages pending.

**Notable:** **this host shipped misnamed.** It reported itself as `hxs-9` at discovery time, duplicating the genuine hxs-9 at `.208`. Serial `8CG8170SXM` and machine ID confirmed it was a physically distinct machine, almost certainly imaged from hxs-9 without the hostname being set. No record was written until the owner corrected the hostname; the host was then re-collected and documented normally. `iss-009`, resolved.

### hxs-11 — 192.168.50.210

HP EliteDesk 800 G3 DM 65W, firmware 02.15. i5-7500, 32 GB dual channel. 210 GB free. 0 packages pending.

**Notable:** **the storage device is an aftermarket iDsonix unit**, not the original vendor part. First of three such drives found in the batch.

### hxs-12 — 192.168.50.211

HP EliteDesk 800 G3 DM 65W, firmware 02.15. i5-7500, 32 GB dual channel. Single 238.5 GB KIOXIA NVMe, 210 GB free. 0 packages pending.

**Notable:** nothing distinguishes this host from the batch reference. It is the cleanest match to hxs-5 and hxs-9.

### hxs-13 — 192.168.50.212

HP EliteDesk 800 G3 DM 65W by model name, but **not part of the batch**. Firmware P21 02.37 dated 2020-10-19. **Intel i5-6500 — Skylake, a generation older than the rest.** 32 GB DDR4 at **2133 MT/s**, the slowest memory in the batch. **Intel HD Graphics 530**, not 630.

**Notable:** **the operating system runs from a SATA-attached SSD, not NVMe** — the only host in the fleet that does. Same 238.5 GB capacity, materially lower sequential throughput. Serial `8CG74642Y0` belongs to a different series from the `8CG8170Sxx` batch. **This host shares a model name with five others but is a different machine in CPU, graphics, memory speed, storage interface and firmware. It should not be treated as interchangeable with them.** 0 packages pending.

### hxs-14 — 192.168.50.213

HP EliteDesk 800 G3 DM 65W, firmware P21 **02.50 dated 2024-07-14 — the newest firmware of any EliteDesk 800 G3 in the fleet**. i5-7500, 32 GB dual channel. 210 GB free.

**Notable:** aftermarket **iDsonix** storage. Serial `8CG81608NR` sits outside the `8CG8170Sxx` batch range. **32 packages pending, including one security update.**

### hxs-15 — 192.168.50.214

HP EliteDesk 800 G3 DM 65W, firmware 02.15. i5-7500, 32 GB dual channel across a **Hynix and a Samsung module**. Aftermarket **iDsonix** storage, 210 GB free. Sixth member of the `8CG8170Sxx` batch, serial `8CG8170SVQ`.

**Notable — `iss-011`: hardware virtualization is not available on this host.** `lscpu` emits no `Virtualization` field, the `vmx` flag is absent from the CPU flags, and the kernel records `KVM: Mitigation: VMX unsupported`. Three independent signals agree. The identical i5-7500 reports `VT-x present` on hxs-5, hxs-9, hxs-10, hxs-11, hxs-12 and hxs-14, so the silicon supports it and the cause is a firmware setting. **This is the only host in 15 without VT-x.** **32 packages pending, including one security update.**

---

## 3. The critical finding

### This half of the fleet has no expansion path

The four GPU hosts are tower and desktop systems with PCIe slots and spare drive bays. These eleven are not.

```text
hxs-5, 9, 10, 11, 12, 13, 14, 15   HP EliteDesk 800 G3 DM 65W   desktop-mini
hxs-6                              HP EliteDesk 800 G4 DM 35W   desktop-mini
hxs-7                              HP ProDesk 400 G4 DM         desktop-mini
hxs-8                              Lenovo 10T8SMWP00            small form factor
```

Every one is a 35 W or 65 W desktop-mini chassis. Across all eleven:

- **no discrete GPU, and no PCIe slot to add one**
- **no spare drive, and no free bay to add one.** All 2.9 TB is the boot device
- **no second network interface** on nine of eleven; the two exceptions are wireless and DOWN
- **no baseboard management controller**, so no out-of-band recovery on any host

The consequence: whatever these machines are assigned to do, they will do it with the CPU, the RAM and the single disk they were found with. hxs-7 and hxs-8 have a free memory slot each — that is the only physical upgrade available anywhere in the batch.

### Three hosts are further constrained

**Memory bandwidth.** hxs-7 and hxs-8 run a single DIMM in single-channel mode. They have the least memory in the fleet *and* half the bandwidth to reach it.

**Storage interface.** hxs-13 boots from SATA where all others use NVMe. Same capacity, slower.

**Virtualization.** hxs-15 cannot run KVM or any hypervisor-backed workload in its current firmware state (`iss-011`). Container workloads do not require VT-x and are unaffected.

### Two hosts have Secure Boot enabled

hxs-6 and hxs-7. Every other host in the fleet has it disabled. This is not a defect — it is the more secure configuration — but it is an asymmetry with a practical consequence: any unsigned or DKMS-built kernel module on those two hosts needs signing and key enrolment first. On the four GPU hosts, the NVIDIA open module already taints the kernel precisely because Secure Boot is disabled there.

### Four hosts carry pending updates

hxs-5, hxs-6, hxs-14 and hxs-15 each report **32 packages upgradable, one of them a standard security update**. hxs-7 through hxs-13 were brought to 0 pending during preparation. The four were not. This is preparation drift, not a hardware finding, and it is trivially correctable by the owner.

---

## 4. Common characteristics across all eleven

Every host shares these as-found conditions:

- Ubuntu 24.04.4 LTS, kernel 7.0.0-28-generic HWE, UTC, NTP synchronized, **zero failed units**
- **No discrete GPU**, confirmed by direct PCI enumeration on each host, not inferred
- **Non-ECC memory**
- **No baseboard management controller** observed, so no out-of-band recovery path
- **ufw inactive and disabled at boot**, so no host is firewalled
- **SSH permits password authentication**
- **Single storage device**, carrying the operating system, with no spare capacity
- No NVIDIA, CUDA, ROCm, Docker, containerd, podman, Ollama or vLLM packages installed
- `nvme-cli` and `smartmontools` absent, so **no SMART health data exists for any drive in this batch**
- No FQDN configured; discovery was performed by direct IP throughout. `act-001` is operationally complete and blocked nothing

Two conditions are shared by all but two hosts:

- Secure Boot disabled — except hxs-6 and hxs-7
- Single network interface — except hxs-7 and hxs-8, which add a wireless interface in state DOWN

---

## 5. What this means for role assignment

Stated as constraints only. Role assignment is a manual project decision and none is made here.

**No host in this batch can perform GPU compute.** All eight discrete GPUs and all 122458 MiB of VRAM in the fleet sit on hxs-1 through hxs-4. That is a hardware fact, not a configuration gap, and no change to these eleven machines alters it.

**Storage is the binding constraint for anything that holds large files.** The batch offers 2.5 TB free, but it is distributed as 210 GB on eight hosts, 214 GB on two, and 437 GB on hxs-8 — all of it on the same device the operating system boots from. There is no dedicated data volume anywhere in the batch, and no bay to create one. hxs-8 has both the largest free capacity and the newest firmware.

**Three hosts have materially less memory than the rest.** hxs-6, hxs-7 and hxs-8 hold 16 GB where the other eight hold 32 GB, and two of the three run single channel. hxs-7 and hxs-8 each have one free DIMM slot, which is the only expansion available in the batch.

**hxs-13 is not interchangeable with the units it resembles.** It carries the same model name as five other hosts but differs in CPU generation, integrated graphics, memory speed and storage interface. Treating it as a drop-in equivalent would be a mistake.

**hxs-15 cannot host a hypervisor** until `iss-011` is resolved by a firmware change.

**hxs-6 and hxs-7 need Secure Boot handled** before any unsigned or DKMS-built module is loaded on them.

---

## 6. Phase 1 gate

```text
phase 1 gate
servers expected:     15
servers registered:   15
discovery complete:   15
discovery incomplete:  0
roles assigned:        0
roles unassigned:     15

phase 1: not complete
phase 2: blocked
```

Gate conditions:

```text
[x] Every expected server is present in the registry
[x] Every server has a complete discovery.md
[x] Fleet hardware capabilities are documented and comparable
[ ] Fleet capabilities have been manually reviewed
[ ] Every server has a manually assigned role
[ ] Every assigned role is recorded in SERVER-REGISTRY.md
[x] No role-specific configuration has begun
```

**Discovery is finished. The remaining three conditions are all human decisions**, tracked as `act-012`. Phase 2 stays `BLOCKED` until they complete.

The comparability condition was closed on 2026-08-13 after verification and repair. All 15 records carry the same 10 sections, no record holds an unresolved placeholder, every factual registry column is populated, and all 15 pass the `hx-validate-discovery` hook. Verification also exposed a class of defect worth naming: **cross-host claims written while the fleet was only partly discovered had silently become false.** hxs-6 claimed the newest firmware in the fleet — hxs-8 is newer. hxs-6 claimed to be the only host with Secure Boot — hxs-7 also has it. hxs-4 claimed the smallest memory and the smallest storage — three later hosts are smaller in both. hxs-8 claimed second-newest firmware when it is in fact the newest. The four GPU hosts still stated that no NVIDIA packages were installed, which the approved driver install had made false. Batch-membership notes counted four or five members where six now exist. hxs-10 and hxs-11 were missing the root filesystem usage line that the other nine carried. **Twenty-seven corrections across thirteen records were applied**, and the two missing figures were recovered from retained collector output rather than by re-contacting the hosts.

Regression suite: **153 pass, 0 fail.** This is down from 161 at the hxs-1-to-4 report. The suite file was quarantined by Norton 360 on 2026-08-12 (`iss-010`) and recovered from `HEAD`; eight collector assertions added after that commit have not yet been re-added, and the file currently runs under a temporary name because the canonical path is still write-locked.

---

## 7. Open items from this batch

| Item | Priority | Summary |
| --- | --- | --- |
| `act-012` | **high** | Manual fleet capability review and role assignment. This is the entire remaining Phase 1 gate |
| `iss-011` | open | hxs-15 does not expose VT-x. Firmware setting, human-performed |
| `iss-010` | open | Norton quarantined the regression suite. Canonical path still write-locked pending a workstation reboot; 8 assertions to re-add |
| `act-005` | open | **No off-machine copy of this repository.** Nothing committed since `c5dd045`. The complete discovery record for 15 servers exists on one workstation |
| `act-011` / `iss-001` | backlog | Router-side DNS records are not proven to survive a reboot |
| `iss-004` | open | Residual: mdadm short flags `-a`, `-r`, `-f` are unguarded |

`iss-009` (duplicate hostname on hxs-10) was raised and resolved within this batch.

---

## 8. Process outcome

The batch ran as intended. After the preparation checklist gained passwordless sudo and fleet key authorization, **each of the eleven servers took one unattended command and zero prompts.** hxs-6 through hxs-15 were collected and documented at a steady cadence with no authentication failures and no repeat collections, apart from hxs-10 which was re-collected after its hostname was corrected.

Three process defects were found and corrected during the batch, all recorded in `lessons-learned.md`:

- **`ll-024` — the pre-work file was not read before acting.** On hxs-5 the gating step was run in the same batch as network probes of two candidate addresses, while announcing that the step was being followed. The file already stated the address, the account and the privilege state. The skill now requires step 0 to complete before the target is contacted in any way, not concurrently with other calls
- **`ll-025` — the collector named its output from a host-controlled value.** Output was `<hostname>-facts.txt`, so collecting the misnamed `.209` silently destroyed the genuine hxs-9 collection. Output is now `<hostname>-<last-octet>-facts.txt` and the script warns on overwrite. That fix is why the hxs-10 and hxs-11 figures were still recoverable for this report
- **`ll-026` — a hostname is a claim, not an identity.** The duplicate `hxs-9` was separated only by serial and machine ID. No discovery record is now written when a host's reported name contradicts its intended one

A fourth lesson came out of the comparability work at the end of the batch:

- **`ll-029` — batch identity does not imply configuration identity.** hxs-15 matches five other machines in serial range, model, CPU, memory, graphics and firmware, and is the only host in the fleet without VT-x. Nothing about it predicted that. It surfaced only from comparing one field across all 15 records

The declared-hardware cross-check could not be exercised in this batch: **no expected-hardware counts were declared for any of the eleven hosts.** The owner's fleet-level statement that servers 5 through 15 carry no discrete GPU served as the check instead, and every host was consistent with it.
