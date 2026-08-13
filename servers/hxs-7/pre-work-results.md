# hxs-7 — pre-work results

Human preparation record for one server, completed before discovery ran.
The raw terminal output below is the evidence and is preserved verbatim;
only the summary above it was added.

**Server:** hxs-7
**IP address:** 192.168.50.206
**FQDN:** hxs-7.hx.local.arpa
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
| Passwordless sudo | confirmed — `SUDO_NOPASSWD=yes` |
| Fleet key installed | confirmed — `INSTALLED` |
| ufw disabled | confirmed — `Status: inactive` |
| SSH active on port 22 | confirmed — `port 22` |

## Raw terminal output

Verbatim. Do not edit.

````text
hxsa@hxs-7:~$ sudo reboot

Broadcast message from root@hxs-7 on pts/1 (Wed 2026-08-12 19:45:21 UTC):

The system will reboot now!

hxsa@hxs-7:~$ Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 7.0.0-28-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Wed Aug 12 19:46:23 UTC 2026

  System load:  0.47               Temperature:             44.0 C
  Usage of /:   3.1% of 232.64GB   Processes:               179
  Memory usage: 2%                 Users logged in:         0
  Swap usage:   0%                 IPv4 address for enp2s0: 192.168.50.206


Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


Last login: Wed Aug 12 19:37:17 2026 from 192.168.50.115
hxsa@hxs-7:~$ sudo apt update && sudo apt upgrade -y
[sudo] password for hxsa: 
Hit:1 http://security.ubuntu.com/ubuntu noble-security InRelease
Hit:2 http://archive.ubuntu.com/ubuntu noble InRelease
Hit:3 http://archive.ubuntu.com/ubuntu noble-updates InRelease
Hit:4 http://archive.ubuntu.com/ubuntu noble-backports InRelease
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
All packages are up to date.
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
Calculating upgrade... Done
The following packages were automatically installed and are no longer required:
  libfwupd2 libgusb2
Use 'sudo apt autoremove' to remove them.
0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
hxsa@hxs-7:~$ sudo sh -c 'set -e; tmp=/etc/sudoers.d/90-hx-admin.tmp; umask 022; printf "%s\n" "hxsa ALL=(ALL:ALL) NOPASSWD: ALL" > "$tmp"; chown root:root "$tmp"; chmod 0440 "$tmp"; visudo -cf "$tmp"; mv "$tmp" /etc/sudoers.d/90-hx-admin; visudo -c'
/etc/sudoers.d/90-hx-admin.tmp: parsed OK
/etc/sudoers: parsed OK
/etc/sudoers.d/90-hx-admin: parsed OK
/etc/sudoers.d/README: parsed OK
hxsa@hxs-7:~$ sudo -n true
echo $?
0
hxsa@hxs-7:~$ sudo ufw disable
sudo systemctl disable --now ufw
Firewall stopped and disabled on system startup
Synchronizing state of ufw.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install disable ufw
Removed "/etc/systemd/system/multi-user.target.wants/ufw.service".
hxsa@hxs-7:~$ sudo ufw status
systemctl is-enabled ufw || true
systemctl is-active ufw || true
Status: inactive
disabled
inactive
hxsa@hxs-7:~$ systemctl is-active ssh
sudo sshd -T | grep '^port '
active
port 22
hxsa@hxs-7:~$ 

PS C:\Users\JarvisRichardson> Get-Content "$HOME\.ssh\hx_fleet_ed25519.pub" | ssh hxsa@192.168.50.206 "mkdir -p -m 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && grep -v 'hx_fleet_ed25519\.pub$' ~/.ssh/authorized_keys | sort -u > ~/.ssh/ak.tmp && mv ~/.ssh/ak.tmp ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && echo INSTALLED"
The authenticity of host '192.168.50.206 (192.168.50.206)' can't be established.
ED25519 key fingerprint is SHA256:vCmOGkEHWJN82Dpi3baWQbjcgJthVasAPiq4ZtO8Kpw.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.50.206' (ED25519) to the list of known hosts.
hxsa@192.168.50.206's password:
INSTALLED
PS C:\Users\JarvisRichardson> ssh -i "$HOME\.ssh\hx_fleet_ed25519" -o BatchMode=yes hxsa@192.168.50.206 "id -un; sudo -n true && echo SUDO_NOPASSWD=yes"
hxsa
SUDO_NOPASSWD=yes
PS C:\Users\JarvisRichardson>
````
