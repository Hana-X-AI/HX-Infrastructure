# HX-Infrastructure Outstanding Findings

**Reviewer:** Claude Opus 5 (Claude Code)
**Reported at:** 2026-08-11 20:15:30 -05:00
**Scope:** All 42 non-`.git` files in the project, reviewed after the GitHub Copilot remediation pass of 2026-08-10 was applied
**Method:** Direct file inspection, cross-document consistency checks, file-hash comparison of active and packaged hooks, direct hook invocation with representative payloads, execution tracing of the regression suite, and Git ignore/tracking checks
**Purpose:** Record in plain language what is still outstanding after the F1 fix, so the project owner can decide what to schedule next

---

## Summary

The remediation work done on 2026-08-10 is genuinely complete. All twelve items, rem-001 through rem-012, were verified as applied.

One defect that the remediation itself introduced has now been fixed: the Phase 2 unblock path. That fix is described below under "Already resolved" and is not outstanding.

Seven items remain outstanding. One is high priority and was discovered while verifying the fix. Two are medium. Four are low. None of them prevent Phase 1 server discovery from starting.

The most important thing in this report: **the project's automated test suite has never successfully run on this machine.** It hangs partway through and never finishes. Every previous claim that "hook tests pass" rests on a suite that does not complete here. That should be fixed before any further automation work is trusted.

---

## Already resolved (for context, not outstanding)

The hook that guards Phase 1 used to release only when the server registry contained the exact word `OPEN`. But the registry's own approved vocabulary, set during the 2026-08-10 remediation, is `BLOCKED`, `READY`, `IN PROGRESS`, and `COMPLETE`. `OPEN` was not one of them.

The practical effect: once the fleet passed the Phase 1 gate and the owner set the registry to `READY` as documented, the guard would have kept blocking every Phase 2 action anyway — package installs, service changes, network changes, GPU drivers, and all `configuration.md` files. Phase 2 could not have been started by following the written process.

The guard now releases on `READY`, `IN PROGRESS`, or `COMPLETE`, and stays active on `BLOCKED` or when the registry file is missing. The registry itself was not changed. Sixteen checks covering all four states passed.

---

## Outstanding item 1 — The regression test suite hangs and never finishes

**Priority:** High
**Where:** `tests/remediation-tests.ps1`, line 47
**Status:** Open, discovered 2026-08-11

### What is wrong

The test suite starts, runs its first check, and then freezes on the second one. It never recovers and never prints results. Three separate runs all stopped at exactly the same place. Execution tracing confirmed the stopping point precisely.

The suite launches each hook as a separate program and talks to it through pipes. It sends the hook its input, then waits to read the hook's reply. That order is the problem: the suite finishes sending before it starts listening. The first hook produces no output, so nothing goes wrong. The second hook produces a block message, and the two programs end up waiting on each other forever. Neither uses any processor time — they are simply stuck.

### Why it matters

The hooks themselves are fine. That was confirmed by calling each one directly, including with output far larger than the one that causes the suite to freeze. Every hook answered correctly and immediately.

The problem is entirely in the test harness. But the consequence is serious: the project's stated verification gate, `rem-006`, requires "hook tests pass" before the Git baseline is created, and the remediation checklist requires the suite to be green before remediation can be called complete. Neither of those was ever actually demonstrated on this machine. The suite cannot report a failure, because it cannot report anything.

### What to do

Change the test harness so it begins listening for the hook's reply before it sends input, rather than after. A working version of this pattern already exists and was used to verify the Phase 2 fix; it ran the same hooks in seconds.

Until this is fixed, the new Phase 2 checks that were added to the suite cannot run, even though they are correct and pass when run standalone.

---

## Outstanding item 2 — The subagent check may not work in a real session

**Priority:** Medium
**Where:** `.claude/hooks/hx-validate-subagent.ps1`, `.claude/settings.json`
**Status:** Open

### What is wrong

This hook is supposed to stop the server-discovery subagent from finishing until it has written a valid, complete discovery record. It does that by reading the subagent's final message and looking for the path of the discovery file.

