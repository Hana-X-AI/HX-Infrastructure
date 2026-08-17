# kimi — complete Phase 3 handoff (v4, corrected against verified repository state)

**Prepared by:** Claude (claude-opus-5), cloud session · 2026-08-17 01:38 CDT
**For:** kimi-k3
**Supersedes:** v1 (`..._005156_...p1-06`), v2 (`..._010430_...`), v3 (`..._011245_...v2`, `..._011854_...v3`). This is the only current handoff.
**What changed in v4:** every branch, commit and merge claim is now taken from verified `git` output rather than inference. Part B collapsed from a consolidation exercise to a fast-forward — `main` is an ancestor of the evidence branch. P1-06 is complete and reduced to two small follow-ups. F-06 is confirmed closed. The nine unpushed commits are pushed.

Paste everything between the `═══` rules.

---

## Verified state as of 2026-08-17 01:38 CDT

| Fact | Value | How established |
| --- | --- | --- |
| Working branch | `docs/phase3-remediation-evidence` @ `47a95dcf` | `git branch -vv` |
| Remote | `origin/docs/phase3-remediation-evidence` @ `47a95dcf` — **pushed, in sync** | `git push` output |
| Default branch | `main` @ `52b76f91`, `origin/HEAD -> origin/main` | `git branch -a`, `git branch -vv` |
| **main is an ancestor of the evidence branch** | **yes** (exit 0) | `git merge-base --is-ancestor` |
| Other branch | `remediation/phase3` @ `1902e0b9`, checked out in the `hx-remediation` worktree | `git worktree list` |
| Commits unique to `remediation/phase3` | `1902e0b9`, `bfac142b`, `d1ad55de`, `8ec683bc` | `git log --not` |
| PR #2 head | `d1ad55de` — real commit on `remediation/phase3`, superseded by `1dc4f466` | `git log --not` |

**Claude Code's commits, all on the evidence branch:** `fa865931` (F-03, CR-5), `1dc4f466` (CR-2, CR-4, v3 digest, hard-lock), `ba9bc2da` (F-06, CR-3), `6a6dfd9c` (F-05), `80b3a253` (reports).
**kimi's commits:** `0d3e7b19` (F-02), `47a95dcf` (P1-06 report).

**Corrections carried into this document.** Two claims in earlier briefings were wrong and are removed: that P1-06's scripts had live-contact paths (kimi disproved it), and that PR #2's head existed on no branch (it is on `remediation/phase3`; I had read a truncated `--all -15` log as authoritative). Both were inference where a direct check was available.

---

═══════════════════════ PASTE FROM HERE ═══════════════════════

You are working in HX-Infrastructure, a governance repository for a 15-server fleet owned by Jarvis Richardson (Agent Zero), Hana-X AI. Read this entire message before acting.

You are taking over all remaining Phase 3 remediation work. The Claude Code session has committed and stopped. No other agent is writing to this repository — the file-boundary restrictions you were operating under are lifted.

## The rule that governs everything

The project is in **Phase 3 — Regroup & Reconciliation**: planning, decisions, and control-correction that **only tightens**. You may not contact a live server, invoke a remote endpoint, run any package, service, storage or network command, or run an operational commissioning path. You may not create `servers/<host>/configuration.md`. Nothing you do authorizes server implementation. This holds through every task, including the branch work.

## Verified repository state — do not re-derive it, but do verify it still holds

- You are on `docs/phase3-remediation-evidence` @ `47a95dcf`, in the main checkout at `<repository-root>`.
- That branch is **pushed and in sync** with `origin/docs/phase3-remediation-evidence`.
- `main` is `52b76f91` and is `origin/HEAD`. **`main` is an ancestor of your branch** — the eventual merge is a fast-forward.
- `remediation/phase3` @ `1902e0b9` is checked out in a separate worktree at `<remediation-worktree>`. It is stale. Do not work in it.
- Claude Code's work is committed as `fa865931`, `1dc4f466`, `ba9bc2da`, `6a6dfd9c`, `80b3a253`.
- Your work so far is `0d3e7b19` (F-02) and `47a95dcf` (P1-06 report).

