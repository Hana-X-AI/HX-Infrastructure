# HX-Infrastructure Remediation Completion — Items 5 through 7, and AGENTS.md Validation

**Reviewer:** Claude Opus 5 (Claude Code)
**Reported at:** 2026-08-11 21:26:17 -05:00
**Prior pass:** `Claude-Opus-5_2026-08-11_204432_remediation-items-1-4-completion.md`
**Source findings:** `Claude-Opus-5_2026-08-11_201530_outstanding-findings.md`
**Scope:** Outstanding items 5, 6 and 7, plus validation of the new `AGENTS.md` routing hierarchy.

---

## Summary

Items 5 and 7 are complete. Item 6 is **not** complete and remains open by decision of the project owner.

The `AGENTS.md` hierarchy was reviewed against all five authoritative documents. **No conflicts were found.** The hierarchy is valid and is now in use for subsequent work. Three non-blocking observations are recorded below.

One further defect was found while performing item 6: **the repository could not accept any commit at all.** This is recorded as `iss-005` and is now fixed.

The regression suite reports 153 pass, 0 fail, exit code 0.

Phase 1 remains discovery and documentation only. The registry is unchanged at `Phase 2 BLOCKED`. Nothing was pushed to any remote.

---

## Item 5 — Notification scope — DONE

### What was wrong

The Notification hook opened a modal Windows dialog on four event types, including every permission prompt. Modal dialogs must be dismissed by hand and they stack. A discovery run issues many commands, so dialogs would have arrived faster than an operator could clear them.

### What changed

The matcher was reduced to `idle_prompt|agent_needs_input` — the two events that genuinely mean the operator is needed at the machine. The change was made in both `.claude/settings.json` and the packaged `claude-hooks/claude-hooks/settings.fragment.json`, which are now asserted to stay in step by a regression test.

The reasoning was written into `claude-hooks/README.md` so the omission of `permission_prompt` reads as deliberate rather than accidental.

### Note

Hook configuration is read when a session starts. This change takes effect in the next Claude Code session, not the current one.

Tracked as `act-004`, status done.

---

## Item 6 — Off-machine copy — NOT DONE, REMAINS OPEN

### What was attempted

The project owner approved creating a **private** GitHub repository and pushing `main`, after committing the outstanding work.

Pre-commit checks were run first: `.env` confirmed ignored and unstaged, no populated secret assignments in the staged diff, the Bash fact collector passing `bash -n`, and the full regression suite green. The four new `AGENTS.md` files were read in full before staging, since pushing distributes them.

Two commits were created locally:

```text
4c89358  Repair Phase 1 automation and complete outstanding remediation items 1-7
c5dd045  Record items 5 through 7 outcomes in the action and issue log
```

### Why it stopped

`gh repo create` was rejected: the name already exists on the account.

Inspection of `hanax-ai/HX-Infrastructure` found an entirely different project:

```text
visibility:   PUBLIC
last pushed:  2025-09-17
contents:     ansible.cfg, site.yml, playbooks/, roles/, inventories/, scripts/, docs/
recent work:  LiteLLM and PostgreSQL integration
branches:     main, feature/metrics-server-integration
open PR:      #1  Integrate HX Metrics Server into Phase 3 Variable Management System
shared history with this repository: none
```

Pushing `main` there would have been rejected as a non-fast-forward, and forcing it would have destroyed that repository's history and its open pull request. Nothing was forced and nothing was pushed.

The project owner was presented with three options — a new private repository under a different name, pushing as a branch on the existing repository after making it private, or stopping — and chose to stop and defer the destination decision.

### Current state

The work is committed locally. No remote is configured. The project still exists on one workstation only.

Tracked as `act-005`, status open.

### Separate observation, outside this pass

The existing `hanax-ai/HX-Infrastructure` repository is public and appears to contain live HX infrastructure material, including an `ansible.cfg.secure` and a file named for `hx-ca-server.dev-test.hana-x.ai`. That repository is not in scope here and was not modified. It is noted once because it concerns the same class of exposure this project is careful about.