Two assumptions behind it have never been tested in a live session.

First, the hook reads a field called `last_assistant_message`. If a real session does not supply that field, the hook will error out instead of running its check. Because of how these hooks report results, an error is treated as "carry on" — so the subagent would be allowed to finish without any validation at all. This is the same failure pattern that `rem-001` was created to fix, in a different place.

Second, the hook is configured to apply only to the server-discovery subagent. If that filter is not honoured, the hook applies to every subagent instead, and would block any subagent whose final message does not name a discovery file.

### Why it matters

The existing test for this hook supplies the `last_assistant_message` field itself, so the test passes whether or not the field exists in reality. The test is confirming its own assumption rather than the actual behaviour. The original Copilot review noted the same limitation: hooks were tested with made-up inputs, not through a real session.

Either outcome is bad. If the field is missing, discovery records can be accepted unvalidated. If the filter is ignored, ordinary subagent work gets blocked.

### What to do

Check the live behaviour before changing anything. Run `/hooks` and note whether the subagent filter is listed as active. Run the server-discovery subagent once against a throwaway target. Separately, run any other subagent and confirm it is not blocked.

Then make the hook read the message field defensively so a missing field cannot cause a silent pass, and have it check the agent's identity itself rather than relying on the filter.

---

## Outstanding item 3 — Most of the Phase 1 guard is untested

**Priority:** Medium
**Where:** `.claude/hooks/hx-phase1-guard.ps1`, `tests/remediation-tests.ps1`
**Status:** Open

### What is wrong

The guard blocks thirteen categories of command during Phase 1. Only one of them has any test coverage: the different ways of writing a path to a `configuration.md` file, which has nine variations tested.

The other twelve have no test at all. Those are package installs, service start and stop, network configuration changes, firewall changes, GPU driver installs, disk formatting and partitioning, RAID changes, hostname changes, model downloads, Ollama commands, vLLM commands, and vLLM installs via pip.

Two other pieces of automation also have no tests: the session-state hook that reports fleet counts at the start of each session, and, until this week, the Phase 2 release condition.

### Why it matters

These twelve patterns are the ones that actually protect the servers. A typo in any of them would silently stop protecting against that category, and nothing would notice. The one category that is tested is the least destructive of the group.

### What to do

Add one blocked example and one similar-but-allowed example for each of the thirteen categories, plus coverage for the session-state hook. This depends on outstanding item 1 being fixed first, since the suite currently cannot run.

### Related minor point

The guard also blocks the `parted` command outright. `parted -l` is a harmless, read-only way to list disks and is legitimate discovery work. The impact is small because `lsblk` and `blkid` cover the same ground and are allowed, but the pattern currently blocks looking as well as changing.

---

## Outstanding item 4 — The registry structure check does not really check the structure

**Priority:** Low
**Where:** `.claude/hooks/hx-validate-discovery.ps1`
**Status:** Open

### What is wrong

After the registry is edited, a hook is supposed to confirm the fleet table still has all its required columns. It does this by searching the whole file for each column name as a word.

Words like "Server", "Discovery", "IP", and "CPU" appear throughout the surrounding explanatory text, not only in the table. So the table's header row could be deleted entirely and the check would still pass.

### Why it matters

The check gives the appearance of protecting the registry schema without actually doing so. Low impact today because the registry is still empty, but it becomes more relevant once real server rows exist.

### What to do

Anchor the check to the actual table header row instead of the whole document. Code that already finds and parses that header row exists in `.claude/hooks/hx-session-state.ps1` and can be reused.

---

## Outstanding item 5 — Notification pop-ups will be disruptive during discovery

**Priority:** Low
**Where:** `.claude/hooks/hx-notify.ps1`, `.claude/settings.json`
**Status:** Open

### What is wrong

A Windows dialog box opens for four kinds of event, including every permission prompt. Each dialog must be dismissed by hand, and they stack up if several arrive together.

### Why it matters

