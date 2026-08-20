# kimi — full remaining backlog and branch consolidation to main

> **SUPERSEDED — do not use for execution.** This document is replaced by `claude_2026-08-17_011854_kimi-complete-handoff-v3.md`. It is retained as history only; run the v3 handoff, not this one.

**Prepared by:** Claude (claude-opus-5), cloud session · 2026-08-17 01:04 CDT
**For:** kimi-k3, taking over all remaining Phase 3 remediation work
**Gate:** Part A tasks 2–7 do not start until Claude Code has committed. Part B does not start until Part A is green and the owner has ruled on the six items in Part C.

---

## Owner notes — read before you paste this

**Why this can now all go to kimi.** Most of the remaining backlog was withheld from kimi earlier for one reason only: file collision with Claude Code's uncommitted work. Once cc commits and stops, that reason disappears. kimi can own every remaining file because nobody else is holding one. The sequencing is therefore strict — **cc commits first, cc stops, then kimi takes everything.** If cc is still editing when kimi starts on P2-06 or P3-01, you get the same interleaved-hunk problem that already blocked P2-02, but on a file rename, which is worse.

**About "push all branches cleanly to main."** This will not be a three-way merge, and you should not let an agent attempt one. Three branches carry *duplicate-content commits under different SHAs* — the same changes, committed more than once, with different hashes. Git cannot tell that two such commits are the same change; merging them produces conflicts on identical content and, worse, can silently apply a change twice. The correct shape is almost certainly: **pick one branch as the source of truth, verify by content that the others contain nothing it lacks, then fast-forward main from that one and abandon the rest.** Part B is written that way — as a verify-then-pick, not a merge. If the verification shows unique content on more than one branch, that is a finding to bring back to you, not a licence to merge.

**What I have not verified.** I cannot run git. Everything below about branch state comes from earlier reconnaissance and from kimi's and cc's own reports. Three specifics I flag as unconfirmed: (a) whether F-06 was fully closed by cc's item 8 hook-installer work; (b) the current content of finding F-04, which I am deliberately not restating — kimi reads it from the source; (c) which checkout or worktree kimi is actually in. Part A task 0 makes kimi establish all three before it acts.

**One item on this list is kimi's own defect.** Commit `0d3e7b1` contains regenerated HTML produced by an uncommitted generator. It is task 3. It is written neutrally; kimi found and disclosed its own boundary crossing already, which is the behaviour you want to keep.

---

## The prompt

