# kimi — complete Phase 3 handoff (v3, consolidated)

**Prepared by:** Claude (claude-opus-5), cloud session · 2026-08-17 01:18 CDT
**For:** kimi-k3, taking over all remaining Phase 3 remediation work
**Supersedes:** `claude_2026-08-17_005156_parallel-agent-prompt-p1-06.md`, `claude_2026-08-17_010430_kimi-full-remaining-backlog-and-consolidation.md`, and `claude_2026-08-17_011245_kimi-full-remaining-backlog-and-consolidation-v2.md`. This is the single complete document — Parts A, B and C in one prompt. Paste everything between the two `═══` rules.

---

## Owner notes — for you, not for kimi

**Sequencing is the whole risk.** Claude Code must commit and stop before kimi starts task 2 onward. Most of this backlog was withheld from kimi purely for file collision; once cc is out of the tree, kimi can own every file. If cc is still editing when kimi starts P2-06, you get the interleaved-hunk problem that already blocked P2-02 — this time on a file rename, which is harder to unpick.

**Part B declines the history problem rather than solving it.** Your branches carry duplicate-content commits under different SHAs. Rather than reconcile them, kimi lands the correct file state on main as one commit and leaves the old branches in place. This is a real loss, not a harmless one: the commit-level provenance of the remediation is destroyed, and `git log` can no longer trace which source commit produced which line of the consolidated state. That is an **unresolved governance risk**, not a settled one.

Because the risk is real, Part B requires two things before it can be called complete:

- **A provenance mapping.** kimi records, in its report, a mapping from each source branch's tip and meaningful intermediate commits to the single consolidated commit — so the discarded history is at least addressable from the record that replaces it.
- **Explicit owner acceptance.** The owner must accept the provenance loss in writing before the consolidation is treated as done. Acceptance acknowledges the risk; it does **not** mark it resolved. The risk stays open until the owner separately rules it closed, and the dated reports under `governance/Phase -3-Regroup/reports/` remain the load-bearing audit trail in the meantime.

**B3 is the load-bearing check.** `git diff --stat <candidate> phase3-consolidated` returning empty proves the consolidation is content-identical to its source regardless of method. If a report claims content-identical without pasting that output, it was not verified.

**B1 may end the exercise.** If main is an ancestor of the good branch it is a fast-forward and Part B is one command. That check is first because it is cheap.

**Three things I could not verify** and task 0 makes kimi establish: the content of finding F-04, whether F-06 was actually closed by cc's item 8, and which checkout kimi is in.

---

═══════════════════════ PASTE FROM HERE ═══════════════════════

You are working in HX-Infrastructure, a governance repository for a 15-server fleet owned by Jarvis Richardson (Agent Zero), Hana-X AI. Read this entire message before acting.

You are taking over **all** remaining Phase 3 remediation work. The Claude Code session that was working alongside you is committing its work and stopping. After it stops, no other agent is writing to this repository — the file-boundary restrictions you were operating under are lifted, but only once you have confirmed cc has actually committed and stopped, which is task 0.

## The rule that governs everything

The project is in **Phase 3 — Regroup & Reconciliation**: planning, decisions, and control-correction that **only tightens**. You may not contact a live server, invoke a remote endpoint, run any package, service, storage or network command, or run an operational commissioning path. You may not create `servers/<host>/configuration.md`. Nothing you do authorizes server implementation. This holds through every task below, including the branch work.

## Standing rules for all tasks

