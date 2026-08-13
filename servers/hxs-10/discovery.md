# hxs-10 — Discovery

**Phase:** 1
**Discovery date:** 2026-08-12

All values below are direct server evidence collected read-only over SSH using the project
collector. No package was installed, no driver loaded or changed, and no configuration
modified. The collector ran with passwordless sudo, so no fact was skipped for lack of
privilege.

The target address, account and privilege state were taken from
`servers/hxs-10/pre-work-results.md` rather than discovered by probing.

## Identity
- Hostname: hxs-10
- FQDN: not configured. No domain suffix is set on the host and no router-side `hx.local.arpa` record existed at discovery time. See act-001
- Manufacturer: HP
- Model: HP EliteDesk 800 G3 DM 65W, a desktop-mini small form factor system
- Baseboard: 829A
- Serial: system serial `8CG8170SXM`, baseboard serial `PGATU0MNNAQJTF`
- Machine ID: 4448cf54f6a14b6a8c553f1ca5b26d66
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
| /dev/nvme0n1 | KBG50ZNS256G NVMe KIOXIA 256GB | 92GPGAT9Q69K | NVMe SSD | 238.5 GB | partitioned, in use | see partitions |
| /dev/nvme0n1p1 | partition of nvme0n1 | not applicable | partition | 1 GB | vfat FAT32 | /boot/efi |
| /dev/nvme0n1p2 | partition of nvme0n1 | not applicable | partition | 237.4 GB | ext4 | / |

- Root filesystem usage: 5 percent of 233 GB, 11 GB used, 210 GB available, per `df`
- Single storage device, with no additional unallocated drive
- LVM: no physical volumes, volume groups or logical volumes present
- RAID: no active arrays
- SMART detail: unavailable, smartctl is not installed

## Network
- Primary interface: eno1
- MAC: 10:e7:c6:10:fb:6c
- IPv4: 192.168.50.209/24
- Gateway: 192.168.50.1
- DNS: 192.168.50.1, systemd-resolved running in stub mode
- Link speed: 1000 Mb/s, full duplex
- IPv6: link-local only, fe80::12e7:c6ff:fe10:fb6c/64
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
- Firewall: ufw reports Status: inactive
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
  - ufw is inactive, so the host is not firewalled
  - SSH currently permits password authentication
  - Secure Boot is disabled

## Notes
- Discovery was performed over SSH to 192.168.50.209 by direct IP using fleet key authentication
- The collector ran with passwordless sudo. No fact was recorded as unavailable due to insufficient privilege
- **Hostname correction applied before this record was written.** At first collection this host reported its hostname as `hxs-9`, which is the name of a different physical machine at 192.168.50.208. The two were confirmed distinct by system serial, `8CG8170SXM` here against `8CG8170SW8`, and by machine ID. The host had been imaged without its hostname being set. The project owner set the hostname to `hxs-10` and the host was re-collected. See iss-009. No other configuration was changed
- This host is one of a batch of six near-identical HP EliteDesk 800 G3 DM 65W units, alongside hxs-5, hxs-9, hxs-11, hxs-12 and hxs-15, sharing the same model, firmware version and date, CPU and memory configuration. Their serials are close: `8CG8170SXM` here, plus `8CG8170SW5`, `8CG8170SW8`, `8CG8170SW9`, `8CG8170SWK` and `8CG8170SVQ`
- No expected-hardware counts were declared for this host. The owner-confirmed fleet statement that servers 5 through 15 carry no discrete GPU is consistent with what was found
- Vendor specifications were not used to populate any field in this record

**Discovery Status:** COMPLETE

> Role assignment is not performed in this file.