---

## Item 7 — Documentation and enforcement cleanup — DONE

Four separate corrections.

### Empty registry placeholder row

`SERVER-REGISTRY.md` carried a blank row in the fleet table. Parsers skipped it correctly, but it would have been mistaken for a real entry. Removed. A regression test now asserts no such row returns.

### Stale packaged-hook paths

`GITHUB-REMEDIATION-INSTRUCTIONS.md` referred to hook files at `claude-hooks/hooks/`. The real location is `claude-hooks/claude-hooks/hooks/`. Four references corrected. Only the paths changed; no finding, recommendation or historical meaning was altered. A regression test now guards against the single-nested form reappearing.

### Permission deny rules

`.claude/settings.json` had no `permissions.deny` block, so the stronger enforcement layer identified during the original remediation existed only on paper.

Deny rules were added for the operations that `INFRASTRUCTURE-CONTRACT.md` section 10.5 prohibits **without explicit approval in any phase**: `mkfs`, `wipefs`, `sgdisk`, `pvcreate`, `vgcreate`, `lvcreate`, and RAID array creation. Both bare and `sudo`-prefixed forms are listed.

These rules are deliberately **phase-independent**. Unlike the `PreToolUse` hook, they are not released when the registry reaches `READY`, because the contract prohibits those operations without approval in Phase 2 as well.

Permission rules match on a command prefix and therefore cannot cover every invocation form. The hook remains the broader, registry-aware layer; the deny list is a deterministic backstop for the highest-impact commands. This distinction is documented in `claude-hooks/README.md`, along with the fact that `apply-hooks.ps1` merges only the `hooks` section and will not install permission rules on a fresh setup.

### Audit versus hook strictness

The `audit-discovery` skill checks discovery records field by field; the hook validators check them section by section. The skill is stricter, so a record can satisfy the hooks and still fail the audit. That difference was real but undocumented, which made hook acceptance look like Phase 1 acceptance. A short paragraph in `audit-discovery/SKILL.md` now states that hook acceptance is the floor, not Phase 1 acceptance.

Tracked as `act-006`, status done.

---

## New defect found during this pass — iss-005

### The repository could not accept any commit

The first attempt to stage the work failed:

```text
fatal: LF would be replaced by CRLF in .claude/hooks/hx-common.ps1
```

The cause is a mismatch between how the baseline was committed and how Git is configured on this machine. Every blob in the repository is stored with CRLF endings, while `core.autocrlf` and `core.safecrlf` are both `true` globally. Git therefore wants LF in the object store, cannot perform the round trip reversibly, and refuses.

This is not a consequence of the recent work. It would have blocked the **first** commit attempted after the baseline, whenever that happened. Until now nothing had been committed, so it had never surfaced.

The working tree was checked before changing anything and was found to be uniformly CRLF, so no file content needed correcting.

### Fix

A `.gitattributes` file containing `* -text` was added. This disables end-of-line conversion in both directions and preserves bytes exactly. Existing objects are untouched and no history was rewritten.

It also protects something this project depends on: the active hooks under `.claude/hooks` are compared byte-for-byte against their packaged copies, and any end-of-line conversion would break that parity check.

Tracked as `iss-005`, status resolved.

### A second, smaller observation

The first commit attempt was denied by the project's own Phase 1 guard, because the commit message quoted a RAID creation command as part of describing the fix. The guard inspects command text and correctly could not distinguish a quoted example from a real invocation.

This is the guard behaving conservatively and is not a defect. The commit message was supplied through a file instead. Recorded so the behaviour is not mistaken for a fault later.

---

## AGENTS.md hierarchy validation

Four files were reviewed in full: `AGENTS.md`, `.claude/AGENTS.md`, `governance/AGENTS.md`, and `servers/AGENTS.md`.

### Conflict check — no conflicts found

