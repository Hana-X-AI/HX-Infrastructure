# hxs-12 — pre-work results

Human preparation record for one server, completed before discovery ran.
The raw terminal output below is the evidence and is preserved verbatim;
only the summary above it was added.

**Server:** hxs-12
**IP address:** 192.168.50.211
**FQDN:** hxs-12.hx.local.arpa
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

 System information as of Wed Aug 12 09:33:58 PM UTC 2026

  System load:  0.04               Temperature:           44.0 C
  Usage of /:   4.7% of 232.64GB   Processes:             142
  Memory usage: 1%                 Users logged in:       0
  Swap usage:   0%                 IPv4 address for eno1: 192.168.50.211

Expanded Security Maintenance for Applications is not enabled.

34 updates can be applied immediately.
1 of these updates is a standard security update.
To see these additional updates run: apt list --upgradable

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status



The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

hxsa@hxs-12:~$ ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eno1             UP             192.168.50.211/24 fe80::12e7:c6ff:fe10:fbc2/64 
hxsa@hxs-12:~$ sudo sh -c 'set -e; tmp=/etc/sudoers.d/90-hx-admin.tmp; umask 022; printf "%s\n" "hxsa ALL=(ALL:ALL) NOPASSWD: ALL" > "$tmp"; chown root:root "$tmp"; chmod 0440 "$tmp"; visudo -cf "$tmp"; mv "$tmp" /etc/sudoers.d/90-hx-admin; visudo -c'
[sudo] password for hxsa: 
/etc/sudoers.d/90-hx-admin.tmp: parsed OK
/etc/sudoers: parsed OK
/etc/sudoers.d/90-hx-admin: parsed OK
/etc/sudoers.d/README: parsed OK
hxsa@hxs-12:~$ sudo -n true
echo $?
0
hxsa@hxs-12:~$ sudo ufw disable
sudo systemctl disable --now ufw
Firewall stopped and disabled on system startup
Synchronizing state of ufw.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install disable ufw
Removed "/etc/systemd/system/multi-user.target.wants/ufw.service".
hxsa@hxs-12:~$ sudo ufw status
systemctl is-enabled ufw || true
systemctl is-active ufw || true
Status: inactive
disabled
inactive
hxsa@hxs-12:~$ systemctl is-active ssh
sudo sshd -T | grep '^port '
active
port 22
hxsa@hxs-12:~$ 

PS C:\Users\JarvisRichardson> Get-Content "$HOME\.ssh\hx_fleet_ed25519.pub" | ssh hxsa@192.168.50.211 "mkdir -p -m 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && grep -v 'hx_fleet_ed25519\.pub$' ~/.ssh/authorized_keys | sort -u > ~/.ssh/ak.tmp && mv ~/.ssh/ak.tmp ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && echo INSTALLED"
The authenticity of host '192.168.50.211 (192.168.50.211)' can't be established.
ED25519 key fingerprint is SHA256:rVoitmZi9HHfsk5QwIkaE3B2J5nsg9yXc46g9UAQlyQ.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.50.211' (ED25519) to the list of known hosts.
hxsa@192.168.50.211's password:
INSTALLED
PS C:\Users\JarvisRichardson> ssh -i "$HOME\.ssh\hx_fleet_ed25519" -o BatchMode=yes hxsa@192.168.50.211 "id -un; sudo -n true && echo SUDO_NOPASSWD=yes"
hxsa
SUDO_NOPASSWD=yes
PS C:\Users\JarvisRichardson>
````
