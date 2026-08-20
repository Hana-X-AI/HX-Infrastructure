# hxs-2 — pre-work results

Human preparation record for one server, completed before discovery ran.
The raw terminal output below is the evidence and is preserved verbatim;
only the summary above it was added.

**Server:** hxs-2
**IP address:** 192.168.50.201
**FQDN:** hxs-2.hx.local.arpa
**Admin account:** hxsa

## Declared hardware

Counts as physically installed, taken from building or racking the machine rather
than from running a command. A wrong count invents a fault, so `unknown` is a valid
answer and no value is guessed here.

| Item | Declared |
| --- | --- |
| Discrete GPUs | not recorded in this file |
| Drives | not recorded in this file |
| Wired NICs | not recorded in this file |

## Preparation outcome

Derived from the raw output below. `not recorded here` means this record does not
show the check, not that the check failed.

| Check | Result |
| --- | --- |
| Passwordless sudo | not recorded here |
| Fleet key installed | not recorded here |
| ufw disabled | confirmed — `Status: inactive` |
| SSH active on port 22 | not recorded here |

## Raw terminal output

Verbatim. Do not edit.

````text
hxsa@hxs-2:~$ sh -c 'set -e; tmp=/etc/sudoers.d/90-hx-admin.tmp; umask 022; printf "%s\n" "hxsa ALL=(ALL:ALL) NOPASSWD: ALL" > "$tmp"; chown root:root "$tmp"; chmod 0440 "$tmp"; visudo -cf "$tmp"; mv "$tmp" /etc/sudoers.d/90-hx-admin; visudo -c'
sh: 1: cannot create /etc/sudoers.d/90-hx-admin.tmp: Permission denied
hxsa@hxs-2:~$ sudo sh -c 'set -e; tmp=/etc/sudoers.d/90-hx-admin.tmp; umask 022; printf "%s\n" "hxsa ALL=(ALL:ALL) NOPASSWD: ALL" > "$tmp"; chown root:root "$tmp"; chmod 0440 "$tmp"; visudo -cf "$tmp"; mv "$tmp" /etc/sudoers.d/90-hx-admin; visudo -c'
/etc/sudoers.d/90-hx-admin.tmp: parsed OK
/etc/sudoers: parsed OK
/etc/sudoers.d/90-hx-admin: parsed OK
/etc/sudoers.d/README: parsed OK
hxsa@hxs-2:~$ sudo -n true
echo $?
0
hxsa@hxs-2:~$ sudo -n dmidecode -t system | head
# dmidecode 3.5
Getting SMBIOS data from sysfs.
SMBIOS 3.0.0 present.

Handle 0x0001, DMI type 1, 27 bytes
System Information
        Manufacturer: Gigabyte Technology Co., Ltd.
        Product Name: Default string
        Version: Default string
        Serial Number: Default string
hxsa@hxs-2:~$ sudo ufw status
Status: inactive
hxsa@hxs-2:~$ ip -br link
ip -br addr
ip route
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
enp6s0           DOWN           40:8d:5c:e7:90:e9 <BROADCAST,MULTICAST> 
eno1             UP             40:8d:5c:e7:90:d5 <BROADCAST,MULTICAST,UP,LOWER_UP> 
wlp5s0           DOWN           58:91:cf:e7:8a:38 <BROADCAST,MULTICAST> 
lo               UNKNOWN        127.0.0.1/8 ::1/128 
enp6s0           DOWN           
eno1             UP             192.168.50.201/24 fe80::428d:5cff:fee7:90d5/64 
wlp5s0           DOWN           
default via 192.168.50.1 dev eno1 proto static 
192.168.50.0/24 dev eno1 proto kernel scope link src 192.168.50.201 
hxsa@hxs-2:~$ lspci -nn | grep -Ei 'vga|3d|display'
02:00.0 VGA compatible controller [0300]: NVIDIA Corporation Device [10de:2d04] (rev a1)
03:00.0 VGA compatible controller [0300]: NVIDIA Corporation Device [10de:2d04] (rev a1)
hxsa@hxs-2:~$ lspci -nnk | grep -A4 -Ei 'vga|3d|display'
02:00.0 VGA compatible controller [0300]: NVIDIA Corporation Device [10de:2d04] (rev a1)
        Subsystem: Micro-Star International Co., Ltd. [MSI] Device [1462:5351]
        Kernel modules: nvidiafb, nouveau
