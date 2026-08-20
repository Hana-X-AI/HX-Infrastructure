# Step 1 — verification gate report

**Author:** Claude-Opus-5 (Claude Code, workstation session)
**Date:** 2026-08-16 21:37:27 CDT
**Branch:** `docs/phase3-remediation-evidence` @ `ba991166`
**Task:** Next-steps group A item 1 — "Verify before anything else"
**Source of the task:** `governance/Phase -3-Regroup/remediation/claude_2026-08-16_180846_claude-code-session-onboarding-prompt.md`
**Status:** COMPLETE — all named checks executed, outputs retained below.

---

## 1. Verdict

**The pre-flight briefing is accurate on every state it asserted, and the repository confirms it.** Nothing in Part 1 of the onboarding prompt was found to be wrong about the guard blob, the suite blob, the branch tip, the F1 matrix shape, or the removal of `temp_edit.ps1`. The one item the briefing flagged as unconfirmed — the regression suite result — was run and returned the expected figure.

Two things the briefing did **not** state were found, and both are reported as discrepancies rather than folded into the summary:

1. The working tree is **not clean**. Four tracked files carry uncommitted modifications.
2. **F-03 is confirmed, and it is larger than the finding describes.** The briefing names two unguarded property reads and states that line 16 "defends the same way correctly." That is incorrect. Line 16 guards `file_path` but not `tool_input`, so it is a third fail-open path, not a correct defence. A fourth instance of the same defect class exists in a hook outside F-03's stated scope.

Per the standing rule that the repository outranks the briefing, the line-16 characterisation is superseded by the executed evidence below.

---

## 2. Gates executed

Every row is a check this session ran. No row is quoted from the briefing.

| # | Gate | Command | Result |
| --- | --- | --- | --- |
| 1 | Regression suite | `powershell -NoProfile -ExecutionPolicy Bypass -File ./tests/remediation-tests-restored.ps1` | **PASS: 160  FAIL: 0** |
| 2 | Branch tip | `git rev-parse --short HEAD` | `ba991166` |
| 3 | Branch identity | `git rev-parse --abbrev-ref HEAD` | `docs/phase3-remediation-evidence` |
| 4 | Guard blob | `git hash-object .claude/hooks/hx-phase1-guard.ps1` | `3826530241d2a8d8f4b98ed8dd9722acb8aa3ef9` |
| 5 | Guard hard-lock | `grep -c "Test-HxPhase2Open" .claude/hooks/hx-phase1-guard.ps1` | `0` |
| 6 | Suite blob | `git hash-object tests/remediation-tests-restored.ps1` | `e294690d019f409bb3a8bb4ba47c3425020f6a6b` |
| 7 | F1 matrix shape | read `tests/remediation-tests-restored.ps1:758-763` | 6 states, all `GuardActive = $true` |
| 8 | Dropped artifact | `ls temp_edit.ps1` | absent |
| 9 | Whitespace gate | `git diff --check` | clean |
| 10 | Working tree | `git status --short` | **4 modified, ~14 untracked** — see §4.1 |

### Gate scope statement

Gate 1 covers the 160 assertions in `tests/remediation-tests-restored.ps1` only. It does **not** cover the P1-01 scanner, the hook installer, or anything under `governance/`. Gate 5 is a textual check on one file, not a behavioural proof that Phase 2 release is unreachable; the behavioural proof is the F1 loop inside gate 1.

### F1 matrix, as read from source

```powershell
$phase2States = @(
    @{ Value = "BLOCKED";     GuardActive = $true },
    @{ Value = "READY";       GuardActive = $true },
    @{ Value = "IN PROGRESS"; GuardActive = $true },
    @{ Value = "COMPLETE";    GuardActive = $true },
    @{ Value = "BANANA";      GuardActive = $true },   # unknown value
    @{ Value = "";            GuardActive = $true }     # malformed / empty
)
```

Six states, all expecting the guard to stay active. This matches the briefing exactly.

---

## 3. Finding — F-03 confirmed, and wider than reported

### 3.1 What was run

`hx-common.ps1:1` sets `Set-StrictMode -Version Latest`, which turns a read of a non-existent property into a terminating error. `Read-HxHookInput` returns a bare `[pscustomobject]@{}` when stdin is empty or whitespace (`hx-common.ps1:6-8`), so a malformed payload produces an object with no `tool_name` and no `tool_input`.

Every project hook was probed with empty stdin:

```
hx-authority-edit-guard   | exit=0 |
hx-permanent-policy-guard | exit=0 |
hx-phase1-guard           | exit=1 | The property 'tool_name' cannot be found on this object. Verify that the property exists.
hx-notify                 | exit=0 |
hx-session-state          | exit=0 | {"hookSpecificOutput":{"hookEventName":"SessionStart", ...
hx-validate-discovery     | exit=1 | The property 'tool_input' cannot be found on this object. Verify that the property exists.
hx-validate-subagent      | exit=0 | {"decision":"block","reason":"Discovery cannot finish yet: ...
```

Two further payloads were fed to `hx-phase1-guard.ps1` — a well-formed `tool_name` with **no** `tool_input`:

