# hxs-14 — Discovery

**Phase:** 1
**Discovery date:** 2026-08-12

All values below are direct server evidence collected read-only over SSH using the project
collector. No package was installed, no driver loaded or changed, and no configuration
modified. The collector ran with passwordless sudo, so no fact was skipped for lack of
privilege.

The target address, account and privilege state were taken from
`servers/hxs-14/pre-work-results.md` rather than discovered by probing.

## Identity
- Hostname: hxs-14
- FQDN: not configured. No domain suffix is set on the host and no router-side `hx.local.arpa` record existed at discovery time. See act-001
- Manufacturer: HP
- Model: HP EliteDesk 800 G3 DM 65W, a desktop-mini small form factor system
- Baseboard: 829A
- Serial: system serial `8CG81608NR`, baseboard serial `PGATU0MNNAPRP1`
- Machine ID: abc587eb073d4ec78f177e175869ee72
- Chassis type: 35
- BIOS / UEFI: HP P21 version 02.50, release date 2024-07-14. **This is the newest firmware revision of any EliteDesk 800 G3 in the fleet**, against 02.15 dated 2018 on most and 02.37 dated 2020 on hxs-13
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
- Installed RAM: 32 GB total online
- DIMM layout: 2 modules of 16 GB, dual channel
- Type / speed: DDR4, configured memory speed 2400 MT/s
- ECC: Error Correction Type reports None
- Swap: file-backed

## GPU / Accelerators
- **No discrete GPU detected.** Consistent with the owner-confirmed fleet statement that servers 5 through 15 carry no discrete GPU
- Integrated graphics: Intel HD Graphics 630, PCI ID 8086:5912 at 0000:00:02.0, driver `i915` bound
- VRAM: not applicable. Integrated graphics share system memory and no discrete GPU is present
- No NVIDIA, AMD or other discrete accelerator devices detected
- No NPU or dedicated AI accelerator detected
- CUDA availability: none. No NVIDIA hardware and no NVIDIA, CUDA or libcuda package installed

## Storage

| Device | Model | Serial | Type | Capacity | Filesystem / Role | Mount |
|---|---|---|---|---|---|---|
| /dev/nvme0n1 | iDsonix | RKL06EYBK6HBH312J9F4 | NVMe SSD | 238.5 GB | partitioned, in use | see partitions |
| /dev/nvme0n1p1 | partition of nvme0n1 | not applicable | partition | 1 GB | vfat FAT32 | /boot/efi |
| /dev/nvme0n1p2 | partition of nvme0n1 | not applicable | partition | 237.4 GB | ext4 | / |

- Root filesystem usage: 4.7 percent of 232.64 GB
- **The storage device is an aftermarket iDsonix unit**, the same brand found in hxs-11 and hxs-15 and unlike the KIOXIA, Toshiba, Intel, SK hynix and Western Digital drives elsewhere in the fleet. The original drive appears to have been replaced
- Single storage device, with no additional unallocated drive
- LVM: no physical volumes, volume groups or logical volumes present
- RAID: no active arrays
- SMART detail: unavailable, smartctl is not installed

## Network
- Primary interface: eno1
- MAC: 10:e7:c6:0f:e4:bc
- IPv4: 192.168.50.213/24
- Gateway: 192.168.50.1
- DNS: 192.168.50.1, systemd-resolved running in stub mode
- Link speed: 1000 Mb/s, full duplex
- IPv6: link-local only, fe80::12e7:c6ff:fe0f:e4bc/64
- **Single network interface.** No secondary wired interface and no wireless interface detected
- Listening services: TCP 22 on all interfaces for SSH. TCP and UDP 53 bound only to the systemd-resolved stub addresses

## Operating System
- Distribution: Ubuntu
- Release: 24.04.4 LTS, codename noble
- Kernel: 7.0.0-28-generic, HWE kernel series
- Architecture: x86_64
- Timezone: Etc/UTC. System clock synchronized, NTP service active
- **Update state: 32 packages upgradable.** This host was not upgraded during preparation, unlike hxs-7 through hxs-13 which all report 0 pending. One of the pending updates is a standard security update, per the login banner
- Reboot required: no

## Relevant Existing Software / Services
- openssh-server present and active
- SSH effective configuration: port 22, PermitRootLogin without-password, PubkeyAuthentication yes, PasswordAuthentication yes
- python3 3.12.3
- Firewall: ufw reports Status: inactive, and the unit was disabled at boot during human preparation
- Failed units: none
- No NVIDIA, CUDA, ROCm, Docker, containerd, podman, Ollama or vLLM packages are installed
- Absent diagnostic tooling: nvidia-smi, rocminfo, nvme-cli, smartmontools

## Capability Summary
- CPU: 4 physical cores and 4 threads in a single socket, single NUMA domain, no SMT. Kaby Lake desktop silicon
- Memory: 32 GB across 2 slots in dual channel, non-ECC, DDR4 at 2400 MT/s
- GPU: none. Integrated Intel HD Graphics 630 only, suitable for console output rather than compute
- Storage: a single 238.5 GB aftermarket NVMe device carrying the operating system
- Network: single active 1 Gb/s copper link, single interface
- Constraints / notable characteristics:
  - **32 package updates are pending, including one security update.** hxs-5, hxs-6 and hxs-15 are in the same state; hxs-7 through hxs-13 were brought to 0 pending during preparation
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
- Discovery was performed over SSH to 192.168.50.213 by direct IP using fleet key authentication
- The collector ran with passwordless sudo. No fact was recorded as unavailable due to insufficient privilege
- Human preparation was verified from the pre-work record before collection: hostname correctly set, passwordless sudo confirmed, ufw disabled and its unit disabled at boot, SSH active on port 22, and fleet key authentication confirmed returning `SUDO_NOPASSWD=yes`. The package upgrade step was not performed on this host
- This host matches the Kaby Lake configuration of hxs-5, hxs-9, hxs-10, hxs-11 and hxs-12 in CPU, memory and integrated graphics, but its serial belongs to a different series, `8CG81608NR` against the `8CG8170Sxx` range, and its firmware is six years newer than theirs
- No expected-hardware counts were declared for this host. The owner-confirmed fleet statement that servers 5 through 15 carry no discrete GPU is consistent with what was found
- Vendor specifications were not used to populate any field in this record

**Discovery Status:** COMPLETE

> Role assignment is not performed in this file.
