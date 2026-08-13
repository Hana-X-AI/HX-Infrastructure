# hxs-15 — Discovery

**Phase:** 1
**Discovery date:** 2026-08-13

All values below are direct server evidence collected read-only over SSH using the project
collector. No package was installed, no driver loaded or changed, and no configuration
modified. The collector ran with passwordless sudo, so no fact was skipped for lack of
privilege.

The target address, account and privilege state were taken from
`servers/hxs-15/pre-work-results.md` rather than discovered by probing.

## Identity
- Hostname: hxs-15
- FQDN: not configured. No domain suffix is set on the host and no router-side `hx.local.arpa` record existed at discovery time. See act-001
- Manufacturer: HP
- Model: HP EliteDesk 800 G3 DM 65W, a desktop-mini small form factor system
- Baseboard: 829A, KBC version 06.21
- Serial: system serial `8CG8170SVQ`, baseboard serial `PGATU0MNNAQJX9`, chassis serial `8CG8170SVQ`
- System UUID: b6724cfe-b271-5a0d-30d4-ca539886f33b
- SKU: Y3A18AV
- Machine ID: 62cc8758d1854524989541c2af1be5b9
- Chassis type: 35
- BIOS / UEFI: HP P21 version 02.15, release date 2018-01-31. This is the common firmware revision across the EliteDesk 800 G3 units in the fleet
- Boot mode: UEFI
- Secure Boot: disabled

## CPU
- Model: Intel Core i5-7500 at 3.40 GHz, Kaby Lake, family 6 model 158 stepping 9
- Sockets: 1
- Physical cores: 4
- Threads: 4, 1 thread per core. No simultaneous multithreading
- Architecture: x86_64
- NUMA: 1 node
- Frequency range: 800 MHz minimum, 3800 MHz maximum
- **Virtualization: not available to the operating system.** `lscpu` reports no `Virtualization` field at all, the `vmx` flag is absent from the CPU flag list, and the kernel records `Itlb multihit: KVM: Mitigation: VMX unsupported`. The i5-7500 supports VT-x in silicon and the identical part reports `VT-x` on hxs-5, hxs-9, hxs-10, hxs-11, hxs-12 and hxs-14, so this is a firmware setting on this host rather than a different processor. **This is the only host in the fleet where VT-x is not exposed.** Recorded as iss-011. Not changed during Phase 1

## Memory
- Installed RAM: 32 GB total online
- DIMM layout: 2 modules of 16 GB, dual channel. DIMM1 on ChannelB, DIMM3 on ChannelA
- Type / speed: DDR4 SODIMM, configured memory speed 2400 MT/s
- **The two modules are from different manufacturers**: DIMM1 is Hynix `HMA82GS6AFR8N-UH` serial `2BC9FC6B`, DIMM3 is Samsung `M471A2K43CB1-CTD` serial `130FF340`. Both are 16 GB, dual rank, unbuffered, 2400 MT/s and 1.2 V, and both train at their rated speed
- ECC: Error Correction Type reports None
- Maximum capacity: 32 GB across 2 sockets, so memory is fully populated and cannot be expanded
- Swap: file-backed, `/swap.img`, 8 GB, unused

## GPU / Accelerators
- **No discrete GPU detected.** Consistent with the owner-confirmed fleet statement that servers 5 through 15 carry no discrete GPU
- Integrated graphics: Intel HD Graphics 630, PCI ID 8086:5912 at 0000:00:02.0, subsystem 103c:829a Hewlett-Packard, driver `i915` bound
- VRAM: not applicable. Integrated graphics share system memory and no discrete GPU is present. The `i915` driver exposes no VRAM attribute, and firmware reports 32 MB of pre-allocated onboard video memory
- PCIe link: none reported. The device is root-complex integrated rather than on a PCIe slot
- No NVIDIA, AMD or other discrete accelerator devices detected
- No NPU or dedicated AI accelerator detected
- CUDA availability: none. No NVIDIA hardware and no NVIDIA, CUDA or libcuda package installed

## Storage

| Device | Model | Serial | Type | Capacity | Filesystem / Role | Mount |
|---|---|---|---|---|---|---|
| /dev/nvme0n1 | iDsonix | H6W9IXAPYWUIANKVW7VU | NVMe SSD | 238.5 GB | partitioned, in use | see partitions |
| /dev/nvme0n1p1 | partition of nvme0n1 | not applicable | partition | 1 GB | vfat FAT32 | /boot/efi |
| /dev/nvme0n1p2 | partition of nvme0n1 | not applicable | partition | 237.4 GB | ext4 | / |

- Root filesystem usage: 5 percent of 233 GB, 11 GB used, per `df`
- **The storage device is an aftermarket iDsonix unit**, the same brand found in hxs-11 and hxs-14 and unlike the KIOXIA and Western Digital drives elsewhere in the fleet. The original drive appears to have been replaced
- Single storage device, with no additional unallocated drive
- LVM: no physical volumes, volume groups or logical volumes present. Confirmed with sudo, so the empty result is authoritative
- RAID: md subsystem present with no active arrays
- SMART detail: unavailable, smartctl is not installed

