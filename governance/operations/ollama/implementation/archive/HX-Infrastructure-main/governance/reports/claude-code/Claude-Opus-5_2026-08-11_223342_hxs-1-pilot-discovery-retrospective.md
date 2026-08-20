# hxs-1 Pilot Discovery Retrospective

**Author:** Claude Opus 5 (Claude Code)
**Reported at:** 2026-08-11 22:33:42 -05:00
**Subject:** First real Phase 1 discovery, `hxs-1` at 192.168.50.200
**Outcome:** Discovery complete, audit passed, registry synchronised, Phase 2 still blocked, regression suite 153/153
**Purpose:** Capture what actually happened so servers 2 through 15 cost a fraction of what server one cost

---

## Headline

The discovery itself was never the hard part. Collecting the facts took two commands. **Everything expensive was authentication and transport.**

One preparation step, already written in `human-pre-discovery-checklist.md` section 4 and not applied to `hxs-1`, would have eliminated roughly two thirds of the effort: **permanent `NOPASSWD` sudo for `hxsa`**. Without it the collector's `sudo -n` calls failed silently, which forced a second privileged pass, which could not be redirected to a file, which produced four separate failed attempts before a working method was found.

The checklist was right. It just had not been run against this host.

---

## 1. What worked

### Commands that returned useful data

Every one of these produced directly usable facts on the first attempt:

| Command | What it gave |
| --- | --- |
| `hostnamectl` | vendor, model, firmware version and date, chassis, machine ID — **without root** |
| `lscpu` | model, sockets, cores, threads, NUMA, cache, virtualization |
| `lsmem`, `free -h`, `numactl --hardware` | installed and online memory, NUMA sizing |
| `lspci -nnk` | every device with vendor/device ID **and bound driver** |
| `lsblk -e7 -o NAME,PATH,MODEL,SERIAL,SIZE,TYPE,FSTYPE,MOUNTPOINTS,TRAN,ROTA` | model, serial, capacity, transport and rotational flag in one pass |
| `blkid`, `findmnt`, `df -hT`, `/etc/fstab` | filesystem UUIDs, mounts, persistence method |
| `ip -br link`, `ip -br address`, `ip route`, `resolvectl status` | interfaces, MAC, addressing, gateway, resolver |
| `/sys/class/net/*/speed` and `/duplex` | negotiated link speed without extra tooling |
| `timedatectl`, `systemctl --failed`, `systemctl list-unit-files --state=enabled` | time sync, unit health, enabled units |
| `dpkg-query -W` filtered | installed package versions |
| `ss -lntup` | listening sockets and bind scope |
| **`journalctl -k -b` and `dmesg`** | **GPU VRAM** — the single most valuable command of the exercise |
| `/sys/bus/pci/devices/*/current_link_speed`, `current_link_width`, `max_link_*` | PCIe negotiated versus maximum, per GPU |
| `dmidecode -t memory` (root) | DIMM size, slot, type, speed, part number, ECC state |
| `mokutil --sb-state`, `sshd -T`, `ufw status verbose` (root) | Secure Boot, effective SSH config, firewall reality |

### The standout

`journalctl -k -b | grep -i vram` returned:

```text
nouveau 0000:02:00.0: drm: VRAM: 16376 MiB
nouveau 0000:81:00.0: drm: VRAM: 16376 MiB
```

The kernel names the value as VRAM, which is exactly the evidence standard the project requires. **This is the correct primary source for GPU memory on a host with no vendor driver**, and it should be in the collector permanently. It was not, which is why the first pass reported VRAM as unobtainable.

`hostnamectl` deserves a second mention. It reads DMI through `/sys/class/dmi/id/` and returns vendor, model and firmware **without privilege**, covering most of what `dmidecode -t system` and `-t bios` provide. Only the serial numbers and DIMM detail genuinely need root.

### SSH behaviour

