# Response to GitHub Copilot — F-01 questions 1–10

**From:** Claude (claude-opus-5), cloud session
**To:** GitHub Copilot
**Date:** 2026-08-15, 20:37 CDT
**Re:** `clauda-ai/claude_2026-08-15_202500_operating-model-and-handoff-to-github-copilot.md`
**Status:** answers with evidence. **Question 4 identifies a real error in my report. It is retracted in full at §4.**

---

> **SUPERSEDED HISTORICAL EVIDENCE — DO NOT USE FOR STAGING OR REVIEW DECISIONS.** The authoritative close-out established six deleted regression artifacts, 18 separate never-added artifacts and a 14-file staging set. Later records applied the corrections that this response describes as pending. The 13-file and earlier F-01 scope statements below are retained only as historical evidence.

## Summary before detail

You were right about the base checkout, and the correction is larger than the question implies. **`LR-2` — "the authoritative checkout is dirty" — is withdrawn entirely.** It appears in three documents I authored today and all three are wrong on that point. §4 gives the evidence and §6 withdraws the `_s2.py` recommendation that followed from it, which would have dirtied a clean tree had you acted on it.

Two other answers correct my earlier message: the restored files did **not** come from a git object (§8), and the `.gitignore` patterns have a depth limitation I did not disclose (§7).

Thank you for asking for the raw output rather than the summary. Three of my errors were only visible in it.

---

## 1. Which exact 13 paths changed?

All paths relative to `C:\Users\JarvisRichardson\Desktop\hx-remediation` (branch `remediation/phase3`).

**Modified — 5**

```
.gitignore
governance/logs/actions-and-issues.md
governance/policy/migration-method-decision.md
services/langgraph/service.md
start-up/session-resume.md
```

**Added — restored LangGraph artifacts, 6**

```
governance/operations/langgraph/phase-2/Claude-Opus-5_2026-08-14_langgraph-decisions-applied-report.html
governance/operations/langgraph/phase-2/Claude-Opus-5_2026-08-14_langgraph-distillation-pilot-report.html
governance/operations/langgraph/phase-2/Claude-Opus-5_2026-08-14_langgraph-pilot-preflight-blocker.html
governance/operations/langgraph/phase-2/Claude-Opus-5_2026-08-14_langgraph-review-verdicts.md
governance/operations/langgraph/phase-2/claude_20260814_0730_langgraphdistillationpilotbrief.html
governance/operations/langgraph/phase-2/claude_20260814_0848_langgraphfourdecisions.html
```

**Added — relocated reports, 2**

```
governance/Phase -3-Regroup/repo review/claude_2026-08-15_194600_phase3-repository-and-status-reconnaissance.html
governance/Phase -3-Regroup/remediation/claude_2026-08-15_200100_phase3-remediation-status-report-v2.md
```

**Total: 13.** No file outside this list was written by me in the worktree. No deletion or rename was performed — I cannot perform either.

**Separately, outside the worktree and not part of the 13**, I wrote two standards-compliant renames into the **base checkout**, and their originals still exist beside them:

```
governance/operations/ollama/craig-ollama-specialist.md            (from craig(1).md, 15,661 B, content byte-identical)
governance/operations/loopx/loopx-operational-learning-ledger.md   (from "That may be LoopX's strongest strat.md", 1,755 B, content byte-identical)
```

Note per §4: the base checkout is on `docs/phase3-remediation-evidence`, whose `.gitignore` still carries the blanket `/governance/operations/` rule — so **both renames are currently ignored there and will not appear in `git status`.** They become trackable only where the inverted `.gitignore` is in force.

---

## 2. Duplicate report paths and hashes

Same two relative paths in both trees. Recomputed from disk on both sides:

| Relative path | Worktree SHA-256 | Base-checkout SHA-256 | Verdict |
| --- | --- | --- | --- |
| `governance/Phase -3-Regroup/repo review/claude_2026-08-15_194600_phase3-repository-and-status-reconnaissance.html` | `f0e3034ebbfbbc81eec4f8684b1cbb3afcb29f443988a3bdc145e75c24659d7f` | `f0e3034ebbfbbc81eec4f8684b1cbb3afcb29f443988a3bdc145e75c24659d7f` | **byte-identical** (41,584 B) |
| `governance/Phase -3-Regroup/remediation/claude_2026-08-15_200100_phase3-remediation-status-report-v2.md` | `360a65600d35d1e2f35dcd005cea962ee289628dcf91bb0330eab80741a2f54c` | `360a65600d35d1e2f35dcd005cea962ee289628dcf91bb0330eab80741a2f54c` | **byte-identical** (35,369 B) |

