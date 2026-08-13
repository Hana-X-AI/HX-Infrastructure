# hxs-1 — Discovery

**Phase:** 1
**Discovery date:** 2026-08-11

All values below are direct server evidence collected read-only over SSH. No package was
installed, no driver loaded or changed, and no configuration modified. Facts that could not
be obtained from the as-found state are marked unavailable with the reason.

## Identity
- Hostname: hxs-1
- FQDN: not configured. `hostname -f` returns the short name `hxs-1`; no domain suffix is set and no `hx.local.arpa` record exists yet (see act-001)
- Manufacturer: Micro-Star International Co., Ltd.
- Model: PRO Z890-P WIFI (MS-7E34)
- Serial: system serial reads `Default string`, not programmed by the manufacturer. Baseboard serial is `07E3412_O81B266667`
- System UUID: 3b199aae-eaec-1b1b-a4c4-345a60017cfd
- Machine ID: d23f871deff94ab18b4df69412d69835
- Chassis type: desktop
- BIOS / UEFI: version 1.A80, release date 2025-01-07, vendor American Megatrends
- Boot mode: UEFI
- Secure Boot: disabled

## CPU
- Model: Intel Core Ultra 9 285K
- Sockets: 1
- Physical cores: 24
- Threads: 24 (1 thread per core; no simultaneous multithreading)
- Architecture: x86_64, 46-bit physical / 48-bit virtual addressing
- NUMA: 1 node, node0 covers CPUs 0-23
- Frequency: 800 MHz minimum, 5800 MHz maximum
- Cache: L1d 768 KiB, L1i 1.3 MiB, L2 40 MiB, L3 36 MiB
- Virtualization: VT-x present

## Memory
- Installed RAM: 128 GB (131072 MB), 125 GiB reported usable by the running kernel
- DIMM layout: 4 modules of 32 GB in DIMMA1, DIMMA2, DIMMB1, DIMMB2. All slots populated
- Type / speed: DDR5, G.Skill part F5-6000J3636F32G, dual rank. Rated module speed 4400 MT/s, configured memory speed 4400 MT/s
- ECC: Error Correction Type reports None
- Swap: 8 GB, file-backed at /swap.img

## GPU / Accelerators
- GPU count: 2 discrete NVIDIA GPUs, plus 1 integrated Intel GPU, plus 2 non-GPU accelerators
- Model(s): NVIDIA AD103 [GeForce RTX 4070 Ti SUPER], PCI ID 10de:2705, at PCI addresses 0000:02:00.0 and 0000:81:00.0
- VRAM per GPU: 16376 MiB, directly reported
- Total VRAM: 32752 MiB across both discrete GPUs
- VRAM source: kernel message from `journalctl -k -b` and `dmesg`, reading `nouveau 0000:02:00.0: drm: VRAM: 16376 MiB` and `nouveau 0000:81:00.0: drm: VRAM: 16376 MiB`. The kernel names the value as VRAM. PCI base address register sizes were not used
- Driver: nouveau, open-source, bound to both discrete GPUs. The proprietary NVIDIA driver is not installed, `nvidia-smi` is absent, and no nvidia, cuda or libcuda package is present
- CUDA availability: none in the as-found state
- UUID(s): unavailable. GPU UUIDs are reported by `nvidia-smi`, which requires the proprietary driver
- PCIe link, 0000:02:00.0: negotiated 2.5 GT/s at width x16; device maximum 16.0 GT/s at width x16
- PCIe link, 0000:81:00.0: negotiated 2.5 GT/s at width x4; device maximum 16.0 GT/s at width x16
- Integrated GPU: Intel Arrow Lake-U [Intel Graphics], PCI ID 8086:7d67 at 0000:00:02.0, driver i915, active console at 1600x900
- Neural accelerator: Intel Arrow Lake NPU, PCI ID 8086:ad1d at 0000:00:0b.0, driver intel_vpu bound, firmware intel/vpu/vpu_37xx_v1.bin loaded
- AI accelerator: Hailo-8 AI Processor, PCI ID 1e60:2864 at 0000:84:00.0. Present on the PCI bus with no kernel driver bound and no kernel module listed
- PCIe link, 0000:84:00.0: negotiated 8.0 GT/s at width x2; device maximum 8.0 GT/s at width x4. The link is at half the device's maximum width

