# kimi — complete Phase 3 handoff (v5)

**Prepared by:** Claude (claude-opus-5), cloud session · 2026-08-17 01:49 CDT
**For:** kimi-k3
**Supersedes:** all earlier handoffs (`..._005156_`, `..._010430_`, `..._011245_`, `..._011854_`, `..._013822_`). This is the only current one.
**What changed in v5:**

1. **Structure.** Every gate and stop condition now appears **before** the work it gates. Prior versions buried "complete task 0 before editing anything" at the end of the document, which is where an instruction goes to be ignored.
2. **Task 2's premise was wrong and is corrected.** v4 claimed Claude Code's tracker rows were committed. They are not — `iss-020`, `iss-021`, `iss-022`, `act-019` are absent from HEAD and `iss-017` is worktree-only. I inferred "committed" from cc's commit messages without checking whether the tracker file was in those commits. kimi caught it in step zero. Task 2 now carries the ruling: one commit, whole file, attribution in the message.
3. **The parked `build-governance-html.js` revert is named explicitly** in section 3 so it is not swept in.

Paste everything between the `═══` rules.

---

## Verified state as of 2026-08-17 01:49 CDT

| Fact | Value | How established |
| --- | --- | --- |
| Working branch | `docs/phase3-remediation-evidence` @ `47a95dcf` | `git branch -vv` |
| Remote | `origin/docs/phase3-remediation-evidence` @ `47a95dcf` — pushed, in sync | `git push` output |
| Default branch | `main` @ `52b76f91`, `origin/HEAD -> origin/main` | `git branch -a`, `git branch -vv` |
| **main is an ancestor of the evidence branch** | **yes** (exit 0) | `git merge-base --is-ancestor` |
| Other branch | `remediation/phase3` @ `1902e0b9`, in the `hx-remediation` worktree | `git worktree list` |
| Commits unique to `remediation/phase3` | `1902e0b9`, `bfac142b`, `d1ad55de`, `8ec683bc` | `git log --not` |
| PR #2 head | `d1ad55de` — real commit on `remediation/phase3`, superseded by `1dc4f466` | `git log --not` |

**Claude Code's commits, all on the evidence branch:** `fa865931` (F-03, CR-5), `1dc4f466` (CR-2, CR-4, v3 digest, hard-lock), `ba9bc2da` (F-06, CR-3), `6a6dfd9c` (F-05), `80b3a253` (reports).
**kimi's commits:** `0d3e7b19` (F-02), `47a95dcf` (P1-06 report).

**Corrections carried in.** Two claims from earlier briefings were wrong and are removed: that P1-06's scripts had live-contact paths (kimi disproved it), and that PR #2's head existed on no branch (it is on `remediation/phase3`; I had treated a truncated `--all -15` log as authoritative). Both were inference where a direct check was available.

---

═══════════════════════ PASTE FROM HERE ═══════════════════════

You are working in HX-Infrastructure, a governance repository for a 15-server fleet owned by Jarvis Richardson (Agent Zero), Hana-X AI. You are taking over all remaining Phase 3 remediation work. The Claude Code session has committed and stopped; no other agent is writing to this repository.

# 1. THE RULE THAT GOVERNS EVERYTHING

The project is in **Phase 3 — Regroup & Reconciliation**: planning, decisions, and control-correction that **only tightens**. You may not contact a live server, invoke a remote endpoint, run any package, service, storage or network command, or run an operational commissioning path. You may not create `servers/<host>/configuration.md`. Nothing you do authorizes server implementation. This holds through every task below, including the branch work.

# 2. STOP — DO THIS FIRST, THEN REPORT, THEN WAIT

**Do not edit any file until you have completed both items below and reported them.**

**0a.** Report `git status --porcelain` and `git log --oneline -3`. Confirm the state in section 3 still holds.

**0b.** **Read finding F-04 from its source** in the findings register. Do not rely on any summary, including this document — F-04 was silently dropped from Claude Code's coverage lists and never worked, and no briefing in this project has ever stated its content. Report what it says, whether it is closed, and what closing it requires. This is the input to task 4.

Report both, then continue.

**Do not verify the same thing twice.** You already ran step 0a in the previous round and found three deviations from the v4 briefing; all three are folded into this document. If your `git status` matches what section 3 now describes, say so in one line and move to 0b.

# 3. VERIFIED STATE — verify it still holds, do not re-derive it