- **Stage only files you name.** Never `git add -A`, `git add .`, `git stash`, `git clean`, or `git checkout .`.
- **Never push, amend, rebase, or force anything** until Part B, and Part B does not start without explicit owner authorization.
- **Read `governance/documentation-standards.html` before creating or renaming any file.** `governance/` uses `lower-kebab-case.md`; reports use `<author>_<YYYY-MM-DD>[_<HHMMSS>]_<lower-kebab-slug>`; scripts are lower-kebab-case; no spaces, no non-ASCII; hyphen separates words, underscore is the report field separator.
- **Never put a real filesystem path in a committed file.** Use `<repository-root>`, `<remediation-worktree>`, `<main-checkout>`.
- **State the scope of every check.** If a search covered eleven files, say eleven files. Multiple gates in this project have gone green on a scope narrower than the claim they supported. That is the failure mode being corrected.
- **Assertions are not evidence.** If you did not run a check, say so. "No server contacted" is an attestation — label it as one.
- **Do not update a report to match a conclusion.** If a task is not done, the report says not done.
- **Suite baselines: 305 passed / 0 failed (main suite), 22 passed / 0 failed (AI-runtime invariants).** Any briefing that says 160 is four revisions stale. If a baseline run does not match, stop and report — it means the tree moved under you.
- Preserve line endings and encoding. Files are UTF-8, some with a BOM. Do not normalise them.

═══════════════════════════════════════════════════════════════

# PART A — the remaining backlog

## Task 0 — establish ground truth (before anything else)

Report all of the following verbatim, then stop and wait if any of it surprises you:

1. `git status --porcelain`, `git branch -vv`, `git log --oneline -10`, and which checkout or worktree you are in.
2. `git log --oneline` for each of `remediation/phase3`, `docs/phase3-remediation-evidence`, and the default branch, plus each one's remote tracking state.
3. **Confirm Claude Code has committed.** Its work covered a verification gate, guard fail-closed changes to `.claude/hooks/hx-phase1-guard.ps1`, Group C corrections, a hook installer, and an F-05 reconstruction of `governance/policy/ai-runtime-acceptance-contract.md`. If any of that still shows as uncommitted in `git status`, **stop and report** — do not commit another agent's work.
4. **Read finding F-04 from its source** in the findings register. Do not rely on any summary, including this one. Report what it says, whether it is closed, and what closing it would require. It was silently dropped from the coverage lists and never worked; you are picking it up cold.
5. **Verify whether F-06 is actually closed** by cc's item 8 work — the `claude-hooks/apply-hooks.ps1` pattern defect, a regex covering five hook names against seven commands. Verify by reading the file, not by reading a report.

## Task 1 — P1-06: quarantine the DS4-era runtime gates — ALREADY DONE, verified clean

**This task is complete and closed by `kimi-k3_2026-08-17_011739_p1-06-runtime-gate-quarantine.md`. Do not re-execute it.** The findings below are recorded so the rest of this handoff stays consistent with what the tree actually contains.

The inventory established, against the current tree:

- **No live-contact path exists.** None of the four gate scripts (`hx-capacity-gate.ps1`, `hx-gpu-fit.ps1`, `hx-workload-commission.ps1`, `hx-runtime-acceptance.ps1`) executes an install, download, service, network, or host command. The single nominal live path — `hx-runtime-acceptance.ps1` reading a profile's `base_url_env` — terminates in `live execution not implemented in this pass` and issues no request. The scripts are inert in Phase 3 by construction, so **no fail-closed phase guard was added** (owner ruling: repo wins; guarding an absent capability would be over-engineering).
- **No DS4 or third-profile assumption exists.** `tests/ai-runtime/` is `ds4`-clean across all files; `profiles/` holds exactly `offline-fixture.json` and `vllm-qwen.json`; no script, fixture, workload, test, or capability table assumes a profile not on disk.

**The only checks from this task that still apply downstream** are the suite baselines, which Part B's pre-merge gate (B4) already runs: main suite 305/0 and AI-runtime invariants 22/0. There is no guard-enforcement, guard-execution, or before/after proof to perform here, because no guard was needed and no file changed.

## Task 2 — P2-02: tracker reconciliation

Your earlier analysis and your decision to hold were both correct. Once cc's rows are committed, your tracker diff should shrink to only your own edits — **verify that it has** before committing.

Reconcile `governance/logs/actions-and-issues.md` and regenerate `governance/actions-and-issues.html` and `governance/site/actions-and-issues.html` so they match the Markdown source.

The table uses **escaped pipes** (`\|`) inside code spans — a naive column split mis-parses `iss-004`, `act-003`, `act-004`. That is correct Markdown, not a defect; do not "fix" it.