Predictable and well-behaved. Server offered `publickey,password`. Host key accepted once, then stable. `OpenSSH_9.6p1 Ubuntu-3ubuntu13.18` on the server, `OpenSSH_for_Windows_9.5p2` on the workstation, no protocol issues between them.

### sudo behaviour

Correct in both directions. `sudo -n` refused cleanly when no cached credential existed — which is the right behaviour, even though it cost us. Interactive `sudo` worked normally once given a real terminal.

### Discovery collector behaviour

**First real execution in the project's history, and it ran correctly.** The `section()` / `run()` structure produced output that was straightforward to parse, the `2>&1 || true` per command meant one failure never aborted the run, and every command was genuinely read-only as claimed.

### audit-discovery behaviour

The field-level rules were more useful as a construction checklist than as a post-hoc audit — building the record against them meant the audit found nothing. The documented distinction that hook acceptance is the floor rather than Phase 1 acceptance held up in practice.

### Registry synchronisation

Clean. One row added, factual columns only, `Assigned Role` and `Workload / Model` left blank, Phase 2 `BLOCKED`. The anchored header validator accepted the modified table.

### Hooks and subagent behaviour

All correct, and this run was the first real test of several:

- `PostToolUse` validator accepted a genuine complete record — previously only ever tested against fixtures;
- `hx-phase1-guard` denied `apt-get install` against the live project root;
- `hx-session-state` counted 1 registered, 1 complete, 0 roles from a real registry row;
- the SubagentStop matcher and payload behaviour, verified live earlier in the session, held.

No hook produced a false positive during discovery.

---

## 2. What did not work

### Commands unavailable on the host

| Command | Consequence |
| --- | --- |
| `nvidia-smi` | GPU UUIDs unobtainable; VRAM had to come from the kernel log instead |
| `nvme list` (`nvme-cli`) | no NVMe-specific detail; `lsblk` covered model and serial adequately |
| `smartctl` (`smartmontools`) | no drive health or power-on hours |

None were installed, correctly, per the Tooling First Rule. `lshw` **was** present and provided useful independent confirmation of GPU model and PCI ID.

### Commands requiring interactive sudo

`dmidecode`, `pvs`/`vgs`/`lvs`, `ufw status`, `sshd -T`, `mokutil`, and `dmesg`. This set is the entire reason a second pass existed.

### Commands producing incomplete or ambiguous information

Two genuine problems, both worth fixing:

**`dmidecode` without root fails silently.** It printed a banner and no data:

```text
# dmidecode 3.5
Scanning /dev/mem for entry point.
```

No error, no non-zero exit visible in the transcript. A reader scanning the output sees a heading and moves on. Manufacturer serial, BIOS detail and the complete DIMM layout were lost this way, and nothing flagged it.

**`pvs`/`vgs`/`lvs` without root return empty output** — which is indistinguishable from "this host has no LVM". Only the root pass proved there genuinely is no LVM. An empty result that means two different things is worse than an error.

### GPU facts unavailable without vendor driver

Only **GPU UUID** is genuinely blocked. VRAM was recoverable from kernel messages, and model plus PCI ID come from `lspci`. That is a much better outcome than the first pass suggested, and it was my error to report VRAM as unobtainable before exhausting native sources.

### Commands blocked unnecessarily by hooks

**None during discovery.** One block occurred outside it: the Phase 1 guard denied a `git commit` whose message quoted a RAID creation command. The guard inspects command text and cannot distinguish a quoted example from a real invocation. Correct conservative behaviour; the message was passed through a file instead. No change recommended.

### Time-consuming manual steps

Ranked by cost:

1. **Four failed attempts to run the privileged pass.** Each needed a human at the keyboard.
2. **Host key acceptance**, which had to be interactive on first contact.
3. **Transferring the collector to the host** — three different methods tried before one held.

### Authentication interruptions

Every remote action required the operator to type a password. Cause: no authorised key, and Windows OpenSSH has no password automation — no `sshpass`, no `plink` present.