02:00.1 Audio device [0403]: NVIDIA Corporation Device [10de:22eb] (rev a1)
        Subsystem: NVIDIA Corporation Device [10de:0000]
--
03:00.0 VGA compatible controller [0300]: NVIDIA Corporation Device [10de:2d04] (rev a1)
        Subsystem: Micro-Star International Co., Ltd. [MSI] Device [1462:5351]
        Kernel modules: nvidiafb, nouveau
03:00.1 Audio device [0403]: NVIDIA Corporation Device [10de:22eb] (rev a1)
        Subsystem: NVIDIA Corporation Device [10de:0000]
hxsa@hxs-2:~$ hostnamectl
cat /etc/os-release
uname -a
lscpu
free -h
lsblk -e7 -o NAME,MODEL,SERIAL,SIZE,TYPE,FSTYPE,MOUNTPOINTS
ip -br addr
ip route
resolvectl status
timedatectl
systemctl --failed --no-pager
sudo -n dmidecode -t system 2>/dev/null | head -40
sudo -n ss -lntp
 Static hostname: hxs-2
       Icon name: computer-desktop
         Chassis: desktop 🖥️
      Machine ID: 0c249b9ad97c48d0b7d33693d120a576
         Boot ID: 16af16b6fd70433ebce46bb312d000f1
Operating System: Ubuntu 24.04.4 LTS              
          Kernel: Linux 7.0.0-28-generic
    Architecture: x86-64
 Hardware Vendor: Gigabyte Technology Co., Ltd.
  Hardware Model: X99-UD5 WIFI-CF
Firmware Version: F22
   Firmware Date: Mon 2016-06-13
    Firmware Age: 10y 1month 4w 1d                
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=noble
LOGO=ubuntu-logo
Linux hxs-2 7.0.0-28-generic #28~24.04.1-Ubuntu SMP PREEMPT_DYNAMIC Wed Jul  1 15:50:57 UTC 2 x86_64 x86_64 x86_64 GNU/Linux
Architecture:                x86_64
  CPU op-mode(s):            32-bit, 64-bit
  Address sizes:             46 bits physical, 48 bits virtual
  Byte Order:                Little Endian
CPU(s):                      16
  On-line CPU(s) list:       0-15
Vendor ID:                   GenuineIntel
  Model name:                Intel(R) Core(TM) i7-5960X CPU @ 3.00GHz
    CPU family:              6
    Model:                   63
    Thread(s) per core:      2
    Core(s) per socket:      8
    Socket(s):               1
    Stepping:                2
    CPU(s) scaling MHz:      42%
    CPU max MHz:             3500.0000
    CPU min MHz:             1200.0000
    BogoMIPS:                5999.83
    Flags:                   fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall 
                             nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes6
                             4 monitor ds_cpl vmx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid dca sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsa
                             ve avx f16c rdrand lahf_lm abm cpuid_fault epb pti intel_ppin ssbd ibrs ibpb stibp tpr_shadow flexpriority ept vpid ept_ad fsgsb
                             ase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid cqm xsaveopt cqm_llc cqm_occup_llc dtherm ida arat pln pts vnmi md_clear flush_l
                             1d
Virtualization features:     
  Virtualization:            VT-x
Caches (sum of all):         
  L1d:                       256 KiB (8 instances)
  L1i:                       256 KiB (8 instances)
  L2:                        2 MiB (8 instances)
  L3:                        20 MiB (1 instance)
NUMA:                        
  NUMA node(s):              1
  NUMA node0 CPU(s):         0-15