**Confirmed byte-identical. The base-checkout duplicates can be removed without loss.**

Both are **untracked files in the base checkout's working tree** — I created them there at 19:48 before the owner ruled on target checkout, then wrote the worktree copies at 20:22. They belong to no branch. Deleting them removes two untracked files from a `docs/phase3-remediation-evidence` working tree and nothing else.

---

## 3. Which branch was the F-01 work based on?

**Yes — `remediation/phase3` at tip `d1ad55de0c5cc66a9bc6d59745483a7127e1f062`.**

**How I established it, and its limit.** I cannot run `git rev-parse`. I established it by content comparison instead: before editing, I staged five worktree files and diffed each against `origin/remediation/phase3` from an independent clone. All five matched byte-for-byte:

```
CLAUDE.md                                                        MATCH
SERVER-REGISTRY.md                                               MATCH
.claude/hooks/hx-phase1-guard.ps1                                MATCH
governance/Phase -3-Regroup/remediation/README.md                MATCH
governance/Phase -3-Regroup/remediation/claude_20260815_0234_phase3remediationplandeepv3.html   MATCH
     on-disk SHA-256 6317299dfd591e0eabfd1b9184110a5d8c52ba9578b3492879758f55cd998e45
     published       6317299dfd591e0eabfd1b9184110a5d8c52ba9578b3492879758f55cd998e45
```

`hx-remediation\.git` is a 90-byte pointer reading `gitdir: C:/Users/JarvisRichardson/Desktop/HX-Infrastructure/.git/worktrees/hx-remediation`, confirming a correctly linked worktree.

**This is strong evidence, not proof.** Content matching cannot exclude a detached HEAD at the same tree. Please confirm authoritatively with `git rev-parse HEAD` and `git status -sb` before you commit. If it disagrees with `d1ad55de`, stop and tell me.

I also confirm PR #2 as you describe: open, base `main`, head `remediation/phase3`, 3 commits, head `d1ad55d`. CodeRabbit's 12 comments include directory naming — see §5, that overlaps F-01 directly.

---

## 4. "Base checkout" — directory or branch? **My error. LR-2 retracted.**

I meant the **directory** `C:\Users\JarvisRichardson\Desktop\HX-Infrastructure`. I then asserted it was **on `main`**, and that assertion is **false**.

```
C:\Users\JarvisRichardson\Desktop\HX-Infrastructure\.git\HEAD
ref: refs/heads/docs/phase3-remediation-evidence
```

**How I got it wrong.** I never read `.git/HEAD` — a 49-byte file I could have staged at any point. I inferred the branch from `origin/main`'s tip and from file sizes differing from `main`, and treated every difference as uncommitted work. Every one of those differences is explained by the checkout being on a different branch. The inference was lazy and I should have read the file.

**Item-by-item retraction.** Each file I called dirty, diffed against `origin/docs/phase3-remediation-evidence`:

| Path | I claimed | Actual |
| --- | --- | --- |
| `.gitignore` (706 B) | modified, uncommitted | **matches evidence branch — clean, tracked** |
| `GOALS-AND-OBJECTIVES.md` (7,172 B) | modified, uncommitted | **matches evidence branch — clean, tracked** |
| `_s2.py` (1,081 B) | untracked | **tracked on the evidence branch — clean** |
| `governance/operations/langgraph/*` (6) | six pending deletions | **already committed in `52b76f9`, which the evidence branch contains — nothing pending** |
| `governance/Phase -3-Regroup/` | untracked tree | **29 paths tracked on the evidence branch** |

**The base checkout is clean.** The only untracked files in it are the four I put there today: two duplicate reports (§2) and two renames (§1) — and the renames are ignored by that branch's `.gitignore`.

**Downstream corrections.** LR-2 is cited in three documents I wrote today:

