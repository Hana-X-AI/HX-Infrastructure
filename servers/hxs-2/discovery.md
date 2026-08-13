# hxs-2 — Discovery

**Phase:** 1
**Discovery date:** 2026-08-12

All values below are direct server evidence collected read-only over SSH using the project
collector. No package was installed, no driver loaded or changed, and no configuration
modified. Facts that could not be obtained from the as-found state are marked unavailable
with the reason. The collector ran with passwordless sudo, so no fact was skipped for lack
of privilege.

## Identity
- Hostname: hxs-2
- FQDN: not configured. No domain suffix is set and no `hx.local.arpa` record exists yet (see act-001)
- Manufacturer: Gigabyte Technology Co., Ltd.
- Model: baseboard X99-UD5 WIFI-CF. System product name reads `Default string`, not programmed by the manufacturer
- Serial: system and baseboard serials both read `Default string`, not programmed
- System UUID: 038d0240-045c-05e7-9006-e90700080009
- Machine ID: 0c249b9ad97c48d0b7d33693d120a576
- Chassis type: desktop
- BIOS / UEFI: version F22, release date 2016-06-13
- Boot mode: UEFI
- Secure Boot: disabled, platform reported in Setup Mode

## CPU
- Model: Intel Core i7-5960X at 3.00 GHz
- Sockets: 1
- Physical cores: 8
- Threads: 16, 2 threads per core
- Architecture: x86_64, 46-bit physical / 48-bit virtual addressing
- NUMA: 1 node, node0 covers CPUs 0-15
- Frequency: 1200 MHz minimum, 3500 MHz maximum
- Cache: L1d 256 KiB, L1i 256 KiB, L2 2 MiB, L3 20 MiB
- Virtualization: VT-x present

## Memory
- Installed RAM: 66 GB total online, 62 GiB reported usable by the running kernel
- DIMM layout: 8 modules of 8 GB
- Type / speed: configured memory speed 2133 MT/s
- ECC: Error Correction Type reports None
- Swap: 8 GB, file-backed

## GPU / Accelerators
- GPU count: 2 discrete NVIDIA GPUs. No integrated graphics on this platform
- Chip: NVIDIA GB206 on both GPUs, directly reported by the kernel as `nouveau 0000:02:00.0: NVIDIA GB206 (1b6000a1)` and `nouveau 0000:03:00.0: NVIDIA GB206 (1b6000a1)`
- Model(s): the marketing model name is not identified by the host. `lspci` reports `NVIDIA Corporation Device [10de:2d04] (rev a1)` with no model string, which indicates the installed PCI ID database predates these devices
- GPU PCI IDs: 10de:2d04 at PCI addresses 0000:02:00.0 and 0000:03:00.0
- Board partner / subsystem ID: **Micro-Star International (MSI) 1462:5351** on both cards. In the as-found state this was the only card model in the fleet that failed to initialize, and both instances failed. Resolved: both cards work correctly under the proprietary driver and are not faulty. See the post-directive validation section below and iss-008
- Associated audio functions: 10de:22eb at 0000:02:00.1 and 0000:03:00.1
- VRAM per GPU: unavailable from current as-found OS/driver state
- VRAM source: none available. No driver is bound to either GPU, so no kernel message reporting VRAM was produced, and no drm sysfs VRAM attribute exists. `nvidia-smi` is not installed
- Driver: **no kernel driver bound to either GPU.** `nouveau` attempts to initialize both devices and fails on each, after correctly identifying both as GB206. The failure is in GSP firmware initialization, not PCI resource allocation: `gsp: RM version: 570.144` loads, then `gsp:msg fn:4097 res:0x65 resp:0x65` returns an error, followed by `gsp: init failed, -22`, `drm: Device allocation failed: -22` and `probe with driver nouveau failed with error -22`. No PCI resource or BAR error appears anywhere in the boot log. The modules `nvidiafb` and `nouveau` are available but neither ends up in use. The proprietary NVIDIA driver is not installed and no nvidia, cuda or libcuda package is present. See iss-008 and act-008
- PCI address space: Above 4G Decoding is disabled in firmware. All GPU BARs are allocated below 4G and BAR1 is 256 MiB on both cards. This is recorded as an observation, not as the cause of the initialization failure; hxs-3 has the identical 256 MiB BAR1 and initializes successfully
- CUDA availability: none in the as-found state
- UUID(s): unavailable. GPU UUIDs are reported by `nvidia-smi`, which requires the proprietary driver
- PCIe link, 0000:02:00.0: negotiated 8.0 GT/s at width x8; device maximum 32.0 GT/s at width x8
- PCIe link, 0000:03:00.0: negotiated 8.0 GT/s at width x8; device maximum 32.0 GT/s at width x8
- No other accelerator devices detected