**`act-015` and `iss-016` are owner-ruling items. Leave both. List them as blocked.**

## Task 3 — repair the reproducibility defect in `0d3e7b1`

Your F-02 commit contains `governance/index.html` and `governance/site/index.html` regenerated using your reverted `tools/build-governance-html.js` — but the generator revert was not committed. As it stands, a clean checkout of `0d3e7b1` followed by `node tools/build-governance-html.js` produces different nav order than the committed HTML. That is the same generated-vs-source desync F-02 exists to fix.

**First, prove or disprove it.** Check out `0d3e7b1` into a scratch location, run the generator, diff the output against the committed `governance/index.html`, and **report the actual diff**. If there is no diff, say so and close this task — this briefing may be wrong.

**If there is a diff, do not fix it yet.** Run `git log --format='%h %an %ad %s' -- tools/build-governance-html.js` and report it. Somebody reordered the `navHtml()` items array deliberately and you reverted it as out-of-scope drift. Whether that revert stands is an owner ruling. Report and wait.

## Task 4 — item 4 / F-04

Execute whatever task 0.4 established F-04 requires. If it needs an owner ruling or touches something outside a safe scope, report rather than proceed.

## Task 5 — P2-06: canonical suite path

Rename `tests/remediation-tests-restored.ps1` to the canonical path and update every reference. Use `git mv` so history follows.

Then grep the **entire repository** for the old filename — CI configuration, task runners, hook scripts, documentation — and report **the number of files searched** alongside the number of references found. A rename leaving one stale reference in a runner is worse than no rename.

Re-run the suite; it must still be **305/0** after the rename. Report both runs.

## Task 6 — the workstation-path sweep

Remove literal filesystem paths from committed files, replacing them with `<repository-root>`, `<remediation-worktree>`, `<main-checkout>`.

**Gated on an owner ruling** (Part C item 4): whether dated historical reports get rewritten or get a dated supersession banner. A dated report describing what was true when written is correct as history — do not rewrite history without the ruling. You may sweep **current-state and published surfaces** now, and stage the historical set as a separate reported list awaiting the ruling.

## Task 7 — P3-01: version-stamping

Version-stamp the authority files, including `SERVER-REGISTRY.md`. The guard `hx-authority-edit-guard.ps1` governs edits to these — read it before touching anything it covers. **If it refuses an edit, that refusal is correct.** Report it; do not work around it.

## Task 8 — the twelve CodeRabbit comments on PR #2

Read all twelve. For each, report what it says, whether it still reproduces against the current tree, and either the fix applied or why it does not apply. Several may already be resolved by cc's or your own work — a comment that no longer reproduces is resolved, but say **why** it no longer reproduces.

**Do not resolve a comment by asserting it is fixed. Show the current state of the line it points at.**

═══════════════════════════════════════════════════════════════

# PART B — consolidation to main

**Do not begin Part B until the owner explicitly authorizes it.** Part A must be complete, both suites green (305/0 and 22/0), and the Part C rulings issued.

You are consolidating **content**, not history. The branches carry duplicate-content commits under different SHAs — the same changes committed more than once with different hashes. Git cannot recognise those as identical, so reconciling history across them produces conflicts on identical content and can apply the same change twice. **We are declining that problem, not solving it.** The end state of the files is what lands; the commit graph that produced it does not.

**Never force-push. Never rewrite a published branch. Everything below is additive until B6.**

## B1 — find the source of truth, and check whether this is already trivial

Report all of the following verbatim:

1. Tip SHA, commit count and tracking state for `remediation/phase3`, `docs/phase3-remediation-evidence`, and the default branch. Also what PR #2 reports as its head and how that compares to the actual tip — they were last seen disagreeing (`d1ad55d` / 3 commits versus `1902e0b` / 5).
2. `git diff --stat` for each pair of branches. **Content difference is the only thing that matters. Commit count and history shape are noise — do not reason from them.**
3. For each branch: what content exists there and nowhere else.
4. `git merge-base --is-ancestor <default-branch> <candidate>` for each candidate; report the exit status plainly.

