# HX-Infrastructure Remediation Completion — Items 1 through 4

**Reviewer:** Claude Opus 5 (Claude Code)
**Reported at:** 2026-08-11 20:44:32 -05:00
**Authoritative instruction:** `chatgpt_2026-08-11_202300_remediation-direction.md`
**Source findings:** `Claude-Opus-5_2026-08-11_201530_outstanding-findings.md`
**Scope:** Outstanding items 1 through 4 only. Items 5 through 7 were not touched.

---

## Summary

All four directed items are complete. The regression suite now completes on this machine and reports 146 pass, 0 fail, exit code 0.

Two defects were found during the work that were not in the original finding list. Both were caused by the work itself doing what it was supposed to do — running the tests that had never run, and testing the guard categories that had never been tested.

The more serious of the two: **the RAID guard has never worked.** `mdadm --create` was permitted throughout Phase 1. This is recorded as `iss-004` and is now fixed and under test.

Phase 1 remains discovery and documentation only. No Phase 2 configuration was performed. The live registry was not modified and still reads `BLOCKED`.

---

## Files changed

### Hook scripts

Each file below was changed in both its active copy under `.claude/hooks/` and its packaged copy under `claude-hooks/claude-hooks/hooks/`. All six hook files were confirmed byte-identical between the two locations at the end of the pass.

| File | Change |
| --- | --- |
| `hx-common.ps1` | Added `Get-HxInputProperty`, which reads a field from a hook payload without failing when the field is absent. Added `Get-HxRegistryTable`, a single shared parser for the registry fleet table. |
| `hx-validate-subagent.ps1` | Checks the subagent's own identity rather than trusting the settings filter alone. Blocks when the final message is unavailable instead of letting the subagent finish. |
| `hx-phase1-guard.ps1` | Repaired the RAID pattern. Separated read-only disk listing from disk mutation. |
| `hx-validate-discovery.ps1` | Registry schema check now reads the real table header instead of searching the whole document. |
| `hx-session-state.ps1` | Now uses the shared table parser rather than its own copy of the logic. |

### Documentation and tracking

| File | Change |
| --- | --- |
| `claude-hooks/README.md` | Phase Gate section describes the correct registry values (from the earlier F1 fix). |
| `.claude/skills/phase1-gate/SKILL.md` | Gate report vocabulary aligned with the registry (from the earlier F1 fix). |
| `governance/actions-and-issues.md` | `iss-002` and `iss-003` closed with resolutions. `act-002` marked done. `iss-004` and `act-003` added and closed. |

### Tests

| File | Change |
| --- | --- |
| `tests/remediation-tests.ps1` | Test harness rewritten. 49 assertions added. |

Nothing has been committed. All changes are in the working tree.

---

## Tests added or modified

### Harness rewrite (item 1)

The suite used to send a hook its input and only afterwards begin reading the hook's reply. That order caused the suite and the hook to wait on each other as soon as a hook produced any output. The suite now begins reading both output streams before it sends input.

A 30 second per-hook timeout was also added. If a hook ever stops responding again, the suite reports `HOOK TIMEOUT` against the specific hook and continues, instead of freezing with no result.

### New coverage

| Area | Assertions added |
| --- | --- |
| SubagentStop identity and missing-field handling | 6 |
| Phase 1 guard categories and read-only storage commands | 38 |
| Registry validator anchoring | 4 |
| Session-state hook (counted within the 38 above) | 6 |

Total added: 49.

---

## Full regression-suite result

```text
PASS: 146   FAIL: 0   exit code 0
```

The suite completes in seconds. It was run and confirmed green after each of the four items, and once more at the end of the pass. The Phase 2 lifecycle tests added in the previous pass now run inside the complete suite rather than only in a standalone script.

This is the first time the suite has completed successfully on this machine.

---

## Live SubagentStop verification result

The hook was temporarily instrumented to record the real payload. The instrumentation added observability only — every validation and blocking decision remained active and unchanged throughout. It was removed immediately afterwards, and its absence was verified by searching both hook copies.