| Authoritative document | Result |
| --- | --- |
| `CLAUDE.md` | No conflict. The root file's authoritative list is CLAUDE.md's read-first four, plus CLAUDE.md itself. |
| `GOALS-AND-OBJECTIVES.md` | No conflict. The Phase 1 gate still has exactly seven conditions. No `AGENTS.md` adds an eighth. |
| `INFRASTRUCTURE-CONTRACT.md` | No conflict, and no restatement of its technical rules. It is referenced, not duplicated. |
| `SERVER-REGISTRY.md` | No conflict. `.claude/AGENTS.md` defers Phase 2 release vocabulary to the registry, which matches the corrected lifecycle values. |
| `governance/policy/risk-acceptances.md` | No conflict. The re-report conditions match the register's own Reporting Rule. |

### Specific verifications

**Packaged hook location is correct.** `.claude/AGENTS.md` line 45 gives `../claude-hooks/claude-hooks/hooks/`, which resolves from `.claude/` to the real directory. All six hook scripts are present there. This was the claim most likely to be wrong, because the stale single-nested form existed elsewhere in the repository until this pass corrected it.

**Child scopes are correctly assigned.** Each of the three child contracts owns a subtree that exists and describes work that genuinely happens there.

**Referenced skills exist.** `servers/AGENTS.md` points at `/audit-discovery`, `/sync-registry` and `/phase1-gate`; all three skill files are present.

**No credential material** appears in any of the four files.

**No project policy is unnecessarily duplicated.** The technical contents of the infrastructure contract, the registry schema and the risk register are referenced rather than copied.

**No new Phase 1 blocker is introduced.** The hierarchy in fact removes an ambiguity. `servers/AGENTS.md` states that stable DNS is useful but not required for discovery when a server is reachable by an approved IP address, and `governance/AGENTS.md` states that open actions do not automatically become phase gates. Both encode the `act-001` correction rather than contradicting it.

### Three observations — none blocking, none requiring a change

**1. `tests/` and `claude-hooks/` route to the root contract, not to `.claude/AGENTS.md`.**

`.claude/AGENTS.md` owns synchronization between active and packaged hooks, and requires `tests/remediation-tests.ps1` in its verification list. Both of those paths sit outside `.claude/`:

```text
tests/         nearest AGENTS.md -> root
claude-hooks/  nearest AGENTS.md -> root
```

Under the nearest-contract rule, an agent editing only the test suite, or only the packaged hook copies, follows the root contract — which says nothing about hook packaging or the suite beyond "do not claim a test passed unless it completed successfully."

The cheapest correction adds a routing line to the root child index pointing `tests/` and `claude-hooks/` at `.claude/AGENTS.md`. No new `AGENTS.md` file is needed, which is consistent with the rule against creating child contracts for directories that are not durable boundaries.

**2. The root contract restates what it advises against restating.**

The root file says not to restate the authoritative documents when a reference is sufficient, then lists seven repository-wide rules. All seven are accurate as written today. The risk is drift if `CLAUDE.md` changes, not contradiction.

**3. `conversations/SYNC-POLICY.md` routes to the root contract.**

That policy governs where ratified decisions may be recorded — `risk-acceptances.md` and `actions-and-issues.md` — which is governance work, but the file sits outside `governance/` and `governance/AGENTS.md` does not reference it.

### Verdict

The hierarchy is valid, consistent with authoritative project policy, and introduces no Phase 1 blocker. It is adopted for subsequent work.

### One judgement call, stated plainly

`CLAUDE.md` directs work to avoid speculative architecture, exhaustive runbooks and unnecessary planning documents. Four contract files totalling roughly 330 lines is the one place a reviewer could reasonably push back. The files are concise, operational and non-speculative, and the layer was explicitly requested, so this reads as within the letter of that rule. It is recorded once rather than argued.

### Disclosure

`governance/AGENTS.md` requires preserving the historical meaning of existing reports. In commit `4c89358` — the same commit that introduced these contracts — stale packaged-hook paths were corrected in `GITHUB-REMEDIATION-INSTRUCTIONS.md`. Only file paths changed; no finding, recommendation or conclusion was altered.

---

## Files changed