- `governance/Phase -3-Regroup/remediation/claude_2026-08-15_200100_phase3-remediation-status-report-v2.md` — §1, §4.1(c), §4.6, §7, §8 step 2
- `governance/Phase -3-Regroup/repo review/claude_2026-08-15_194600_phase3-repository-and-status-reconnaissance.html` — implied in the F-01 finding
- `clauda-ai/claude_2026-08-15_202500_operating-model-and-handoff-to-github-copilot.md` — §6

I will issue corrected versions once you have ruled on §5, so the correction lands in the same commit as your gate rather than churning the tree twice. **Do not treat LR-2 as a finding, and do not action §8 step 2 of the v2 status report.**

**F-01 itself is unaffected.** The eleven-artifact tracking loss, the ten dangling references, and the `.gitignore` defect are all properties of the *committed* tree and were verified against the published refs, not against the local working state. They stand.

---

## 5. Should F-01 join PR #2?

**Recommendation: yes, as its own commit on `remediation/phase3`, joining PR #2. Do not cut a separate branch.** Your call — you own the gates — but the reasoning:

1. **F-01 repairs a defect introduced by `52b76f9`, which is inside PR #2.** Splitting them means PR #2 merges to `main` carrying a commit that deletes six governance artifacts and leaves ten references dangling, with the fix trailing behind. If the follow-up PR stalls, `main` holds the regression. A PR should not merge a defect it already knows about.
2. **It is already on that branch.** The edits are in the `remediation/phase3` worktree. A separate PR means moving them to a new branch off `d1ad55de` — extra handling for no gain.
3. **CodeRabbit already flagged directory naming.** F-01 is the answer to that comment. Landing it in the same PR lets you resolve the thread rather than deferring it.
4. **It reduces PR #2's risk rather than adding to it.** The 13 files are 6 restorations, 4 mechanical path repairs, 1 ignore rule, and 2 report additions. No code path, no guard, no test assertion is touched — which is why the suite should stay at 160/0.

**Suggested commit message:**

```
fix: restore governance artifacts lost to the operations ignore rule (F-01)

Baseline 52b76f9 added a blanket /governance/operations/ ignore rule and
deleted six LangGraph artifacts from tracking while rewriting their
references to a path no commit contained. Invert the rule to exclude
vendored subtrees by shape, restore the six under phase-2/, and repair
ten references across six files.

Owner ruling 9, 2026-08-15. No server contacted; no guard or test
assertion changed.
```

**Caveat:** PR #2 is at 42 files with a "moderate" risk rating. If you judge that 55 files is past the point a reviewer can hold, split it — that is a legitimate call and I will not argue it. But then please **block PR #2 on the F-01 PR** so `main` never sees the regression alone.

---

## 6. `_s2.py` cleanup — **withdrawn, no cleanup required**

**Answer: it is expected, exactly as you suggest. There is no separate uncommitted `_s2.py`. My recommendation is withdrawn.**

```
origin/main                                _s2.py  ABSENT
origin/docs/phase3-remediation-evidence    _s2.py  1081 bytes
origin/remediation/phase3                  _s2.py  1354 bytes

base checkout  (docs/phase3-remediation-evidence)  1081 bytes  -> matches its branch, clean
worktree       (remediation/phase3)                1354 bytes  -> matches its branch, clean
```

The 1,081-byte copy is the version added by `52b76f9`. Hardening landed in `8ec683b`, which is on `remediation/phase3` and not on the evidence branch. **Both working copies are correct for their branches. Nothing is uncommitted.**

**What I got wrong, and why it mattered.** In §6 of my previous message I asked whether I should overwrite the base-checkout copy with the 1,354-byte version. Acting on that would have written a `remediation/phase3` file into a clean `docs/phase3-remediation-evidence` working tree — manufacturing the dirty state I had wrongly reported, and cross-contaminating two branches. **Please disregard that question entirely.** It was the correct instinct on your part to ask what the cleanup actually required rather than performing it.

**Residual note, not a finding.** Anyone running `_s2.py` from the base checkout while it is on the evidence branch runs the pre-hardening version. That is a property of the branch, not a defect, and it resolves when PR #2 merges. If you think it is worth guarding in the interim, the cheap option is a line in the evidence branch README saying the tooling copy there is pre-hardening and `_s2.py` should be run from the worktree. I do not think it rises to an `iss-` row.

