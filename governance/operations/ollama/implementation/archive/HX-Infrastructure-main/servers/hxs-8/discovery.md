# hxs-8 — Discovery

**Phase:** 1
**Discovery date:** 2026-08-12

All values below are direct server evidence collected read-only over SSH using the project
collector. No package was installed, no driver loaded or changed, and no configuration
modified. The collector ran with passwordless sudo, so no fact was skipped for lack of
privilege.

The target address, account and privilege state were taken from
`servers/hxs-8/pre-work-results.md` rather than discovered by probing.

## Identity
- Hostname: hxs-8
- FQDN: not configured. No domain suffix is set on the host and no router-side `hx.local.arpa` record existed at discovery time. See act-001
- Manufacturer: LENOVO
- Model: 10T8SMWP00. **This is the only non-HP small form factor host in the fleet**
- Baseboard: 312D
- Serial: system serial `MJ0EFA65`, baseboard serial `MJ0EFA65`
- Machine ID: 91086d5265a74450b7c2047b3b7ca2ae
- Chassis type: 35
- BIOS / UEFI: Lenovo M1UKT79A, release date 2026-03-12. **This is the newest platform firmware in the fleet**, ahead of hxs-6 at 2026-02-03
- Boot mode: UEFI
- Secure Boot: disabled

## CPU
- Model: Intel Core i5-9400T at 1.80 GHz
- Sockets: 1
- Physical cores: 6
- Threads: 6, 1 thread per core. No simultaneous multithreading
- Architecture: x86_64
- NUMA: 1 node
- Virtualization: VT-x present
- The T suffix indicates a low power variant

## Memory
- Installed RAM: 16 GB total online
- DIMM layout: **1 module of 16 GB, single channel.** A second slot is unpopulated
- Type / speed: DDR4, configured memory speed 2666 MT/s
- ECC: Error Correction Type reports None
- Swap: file-backed

## GPU / Accelerators
- **No discrete GPU detected.** Consistent with the owner-confirmed fleet statement that servers 5 through 15 carry no discrete GPU
- Integrated graphics: Intel CoffeeLake-S GT2 UHD Graphics 630, PCI ID 8086:3e92 at 0000:00:02.0, driver `i915` bound
- VRAM: not applicable. Integrated graphics share system memory and no discrete GPU is present
- No NVIDIA, AMD or other discrete accelerator devices detected
- No NPU or dedicated AI accelerator detected
- CUDA availability: none. No NVIDIA hardware and no NVIDIA, CUDA or libcuda package installed

## Storage

| Device | Model | Serial | Type | Capacity | Filesystem / Role | Mount |
|---|---|---|---|---|---|---|
| /dev/nvme0n1 | PC SN530 NVMe WDC 512GB | 2117BG450228 | NVMe SSD | 476.9 GB | partitioned, in use | see partitions |
| /dev/nvme0n1p1 | partition of nvme0n1 | not applicable | partition | 1 GB | vfat FAT32 | /boot/efi |
| /dev/nvme0n1p2 | partition of nvme0n1 | not applicable | partition | 475.9 GB | ext4 | / |

- Root filesystem usage: 1.5 percent of 467.35 GB
- Single storage device, but **the largest capacity of any non-GPU host**, roughly double the others
- LVM: no physical volumes, volume groups or logical volumes present
- RAID: no active arrays
- SMART detail: unavailable, smartctl is not installed

## Network
- Primary interface: eno1
- MAC: 8c:8c:aa:7e:89:c5
- IPv4: 192.168.50.207/24
- Gateway: 192.168.50.1
- DNS: 192.168.50.1, systemd-resolved running in stub mode
- Link speed: 1000 Mb/s, full duplex
- IPv6: link-local only, fe80::8e8c:aaff:fe7e:89c5/64
- Secondary interface: wlp2s0 wireless, state DOWN
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
- open-vm-tools is installed and was upgraded during preparation, consistent with deployment from a virtualization-oriented image
- Absent diagnostic tooling: nvidia-smi, rocminfo, nvme-cli, smartmontools

## Capability Summary
- CPU: 6 physical cores and 6 threads in a single socket, single NUMA domain, no SMT. Coffee Lake low power desktop silicon
- Memory: 16 GB in a single module, non-ECC, DDR4 at 2666 MT/s
- GPU: none. Integrated Intel UHD Graphics 630 only, suitable for console output rather than compute
- Storage: a single 476.9 GB NVMe device carrying the operating system, 1.5 percent used. Roughly 460 GB free, the most usable free space of any non-GPU host
- Network: single active 1 Gb/s copper link, plus an inactive wireless interface
- Constraints / notable characteristics:
  - **memory runs in single channel**, one populated slot of two, which halves available memory bandwidth relative to a matched pair
  - a small form factor chassis with no discrete GPU and no PCIe expansion capability
  - a single storage device with no redundancy, though with materially more free capacity than its peers
  - memory is non-ECC
  - no baseboard management controller or out-of-band management interface was observed
  - ufw is inactive and disabled at boot, so the host is not firewalled
  - SSH currently permits password authentication
  - Secure Boot is disabled

## Notes
- Discovery was performed over SSH to 192.168.50.207 by direct IP using fleet key authentication
- The collector ran with passwordless sudo. No fact was recorded as unavailable due to insufficient privilege
- Human preparation was verified from the pre-work record before collection: full package upgrade applied, passwordless sudo confirmed, ufw disabled and its unit disabled at boot, SSH active on port 22, and fleet key authentication confirmed returning `SUDO_NOPASSWD=yes`
- No expected-hardware counts were declared for this host. The owner-confirmed fleet statement that servers 5 through 15 carry no discrete GPU is consistent with what was found
- Vendor specifications were not used to populate any field in this record

**Discovery Status:** COMPLETE

> Role assignment is not performed in this file.