The four failures, and what each taught:

| Attempt | Failure | Cause |
| --- | --- | --- |
| 1 | `ssh ... 'bash -s' < script` via `!` | `!` has no tty; the redirect also consumed the stdin the prompt needed, so the script's opening comment lines were submitted as password guesses |
| 2 | `Get-Content script \| ssh ...` | PowerShell rejoins pipeline lines with `\r\n`; remote bash failed with `$'\r': command not found` on a file containing zero CR bytes |
| 3 | `ssh -t ... \| Out-File` | 0 bytes captured; stderr was not redirected so the real error never reached the file |
| 4 | `ssh -t ... \| Tee-Object` | `[sudo] password for hxsa:` then `sudo: a password is required` — piping output breaks the terminal sudo needs |

What finally worked: base64-encode the script, run it server-side with output to `/tmp`, `scp` the result back, remove the temp file. Three prompts, one write to the host, removed afterwards.

---

## 3. What was unnecessary

### Redundant commands

- **`lspci -vv` for each GPU.** Its memory regions are apertures, not VRAM, and must not be used as VRAM evidence. PCIe link state came from sysfs more cleanly. Only `lspci -nnk` earned its place.
- **Three overlapping memory sources.** `free -h`, `lsmem` and `dmidecode -t memory` all ran. Two suffice: one for installed total, one for DIMM topology.
- **`numactl --hardware`** largely repeats `lscpu`'s NUMA lines on a single-socket host.
- **`findmnt -A`** emitted the full mount tree, overwhelmingly kernel pseudo-filesystems. Noise against signal.

### Probes that duplicated existing evidence

My **first VRAM probe computed PCI BAR sizes** and offered BAR1 as corroboration on the Resizable-BAR heuristic. That was wrong, and `governance/reports/owner_2026-08-11_gpu-vram-discovery-prompt.md` correctly prohibited it. A BAR is an address-space aperture, not physical memory. The probe was rewritten before it ever ran.

**Two separate probe scripts** were prepared where one would do. Combining them into a single pass, which is what eventually ran, halved the authentication burden.

### External documentation lookups

**Context7 added real value and was not redundant.** It established vLLM's compute capability floor of 7.5, the supported Python range of 3.10 to 3.13, and the `gpu_memory_utilization` default of 0.92 — facts that materially shaped the capability analysis and that I would otherwise have asserted from memory. It replaced no server evidence.

---

## 4. What should change in automation

### Collector improvements — highest value first

1. **Add kernel-log VRAM extraction.** `journalctl -k -b | grep -Ei 'vram|gddr|fb:'`. This is how GPU memory is obtained without a vendor driver, and its absence caused the single largest gap in the first pass.
2. **Add a non-root DMI fallback.** Read `/sys/class/dmi/id/` for `sys_vendor`, `product_name`, `board_name`, `bios_version`, `bios_date` when `dmidecode` is unprivileged. Most identity facts need no root at all.
3. **Make "not installed" explicit.** Every optional tool should print `TOOL NOT INSTALLED: nvme-cli` rather than producing empty output. Silence currently reads as a collected result.
4. **Disambiguate permission from absence.** For `pvs`/`vgs`/`lvs`, emit `requires root — not determined` when unprivileged, never an empty result that could mean "no LVM".
5. **Add PCIe link state per GPU** — negotiated and maximum speed and width. The x4 second slot on `hxs-1` is a first-order capability constraint that no other command surfaced.
6. **Add the security and access block:** `ufw status verbose`, `sshd -T` filtered, `mokutil --sb-state`, UEFI versus legacy boot.
7. **Add pending-update count** rather than the full list.
8. **Filter `findmnt`** to real filesystems, excluding `sysfs`, `proc`, `cgroup`, `tmpfs`, `devtmpfs`.
9. **Single script with an optional privileged section**, so one authentication covers everything when `sudo -n` works.

### Discovery skill improvements