### Post-directive driver validation, 2026-08-12

The sections above record the as-found state under `nouveau`. The project owner subsequently
installed the NVIDIA driver on this host as well, extending
`governance/policy/nvidia-driver-install-directive.md` beyond its stated scope of hxs-2 and hxs-3.
That is an approved Phase 1 exception and an HX-introduced change, recorded separately here so
the as-found record remains intact.

- Driver installed: `nvidia-driver-580-server-open`, module version 580.173.02, licence Dual MIT/GPL
- **Both GPUs initialize and are bound to `nvidia`.** No GPU remains on `nouveau`
- GPU model confirmed by the driver: NVIDIA GeForce RTX 4070 Ti SUPER, both cards
- VRAM confirmed by `nvidia-smi`: 16376 MiB per GPU, 32752 MiB total. **This exactly matches the figure `nouveau` reported during discovery**, validating the kernel-message VRAM method
- CUDA runtime version reported by the driver: 13.0
- Power limits: 285 W per card
- The integrated Intel GPU remains bound to `i915` and is unaffected
- Kernel message, benign: `nvidia: module verification failed: signature and/or required key missing - tainting kernel`, expected because Secure Boot is disabled and the open module is unsigned. No LTR warning appears on this host, unlike the two X99 machines

## Storage

| Device | Model | Serial | Type | Capacity | Filesystem / Role | Mount |
|---|---|---|---|---|---|---|
| /dev/nvme0n1 | WD_BLACK SN850X 4000GB | 250816800073 | NVMe SSD | 3.6 TB | partitioned, in use | see partitions |
| /dev/nvme0n1p1 | partition of nvme0n1 | not applicable | partition | 1 GB | vfat FAT32, UUID 2EFE-5D0D | /boot/efi |
| /dev/nvme0n1p2 | partition of nvme0n1 | not applicable | partition | 3.6 TB | ext4, UUID ab09b07d-fb20-4235-99df-440f18896e99 | / |
| /dev/nvme1n1 | WD_BLACK SN850X 4000GB | 250816800905 | NVMe SSD | 3.6 TB | no partition table, no filesystem | not mounted |
| /dev/sda | ST8000DM004-2U91 | ZR1682F1 | SATA HDD, rotational | 7.3 TB | no partition table, no filesystem | not mounted |

- Root filesystem usage: 11 GB used of 3.6 TB, 1 percent
- LVM: no physical volumes, volume groups or logical volumes present
- RAID: /proc/mdstat lists RAID personalities but reports no active arrays
- fstab: mounts root and /boot/efi by UUID, which matches the stable-identifier requirement in the infrastructure contract. Swap is the /swap.img file
- fstab comments record that root and /boot/efi were on nvme1n1 during installation; they are now on nvme0n1, so NVMe enumeration changed after install
- Approximately 11 TB across two devices is installed, unpartitioned and unused
- SMART detail: unavailable, smartctl is not installed

## Network
- Primary interface: enp131s0, Realtek RTL8126, PCI ID 10ec:8126, driver r8169
- MAC: 34:5a:60:01:7c:fd
- IPv4: 192.168.50.200/24
- Gateway: 192.168.50.1
- DNS: 192.168.50.1, systemd-resolved running in stub mode, DNSSEC not enabled
- Link speed: 1000 Mb/s, full duplex
- IPv6: link-local only, fe80::365a:60ff:fe01:7cfd/64. No routable IPv6 address
- Secondary interface: wlp130s0f0, Intel Wi-Fi 7 BE200, MAC e8:bf:b8:b9:6a:db, state DOWN, no address
- Listening services: TCP 22 on all interfaces for SSH. TCP and UDP 53 bound only to the systemd-resolved stub addresses 127.0.0.53 and 127.0.0.54