- You are on `docs/phase3-remediation-evidence` @ `47a95dcf`, in the main checkout at `<repository-root>`.
- That branch is **pushed and in sync** with `origin/docs/phase3-remediation-evidence`.
- `main` is `52b76f91` and is `origin/HEAD`. **`main` is an ancestor of your branch** — the eventual merge is a fast-forward.
- `remediation/phase3` @ `1902e0b9` is checked out in a separate worktree at `<remediation-worktree>`. It is stale. Do not work in it.
- Claude Code's work is committed as `fa865931`, `1dc4f466`, `ba9bc2da`, `6a6dfd9c`, `80b3a253`.
- Your work so far is `0d3e7b19` (F-02) and `47a95dcf` (P1-06 report).

**Already closed in code — do not re-investigate:** F-06 by `ba9bc2da`. F-05 by `6a6dfd9c`. F-03 and CR-5 by `fa865931`. CR-2, CR-4, the v3 digest and the hard-lock record by `1dc4f466`. F-02 by your `0d3e7b19`.

**But the tracker is not committed.** Claude Code's code changes are committed; its **tracker rows are not**. `iss-020`, `iss-021`, `iss-022`, `act-019` are absent from HEAD and `iss-017` is modified in the worktree only. Earlier versions of this briefing claimed otherwise and were wrong. Task 2 handles it.

**Also uncommitted and deliberately parked:** `tools/build-governance-html.js` — your `navHtml()` revert. **Do not commit it.** It is reserved for section 8 ruling 2.

If any of this has changed, stop and report before acting.

# 4. HARD STOPS — conditions that end work immediately

Report and wait. Do not work around any of these.

- A suite baseline does not match: **main suite 305 passed / 0 failed**, **AI-runtime invariants 22 passed / 0 failed**. Any briefing citing 160 is stale. A mismatch means the tree moved.
- `hx-authority-edit-guard.ps1` refuses an edit. **That refusal is correct.**
- A task appears to require an owner ruling from section 8.
- The repository contradicts this document. **The repository wins** — say so plainly and describe the difference. Two claims in earlier versions of this briefing were caught exactly that way.
- `git merge --ff-only` fails in Part B. Do not fall back to a merge commit or a rebase.
- Part B's B1 shows content unique to `remediation/phase3`.

# 5. STANDING RULES

- **Stage only files you name.** Never `git add -A`, `git add .`, `git stash`, `git clean`, or `git checkout .`.
- **Never force-push, amend a pushed commit, or rebase.** The branch is published. Corrections are new commits.
- **Do not push again until Part B**, and Part B requires explicit owner authorization.
- **Read `governance/documentation-standards.html` before creating or renaming any file.** `governance/` uses `lower-kebab-case.md`; reports use `<author>_<YYYY-MM-DD>[_<HHMMSS>]_<lower-kebab-slug>`; scripts are lower-kebab-case; no spaces, no non-ASCII; hyphen separates words, underscore is the report field separator.
- **Never put a real filesystem path in a committed file.** Use `<repository-root>`, `<remediation-worktree>`, `<main-checkout>`.
- **State the scope of every check.** If a search covered eleven files, say eleven files. Multiple gates in this project have gone green on a scope narrower than the claim they supported. That is the failure mode being corrected.
- **Denylist searches are not proof of absence.** When you sweep for a class of thing, list the terms you used so the gaps are visible. Your P1-06 sweep omitted the PowerShell-native remoting verbs; that is why task 1a exists.
- **Assertions are not evidence.** If you did not run a check, say so. "No server contacted" is an attestation — label it as one.
- **Do not update a report to match a conclusion.** If a task is not done, the report says not done.
- Preserve line endings and encoding. Files are UTF-8, some with a BOM. Do not normalise them.
- One commit per task, message naming the finding it closes.

# 6. PART A — the remaining backlog

## Task 1 — P1-06 follow-ups (the main task is done)

Your P1-06 report stands: no live-contact path, no DS4 profile assumption, zero files changed, 22/0 before and after. The owner accepted it. Two follow-ups only.

**1a — close the denylist gap.** Your sweep covered 23 terms but omitted the PowerShell-native remoting verbs, the most direct route to a remote host in a `.ps1` codebase. Re-sweep the four gate scripts for: `Invoke-Command`, `New-PSSession`, `Enter-PSSession`, `iwr`, `irm`, `Invoke-Expression`, `Invoke-CimMethod`, `Get-WmiObject`, `Restart-Computer`, `systemctl`, `docker`, `kubectl`, `cmd /c`, and the `&` and `.` call operators applied to a variable. Report result and scope. Zero closes P1-06 clean.