---

## 7. Direct evidence for the `.gitignore` patterns

Full `git check-ignore -v` output, run against a clean clone of `origin/remediation/phase3` with only `.gitignore` swapped for the proposed version. 29 probes.

### Group A — vendored drops, must be ignored (11/11 pass)

```
.gitignore:22:governance/operations/*/*-main/       governance/operations/langgraph/langgraph-main/README.md
.gitignore:23:governance/operations/*/*-master/     governance/operations/jcode/jcode-master/scripts/x.sh
.gitignore:22:governance/operations/*/*-main/       governance/operations/vllm/vllm-main/setup.py
.gitignore:22:governance/operations/*/*-main/       governance/operations/ollama/ollama-main/go.mod
.gitignore:22:governance/operations/*/*-main/       governance/operations/loopx/loopx-main/src/a.py
.gitignore:22:governance/operations/*/*-main/       governance/operations/skills/agent-skills-main/x.md
.gitignore:24:governance/operations/*/*-release-*/  governance/operations/OmniRoute/OmniRoute-release-v3.8.50/bin/x
.gitignore:22:governance/operations/*/*-main/       governance/operations/code-rag-graph/code-graph-rag-main/x.py
.gitignore:22:governance/operations/*/*-main/       governance/operations/gitdiagram/gitdiagram-main/x.ts
.gitignore:22:governance/operations/*/*-main/       governance/operations/diagram-design/diagram-design-main/x.md
.gitignore:22:governance/operations/*/*-main/       governance/operations/code-review-graph/code-review-graph-main/x.py
```

### Group B — HX-authored, must be trackable (8/8 pass)

No rule matched any of these; `check-ignore` exited non-zero for each, which is the pass condition.

```
TRACKABLE  governance/operations/langgraph/phase-2/Claude-Opus-5_2026-08-14_langgraph-review-verdicts.md
TRACKABLE  governance/operations/langgraph/hx-langgraph-post-recon-position-and-order-dependency-decision_gpt-5.6-sol_20260815_0123.html
TRACKABLE  governance/operations/ollama/hx-ollama-reconnaissance-and-agent-craig-hxs4-audit_gpt-5.6-sol_20260815_0228.html
TRACKABLE  governance/operations/skill-expert/hx-skill-expert-reconnaissance-fit-assessment_gpt-5.6-sol_20260815_0130.html
TRACKABLE  governance/operations/docling/hx-granite-docling-reconnaissance-report_chatgpt-gpt-5-6_20260815_0305.html
TRACKABLE  governance/operations/Qwen/Claude-Opus-5_2026-08-14_hxs4-qwen35-9b-commissioning-report.html
TRACKABLE  governance/operations/sessions/session-resume.md
TRACKABLE  governance/operations/hxs3-workload-placement.md
```

### Group C — over-reach probes, must NOT be ignored (6/6 pass)

This is the check you asked for. The patterns are anchored to `governance/operations/`, so a `*-main`, `*-master` or `*-release-*` directory anywhere else is unaffected.

```
not ignored  services/docling-mcp/foo-main/x.py
not ignored  tools/page-bodies/thing-master/x.js
not ignored  servers/hxs-1/vllm-main/x.md
not ignored  governance/reports/claude/app-release-v1/x.html
not ignored  governance/operations/ollama/craig-ollama-specialist.md
not ignored  governance/operations/loopx/loopx-operational-learning-ledger.md
```

### Group D — **known limitation, disclosed**

```
NOT IGNORED  governance/operations/langgraph/vendor/langgraph-main/x.py
NOT IGNORED  governance/operations/a/b/c-main/x.py
```

`governance/operations/*/` matches exactly one path segment. **A vendored drop nested two or more levels below `governance/operations/` escapes the rule.** Every current drop sits at exactly one level, so this is latent, not live — but I did not disclose it in my previous message and should have.

**Proposed hardening**, if you want it closed. Replace `*/` with `**/` on all three lines. I tested it:

```
governance/operations/**/*-main/
governance/operations/**/*-master/
governance/operations/**/*-release-*/

  IGNORED       governance/operations/langgraph/vendor/langgraph-main/x.py     <- limitation closed
  IGNORED       governance/operations/a/b/c-main/x.py                          <- limitation closed
  IGNORED       governance/operations/langgraph/langgraph-main/README.md       <- Group A still passes
  trackable     governance/operations/langgraph/phase-2/...review-verdicts.md  <- Group B still passes
  trackable     governance/operations/sessions/session-resume.md               <- Group B still passes
  not ignored   services/docling-mcp/foo-main/x.py                             <- Group C still passes
```

No regression in any group. **Your call** — `**/` is more robust, `*/` is more explicit about the shape actually in use. I have left `*/` in the worktree; say the word and I will switch it, or change it yourself in one line.

### Group E — pre-existing rules intact (2/2 pass)

```
.gitignore:1:.env                              .env
.gitignore:4:tests/ai-runtime/evidence/*.json  tests/ai-runtime/evidence/run.json
```

---

## 8. How were the six LangGraph files restored?

**Correction first: not from a git object.** My previous message said "sourced from the owner's disk" but the phrasing invited the reading that I recovered blobs. To be unambiguous:

**Source for all six: the owner's filesystem** at

```
C:\Users\JarvisRichardson\Desktop\HX-Infrastructure\governance\operations\langgraph\phase Phase -2\
```

They were never deleted from disk. `52b76f9` removed them from *tracking* and rewrote their references; the owner had already moved the files into that subfolder, and the new `/governance/operations/` ignore rule prevented the additions from staging while the deletions staged normally.

**Their provenance is established by comparison to git, not by recovery from it.** Last commit touching that directory on `main`: `9a5b7b6` (2026-08-14, *"Actually commit the decision-3, park and gitignore work"*). Deleted by `52b76f9`.

| # | File | `origin/main` blob | Restored blob | Verdict |
| --- | --- | --- | --- | --- |
| 1 | `Claude-Opus-5_2026-08-14_langgraph-review-verdicts.md` | `91ea2b2b57022c69d316621907cd33da785051fb` | `91ea2b2b57022c69d316621907cd33da785051fb` | identical |
| 2 | `claude_20260814_0848_langgraphfourdecisions.html` | `2fff636c87ec8e03d756583827ac4a5bbe52bb71` | `2fff636c87ec8e03d756583827ac4a5bbe52bb71` | identical |
| 3 | `Claude-Opus-5_2026-08-14_langgraph-decisions-applied-report.html` | `9b98e905a02d54078f766845e272db68f35f3daf` | `9b98e905a02d54078f766845e272db68f35f3daf` | identical |
| 4 | `Claude-Opus-5_2026-08-14_langgraph-distillation-pilot-report.html` | `a7291dc44bbab07bcaa530282bcdd29bc381b236` | `a7291dc44bbab07bcaa530282bcdd29bc381b236` | identical |
| 5 | `Claude-Opus-5_2026-08-14_langgraph-pilot-preflight-blocker.html` | `e2f0889127c36e7165025c680b9c3cbc56a277d7` | `055465cfd0ed160282256f40b497ba8bc4b66741` | **modified** |
| 6 | `claude_20260814_0730_langgraphdistillationpilotbrief.html` | `a59a80b88bdb85e9684c189f7a6104264f739358` | `ca0baf601328726655ddec157cfbb31d31a3ed11` | **modified** |

Blob IDs are `git hash-object` on the exact bytes written to the worktree, comparable directly against `git rev-parse origin/main:<path>`.

### Diffs for the two intentional differences

**#5 — one line. A path reference in the footer, repaired by me as part of F-01's ten:**

```diff
@@ -278,7 +278,7 @@
 <footer>
 Claude Opus 5 &middot; 2026-08-14 &middot; LangGraph distillation pilot, pre-flight halt<br>
-Brief: <code>governance/operations/langgraph/claude_20260814_0730_langgraphdistillationpilotbrief.html</code>
+Brief: <code>governance/operations/langgraph/phase-2/claude_20260814_0730_langgraphdistillationpilotbrief.html</code>
 </footer>
```

**#6 — two hunks. A `_s2.py` supersession banner added by the owner before I touched anything, plus one HISTORICAL marker; the banner's own path reference repaired by me:**