If any of this has changed, stop and report before acting.

## Standing rules

- **Stage only files you name.** Never `git add -A`, `git add .`, `git stash`, `git clean`, or `git checkout .`.
- **Never force-push, amend a pushed commit, or rebase.** The branch is published.
- **Do not push again until Part B**, and Part B does not start without explicit owner authorization.
- **Read `governance/documentation-standards.html` before creating or renaming any file.** `governance/` uses `lower-kebab-case.md`; reports use `<author>_<YYYY-MM-DD>[_<HHMMSS>]_<lower-kebab-slug>`; scripts are lower-kebab-case; no spaces, no non-ASCII; hyphen separates words, underscore is the report field separator.
- **Never put a real filesystem path in a committed file.** Use `<repository-root>`, `<remediation-worktree>`, `<main-checkout>`.
- **State the scope of every check.** If a search covered eleven files, say eleven files. Multiple gates in this project have gone green on a scope narrower than the claim they supported. That is the failure mode being corrected.
- **Assertions are not evidence.** If you did not run a check, say so. "No server contacted" is an attestation — label it as one.
- **Do not update a report to match a conclusion.** If a task is not done, the report says not done.
- **Suite baselines: 305 passed / 0 failed (main suite), 22 passed / 0 failed (AI-runtime invariants).** Any briefing that says 160 is stale. If a baseline run does not match, stop and report — the tree moved.
- **Denylist searches are not proof of absence.** When you sweep for a class of thing, state the terms you used so the gaps are visible. Your P1-06 sweep omitted the PowerShell-native remoting verbs; that is why task 1 exists.
- Preserve line endings and encoding. Files are UTF-8, some with a BOM. Do not normalise them.
- One commit per task, message naming the finding it closes.

═══════════════════════════════════════════════════════════════

# PART A — the remaining backlog

## Task 0 — ground truth (short, because most is established above)

1. Report `git status --porcelain` and `git log --oneline -3`. Confirm the state in the section above still holds.
2. **Read finding F-04 from its source** in the findings register. Do not rely on any summary, including this one — it was silently dropped from Claude Code's coverage lists and never worked, and no briefing in this project has ever stated its content. Report what it says, whether it is closed, and what closing it requires. This is task 4's input.

**Already established — do not re-investigate:** F-06 is closed by `ba9bc2da` (`fix(F-06,CR-3): derive the installer removal pattern from the packaged fragment`). F-05 is closed by `6a6dfd9c`. F-03 and CR-5 by `fa865931`. CR-2, CR-4, the v3 digest and the hard-lock record by `1dc4f466`. F-02 by your `0d3e7b19`.

## Task 1 — P1-06 follow-ups (small; the main task is done)

Your P1-06 report stands: no live-contact path exists, no DS4 profile assumption remains, zero files changed, suites 22/0 before and after. The owner accepted it. Two follow-ups only.

**1a — close the denylist gap.** Your primitive sweep covered 23 terms but omitted the PowerShell-native remoting verbs, which for a `.ps1` codebase are the most direct route to a remote host. Re-sweep the four gate scripts for: `Invoke-Command`, `New-PSSession`, `Enter-PSSession`, `iwr`, `irm`, `Invoke-Expression`, `Invoke-CimMethod`, `Get-WmiObject`, `Restart-Computer`, `systemctl`, `docker`, `kubectl`, `cmd /c`, and the `&` and `.` call operators applied to a variable. Report result and scope. If zero, P1-06 closes clean.

**1b — mark the deferred live path.** Add **one comment** at `tests/ai-runtime/hx-runtime-acceptance.ps1` line 268, above the `live execution not implemented in this pass` branch, stating that implementing this path requires a fail-closed phase guard at the script entry point first, per the Phase 3 control model. That is the entire change. **Do not add a guard** — the owner ruled against guarding an unimplemented capability, and that ruling stands. The comment exists so whoever implements the path later inherits the requirement rather than the gap.

**1c — record it.** Append the P1-06 row to `governance/logs/actions-and-issues.md`. The tracker hold is lifted; Claude Code's rows are committed. **Close P1-06 as premise-invalid, not as done**, citing your report — the item was created against a risk that does not exist, and anyone auditing why it produced no diff needs to see that distinction.

