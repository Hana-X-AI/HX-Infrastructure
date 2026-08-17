# Item 8 — the hook installer package (CR-3 / F-06)

**Author:** Claude-Opus-5 (Claude Code, workstation session)
**Date:** 2026-08-16 23:06:20 CDT
**Branch:** `docs/phase3-remediation-evidence`
**Task:** Next-steps group D item 8 — `claude-hooks/README.md` command count, and the `apply-hooks.ps1` duplicate-registration defect
**Predecessor report:** `Claude-Opus-5_2026-08-16_223501_group-c-corrections.md`
**Status:** COMPLETE — both defects reproduced before fixing, both fixed, both now regression-tested.

---

## 1. Verdict

Both defects were real. The installer one was worse than a documentation slip: **re-running the installer added two registrations every time, permanently, to the user's live `settings.json`.**

Reproduced against a scratch project before touching anything, then again after:

```
--- old installer ---        --- new installer ---
  run 1:  7 registrations      run 1:  7 registrations
  run 2:  9 registrations      run 2:  7 registrations
  run 3: 11 registrations      run 3:  7 registrations
```

That is the exact 7 → 9 → 11 progression the finding predicted, measured rather than inferred.

**Suite: 302 PASS / 0 FAIL**, up from 295. Seven new assertions, all F-06.

---

## 2. What changed

```
claude-hooks/apply-hooks.ps1           the removal pattern, and the closing summary
claude-hooks/README.md                 the hook list, and the /hooks verification block
tests/remediation-tests-restored.ps1   seven F-06 assertions
```

---

## 3. The installer defect

### 3.1 Mechanism

`apply-hooks.ps1` merges the packaged fragment into an existing `settings.json` without disturbing anything else. For each event it keeps the groups that are **not** its own, then appends the fragment's groups. "Its own" was decided by a hand-written regex:

```powershell
$ourPattern = 'hx-(session-state|phase1-guard|validate-discovery|validate-subagent|notify)\.ps1'
```

Five names. The project registers **seven** commands, and `PreToolUse` alone carries three. `hx-permanent-policy-guard.ps1` and `hx-authority-edit-guard.ps1` are absent from that list, so on a re-run their existing groups did not match, were classified as somebody else's, and were **kept** — and then the fragment's copies of the same two guards were appended alongside. Two duplicates per run, compounding.

The result is not cosmetic. Every duplicate is a real hook invocation: the same guard runs twice, then three times, on every matching tool call, and `settings.json` keeps the extras permanently.

### 3.2 Fix — derive the pattern instead of listing it

```powershell
$ourHookFiles = @(
    [regex]::Matches(($fragment | ConvertTo-Json -Depth 30), '(?i)hx-[a-z0-9-]+\.ps1') |
        ForEach-Object { $_.Value } |
        Sort-Object -Unique
)

if ($ourHookFiles.Count -eq 0) {
    throw "Settings fragment references no hx-*.ps1 hook scripts: $fragmentPath"
}

$ourPattern = '(' + ((@($ourHookFiles) | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')'
```

The fragment is the thing being installed, so it is the correct authority for what counts as ours. A hook added to the fragment can no longer be missed here — which is the class of defect, not just this instance. The guard clause exists because an empty pattern would match everything and silently wipe unrelated hooks.

The closing summary now prints the real registered count and a per-event breakdown derived from the fragment, rather than a hard-coded list of five event names.

### 3.3 Why the old installer's own promise made this worse

The README claims the installer "removes/replaces prior HX hook entries if the installer is run again." It did — for five of seven. A promise kept for most of a set is harder to notice than one not made at all.

---

## 4. The README count

`claude-hooks/README.md:3` said "seven approved project hook commands"; the list below it had five entries. The list was not short — it was listing the wrong thing. Those five are **events**, and `PreToolUse` carries three commands.

Per the finding, the count was raised from five to seven at some point to satisfy the P1-01 scanner's P1-04 prose regex, without touching the list. That is the F-06 scope-narrowing pattern: the check was satisfied, the document was not corrected.