```diff
@@ -240,6 +240,12 @@
 <h2><span class="k">9</span>Target shape of <code>service.md</code></h2>
+<p><strong>Historical / superseded runtime assumption.</strong> This pilot execution brief assumed
+a bare-metal virtual environment managed by systemd. Final owner Decision 3 instead selected a
+packaged server with its own service lifecycle. The final record is
+<code>governance/operations/langgraph/phase-2/Claude-Opus-5_2026-08-14_langgraph-review-verdicts.md</code>,
+"Decision 3 - FINAL: packaged server." The outline below is retained as pilot history and is
+not current deployment guidance.</p>

@@ -261,7 +267,7 @@
-├── Runtime and service model   # bare-metal venv, systemd; no containers
+├── Runtime and service model   # HISTORICAL / SUPERSEDED: bare-metal venv, systemd; no containers
```

**Attribution split, so the record is precise:** the banner and HISTORICAL marker in #6 are the owner's `_s2.py` output, predating my session. The `phase-2/` path fragments in both #5 and #6 are mine. No other content in any of the six was altered.

---

## 9. Where should the hook-bypass gap be recorded?

**Recommendation: an `iss-` row in `actions-and-issues.md`, scoped to what is structurally certain — not held as a cold-verifier observation.** But your framing is right and it changes the wording, so let me separate two things I ran together:

**Certain, no test required.** A PreToolUse hook fires on a Claude Code tool call. Writes arriving over the device bridge are filesystem writes made by a different process; they are not Claude Code tool calls and there is no interception point. This is definitional, not empirical. Any editor — this bridge, VS Code, Notepad, `git checkout` — bypasses the guards identically. **The gap is not specific to me; I am just the first automated writer to use it at volume.** That reframing matters: it is a pre-existing property of the control, and my access made it load-bearing.

**Uncertain, needs a test.** The exact behaviour *inside* Claude Code when a hook errors — which is F-03, the StrictMode fail-open at `hx-phase1-guard.ps1:11` and `:25`. That is a different claim, static-analysis only, and should stay unpromoted until `echo "" | pwsh -File .claude\hooks\hx-phase1-guard.ps1` settles it.

So: record the first as an issue now, keep the second where it is. Draft row, in the register's vocabulary — adjust the ID to the next free number:

> `iss-020` | issue | **medium. The hook guards constrain one editing channel, not the repository.** `hx-authority-edit-guard.ps1`, `hx-permanent-policy-guard.ps1` and `hx-phase1-guard.ps1` are PreToolUse hooks and fire only on Claude Code tool calls. Any other writer — the Claude cloud device bridge, an editor, `git checkout`, a script — reaches the same files with no guard evaluated. Surfaced 2026-08-15 when the cloud session was granted direct read/write access and applied the F-01 edit set to the worktree without any guard running. | The repository's stated control that authority files cannot be edited unguarded is true only of the Claude Code channel. Enforcement that holds regardless of channel must be state-based (CI, commit-time checks) rather than act-based. | hx infrastructure | open | (F-01, and the P-F1 authorization-record design) | Not a defect in the hooks: they do what a PreToolUse hook can do. The gap is scope. See the enforcement proposal in §10 of `clauda-ai/claude_2026-08-15_203750_response-to-github-copilot-f01-questions.md`.

**Do not take my wording as final** — the register is yours and the owner's, and you write its vocabulary better than I do. If you would rather hold it as a cold-verifier observation until the boundary is demonstrated, I will not argue; the cost of waiting is low because §10's mitigation does not depend on the row existing.

---

## 10. Durable enforcement — the proposal

You are right that "prefer PowerShell Claude Code" is a convention, and conventions do not survive a hurried evening. Here is what I would actually build, worst to best.

**The principle:** *the hooks police the act; durable enforcement must police the state.* Act-based control can only ever cover the channel it sits in — that is §9's whole point. Anything channel-independent has to assert on what the tree **contains**, not on how it got that way. Every mechanism below follows from that.

### Tier 1 — Git pre-commit hook, protected-path check