```
{"hook_event_name":"PreToolUse","tool_name":"Write"} | exit=1 | The property 'tool_input' cannot be found on this object.
{"hook_event_name":"PreToolUse","tool_name":"Bash"}  | exit=1 | The property 'tool_input' cannot be found on this object.
```

### 3.2 Why it is a fail-open

`hx-phase1-guard.ps1` denies by writing a JSON decision object and exiting **0** (lines 57-65); it never uses a non-zero exit to block. Both `exit` statements in the file are `exit 0`. On a strict-mode error the script terminates before any JSON is written and the process exits 1 — so no `permissionDecision` reaches the harness, and a non-zero exit with no decision is treated as a non-blocking error, not a denial. **The protected tool call proceeds.**

This is not an inference from outside the project. It is the project's own established characterisation of the identical defect class, recorded against `iss-002` in `governance/logs/actions-and-issues.md:46`:

> "A missing field makes the hook error out, which is treated as non-blocking."

And it violates a rule the project already wrote down, `.claude/AGENTS.md:38`:

> "missing or malformed hook input must not silently create a fail-open path for a protected operation."

### 3.3 Correction to the briefing

The briefing states lines 11 and 25 are unguarded "while line 16 defends the same way correctly." Line 16 reads:

```powershell
if ($null -ne $inputObject.tool_input.PSObject.Properties["file_path"]) {
```

It guards the **`file_path`** read but performs an unguarded **`.tool_input`** read to do so. The `payload-write-no-toolinput` probe above throws at that exact line. Line 16 is therefore a third fail-open path, not a correct defence.

### 3.4 Confirmed fail-open inventory

| Location | Unguarded read | Reached when | Severity |
| --- | --- | --- | --- |
| `hx-phase1-guard.ps1:11` | `tool_name` | any malformed payload | **High** — safety-critical Phase 3 mutation guard |
| `hx-phase1-guard.ps1:16` | `tool_input` | `tool_name` is `Write` or `Edit` | **High** — same guard, `configuration.md` write path |
| `hx-phase1-guard.ps1:25` | `tool_input` | `tool_name` is `Bash` or `PowerShell` | **High** — same guard, all nine blocked command patterns |
| `hx-validate-discovery.ps1:7` | `tool_input` | any malformed payload | **Medium** — validation hook; a bad discovery record is accepted unvalidated |

`hx-validate-subagent.ps1` is the counter-example and the correct pattern: it fails **closed**, returning `{"decision":"block"}` on malformed input. That behaviour was the `iss-002` remediation, and it is the model the guard should follow.

### 3.5 Why the suite did not catch it

The F1 matrix varies the **registry state** across six values. It never varies the **input shape**. Every F1 case supplies a well-formed payload, so all six pass while three fail-open paths sit untested. The `""` and `"BANANA"` rows are frequently mistaken for malformed-input coverage; they are malformed *registry values*, which is a different axis. This is the same shape of gap as CR-5, and it is why items 3 and 2 belong in one change.

---

## 4. Discrepancies against the briefing

### 4.1 Working tree is not clean

The briefing describes the pre-flight as finished and does not mention pending changes. `git status --short` shows otherwise:

```
 M governance/operations/langgraph/phase-2/Claude-Opus-5_2026-08-14_langgraph-pilot-preflight-blocker.html
 M governance/operations/langgraph/phase-2/Claude-Opus-5_2026-08-14_langgraph-review-verdicts.md
 M governance/operations/langgraph/phase-2/claude_20260814_0730_langgraphdistillationpilotbrief.html
 M governance/operations/langgraph/phase-2/claude_20260814_0848_langgraphfourdecisions.html
```

`git diff --stat` — 4 files, +13 / -7. The content is substantive, not incidental: it is a source-verification correction retracting an earlier claim that LangGraph's `LANGGRAPH_STRICT_MSGPACK` control "fails silently." The revised text records that in LangGraph 1.2.11 an unregistered constructor emits a `msgpack_blocked` event and a warning, and that `langgraph.types.Interrupt` and `langgraph.types.StateSnapshot` are both on the safe list.

This is real work that would be lost by a careless `git checkout -- .`. It is unrelated to the guard and suite items and should not be swept into their commit.

Around fourteen untracked paths also sit under `governance/operations/`. Some or all may fall under owner ruling 10 (disposition of 18 never-added artifacts), which is an open owner decision and is not decided here.

### 4.2 F-03 scope understated

Covered in §3.3 and §3.4. Two unguarded reads were reported; three exist in the guard, plus one in `hx-validate-discovery.ps1`.

---

## 5. Recommendations

### R-1 — Fix all three guard fail-opens with the existing helper, not a new pattern (do now)

`hx-common.ps1:12-25` already provides `Get-HxInputProperty`, written for the `iss-002` remediation precisely to perform a defensive property read under strict mode. Use it at lines 11, 16 and 25 rather than adding a fourth ad-hoc `$null -ne ...PSObject.Properties[...]` idiom.

