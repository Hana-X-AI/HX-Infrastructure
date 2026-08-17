# Parallel agent prompt — F-05, F-02, P2-02

**Prepared by:** Claude (claude-opus-5), cloud session · 2026-08-17 00:12 CDT
**For:** a second agent working in parallel with the Claude Code session
**Scope chosen because:** file-disjoint from Claude Code's first batch (items 1–4). Verified — intersection is empty.

---

## Owner notes — read before you paste this

**File ownership, verified.** Claude Code's items 1–4 touch exactly three files: `tests/remediation-tests-restored.ps1`, `.claude/hooks/hx-phase1-guard.ps1`, and `SERVER-REGISTRY.md`. The scope below touches none of them. The intersection is empty.

**Two risks worth knowing.**

1. **Hooks will not fire for this agent.** `hx-authority-edit-guard.ps1`, `hx-permanent-policy-guard.ps1` and `hx-phase1-guard.ps1` are Claude Code `PreToolUse` hooks. Any other tool writing to the tree bypasses them — the same gap tracked as the proposed `iss-020`. Nothing in this scope is a server-mutation pattern, so the substantive Phase 3 rule is not at risk, but the procedural guarantee does not apply to this channel. Review its authority-file edits explicitly.
2. **Two agents in one working tree race on the index.** If both run in `<repository-root>`, a `git add -A` from one can sweep the other's half-finished work — the exact hazard flagged during the LoopX handoff. **Strongly prefer giving this agent the `hx-remediation` worktree** (`<remediation-worktree>`, branch `remediation/phase3`), which already exists, is hard-locked, and is physically separate. Its work then lands on the branch PR #2 targets.

If you do run both in the same checkout, tell this agent to stage only its own named files and never use `git add -A`, `git add .`, `git stash`, `git clean`, or `git checkout .`.

**Deliberately excluded from this scope** — do not add these without re-checking overlap:

| Excluded | Why |
| --- | --- |
| `P2-06` — canonical suite path | **Direct conflict.** It renames `tests/remediation-tests-restored.ps1`, which Claude Code items 2–4 are editing |
| `F-06` / hook installer | Touches `claude-hooks/README.md`, which the workstation-path sweep also touches |
| Workstation-path sweep | Same collision as above; also carries an unresolved owner question on historical records |
| `P3-01` version-stamping | Would touch authority files including `SERVER-REGISTRY.md` |
| `P1-06` | Safe on files, but substantial and safety-adjacent — better with hooks active |

---

## The prompt