## Task 2 — P2-02: tracker reconciliation

Unblocked. Claude Code's rows are committed, so your diff should now contain only your own edits — **verify that before committing.**

Reconcile `governance/logs/actions-and-issues.md` and regenerate `governance/actions-and-issues.html` and `governance/site/actions-and-issues.html` so they match the Markdown source.

The table uses **escaped pipes** (`\|`) inside code spans — a naive column split mis-parses `iss-004`, `act-003`, `act-004`. That is correct Markdown, not a defect.

**`act-015` and `iss-016` are owner-ruling items. Leave both. List them as blocked.**

## Task 3 — the reproducibility question on `0d3e7b19`

Your F-02 commit contains `governance/index.html` and `governance/site/index.html` regenerated using your reverted `tools/build-governance-html.js` — but that revert was not committed. If so, a clean checkout of `0d3e7b19` plus `node tools/build-governance-html.js` produces different nav order than the committed HTML: the same generated-vs-source desync F-02 exists to fix.

**Prove or disprove it first.** Check out `0d3e7b19` into a scratch location, run the generator, diff the output against the committed `governance/index.html`, and **report the actual diff**. If there is no diff, say so and close the task — this briefing may be wrong.

**If there is a diff, do not fix it.** `0d3e7b19` is pushed; it cannot be amended. Run `git log --format='%h %an %ad %s' -- tools/build-governance-html.js` and report it. Somebody reordered the `navHtml()` items array deliberately and you reverted it as out-of-scope drift. Whether that revert stands is Part C ruling 2. Report and wait. The fix, once ruled, is a **new commit** — never a rewrite of a published one.

## Task 4 — F-04

Execute whatever task 0.2 established F-04 requires. If it needs an owner ruling, or touches something outside a safe scope, report rather than proceed.

## Task 5 — P2-06: canonical suite path

Rename `tests/remediation-tests-restored.ps1` to the canonical path. Use `git mv` so history follows.

Then grep the **entire repository** for the old filename — CI configuration, task runners, hook scripts, documentation, and the AI-runtime invariants suite, which reads sibling scripts as source text — and report **the number of files searched** alongside the number of references found. A rename leaving one stale reference in a runner is worse than no rename.

Re-run both suites. Main must be **305/0**, AI-runtime **22/0**. Report before and after for each.

## Task 6 — the workstation-path sweep

Replace literal filesystem paths in committed files with `<repository-root>`, `<remediation-worktree>`, `<main-checkout>`.

**Gated on Part C ruling 4:** whether dated historical reports get rewritten or get a dated supersession banner. A dated report describing what was true when written is correct as history — do not rewrite history without the ruling. Sweep **current-state and published surfaces** now; stage the historical set as a separate reported list awaiting the ruling.

## Task 7 — P3-01: version-stamping

Version-stamp the authority files, including `SERVER-REGISTRY.md`. `hx-authority-edit-guard.ps1` governs edits to these and was rewritten fail-closed in `fa865931` — read it before touching anything it covers. **If it refuses an edit, that refusal is correct.** Report it; do not work around it.

## Task 8 — the twelve CodeRabbit comments on PR #2

PR #2's head is `d1ad55de` on `remediation/phase3`. The twelve comments were written against **that** tree. Its content has been superseded on your branch by `1dc4f466`, so line numbers and file states may not map across.

For each comment, the question is **"does this still reproduce on `docs/phase3-remediation-evidence`?"** — not "was it fixed on `remediation/phase3`."

Report per comment: what it says, whether it reproduces on your branch, and either the fix applied or a demonstration that it does not reproduce. **Show the current state of the line it points at.** A comment is not resolved because the branch carrying it was abandoned.

═══════════════════════════════════════════════════════════════

# PART B — merge to main

**Do not begin Part B until the owner explicitly authorizes it.** Part A must be complete and B2 must be fully green.

**`main` is an ancestor of `docs/phase3-remediation-evidence`.** The merge is a fast-forward. There is no consolidation, no squash, no conflict surface. Do not create a consolidation branch and do not merge `remediation/phase3` into anything.