- **Resolves:** the three confirmed fail-open paths in the Phase 3 mutation guard.
- **Does not resolve:** `hx-validate-discovery.ps1:7`; see R-3.
- **Prerequisite:** none. The helper is already dot-sourced.
- **Reversal criteria:** none expected. This only tightens; a guard that survives malformed input can still only deny or allow on the same rules.

### R-2 — Cross the two test dimensions, and add the input-shape axis (do now, same change)

Drive F1 across `$phase2States` x `$guardCategories` and add malformed-input cases to the matrix. Demote the textual `Test-HxPhase2Open` grep at lines 810-811 to a secondary check behind the behavioural assertions.

- **Resolves:** CR-5's coverage hole, and gives R-1 a regression test that would have caught F-03.
- **Does not resolve:** coverage of hooks other than `hx-phase1-guard.ps1`.
- **Prerequisite:** R-1, so that the new malformed-input cases assert the fixed behaviour rather than encoding the defect.
- **Note:** the assertion count will rise well above 160. State the new figure explicitly in the next report rather than reporting "the suite still passes."

### R-3 — Fix `hx-validate-discovery.ps1:7` in the same pass (do now)

One line, same helper, same defect class, already proven present. Fixing it here costs nothing and avoids leaving a known fail-open in the tree because it fell outside a finding's original wording.

- **Resolves:** unvalidated acceptance of a malformed discovery record.
- **Does not resolve:** anything about the guard.
- **Reversal criteria:** none.

### R-4 — Leave the four modified LangGraph files uncommitted and untouched (decision, not an action)

They are a separate concern from the guard work and belong in their own commit with their own justification. Do not stage them alongside R-1 through R-3.

- **Owner decision needed:** whether the LangGraph correction lands on this branch or on `remediation/phase3`.

### R-5 — Do not re-run gate 5 as proof of the hard-lock

`grep -c "Test-HxPhase2Open"` returning `0` proves one string is absent from one file. It does not prove Phase 2 release is unreachable. The behavioural F1 assertions are the real proof. This is the "gates state their scope" rule applied to a gate this session ran.

---

## 6. Next tasks

Presented as the two options given to the owner, with the recommendation stated.

**Option 1 — items 3 + 2 combined, extended by R-3. RECOMMENDED. Owner selected this option.**

Guard lines 11, 16 and 25 plus `hx-validate-discovery.ps1:7`, then rebuild F1 as `$phase2States` x `$guardCategories` with malformed-input cases and the direct `Write`/`Edit` `configuration.md` paths folded in.

- **For:** fixes a confirmed fail-open on the most safety-critical control in Phase 3, and closes the coverage hole that hid it. Both items touch the same two files; splitting them means editing both files twice. One suite run proves both.
- **Against:** larger diff to review in a single pass.

**Option 2 — item 3 alone first.**

Guarded property reads and one new test, then re-run the suite.

- **For:** smaller and faster to review.
- **Against:** leaves the matrix hole open, and the malformed-input test would land in a matrix that is about to be restructured — so the same two files get edited twice within the hour.

**Selected:** Option 1, per owner instruction of 2026-08-16.

---

## 7. Standing directives adopted this session

Recorded here because they change how every later report is produced.

1. **Report on completion.** Each finished task, step or item gets a `.md` report in `governance/Phase -3-Regroup/reports/`, named per `governance/documentation-standards.html`: `<author>_<YYYY-MM-DD>[_<HHMMSS>]_<lower-kebab-slug>.md`.
2. **Be Great depth.** Reports are investigation artifacts, not status notes. Evidence must be reproducible, contradictions surfaced rather than buried, and authority distinguished from detail.
3. **Every report carries recommendations** for correcting or fixing what was encountered, plus the recommended next tasks as options.
4. **Fix, do not merely report.** When a defect is encountered while executing a task, it is fixed in that task. This applies to any subagent dispatched as well. Stopping at "there is a problem" is not an acceptable outcome.

Directive 4 is the reason R-3 exists: `hx-validate-discovery.ps1:7` was found while proving F-03 and is fixed in the same pass rather than logged and left.

---

## 8. Provenance and limits

- **Executed on:** the workstation session, Windows PowerShell 5.1, project root `C:\Users\JarvisRichardson\Desktop\HX-Infrastructure` (root-relative paths used throughout the repository; the literal path appears here only as the execution record).
- **Every figure above is from a command run in this session.** No count, hash or state is carried over from the briefing.
- **Attestation, not evidence:** no live server was contacted and no remote endpoint was invoked during Step 1. All work was local file reads, `git` plain-text queries, and local PowerShell hook invocations. That statement is an attestation.
- **Verified fact vs inference.** The exit codes, error text, blob hashes, branch tip and suite totals are verified facts, reproducible from the commands given. The consequence "the protected tool call proceeds" is derived from the guard's own deny mechanism (JSON + `exit 0`) combined with the project's recorded characterisation at `governance/logs/actions-and-issues.md:46`. It was not observed end-to-end in a live tool call, because the harness constructs hook payloads itself and a malformed one cannot be induced on demand.
- **Not covered:** the P1-01 scanner, the hook installer two-run behaviour, and findings F-02, F-04, F-05, F-06 and CR-1 through CR-4. None were run or inspected for this report.
