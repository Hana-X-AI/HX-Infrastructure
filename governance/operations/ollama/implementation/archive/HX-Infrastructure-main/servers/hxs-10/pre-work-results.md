# hxs-10 — pre-work results

Human preparation record for one server, completed before discovery ran.
The raw terminal output below is the evidence and is preserved verbatim;
only the summary above it was added.

**Server:** hxs-10
**IP address:** 192.168.50.209
**FQDN:** hxs-10.hx.local.arpa
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
hxsa@hxs-9:~$ sudo sh -c 'set -e; tmp=/etc/sudoers.d/90-hx-admin.tmp; umask 022; printf "%s\n" "hxsa ALL=(ALL:ALL) NOPASSWD: ALL" > "$tmp"; chown root:root "$tmp"; chmod 0440 "$tmp"; visudo -cf "$tmp"; mv "$tmp" /etc/sudoers.d/90-hx-admin; visudo -c'
/etc/sudoers.d/90-hx-admin.tmp: parsed OK
/etc/sudoers: parsed OK
/etc/sudoers.d/90-hx-admin: parsed OK
/etc/sudoers.d/README: parsed OK
hxsa@hxs-9:~$ sudo -n true
echo $?
0
hxsa@hxs-9:~$ sudo ufw disable
sudo systemctl disable --now ufw
Firewall stopped and disabled on system startup
Synchronizing state of ufw.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install disable ufw
Removed "/etc/systemd/system/multi-user.target.wants/ufw.service".
hxsa@hxs-9:~$ sudo ufw status
systemctl is-enabled ufw || true
systemctl is-active ufw || true
Status: inactive
disabled
inactive
hxsa@hxs-9:~$ systemctl is-active ssh
sudo sshd -T | grep '^port '
active
port 22
hxsa@hxs-9:~$ 

PS C:\Users\JarvisRichardson> Get-Content "$HOME\.ssh\hx_fleet_ed25519.pub" | ssh hxsa@192.168.50.209 "mkdir -p -m 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && grep -v 'hx_fleet_ed25519\.pub$' ~/.ssh/authorized_keys | sort -u > ~/.ssh/ak.tmp && mv ~/.ssh/ak.tmp ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && echo INSTALLED"
The authenticity of host '192.168.50.209 (192.168.50.209)' can't be established.
ED25519 key fingerprint is SHA256:dzEJtcvAB8Nx/Yp1chaz9j5kHqQpYe52nYgxV4d5+jo.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.50.209' (ED25519) to the list of known hosts.
hxsa@192.168.50.209's password:
INSTALLED

PS C:\Users\JarvisRichardson> ssh -i "$HOME\.ssh\hx_fleet_ed25519" -o BatchMode=yes hxsa@192.168.50.209 "id -un; sudo -n true && echo SUDO_NOPASSWD=yes"
hxsa
SUDO_NOPASSWD=yes
````