**Then state which single branch holds the correct end state, and why.**

**If more than one branch has unique content, stop and report it as a finding.** That is an owner decision about what to keep, not a consolidation strategy.

**If the default branch is an ancestor of the chosen candidate, say so loudly** — the consolidation is a fast-forward, B2 is one command, and most of this section is unnecessary.

## B2 — build the consolidated branch

```
git switch -c phase3-consolidated <default-branch>
```

Then land the chosen branch's content by whichever case applies:

**Case 1 — default branch is an ancestor of the candidate.** Fast-forward:

```
git merge --ff-only <candidate>
```

**Case 2 — the branches have diverged.** Squash into one commit:

```
git merge --squash <candidate>
git commit -m "Phase 3 remediation: consolidated content from <candidate>"
```

**Case 3 — the squash conflicts.** Do not resolve conflicts by hand. Set the tree exactly — this cannot conflict, because it is an assignment rather than a merge.

**`git read-tree -u --reset` overwrites tracked files in the worktree without prompting.** Run it only on a clean worktree so no tracked uncommitted change is silently destroyed. Immediately before running it, verify the worktree is clean and stop if it is not:

```
git status --porcelain
```

That output must be empty. If it is not, stop: commit, stash with an explicit name, or discard each change deliberately — do not let `--reset` make that choice for you. Safer still, run the whole consolidation in a disposable worktree (`git worktree add <path> phase3-consolidated`) so a mistake destroys nothing you cannot recreate.

```
git read-tree -u --reset <candidate>
git commit -m "Phase 3 remediation: consolidated content from <candidate>"
```

Report which case applied and the exact commands you ran.

**Do not use `git checkout <candidate> -- .`.** It copies files in but does not delete files that exist on the default branch and not on the candidate. It silently produces a tree that is neither branch.

## B3 — prove the consolidation lost nothing

```
git diff --stat <candidate> phase3-consolidated
```

**This must be empty.** Empty means the consolidated branch is content-identical to its source, whatever method got it there. Non-empty means the consolidation dropped or altered something.

**If it is not empty, stop. Do not fix it by adding another commit.** Report the diff, delete `phase3-consolidated`, and start B2 again from a clean branch. A consolidation that needed a patch to be correct is one you cannot vouch for.

Paste the actual output, including when it is empty.

## B4 — the pre-merge gate

Run every check **on `phase3-consolidated`**. Each demonstrated with output, not asserted. Report the **scope** of every search alongside its result.

- Main suite 305 passed / 0 failed; AI-runtime invariants 22 passed / 0 failed. Run both from the repository root (the working directory is the repository root); the invariants suite is invoked by its repository-relative path `tests/ai-runtime/hx-runtime-invariants.tests.ps1`, e.g. `powershell -NoProfile -ExecutionPolicy Bypass -File tests/ai-runtime/hx-runtime-invariants.tests.ps1`.
- Zero literal filesystem paths in any tracked file.
- Zero `DS4` / `ds4-` occurrences in the scannable source set. That set is the repository's **tracked text, code, and configuration files**: `*.ps1`, `*.py`, `*.js`, `*.json`, `*.md`, `*.yaml`, `*.yml`, `*.toml`, `*.txt`, and CI/hook configuration. **Excluded from the scan** (these produced only false positives or legitimate history in the P1-06 sweep): binary and media files (`*.png`, `*.mp4`, `*.ttf`, `*.pdf`, `*.gif`, `*.jpg`, lockfiles, `cacert.pem`, `go.sum`, `package-lock.json`), the vendored third-party mirrors under `governance/operations/*/...`, and dated historical governance text that legitimately records the DS4 removal (remediation plans, reports, the tracker). The one permitted live mention is the Provenance section naming the reviewed snapshot as design inspiration. The scanner enforces zero matches against that scoped set, not against the whole tree.
- Every hook fails closed on all four negative cases — unknown value, empty value, missing file, parse error — demonstrated by execution, not by reading source.
- `governance/index.html` and `governance/site/*.html` reproduce byte-identically from a clean checkout via `node tools/build-governance-html.js` and `node tools/make-standalone.js`.
- `governance/actions-and-issues.html` row count matches `governance/logs/actions-and-issues.md`.
- No `servers/<host>/configuration.md` exists anywhere in the tree.
- No file contains a server-mutation path reachable without a later-phase authorization.

