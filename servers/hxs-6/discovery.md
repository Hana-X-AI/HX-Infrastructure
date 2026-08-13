# hxs-6 — Discovery

**Phase:** 1
**Discovery date:** 2026-08-12

All values below are direct server evidence collected read-only over SSH using the project
collector. No package was installed, no driver loaded or changed, and no configuration
modified. The collector ran with passwordless sudo, so no fact was skipped for lack of
privilege.

The target address, account and privilege state were taken from
`servers/hxs-6/pre-work-results.md` rather than discovered by probing.

## Identity
- Hostname: hxs-6
- FQDN: not configured. No domain suffix is set on the host. A router-side record for `hxs-6.hx.local.arpa` did not exist at the time of discovery; records exist for hxs-1 through hxs-5. See act-001
- Manufacturer: HP
- Model: HP EliteDesk 800 G4 DM 35W, a desktop-mini small form factor system
- Baseboard: 83E2
- Serial: system serial `8CC8411WX3`, baseboard serial `PGVXV0C8JBF1NL`, chassis serial `8CC8411WX3`
- Machine ID: 0b899c5612f44c63ac468d2dd8dba5b5
- Chassis type: 6
- BIOS / UEFI: HP Q21 version 02.33.00, release date 2026-02-03. **This is the second most recent platform firmware in the fleet**, behind hxs-8 at 2026-03-12
- Boot mode: UEFI
- **Secure Boot: enabled.** Only this host and hxs-7 have Secure Boot active; the other 13 servers in the fleet have it disabled

## CPU
- Model: Intel Core i5-8500T at 2.10 GHz
- Sockets: 1
- Physical cores: 6
- Threads: 6, 1 thread per core. No simultaneous multithreading
- Architecture: x86_64
- NUMA: 1 node
- Virtualization: VT-x present
- The T suffix indicates a low power variant, consistent with the 35 W chassis

## Memory
- Installed RAM: 15.9 GB total online, 15 GiB reported usable by the running kernel
- DIMM layout: 2 modules of 8 GB
- Type / speed: DDR4, configured memory speed 2667 MT/s
- ECC: Error Correction Type reports None
- Swap: file-backed
- **This is the smallest memory configuration in the fleet**, at the same 15.9 GB as hxs-7 and effectively the same as the 16 GB of hxs-8. All three carry 16 GB installed

## GPU / Accelerators
- **No discrete GPU detected.** This is consistent with the owner-confirmed fleet statement that servers 5 through 15 carry no discrete GPU
- Integrated graphics: Intel CoffeeLake-S GT2 UHD Graphics 630, PCI ID 8086:3e92 at 0000:00:02.0, subsystem Hewlett-Packard 103c:83e2, driver `i915` bound
- VRAM: not applicable. Integrated graphics share system memory and no discrete GPU is present
- No NVIDIA, AMD or other discrete accelerator devices detected
- No NPU or dedicated AI accelerator detected
- CUDA availability: none. No NVIDIA hardware and no NVIDIA, CUDA or libcuda package installed

## Storage

| Device | Model | Serial | Type | Capacity | Filesystem / Role | Mount |
|---|---|---|---|---|---|---|
| /dev/nvme0n1 | KXG60ZNV256G NVMe TOSHIBA 256GB | 49FF70BNF0AN | NVMe SSD | 238.5 GB | partitioned, in use | see partitions |
| /dev/nvme0n1p1 | partition of nvme0n1 | not applicable | partition | 1 GB | vfat FAT32 | /boot/efi |
| /dev/nvme0n1p2 | partition of nvme0n1 | not applicable | partition | 237.4 GB | ext4 | / |

- Root filesystem usage: 3.0 percent of 232.64 GB
- **Single storage device**, with no additional unallocated drive
- LVM: no physical volumes, volume groups or logical volumes present
- RAID: no active arrays
- SMART detail: unavailable, smartctl is not installed

## Network
- Primary interface: eno1
- MAC: 84:a9:3e:0d:a7:fb
- IPv4: 192.168.50.205/24
- Gateway: 192.168.50.1
- DNS: 192.168.50.1, systemd-resolved running in stub mode
- Link speed: 1000 Mb/s, full duplex
- IPv6: link-local only, fe80::86a9:3eff:fe0d:a7fb/64
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
- openssh-server present and active
- SSH effective configuration: port 22, PermitRootLogin without-password, PubkeyAuthentication yes, PasswordAuthentication yes
- python3 3.12.3
- Firewall: ufw reports Status: inactive, and the unit was disabled at boot during human preparation
- Failed units: none
- No NVIDIA, CUDA, ROCm, Docker, containerd, podman, Ollama or vLLM packages are installed
- Absent diagnostic tooling: nvidia-smi, rocminfo, nvme-cli, smartmontools

## Capability Summary
- CPU: 6 physical cores and 6 threads in a single socket, single NUMA domain, no SMT. Coffee Lake low power desktop silicon
- Memory: 15.9 GB across 2 slots, non-ECC, DDR4 at 2667 MT/s. Smallest in the fleet, tied with hxs-7 and hxs-8
- GPU: none. Integrated Intel UHD Graphics 630 only, suitable for console output rather than compute
- Storage: a single 238.5 GB NVMe device carrying the operating system, 3.0 percent used. No spare capacity and no second device
- Network: single active 1 Gb/s copper link, single interface
- Constraints / notable characteristics:
  - a small form factor desktop-mini chassis with a 35 W power envelope, which limits both expansion and sustained load
  - no discrete GPU and no PCIe expansion capability in this chassis class
  - a single storage device with no redundancy and no spare capacity for data or model storage
  - a single network interface, so no link redundancy
  - memory is non-ECC and totals 15.9 GB, the least of any host in the fleet, tied with hxs-7 and hxs-8
  - no baseboard management controller or out-of-band management interface was observed
  - **Secure Boot is enabled**, as it is on hxs-7 and on no other host in the fleet. Any future requirement to load an unsigned or DKMS-built kernel module on this server would need either module signing and key enrolment, or Secure Boot to be disabled
  - platform firmware dates from 2026-02-03, the second newest in the fleet after hxs-8
  - ufw is inactive and disabled at boot, so the host is not firewalled
  - SSH currently permits password authentication

## Notes
- Discovery was performed over SSH to 192.168.50.205 by direct IP using fleet key authentication. Persistent `hx.local.arpa` DNS for this host did not exist at discovery time; act-001 is complete for hxs-1 through hxs-5 and a record for this host has not yet been added
- The collector ran with passwordless sudo. No fact was recorded as unavailable due to insufficient privilege
- Human preparation was verified from the pre-work record before collection: passwordless sudo confirmed, ufw disabled and its unit disabled at boot, SSH active on port 22, and fleet key authentication confirmed returning `SUDO_NOPASSWD=yes`
- No expected-hardware counts were declared for this host. The owner-confirmed fleet statement that servers 5 through 15 carry no discrete GPU is consistent with what was found
- This host is a generation newer than hxs-5, an EliteDesk 800 G4 against a G3, with two more cores but half the memory
- Vendor specifications were not used to populate any field in this record

**Discovery Status:** COMPLETE

> Role assignment is not performed in this file.
