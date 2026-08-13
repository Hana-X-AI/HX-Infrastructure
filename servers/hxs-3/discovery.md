# hxs-3 — Discovery

**Phase:** 1
**Discovery date:** 2026-08-12

All values below are direct server evidence collected read-only over SSH using the project
collector. No package was installed, no driver loaded or changed, and no configuration
modified. Facts that could not be obtained from the as-found state are marked unavailable
with the reason. The collector ran with passwordless sudo, so no fact was skipped for lack
of privilege.

## Identity
- Hostname: hxs-3
- FQDN: not configured. No domain suffix is set and no `hx.local.arpa` record exists yet (see act-001)
- Manufacturer: Gigabyte Technology Co., Ltd.
- Model: baseboard X99-UD5 WIFI-CF. System product name reads `Default string`, not programmed by the manufacturer
- Serial: system and baseboard serials both read `Default string`, not programmed
- Machine ID: d02a8e3a8d76474390e51a162e9f196d
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
- GPU count: **2 discrete NVIDIA GPUs, both enumerated and both initialized.** No integrated graphics on this platform
- Chip: NVIDIA GB206 on both, directly reported by the kernel as `NVIDIA GB206 (1b6000a1)`
- Model(s): the marketing model name is not identified by the host. `lspci` reports `NVIDIA Corporation Device [10de:2d04] (rev a1)` with no model string, which indicates the installed PCI ID database predates these devices
- GPU PCI IDs: 10de:2d04 at PCI addresses 0000:02:00.0 and 0000:03:00.0
- Board partner / subsystem ID: **PNY 196e:143e on both cards.** This is a different card model from the two MSI 1462:5351 cards in hxs-2, despite sharing the same GB206 chip and PCI device ID
- VRAM: 16311 MiB per GPU, **32622 MiB total**, directly reported
- VRAM source: kernel messages from `journalctl -k -b`, reading `nouveau 0000:02:00.0: drm: VRAM: 16311 MiB` and `nouveau 0000:03:00.0: drm: VRAM: 16311 MiB`. The kernel names the value as VRAM. PCI base address register sizes were not used
- Driver: nouveau, open-source, bound to both GPUs and initialized successfully on each. The proprietary NVIDIA driver is not installed, `nvidia-smi` is absent, and no nvidia, cuda or libcuda package is present
- CUDA availability: none in the as-found state
- UUIDs: unavailable. GPU UUIDs are reported by `nvidia-smi`, which requires the proprietary driver
- PCIe link, 0000:02:00.0: negotiated x8; device maximum 32.0 GT/s at width x16
- PCIe link, 0000:03:00.0: negotiated x8; device maximum 32.0 GT/s at width x16
- PCIe bandwidth, kernel-reported: 63.008 Gb/s available per card, limited by an 8.0 GT/s x8 link, against 504.112 Gb/s that the cards could reach on a 32.0 GT/s x16 link. The X99 platform is PCIe Gen3, so Gen5 speeds are not attainable here regardless of slot
- PCI resource pressure: the kernel could not assign SR-IOV virtual-function BARs on either card, reporting `VF BAR 2 ... can't assign; no space` and `VF BAR 4 ... can't assign; no space`, and a bridge-window expansion to `0x24000000` also failed. PCI reallocation was automatically enabled. The primary BARs were assigned successfully and both GPUs work, so this pressure is not fatal, but it confirms the 32-bit MMIO region is tight with Above 4G Decoding disabled
- No other accelerator devices detected

### Post-directive driver validation, 2026-08-12

The sections above record the as-found state under `nouveau`. The project owner subsequently
authorized an NVIDIA driver install through `governance/nvidia-driver-install-directive.md`.
That is an approved Phase 1 exception and an HX-introduced change, recorded separately here so
the as-found record remains intact.

- Driver installed: `nvidia-driver-580-server-open`, module version 580.173.02, licence Dual MIT/GPL
- **Both GPUs initialize and are bound to `nvidia`.** No GPU remains on `nouveau`
- **GPU model, authoritatively identified by the driver: NVIDIA GeForce RTX 5060 Ti**, both cards, PNY 196e:143e
- VRAM confirmed by `nvidia-smi`: 16311 MiB per GPU, 32622 MiB total. **This exactly matches the figure `nouveau` reported during discovery**, validating the kernel-message VRAM method used before any vendor driver was present
- CUDA runtime version reported by the driver: 13.0
- Power limits: 180 W per card
- Kernel messages, both benign: `nvidia: module verification failed: signature and/or required key missing - tainting kernel`, expected because Secure Boot is disabled and the open module is unsigned; and `NVRM: kbifInitLtr_GB202: LTR is disabled in the hierarchy`, indicating the 2016 X99 chipset does not support PCIe Latency Tolerance Reporting

## Storage