Any failure stops Part B. Report it; do not repair it inside the consolidation.

## B5 — triage the twelve CodeRabbit comments before PR #2 is abandoned

Closing PR #2 makes its comments disappear procedurally. It does not make any defect they found disappear. **Read all twelve for content before the PR is closed.**

For each: what it says, whether it still reproduces against `phase3-consolidated`, and either the fix applied or a demonstration that it no longer reproduces. **Show the current state of the line the comment points at.** A comment is not resolved because the PR carrying it was closed.

If any comment identifies a defect that still reproduces, that is a B4 failure — stop and report.

## B6 — land it, once authorized

Only after the owner has read B1 through B5 and explicitly authorized the merge.

1. Push `phase3-consolidated`.
2. Open a PR into the default branch, or merge as the owner directed.
3. Report the resulting SHA on the default branch.
4. Close PR #2 with a comment naming the consolidated commit that supersedes it and summarizing the B5 triage.
5. **Do not delete any branch.** List the branches now superseded and leave them for the owner. They are the only remaining copy of the history being declined, and deletion is not reversible in the way this consolidation assumes.

Report the final state of every branch and of PR #2.

═══════════════════════════════════════════════════════════════

# PART C — owner rulings you must not decide yourself

Collect these into one list and put it **at the top** of your first report. Do not proceed on any task that depends on one.

1. **Source of truth branch** — which of `remediation/phase3` and `docs/phase3-remediation-evidence` survives, and what happens to the other. Gates all of Part B.
2. **The `navHtml()` reorder** — does your revert stand, or was the reorder a deliberate fix? Gates task 3.
3. **`act-015` and `iss-016` status.** Gates the close of task 2.
4. **Historical reports** — rewritten, or dated supersession banner? Gates half of task 6.
5. **DS4 redaction reversibility** — raised in cc's reports, unresolved.
6. **The thirteen `pre-work-results.md` files** and **the LangGraph branch question** — both raised in cc's reports, both unresolved.

═══════════════════════════════════════════════════════════════

# Report back

One report per part, written to `governance/Phase -3-Regroup/reports/` using the naming standard.

Every report covers: what you changed file by file; every check you ran with its **actual output** and its **scope**; before/after suite counts; what you could not resolve and why; the commit hash for each piece of work; and **anything you found that contradicts this briefing**.

**If the repository disagrees with anything written here, the repository wins.** Say so plainly and describe the difference.

Do not begin editing until you have completed task 0 and reported it.

═══════════════════════ PASTE TO HERE ═══════════════════════

---

## Verification the owner should apply

**Part A**

- Task 0 was reported **before** any edit. If the first thing in the report is a change rather than a `git status`, the sequencing was skipped.
- Every task has a commit hash. Work with no hash is work that can still evaporate.
- Task 1's guard tests show the **negative** cases executing, not only the happy path.
- Task 3 reports an actual diff — including the possibility that the briefing was wrong and there is none.
- Task 5 reports the number of files its rename-reference grep covered, not just the hits.
- Task 8 gives twelve dispositions with line states, not a summary sentence.

**Part B**

- **B3's diff output is pasted and empty.** This is the single load-bearing check in the section. "Verified content-identical" without the command output means it was not verified.
- B1 reports the `merge-base --is-ancestor` result. If it was a fast-forward all along, the report says so rather than quietly squashing.
- B2 names which of the three cases applied. `git checkout <candidate> -- .` appears nowhere.
- B4's checks report their **scope**, not only their result.
- No branch was deleted; no force-push appears anywhere.

**Part C**

- The rulings list is at the top of the first report, not buried. Any task that proceeded past a gate without its ruling is the escalation.
