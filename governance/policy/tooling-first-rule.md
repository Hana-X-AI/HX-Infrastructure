## Native Ubuntu Tooling First

When inspecting or administering Ubuntu servers, use the operating system's existing native tools and exposed kernel/system interfaces before installing or introducing additional utilities.

For Phase 1 discovery:

- Use commands already present on the server first.
- Prefer direct system evidence from `/proc`, `/sys`, `systemd`, `dpkg`, `iproute2`, `util-linux`, and other installed Ubuntu tooling.
- Do not install a package merely to obtain discovery information.
- Do not install or change hardware drivers merely to expose additional discovery information.
- If a fact cannot be determined reliably from the server's current as-found state, record it as unavailable rather than modifying the server.

Preferred native sources include, where applicable:

```text
hostname
hostnamectl
uname
cat /etc/os-release
lscpu
free
lsmem
lspci
lsusb
lsblk
blkid
findmnt
df
ip
ss
resolvectl
timedatectl
systemctl
journalctl
dmesg
dpkg
apt-cache
/sys
/proc
```

Use privileged read-only commands with `sudo` when required and already permitted.

Examples:

```bash
sudo dmidecode
sudo lspci -vv
sudo journalctl -k -b
sudo dmesg
```

Hardware facts must come from authoritative system evidence whenever possible.

Do not infer a hardware property from an unrelated value. For example:

- do not treat a GPU PCI BAR size as physical VRAM;
- do not infer disk capacity from filesystem free space;
- do not infer physical RAM from swap or available-memory values;
- do not infer hardware capabilities solely from a product/model name when variants exist.

If native Ubuntu tooling does not expose a reliable value, use:

```text
unavailable from current as-found OS/driver state
```

and record the evidence that was available.

External documentation, Context7, vendor specifications, or additional tooling may be used to interpret discovered hardware, but they must not replace direct server evidence for the as-found discovery record.

During Phase 1, installing a missing diagnostic utility or vendor driver requires an explicit project decision and must not be done automatically.

During Phase 2, additional vendor or role-specific tooling may be installed only when required by the approved server role and allowed by the infrastructure contract.