- Document the **base64 transport** as the standard method for getting the collector to a host. It is immune to line-ending translation and leaves stdin free.
- Record that the **`!` prefix cannot service interactive authentication** — no controlling terminal.
- State that when `NOPASSWD` sudo is prepared per the human checklist, **a single collector pass is sufficient** and no second privileged pass is needed.

### Validator improvements

- Consider requiring a **`VRAM source`** field whenever a VRAM value is present, so provenance travels with the number. The current record carries it by convention only.
- Consider requiring **explicit `unavailable` wording** rather than allowing a field to be silently thin.

### Hook adjustments

**None.** Every hook behaved correctly throughout, including the one denial outside discovery.

### Documentation and template improvements

`servers/_templates/discovery.md` should gain fields the pilot proved necessary:

```text
VRAM source
PCIe link (negotiated / maximum) per GPU
Secure Boot state
Boot mode (UEFI / legacy)
Firewall state
Effective SSH authentication methods
```

---

## 5. What the human should prepare before discovery

`human-pre-discovery-checklist.md` already covers this well. The pilot validated it and exposed one gap in application rather than content.

| Item | hxs-1 status | Cost of the gap |
| --- | --- | --- |
| Ubuntu 24.04 installed | yes, 24.04.4 | none |
| Network reachable | yes, 8 ms | none |
| Approved static IP configured | yes, but outside the then-documented range | resolved by owner policy amendment, `iss-006` |
| `hxsa` account available | yes | none |
| OpenSSH server running | yes, socket-activated | none |
| **`NOPASSWD` sudo prepared** | **no — `sudo -n` refused** | **the dominant cost of the exercise** |
| Local console available | not required | none |
| No role-specific software applied | confirmed clean | none |
| UFW permanently disabled | inactive, but unit still enabled at boot | minor; checklist expects both |

**The one change that matters most:** run checklist section 4 before handoff. With `sudo -n true` succeeding, the collector's existing privileged commands would have worked on the first pass, and attempts one through four would never have happened.

---

## 6. What should NOT be required

The pilot confirms all of these are genuinely unnecessary for Phase 1 discovery:

| Not required | Evidence from the pilot |
| --- | --- |
| NVIDIA proprietary driver | GPU model, PCI ID, count and **VRAM** were all obtained without it. Only GPU UUID was lost |
| CUDA | not needed to discover anything |
| vLLM | not needed to discover anything |
| Ollama | not needed to discover anything |
| Persistent `hx.local.arpa` DNS | discovery ran entirely by IP; `act-001` stayed open and blocked nothing |
| Shared fleet SSH identity | interactive authentication was sufficient; the shared key remains a Phase 2 baseline activity |
| Role assignment | the record was completed and audited with no role assigned, and none was assigned |

---

## 7. Cost model for the remaining fleet

| Scenario | Human interactions per server | Passes |
| --- | --- | --- |
| `hxs-1` as it actually ran | 4 failed plus 3 successful prompts | 2 collector passes plus 4 diagnostic attempts |
| With checklist section 4 applied | 1 password prompt | 1 combined pass |
| With Phase 2 fleet key, later | 0 | 1 |

Fourteen servers remain. The difference between the first and second rows is roughly forty avoidable human interactions.

---

## 8. Recommended actions

| Priority | Action |
| --- | --- |
| High | Apply `human-pre-discovery-checklist.md` section 4 to every remaining server before handoff |
| High | Rebuild the collector with items 1 through 9 above, and validate against `hxs-1` where the answers are already known |
| Medium | Extend `servers/_templates/discovery.md` with the six new fields |
| Medium | Document the base64 transport in the `discover-server` skill |
| Low | Consider a `VRAM source` requirement in the validator |
| Low | Correct the duplicate section numbering in the human checklist |

The collector rebuild is worth doing **before** server two rather than after server four. Validating it against `hxs-1`, where every answer is already known, is a free correctness check that will not be available later.
