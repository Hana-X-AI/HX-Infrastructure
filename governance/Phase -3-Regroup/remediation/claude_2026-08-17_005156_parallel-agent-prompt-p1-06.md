# Parallel agent prompt — P1-06 (DS4-era runtime-gate quarantine)

**Prepared by:** Claude (claude-opus-5), cloud session · 2026-08-17 00:51 CDT
**For:** kimi-k3, working in parallel with the Claude Code session
**Supersedes for scope purposes:** `claude_2026-08-17_001233_parallel-agent-prompt-f05-f02-p202.md` — F-05 and F-02 were completed by Claude Code as its items 11 and 9 while that prompt was in flight. P2-02 remains open but is now a live collision (see below).

---

## Owner notes — read before you paste this

**Why P1-06.** It is the largest remaining untouched work item in the Phase 3 backlog, and it is the only large one that is file-disjoint from everything Claude Code has modified across its five reports. I verified the file list on the staged tree:

| P1-06 path | Present | Touched by cc? |
| --- | --- | --- |
| `tests/ai-runtime/hx-capacity-gate.ps1` | yes | no |
| `tests/ai-runtime/hx-gpu-fit.ps1` | yes | no |
| `tests/ai-runtime/hx-workload-commission.ps1` | yes | no |
| `tests/ai-runtime/hx-runtime-acceptance.ps1` | yes | no |
| `tests/ai-runtime/hx-runtime-invariants.tests.ps1` | yes | no |
| `tests/ai-runtime/profiles/` | yes | no |
| `tests/ai-runtime/workloads/` | yes | no |
| `tests/ai-runtime/fixtures/` | yes | no |
| `tests/ai-runtime/README.md` | yes | **YES — cc edited this in item 11** |

The intersection is exactly one file. The prompt below tells kimi not to touch it.

**One live collision to resolve before you paste.** Both Claude Code and kimi have `governance/logs/actions-and-issues.md` open. That file is the tracker every agent appends to, and both are read-modify-writing it. Decide who owns it, or the second writer silently reverts the first. The prompt below assigns kimi an **append-only** discipline on that file and tells it to write its findings to a separate report if the file has changed under it.

**What I could not verify.** I have not seen kimi's working tree. The file list above comes from the staged snapshot of the main checkout. If kimi is in a worktree, confirm its branch before it starts.

---

## The prompt