> You are working in HX-Infrastructure, a governance repository for a 15-server fleet owned by Jarvis Richardson (Agent Zero), Hana-X AI. Read this entire message before acting.
>
> You are now taking over **all** remaining Phase 3 remediation work. The Claude Code session that was working alongside you is committing its work and stopping. After it stops, no other agent is writing to this repository. That means the file-boundary restrictions you were operating under are lifted — but only after you have confirmed cc has actually committed and stopped, which is task 0.
>
> ### The rule that governs everything
>
> The project is in **Phase 3 — Regroup & Reconciliation**: planning, decisions, and control-correction that **only tightens**. You may not contact a live server, invoke a remote endpoint, run any package, service, storage or network command, or run an operational commissioning path. You may not create `servers/<host>/configuration.md`. Nothing you do authorizes server implementation. This holds through every task below, including the branch work.
>
> ### Standing rules for all tasks
>
> - **Stage only files you name.** Never `git add -A`, `git add .`, `git stash`, `git clean`, or `git checkout .`.
> - **Never push, amend, rebase, or force anything** until Part B, and Part B does not start without explicit owner authorization.
> - **Read `governance/documentation-standards.html` before creating or renaming any file.** `governance/` uses `lower-kebab-case.md`; reports use `<author>_<YYYY-MM-DD>[_<HHMMSS>]_<lower-kebab-slug>`; scripts are lower-kebab-case; no spaces, no non-ASCII; hyphen separates words, underscore is the report field separator.
> - **Never put a real filesystem path in a committed file.** Use `<repository-root>`, `<remediation-worktree>`, `<main-checkout>`.
> - **State the scope of every check.** If a search covered eleven files, say eleven files. Multiple gates in this project have gone green on a scope narrower than the claim they supported. That is the failure mode being corrected.
> - **Assertions are not evidence.** If you did not run a check, say so. "No server contacted" is an attestation — label it as one.
> - **Do not update a report to match a conclusion.** If a task is not done, the report says not done.
> - **Suite baselines: 305 passed / 0 failed (main suite), 22 passed / 0 failed (AI-runtime invariants).** Any briefing that says 160 is four revisions stale. If a baseline run does not match, stop and report — it means the tree moved.
> - Preserve line endings and encoding. Files are UTF-8, some with a BOM. Do not normalise.
>
> ---
>
> ## Part A — the remaining backlog
>
> ### Task 0 — establish ground truth (do this before anything else)
>
> Report all of the following verbatim, then stop and wait if any of it surprises you:
>
> 1. `git status --porcelain`, `git branch -vv`, `git log --oneline -10`, and which checkout or worktree you are in.
> 2. `git log --oneline` for each of `remediation/phase3`, `docs/phase3-remediation-evidence`, and `main` (or the default branch), plus each one's remote tracking state.
> 3. Confirm Claude Code has committed: its work covered a verification gate, guard fail-closed changes to `.claude/hooks/hx-phase1-guard.ps1`, Group C corrections, a hook installer, and an F-05 reconstruction of `governance/policy/ai-runtime-acceptance-contract.md`. If any of that is still showing as uncommitted in `git status`, **stop and report** — do not commit another agent's work.
> 4. Read finding **F-04** from its source in the findings register. Do not rely on any summary. Report what it says, whether it is closed, and what closing it would require. It was silently dropped from the coverage lists and never worked; you are picking it up cold.
> 5. Report whether **F-06** (the hook installer / `claude-hooks/apply-hooks.ps1` pattern defect — a regex covering five hook names against seven commands) is actually closed by cc's item 8 work. Verify by reading the file, not by reading a report.
>
> ### Task 1 — P1-06: quarantine the DS4-era runtime gates
>
> Full briefing already delivered as `governance/Phase -3-Regroup/remediation/claude_2026-08-17_005156_parallel-agent-prompt-p1-06.md`. Read it and execute it. Two amendments now that cc has stopped: `tests/ai-runtime/README.md` is no longer off-limits — you may edit it, but say what you changed and why. And the shared-tracker append-only discipline no longer applies once you have confirmed cc has stopped.
>
> ### Task 2 — P2-02: tracker reconciliation (unblocked by cc's commit)
>
> Your earlier analysis was correct and your decision to hold was correct. Once cc's rows are committed, your tracker diff should shrink to only your own edits. Verify that it has before committing. Reconcile `governance/logs/actions-and-issues.md` and regenerate `governance/actions-and-issues.html` and `governance/site/actions-and-issues.html` so they match the Markdown source.
>
> The table uses **escaped pipes** (`\|`) inside code spans — a naive column split mis-parses `iss-004`, `act-003`, `act-004`. That is correct Markdown, not a defect.
>
> **`act-015` and `iss-016` are owner-ruling items. Leave both. List them as blocked.**
>
> ### Task 3 — repair the reproducibility defect in `0d3e7b1`
>
> Your F-02 commit contains `governance/index.html` and `governance/site/index.html` regenerated using your reverted `tools/build-governance-html.js` — but the generator revert was not committed. As it stands, a clean checkout of `0d3e7b1` followed by `node tools/build-governance-html.js` produces different nav order than the committed HTML. That is the same generated-vs-source desync F-02 exists to fix.
>
> **First, prove or disprove it.** Check out `0d3e7b1` into a scratch location, run the generator, diff the output against the committed `governance/index.html`, and report the actual diff. If there is no diff, say so and close this task — I may be wrong.
>
> **If there is a diff, do not fix it yet.** Run `git log --format='%h %an %ad %s' -- tools/build-governance-html.js` and report it. Somebody reordered the `navHtml()` items array deliberately, and you reverted it as out-of-scope drift. Whether that revert stands is an owner ruling, not yours. Report and wait.
>
> ### Task 4 — item 4 / F-04
>
> Execute whatever task 0.4 established F-04 requires. If F-04 turns out to need an owner ruling or to touch something outside a safe scope, report rather than proceed.
>
> ### Task 5 — P2-06: canonical suite path
>
> Rename `tests/remediation-tests-restored.ps1` to the canonical path **`tests/remediation-tests.ps1`** (repository-relative, from the repository root) and update every reference to it. This was withheld from you earlier solely because cc was editing that file; it is yours now. The `-restored` suffix was a quarantine workaround while the canonical name was locked; with the lock cleared, the suite returns to its documented name.
>
> Do the rename with `git mv tests/remediation-tests-restored.ps1 tests/remediation-tests.ps1` so history follows. Then grep the **entire repository** for the old filename — including CI configuration, task runners, hook scripts, and documentation — and report the number of files searched alongside the number of references found. A rename that leaves one stale reference in a runner is worse than no rename.
>
> Re-run the suite. It must still be 305/0 after the rename. Report both runs.
>
> ### Task 6 — the workstation-path sweep
>
> Remove literal filesystem paths from committed files, replacing them with `<repository-root>`, `<remediation-worktree>`, `<main-checkout>`.
>
> **This is gated on an owner ruling** (Part C, item 4): whether dated historical reports get rewritten or get a dated supersession banner. A dated report describing what was true when written is correct as history. Do not rewrite history without the ruling. You may do the sweep on **current-state and published surfaces** now, and stage the historical set as a separate reported list awaiting the ruling.
>
> ### Task 7 — P3-01: version-stamping
>
> Version-stamp the authority files, including `SERVER-REGISTRY.md`. cc's guard `hx-authority-edit-guard.ps1` governs edits to these — read it before you touch anything it covers, and if it refuses an edit, that refusal is correct and you report it rather than working around it.
>
> ### Task 8 — the twelve CodeRabbit comments on PR #2
>
> Twelve review comments are unresolved. Read all twelve. For each, report: what it says, whether it is still valid against the current tree, and either the fix you applied or why it does not apply. Several may already be resolved by cc's or your own work — a comment that no longer reproduces is resolved, but say *why* it no longer reproduces.
>
> Do not resolve a comment by asserting it is fixed. Show the current state of the line it points at.
>
> ---
>
> ## Part B — consolidation to main
>
> **Do not begin Part B until the owner explicitly authorizes it.** Part A must be complete, both suites green (305/0 and 22/0), and the Part C rulings issued.
>
> This is **not** a three-way merge, and you should not attempt one. The branches carry **duplicate-content commits under different SHAs** — the same changes committed more than once with different hashes. Git cannot recognise these as identical; merging them produces conflicts on identical content and can apply the same change twice. Work it as verify-then-pick.
>
> **B1 — map the branches.** For each of `remediation/phase3`, `docs/phase3-remediation-evidence`, and the default branch, report: tip SHA, commit count, tracking state, and ahead/behind against each of the others. Report what PR #2 currently has as its head and how that compares to the actual branch tip — they were last seen disagreeing (`d1ad55d`/3 commits versus `1902e0b`/5).
>
> **B2 — compare by content, not by history.** For each pair of branches, produce `git diff <a>..<b> --stat`. **Content difference is the only thing that matters here; commit count and history shape are noise.** Identify, per branch, what content exists there and nowhere else.
>
> **B3 — report and stop.** Present: which single branch contains a superset of all the work; what, if anything, exists uniquely on the others; and your recommended consolidation path. **If more than one branch has unique content, stop and report that as a finding.** That case needs an owner decision, not an agent's merge strategy.
>
> **B4 — pre-merge gate.** Before anything lands on main, all of these must hold, and each must be demonstrated with output rather than asserted:
>
> - Main suite 305/0 and AI-runtime invariants 22/0 on the merge candidate.
> - Zero literal filesystem paths in any tracked file — report the search and its scope.
> - Zero `DS4` / `ds4-` occurrences outside the Provenance section where the reviewed snapshot is legitimately named as design inspiration.
> - Every hook fails closed on all four negative cases: unknown value, empty value, missing file, parse error. Demonstrated by execution.
> - All twelve CodeRabbit comments dispositioned.
> - `governance/index.html` and `governance/site/*.html` reproduce byte-identically from a clean checkout via `node tools/build-governance-html.js` and `node tools/make-standalone.js`.
> - `governance/actions-and-issues.html` row count matches `governance/logs/actions-and-issues.md`.
> - No `servers/<host>/configuration.md` exists. No commit in the merge set contains a server-mutation path.
>
> **B5 — execute, once authorized.** Fast-forward or merge exactly as the owner ruled in B3. One push. Report the resulting SHA and the state of every branch and the PR afterward.
>
> ---
>
> ## Part C — owner rulings you need and must not decide yourself
>
> Collect these into one list and put it at the top of your report. Do not proceed on any task that depends on one.
>
> 1. **Source of truth branch** — which of `remediation/phase3` and `docs/phase3-remediation-evidence` survives, and what happens to the other. Gates all of Part B.
> 2. **The `navHtml()` reorder** — does your revert stand, or was the reorder a deliberate fix? Gates task 3.
> 3. **`act-015` and `iss-016` status.** Gates the close of task 2.
> 4. **Historical reports** — rewritten, or dated supersession banner? Gates half of task 6.
> 5. **DS4 redaction reversibility** — raised in cc's reports, unresolved.
> 6. **The thirteen `pre-work-results.md` files** and **the LangGraph branch question** — both raised in cc's reports, both unresolved.
>
> ---
>
> ## Report back
>
> One report per part, written to `governance/Phase -3-Regroup/reports/` using the naming standard.
>
> Every report covers: what you changed file by file; every check you ran with its **actual output** and its **scope**; before/after suite counts; what you could not resolve and why; the commit hash for each piece of work; and **anything you found that contradicts this briefing**.
>
> **If the repository disagrees with anything written here, the repository wins.** Say so plainly and describe the difference.

---

## Verification the owner should apply

- Task 0 was reported before any edit. If the first thing in kimi's report is a change rather than a `git status`, the sequencing was skipped.
- Every task has a commit hash. Work with no hash is work that can still evaporate.
- Task 3 reports an actual diff, not a conclusion — including the possibility that I was wrong and there is no diff.
- Task 5 reports the number of files its rename-reference grep covered, not just the number of hits.
- Part B stops at B3 and waits. If kimi merges anything without the ruling, that is the escalation.
- Part C list appears at the top of the first report, not buried.