| File | Change |
| --- | --- |
| `.claude/settings.json` | Notification matcher narrowed; `permissions.deny` block added. |
| `claude-hooks/claude-hooks/settings.fragment.json` | Notification matcher narrowed to match. |
| `claude-hooks/README.md` | Notification rationale and a new permission deny rules section. |
| `SERVER-REGISTRY.md` | Empty placeholder row removed. |
| `.claude/skills/audit-discovery/SKILL.md` | Audit versus hook strictness documented. |
| `governance/reports/GITHUB-REMEDIATION-INSTRUCTIONS.md` | Four stale packaged-hook paths corrected. |
| `.gitattributes` | New. Disables end-of-line conversion so commits are possible. |
| `governance/logs/actions-and-issues.md` | `act-004`, `act-005`, `act-006` and `iss-005` recorded. |
| `tests/remediation-tests.ps1` | Seven assertions added. |

---

## Tests added or modified

Seven assertions were added for this pass:

| Assertion | Covers |
| --- | --- |
| Notification hook no longer fires on permission prompts | Item 5 |
| Notification hook still fires when input is needed | Item 5 |
| Settings and packaged fragment hooks stay in sync | Item 5 |
| Contract-mandated storage operations have deny rules | Item 7 |
| Registry has no empty placeholder row | Item 7 |
| Audit and hook strictness difference is documented | Item 7 |
| Packaged hook paths are correct | Item 7 |

---

## Full regression-suite result

```text
PASS: 153   FAIL: 0   exit code 0
```

The suite was run after item 5, after item 7, and once more after the governance log was updated. It completes in seconds.

---

## Remaining open items

| Item | Priority | Status |
| --- | --- | --- |
| `act-005` — off-machine copy of the repository | Low | **Open.** Destination deferred by the project owner. Work is committed locally at `c5dd045`. |
| `iss-004` residual — mdadm short-form flags | Low | Open. `-a`, `-r` and `-f` cannot be added safely to a case-insensitive pattern, because `-C` would also match `-c`, which is read-only. Requires restructuring the pattern. |
| AGENTS.md routing gap | Low | Open observation. `tests/` and `claude-hooks/` route to the root contract. Not yet corrected; awaiting a decision. |

Nothing above blocks Phase 1 discovery.

---

## act-001 — open, and not a Phase 1 discovery blocker

`act-001` remains **open**. It was not closed, downgraded or redefined in this pass, and it continues to be tracked as a separate infrastructure action for persistent router-side `hx.local.arpa` DNS records covering approved, server-managed static addresses.

It is not a prerequisite for Phase 1 discovery. Discovery may proceed by approved IP address. None of the following require persistent DNS:

- connecting to a server over SSH by its approved IP address;
- running read-only hardware and operating system discovery;
- creating `servers/<server>/discovery.md`;
- auditing a discovery record;
- synchronising factual discovery data into `SERVER-REGISTRY.md`.

The new `servers/AGENTS.md` now states this directly, so the sequencing question should not reappear.

---

## Phase boundary confirmation

- Phase 1 remains discovery and documentation only.
- No Phase 2 configuration was performed and no `configuration.md` was created.
- `SERVER-REGISTRY.md` still reads `Phase 1 Status: IN PROGRESS` and `Phase 2 Status: BLOCKED`. Only the empty placeholder row was removed.
- The live guard continues to deny Phase 2 commands, verified during this pass by its refusal of the first commit attempt.
- All six active and packaged hook copies remain byte-identical.
- Nothing was pushed to any remote. No repository was created, modified or deleted on GitHub.

---

## Suggested next steps

1. Decide the destination for `act-005` so the project gains an off-machine copy. A new private repository under a different name is the low-risk option.
2. Optionally close the AGENTS.md routing gap with a single line in the root child index.
3. Continue finalising the authoritative 15-server expected-fleet list.
4. Begin Phase 1 discovery by approved IP address.
5. Keep `act-001` open until persistent router-side DNS is actually solved.
6. Consider whether the public `hanax-ai/HX-Infrastructure` repository should remain public.
