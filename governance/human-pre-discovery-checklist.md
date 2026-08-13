# human pre-discovery checklist

**purpose:** minimum human preparation required before handing an Ubuntu 24.04 server to Claude Code for Phase 1 discovery.

**scope:** human preparation only. Claude performs the actual hardware, OS, storage, GPU, service, and capability discovery.

---

## 1. verify server identity

Run:

```bash
hostname
```

Confirm the hostname matches the intended HX server name.

If it is wrong, correct it before handoff.

---

## 2. verify the static ip

Run:

```bash
ip -br addr
```

Confirm the active interface already has the approved static address:

```text
<server-ip>/24
```

Do not change Netplan, routes, DNS, interfaces, or other network configuration as part of this checklist.

If the IP is wrong, stop and correct it outside this checklist before Phase 1 discovery.

---

## 3. configure permanent noninteractive sudo for hxsa

Configure `hxsa` for permanent passwordless sudo before Claude begins discovery.

Run:

```bash
sudo sh -c 'set -e; tmp=/etc/sudoers.d/90-hx-admin.tmp; umask 022; printf "%s\n" "hxsa ALL=(ALL:ALL) NOPASSWD: ALL" > "$tmp"; chown root:root "$tmp"; chmod 0440 "$tmp"; visudo -cf "$tmp"; mv "$tmp" /etc/sudoers.d/90-hx-admin; visudo -c'
```

Verify:

```bash
sudo -n true
echo $?
```

Expected:

```text
0
```

This is a human-preparation change. Claude must not modify sudoers during Phase 1.

---

## 4. disable the ubuntu host firewall

Run:

```bash
sudo ufw disable
sudo systemctl disable --now ufw
```

Verify:

```bash
sudo ufw status
systemctl is-enabled ufw || true
systemctl is-active ufw || true
```

Expected:

```text
Status: inactive
disabled
inactive
```

This is a human-preparation change. Claude must not change firewall state during Phase 1.

---

## 5. verify ssh

Run:

```bash
systemctl is-active ssh
sudo sshd -T | grep '^port '
```

Expected:

```text
active
port 22
```

Claude will connect by the approved static IP.

Persistent `hx.local.arpa` DNS is not required for Phase 1 discovery.

---

## 5a. authorize the fleet ssh key

Discovery is unattended only when Claude can authenticate without a password. Authorize the HX fleet public key as part of human preparation, **before** handoff.

Only the **public** key is placed on the server. The private key never leaves the workstation.

From the Windows workstation:

```powershell
Get-Content "$HOME\.ssh\hx_fleet_ed25519.pub" | ssh hxsa@<server-ip> "mkdir -p -m 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && grep -v 'hx_fleet_ed25519\.pub$' ~/.ssh/authorized_keys | sort -u > ~/.ssh/ak.tmp && mv ~/.ssh/ak.tmp ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && echo INSTALLED"
```

Enter the account password once. This is the last password this server should require.

> **Use `Get-Content`, not a bare quoted path.** In PowerShell, `"$HOME\.ssh\key.pub" | ssh ...` pipes the *path string*, not the file contents, and appends a junk line to `authorized_keys` while appearing to succeed. `sshd` ignores the bad line, so the only symptom is that key authentication still fails. The `grep -v` above removes that line if it was created by an earlier attempt.

Verify from the workstation:

```powershell
ssh -i "$HOME\.ssh\hx_fleet_ed25519" -o BatchMode=yes hxsa@<server-ip> "id -un; sudo -n true && echo SUDO_NOPASSWD=yes"
```

Expected:

```text
hxsa
SUDO_NOPASSWD=yes
```

`BatchMode=yes` fails rather than prompting, so a successful result proves key authentication actually worked.

The expected key is:

```text
SHA256:fpIJEHjkhRYRqnhvRhtgSqggOAjkTU90vSGWbh0vsPk  hx-fleet-20260810 (ED25519)
```

Confirm the fingerprint matches before authorizing it:

```powershell
ssh-keygen -lf "$HOME\.ssh\hx_fleet_ed25519.pub"
```

### why this is human preparation, not discovery

Writing to `authorized_keys` is a persistent change to server access state. Performing it **before** handoff keeps it a human-prepared baseline condition, so `discovery.md` remains a pure as-found record and Claude never mutates a host during Phase 1.

Do not have Claude install this key. If a server is handed over without it, discovery still works — it simply requires a password for that server.

---

## 6. handoff

Before handing the server to Claude Code, confirm:

- [ ] hostname is correct;
- [ ] approved static IP is present;
- [ ] `sudo -n true` succeeds;
- [ ] UFW is inactive;
- [ ] UFW service is disabled and inactive;
- [ ] SSH is active on TCP/22;
- [ ] fleet public key authorized, and key authentication verified with `BatchMode=yes`;
- [ ] expected hardware counts stated below, from physical knowledge rather than from a command.

Then provide Claude Code:

```text
server name:   <server-name>
ip address:    <server-ip>

expected hardware, as physically installed:
  discrete GPUs: <count>
  drives:        <count>
  wired NICs:    <count>
```

The expected-hardware counts are the important addition. They are **not** an inventory — do not run `lspci`, `lsblk` or any discovery command to produce them. State what you know is physically in the machine, from building or racking it.

Claude compares those counts against what the operating system actually enumerates. Agreement corroborates the record. **Disagreement is a hardware finding**, and it is the only reliable way to detect a device that is installed but invisible to the OS.

This is not hypothetical. On `hxs-3` the owner knew two GPUs were installed; the operating system enumerated one. The missing card generated no kernel message whatsoever, so no amount of software discovery could have found it. Without the declared count it would have been recorded as a single-GPU host. See `iss-007`.

If a count is genuinely unknown, write `unknown` rather than guessing. A wrong number is worse than an absent one, because it manufactures a fault that does not exist.

Beyond those counts, stop manual inspection at this point.

Do not manually run the discovery inventory. Earlier `pre-work-results.md` files were produced by hand; they are superseded by this declaration. One of them was truncated at a shell continuation prompt and silently recorded nothing, which is exactly the failure mode this structured handoff removes.

Claude is responsible for:

```text
CPU discovery
memory discovery
GPU / accelerator discovery
VRAM probing
PCIe capability probing
storage discovery
network inventory beyond IP verification
OS and kernel inventory
services and listening sockets
firmware / DMI collection
Secure Boot state
installed software inventory
native-tool availability
audit-discovery
registry synchronization
phase1-gate
```

---

## 7. phase 1 boundaries

Do not install or configure role-specific software before discovery, including:

```text
NVIDIA proprietary drivers
CUDA
vLLM
Ollama
Hugging Face serving software
databases
role-specific services
```

The shared fleet SSH **public** key is an exception and is authorized during human preparation, per section 5a. It is a prepared baseline condition, not role-specific software, and Claude must still never install or modify it during Phase 1.

Do not install missing diagnostic utilities merely to improve discovery.

If a native tool is unavailable, Claude records the corresponding fact as unavailable unless the project explicitly approves otherwise.

---

## 8. human preparation complete

The human preparation process is complete when:

```text
correct hostname
+ correct static IP
+ permanent NOPASSWD sudo
+ UFW disabled
+ SSH active on port 22
+ fleet public key authorized
= ready for unattended Phase 1 discovery
```

The last two lines are what make discovery unattended. Without the fleet key, discovery still completes but costs one password per server. Without `NOPASSWD` sudo, it completes but records firmware, DIMM, VRAM, firewall and SSH facts as `REQUIRES ROOT`.
