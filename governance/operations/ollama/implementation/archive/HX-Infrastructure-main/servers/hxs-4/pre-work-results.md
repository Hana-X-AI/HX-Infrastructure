# hxs-4 — pre-work results

Human preparation record for one server, completed before discovery ran.
The raw terminal output below is the evidence and is preserved verbatim;
only the summary above it was added.

**Server:** hxs-4
**IP address:** 192.168.50.203
**FQDN:** hxs-4.hx.local.arpa
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
Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 7.0.0-28-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Wed Aug 12 04:40:32 AM UTC 2026

  System load:  0.05               Temperature:           68.8 C
  Usage of /:   1.2% of 914.78GB   Processes:             365
  Memory usage: 2%                 Users logged in:       0
  Swap usage:   0%                 IPv4 address for eno1: 192.168.50.203

 * Strictly confined Kubernetes makes edge and IoT secure. Learn how MicroK8s
   just raised the bar for easy, resilient and secure K8s cluster deployment.

   https://ubuntu.com/engage/secure-kubernetes-at-the-edge

Expanded Security Maintenance for Applications is not enabled.

34 updates can be applied immediately.
1 of these updates is a standard security update.
To see these additional updates run: apt list --upgradable

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

hxsa@hxs-4:~$ sudo sh -c 'set -e; tmp=/etc/sudoers.d/90-hx-admin.tmp; umask 022; printf "%s\n" "hxsa ALL=(ALL:ALL) NOPASSWD: ALL" > "$tmp"; chown root:root "$tmp"; chmod 0440 "$tmp"; visudo -cf "$tmp"; mv "$tmp" /etc/sudoers.d/90-hx-admin; visudo -c'
[sudo] password for hxsa: 
/etc/sudoers.d/90-hx-admin.tmp: parsed OK
/etc/sudoers: parsed OK
/etc/sudoers.d/90-hx-admin: parsed OK
/etc/sudoers.d/README: parsed OK
hxsa@hxs-4:~$ sudo -n true
echo $?
0
hxsa@hxs-4:~$ sudo ufw disable
sudo systemctl disable --now ufw
Firewall stopped and disabled on system startup
Synchronizing state of ufw.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install disable ufw
Removed "/etc/systemd/system/multi-user.target.wants/ufw.service".
hxsa@hxs-4:~$ sudo ufw status
systemctl is-enabled ufw || true
systemctl is-active ufw || true
Status: inactive
disabled
inactive
hxsa@hxs-4:~$ systemctl is-active ssh
sudo sshd -T | grep '^port '
active
port 22
hxsa@hxs-4:~$ 

PS C:\Users\JarvisRichardson\Desktop\HX-Infrastructure\.claude\skills\discover-server\scripts> Get-Content "$HOME\.ssh\hx_fleet_ed25519.pub" | ssh hxsa@192.168.50.203 "mkdir -p -m 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && grep -v 'hx_fleet_ed25519\.pub$' ~/.ssh/authorized_keys | sort -u > ~/.ssh/ak.tmp && mv ~/.ssh/ak.tmp ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && echo INSTALLED"
hxsa@192.168.50.203's password:
INSTALLED
PS C:\Users\JarvisRichardson\Desktop\HX-Infrastructure\.claude\skills\discover-server\scripts> ssh -i "$HOME\.ssh\hx_fleet_ed25519" -o BatchMode=yes hxsa@192.168.50.230 "id -un; sudo -n true && echo SUDO_NOPASSWD=yes"
PS C:\Users\JarvisRichardson\Desktop\HX-Infrastructure\.claude\skills\discover-server\scripts> ssh -i "$HOME\.ssh\hx_fleet_ed25519" -o BatchMode=yes hxsa@192.168.50.203 "id -un; sudo -n true && echo SUDO_NOPASSWD=yes"
hxsa
SUDO_NOPASSWD=yes
PS C:\Users\JarvisRichardson\Desktop\HX-Infrastructure\.claude\skills\discover-server\scripts>
PS C:\Users\JarvisRichardson\Desktop\HX-Infrastructure\.claude\skills\discover-server\scripts> ssh-keygen -lf "$HOME\.ssh\hx_fleet_ed25519.pub"
256 SHA256:fpIJEHjkhRYRqnhvRhtgSqggOAjkTU90vSGWbh0vsPk hx-fleet-20260810 (ED25519)
PS C:\Users\JarvisRichardson\Desktop\HX-Infrastructure\.claude\skills\discover-server\scripts>
````
