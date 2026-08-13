# hxs-5 — Discovery

**Phase:** 1
**Discovery date:** 2026-08-12

All values below are direct server evidence collected read-only over SSH using the project
collector. No package was installed, no driver loaded or changed, and no configuration
modified. The collector ran with passwordless sudo, so no fact was skipped for lack of
privilege.

The target address, account and privilege state were taken from
`servers/hxs-5/pre-work-results.md` rather than discovered by probing.

## Identity
- Hostname: hxs-5
- FQDN: not configured. No domain suffix is set on the host. A router-side record for `hxs-5.hx.local.arpa` did not exist at the time of discovery, although records for hxs-1 through hxs-4 did. See act-001
- Manufacturer: HP
- Model: HP EliteDesk 800 G3 DM 65W, a desktop-mini small form factor system
- Baseboard: 829A
- Serial: system serial `8CG8170SW9`, baseboard serial `PGATU0MNNAQJRV`, chassis serial `8CG8170SW9`
- Machine ID: b5bf3ee8892545f1b5d15d830021b4e9
- Chassis type: 35, mini PC
- BIOS / UEFI: HP P21 version 02.15, release date 2018-01-31
- Boot mode: UEFI
- Secure Boot: disabled

## CPU
- Model: Intel Core i5-7500 at 3.40 GHz
- Sockets: 1
- Physical cores: 4
- Threads: 4, 1 thread per core. No simultaneous multithreading
- Architecture: x86_64
- NUMA: 1 node
- Virtualization: VT-x present

## Memory
- Installed RAM: 32 GB total online, 31 GiB reported usable by the running kernel
- DIMM layout: 2 modules of 16 GB
- Type / speed: DDR4, configured memory speed 2400 MT/s
- ECC: Error Correction Type reports None
- Swap: file-backed

## GPU / Accelerators
- **No discrete GPU detected.** This is consistent with the owner-confirmed fleet statement that servers 5 through 15 carry no discrete GPU
- Integrated graphics: Intel HD Graphics 630, PCI ID 8086:5912 at 0000:00:02.0, subsystem Hewlett-Packard 103c:829a, driver `i915` bound
- VRAM: not applicable. Integrated graphics share system memory and no discrete GPU is present
- No NVIDIA, AMD or other discrete accelerator devices detected
- No NPU or dedicated AI accelerator detected
- CUDA availability: none. No NVIDIA hardware and no NVIDIA, CUDA or libcuda package installed

## Storage

| Device | Model | Serial | Type | Capacity | Filesystem / Role | Mount |
|---|---|---|---|---|---|---|
| /dev/nvme0n1 | KBG50ZNS256G NVMe KIOXIA 256GB | 92HPHA13Q69K | NVMe SSD | 238.5 GB | partitioned, in use | see partitions |
| /dev/nvme0n1p1 | partition of nvme0n1 | not applicable | partition | 1 GB | vfat FAT32 | /boot/efi |
| /dev/nvme0n1p2 | partition of nvme0n1 | not applicable | partition | 237.4 GB | ext4 | / |

- Root filesystem usage: 4.7 percent of 232.64 GB
- **Single storage device**, with no additional unallocated drive. Across the complete fleet this is the pattern for every small form factor host, hxs-5 through hxs-15; only the four GPU hosts carry unallocated capacity
- LVM: no physical volumes, volume groups or logical volumes present
- RAID: no active arrays
- SMART detail: unavailable, smartctl is not installed

## Network
- Primary interface: eno1
- MAC: 10:e7:c6:10:fb:2e
- IPv4: 192.168.50.204/24
- Gateway: 192.168.50.1
- DNS: 192.168.50.1, systemd-resolved running in stub mode
- Link speed: 1000 Mb/s, full duplex
- IPv6: link-local only, fe80::12e7:c6ff:fe10:fb2e/64
- **Single network interface.** No secondary wired interface and no wireless interface detected
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
- openssh-server 1:9.6p1-3ubuntu13.18, active
- SSH effective configuration: port 22, PermitRootLogin without-password, PubkeyAuthentication yes, PasswordAuthentication yes, X11Forwarding yes
- python3 3.12.3
- Firewall: ufw reports Status: inactive, and the unit was disabled at boot during human preparation
- Failed units: none
- No NVIDIA, CUDA, ROCm, Docker, containerd, podman, Ollama or vLLM packages are installed
- Absent diagnostic tooling: nvidia-smi, rocminfo, nvme-cli, smartmontools

## Capability Summary
- CPU: 4 physical cores and 4 threads in a single socket, single NUMA domain, no SMT. Kaby Lake desktop silicon from 2017. **The smallest core count in the fleet**, shared with hxs-9 through hxs-15
- Memory: 32 GB across 2 slots, non-ECC, DDR4 at 2400 MT/s
- GPU: none. Integrated Intel HD Graphics 630 only, suitable for console output rather than compute
- Storage: a single 238.5 GB NVMe device carrying the operating system, 4.7 percent used. **No spare capacity and no second device**
- Network: single active 1 Gb/s copper link, single interface
- Constraints / notable characteristics:
  - this is a small form factor desktop-mini chassis, not a server, and its 65 W power envelope limits expansion
  - no discrete GPU and no PCIe expansion capability in this chassis class
  - a single storage device with no redundancy and no spare capacity for data or model storage
  - a single network interface, so no link redundancy
  - memory is non-ECC
  - no baseboard management controller or out-of-band management interface was observed
  - platform firmware dates from 2018-01-31
  - ufw is inactive and disabled at boot, so the host is not firewalled
  - SSH currently permits password authentication, and X11 forwarding is enabled
  - Secure Boot is disabled

## Notes
- Discovery was performed over SSH to 192.168.50.204 by direct IP using fleet key authentication. Persistent `hx.local.arpa` DNS for this host did not exist at discovery time; act-001 remains open and did not block this discovery
- The collector ran with passwordless sudo. No fact was recorded as unavailable due to insufficient privilege
- Human preparation was verified from the pre-work record before collection: passwordless sudo confirmed, ufw disabled and its unit disabled at boot, SSH active on port 22, and fleet key authentication confirmed returning `SUDO_NOPASSWD=yes`
- No expected-hardware counts were declared for this host. The owner-confirmed fleet statement that servers 5 through 15 carry no discrete GPU is consistent with what was found
- Vendor specifications were not used to populate any field in this record

**Discovery Status:** COMPLETE

> Role assignment is not performed in this file.