### What was verified

**The subagent filter is honoured.** A non-discovery subagent was run under controlled instructions. No payload was recorded, meaning the hook never fired for it. Unrelated subagents are not affected by the discovery validator. This resolves the concern that the filter might be ignored.

**The final-message field does exist.** The real payload contains `last_assistant_message`. The suspected silent fail-open does not occur in this version of Claude Code.

**The payload also carries the agent's identity.** The field `agent_type` was present and set to `server-discovery`, which means the hook can check its own identity rather than depending on configuration.

**Blocking works as intended.** The `server-discovery` subagent was run with no reachable target. The hook blocked it and returned the expected instruction. No file was created and no fabricated data was produced.

### What was changed as a result

Even though the fail-open did not occur in practice, the hook was hardened as directed:

- payload fields are now read defensively, so a missing field cannot cause the hook to error out and be treated as approval;
- the hook checks `agent_type` itself and exits quietly for any other subagent;
- an absent final message now blocks, because without it there is nothing to verify;
- incomplete discovery records remain blocked exactly as before.

### One observation, deliberately not acted on

The payload contains a flag named `stop_hook_active`, which changed from false to true on the second stop. The hook does not read this flag. Claude Code capped the retry on its own, so no loop occurred.

Adding a bypass on that flag would have let an incomplete discovery record through on the second attempt. That would weaken the exact protection the hook exists to provide, so the flag was left unread and enforcement was kept at full strength. This is recorded here rather than changed.

---

## Guard categories covered

Fourteen categories now have a blocking case and a matching read-only case that must remain permitted.

| Category | Blocked example | Permitted example |
| --- | --- | --- |
| Package installation and upgrades | `apt-get install -y curl` | `apt-cache policy curl` |
| Service mutation | `systemctl restart ssh` | `systemctl list-unit-files --state=enabled` |
| Network configuration | `netplan apply` | `netplan get` |
| Firewall mutation | `ufw allow 22/tcp` | `ufw status verbose` |
| GPU driver installation | `ubuntu-drivers install` | `ubuntu-drivers devices` |
| Disk formatting | `mkfs.ext4 /dev/sdb1` | `parted -l` |
| Partition table mutation | `fdisk /dev/sdb` | `fdisk -l` |
| RAID mutation | `mdadm --create ...` | `mdadm --detail --scan` |
| Hostname mutation | `hostnamectl set-hostname hx-01` | `hostnamectl status` |
| Model downloads | `hf download ...` | `hf auth whoami` |
| Ollama mutation | `ollama pull llama3` | `ollama list` |
| vLLM serve | `vllm serve ...` | `vllm --version` |
| vLLM installation | `pip install vllm` | `pip show vllm` |
| `configuration.md` writes | write to `servers/hx-test/configuration.md` | write to `servers/hx-test/discovery.md` |

Five additional read-only storage commands were confirmed permitted: `lsblk -f`, `blkid`, `sfdisk -l`, `parted --list`, and `findmnt --verify`.

### New defect found by this coverage — iss-004

The RAID rule was written as `\bmdadm\b.*\b(--create|--assemble|--add|--remove|--fail)\b`.

That rule could never match anything. The `\b` marker means "word boundary", and there is no word boundary between a space and a leading dash, because neither is a word character. So `\b--create` cannot fire when the flag follows a space, which is how it is always written.

The practical consequence: creating a RAID array, or adding, removing, or failing a member, was never blocked during Phase 1, despite being listed as prohibited. Nothing detected this because the category had no test.

The rule is now anchored on whitespace instead. `mdadm --create` is denied, `mdadm --detail --scan` remains allowed, and both are under regression test.

**Residual gap, deliberately not closed:** the mdadm short forms `-a`, `-r`, and `-f` are still unguarded. They cannot be added safely to a case-insensitive rule, because `-C` would also match `-c`, which is `--config` and read-only. Closing this properly would require restructuring the pattern and is outside this pass.