### Post-directive driver validation, 2026-08-12

The sections above record the as-found state, in which no driver was bound. The project
owner subsequently authorized an NVIDIA driver install through
`governance/nvidia-driver-install-directive.md`. That is an approved Phase 1 exception and an
HX-introduced change, recorded separately here so the as-found record remains intact.

- Driver installed: `nvidia-driver-580-server-open`, module version 580.173.02, licence Dual MIT/GPL
- **Both GPUs initialize and are bound to `nvidia`.** No GPU remains on `nouveau`
- **GPU model, authoritatively identified by the driver: NVIDIA GeForce RTX 5060 Ti**, both cards. PCI ID 10de:2d04 corresponds to this model
- VRAM confirmed by `nvidia-smi`: 16311 MiB per GPU, 32622 MiB total. This matches the figure `nouveau` reported on hxs-3 for the same device, confirming the kernel-message VRAM method used during discovery
- CUDA runtime version reported by the driver: 13.0
- Power limits: 180 W per card
- **The MSI 1462:5351 cards are not faulty.** The earlier `-22` failure was a limitation of `nouveau`'s GSP path with this board variant, not a hardware fault. See iss-008
- Kernel messages, both benign: `nvidia: module verification failed: signature and/or required key missing - tainting kernel`, expected because Secure Boot is disabled and the open module is unsigned; and `NVRM: kbifInitLtr_GB202: LTR is disabled in the hierarchy`, indicating the 2016 X99 chipset does not support PCIe Latency Tolerance Reporting

## Storage

| Device | Model | Serial | Type | Capacity | Filesystem / Role | Mount |
|---|---|---|---|---|---|---|
| /dev/nvme0n1 | WD_BLACK SN7100 4TB | 251119800431 | NVMe SSD | 3.6 TB | partitioned, in use | see partitions |
| /dev/nvme0n1p1 | partition of nvme0n1 | not applicable | partition | 1 GB | vfat FAT32 | /boot/efi |
| /dev/nvme0n1p2 | partition of nvme0n1 | not applicable | partition | 3.6 TB | ext4 | / |
| /dev/sda | WDC WD6400AAKS-6 | WD-WCASYC677952 | SATA HDD, rotational | 596.2 GB | no partition table, no filesystem | not mounted |
| /dev/sdb | WDC WD6400AAKS-6 | WD-WCASY9039376 | SATA HDD, rotational | 596.2 GB | no partition table, no filesystem | not mounted |

- LVM: no physical volumes, volume groups or logical volumes present
- RAID: no active arrays
- Approximately 1.2 TB across two rotational devices is installed, unpartitioned and unused
- SMART detail: unavailable, smartctl is not installed