## Operating System
- Distribution: Ubuntu
- Release: 24.04.4 LTS, codename noble
- Kernel: 7.0.0-28-generic, HWE kernel series
- Architecture: x86_64
- Timezone: Etc/UTC. System clock synchronized, NTP service active
- Update state: 34 packages upgradable at time of discovery, including ubuntu-drivers-common, systemd-hwe-hwdb and sosreport
- Reboot required: no. /var/run/reboot-required is absent

## Relevant Existing Software / Services
- openssh-server 1:9.6p1-3ubuntu13.18, socket-activated through ssh.socket
- SSH effective configuration: port 22, PermitRootLogin without-password, PubkeyAuthentication yes, PasswordAuthentication yes
- python3 3.12.3
- Firewall: ufw.service is enabled at boot, but `ufw status verbose` reports Status: inactive. No rules are being enforced
- Failed units: none. `systemctl --failed` lists 0 units
- **As found**, no NVIDIA, CUDA, ROCm, Docker, containerd, podman, Ollama or vLLM packages were installed. `nvidia-driver-580-server-open` and `nvidia-utils-580-server` were installed afterwards under the approved directive, so NVIDIA packages and `nvidia-smi` are present on this host now. Nothing else in this list changed. See `driver-results.md` and act-010
- cloud-init, open-vm-tools and vgauth are enabled on this bare-metal host, consistent with deployment from a virtualization-oriented image
- Other enabled units of note: snapd, unattended-upgrades, multipathd, open-iscsi, lvm2-monitor, thermald, wpa_supplicant

## Capability Summary
- CPU: 24 physical cores in a single socket, single NUMA domain, no SMT. Consumer desktop silicon
- Memory: 128 GB DDR5 across 4 populated slots, non-ECC, running at 4400 MT/s
- GPU: 2 discrete NVIDIA AD103 GPUs with 16376 MiB VRAM each, 32752 MiB combined, measured from kernel reporting. Both are bound to the open-source nouveau driver, so no CUDA runtime exists in the as-found state and CUDA-dependent inference software cannot run without a driver change
- Accelerators: an Intel NPU with its driver bound and firmware loaded, and a Hailo-8 with no driver bound and therefore not usable as found
- Storage: 3.6 TB NVMe in use for the operating system at 1 percent capacity, plus 3.6 TB NVMe and 7.3 TB SATA installed but entirely unallocated
- Network: single active 1 Gb/s copper link. The installed controller is a Realtek RTL8126, and the negotiated speed is 1000 Mb/s
- Constraints / notable characteristics:
  - the second discrete GPU negotiates PCIe x4 while the device supports x16, so the two GPUs do not have equal host bandwidth
  - both GPUs report a negotiated link speed of 2.5 GT/s against a 16.0 GT/s maximum, which is consistent with idle power management but has not been confirmed under load
  - memory is non-ECC and the system serial is unset, both typical of desktop-class hardware
  - no baseboard management controller or out-of-band management interface was observed, so recovery requires in-band or physical access
  - ufw is enabled as a unit but inactive in practice, so the host is not firewalled
  - SSH currently permits password authentication

## Notes
- Discovery was performed over SSH to 192.168.50.200 by direct IP. Persistent `hx.local.arpa` DNS is not established; act-001 remains open and did not block this discovery
- The address 192.168.50.200 was outside the server range documented at the time of discovery. The project owner amended the allocation policy on 2026-08-11 so that servers occupy 192.168.50.200-254. See iss-006, resolved by policy change with no change to this server
- Firmware, DIMM and Secure Boot facts required interactive sudo. All commands executed were read-only
- Vendor specifications were not used to populate any field in this record

**Discovery Status:** COMPLETE

> Role assignment is not performed in this file.
