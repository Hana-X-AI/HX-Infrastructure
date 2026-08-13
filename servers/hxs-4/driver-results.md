hxsa@hxs-4:~$ Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 7.0.0-28-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Wed Aug 12 04:16:49 PM UTC 2026

  System load:  0.0                Temperature:           65.8 C
  Usage of /:   1.4% of 914.78GB   Processes:             372
  Memory usage: 2%                 Users logged in:       0
  Swap usage:   0%                 IPv4 address for eno1: 192.168.50.203

 * Strictly confined Kubernetes makes edge and IoT secure. Learn how MicroK8s
   just raised the bar for easy, resilient and secure K8s cluster deployment.

   https://ubuntu.com/engage/secure-kubernetes-at-the-edge

Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


Last login: Wed Aug 12 05:09:02 2026 from 192.168.50.115
hxsa@hxs-4:~$ echo "=== HOST ==="
hostname

echo
echo "=== NVIDIA SMI ==="
nvidia-smi

echo
echo "=== GPU SUMMARY ==="
nvidia-smi \
  --query-gpu=index,name,pci.bus_id,driver_version,memory.total \
  --format=csv

echo
echo "=== DRIVER BINDING ==="
lspci -nnk | grep -A4 -Ei 'vga|3d|display'

echo
echo "=== MODULE ==="
modinfo nvidia | grep -E '^(version|license):'

echo
echo "=== NVIDIA KERNEL ERRORS ==="
sudo journalctl -k -b | grep -Ei 'NVRM|Xid|nvidia.*fail|nvidia.*error' || true
=== HOST ===
hxs-4

=== NVIDIA SMI ===
Wed Aug 12 16:17:41 2026       
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 580.173.02             Driver Version: 580.173.02     CUDA Version: 13.0     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce RTX 5060 Ti     Off |   00000000:01:00.0 Off |                  N/A |
| 30%   35C    P0             13W /  180W |       0MiB /  16311MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+
|   1  NVIDIA GeForce RTX 5060        Off |   00000000:07:00.0 Off |                  N/A |
| 34%   37C    P0             21W /  145W |       0MiB /   8151MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+

=== GPU SUMMARY ===
index, name, pci.bus_id, driver_version, memory.total [MiB]
0, NVIDIA GeForce RTX 5060 Ti, 00000000:01:00.0, 580.173.02, 16311 MiB
1, NVIDIA GeForce RTX 5060, 00000000:07:00.0, 580.173.02, 8151 MiB

=== DRIVER BINDING ===
01:00.0 VGA compatible controller [0300]: NVIDIA Corporation Device [10de:2d04] (rev a1)
        Subsystem: PNY Device [196e:143e]
        Kernel driver in use: nvidia
        Kernel modules: nvidiafb, nouveau, nvidia_drm, nvidia
01:00.1 Audio device [0403]: NVIDIA Corporation Device [10de:22eb] (rev a1)
--
07:00.0 VGA compatible controller [0300]: NVIDIA Corporation Device [10de:2d05] (rev a1)
        Subsystem: Micro-Star International Co., Ltd. [MSI] Device [1462:5371]
        Kernel driver in use: nvidia
        Kernel modules: nvidiafb, nouveau, nvidia_drm, nvidia
07:00.1 Audio device [0403]: NVIDIA Corporation Device [10de:22eb] (rev a1)

=== MODULE ===
version:        580.173.02
license:        Dual MIT/GPL

=== NVIDIA KERNEL ERRORS ===
Aug 12 16:16:34 hxs-4 kernel: r8169 0000:05:00.0 eth0: RTL8168h/8111h, bc:fc:e7:3e:10:66, XID 541, IRQ 158
Aug 12 16:16:34 hxs-4 kernel: nvidia: module verification failed: signature and/or required key missing - tainting kernel
Aug 12 16:16:34 hxs-4 kernel: NVRM: loading NVIDIA UNIX Open Kernel Module for x86_64  580.173.02  Release Build  (dvs-builder@U22-I3-AK02-24-4)  Tue Jun 23 08:17:01 UTC 2026