| Device | Model | Serial | Type | Capacity | Filesystem / Role | Mount |
|---|---|---|---|---|---|---|
| /dev/nvme0n1 | WD_BLACK SN7100 4TB | 25160X800274 | NVMe SSD | 3.6 TB | partitioned, in use | see partitions |
| /dev/nvme0n1p1 | partition of nvme0n1 | not applicable | partition | 1 GB | vfat FAT32 | /boot/efi |
| /dev/nvme0n1p2 | partition of nvme0n1 | not applicable | partition | 3.6 TB | ext4 | / |
| /dev/sda | Samsung SSD 870 | S753NL0Y210877D | SATA SSD, non-rotational | 1.8 TB | no partition table, no filesystem | not mounted |

- LVM: no physical volumes, volume groups or logical volumes present
- RAID: no active arrays
- A 1.8 TB SATA SSD is installed, unpartitioned and unused
- SMART detail: unavailable, smartctl is not installed

## Network
- Primary interface: eno1
- MAC: 40:8d:5c:e7:d0:e5
- IPv4: 192.168.50.202/24
- Gateway: 192.168.50.1
- DNS: 192.168.50.1, systemd-resolved running in stub mode, DNSSEC not enabled
- Link speed: 1000 Mb/s, full duplex
- IPv6: link-local only, fe80::428d:5cff:fee7:d0e5/64
- Secondary interfaces: enp6s0 with MAC 40:8d:5c:e7:d0:e7, state DOWN; wlp5s0 wireless with MAC 58:91:cf:e7:53:74, state DOWN
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
- **As found**, no NVIDIA, CUDA, ROCm, Docker, containerd, podman, Ollama or vLLM packages were installed. `nvidia-driver-580-server-open` and `nvidia-utils-580-server` were installed afterwards under the approved directive, so NVIDIA packages are present on this host now. Nothing else in this list changed. See `driver-results.md` and act-010
- Absent diagnostic tooling as found: nvidia-smi, rocminfo, nvme-cli, smartmontools. `nvidia-smi` is present since the driver install; the other three remain absent

## Capability Summary
- CPU: 8 physical cores and 16 threads in a single socket, single NUMA domain. Haswell-generation desktop silicon
- Memory: 66 GB across 8 populated slots, non-ECC, 2133 MT/s
- GPU: 2 discrete NVIDIA GB206 devices, PNY 196e:143e, with 16311 MiB each and 32622 MiB combined, measured from kernel reporting. Both are bound to the open-source nouveau driver and initialize successfully, so no CUDA runtime exists in the as-found state and CUDA-dependent inference software cannot run without a driver change
- Storage: 3.6 TB NVMe in use for the operating system, plus a 1.8 TB SATA SSD installed but entirely unallocated
- Network: single active 1 Gb/s copper link
- Constraints / notable characteristics:
  - platform firmware dates from 2016-06-13, roughly ten years before discovery
  - the GPU is connected at x8 against a device maximum of x16, so it has half the host bandwidth the card supports
  - the negotiated link speed of 2.5 GT/s against a 32.0 GT/s maximum is consistent with idle power management but has not been confirmed under load
  - both GPUs run at PCIe x8 rather than their x16 maximum, and the X99 platform is Gen3, so each card reaches 63.008 Gb/s against the 504.112 Gb/s the hardware could support on a modern host. This is a platform ceiling, not a fault
  - Above 4G Decoding is disabled, which leaves the 32-bit MMIO region tight enough that SR-IOV virtual-function BARs cannot be assigned. Both GPUs still initialize and work
  - the host cannot name its own GPU; the installed PCI ID database does not contain 10de:2d04
  - memory is non-ECC and no system serial is programmed
  - no baseboard management controller or out-of-band management interface was observed
  - ufw is inactive, so the host is not firewalled
  - SSH currently permits password authentication
  - Secure Boot is disabled and the platform is in Setup Mode

## Notes
- Re-collected on 2026-08-12 after the project owner reseated the second GPU. **Both GPUs now enumerate and initialize**, resolving iss-007. The earlier single-GPU state was a seating or slot-contact condition, not a firmware, driver or platform limitation. Both cards are behind separate CPU root ports, `00:02.0` for bus 02 and `00:03.0` for bus 03, and root port `00:01.0` remains enumerated and empty
- This host is now the controlled comparison that isolates iss-008. It runs **two GB206 cards on the same X99-UD5 board, the same F22 firmware, the same 7.0.0-28-generic kernel and the same GSP RM 570.144 as hxs-2**, and both initialize. The only remaining difference from hxs-2 is the card model: PNY 196e:143e here, MSI 1462:5351 there
- PCI address space: Above 4G Decoding is disabled in firmware. The GPU BARs are allocated below 4G and BAR1 is 256 MiB. Despite this the card initializes successfully, which is why the same condition on hxs-2 is not treated as the cause of that host's failure
- Discovery was performed over SSH to 192.168.50.202 by direct IP using fleet key authentication. Persistent `hx.local.arpa` DNS is not established; act-001 remains open and did not block this discovery
- The collector ran with passwordless sudo. No fact was recorded as unavailable due to insufficient privilege
- Vendor specifications were not used to populate any field in this record

**Discovery Status:** COMPLETE

> Role assignment is not performed in this file.
