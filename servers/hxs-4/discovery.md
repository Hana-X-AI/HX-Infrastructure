# hxs-4 — Discovery

**Phase:** 1
**Discovery date:** 2026-08-12

All values below are direct server evidence collected read-only over SSH using the project
collector. No package was installed, no driver loaded or changed, and no configuration
modified. The collector ran with passwordless sudo, so no fact was skipped for lack of
privilege.

The project owner declared two discrete GPUs physically installed. The operating system
enumerates two. The declared and observed counts agree.

## Identity
- Hostname: hxs-4
- FQDN: not configured. No domain suffix is set and no `hx.local.arpa` record exists yet (see act-001)
- Manufacturer: iBUYPOWER
- Model: system product name field reads `Intel(R) Core(TM) i7-14700F`, which the system builder populated with the processor name rather than a system model. Baseboard is ASUS PRIME B760M-A AX6 II
- Serial: system serial `1750840-100`, baseboard serial `250351617100731`. Chassis serial reads `Default string`, not programmed
- Machine ID: a3244b92b98448ad83da8ecad6511889
- Chassis type: desktop
- BIOS / UEFI: version 1820, release date 2025-05-15
- Boot mode: UEFI
- Secure Boot: disabled

## CPU
- Model: Intel Core i7-14700F
- Sockets: 1
- Physical cores: 20
- Threads: 28, hybrid topology of performance cores with simultaneous multithreading and efficiency cores without
- Architecture: x86_64
- NUMA: 1 node
- Virtualization: VT-x present

## Memory
- Installed RAM: 32 GB total online, 31 GiB reported usable by the running kernel
- DIMM layout: 2 modules of 16 GB. Two further slots are unpopulated on a four-slot board
- Type / speed: DDR5, configured memory speed 5600 MT/s
- ECC: Error Correction Type reports None
- Swap: file-backed

## GPU / Accelerators
- GPU count: 2 discrete NVIDIA GPUs enumerated, matching the two declared as installed. No integrated graphics; the i7-14700F is an F-series processor without integrated graphics
- **The two GPUs are not identical.** They carry different PCI device IDs and report different VRAM capacities
- Chip: NVIDIA GB206 on both, directly reported by the kernel

### GPU at 0000:01:00.0
- PCI ID: 10de:2d04
- Board partner / subsystem ID: PNY 196e:143e, the same card model as the working GPU in hxs-3
- VRAM: 16311 MiB, directly reported
- VRAM source: kernel message `nouveau 0000:01:00.0: drm: VRAM: 16311 MiB`
- Driver: nouveau, bound and initialized successfully
- PCIe link: negotiated 2.5 GT/s at width x8; device maximum 32.0 GT/s at width x16

### GPU at 0000:07:00.0
- PCI ID: 10de:2d05
- Board partner / subsystem ID: MSI 1462:5371. This is an MSI card that initializes normally, and is a different subsystem device ID from the MSI 1462:5351 cards that fail in hxs-2
- VRAM: 8151 MiB, directly reported
- VRAM source: kernel message `nouveau 0000:07:00.0: drm: VRAM: 8151 MiB`
- Driver: nouveau, bound and initialized successfully
- PCIe link: negotiated 2.5 GT/s at width x4; device maximum 32.0 GT/s at width x16

### Combined
- Total VRAM: 24462 MiB across both GPUs, in an asymmetric 16311 / 8151 split
- Model names: not identified by the host. `lspci` reports both as `NVIDIA Corporation Device` with no model string, indicating the installed PCI ID database predates these devices
- UUIDs: unavailable. GPU UUIDs are reported by `nvidia-smi`, which requires the proprietary driver
- CUDA availability: none in the as-found state. The proprietary NVIDIA driver is not installed and no nvidia, cuda or libcuda package is present
- No other accelerator devices detected

### Post-directive driver validation, 2026-08-12

The sections above record the as-found state under `nouveau`. The project owner subsequently
installed the NVIDIA driver on this host as well, extending
`governance/nvidia-driver-install-directive.md` beyond its stated scope of hxs-2 and hxs-3.
That is an approved Phase 1 exception and an HX-introduced change, recorded separately here so
the as-found record remains intact.

- Driver installed: `nvidia-driver-580-server-open`, module version 580.173.02, licence Dual MIT/GPL
- **Both GPUs initialize and are bound to `nvidia`.** No GPU remains on `nouveau`
- **GPU models, authoritatively identified by the driver.** The asymmetry recorded during discovery is confirmed as two different products:
  - `0000:01:00.0`, PNY 196e:143e, PCI 10de:2d04: **NVIDIA GeForce RTX 5060 Ti**, 16311 MiB, 180 W
  - `0000:07:00.0`, MSI 1462:5371, PCI 10de:2d05: **NVIDIA GeForce RTX 5060**, 8151 MiB, 145 W
- VRAM confirmed by `nvidia-smi`: 24462 MiB total. **Both figures exactly match those `nouveau` reported during discovery**, validating the kernel-message VRAM method
- CUDA runtime version reported by the driver: 13.0
- Kernel message, benign: `nvidia: module verification failed: signature and/or required key missing - tainting kernel`, expected because Secure Boot is disabled and the open module is unsigned. No LTR warning appears on this host, unlike the two X99 machines

## Storage