**1b — mark the deferred live path.** Add **one comment** at `tests/ai-runtime/hx-runtime-acceptance.ps1` line 268, above the `live execution not implemented in this pass` branch, stating that implementing this path requires a fail-closed phase guard at the script entry point first, per the Phase 3 control model. That is the entire change. **Do not add a guard** — the owner ruled against guarding an unimplemented capability and that ruling stands. The comment exists so whoever implements the path inherits the requirement rather than the gap.

**1c — record it.** Append the P1-06 row to `governance/logs/actions-and-issues.md`. The tracker hold is lifted. **Close P1-06 as premise-invalid, not as done**, citing your report — the item was created against a risk that does not exist, and anyone auditing why it produced no diff needs that distinction.

## Task 2 — P2-02: tracker reconciliation

**Corrected premise.** Claude Code's tracker rows are **not** committed — `iss-020`, `iss-021`, `iss-022`, `act-019` are absent from HEAD, `iss-017` is modified in the worktree only. Your diff therefore contains both agents' work, exactly as you found. Earlier briefings said the opposite; you were right to stop.

**Owner ruling, already given: commit the whole file in one commit, with attribution in the message.** Do not attempt to separate the two agents' rows. Line-surgery on an interleaved Markdown table whose generated HTML derives from the full file cannot be verified — you refused it once already for that reason and the reasoning still holds. Claude Code has stopped and cannot commit its own rows, so committing them attributed is the correct disposition, not a boundary violation. The rule you were given was never to claim another agent's work as yours; naming it is compliance, not an exception.

Commit message form:

```
docs(tracker): reconcile actions-and-issues (P2-02)

Rows iss-017, iss-020, iss-021, iss-022, act-019 authored by Claude Code
(commits fa865931, 1dc4f466, ba9bc2da, 6a6dfd9c) and left uncommitted when
that session ended. Committed here by kimi-k3 without modification.

Rows act-012 and the iss-021 condensation are kimi-k3's own P2-02 edits.
```

Then reconcile `governance/logs/actions-and-issues.md` and regenerate `governance/actions-and-issues.html` and `governance/site/actions-and-issues.html` so they match the Markdown source.

The table uses **escaped pipes** (`\|`) inside code spans — a naive column split mis-parses `iss-004`, `act-003`, `act-004`. That is correct Markdown, not a defect.

**`act-015` and `iss-016` are owner-ruling items (section 8, item 3). Leave both. List them as blocked.**

## Task 3 — the reproducibility question on `0d3e7b19`

Your F-02 commit contains `governance/index.html` and `governance/site/index.html` regenerated using your reverted `tools/build-governance-html.js` — but that revert was not committed. If so, a clean checkout of `0d3e7b19` plus `node tools/build-governance-html.js` produces different nav order than the committed HTML: the same generated-vs-source desync F-02 exists to fix.

**Prove or disprove it first.** Check out `0d3e7b19` into a scratch location, run the generator, diff the output against the committed `governance/index.html`, and **report the actual diff**. If there is no diff, say so and close the task — this briefing may be wrong.

**If there is a diff, do not fix it.** `0d3e7b19` is pushed and cannot be amended. Run `git log --format='%h %an %ad %s' -- tools/build-governance-html.js` and report it. Somebody reordered the `navHtml()` items array deliberately and you reverted it as out-of-scope drift. Whether that revert stands is section 8, item 2. Report and wait. The fix, once ruled, is a **new commit**.

## Task 4 — F-04

Execute whatever step 0b established F-04 requires. If it needs an owner ruling or touches something outside a safe scope, report rather than proceed.

## Task 5 — P2-06: canonical suite path

Rename `tests/remediation-tests-restored.ps1` to the canonical path. Use `git mv` so history follows.

Then grep the **entire repository** for the old filename — CI configuration, task runners, hook scripts, documentation, and the AI-runtime invariants suite, which reads sibling scripts as source text — and report **the number of files searched** alongside the number of references found. A rename leaving one stale reference in a runner is worse than no rename.

Re-run both suites: main **305/0**, AI-runtime **22/0**. Report before and after for each.

## Task 6 — the workstation-path sweep

Replace literal filesystem paths in committed files with `<repository-root>`, `<remediation-worktree>`, `<main-checkout>`.

**Gated on section 8, item 4:** whether dated historical reports get rewritten or get a dated supersession banner. A dated report describing what was true when written is correct as history — do not rewrite history without the ruling. Sweep **current-state and published surfaces** now; stage the historical set as a separate reported list awaiting the ruling.

## Task 7 — P3-01: version-stamping

Version-stamp the authority files, including `SERVER-REGISTRY.md`. `hx-authority-edit-guard.ps1` governs edits to these and was rewritten fail-closed in `fa865931` — read it before touching anything it covers.

