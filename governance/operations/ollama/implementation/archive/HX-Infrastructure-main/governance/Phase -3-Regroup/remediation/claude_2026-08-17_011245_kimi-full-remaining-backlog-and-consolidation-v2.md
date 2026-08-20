# kimi — full remaining backlog and consolidation to main (v2)

> **SUPERSEDED — do not use for execution.** This document is replaced by `claude_2026-08-17_011854_kimi-complete-handoff-v3.md`. It is retained as history only; run the v3 handoff, not this one.

**Prepared by:** Claude (claude-opus-5), cloud session · 2026-08-17 01:12 CDT
**For:** kimi-k3, taking over all remaining Phase 3 remediation work
**Supersedes:** `claude_2026-08-17_010430_kimi-full-remaining-backlog-and-consolidation.md` — Part B replaced. Part A and Part C are unchanged; if kimi has already started Part A, that work is unaffected.
**Gate:** Part A tasks 2–8 do not start until Claude Code has committed. Part B does not start until Part A is green and the owner has ruled on the items in Part C.

---

## Owner notes — read before you paste this

**What changed in v2.** Part B was a full history reconciliation across three diverged branches. It is now a **content consolidation**: determine which branch holds the correct end state, land that state on main as one commit, delete the rest. The history-reconciliation problem is not solved — it is *declined*. That is the right call here because this repository's audit trail lives in the dated reports under `governance/Phase -3-Regroup/reports/`, not in commit granularity. You lose the ability to `git log` your way through the remediation; you lose nothing you would ever actually go looking for.

**The check that makes this safe.** Any consolidation method — fast-forward, squash, exact-tree — is only trustworthy if the result is content-identical to the branch it came from. `git diff --stat <source-branch> <consolidated-branch>` returning **empty** proves that, whatever method was used. Part B is built around that one check. If it is not empty, the consolidation dropped something and must not land.

**The one real trap in the easy path.** The obvious shortcut — `git checkout <branch> -- .` — copies files *in* but does not delete files that exist on main and not on the source branch. It silently produces a tree that is neither branch. Part B avoids it and names the correct primitives instead.

**It may be simpler than any of this.** If main is an ancestor of the good branch, the consolidation is a fast-forward and there is nothing to decide. B1 checks that first, because it is one command and it may end the whole exercise.

**Do not let the shortcut swallow the twelve CodeRabbit comments.** Abandoning PR #2 makes them go away procedurally. It does not make any defect they found go away. They are triaged for content in B5 before the PR is closed.

---

## The prompt — Part B replacement