| Device | Model | Serial | Type | Capacity | Filesystem / Role | Mount |
|---|---|---|---|---|---|---|
| /dev/nvme0n1 | WD Green SN3000 1TB | 25141G804732 | NVMe SSD | 931.5 GB | partitioned, in use | see partitions |
| /dev/nvme0n1p1 | partition of nvme0n1 | not applicable | partition | 1 GB | vfat FAT32 | /boot/efi |
| /dev/nvme0n1p2 | partition of nvme0n1 | not applicable | partition | 930.5 GB | ext4 | / |
| /dev/nvme1n1 | ADATA LEGEND 700 | 4O4020822989 | NVMe SSD | 476.9 GB | no partition table, no filesystem | not mounted |

- Root filesystem usage: 1.2 percent of 914.78 GB
- LVM: no physical volumes, volume groups or logical volumes present
- RAID: no active arrays
- A 476.9 GB NVMe device is installed, unpartitioned and unused
- SMART detail: unavailable, smartctl is not installed

## Network
- Primary interface: eno1
- MAC: bc:fc:e7:3e:10:66
- IPv4: 192.168.50.203/24
- Gateway: 192.168.50.1
- DNS: 192.168.50.1, systemd-resolved running in stub mode
- Link speed: 1000 Mb/s, full duplex
- IPv6: link-local only, fe80::befc:e7ff:fe3e:1066/64
- Secondary interface: wlp6s0 wireless with MAC d8:b3:2f:63:4a:99, state DOWN
- Listening services: TCP 22 on all interfaces for SSH. TCP and UDP 53 bound only to the systemd-resolved stub addresses

## Operating System
- Distribution: Ubuntu
- Release: 24.04.4 LTS, codename noble
- Kernel: 7.0.0-28-generic, HWE kernel series
- Architecture: x86_64
- Timezone: Etc/UTC. System clock synchronized, NTP service active
- Update state: 32 packages upgradable at time of discovery
- Reboot required: no

## Relevant Existing Software / Services
- openssh-server present and active
- SSH effective configuration: port 22, PermitRootLogin without-password, PubkeyAuthentication yes, PasswordAuthentication yes, X11Forwarding yes
- python3 3.12.3
- Firewall: ufw reports Status: inactive, and the unit was disabled at boot during human preparation
- Failed units: none
- **As found**, no NVIDIA, CUDA, ROCm, Docker, containerd, podman, Ollama or vLLM packages were installed. `nvidia-driver-580-server-open` and `nvidia-utils-580-server` were installed afterwards under the approved directive, so NVIDIA packages are present on this host now. Nothing else in this list changed. See `driver-results.md` and act-010
- Absent diagnostic tooling as found: nvidia-smi, rocminfo, nvme-cli, smartmontools. `nvidia-smi` is present since the driver install; the other three remain absent

## Capability Summary
- CPU: 20 physical cores and 28 threads in a single socket, hybrid performance and efficiency core topology, single NUMA domain
- Memory: 32 GB across 2 of 4 populated slots, non-ECC, DDR5 at 5600 MT/s. This is the smallest memory configuration of the four GPU hosts. Across the complete fleet, hxs-6, hxs-7 and hxs-8 are smaller at 16 GB
- GPU: 2 discrete NVIDIA GB206 devices with 16311 MiB and 8151 MiB of VRAM, 24462 MiB combined, both measured from kernel reporting. Both are bound to the open-source nouveau driver and initialized successfully, so no CUDA runtime exists in the as-found state
- Storage: 931.5 GB NVMe in use for the operating system at 1.2 percent, plus a 476.9 GB NVMe installed but entirely unallocated. Total installed storage is roughly 1.4 TB, the smallest of the four GPU hosts. Across the complete fleet the small form factor hosts carry less still, at a single 238.5 GB or 476.9 GB device
- Network: single active 1 Gb/s copper link
- Constraints / notable characteristics:
  - the two GPUs are asymmetric in both VRAM and host bandwidth, at 16311 MiB on x8 and 8151 MiB on x4. Work that assumes matched GPUs would be constrained by the smaller device
  - both GPUs negotiate below their maximum width, x8 and x4 against a device maximum of x16
  - both report a negotiated link speed of 2.5 GT/s against a 32.0 GT/s maximum, consistent with idle power management but not confirmed under load
  - system memory of 32 GB is smaller than the combined 24462 MiB of VRAM, which limits headroom for staging model weights in host RAM
  - memory is non-ECC
  - no baseboard management controller or out-of-band management interface was observed
  - ufw is inactive and disabled at boot, so the host is not firewalled
  - SSH currently permits password authentication, and X11 forwarding is enabled
  - Secure Boot is disabled

## Notes
- Discovery was performed over SSH to 192.168.50.203 by direct IP using fleet key authentication. Persistent `hx.local.arpa` DNS is not established; act-001 remains open and did not block this discovery
- The collector ran with passwordless sudo. No fact was recorded as unavailable due to insufficient privilege
- Human preparation for this host was verified before collection: passwordless sudo confirmed, ufw disabled and its unit disabled at boot, SSH active on port 22, and fleet key authentication confirmed returning `SUDO_NOPASSWD=yes`
- Declared hardware cross-check: two discrete GPUs declared installed, two enumerated by the operating system. Counts agree
- This host is the only one of the four GPU hosts with programmed system and baseboard serial numbers. Every small form factor host, hxs-5 through hxs-15, also carries programmed serials
- Vendor specifications were not used to populate any field in this record

**Discovery Status:** COMPLETE

> Role assignment is not performed in this file.
