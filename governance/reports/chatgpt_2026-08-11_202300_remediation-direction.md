# hx-infrastructure remediation direction

**reviewer:** chatgpt  
**reported at:** 2026-08-11 20:23 -05:00  
**source reviewed:** `Claude-Opus-5_2026-08-11_201530_outstanding-findings.md`  
**purpose:** direct the next remediation pass and clarify the router-dns sequencing decision

---

## direction

Proceed with outstanding items **1 through 4**, in this exact order:

1. fix the regression test harness so the suite completes;
2. verify and harden the `server-discovery` `SubagentStop` hook using live Claude Code behavior;
3. add regression coverage for the remaining Phase 1 guard categories and the session-state hook;
4. anchor the registry structure validator to the actual registry table header.

Do not fold items 5 through 7 into this pass unless a change in items 1 through 4 requires a minimal supporting adjustment.

After item 4, stop and report.

---

## item 1 — fix the regression test harness first

This remains the highest-priority defect because the project's automated regression suite currently hangs and cannot provide a trustworthy pass/fail result.

The hooks themselves were directly tested and responded correctly, so the immediate defect is the harness, not the hook logic.

Correct the harness so it begins reading hook output before or concurrently with sending input, using the already proven non-deadlocking pattern described in the outstanding-findings report.

### required result

```text
[ ] remediation-tests.ps1 completes
[ ] no deadlock occurs
[ ] the suite reports explicit pass/fail results
[ ] existing F1 Phase 2 lifecycle tests run inside the complete suite
[ ] test failures return useful diagnostics
```

Do not claim the regression suite is green until the full suite completes successfully on this machine.

---

## item 2 — verify and harden the subagent hook

Do not change the hook based only on simulated payload assumptions.

First verify actual Claude Code behavior:

1. run `/hooks` and confirm the `server-discovery` `SubagentStop` matcher is active as expected;
2. invoke the `server-discovery` subagent in a controlled test;
3. inspect the real `SubagentStop` payload/behavior;
4. separately invoke a non-discovery subagent and verify it is not blocked by the discovery validator.

Then harden the hook so:

- a missing message field cannot produce a silent fail-open path;
- the hook defensively checks the subagent identity itself;
- incomplete discovery remains blocked;
- unrelated subagents are unaffected.

### required result

```text
[ ] live server-discovery SubagentStop behavior verified
[ ] real message-field behavior verified
[ ] missing field cannot silently bypass validation
[ ] hook verifies agent identity defensively
[ ] unrelated subagent is not blocked
[ ] regression tests added
[ ] active and packaged hook copies remain synchronized
```

---

## item 3 — complete Phase 1 guard test coverage

After the harness is reliable, add one blocked case and one similar-but-allowed case for every Phase 1 guard category.

Coverage should include all thirteen guard categories, including:

```text
package installation/upgrades
service mutation
network configuration mutation
firewall mutation
GPU-driver installation
disk formatting/partitioning
RAID mutation
hostname mutation
model downloads
Ollama mutation
vLLM serve commands
vLLM installation
configuration.md writes
```

Also add coverage for the session-state hook.

Review the `parted` pattern while doing this. Read-only discovery such as:

```text
parted -l
```

should not be blocked merely because mutating `parted` operations are prohibited.

The guard must continue blocking persistent configuration changes during Phase 1.

### required result

```text
[ ] every guard category has a blocked regression case
[ ] every guard category has a similar allowed case where meaningful
[ ] read-only discovery commands remain permitted
[ ] session-state hook has regression coverage
[ ] complete regression suite remains green
```

---

## item 4 — anchor the registry validator to the actual table

Correct the current registry schema check so it validates the actual fleet-table header rather than searching the entire Markdown document for column names.

Reuse the existing header parsing logic in `hx-session-state.ps1` where practical rather than creating a second incompatible parser.

The validator should fail if the fleet table itself loses required columns even when words such as `Server`, `CPU`, `IP`, or `Discovery` still appear elsewhere in explanatory prose.

### required result

```text
[ ] validator locates the real fleet table header
[ ] all required columns are checked against that header
[ ] removal/renaming of a required header is detected
[ ] explanatory prose cannot satisfy the table-schema check
[ ] regression coverage added
[ ] complete regression suite remains green
```

---

## correction — `act-001` does not block Phase 1 discovery

The prior report's final suggested work order says:

> Resolve `act-001` so servers have stable names, then begin fleet discovery.

Do **not** use that as a Phase 1 prerequisite.

The same report correctly states earlier that discovery can proceed by IP address while `act-001` remains unresolved. That is the correct project interpretation.

### why

`act-001` concerns persistent router-side `hx.local.arpa` DNS records for server-managed static addresses.

It affects:

- stable human-readable names;
- name resolution;
- convenience and consistency of later fleet operations.

It does **not** prevent:

- connecting to a server by its approved IP address;
- running read-only hardware/OS discovery;
- creating `servers/<server>/discovery.md`;
- auditing a discovery record;
- synchronizing factual discovery data into the registry.

Phase 1 is explicitly discovery and documentation only. Requiring persistent DNS before discovery would introduce an unnecessary infrastructure dependency into the discovery gate.

That would also be circular in practice: discovery is one of the mechanisms used to establish and verify the authoritative server inventory that will later benefit from stable naming.

Therefore:

```text
act-001
status: open

phase 1 discovery
status: may proceed by approved IP address
```

Do not close or downgrade `act-001`. It remains a legitimate open infrastructure action.

Do not treat it as a blocker for beginning server discovery.

Stable `hx.local.arpa` naming should be resolved as a separate infrastructure action and adopted when available.

---

## sequencing after this pass

After items 1 through 4 are complete and validated:

```text
1. report results;
2. keep items 5 through 7 documented as open;
3. continue finalizing the authoritative 15-server expected-fleet list;
4. begin Phase 1 discovery by IP where DNS is not yet available;
5. keep act-001 open until persistent router-side DNS is actually solved.
```

Do not begin Phase 2 configuration.

---

## completion report

When finished, return:

```text
files changed
tests added or modified
full regression-suite result
live SubagentStop verification result
guard categories covered
registry-validator result
remaining open items
confirmation that act-001 remains open but is not a Phase 1 discovery blocker
```

If any of items 1 through 4 cannot be completed safely, stop on that item and explain the blocker rather than broadening scope.