> You are working in HX-Infrastructure, a governance repository for a 15-server fleet owned by Jarvis Richardson (Agent Zero), Hana-X AI. Read this entire message before acting. A Claude Code session is working in this repository at the same time on a different set of files.
>
> ### The rule that governs everything
>
> The project is in **Phase 3 — Regroup & Reconciliation**: planning, decisions, and control-correction that **only tightens**. You may not contact a live server, invoke a remote endpoint, run any package, service, storage or network command, or run an operational commissioning path. You may not create `servers/<host>/configuration.md`. Nothing you do authorizes server implementation.
>
> This matters more than usual for this task. The scripts you are working on are *commissioning* scripts. Several of them are written to reach out and touch hardware. **Your job is to make sure they cannot run in Phase 3 — not to run them.** If at any point you find yourself about to execute `hx-workload-commission.ps1` or `hx-capacity-gate.ps1` against anything, stop.
>
> ### Your file boundary — do not cross it
>
> You own exactly this subtree:
>
> ```
> tests/ai-runtime/hx-capacity-gate.ps1
> tests/ai-runtime/hx-gpu-fit.ps1
> tests/ai-runtime/hx-workload-commission.ps1
> tests/ai-runtime/hx-runtime-acceptance.ps1
> tests/ai-runtime/hx-runtime-invariants.tests.ps1
> tests/ai-runtime/profiles/
> tests/ai-runtime/workloads/
> tests/ai-runtime/fixtures/
> ```
>
> **`tests/ai-runtime/README.md` is NOT yours.** The Claude Code session edited it during its F-05 contract reconstruction. Read it for context; do not write to it. If your work requires a README change, put the proposed text in your report and let the owner apply it.
>
> **Also not yours:** `tests/remediation-tests-restored.ps1`, `.claude/hooks/*.ps1`, `SERVER-REGISTRY.md`, `governance/policy/ai-runtime-acceptance-contract.md`. All were rewritten by Claude Code in the last several hours.
>
> **`governance/logs/actions-and-issues.md` is shared and Claude Code is also editing it right now.** Treat it as append-only: read it immediately before you write, append your rows at the end of the table, write, and re-read to confirm your rows survived. If the file changed under you, do not re-apply — put your rows in your report and say so.
>
> **Permitted outputs outside the owned subtree.** Two writes outside `tests/ai-runtime/` are expected and allowed; they are exceptions to the boundary, not crossings:
>
> - **The report** — exactly one new file under `governance/Phase -3-Regroup/reports/`, named per the standard below. This is the deliverable and is always permitted.
> - **The tracker row** — the append-only update to `governance/logs/actions-and-issues.md` described above.
>
> Every other path outside `tests/ai-runtime/` remains out of bounds. These two exceptions do not extend to any other file under `governance/`.
>
> Stage only files you have named. Never use `git add -A`, `git add .`, `git stash`, `git clean`, or `git checkout .` — the working tree contains a large volume of uncommitted work belonging to another agent.
>
> ### Task — P1-06: quarantine the DS4-era runtime gates
>
> `tests/ai-runtime/` contains a suite of runtime capacity and commissioning gates written during the DS4 era, before the current phase model existed. They encode assumptions that are now wrong in three distinct ways, and they are reachable from the test tree, which means a future contributor can run them by accident.
>
> Work the three in order.
>
> **1. Establish what is actually there.** Before changing anything, produce an inventory: for each of the eight owned paths, what it does, what it invokes, whether it is referenced by any other file in the repository, and whether it can currently be executed. Grep the whole repository for references to each filename — including CI config, task runners, and documentation — and report the reference graph. **Report the scope of that grep**: how many files it covered. Do not say "no references" if you searched one directory.
>
> Expect surprises here. Report what you find before you decide what to change; if the inventory contradicts anything below, the repository wins.
>
> **2. Remove the live-contact reachability.** Any path in these scripts that can reach hardware, a remote host, a package manager, a service manager, or the network must be made unreachable in Phase 3. The preferred mechanism is a **fail-closed phase guard at the top of each entry-point script** — the script refuses to run and exits non-zero unless an explicit later-phase authorization is present, and the *absence* or *malformation* of that authorization is a refusal, not a pass.
>
> Read `.claude/hooks/hx-phase1-guard.ps1` first. It was just rewritten to be fail-closed and it is the pattern to follow. The specific defect it was fixed for: under `Set-StrictMode -Version Latest`, an unguarded read of a missing property throws, and a `catch` that returned "allow" turned every error into a silent pass. Do not reproduce that. **Every error path exits non-zero.**
>
> Match its refusal semantics exactly: unknown value → refuse, empty value → refuse, missing file → refuse, parse error → refuse.
>
> **3. Strip the DS4 profile assumptions.** `profiles/` contains only `offline-fixture.json` and `vllm-qwen.json`. The `ds4-deepseek` profile was deliberately removed. Any script, fixture, workload definition or test that still assumes a third profile exists is broken and must be corrected — not by re-adding the profile, but by reducing to the two that exist. Same for any capability matrix or table with a row for a profile that is not on disk.
>
> ### Prove it
>
> Assertions are not evidence. For each of the three parts, run a check and report its output.
>
> - **Guards:** for each entry-point script, execute it in a way that exercises the guard and show it refusing. Test the malformed and missing cases explicitly, not just the happy path. A guard tested only against a well-formed input has not been tested.
> - **Profiles:** show the count of files on disk in `profiles/`, and show a repository-wide search for `ds4` (case-insensitive) with its result and its scope.
> - **Suite:** run `tests/ai-runtime/hx-runtime-invariants.tests.ps1` and report the pass/fail counts before and after your change. **The current expected baseline is 22 passed / 0 failed** — Claude Code established that in its item 11 report. If your "before" run does not show 22/0, say so immediately and stop; it means the tree moved under you.
> - **Cross-check:** the main suite is at **305 passed / 0 failed** as of Claude Code's item 11. If you touch anything that suite covers, re-run it and report. Do not use the number 160 — that figure appears in older briefings and is four revisions stale.
>
> ### How to work
>
> - **Read `governance/documentation-standards.html` before creating or renaming any file.** It is the naming authority and it is enforced: `governance/` uses `lower-kebab-case.md`; reports use `<author>_<YYYY-MM-DD>[_<HHMMSS>]_<lower-kebab-slug>`; scripts are lower-kebab-case; no spaces, no non-ASCII; hyphen separates words, underscore is reserved as the report field separator.
> - **Never put a real filesystem path in a committed file.** Use `<repository-root>`, `<remediation-worktree>` or `<main-checkout>`. A reviewer has already rejected a document for containing a literal user-profile path.
> - **State the scope of every check you run.** If a search covered eleven files, say eleven files. Several gates in this project have gone green on a scope narrower than the claim they supported; that is the exact failure mode being corrected.
> - **Do not update the status document instead of doing the work.** The recurring failure in this repository is that the artifact reporting the work is easier to change than the work. If a task is not done, the report says not done.
> - **Preserve line endings and encoding.** Files are UTF-8, some with a BOM. Do not normalise them.
> - Commit only files you named. One commit per part, with a message naming what it closes.
>
> ### Report back
>
> Write your report to `governance/Phase -3-Regroup/reports/` using the naming standard above.
>
> Cover: the inventory and reference graph from part 1 with its scope; what you changed file by file; every check you ran with its actual output; the before/after suite counts; what you could not resolve and why; and **anything you found that contradicts this briefing**. If the repository disagrees with anything written here, the repository wins — say so plainly and describe the difference.
>
> Do not begin editing until you have confirmed which branch and checkout you are in, and reported the current `git status`.

---

## Verification the owner should apply on return

- Scope the diff check to what the agent was permitted to touch — an unscoped `git diff --stat` flags the legitimate report and tracker row as violations. Use path-scoped checks instead:
  - `git diff --stat -- tests/ai-runtime/` shows changes **only** under `tests/ai-runtime/`, and **not** `tests/ai-runtime/README.md`.
  - `git status --porcelain -- "governance/Phase -3-Regroup/reports/"` shows at most the one new report file this task produces.
  - `git diff -- governance/logs/actions-and-issues.md` shows only appended rows, none of cc's existing rows modified or removed.
  - No other path outside `tests/ai-runtime/`, the one report file, and the tracker appears in the agent's commits.
- Every entry-point script refuses on all four negative cases (unknown, empty, missing, malformed) with a non-zero exit, demonstrated by output, not asserted.
- `profiles/` still contains exactly two files; repo-wide case-insensitive `ds4` search result reported with its scope.
- `hx-runtime-invariants.tests.ps1` before-run was 22/0. If the report does not state the before-run, the after-run means nothing.
- No literal filesystem path in any changed file.
- kimi's rows in `governance/logs/actions-and-issues.md` are present *and* Claude Code's rows are still present. If either set is missing, one agent overwrote the other.