### Read-only disk inspection — act-003

`parted`, `fdisk`, and `sfdisk` were previously blocked outright, which also blocked legitimate Phase 1 discovery. Their read-only listing form is now permitted while every mutating form stays denied.

`sgdisk` was deliberately left fully blocked. Its `-l` switch means `--load-backup`, which writes a partition table, not a listing. Treating it like the others would have opened a destructive path.

---

## Registry-validator result

The validator previously confirmed the registry's columns by searching the entire Markdown file for each column name. Words such as Server, CPU, IP, and Discovery appear throughout the surrounding explanation, so the fleet table could have been damaged or deleted entirely and the check would still have passed.

The validator now finds the actual table header row and compares the parsed column names against the required list. Four regression cases confirm the behaviour:

- an intact fleet table is accepted;
- renaming `Assigned Role` to `Role` in the header is detected, even though prose in the same document still contains the phrase `Assigned Role`;
- deleting the fleet table entirely is detected, even though prose names every required column;
- the live `SERVER-REGISTRY.md` still passes.

The session-state hook was switched to the same parser, so there is one implementation rather than two that could drift apart.

---

## Remaining open items

Not addressed in this pass, as directed. All remain documented.

| Item | Priority | Summary |
| --- | --- | --- |
| Item 5 | Low | Notification hook opens a Windows dialog for every permission prompt. Dialogs stack and must be dismissed by hand. Likely to be disruptive during a real discovery run. |
| Item 6 | Low | No Git remote is configured. The whole project exists only on this machine. |
| Item 7 | Low | Empty placeholder row in the registry table; stale hook paths in the remediation instructions; no permission deny rules in settings; undocumented difference between the audit skill's field-level checks and the hooks' section-level checks. |
| iss-004 residual | Low | mdadm short-form flags `-a`, `-r`, `-f` remain unguarded. |

Nothing has been committed. The working tree holds 14 modified files and 3 untracked reports.

---

## act-001 — open, and not a Phase 1 discovery blocker

`act-001` remains **open**. It was not closed, downgraded, or redefined. It continues to be tracked as a separate infrastructure action for persistent router-side `hx.local.arpa` DNS records covering approved, server-managed static addresses.

It is **not** a prerequisite for Phase 1 discovery. Discovery may proceed by approved IP address. Specifically, none of the following require persistent DNS:

- connecting to a server over SSH by its approved IP address;
- running read-only hardware and operating system discovery;
- creating `servers/<server>/discovery.md`;
- auditing a discovery record;
- synchronising factual discovery data into `SERVER-REGISTRY.md`.

The earlier outstanding-findings report ended with a suggested work order implying that `act-001` should be resolved before fleet discovery begins. That sequencing is withdrawn. Requiring persistent DNS before discovery would add an unnecessary infrastructure dependency to the discovery gate, and would be circular in practice, because discovery is one of the mechanisms used to establish the authoritative inventory that stable naming will later serve.

Stable `hx.local.arpa` naming should be solved as its own infrastructure action and adopted when it is available.

---

## Phase boundary confirmation

- Phase 1 remains discovery and documentation only.
- No Phase 2 configuration was performed and no `configuration.md` was created.
- `SERVER-REGISTRY.md` was not modified. It still reads `Phase 1 Status: IN PROGRESS` and `Phase 2 Status: BLOCKED`.
- The live guard was re-tested against the real project root after every change and continues to deny Phase 2 commands.
- Active and packaged hook copies are byte-identical.
- The temporary diagnostic used for the live subagent verification was removed, and its removal was verified in both hook locations.

---

## Suggested next steps

1. Review and commit this pass, so the repaired automation has a tracked baseline.
2. Continue finalising the authoritative 15-server expected-fleet list.
3. Begin Phase 1 discovery by approved IP address where DNS is not yet available.
4. Keep `act-001` open until persistent router-side DNS is actually solved.
5. Schedule items 5 through 7 whenever convenient. None of them block discovery.
