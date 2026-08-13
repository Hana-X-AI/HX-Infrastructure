hxsa@hxs-1:~$ Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 7.0.0-28-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Wed Aug 12 04:16:12 PM UTC 2026

  System load:  0.07             Temperature:               52.9 C
  Usage of /:   0.3% of 3.58TB   Processes:                 366
  Memory usage: 0%               Users logged in:           0
  Swap usage:   0%               IPv4 address for enp131s0: 192.168.50.200

 * Strictly confined Kubernetes makes edge and IoT secure. Learn how MicroK8s
   just raised the bar for easy, resilient and secure K8s cluster deployment.

   https://ubuntu.com/engage/secure-kubernetes-at-the-edge

Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


Last login: Wed Aug 12 05:07:02 2026 from 192.168.50.115
hxsa@hxs-1:~$ echo "=== HOST ==="
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
hxs-1

=== NVIDIA SMI ===
Wed Aug 12 16:21:30 2026       
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 580.173.02             Driver Version: 580.173.02     CUDA Version: 13.0     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce RTX 4070 ...    Off |   00000000:02:00.0 Off |                  N/A |
| 34%   36C    P0             38W /  285W |       0MiB /  16376MiB |      2%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+
|   1  NVIDIA GeForce RTX 4070 ...    Off |   00000000:81:00.0 Off |                  N/A |
|  0%   32C    P0             40W /  285W |       0MiB /  16376MiB |      1%      Default |
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
0, NVIDIA GeForce RTX 4070 Ti SUPER, 00000000:02:00.0, 580.173.02, 16376 MiB
1, NVIDIA GeForce RTX 4070 Ti SUPER, 00000000:81:00.0, 580.173.02, 16376 MiB

=== DRIVER BINDING ===
00:02.0 VGA compatible controller [0300]: Intel Corporation Arrow Lake-U [Intel Graphics] [8086:7d67] (rev 06)
        DeviceName: Onboard - Video
        Subsystem: Micro-Star International Co., Ltd. [MSI] Device [1462:7e34]
        Kernel driver in use: i915
        Kernel modules: i915, xe
--
02:00.0 VGA compatible controller [0300]: NVIDIA Corporation AD103 [GeForce RTX 4070 Ti SUPER] [10de:2705] (rev a1)
        Subsystem: Micro-Star International Co., Ltd. [MSI] Device [1462:e13b]
        Kernel driver in use: nvidia
        Kernel modules: nvidiafb, nouveau, nvidia_drm, nvidia
02:00.1 Audio device [0403]: NVIDIA Corporation Device [10de:22bb] (rev a1)
--
80:14.5 Non-VGA unclassified device [0000]: Intel Corporation Device [8086:7f2f] (rev 10)
        Subsystem: Micro-Star International Co., Ltd. [MSI] Device [1462:7e34]
80:15.0 Serial bus controller [0c80]: Intel Corporation Device [8086:7f4c] (rev 10)
        Subsystem: Micro-Star International Co., Ltd. [MSI] Device [1462:7e34]
        Kernel driver in use: intel-lpss
--
81:00.0 VGA compatible controller [0300]: NVIDIA Corporation AD103 [GeForce RTX 4070 Ti SUPER] [10de:2705] (rev a1)
        Subsystem: Micro-Star International Co., Ltd. [MSI] Device [1462:e133]
        Kernel driver in use: nvidia
        Kernel modules: nvidiafb, nouveau, nvidia_drm, nvidia
81:00.1 Audio device [0403]: NVIDIA Corporation Device [10de:22bb] (rev a1)

=== MODULE ===
version:        580.173.02
license:        Dual MIT/GPL

=== NVIDIA KERNEL ERRORS ===
Aug 12 16:16:03 hxs-1 kernel: r8169 0000:83:00.0 eth0: RTL8126A, 34:5a:60:01:7c:fd, XID 64a, IRQ 150
Aug 12 16:16:03 hxs-1 kernel: nvidia: module verification failed: signature and/or required key missing - tainting kernel
Aug 12 16:16:03 hxs-1 kernel: NVRM: loading NVIDIA UNIX Open Kernel Module for x86_64  580.173.02  Release Build  (dvs-builder@U22-I3-AK02-24-4)  Tue Jun 23 08:17:01 UTC 2026
hxsa@hxs-1:~$ 