The list now shows all seven commands grouped under their five events, names each script file, and states plainly that `hx-common.ps1` is a shared library rather than a registered command — eight `.ps1` files ship, seven register. The `/hooks` verification block now shows per-event command counts instead of bare event names, so a reader comparing the page against `/hooks` output sees the 1/3/1/1/1 split rather than inferring five.

**The word "seven" is unchanged**, so any P1-04 prose check that keyed on it still passes. Verified: no `.ps1` in this branch greps for that count, so the fix could not have broken a scanner that is not here.

---

## 5. Regression tests

Seven assertions, all under the `F-06:` prefix.

| Assertion | What breaks it |
| --- | --- |
| packaged fragment declares seven hook commands | the fragment and the documented count diverge |
| first install registers exactly the packaged command count | the installer drops or adds a hook on a clean project |
| re-running the installer does not duplicate registrations | the original defect |
| all three PreToolUse guards survive a re-run exactly once | a fix that dropped one guard while removing duplicates |
| every packaged guard is registered after a re-run | the two previously-missed guards vanishing entirely |
| an unrelated third-party hook survives the installer | a fix that cleared every group for our events |
| preserving a foreign hook does not change the HX command count | the foreign hook being counted as ours, or vice versa |

**Three runs, not the two the finding asked for.** The defect grew by two per run, so a fix that handled only the first duplicate would still pass a two-run test. The third run costs one process spawn.

**The last two assertions guard against the wrong fix, not the original defect.** The simplest way to make re-runs idempotent is to clear every group for each event before appending — which passes the idempotence check and quietly breaks the installer's stated promise to preserve unrelated hooks. The preservation test seeds a foreign `third-party-tool.exe` hook, runs the installer twice, and asserts the foreign entry survives exactly once while the HX count stays at seven.

---

## 6. Gate

| Check | Result |
| --- | --- |
| Regression suite | **302 PASS / 0 FAIL** (was 295) |
| `git diff --check` | clean |
| Old installer, three runs | 7 → 9 → 11 registrations — defect reproduced |
| New installer, three runs | 7 → 7 → 7 |

Scope: the suite exercises `apply-hooks.ps1` against scratch project roots under the test temp directory. It does not install into, read, or modify the live `.claude/settings.json`.

---

## 7. Defect found and not fixed here — stated, not buried

`claude-hooks/README.md` lines 20 and 27 contain the literal workstation path `C:\Users\JarvisRichardson\Desktop\HX-Infrastructure`, in the two runnable command examples.

This file is named explicitly in **item 10**, the repo-wide workstation-path sweep, which counts 26 tracked files on this branch. It was left alone deliberately. Fixing two of twenty-six here would break item 10's own baseline — its verification depends on that count — and would spread one sweep across two unrelated commits.

The standing directive to fix defects on sight is about not stalling on a problem. This one is already scheduled, has a defined scope, and is better done whole. Flagged here so it is not mistaken for an oversight.

---

## 8. Provenance and limits

- **Verified fact.** The 7 → 9 → 11 progression, the 7 → 7 → 7 result, the suite total, and `git diff --check` are reproducible. The old installer was restored from `git show HEAD:claude-hooks/apply-hooks.ps1` into a scratch copy of the package and run against a scratch project root; no repository file was installed into.
- **Verified by reading, then by execution.** The `$ourPattern` omission was identified by reading `apply-hooks.ps1:40` and then confirmed by running the old installer, rather than accepted from the finding.
- **Attestation, not evidence:** no live server was contacted and no remote endpoint was invoked. Work was local file edits, `git` plain-text queries, and local PowerShell runs against scratch directories.
- **Not covered:** items 9, 10 and 11; the P1-01 scanner; F-02, F-04, F-05; CR-1. None were run or inspected.
- **Also completed this session, outside item 8:** two CodeRabbit findings on `governance/logs/actions-and-issues.md` (`act-015` status and the stale gateway name in `iss-017`) and two on the predecessor report (incomplete post-change state, undefined sweep term). All four are recorded in their own documents.