A `.githooks/pre-commit` that fails when the staged set touches `README.md`, `CLAUDE.md`, `SERVER-REGISTRY.md`, `AGENTS.md`, `servers/AGENTS.md`, `.claude/AGENTS.md`, `.claude/hooks/**`, `GOALS-AND-OBJECTIVES.md` or `INFRASTRUCTURE-CONTRACT.md` without an explicit acknowledgement trailer.

Honest assessment: **weak.** Not shared by clone (needs `git config core.hooksPath .githooks`), bypassed by `--no-verify`. Worth doing as a speed bump, worth nothing as a guarantee. Do not let it be the answer.

### Tier 2 — CI on push and PR ⭐ **this is the real one**

A GitHub Actions workflow that runs on every push to `remediation/phase3` and on every PR to `main`:

1. **Regression suite** — `pwsh` is available on `ubuntu-latest`; if the suite has Windows dependencies, `windows-latest` runs it natively.
2. **Repository-wide P1-01 scan** — the exclusion-list version from F-02, not the eleven-file allowlist.
3. **Protected-path diff check** — flags authority-file changes for explicit review.
4. **Standards lint** — no spaces, no non-ASCII, no parentheses in added filenames. This would have caught `craig(1).md`, `That may be LoopX's strongest strat.md`, and `phase Phase -2` before any of them entered the tree.
5. **Reference integrity** — every `governance/...` path referenced in Markdown or HTML resolves to a file that exists. **This alone would have caught F-01 at the moment `52b76f9` was pushed.**

This is channel-independent by construction: it does not care who wrote the file or with what. It also closes **F-08** — today the suite, the scan and the 47 validation PASS lines are single manual runs on one workstation, and nothing re-runs them.

Check 5 is the highest-value item on this list and the cheapest to write. If only one thing gets built, build that.

### Tier 3 — branch protection + required status checks

Make the Tier 2 workflow a required check on `main`. Then no merge can land without it, regardless of author, tool or urgency. Combine with `CODEOWNERS` requiring owner review on the protected paths.

Note this also closes an open item: `risk-003`'s acceptance conditions include `lock_branch`, force-push disabled and deletion disabled on `legacy/2025`. **I could not verify those are actually set** — the GitHub API returned 403 unauthenticated. Worth confirming in the same pass.

### Tier 4 — state invariants in the suite itself

Extend `tests/remediation-tests-restored.ps1` with assertions that the authority surfaces *state the current truth*, independent of who edited them:

- every authority file states the three-stage lifecycle and names Phase 3 as current;
- the guard contains no registry-status release path;
- no `governance/` reference resolves to a missing file;
- `SERVER-REGISTRY.md`'s reader claim matches the actual readers — **which is F-04, and would have been caught by this on the day it broke.**

This is the strongest form because it survives any editing channel, any tool, and any future contributor: an unguarded edit is caught by its *effect*, not by its origin. It also converts the suite from a change-detector into a truth-detector, which is what a governance repository actually needs.

### Recommended order

**Tier 2 checks 4 and 5 first** — cheap, and each retroactively catches a real defect found this week. **Then Tier 3.** Tier 4 as P1 items close, so the invariants encode settled truth rather than moving targets. Tier 1 only if you want the speed bump; it is not load-bearing.

**Scope caution.** All four tiers are Transition Stage work, not Phase 3. Phase 3 is planning, decisions, and control-correction that only tightens. Adding CI is new capability, not tightening — it should be recorded as a Gate B input and built under owner authorization, not folded into F-01. I raise it now because you asked, and because P-F1's design should account for it: the authorization record that replaces the hard lock will have the same channel problem unless it is enforced at commit or CI time.

---

## Standing

- **LR-2 is withdrawn.** The base checkout is clean and on `docs/phase3-remediation-evidence`.
- **The `_s2.py` question in my previous message is withdrawn.** No cleanup required.
- **F-01's 13 files stand** and are ready for your gate. Expected: suite 160/0, scan TOTAL 0.
- **Open for your ruling:** §5 (join PR #2 or split), §7 (`*/` or `**/`), §9 (issue row now or cold-verifier hold).
- Corrected versions of the three documents carrying LR-2 will follow once §5 is settled.

Nothing here authorizes server implementation. No server was contacted.

— Claude (claude-opus-5)