A real discovery run involves many SSH commands. If each one raises a permission prompt, the operator will be dismissing dialog boxes continuously. This has not caused a problem yet only because no discovery run has happened.

### What to do

Narrow the trigger to the two events where the operator genuinely needs to be called back to the machine — idle prompts and agent-needs-input — or replace the dialog with a non-blocking notification or a console alert.

---

## Outstanding item 6 — The project exists only on this machine

**Priority:** Low
**Status:** Open

### What is wrong

The Git repository has no remote configured. Nothing has ever been pushed anywhere.

### Why it matters

The entire governance baseline — the contract, the registry, the hooks, the risk register, the review history — exists in one folder on one desktop. There is no off-machine copy and no shared history.

### What to do

Add the intended remote and push `main`.

---

## Outstanding item 7 — Documentation drift and small inconsistencies

**Priority:** Low
**Status:** Open

These are cosmetic and can be handled together whenever convenient.

- `SERVER-REGISTRY.md` line 38 contains an empty placeholder row in the fleet table. The automation skips it correctly. Remove it when the first real server row is added.
- `governance/reports/GITHUB-REMEDIATION-INSTRUCTIONS.md` refers to hook files at `claude-hooks/hooks/`. The real location is `claude-hooks/claude-hooks/hooks/`. This is a stale path in a historical document.
- `.claude/settings.json` contains no permission deny rules. The remediation identified permission rules as the stronger, more reliable enforcement layer compared with hooks. The distinction is now written down in `claude-hooks/README.md`, but no rules were ever created, so the stronger layer does not exist in practice.
- The `audit-discovery` skill checks discovery records field by field. The hooks check them section by section. The skill is stricter. A record can therefore satisfy the hooks and still fail the skill. This is not necessarily wrong, but it is not written down anywhere.

---

## Project status

This is a statement of where the work stands, not a defect.

Phase 1 has produced its governance framework and its automation, but no discovery output yet:

```text
Servers expected:    15
Servers registered:   0
Discovery records:    0
Roles assigned:       0
```

The `servers/` directory contains only the templates and a README.

Two related tracked items remain open in `governance/logs/actions-and-issues.md`:

- **act-001** — establish persistent router-side `hx.local.arpa` DNS records for approved, server-managed static addresses.
- **iss-001** — stock ASUSWRT regenerates `/etc/dnsmasq.conf` and `/etc/hosts`, so direct edits cannot currently be relied on to survive a reboot or configuration apply.

Until act-001 is resolved, servers have no stable, resolvable names on the network. Discovery can still proceed by IP address, but fleet records will refer to addresses rather than names.

---

## What is not blocking Phase 1

Discovery can begin now. Specifically:

- The Phase 1 guard allows writes to `discovery.md` and blocks writes to `configuration.md`, confirmed by direct testing.
- The discovery record validator works correctly when called, confirmed by direct testing against both a valid and an incomplete record.
- The active hooks and the packaged distributable copies are byte-identical.
- The discovery skills, the audit skill, the registry sync skill, the gate skill, and the discovery subagent are all present and correctly worded.
- The read-only fact collector script is intact and performs no changes to a target host.

The outstanding items above affect confidence in the automation and the quality of its test coverage. They do not stop a server from being discovered and documented.

---

## Accepted risks

`risk-001` and `risk-002` in `governance/policy/risk-acceptances.md` remain active, scoped to initial setup, and time-bounded. Their review trigger is the Phase 1 gate review, or before Phase 2 begins, whichever comes first. Neither has been reached, because Phase 1 is still in progress.

In line with the risk register and `CLAUDE.md`, this report does not re-report them. No credential value appears anywhere in this document.

---

## Suggested order of work

1. Fix the test harness so the suite can complete (outstanding item 1). Nothing else can be verified reliably until this is done.
2. Verify the subagent hook's live behaviour and harden it (outstanding item 2).
3. Add test coverage for the remaining twelve guard categories and the session-state hook (outstanding item 3).
4. Handle the four low-priority items together (items 4 through 7).
5. Resolve act-001 so servers have stable names, then begin fleet discovery.