## Network
- Primary interface: eno1
- MAC: 40:8d:5c:e7:90:d5
- IPv4: 192.168.50.201/24
- Gateway: 192.168.50.1
- DNS: 192.168.50.1, systemd-resolved running in stub mode, DNSSEC not enabled
- Link speed: 1000 Mb/s, full duplex
- IPv6: link-local only, fe80::428d:5cff:fee7:90d5/64
- Secondary interfaces: enp6s0 with MAC 40:8d:5c:e7:90:e9, state DOWN; wlp5s0 wireless with MAC 58:91:cf:e7:8a:38, state DOWN
- Listening services: TCP 22 on all interfaces for SSH. TCP and UDP 53 bound only to the systemd-resolved stub addresses 127.0.0.53 and 127.0.0.54

## Operating System
- Distribution: Ubuntu
- Release: 24.04.4 LTS, codename noble
- Kernel: 7.0.0-28-generic, HWE kernel series
- Architecture: x86_64
- Timezone: Etc/UTC. System clock synchronized, NTP service active
- Update state: 0 packages upgradable. The project owner applied a full package upgrade, autoremove and autoclean, then rebooted, on 2026-08-12. This record reflects the post-upgrade state
- Kernel after upgrade: unchanged at 7.0.0-28-generic. No newer kernel was available, so the `nouveau` version is unchanged
- Reboot required: no

## Relevant Existing Software / Services
- openssh-server present and active, socket-activated
- SSH effective configuration: port 22, PermitRootLogin without-password, PubkeyAuthentication yes, PasswordAuthentication yes
- python3 3.12.3
- Firewall: ufw reports Status: inactive. No rules are being enforced
- Failed units: none
- **As found**, no NVIDIA, CUDA, ROCm, Docker, containerd, podman, Ollama or vLLM packages were installed. `nvidia-driver-580-server-open` and `nvidia-utils-580-server` were installed afterwards under the approved directive, so NVIDIA packages are present on this host now. Nothing else in this list changed. See the post-directive validation section above, `driver-results.md` and act-010
- Absent diagnostic tooling as found: nvidia-smi, rocminfo, nvme-cli, smartmontools. `nvidia-smi` is present since the driver install; the other three remain absent

## Capability Summary
- CPU: 8 physical cores and 16 threads in a single socket, single NUMA domain. Haswell-generation desktop silicon
- Memory: 66 GB across 8 populated slots, non-ECC, 2133 MT/s
- GPU: 2 discrete NVIDIA devices with PCI ID 10de:2d04. Neither has a driver bound, so no CUDA runtime exists and VRAM cannot be read from the as-found state. Both are connected at PCIe 8.0 GT/s x8, which is the maximum width their slots provide
- Storage: 3.6 TB NVMe in use for the operating system, plus two 596.2 GB rotational drives installed but entirely unallocated
- Network: single active 1 Gb/s copper link
- Constraints / notable characteristics:
  - platform firmware dates from 2016-06-13, roughly ten years before discovery
  - no driver is bound to either GPU, so the hardware is present but unusable in the as-found state
  - the host cannot name its own GPUs; the installed PCI ID database does not contain 10de:2d04
  - memory is non-ECC and no system serial is programmed
  - no baseboard management controller or out-of-band management interface was observed
  - ufw is inactive, so the host is not firewalled
  - SSH currently permits password authentication
  - Secure Boot is disabled and the platform is in Setup Mode

## Notes
- Discovery was performed over SSH to 192.168.50.201 by direct IP using fleet key authentication. Persistent `hx.local.arpa` DNS is not established; act-001 remains open and did not block this discovery
- The collector ran with passwordless sudo. No fact was recorded as unavailable due to insufficient privilege
- Cross-reference, not a discovered fact for this host: hxs-3 contains a GPU with the same PCI ID 10de:2d04, and on that host the kernel bound `nouveau` and reported 16311 MiB of VRAM. That figure belongs to hxs-3 and is recorded here only to indicate that the device class is capable of reporting VRAM once a driver binds. It must not be treated as this server's VRAM
- Vendor specifications were not used to populate any field in this record

**Discovery Status:** COMPLETE

> Role assignment is not performed in this file.