## B1 — confirm `remediation/phase3` holds nothing unique

```
git diff docs/phase3-remediation-evidence remediation/phase3 --stat
```

**Only additions matter** — an addition is content that exists on `remediation/phase3` and nowhere else. Three of its four unique commits (`1902e0b9`, `bfac142b`, `8ec683bc`) carry messages identical to commits already on your branch — the duplicate-content-under-different-SHA pattern. The fourth, `d1ad55de` ("correct v3 remediation digest"), was redone on your branch as part of `1dc4f466`.

If the output is deletions-only, `remediation/phase3` is dead weight — report that and proceed. **If there are additions, stop and report them as a finding.** What to do with unique content on an abandoned branch is an owner decision, not a merge strategy.

## B2 — the pre-merge gate

Run every check on `docs/phase3-remediation-evidence`. Each demonstrated with **output**, not asserted. Report the **scope** of every search alongside its result.

- Main suite 305 passed / 0 failed; AI-runtime invariants 22 passed / 0 failed.
- Zero literal filesystem paths in any tracked file.
- Zero `DS4` / `ds4-` occurrences in active configuration or code. Historical governance text and vendored third-party mirrors are legitimate; say which category each match falls into.
- Every hook — `hx-phase1-guard.ps1`, `hx-authority-edit-guard.ps1`, `hx-permanent-policy-guard.ps1`, `hx-validate-discovery.ps1` — fails closed on all four negative cases: unknown value, empty value, missing file, parse error. **Demonstrated by execution, not by reading source.**
- `governance/index.html` and `governance/site/*.html` reproduce byte-identically from a clean checkout via `node tools/build-governance-html.js` and `node tools/make-standalone.js`.
- `governance/actions-and-issues.html` row count matches `governance/logs/actions-and-issues.md`.
- No `servers/<host>/configuration.md` exists anywhere in the tree.
- No file contains a server-mutation path reachable without a later-phase authorization.

Any failure stops Part B. Report it; do not repair it inside the merge.

## B3 — merge, once authorized

```
git switch main
git merge --ff-only docs/phase3-remediation-evidence
git push origin main
```

If `--ff-only` fails, **stop.** It means `main` moved and the ancestry assumption no longer holds. Do not fall back to a merge commit or a rebase — report it.

Report the resulting SHA on `main`.

## B4 — close out

1. Close PR #2 with a comment naming the commit on `main` that supersedes it and summarizing your task 8 triage.
2. **Delete nothing.** Leave `remediation/phase3`, `origin/remediation/phase3`, and the `<remediation-worktree>` worktree in place. List them as superseded and leave removal to the owner.
3. Report the final state of every branch, every worktree, and PR #2.

═══════════════════════════════════════════════════════════════

# PART C — owner rulings you must not decide yourself

Put this list at the **top** of your first report, with current status against each. Do not proceed on any task that depends on an unresolved one.

1. **`remediation/phase3` disposition** — confirmed dead weight or not, per B1, then what happens to it. Gates B4.
2. **The `navHtml()` reorder** — does your revert stand, or was the reorder a deliberate fix? Gates task 3.
3. **`act-015` and `iss-016` status.** Gates the close of task 2.
4. **Historical reports** — rewritten, or dated supersession banner? Gates half of task 6.
5. **DS4 redaction reversibility** — raised in Claude Code's reports, unresolved.
6. **The thirteen `pre-work-results.md` files** and **the LangGraph branch question** — both raised in Claude Code's reports, unresolved.

═══════════════════════════════════════════════════════════════

# Report back

One report per part, in `governance/Phase -3-Regroup/reports/`, using the naming standard.

Every report covers: what you changed file by file; every check you ran with its **actual output** and its **scope**; before/after suite counts; what you could not resolve and why; the commit hash for each piece of work; and **anything you found that contradicts this briefing**.

**If the repository disagrees with anything written here, the repository wins.** Say so plainly and describe the difference. Two claims in earlier versions of this briefing were wrong and were caught exactly that way.

Complete task 0 and report it before editing anything.

═══════════════════════ PASTE TO HERE ═══════════════════════