> You are working in HX-Infrastructure, a governance repository for a 15-server fleet owned by Jarvis Richardson (Agent Zero), Hana-X AI. Read this entire message before acting. Another agent is working in this repository at the same time on a different, non-overlapping set of files.
>
> ### The rule that governs everything
>
> The project is in **Phase 3 — Regroup & Reconciliation**: planning, decisions, and control-correction that **only tightens**. You may not contact a live server, invoke a remote endpoint, run any package, service, storage or network command, or run an operational commissioning path. You may not create `servers/<host>/configuration.md`. Nothing you do authorizes server implementation.
>
> ### Your file boundary — do not cross it
>
> You own exactly these paths:
>
> ```
> governance/policy/ai-runtime-acceptance-contract.md
> governance/index.html
> governance/site/                       (10 files)
> tools/page-bodies/                     (2 files)
> governance/actions-and-issues.html
> governance/logs/actions-and-issues.md
> services/docling-mcp/service.md
> ```
>
> **Another agent is concurrently editing `tests/remediation-tests-restored.ps1`, `.claude/hooks/hx-phase1-guard.ps1` and `SERVER-REGISTRY.md`. Do not read-modify-write any of those three.** You may read them for context. If a task appears to require editing one, stop and report it rather than proceeding.
>
> Stage only files you have named. Never use `git add -A`, `git add .`, `git stash`, `git clean`, or `git checkout .` — the working tree contains unrelated modified and untracked files belonging to other work.
>
> ### Task 1 — F-05: repair the corrupted AI-runtime contract
>
> `governance/policy/ai-runtime-acceptance-contract.md` contains **nine corrupted lines**. A regex intended to strip references to "DS4" deleted the matched term plus everything to the next clause boundary, so where "DS4" sat mid-sentence it took surrounding words with it. A later commit (`5a134ca`) repaired some damage elsewhere but left these.
>
> The damaged lines are approximately 100, 126, 128, 164, 170, 172, 174, 180, 181. Symptoms include an orphaned backtick opening a code span that never closes, a table row whose first cell is missing, and sentences with no subject.
>
> **The known-good pre-damage version is git blob `b7c6885132bde530dc60d7b01465ec45958fd7ef` at commit `04793ee`.** Retrieve it with `git show 04793ee:governance/policy/ai-runtime-acceptance-contract.md`.
>
> **It cannot be restored verbatim.** The original names a `ds4-deepseek` runtime profile that was deliberately removed and no longer exists — `tests/ai-runtime/profiles/` contains only `offline-fixture.json` and `vllm-qwen.json`. Restoring the old text would reintroduce a profile the repository does not have.
>
> So this is **semantic reconstruction**, not a revert. For each damaged line: read the pre-damage text to recover the intent, then write a correct sentence that does not reference DS4 or `ds4-deepseek`. Where the original documented the third profile, either drop the row or describe the remaining two — your judgement, but state which you chose and why.
>
> **Highest priority within this task:** lines 170–174 are the **provenance and MIT-attribution paragraph**. The upstream URL, the copyright holders, and the "no source code was copied" disclaimer are all mangled. That is a licence-attribution statement in a public repository, not decorative prose. Get it right and flag any judgement call you had to make.
>
> **Exit check:** no orphaned backticks; every table row has the same cell count as its header; every sentence has a subject and verb; zero occurrences of `DS4` or `ds4-` outside the Provenance section where the reviewed snapshot is legitimately named as design inspiration; and the capability table contains no row for a profile that does not exist on disk.
>
> ### Task 2 — F-02: the stale lifecycle sweep
>
> The project's phase model changed. Phase 2 now means repository consolidation (complete), Phase 3 is Regroup & Reconciliation (current), and server implementation is deferred to a later owner-authorized phase with no number assigned. A mutation guard was also hard-locked so that **no registry status value releases it**.
>
> A scanner was supposed to find every place still describing the old model. **It reads a hard-coded eleven-file allowlist**, so it reported zero while **38 stale statements survived outside that window**. The live surfaces in your scope:
>
> | File | Says | Should say |
> | --- | --- | --- |
> | `governance/index.html` ~L359 | "Phase 1 is complete; Phase 2 is open." | Phase 2 consolidation complete; Phase 3 Regroup current |
> | `governance/site/index.html` ~L365 | same | same |
> | `tools/page-bodies/index-body.html` ~L191 | same — **this is the generator source** | same |
> | `governance/index.html` ~L176, `site/` ~L182, `page-bodies/` ~L8 | "server implementation is Phase 3" | implementation is a later owner-authorized phase; Phase 3 is Regroup |
> | `governance/actions-and-issues.html` ~L366, `site/` ~L372 | published closeout still narrates the guard release | guard is hard-locked for every registry status |
> | `services/docling-mcp/service.md` ~L283 | "server implementation is Phase 3 and has not started" | as above |
>
> **`governance/index.html` and `governance/site/*.html` are generated** from `tools/page-bodies/` by `node tools/build-governance-html.js` and `node tools/make-standalone.js`. **Fix the generator source first**, then regenerate — do not hand-edit generated output and leave the source stale, or this recurs on the next build.
>
> Line numbers are approximate; locate by content. Do a repo-wide search within your owned paths rather than trusting the list — treat 38 as a floor, not a target.
>
> **Historical reports are different.** A dated report describing what was true when it was written is correct as history. Those take a dated supersession banner, not a rewrite — the pattern already used elsewhere in this repository. Only current-state and published surfaces get corrected.
>
> ### Task 3 — P2-02: tracker reconciliation
>
> In `governance/logs/actions-and-issues.md`, reconcile the tracker and regenerate the human-readable pages so `governance/actions-and-issues.html` and `governance/site/actions-and-issues.html` match the Markdown source. The table currently has 37 rows.
>
> Note the table uses **escaped pipes** (`\|`) inside code spans — a naive column split will mis-parse rows `iss-004`, `act-003` and `act-004`. That is correct Markdown, not a defect; do not "fix" it.
>
> **Two rows require an owner ruling and are not yours to decide:** the status of `act-015` and `iss-016`. Leave both as they are and list them in your report as blocked.
>
> ### How to work
>
> - **Read `governance/documentation-standards.html` before creating or renaming any file.** It is the naming authority and it is enforced: `governance/` uses `lower-kebab-case.md`; reports use `<author>_<YYYY-MM-DD>[_<HHMMSS>]_<lower-kebab-slug>`; no spaces, no non-ASCII, hyphen as word separator, underscore reserved as the report field separator.
> - **Never put a real filesystem path in a committed file.** Use `<repository-root>`, `<remediation-worktree>` or `<main-checkout>` — the convention already in use in this repository. A reviewer has already rejected a document for containing a literal user-profile path.
> - **State the scope of every check you run.** If a search covered eleven files, say eleven files. Several gates in this project have gone green on a scope narrower than the claim they supported; that is the failure mode being corrected.
> - **Assertions are not evidence.** If you did not run a check, say you did not run it. "No server contacted" is an attestation — label it as one.
> - **Preserve line endings and encoding.** Files are UTF-8, some with a BOM. Do not normalise them.
> - Commit only files you named. One commit per task, with a message naming the finding it closes.
>
> ### Report back
>
> For each of the three tasks: what you changed, file by file; what you verified and how; what you could not resolve and why; and anything you found that contradicts this briefing. **If the repository disagrees with anything written here, the repository wins** — say so plainly and describe the difference.
>
> Do not begin editing until you have confirmed which branch and checkout you are in, and reported the current `git status`.

---

## Verification the owner should apply on return

- `git diff --stat` shows **only** the seven owned paths — nothing from Claude Code's three files.
- F-05: zero `DS4`/`ds4-` occurrences outside the Provenance section; the attribution paragraph reads as a coherent licence statement; no capability-table row for a non-existent profile.
- F-02: the generator source under `tools/page-bodies/` was fixed **before** regeneration, and `governance/index.html` matches a fresh `node tools/build-governance-html.js` run.
- P2-02: `governance/actions-and-issues.html` row count matches the 37 rows in the Markdown; `act-015` and `iss-016` untouched.
- No literal filesystem path in any changed file.
