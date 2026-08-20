# hxs-12 — Discovery

**Phase:** 1
**Discovery date:** 2026-08-12

All values below are direct server evidence collected read-only over SSH using the project
collector. No package was installed, no driver loaded or changed, and no configuration
modified. The collector ran with passwordless sudo, so no fact was skipped for lack of
privilege.

The target address, account and privilege state were taken from
`servers/hxs-12/pre-work-results.md` rather than discovered by probing.

## Identity
- Hostname: hxs-12
- FQDN: not configured. No domain suffix is set on the host and no router-side `hx.local.arpa` record existed at discovery time. See act-001
- Manufacturer: HP
- Model: HP EliteDesk 800 G3 DM 65W, a desktop-mini small form factor system
- Baseboard: 829A
- Serial: system serial `8CG8170SWK`, baseboard serial `PGATU0MNNAQJWM`
- Machine ID: 3b1e05cd680b4ae18b233a511efcf192
- Chassis type: 35
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
| /dev/nvme0n1 | KBG50ZNS256G NVMe KIOXIA 256GB | 724C72K0EJ26 | NVMe SSD | 238.5 GB | partitioned, in use | see partitions |
| /dev/nvme0n1p1 | partition of nvme0n1 | not applicable | partition | 1 GB | vfat FAT32 | /boot/efi |
| /dev/nvme0n1p2 | partition of nvme0n1 | not applicable | partition | 237.4 GB | ext4 | / |

- Root filesystem usage: 4.7 percent of 232.64 GB
- Single storage device, with no additional unallocated drive
- LVM: no physical volumes, volume groups or logical volumes present
- RAID: no active arrays
- SMART detail: unavailable, smartctl is not installed

## Network
- Primary interface: eno1
- MAC: 10:e7:c6:10:fb:c2
- IPv4: 192.168.50.211/24
- Gateway: 192.168.50.1
- DNS: 192.168.50.1, systemd-resolved running in stub mode
- Link speed: 1000 Mb/s, full duplex
- IPv6: link-local only, fe80::12e7:c6ff:fe10:fbc2/64
- **Single network interface.** No secondary wired interface and no wireless interface detected
- Listening services: TCP 22 on all interfaces for SSH. TCP and UDP 53 bound only to the systemd-resolved stub addresses

## Operating System
- Distribution: Ubuntu
- Release: 24.04.4 LTS, codename noble
- Kernel: 7.0.0-28-generic, HWE kernel series
- Architecture: x86_64
- Timezone: Etc/UTC. System clock synchronized, NTP service active
- Update state: 0 packages upgradable. The owner applied a full upgrade during preparation
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
- Storage: a single 238.5 GB NVMe device carrying the operating system
- Network: single active 1 Gb/s copper link, single interface
- Constraints / notable characteristics:
  - a small form factor desktop-mini chassis with a 65 W power envelope, no discrete GPU and no PCIe expansion capability
  - a single storage device with no redundancy and no spare capacity
  - a single network interface, so no link redundancy
  - memory is non-ECC, and runs dual channel
  - no baseboard management controller or out-of-band management interface was observed
  - platform firmware dates from 2018-01-31
  - ufw is inactive and disabled at boot, so the host is not firewalled
  - SSH currently permits password authentication
  - Secure Boot is disabled

## Notes
- Discovery was performed over SSH to 192.168.50.211 by direct IP using fleet key authentication
- The collector ran with passwordless sudo. No fact was recorded as unavailable due to insufficient privilege
- Human preparation was verified from the pre-work record before collection: hostname correctly set, passwordless sudo confirmed, ufw disabled and its unit disabled at boot, SSH active on port 22, and fleet key authentication confirmed returning `SUDO_NOPASSWD=yes`
- This host is one of a batch of six near-identical HP EliteDesk 800 G3 DM 65W units, alongside hxs-5, hxs-9, hxs-10, hxs-11 and hxs-15. All six share the same model, firmware version and date, CPU and memory configuration. Their serials are close: `8CG8170SWK` here, plus `8CG8170SW5`, `8CG8170SW8`, `8CG8170SW9`, `8CG8170SXM` and `8CG8170SVQ`. The one substantive difference within the batch is that hxs-15 does not expose VT-x; see iss-011
- No expected-hardware counts were declared for this host. The owner-confirmed fleet statement that servers 5 through 15 carry no discrete GPU is consistent with what was found
- Vendor specifications were not used to populate any field in this record

**Discovery Status:** COMPLETE

> Role assignment is not performed in this file.