Vulnerabilities:             
  Gather data sampling:      Not affected
  Ghostwrite:                Not affected
  Indirect target selection: Not affected
  Itlb multihit:             KVM: Mitigation: Split huge pages
  L1tf:                      Mitigation; PTE Inversion; VMX conditional cache flushes, SMT vulnerable
  Mds:                       Mitigation; Clear CPU buffers; SMT vulnerable
  Meltdown:                  Mitigation; PTI
  Mmio stale data:           Mitigation; Clear CPU buffers; SMT vulnerable
  Old microcode:             Not affected
  Reg file data sampling:    Not affected
  Retbleed:                  Not affected
  Spec rstack overflow:      Not affected
  Spec store bypass:         Mitigation; Speculative Store Bypass disabled via prctl
  Spectre v1:                Mitigation; usercopy/swapgs barriers and __user pointer sanitization
  Spectre v2:                Mitigation; Retpolines; IBPB conditional; IBRS_FW; STIBP conditional; RSB filling; PBRSB-eIBRS Not affected; BHI Not affected
  Srbds:                     Not affected
  Tsa:                       Not affected
  Tsx async abort:           Not affected
  Vmscape:                   Mitigation; IBPB before exit to userspace
               total        used        free      shared  buff/cache   available
Mem:            62Gi       1.0Gi        61Gi       1.5Mi       764Mi        61Gi
Swap:          8.0Gi          0B       8.0Gi
NAME        MODEL               SERIAL            SIZE TYPE FSTYPE MOUNTPOINTS
sda         WDC WD6400AAKS-6    WD-WCASYC677952 596.2G disk        
sdb         WDC WD6400AAKS-6    WD-WCASY9039376 596.2G disk        
nvme0n1     WD_BLACK SN7100 4TB 251119800431      3.6T disk        
├─nvme0n1p1                                         1G part vfat   /boot/efi
└─nvme0n1p2                                       3.6T part ext4   /
lo               UNKNOWN        127.0.0.1/8 ::1/128 
enp6s0           DOWN           
eno1             UP             192.168.50.201/24 fe80::428d:5cff:fee7:90d5/64 
wlp5s0           DOWN           
default via 192.168.50.1 dev eno1 proto static 
192.168.50.0/24 dev eno1 proto kernel scope link src 192.168.50.201 
Global
         Protocols: -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
  resolv.conf mode: stub

Link 2 (enp6s0)
    Current Scopes: none
         Protocols: -DefaultRoute -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported

Link 3 (eno1)
    Current Scopes: DNS
         Protocols: +DefaultRoute -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
Current DNS Server: 192.168.50.1
       DNS Servers: 192.168.50.1

Link 4 (wlp5s0)
    Current Scopes: none
         Protocols: -DefaultRoute -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
               Local time: Wed 2026-08-12 03:44:13 UTC
           Universal time: Wed 2026-08-12 03:44:13 UTC
                 RTC time: Wed 2026-08-12 03:44:13
                Time zone: Etc/UTC (UTC, +0000)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: no
  UNIT LOAD ACTIVE SUB DESCRIPTION

0 loaded units listed.
# dmidecode 3.5
Getting SMBIOS data from sysfs.
SMBIOS 3.0.0 present.

Handle 0x0001, DMI type 1, 27 bytes
System Information
        Manufacturer: Gigabyte Technology Co., Ltd.
        Product Name: Default string
        Version: Default string
        Serial Number: Default string
        UUID: 038d0240-045c-05e7-9006-e90700080009
        Wake-up Type: Power Switch
        SKU Number: Default string
        Family: Default string

Handle 0x0025, DMI type 12, 5 bytes
System Configuration Options
        Option 1: Default string

Handle 0x0026, DMI type 32, 20 bytes
System Boot Information
        Status: No errors detected

State       Recv-Q      Send-Q           Local Address:Port             Peer Address:Port      Process                                                       
LISTEN      0           4096                   0.0.0.0:22                    0.0.0.0:*          users:(("sshd",pid=1099,fd=3),("systemd",pid=1,fd=147))      
LISTEN      0           4096             127.0.0.53%lo:53                    0.0.0.0:*          users:(("systemd-resolve",pid=818,fd=15))                    
LISTEN      0           4096                127.0.0.54:53                    0.0.0.0:*          users:(("systemd-resolve",pid=818,fd=17))                    
LISTEN      0           4096                      [::]:22                       [::]:*          users:(("sshd",pid=1099,fd=4),("systemd",pid=1,fd=148))      
hxsa@hxs-2:~$ 
````
