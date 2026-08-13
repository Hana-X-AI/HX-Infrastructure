# hxs-3 — pre-work results

Human preparation record for one server, completed before discovery ran.
The raw terminal output below is the evidence and is preserved verbatim;
only the summary above it was added.

**Server:** hxs-3
**IP address:** 192.168.50.202
**FQDN:** hxs-3.hx.local.arpa
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
| SSH active on port 22 | confirmed — `port 22` |

## Raw terminal output

Verbatim. Do not edit.

````text
Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 7.0.0-28-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Wed Aug 12 03:52:58 AM UTC 2026

  System load:  0.0              Temperature:           58.9 C
  Usage of /:   0.3% of 3.58TB   Processes:             238
  Memory usage: 0%               Users logged in:       1
  Swap usage:   0%               IPv4 address for eno1: 192.168.50.202


Expanded Security Maintenance for Applications is not enabled.

34 updates can be applied immediately.
1 of these updates is a standard security update.
To see these additional updates run: apt list --upgradable

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

hxsa@hxs-3:~$ sudo sh -c 'set -e; tmp=/etc/sudoers.d/90-hx-admin.tmp; umask 022; printf "%s\n" "hxsa ALL=(ALL:ALL) NOPASSWD: ALL" > "$tmp"; chown root:root "$tmp"; chmod 0440 "$tmp"; visudo -cf "$tmp"; mv "$tmp" /etc/sudoers.d/90-hx-admin; visudo -c'
[sudo] password for hxsa: 
/etc/sudoers.d/90-hx-admin.tmp: parsed OK
/etc/sudoers: parsed OK
/etc/sudoers.d/90-hx-admin: parsed OK
/etc/sudoers.d/README: parsed OK
hxsa@hxs-3:~$ sudo -n true
echo $?
0
hxsa@hxs-3:~$ sudo -n dmidecode -t system | head
# dmidecode 3.5
Getting SMBIOS data from sysfs.
SMBIOS 3.0.0 present.

Handle 0x0001, DMI type 1, 27 bytes
System Information
        Manufacturer: Gigabyte Technology Co., Ltd.
        Product Name: Default string
        Version: Default string
        Serial Number: Default string
hxsa@hxs-3:~$ sudo ufw status verbose
Status: inactive
hxsa@hxs-3:~$ sudo ufw disable
Firewall stopped and disabled on system startup
hxsa@hxs-3:~$ sudo systemctl disable ufw
Synchronizing state of ufw.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install disable ufw
Removed "/etc/systemd/system/multi-user.target.wants/ufw.service".
hxsa@hxs-3:~$ sudo ufw status
systemctl is-enabled ufw || true
systemctl is-active ufw || true
Status: inactive
disabled
active
hxsa@hxs-3:~$ ip -br link
ip -br addr
ip route
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
enp6s0           DOWN           40:8d:5c:e7:d0:e7 <BROADCAST,MULTICAST> 
eno1             UP             40:8d:5c:e7:d0:e5 <BROADCAST,MULTICAST,UP,LOWER_UP> 
wlp5s0           DOWN           58:91:cf:e7:53:74 <BROADCAST,MULTICAST> 
lo               UNKNOWN        127.0.0.1/8 ::1/128 
enp6s0           DOWN           
eno1             UP             192.168.50.202/24 fe80::428d:5cff:fee7:d0e5/64 
wlp5s0           DOWN           
default via 192.168.50.1 dev eno1 proto static 
192.168.50.0/24 dev eno1 proto kernel scope link src 192.168.50.202 
hxsa@hxs-3:~$ ip route get 192.168.50.1
192.168.50.1 dev eno1 src 192.168.50.202 uid 1000 
    cache 
hxsa@hxs-3:~$ systemctl status ssh --no-pager
systemctl is-enabled ssh
systemctl is-active ssh
● ssh.service - OpenBSD Secure Shell server
     Loaded: loaded (/usr/lib/systemd/system/ssh.service; disabled; preset: enabled)
     Active: active (running) since Wed 2026-08-12 03:52:57 UTC; 4min 58s ago
TriggeredBy: ● ssh.socket
       Docs: man:sshd(8)
             man:sshd_config(5)
   Main PID: 1759 (sshd)
      Tasks: 1 (limit: 70875)
     Memory: 4.1M (peak: 5.3M)
        CPU: 70ms
     CGroup: /system.slice/ssh.service
             └─1759 "sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups"

Aug 12 03:52:57 hxs-3 systemd[1]: Starting ssh.service - OpenBSD Secure Shell server...
Aug 12 03:52:57 hxs-3 sshd[1759]: Server listening on 0.0.0.0 port 22.
Aug 12 03:52:57 hxs-3 sshd[1759]: Server listening on :: port 22.
Aug 12 03:52:57 hxs-3 systemd[1]: Started ssh.service - OpenBSD Secure Shell server.
Aug 12 03:52:58 hxs-3 sshd[1761]: Accepted password for hxsa from 192.168.50.115 port 52282 ssh2
Aug 12 03:52:58 hxs-3 sshd[1761]: pam_unix(sshd:session): session opened for user hxsa(uid=1000) by hxsa(uid=0)
disabled
active
hxsa@hxs-3:~$ sudo sshd -T | grep '^port '
port 22
hxsa@hxs-3:~$ whoami
hostname
sudo -n true
hxsa
hxs-3
hxsa@hxs-3:~$ cat /etc/os-release
uname -a
timedatectl
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
Linux hxs-3 7.0.0-28-generic #28~24.04.1-Ubuntu SMP PREEMPT_DYNAMIC Wed Jul  1 15:50:57 UTC 2 x86_64 x86_64 x86_64 GNU/Linux
               Local time: Wed 2026-08-12 03:59:56 UTC
           Universal time: Wed 2026-08-12 03:59:56 UTC
                 RTC time: Wed 2026-08-12 03:59:56
                Time zone: Etc/UTC (UTC, +0000)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: no
hxsa@hxs-3:~$ for cmd in \
  hostname hostnamectl uname lscpu free lsmem lspci lsusb lsblk blkid \
  findmnt df ip ss resolvectl timedatectl systemctl journalctl dmesg \
  dpkg-query apt-cache dmidecode lshw numactl nvme; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '%-16s available\n' "$cmd"
  else
    printf '%-16s unavailable\n' "$cmd"
  fi
done
```
hostname         available
hostnamectl      available
uname            available
lscpu            available
free             available
lsmem            available
lspci            available
lsusb            available
lsblk            available
blkid            available
findmnt          available
df               available
ip               available
ss               available
resolvectl       available
timedatectl      available
systemctl        available
journalctl       available
dmesg            available
dpkg-query       available
apt-cache        available
dmidecode        available
lshw             available
numactl          available
nvme             unavailable
> lspci -nn | grep -Ei 'vga|3d|display'
> lspci -nnk | grep -A4 -Ei 'vga|3d|display'
> hostnamectl
cat /etc/os-release
uname -a
lscpu
free -h
lsblk -e7 -o NAME,MODEL,SERIAL,SIZE,TYPE,FSTYPE,MOUNTPOINTS
ip -br addr
timedatectl
systemctl --failed --no-pager
sudo -n dmidecode -t system 2>/dev/null | head -40
sudo -n ss -lntp
> 
````