> ## Part B — consolidation to main
>
> **Do not begin Part B until the owner explicitly authorizes it.** Part A must be complete, both suites green (305 passed / 0 failed main, 22 passed / 0 failed AI-runtime invariants), and the Part C rulings issued.
>
> You are consolidating **content**, not history. The branches carry duplicate-content commits under different SHAs — the same changes committed more than once with different hashes. Git cannot recognise those as identical, so history reconciliation across them produces conflicts on identical content and can apply the same change twice. We are declining that problem, not solving it. The end state of the files is what lands; the commit graph that produced it does not.
>
> **Never force-push. Never rewrite a published branch. Everything below is additive until B6.**
>
> ### B1 — find the source of truth, and check whether this is already trivial
>
> Report all of the following verbatim:
>
> 1. Tip SHA, commit count and tracking state for `remediation/phase3`, `docs/phase3-remediation-evidence`, and the default branch. Also what PR #2 currently reports as its head, and how that compares to the actual tip — they were last seen disagreeing (`d1ad55d` / 3 commits versus `1902e0b` / 5).
> 2. `git diff --stat` for each pair of branches. **Content difference is the only thing that matters. Commit count and history shape are noise — do not reason from them.**
> 3. For each branch: what content exists there and nowhere else.
> 4. `git merge-base --is-ancestor <default-branch> <candidate>` for each candidate, and report the exit status plainly.
>
> **Then state which single branch holds the correct end state, and why.**
>
> **If more than one branch has unique content, stop and report it as a finding.** That is an owner decision about what to keep, not a consolidation strategy.
>
> **If the default branch is an ancestor of the chosen candidate, say so loudly.** That means the consolidation is a fast-forward, B2 is one command, and most of this section is unnecessary.
>
> ### B2 — build the consolidated branch
>
> Create it from the default branch:
>
> ```
> git switch -c phase3-consolidated <default-branch>
> ```
>
> Then land the chosen branch's content, by whichever case applies:
>
> **Case 1 — default branch is an ancestor of the candidate.** Fast-forward. Nothing else to do:
>
> ```
> git merge --ff-only <candidate>
> ```
>
> **Case 2 — the branches have diverged.** Squash the candidate's content into one commit:
>
> ```
> git merge --squash <candidate>
> git commit -m "Phase 3 remediation: consolidated content from <candidate>"
> ```
>
> **Case 3 — the squash conflicts.** Do not resolve conflicts by hand. Set the tree exactly, which cannot conflict because it is an assignment rather than a merge.
>
> **`git read-tree -u --reset` overwrites tracked files in the worktree without prompting.** Run it only on a clean worktree so no tracked uncommitted change can be silently destroyed. Immediately before running it, verify the worktree is clean and stop if it is not:
>
> ```
> git status --porcelain
> ```
>
> That output must be empty. If it is not, stop: commit, stash with an explicit name, or discard each change deliberately — do not let `--reset` make that choice for you. Safer still, run the whole consolidation in a disposable worktree (`git worktree add <path> phase3-consolidated`) so a mistake destroys nothing you cannot recreate.
>
> ```
> git read-tree -u --reset <candidate>
> git commit -m "Phase 3 remediation: consolidated content from <candidate>"
> ```
>
> Report which case applied and the exact commands you ran.
>
> **Do not use `git checkout <candidate> -- .`.** It copies files in but does not delete files that exist on the default branch and not on the candidate. It produces a tree that is neither branch and it does so silently.
>
> ### B3 — prove the consolidation lost nothing
>
> ```
> git diff --stat <candidate> phase3-consolidated
> ```
>
> **This must be empty.** Empty output means the consolidated branch is content-identical to the branch it came from, whatever method got it there. Non-empty means the consolidation dropped or altered something.
>
> **If it is not empty, stop. Do not fix it by adding another commit.** Report the diff, delete `phase3-consolidated`, and start B2 again from a clean branch. A consolidation that needed a patch to be correct is a consolidation you cannot vouch for.
>
> Paste the actual output, including when it is empty.
>
> ### B4 — the pre-merge gate
>
> Run every check below **on `phase3-consolidated`**. Each must be demonstrated with output, not asserted. Report the scope of every search — how many files it covered — alongside its result.
>
> - Main suite 305 passed / 0 failed; AI-runtime invariants 22 passed / 0 failed.
> - Zero literal filesystem paths in any tracked file.
> - Zero `DS4` / `ds4-` occurrences outside the Provenance section, where the reviewed snapshot is legitimately named as design inspiration.
> - Every hook fails closed on all four negative cases — unknown value, empty value, missing file, parse error — demonstrated by execution, not by reading the source.
> - `governance/index.html` and `governance/site/*.html` reproduce byte-identically from a clean checkout via `node tools/build-governance-html.js` and `node tools/make-standalone.js`.
> - `governance/actions-and-issues.html` row count matches `governance/logs/actions-and-issues.md`.
> - No `servers/<host>/configuration.md` exists anywhere in the tree.
> - No file in the tree contains a server-mutation path reachable without a later-phase authorization.
>
> Any failure stops Part B. Report it; do not repair it inside the consolidation.
>
> ### B5 — triage the twelve CodeRabbit comments before PR #2 is abandoned
>
> Closing PR #2 makes its twelve unresolved comments disappear procedurally. It does not make any defect they found disappear. **Read all twelve for content before the PR is closed.**
>
> For each: what it says, whether it still reproduces against `phase3-consolidated`, and either the fix applied or a demonstration that it no longer reproduces. **Show the current state of the line the comment points at.** A comment is not resolved because the PR carrying it was closed.
>
> If any comment identifies a defect that still reproduces, that is a B4 failure — stop and report.
>
> ### B6 — land it, once authorized
>
> Only after the owner has read B1 through B5 and explicitly authorized the merge.
>
> 1. Push `phase3-consolidated`.
> 2. Open a PR into the default branch, or merge as the owner directed.
> 3. Report the resulting SHA on the default branch.
> 4. Close PR #2 with a comment naming the consolidated commit that supersedes it and summarizing the B5 triage.
> 5. **Do not delete any branch.** List the branches now superseded and leave them for the owner to delete. They are the only remaining copy of the history being declined, and deletion is not reversible in the way this consolidation assumes.
>
> Report the final state of every branch and of PR #2.

---

## Verification the owner should apply

- **B3's diff output is pasted and empty.** This is the single load-bearing check in the whole section. If the report says "verified content-identical" without showing the command output, it was not verified.
- B1 reports the `merge-base --is-ancestor` result. If it was a fast-forward all along, the report should say so rather than quietly performing a squash.
- B2 names which of the three cases applied. `git checkout <candidate> -- .` appears nowhere.
- B4's checks report their **scope**, not only their result. "No literal paths found" across eleven files is not the same claim as across the repository, and this project has been burned by exactly that difference.
- B5 shows the current state of each commented line. Twelve dispositions, not a summary sentence.
- No branch was deleted, and no force-push appears anywhere in the report.
