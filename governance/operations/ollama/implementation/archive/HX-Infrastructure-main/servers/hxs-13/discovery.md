# hxs-13 — Discovery

**Phase:** 1
**Discovery date:** 2026-08-12

All values below are direct server evidence collected read-only over SSH using the project
collector. No package was installed, no driver loaded or changed, and no configuration
modified. The collector ran with passwordless sudo, so no fact was skipped for lack of
privilege.

The target address, account and privilege state were taken from
`servers/hxs-13/pre-work-results.md` rather than discovered by probing.

## Identity
- Hostname: hxs-13
- FQDN: not configured. No domain suffix is set on the host and no router-side `hx.local.arpa` record existed at discovery time. See act-001
- Manufacturer: HP
- Model: HP EliteDesk 800 G3 DM 65W, a desktop-mini small form factor system
- Baseboard: 829A
- Serial: system serial `8CG74642Y0`, baseboard serial `PGATU0GWRA3LWX`
- Machine ID: 20f3a647830e416c9757d0f650f18cb1
- Chassis type: 35
- BIOS / UEFI: HP P21 version 02.37, release date 2020-10-19. **This is newer than the 02.15 dated 2018-01-31 carried by hxs-5, hxs-9, hxs-10, hxs-11, hxs-12 and hxs-15, and older than the 02.50 dated 2024-07-14 on hxs-14**
- Boot mode: UEFI
- Secure Boot: disabled

## CPU
- Model: **Intel Core i5-6500 at 3.20 GHz.** This is Skylake, a generation earlier than the i5-7500 Kaby Lake parts in the otherwise similar hxs-5, hxs-9, hxs-10, hxs-11 and hxs-12
- Sockets: 1
- Physical cores: 4
- Threads: 4, 1 thread per core. No simultaneous multithreading
- Architecture: x86_64
- NUMA: 1 node
- Virtualization: VT-x present

## Memory
- Installed RAM: 32 GB total online
- DIMM layout: 2 modules of 16 GB, dual channel
- Type / speed: DDR4, configured memory speed **2133 MT/s**, lower than the 2400 MT/s of the Kaby Lake units
- ECC: Error Correction Type reports None
- Swap: file-backed

## GPU / Accelerators
- **No discrete GPU detected.** Consistent with the owner-confirmed fleet statement that servers 5 through 15 carry no discrete GPU
- Integrated graphics: **Intel HD Graphics 530**, PCI ID 8086:1912 at 0000:00:02.0, driver `i915` bound. This is the Skylake integrated graphics part, where the other units carry HD Graphics 630
- VRAM: not applicable. Integrated graphics share system memory and no discrete GPU is present
- No NVIDIA, AMD or other discrete accelerator devices detected
- No NPU or dedicated AI accelerator detected
- CUDA availability: none. No NVIDIA hardware and no NVIDIA, CUDA or libcuda package installed

## Storage

| Device | Model | Serial | Type | Capacity | Filesystem / Role | Mount |
|---|---|---|---|---|---|---|
| /dev/sda | SK hynix SC311 S | MJ87N636812207M33 | SATA SSD, non-rotational | 238.5 GB | partitioned, in use | see partitions |
| /dev/sda1 | partition of sda | not applicable | partition | 1 GB | vfat FAT32 | /boot/efi |
| /dev/sda2 | partition of sda | not applicable | partition | 237.4 GB | ext4 | / |

- Root filesystem usage: 4.7 percent of 232.64 GB
- **The operating system runs from a SATA-attached SSD, not NVMe.** Every other small form factor host in the fleet boots from an NVMe device. Capacity is the same at 238.5 GB, but the interface is slower
- Single storage device, with no additional unallocated drive
- LVM: no physical volumes, volume groups or logical volumes present
- RAID: no active arrays
- SMART detail: unavailable, smartctl is not installed

## Network
- Primary interface: eno1
- MAC: ac:e2:d3:0b:7b:5a
- IPv4: 192.168.50.212/24
- Gateway: 192.168.50.1
- DNS: 192.168.50.1, systemd-resolved running in stub mode
- Link speed: 1000 Mb/s, full duplex
- IPv6: link-local only, fe80::aee2:d3ff:fe0b:7b5a/64
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
- CPU: 4 physical cores and 4 threads in a single socket, single NUMA domain, no SMT. Skylake desktop silicon, one generation older than most of the fleet's small form factor hosts
- Memory: 32 GB across 2 slots in dual channel, non-ECC, DDR4 at 2133 MT/s
- GPU: none. Integrated Intel HD Graphics 530 only, suitable for console output rather than compute
- Storage: a single 238.5 GB SATA SSD carrying the operating system
- Network: single active 1 Gb/s copper link, single interface
- Constraints / notable characteristics:
  - despite carrying the same EliteDesk 800 G3 DM 65W model name as five other hosts, this unit is a different build: Skylake i5-6500 rather than Kaby Lake i5-7500, HD Graphics 530 rather than 630, memory at 2133 rather than 2400 MT/s, and SATA rather than NVMe storage
  - storage is SATA-attached, so sustained sequential throughput is materially lower than the NVMe-equipped hosts
  - a small form factor desktop-mini chassis with a 65 W power envelope, no discrete GPU and no PCIe expansion capability
  - a single storage device with no redundancy and no spare capacity
  - a single network interface, so no link redundancy
  - memory is non-ECC, and runs dual channel
  - no baseboard management controller or out-of-band management interface was observed
  - ufw is inactive and disabled at boot, so the host is not firewalled
  - SSH currently permits password authentication
  - Secure Boot is disabled

## Notes
- Discovery was performed over SSH to 192.168.50.212 by direct IP using fleet key authentication
- The collector ran with passwordless sudo. No fact was recorded as unavailable due to insufficient privilege
- Human preparation was verified from the pre-work record before collection: hostname correctly set, passwordless sudo confirmed, ufw disabled and its unit disabled at boot, SSH active on port 22, and fleet key authentication confirmed returning `SUDO_NOPASSWD=yes`
- **This host shares a model name with the hxs-5, hxs-9, hxs-10, hxs-11 and hxs-12 batch but is not part of it.** Its serial belongs to a different series, `8CG74642Y0` against the `8CG8170Sxx` range of the others, and its CPU, integrated graphics, memory speed, storage interface and firmware revision all differ. It should not be treated as interchangeable with those five
- No expected-hardware counts were declared for this host. The owner-confirmed fleet statement that servers 5 through 15 carry no discrete GPU is consistent with what was found
- Vendor specifications were not used to populate any field in this record

**Discovery Status:** COMPLETE

> Role assignment is not performed in this file.