## Network
- Primary interface: eno1
- MAC: 10:e7:c6:10:fb:86
- IPv4: 192.168.50.214/24
- Gateway: 192.168.50.1
- DNS: 192.168.50.1, systemd-resolved running in stub mode
- Link speed: 1000 Mb/s, full duplex
- IPv6: link-local only, fe80::12e7:c6ff:fe10:fb86/64
- **Single network interface.** No secondary wired interface and no wireless interface detected
- Listening services: TCP 22 on all interfaces for SSH. TCP and UDP 53 bound only to the systemd-resolved stub addresses

## Operating System
- Distribution: Ubuntu
- Release: 24.04.4 LTS, codename noble
- Kernel: 7.0.0-28-generic, HWE kernel series
- Architecture: x86_64
- Timezone: Etc/UTC. System clock synchronized, NTP service active
- **Update state: 32 packages upgradable.** The login banner reports one of them is a standard security update. This host was not upgraded during preparation, matching hxs-5, hxs-6 and hxs-14, and unlike hxs-7 through hxs-13 which all report 0 pending
- Reboot required: no

## Relevant Existing Software / Services
- openssh-server 1:9.6p1-3ubuntu13.18, present and active
- SSH effective configuration: port 22, PermitRootLogin without-password, PubkeyAuthentication yes, PasswordAuthentication yes, X11Forwarding yes
- python3 3.12.3
- Firewall: ufw reports Status: inactive, and the unit was disabled at boot during human preparation
- Failed units: none
- No NVIDIA, CUDA, ROCm, Docker, containerd, podman, Ollama or vLLM packages are installed
- Absent diagnostic tooling: nvidia-smi, rocminfo, nvme-cli, smartmontools

## Capability Summary
- CPU: 4 physical cores and 4 threads in a single socket, single NUMA domain, no SMT. Kaby Lake desktop silicon
- Memory: 32 GB across 2 slots in dual channel, non-ECC, DDR4 at 2400 MT/s, fully populated at the platform maximum
- GPU: none. Integrated Intel HD Graphics 630 only, suitable for console output rather than compute
- Storage: a single 238.5 GB aftermarket NVMe device carrying the operating system
- Network: single active 1 Gb/s copper link, single interface
- Constraints / notable characteristics:
  - **hardware virtualization is not available.** VT-x is not exposed to the operating system, uniquely in this fleet, so this host cannot run KVM or any hypervisor-backed workload in its current firmware state. Container workloads, which do not require VT-x, are unaffected. See iss-011
  - **32 package updates are pending, including one security update**
  - memory is at the platform maximum of 32 GB and cannot be expanded
  - the two memory modules are from different manufacturers, which is functional here but removes the option of a matched-pair replacement from stock
  - the storage device is an aftermarket replacement rather than the original vendor part, so its endurance and firmware history are not known from vendor records
  - a small form factor desktop-mini chassis with a 65 W power envelope, no discrete GPU and no PCIe expansion capability
  - a single storage device with no redundancy and no spare capacity
  - a single network interface, so no link redundancy
  - memory is non-ECC, and runs dual channel
  - no baseboard management controller or out-of-band management interface was observed
  - ufw is inactive and disabled at boot, so the host is not firewalled
  - SSH currently permits password authentication
  - Secure Boot is disabled

## Notes
- Discovery was performed over SSH to 192.168.50.214 by direct IP using fleet key authentication
- The collector ran with passwordless sudo. No fact was recorded as unavailable due to insufficient privilege
- Human preparation was verified from the pre-work record before collection: hostname correctly set, passwordless sudo confirmed, ufw disabled and its unit disabled at boot, SSH active on port 22, and fleet key authentication confirmed returning `SUDO_NOPASSWD=yes`. The package upgrade step was not performed on this host
- **This host is the sixth member of the `8CG8170Sxx` batch**, alongside hxs-5 `8CG8170SW9`, hxs-9 `8CG8170SW8`, hxs-10 `8CG8170SXM`, hxs-11 `8CG8170SW5` and hxs-12 `8CG8170SWK`. Its baseboard serial `PGATU0MNNAQJX9` also matches the batch pattern. CPU, memory, integrated graphics and firmware revision are identical to those units. The one substantive difference is the absent VT-x
- The pre-work login banner reported 34 updates while `apt list --upgradable` counted 32 at collection time. The `apt` figure is recorded, as it is the direct measurement
- No expected-hardware counts were declared for this host. The owner-confirmed fleet statement that servers 5 through 15 carry no discrete GPU is consistent with what was found
- Vendor specifications were not used to populate any field in this record

**Discovery Status:** COMPLETE

> Role assignment is not performed in this file.