## Task 8 — the twelve CodeRabbit comments on PR #2

PR #2's head is `d1ad55de` on `remediation/phase3`. The twelve comments were written against **that** tree. Its content has been superseded on your branch by `1dc4f466`, so line numbers and file states may not map across.

Per comment, the question is **"does this still reproduce on `docs/phase3-remediation-evidence`?"** — not "was it fixed on `remediation/phase3`."

Report per comment: what it says, whether it reproduces on your branch, and either the fix applied or a demonstration that it does not reproduce. **Show the current state of the line it points at.** A comment is not resolved because the branch carrying it was abandoned.

# 7. PART B — merge to main

**Requires explicit owner authorization. Part A must be complete and B2 fully green.**

**`main` is an ancestor of `docs/phase3-remediation-evidence`.** The merge is a fast-forward. There is no consolidation, no squash, no conflict surface. Do not create a consolidation branch. Do not merge `remediation/phase3` into anything.

## B1 — confirm `remediation/phase3` holds nothing unique

```
git diff docs/phase3-remediation-evidence remediation/phase3 --stat
```

**Only additions matter** — an addition is content existing on `remediation/phase3` and nowhere else. Three of its four unique commits (`1902e0b9`, `bfac142b`, `8ec683bc`) carry messages identical to commits already on your branch — the duplicate-content-under-different-SHA pattern. The fourth, `d1ad55de` ("correct v3 remediation digest"), was redone on your branch as part of `1dc4f466`.

Deletions-only output means `remediation/phase3` is dead weight — report that and proceed. **Additions are a hard stop** (section 4).

## B2 — the pre-merge gate

Run every check on `docs/phase3-remediation-evidence`. Each demonstrated with **output**, not asserted. Report the **scope** of every search alongside its result. Any failure stops Part B — report it; do not repair it inside the merge.

- Main suite 305 passed / 0 failed; AI-runtime invariants 22 passed / 0 failed.
- Zero literal filesystem paths in any tracked file.
- Zero `DS4` / `ds4-` occurrences in active configuration or code. Historical governance text and vendored third-party mirrors are legitimate; say which category each match falls into.
- Every hook — `hx-phase1-guard.ps1`, `hx-authority-edit-guard.ps1`, `hx-permanent-policy-guard.ps1`, `hx-validate-discovery.ps1` — fails closed on all four negative cases: unknown value, empty value, missing file, parse error. **Demonstrated by execution, not by reading source.**
- `governance/index.html` and `governance/site/*.html` reproduce byte-identically from a clean checkout via `node tools/build-governance-html.js` and `node tools/make-standalone.js`.
- `governance/actions-and-issues.html` row count matches `governance/logs/actions-and-issues.md`.
- No `servers/<host>/configuration.md` exists anywhere in the tree.
- No file contains a server-mutation path reachable without a later-phase authorization.

## B3 — merge

```
git switch main
git merge --ff-only docs/phase3-remediation-evidence
git push origin main
```

Report the resulting SHA on `main`. If `--ff-only` fails, that is a hard stop (section 4).

## B4 — close out

1. Close PR #2 with a comment naming the commit on `main` that supersedes it and summarizing your task 8 triage.
2. **Delete nothing.** Leave `remediation/phase3`, `origin/remediation/phase3`, and the `<remediation-worktree>` worktree in place. List them as superseded; removal is the owner's.
3. Report the final state of every branch, every worktree, and PR #2.

# 8. PART C — owner rulings you must not decide yourself

Put this list at the **top** of your first report with current status against each. Do not proceed on any task that depends on an unresolved one.

1. **`remediation/phase3` disposition** — confirmed dead weight or not, per B1, then what happens to it. Gates B4.
2. **The `navHtml()` reorder** — does your revert stand, or was the reorder a deliberate fix? Gates task 3.
3. **`act-015` and `iss-016` status.** Gates the close of task 2.
4. **Historical reports** — rewritten, or dated supersession banner? Gates half of task 6.
5. **DS4 redaction reversibility** — raised in Claude Code's reports, unresolved.
6. **The thirteen `pre-work-results.md` files** and **the LangGraph branch question** — both raised in Claude Code's reports, unresolved.

# 9. REPORT FORMAT

One report per part, in `governance/Phase -3-Regroup/reports/`, using the naming standard from section 5.

Every report covers: what you changed file by file; every check you ran with its **actual output** and its **scope**; before/after suite counts; what you could not resolve and why; the commit hash for each piece of work; and anything you found that contradicts this briefing.

═══════════════════════ PASTE TO HERE ═══════════════════════
